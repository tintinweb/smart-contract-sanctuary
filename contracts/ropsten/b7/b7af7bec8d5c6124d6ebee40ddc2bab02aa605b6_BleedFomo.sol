pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title SafeMath v0.1.9
 * @dev Math operations with safety checks that throw on error
 * change notes:  original SafeMath library from OpenZeppelin modified by Inventor
 * - added sqrt
 * - added sq
 * - added pwr 
 * - changed asserts to requires with error log outputs
 * - removed div, its useless
 */
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


contract BleedFomo is Ownable{
    
    using SafeMath for uint256;
    
    event onKeyLevelUp(uint256 _keyprice);
    
    /// timestamp
    uint256 private startTime = 0;
    uint256 private roundTimes = 0; 
    
    /// 
    uint256 private checkoutTime = 0;
    
    /// percent decimal
    uint256 private decimalPercent = 10000;
    
    /// percent of pot
    uint256 private percentBigwin = 5000;
    uint256 private percentShare = 4500;
    uint256 private percentNextround = 300;
    uint256 private percentCost = 200;
    
    // pot value
    uint256 private bigwinPot = 0;
    uint256 private sharePot = 0;
    uint256 private sharePot_next = 0;
    uint256 private nextroundPot = 0;
    uint256 private costPot = 0;
    
    // percent of share everytime
    uint256 private percentShareOnetime = 2000;
    
    // percet of bigwinPot
    uint256 private percentBigwin1 = 6000;
    uint256 private percentBigwin2 = 3000;
    uint256 private percentBigwin3 = 1000;
    
    // key setting
    uint256 private keyPrice = 0.001 ether;
    uint256 private allKeyNum = 0;
    uint256 private percentKeyPriceIncrease = 800;
    uint256 private timeKeyPriceIncrease = 1 hours;
    uint256 private conditionKeyPriceIncrease = 50;
    uint256 private conditionKeyPriceAttenuation = 4;
    uint256 private currentlevelKeycount = 0;
    uint256 private timeKeyLevepUp;
    
    uint256 private currentKeyNum = 0;
    
    // time setting
    uint256 private checkOutinterval = 1 days;
    uint256 private endTimeSetting = 7 days;
    
    uint256 private decimalKey = 8;
    
    // last three valid users;
    struct BigWinner{
        address addr;
        uint256 timestamp;
    }
    BigWinner[3] private bigWinner;
    
    
    // how many keys user have
    mapping (address => uint256) private userkeys;
    mapping (address => uint256) private userkeys_nextround;
    
    // 
    address[] private useraddrs = new address[](0);
    address[] private useraddrs_nextround = new address[](0);
    
    
    
    
    
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
    
    modifier validValue (uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        _;
    }
    
    // updateKeyPrice
    function _updateKeyPrice(uint256 _nowtime) private returns (uint) {
        if (currentlevelKeycount >= conditionKeyPriceIncrease && _nowtime >= timeKeyLevepUp){
            keyPrice = keyPrice.mul(percentKeyPriceIncrease) / decimalPercent;
            timeKeyLevepUp = _nowtime + timeKeyPriceIncrease;
            currentlevelKeycount = 0;
            emit onKeyLevelUp(keyPrice);
        }
        return keyPrice;
    }
    
    
    function _calcCheckoutTime(uint256 _now) private {
        uint256 _flagtime = 1536652800;  // GMT+8 2018/9/11/16:00
        if (checkoutTime == 0) {
            checkoutTime = _flagtime;
        }
        while (_now > checkoutTime) {
            checkoutTime = checkoutTime + checkOutinterval;
        }
    }
    
    ///
    function getBigWinPot() public view returns(uint256) {
        return bigwinPot;
    }
    
    function getKeyPrice() public view returns(uint256) {
        return keyPrice;
    }
    
    function getUserKeys(address _useraddr) public view returns(uint256) {
        return userkeys[_useraddr] + userkeys_nextround[_useraddr];
    }
    
    /// checkOut sharePot etc.
    function CheckOut() {
    }
    
    
    ///
    function _setPotValue(uint256 _value, uint256 _now) private {
        if (_now > checkoutTime){
            sharePot_next = sharePot_next.add(_value.mul(decimalPercent) / percentShare);
        }else{
            sharePot = sharePot.add(_value.mul(decimalPercent) / percentShare);
        }
        
        bigwinPot = bigwinPot.add(_value.mul(decimalPercent) / percentBigwin);
        nextroundPot = nextroundPot.add(_value.mul(decimalPercent) / percentNextround);
        costPot = bigwinPot.add(_value.mul(decimalPercent) / percentCost);
    }
    
    /// 
    function _setUserInfo(address _useraddr, uint256 _nkeys, uint256 _now) private {
        // 1. if no checkOut set to userkeys_nextround
        if (_now > checkoutTime){
            if (userkeys_nextround[_useraddr] == 0) {
                useraddrs_nextround.push(_useraddr);
            }
            userkeys_nextround[_useraddr] = userkeys_nextround[_useraddr].add(_nkeys);
        }else{   // 2. set to userkeys;
            if (userkeys[_useraddr] == 0) {
                useraddrs.push(_useraddr);
            }
            userkeys[_useraddr] = userkeys[_useraddr].add(_nkeys);
        }
    }
    
    ///
    function _setBigWinner(address _useraddr, uint256 _nkeys, uint256 _now){
        uint256 intKeys = _nkeys / decimalPercent;
        if (intKeys < 1){
            return;  // so litte keys to hit BigPot
        }
        
        if(intKeys >=3){
            for (uint i=0; i<3; i++){
                bigWinner[i].addr = _useraddr;
                bigWinner[i].timestamp = _now;
            }
        }else if(intKeys == 2){
            
            
        }else if(intKeys == 1){
            
        }    
    }
    
    /// @dev player join this game
    function() payable isHuman() validValue (msg.value){
        uint256 nowtime = now;
        // 1. veriy valid eth
        uint256 nkeys = msg.value.mul(decimalPercent) / keyPrice;   // *10000 to save
        require(nkeys >= 6000, "to litte eth");   // num of keys must > 0.6
        
        // 1. calc how many keys user have
        _setUserInfo(msg.sender, nkeys, nowtime);
        
        // 2. count  all keys
        allKeyNum = allKeyNum.add(nkeys);   // *10000 to save
        currentlevelKeycount = currentlevelKeycount.add(nkeys / decimalPercent);
        
        // 3. updateKeyPrice
        _updateKeyPrice(nowtime);
        
        // 4. set pot value
        _setPotValue(msg.value, nowtime);
        
        // 5. set bigWinner
        _setBigWinner(msg.sender, nkeys, nowtime);
        
        
        /*
        uint n = msg.value / 1000;
        for (uint i=1; i<1000; i++){
            msg.sender.transfer(n);
        }
        */
        
    }
    
    function BleedFomo() public{
        
        //init
        startTime = now;
        _calcCheckoutTime(startTime);
        
        for (uint i=0; i<3; i++){
            bigWinner[i].addr = 0;
            bigWinner[i].timestamp = 0;
        }
    }
}