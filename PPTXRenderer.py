from marko.renderer import Renderer
from marko.block import BlockElement
# from marko.helpers import camel_to_snake_case
import pptx


class PPTXRenderer(Renderer):
    def __init__(self):
        self.pres = None

    # def __enter__(self):
    #     return super().__enter__()

    # def __exit__(self, *args):
    #     return super().__exit__(*args)

    def setup(self, pathname: str = None):
        self.pres = pptx.Presentation()
        self.indent = -1

    def render_children(self, element):
        # if element is self.root_node:
        #     self.pres = pptx.Presentation()
        # element_name = camel_to_snake_case(element.__class__.__name__)
        for item in getattr(element, "children", None):
            self.indent += 1
            self._render_item(item)
            self.indent -= 1

    def _render_item(self, item: BlockElement):
        raise TypeError(f'Unknown type {item.__class__}')
