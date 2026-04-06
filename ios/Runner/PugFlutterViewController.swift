import Flutter
import UIKit

final class PugFlutterViewController: FlutterViewController {
  override var prefersHomeIndicatorAutoHidden: Bool {
    true
  }

  override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
    .bottom
  }
}
