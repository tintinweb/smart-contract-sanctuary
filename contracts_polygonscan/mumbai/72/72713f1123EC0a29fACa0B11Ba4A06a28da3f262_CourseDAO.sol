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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICoursePass.sol";

/*
 * @dev Manages the sales, refund and distribution of course sales.
 */

contract CourseDAO is Ownable {
    IERC20 public USDC;
    ICoursePass public COURSE_PASS;

    struct Shareholder {
        uint256 shares;
        uint256 totalClaimed;
    }

    mapping(address => Shareholder) public shareholders;
    address[] public shareholderAddresses;
    uint256 public totalShares;
    uint256 public coursePrice = 500 * 10**6; // USDC has 6 decimals
    uint256 public refundRate = 90; // 90% Refund Rate

    uint256 public refundedCount = 0;
    uint256 private lastNonRefundable = 0; // tokenId of first Non-Refundable

    modifier onlyShareholders() {
        require(isShareholder(msg.sender), "CourseDAO: Not a shareholder");
        _;
    }

    constructor(address _usdcAddress, address _coursePass) {
        USDC = IERC20(_usdcAddress);
        COURSE_PASS = ICoursePass(_coursePass);
    }

    function purchaseCourse() public {
        // Mint 1 Course Pass
        COURSE_PASS.mint(msg.sender);
        // Transfer USDC
        USDC.transferFrom(msg.sender, address(this), coursePrice);

        _updateRefundable();
    }

    /// @dev Allow user to refund their course
    function refundCourse(uint256 tokenId) public {
        require(
            msg.sender == COURSE_PASS.ownerOf(tokenId),
            "CourseDAO: You are not the owner!"
        );
        require(
            COURSE_PASS.isRefundable(tokenId),
            "CourseDAO: Token is not refundable!"
        );
        // Burn Token
        COURSE_PASS.refund(tokenId);
        // Refund USDC
        uint256 amountToRefund = (coursePrice * refundRate) / 100;
        USDC.transfer(msg.sender, amountToRefund);

        refundedCount += 1;
    }

    /// @dev Calculate Unlocked Funds
    /// @dev Balance of USDC in this Contract - Locked Funds
    function getUnlockedFunds() public view returns (uint256) {
        return USDC.balanceOf(address(this)) - getLockedFunds();
    }

    /// @dev Calculated Locked Funds (for refunds)
    /// @dev Number of refundable courses * COURSE_PRICE
    function getLockedFunds() public view returns (uint256) {
        uint256 refundableCourses = _countRefundable();
        return coursePrice * refundableCourses;
    }

    /// @dev Returns the count of refundable courses
    function _updateRefundable() private {
        uint256 totalSupply = COURSE_PASS.totalSupply();
        for (uint256 i = lastNonRefundable; i <= totalSupply; i++) {
            if (COURSE_PASS.isRefundable(i)) {
                lastNonRefundable = i - 1;
                break;
            }
        }
    }

    /// @dev Returns the count of refundable courses
    function _countRefundable() private view returns (uint256) {
        uint256 totalSupply = COURSE_PASS.totalSupply();
        return totalSupply - lastNonRefundable - refundedCount;
    }

    /// @dev Returns the count of non-refundable courses
    function _countNonRefundable() private view returns (uint256) {
        return lastNonRefundable - refundedCount;
    }

    /// @dev Set Price of Course in USDC
    function setCoursePrice(uint256 _newPrice) public onlyOwner {
        coursePrice = _newPrice;
    }

    /// @dev Set Course Pass
    function setCoursePass(address _coursePass) public onlyOwner {
        COURSE_PASS = ICoursePass(_coursePass);
    }

    /// @dev Set Time Period before course pass becomes un-refundable
    function setRefundPeriod(uint256 _time) public onlyOwner {
        COURSE_PASS._setRefundPeriod(_time);
    }

    /// @dev Set Time Period to course pass becoming tradable
    function setTradablePeriod(uint256 _time) public onlyOwner {
        COURSE_PASS._setTradablePeriod(_time);
    }

    /// @dev Add Shares of Shareholder
    function addShares(address _shareholder, uint256 _shares) public onlyOwner {
        shareholders[_shareholder].shares += _shares;
        totalShares += _shares;
    }

    /// @dev Remove Shares of Shareholder
    function removeShares(address _shareholder, uint256 _shares)
        public
        onlyOwner
    {
        shareholders[_shareholder].shares -= _shares;
        totalShares -= _shares;
    }

    /// @dev Add Shareholder to List
    function addShareholder(address _user, uint256 _shares) public onlyOwner {
        shareholderAddresses.push(_user);
        shareholders[_user] = Shareholder(_shares, 0);

        totalShares += _shares;
    }

    /// @dev Remove Shareholder from list
    function removeShareholder(address _user) public onlyOwner {
        uint8 shareholderIndex = _findInList(shareholderAddresses, _user);
        _removeFromsList(shareholderAddresses, shareholderIndex);

        uint256 shares = shareholders[_user].shares;
        totalShares -= shares;
    }

    /// @dev Distribute Profits to shareholders
    function distributeProfits() public onlyShareholders {
        uint256 sharableProfits = getUnlockedFunds();
        for (uint256 i; i < shareholderAddresses.length; i++) {
            Shareholder storage shareholder = shareholders[
                shareholderAddresses[i]
            ];
            uint256 amount = (sharableProfits * shareholder.shares) /
                totalShares;
            USDC.transfer(shareholderAddresses[i], amount);
        }
    }

    /// @dev Check if user is a shareholder
    function isShareholder(address _user) public view returns (bool) {
        for (uint256 i = 0; i < shareholderAddresses.length; i++) {
            if (_user == shareholderAddresses[i]) {
                return true;
            }
        }
        return false;
    }

    /// @dev Find and item from a list
    function _findInList(address[] memory _list, address _user)
        private
        pure
        returns (uint8)
    {
        for (uint8 i; i < _list.length; i++) {
            if (_user == _list[i]) {
                return i;
            }
        }
        revert("CourseDAO: Not found in list");
    }

    /// @dev Remove an item from a list
    function _removeFromsList(address[] storage _list, uint8 _index) private {
        require(_index < _list.length);
        _list[_index] = _list[_list.length - 1];
        _list.pop();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICoursePass {
    function mint(address to) external;

    function refund(uint256 tokenId) external;

    function isRefundable(uint256 tokenId) external view returns (bool);

    function isTradable(uint256 tokenId) external view returns (bool);

    function _setRefundPeriod(uint256 _time) external;

    function _setTradablePeriod(uint256 _time) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function totalSupply() external view returns (uint256);
}