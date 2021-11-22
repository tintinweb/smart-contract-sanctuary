// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/ITokenVesting.sol";
import "./interfaces/ITokenVestingFactory.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TokenVesting.sol";

contract TokenVestingFactory is ITokenVestingFactory {
    address internal _router;

    function deployTokenVesting(address token, address router_, address owner) external override returns (address) {
        require(msg.sender == _router, "ROUTER");
        ITokenVesting tokenVesting = new TokenVesting(token, router_, owner);
        return address(tokenVesting);
    }

    function router() external view override returns (address) {
        return _router;
    }

    function initialize(address router_) external override {
        _router = router_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ITokenVesting {
    function depositAndConfigureVesting(
        uint256[] memory timestamps, 
        uint256[] memory amounts, 
        address investor
    ) external;

    function router() external view returns(address);

    function token() external view returns(address);

    function claim() external;

    function breakExpiredLocksOf(address investor) external;

    function claimableAmountOf(address investor) external view returns(uint256);

    function detailedLocksOf(address investor) external view returns(uint256[] memory, uint256[] memory);

    function lockedAmountOf(address investor) external view returns(uint256);

    function totalDepositsOf(address investor) external view returns(uint256);

    function totalClaimsOf(address investor) external view returns(uint256);

    event ConfiguredVesting(address indexed investor, uint256[] timestamps, uint256[] amounts);

    event Claimed(address indexed investor, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ITokenVestingFactory {
    function deployTokenVesting(address token, address router, address owner) external returns (address);

    function initialize(address router_) external;
    function router() external view returns (address);
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
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/Heap.sol";
import "./interfaces/ITokenVesting.sol";
import "./interfaces/ITokenVestingRouter.sol";


contract TokenVesting is ITokenVesting, Ownable {
    using SummingPriorityQueue for SummingPriorityQueue.Heap;

    string constant public INVALID_VESTING_CONFIG_ERR = "errno#1";
    string constant public INVALID_AMOUNT_ERR = "errno#2";
    string constant public INVALID_ADDRESS_ERR = "errno#3";

    mapping(address => SummingPriorityQueue.Heap) internal _locks;
    mapping(address => uint256) internal _totalDeposits;
    mapping(address => uint256) internal _totalClaims;

    IERC20 internal _token;
    ITokenVestingRouter internal _router;

    constructor (address tokenAddress, address routerAddress, address newOwner) Ownable() {
        _token = IERC20(tokenAddress);
        _router = ITokenVestingRouter(routerAddress);
        transferOwnership(newOwner);
    }

    function depositAndConfigureVesting(
        uint256[] memory timestamps, 
        uint256[] memory amounts, 
        address investor
    ) external override onlyOwner {
        require(timestamps.length == amounts.length, INVALID_VESTING_CONFIG_ERR);
        uint256 vestingAmount = 0;
        for (uint256 i = 0; i < timestamps.length; ++i) {
            if (i == 0)
                require(timestamps[i] > block.timestamp, INVALID_VESTING_CONFIG_ERR);
            else
                require(timestamps[i] > timestamps[i - 1], INVALID_VESTING_CONFIG_ERR);
            _locks[investor].enqueue(timestamps[i], amounts[i]);
            vestingAmount += amounts[i];
        }
        _totalDeposits[investor] += vestingAmount;
        _token.transferFrom(msg.sender, address(this), vestingAmount);
        emit ConfiguredVesting(investor, timestamps, amounts);
    }

    function claim() external override {
        address investor = _msgSender();
        _breakExpiredLocksOf(investor);
        _claim(investor);
    }

    function breakExpiredLocksOf(address investor) external override {
        _breakExpiredLocksOf(investor);
    }

    function detailedLocksOf(address investor) external view override returns(uint256[] memory, uint256[] memory) {
        require(_totalDeposits[investor] != 0, INVALID_ADDRESS_ERR);
        uint256 locksCount = _locks[investor].keys.length - 1;
        uint256[] memory timestamps = new uint256[](locksCount);
        uint256[] memory amounts = new uint256[](locksCount);
        for (uint256 i = 1; i <= locksCount; ++i) {
            uint256 key = _locks[investor].keys[i];
            timestamps[i - 1] = key;
            amounts[i - 1] = _locks[investor].map[key];
        }
        return (timestamps, amounts);
    }

    function lockedAmountOf(address investor) external view override returns(uint256) {
        return _locks[investor].totalEnqueuedAmount;
    }

    function totalDepositsOf(address investor) external view override returns(uint256) {
        return _totalDeposits[investor];
    }

    function totalClaimsOf(address investor) external view override returns(uint256) {
        return _totalClaims[investor];
    }

    function claimableAmountOf(address investor) external view override returns(uint256) {
        return _claimableAmountOf(investor);
    }

    function token() external view override returns(address) {
        return address(_token);
    }

    function router() external view override returns(address) {
        return address(_router);
    }

    function _breakExpiredLocksOf(address investor) internal {
        _locks[investor].drain(block.timestamp);
    }

    function _claim(address investor) internal {
        uint256 availableAmount = _claimableAmountOf(investor);
        require(availableAmount != 0, INVALID_AMOUNT_ERR);
        _totalClaims[investor] += availableAmount;
        _token.transfer(investor, availableAmount);
        emit Claimed(investor, availableAmount);
    }

    function _claimableAmountOf(address investor) internal view returns(uint256) {
        return (
            _totalDeposits[investor] 
            - _totalClaims[investor] 
            - _locks[investor].totalEnqueuedAmount
        );
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


library SummingPriorityQueue {

    struct Heap {
        uint256[] keys;
        mapping(uint256 => uint256) map;
        uint256 totalEnqueuedAmount;
    }

    modifier notEmpty(Heap storage self) {
        require(self.keys.length > 1);
        _;
    }

    function top(Heap storage self) public view notEmpty(self) returns(uint256) {
        return self.keys[1];
    }

    function dequeue(Heap storage self) public notEmpty(self) {
        require(self.keys.length > 1);
        
        uint256 topKey = top(self);
        self.totalEnqueuedAmount -= self.map[topKey];
        delete self.map[topKey];
        self.keys[1] = self.keys[self.keys.length - 1];
        self.keys.pop();

        uint256 i = 1;
        while (i * 2 < self.keys.length) {
            uint256 j = i * 2;

            if (j + 1 < self.keys.length)
                if (self.keys[j + 1] < self.keys[j])
                    j++;
            

            if (self.keys[i] < self.keys[j])
                break;

            (self.keys[i], self.keys[j]) = (self.keys[j], self.keys[i]);
            i = j;
        }
    }

    function enqueue(Heap storage self, uint256 key, uint256 value) public {
        if (self.keys.length == 0) 
            self.keys.push(0); // initialize
        
        self.keys.push(key);
        uint256 i = self.keys.length - 1;

        while (i > 1 && self.keys[i / 2] > self.keys[i]) {
            (self.keys[i / 2], self.keys[i]) = (key, self.keys[i / 2]);
            i /= 2;
        }

        self.map[key] = value;
        self.totalEnqueuedAmount += value;
    }

    function drain(Heap storage self, uint256 ts) public {
        while (self.keys.length > 1 && top(self) < ts)
            dequeue(self);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ITokenVestingRouter {
    function createTokenVesting(address token) external returns (address);

    function tokenVestingOf(address token) external view returns (address);

    function tokenVestingAt(uint256 id) external view returns (address);

    function tokenVestingsCount() external view returns (uint256);

    function tokenVestingFactory() external view returns (address);

    function setTokenVestingFactory(address factory) external;
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