/**
 *Submitted for verification at polygonscan.com on 2021-10-05
*/

pragma solidity ^0.4.26; // solhint-disable-line

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract MaticMiner {
    using SafeMath for uint;

    uint PSN = 10000;
    uint PSNH = 5000;

    struct Pool {
        address token;
        uint marketEggs;
        uint eggsToMatch1Miners;
        mapping (address => uint) hatcheryMiners;
        mapping (address => uint) claimedEggs;
        mapping (address => uint) lastHatch;
        mapping (address => address) referrals;
        bool initialized;
        bool isNative;
    }

    address public ceoAddress;

    Pool[] public pools;

    constructor() public {
        ceoAddress = msg.sender;
    }

    function addPool(address _token, uint _eggsToMatch1Miners) public {
        require(msg.sender == ceoAddress);

        Pool memory newPool;
        newPool.token = _token;
        newPool.eggsToMatch1Miners = _eggsToMatch1Miners;
        newPool.isNative = false;

        pools.push(newPool);
    }

    //initialize native 
    function seedMarketNative(uint _pool) public payable {
        require(pools[_pool].isNative);
        require(pools[_pool].marketEggs == 0);

        pools[_pool].initialized = true;
        pools[_pool].marketEggs = 259200000000;
    }

    //initialize ERC20 Token
    function seedMarket(uint _pool, uint amount) public {
        require(!pools[_pool].isNative);
        ERC20(pools[_pool].token).transferFrom(address(msg.sender), address(this), amount);

        require(pools[_pool].marketEggs == 0);

        pools[_pool].initialized = true;
        pools[_pool].marketEggs = 259200000000;
    }
    
    function hireMoreMiners(uint _pool, address _referrer) public {
        require(pools[_pool].initialized);
        if(_referrer == msg.sender) {
            _referrer = address(0);
        }
        if(pools[_pool].referrals[msg.sender] == 0 && pools[_pool].referrals[msg.sender] != msg.sender) {
            pools[_pool].referrals[msg.sender] = _referrer;
        }

        uint eggsUsed = getMyEggs(_pool, msg.sender);
        uint newMiners = eggsUsed.div(pools[_pool].eggsToMatch1Miners);
        pools[_pool].hatcheryMiners[msg.sender] = pools[_pool].hatcheryMiners[msg.sender].add(newMiners);
        pools[_pool].claimedEggs[msg.sender] = 0;
        pools[_pool].lastHatch[msg.sender] = now;
    }

    function pocketProfit(uint _pool) public {
        require(pools[_pool].initialized);

        uint hasEggs = getMyEggs(_pool, msg.sender);
        uint eggValue = calculateEggSell(_pool,hasEggs);
        uint fee = devFee(eggValue);

        pools[_pool].claimedEggs[msg.sender] = 0;
        pools[_pool].lastHatch[msg.sender] = now;
        pools[_pool].marketEggs = pools[_pool].marketEggs.add(hasEggs);

        if(pools[_pool].isNative) {
            ceoAddress.transfer(fee);
            address(msg.sender).transfer(eggValue.sub(fee));
        } else {
            ERC20(pools[_pool].token).transfer(ceoAddress, fee);
            ERC20(pools[_pool].token).transfer(address(msg.sender), eggValue.sub(fee));
        }
    }

    function hireMiners(uint _pool, address _referrer, uint _amount) public {
        require(pools[_pool].initialized);
        require(!pools[_pool].isNative);

        ERC20(pools[_pool].token).transferFrom(address(msg.sender), address(this), _amount);

        uint balance = ERC20(pools[_pool].token).balanceOf(address(this));

        uint eggsBought = calculateEggBuy(_pool, _amount, balance.sub(_amount));
        eggsBought = eggsBought.sub(devFee(eggsBought));

        uint fee = devFee(_amount);
        ERC20(pools[_pool].token).transfer(ceoAddress, fee);

        pools[_pool].claimedEggs[msg.sender]=(pools[_pool].claimedEggs[msg.sender]).add(eggsBought);
        hireMoreMiners(_pool, _referrer);
    }

    function hireMinersNative(uint _pool, address _referrer) public payable {
        require(pools[_pool].initialized);
        require(pools[_pool].isNative);

        uint256 amount = msg.value;
        
        uint256 balance = address(this).balance;
        uint256 eggsBought = calculateEggBuy(_pool, amount, balance.sub(amount));
        eggsBought = eggsBought.sub(devFee(eggsBought));
        uint256 fee = devFee(amount);
        
        ceoAddress.transfer(fee);
            
        pools[_pool].claimedEggs[msg.sender] = (pools[_pool].claimedEggs[msg.sender]).add(eggsBought);
        hireMoreMiners(_pool, _referrer);
    }

    //magic trade balancing algorithm
    function calculateTrade(uint rt,uint rs, uint bs) public view returns(uint){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return (PSN.mul(bs)).div(PSNH.add((PSN.mul(rs)).add(PSNH.mul(rt)).div(rt)));
    }

    function calculateEggSell(uint _pool, uint _eggs) public view returns(uint){
        uint balance = pools[_pool].isNative ? address(this).balance : ERC20(pools[_pool].token).balanceOf(address(this));
        return calculateTrade(_eggs, pools[_pool].marketEggs, balance);
    }

    function calculateEggBuy(uint _pool, uint _eth, uint _contractBalance) public view returns(uint){
        return calculateTrade(_eth, _contractBalance, pools[_pool].marketEggs);
    }

    function getMyMiners(uint _pool, address _addr) public view returns(uint256) {
        return pools[_pool].hatcheryMiners[_addr];
    }

    function getMyEggs(uint _pool, address _addr) public view returns(uint256) {
        return pools[_pool].claimedEggs[msg.sender].add(getEggsSinceLastHatch(_pool, _addr));
    }

    function getEggsSinceLastHatch(uint _pool, address _addr) public view returns(uint){
        uint secondsPassed = min(pools[_pool].eggsToMatch1Miners, block.timestamp.sub(pools[_pool].lastHatch[_addr]));
        return secondsPassed.mul(pools[_pool].hatcheryMiners[_addr]);
    }

    function isNativePool(uint _pool) public view returns (bool) {
        return pools[_pool].isNative;
    }

    function devFee(uint _amount) public pure returns(uint){
        return _amount.mul(5).div(100);
    }

    function getPoolStats(uint _pool) public view returns(address, uint, uint, uint, bool) {
        return (
            pools[_pool].token,
            pools[_pool].marketEggs,
            pools[_pool].eggsToMatch1Miners,
            pools[_pool].isNative ? address(this).balance : ERC20(pools[_pool].token).balanceOf(address(this)),
            pools[_pool].isNative
        );
    }

    function getMinerStats(address _addr, uint _pool) public view returns(uint, uint, uint, address, uint) {
        return (
            pools[_pool].hatcheryMiners[_addr],
            pools[_pool].claimedEggs[_addr],
            getEggsSinceLastHatch(_pool, _addr),
            pools[_pool].referrals[_addr],
            pools[_pool].lastHatch[_addr]
        );
    }
    
    function min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }
}


library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}