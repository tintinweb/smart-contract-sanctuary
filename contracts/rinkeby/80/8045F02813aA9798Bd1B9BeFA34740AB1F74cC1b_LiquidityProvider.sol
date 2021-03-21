/**
 *Submitted for verification at Etherscan.io on 2021-03-20
*/

// Dependency file: openzeppelin-solidity/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

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


// Dependency file: openzeppelin-solidity/contracts/access/Ownable.sol


// pragma solidity ^0.8.0;

// import "openzeppelin-solidity/contracts/utils/Context.sol";
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


// Dependency file: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol


// pragma solidity ^0.8.0;

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
     * // importANT: Beware that changing an allowance with this method brings the risk
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


// Dependency file: contracts/interfaces/SafeExContract.sol


// pragma solidity ^0.8.0;

// import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

/**
 * @dev SafeExToken interface.
 *
 * See {SafeExToken}.
 */
interface SafeExContract is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;
}


// Root file: contracts/LiquidityProvider.sol


pragma solidity ^0.8.0;

// import "openzeppelin-solidity/contracts/access/Ownable.sol";
// import "contracts/interfaces/SafeExContract.sol";

/**
 * @dev LiquidityProvider contract.
 *
 * This contract is able to mint SafeExToken for users. To get tokens
 * the users have to send ether to the contract. Then, according to the {fees}
 * the corresponding amount of SafeEx tokens is minted and sent to the user. The {buy} method
 * can also be called to mint a specific amount of tokens.
 *
 */
contract LiquidityProvider is Ownable {
    uint256 private _fees;
    SafeExContract private _safe;
    bool private _locked;

    constructor(
        address _owner,
        uint256 fees_,
        address safe_
    ) {
        setFees(fees_);
        setSafeEx(SafeExContract(safe_));
        lock();

        transferOwnership(_owner);
    }

    /**
     * @dev Returns the number of eth wei to pay for 1 SAFE token
     */
    function fees() public view returns (uint256) {
        return _fees;
    }

    /**
     * @dev Set the fees
     *
     * See {fees} for more information
     *
     * Requirements:
     *  - the caller must be the contract owner
     *  - fees must be strictly positive
     */
    function setFees(uint256 fees_) public onlyOwner {
        require(fees_ > 0, "LiquidityProvider: fees cannot be equal to 0");

        _fees = fees_;
    }

    /**
     * @dev Returns `true` if the contract is locked. When the contract is
     * locked, the user is not able to send eth or use the {buy} method
     */
    function isLocked() public view returns (bool) {
        return _locked;
    }

    /**
     * @dev Locks the contract
     *
     * Requirements:
     *  - the caller must be the contract owner
     */
    function lock() public onlyOwner {
        _locked = true;
    }

    /**
     * @dev Un-locks the contract
     *
     * Requirements:
     *  - the caller must be the contract owner
     */
    function unlock() public onlyOwner {
        _locked = false;
    }

    /**
     * @dev Sets the SafeExToken contract address
     *
     * Requirements:
     *  - the caller must be the contract owner
     *  - `safe_` cannot be the 0x0 address
     */
    function SafeEx() public view returns (SafeExContract) {
        return _safe;
    }

    /**
     * @dev Sets the SafeExToken contract address
     *
     * Requirements:
     *  - the caller must be the contract owner
     *  - `safe_` cannot be the 0x0 address
     */
    function setSafeEx(SafeExContract safe_) public onlyOwner {
        require(
            address(safe_) != address(0),
            "LiquidityProvider: SafeEx token cannot be at address 0x0"
        );

        _safe = safe_;
    }

    /**
     * @dev When receive is triggered, the amount of eth in `msg.value`
     * is automatically converted in SAFE and remaining eth sent back to
     * `msg.sender`
     *
     * Requirements:
     *  - the contract cannot be locked
     */
    receive() external payable {
        uint256 mintAmount = msg.value / _fees;
        buy(mintAmount);
    }

    /**
     * @dev Buys a specific `amount` of SAFE token, remaining eth is sent back to
     * `msg.sender`.
     *
     * Requirements:
     *  - the contract cannot be locked
     *  - enough eth must be send
     */
    function buy(uint256 amount) public payable {
        uint256 requiredEth = _fees * amount;
        require(_locked == false, "LiquidityProvider: Contract is locked");
        require(
            msg.value >= requiredEth && amount > 0,
            "LiquidityProvider: Not enough eth or zero amount"
        );

        uint256 oldBal = _safe.balanceOf(_msgSender());

        _safe.mint(_msgSender(), amount);
        require(
            _safe.balanceOf(_msgSender()) - oldBal == amount, // Note: since version 0.8.0 substractions are safe
            "LiquidityProvider: internal mint error"
        );

        (bool success, ) = msg.sender.call{value: msg.value - requiredEth}("");
        require(
            success == true,
            "LiquidityProvider: unable to send back remaining eth"
        );
    }

    /**
     * @dev Sends the eth contained at the contract address to the caller
     *
     * Requirements:
     *  - the caller must be the contract owner
     *
     */
    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success == true, "LiquidityProvider: unable to send eth");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     * By doing this, the contract is locked and so becomes a zoombi
     *
     * Requirements:
     *  - the caller must be the contract owner
     *
     */
    function renounceOwnership() public virtual override onlyOwner {
        lock();
        withdraw();
        super.renounceOwnership();
    }
}