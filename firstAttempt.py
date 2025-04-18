import sys
from PyQt5.QtWidgets import QApplication, QWidget, QColorDialog
from PyQt5.QtGui import QPainter, QPen, QPixmap, QTabletEvent, QColor
from PyQt5.QtCore import Qt

class TabletWidget(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("GAOMON Tablet Drawing with Pressure & Live Color Picker")
        self.setGeometry(100, 100, 1000, 700)

        self.canvas = QPixmap(self.size())
        self.canvas.fill(Qt.white)

        self.last_pos = None
        self.pen_color = QColor(0, 0, 0)  # Start with black

        # Create a permanently open color picker window
        self.color_dialog = QColorDialog(self.pen_color, self)
        self.color_dialog.setOption(QColorDialog.ShowAlphaChannel, False)
        self.color_dialog.setWindowTitle("Color Picker")
        self.color_dialog.show()

        # Update color whenever user picks a new one
        self.color_dialog.currentColorChanged.connect(self.set_pen_color)

    def set_pen_color(self, color):
        self.pen_color = color
        print(f"🎨 Color selected: RGB({color.red()}, {color.green()}, {color.blue()})")

    def tabletEvent(self, event: QTabletEvent):
        pos = event.pos()
        pressure = event.pressure()
        rgb = (self.pen_color.red(), self.pen_color.green(), self.pen_color.blue())

        print(f"🖊️ Position: ({pos.x()}, {pos.y()}), Pressure: {pressure:.3f}, Color: RGB{rgb}")

        if event.type() == QTabletEvent.TabletPress:
            self.last_pos = pos

        elif event.type() == QTabletEvent.TabletMove and self.last_pos is not None:
            painter = QPainter(self.canvas)
            pen = QPen(self.pen_color, pressure * 10)
            pen.setCapStyle(Qt.RoundCap)
            painter.setPen(pen)
            painter.drawLine(self.last_pos, pos)

            self.last_pos = pos
            self.update()

        elif event.type() == QTabletEvent.TabletRelease:
            self.last_pos = None

        event.accept()

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.drawPixmap(0, 0, self.canvas)

    def resizeEvent(self, event):
        new_canvas = QPixmap(self.size())
        new_canvas.fill(Qt.white)
        painter = QPainter(new_canvas)
        painter.drawPixmap(0, 0, self.canvas)
        self.canvas = new_canvas

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = TabletWidget()
    window.show()
    sys.exit(app.exec_())
