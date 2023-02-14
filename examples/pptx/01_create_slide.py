from pptx import Presentation
from pptx.util import Pt

prs = Presentation()
bullet_slide_layout = prs.slide_layouts[1]

slide = prs.slides.add_slide(bullet_slide_layout)
shapes = slide.shapes

title_shape = shapes.title
body_shape = shapes.placeholders[1]

title_shape.text = 'Adding a Bullet Slide'

tf = body_shape.text_frame
tf.text = 'Find the bullet slide layout'
# tf.paragraphs[0].text = 'Find the bullet slide layout'
p = tf.paragraphs[0]
# p.level = 0
# p.text = 'Start'
run = p.runs[0]
# run = p.add_run()
run.text = 'XXXX'
font = run.font
font.italic = True


run = p.add_run()
run.text = 'Spam, eggs, and spam'

font = run.font
font.name = 'Consolas'
# font.bold = True
# font.italic = None  # cause value to be inherited from theme
# font.color.theme_color = MSO_THEME_COLOR.ACCENT_1

run = p.add_run()
run.text = 'After'


p = tf.add_paragraph()
p.text = 'Use _TextFrame.text for first bullet'
p.level = 0
#
# p = tf.add_paragraph()
# p.text = 'Use _TextFrame.add_paragraph() for subsequent bullets'
# p.level = 2

prs.save('demo.pptx')
