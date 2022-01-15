//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IReflectionDistributor.sol";
import "../libraries/SafeMath.sol";
import "../utils/Allowable.sol";

contract ReflectionDistributor is Allowable, IReflectionDistributor {
    using SafeMath for uint256;
    
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] private _shareholders;
    mapping (address => uint256) private _shareholderIndexes;
    mapping (address => uint256) private _shareholderClaims;
    mapping (address => Share) public _shares;
    
    uint256 public _totalShares;
    uint256 public _totalDistributed;
    uint256 public _dividendsPerShare;
    uint256 private _dividendsPerShareAccuracyFactor = 10 ** 21;
    
    uint256 public _minPeriod = 12 hours;
    uint256 public _minDistribution = 100_000_000 * 10 ** 18;
    
    uint256 private _currentBalance;
    uint256 private _currentIndex;

    receive() external payable {
        uint256 balance = address(this).balance;
        uint256 ethAmount = balance.sub(_currentBalance);
        _currentBalance = balance;

        if (_totalShares > 0) {
            _dividendsPerShare = _dividendsPerShare.add(ethAmount.div(_totalShares));
        }
    }

    function setDividendsPerShareAccuracyFactor(uint256 accuracyFactor) external onlyAllowed {
        _dividendsPerShareAccuracyFactor = accuracyFactor;
    }

    function setDistributionCriteria(uint256 minPeriod, uint256 minDistribution) external onlyAllowed {
        _minPeriod = minPeriod;
        _minDistribution = minDistribution * 10 ** 18;
    }

    function setShare(address shareholder, uint256 amount) external override onlyAllowed {
        _setShare(shareholder, amount);
    }

    function process(uint256 gas) external override onlyAllowed {
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;
        uint256 shareholderCount = _shareholders.length;

        while (iterations < shareholderCount && gasUsed < gas) {
            if (_currentIndex >= shareholderCount) {
                _currentIndex = 0;
            }

            address currentShareHolder = _shareholders[_currentIndex];
            uint256 currentAmount = IERC20(_msgSender()).balanceOf(currentShareHolder);

            if (_shares[currentShareHolder].amount != currentAmount) {
                _setShare(_shareholders[_currentIndex], currentAmount);
            }

            if (_shouldDistribute(_shareholders[_currentIndex])) {
                _distributeDividends(_shareholders[_currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            _currentIndex++;
            iterations++;
        }
    }
    
    function _shouldDistribute(address shareholder) private view returns (bool) {
        return
            block.timestamp >= _shareholderClaims[shareholder] + _minPeriod &&
            _getUnpaidEarnings(shareholder) >= _minDistribution;
    }
    
    function _getUnpaidEarnings(address shareholder) private view returns (uint256) {
        uint256 shareholderTotalDividends = _getCumulativeDividends(_shares[shareholder].amount);
        uint256 shareholderTotalExcluded = _shares[shareholder].totalExcluded;

        return shareholderTotalDividends > shareholderTotalExcluded
            ? shareholderTotalDividends.sub(shareholderTotalExcluded)
            : 0;
    }
    
    function _getCumulativeDividends(uint256 share) private view returns (uint256) {
        return share.mul(_dividendsPerShare);
    }

    function _setShare(address shareholder, uint256 amount) private {
        uint256 previousAmount = _shares[shareholder].amount;

        if (previousAmount == 0 && amount > 0) {
            _addShareholder(shareholder);
        }
        else if (previousAmount > 0 && amount == 0) {
            _removeShareholder(shareholder);
        }

        _shares[shareholder].amount = amount;
        _totalShares = _totalShares
            .sub(previousAmount.div(_dividendsPerShareAccuracyFactor))
            .add(amount.div(_dividendsPerShareAccuracyFactor));
        _shares[shareholder].totalExcluded = _getCumulativeDividends(previousAmount);
    }
    
    function _addShareholder(address shareholder) private {
        _shareholderIndexes[shareholder] = _shareholders.length;
        _shareholders.push(shareholder);
    }
    
    function _removeShareholder(address shareholder) private {
        _shareholders[_shareholderIndexes[shareholder]] = _shareholders[_shareholders.length - 1];
        _shareholderIndexes[_shareholders[_shareholders.length - 1]] = _shareholderIndexes[shareholder];
        _shareholders.pop();
    }
    
    function _distributeDividends(address shareholder) private {
        uint256 amount = _getUnpaidEarnings(shareholder);
        _totalDistributed = _totalDistributed.add(amount);

        ( bool successShareholder, /* bytes memory data */ ) = payable(shareholder).call{value: amount, gas: 30_000}("");
        require(successShareholder, "ReflectionDistributor: Provider receiver rejected ETH transfer");
        _currentBalance = _currentBalance.sub(amount);

        _shareholderClaims[shareholder] = block.timestamp;
        _shares[shareholder].totalRealised = _shares[shareholder].totalRealised.add(amount);
        _shares[shareholder].totalExcluded = _getCumulativeDividends(_shares[shareholder].amount);
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
    function process(uint256 gas) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
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