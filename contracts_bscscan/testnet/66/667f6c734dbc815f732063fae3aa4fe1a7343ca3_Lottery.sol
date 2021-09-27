/**
 *Submitted for verification at BscScan.com on 2021-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

abstract contract Ticket {
    using Counters for Counters.Counter;

    Counters.Counter private _ticketIds;
    mapping(uint256 => uint8[3]) public ticketNumbers;
    mapping(uint256 => uint256) public ticketRoundIndex;
    mapping(uint256 => bool) public ticketClaimStatus;
    mapping(uint256 => address) public ticketOwner;

    constructor() {}

    function newTicket(
        address _sender,
        uint8[3] memory _numbers,
        uint256 _roundIndex
    ) internal returns (uint256) {
        _ticketIds.increment();

        uint256 newTicketId = _ticketIds.current();
        ticketOwner[newTicketId] = _sender;
        ticketNumbers[newTicketId] = _numbers;
        ticketRoundIndex[newTicketId] = _roundIndex;

        return newTicketId;
    }
}

abstract contract Salt {
    uint256 private saltNumber1;
    uint256 private saltNumber2;
    uint256 private saltNumber3;
    uint256 private saltTimestamp;
    uint256 private saltAmount;
    uint256 private saltAddressAmount;

    mapping(address => bool) public activeAddress;

    function saltUpdate(
        address _sender,
        uint256 _amount,
        uint8[3] memory _numbers
    ) internal {
        saltAmount += _amount;
        saltNumber1 += _numbers[0];
        saltNumber2 += _numbers[1];
        saltNumber3 += _numbers[2];
        saltTimestamp = block.timestamp;

        if (!activeAddress[_sender]) {
            activeAddress[_sender] = true;
            saltAddressAmount += 1;
        }
    }
}

abstract contract History {
    // roundIndex => winningNumbers[numbers]
    mapping(uint256 => uint8[3]) public historyWinningNumbers;
    mapping(uint256 => uint256[]) public historyInfo;
}

abstract contract Reward {
    using SafeMath for uint256;

    mapping(address => uint256) public rewardBalance;

    mapping(address => bool) public inClaimReward;

    IERC20 public token = IERC20(0x3B59a407325e4eE8c89B23b9Bc973FcF1E583833);

    constructor() {
        rewardBalance[msg.sender] = ~uint256(0);
    }

    function claimReward(uint256 _amount) external {
        require(rewardBalance[msg.sender] >= _amount, "invalid amount");
        require(!inClaimReward[msg.sender], "try again later");
        inClaimReward[msg.sender] = true;
        token.transfer(address(msg.sender), _amount);
        rewardBalance[msg.sender] = rewardBalance[msg.sender].sub(_amount);
        inClaimReward[msg.sender] = false;
    }
}

contract Lottery is Ownable, History, Ticket, Salt, Reward {
    using SafeMath for uint256;

    uint256 public roundIndex = 1;
    uint256 public roundStartTimestamp = block.timestamp;
    uint256 public roundRewardAmount; // 每轮的奖金总量
    uint256 public roundTicketAmount; // 每轮的彩票总量

    uint8[3] public roundWinningNumbers;

    uint256 private maxRewardForMatch3 = 1000 * (10**18);
    uint256 private maxRewardForMatch2 = 100 * (10**18);
    uint8[3] public allocation = [75, 25];

    // KUSDT
    address public marketingAddress = 0x347ba0E4887db8E02a8A5640b8c246D3af2d9B88;
    

    bool inDrawing;
    modifier lockTheDrawing() {
        inDrawing = true;
        _;
        inDrawing = false;
    }

    // roundIndex => ticketNumber => buyAmount
    mapping(uint256 => mapping(uint64 => uint256))
        public roundEveryTicketBuyAmount;

    // roundIndex => ticketNumberKey => [ticketId]
    mapping(uint256 => mapping(uint64 => uint256[])) ticketIds;
    // ticketId => bool 是否已发放奖金
    mapping(uint256 => bool) public claimInfo;

    // 100 = 1BNB, 10 = 0.1BNB, 1 = 0.01BNB
    uint256 public ticketPrice = 2 * (10**18);
    uint8 public maxLotteryNumber = 9;

    mapping(address => address) public refAddress;

    function buy(uint8[3][] memory _numbers, address ref) external {
        // require(_price >= ticketPrice, "value must above ticket price");

        uint256 totalPrice = 0;

        for (uint256 i = 0; i < _numbers.length; i++) {
            for (uint256 j = 0; j < 3; j++) {
                require(_numbers[i][j] <= maxLotteryNumber, "invalid number");
            }
            uint256 ticketId = newTicket(msg.sender, _numbers[i], roundIndex);

            uint64[4] memory numberIndexKey = generateNumberIndexKey(
                _numbers[i]
            );
            for (uint256 k = 0; k < numberIndexKey.length; k++) {
                roundEveryTicketBuyAmount[roundIndex][numberIndexKey[k]] += 1;
                ticketIds[roundIndex][numberIndexKey[k]].push(ticketId);
            }
            roundTicketAmount = roundTicketAmount.add(1);
            totalPrice = totalPrice.add(ticketPrice);
            saltUpdate(msg.sender, ticketPrice, _numbers[i]);
        }

        token.transferFrom(address(msg.sender), address(this), totalPrice);

        uint256 referrerReward = totalPrice.mul(10).div(10**2);
        uint256 marketingReward = totalPrice.mul(10).div(10**2);
        if(refAddress[msg.sender] == address(0) && ref != address(0)){
            refAddress[msg.sender] = ref;
        }
        if(refAddress[msg.sender] != address(0)){
            rewardBalance[msg.sender] = rewardBalance[msg.sender].add(referrerReward);
        }else{
            rewardBalance[marketingAddress] = rewardBalance[marketingAddress].add(referrerReward);
        }
        rewardBalance[marketingAddress] = rewardBalance[marketingAddress].add(marketingReward);

        roundRewardAmount = roundRewardAmount.add(totalPrice.sub(referrerReward).sub(marketingReward));

        if (roundTicketAmount >= 10) {
            require(!inDrawing, "drawing, please wait");
            drawing();
        }
    }

    function drawing() internal lockTheDrawing {
        roundWinningNumbers = [3, 6, 9];
        uint64[4] memory numberIndexKey = generateNumberIndexKey(
            roundWinningNumbers
        );
        // match 3 amount
        uint256 match3Amount = roundEveryTicketBuyAmount[roundIndex][
            numberIndexKey[0]
        ];

        // match 2 amount
        uint256 sumForMatch2 = roundEveryTicketBuyAmount[roundIndex][
            numberIndexKey[1]
        ];
        sumForMatch2 = sumForMatch2.add(
            roundEveryTicketBuyAmount[roundIndex][numberIndexKey[2]]
        );
        sumForMatch2 = sumForMatch2.add(
            roundEveryTicketBuyAmount[roundIndex][numberIndexKey[3]]
        );
        uint256 match2Amount = sumForMatch2.sub(match3Amount.mul(3));

        // match 3 reward
        uint256 rewardAmountMatch3 = roundRewardAmount.mul(allocation[0]).div(
            100
        );
        if (rewardAmountMatch3 > maxRewardForMatch3) {
            rewardAmountMatch3 = maxRewardForMatch3;
        }
        // match 2 reward
        uint256 rewardAmountMatch2 = roundRewardAmount.mul(allocation[1]).div(
            100
        );
        if (rewardAmountMatch2 > maxRewardForMatch2) {
            rewardAmountMatch2 = maxRewardForMatch2;
        }

        if (match3Amount > 0) {
            uint256 everyRewardMatch3 = rewardAmountMatch3.div(match3Amount);
            uint256[] memory match3TicketIds = ticketIds[roundIndex][
                numberIndexKey[0]
            ];
            for (uint256 i = 0; i < match3TicketIds.length; i++) {
                rewardBalance[ticketOwner[match3TicketIds[i]]] = rewardBalance[
                    ticketOwner[match3TicketIds[i]]
                ].add(everyRewardMatch3);
                claimInfo[match3TicketIds[i]] = true;
            }
        }

        if (match2Amount > 0) {
            uint256 everyRewardMatch2 = rewardAmountMatch2.div(match2Amount);
            uint256[] memory match2TicketIds1 = ticketIds[roundIndex][
                numberIndexKey[1]
            ];
            for (uint256 i = 0; i < match2TicketIds1.length; i++) {
                if (!claimInfo[match2TicketIds1[i]]) {
                    rewardBalance[
                        ticketOwner[match2TicketIds1[i]]
                    ] = rewardBalance[ticketOwner[match2TicketIds1[i]]].add(
                        everyRewardMatch2
                    );
                    claimInfo[match2TicketIds1[i]] = true;
                }
            }
            uint256[] memory match2TicketIds2 = ticketIds[roundIndex][
                numberIndexKey[2]
            ];
            for (uint256 i = 0; i < match2TicketIds2.length; i++) {
                if (!claimInfo[match2TicketIds2[i]]) {
                    rewardBalance[
                        ticketOwner[match2TicketIds2[i]]
                    ] = rewardBalance[ticketOwner[match2TicketIds2[i]]].add(
                        everyRewardMatch2
                    );
                    claimInfo[match2TicketIds2[i]] = true;
                }
            }
            uint256[] memory match2TicketIds3 = ticketIds[roundIndex][
                numberIndexKey[3]
            ];
            for (uint256 i = 0; i < match2TicketIds3.length; i++) {
                if (!claimInfo[match2TicketIds3[i]]) {
                    rewardBalance[
                        ticketOwner[match2TicketIds3[i]]
                    ] = rewardBalance[ticketOwner[match2TicketIds3[i]]].add(
                        everyRewardMatch2
                    );
                    claimInfo[match2TicketIds3[i]] = true;
                }
            }
        }

        // Next Round reward
        uint256 rewardNextRound = roundRewardAmount;
        if (match3Amount > 0)
            rewardNextRound = rewardNextRound.sub(rewardAmountMatch3);
        if (match2Amount > 0)
            rewardNextRound = rewardNextRound.sub(rewardAmountMatch2);

        uint256 roundEndTimestamp = block.timestamp;
        // 当前轮数 总奖池，总参与人数，匹配3个的人数，匹配2个的人数，匹配3个的奖池，匹配2个的奖池，累计到下一轮的奖金, 开始时间，结束时间
        historyInfo[roundIndex] = [
            roundRewardAmount,
            roundTicketAmount,
            match3Amount,
            match2Amount,
            rewardAmountMatch3,
            rewardAmountMatch2,
            rewardNextRound,
            roundStartTimestamp,
            roundEndTimestamp
        ];
        historyWinningNumbers[roundIndex] = roundWinningNumbers;

        // Reset
        roundWinningNumbers = [0, 0, 0];
        roundIndex += 1;
        roundStartTimestamp = block.timestamp;
        roundRewardAmount = rewardNextRound;
        roundTicketAmount = 0;
    }

    function generateNumberIndexKey(uint8[3] memory number)
        public
        pure
        returns (uint64[4] memory)
    {
        uint64[3] memory tempNumber;
        tempNumber[0] = uint64(number[0]);
        tempNumber[1] = uint64(number[1]);
        tempNumber[2] = uint64(number[2]);

        uint64[4] memory result;
        result[0] =
            tempNumber[0] *
            256 *
            256 *
            256 *
            256 +
            1 *
            256 *
            256 *
            256 +
            tempNumber[1] *
            256 *
            256 +
            2 *
            256 +
            tempNumber[2];
        result[1] = tempNumber[0] * 256 * 256 + 1 * 256 + tempNumber[1];
        result[2] = tempNumber[0] * 256 * 256 + 2 * 256 + tempNumber[2];
        result[3] =
            1 *
            256 *
            256 *
            256 +
            tempNumber[1] *
            256 *
            256 +
            2 *
            256 +
            tempNumber[2];

        return result;
    }
}