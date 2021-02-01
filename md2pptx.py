import argparse
import os
import sys
import marko
import marko.ext.footnote
import PPTXRenderer


def main():
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('--input', required=True, help='Markdown file')
    arg_parser.add_argument('--output', help='Output file')
    arg_parser.add_argument('--layout', type=int, default=1, help='Number of layout (starting with 1)')
    # default encoding for files?
    # TODO: calculate output if not specified
    args = arg_parser.parse_args()

    if not os.path.isfile(args.input):
        raise RuntimeError(f'File {args.input} does not exist or not a file')
    f = open(args.input, 'r', encoding='utf-8')
    md_text = f.read()
    f.close()
    md = marko.Markdown(renderer=PPTXRenderer.PPTXRenderer)
    # md = marko.Markdown(renderer=PPTXRenderer.PPTXRenderer, extensions=[marko.ext.footnote.Footnote])
    parsed = md.parse(md_text)  # md.renderer is created during parse
    # md.renderer.setup(template_filename='c:/Work/Trainings/Kubernetes.Suslov/Информация по курсу/ADM-021_Kubernetes_Fundamentals_Eng.pptm',
    #                   default_layout=11)
    md.render(parsed)
    # TODO: create an output folder if not exists
    # save extention as original or warn
    md.renderer.pres.save(args.output)


if __name__ == '__main__':
    sys.exit(main())
