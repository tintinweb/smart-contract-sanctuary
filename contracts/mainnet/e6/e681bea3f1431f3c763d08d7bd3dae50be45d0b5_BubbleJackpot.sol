pragma solidity ^0.5.0;

contract BubbleJackpot {
    using SafeMath for *;

    address payable[6] rankList;
    address owner;
    uint256 public countdown;
    bool isLottery;

    IBubble Bubble;

    mapping(address => uint256) betMap;
    mapping(address => uint256) withdrawMap;

    uint256 public totalToken;
    uint256 LOTTERYCOUNTDOWN = 24 hours;

    modifier onlyOwner {
        require(msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }

    modifier isHuman() {
        address addr = msg.sender;
        uint256 codeLength;

        assembly {
            codeLength := extcodesize(addr)
        }
        require(codeLength == 0, "sorry humans only");
        require(tx.origin == msg.sender, "sorry, human only");
        _;
    }

    function() external payable {}

    constructor() public {
        owner = msg.sender;
        for (uint256 idx = 0; idx < 5; idx++) {
            rankList[idx] = address(0);
        }
    }

    function getBubbleAddress() public view returns (address) {
        return address(Bubble);
    }

    function setBubbleAddress(address contractAddr) public onlyOwner() {
        require(address(Bubble) == address(0));
        Bubble = IBubble(contractAddr);
    }

    function startLotteryCountdown() public isHuman() {
        require(
            Bubble.getGameOverStatus(),
            "only lottery after bubble game over"
        );
        require(countdown == 0);
        countdown = now + LOTTERYCOUNTDOWN;
    }

    function lottery() public isHuman() {
        require(
            Bubble.getGameOverStatus(),
            "only lottery after bubble game over"
        );
        require(countdown != 0 && now > countdown, "countdown is not finished");
        require(!isLottery, "only lottery once");
        isLottery = true;
        Bubble.transferAllEthToJackPot();

        uint256 balance = address(this).balance;
        uint256 temp = 0;
        uint8[5] memory profit = [52, 23, 14, 8, 3];
        for (uint256 idx = 0; idx < 5; idx++) {
            if (rankList[idx] != address(0)) {
                withdrawMap[rankList[idx]] = balance.mul(profit[idx]).div(100);
                temp = temp.add(withdrawMap[rankList[idx]]);
            }
        }

        withdrawMap[owner] = withdrawMap[owner].add(balance).sub(temp);
    }

    function withdraw() public isHuman() {
        uint256 amount = withdrawMap[msg.sender];
        require(amount > 0, "must above 0");
        withdrawMap[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function getWithdrawAmount(address user) public view returns (uint256) {
        return withdrawMap[user];
    }

    function bet(uint256 amount) public isHuman() {
        if (countdown != 0 && now > countdown) {
            revert();
        }
        Bubble.sendTokenToJackpot(msg.sender, amount);
        betMap[msg.sender] = betMap[msg.sender].add(amount);
        totalToken = totalToken.add(amount);
        updateRankList(msg.sender);
    }

    //Get
    function getBetTokenAmount() public view returns (uint256) {
        return betMap[msg.sender];
    }

    function getRankListInfo()
        public
        view
        returns (address payable[6] memory, uint256[5] memory)
    {
        uint256[5] memory tokenList;

        for (uint256 idx = 0; idx < 5; idx++) {
            address user = rankList[idx];
            tokenList[idx] = betMap[user];
        }

        return (rankList, tokenList);
    }

    //Rank
    function inRankList(address addr) private returns (bool) {
        for (uint256 idx = 0; idx < 5; idx++) {
            if (addr == rankList[idx]) {
                return true;
            }
        }
        return false;
    }

    function updateRankList(address payable addr) private returns (bool) {
        uint256 idx = 0;
        uint256 rechargeAmount = betMap[addr];
        uint256 lastOne = betMap[rankList[5]];
        if (rechargeAmount < lastOne) {
            return false;
        }
        address payable[6] memory tempList = rankList;
        if (!inRankList(addr)) {
            tempList[5] = addr;
            quickSort(tempList, 0, 5);
        } else {
            quickSort(tempList, 0, 4);
        }
        for (idx = 0; idx < 6; idx++) {
            if (tempList[idx] != rankList[idx]) {
                rankList[idx] = tempList[idx];
            }
        }
        return true;
    }

    function quickSort(
        address payable[6] memory list,
        int256 left,
        int256 right
    ) internal {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        address addr = list[uint256(left + (right - left) / 2)];
        uint256 token = betMap[addr];
        while (i <= j) {
            while (betMap[list[uint256(i)]] > token) i++;
            while (token > betMap[list[uint256(j)]]) j--;
            if (i <= j) {
                (list[uint256(i)], list[uint256(j)]) = (
                    list[uint256(j)],
                    list[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) quickSort(list, left, j);
        if (i < right) quickSort(list, i, right);
    }
}

interface IBubble {
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

    function getGameOverStatus() external view returns (bool);

    function transferAllEthToJackPot() external;

    function sendTokenToJackpot(address sender, uint256 amount) external;
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "mul overflow");

        return c;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "div zero"); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "lower sub bigger");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "overflow");

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "mod zero");
        return a % b;
    }
}