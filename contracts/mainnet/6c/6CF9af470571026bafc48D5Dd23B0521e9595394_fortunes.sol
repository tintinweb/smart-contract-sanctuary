pragma solidity ^0.4.24;


contract fortunes {
    
    string public standard = &#39;Fortunes&#39;;
    string public name;
    string public symbol;
    uint8 public decimals;
    
    address owner;
    uint public max_fortunes;
    uint public unopened_bid;
    bytes32[] public ur_luck;                      // store lucky say
    
    struct fortune {
        address original_owner;                     // one who opened
        address original_minter;                    // one who marked
        address current_owner;
        uint32 number;
        uint8 level;
        bytes32[144] img;
        bytes32 str_luck;                           // 32 char max luck
        bytes32 str_name;                           // 32 char max name
        bool has_img;   
        bool opened;                                // opened has set the lvl and luck
        bool forsale;                       
        uint current_bid;
        address current_bidder;
        uint bid_cnt;                               // times bid on this sale
        uint auction_end;                           // time to end the auction
    }
    
    fortune[] public fortune_arr;                   // fortunes cannot be deleted
    mapping(uint8 => uint8) public lvl_count;       // cnt each lvl fortunes
    mapping(address => uint) public pending_pay;    // pending withdrawals
    
    uint tax;
	uint public fortune_limitbreak;				    // current limitbreak ammount
	uint public fortune_break_current;				// current ammount of ether for limitbreak
    
    
    modifier only_owner() 
        { require(msg.sender == owner, &quot;only owner can call.&quot;); _; }
    modifier only_currowner(uint _idx) 
        { require(fortune_arr[_idx].current_owner == msg.sender, &quot;you&#39;re not the owner&quot;); _; }
    modifier idx_inrange(uint _idx)
        { require(_idx >= 0 && _idx < fortune_arr.length, &quot;idx out of range&quot;); _; }
        
        
    constructor() public {
        owner = (msg.sender);
        max_fortunes = 5000;
        unopened_bid = 0.014 ether;
        tax = 50; // N/25 = 4% 
		fortune_limitbreak = 2 ether;
        
        name = &quot;FORTUNES&quot;;
        symbol = &quot;4TN&quot;;
        decimals = 0;
        
        // initial luck
        ur_luck.push(&quot;The WORST Possible&quot;);
        ur_luck.push(&quot;Terrible&quot;);
        ur_luck.push(&quot;Bad&quot;);
        ur_luck.push(&quot;Exactly Average&quot;);
        ur_luck.push(&quot;Good&quot;);
        ur_luck.push(&quot;Excellent&quot;);
        ur_luck.push(&quot;The BEST Possible&quot;);
    }
    
    function is_owned(uint _idx) public view idx_inrange(_idx) returns(bool) 
        { return msg.sender == fortune_arr[_idx].current_owner; }
	
    function ret_len() public view returns(uint) { return fortune_arr.length; }
    
    function ret_luklen () public view returns(uint) { return ur_luck.length; }
    
	function ret_img(uint _idx) public idx_inrange(_idx) view returns(bytes32[144]) {
		return fortune_arr[_idx].img;
	}
    
    function fortune_new() public payable {
		require(msg.value >= unopened_bid || 
		        msg.sender == owner || 
		        fortune_arr.length <= 500, 
		        &quot;ammount below unopened bid&quot;);
        require(fortune_arr.length <= max_fortunes,&quot;fortunes max reached&quot;);
        fortune memory x;
        x.current_owner = msg.sender;
		x.number = uint32(fortune_arr.length);
		unopened_bid += unopened_bid/1000; // 0.01% increase
        fortune_arr.push(x);
        pending_pay[owner]+= msg.value;
        emit event_new(fortune_arr.length-1);
    }
    
    function fortune_open(uint _idx) public idx_inrange(_idx) only_currowner(_idx) {
        require(!fortune_arr[_idx].opened, &quot;fortune is already open&quot;);
        require(!fortune_arr[_idx].forsale, &quot;fortune is selling&quot;);
        fortune_arr[_idx].original_owner = msg.sender;
        uint _ran = arand(fortune_arr[_idx].current_owner, now)%1000;
        uint8 clvl = 1;
        if (_ran <= 810) clvl = 2;
        if (_ran <= 648) clvl = 3;
        if (_ran <= 504) clvl = 4;
        if (_ran <= 378) clvl = 5;
        if (_ran <= 270) clvl = 6;
        if (_ran <= 180) clvl = 7;
        if (_ran <= 108) clvl = 8;
        if (_ran <= 54)  clvl = 9;
        if (_ran <= 18)  clvl = 10;

        fortune_arr[_idx].level = clvl;
        fortune_arr[_idx].opened = true;
        fortune_arr[_idx].str_luck = 
            ur_luck[arand(fortune_arr[_idx].current_owner, now)% ur_luck.length];
        
        // first fortune in honor of mai waifu
        if(_idx == 0) {
            fortune_arr[_idx].level = 0;
            fortune_arr[_idx].str_luck = ur_luck[6];
            lvl_count[0] += 1;
        } else lvl_count[clvl] += 1;    
        emit event_open(_idx);
    }
    
    // mint fortune
    function fortune_setimgnme(uint _idx, bytes32[144] _imgarr, bytes32 _nme) 
        public idx_inrange(_idx) only_currowner(_idx) {
        require(fortune_arr[_idx].opened, &quot;fortune has to be opened&quot;);
        require(!fortune_arr[_idx].has_img, &quot;image cant be reset&quot;);
        require(!fortune_arr[_idx].forsale, &quot;fortune is selling&quot;);
        fortune_arr[_idx].original_minter = fortune_arr[_idx].current_owner;
        for(uint i = 0; i < 144; i++)
            fortune_arr[_idx].img[i] = _imgarr[i];
        fortune_arr[_idx].str_name = _nme;
        emit event_mint(_idx);
        fortune_arr[_idx].has_img = true;
    }
    
    // start auction
    function fortune_sell(uint _idx, uint basebid, uint endt) 
        public idx_inrange(_idx) only_currowner(_idx) {
        require(_idx > 0, &quot;I&#39;ll always be here with you.&quot;);
        require(!fortune_arr[_idx].forsale, &quot;already selling&quot;);
        require(endt <= 7 days, &quot;auction time too long&quot;);
        fortune_arr[_idx].current_bid = basebid;
        fortune_arr[_idx].auction_end = now + endt;
        fortune_arr[_idx].forsale = true;
        emit event_sale(_idx);
    }
    
    // bid auction
    function fortune_bid(uint _idx) public payable idx_inrange(_idx) {
        require(fortune_arr[_idx].forsale, &quot;fortune not for sale&quot;);
        require(now < fortune_arr[_idx].auction_end, &quot;auction ended&quot;);
        require(msg.value > fortune_arr[_idx].current_bid, 
            &quot;new bid has to be higher than current&quot;);

        // return the previous bid        
        if(fortune_arr[_idx].bid_cnt != 0) 
            pending_pay[fortune_arr[_idx].current_bidder] += 
                fortune_arr[_idx].current_bid;
        
        fortune_arr[_idx].current_bid = msg.value;
        fortune_arr[_idx].current_bidder = msg.sender;
        fortune_arr[_idx].bid_cnt += 1;
        emit event_bids(_idx);
    }
    
    // end auction
    function fortune_endauction(uint _idx) public idx_inrange(_idx) {
        require(now >= fortune_arr[_idx].auction_end,&quot;auction is still going&quot;);
        require(fortune_arr[_idx].forsale, &quot;fortune not for sale&quot;);
        
        // sale
        if(fortune_arr[_idx].bid_cnt > 0) {
    		uint ntax = fortune_arr[_idx].current_bid/tax;              // 2%
    		uint otax = fortune_arr[_idx].current_bid/tax;               // 2% 
    		uint ftax = ntax;

            pending_pay[owner] += ntax;
    		if(fortune_arr[_idx].opened) { 
    		    ftax+= otax; 
    		    pending_pay[fortune_arr[_idx].original_owner] += otax; 
    		}                  
    		if(fortune_arr[_idx].has_img) { 
    		    ftax+= otax; 
    		    pending_pay[fortune_arr[_idx].original_minter] += otax; 
    		}             
    		pending_pay[fortune_arr[_idx].current_owner] += 
                fortune_arr[_idx].current_bid-ftax; 
                
            fortune_arr[_idx].current_owner = 
                fortune_arr[_idx].current_bidder;
            emit event_sold(_idx, fortune_arr[_idx].current_owner);
        }
        
        // reset bid
        // current bid doesnt reset to save last sold price
        fortune_arr[_idx].forsale = false;
        fortune_arr[_idx].current_bidder = 0;
        fortune_arr[_idx].bid_cnt = 0;
        fortune_arr[_idx].auction_end = 0;
    }
    
    
    function withdraw() public {
        require(pending_pay[msg.sender]>0, &quot;insufficient funds&quot;);
        uint _pay = pending_pay[msg.sender];
        pending_pay[msg.sender] = 0;
        msg.sender.transfer(_pay);
        emit event_withdraw(msg.sender, _pay);
    }
    
    function add_luck(bytes32 _nmsg) public payable {
        require(msg.value >= unopened_bid, 
            &quot;adding a fortune label costs the unopened_bid eth&quot;);
        ur_luck.push(_nmsg);
        pending_pay[owner] += msg.value;
        emit event_addluck(msg.sender);
    } 
    
    function limitbreak_contrib() public payable {
		fortune_break_current += msg.value;
		emit event_limitbreak_contrib(msg.sender, msg.value);
	}
	
    function limitbreak_RELEASE() public {
		require(fortune_break_current >= fortune_limitbreak, 
			&quot;limit breaking takes a few hits more&quot;);
		require(fortune_arr.length >= max_fortunes, &quot;limit not reached yet&quot;);
        max_fortunes += max_fortunes + 500;
		pending_pay[owner]+= fortune_break_current;
		fortune_break_current = 0;
		if(fortune_limitbreak >= 128 ether) fortune_limitbreak = 32 ether;
		else fortune_limitbreak *= 2;
		emit event_limitbreak(fortune_limitbreak);
    }
    
    
    function arand(address _addr, uint seed) internal view returns(uint) {
        return uint
            (keccak256
                (abi.encodePacked(blockhash(block.number-1), seed, uint(_addr))));
    }
    
    // erc20 semi 
    function totalSupply() public constant returns (uint) { return max_fortunes; }
    function balanceOf(address tokenOwner) public constant returns (uint balance)
        { return pending_pay[tokenOwner]; }
        
    function giveTo(uint _idx, address _addr) public idx_inrange(_idx) only_currowner(_idx) {
        fortune_arr[_idx].current_owner = _addr;
    }
    
    
    // events
    event event_new(uint _idx);                                     //[x]
    event event_open(uint _idx);                                    //[x]
    event event_mint(uint _idx);                                    //[x]
    event event_sale(uint _idx);                                    //[x]
    event event_bids(uint _idx);                                    //[x]
    event event_sold(uint _idx, address _newowner);                 //[x]
    event event_addluck(address _addr);                             //[x]
    event event_limitbreak(uint newlimit);                          //[x]
    event event_limitbreak_contrib(address _addr, uint _ammount);   //[x]
    event event_withdraw(address _addr, uint _ammount);             //[x]

}