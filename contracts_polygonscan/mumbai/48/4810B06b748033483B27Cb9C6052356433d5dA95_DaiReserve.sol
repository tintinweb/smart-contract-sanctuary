/**
 *Submitted for verification at polygonscan.com on 2021-12-27
*/

// Verified using https://dapp.tools

// hevm: flattened sources of lib/radicle-drips-hub/src/DaiReserve.sol
// SPDX-License-Identifier: MIT AND GPL-3.0-only
pragma solidity >=0.8.0 <0.9.0 >=0.8.7 <0.9.0;

////// lib/openzeppelin-contracts/contracts/utils/Context.sol

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/access/Ownable.sol

/* pragma solidity ^0.8.0; */

/* import "../utils/Context.sol"; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

/* pragma solidity ^0.8.0; */

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

////// lib/radicle-drips-hub/src/Dai.sol
/* pragma solidity ^0.8.7; */

/* import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol"; */

interface IDai is IERC20 {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

////// lib/radicle-drips-hub/src/ERC20Reserve.sol
/* pragma solidity ^0.8.7; */

/* import {Ownable} from "openzeppelin-contracts/access/Ownable.sol"; */
/* import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol"; */

interface IERC20Reserve {
    function erc20() external view returns (IERC20);

    function withdraw(uint256 amt) external;

    function deposit(uint256 amt) external;
}

contract ERC20Reserve is IERC20Reserve, Ownable {
    IERC20 public immutable override erc20;
    address public user;
    uint256 public balance;

    event Withdrawn(address to, uint256 amt);
    event Deposited(address from, uint256 amt);
    event ForceWithdrawn(address to, uint256 amt);
    event UserSet(address oldUser, address newUser);

    constructor(
        IERC20 _erc20,
        address owner,
        address _user
    ) {
        erc20 = _erc20;
        setUser(_user);
        transferOwnership(owner);
    }

    modifier onlyUser() {
        require(_msgSender() == user, "Reserve: caller is not the user");
        _;
    }

    function withdraw(uint256 amt) public override onlyUser {
        require(balance >= amt, "Reserve: withdrawal over balance");
        balance -= amt;
        emit Withdrawn(_msgSender(), amt);
        require(erc20.transfer(_msgSender(), amt), "Reserve: transfer failed");
    }

    function deposit(uint256 amt) public override onlyUser {
        balance += amt;
        emit Deposited(_msgSender(), amt);
        require(erc20.transferFrom(_msgSender(), address(this), amt), "Reserve: transfer failed");
    }

    function forceWithdraw(uint256 amt) public onlyOwner {
        emit ForceWithdrawn(_msgSender(), amt);
        require(erc20.transfer(_msgSender(), amt), "Reserve: transfer failed");
    }

    function setUser(address newUser) public onlyOwner {
        emit UserSet(user, newUser);
        user = newUser;
    }
}

////// lib/radicle-drips-hub/src/DaiReserve.sol
/* pragma solidity ^0.8.7; */

/* import {ERC20Reserve, IERC20Reserve} from "./ERC20Reserve.sol"; */
/* import {IDai} from "./Dai.sol"; */

interface IDaiReserve is IERC20Reserve {
    function dai() external view returns (IDai);
}

contract DaiReserve is ERC20Reserve, IDaiReserve {
    IDai public immutable override dai;

    constructor(
        IDai _dai,
        address owner,
        address user
    ) ERC20Reserve(_dai, owner, user) {
        dai = _dai;
    }
}