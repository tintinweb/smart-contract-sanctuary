/**
 *Submitted for verification at BscScan.com on 2021-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title LP Staking
 * @author gotbit
 */

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

    function transferOwnership(address newOwner) external onlyOwner {
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

    function addToWhitelist(address newWhitelistUser) external onlyOwner {
        require(newWhitelistUser != address(0), 'You cant add to whitelist address 0x0');
        emit WhitelistAdded(msg.sender, newWhitelistUser);
        whitelist[newWhitelistUser] = true;
    }
    function removeFromWhitelist(address newWhitelistUser) external onlyOwner {
        require(whitelist[newWhitelistUser], 'You cant remove from whitelist');
        emit WhitelistRemoved(msg.sender, newWhitelistUser);
        whitelist[newWhitelistUser] = false;
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
    
    address dividends;

    uint public year = 365 days;

    uint public constant ETH = 1e18; 
    uint public rate = 888;
    uint public lowRate = 70;
    uint public alpha = 70;

    uint public pool;

    uint constant public cutoff = 48 hours;
    uint constant public beforeCutoff = 15;
    uint constant public afterCutoff = 10;

    address[] public users;

    mapping(address => bool) public isPermitted;
    mapping(address => mapping(address => Stake)) public stakes;
    mapping(address => bool) public userIncludes;

    event Staked(address indexed who, address indexed lpToken, uint amount, uint startTime);
    event AddedAmount(address indexed who, address indexed lpToken, uint amount);
    event Harvested(address indexed who, address indexed lpToken, uint value, uint toDividends);    
    event Unstaked(address indexed who, address indexed lpToken, uint amount);
    event Boosted(address indexed who, address indexed lpToken, uint boost);
    event SettedPermisionLPToken(address indexed lpToken, bool perm);

    event SettedAlpha(address indexed sender, uint alpha);
    event SettedLowRate(address indexed sender, uint lowRate);
    event SettedDividends(address indexed sender, address indexed dividends);


    constructor(address owner_, address token_, address dividends_) {
        owner = owner_;
        mainToken = IERC20(token_);
        dividends = dividends_;
    }

    function stake(address lpTokenAddress_, uint amount_)
    external {
        require(amount_ > 0, 'Amount must be greater then zero');
        require(stakes[msg.sender][lpTokenAddress_].startStaking == 0, 'You have already staked');
        require(isPermitted[lpTokenAddress_], 'You cant stake those LP tokens');

        IERC20 lpToken_ = IERC20(lpTokenAddress_); 

        require(lpToken_.balanceOf(msg.sender) >= amount_, 'You dont enough LP tokens');
        require(lpToken_.transferFrom(msg.sender, address(this), amount_), 'Transfer issues');

        addBonuses(lpTokenAddress_, pool, pool + amount_);
        pool += amount_;
        
        stakes[msg.sender][lpTokenAddress_] = Stake({
            amount: amount_,
            startStaking: block.timestamp,
            lastHarvest: block.timestamp,
            bonus: 0,
            boost: 0
        });

        require(addUser(msg.sender), 'Contract issue');

        emit Staked(msg.sender, lpTokenAddress_, amount_, block.timestamp);
    }

    function addBonuses(address lpTokenAddress_, uint oldPool_, uint newPool_)
    internal {
        uint length_ = users.length;
        
        for (uint i = 0; i < length_; i++) {
            if (userIncludes[users[i]]) {
                (uint oldVal_, ) = harvested(users[i], lpTokenAddress_,  oldPool_);
                (uint newVal_, ) = harvested(users[i], lpTokenAddress_, newPool_); 
                stakes[users[i]][lpTokenAddress_].bonus += oldVal_ - newVal_;
            }
        }
    }

    function removeBonuses(address lpTokenAddress_, uint oldPool_, uint newPool_)
    internal {
        uint length_ = users.length;

        for (uint i = 0; i < length_; i++) {
            if (userIncludes[users[i]]) {
                (uint oldVal_, ) = harvested(users[i], lpTokenAddress_, oldPool_);
                (uint newVal_, ) = harvested(users[i], lpTokenAddress_, newPool_); 
                stakes[users[i]][lpTokenAddress_].bonus -= newVal_ - oldVal_;
            }
        }
    }

    function addAmount(uint amount_, address lpTokenAddress_)
    external {
        require(amount_ > 0, 'Amount must be greater then zero');
        require(stakes[msg.sender][lpTokenAddress_].startStaking != 0, 'You dont have stake');

        IERC20 lpToken_ = IERC20(lpTokenAddress_);

        require(lpToken_.balanceOf(msg.sender) >= amount_, 'You dont enough LP tokens');
        require(lpToken_.transferFrom(msg.sender, address(this), amount_), 'Transfer issues');

        addBonuses(lpTokenAddress_, pool, pool + amount_);
        pool += amount_;

        stakes[msg.sender][lpTokenAddress_].amount += amount_;

        emit AddedAmount(msg.sender, lpTokenAddress_, amount_);
    }

    function harvest(address lpTokenAddress_) 
    public {
        require(stakes[msg.sender][lpTokenAddress_].startStaking != 0, 'You dont have stake');


        (uint value_, uint toDividends_) = harvested(msg.sender, lpTokenAddress_, pool);
        require(mainToken.balanceOf(address(this)) >= (value_ + toDividends_), 'Contract doesnt have enough DES');
    
        stakes[msg.sender][lpTokenAddress_].lastHarvest = block.timestamp;
        stakes[msg.sender][lpTokenAddress_].bonus = 0;

        require(mainToken.transfer(msg.sender, value_), 'Transfer issues');
        require(mainToken.transfer(dividends, toDividends_), 'Transfer issues');

        emit Harvested(msg.sender, lpTokenAddress_, value_, toDividends_);
    }

    function harvested(address who_, address lpTokenAddress_, uint pool_) 
    public 
    view
    returns (uint value_, uint toDividends_) {
        require(stakes[msg.sender][lpTokenAddress_].startStaking != 0, 'You dont have stake');

        if (stakes[who_][lpTokenAddress_].lastHarvest == 0) return (0, 0);
        Stake memory stake_ = stakes[who_][lpTokenAddress_];

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

    function unstake(address lpTokenAddress_) 
    public {
        require(stakes[msg.sender][lpTokenAddress_].startStaking != 0, 'You dont have stake');

        harvest(lpTokenAddress_);

        uint amount_ = stakes[msg.sender][lpTokenAddress_].amount;

        IERC20 lpToken_ = IERC20(lpTokenAddress_);
        require(lpToken_.balanceOf(address(this)) >= amount_, 'Contract doesnt have enough DES');
        
        delete stakes[msg.sender][lpTokenAddress_];

        require(removeUser(msg.sender), 'Contract issue');
        removeBonuses(lpTokenAddress_, pool, pool - amount_);
        pool -= amount_;

        require(lpToken_.transfer(msg.sender, amount_), 'Transfer issues');

        emit Unstaked(msg.sender, lpTokenAddress_, amount_);
    }


    function addUser(address user_) 
    internal 
    returns (bool _status) {
        users.push(user_);
        userIncludes[user_] = true;
        return true;
    }

    function removeUser(address user_)
    internal 
    returns (bool _status) {
        uint len = users.length;

        for (uint i = 0; i < len; i++ ) {
            if (users[i] == user_) {
                users[i] = address(0);
                userIncludes[user_] = false;
                return true;
            }
        }
        return false;
    }

    function getStake(address user_, address lpTokenAddress_)
    external
    view
    returns (Stake memory) {
        return stakes[user_][lpTokenAddress_];
    }

    function setBoost(address for_, address lpTokenAddress_, uint boost_) 
    external
    onlyWhitelist {
        stakes[for_][lpTokenAddress_].boost = boost_;
        emit Boosted(for_, lpTokenAddress_,  boost_);
    }

    function setDividends(address newDividends_)
    external
    onlyOwner {
        dividends = newDividends_;
        emit SettedDividends(msg.sender, newDividends_);
    }

    function setAlpha(uint alpha_)
    external
    onlyOwner {
        alpha = alpha_;
        emit SettedAlpha(msg.sender, alpha_);
    }

    function setLowRate(uint lowRate_)
    external
    onlyOwner {
        lowRate = lowRate_;
        emit SettedAlpha(msg.sender, lowRate_);
    }

    function setPermission(address lpTokenAddress_, bool perm_) 
    external 
    onlyOwner {
        isPermitted[lpTokenAddress_] = perm_;
        emit SettedPermisionLPToken(lpTokenAddress_, perm_);
    }

}