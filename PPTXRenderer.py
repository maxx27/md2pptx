from enum import Enum
from marko.renderer import Renderer
import marko.block
# from marko.helpers import camel_to_snake_case
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

    def _on_next_pres(self):
        self.slide = None
        self.pres = pptx.Presentation()

    def _on_next_slide(self):
        title_slide_layout = self.pres.slide_layouts[0]
        self.slide = self.pres.slides.add_slide(title_slide_layout)

    def render_children(self, element):
        # For debug purpose: not to miss something
        raise TypeError(f'Unknown type {element.__class__}')

    def render_heading(self, element):
        self.state = self.State.ST_NEXT_SLIDE
        self._on_next_slide()
        assert len(element.children) == 1
        self.slide.shapes.title.text = element.children[0].children

    def render_document(self, element):
        self.state = self.State.ST_NEXT_PRES
        self._on_next_pres()
        self.indent = 0
        self.state = self.State.ST_NEXT_SLIDE
        for child in getattr(element, "children", None):
            self.render(child)
