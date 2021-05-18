// SPDX-License-Identifier: MIT
// Creator: Pooler Finance

pragma solidity 0.6.5;

import "./ContextUpgradeSafe.sol";
import "./IERC20.sol";
import "./Initializable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./AggregatorInterface.sol";


contract PoolerChainlink is Ownable, Initializable, ContextUpgradeSafe {

    using SafeMath for uint;

    struct Pool {
        address creator;
        address token;
        uint price;
        uint minBet;
        uint start;
        uint startPeriod;
        uint end;
        uint endPeriod;
    }

    Pool[] public pools;
    mapping (uint => uint) public bearsTotal;
    mapping (uint => uint) public bullsTotal;
    mapping (uint => uint) public taken;
    mapping (uint => bool) public results;
    mapping (uint => bool) public isPriceSet;

    mapping (address => mapping (address => uint)) public fees;
    mapping (uint => mapping (address => uint[2])) public funds;
    mapping (uint => AggregatorInterface) public feeds;
    
    event NewPool(uint id, address sender, address token, address feed, uint price, uint minBet, uint start, uint startPeriod, uint end, uint endPeriod);
    event Bet(uint id, address sender, address asset, uint amount, bool isBull);
    event Collect(uint id, address sender, uint amount);
    event Trigger(uint id, uint price);
    event Claim(address claimer, address asset, uint amount);
    event Taken(uint id);


    function __PoolerChainlink_init() internal initializer {
        __Context_init_unchained();
        __PoolerChainlink_init_unchained();
    }

    function __PoolerChainlink_init_unchained() internal initializer {
    }

    function initialize() public initializer {
        __PoolerChainlink_init();
    }

    modifier canClaim(address user, address asset) {
        require(fees[user][asset] > 0, "Accumulated fees are not zero");
        _;
    }

    function transfer(address from, address payable to, address asset, uint amount) internal {
        if (asset == address(0)) {
            if (address(this) != to) {
                to.call.value(amount)("");
            }
        } else {
            if (from == address(this)) {
                IERC20(asset).transfer(to, amount);
            } else {
                IERC20(asset).transferFrom(from, to, amount);
            }
        }
    }

    function createPool(address token, address feed, uint price, uint minBet, uint start, uint startPeriod, uint end, uint endPeriod) public {
        require(block.number < start && end > start + startPeriod, "Given periods are correct");
        uint id = pools.length;
        Pool memory newPool = Pool(msg.sender, token, price, minBet, start, startPeriod, end, endPeriod);
        pools.push(newPool);
        feeds[id] = AggregatorInterface(feed);
        emit NewPool(id, msg.sender, token, feed, price, minBet, start, startPeriod, end, endPeriod);
    }

    function bet(uint id, address asset, uint amount, bool isBull) public payable {
        require(asset == pools[id].token, "Sent asset is same as asset in which we collect bets");
        if (asset == address(0)) {
            require(amount == msg.value, "Sent value should be equal to the amount");
        }
        require(amount > 0 && amount >= pools[id].minBet, "Amount should be at least the minimal bet");
        uint start = pools[id].start;
        uint poolBullsTotal = bullsTotal[id];
        uint poolBearsTotal = bearsTotal[id];
        require(block.number >= start && block.number <= start.add(pools[id].startPeriod), "Acceptance period");
        uint fee = amount.div(500);
        uint amt = amount.sub(fee);
        if (isBull) {
            bullsTotal[id] = poolBullsTotal.add(amt);
            require(funds[id][msg.sender][1] == 0, "Didn't place bet on bears");
            funds[id][msg.sender][0] = funds[id][msg.sender][0].add(amt);
        } else {
            bearsTotal[id] = poolBearsTotal.add(amt);
            require(funds[id][msg.sender][0] == 0, "Didn't place bet on bulls");
            funds[id][msg.sender][1] = funds[id][msg.sender][1].add(amt);
        }
        fees[owner()][asset] = fees[owner()][asset].add(fee);
        transfer(msg.sender, payable(address(this)), asset, amount);
        emit Bet(id, msg.sender, asset, amount, isBull);
    }

    function getPrice(uint id) public view returns (int)  {
        int price = feeds[id].latestAnswer();
        require(price > 0, "Price exists in the feed");
        return price;
    }

    function trigger(uint id) public {
        uint end = pools[id].end;
        require(block.number >= end && block.number <= end.add(pools[id].endPeriod), "Price settlement period");
        int price = feeds[id].latestAnswer();
        require(price > 0, "Price exists in the feed");
        if (uint(price) > pools[id].price) {
            results[id] = true;
        }
        isPriceSet[id] = true;
        emit Trigger(id, uint(price));
    }

    function collect(uint id) public {
        uint timeToCollect = pools[id].end.add(pools[id].endPeriod);
        require(block.number > timeToCollect && block.number < timeToCollect.add(60000), "After price settlement period and not later than 2 days");
        uint amount = 0;
        address owner = owner();
        address token = pools[id].token;
        if (isPriceSet[id]) {
            if (results[id]) {
                amount = funds[id][msg.sender][0];
                require(amount > 0, "Has earnings");
                uint earnings = bearsTotal[id].mul(amount).div(bullsTotal[id]);
                uint fee = earnings.mul(3).div(100);
                earnings = earnings.sub(fee);
                amount = amount.add(earnings);
                funds[id][msg.sender][0] = 0;
                taken[id] = taken[id].add(amount.add(fee));
                fees[owner][token] = fees[owner][token].add(fee);
                transfer(address(this), msg.sender, token, amount);
            } else {
                amount = funds[id][msg.sender][1];
                require(amount > 0, "Has earnings");
                uint earnings = bullsTotal[id].mul(amount).div(bearsTotal[id]);
                uint fee = earnings.mul(3).div(100);
                earnings = earnings.sub(fee);
                amount = amount.add(earnings);
                funds[id][msg.sender][1] = 0;
                taken[id] = taken[id].add(amount.add(fee));
                fees[owner][token] = fees[owner][token].add(fee);
                transfer(address(this), msg.sender, token, amount);
            }
        } else {
            amount = funds[id][msg.sender][0].add(funds[id][msg.sender][1]);
            funds[id][msg.sender][1] = 0;
            funds[id][msg.sender][0] = 0;
            taken[id] = taken[id].add(amount);
            transfer(address(this), msg.sender, token, amount);
        }

        emit Collect(id, msg.sender, amount);
    }

    function claimNotTaken(uint id) public onlyOwner {
        uint timeToCollect = pools[id].end.add(pools[id].endPeriod);
        require(block.number >= timeToCollect.add(60000), "Time to collect funds from the pool expired");
        uint totalBearsBulls = bullsTotal[id].add(bearsTotal[id]);
        transfer(address(this), msg.sender, pools[id].token, totalBearsBulls.sub(taken[id]));
        taken[id] = taken[id].add(totalBearsBulls);
        emit Taken(id);
    }

    function claim(address asset) public canClaim(msg.sender, asset) {
        uint amount = fees[msg.sender][asset];
        fees[msg.sender][asset] = 0;
        transfer(address(this), msg.sender, asset, amount);
        emit Claim(msg.sender, asset, amount);
    }

    uint256[44] private __gap;
}