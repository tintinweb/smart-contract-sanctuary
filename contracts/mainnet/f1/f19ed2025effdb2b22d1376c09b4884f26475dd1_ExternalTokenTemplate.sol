// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;



/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/TownToken.sol

pragma solidity ^0.5.0;



interface TownInterface {
    function checkProposal(address proposal) external returns (bool);
    function voteOn(address externalToken, uint256 amount) external returns (bool);
}


contract TownToken is ERC20, Ownable {
    using SafeMath for uint256;

    string public constant name = "Town Token";
    string public constant symbol = "TTW";
    uint8 public constant decimals = 18;

    bool public initiated;

    address[] private _holders;

    TownInterface _town;

    constructor () public {
        initiated = false;
    }

    function getHoldersCount() external view returns (uint256) {
        return _holders.length;
    }

    function getHolderByIndex(uint256 index) external view returns (address) {
        return _holders[index];
    }

    function init (uint256 totalSupply, address townContract) public onlyOwner {
        require(initiated == false, "contract already initiated");
        _town = TownInterface(townContract);
        _mint(townContract, totalSupply);
        initiated = true;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        if (msg.sender != address(_town)) {
            if (_town.checkProposal(recipient) == true) {
                super.transfer(address(_town), amount);
                return _town.voteOn(recipient, amount);
            }
            // check 223 ERC and call voteOn function
        }

        if (recipient != address(_town)) {
            bool found = false;
            for (uint i = 0; i < _holders.length; ++i) {    // find recipient address in holders list
                if (_holders[i] == recipient) {
                    found = true;
                    break;
                }
            }
            if (found == false) {                           // if recipient not found, we push new address
                _holders.push(recipient);
            }
        }

        if (balanceOf(address(msg.sender)) == amount && msg.sender != address(_town)) { // remove address with 0 balance from holders
            uint i = 0;
            for (; i < _holders.length; ++i) {
                if (_holders[i] == address(msg.sender)) {
                    break;
                }
            }

            if (i < (_holders.length - 1)) {
                _holders[i] = _holders[_holders.length - 1];
                delete _holders[_holders.length - 1];
                _holders.length--;
            }
        }

        return super.transfer(recipient, amount);
    }
}

// File: contracts/ExternalTokenTemplate.sol

pragma solidity ^0.5.0;



contract ExternalTokenTemplate is ERC20 {
    using SafeMath for uint256;

    string public constant name = "Karma Finance";
    string public constant symbol = "KFI";
    uint8 public constant decimals = 18;

    constructor (uint256 totalSupply) public {
        _mint(msg.sender, totalSupply);
    }
}

// File: contracts/Town.sol

pragma solidity ^0.5.0;




contract Town is TownInterface {
    using SafeMath for uint256;

    uint256 private _distributionPeriod;
    uint256 private _distributionPeriodsNumber;
    uint256 private _startRate;
    uint256 private _minTokenGetAmount;
    uint256 private _durationOfMinTokenGetAmount;
    uint256 private _maxTokenGetAmount;
    uint256 private _minExternalTokensAmount;
    uint256 private _minSignAmount;
    uint256 private _lastDistributionsDate;

    uint256 private _transactionsCount;

    struct ExternalTokenDistributionsInfo {
        address _official;
        uint256 _distributionAmount;
        uint256 _distributionsCount;
    }

    struct ExternalToken {
        ExternalTokenDistributionsInfo[] _entities;
        uint256 _weight;
    }

    struct TransactionsInfo {
        uint256 _rate;
        uint256 _amount;
    }

    struct TownTokenRequest {
        address _address;
        TransactionsInfo _info;
    }

    struct RemunerationsInfo {
        address payable _address;
        uint256 _priority;
        uint256 _amount;
    }

    struct RemunerationsOfficialsInfo {
        uint256 _amount;
        uint256 _decayTimestamp;
    }

    TownToken private _token;

    mapping (address => TransactionsInfo[]) private _historyTransactions;

    TownTokenRequest[] private _queueTownTokenRequests;

    RemunerationsInfo[] private _remunerationsQueue;

    mapping (address => ExternalToken) private _externalTokens;
    address[] private _externalTokensAddresses;

    mapping (address => mapping (address => uint256)) private _townHoldersLedger;
    mapping (address => address[]) private _ledgerExternalTokensAddresses;

    mapping (address => RemunerationsOfficialsInfo) private _officialsLedger;

    address[] private _externalTokensWithWight;

    modifier onlyTownTokenSmartContract {
        require(msg.sender == address(_token), "only town token smart contract can call this function");
        _;
    }

    constructor (
        uint256 distributionPeriod,
        uint256 distributionPeriodsNumber,
        uint256 startRate,
        uint256 minTokenGetAmount,
        uint256 durationOfMinTokenGetAmount,
        uint256 maxTokenGetAmount,
        uint256 minExternalTokensAmount,
        address tokenAddress) public {
        require(distributionPeriod > 0, "distributionPeriod wrong");
        require(distributionPeriodsNumber > 0, "distributionPeriodsNumber wrong");
        require(minTokenGetAmount > 0, "minTokenGetAmount wrong");
        require(durationOfMinTokenGetAmount > 0, "durationOfMinTokenGetAmount wrong");
        require(maxTokenGetAmount > 0, "maxTokenGetAmount wrong");
        require(minExternalTokensAmount > 0, "minExternalTokensAmount wrong");

        _distributionPeriod = distributionPeriod * 1 days;
        _distributionPeriodsNumber = distributionPeriodsNumber;
        _startRate = startRate;

        _token = TownToken(tokenAddress);

        _transactionsCount = 0;
        _minTokenGetAmount = minTokenGetAmount;
        _durationOfMinTokenGetAmount = durationOfMinTokenGetAmount;
        _maxTokenGetAmount = maxTokenGetAmount;
        _minExternalTokensAmount = minExternalTokensAmount;
        _lastDistributionsDate = (now.div(86400).add(1)).mul(86400);
        _minSignAmount = 10000000000000;
    }

    function () external payable {
        if (msg.value <= _minSignAmount) {
            if (_officialsLedger[msg.sender]._amount > 0) {
                claimFunds(msg.sender);
            }
            if (_ledgerExternalTokensAddresses[msg.sender].length > 0) {
                claimExternalTokens(msg.sender);
            }
            return;
        }
        uint256 tokenAmount = IWantTakeTokensToAmount(msg.value);
        require(_transactionsCount > _durationOfMinTokenGetAmount || tokenAmount > _minTokenGetAmount, "insufficient amount");

        getTownTokens(msg.sender);
    }

    function token() external view returns (IERC20) {
        return _token;
    }

    function distributionPeriod() external view returns (uint256) {
        return _distributionPeriod;
    }

    function distributionPeriodsNumber() external view returns (uint256) {
        return _distributionPeriodsNumber;
    }

    function startRate() external view returns (uint256) {
        return _startRate;
    }

    function minTokenGetAmount() external view returns (uint256) {
        return _minTokenGetAmount;
    }

    function durationOfMinTokenGetAmount() external view returns (uint256) {
        return _durationOfMinTokenGetAmount;
    }

    function maxTokenGetAmount() external view returns (uint256) {
        return _maxTokenGetAmount;
    }

    function minExternalTokensAmount() external view returns (uint256) {
        return _minExternalTokensAmount;
    }

    function lastDistributionsDate() external view returns (uint256) {
        return _lastDistributionsDate;
    }

    function transactionsCount() external view returns (uint256) {
        return _transactionsCount;
    }

    function getCurrentRate() external view returns (uint256) {
        return currentRate();
    }

    function getLengthRemunerationQueue() external view returns (uint256) {
        return _remunerationsQueue.length;
    }

    function getMinSignAmount() external view returns (uint256) {
        return _minSignAmount;
    }

    function getRemunerationQueue(uint256 index) external view returns (address, uint256, uint256) {
        return (_remunerationsQueue[index]._address, _remunerationsQueue[index]._priority, _remunerationsQueue[index]._amount);
    }

    function getLengthQueueTownTokenRequests() external view returns (uint256) {
        return _queueTownTokenRequests.length;
    }

    function getQueueTownTokenRequests(uint256 index) external  view returns (address, uint256, uint256) {
        TownTokenRequest memory tokenRequest = _queueTownTokenRequests[index];
        return (tokenRequest._address, tokenRequest._info._rate, tokenRequest._info._amount);
    }

    function getMyTownTokens() external view returns (uint256, uint256) {
        uint256 amount = 0;
        uint256 tokenAmount = 0;
        for (uint256 i = 0; i < _historyTransactions[msg.sender].length; ++i) {
            amount = amount.add(_historyTransactions[msg.sender][i]._amount.mul(_historyTransactions[msg.sender][i]._rate).div(10 ** 18));
            tokenAmount = tokenAmount.add(_historyTransactions[msg.sender][i]._amount);
        }
        return (amount, tokenAmount);
    }

    function checkProposal(address proposal) external returns (bool) {
        if (_externalTokens[proposal]._entities.length > 0) {
            return true;
        }
        return false;
    }

    function sendExternalTokens(address official, address externalToken) external returns (bool) {
        ERC20 tokenERC20 = ERC20(externalToken);
        uint256 balance = tokenERC20.allowance(official, address(this));
        require(tokenERC20.balanceOf(official) >= balance, "Official should have external tokens for approved");
        require(balance > 0, "External tokens must be approved for town smart contract");
        tokenERC20.transferFrom(official, address(this), balance);

        ExternalTokenDistributionsInfo memory tokenInfo;
        tokenInfo._official = official;
        tokenInfo._distributionsCount = _distributionPeriodsNumber;
        tokenInfo._distributionAmount = balance.div(_distributionPeriodsNumber);

        ExternalToken storage tokenObj = _externalTokens[externalToken];

        if (tokenObj._entities.length == 0) {
            _externalTokensAddresses.push(externalToken);
        }

        tokenObj._entities.push(tokenInfo);

        return true;
    }

    function remuneration(uint256 tokensAmount) external returns (bool) {
        require(_token.balanceOf(msg.sender) >= tokensAmount, "Town tokens not found");
        require(_token.allowance(msg.sender, address(this)) >= tokensAmount, "Town tokens must be approved for town smart contract");

        uint256 debt = 0;
        uint256 restOfTokens = tokensAmount;
        uint256 executedRequestCount = 0;
        for (uint256 i = 0; i < _queueTownTokenRequests.length; ++i) {
            address user = _queueTownTokenRequests[i]._address;
            uint256 rate = _queueTownTokenRequests[i]._info._rate;
            uint256 amount = _queueTownTokenRequests[i]._info._amount;
            if (restOfTokens > amount) {
                _token.transferFrom(msg.sender, user, amount);
                restOfTokens = restOfTokens.sub(amount);
                debt = debt.add(amount.mul(rate).div(10 ** 18));
                executedRequestCount++;
            } else {
                break;
            }
        }

        if (restOfTokens > 0) {
            _token.transferFrom(msg.sender, address(this), restOfTokens);
        }

        if (executedRequestCount > 0) {
            for (uint256 i = executedRequestCount; i < _queueTownTokenRequests.length; ++i) {
                _queueTownTokenRequests[i - executedRequestCount] = _queueTownTokenRequests[i];
            }

            for (uint256 i = 0; i < executedRequestCount; ++i) {
                delete _queueTownTokenRequests[_queueTownTokenRequests.length - 1];
                _queueTownTokenRequests.length--;
            }
        }

        if (_historyTransactions[msg.sender].length > 0) {
            for (uint256 i = _historyTransactions[msg.sender].length - 1; ; --i) {
                uint256 rate = _historyTransactions[msg.sender][i]._rate;
                uint256 amount = _historyTransactions[msg.sender][i]._amount;
                delete _historyTransactions[msg.sender][i];
                _historyTransactions[msg.sender].length--;

                if (restOfTokens < amount) {
                    TransactionsInfo memory info = TransactionsInfo(rate, amount.sub(restOfTokens));
                    _historyTransactions[msg.sender].push(info);

                    debt = debt.add(restOfTokens.mul(rate).div(10 ** 18));
                    break;
                }

                debt = debt.add(amount.mul(rate).div(10 ** 18));
                restOfTokens = restOfTokens.sub(amount);

                if (i == 0) break;
            }
        }

        if (debt > address(this).balance) {
            msg.sender.transfer(address(this).balance);

            RemunerationsInfo memory info = RemunerationsInfo(msg.sender, 2, debt.sub(address(this).balance));
            _remunerationsQueue.push(info);
        } else {
            msg.sender.transfer(debt);
        }

        return true;
    }

    function distributionSnapshot() external returns (bool) {
        require(now > (_lastDistributionsDate + _distributionPeriod), "distribution time has not yet arrived");

        uint256 sumWeight = 0;
        address[] memory tempArray;
        _externalTokensWithWight = tempArray;
        for (uint256 i = 0; i < _externalTokensAddresses.length; ++i) {
            ExternalToken memory externalToken = _externalTokens[_externalTokensAddresses[i]];
            if (externalToken._weight > 0) {
                uint256 sumExternalTokens = 0;
                for (uint256 j = 0; j < externalToken._entities.length; ++j) {
                    if (externalToken._entities[j]._distributionsCount > 0) {
                        ExternalTokenDistributionsInfo memory info = externalToken._entities[j];
                        sumExternalTokens = sumExternalTokens.add(info._distributionAmount.mul(info._distributionsCount));
                    }
                }
                if (sumExternalTokens > _minExternalTokensAmount) {
                    sumWeight = sumWeight.add(externalToken._weight);
                    _externalTokensWithWight.push(_externalTokensAddresses[i]);
                } else {
                    externalToken._weight = 0;
                }
            }
        }

        uint256 fullBalance = address(this).balance;
        for (uint256 i = 0; i < _externalTokensWithWight.length; ++i) {
            ExternalToken memory externalToken = _externalTokens[_externalTokensWithWight[i]];
            uint256 sumExternalTokens = 0;
            for (uint256 j = 0; j < externalToken._entities.length; ++j) {
                sumExternalTokens = sumExternalTokens.add(externalToken._entities[j]._distributionAmount);
            }
            uint256 externalTokenCost = fullBalance.mul(externalToken._weight).div(sumWeight);
            for (uint256 j = 0; j < externalToken._entities.length; ++j) {
                address official = externalToken._entities[j]._official;
                uint256 tokensAmount = externalToken._entities[j]._distributionAmount;
                uint256 amount = externalTokenCost.mul(tokensAmount).div(sumExternalTokens);
                uint256 decayTimestamp = (now - _lastDistributionsDate).div(_distributionPeriod).mul(_distributionPeriod).add(_lastDistributionsDate).add(_distributionPeriod);
                _officialsLedger[official] = RemunerationsOfficialsInfo(amount, decayTimestamp);
            }
        }

        uint256 sumHoldersTokens = _token.totalSupply().sub(_token.balanceOf(address(this)));

        if (sumHoldersTokens != 0) {
            for (uint256 i = 0; i < _token.getHoldersCount(); ++i) {
                address holder = _token.getHolderByIndex(i);
                uint256 balance = _token.balanceOf(holder);
                for (uint256 j = 0; j < _externalTokensAddresses.length; ++j) {
                    address externalTokenAddress = _externalTokensAddresses[j];
                    ExternalToken memory externalToken = _externalTokens[externalTokenAddress];
                    for (uint256 k = 0; k < externalToken._entities.length; ++k) {
                        if (holder != address(this) && externalToken._entities[k]._distributionsCount > 0) {
                            uint256 percent = balance.mul(externalToken._entities[k]._distributionAmount).div(sumHoldersTokens);
                            if (percent > (10 ** 4)) {
                                address[] memory externalTokensForHolder = _ledgerExternalTokensAddresses[holder];
                                bool found = false;
                                for (uint256 h = 0; h < externalTokensForHolder.length; ++h) {
                                    if (externalTokensForHolder[h] == externalTokenAddress) {
                                        found = true;
                                        break;
                                    }
                                }
                                if (found == false) {
                                    _ledgerExternalTokensAddresses[holder].push(externalTokenAddress);
                                }

                                _townHoldersLedger[holder][externalTokenAddress] = _townHoldersLedger[holder][externalTokenAddress].add(percent);
                            }
                        }
                    }
                }
            }

            for (uint256 j = 0; j < _externalTokensAddresses.length; ++j) {
                ExternalTokenDistributionsInfo[] memory tempEntities = _externalTokens[_externalTokensAddresses[j]]._entities;

                for (uint256 k = 0; k < tempEntities.length; ++k) {
                    delete _externalTokens[_externalTokensAddresses[j]]._entities[k];
                }
                _externalTokens[_externalTokensAddresses[j]]._entities.length = 0;

                for (uint256 k = 0; k < tempEntities.length; ++k) {
                    tempEntities[k]._distributionsCount--;
                    if (tempEntities[k]._distributionsCount > 0) {
                        _externalTokens[_externalTokensAddresses[j]]._entities.push(tempEntities[k]);
                    }
                }
            }
        }

        for (uint256 i = 0; i < _externalTokensAddresses.length; ++i) {
            if (_externalTokens[_externalTokensAddresses[i]]._weight > 0) {
                _externalTokens[_externalTokensAddresses[i]]._weight = 0;
            }
        }

        _lastDistributionsDate = _lastDistributionsDate.add(_distributionPeriod);
        return true;
    }

    function voteOn(address externalToken, uint256 amount) external onlyTownTokenSmartContract returns (bool) {
        require(_externalTokens[externalToken]._entities.length > 0, "external token address not found");
        require(now < (_lastDistributionsDate + _distributionPeriod), "need call distributionSnapshot function");

        _externalTokens[externalToken]._weight = _externalTokens[externalToken]._weight.add(amount);
        return true;
    }

    function claimExternalTokens(address holder) public returns (bool) {
        address[] memory externalTokensForHolder = _ledgerExternalTokensAddresses[holder];
        if (externalTokensForHolder.length > 0) {
            for (uint256 i = externalTokensForHolder.length - 1; ; --i) {
                ERC20(externalTokensForHolder[i]).transfer(holder, _townHoldersLedger[holder][externalTokensForHolder[i]]);
                delete _townHoldersLedger[holder][externalTokensForHolder[i]];
                delete _ledgerExternalTokensAddresses[holder][i];
                _ledgerExternalTokensAddresses[holder].length--;

                if (i == 0) break;
            }
        }

        return true;
    }

    function claimFunds(address payable official) public returns (bool) {
        require(_officialsLedger[official]._amount != 0, "official address not found in ledger");

        if (now >= _officialsLedger[official]._decayTimestamp) {
            RemunerationsOfficialsInfo memory info = RemunerationsOfficialsInfo(0, 0);
            _officialsLedger[official] = info;
            return false;
        }

        uint256 amount = _officialsLedger[official]._amount;
        if (address(this).balance >= amount) {
            official.transfer(amount);
        } else {
            RemunerationsInfo memory info = RemunerationsInfo(official, 1, amount);
            _remunerationsQueue.push(info);
        }
        RemunerationsOfficialsInfo memory info = RemunerationsOfficialsInfo(0, 0);
        _officialsLedger[official] = info;

        return true;
    }

    function IWantTakeTokensToAmount(uint256 amount) public view returns (uint256) {
        return amount.mul(10 ** 18).div(currentRate());
    }

    function getTownTokens(address holder) public payable returns (bool) {
        require(holder != address(0), "holder address cannot be null");

        uint256 amount = msg.value;
        uint256 tokenAmount = IWantTakeTokensToAmount(amount);
        uint256 rate = currentRate();
        if (_transactionsCount < _durationOfMinTokenGetAmount && tokenAmount < _minTokenGetAmount) {
            return false;
        }
        if (tokenAmount >= _maxTokenGetAmount) {
            tokenAmount = _maxTokenGetAmount;
            uint256 change = amount.sub(_maxTokenGetAmount.mul(rate).div(10 ** 18));
            msg.sender.transfer(change);
            amount = amount.sub(change);
        }

        if (_token.balanceOf(address(this)) >= tokenAmount) {
            TransactionsInfo memory transactionsHistory = TransactionsInfo(rate, tokenAmount);
            _token.transfer(holder, tokenAmount);
            _historyTransactions[holder].push(transactionsHistory);
            _transactionsCount = _transactionsCount.add(1);
        } else {
            if (_token.balanceOf(address(this)) > 0) {
                uint256 tokenBalance = _token.balanceOf(address(this));
                _token.transfer(holder, tokenBalance);
                TransactionsInfo memory transactionsHistory = TransactionsInfo(rate, tokenBalance);
                _historyTransactions[holder].push(transactionsHistory);
                tokenAmount = tokenAmount.sub(tokenBalance);
            }

            TransactionsInfo memory transactionsInfo = TransactionsInfo(rate, tokenAmount);
            TownTokenRequest memory tokenRequest = TownTokenRequest(holder, transactionsInfo);
            _queueTownTokenRequests.push(tokenRequest);
        }

        for (uint256 i = 0; i < _remunerationsQueue.length; ++i) {
            if (_remunerationsQueue[i]._priority == 1) {
                if (_remunerationsQueue[i]._amount > amount) {
                    _remunerationsQueue[i]._address.transfer(_remunerationsQueue[i]._amount);
                    amount = amount.sub(_remunerationsQueue[i]._amount);

                    delete _remunerationsQueue[i];
                    for (uint j = i + 1; j < _remunerationsQueue.length; ++j) {
                        _remunerationsQueue[j - 1] = _remunerationsQueue[j];
                    }
                    _remunerationsQueue.length--;
                } else {
                    _remunerationsQueue[i]._address.transfer(amount);
                    _remunerationsQueue[i]._amount = _remunerationsQueue[i]._amount.sub(amount);
                    break;
                }
            }
        }

        for (uint256 i = 0; i < _remunerationsQueue.length; ++i) {
            if (_remunerationsQueue[i]._amount > amount) {
                _remunerationsQueue[i]._address.transfer(_remunerationsQueue[i]._amount);
                amount = amount.sub(_remunerationsQueue[i]._amount);

                delete _remunerationsQueue[i];
                for (uint j = i + 1; j < _remunerationsQueue.length; ++j) {
                    _remunerationsQueue[j - 1] = _remunerationsQueue[j];
                }
                _remunerationsQueue.length--;
            } else {
                _remunerationsQueue[i]._address.transfer(amount);
                _remunerationsQueue[i]._amount = _remunerationsQueue[i]._amount.sub(amount);
                break;
            }
        }

        return true;
    }

    function currentRate() internal view returns (uint256) {
        return _startRate;
    }
}