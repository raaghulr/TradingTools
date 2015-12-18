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

/* Button New 
*/
onNew(){
	global contextObj, selectedScrip, EntryOrderType, Direction, Qty, ProdType, EntryPrice, StopPrice
		
	Gui, 1:Submit, NoHide										// sets variables from GUI
	
	adjustPrices( EntryPrice, StopPrice)
		
	if( !validateInput() )
		return

	trade 	:= contextObj.getCurrentTrade()
	trade.create( selectedScrip, EntryOrderType, "SLM", Direction, Qty, ProdType, EntryPrice, StopPrice )
	
}

/* Button Add
*/
onAdd(){
	onNew()
}

/* Button Update
*/
onUpdate(){
	global contextObj, selectedScrip, EntryOrderType, Qty, ProdType, EntryPrice, StopPrice
	trade := contextObj.getCurrentTrade()
	
	Gui, 1:Submit, NoHide
	
	adjustPrices( EntryPrice, StopPrice)
	
	if( !validateInput() )
		return
		
	trade.reload()

	entry := ""																// Update if order linked and status is open/trigger pending and price/qty has changed
	stop  := ""
	
	if( trade.isEntryOpen() && hasOrderChanged( trade.newEntryOrder, EntryPrice, Qty)  )
	{	 																	// Entry Order is open and Entry order has changed
		entry := EntryPrice													// If entry is empty, trade.update() will skip changing Entry Order
	}
	if(  hasOrderChanged( trade.stopOrder, StopPrice, Qty) )
	{																		
		stop := StopPrice													
	}
		
	if( entry != ""  ||  stop != "" ){
		trade.update( selectedScrip, EntryOrderType, "SLM", Qty, ProdType, entry, stop  )
	}
	else{
		MsgBox, 262144,, Nothing to update or Order status is not open
	}
}

/*	Status Bar Double Click
	Open window to manually link orders
	Entry order can be linked with Open Orders and successfully completed orders
	Stop order can only be linked with open orders
*/
statusBarClick(){	
	if( A_GuiEvent == "DoubleClick" ){
		openStatusGUI()			
	}
}

/* Stop Text Double Click 
*/
stopClick(){	
	if( A_GuiEvent == "DoubleClick"  ){
		setDefaultStop()
	}	
}

/*  Unlink Button
*/
onUnlink(){
	global contextObj
	trade := contextObj.getCurrentTrade()
	
	toggleStatusTracker( "off" )
	trade.unlinkOrders()
	updateStatus()
}

/* Cancel Button
*/
onCancel(){
	global contextObj
	trade := contextObj.getCurrentTrade()
	
	trade.cancel()
}

/* Direction Switch
*/
onDirectionChange(){
	global Direction
	
	updateCurrentResult()												// Also submits		
	Gui, Color, % Direction == "B" ? "33cc66" : "ff9933"
}

onEntryPriceChange(){
	global EntryPrice, EntryPriceActual
	
	Gui, 1:Submit, NoHide
	
	EntryPriceActual := EntryPrice	
	updateCurrentResult()
}

onStopPriceChange(){
	global StopPrice, StopPriceActual
	
	Gui, 1:Submit, NoHide
	
	StopPriceActual := StopPrice
	updateCurrentResult()
}

OnEntryUpDown(){
	global EntryUpDown, TickSize, EntryPrice
	
	EntryPrice := (EntryUpDown == 1) ? EntryPrice + TickSize : EntryPrice - TickSize	
	setEntryPrice( EntryPrice, EntryPrice )
}

OnStopUpDown(){
	global StopUpDown, TickSize, StopPrice
	
	StopPrice := (StopUpDown == 1) ? StopPrice + TickSize : StopPrice - TickSize	
	setStopPrice( StopPrice, StopPrice )
}

/* Links Context to selected existing orders
*/
linkOrdersSubmit(){
	global contextObj, ORDER_TYPE_SL_LIMIT, ORDER_TYPE_SL_MARKET, ORDER_STATUS_OPEN, ORDER_STATUS_TRIGGER_PENDING, ORDER_STATUS_COMPLETE, listViewOrderIDPosition, listViewOrderTypePosition, listViewOrderStatusPosition
		
	entryId   			:= ""
	entryType 			:= ""
	executedEntryIDList	:= ""
	stopOrderId	    	:= ""
	isPending			:= false
	rowno				:= 0

	Gui, 2:ListView, SysListView321
	Loop % LV_GetCount("Selected")
	{		
		rowno := LV_GetNext( rowno )							// Entry Order ListView Selected row
		if( rowno == 0 )
			break
		
		LV_GetText( orderId,   rowno, listViewOrderIDPosition )
		LV_GetText( ordertype, rowno, listViewOrderTypePosition )
		LV_GetText( status,    rowno, listViewOrderStatusPosition )
																// Is this Open Order?
		if( status == ORDER_STATUS_OPEN || status == ORDER_STATUS_TRIGGER_PENDING ){
			if( entryId != ""  ){
				MsgBox, 262144,, Select Only One Open Entry Order
				return
			}
			entryId   := orderId
			entryType := ordertype
		}
		else{
			executedEntryIDList := orderId . "," . executedEntryIDList
		}
	}

	if( entryId == "" && executedEntryIDList == "" ){
		MsgBox, 262144,, Select Atleast One Entry Order
		return
	}


	Gui, 2:ListView, SysListView322
	rowno := LV_GetNext()										// Stop Order ListView Selected row
	if( rowno > 0 )
		LV_GetText( stopOrderId, rowno, listViewOrderIDPosition )
	
	
	if( entryType == ORDER_TYPE_SL_LIMIT || entryType == ORDER_TYPE_SL_MARKET )
		isPending := true
	
	if( stopOrderId == "" ){
		if( entryType == ORDER_TYPE_SL_LIMIT || entryType == ORDER_TYPE_SL_MARKET ){
			MsgBox, 262144,, Stop order is not linked, Enter Stop Price and click Update immediately to ready Stop order
		}
		else{
			MsgBox, 262144,, Select Stop Order					// Skipping Stop order allowed only for SL/SLM Orders
			return
		}
	}

	if( entryId == stopOrderId ){							// No Need to check against executedEntryIDList as only completed orders are allowed in it
		MsgBox, 262144,, Selected Entry And Stop Order are same
		return
	}
	
	trade := contextObj.getCurrentTrade()					// Link Orders in Current Context
	
	if( !trade.linkOrders( false, entryId, executedEntryIDList, stopOrderId, isPending, 0  ) )
		return
	
	Gui, 2:Destroy
	Gui  1:Default	
	
	loadTradeInputToGui()									// Load Gui with data from Order->Input	
	
	trade.save()											// Manually Linked orders - save order nos to ini
}


// -- Helpers ---

/*	Check if Order Details in GUI is different than input order 
*/
hasOrderChanged( order, price, qty ){
	global ORDER_TYPE_GUI_LIMIT, ORDER_TYPE_GUI_MARKET
	
	orderInput := order.getInput()	
	if( !IsObject(orderInput) )
		return false
	
	if( qty != orderInput.qty)
		return true
	
	type := orderInput.orderType
	
	if( type == ORDER_TYPE_GUI_LIMIT || type == ORDER_TYPE_GUI_MARKET)
		oldprice := orderInput.price
	else
		oldprice := orderInput.trigger
	
	return price != oldprice
}

/* Validations before trade orders creation/updation
*/
validateInput(){
	global contextObj, EntryPrice, StopPrice, Direction, CurrentResult, MaxStopSize
	
	trade 		:= contextObj.getCurrentTrade()
	checkEntry  := trade.positionSize==0  ||  trade.isNewEntryLinked()		// Skip Entry Price Validations if Entry is Complete and No Add Orders created yet
	
	if( Direction != "B" && Direction != "S"  ){
		MsgBox, 262144,, Direction not set
		return false
	}
		
	if( checkEntry && !UtilClass.isNumber(EntryPrice) ){
		MsgBox, 262144,, Invalid Entry Price
		return false
	}
	if( !UtilClass.isNumber(StopPrice) ){
		MsgBox, 262144,, Invalid Stop Trigger Price
		return false
	}	
	
	if( checkEntry ){														// If Buying, stop should be below price and vv
		if( Direction == "B" ){												// checkEntry - Allow to trail past Entry once Entry/Add order is closed
			if( StopPrice >= EntryPrice  ){
				MsgBox, 262144,, Stop Trigger should be below Buy price
				return false
			}
		}
		else{
			if( StopPrice <= EntryPrice  ){
				MsgBox, 262144,, Stop Trigger should be above Sell price
				return false
			}
		}	
	}

	updateCurrentResult()
	if( CurrentResult < -MaxStopSize  ){
		MsgBox, % 262144+4,, Stop size more than Maximum Allowed. Continue?
		IfMsgBox No
			return false
	}
	
	return true
}


