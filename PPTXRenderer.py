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

    def setup(self):
        self.indent = -1
        self.state = self.State.ST_NEXT_PRES
        self._on_next_pres()
        self.state = self.State.ST_NEXT_SLIDE

    def _on_next_pres(self):
        self.slide = None
        self.pres = pptx.Presentation()

    def _on_next_slide(self):
        title_slide_layout = self.pres.slide_layouts[0]
        self.slide = self.pres.slides.add_slide(title_slide_layout)

    def render_children(self, element):
        # if element is self.root_node:
        #     self.pres = pptx.Presentation()
        # element_name = camel_to_snake_case(element.__class__.__name__)
        for item in getattr(element, "children", None):
            self.indent += 1
            self._render_item(item)
            self.indent -= 1

    def _render_item(self, item: marko.block.BlockElement):
        if self.state == self.State.ST_NEXT_SLIDE:
            if isinstance(item, marko.block.Heading):
                return self._render_heading(item)
        raise TypeError(f'Unknown type {item.__class__}')

    def _render_heading(self, item):
        self.state = self.State.ST_NEXT_SLIDE
        self._on_next_slide()
        assert len(item.children) == 1
        self.slide.shapes.title.text = item.children[0].children
