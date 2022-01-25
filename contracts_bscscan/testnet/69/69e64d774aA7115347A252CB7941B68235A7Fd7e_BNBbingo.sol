//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./role/CoOperateRole.sol";
import "./role/CallerRole.sol";
import "./structure/Lottery.sol";
import "./structure/Ticket.sol";
import "./const/LotteryStatus.sol";
import "./interface/IRandomGenerator.sol";

contract BNBbingo is CoOperateRole, CallerRole, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public ticketPrice;

    uint256 public currentLotteryId = 0;
    mapping (uint256 => Lottery) public lotteries;
    
    uint256 public currentTicketId = 0;
    mapping (uint256 => Ticket) public tickets;

    uint256[] public prizeDivision = [1, 2, 10, 17, 25, 40];
    uint256 public systemDivision = 5;

    mapping (uint8 => mapping (bytes => uint256)) public brackets;

    address public randomGenerator;

    uint256 public currentPrize = 0;

    modifier roundStopped() {
        require(
            lotteries[currentLotteryId].status == LotteryStatus.CLOSE,
            "Round is not closed"
        );
        _;
    }

    modifier roundClaimable() {
        require(
            lotteries[currentLotteryId].status == LotteryStatus.CLAIMABLE,
            "Round is not claimable"
        );
        _;
    }

    modifier roundStarted() {
        require(
            lotteries[currentLotteryId].status == LotteryStatus.OPEN,
            "Round is not started"
        );
        _;
    }

    /**
     * @dev Event of ticket buy
     * @param buyer ticket buyer
     * @param ticketId ticket id
     */
    event BuyTicket(address indexed buyer, uint256 indexed ticketId, uint8[6] indexed ticketNums);

    /**
     * @dev Event of starting round
     * @param round round id
     */
    event RoundStarted(uint256 indexed round);
    
    constructor(
        address aAddress,
        address bAddress,
        uint256 _ticketPrice,
        address generator
    ) CoOperateRole(aAddress, bAddress) {
        ticketPrice = _ticketPrice;

        randomGenerator = generator;
    }

    /**
     * @dev set ticket price
     * @param price ticket price
     */
    function setTicketPrice(uint256 price) public onlyOwner {
        require(price != 0, "Ticket price can't be zero");

        ticketPrice = price;
    }

    /**
     * @dev set PrizeDivision rate;
     * @param divisions division rates;
     */
    function setPrizeDivision(uint256[6] calldata divisions) 
    public onlyOwner 
    {
        uint256 divisionSum = 
            divisions[0] + divisions[1] + divisions[2] +
            divisions[3] + divisions[4] + divisions[5];
        
        require(divisionSum < 100, "Percentage overflow");
        
        prizeDivision[0] = divisions[0];
        prizeDivision[1] = divisions[1];
        prizeDivision[2] = divisions[2];
        prizeDivision[3] = divisions[3];
        prizeDivision[4] = divisions[4];
        prizeDivision[5] = divisions[5];
        systemDivision = 100 - divisionSum;
    }

    /**
     * @dev stop the round
     */
    function forceStopRound() public onlyOwner roundStarted {
        require(
            lotteries[currentLotteryId].firstTicketId == 0,
            "Bought ticket exists"
        );

        lotteries[currentLotteryId].status = LotteryStatus.CLOSE;
    }

    /**
     * @dev start the round
     */
    function startRound() public onlyOwner roundClaimable {
        currentLotteryId++;

        lotteries[currentLotteryId].status = LotteryStatus.OPEN;
        lotteries[currentLotteryId].startTime = block.timestamp;
        lotteries[currentLotteryId].ticketPrice = ticketPrice;
        lotteries[currentLotteryId].prizeDivision = 
            [
                prizeDivision[0],
                prizeDivision[1],
                prizeDivision[2],
                prizeDivision[3],
                prizeDivision[4],
                prizeDivision[5],
                systemDivision
            ];
        
        emit RoundStarted(currentLotteryId);
    }

    function buyTicket(uint8[6] memory numbers) 
    public payable roundStarted nonReentrant 
    {
        require(
            msg.value == lotteries[currentLotteryId].ticketPrice,
            "Incorrect ticket price"
        );

        require(
            (
                numbers[0] < numbers[1] &&
                numbers[1] < numbers[2] &&
                numbers[2] < numbers[3] &&
                numbers[4] < numbers[5]
            ),
            "Not sorted"
        );

        for (uint8 i1 = 0; i1 < 6; i1++) {
            for (uint8 i2 = i1 + 1; i2 < 6; i2++) {
                for (uint8 i3 = i2 + 1; i3 < 6; i3++) {
                    for (uint8 i4 = i3 + 1; i4 < 6; i4++) {
                        for (uint8 i5 = i4 + 1; i5 < 6; i5++) {
                            for (uint8 i6 = i5 + 1; i6 < 6; i6++) {
                                brackets[6][
                                    abi.encodePacked(
                                        numbers[i1],
                                        numbers[i2],
                                        numbers[i3],
                                        numbers[i4],
                                        numbers[i5],
                                        numbers[i6]
                                    )
                                ]++;
                            }
                            brackets[5][
                                abi.encodePacked(
                                    numbers[i1],
                                    numbers[i2],
                                    numbers[i3],
                                    numbers[i4],
                                    numbers[i5]
                                )
                            ]++;
                        }
                        brackets[4][
                            abi.encodePacked(
                                numbers[i1],
                                numbers[i2],
                                numbers[i3],
                                numbers[i4]
                            )
                        ]++;
                    }
                    brackets[3][
                        abi.encodePacked(numbers[i1], numbers[i2], numbers[i3])
                    ]++;
                }
                brackets[2][
                    abi.encodePacked(numbers[i1], numbers[i2])
                ]++;
            }
            brackets[1][
                abi.encodePacked(numbers[i1])
            ]++;
        }

        currentTicketId++;

        tickets[currentTicketId] = Ticket({
            claimed: false,
            ticketNumber: numbers,
            lotteryId: currentLotteryId,
            buyer: msg.sender
        });

        if (lotteries[currentLotteryId].firstTicketId == 0) {
            lotteries[currentLotteryId].firstTicketId = currentTicketId;
        }

        lotteries[currentLotteryId].lastTicketId = currentTicketId;

        currentPrize += ticketPrice;

        emit BuyTicket(msg.sender, currentTicketId, numbers);
    }

    /**
     * @dev stop the round
     */
    function stopRound() public onlyOwner roundStarted {
        uint8[6] memory winningNumber = 
            IRandomGenerator(randomGenerator).generateWiningNumber();

        lotteries[currentLotteryId].status = LotteryStatus.CLOSE;
        lotteries[currentLotteryId].finalNumber = winningNumber;
        lotteries[currentLotteryId].endTime = block.timestamp;
    }

    /**
     * @dev calculate winning ticket and prizes
     */
    function drawClaimableRound() public onlyOwner roundStopped {
        uint8[6] memory winningNumber = lotteries[currentLotteryId].finalNumber;

        for (uint8 i1 = 0; i1 < 6; i1++) {
            for (uint8 i2 = i1 + 1; i2 < 6; i2++) {
                for (uint8 i3 = i2 + 1; i3 < 6; i3++) {
                    for (uint8 i4 = i3 + 1; i4 < 6; i4++) {
                        for (uint8 i5 = i4 + 1; i5 < 6; i5++) {
                            for (uint8 i6 = i5 + 1; i6 < 6; i6++) {
                                lotteries[currentLotteryId].winningCnt[6] += 
                                    brackets[6][
                                        abi.encodePacked(
                                            winningNumber[i1],
                                            winningNumber[i2],
                                            winningNumber[i3],
                                            winningNumber[i4],
                                            winningNumber[i5],
                                            winningNumber[i6]
                                        )
                                    ];
                            }
                            lotteries[currentLotteryId].winningCnt[5] += 
                                brackets[5][
                                    abi.encodePacked(
                                        winningNumber[i1],
                                        winningNumber[i2],
                                        winningNumber[i3],
                                        winningNumber[i4],
                                        winningNumber[i5]
                                    )
                                ];
                        }
                        lotteries[currentLotteryId].winningCnt[4] += 
                            brackets[4][
                                abi.encodePacked(
                                    winningNumber[i1],
                                    winningNumber[i2],
                                    winningNumber[i3],
                                    winningNumber[i4]
                                )
                            ];
                    }
                    lotteries[currentLotteryId].winningCnt[3] += 
                        brackets[3][
                            abi.encodePacked(
                                winningNumber[i1],
                                winningNumber[i2],
                                winningNumber[i3]
                            )
                        ];
                }
                lotteries[currentLotteryId].winningCnt[2] += 
                    brackets[2][
                        abi.encodePacked(
                            winningNumber[i1],
                            winningNumber[i2]
                        )
                    ];
            }
            lotteries[currentLotteryId].winningCnt[1] += 
                brackets[1][abi.encodePacked(winningNumber[i1])];
        }

        lotteries[currentLotteryId].winningCnt[5] -= 
            lotteries[currentLotteryId].winningCnt[6] * 6;
        lotteries[currentLotteryId].winningCnt[4] -= 
            lotteries[currentLotteryId].winningCnt[6] * 15 + 
            lotteries[currentLotteryId].winningCnt[5] * 5;
        
        lotteries[currentLotteryId].winningCnt[3] -=
            lotteries[currentLotteryId].winningCnt[6] * 20 +
            lotteries[currentLotteryId].winningCnt[5] * 10 +
            lotteries[currentLotteryId].winningCnt[4] * 4;

        lotteries[currentLotteryId].winningCnt[2] -=
            lotteries[currentLotteryId].winningCnt[6] * 15 +
            lotteries[currentLotteryId].winningCnt[5] * 10 +
            lotteries[currentLotteryId].winningCnt[4] * 6 +
            lotteries[currentLotteryId].winningCnt[3] * 3;

        lotteries[currentLotteryId].winningCnt[1] -=
            lotteries[currentLotteryId].winningCnt[6] * 6 +
            lotteries[currentLotteryId].winningCnt[5] * 5 +
            lotteries[currentLotteryId].winningCnt[4] * 4 +
            lotteries[currentLotteryId].winningCnt[3] * 3 +
            lotteries[currentLotteryId].winningCnt[2] * 2;
        
        lotteries[currentLotteryId].totalPrize = currentPrize;
        
        currentPrize = 0;
        for (uint8 i = 1; i <= 6; i++) {
            if (lotteries[currentLotteryId].winningCnt[i] == 0) {
                currentPrize += 
                    lotteries[currentLotteryId].totalPrize
                    .mul(lotteries[currentLotteryId].prizeDivision[i - 1])
                    .div(100);
            }
        }

        lotteries[currentLotteryId].status = LotteryStatus.CLAIMABLE;
    }

    /**
     * @dev get prize with ticket
     * @param ticketId the ticket id
     */
    function claimTicket(uint256 ticketId) public {
        require(tickets[ticketId].buyer == msg.sender, "Not ticket owner");
        require(!tickets[ticketId].claimed, "The ticket was already claimed");
        uint256 prize = getPrize(ticketId);
        require(prize != 0, "The ticket with no prize");
        tickets[ticketId].claimed = true;
        payable(msg.sender).transfer(prize);
    }

    /**
     * @dev calculate prize with ticket
     * @param ticketId the ticket id
     */
    function getPrize(uint256 ticketId) public view returns (uint256) {
        require(tickets[ticketId].lotteryId != 0, "Not exist ticket");      
        require(
            (
                tickets[ticketId].lotteryId < currentLotteryId ||
                lotteries[currentLotteryId].status == LotteryStatus.CLAIMABLE
            ),
            "Not claimable yet"
        );

        Lottery storage lottery = lotteries[tickets[ticketId].lotteryId];
        uint8[6] memory winningNumber = lottery.finalNumber;
        uint8[6] memory ticketNumber = tickets[ticketId].ticketNumber;
        uint8 winningCnt = 0;

        for (uint8 i = 0; i < 6; i++) {
            for (uint8 j = 0; j < 6; j++) {
                if (winningNumber[j] == 0) {
                    continue;
                }

                if (ticketNumber[i] == winningNumber[j]) {
                    winningCnt++;
                    winningNumber[j] = 0;
                    break;
                }
            }
        }

        uint256 totalPrize = 
            lottery.ticketPrice.mul(
                lottery.lastTicketId.sub(lottery.firstTicketId).add(1)
            );
        uint256 prize = 
            totalPrize.mul(lottery.prizeDivision[winningCnt - 1])
            .div(100).div(lottery.winningCnt[winningCnt]);

        return prize;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CoOperateRole is Ownable {
    using SafeMath for uint256;

    address private aOperatorAddress;
    address private bOperatorAddress;

    uint256 private aOperatorDivision; // 5 = 50%

    constructor(address aAddress, address bAddress) {
        aOperatorAddress = aAddress;
        bOperatorAddress = bAddress;
    }

    /**
     * @dev modifier of operator validation
     */
    modifier onlyOperator() {
        require(
            msg.sender == aOperatorAddress || msg.sender == bOperatorAddress,
            "Not operator"
        );
        _;
    }

    /**
     * @dev set A operator address
     * @param aAddress A operator address
     */
    function setAOperatorAddress(address aAddress) public {
        require(aOperatorAddress == msg.sender, "Incorrect operator");

        aOperatorAddress = aAddress;
    }

    /**
     * @dev set B operator address
     * @param bAddress B operator address
     */
    function setBOperatorAddress(address bAddress) public {
        require(bOperatorAddress == msg.sender, "Incorrect operator");

        bOperatorAddress = bAddress;
    }

    /**
     * @dev set A operator's division value
     * @param division A operator's division value
     */
    function setAOperatorDivision(uint256 division) public onlyOwner {
        require(division < 10, "Division can't be 100%");

        aOperatorDivision = division;
    }

    function withdraw(uint256 amount) public onlyOperator {
        require(amount != 0, "Amount can't be zero");

        uint256 aAmount = amount.mul(aOperatorDivision).div(10);
        uint256 bAmount = amount.sub(aAmount);

        payable(aOperatorAddress).transfer(aAmount);
        payable(bOperatorAddress).transfer(bAmount);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";

contract CallerRole {
    modifier onlyWallet {
        require(!Address.isContract(msg.sender), "Caller is contract address");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../const/LotteryStatus.sol";

struct Lottery {
    LotteryStatus status;
    uint256 startTime;
    uint256 endTime;
    uint256 ticketPrice;
    uint256 firstTicketId;
    uint256 lastTicketId;
    mapping (uint8 => uint256) winningCnt;
    uint256[7] prizeDivision;
    uint8[6] finalNumber;
    uint256 totalPrize;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

struct Ticket {
    bool claimed;
    uint8[6] ticketNumber;
    uint256 lotteryId;
    address buyer;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

enum LotteryStatus {
    CLAIMABLE,
    OPEN,
    CLOSE
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract IRandomGenerator {
    /**
     * @dev generate random 6 values
     * Every random values are different each other and in the range of [0~32]
     * @return 
     */
    function generateWiningNumber() external virtual view returns(uint8[6] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}