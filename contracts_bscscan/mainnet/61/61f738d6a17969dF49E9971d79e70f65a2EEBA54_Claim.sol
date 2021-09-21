/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title Claim
 * @author gotbit
 */

interface IERC20 {
    function balanceOf(address who) external view returns (uint balance);
    function transfer(address to, uint value) external returns (bool trans1);
}

contract Ownable {
    address public owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function transferOwnership(address newOwner_) external onlyOwner {
        require(
            newOwner_ != address(0),
            "You cant tranfer ownerships to address 0x0"
        );
        require(newOwner_ != owner, "You cant transfer ownerships to yourself");
        emit OwnershipTransferred(owner, newOwner_);
        owner = newOwner_;
    }
}

contract Claim is Ownable {
    struct Round {
        uint cliff;
        uint constReward;
        uint linearPeriod;
    }

    struct Allocation {
        uint seed;
        uint strategic;
        uint private_;
    }

    struct User {
        uint claimed;
        Allocation allocation;
        uint claimTimestamp;
    }

    uint public constant MONTH = 30 days;
    uint public constant MINUTE = 1 minutes;
    uint public constant CONST_PERIOD = 2 * 24 hours;
    uint public constant CONST_RELAX = MONTH;

    IERC20 public token;

    bool public isStarted;
    uint public startTimestamp;

    mapping(string => Round) rounds;
    mapping(address => User) public users;

    event Started(uint timestamp, address who);
    event Claimed(address indexed to, uint value);
    event SettedAllocation(address indexed to, uint seed, uint strategic, uint private_);


    constructor(address owner_, address token_) {
        owner = owner_;
        token = IERC20(token_);

        rounds["seed"] = Round(1, 10, 13);
        rounds["strategic"] = Round(0, 15, 9);
        rounds["private"] = Round(0, 20, 7);
    }

    function start() external onlyOwner returns (bool status) {
        require(!isStarted, "The claim has already begun");

        isStarted = true;
        startTimestamp = block.timestamp;

        emit Started(startTimestamp, msg.sender);

        return true;
    }

    function claim() external returns (bool status) {
        require(isStarted, "The claim has not started yet");

        uint value_ = calculateUnclaimed(msg.sender);

        require(value_ > 0, "You dont have DES to harvest");
        require(
            token.balanceOf(address(this)) >= value_,
            "Not enough tokens on contract"
        );

        users[msg.sender].claimed += value_;
        users[msg.sender].claimTimestamp = block.timestamp;

        require(token.transfer(msg.sender, value_), 'Transfer issues');

        emit Claimed(msg.sender, value_);
        return true;
    }

    function getAllocation(address user_) external view returns (uint sum) {
        return
            (users[user_].allocation.seed +
                users[user_].allocation.strategic +
                users[user_].allocation.private_) / 2;
    }

    function calculateUnclaimed(address user_)
        public
        view
        returns (uint unclaimed)
    {
        require(isStarted, "The claim has not started yet");

        uint resultSeed_ = calculateRound(
            "seed",
            users[user_].allocation.seed
        );
        uint resultStrategic_ = calculateRound(
            "strategic",
            users[user_].allocation.strategic
        );
        uint resultPrivate_ = calculateRound(
            "private",
            users[user_].allocation.private_
        );

        return
            (resultSeed_ + resultStrategic_ + resultPrivate_) /
            2 -
            users[user_].claimed;
    }

    function calculateRound(string memory roundName_, uint allocation_)
        internal
        view
        returns (uint unclaimedFromRound)
    {
        require(isStarted, "The claim has not started yet");

        Round memory round_ = rounds[roundName_];

        uint timePassed_ = block.timestamp - startTimestamp;
        uint bank_ = allocation_;

        if (timePassed_ < (round_.cliff * MONTH)) return 0;

        timePassed_ -= (round_.cliff * MONTH);
        uint constReward_ = (bank_ * round_.constReward) / 100;
        if (round_.cliff == 0) {
            if (timePassed_ < CONST_PERIOD / 2) return constReward_ / 2;
        }

        if (timePassed_ < CONST_RELAX) return constReward_;
        timePassed_ -= CONST_RELAX;

        uint minutesPassed_ = timePassed_ / MINUTE;
        uint leftInBank_ = bank_ - constReward_;
        return
            (leftInBank_ * MINUTE * minutesPassed_) /
            (MONTH * round_.linearPeriod) +
            constReward_;
    }

    function setAllocations(
        address[] memory whos_,
        uint[] memory seeds_,
        uint[] memory strategics_,
        uint[] memory privates_
    )
    public
    onlyOwner {
        uint len = whos_.length;
        for (uint i = 0; i < len; i++) {
            address who_ = whos_[i];

            if (users[who_].claimed == 0) {
                uint seed_ = seeds_[i];
                uint strategic_ = strategics_[i];
                uint private_ = privates_[i];
            
                users[who_] = User({
                    claimed: users[who_].claimed,
                    allocation: Allocation(seed_, strategic_, private_),
                    claimTimestamp: users[who_].claimTimestamp
                });
                emit SettedAllocation(who_, seed_, strategic_, private_);
            }
        }
    }
}