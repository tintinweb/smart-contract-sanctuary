/**
 *Submitted for verification at Etherscan.io on 2021-09-29
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
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "You cant transfer ownerships to address 0x0");
        require(newOwner != owner, "You cant transfer ownerships to yourself");
        emit OwnershipTransferred(owner, newOwner);
        whitelist[owner] = false;
        whitelist[newOwner] = true;
        owner = newOwner;
    }

    modifier onlyWhitelist() {
        require(whitelist[msg.sender], "Only whitelist users can call this function");
        _;
    }

    function addToWhitelist(address newWhitelistUser) external onlyOwner {
        require(newWhitelistUser != address(0), "You cant add to whitelist address 0x0");
        emit WhitelistAdded(msg.sender, newWhitelistUser);
        whitelist[newWhitelistUser] = true;
    }

    function removeFromWhitelist(address newWhitelistUser) external onlyOwner {
        require(whitelist[newWhitelistUser], "You cant remove from whitelist");
        emit WhitelistRemoved(msg.sender, newWhitelistUser);
        whitelist[newWhitelistUser] = false;
    }
}

contract StakingAddble is OwnableAndWhitelistble {
    struct Stake {
        uint256 lastHarvest;
        uint256 startStaking;
        uint256 amount;
        uint256 boost;
    }

    IERC20 public mainToken;

    address public dividends;

    uint256 public rate = 25;
    uint256 public constant beforeCutoff = 15;
    uint256 public constant afterCutoff = 10;

    uint256 public constant cutoff = 48 hours;
    uint256 public constant maxStakePeriod = 365 days;

    mapping(address => Stake) public stakes;

    event Staked(address indexed who, uint256 startTime, uint256 amount);
    event Harvested(address indexed who, uint256 value, uint256 toDividends);
    event Unstaked(address indexed who, uint256 amount);
    event AddedAmount(address indexed who, uint256 amount);
    event Boosted(address indexed who, uint256 boost);
    event SettedDividends(address indexed who);
    event SettedRate(address indexed who, uint256 rate);

    constructor(
        address _owner,
        IERC20 _token,
        address _dividends
    ) {
        owner = _owner;
        whitelist[_owner] = true;
        mainToken = _token;
        dividends = _dividends;
    }

    function stake(uint256 _amount) external {
        require(stakes[msg.sender].startStaking == 0, "You have already staked");
        require(_amount > 0, "Amount must be greater then zero");
        require(mainToken.balanceOf(msg.sender) >= _amount, "You dont enough DES");
        require(maxReward(_amount) < mainToken.balanceOf(address(this)), "Pool is empty");

        stakes[msg.sender] = Stake(block.timestamp, block.timestamp, _amount, 0);
        emit Staked(msg.sender, block.timestamp, _amount);

        mainToken.transferFrom(msg.sender, address(this), _amount);
    }

    function addAmount(uint256 _amount) external {
        require(stakes[msg.sender].startStaking != 0, "You dont have stake");
        require(_amount > 0, "Amount must be greater then zero");
        require(mainToken.transferFrom(msg.sender, address(this), _amount), "Transfer issues");

        stakes[msg.sender].amount += _amount;

        emit AddedAmount(msg.sender, _amount);
    }

    function maxReward(uint256 _amount) public view returns (uint256) {
        return (_amount * rate) / 100;
    }

    function harvest() public returns (uint256 value, uint256 toDividends) {
        require(stakes[msg.sender].startStaking != 0, "You dont have stake");

        (uint256 _value, uint256 _toDividends) = harvested(msg.sender);
        require(mainToken.balanceOf(address(this)) >= (_value + _toDividends), "Contract doesnt have enough DES");

        stakes[msg.sender].lastHarvest = block.timestamp;
        emit Harvested(msg.sender, _value, _toDividends);

        require(mainToken.transfer(msg.sender, _value), "Transfer issues");
        require(mainToken.transfer(dividends, _toDividends), "Transfer issues");

        return (_value, _toDividends);
    }

    function harvested(address _who) public view returns (uint256 _value, uint256 _toDividends) {
        if (stakes[_who].lastHarvest == 0) return (0, 0);

        Stake memory _stake = stakes[_who];

        uint256 timeNow = block.timestamp;
        if ((block.timestamp - _stake.startStaking) > maxStakePeriod) {
            timeNow = _stake.startStaking + maxStakePeriod;
        }

        uint256 _timePassed = timeNow - _stake.lastHarvest;
        uint256 _percentDiv = _timePassed < cutoff ? beforeCutoff : afterCutoff;

        uint256 _reward = (_stake.amount * _timePassed * (rate + _stake.boost)) / (100 * (365 days));
        uint256 _toDiv = (_reward * _percentDiv) / 100;

        return (_reward - _toDiv, _toDiv);
    }

    function unstake() external {
        require(stakes[msg.sender].startStaking != 0, "You dont have stake");

        harvest();

        uint256 _amount = stakes[msg.sender].amount;
        require(mainToken.balanceOf(address(this)) >= _amount, "Contract doesnt have enough DES");

        delete stakes[msg.sender];
        emit Unstaked(msg.sender, _amount);

        require(mainToken.transfer(msg.sender, _amount), "Transfer issues");
    }

    function getStake(address _user) external view returns (Stake memory) {
        return stakes[_user];
    }

    function setRate(uint256 _rate) external onlyOwner {
        rate = _rate;
        emit SettedRate(msg.sender, _rate);
    }

    function setBoost(address _for, uint256 _boost) external onlyWhitelist {
        stakes[_for].boost = _boost;
        emit Boosted(_for, _boost);
    }

    function setDividends(address _newDividends) external onlyOwner {
        dividends = _newDividends;
        emit SettedDividends(_newDividends);
    }
}