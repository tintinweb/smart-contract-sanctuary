// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "./libs/SafeMath.sol";
import "./libs/Ownable.sol";

interface ISponsoredContract {
    function getUserLendingState(bytes32 _lendingId)
        external
        view
        returns (uint256);
}

contract LiquidateSponsor is Ownable {
    enum LendingInfoState {
        NONE,
        WAITTING,
        CLOSED
    }

    struct LendingInfo {
        address user;
        uint256 expendGas;
        uint256 amount;
        LendingInfoState state;
    }

    bool public isPaused;
    address public liquidateSponsor;
    address public sponsoredContract;
    uint256 public totalSupply;
    uint256 public totalRequest;
    uint256 public sponsorAmount = 0.1 ether;

    mapping(bytes32 => LendingInfo) public lendingInfos;

    event SponsoredContribution(bytes32 sponsor, uint256 amount);
    event RequestSponsor(bytes32 sponsor, uint256 amount);
    event PayFee(
        bytes32 sponsor,
        address user,
        uint256 sponsorAmount,
        uint256 expendGas
    );

    modifier onlySponsor() {
        require(
            msg.sender == liquidateSponsor,
            "LiquidateSponsor: not a sponsor"
        );
        _;
    }

    constructor() public {
        liquidateSponsor = msg.sender;
    }

    function setSponsoredContract(address _s) external onlySponsor {
        sponsoredContract = _s;
    }

    function payFee(
        bytes32 _lendingId,
        address _user,
        uint256 _expendGas
    ) public {
        if (msg.sender == sponsoredContract && isPaused == false) {
            if (address(this).balance < sponsorAmount) {
                return;
            }

            LendingInfo storage lendingInfo = lendingInfos[_lendingId];

            if (
                lendingInfo.state == LendingInfoState.NONE ||
                lendingInfo.state == LendingInfoState.WAITTING
            ) {
                lendingInfo.expendGas = _expendGas;
                lendingInfo.state = LendingInfoState.CLOSED;

                payable(_user).transfer(sponsorAmount);

                emit PayFee(_lendingId, _user, sponsorAmount, _expendGas);
            }
        }
    }

    function addSponsor(bytes32 _lendingId, address _user) public payable {
        if (msg.sender == sponsoredContract && isPaused == false) {
            lendingInfos[_lendingId] = LendingInfo({
                user: _user,
                amount: msg.value,
                expendGas: 0,
                state: LendingInfoState.NONE
            });

            totalSupply += msg.value;
            totalRequest++;

            emit SponsoredContribution(_lendingId, msg.value);
        }
    }

    function requestSponsor(bytes32 _lendingId) public {
        if (msg.sender == sponsoredContract && isPaused == false) {
            LendingInfo storage lendingInfo = lendingInfos[_lendingId];

            if (address(this).balance < sponsorAmount) {
                lendingInfo.state = LendingInfoState.WAITTING;
                return;
            }

            if (
                lendingInfo.state == LendingInfoState.NONE ||
                lendingInfo.state == LendingInfoState.WAITTING
            ) {
                lendingInfo.state = LendingInfoState.CLOSED;

                payable(lendingInfo.user).transfer(lendingInfo.amount);

                totalRequest--;
            }

            emit RequestSponsor(_lendingId, lendingInfo.amount);
        }
    }

    // function manualSponsor(bytes32 _lendingId) public {
    //     if (isPaused == false) {
    //         LendingInfo storage lendingInfo = lendingInfos[_lendingId];

    //         require(msg.sender == lendingInfo.user, "!user");

    //         uint256 state = ISponsoredContract(sponsoredContract)
    //             .getUserLendingState(_lendingId);

    //         require(state == 1, "!state");

    //         if (address(this).balance < sponsorAmount) {
    //             lendingInfo.state = LendingInfoState.WAITTING;
    //             return;
    //         }

    //         if (
    //             lendingInfo.state == LendingInfoState.NONE ||
    //             lendingInfo.state == LendingInfoState.WAITTING
    //         ) {
    //             lendingInfo.state = LendingInfoState.CLOSED;

    //             payable(lendingInfo.user).transfer(lendingInfo.amount);

    //             totalRequest--;
    //         }
    //     }
    // }

    function refund() public onlyOwner {
        require(totalRequest == 0, "!totalRequest");
        require(address(this).balance > 0, "!balance");

        payable(owner()).transfer(address(this).balance);
    }

    function pause() external onlySponsor {
        isPaused = true;
    }

    function resume() external onlySponsor {
        isPaused = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}