// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGloryDogePrivateSale {
    function contribution(address account) external view returns (uint256);

    function totalContributions() external view returns (uint256);

    function totalContributors() external view returns (uint256);
}

/**
 * @title Small utility contract to manage the GloryDoge Private Sale.
 * @author The GloryDoge team - glorydogecoin.com
 */
contract GloryDogePrivateSaleV2 is Context, Ownable {
    IERC20 private _gloryDoge;
    IGloryDogePrivateSale private _gloryDogePrivateSale;

    bool private _privateSaleOpen;
    bool private _claimOpen;

    uint256 private _decimals = 18;
    uint256 private _privateSaleCap = 50 * 10**_decimals;
    uint256 private _minContribution = (1 * 10**_decimals) / 10;
    uint256 private _maxContribution = 3 * 10**_decimals;
    uint256 private _amountPerBNB = 520000000000 * 10**_decimals;
    uint256 private _totalContributions;
    uint256 private _totalContributors;

    mapping(address => uint256) private _contributions;
    mapping(address => bool) private _claimed;

    address private _marketingWallet =
        0xe2149C2E2A9e664E9AD5f20eb90db575bcb95F18;

    event Contribute(address indexed account, uint256 amount);
    event Claim(address indexed account, uint256 amount);
    event OpenPrivateSale(bool open);
    event OpenClaim(bool open);

    constructor(address gloryDogeContract_, address gloryDogePrivateSale_) {
        _gloryDoge = IERC20(gloryDogeContract_);
        _gloryDogePrivateSale = IGloryDogePrivateSale(gloryDogePrivateSale_);
    }

    function privateSaleOpen() public view returns (bool) {
        return _privateSaleOpen;
    }

    function claimOpen() public view returns (bool) {
        return _claimOpen;
    }

    function privateSaleCap() public view returns (uint256) {
        return _privateSaleCap;
    }

    function totalContributions() public view returns (uint256) {
        return _totalContributions + _gloryDogePrivateSale.totalContributions();
    }

    function totalContributors() public view returns (uint256) {
        return _totalContributors + _gloryDogePrivateSale.totalContributors();
    }

    function minContribution() public view returns (uint256) {
        return _minContribution;
    }

    function maxContribution() public view returns (uint256) {
        return _maxContribution;
    }

    function amountPerBNB() public view returns (uint256) {
        return _amountPerBNB;
    }

    function contribution(address account) public view returns (uint256) {
        if (_claimed[account]) return 0;

        return
            _contributions[account] +
            _gloryDogePrivateSale.contribution(account);
    }

    function claimed(address account) public view returns (bool) {
        return _claimed[account];
    }

    function marketingWallet() public view returns (address) {
        return _marketingWallet;
    }

    function tokenAddress() public view returns (address) {
        return address(_gloryDoge);
    }

    function setPrivateSaleOpen(bool open) public onlyOwner {
        _privateSaleOpen = open;
        emit OpenPrivateSale(_privateSaleOpen);
    }

    function setClaimOpen(bool open) public onlyOwner {
        _claimOpen = open;
        emit OpenClaim(_claimOpen);
    }

    // Purge function to empty the contract of tokens in case of emergency
    function purge() public onlyOwner {
        uint256 balance = _gloryDoge.balanceOf(address(this));
        _gloryDoge.transfer(_marketingWallet, balance);
    }

    function claimTokens() public {
        require(_claimOpen, "Claiming is closed");
        uint256 _contribution = contribution(_msgSender());
        require(_contribution >= _minContribution, "No contribution was made");

        uint256 claimAmount = (_amountPerBNB / 10**_decimals) * _contribution;

        _contributions[_msgSender()] = 0;
        _claimed[_msgSender()] = true;
        _gloryDoge.transfer(_msgSender(), claimAmount);

        emit Claim(_msgSender(), claimAmount);
    }

    receive() external payable {
        require(_privateSaleOpen, "Private sale is closed");
        if (_contributions[_msgSender()] == 0) _totalContributors++;
        _contributions[_msgSender()] += msg.value;

        require(
            _contributions[_msgSender()] >= _minContribution,
            "Contribution amount is less than minimum contribution"
        );
        require(
            _contributions[_msgSender()] <= _maxContribution,
            "Contribution amount exceeds maximum contribution"
        );

        _totalContributions += msg.value;
        require(
            _totalContributions <= _privateSaleCap,
            "Private sale cap reached"
        );

        payable(_marketingWallet).transfer(msg.value);

        emit Contribute(_msgSender(), msg.value);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}