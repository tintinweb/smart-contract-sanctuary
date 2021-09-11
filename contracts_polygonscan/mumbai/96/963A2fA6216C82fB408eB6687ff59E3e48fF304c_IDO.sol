/**
 *Submitted for verification at polygonscan.com on 2021-09-10
*/

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


pragma solidity ^0.8.0;

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


pragma solidity ^0.8.0;

contract IDO is Ownable {
    uint256 public price;

    uint256 public maxDeposit;
    uint256 public minDeposit;

    uint256 public startTime;
    uint256 public endTime;

    uint256 public participants;

    IERC20 gfx_;

    mapping(address => bool) public whiteLists;
    mapping(address => uint256) public deposits;
    mapping(address => bool) public claimStatuses;

    constructor() {
        // Set 1:1 as default
        price = 10**18;

        maxDeposit = 0;
        minDeposit = 0;

        startTime = 0;
        endTime = 0;

        participants = 0;
    }

    event SetIDODepositLimit(uint256 max, uint256 min);

    event SetIDOPeriod(uint256 startTime, uint256 endTime);

    event WhiteListed(address owner, bool approved);

    event Deposited(address owner, uint256 amount);

    event Claimed(address owner, uint256 amount);

    modifier canParticipate() {
        require(
            block.timestamp >= startTime && block.timestamp < endTime,
            "Can't participate"
        );
        require(
            deposits[msg.sender] + msg.value <= maxDeposit,
            "Deposit amount overflowed"
        );
        _;
    }

    modifier canClaim() {
        require(block.timestamp > endTime, "Not ready to claim");
        require(!whiteLists[msg.sender], "Can't claim");
        require(!claimStatuses[msg.sender], "Already claimed");
        _;
    }

    function initialize(address _gfx) external onlyOwner {
        gfx_ = IERC20(_gfx);
    }

    function setPrice(uint256 _price) external onlyOwner {
        require(_price > 0, "Invalid price");

        price = _price;
    }

    function setDepositLimit(uint256 _max, uint256 _min) external onlyOwner {
        require(_min > 0 && _max > _min, "Invalid limit");

        maxDeposit = _max;
        minDeposit = _min;

        emit SetIDODepositLimit(_max, _min);
    }

    function setIDOTime(uint256 _start, uint256 _end) external onlyOwner {
        require(_start > block.timestamp && _end > _start, "Invalid time");

        startTime = _start;
        endTime = _end;

        emit SetIDOPeriod(_start, _end);
    }

    function whitelistAddress(address _address) external onlyOwner {
        require(!whiteLists[_address], "Already whitelisted");

        whiteLists[_address] = true;

        emit WhiteListed(_address, true);
    }

    function removeAddressFromList(address _address) external onlyOwner {
        require(whiteLists[_address], "Not whitelisted");

        whiteLists[_address] = false;

        emit WhiteListed(_address, false);
    }

    function buy() external payable canParticipate {
        deposits[msg.sender] += msg.value;

        if (whiteLists[msg.sender]) {
            claimToken(msg.sender, msg.value);
        }

        emit Deposited(msg.sender, deposits[msg.sender]);
    }

    function claim() external canClaim {
        claimToken(msg.sender, deposits[msg.sender]);
        claimStatuses[msg.sender] = true;

        emit Claimed(msg.sender, deposits[msg.sender]);
    }

    function claimToken(address _owner, uint256 _amount) private {
        uint256 amount = (_amount * price) / (10**18);
        gfx_.transfer(_owner, amount);
    }
}