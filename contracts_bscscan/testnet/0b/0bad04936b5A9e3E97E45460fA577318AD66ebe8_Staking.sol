/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title Staking
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

contract Staking is OwnableAndWhitelistble {

    struct Stake {
        uint lastHarvest;
        uint startStaking;
        uint amount;
        uint boost; 
    }

    IERC20 public mainToken;

    address public dividends;

    uint public year = 365 days;

    uint public rate = 10;
    uint public beforeCutoff = 15;
    uint public afterCutoff = 10;

    // prod
    uint public cutoff = 48 hours;
    uint public stakePeriod = 48 hours;
    uint public maxStakePeriod = year;

    // test
    // uint public cutoff = 7 minutes;
    // uint public stakePeriod = 7 minutes;
    // uint public maxStakePeriod = 10 minutes;

    // uint public timePenalty = 7 days;
    // uint public penalty = 10;

    mapping(address => Stake) public stakes;

    event Staked(address indexed who, uint startTime, uint amount);
    event Harvested(address indexed who, uint value, uint toDividends);
    event Unstaked(address indexed who, uint amount);
    event Boosted(address indexed who, uint boost);

    constructor(address owner_, address token_, address dividends_) {
        owner = owner_;
        mainToken = IERC20(token_);
        dividends = dividends_;
    }

    function stake(uint amount_) 
    external {   
        require(stakes[msg.sender].startStaking == 0, 'You have already staked');
        require(amount_ > 0, 'Amount must be greater then zero');
        require(mainToken.balanceOf(msg.sender) >= amount_, 'You dont enough DES');
        require(maxReward(amount_) < mainToken.balanceOf(address(this)), 'Pool is empty');
        
        mainToken.transferFrom(msg.sender, address(this), amount_);

        stakes[msg.sender] = Stake(block.timestamp, block.timestamp, amount_, 0);

        emit Staked(msg.sender, block.timestamp, amount_);
    }

    function maxReward(uint amount_) 
    public
    view
    returns (uint256) {
        return (amount_ * maxStakePeriod * rate) / (100 * year);
    }

    function harvest() 
    public 
    returns (uint value, uint toDividends) {
        require(stakes[msg.sender].startStaking != 0, 'You dont have stake');

        (uint value_, uint toDividends_) = harvested(msg.sender);
        require(mainToken.balanceOf(address(this)) >= (value_ + toDividends_), 'Contract doesnt have enough DES');
    
        stakes[msg.sender].lastHarvest = block.timestamp;

        mainToken.transfer(msg.sender, value_);
        mainToken.transfer(dividends, toDividends_);

        emit Harvested(msg.sender, value_, toDividends_);

        return (value_, toDividends_);
    }

    function harvested(address who_) 
    public 
    view
    returns (uint value_, uint toDividends_) {
        if (stakes[who_].lastHarvest == 0) return (0, 0);

        Stake memory stake_ = stakes[who_];

        uint timeNow = block.timestamp;
        if ( (block.timestamp - stake_.startStaking) > maxStakePeriod ) {
            timeNow = stake_.startStaking + maxStakePeriod;
        }

        uint timePassed_ = timeNow - stake_.lastHarvest;
        uint percentDiv_ = timePassed_ < cutoff ? beforeCutoff: afterCutoff;

        uint reward_ = (stake_.amount * timePassed_ * (rate + stake_.boost)) / (100 * year);
        uint toDiv_ = (reward_ * percentDiv_) / 100;

        return (reward_ - toDiv_, toDiv_);
    }

    function unstake() 
    external {
        require(stakes[msg.sender].startStaking != 0, 'You dont have stake');
        require((block.timestamp - stakes[msg.sender].startStaking) >= stakePeriod, 'Time does not pass');

        harvest();
        
        uint amount_ = stakes[msg.sender].amount;
        // if ((block.timestamp - stakes[msg.sender].startStaking) < timePenalty) {
        //     amount_ = ((100 - penalty) * amount_) / 100;
        // }
        require(mainToken.balanceOf(address(this)) >= amount_, 'Contract doesnt have enough DES');
        
        delete stakes[msg.sender];
        mainToken.transfer(msg.sender, amount_);

        emit Unstaked(msg.sender, amount_);
    }

    function getStake(address user_)
    external
    view
    returns (Stake memory) {
        return stakes[user_];
    }
    
    function setRate(uint rate_)
    external
    onlyOwner {
        rate = rate_;
    }

    function setBoost(address for_, uint boost_) 
    external
    onlyWhitelist {
        stakes[for_].boost = boost_;
        emit Boosted(for_, boost_);
    }

    function setDividends(address newDividends_)
    external
    onlyOwner {
        dividends = newDividends_;
    }

    function setBeforeAfterCutoff(uint cutoff_, uint beforeCutoff_, uint afterCutoff_)
    external
    onlyOwner {
        cutoff = cutoff_;
        beforeCutoff = beforeCutoff_;
        afterCutoff = afterCutoff_;
    }
    
}