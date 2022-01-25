// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

/**
 * @title Claim
 * @author gotbit
 */

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);
}

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, 'Only owner can call this function');
        _;
    }

    function transferOwnership(address newOwner_) external onlyOwner {
        require(newOwner_ != address(0), 'You cant tranfer ownerships to address 0x0');
        require(newOwner_ != owner, 'You cant transfer ownerships to yourself');
        emit OwnershipTransferred(owner, newOwner_);
        owner = newOwner_;
    }
}

contract Claim is Ownable {
    IERC20 public token;

    uint256 public start;
    uint256 public finish;
    uint256 public totalBank;

    struct User {
        uint256 bank;
        uint256 claimed;
        uint256 debt; // Unclaimed from previous program
        uint256 finish; // Compare with global finish to determine if user is in current 2nd+ program
    }
    mapping(address => User) public users;

    event Started(uint256 timestamp, uint256 rewardsDuration, address who);
    event Claimed(address indexed who, uint256 amount);
    event SetBank(address indexed who, uint256 bank, uint256 debt);
    event RecoveredERC20(address owner, uint256 amount);
    event RecoveredAnotherERC20(IERC20 token, address owner, uint256 amount);

    constructor(address owner_, IERC20 token_) {
        owner = owner_;
        token = token_;
    }

    function claim() external returns (bool) {
        address who = msg.sender;
        User storage user = users[who];
        uint256 absoluteClaimable = getAbsoluteClaimable(who);
        uint256 amount = (absoluteClaimable + user.debt) - user.claimed;

        require(amount > 0, 'You dont have LIME to harvest');
        require(token.balanceOf(address(this)) >= amount, 'Not enough tokens on contract');
        require(token.transfer(who, amount), 'Transfer issue');

        totalBank -= amount;
        user.debt = 0;
        user.claimed = absoluteClaimable;

        emit Claimed(who, amount);
        return true;
    }

    function getAbsoluteClaimable(address who) public view returns (uint256) {
        User storage user = users[who];

        // No program or user never participated
        if (start == 0 || user.finish == 0) return 0;

        if (user.finish == finish) {
            // Nth program, and user is included in last activated program
            uint256 lastApplicableTime = block.timestamp;
            if (lastApplicableTime > user.finish) lastApplicableTime = user.finish;
            return (user.bank * (lastApplicableTime - start)) / (user.finish - start);
        } else {
            // Nth program, and user is not included in last activated program
            // always true in this case:
            // block.timestamp > user.finish
            return user.bank;
        }
    }

    // For UI
    function getActualClaimable(address who) public view returns (uint256) {
        return (getAbsoluteClaimable(who) + users[who].debt) - users[who].claimed;
    }

    function infoBundle(address who)
        public
        view
        returns (
            User memory uInfo,
            uint256 uBalance,
            uint256 uClaimable,
            uint256 cBalance,
            uint256 cStart,
            uint256 cFinish,
            uint256 cBank
        )
    {
        uInfo = users[who];
        uBalance = token.balanceOf(who);
        uClaimable = getActualClaimable(who);
        cBalance = token.balanceOf(address(this));
        cStart = start;
        cFinish = finish;
        cBank = totalBank;
    }

    function setRewards(
        address[] memory whos,
        uint256[] memory banks,
        uint256 durationDays
    ) public onlyOwner {
        require(whos.length == banks.length, 'Different lengths');

        require(block.timestamp > finish, 'Claiming programm is already started. Wait for its end');
        start = block.timestamp;
        finish = start + (durationDays * (1 days));

        for (uint256 i = 0; i < whos.length; i++) {
            address who = whos[i];
            uint256 bank = banks[i];
            uint256 debt = (users[who].bank + users[who].debt) - users[who].claimed;

            users[who] = User({bank: bank, claimed: 0, debt: debt, finish: finish});
            emit SetBank(who, bank, debt);

            totalBank += bank;
        }

        emit Started(start, durationDays, msg.sender);
    }

    function recoverERC20(uint256 amount) external onlyOwner {
        require(token.balanceOf(address(this)) >= totalBank + amount, 'RecoverERC20 error: Not enough balance on contract');
        require(token.transfer(owner, amount), 'Transfer issue');
        emit RecoveredERC20(owner, amount);
    }

    function recoverAnotherERC20(IERC20 token_, uint256 amount) external onlyOwner {
        require(token_ != token, 'For recovering main token use another function');
        require(token_.balanceOf(address(this)) >= amount, 'RecoverAnotherERC20 error: Not enough balance on contract');
        require(token_.transfer(owner, amount), 'Transfer issue');
        emit RecoveredAnotherERC20(token_, owner, amount);
    }
}