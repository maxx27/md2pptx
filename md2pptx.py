import argparse
import os
import sys
import marko
import marko.ext.footnote
import PPTXRenderer


def main():
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('--input-file', required=True, help='Input markdown file')
    arg_parser.add_argument('--output-file', help='Output powerpoint file')
    arg_parser.add_argument('--input-encoding', type=str, default='utf-8', help='Encoding of input file')
    arg_parser.add_argument('--template-file', type=str, default=None, help='Powerpoint file as template')
    arg_parser.add_argument('--layout-number', type=int, default=1, help='Number of layout (starting with 1)')
    # TODO: calculate output if not specified
    args = arg_parser.parse_args()

    if not os.path.isfile(args.input_file):
        raise RuntimeError(f'File {args.input_file} does not exist or not a file')
    f = open(args.input_file, 'r', encoding=args.input_encoding)
    md_text = f.read()
    f.close()
    md = marko.Markdown(renderer=PPTXRenderer.PPTXRenderer)
    # md = marko.Markdown(renderer=PPTXRenderer.PPTXRenderer, extensions=[marko.ext.footnote.Footnote])
    parsed = md.parse(md_text)  # md.renderer is created during parse
    folder = os.path.abspath(os.path.dirname(args.input_file))
    md.renderer.setup(template_filename=args.template_file, default_layout=args.layout_number-1, folder=folder)
    md.render(parsed)
    # TODO: create an output folder if not exists
    # save extention as original or warn
    md.renderer.pres.save(args.output_file)


if __name__ == '__main__':
    sys.exit(main())
