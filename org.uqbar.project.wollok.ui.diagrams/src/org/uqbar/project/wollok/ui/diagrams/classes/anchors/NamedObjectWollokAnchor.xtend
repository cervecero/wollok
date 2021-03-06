package org.uqbar.project.wollok.ui.diagrams.classes.anchors

import org.eclipse.draw2d.IFigure

/**
 * Specific anchor for Objects.
 * Connector should begin at middle-bottom, like this
 * 
 *         _____________             _____________
 *        |             |           |             |
 *         -------------             -------------
 *               |                         ^
 *               |                         |
 *               ---------------------------
 * 
 * 
 * Thanks to Javi & https://books.google.com.ar/books?id=GiKTAR9M-L4C&pg=PA70&lpg=PA70&dq=chopboxanchor+connection&source=bl&ots=3FnJ0ifwyQ&sig=gQyaXEFpD-JQuYFsNcRJeGWR0Bw&hl=es&sa=X&ved=0ahUKEwiL5JCskYjOAhUHjJAKHbN_CLMQ6AEIOjAE#v=onepage&q=chopboxanchor%20connection&f=false
 * 
 * @author dodain
 */
class NamedObjectWollokAnchor extends DefaultWollokAnchor {
	
	new(IFigure owner) {
		super(owner)	
	}
	
	override getReferencePoint() {
		owner.bounds.middleBottom.translateToAbsolute
	}

}
