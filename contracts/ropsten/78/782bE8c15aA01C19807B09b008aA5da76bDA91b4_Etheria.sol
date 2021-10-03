/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

contract BlockDefStorage 
{
	function getOccupies(uint8 blocktype) public returns (int8[24])
	{}
	function getAttachesto(uint8 blocktype) public returns (int8[48])
    {}
}

contract MapElevationRetriever 
{
	function getElevation(uint8 col, uint8 row) public constant returns (uint8)
	{}
}

contract Etheria 
{
	event TileChanged(uint8 col, uint8 row);//, address owner, string name, string status, uint lastfarm, address[] offerers, uint[] offers, int8[5][] blocks);
	
    uint8 mapsize = 33;
    Tile[33][33] tiles;
    address creator;
    
    struct Tile 
    {
    	address owner;
    	string name;
    	string status;
    	int8[5][] blocks; //0 = blocktype,1 = blockx,2 = blocky,3 = blockz, 4 = color
    	uint lastfarm;
    	int8[3][] occupado; // the only one not reported in the //TileChanged event
    }
    
    BlockDefStorage bds;
    MapElevationRetriever mer;
    
    function Etheria() {
    	creator = tx.origin;
    	bds = BlockDefStorage(0x50C50eb5797A93B009100805490940B6fd81e46a); 
    	mer = MapElevationRetriever(0xF39E44fA32d9DdE5f0e919DFa1670a7D66482067);
    }
    
    function getOwner(uint8 col, uint8 row) public constant returns(address)
    {
    	return tiles[col][row].owner; // no harm if col,row are invalid
    }
    
    function setOwner(uint8 col, uint8 row, address newowner)
    {
//    	if(isOOB(col,row)) // row and/or col was not between 0-mapsize
//    	{
//    		whathappened = "setOwner:ERR:c,r OOB";  
//    		return;
//    	}
    	Tile tile = tiles[col][row];
    	if(tile.owner != tx.origin && !(tx.origin == creator && !getLocked()))
    	{
    		whathappened = "setOwner:ERR:not owner";  
    		return;
    	}
    	tile.owner = newowner;
    	TileChanged(col,row);
    	whathappened = "setOwner:OK";
    	return;
    }
    
    /***
     *     _   _   ___  ___  ___ _____            _____ _____ ___ _____ _   _ _____ 
     *    | \ | | / _ \ |  \/  ||  ___|   ___    /  ___|_   _/ _ \_   _| | | /  ___|
     *    |  \| |/ /_\ \| .  . || |__    ( _ )   \ `--.  | |/ /_\ \| | | | | \ `--. 
     *    | . ` ||  _  || |\/| ||  __|   / _ \/\  `--. \ | ||  _  || | | | | |`--. \
     *    | |\  || | | || |  | || |___  | (_>  < /\__/ / | || | | || | | |_| /\__/ /
     *    \_| \_/\_| |_/\_|  |_/\____/   \___/\/ \____/  \_/\_| |_/\_/  \___/\____/ 
     *                                                                              
     *                                                                              
     */
    
    function getName(uint8 col, uint8 row) public constant returns(string)
    {
    	return tiles[col][row].name; // no harm if col,row are invalid
    }
    
    function setName(uint8 col, uint8 row, string _n) public
    {
//    	if(isOOB(col,row)) // row and/or col was not between 0-mapsize
//    	{
//    		whathappened = "setName:ERR:c,r OOB";  
//    		return;
//    	}
    	Tile tile = tiles[col][row];
    	if(tile.owner != tx.origin && !(tx.origin == creator && !getLocked()))
    	{
    		whathappened = "setName:ERR:not owner";  
    		return;
    	}
    	tile.name = _n;
    	TileChanged(col,row);
    	whathappened = "setName:OK";
    	return;
    }
    
    function getStatus(uint8 col, uint8 row) public constant returns(string)
    {
    	return tiles[col][row].status; // no harm if col,row are invalid
    }
    
    function setStatus(uint8 col, uint8 row, string _s) public // setting status costs 1 eth to prevent spam
    {
//    	if(isOOB(col,row)) // row and/or col was not between 0-mapsize
//    	{
//    		tx.origin.send(msg.value); 		// return their money, if any
//    		whathappened = "setStatus:ERR:c,r OOB";  
//    		return;
//    	}
    	if(msg.value != 1000000000000000000) 
    	{
    		tx.origin.send(msg.value); 		// return their money, if any
    		whathappened = "setStatus:ERR:val!=1eth";
    		return;
    	}
    	Tile tile = tiles[col][row];
    	if(tile.owner != tx.origin && !(tx.origin == creator && !getLocked()))
    	{
    		tx.origin.send(msg.value); 		// return their money, if any
    		whathappened = "setStatus:ERR:not owner";  
    		return;
    	}
    	tile.status = _s;
    	creator.send(msg.value);
    	TileChanged(col,row);
    	whathappened = "setStatus:OK";
    	return;
    }
    
    /***
     *    ______ ___  _________  ________ _   _ _____            ___________ _____ _____ _____ _   _ _____ 
     *    |  ___/ _ \ | ___ \  \/  |_   _| \ | |  __ \   ___    |  ___|  _  \_   _|_   _|_   _| \ | |  __ \
     *    | |_ / /_\ \| |_/ / .  . | | | |  \| | |  \/  ( _ )   | |__ | | | | | |   | |   | | |  \| | |  \/
     *    |  _||  _  ||    /| |\/| | | | | . ` | | __   / _ \/\ |  __|| | | | | |   | |   | | | . ` | | __ 
     *    | |  | | | || |\ \| |  | |_| |_| |\  | |_\ \ | (_>  < | |___| |/ / _| |_  | |  _| |_| |\  | |_\ \
     *    \_|  \_| |_/\_| \_\_|  |_/\___/\_| \_/\____/  \___/\/ \____/|___/  \___/  \_/  \___/\_| \_/\____/
     *                                                                                                     
     */
    
    function getLastFarm(uint8 col, uint8 row) public constant returns (uint)
    {
    	return tiles[col][row].lastfarm;
    }
    
    function farmTile(uint8 col, uint8 row, int8 blocktype) public 
    {
//    	if(isOOB(col,row)) // row and/or col was not between 0-mapsize
//    	{
//    		tx.origin.send(msg.value); 		// return their money, if any
//    		whathappened = "farmTile:ERR:c,r OOB";  
//    		return;
//    	}
    	
    	if(blocktype < 0 || blocktype > 17) // invalid blocktype
    	{
    		tx.origin.send(msg.value); 		// return their money, if any
    		whathappened = "farmTile:ERR:invalid blocktype";
    		return;
    	}	
    	
    	Tile tile = tiles[col][row];
        if(tile.owner != tx.origin)
        {
        	tx.origin.send(msg.value); 		// return their money, if any
        	whathappened = "farmTile:ERR:not owner";
        	return;
        }
        if((block.number - tile.lastfarm) < 2500) // ~12 hours of blocks
        {
        	if(msg.value != 1000000000000000000)
        	{	
        		tx.origin.send(msg.value); // return their money
        		whathappened = "farmTile:ERR:val!=1eth";
        		return;
        	}
        	else // they paid 1 ETH
        	{
        		creator.send(msg.value); // If they haven't waited long enough, but they've paid 1 eth, let them farm again.
        	}	
        }
        else
        {
        	if(msg.value > 0) // they've waited long enough but also sent money. Return it and continue normally.
        	{
        		tx.origin.send(msg.value); // return their money
        	}
        }
        
        // by this point, they've either waited 2500 blocks or paid 1 ETH
    	for(uint8 i = 0; i < 10; i++)
    	{
            tile.blocks.length+=1;
            tile.blocks[tile.blocks.length - 1][0] = int8(blocktype); // blocktype 0-17
    	    tile.blocks[tile.blocks.length - 1][1] = 0; // x
    	    tile.blocks[tile.blocks.length - 1][2] = 0; // y
    	    tile.blocks[tile.blocks.length - 1][3] = -1; // z
    	    tile.blocks[tile.blocks.length - 1][4] = 0; // color
    	}
    	tile.lastfarm = block.number;
    	TileChanged(col,row);
    	whathappened = "farmTile:OK";
    	return;
    }
    
    function editBlock(uint8 col, uint8 row, uint index, int8[5] _block)   // NOTE: won't return accidental money.
    {
//    	if(isOOB(col,row)) // row and/or col was not between 0-mapsize
//    	{
//    		whathappened = "editBlock:ERR:c,r OOB";  
//    		return;
//    	}
    	Tile tile = tiles[col][row];
        if(tile.owner != tx.origin) // 1. DID THE OWNER SEND THIS MESSAGE?
        {
        	whathappened = "editBlock:ERR:not owner";
        	return;
        }
        if(_block[3] < 0) // 2. IS THE Z LOCATION OF THE BLOCK BELOW ZERO? BLOCKS CANNOT BE HIDDEN
        {
        	whathappened = "editBlock:ERR:can't hide blocks";
        	return;
        }
        if(index > (tile.blocks.length-1))
        {
        	whathappened = "editBlock:ERR:index OOR";
        	return;
        }		
        if(_block[0] == -1) // user has signified they want to only change the color of this block
        {
        	tile.blocks[index][4] = _block[4];
        	whathappened = "editBlock:OK:color changed";
        	return;
        }	
        _block[0] = tile.blocks[index][0]; // can't change the blocktype, so set it to whatever it already was

        int8[24] memory didoccupy = bds.getOccupies(uint8(_block[0]));
        int8[24] memory wouldoccupy = bds.getOccupies(uint8(_block[0]));
        
        for(uint8 b = 0; b < 24; b+=3) // always 8 hexes, calculate the didoccupy
 		{
 			 wouldoccupy[b] = wouldoccupy[b]+_block[1];
 			 wouldoccupy[b+1] = wouldoccupy[b+1]+_block[2];
 			 if(wouldoccupy[1] % 2 != 0 && wouldoccupy[b+1] % 2 == 0) // if anchor y is odd and this hex y is even, (SW NE beam goes 11,`2`2,23,`3`4,35,`4`6,47,`5`8  ` = x value incremented by 1. Same applies to SW NE beam from 01,12,13,24,25,36,37,48)
 				 wouldoccupy[b] = wouldoccupy[b]+1;  			   // then offset x by +1
 			 wouldoccupy[b+2] = wouldoccupy[b+2]+_block[3];
 			 
 			 didoccupy[b] = didoccupy[b]+tile.blocks[index][1];
 			 didoccupy[b+1] = didoccupy[b+1]+tile.blocks[index][2];
 			 if(didoccupy[1] % 2 != 0 && didoccupy[b+1] % 2 == 0) // if anchor y and this hex y are both odd,
 				 didoccupy[b] = didoccupy[b]+1; 					 // then offset x by +1
       		didoccupy[b+2] = didoccupy[b+2]+tile.blocks[index][3];
 		}
        
        if(!isValidLocation(col,row,_block, wouldoccupy))
        {
        	return; // whathappened is already set
        }
        
        // EVERYTHING CHECKED OUT, WRITE OR OVERWRITE THE HEXES IN OCCUPADO
        
      	if(tile.blocks[index][3] >= 0) // If the previous z was greater than 0 (i.e. not hidden) ...
     	{
         	for(uint8 l = 0; l < 24; l+=3) // loop 8 times,find the previous occupado entries and overwrite them
         	{
         		for(uint o = 0; o < tile.occupado.length; o++)
         		{
         			if(didoccupy[l] == tile.occupado[o][0] && didoccupy[l+1] == tile.occupado[o][1] && didoccupy[l+2] == tile.occupado[o][2]) // x,y,z equal?
         			{
         				tile.occupado[o][0] = wouldoccupy[l]; // found it. Overwrite it
         				tile.occupado[o][1] = wouldoccupy[l+1];
         				tile.occupado[o][2] = wouldoccupy[l+2];
         			}
         		}
         	}
     	}
     	else // previous block was hidden
     	{
     		for(uint8 ll = 0; ll < 24; ll+=3) // add the 8 new hexes to occupado
         	{
     			tile.occupado.length++;
     			tile.occupado[tile.occupado.length-1][0] = wouldoccupy[ll];
     			tile.occupado[tile.occupado.length-1][1] = wouldoccupy[ll+1];
     			tile.occupado[tile.occupado.length-1][2] = wouldoccupy[ll+2];
         	}
     	}
     	tile.blocks[index] = _block;
     	TileChanged(col,row);
    	return;
    }
       
    function getBlocks(uint8 col, uint8 row) public constant returns (int8[5][])
    {
    	return tiles[col][row].blocks; // no harm if col,row are invalid
    }
   
    // three OK conditions:
    // 1. Valid offer on unowned tile. (whathap = 4)
    // 2. Valid offer on owned tile where offerer did not previously have an offer on file (whathap = 7)
    // 3. Valid offer on owned tile where offerer DID have a previous offer on file (whathap = 6)
    function buyTile(uint8 col, uint8 row)
    {    	
//    	if(isOOB(col,row)) // row and/or col was not between 0-mapsize
//    	{
//    		tx.origin.send(msg.value);              // return their money, if any
//    		whathappened = "buyTile:ERR:c,r OOB";  
//    		return;
//    	}
//    	
    	if(msg.value != 1000000000000000000)	// 1 ETH is the starting value. If not return; // Also, if below sea level, return. 
		{
    		tx.origin.send(msg.value);              // return their money, if any
    		whathappened = "buyTile:ERR:val!=1eth";  
    		return;
		}
    	
    	Tile tile = tiles[col][row];
    	if(tile.owner == address(0x0000000000000000000000000000000000000000))			// if UNOWNED
    	{	  
    		if(mer.getElevation(col,row) < 125)	// 1 ETH is the starting value. If not return; // Also, if below sea level, return. 
    		{
    			tx.origin.send(msg.value); 	 									// return their money
    			whathappened = "buyTile:ERR:water";
    			return;
    		}
    		else
    		{	
    			creator.send(msg.value);     		 					// this was a valid offer, send money to contract creator
    			tile.owner = tx.origin;  								// set tile owner to the buyer
    			TileChanged(col,row);
    			whathappened = "buyTile:OK";
    			return;
    		}
    	}
    	else
    	{
    		tx.origin.send(msg.value);              // return their money, if any
    		whathappened = "buyTile:ERR:alr owned";
    		return;
    	}
    }
    
    /***
     *     _   _ _____ _____ _     _____ _______   __
     *    | | | |_   _|_   _| |   |_   _|_   _\ \ / /
     *    | | | | | |   | | | |     | |   | |  \ V / 
     *    | | | | | |   | | | |     | |   | |   \ /  
     *    | |_| | | |  _| |_| |_____| |_  | |   | |  
     *     \___/  \_/  \___/\_____/\___/  \_/   \_/  
     *                                               
     */
    
    // this logic COULD be reduced a little, but the gain is minimal and readability suffers
    function blockHexCoordsValid(int8 x, int8 y) private constant returns (bool)
    {
    	uint absx;
		uint absy;
		if(x < 0)
			absx = uint(x*-1);
		else
			absx = uint(x);
		if(y < 0)
			absy = uint(y*-1);
		else
			absy = uint(y);
    	
    	if(absy <= 33) // middle rectangle
    	{
    		if(y % 2 != 0 ) // odd
    		{
    			if(-50 <= x && x <= 49)
    				return true;
    		}
    		else // even
    		{
    			if(absx <= 49)
    				return true;
    		}	
    	}	
    	else
    	{	
    		if((y >= 0 && x >= 0) || (y < 0 && x > 0)) // first or 4th quadrants
    		{
    			if(y % 2 != 0 ) // odd
    			{
    				if (((absx*2) + (absy*3)) <= 198)
    					return true;
    			}	
    			else	// even
    			{
    				if ((((absx+1)*2) + ((absy-1)*3)) <= 198)
    					return true;
    			}
    		}
    		else
    		{	
    			if(y % 2 == 0 ) // even
    			{
    				if (((absx*2) + (absy*3)) <= 198)
    					return true;
    			}	
    			else	// odd
    			{
    				if ((((absx+1)*2) + ((absy-1)*3)) <= 198)
    					return true;
    			}
    		}
    	}
    	return false;
    }
    
    // SEVERAL CHECKS TO BE PERFORMED
    // 1. DID THE OWNER SEND THIS MESSAGE?		(SEE editBlock)
    // 2. IS THE Z LOCATION OF THE BLOCK BELOW ZERO? BLOCKS CANNOT BE HIDDEN AFTER SHOWING	   (SEE editBlock)
    // 3. DO ANY OF THE PROPOSED HEXES FALL OUTSIDE OF THE TILE? 
    // 4. DO ANY OF THE PROPOSED HEXES CONFLICT WITH ENTRIES IN OCCUPADO? 
    // 5. DO ANY OF THE BLOCKS TOUCH ANOTHER?
    // 6. NONE OF THE OCCUPY BLOCKS TOUCHED THE GROUND. BUT MAYBE THEY TOUCH ANOTHER BLOCK?
    
    function isValidLocation(uint8 col, uint8 row, int8[5] _block, int8[24] wouldoccupy) private constant returns (bool)
    {
    	bool touches;
    	Tile tile = tiles[col][row]; // since this is a private method, we don't need to check col,row validity
    	
        for(uint8 b = 0; b < 24; b+=3) // always 8 hexes, calculate the wouldoccupy and the didoccupy
       	{
       		if(!blockHexCoordsValid(wouldoccupy[b], wouldoccupy[b+1])) // 3. DO ANY OF THE PROPOSED HEXES FALL OUTSIDE OF THE TILE? 
      		{
       			whathappened = "editBlock:ERR:OOB";
      			return false;
      		}
       		for(uint o = 0; o < tile.occupado.length; o++)  // 4. DO ANY OF THE PROPOSED HEXES CONFLICT WITH ENTRIES IN OCCUPADO? 
          	{
      			if(wouldoccupy[b] == tile.occupado[o][0] && wouldoccupy[b+1] == tile.occupado[o][1] && wouldoccupy[b+2] == tile.occupado[o][2]) // do the x,y,z entries of each match?
      			{
      				whathappened = "editBlock:ERR:conflict";
      				return false; // this hex conflicts. The proposed block does not avoid overlap. Return false immediately.
      			}
          	}
      		if(touches == false && wouldoccupy[b+2] == 0)  // 5. DO ANY OF THE BLOCKS TOUCH ANOTHER? (GROUND ONLY FOR NOW)
      		{
      			touches = true; // once true, always true til the end of this method. We must keep looping to check all the hexes for conflicts and tile boundaries, though, so we can't return true here.
      		}	
       	}
        
        // now if we're out of the loop and here, there were no conflicts and the block was found to be in the tile boundary.
        // touches may be true or false, so we need to check 
          
        if(touches == false)  // 6. NONE OF THE OCCUPY BLOCKS TOUCHED THE GROUND. BUT MAYBE THEY TOUCH ANOTHER BLOCK?
  		{
          	int8[48] memory attachesto = bds.getAttachesto(uint8(_block[0]));
          	for(uint8 a = 0; a < 48 && !touches; a+=3) // always 8 hexes, calculate the wouldoccupy and the didoccupy
          	{
          		if(attachesto[a] == 0 && attachesto[a+1] == 0 && attachesto[a+2] == 0) // there are no more attachestos available, break (0,0,0 signifies end)
          			break;
          		//attachesto[a] = attachesto[a]+_block[1];
          		attachesto[a+1] = attachesto[a+1]+_block[2];
           		if(attachesto[1] % 2 != 0 && attachesto[a+1] % 2 == 0) // (for attachesto, anchory is the same as for occupies, but the z is different. Nothing to worry about)
           			attachesto[a] = attachesto[a]+1;  			       // then offset x by +1
           		//attachesto[a+2] = attachesto[a+2]+_block[3];
           		for(o = 0; o < tile.occupado.length && !touches; o++)
           		{
           			if((attachesto[a]+_block[1]) == tile.occupado[o][0] && attachesto[a+1] == tile.occupado[o][1] && (attachesto[a+2]+_block[3]) == tile.occupado[o][2]) // a valid attachesto found in occupado?
           			{
           				whathappened = "editBlock:OK:attached";
           				return true; // in bounds, didn't conflict and now touches is true. All good. Return.
           			}
           		}
          	}
          	whathappened = "editBlock:ERR:floating";
          	return false; 
  		}
        else // touches was true by virtue of a z = 0 above (touching the ground). Return true;
        {
        	whathappened = "editBlock:OK:ground";
        	return true;
        }	
    }  

//    function isOOB(uint8 col, uint8 row) private constant returns (bool)
//    {
//    	if(col < 0 || col > (mapsize-1) || row < 0 || row > (mapsize-1))
//    		return true; // is out of bounds
//    }
    
    string whathappened;
    function getWhatHappened() public constant returns (string)
    {
    	return whathappened;
    }

   /***
    Return money fallback and empty random funds, if any
    */
   function() 
   {
	   tx.origin.send(msg.value);
   }
   
   function empty() 
   {
	   creator.send(address(this).balance); // etheria should never hold a balance. But in case it does, at least provide a way to retrieve them.
   }
    
   /**********
   Standard lock-kill methods 
   **********/
   bool locked;			// until locked, creator can kill, set names, statuses and tile ownership.
   function setLocked()
   {
	   if (msg.sender == creator)
		   locked = true;
   }
   function getLocked() public constant returns (bool)
   {
	   return locked;
   }
   function kill()
   { 
	   if (!getLocked() && msg.sender == creator)
		   suicide(creator);  // kills this contract and sends remaining funds back to creator
   }
}