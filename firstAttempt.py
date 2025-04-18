import sys
from PyQt5.QtWidgets import QApplication, QWidget
from PyQt5.QtGui import QPainter, QPen, QPixmap, QTabletEvent
from PyQt5.QtCore import Qt

class TabletWidget(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("GAOMONgit push -u origin main Tablet Drawing with Pressure")
        self.setGeometry(100, 100, 800, 600)

        self.canvas = QPixmap(self.size())
        self.canvas.fill(Qt.white)

        self.last_pos = None

    def tabletEvent(self, event: QTabletEvent):
        pos = event.pos()
        pressure = event.pressure()

        # Log pressure and position to console
        print(f"Position: ({pos.x()}, {pos.y()}), Pressure: {pressure:.3f}")

        if event.type() == QTabletEvent.TabletPress:
            self.last_pos = pos

        elif event.type() == QTabletEvent.TabletMove and self.last_pos is not None:
            painter = QPainter(self.canvas)
            pen = QPen(Qt.black, pressure * 10)  # pressure controls thickness
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

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = TabletWidget()
    window.show()
    sys.exit(app.exec_())