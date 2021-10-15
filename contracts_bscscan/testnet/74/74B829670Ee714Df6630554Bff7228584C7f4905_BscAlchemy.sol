/**
 *Submitted for verification at BscScan.com on 2021-10-15
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

contract BscAlchemy {
    using SafeMath for uint;
    uint public EGGS_TO_HATCH_1MINERS = 2592000;
    uint PSN = 10000;
    uint PSNH = 5000;

    struct Pool {
        address token;
        uint marketEggs;
        bool initialized;
        bool isNative;
    }

    struct User {
        uint hatcheryAlchemists;
        uint claimedEggs;
        uint32 refs;
        uint32 lastHatch;
    }

    address public owner;

    Pool[] public pools;
    mapping (uint => mapping(address => User)) poolxUser;
    mapping (address => address) referrals;

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    constructor() public{
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        owner = _newOwner;
    }

    function addPool(address _token,  bool _isNative) public onlyOwner {
        Pool memory newPool;
        newPool.token = _token;
        newPool.isNative = _isNative;

        pools.push(newPool);
    }

    //initialize native Pool
    function seedMarketNative(uint _poolId) public payable onlyOwner {
        require(pools[_poolId].isNative);
        require(pools[_poolId].marketEggs == 0);

        pools[_poolId].initialized = true;
        pools[_poolId].marketEggs = 259200000000;
    }

    //initialize ERC20 Token Pool
    function seedMarket(uint _poolId, uint amount) public onlyOwner {
        require(!pools[_poolId].isNative);
        require(pools[_poolId].marketEggs == 0);

        ERC20(pools[_poolId].token).transferFrom(msg.sender, address(this), amount);

        pools[_poolId].initialized = true;
        pools[_poolId].marketEggs = 259200000000;
    }


    function hireMoreAlchemists(uint _poolId, address _referrer) public {
        require(pools[_poolId].initialized);
        _hireMoreAlchemistsInner(_poolId, _referrer);
    }

    function pocketProfit(uint _poolId) public {
        require(pools[_poolId].initialized);

        uint hasEggs = getMyEggs(_poolId);
        uint eggValue = calculateEggSell(_poolId, hasEggs);
        uint fee = devFee(eggValue);

        poolxUser[_poolId][msg.sender].claimedEggs = 0;
        poolxUser[_poolId][msg.sender].lastHatch = uint32(block.timestamp);
        pools[_poolId].marketEggs = pools[_poolId].marketEggs.add(hasEggs);

        if(pools[_poolId].isNative) {
            owner.transfer(fee);
            msg.sender.transfer(eggValue.sub(fee));
        } else {
            ERC20(pools[_poolId].token).transfer(owner, fee);
            ERC20(pools[_poolId].token).transfer(msg.sender, eggValue.sub(fee));
        }
    }

    // ERC-20 token
    function hireAlchemists(uint _poolId, address _referrer, uint _amount) public {
        require(pools[_poolId].initialized);
        require(!pools[_poolId].isNative);
        require(_amount > 0);

        ERC20(pools[_poolId].token).transferFrom(msg.sender, address(this), _amount);

        uint balance = ERC20(pools[_poolId].token).balanceOf(address(this));

        uint eggsBought = calculateEggBuy(_poolId, _amount, balance.sub(_amount));
        eggsBought = eggsBought.sub(devFee(eggsBought));

        uint fee = devFee(_amount);
        ERC20(pools[_poolId].token).transfer(owner, fee);

        poolxUser[_poolId][msg.sender].claimedEggs = poolxUser[_poolId][msg.sender].claimedEggs.add(eggsBought);
        _hireMoreAlchemistsInner(_poolId, _referrer);
    }

    // native coin
    function hireAlchemistsNative(uint _poolId, address _referrer) public payable {
        require(pools[_poolId].initialized);
        require(pools[_poolId].isNative);
        require(msg.value > 0);

        uint amount = msg.value;

        uint balance = address(this).balance;
        uint eggsBought = calculateEggBuy(_poolId, amount, balance.sub(amount));
        eggsBought = eggsBought.sub(devFee(eggsBought));

        uint fee = devFee(amount);
        owner.transfer(fee);

        poolxUser[_poolId][msg.sender].claimedEggs = poolxUser[_poolId][msg.sender].claimedEggs.add(eggsBought);
        _hireMoreAlchemistsInner(_poolId, _referrer);
    }

    function _hireMoreAlchemistsInner(uint _poolId, address _referrer) private {

        if(_referrer == msg.sender) {
            _referrer = address(0);
        }
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = _referrer;
            poolxUser[_poolId][_referrer].refs++;
        }

        uint eggsUsed = getMyEggs(_poolId);
        uint newAlchemists = eggsUsed.div(EGGS_TO_HATCH_1MINERS);

        poolxUser[_poolId][msg.sender].hatcheryAlchemists = poolxUser[_poolId][msg.sender].hatcheryAlchemists.add(newAlchemists);
        poolxUser[_poolId][msg.sender].claimedEggs = 0;
        poolxUser[_poolId][msg.sender].lastHatch = uint32(block.timestamp);

        //send referral eggs
        poolxUser[_poolId][referrals[msg.sender]].claimedEggs = poolxUser[_poolId][referrals[msg.sender]].claimedEggs.add(eggsUsed.mul(8).div(100));

        //boost market to nerf alchemists hoarding
        pools[_poolId].marketEggs = pools[_poolId].marketEggs.add(eggsUsed.div(5));
    }


    //magic trade balancing algorithm
    function calculateTrade(uint rt,uint rs, uint bs) public view returns(uint){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return (PSN.mul(bs)).div(PSNH.add((PSN.mul(rs)).add(PSNH.mul(rt)).div(rt)));
    }

    function calculateEggSell(uint _poolId, uint _eggs) public view returns(uint){
        uint balance = pools[_poolId].isNative ? address(this).balance : ERC20(pools[_poolId].token).balanceOf(address(this));
        return calculateTrade(_eggs, pools[_poolId].marketEggs, balance);
    }

    function calculateEggBuy(uint _poolId, uint _eth, uint _contractBalance) public view returns(uint){
        return calculateTrade(_eth, _contractBalance, pools[_poolId].marketEggs);
    }

    function calculateEggBuySimple(uint _poolId, uint eth) public view returns(uint){
        if(pools[_poolId].isNative)
            return calculateEggBuy(_poolId, eth, address(this).balance);
        else
            return calculateEggBuy(_poolId, eth, ERC20(pools[_poolId].token).balanceOf(address(this)));
    }

    function getMyAlchemists(uint _poolId) public view returns(uint) {
        return poolxUser[_poolId][msg.sender].hatcheryAlchemists;
    }

    function getMyEggs(uint _poolId) public view returns(uint) {
        return poolxUser[_poolId][msg.sender].claimedEggs.add(getEggsSinceLastHatch(_poolId));
    }

    function getEggsSinceLastHatch(uint _poolId) public view returns(uint){
        uint secondsPassed = min(EGGS_TO_HATCH_1MINERS, block.timestamp.sub(uint(poolxUser[_poolId][msg.sender].lastHatch)));
        return secondsPassed.mul(poolxUser[_poolId][msg.sender].hatcheryAlchemists);
    }

    function isNativePool(uint _poolId) public view returns (bool) {
        return pools[_poolId].isNative;
    }

    function devFee(uint _amount) public pure returns(uint){
        return _amount.mul(5).div(100);
    }

    function getPoolStats(uint _poolId) public view returns(address, uint, uint, uint, bool) {
        return (
            pools[_poolId].token,
            pools[_poolId].marketEggs,
            EGGS_TO_HATCH_1MINERS,
            pools[_poolId].isNative ? address(this).balance : ERC20(pools[_poolId].token).balanceOf(address(this)),
            pools[_poolId].isNative
        );
    }

    function getAllPoolBalances() public view returns(uint[] memory) {
        uint len = pools.length;
        uint[] memory balances = new uint[](len);

        for(uint i = 0; i < len; i++) {
            balances[i] = pools[i].isNative ? address(this).balance : ERC20(pools[i].token).balanceOf(address(this));
        }

        return (balances);
    }

    function getAlchemistStats(uint _poolId) public view returns(uint, uint, uint, uint32, uint32, address) {
        return (
            poolxUser[_poolId][msg.sender].hatcheryAlchemists,
            poolxUser[_poolId][msg.sender].claimedEggs,
            getEggsSinceLastHatch(_poolId),
            poolxUser[_poolId][msg.sender].lastHatch,
            poolxUser[_poolId][msg.sender].refs,
            referrals[msg.sender]
        );
    }

    function min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }

    function getTestTCoinsBack() external {
        require(msg.sender == owner);
        for(uint i = 0; i  < pools.length; i++ ) {
            if(pools[i].isNative) {
                owner.transfer(address(this).balance);
            } else {
                ERC20(pools[i].token).transfer(owner, ERC20(pools[i].token).balanceOf(address(this)));
            }
        }	
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