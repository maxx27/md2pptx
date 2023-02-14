#!/bin/bash -e

# v2023.02.14

function most_recent {
    local dir="$1"
    local result="$2"

    local output=$(find "$dir" -exec stat --format '%Y :%n' {} \; | sort -r | head -n 1 | cut -d: -f2-)
    # local output=$(rg --files "$dir" -0 | xargs -0r stat --format '%Y :%n' | sort -nr | cut -d: -f2- | head -n 1)
    eval $result="'$output'"
}

function need_generate {
    local source_dir="$1"
    local target_file="$2"

    if [ ! -e "$source_dir" ]; then
        echo ERROR: missing source directory $source_dir
        exit 1
    fi

    # YES, target file is missing
    [ ! -e "$target_file" ] && return 0

    # find the newest file in the source directory
    local source_file
    most_recent "$source_dir" source_file

    # NO, there is no source file, nothing to regenerate
    [ -z "$source_file" ] && return 1

    # YES, source file is newest than target file
    [ "$source_file" -nt "$target_file" ] && return 0

    # NO
    return 1
}

function skip_md_file {
    local name="$1"
    [[ "$name" =~ _draft ]] && return 0
    [[ "$name" =~ _disabled ]] && return 0
    [[ "$name" =~ old ]] && return 0
    [[ "$name" =~ X[0-9]?.\  ]] && return 0
    return 1
}

function skip_image_file {
    local name="$1"
    [[ "$name" =~ _draft ]] && return 0
    [[ "$name" =~ _original ]] && return 0
    [[ "$name" =~ \(original\) ]] && return 0
    return 1
}

function setup_none {
    suffix=
}

function setup_light {
    suffix=
}

function setup_dark {
    suffix=-dark
}

function generate_markdown_none {
    cat <<EOF > "$outmarkdown"
EOF
}

function generate_markdown_light {
    cat <<EOF > "$outmarkdown"
---
marp: true
headingDivider: 3
paginate: true
---
EOF
}

function generate_markdown_dark {
    cat <<EOF > "$outmarkdown"
---
marp: true
headingDivider: 3
class: invert
paginate: true
---
EOF
}

function generate_markdown {
    generate_markdown_$theme

    # merge files (except those contains "_draft" and "X.")
    find "$inputdir" -maxdepth 1 -path "$inputdir/Practice" -prune -o -type f -name "*.md" -print0 | sort -z | while IFS= read -r -d '' file; do
        skip_md_file "$file" && echo "skip $file" && continue
        echo processing $file
        cat "$file" | \
        perl -ne 'BEGIN {$/=undef}; s/<!--(SKIP|TODO).*?-->//sg; print' | \
        perl -ne 'BEGIN {$/=undef}; s/---\r?\nmarp.*?---\r?\n//sg; print' | \
        cat >> "$outmarkdown"
        # some files may not have empty line at the end
        echo >> "$outmarkdown"
    done

    # change type of code snippets for dark theme to look better
    if [ "$theme" == dark ]; then
        perl -i -p -e 's/```(python|yaml|console|bash|dockerfile|xml|json|ini)/```text/g' "$outmarkdown"
    fi

    # TODO:
    # perl -i -p -e 's/\[==stop-here==\]//s' "$outmarkdown"
}

function generate_output_html {
    npm_config_yes=true npx \@marp-team/marp-cli --stdin=false --allow-local-files -o "$2" "$1"
}

function generate_output_pdf {
    npm_config_yes=true npx \@marp-team/marp-cli --stdin=false --allow-local-files -o "$2" "$1"
}

function generate_output_pptx {
    # TODO: avoid hardcoding
    # as draft slides
    python ${md2pptx_dir}/md2pptx.py \
        --input-file "$1" \
        --output-file "$2" \
        --template-file "pptx/dxc_template.pptx" \
        --template-file "/c/Work/TC/Trainings/My/pptx_template/dxc_template.pptx" \
        --layout-number 12 \
        --clean-content
    # as slides
    # npx \@marp-team/marp-cli --stdin=false --allow-local-files -o "$2" "$1"
}

function generate_output_docx {
    local rpath=$(dirname "$2")
    local ref
    if [ -n "$referencedoc" ]; then
        ref="--reference-doc $referencedoc"
    fi
    pandoc \
        --standalone \
        --variable pointsize:14p \
        -f markdown+smart \
        -t docx \
        --resource-path "$rpath" \
        $ref \
        -o "$2" \
        "$1"
}

function copy_images {
    local inputdir="$1"
    local outputdir="$2"

    for ext in png svg jpeg jpg gif; do
        # TODO: -maxdepth 1
        find "$inputdir" -path "$inputdir/Practice" -prune -o -type f -name "*.$ext" -print0 | while IFS= read -r -d '' file; do
            skip_image_file "$file" && echo "skip $file" && continue
            echo copy $file
            # keep images in relative paths
            imagedir=${file#$inputdir/}
            imagedir=$(dirname "$imagedir")
            mkdir -p "$outputdir/$imagedir"
            cp "$file" "$outputdir/$imagedir"
            # keep images in single foler
            # cp "$file" "$outputdir"
        done
    done
}

#=============================

outputdir=output
declare -A formats
declare -A themes

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--in-dir) inputdir="$2"; shift ;;
        -o|--out-dir) outputdir="$2"; shift ;;
        -n|--name) chaptername="$2"; shift ;;
        -f|--format) formats["$2"]=1; shift ;;
        -t|--theme) themes["$2"]=1; shift ;;
        -r|--reference-docx) referencedoc="$2"; shift ;;
        # -u|--uglify) uglify=1 ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [[ -z "$inputdir" ]]; then
    # TODO: make -maxdepth as parameter
    echo Usage: generate.sh --in-dir DIR [--out-dir DIR] [--name NAME] [--format FORMAT] [--theme THEME]
    exit 1
fi

if [ -z "$chaptername" ]; then
    chapter=$(basename "$inputdir")
    chaptername=${chapter// /_}
    chaptername=${chaptername//._/_}
fi

if [[ ! "$inputdir" =~ ^([[:digit:]]+) ]]; then
    echo "Unable to find chapter number"
    exit 1
fi
chapternumber="${BASH_REMATCH[1]}"

if [ "${#formats[@]}" -eq 0 ]; then
    formats=( [html]=1 [pdf]=1 )
fi

if [ "${#themes[@]}" -eq 0 ]; then
    themes=( [dark]=1 [light]=1 )
fi

echo "in-dir    : $inputdir"
echo "out-dir   : $outputdir"
echo "name      : $chaptername"
echo "number    : $chapternumber"
echo "formats   : ${!formats[@]}"
echo "themes    : ${!themes[@]}"
echo "reference : $referencedoc"
echo

#=============================

# scriptdir=$(readlink -f "$0")
# scriptdir=$(dirname "$scriptdir")
# scriptdir=$(readlink -f "$scriptdir/..")
# cd "$scriptdir"


if [ -n "${formats[pptx]}" ]; then
    # TODO: avoid hardcoding
    # md2pptx_dir=/c/Work/TC/Trainings/My/md2pptx
    md2pptx_dir=/c/Data/Projects/Python/md2pptx
    source ${md2pptx_dir}/venv/Scripts/activate
fi

mkdir -p "$outputdir"

for theme in "${!themes[@]}"; do
    echo "theme $theme"
    setup_$theme
    outmarkdown="$outputdir/$chaptername$suffix.md"
    if need_generate "$inputdir" "$outmarkdown"; then
        generate_markdown
        copy_images "$inputdir" "$outputdir"
    else
        echo no changes at $inputdir
    fi


    if [ -n "${formats[html]}" ] && need_generate "$outmarkdown" "$outputdir/$chaptername$suffix.html"; then
        echo generating HTML files...
        generate_output_html "$outmarkdown" "$outputdir/$chaptername$suffix.html"
    fi

    if [ -n "${formats[pdf]}" ] && need_generate "$outmarkdown" "$outputdir/$chaptername$suffix.pdf"; then
        echo generating PDF files...
        generate_output_pdf "$outmarkdown" "$outputdir/$chaptername$suffix.pdf"
    fi

    if [ -n "${formats[pptx]}" ] && need_generate "$outmarkdown" "$outputdir/$chaptername$suffix.pptx"; then
        echo generating PPTX files...
        generate_output_pptx "$outmarkdown" "$outputdir/$chaptername$suffix.pptx"
    fi

    if [ -n "${formats[docx]}" ] && need_generate "$outmarkdown" "$outputdir/$chaptername$suffix.docx"; then
        echo generating DOCX files...
        generate_output_docx "$outmarkdown" "$outputdir/$chaptername$suffix.docx"
    fi
done

# Sberbank specific
# TODO: Get rid of this
if [ -e "$inputdir/Practice" ]; then
    echo
    echo generating practice files...
    mkdir -p "$outputdir/Practice"

    find "$inputdir/Practice" -type f -name "*.md" -print0 | sort -z | while IFS= read -r -d '' file; do
        skip_md_file "$file" && echo "skip $file" && continue
        newname=$outputdir/Practice/$chapternumber.$(basename "$file")

        if ! need_generate "$file" "$newname"; then
            echo no changes at "$file"
            continue
        fi

        echo processing $file
        cp "$file" "$newname"
        newname_docx="${newname%.md}.docx"
        generate_output_docx "$file" "$newname_docx"
    done

    copy_images "$inputdir/Practice" "$outputdir/Practice"
fi
