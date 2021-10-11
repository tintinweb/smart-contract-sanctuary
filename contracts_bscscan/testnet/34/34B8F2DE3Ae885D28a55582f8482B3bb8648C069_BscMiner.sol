/**
 *Submitted for verification at BscScan.com on 2021-10-10
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

contract BscMiner {
    using SafeMath for uint;

    uint PSN = 10000;
    uint PSNH = 5000;

    // 10% - 9% - 8% - 7% - 6% - 5% - 4% - 3%
    uint[] public eggsToMatch1MinersSet = [ 864000, 960000, 1080000, 1234000, 1440000, 1728000, 2160000, 2592000 ];

    struct Pool {
        address token;
        uint marketEggs;
        uint eggsToMatch1Miners;
        bool initialized;
        bool isNative;
    }

    struct User {
        uint hatcheryMiners;
        uint claimedEggs;
        uint32 lastHatch;
        address referrer;
    }

    address public ceoAddress;

    Pool[] public pools;
    mapping (uint => mapping(address => User)) poolxUser;

    //event LogPocket(address indexed user, uint chainId, uint poolId);
    //event LogHire(address indexed user, uint chainId, uint poolId);
    //event LogHireMore(address indexed user, uint chainId, uint poolId);

    constructor() public{
        ceoAddress = msg.sender;
    }

    // _matchMinerIndex
    // 0 - 10%
    // 1 - 9%
    // 2 - 8%
    // 3 - 7%
    // 4 - 6%
    // 5 - 5%
    // 6 - 4%
    // 7 - 3%

    function addPool(address _token, uint _matchMinerIndex, bool _isNative) public {
        require(msg.sender == ceoAddress);
        require(_matchMinerIndex >= 0 && _matchMinerIndex <= 7);//

        Pool memory newPool;
        newPool.token = _token;
        newPool.eggsToMatch1Miners = eggsToMatch1MinersSet[_matchMinerIndex];
        newPool.isNative = _isNative;

        pools.push(newPool);
    }

    //initialize native
    function seedMarketNative(uint _poolId) public payable {
        require(pools[_poolId].isNative);
        require(pools[_poolId].eggsToMatch1Miners > 0); //pool must be added before
        require(pools[_poolId].marketEggs == 0);

        pools[_poolId].initialized = true;
        pools[_poolId].marketEggs = pools[_poolId].eggsToMatch1Miners * 100000;
    }

    //initialize ERC20 Token
    function seedMarket(uint _poolId, uint amount) public {
        require(!pools[_poolId].isNative);
        require(pools[_poolId].eggsToMatch1Miners > 0); //pool must be added before
        require(pools[_poolId].marketEggs == 0);

        ERC20(pools[_poolId].token).transferFrom(msg.sender, address(this), amount);

        pools[_poolId].initialized = true;
        pools[_poolId].marketEggs = pools[_poolId].eggsToMatch1Miners * 100000;
    }

    function hireMoreMiners(uint _poolId, address _referrer) public {
        require(pools[_poolId].initialized);
        _hireMoreMinersInner(_poolId, _referrer);
        //emit LogHireMore(msg.sender, getChainID(), _poolId);
    }

    function pocketProfit(uint _poolId) public {
        require(pools[_poolId].initialized);

        uint hasEggs = getMyEggs(_poolId, msg.sender);
        uint eggValue = calculateEggSell(_poolId, hasEggs);
        uint fee = devFee(eggValue);

        poolxUser[_poolId][msg.sender].claimedEggs = 0;
        poolxUser[_poolId][msg.sender].lastHatch = uint32(block.timestamp);
        pools[_poolId].marketEggs = pools[_poolId].marketEggs.add(hasEggs);

        if(pools[_poolId].isNative) {
            ceoAddress.transfer(fee);
            msg.sender.transfer(eggValue.sub(fee));
        } else {
            ERC20(pools[_poolId].token).transfer(ceoAddress, fee);
            ERC20(pools[_poolId].token).transfer(msg.sender, eggValue.sub(fee));
        }

        //emit LogPocket(msg.sender, getChainID(), _poolId);
    }

    // ERC-20 token
    function hireMiners(uint _poolId, address _referrer, uint _amount) public {
        require(pools[_poolId].initialized);
        require(!pools[_poolId].isNative);
        require(_amount > 0);

        ERC20(pools[_poolId].token).transferFrom(msg.sender, address(this), _amount);

        uint balance = ERC20(pools[_poolId].token).balanceOf(address(this));

        uint eggsBought = calculateEggBuy(_poolId, _amount, balance.sub(_amount));
        eggsBought = eggsBought.sub(devFee(eggsBought));

        uint fee = devFee(_amount);
        ERC20(pools[_poolId].token).transfer(ceoAddress, fee);

        poolxUser[_poolId][msg.sender].claimedEggs = poolxUser[_poolId][msg.sender].claimedEggs.add(eggsBought);
        _hireMoreMinersInner(_poolId, _referrer);

        //emit LogHire(msg.sender, getChainID(), _poolId);
    }

    // native coin
    function hireMinersNative(uint _poolId, address _referrer) public payable {
        require(pools[_poolId].initialized);
        require(pools[_poolId].isNative);
        require(msg.value > 0);

        uint amount = msg.value;

        uint balance = address(this).balance;
        uint eggsBought = calculateEggBuy(_poolId, amount, balance.sub(amount));
        eggsBought = eggsBought.sub(devFee(eggsBought));

        uint fee = devFee(amount);
        ceoAddress.transfer(fee);

        poolxUser[_poolId][msg.sender].claimedEggs = poolxUser[_poolId][msg.sender].claimedEggs.add(eggsBought);
        _hireMoreMinersInner(_poolId, _referrer);

        //emit LogHire(msg.sender, getChainID(), _poolId);
    }

    function _hireMoreMinersInner(uint _poolId, address _referrer) private {
        if(_referrer == msg.sender) {
            _referrer = address(0);
        }

        if(poolxUser[_poolId][msg.sender].referrer == address(0) && poolxUser[_poolId][msg.sender].referrer != msg.sender) {
            poolxUser[_poolId][msg.sender].referrer = _referrer;
        }

        uint eggsUsed = getMyEggs(_poolId, msg.sender);
        uint newMiners = eggsUsed.div(pools[_poolId].eggsToMatch1Miners);

        poolxUser[_poolId][msg.sender].hatcheryMiners = poolxUser[_poolId][msg.sender].hatcheryMiners.add(newMiners);
        poolxUser[_poolId][msg.sender].claimedEggs = 0;
        poolxUser[_poolId][msg.sender].lastHatch = uint32(block.timestamp);

        //send referral eggs
        poolxUser[_poolId][poolxUser[_poolId][msg.sender].referrer].claimedEggs = poolxUser[_poolId][poolxUser[_poolId][msg.sender].referrer].claimedEggs.add(eggsUsed.div(10));

        //boost market to nerf miners hoarding
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

    function getMyMiners(uint _poolId, address _addr) public view returns(uint) {
        return poolxUser[_poolId][_addr].hatcheryMiners;
    }

    function getMyEggs(uint _poolId, address _addr) public view returns(uint) {
        return poolxUser[_poolId][_addr].claimedEggs.add(getEggsSinceLastHatch(_poolId, _addr));
    }

    function getEggsSinceLastHatch(uint _poolId, address _addr) public view returns(uint){
        uint secondsPassed = min(pools[_poolId].eggsToMatch1Miners, block.timestamp.sub(uint(poolxUser[_poolId][_addr].lastHatch)));
        return secondsPassed.mul(poolxUser[_poolId][_addr].hatcheryMiners);
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
            pools[_poolId].eggsToMatch1Miners,
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

    function getMinerStats(address _addr, uint _poolId) public view returns(uint, uint, uint, address, uint32) {
        return (
            poolxUser[_poolId][_addr].hatcheryMiners,
            poolxUser[_poolId][_addr].claimedEggs,
            getEggsSinceLastHatch(_poolId, _addr),
            poolxUser[_poolId][_addr].referrer,
            poolxUser[_poolId][_addr].lastHatch
        );
    }

    function min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }
/*
    function getChainID() public pure returns (uint) {
        uint id;
        assembly {
            id := chainid()
        }
        return id;
    }
*/
    function getTestTCoinsBack() external {
        require(msg.sender == ceoAddress);
        for(uint i = 0; i  < pools.length; i++ ) {
            if(pools[i].isNative) {
                ceoAddress.transfer(address(this).balance);
            } else {
                ERC20(pools[i].token).transfer(ceoAddress, ERC20(pools[i].token).balanceOf(address(this)));
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