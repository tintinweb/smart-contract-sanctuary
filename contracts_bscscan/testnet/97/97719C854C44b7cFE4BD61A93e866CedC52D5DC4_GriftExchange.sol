// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";

// GriftExchange allows users to purchase GRIFT with BNB directly
// from the site using a wallet like Metamask.
// GriftExchange charges a 10% fee.

contract GriftExchange is Ownable {
    uint256 public bnb_reserves;
    uint256 public grift_reserves;
    uint256 public percent_fee;
    address payable payableOwner;
    IERC20 griftCoin;

    constructor(
        uint256 _bnb_reserves,
        uint256 _grift_reserves,
        uint256 _percent_fee
    ) {
        bnb_reserves = _bnb_reserves;
        grift_reserves = _grift_reserves;
        percent_fee = _percent_fee;
        griftCoin = IERC20(0x4dE18A11e4b39d0648Fd8ed7C983d7F0545891f5);
        payableOwner = payable(msg.sender);
    }

    function getActualGriftBalance()
        public
        view
        returns (uint256 _griftReserves)
    {
        return griftCoin.balanceOf(address(this));
    }

    function getGriftReserves() public view returns (uint256) {
        return grift_reserves;
    }

    function transferExcessGrift(uint256 _grift_qty_wei) public onlyOwner {
        grift_reserves = grift_reserves - _grift_qty_wei;
        griftCoin.transfer(payableOwner, _grift_qty_wei);
    }

    function getBnbReserves() public view returns (uint256) {
        return bnb_reserves;
    }

    function rawSetBnbReserves(uint256 _bnb_reserves) public onlyOwner {
        bnb_reserves = _bnb_reserves;
    }

    function rawSetFee(uint256 _percent_fee) public onlyOwner {
        percent_fee = _percent_fee;
    }

    function addGriftLiquidity(uint256 _additional_grift) public onlyOwner {
        uint256 old_grift_reserves = grift_reserves;
        uint256 old_bnb_reserves = bnb_reserves;
        griftCoin.transferFrom(payableOwner, address(this), _additional_grift);
        grift_reserves += _additional_grift;
        bnb_reserves =
            (old_bnb_reserves) *
            (grift_reserves / old_grift_reserves);
    }

    function buyGrift(
        uint256 _bnb_minus_overhead,
        uint256 _grift_target,
        uint256 _slippage_percent
    ) public payable {
        // Make sure they can buy GRIFT
        (bool success, ) = payableOwner.call{value: msg.value}("");
        require(success, "Transfer failed.");

        // Make sure they've provided the right 10% fee
        uint256 overhead_amount = msg.value - _bnb_minus_overhead;
        uint256 expected_overhead_amount = (_bnb_minus_overhead / 100) *
            percent_fee;
        if (overhead_amount > expected_overhead_amount) {
            require(
                overhead_amount - expected_overhead_amount <
                    (expected_overhead_amount / 1000),
                "Re-check overhead calculations (too high)."
            );
        } else {
            require(
                expected_overhead_amount - overhead_amount <
                    (expected_overhead_amount / 1000),
                "Re-check overhead calculations (too low)."
            );
        }

        // Make sure the slippage isn't exceeded
        uint256 grift_to_buy = calculateGriftBought(_bnb_minus_overhead);
        uint256 grift_diff = 0;
        if (_grift_target > grift_to_buy) {
            grift_diff = _grift_target - grift_to_buy;
        } else {
            grift_diff = grift_to_buy - _grift_target;
        }
        uint256 max_slippage = (_grift_target / 100) * _slippage_percent;
        require(grift_diff < max_slippage, "Slippage too high.");

        // Transfer the GRIFT
        griftCoin.transfer(msg.sender, grift_to_buy);

        // Bookkeeping
        grift_reserves -= grift_to_buy;
        bnb_reserves += _bnb_minus_overhead;
    }

    function calculateGriftBought(uint256 _bnb_wei)
        public
        view
        returns (uint256)
    {
        uint256 total = bnb_reserves * grift_reserves;
        return grift_reserves - total / (bnb_reserves + _bnb_wei);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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