//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IReflectionDistributor.sol";
import "../utils/Allowable.sol";

contract ReflectionDistributor is Allowable, IReflectionDistributor {
    struct Share {
        bool initialized;
        uint256 amount;
        uint256 totalExcluded;
        uint256 lastClaim;
    }

    uint256 public _minPeriod = 12 hours;
    uint256 public _minTokenToHold = 100_000_000 * 10 ** 18;
    uint256 public _minDistribution = 1_000_000 * 10 ** 9;  // 0.0001 ETH

    address[] public _shareholders;
    mapping (address => Share) public _shares;

    uint256 private _totalAmount;
    uint256 private _totalEthReceived;
    uint256 private _totalEthDistributed;

    uint256 public _dividendsPerShare;
    uint256 public _dividendsPerShareAccuracyFactor = 1_000 * 10 ** 18;
    
    uint256 private _currentIndex;
    
    event DividendendsDistributed(address account, uint256 amount);

    receive() external payable {
        _totalEthReceived += msg.value;
    }

    function shareholderShares(address shareholder) public view returns (uint256) {
        return _shares[shareholder].amount / _dividendsPerShareAccuracyFactor;
    }

    function claimableDividends(address shareholder) public view returns (uint256) {
        return shareholderShares(shareholder) * dividendsPerShare();
    }

    function totalAmount() public view returns (uint256) {
        return _totalAmount;
    }

    function totalShares() public view returns (uint256) {
        return _totalAmount / _dividendsPerShareAccuracyFactor;
    }

    function totalEthReceived() external view returns (uint256) {
        return _totalEthReceived;
    }

    function totalEthDistributed() external view returns (uint256) {
        return _totalEthDistributed;
    }

    function dividendsPerShare() public view returns (uint256) {
        return totalShares() > 0
            ? address(this).balance / totalShares()
            : 0;
    }

    function setMinPeriod(uint256 minPeriod) external onlyAllowed {
        _minPeriod = minPeriod;
    }

    function setMinTokenToHold(uint256 minTokenToHold) external onlyAllowed {
        _minTokenToHold = minTokenToHold * 10 ** 18;
    }

    function setMinDistribution(uint256 minDistribution) external onlyAllowed {
        _minDistribution = minDistribution * 10 ** 9;
    }

    function setShare(address shareholder, uint256 amount) external override onlyAllowed {
        _setShare(shareholder, amount);
    }

    function process(uint256 gas) external override onlyAllowed payable {
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;
        uint256 shareholderCount = _shareholders.length;
        
        while (iterations < shareholderCount && gasUsed < gas) {
            if (_currentIndex >= shareholderCount) {
                _currentIndex = 0;
            }

            address currentShareHolder = _shareholders[_currentIndex];
            uint256 holderAmount = IERC20(_msgSender()).balanceOf(currentShareHolder);

            if (_shares[currentShareHolder].amount != holderAmount) {
                _setShare(currentShareHolder, holderAmount);
            }

            if (_shouldDistribute(currentShareHolder)) {
                _distributeDividends(currentShareHolder);
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            _currentIndex++;
            iterations++;
        }
    }

    function _shouldDistribute(address shareholder) private view returns (bool) {
        return
            block.timestamp >= _shares[shareholder].lastClaim + _minPeriod &&
            _shares[shareholder].amount >= _minDistribution;
    }
    
    function _setShare(address shareholder, uint256 amount) private {
        if (!_shares[shareholder].initialized) {
            _addShareholder(shareholder);
            _shares[shareholder].initialized = true;
            _shares[shareholder].lastClaim = block.timestamp;
        }

        if (amount >= _minTokenToHold) {
            uint256 previousAmount = _shares[shareholder].amount;
            _shares[shareholder].amount = amount;
            _totalAmount = _totalAmount - previousAmount + amount;
        } else {
            uint256 previousAmount = _shares[shareholder].amount;
            _shares[shareholder].amount = 0;
            _totalAmount = _totalAmount - previousAmount;
        }
    }

    function _addShareholder(address shareholder) private {
        _shareholders.push(shareholder);
    }
    
    function _distributeDividends(address shareholder) private {
        uint256 amount = claimableDividends(shareholder);
        
        if (amount > 0) {
            ( bool successShareholder, /* bytes memory data */ ) = payable(shareholder).call{value: amount, gas: 30_000}("");
            require(successShareholder, "ReflectionDistributor: Provider receiver rejected ETH transfer");

            emit DividendendsDistributed(shareholder, amount);
            
            _totalEthDistributed = _totalEthDistributed + amount;
            
            _shares[shareholder].lastClaim = block.timestamp;
        }
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IReflectionDistributor {
    function setShare(address shareholder, uint256 amount) external;
    function process(uint256 gas) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Allowable is Ownable {
    mapping (address => bool) private _allowables;

    event AllowableChanged(address indexed allowable, bool enabled);

    constructor() {
        _allow(_msgSender(), true);
    }

    modifier onlyAllowed() {
        require(_allowables[_msgSender()], "Allowable: caller is not allowed");
        _;
    }

    function allow(address allowable, bool enabled) public onlyAllowed {
        _allow(allowable, enabled);
    }

    function isAllowed(address allowable) public view returns (bool) {
        return _allowables[allowable];
    }

    function _allow(address allowable, bool enabled) internal {
        _allowables[allowable] = enabled;
        emit AllowableChanged(allowable, enabled);
    }

    function _transferOwnership(address newOwner) internal override {
        _allow(_msgSender(), false);
        super._transferOwnership(newOwner);
    }
}

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