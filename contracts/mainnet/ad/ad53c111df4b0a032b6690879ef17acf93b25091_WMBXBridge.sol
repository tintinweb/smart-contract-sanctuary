// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNWWMMMMMMMMMMMMMMMMMMWWNNWWMMMMMMMMMMMMMMMMMMMWMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKxood0WMMMMMMMMMMMMMMMMNOdoodOXWMMMMMMMMMMMMMMMMNK0K00KWMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOo;;;;oKWMMMMMMMMMMMMMMW0l;;;;ckNMMMMMMMMMMMMMMMMWK0OkxONMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKko;;;;l0WMMMMMMMMMMMMMMMNkolclxXWMMMMMMMMMMMMMMMMMWWWWWWWMMM
MMMWNNWMMMMWNNXNNWMMMMMWWNXXNNWMMMMMMMMMMMWNNXKKXXNWWMMMMMWKko;;;;l0WWWXXKKXNWWMMMMMMWX00KNMMMMMMMWWNXXKXXNWWMMMMMMMMMMM
MNKxood0NXOdolllodOXWN0xollllldkKWMMMMMWXOxolcccccldx0NWMMWKko;;;;lO0kolccccldkKWMMMW0dlloONMMMWN0kdlcccccldkKNMMMMMMMMM
W0l;;;;col:;;;;;;;:lxo:;;;;;;;;:lONMMW0dc:;;;;;;;;;;;:lkXWWKko;;;;clc:;;;;;;;;:cxKWMXd;;;;l0WMN0o:;;;;::;;;;;cd0WMMMMMMM
WOc;;;;;;clool:;;;;;;;:lool:;;;;;l0WNkc;;;;:ldxxxoc:;;;:o0NKko;;;;;;:ldkkxoc;;;;:o0WKo;;;;l0WXxc;;;:lxkOkdl:;;;lONMMMMMM
WOl;;;;:o0NNNKkc;;;;;lOXNNXOl;;;;:xXk:;;;:oONWWWWNKxc;;;;l0KOo;;;;;lkXWWMWN0o:;;;;dKKo;;;;l0Xkc;;;cxKWWWWN0o:;;;l0WMMMMM
W0l;;;;cONMMMWXd;;;;:kNMMMMNx:;;;:xOl;;;;l0WMMMMMMWXxc;;;:x0Oo;;;;cONMMMMMMWKo;;;;cOKo;;;;l00o;;;;cdkkkkkkko:;;;cxNMMMMM
W0l;;;;l0WMMMMNx:;;;ckWMMMMNkc;;;:xOl;;;:dXMMMMMMMMWOl;;;;d0Oo;;;;l0WMMMMMMMXd:;;;ckKo;;;;l00l;;;;;:::::::::;;;:cONMMMMM
W0l;;;;l0WMMMMNx:;;;ckWMMMMNkc;;;:x0o;;;;l0WMMMMMMWXx:;;;:x0Oo;;;;ckNMMMMMMWKo;;;;cOKo;;;;l00o:;;;coxkkkkkkkkkkOKNWMMMMM
W0l;;;;l0WMMMMNx:;;;ckWMMMMNkc;;;:xKkc;;;;lkXNWWWNKxc;;;;oKKko;;;;;cxKNWWNXOo:;;;:dXKo;;;;l0Xkc;;;:d0NWWWWWXKOOXWMMMMMMM
WOl;;;;l0WMMMMNx:;;;ckWMMMMNkc;;;:xXNkl:;;;:codddoc:;;;:dKWKOo;;;;;;:codddl:;;;;:oKWXo;;;;l0NXkc;;;;cdxkkxdlc;:oKMMMMMMM
W0l;;;;l0WMMMMNx:;;;cOWMMMMNkc;;;:xNWWKxl:;;;;;;;;;;;coONWWX0d;;;;clc:;;;;;;;;:lkXWWXd:;;;l0WMW0dc:;;;;;;;;;;:cxXMMMMMMM
MN0dlloONMMMMMWKxllokXWMMMMWXkollxXWMMMWX0xdollllloxkKNWMMMWNKxood0XKOdolllodx0XWMMMWKxold0NMMMMWXOxolllllloxOXWMMMMMMMM
MMMWNXNWMMMMMMMMWNXNWMMMMMMMMWNNNWMMMMMMMMWWNNXXNNWWMMMMMMMMMMWWWWMMMWWNNNNNWWMMMMMMMMWWNWMMMMMMMMMWWNNXXNNWWMMMMMMMMMMM
*/

import "./lib/SafeMath.sol";
import "./lib/IERC20Burnable.sol";
import "./lib/Context.sol";
import "./lib/ReentrancyGuard.sol";
import "./lib/Ownable.sol";

contract WMBXBridge is ReentrancyGuard, Context, Ownable {
  using SafeMath for uint256;

  constructor(address _token, address payable _feeAddress, uint256 _claimFeeRate, uint256 _burnFeeRate) {
    TOKEN = IERC20(_token);
    feeAddress = _feeAddress;
    claimFeeRate = _claimFeeRate;
    burnFeeRate = _burnFeeRate;
    isFrozen = false;
  }

  IERC20 private TOKEN;

  address payable private feeAddress;
  uint256 private claimFeeRate;
  uint256 private burnFeeRate;
  bool private isFrozen;

  /* Defines a mint operation */
  struct MintOperation
  {
    address user;
    uint256 amount;
    bool isReceived;
    bool isProcessed;
  }

  mapping (string => MintOperation) private _mints;  // History of mint claims

  struct MintPending
  {
    string memo;
    bool isPending;
  }

  mapping (address => MintPending) private _pending; // Pending mint owners

  struct BurnOperation
  {
    uint256 amount;
    bool isProcessed;
  }

  mapping (string => BurnOperation) private _burns;  // History of burn requests

  mapping (address => bool) private _validators;

  event BridgeAction(address indexed user, string action, uint256 amount, uint256 fee, string memo);
  // event BridgeBurn(address indexed user, uint256 amount, uint256 fee, string memo);

  function getPending(address _user) external view returns(string memory) {
    require(msg.sender == _user || _validators[msg.sender] || msg.sender == owner(), "Not authorized.");
    if(_pending[_user].isPending){
      return _pending[_user].memo;
    } else {
      return "";
    }
  }

  function claimStatus(string memory _memo) external view returns(address user, uint256 amount, bool received, bool processed) {
    require (_mints[_memo].isReceived, "Memo not found.");
    require(msg.sender == _mints[_memo].user || _validators[msg.sender] || msg.sender == owner(), "Not authorized.");
    user = _mints[_memo].user;
    amount = _mints[_memo].amount;
    received = _mints[_memo].isReceived;
    processed = _mints[_memo].isProcessed;
  }

  function isValidator(address _user) external view returns (bool) {
    return _validators[_user];
  }

  function addValidator(address _user) external onlyOwner nonReentrant {
    require (!_validators[_user], "Address already validator.");
    _validators[_user] = true;
  }

  function removeValidator(address _user) external onlyOwner nonReentrant {
    require (_validators[_user], "Address not found.");
    _validators[_user] = false;
  }

  function getFeeAddress() external view returns (address) {
    return feeAddress;
  }

  function setFeeAddress(address payable _feeAddress) external onlyOwner nonReentrant {
    feeAddress = _feeAddress;
  }

  function getClaimFeeRate() external view returns (uint256) {
    return claimFeeRate;
  }

  function getBurnFeeRate() external view returns (uint256) {
    return burnFeeRate;
  }

  function setClaimFeeRate(uint256 _claimFeeRate) external onlyOwner nonReentrant {
    claimFeeRate = _claimFeeRate;
  }

  function setBurnFeeRate(uint256 _burnFeeRate) external onlyOwner nonReentrant {
    burnFeeRate = _burnFeeRate;
  }

  function getFrozen() external view returns (bool) {
    return isFrozen;
  }

  function setFrozen(bool _isFrozen) external onlyOwner nonReentrant {
    isFrozen = _isFrozen;
  }

  function burnTokens(string memory _memo, uint256 _amount) external payable nonReentrant {
    require(!isFrozen, "Contract is frozen");
    require(msg.value >= burnFeeRate, "Fee not met");
    require(TOKEN.allowance(msg.sender, address(this)) >= _amount, "No allowance");
    TOKEN.burnFrom(msg.sender, _amount);
    feeAddress.transfer(msg.value);
    emit BridgeAction(msg.sender, 'BURN', _amount, msg.value, _memo);
  }

  function validateMint(address _user, string memory _memo, uint256 _amount) external nonReentrant {
    require(!isFrozen, "Contract is frozen");
    require(_validators[msg.sender], "Not authorized");
    require(_amount > 0, "Amount must be greater than zero.");
    require(!_mints[_memo].isReceived, "Mint already logged.");
    require(!_pending[_user].isPending, "Owner already has mint pending.");
    _mints[_memo] = MintOperation(_user, _amount, true, false);
    _pending[_user] = MintPending(_memo, true);
  }

  function claimTokens(string memory _memo) external payable nonReentrant {
    require(!isFrozen, "Contract is frozen");
    require(_mints[_memo].isReceived, "Memo not found");
    require(_mints[_memo].user == msg.sender, "Not owner");
    require(!_mints[_memo].isProcessed, "Memo already processed");
    require(msg.value >= claimFeeRate, "Fee not met");
    TOKEN.mint(msg.sender, _mints[_memo].amount);
    feeAddress.transfer(msg.value);
    _mints[_memo].isProcessed = true;
    _pending[_mints[_memo].user].isPending = false;
    emit BridgeAction(msg.sender, "CLAIM", _mints[_memo].amount, msg.value, _memo);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external;

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */

    function mint(address to, uint256 amount) external;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

import "./Context.sol";
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
    constructor () {
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

