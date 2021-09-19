/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title LP Staking
 * @author gotbit
 */

// TODO cofigure visabilities

interface IERC20 {
    function balanceOf(address who) external view returns (uint256 balance);
    function transfer(address to, uint256 value) external returns (bool trans1);
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool trans);
}

contract OwnableAndWhitelistble {

    address public owner;
    mapping(address => bool) internal whitelist;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event WhitelistAdded(address indexed sender, address indexed whitelistUser);
    event WhitelistRemoved(address indexed sender, address indexed whitelistUser);


    modifier onlyOwner() {
        require(msg.sender == owner, 'Only owner can call this function');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), 'You cant transfer ownerships to address 0x0');
        require(newOwner != owner, 'You cant transfer ownerships to yourself');
        emit OwnershipTransferred(owner, newOwner);
        whitelist[owner] = false;
        whitelist[newOwner] = true;
        owner = newOwner;
    }

    modifier onlyWhitelist() {
        require(whitelist[msg.sender], 'Only whitelist users can call this function');
        _;
    }

    function addToWhitelist(address newWhitelistUser) public onlyOwner {
        require(newWhitelistUser != address(0), 'You cant add to whitelist address 0x0');
        emit WhitelistAdded(msg.sender, newWhitelistUser);
        whitelist[newWhitelistUser] = true;
    }

    function removeFromWhitelist(address newWhitelistUser) public onlyOwner {
        require(newWhitelistUser != address(0), 'You cant add to whitelist address 0x0');
        emit WhitelistAdded(msg.sender, newWhitelistUser);
        whitelist[newWhitelistUser] = true;
    }
}

contract LPStaking is OwnableAndWhitelistble{

    struct Stake {
        uint amount;
        uint startStaking;
        uint lastHarvest;
        uint bonus;
        uint boost; 
    }


    IERC20 mainToken;
    IERC20 lpToken;
    
    address dividends;

    uint public year = 365 days;

    uint public constant ETH = 1e18; 
    uint public rate = 888;
    uint public lowRate = 70;
    uint public alpha = 70;

    uint public pool = 0;

    uint public cutoff = 48 hours;
    uint public beforeCutoff = 15;
    uint public afterCutoff = 10;

    uint public stakePeriod = 0;
    uint public maxStakePeriod = year;

    address[] public users;
    
    mapping(address => Stake) public stakes;

    event Staked(address indexed who, uint startTime, uint amount, address lpToken);
    event AddedAmount(address indexed who, uint amount);
    event Harvested(address indexed who, uint value, uint toDividends);    
    event Unstaked(address indexed who, uint amount);
    event Boosted(address indexed who, uint boost);

    modifier isStake() {
        require(stakes[msg.sender].startStaking != 0, 'You dont have stake');
        _;
    }

    modifier isNotStake() {
        require(stakes[msg.sender].startStaking == 0, 'You have already staked');
        _;
    }


    constructor(address owner_, address token_, address lpToken_, address dividends_) {
        owner = owner_;

        mainToken = IERC20(token_);
        lpToken = IERC20(lpToken_);

        dividends = dividends_;
    }

    function stake(uint amount_)
    public 
    isNotStake {
        require(amount_ > 0, 'Amount must be greater then zero');

        require(lpToken.balanceOf(msg.sender) >= amount_, 'You dont enough LP tokens');

        lpToken.transferFrom(msg.sender, address(this), amount_);

        addBonuses(pool, pool + amount_);
        pool += amount_;

        stakes[msg.sender] = Stake({
            amount: amount_,
            startStaking: block.timestamp,
            lastHarvest: block.timestamp,
            bonus: 0,
            boost: 0
        });
        addUser(msg.sender);

        // emit Staked(msg.sender, block.timestamp, amount_, lpTokenAddress_);
    }

    function addBonuses(uint oldPool_, uint newPool_)
    internal {
        for (uint i = 0; i < users.length; i++) {
            (uint oldVal_, ) = harvested(users[i], oldPool_);
            (uint newVal_, ) = harvested(users[i], newPool_); 
            
            stakes[users[i]].bonus += oldVal_ - newVal_;
        }
    }

    function removeBonuses(uint oldPool_, uint newPool_)
    internal {
        for (uint i = 0; i < users.length; i++) {
            (uint oldVal_, ) = harvested(users[i], oldPool_);
            (uint newVal_, ) = harvested(users[i], newPool_); 
            
            stakes[users[i]].bonus -= newVal_ - oldVal_;
        }
    }

    function addAmount(uint amount_)
    public 
    isStake {
        require(amount_ > 0, 'Amount must be greater then zero');
        require(lpToken.balanceOf(msg.sender) >= amount_, 'You dont enough LP tokens');

        lpToken.transferFrom(msg.sender, address(this), amount_);

        stakes[msg.sender].amount += amount_;

        emit AddedAmount(msg.sender, amount_);
    }

    function harvest() 
    public
    isStake {
        require(stakes[msg.sender].startStaking != 0, 'You dont have stake');

        (uint value_, uint toDividends_) = harvested(msg.sender, pool);
        require(mainToken.balanceOf(address(this)) >= (value_ + toDividends_), 'Contract doesnt have enough DES');
    
        stakes[msg.sender].lastHarvest = block.timestamp;
        stakes[msg.sender].bonus = 0;

        mainToken.transfer(msg.sender, value_);
        mainToken.transfer(dividends, toDividends_);

        emit Harvested(msg.sender, value_, toDividends_);
    }

    function harvested(address who_, uint pool_) 
    public 
    view
    isStake
    returns (uint value_, uint toDividends_) {
        if (stakes[who_].lastHarvest == 0) return (0, 0);
        Stake memory stake_ = stakes[who_];

        uint timePassed_ = block.timestamp - stake_.lastHarvest;
        uint percentDiv_ = timePassed_ < cutoff ? beforeCutoff: afterCutoff;

        uint reward_ = (stake_.amount * timePassed_ * (getRate(pool_) + stake_.boost)) / (100 * year) + stake_.bonus;
        uint toDiv_ = (reward_ * percentDiv_) / 100;

        return (reward_ - toDiv_, toDiv_);
    }

    function getRate(uint pool_)
    public
    view
    returns (uint rate_) {
        return ((rate - lowRate) * alpha * ETH) / (pool_ + alpha * ETH) + lowRate;
    }

    function unstake() 
    public
    isStake {
        require((block.timestamp - stakes[msg.sender].startStaking) > stakePeriod, 'Time does not pass');

        harvest();

        uint amount_ = stakes[msg.sender].amount;
        require(lpToken.balanceOf(address(this)) >= amount_, 'Contract doesnt have enough DES');
        
        delete stakes[msg.sender];
        removeUser(msg.sender);
        removeBonuses(pool, pool - amount_);
        pool -= amount_;

        lpToken.transfer(msg.sender, amount_);

        emit Unstaked(msg.sender, amount_);
    }

    function addUser(address user_) 
    internal 
    returns (bool _status) {
        users.push(user_);
        return true;
    }

    function removeUser(address user_)
    internal 
    returns (bool _status) {
        uint _index = users.length;
        for (uint i = 0; i < users.length; i++) {
            if (users[i] == user_) {
                _index = i;
                break;
            }
        }
        if (_index == users.length) return false;
        for (uint i = _index; i < users.length - 1; i++) {
            users[i] = users[i + 1];
        }
        users.pop();
        return true;

    }

    function getStake(address user_)
    public
    view
    returns (Stake memory) {
        return stakes[user_];
    }

    function setBoost(address for_, uint boost_) 
    public
    onlyWhitelist {
        stakes[for_].boost = boost_;
        emit Boosted(for_, boost_);
    }

    function setDividends(address newDividends_)
    public
    onlyOwner {
        dividends = newDividends_;
    }

    function setBeforeAfterCutoff(uint cutoff_, uint beforeCutoff_, uint afterCutoff_)
    public
    onlyOwner {
        cutoff = cutoff_;
        beforeCutoff = beforeCutoff_;
        afterCutoff = afterCutoff_;
    }

    function setAlpha(uint alpha_)
    public
    onlyOwner {
        alpha = alpha_;
    }

    function setLowRate(uint lowRate_)
    public
    onlyOwner {
        lowRate = lowRate_;
    }

}