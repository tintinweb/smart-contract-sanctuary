pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TreasuryVester is Ownable {
    using SafeMath for uint;

    address public OVER;
    address public recipient;

    bool public initialised;

    uint public vestingAmount;
    uint public totalAmount;
    uint public oneShot20Amount;


    uint public vestingBegin;
    uint public vestingCliff;
    uint public vestingEnd;
    uint public oneShot10Timestamp;

    uint public lastUpdate;

    mapping (address => bool) recipients;
    mapping (address => uint) claimed;


    function init(
        address OVER_,
        uint vestingBegin_,
        uint vestingEnd_,
        uint oneShot10Timestamp_
    ) onlyOwner public
    {
        require(!initialised, "TreasuryVester::init: already initialised");
        require(vestingBegin_ >= block.timestamp, 'TreasuryVester::init: vesting begin too early');
        require(vestingEnd_ > vestingBegin_, 'TreasuryVester::init: end is too early');
        OVER = OVER_;
        initialised = true;
        totalAmount = IOVER(OVER).balanceOf(address(this)).div(30);
        vestingAmount = totalAmount.div(100).mul(70);
        oneShot20Amount = totalAmount.div(100).mul(90);
        vestingBegin = vestingBegin_;
        vestingEnd = vestingEnd_;
        oneShot10Timestamp = oneShot10Timestamp_;
        lastUpdate = vestingBegin;

        // Setting recipients
        recipients[0x9c79f2039601E2c2055ae710143C19197F4Ba5aF] = true;
        recipients[0xaE41C3555E3Bf7df357c4Cc2E4b08bef3a767f2E] = true;
        recipients[0x740C3a6D1F919afC62100Fc95b31E1d8232A6E56] = true;
        recipients[0xB650ba085f404580E1D4759Cf8876623F902275C] = true;
        recipients[0x835f21d2135213ae88CEecb26fcD64B5ee995F34] = true;
        recipients[0xe6f85fF76f1Da050301872b948704e28A60BEd55] = true;
        recipients[0xf2f10FC046a55F891204B02792761Fc905b4bbB8] = true;
        recipients[0xed435c8B10eD7eD15e8277170e2d68e71CabcC59] = true;
        recipients[0x2b3812BCc73574a927022d2b5909b8d1a98183dD] = true;
        recipients[0x913ee0B92A5315Ce2F97BD6579952FAd090b8E38] = true;
        recipients[0x26Aaf74D488f8A9992591F1984Ef03D41Aa0a628] = true;
        recipients[0x4f3C2C39EDF128c958453E7ca7b81e0b24D6ad3e] = true;
        recipients[0xb3755a4DBa572086F735af26E900A740a8A830e7] = true;
        recipients[0xE726A62dF9Eafdd8eCFD904e6AcbaAA8f375889F] = true;
        recipients[0xe074ECCDa6C8483fE607Ec73f6F470e9b39c4abF] = true;
        recipients[0xd77C8FffF18F6B2EddFfe1503b26aB41344Df21D] = true;
        recipients[0x7C0bb98208994A7BD93b8bf1ACB5c60C84a41Ec7] = true;
        recipients[0xDd8c8B2862a49bD56C928F59FE5f05a3e44a8446] = true;
        recipients[0x976f45CDDFA093e29d196D605B31583AD22c6f6B] = true;
        recipients[0xb94F5A0A3E11a9ba859a24A2387aD020580A269C] = true;
        recipients[0x8362c308F71f981bd55C1f5B5e624165F9A61618] = true;
        recipients[0xBbb58c40b6e27B3872A37Bbc1F429c2Ae88a1B2e] = true;
        recipients[0x0299afBd4969667f909296d5df6756a6670f86DE] = true;
        recipients[0xBEa174bB9712462D050cf1B9d492bCDF3F0d5549] = true;
        recipients[0x50968a118d6494461a0379D7020C1B0e15624afC] = true;
        recipients[0xfF9c64388728CfB711cf662d56B07A2cE8Ba4006] = true;
        recipients[0x9a84Ff8Ee2AC17a55f3F6a89D9A658694B54C708] = true;
        recipients[0x6a2Eec705383Bc12e429bC15de470abB9e7082B0] = true;
        recipients[0xD2b7cf823391c6fBdd97b3186a6e1C5a8eB6a444] = true;
        recipients[0x9455FD942cA87446fD914e07C403C785bdcdE84E] = true;
        // 30 addresses
    }

    function claim(address recipient_) public {
        require(block.timestamp >= vestingBegin, 'TreasuryVester::claim: not time yet');
        require(recipients[recipient_], 'TreasuryVester::claim: recipient not valid');
        uint amount;
        if (block.timestamp >= oneShot10Timestamp) {
            amount = totalAmount - claimed[recipient_];
        } else if (block.timestamp >= vestingEnd) {
            amount = oneShot20Amount - claimed[recipient_];
        } else {
            amount = vestingAmount.mul(block.timestamp - lastUpdate).div(vestingEnd - vestingBegin);
            lastUpdate = block.timestamp;
        }
        claimed[recipient_] = claimed[recipient_].add(amount);
        IOVER(OVER).transfer(recipient_, amount);
    }

}

interface IOVER {
    function balanceOf(address account) external view returns (uint);
    function transfer(address dst, uint rawAmount) external returns (bool);
}

pragma solidity ^0.6.0;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}