import QtQuick  
import Quickshell.Hyprland

Item {  
    id: root

    property var monitor: Hyprland.focusedMonitor
    property var workspace: monitor?.activeWorkspace
    property var windows: workspace?.toplevels ?? []

    signal checkHover(real mouseX, real mouseY)
    signal regionSelected(real x, real y, real width, real height)  
      
    // Shader customization properties  
    property real dimOpacity: 0.6  
    property real borderRadius: 10.0  
    property real outlineThickness: 2.0  
    property url fragmentShader: Qt.resolvedUrl("dimming.frag.qsb")  
      
    property point startPos  
    property real selectionX: 0  
    property real selectionY: 0  
    property real selectionWidth: 0  
    property real selectionHeight: 0  
      
    Behavior on selectionX { SpringAnimation { spring: 4; damping: 0.4 } }  
    Behavior on selectionY { SpringAnimation { spring: 4; damping: 0.4 } }  
    Behavior on selectionHeight { SpringAnimation { spring: 4; damping: 0.4 } }  
    Behavior on selectionWidth { SpringAnimation { spring: 4; damping: 0.4 } }  
      
    // Shader overlay  
    ShaderEffect {  
        anchors.fill: parent  
        z: 0  
          
        property vector4d selectionRect: Qt.vector4d(  
            root.selectionX,  
            root.selectionY,  
            root.selectionWidth,  
            root.selectionHeight  
        )  
        property real dimOpacity: root.dimOpacity  
        property vector2d screenSize: Qt.vector2d(root.width, root.height)  
        property real borderRadius: root.borderRadius  
        property real outlineThickness: root.outlineThickness  
          
        fragmentShader: root.fragmentShader  
    }  

    Repeater {
        model: root.windows

        Item {
            required property var modelData

            Connections {
                target: root

                function onCheckHover(mouseX, mouseY) {
                    const monitorX = root.monitor.lastIpcObject.x
                    const monitorY = root.monitor.lastIpcObject.y
                    
                    const windowX = modelData.lastIpcObject.at[0] - monitorX
                    const windowY = modelData.lastIpcObject.at[1] - monitorY
                    
                    const width = modelData.lastIpcObject.size[0]
                    const height = modelData.lastIpcObject.size[1]

                    if (mouseX >= windowX && mouseX <= windowX + width && mouseY >= windowY && mouseY <= windowY + height) {
                        selectionX = windowX
                        selectionY = windowY
                        selectionWidth = width
                        selectionHeight = height
                    }
                }
            }
        }
    }
      
    MouseArea {  
        id: mouseArea  
        anchors.fill: parent  
        z: 3
        hoverEnabled: true
          
        onPositionChanged: (mouse) => { 
            root.checkHover(mouse.x, mouse.y)
        }  
          
        onReleased: (mouse) => {  
            if (mouse.x >= root.selectionX && mouse.x <= root.selectionX + root.selectionWidth &&
                mouse.y >= root.selectionY && mouse.y <= root.selectionY + root.selectionHeight) {
                root.regionSelected(  
                    Math.round(root.selectionX),  
                    Math.round(root.selectionY),  
                    Math.round(root.selectionWidth),  
                    Math.round(root.selectionHeight)  
                )  
            }
        }  
    }  
}
