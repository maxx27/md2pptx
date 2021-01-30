import argparse
import sys
import markdown
import pptx


def main():
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('--input', required=True, help='Markdown file')
    arg_parser.add_argument('--output', help='Output file')
    arg_parser.add_argument('--layout', type=int, default=1, help='Number of layout (starting with 1)')
    # default encoding for files?
    args = arg_parser.parse_args()

    md_parser = markdown.Parser()
    dom = md_parser.parse(args.input)
    pptx_composer = pptx.Composer()
    pptx_composer.compose(args.output, dom)


if __name__ == '__main__':
    sys.exit(main())
