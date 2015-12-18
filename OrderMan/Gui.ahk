/*
  Copyright (C) 2015  SpiffSpaceman

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>
*/

createGUI(){
	global Qty, EntryPrice, StopPrice, Direction, CurrentResult, BtnOrder, BtnUpdate, BtnLink, BtnUnlink, BtnCancel, EntryStatus, StopStatus, LastWindowPosition, EntryOrderType, EntryUpDown, StopUpDown, EntryText, AddText, BtnAdd
	
	SetFormat, FloatFast, 0.2
		
	Gui, 1:New, +AlwaysOnTop +Resize, OrderMan

	Gui, 1:Add, ListBox, vDirection gonDirectionChange h30 w20 Choose1, B|S	
	Gui, 1:Add, Edit, vQty w30														// Column 1
		
	Gui, 1:Add, Text, vEntryText ym, Entry											// Column 2	
	Gui, 1:Add, Text, vAddText xp+0 yp+0, Add
	Gui, 1:Add, Text, gstopClick, Stop
			
	Gui, 1:Add, Edit, vEntryPrice w55 ym gonEntryPriceChange 						// Column 3
	Gui, 1:Add, Edit, vStopPrice w55 gonStopPriceChange
		
	Gui, 1:Add, Button, gonNew vBtnOrder xp-35 y+m, New								// New or Update
	Gui, 1:Add, Button, gonUpdate vBtnUpdate  xp+0 yp+0, Update	

	Gui, 1:Add, Button, gopenLinkOrdersGUI vBtnLink x+5, Link						// Link or Unlink
	Gui, 1:Add, Button, gonUnlink vBtnUnlink xp+0 yp+0, Unlink		
	
	Gui, 1:Add, UpDown, vEntryUpDown gOnEntryUpDown Range0-1 -16 hp x+0 ym			// Column 4 
	Gui, 1:Add, UpDown, vStopUpDown  gOnStopUpDown  Range0-1 -16 hp y+m
																					// Column 5
	Gui, 1:Add, DropDownList, vEntryOrderType w45 Choose1 ym, LIM|SL|SLM|M 			// Entry Type
	//Gui, 1:Add, DropDownList, w45 Choose1, SLM|SL
	Gui, 1:Add, Text, vCurrentResult  w30
	Gui, 1:Add, Button, gonCancel vBtnCancel y+14, Cancel		 					// Add or Cancel button	
	Gui, 1:Add, Button, gonAdd vBtnAdd xp+0 yp+0, Add
	
	Gui, 1:Add, Text, ym vEntryStatus												// Column 6
	Gui, 1:Add, Text, vStopStatus	
	
	Gui, 1:Add, StatusBar, gstatusBarClick, 										// Status Bar - Shows link order Numbers. Double click to link manually
	
	Gui, 1:Show, AutoSize NoActivate %LastWindowPosition% 
		
	setGUIValues(Qty, 0, 0, "B", EntryOrderType)
	
	initalizeListViewVars()
	
	return	
}

/* Link Button GUI
*/
openLinkOrdersGUI(){	
	
	global listViewFields, LinkOrdersSelectedDirection
	
	Gui, 2:New, +AlwaysOnTop, Link Orders		
	
	Gui, 2:font, bold
	Gui, 2:Add, Text,, Select Entry Order
	Gui, 2:font
		
	Gui, 2:Add, ListView, w600, % listViewFields
	
	Gui, 2:Add, Radio, vLinkOrdersSelectedDirection gonLinkOrdersDirectionSelect Checked, Long
	Gui, 2:Add, Radio, gonLinkOrdersDirectionSelect xp+60 yp, Short
	
	
	Gui, 2:font, bold
	Gui, 2:Add, Text, ym, Select Stop Order				// Column 2
	Gui, 2:font	
	Gui, 2:Add, ListView, w600 -Multi SortDesc,  % listViewFields
	
	onLinkOrdersDirectionSelect()
	
	Gui, 2:Add, Button, Default glinkOrdersSubmit, Link Orders
	Gui, 2:Show, AutoSize	
}

/* Fills up Entry/Stop ListViews in Link Orders GUI based on input Direction
*/
onLinkOrdersDirectionSelect(){
	global  ORDER_TYPE_SL_MARKET, ORDER_STATUS_COMPLETE, ORDER_DIRECTION_BUY, ORDER_DIRECTION_SELL, orderbookObj, LinkOrdersSelectedDirection		
	
	Gui, 2:Submit, NoHide
	
	entryDirection := LinkOrdersSelectedDirection == 1 ? ORDER_DIRECTION_BUY  : ORDER_DIRECTION_SELL		// Long Selected then Entry is Buy Order
	stopDirection  := LinkOrdersSelectedDirection == 1 ? ORDER_DIRECTION_SELL : ORDER_DIRECTION_BUY			// Long Selected then Stop  is Sell Order
	
	orderbookObj.read()
	
	Gui, 2:ListView, SysListView321						// Entry Listview
	LV_Delete()											// Delete All Rows
	Loop, % orderbookObj.OpenOrders.size {				// Show Open Orders + Closed Orders with status Complete in Selected Direction
		o := orderbookObj.OpenOrders[A_Index]
		if( o.buySell == entryDirection )
			addOrderRow( o, "Open" )
	}
	Loop, % orderbookObj.CompletedOrders.size {
		o := orderbookObj.CompletedOrders[A_Index]
		if( o.status == ORDER_STATUS_COMPLETE && o.buySell == entryDirection )
			addOrderRow(o, "Executed")
	}
	if(  LV_GetCount() > 0  )
		LV_ModifyCol()									// Show All text
	
	
	
	Gui, 2:ListView, SysListView322						// Stop Listview
	LV_Delete()											// Delete All Rows
	Loop, % orderbookObj.OpenOrders.size {				// filter: Open + SLM + stop direction
		o :=  orderbookObj.OpenOrders[A_Index]
		if( o.orderType == ORDER_TYPE_SL_MARKET && o.buySell == stopDirection)
			addOrderRow( o, "Open SLM" )
	}
	if(  LV_GetCount() > 0  )
		LV_ModifyCol()	

	Gui, 2:Show, AutoSize
}


/* Linked Order Status GUI
*/
openStatusGUI(){
	global orderbookObj, contextObj, listViewFields
	
	orderbookObj.read()	
	
	Gui, 3:New, +AlwaysOnTop, Linked Orders
	Gui, 3:font, bold
	Gui, 3:Add, Text,, Linked Order Details
	Gui, 3:font
	
	Gui, 3:Add, ListView, w600 -Multi SortDesc,  % listViewFields
	
	trade := contextObj.getCurrentTrade()
	addOrderRow( trade.newEntryOrder.getOrderDetails(), "Entry(Open)" )
	addOrderRow( trade.stopOrder.getOrderDetails(), "Stop(Open)" )
	
	For index, value in trade.executedEntryOrderList{
		addOrderRow( value.getOrderDetails(), "Entry(Executed)" )
	}
	
	if(  LV_GetCount() > 0  )
		LV_ModifyCol()								// Show All text
	
	Gui, 3:Show, AutoSize
}

/* Sets Current Position status if Stop hits
*/
updateCurrentResult(){
	global
	
	Gui, 1:Submit, NoHide
	CurrentResult := Direction == "B" ? StopPrice-EntryPrice : EntryPrice-StopPrice
	GuiControl, 1:Text, CurrentResult, %CurrentResult%	
}

/* Sets Stop price using default Stop size 
*/
setDefaultStop(){
	global
		
	Gui, 1:Submit, NoHide			
	StopPrice :=  Direction == "B" ? EntryPrice-DefaultStopSize : EntryPrice+DefaultStopSize		
	GuiControl, 1:Text, StopPrice, %StopPrice%
	
	updateCurrentResult()
}




//   -- GUI Updates --- 

/*	Update status bar, GUI controls state and Timer state based on order status
*/
updateStatus(){
	global contextObj, orderbookObj, ORDER_STATUS_OPEN, EntryStatus, StopStatus, EntryPrice, StopPrice
	
	trade 			  := contextObj.getCurrentTrade()
	trade.reload()
	
	entryOrderDetails := trade.newEntryOrder.getOrderDetails()
	stopOrderDetails  := trade.stopOrder.getOrderDetails()
	
	entryLinked 	  := trade.isNewEntryLinked()
	stopLinked		  := trade.isStopLinked()
	anyLinked		  := entryLinked || stopLinked 
	entryOpen		  := trade.isEntryOpen()
	isStopPending 	  := trade.isStopPending										// Is Stop waiting for Entry to trigger
	stopOpen		  := trade.isStopOpen()	 || isStopPending
	isEntryClosed	  := trade.isEntryClosed()
	isStopClosed	  := trade.isStopClosed()
	positionSize	  := trade.positionSize
	openSize		  := IsObject(entryOrderDetails) ? entryOrderDetails.totalQty : 0
	isEntered		  := positionSize > 0
	
	GuiControl, % isEntered ? "1:Hide" : "1:Show", EntryText						// Show Add Label once Initial Entry order is successful
	GuiControl, % isEntered ? "1:Show" : "1:Hide", AddText
	
	GuiControl, % anyLinked ? "1:Disable" : "1:Enable", Direction					// Disable Direction if orders Linked
	GuiControl, % anyLinked ? "1:Show"    : "1:Hide",   BtnUnlink					// Show Order if unlinked. If orders links show Unlink button instead
	GuiControl, % anyLinked	? "1:Hide"    : "1:Show",   BtnLink						// Show Link if not linked
	GuiControl, % anyLinked ? "1:Hide"    : "1:Show",   BtnOrder		

	GuiControl, % entryOpen    || stopOpen  ? "1:Show"  : "1:Hide", BtnUpdate		// Show Update only if atleast one linked order is open
	GuiControl, % entryOpen   			    ? "1:Show"  : "1:Hide", BtnCancel		// Show Cancel Button if Entry Order is linked and open	
	GuiControl, % isEntered && !entryLinked ? "1:Show"  : "1:Hide", BtnAdd			// Show Add if already have a position and dont have add entry order linked
	
	GuiControl, % !entryLinked || entryOpen ? "1:Enable"  : "1:Disable", EntryPrice	// Enable Price entry for new orders or for linked open orders
	GuiControl, % !stopLinked  || stopOpen  ? "1:Enable"  : "1:Disable", StopPrice

	if( entryLinked ){																// Set Status if Linked
		shortStatus	:= getOrderShortStatus( entryOrderDetails.status )		
		size 		:= entryOrderDetails.totalQty	
		status 		:= size > 0 ?  shortStatus . "(" . size . ")"   :  shortStatus				
		width		:= StrLen(status) > 12 ? "w125" : "w50"		
		
		GuiControl, 1:Text, EntryStatus, % status
		GuiControl, 1:Move, EntryStatus, % width
	}
	else{
		GuiControl, 1:Text, EntryStatus, 
		GuiControl, 1:Move, EntryStatus, w1
	}

	if( stopLinked || isStopPending ){
		
		shortStatus	:= getOrderShortStatus( stopOrderDetails.status )
		size 		:= stopOrderDetails.totalQty	
		status 		:= size > 0 ?  shortStatus . " (" . size . ")"   :  shortStatus		
		
		if( isStopPending ){
			size			  := entryOrderDetails.totalQty	
			pendingstatus := "P" . "(" . size . ")"			
			status 		  := pendingstatus . "  " .  status
		}		
		
		length := StrLen(status)
		width  := length <= 12 ? "w50" : ( length <= 20 ? "w75" : "w125")
		
		GuiControl, 1:Text, StopStatus, % status
		GuiControl, 1:Move, StopStatus, % width		
	}
	else{
		GuiControl, 1:Text, StopStatus,
		GuiControl, 1:Move, StopStatus, w1
	}	
	
	isTimerActive := (entryLinked || stopLinked) && ! (isEntryClosed && isStopClosed) 		// If order linked, start tracking orderbook. But stop if both closed
	isTimerActive := isTimerActive ?  toggleStatusTracker( "on" ) : toggleStatusTracker( "off" )	
	timeStatus    := isTimerActive ? "ON" : "OFF"
			
	SB_SetText( "Timer: " . timeStatus . "  Open Position: " . positionSize . ". Unfilled: " . openSize )
	
	Gui, 1:Show, AutoSize NA
}

/*  Loads Trade from TradeClass>OrderClass>InputClass into GUI
	Used when linking to existing orders
*/
loadTradeInputToGui(){
	global contextObj, ORDER_TYPE_GUI_LIMIT, ORDER_TYPE_GUI_MARKET
	
	trade := contextObj.getCurrentTrade()
	entry := trade.newEntryOrder.getInput()
	stop  := trade.stopOrder.getInput()
	
	entry_price := (entry.orderType == ORDER_TYPE_GUI_LIMIT || entry.orderType == ORDER_TYPE_GUI_MARKET) ? entry.price : entry.trigger			
	setGUIValues( entry.qty, entry_price, stop.trigger, entry.direction, entry.orderType )
	updateCurrentResult()
}

setGUIValues( inQty, inEntry, inStop, inDirection, inEntryOrderType ){
	
	setQty( inQty )
	setEntryPrice( inEntry, inEntry )
	setStopPrice( inStop, inStop )
	setDirection( inDirection )	
	selectEntryOrderType( inEntryOrderType )
	
	updateStatus()	
}

setQty( inQty ){
	global Qty
	Qty := inQty
	GuiControl, 1:Text, Qty,  %Qty%
}

/* EntryPriceActual should contain the original values taken from AB
*/
setEntryPrice( inEntry, inEntryPriceActual){
	global EntryPrice, EntryPriceActual
	EntryPrice 		 := inEntry
	EntryPriceActual := inEntryPriceActual
	GuiControl, 1:Text, EntryPrice,  %EntryPrice%
}

/* StopPriceActual should contain the original values taken from AB
*/
setStopPrice( inStop, inStopPriceActual ){
	global StopPrice, StopPriceActual
	StopPrice 		:= inStop
	StopPriceActual := inStopPriceActual
	GuiControl, 1:Text, StopPrice, %StopPrice%
}

setDirection( inDirection ){
	global Direction
	Direction := inDirection
	GuiControl, 1:ChooseString, Direction,  %Direction%
	onDirectionChange()
}

selectEntryOrderType( inEntryOrderType ){
	global EntryOrderType	
	EntryOrderType := inEntryOrderType
	GuiControl, 1:ChooseString, EntryOrderType,  %EntryOrderType%
}


// -- GUI Helpers --- 

/* Map order status to short code for GUI
*/
getOrderShortStatus( status ){
	global
	
	if( status == ORDER_STATUS_OPEN )
		return "O"
	else if( status == ORDER_STATUS_TRIGGER_PENDING )
		return "O-TP"
	else if( status == ORDER_STATUS_COMPLETE )
		return "C"
	else if( status == ORDER_STATUS_REJECTED )
		return "R"
	else if( status == ORDER_STATUS_CANCELLED )
		return "CAN"
	else
		return status
}

/* Headers for Order Listviews
*/
initalizeListViewVars(){
	global
	
	listViewFields 	   	         := "Type|Scrip|Status|OrderType|Buy/Sell|Qty|Price|Trigger|Average|Order No|Time"
	listViewOrderIDPosition   	 := 10
	listViewOrderStatusPosition  := 3
	listViewOrderTypePosition	 := 4
}

/* Adds row to list View
*/
addOrderRow( o, type ) {
	if( IsObject(o) )
		LV_Add("", type, o.tradingSymbol, o.status, o.orderType, o.buySell, o.totalQty, o.price, o.triggerPrice, o.averagePrice, o.nowOrderNo, o.nowUpdateTime )
}


GuiClose:
	saveLastPosition()
	ExitApp
