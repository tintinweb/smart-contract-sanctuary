// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;


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
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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


interface IStableV2 {
    // Stable balances management
    function update() external;
    // Management functions callable only be Milker
    function shareMilk(address taker) external returns (uint256);
    function bandits(uint256 amount) external returns (uint256, uint256, uint256);
    // Contract getters
    function milker() external view returns (address);
    function token() external view returns (address);
    function startTime() external view returns (uint256);
    function stakerTokens(address staker) external view returns (uint256);
    function stakerCorrection(address staker) external view returns (uint256);
    function tokenSupply() external view returns (uint256);
    function milkSupply() external view returns (uint256);
    // MILK production related getters
    function level() external view returns (uint256);
    function levelProgress() external view returns (uint256);
    function production() external view returns (uint256);
    function produced() external view returns (uint256);
    function distributed() external view returns (uint256);
    function pending() external view returns (uint256);
    function pendingTo(address account) external view returns (uint256);
}

interface IMilker is IERC20 {
    // Token management accessed only from StableV2 contracts
    function produceMilk(uint256 amount) external returns (uint256);
    function takeMilk(address account) external returns (uint256);
    // Primary MILK tokenomics events
    function bandits(uint256 percent) external returns (uint256, uint256, uint256);
    function sheriffsVaultCommission() external returns (uint256);
    function sheriffsPotDistribution() external returns (uint256);
    // Getters
    function startTime() external view returns (uint256);
    function isWhitelisted(address account) external view returns (bool);
    function vaultOf(address account) external view returns (uint256);
    function period() external view returns (uint256);
    function periodProgress() external view returns (uint256);
    function periodLength() external view returns (uint256);
    function production() external view returns (uint256);
    function producedTotal() external view returns (uint256);
    function distributedTotal() external view returns (uint256);
    function pendingTotal() external view returns (uint256);
    function pendingTo(address account) external view returns (uint256);
}

// solium-disable security/no-block-members

contract StableV2 is Ownable, IStableV2 {
    using SafeMath for uint256;

    // Stable contains info related to each staker.
    struct Staker {
        uint256 amount;      // amount of tokens currently staked to the Stable
        uint256 correction;  // value needed for correct calculation staker's share
        uint256 banditsCorrection;
        uint256 distributed; // amount of distributed MILK tokens
    }

    // Default deflationarity parameters.
    uint256 private constant REDUCING_INTERVAL = 7 days; // 7 days is time between reductions
    uint256 private constant REDUCING_FACTOR = 10;       // production is reduced by 10%

    // MILK token contract.
    IMilker private _milker;

    // ERC20 token contract staking to the Stable.
    IERC20 private _token;

    // Stakers info by token holders.
    mapping(address => Staker) private _stakers;

    // Common variables configuring of the Stable.
    uint256 private _startTime;

    // Common variables describing current state of the Stable.
    uint256 private _banditsCorrection = 1e18;
    uint256 private _tokensPerShare;
    uint256 private _distributed;
    uint256 private _production;
    uint256 private _produced;
    uint256 private _lastUpdateTime;


    // Events.
    event Initialized(uint256 startTime, uint256 initialProduction);
    event Bandits(
        uint256 indexed percent,
        uint256 totalAmount,
        uint256 arrestedAmount,
        uint256 burntAmount
    );
    event Staked(address indexed staker, uint256 amount);
    event Claimed(address indexed staker, uint256 amount);


    modifier onlyMilker() {
        require(address(_milker) == _msgSender(), "StableV2: caller is not the Milker contract");
        _;
    }


    constructor(address milker, address token) public {
        require(address(milker) != address(0), "StableV2: Milker contract address cannot be empty");
        require(address(token) != address(0), "StableV2: ERC20 token contract address cannot be empty");
        _milker = IMilker(milker);
        _token = IERC20(token);
        transferOwnership(Ownable(milker).owner());
    }

    function initialize(uint256 startTime, uint256 initialProductionPerDay) external onlyOwner {
        require(produced() == 0, "StableV2: already started");
        _startTime = startTime;
        _production = 7 * initialProductionPerDay;
        _lastUpdateTime = _startTime;
        emit Initialized(_startTime, _production);
    }

    function stake(uint256 amount) external {
        address staker = msg.sender;
        require(!_milker.isWhitelisted(staker), "StableV2: whitelisted MILK holders cannot stake tokens");

        // Recalculate stable shares
        update();

        // Transfer pending tokens (if any) to the staker
        _shareMilk(staker);

        if (amount > 0) {
            // Transfer staking tokens to the StableV2 contract
            bool ok = _token.transferFrom(staker, address(this), amount);
            require(ok, "StableV2: unable to transfer stake");
            // Register staking tokens
            _stakers[staker].amount = _stakers[staker].amount.add(amount);
        }

        // Adjust correction (staker's reward debt)
        uint256 correction = _stakers[staker].amount.mul(_tokensPerShare).div(1e12);
        _stakers[staker].correction = correction.mul(1e18).div(_banditsCorrection);
        _stakers[staker].banditsCorrection = _banditsCorrection;

        // Emit event to the logs so can be effectively used later
        emit Staked(staker, amount);
    }

    function claim(uint256 amount) external {
        address staker = msg.sender;
        require(!_milker.isWhitelisted(staker), "StableV2: whitelisted MILK holders cannot claim tokens");

        // Recalculate stable shares
        update();

        // Transfer pending tokens (if any) to the staker
        _shareMilk(staker);

        if (amount > 0) {
            // Unregister claimed tokens
            _stakers[staker].amount = _stakers[staker].amount.sub(amount);
            // Transfer requested tokens from the StableV2 contract
            bool ok = _token.transfer(staker, amount);
            require(ok, "StableV2: unable to transfer stake");
        }

        // Adjust correction (staker's reward debt)
        uint256 correction = _stakers[staker].amount.mul(_tokensPerShare).div(1e12);
        _stakers[staker].correction = correction.mul(1e18).div(_banditsCorrection);
        _stakers[staker].banditsCorrection = _banditsCorrection;

        // Emit event to the logs so can be effectively used later
        emit Claimed(staker, amount);
    }

    ////////////////////////////////////////////////////////////////
    // Updating stable state
    ////////////////////////////////////////////////////////////////

    // Updates stable's accumulative data until most recent block.
    function update() public override {
        if (block.timestamp <= _lastUpdateTime) {
            return;
        }
        uint256 productionNew = production();
        uint256 producedNew = produced();
        if (producedNew <= _produced) {
            _lastUpdateTime = block.timestamp;
            return;
        }
        uint256 supply = tokenSupply();
        if (supply == 0) {
            (_production, _produced) = (productionNew, producedNew);
            _lastUpdateTime = block.timestamp;
            return;
        }
        // Produce MILK tokens to this contract
        uint256 producedTotal = producedNew.sub(_produced);
        uint256 producedToStable = _milker.produceMilk(producedTotal);
        // Update stable share price
        _tokensPerShare = _tokensPerShare.add(producedToStable.mul(1e12).div(supply));
        // Update stable state
        _production = productionNew;
        _produced = producedNew;
        _lastUpdateTime = block.timestamp;
    }

    ////////////////////////////////////////////////////////////////
    // Management functions callable only be Milker
    ////////////////////////////////////////////////////////////////

    function shareMilk(address taker) public override onlyMilker returns (uint256) {
        return _shareMilk(taker);
    }

    function bandits(uint256 percent) external override onlyMilker returns (
        uint256 banditsAmount,
        uint256 arrestedAmount,
        uint256 burntAmount
    ) {
        // Recalculate stable shares
        update();

        // Ensure pending amount and total tokens staked are not zero
        uint256 pendingAmount = milkSupply();
        if (pendingAmount == 0) {
            return (0, 0, 0);
        }

        // Calculate bandits amounts
        banditsAmount = pendingAmount.mul(percent).div(100);
        burntAmount = banditsAmount.div(10);
        arrestedAmount = banditsAmount.sub(burntAmount);

        // Transfer arrested MILK to the Sheriff's Vault
        _safeTransferMilk(address(_milker), arrestedAmount);

        // Decrease pending of each staker
        _banditsCorrection = _banditsCorrection.sub(_banditsCorrection.mul(percent).div(100));
        _tokensPerShare = _tokensPerShare.sub(_tokensPerShare.mul(percent).div(100));

        // Emit event to the logs so can be effectively used later
        emit Bandits(percent, banditsAmount, arrestedAmount, burntAmount);
    }

    ////////////////////////////////////////////////////////////////
    // Contract getters
    ////////////////////////////////////////////////////////////////

    function milker() public view override returns (address) {
        return address(_milker);
    }

    function token() public view override returns (address) {
        return address(_token);
    }

    function startTime() public view override returns (uint256) {
        return _startTime;
    }

    function stakerTokens(address staker) public view override returns (uint256) {
        return _stakers[staker].amount;
    }

    function stakerCorrection(address staker) public view override returns (uint256) {
        return _stakers[staker].correction;
    }

    function tokenSupply() public view override returns (uint256) {
        return _token.balanceOf(address(this));
    }

    function milkSupply() public view override returns (uint256) {
        return _milker.balanceOf(address(this));
    }

    ////////////////////////////////////////////////////////////////
    // MILK production related getters
    ////////////////////////////////////////////////////////////////

    function level() public view override returns (uint256) {
        if (_startTime == 0 || _startTime >= block.timestamp) {
            return 0;
        }
        return (block.timestamp - _startTime) / REDUCING_INTERVAL;
    }

    function levelProgress() public view override returns (uint256) {
        if (_startTime == 0 || _startTime >= block.timestamp) {
            return 0;
        }
        uint256 d = block.timestamp - (_startTime + level() * REDUCING_INTERVAL);
        return d * 10**18 / REDUCING_INTERVAL;
    }

    function production() public view override returns(uint256) {
        if (_startTime == 0 || _startTime >= block.timestamp) {
            return 0;
        }
        uint256 prod = _production;
        uint256 lvlA = (_lastUpdateTime - _startTime) / REDUCING_INTERVAL;
        uint256 lvlB = (block.timestamp - _startTime) / REDUCING_INTERVAL;
        for (; lvlA < lvlB; lvlA++) {
            prod -= prod / REDUCING_FACTOR;
        }
        return prod;
    }

    function produced() public view override returns(uint256) {
        if (_startTime == 0 || _startTime >= block.timestamp) {
            return 0;
        }
        uint256 lvlA = (_lastUpdateTime - _startTime) / REDUCING_INTERVAL;
        uint256 lvlB = (block.timestamp - _startTime) / REDUCING_INTERVAL;
        if (lvlA == lvlB) {
            return _produced + (block.timestamp - _lastUpdateTime) * _production / REDUCING_INTERVAL;
        }
        uint256 amount = 0;
        uint256 prod = _production;
        // Count end of first level
        amount += ((_startTime + (lvlA+1) * REDUCING_INTERVAL) - _lastUpdateTime) * prod / REDUCING_INTERVAL;
        prod -= prod / REDUCING_FACTOR;
        for (lvlA++; lvlA < lvlB; lvlA++) {
            // Count full level
            amount += prod;
            prod -= prod / REDUCING_FACTOR;
        }
        // Count start of current level
        amount += (block.timestamp - (_startTime + lvlB * REDUCING_INTERVAL)) * prod / REDUCING_INTERVAL;
        return _produced + amount;
    }

    function distributed() public view override returns(uint256) {
        return _distributed;
    }

    function pending() public view override returns(uint256) {
        uint256 p = produced();
        if (p <= _distributed) {
            return 0;
        }
        return p.sub(_distributed);
    }

    function pendingTo(address account) public view override returns (uint256) {
        uint256 added = produced().sub(_produced);
        uint256 supply = tokenSupply();
        uint256 tokensPerShare = _tokensPerShare;
        if (added > 0 && supply > 0) {
            tokensPerShare = tokensPerShare.add(added.sub(added.div(20)).mul(1e12).div(supply));
        }
        uint256 tokens = _stakers[account].amount.mul(tokensPerShare).div(1e12);
        uint256 correction = _stakers[account].correction.mul(_banditsCorrection).div(1e18);
        if (_banditsCorrection != _stakers[account].banditsCorrection) {
            correction = correction.mul(_stakers[account].banditsCorrection).div(_banditsCorrection);
        }
        if (tokens <= correction) {
            return 0;
        }
        return tokens.sub(correction);
    }

    ////////////////////////////////////////////////////////////////
    // Internal functions
    ////////////////////////////////////////////////////////////////

    function _shareMilk(address taker) private returns (uint256 tokens) {

        // Calculate pending tokens
        Staker storage s = _stakers[taker];
        uint256 pendingAmount = s.amount.mul(_tokensPerShare).div(1e12);
        uint256 correction = s.correction.mul(_banditsCorrection).div(1e18);
        if (_banditsCorrection != s.banditsCorrection) {
            correction = correction.mul(s.banditsCorrection).div(_banditsCorrection);
            s.banditsCorrection = _banditsCorrection;
        }
        if (pendingAmount > correction) {
            uint256 balance = _milker.balanceOf(address(this));
            pendingAmount = pendingAmount.sub(correction);
            tokens = pendingAmount > balance ? balance : pendingAmount;
            // Unregister sharing tokens
            s.correction = correction.add(tokens).mul(1e18).div(_banditsCorrection);
            s.banditsCorrection = _banditsCorrection;
            _distributed = _distributed.add(tokens);
            // Transfer MILK tokens from the StableV2 contract to the taker
            _safeTransferMilk(taker, tokens);
        }

        return tokens;
    }

    function _safeTransferMilk(address to, uint256 amount) private {
        uint256 balance = _milker.balanceOf(address(this));
        uint256 tokens = amount > balance ? balance : amount;
        if (tokens > 0) {
            bool ok = _milker.transfer(to, tokens);
            require(ok, "StableV2: unable to transfer MILK");
        }
    }

    ////////////////////////////////////////////////////////////////
    // [TESTS] Test functions to check internal state
    // TODO: Remove it since only for tests !!!
    ////////////////////////////////////////////////////////////////

    function testProduction() public view returns (uint256) {
        return _production;
    }

    function testProduced() public view returns (uint256) {
        return _produced;
    }

    function testTokensPerShare() public view returns (uint256) {
        return _tokensPerShare;
    }

    function testLastUpdateTime() public view returns (uint256) {
        return _lastUpdateTime;
    }
}

// solium-enable security/no-block-members