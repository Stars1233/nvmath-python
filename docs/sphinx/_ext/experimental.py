"""Sphinx extension for marking APIs as experimental.

APIs are marked with the ``.. experimental:: <type>`` directive in a docstring,
where ``<type>`` names what is being marked:

* ``function`` / ``method`` -- the single documented function or method
  (rendered with a border and a marker box). Put it as the first line of its
  docstring::

      def transform(data):
          '''
          .. experimental:: function

          Transform ``data`` ... (rest of the docstring)
          '''

* ``class`` -- the documented class; the marking covers its whole block
  (signature, docstring, and members). Put it as the first line of the class
  docstring::

      class Solver:
          '''
          .. experimental:: class

          Solve ... (rest of the docstring)
          '''

* ``parameter`` -- a single function input (a highlighted row in the
  Parameters list). Nest it under that parameter's ``Args:`` entry::

      def transform(data, out=None):
          '''
          Transform ``data`` ... (rest of the docstring)

          Args:
              data: Input data to process.

              out: Optional output buffer. If omitted, one is allocated.

                  .. experimental:: parameter
          '''

* ``attribute`` -- a non-function class member (e.g. an options / dataclass
  field). It renders one of two ways, and the marking adapts to whichever:

  - as its own ``.. attribute::`` object (a hand-written directive, an autodoc'd
    attribute docstring, or a Napoleon ``Attributes:`` entry under
    ``napoleon_use_ivar=False``);
  - as a ``Variables``/``:ivar:`` field-list row (a hand-written ``:ivar:`` field
    or a Napoleon ``Attributes:`` entry under ``napoleon_use_ivar=True``)

  Either way, nest the marker under that attribute's entry::

      @dataclass
      class Options:
          '''
          Options for ... (rest of the docstring)

          Attributes:
              mode: A normal option.

              inplace: Overwrite the input in place.

                  .. experimental:: attribute
          '''

* ``module`` -- the *whole page*: one bar spans the page with a banner at the
  top, and the marking **cascades** along the ``toctree`` to every reachable
  page (e.g. the per-API stub pages ``autosummary`` generates), each rendered
  with the same whole-module treatment. Because it applies to the page as a
  whole, write it where it attaches to the page itself -- the top of a
  hand-written ``.rst`` landing page (or a module's docstring, which
  ``automodule`` renders into the page body), not inside a
  class/method/function docstring where it would nest under that one object.
  The banner names the module automatically -- the name is deduced from the
  page's ``.. module::``/``automodule`` registration (see
  :func:`_deduce_module_name`) and the same name is shown on every cascaded
  page; a page documenting a module alongside its submodules uses the umbrella
  module. If it cannot be deduced (no module on the page, or several unrelated
  ones) the banner keeps the generic wording and a build warning explains why.

* ``group`` -- like ``module``, but for a *named set of APIs* whose banner text
  is authored explicitly instead of deduced from a module registration. It
  renders and **cascades** exactly like ``module`` (one page-spanning bar, the
  same banner on every toctree descendant), and the directive's body supplies
  the full banner sentence::

      .. experimental:: group

         The distributed runtime APIs are experimental
         and potentially subject to future changes.

  Use ``group`` when the page documents a *subset* of a broader module (so the
  deduced name would be too broad), documents APIs spanning several modules,
  registers its module with ``:no-index:`` (which leaves nothing to deduce), or
  is a hand-written landing page with no single module. ``module`` and
  ``group`` are peers: at most one page-level marking (of either kind) may
  cover any page in a ``toctree`` chain, so the covering page is unambiguous.

Markings must not be redundant. Following the precedence
``module/group > class > method/function > parameter`` (with ``attribute`` a
leaf under ``class``, just as ``parameter`` is a leaf under
``method/function``), a marking nested inside a higher-precedence one is a hard
error that fails the build immediately (regardless of ``-W``):

* a marked **module**/**group** covers every
  class/method/function/parameter/attribute on the page (and, via the toctree,
  on every descendant page);
* a marked **class** covers its methods (and their parameters) and its
  attributes;
* a marked **method/function** covers its parameters.

Erroring keeps the behavior intentional, preventing a forgotten inner marking
from resurfacing (possibly stale) when the outer one is removed.
"""

from __future__ import annotations

import os
from typing import TYPE_CHECKING

from docutils import nodes
from docutils.parsers.rst import Directive
from docutils.utils import get_source_line
from sphinx import addnodes
from sphinx.errors import SphinxError
from sphinx.util import logging
from sphinx.util.fileutil import copy_asset_file

if TYPE_CHECKING:
    from sphinx.application import Sphinx
    from sphinx.environment import BuildEnvironment

logger = logging.getLogger(__name__)

CSS_FILE = "experimental.css"

API_TYPES = ("module", "group", "function", "class", "method", "parameter", "attribute")

# The two page-level marking kinds. Both wrap the whole page in the module bar,
# cascade down the toctree, and are mutually exclusive within a toctree chain.
# They differ only in how the banner is named: ``module`` deduces the name from
# the page's Python-domain registration, ``group`` takes explicit banner text.
_PAGE_MARKER_SUFFIXES = ("module", "group")

# Build a dictionary whose *key* is a documented object's Sphinx `objtype` and
# whose *value* is the single API_TYPES entry that is valid for it.
#
# Why this is needed: to catch mistakes where the wrong API type is used to mark a
# feature, such as:
#   - a `class` marked with anything but `.. experimental:: class`;
#   - a `method` marked with anything but `.. experimental:: method`;
#   - an attribute rendered as its own `py:attribute` desc -- its *object* form
#     (a hand-written `.. attribute::`, an autodoc'd attribute docstring, or a
#     Napoleon `Attributes:` entry under `napoleon_use_ivar=False`) -- marked with
#     anything but `.. experimental:: attribute`.
#
# Why `parameter`, an attribute's *ivar* form, and `module` are not keys here:
#   - `parameter` is not a documented object: it has no `desc`/`objtype` but is a
#     row in the rendered "Parameters" field list (from `:param:` fields, however
#     authored). Its marker is matched by *location* (walk up to the enclosing
#     row) in the separate *Parameters* pass, not here.
#   - an attribute documented as a `Variables`/`:ivar:` row (rather than a
#     `.. attribute::` object) is the same: not a `desc`, so it is matched by
#     location in the *Attributes (ivar form)* pass, not validated here.
#   - `module` is page-level, not an object: it marks a whole page (and cascades
#     down the toctree), never attaches to a `desc`, and is handled by the
#     module-collection / page-wrapping path; the Objects pass explicitly skips it.
#
# An `objtype` not listed here cannot be marked and is recorded as an error.
_VALID_MARKER_KIND_BY_OBJTYPE = {
    "class": "class",
    "function": "function",
    "method": "method",
    # An attribute documented as its own `.. attribute::` (py:attribute) object.
    "attribute": "attribute",
}

# Marking errors (precedence conflicts and misplaced module markers) are
# collected here as pages are processed and raised together at the end of the
# build. See :class:`ExperimentalMarkingError` for why the raise is deferred.
# Being a plain module-level list, this only works when every append runs in the
# *main* process -- appends from a worker subprocess are discarded when it exits.
# That holds because all recording happens from the ``doctree-resolved`` handler,
# which Sphinx runs in the main process even under ``-j`` (only HTML writing is
# parallelized). A violation found at read time (``doctree-read``, run in
# workers) must instead be routed through ``env`` and the ``env-merge-info``
# handler, the way the page-marking map is -- see
# :func:`_merge_page_markings`.
_violations: list[str] = []


class ExperimentalMarkingError(SphinxError):
    """A misuse of the ``.. experimental::`` markings that fails the build.

    Violations are detected and recorded as pages are processed, then raised
    together at the end of the build by :func:`_raise_collected_violations`.
    """

    category = "Experimental marking error"


def _make_marker(api_type: str) -> nodes.container:
    """Build the inline experimental marker box for ``api_type``.

    Args:
        api_type: The marking granularity, one of :data:`API_TYPES`. Selects the
            message wording and the type-specific CSS class.

    Returns:
        A docutils ``container`` node carrying the ``experimental-marker`` and
        ``experimental-marker-<api_type>`` classes.
    """
    text = f"This {api_type} is experimental and potentially subject to future changes."
    container = nodes.container()
    container += nodes.paragraph("", text)
    # The generic class drives the marker box + enclosing-object detection;
    # the type-specific class lets post-processing special-case e.g. params.
    container["classes"].extend(["experimental-marker", f"experimental-marker-{api_type}"])
    return container


def _make_module_banner(modname: str | None) -> nodes.container:
    """Build the whole-page module banner, naming the module when known.

    Args:
        modname: The module name to render (monospace) in the banner, or
            ``None`` to fall back to the generic wording.

    Returns:
        A ``container`` node carrying the ``experimental-marker`` /
        ``experimental-marker-module`` classes and the banner paragraph.
    """
    para = nodes.paragraph()
    if modname:
        para += nodes.Text("The ")
        para += nodes.literal(modname, modname)
        para += nodes.Text(" module is experimental and potentially subject to future changes.")
    else:
        para += nodes.Text("This module is experimental and potentially subject to future changes.")
    container = nodes.container()
    container += para
    container["classes"].extend(["experimental-marker", "experimental-marker-module"])
    return container


def _make_group_banner(text: str) -> nodes.container:
    """Build the whole-page banner for a ``group`` marking from authored text.

    Unlike :func:`_make_module_banner`, the wording is supplied verbatim by the
    author (the directive body) and rendered as plain text -- there is no module
    name to render in monospace. The banner reuses the module banner's classes so
    it is styled identically (the page bar is driven by the ``experimental-module``
    wrapper, not by this box).

    Args:
        text: The full banner sentence to display.

    Returns:
        A ``container`` node carrying the ``experimental-marker`` /
        ``experimental-marker-module`` classes and the banner paragraph.
    """
    para = nodes.paragraph()
    para += nodes.Text(text)
    container = nodes.container()
    container += para
    container["classes"].extend(["experimental-marker", "experimental-marker-module"])
    return container


class ExperimentalDirective(Directive):
    """Inline admonition marking an API as experimental.

    Usage in docstrings::

        .. experimental:: module
        .. experimental:: function
        .. experimental:: class
        .. experimental:: method
        .. experimental:: parameter
        .. experimental:: attribute

    Emits a ``container`` carrying ``experimental-marker`` and a type-specific
    ``experimental-marker-<type>`` class; the event handlers below act on it.
    """

    # `has_content` is enabled only so that `group` can carry its banner text;
    # every other kind must have an empty body (enforced in `run`).
    has_content = True
    required_arguments = 1
    optional_arguments = 0

    def run(self) -> list[nodes.Node]:
        """Build the marker node for one ``.. experimental:: <type>`` directive.

        Returns:
            A single-element list holding the marker ``container`` node, with the
            directive's source location recorded on it for later error messages.
            For ``group``, the authored banner text is stashed on the node under
            the ``experimental_label`` attribute for the read-time collector.

        Raises:
            DirectiveError: If the argument is not one of :data:`API_TYPES`, if a
                ``group`` has no body text, or if any other kind has body text --
                each failing the build with a source-located error.
        """
        api_type = self.arguments[0]
        if api_type not in API_TYPES:
            raise self.error(f"unknown 'experimental' API type {api_type!r}; expected one of: {', '.join(API_TYPES)}.")
        body = " ".join(" ".join(self.content).split())
        if api_type == "group":
            if not body:
                raise self.error(
                    "'.. experimental:: group' requires body text for the banner, e.g.\n\n"
                    "    .. experimental:: group\n\n"
                    "       The ... APIs are experimental and potentially subject to future changes."
                )
        elif body:
            raise self.error(f"'.. experimental:: {api_type}' does not take body text; only '.. experimental:: group' does.")
        marker = _make_marker(api_type)
        if api_type == "group":
            # Carried to the read-time collector, which stores it (per docname) so
            # the same banner can be rebuilt on the page and every cascaded child.
            marker["experimental_label"] = body
        # Record the directive's source location on the marker so the precedence
        # checks can point authors at the exact `.. experimental::` line.
        marker.source, marker.line = self.state_machine.get_source_and_line(self.lineno)
        return [marker]


def _get_page_markings(env: BuildEnvironment) -> dict[str, str | None]:
    """Return the (mutable) map of page-level experimental markings.

    Maps each whole-page-marked docname to its banner label: the authored text
    for a ``group`` marking, or ``None`` for a ``module`` marking (whose name is
    deduced at resolve time). Membership (the key set) is what drives the toctree
    cascade; the value only selects the banner wording.

    Stored on the build ``env`` so it persists across the build and is pickled
    between runs. Created empty on first access; routing every reader/writer
    through this accessor spares them the not-yet-initialized case.

    Args:
        env: The Sphinx build environment the map is stored on.

    Returns:
        The ``docname -> label`` map of page-level markings.
    """
    if not hasattr(env, "experimental_page_markings"):
        env.experimental_page_markings = {}
    return env.experimental_page_markings


def _is_page_marker(node: nodes.Node) -> bool:
    """Return ``True`` if ``node`` is a page-level (``module``/``group``) marker box.

    Args:
        node: The node whose ``experimental-marker-*`` classes are inspected.

    Returns:
        ``True`` for a ``module`` or ``group`` marker container, else ``False``
        (e.g. an object/parameter marker, or a plain ``experimental-marker``
        container that carries no page-level suffix).
    """
    classes = node.get("classes", [])
    if "experimental-marker" not in classes:
        return False
    return any(f"experimental-marker-{suffix}" in classes for suffix in _PAGE_MARKER_SUFFIXES)


def _page_marking_kind(env: BuildEnvironment, docname: str) -> str:
    """Return the page-level marking kind for ``docname`` (``"module"``/``"group"``).

    A ``group`` marking stores its banner text (a ``str``); a ``module`` marking
    stores ``None``. Used only to word conflict messages after coverage is known.

    Args:
        env: The build environment holding the markings map.
        docname: The covering page whose marking kind is sought.

    Returns:
        ``"group"`` if the page stores authored text, otherwise ``"module"``.
    """
    return "group" if isinstance(_get_page_markings(env).get(docname), str) else "module"


def _find_covering_page(env: BuildEnvironment, docname: str, include_self: bool = True) -> str | None:
    """Return the docname whose page-level marking covers ``docname`` (else ``None``).

    A page-level marking (``module`` or ``group``) cascades *down* the toctree,
    so to test whether a page is covered we walk *up* its toctree parents and
    return the first marked page found. With ``include_self`` (the default) that
    may be the page itself; with ``include_self=False`` the page is skipped so
    only a marked *ancestor* can match -- used to detect a page whose own marker
    is redundant because an ancestor already covers it. The returned docname also
    names the covering page in redundancy errors.

    For example, if ``sparse/index`` is marked and its toctree pulls in the stub
    ``sparse/generated/Foo``, both resolve to ``"sparse/index"``, while an
    unmarked ``linalg/index`` resolves to ``None``.

    Args:
        env: The build environment (holds the page-marking map and toctree).
        docname: The page to test for coverage.
        include_self: Whether ``docname`` itself may be returned as its own cover.
            Pass ``False`` to require a strictly-higher covering ancestor.

    Returns:
        The covering marked-page docname, or ``None`` if none covers it.
    """
    docs = _get_page_markings(env)
    if not docs:  # fast path: no page-level marking anywhere on the site
        return None
    # child -> {parents} map from the toctree graph, so we can walk upward.
    parents: dict[str, set[str]] = {}
    for parent, children in getattr(env, "toctree_includes", {}).items():
        for child in children:
            parents.setdefault(child, set()).add(parent)
    seen = set()  # guards against diamonds in the toctree
    if include_self:
        stack = [docname]
    else:
        # Skip the page itself so only a marked ancestor can match: mark it seen
        # and start the walk from its parents.
        seen.add(docname)
        stack = list(parents.get(docname, ()))
    while stack:
        current = stack.pop()
        if current in seen:
            continue
        seen.add(current)
        if current in docs:
            return current
        stack.extend(parents.get(current, ()))
    return None


def _deduce_module_name(env: BuildEnvironment, docname: str) -> tuple[str | None, str | None]:
    """Deduce the Python module documented on ``docname``, for the banner label.

    Reads which module(s) the page registers from the Python domain. One
    registered module is used as-is. If several are registered but one is an
    ancestor of all the others (a module documented alongside its submodules),
    that umbrella module is used; otherwise the name is ambiguous.

    Args:
        env: The build environment; its merged ``py`` domain data is read.
        docname: The page whose registered module is sought. Passing the covering
            module page makes the name cascade unchanged to its descendants.

    Returns:
        ``(name, None)`` when the name is unambiguous -- exactly one module is
        registered, or one is the common ancestor of all the others; otherwise
        ``(None, reason)`` where ``reason`` explains why it could not be deduced
        (none registered, or several unrelated ones) for the build warning.

    Examples:
        A page with one ``.. module:: something.else`` yields
        ``("something.else", None)``. A page registering ``something.else`` plus
        its submodules ``something.else.foo`` / ``something.else.bar`` yields
        ``("something.else", None)`` (the umbrella). A plain ``.. toctree::``
        landing page yields ``(None, "no Python module ...")``, and a page
        aggregating unrelated modules (``something.else`` and ``something.else.other``)
        yields ``(None, "the page registers several modules ...")``.
    """
    modules = env.domaindata.get("py", {}).get("modules", {})
    names = sorted(name for name, entry in modules.items() if entry.docname == docname)
    if len(names) == 1:
        return names[0], None
    if not names:
        return None, (
            "no Python module is registered on the page (mark it with '.. module::' or "
            "'automodule'; note '.. currentmodule::' does not register one)"
        )
    # Several modules: if one is an ancestor (dotted prefix) of all the others --
    # a module documented on the same page as its submodules -- use it as the
    # umbrella label. Such an ancestor is necessarily the shortest name.
    umbrella = min(names, key=len)
    if all(name == umbrella or name.startswith(umbrella + ".") for name in names):
        return umbrella, None
    return None, f"the page registers several modules ({', '.join(names)}), so the name is ambiguous"


def _tag_experimental_objects_and_params(doctree: nodes.document) -> None:
    """Add the per-entry CSS classes for object-, parameter-, and attribute markings.

    Tags the node that carries the styling for each of three marking forms (see
    the inline comments for the node-walking details):

    - **Objects** -- a ``desc`` with a top-of-docstring marker gets
      ``experimental``; the marker kind must match the object's ``objtype``, and
      the ``objtype`` must be one the extension supports.
    - **Parameters** -- a ``parameter`` marker's row in the "Parameters" field
      list gets ``experimental-param`` (on the ``list_item``, or the ``field_body``
      when a lone parameter collapses the list).
    - **Attributes (ivar form)** -- an ``attribute`` marker in a
      ``:ivar:``/Variables row (rather than a ``.. attribute::`` object) gets
      ``experimental-ivar`` on its row container (likewise a ``list_item`` or a
      collapsed ``field_body``).

    Args:
        doctree: The resolved page tree; mutated in place.
    """
    # Objects: tag each `desc` whose own docstring opened with an object marker.
    for desc_node in doctree.findall(addnodes.desc):
        contents = [n for n in desc_node.children if isinstance(n, addnodes.desc_content)]
        if not contents:
            continue
        # Only direct children: a marker nested inside a child `desc` belongs to
        # that member, and a parameter marker lives deeper (Parameters field).
        for child in contents[0].children:
            if isinstance(child, addnodes.desc):
                continue
            classes = child.get("classes", [])
            if "experimental-marker" not in classes or _is_page_marker(child):
                continue
            objtype = desc_node.get("objtype")
            kind = _marker_kind(child)
            expected = _VALID_MARKER_KIND_BY_OBJTYPE.get(objtype)
            if expected is None:
                # An unsupported object type: fail rather than mark it.
                supported = ", ".join(sorted(_VALID_MARKER_KIND_BY_OBJTYPE))
                _violations.append(
                    f"{_location(child)}'.. experimental:: {kind}' cannot mark this {objtype}; only "
                    f"{supported} objects can be marked experimental."
                )
            elif kind != expected:
                # Wrong admonition for this object (e.g. `parameter` on a function).
                _violations.append(
                    f"{_location(child)}misplaced '.. experimental:: {kind}': cannot mark this "
                    f"{objtype}; use '.. experimental:: {expected}'."
                )
            else:
                desc_node["classes"].append("experimental")
            break

    # Parameters and ivar-form attributes both render as a row that *contains* the
    # marker box, so each is styled by walking *up* from the marker to its row and
    # tagging that row -- not the marker's paragraph, which also holds the
    # description and marker box as block children, so the HTML writer closes the
    # <p> early and the bar would cover only the name. The row is a `list_item`
    # when the field has several entries, or the `field_body` itself when a lone
    # entry collapses the bullet list (a single parameter, or a single `:ivar:`).
    for marker in doctree.findall(nodes.container):
        classes = marker.get("classes", [])
        if "experimental-marker-parameter" in classes:
            row_class = "experimental-param"
        elif "experimental-marker-attribute" in classes and not isinstance(marker.parent, addnodes.desc_content):
            # An `attribute` marker directly under a `desc_content` is a
            # `.. attribute::` object (already bordered by the Objects pass),
            # not an ivar row, so it is excluded above.
            row_class = "experimental-ivar"
        else:
            continue
        row = marker.parent
        while row is not None and not isinstance(row, (nodes.list_item, nodes.field_body)):
            row = row.parent
        if row is not None and row_class not in row.get("classes", []):
            row["classes"].append(row_class)


def _marker_kind(node: nodes.Element) -> str:
    """Return the API-type suffix of a marker container (e.g. ``"class"``).

    Falls back to ``"object"`` if ``node`` carries no ``experimental-marker-*``
    class (e.g. when a ``desc`` is passed instead of its marker box).

    Args:
        node: A node whose ``experimental-marker-*`` class is inspected.

    Returns:
        The API-type suffix (e.g. ``"class"``), or ``"object"`` if absent.
    """
    for cls in node.get("classes", []):
        if cls.startswith("experimental-marker-"):
            return cls[len("experimental-marker-") :]
    return "object"


def _marker_of(desc_node: addnodes.desc) -> nodes.container | None:
    """Return ``desc_node``'s own (direct-child) experimental marker, or ``None``.

    A documented object renders as a ``desc`` whose body is a ``desc_content``;
    its own marker, if any, is a *direct* child of that ``desc_content``::

        desc                 (the object)
        +-- desc_signature   (its name/signature)
        +-- desc_content     (its docstring body)
            +-- container    <- its own marker box (if any)
            +-- paragraph    (the rest of the docstring)
            +-- desc         (a nested member; its marker belongs to it)

    We look only at direct children: a marker deeper down belongs to a nested
    member or a parameter. The returned ``container`` lets callers read its API
    type and point errors at the exact ``.. experimental::`` line.

    Args:
        desc_node: The documented object's ``desc`` node.

    Returns:
        The object's own marker ``container``, or ``None`` if it has none.
    """
    contents = [n for n in desc_node.children if isinstance(n, addnodes.desc_content)]
    if not contents:
        return None
    # Scan only the direct children of the object's own docstring body.
    for child in contents[0].children:
        if isinstance(child, nodes.container) and "experimental-marker" in child.get("classes", []):
            return child
    return None


def _enclosing_experimental_object(node: nodes.Node) -> addnodes.desc | None:
    """Return the nearest ancestor ``desc`` tagged experimental, or ``None``.

    The search starts strictly *above* ``node`` (an object's own ``desc`` is not
    considered), so it answers "is this marking nested inside another experimental
    object?".

    Args:
        node: The node to search above (its own ``desc`` is not considered).

    Returns:
        The nearest experimental-tagged ancestor ``desc``, or ``None``.
    """
    current = node.parent
    while current is not None:
        if isinstance(current, addnodes.desc) and "experimental" in current.get("classes", []):
            return current
        current = current.parent
    return None


def _has_desc_ancestor(node: nodes.Node) -> bool:
    """Return ``True`` if ``node`` has an ``addnodes.desc`` ancestor.

    Used to spot a misplaced page-level ``module`` marker: legitimately it sits
    at page/body level, so a ``desc`` (documented-object) ancestor means it was
    written inside an object's docstring.

    Args:
        node: The node whose ancestry is walked.

    Returns:
        ``True`` if any ancestor is an ``addnodes.desc``.
    """
    current = node.parent
    while current is not None:
        if isinstance(current, addnodes.desc):
            return True
        current = current.parent
    return False


def _location(node: nodes.Node) -> str:
    """Return a ``"path:line: "`` prefix for ``node``.

    Hand-built because a raised error -- unlike ``logger.warning(location=...)``
    -- does not get the source location prepended automatically.

    Args:
        node: The node to locate (its or its nearest ancestor's source/line).

    Returns:
        ``"<source>:<line>: "``, ``"<source>: "``, or ``""`` if neither is known.
    """
    source, line = get_source_line(node)
    if source and line:
        return f"{source}:{line}: "
    if source:
        return f"{source}: "
    return ""


def _check_page_marker_placement(doctree: nodes.document) -> None:
    """Record a page-level (``module``/``group``) marker nested inside an object.

    Both ``module`` and ``group`` are page-level. A marker written inside a
    class/method/function docstring is misplaced: :func:`_collect_page_markings`
    ignores it for page membership, and it is recorded here as a hard error so the
    author fixes the typo -- usually a ``module``/``group`` that was meant to be
    ``class``/``method``/``function``.

    Args:
        doctree: The resolved page tree, scanned for misplaced page-level markers.
    """
    for marker in doctree.findall(nodes.container):
        if not _is_page_marker(marker):
            continue
        if not _has_desc_ancestor(marker):
            continue
        kind = _marker_kind(marker)
        _violations.append(
            f"{_location(marker)}misplaced '.. experimental:: {kind}': it appears inside an "
            f"object's documentation. '.. experimental:: {kind}' marks a whole page and belongs "
            f"at the top of a landing page or in a module docstring; for an individual API use "
            f"'.. experimental:: class' / 'method' / 'function'."
        )


def _check_redundant_markings_under_module(doctree: nodes.document, covering_page: str, covering_kind: str) -> None:
    """Record per-entry markings on a page already covered by a page-level marking.

    A ``module``/``group`` marking covers the whole page (and its toctree
    descendants), so any object/parameter marking on it is redundant. Each is
    recorded as a hard error rather than silently dropped, so a forgotten marking
    cannot resurface (possibly stale) when the page-level marking is removed. The
    page's own page-level banner is skipped here -- a redundant page-level marker
    is handled by :func:`_check_redundant_page_marker` instead.

    Args:
        doctree: The resolved page tree, scanned for per-entry markers.
        covering_page: Docname of the covering page, named in the error message.
        covering_kind: The covering marking's kind (``"module"``/``"group"``),
            used to word the message.
    """
    for marker in doctree.findall(nodes.container):
        classes = marker.get("classes", [])
        if "experimental-marker" not in classes:
            continue
        if _is_page_marker(marker):
            continue
        kind = _marker_kind(marker)
        _violations.append(
            f"{_location(marker)}conflicting experimental marking found: a {kind} and its "
            f"enclosing {covering_kind} cannot both be marked experimental "
            f"({covering_kind} marked on {covering_page})."
        )


def _check_redundant_page_marker(env: BuildEnvironment, doctree: nodes.document, covering_ancestor_page: str) -> None:
    """Record a page-level (``module``/``group``) marker already covered by an ancestor.

    A page marked ``.. experimental:: module`` **or** ``group`` is redundant when
    an ancestor page is *also* page-marked (of either kind): the ancestor's
    marking already cascades down the toctree to cover it. This is the page-level
    analog of the per-entry checks, recorded as a hard error rather than dropped
    so the redundant marker cannot mask a later change of intent. It covers all
    four ancestor/descendant combinations of ``{module, group}``.

    Args:
        env: The build environment, used to word the ancestor's marking kind.
        doctree: The resolved page tree, scanned for its own page-level marker.
        covering_ancestor_page: Docname of the covering ancestor page, named in
            the error message.
    """
    marker = next(
        (box for box in doctree.findall(nodes.container) if _is_page_marker(box) and not _has_desc_ancestor(box)),
        None,
    )
    if marker is None:
        return
    child_kind = _marker_kind(marker)
    ancestor_kind = _page_marking_kind(env, covering_ancestor_page)
    _violations.append(
        f"{_location(marker)}conflicting experimental marking found: this page is marked "
        f"'.. experimental:: {child_kind}' but an ancestor page already covers it "
        f"({ancestor_kind} marked on {covering_ancestor_page})."
    )


def _check_nested_field_rows(doctree: nodes.document, row_class: str, marker_class: str, noun: str) -> None:
    """Flag a per-row marking that is redundant because its object is already experimental.

    Scans the page for field-list rows tagged ``row_class`` (a ``:param:`` or
    ``:ivar:`` row). When such a row sits inside an object that is itself marked
    experimental, the object's marking already covers the row, so marking the row
    too is redundant and a conflict is recorded.

    For example, an experimental parameter of a function that is *also* marked
    ``.. experimental:: function`` (so ``row_class="experimental-param"``,
    ``noun="a parameter"``) yields::

        conflicting experimental marking found: a parameter and its enclosing
        function cannot both be marked experimental.

    The error is located at the row's own marker (matched by ``marker_class``),
    which carries the docstring line; the row node only maps to the generated stub.

    Args:
        doctree: The resolved page tree to scan.
        row_class: The row tag to match (e.g. ``"experimental-param"``).
        marker_class: The marker-box class inside the row (e.g.
            ``"experimental-marker-parameter"``).
        noun: The entry phrase for the message (e.g. ``"a parameter"``).
    """
    for row in doctree.findall(lambda n: isinstance(n, nodes.Element) and row_class in n.get("classes", [])):
        ancestor = _enclosing_experimental_object(row)
        if ancestor is None:
            continue
        outer = _marker_kind(_marker_of(ancestor) or ancestor)
        marker = next(
            (c for c in row.findall(nodes.container) if marker_class in c.get("classes", [])),
            row,
        )
        _violations.append(
            f"{_location(marker)}conflicting experimental marking found: {noun} and its "
            f"enclosing {outer} cannot both be marked experimental."
        )


def _apply_experimental_page(doctree: nodes.document, banner: nodes.container) -> None:
    """Render a whole page as an experimental module/group.

    The page body (everything after a leading title/subtitle) is wrapped in a
    single ``experimental-module`` element so one bar spans it, and the given
    ``banner`` is forced to the top (duplicate page-level markers are dropped).
    Passing a prebuilt banner keeps banner *wording* (deduced module name vs
    authored group text) out of this layout-only helper, so the marked page and
    all its cascaded descendants show the same banner.

    The wrapper is a docutils ``compound`` (not a ``container``) on purpose: the
    HTML writer names the ``<div>``'s class after the node, and the theme's
    bundled Bootstrap styles ``.container`` (max-width/margin/padding), which
    would fight the ``padding-left`` our ``.experimental-module`` bar relies on.
    Nothing styles ``.compound``, so the wrapper stays layout-neutral. (If a
    future theme styles ``.compound`` the only risk is cosmetic bar spacing.)

    Args:
        doctree: The resolved page tree; mutated in place to wrap the body in
            the module bar and hoist the banner to the top.
        banner: The prebuilt banner container to hoist to the top of the page.
    """
    # Reuse an existing wrapper if we somehow run twice.
    wrapper = None
    for child in doctree.children:
        if isinstance(child, nodes.compound) and "experimental-module" in child.get("classes", []):
            wrapper = child
            break

    if wrapper is None:
        wrapper = nodes.compound()
        wrapper["classes"].append("experimental-module")
        # Keep a leading title/subtitle *direct child* outside the box, so the
        # HTML writer still renders it as the page <h1> (a bare title under a
        # plain container misrenders). Note: most Sphinx pages are rooted in a
        # `section`, so their title sits inside that section and is wrapped along
        # with the body -- the page still renders correctly, the experimental bar
        # simply spans the title too. This skip only fires for the rarer case of
        # a title/subtitle promoted to a direct document child.
        body = []
        for child in list(doctree.children):
            if not body and isinstance(child, (nodes.title, nodes.subtitle)):
                continue
            body.append(child)
        for node in body:
            doctree.remove(node)
        wrapper.extend(body)
        doctree += wrapper

    # A page can end up with *two* module markers -- the same whole-module
    # marking simply authored twice for one page: once at the top of the landing
    # ``.rst`` and once in the module's own docstring (which ``automodule``
    # renders into that same page body). Being the same granularity they are
    # duplicates, not a conflict, so collapse them into a single banner: drop
    # every page-level marker (nothing else does -- the precedence checks skip
    # them) and insert the freshly-built banner at the top. Passing the banner in
    # (rather than reusing an authored marker) is what lets it name the module or
    # carry the authored group text (authored markers hold only generic wording).
    for box in list(wrapper.findall(nodes.container)):
        if _is_page_marker(box):
            box.parent.remove(box)
    wrapper.insert(0, banner)


# **********************************************************************
# PUBLIC SETUP() AND PRIMARY CALLBACKS CALLED FROM IT
# **********************************************************************


def _reset_violations(_app: Sphinx) -> None:
    """Clear collected precedence violations at the start of each build.

    The module-level :data:`_violations` list
    outlives a single build in a long-lived process (``sphinx-autobuild``, the
    test suite, repeated programmatic builds), so it must be emptied up front or
    stale entries from a previous build would fail this one.

    Args:
        _app: Part of the callback signature; unused.
    """
    _violations.clear()


def _collect_page_markings(app: Sphinx, doctree: nodes.document) -> None:
    """Record a freshly-read page's whole-page (``module``/``group``) marking.

    ``doctree`` is the page's just-parsed node tree. It is searched, at any
    depth, for a page-level marker (``module`` or ``group``) that sits *outside*
    any documented object (i.e. not inside a class/method/function block -- depth
    does not matter, only whether it is interior to such an object);
    object/parameter markers are ignored here and styled separately. When such a
    marker is found the page's docname is stored in the env-level map (mapped to
    the authored banner text for ``group``, or ``None`` for ``module``),
    otherwise the docname is removed from it. Removing on absence is what keeps
    the map correct across incremental rebuilds: if a marker is deleted from a
    page that is later re-read, ``doctree`` no longer contains it and the
    now-stale entry is dropped (see :func:`_purge_doc_page_marking` for the
    page-deleted-and-never-re-read case).

    A page-level marker that *is* nested inside an object's docstring is
    misplaced: it does not count here (so it cannot silently mark the page) and
    is recorded as a hard error later by :func:`_check_page_marker_placement`. A
    page carrying *both* a ``module`` and a ``group`` marker is contradictory;
    that conflict is recorded at resolve time (main process) by
    :func:`_apply_experimental_markings`, since violations cannot be recorded
    from this read-time handler under parallel builds.

    Args:
        app: The Sphinx application; ``app.env`` holds the map and the docname.
        doctree: The freshly read page tree, searched for a page-level marker.
    """
    env = app.env
    docname = env.docname
    docs = _get_page_markings(env)
    group_label: str | None = None
    has_module = False
    for c in doctree.findall(nodes.container):
        if _has_desc_ancestor(c) or not _is_page_marker(c):
            continue
        if _marker_kind(c) == "group":
            group_label = c.get("experimental_label", "")
        else:
            has_module = True
    if group_label is not None:
        # A group (even alongside a stray module marker, which resolve-time flags
        # as a conflict) stores its authored banner text.
        docs[docname] = group_label
    elif has_module:
        docs[docname] = None
    else:
        docs.pop(docname, None)  # keep correct across incremental rebuilds


def _purge_doc_page_marking(_app: Sphinx, env: BuildEnvironment, docname: str) -> None:
    """Drop ``docname`` from the whole-page-marking map.

    Sphinx caches the build environment between runs (it is pickled and
    reloaded), so the map of whole-page markings outlives a single build. Sphinx
    calls this whenever a document's cached data must be discarded: when its
    source file is deleted, or just before a changed file is re-read. Either way
    we remove ``docname`` so a marking recorded on a previous build cannot linger.

    The deletion case is the one that *requires* this handler:
    :func:`_collect_page_markings` re-evaluates a page only when it is read, so a
    deleted page (never read again) would otherwise keep its stale entry forever.
    For a changed page this clears the old entry just before
    :func:`_collect_page_markings` re-adds it if the marker is still there.

    Args:
        _app: Part of the callback signature; unused.
        env: The build environment holding the map ``docname`` is removed from.
        docname: The document whose cached marking is being discarded.
    """
    _get_page_markings(env).pop(docname, None)


def _merge_page_markings(_app: Sphinx, env: BuildEnvironment, _docnames: set[str], other: BuildEnvironment) -> None:
    """Fold a parallel-read worker's findings into the main env.

    Under parallel reads each worker subprocess populates its *own* copy of the
    map as it reads its subset of docs. When a worker finishes, Sphinx calls this
    in the main process with ``other`` being the worker's env; we merge its map
    into the main one so markings discovered in subprocesses survive instead of
    being discarded when the worker exits.

    Args:
        _app: Part of the callback signature; unused.
        env: The main process's build environment to merge into.
        _docnames: The docs read by the finished worker; unused.
        other: The finished worker's build environment to merge from.
    """
    _get_page_markings(env).update(_get_page_markings(other))


def _apply_experimental_markings(app: Sphinx, doctree: nodes.document, docname: str) -> None:
    """Style and validate one page's experimental markings.

    Runs after the tree is built and references resolved, so traversal/mutation
    are safe. Two stages:

    1. tag every experimental object and parameter -- this is what renders
       the object border, marker box, and parameter highlight.
    2. enforce precedence (``module/group > class > method/function >
       parameter``; see the module docstring). A marking nested inside a
       higher-precedence one is redundant and recorded as a hard error (collected
       in :data:`_violations` and raised at the end of the build):

       * On a whole-page (``module``/``group``) page, every per-entry marking is
         redundant; record it, apply the page-wide treatment, and return. If the
         page carries its own page-level marker yet an ancestor page already
         covers it through the toctree, that marker is redundant too and is
         recorded.
       * Otherwise, record any object/parameter/attribute marking nested inside
         another experimental object.

    Between the two stages it also records a misplaced page-level marker (one
    written inside an object's documentation) and a page carrying both a
    ``module`` and a ``group`` marker, each as a hard error.

    Args:
        app: The Sphinx application; ``app.env`` supplies the page-marking map.
        doctree: The resolved page tree, tagged and validated in place.
        docname: The page's docname, used to test page coverage.
    """
    # Stage 1: tag experimental objects and parameters (this renders the markings).
    _tag_experimental_objects_and_params(doctree)

    # A page-level marker must be page-level; record any nested inside an object.
    _check_page_marker_placement(doctree)

    # A page cannot carry both a `module` and a `group` marker (deduced name vs
    # authored text are contradictory). Recorded here at resolve time (main
    # process), which the read-time collector cannot do under parallel builds.
    page_kinds = {_marker_kind(c) for c in doctree.findall(nodes.container) if _is_page_marker(c) and not _has_desc_ancestor(c)}
    if "module" in page_kinds and "group" in page_kinds:
        first = next(c for c in doctree.findall(nodes.container) if _is_page_marker(c) and not _has_desc_ancestor(c))
        _violations.append(
            f"{_location(first)}conflicting experimental marking found: a page cannot carry both "
            f"'.. experimental:: module' and '.. experimental:: group'."
        )

    # Stage 2: enforce precedence by recording redundant markings.
    #
    # Case A -- a whole-page marking (module/group) covers this page (its own
    # marker, or an ancestor page's via the toctree). It covers everything on the
    # page, so every per-entry marking on it is redundant against that marking.
    covering_page = _find_covering_page(app.env, docname)
    if covering_page is not None:
        covering_kind = _page_marking_kind(app.env, covering_page)
        # The page is its own cover only when it carries its own page-level
        # marker; if an ancestor page also covers it, that marker is redundant.
        if covering_page == docname:
            ancestor_page = _find_covering_page(app.env, docname, include_self=False)
            if ancestor_page is not None:
                _check_redundant_page_marker(app.env, doctree, ancestor_page)
        _check_redundant_markings_under_module(doctree, covering_page, covering_kind)

        # Build the banner once for the covering page and reuse it on every
        # cascaded descendant so they all show the same label. A `group` uses its
        # authored text; a `module` deduces its name (warning + generic wording
        # when it can't be deduced).
        label = _get_page_markings(app.env).get(covering_page)
        if isinstance(label, str):
            banner = _make_group_banner(label)
        else:
            modname, reason = _deduce_module_name(app.env, covering_page)
            if modname is None and docname == covering_page:
                logger.warning(
                    f"'.. experimental:: module' banner uses the generic wording: {reason}.",
                    location=docname,
                    type="experimental",
                    subtype="module_name",
                )
            banner = _make_module_banner(modname)
        _apply_experimental_page(doctree, banner)
        return

    # Case B -- no page-level marking covers the page, so a marking is redundant
    # only when nested inside another experimental *object* on the page (the finer-grained
    # precedence: a class covers its methods/parameters, a function its parameters,
    # etc.). The three nestable forms carry different tags, so each is scanned
    # separately: `experimental` on a `desc` (this also covers an attribute written
    # as a `.. attribute::`), and `experimental-param` / `experimental-ivar` on the
    # field-list rows.
    for desc_node in doctree.findall(addnodes.desc):
        if "experimental" not in desc_node.get("classes", []):
            continue
        ancestor = _enclosing_experimental_object(desc_node)
        if ancestor is None:
            continue
        marker = _marker_of(desc_node) or desc_node
        inner = _marker_kind(marker)
        outer = _marker_kind(_marker_of(ancestor) or ancestor)
        _violations.append(
            f"{_location(marker)}conflicting experimental marking found: a {inner} and its "
            f"enclosing {outer} cannot both be marked experimental."
        )
    _check_nested_field_rows(doctree, "experimental-param", "experimental-marker-parameter", "a parameter")
    _check_nested_field_rows(doctree, "experimental-ivar", "experimental-marker-attribute", "an attribute")


def _copy_css(app: Sphinx, exc: Exception | None) -> None:
    """Copy the bundled stylesheet into the build output's ``_static`` dir.

    Shipping the CSS with the extension lets both the docs and sandbox builds
    pick it up without each source tree needing its own copy in
    ``html_static_path``.

    Args:
        app: The Sphinx application (provides the builder, its format, and the
            output directory).
        exc: The build's exception if it failed, else ``None``; the copy is
            skipped on a failed or non-HTML build.
    """
    if exc is None and app.builder.format == "html":
        static_dir = os.path.join(app.builder.outdir, "_static")
        os.makedirs(static_dir, exist_ok=True)
        copy_asset_file(os.path.join(os.path.dirname(__file__), CSS_FILE), static_dir)


def _raise_collected_violations(_app: Sphinx, exc: Exception | None) -> None:
    """Fail the build if any precedence violations were recorded.

    Args:
        _app: Part of the callback signature; unused.
        exc: The build's exception if it already failed, else ``None``. When set
            we stay silent: the build is failing anyway, and this handler is
            re-invoked with the very error we raise -- so this guard also
            stops us from re-raising in that second pass.

    Raises:
        ExperimentalMarkingError: If violations were recorded on a build that
            otherwise succeeded; one entry is raised as-is, several are listed.
    """
    if exc is not None or not _violations:
        return
    if len(_violations) == 1:
        raise ExperimentalMarkingError(_violations[0])
    listing = "\n".join(f"  - {v}" for v in _violations)
    raise ExperimentalMarkingError(f"{len(_violations)} experimental marking errors found:\n{listing}")


def setup(app: Sphinx) -> dict[str, bool]:
    """Register the directive, event handlers, and stylesheet with Sphinx.

    This is called once at import time, and the purpose is to register callbacks.
    Each registered piece documents its own timing and role.
    The one ordering constraint that matters is that whole-page (module/group)
    markings are gathered on ``doctree-read``, before the resolve phase, because
    the marking cascades down the toctree and resolve order is not parent-first,
    so the full marked-page map and toctree graph must be in hand before any page
    is styled.

    Args:
        app: The Sphinx application to register on.

    Returns:
        Metadata declaring the extension safe under parallel read/write.
    """
    app.add_directive("experimental", ExperimentalDirective)
    app.connect("builder-inited", _reset_violations)
    app.connect("doctree-read", _collect_page_markings)
    app.connect("env-purge-doc", _purge_doc_page_marking)
    app.connect("env-merge-info", _merge_page_markings)
    app.connect("doctree-resolved", _apply_experimental_markings)

    # `add_css_file` only adds the <link> to each HTML page,
    # while `_copy_css` delivers the actual file into the output's `_static`.
    app.add_css_file(CSS_FILE)  #
    app.connect("build-finished", _copy_css)

    app.connect("build-finished", _raise_collected_violations)
    return {"parallel_read_safe": True, "parallel_write_safe": True}
