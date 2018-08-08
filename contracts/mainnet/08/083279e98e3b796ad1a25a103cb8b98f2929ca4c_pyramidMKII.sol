pragma solidity ^0.4.24;

contract pyramidMKII {
    address owner;
	
	struct blockinfo {
        uint256 outstanding;                                                    // remaining debt at block
        uint256 dividend;                                                      	// % dividend all previous can claim, 1 ether 
		uint256 value;															// actual ether value at block
		uint256 index;                                                          // used in frontend bc async checks
	}
	struct debtinfo {
		uint256 idx;															// dividend array position
		uint256 pending;														// pending balance at block
		uint256 initial;														// initial ammount for stats
	}
    struct account {
        uint256 ebalance;                                                       // ether balance
		mapping(uint256=>debtinfo) owed;										// keeps track of outstanding debt 
    }
	
	uint256 public blksze;														// block size
	uint256 public surplus;
	uint256 public IDX;														    // current dividend block
	mapping(uint256=>blockinfo) public blockData;								// dividend block data
	mapping(address=>account) public balances;
	
	bytes32 public consul_nme;
	uint256 public consul_price;
	address public consul;
	address patrician;
	
    string public standard = &#39;PYRAMIDMKII&#39;;
    string public name = &#39;PYRAMIDMKII&#39;;
    string public symbol = &#39;PM2&#39;;
    uint8 public decimals = 0 ;
	
	constructor() public {                                                     
        owner = msg.sender;  
        blksze = 1 ether; 
        consul= owner;                                                          // owner is 1st consul    
        patrician = owner;                                                      // owner is 1st patrician
	}
	
	function addSurplus() public payable { surplus += msg.value; }              // used to pay off the debt in final round
	
	function callSurplus() public {                                             // if there&#39;s enough surplus 
	    require(surplus >= blksze, "not enough surplus");                       // users can call this to make a new block 
	    blockData[IDX].value += blksze;                                         // without increasing outstanding
	    surplus -= blksze;
	    nextBlock();
	}
	    
	function owedAt(uint256 blk) public view returns(uint256, uint256, uint256)
		{ return (	balances[msg.sender].owed[blk].idx, 
					balances[msg.sender].owed[blk].pending, 
					balances[msg.sender].owed[blk].initial); }
	
	function setBlockSze(uint256 _sze) public {
		require(msg.sender == owner && _sze >= 1 ether, "error blksze");
		blksze = _sze;
	}
	
	function withdraw() public {
		require(balances[msg.sender].ebalance > 0, "not enough divs claimed");
        uint256 sval = balances[msg.sender].ebalance;
        balances[msg.sender].ebalance = 0;
        msg.sender.transfer(sval);
        emit event_withdraw(msg.sender, sval);
	}
	
	function chkConsul(address addr, uint256 val, bytes32 usrmsg) internal returns(uint256) {
	    if(val <= consul_price) return val;
	    balances[owner].ebalance += val/4;                                      // 25% for fund
	    balances[consul].ebalance += val/4;                                     // 25% for current consul
	    consul = addr;
	    consul_price = val;
	    consul_nme = usrmsg;
	    balances[addr].owed[IDX].pending += (val/2) + (val/4);                  // compensates for val/2
	    balances[addr].owed[IDX].initial += (val/2) + (val/4);
	    blockData[IDX].outstanding += (val/2) + (val/4);
	    emit event_consul(val, usrmsg);
	    return val/2;
	}
	
	function nextBlock() internal {
	    if(blockData[IDX].value>= blksze) { 
			surplus += blockData[IDX].value - blksze;
			blockData[IDX].value = blksze;
			if(IDX > 0) 
			    blockData[IDX].outstanding -= 
			        (blockData[IDX-1].outstanding * blockData[IDX-1].dividend)/100 ether;
			blockData[IDX].dividend = 
				(blksze * 100 ether) / blockData[IDX].outstanding;				// blocksize as % of total outstanding
			IDX += 1;															// filled block, next
			blockData[IDX].index = IDX;                                         // to avoid rechecking on frontend
			blockData[IDX].outstanding = blockData[IDX-1].outstanding;			// debt rolls over
			if(IDX % 200 == 0 && IDX != 0) blksze += 1 ether;                   // to keep a proper div distribution
			emit event_divblk(IDX);
		}
	}
	
	function pyramid(address addr, uint256 val, bytes32 usrmsg) internal {
	    val = chkConsul(addr, val, usrmsg);
		uint256 mval = val - (val/10);                                          // 10% in patrician, consul && fund money
		uint256 tval = val + (val/2);
		balances[owner].ebalance += (val/100);                                  // 1% for hedge fund
		balances[consul].ebalance += (val*7)/100 ;                              // 7% for consul
		balances[patrician].ebalance+= (val/50);                                // 2% for patrician
		patrician = addr;                                                       // now you&#39;re the patrician
		uint256 nsurp = (mval < blksze)? blksze-mval : (surplus < blksze)? surplus : 0;
		nsurp = (surplus >= nsurp)? nsurp : 0;
		mval += nsurp;                                                          // complete a block using surplus
		surplus-= nsurp;                                                        
		blockData[IDX].value += mval;
        blockData[IDX].outstanding += tval;                                     // block outstanding debt increases until block fills
		balances[addr].owed[IDX].idx = IDX;							            // user can claim when block is full
		balances[addr].owed[IDX].pending += tval;                               // 1.5x for user
		balances[addr].owed[IDX].initial += tval;
		nextBlock();
		emit event_deposit(val, usrmsg);
	}
	
	function deposit(bytes32 usrmsg) public payable {
		require(msg.value >= 0.001 ether, "not enough ether");
		pyramid(msg.sender, msg.value, usrmsg);
	}
	
	function reinvest(uint256 val, bytes32 usrmsg) public {
		require(val <= balances[msg.sender].ebalance && 
				val > 0.001 ether, "no funds");
		balances[msg.sender].ebalance -= val;
		pyramid(msg.sender, val, usrmsg);
	}	
	
	function mine1000(uint256 blk) public {
		require(balances[msg.sender].owed[blk].idx < IDX && blk < IDX, "current block");
		require(balances[msg.sender].owed[blk].pending > 0.001 ether, "no more divs");
		uint256 cdiv = 0;
		for(uint256 i = 0; i < 1000; i++) {
			cdiv = (balances[msg.sender].owed[blk].pending *
                    blockData[balances[msg.sender].owed[blk].idx].dividend ) / 100 ether; // get %
			cdiv = (cdiv > balances[msg.sender].owed[blk].pending)?     
						balances[msg.sender].owed[blk].pending : cdiv;          // check for overflow
			balances[msg.sender].owed[blk].idx += 1;                            // update the index
			balances[msg.sender].owed[blk].pending -= cdiv;
			balances[msg.sender].ebalance += cdiv;
			if( balances[msg.sender].owed[blk].pending == 0 || 
			    balances[msg.sender].owed[blk].idx >= IDX ) 
				return;
		}
	}

    // events ------------------------------------------------------------------
    event event_withdraw(address addr, uint256 val);
    event event_deposit(uint256 val, bytes32 umsg);
    event event_consul(uint256 val, bytes32 umsg);
    event event_divblk(uint256 idx);
}