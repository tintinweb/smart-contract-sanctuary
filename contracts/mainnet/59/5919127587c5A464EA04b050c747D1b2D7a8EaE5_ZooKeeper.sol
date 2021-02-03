// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./ZooKeeper.sol";

// BambooField allows you to grow your Bamboo! Buy some seeds, and then harvest them for more Bamboo!
//
contract BambooField is ERC20("Seed", "SEED"), Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    // Info of each user that can buy seeds.
    mapping (address => FarmUserInfo) public userInfo;
    BambooToken public bamboo;
    ZooKeeper public zooKeeper;
    // Amount needed to register
    uint256 public registerAmount;
    // Amount locked as collateral
    uint256 public depositPool;
    // Minimum time to harvest. Also min time of lock in the deposit.
    uint256 public minStakeTime;

    struct FarmUserInfo {
        uint256 amount;             // Deposited Amount
        uint poolId;                // Pool ID of active staking LP
        uint256 startTime;          // Timestamp of registration
        bool active;                // Flag for checking if this entry is active.
        uint256 endTime;            // Last timestamp the user can buy seeds. Only used if this is not active
    }

    event RegisterAmountChanged(uint256 amount);
    event StakeTimeChanged(uint256 time);

    constructor(BambooToken _bamboo, ZooKeeper _zoo, uint256 _registerprice, uint256 _minstaketime) {
        bamboo= _bamboo;
        zooKeeper = _zoo;
        registerAmount = _registerprice;
        minStakeTime = _minstaketime;
    }

    // Register a staking pool to the user with a collateral payment
    function register(uint _pid, uint256 _amount) public {
        require( _pid < zooKeeper.getPoolLength() , "register: invalid pool");
        require(_amount > registerAmount, "register: amount should be bigger than registerAmount");
        require(userInfo[msg.sender].amount == 0, "register: already registered");
        // Get the poolId
        uint256 amount = zooKeeper.getLpAmount(_pid, msg.sender);
        require(amount > 0, 'register: no LP on pool');
        uint256 seedAmount = _amount.sub(registerAmount);
        // move the registerAmount
        IERC20(bamboo).safeTransferFrom(address(msg.sender), address(this), registerAmount);
        depositPool = depositPool.add(registerAmount);
        // save user data
        userInfo[msg.sender] = FarmUserInfo(registerAmount, _pid, block.timestamp, true, 0);
        // buy seeds with the rest
        buy(seedAmount);
    }

    // Buy some Seeds with BAMBOO.
    // Requires an active register of LP staking, or endTime still valid.
    function buy(uint256 _amount) public {
        // Checks if user is valid
        if(!userInfo[msg.sender].active) {
            require(userInfo[msg.sender].endTime >= block.timestamp, "buy: invalid user");
        }
        // Gets the amount of usable BAMBOO locked in the contract
        uint256 totalBamboo = bamboo.balanceOf(address(this)).sub(depositPool);
        // Gets the amount of Seeds in existence
        uint256 totalShares = totalSupply();
        // If no Seeds exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalBamboo == 0) {
            _mint(msg.sender, _amount);
        }
        // Calculate and mint the amount of Seeds the BAMBOO is worth. The ratio will change overtime, as Seeds are burned/minted and BAMBOO is deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalBamboo);
            _mint(msg.sender, what);
        }
        // Lock the BAMBOO in the contract
        IERC20(bamboo).safeTransferFrom(address(msg.sender), address(this), _amount);
    }

    // Harvest your BAMBOO
    // Unlocks the staked + gained BAMBOO and burns Seeds
    function harvest(uint256 _share) public {
        // Checks if time is valid
        require(block.timestamp.sub(userInfo[msg.sender].startTime) >= minStakeTime, "buy: cannot harvest seeds at this time");
        // Gets the amount of Seeds in existence
        uint256 totalShares = totalSupply();
        uint256 totalBamboo = bamboo.balanceOf(address(this)).sub(depositPool);
        // Calculates the amount of BAMBOO the Seeds are worth
        uint256 what = _share.mul(totalBamboo).div(totalShares);
        _burn(msg.sender, _share);
        IERC20(bamboo).safeTransfer(msg.sender, what);
    }

    // Register a staking pool to the user with a collateral payment
    function withdraw() public {
        // Checks if timestamp is valid
        require(block.timestamp.sub(userInfo[msg.sender].startTime) >= minStakeTime, "withdraw: cannot withdraw yet!");
        // Harvest remaining seeds
        uint256 seeds = balanceOf(msg.sender);
        if (seeds>0){
            harvest (seeds);
        }
        uint256 deposit = userInfo[msg.sender].amount;
        // Reset user data
        delete(userInfo[msg.sender]);
        // Return deposit
        IERC20(bamboo).safeTransfer(msg.sender, deposit);
        depositPool = depositPool.sub(deposit);
    }

    // This function will be called from ZooKeeper if LP balance is withdrawn
    function updatePool(address _user) external {
        require(ZooKeeper(msg.sender) == zooKeeper, "updatePool: contract was not ZooKeeper");
        userInfo[_user].active = false;
        // Get 60 days to buy shares if you staked LP at least 60 days
        if(block.timestamp - userInfo[_user].startTime >= 60 days){
            userInfo[_user].endTime = block.timestamp + 60 days;
        }
    }

    // Changes the entry collateral amount.
    function setRegisterAmount(uint256 _amount) external onlyOwner {
        registerAmount = _amount;
        emit RegisterAmountChanged(registerAmount);
    }

    // Changes the min stake time in seconds.
    function setStakeTime(uint256 _mintime) external onlyOwner {
        minStakeTime = _mintime;
        emit StakeTimeChanged(minStakeTime);
    }

    // Check if user is active with an specific pool
    function isActive(address _user, uint _pid) public view returns(bool) {
        return userInfo[_user].active && userInfo[_user].poolId == _pid;
    }

}