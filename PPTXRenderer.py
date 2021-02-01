from enum import Enum
from marko.renderer import Renderer
import marko.block
import re
import pptx


class PPTXRenderer(Renderer):

    class State(Enum):
        ST_NEXT_PRES = 0
        ST_NEXT_SLIDE = 1

    def __init__(self):
        self.pres = None
        self.indent = None
        self.state = None
        self.slide = None
        self.text_frame = None
        self.paragraph = None
        self.template_filename = None
        self.default_layout = 1  # for default template

    def setup(self, template_filename: str, default_layout: int) -> None:
        self.template_filename = template_filename
        self.default_layout = default_layout

    def on_next_pres(self):
        if self.template_filename:
            self.pres = pptx.Presentation(self.template_filename)
        else:
            self.pres = pptx.Presentation()

    def on_next_slide(self):
        title_slide_layout = self.pres.slide_layouts[self.default_layout]
        self.slide = self.pres.slides.add_slide(title_slide_layout)
        self.text_frame = self.slide.placeholders[1].text_frame
        self.paragraph = self.text_frame.paragraphs[0]
        self.indent = 0

    def render_document(self, element):
        self.state = self.State.ST_NEXT_PRES
        self.on_next_pres()
        self.state = self.State.ST_NEXT_SLIDE
        self.render_children_helper(element)

    def render_heading(self, element):
        self.state = self.State.ST_NEXT_SLIDE
        self.on_next_slide()
        assert len(element.children) == 1
        self.slide.shapes.title.text = element.children[0].children

    def render_blank_line(self, element):
        # Do nothing
        pass

    def render_paragraph(self, element):
        # Special case: if this is first paragraph, then no need to create another one
        if self.paragraph != self.text_frame.paragraphs[0]:
            self.paragraph = self.text_frame.add_paragraph()
            self.paragraph.level = self.indent

        self.render_children_helper(element)
        # TODO: need to take into account element._tight ?

    def render_raw_text(self, element):
        self.paragraph.text += element.children

    def render_code_span(self, element):
        """Inline code"""
        self.paragraph.text += f'`{element.children}`'

    def render_html_block(self, element):
        match = re.search(r'<!--(.*?)-->\n?', element.children)
        if match:
            assert len(match.groups("1")) == 1
            self.slide.notes_slide.notes_text_frame.text += match.groups("1")[0].strip() + '\n'
            return
        raise RuntimeError(f'Unexpected html block: {element.children}')

    def render_list(self, element):
        self.indent += 1
        self.render_children_helper(element)
        self.indent += 1

    def render_list_item(self, element):
        self.render_children_helper(element)

    def render_children_helper(self, element):
        for child in getattr(element, "children", None):
            self.render(child)

    def render_children(self, element):
        # For debug purpose: not to miss something
        raise TypeError(f'Unknown type {element.__class__}')
