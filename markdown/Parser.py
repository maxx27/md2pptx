import os

import dom.Deck


class Parser:

    def __init__(self):
        pass

    def parse(self, filename: str) -> dom.Deck:
        if not os.path.isfile(filename):
            raise RuntimeError(f'File {filename} does not exist or not a file')
        md_file = open(filename, 'r')
        # TODO: How to parse MD?
        md_file.close()
