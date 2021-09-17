//SourceUnit: Amlstake.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Amlstake {
    using SafeMath for uint256;

    address public tokenAddress;
    uint256 public tokenDecimals = 6;

    uint256 public investLevel1Amount = 100 * 10**uint256(tokenDecimals);
    uint256 public investLevel2Amount = 500 * 10**uint256(tokenDecimals);

    uint256 public referrerLevel1Amount = 1 * 10**uint256(tokenDecimals);
    uint256 public referrerLevel2Amount = 5 * 10**uint256(tokenDecimals);

    uint256 public withdrawLevel1Amount = 5 * 10**uint256(tokenDecimals);
    uint256 public withdrawLevel2Amount = 25 * 10**uint256(tokenDecimals);
    address private _burnPool = 0x000000000000000000000000000000000000dEaD;
    address public whitelist;
    address private owner;

    mapping(address => UserInfo) public userInfo;
    uint256 public constant intervalTime = 5 minutes;
    uint256 public maxDay = 30;
    uint256 public totalWithdraw;

    struct DepositLevel1 {
        uint256 start;
        uint256 miningDay;
        uint256 lastaction;
    }

    struct DepositLevel2 {
        uint256 start;
        uint256 miningDay;
        uint256 lastaction;
    }

    struct UserInfo {
        address referrer;
        uint256 totalRefreward;
        uint256 totalWithdraw;
        DepositLevel1 depositLevel1;
        DepositLevel2 depositLevel2;
        address[] childs;
    }

    constructor(address _tokenAddress, address _whitelist) {
        tokenAddress = _tokenAddress;
        whitelist = _whitelist;
        owner = msg.sender;
    }

    function getChilds(address _address) public view returns (address[] memory childs) {
        UserInfo storage user = userInfo[_address];
        childs = user.childs;
    }

    function getUser() public view returns (
        address referrer,
        uint256 totalwithdraw,
        uint256 totalRefreward,
        uint256 depositLevel1Start,
        uint256 depositLevel1MiningDay,
        uint256 depositLevel1Lastaction,
        uint256 depositLevel2Start,
        uint256 depositLevel2MiningDay,
        uint256 depositLevel2Lastaction
    ) {
        UserInfo storage user = userInfo[msg.sender];
        referrer = user.referrer;
        totalwithdraw = user.totalWithdraw;
        totalRefreward = user.totalRefreward;
        depositLevel1Start = user.depositLevel1.start;
        depositLevel1MiningDay = user.depositLevel1.miningDay;
        depositLevel1Lastaction = user.depositLevel1.lastaction;
        depositLevel2Start = user.depositLevel2.start;
        depositLevel2MiningDay = user.depositLevel2.miningDay;
        depositLevel2Lastaction = user.depositLevel2.lastaction;
    }

    function bindReferrer(address referrer) public returns(address) {
        require(referrer != address(0), "bind referrer: referrer the zero address");
        require(referrer != msg.sender, "Can't bind oneself");
        require(userInfo[referrer].depositLevel1.start != 0 || userInfo[referrer].depositLevel2.start != 0, "Invalid account");
        UserInfo storage user = userInfo[msg.sender];
        if (user.referrer == address(0)) {
            user.referrer = referrer;
            userInfo[referrer].childs.push(msg.sender);
        }
        return user.referrer;
    }

    function safe() public {
        require(msg.sender == owner);
        IERC20(tokenAddress).transfer(owner, IERC20(tokenAddress).balanceOf(address(this)));
    }

    function investLevel1(uint256 _amount) public payable {
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer != address(0) || msg.sender == whitelist, "First bind the superior");
        require(_amount == investLevel1Amount, "wrong quantity: 100");
        if (user.depositLevel1.start != 0) {
            require(user.depositLevel1.miningDay == 30, "Mining");
        }
        user.depositLevel1 = DepositLevel1(
            block.timestamp,
            0,
            block.timestamp
        );
        IERC20(tokenAddress).transferFrom(msg.sender, _burnPool, _amount);
    }

    function investLevel2(uint256 _amount) public payable {
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer != address(0) || msg.sender == whitelist, "First bind the superior");
        require(_amount == investLevel2Amount, "wrong quantity: 500");
        if (user.depositLevel2.start != 0) {
            require(user.depositLevel2.miningDay == 30, "Mining");
        }
        user.depositLevel2 = DepositLevel2(
            block.timestamp,
            0,
            block.timestamp
        );
        IERC20(tokenAddress).transferFrom(msg.sender, _burnPool, _amount);
    }

    function withdrawLevel1() public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.depositLevel1.start > 0, "has not started");
        require(user.depositLevel1.miningDay < 30, "Reward has been received");
        uint256 claimDay = getDayByTime(user.depositLevel1.lastaction);
        if (user.depositLevel1.miningDay.add(claimDay) > 30) {
            claimDay = maxDay.sub(user.depositLevel1.miningDay);
        }

        totalWithdraw = totalWithdraw.add(claimDay.mul(withdrawLevel1Amount));
        user.totalWithdraw = user.totalWithdraw.add(claimDay.mul(withdrawLevel1Amount));

        IERC20(tokenAddress).transfer(msg.sender, claimDay.mul(withdrawLevel1Amount));
        if (msg.sender != whitelist) {
            IERC20(tokenAddress).transfer(user.referrer, claimDay.mul(referrerLevel1Amount));
            totalWithdraw = totalWithdraw.add(claimDay.mul(referrerLevel1Amount));
            userInfo[user.referrer].totalRefreward = userInfo[user.referrer].totalRefreward.add(claimDay.mul(referrerLevel1Amount));
        }
        user.depositLevel1.miningDay = user.depositLevel1.miningDay.add(claimDay);
        user.depositLevel1.lastaction = block.timestamp;
    }

    function getDayByTime(uint256 blockTime) private view returns(uint256) {
        return block.timestamp.sub(blockTime).div(intervalTime);
    }

    function getWithdrawLevel1(address _address) public view returns(
        uint256 totalwithdraw
    ) {
        UserInfo storage user = userInfo[_address];
        require(user.depositLevel1.miningDay < 30, "Reward has been received");
        uint256 claimDay = getDayByTime(user.depositLevel1.lastaction);
        if (user.depositLevel1.miningDay.add(claimDay) > 30) {
            claimDay = maxDay.sub(user.depositLevel1.miningDay);
        }
        totalwithdraw = claimDay.mul(withdrawLevel1Amount);
    }

    function getWithdrawLevel2(address _address) public view returns(
        uint256 totalwithdraw
    ) {
        UserInfo storage user = userInfo[_address];
        require(user.depositLevel2.miningDay < 30, "Reward has been received");
        uint256 claimDay = getDayByTime(user.depositLevel2.lastaction);
        if (user.depositLevel2.miningDay.add(claimDay) > 30) {
            claimDay = maxDay.sub(user.depositLevel2.miningDay);
        }
        totalwithdraw = claimDay.mul(withdrawLevel2Amount);
    }

    function withdrawLevel2() public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.depositLevel2.start > 0, "has not started");
        require(user.depositLevel2.miningDay < 30, "Reward has been received");
        uint256 claimDay = getDayByTime(user.depositLevel2.lastaction);
        if (user.depositLevel2.miningDay.add(claimDay) > 30) {
            claimDay = maxDay.sub(user.depositLevel2.miningDay);
        }

        totalWithdraw = totalWithdraw.add(claimDay.mul(withdrawLevel2Amount));
        user.totalWithdraw = user.totalWithdraw.add(claimDay.mul(withdrawLevel2Amount));

        IERC20(tokenAddress).transfer(msg.sender, claimDay.mul(withdrawLevel2Amount));
        if (msg.sender != whitelist) {
            IERC20(tokenAddress).transfer(user.referrer, claimDay.mul(referrerLevel2Amount));
            totalWithdraw = totalWithdraw.add(claimDay.mul(referrerLevel2Amount));
            userInfo[user.referrer].totalRefreward = userInfo[user.referrer].totalRefreward.add(claimDay.mul(referrerLevel2Amount));
        }
        user.depositLevel2.miningDay = user.depositLevel2.miningDay.add(claimDay);
        user.depositLevel2.lastaction = block.timestamp;
    }

    function getContractInfo() public view returns(uint256 balance, uint256 totalwithdraw) {
        balance = IERC20(tokenAddress).balanceOf(address(this));
        totalwithdraw = totalWithdraw;
    }
}