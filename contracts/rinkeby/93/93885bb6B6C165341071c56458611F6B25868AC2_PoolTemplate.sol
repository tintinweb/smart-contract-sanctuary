/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File contracts/libraries/math/SafeMath.sol

pragma solidity ^0.6.0;

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


// File contracts/libraries/utils/Address.sol

pragma solidity ^0.6.0;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}


// File contracts/libraries/tokens/IERC20.sol

pragma solidity ^0.6.0;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


// File contracts/interfaces/IParameters.sol

pragma solidity ^0.6.0;

abstract contract IParameters {
    function commit_transfer_ownership(address _owner) external virtual;

    function apply_transfer_ownership() external virtual;

    function setVault(address _token, address _vault) external virtual;

    function setLockup(address _address, uint256 _target) external virtual;

    function setGrace(address _address, uint256 _target) external virtual;

    function setMindate(address _address, uint256 _target) external virtual;

    function setPremium2(address _address, uint256 _target) external virtual;

    function setFee2(address _address, uint256 _target) external virtual;

    function setWithdrawable(address _address, uint256 _target)
        external
        virtual;

    function setPremiumModel(address _address, address _target)
        external
        virtual;

    function setFeeModel(address _address, address _target) external virtual;

    function setCondition(bytes32 _reference, bytes32 _target) external virtual;

    function getVault(address _token) external view virtual returns (address);

    function getPremium(
        uint256 _amount,
        uint256 _term,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view virtual returns (uint256);

    function getFee(
        uint256 _amount,
        uint256 _term,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view virtual returns (uint256);

    function getLockup() external view virtual returns (uint256);

    function getWithdrawable() external view virtual returns (uint256);

    function getGrace() external view virtual returns (uint256);

    function get_owner() public view virtual returns (address);

    function isOwner() public view virtual returns (bool);

    function getMin() external view virtual returns (uint256);

    function getFee2(uint256 _amount) external view virtual returns (uint256);

    function getPremium2(uint256 _amount)
        external
        view
        virtual
        returns (uint256);

    function getCondition(bytes32 _reference)
        external
        view
        virtual
        returns (bytes32);
}


// File contracts/interfaces/IVault.sol

pragma solidity ^0.6.0;

interface IVault {
    function addValue(
        uint256 _amount,
        address _from,
        address _attribution
    ) external returns (uint256 _attributions);

    function withdrawValue(uint256 _amount, address _to)
        external
        returns (uint256 _attributions);

    function transferValue(uint256 _amount, address _destination) external;

    function withdrawAttribution(uint256 _attribution, address _to) external;

    function withdrawAllAttribution(address _to) external;

    function transferAttribution(uint256 _amount, address _destination)
        external;

    function attributionOf(address _target) external view returns (uint256);

    function underlyingValue(address _target) external view returns (uint256);

    function attributionValue(uint256 _attribution)
        external
        view
        returns (uint256);

    function utilize() external returns (uint256 _amount);
}


// File contracts/interfaces/IRegistry.sol

pragma solidity ^0.6.0;

interface IRegistry {
    function supportMarket(address _market) external;

    function isListed(address _market) external view returns (bool);

    function getCDS(address _address) external view returns (address);
}


// File contracts/interfaces/IIndexTemplate.sol

pragma solidity ^0.6.0;

abstract contract IIndexTemplate {
    function compensate(uint256) external virtual;

    function lock() external virtual;

    function resume() external virtual;

    function adjustAlloc() public virtual;
}


// File contracts/PoolTemplate.sol

pragma solidity ^0.6.0;

/**
 * @author kohshiba
 * @title InsureDAO pool template contract
 */







contract PoolTemplate is IERC20 {
    using Address for address;
    using SafeMath for uint256;

    /**
     * EVENTS
     */

    event Deposit(
        address indexed depositor,
        uint256 amount,
        uint256 mint,
        uint256 balance,
        uint256 underlying
    );
    event Withdraw(address indexed withdrawer, uint256 amount, uint256 retVal);
    event Unlocked(uint256 indexed id, uint256 amount);
    event Insured(
        uint256 indexed id,
        uint256 amount,
        bytes32 target,
        uint256 startTime,
        uint256 endTime,
        address insured
    );
    event Redeemed(
        uint256 indexed id,
        address insured,
        bytes32 target,
        uint256 amount,
        uint256 payout
    );

    event CreditIncrease(
        address indexed depositor,
        uint256 credit
        //uint256 mint
    );
    event CreditDecrease(
        address indexed withdrawer,
        //uint256 indexToken,
        uint256 credit
        //uint256 impact
    );
    event MarketStatusChanged(MarketStatus statusValue);
    /**
     * Storage
     */

    /// @notice Market setting
    bool private initialized;
    bool public paused;
    string public metadata;

    /// @notice EIP-20 token variables
    string public name;
    string public symbol;
    uint8 public decimals;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    /// @notice External contract call addresses
    IParameters public parameters;
    IRegistry public registry;
    IVault public vault;

    /// @notice Market variables
    uint256 private totalAttributions; //how much attribution point this pool's original liquidity has
    uint256 private lockedAmount; //Liquidity locked when utilized
    uint256 private totalCredit; //Liquidity from index
    uint256 private attributionPerCredit; //Times 1e12. To avoid overdlow
    uint256 public pendingEnd; //pending time when paying out

    /// @notice Market variables for margin account
    struct IndexInfo {
        uint256 credit;
        uint256 rewardDebt;
        uint256 lastActionTimestamp;
        bool exist;
    }
    mapping(address => IndexInfo) public indexes;
    address[] public indexList;

    ///@notice Market status transition management
    enum MarketStatus {Trading, Payingout}
    MarketStatus public marketStatus;

    ///@notice user status management
    struct Withdrawal {
        uint256 timestamp;
        uint256 amount;
    }
    mapping(address => Withdrawal) public withdrawalReq;

    ///@notice insurance status management
    struct Insurance {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        uint256 amount;
        bytes32 target;
        address insured;
        bool status;
    }
    Insurance[] public insurances;
    mapping(address => Insurance[]) public insuranceHoldings;

    struct Incident {
        uint256 payoutNumerator;
        uint256 payoutDenominator;
        uint256 incidentTimestamp;
        bytes32[] targets;
    }
    Incident public incident;

    /**
     * @notice Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(
            msg.sender == parameters.get_owner(),
            "Ownable: caller is not the owner"
        );
        _;
    }

    /**
     * Initialize interaction
     */

    /**
     * @notice Initialize market
     * This function registers market conditions.
     * references[0] = parameter
     * references[1] = vault address
     * references[2] = registry
     */
    function initialize(
        address _owner,
        string calldata _metaData,
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals,
        uint256[] calldata _conditions,
        address[] calldata _references
    ) external returns (bool) {
        require(
            bytes(_metaData).length > 10 &&
                bytes(_name).length > 0 &&
                bytes(_symbol).length > 0 &&
                _decimals > 0 &&
                _owner != address(0) &&
                _references[0] != address(0) &&
                _references[1] != address(0) &&
                _conditions[0] <= _conditions[1],
            "ERROR: INITIALIZATION_BAD_CONDITIONS"
        );
        initialized = true;

        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        parameters = IParameters(_references[0]);
        vault = IVault(_references[1]);
        registry = IRegistry(_references[2]);

        metadata = _metaData;

        marketStatus = MarketStatus.Trading;

        if (_conditions[1] > 0) {
            deposit(_conditions[1]);
        }

        return true;
    }

    /**
     * Pool initeractions
     */

    /**
     * @notice A provider supplies token to the pool and receives iTokens
     */
    function deposit(uint256 _amount) public returns (uint256 _mintAmount) {
        require(
            marketStatus == MarketStatus.Trading &&
                paused == false &&
                _amount > 0,
            "ERROR: DEPOSIT_DISABLED"
        );

        _mintAmount = worth(_amount);

        uint256 _newAttribution =
            vault.addValue(_amount, msg.sender, address(this));
        totalAttributions = totalAttributions.add(_newAttribution);

        emit Deposit(
            msg.sender,
            _amount,
            _mintAmount,
            balanceOf(msg.sender),
            valueOfUnderlying(msg.sender)
        );

        //mint iToken
        _mint(msg.sender, _mintAmount);
    }

    /**
     * @notice Provider request withdrawal of collateral
     */
    function requestWithdraw(uint256 _amount) external {
        uint256 _balance = balanceOf(msg.sender);
        require(
            _balance >= _amount && _amount > 0,
            "ERROR: WITHDRAW_REQUEST_BAD_CONDITIONS"
        );
        withdrawalReq[msg.sender].timestamp = now;
        withdrawalReq[msg.sender].amount = _amount;
    }

    /**
     * @notice Provider burns iToken and receives collatral from the pool
     */
    function withdraw(uint256 _amount) external returns (uint256 _retVal) {
        uint256 _supply = totalSupply();
        uint256 _liquidity = vault.attributionValue(totalAttributions);
        _retVal = _divFloor(_amount.mul(_liquidity), _supply);
        require(
            marketStatus == MarketStatus.Trading &&
                withdrawalReq[msg.sender].timestamp.add(
                    parameters.getLockup()
                ) <
                now &&
                withdrawalReq[msg.sender]
                    .timestamp
                    .add(parameters.getLockup())
                    .add(parameters.getWithdrawable()) >
                now &&
                _retVal <= availableBalance() &&
                withdrawalReq[msg.sender].amount >= _amount &&
                _amount > 0,
            "ERROR: WITHDRAWAL_BAD_CONDITIONS"
        );
        //reduce requested amount
        withdrawalReq[msg.sender].amount = withdrawalReq[msg.sender].amount.sub(
            _amount
        );

        //Burn iToken
        _burn(msg.sender, _amount);

        //Withdraw liquidity
        uint256 _deductAttribution = vault.withdrawValue(_retVal, msg.sender);
        totalAttributions = totalAttributions.sub(_deductAttribution);

        emit Withdraw(msg.sender, _amount, _retVal);
    }

    /**
     * @notice Unlocks an array of insurances
     */
    function unlockBatch(uint256[] calldata _ids) external {
        for (uint256 i = 0; i < _ids.length; i++) {
            unlock(_ids[i]);
        }
    }

    /**
     * @notice Unlock funds locked in the expired insurance
     */
    function unlock(uint256 _id) public {
        Insurance storage insurance = insurances[_id];
        require(
            insurance.status == true &&
                marketStatus == MarketStatus.Trading &&
                insurance.endTime.add(parameters.getGrace()) < now,
            "ERROR: UNLOCK_BAD_COINDITIONS"
        );
        insurance.status == false;

        lockedAmount = lockedAmount.sub(insurance.amount);

        emit Unlocked(_id, insurance.amount);
    }

    /**
     * Index interactions
     */

    /**
     * @notice Allocate credit from indexes. Allocated credits are treated as equivalent to deposited real token.
     */

    function allocateCredit(uint256 _credit)
        external
        returns (uint256 _pending)
    {
        require(
            IRegistry(registry).isListed(msg.sender),
            "ERROR: ALLOCATE_BAD_CONDITIONS"
        );
        IndexInfo storage _index = indexes[msg.sender];
        if (indexes[msg.sender].exist == false) {
            indexes[msg.sender].exist = true;
            indexList.push(msg.sender);
        }
        if (_index.credit > 0) {
            _pending = _index.credit.mul(attributionPerCredit).div(1e12).sub(
                _index.rewardDebt
            );
            if (_pending > 0) {
                vault.transferAttribution(_pending, msg.sender);
            }
        }
        if (_credit > 0) {
            _index.lastActionTimestamp = now;
            totalCredit = totalCredit.add(_credit);
            indexes[msg.sender].credit = indexes[msg.sender].credit.add(
                _credit
            );
            emit CreditIncrease(msg.sender, _credit);
        }

        _index.rewardDebt = _index.credit.mul(attributionPerCredit).div(1e12);
    }

    /**
     * @notice An index withdraw credit and earn accrued premium
     */
    function withdrawCredit(uint256 _credit)
        external
        returns (uint256 _pending)
    {
        IndexInfo storage _index = indexes[msg.sender];
        require(
            IRegistry(registry).isListed(msg.sender) &&
                _index.credit >= _credit &&
                _credit <= availableBalance() &&
                _credit > 0,
            "ERROR: DEALLOCATE_BAD_CONDITIONS"
        );

        //calculate acrrued premium
        _pending = _index.credit.mul(attributionPerCredit).div(1e12).sub(
            _index.rewardDebt
        );

        //Withdraw liquidity
        totalCredit = totalCredit.sub(_credit);
        indexes[msg.sender].credit = indexes[msg.sender].credit.sub(_credit);
        emit CreditDecrease(msg.sender, _credit);

        //withdraw acrrued premium
        if (_pending > 0) {
            vault.transferAttribution(_pending, msg.sender);
            _index.rewardDebt = _index.credit.mul(attributionPerCredit).div(
                1e12
            );
        }
    }

    /**
     * Insurance interactions
     */

    /**
     * @notice Get insured for the specified amount for specified span
     */
    function insure(
        uint256 _amount,
        uint256 _maxCost,
        uint256 _endTime,
        bytes32 _target
    ) external returns (uint256) {
        //Distribute premium and fee
        uint256 _span = _endTime.sub(now);
        uint256 _premium = getPremium(_amount, _span);
        uint256 _fee = getFee(_amount, _span);
        uint256 _cost = _premium.add(_fee);

        require(
            marketStatus == MarketStatus.Trading &&
                paused == false &&
                _amount <= availableBalance() &&
                _span <= 365 days &&
                _cost <= _maxCost &&
                parameters.getMin() <= _span,
            "ERROR: INSURE_BAD_CONDITIONS"
        );

        //accrue fee
        vault.addValue(_fee, msg.sender, parameters.get_owner());
        //accrue premium
        uint256 _newAttribution =
            vault.addValue(_premium, msg.sender, address(this));

        //Lock covered amount
        uint256 _id = insurances.length;
        lockedAmount = lockedAmount.add(_amount);
        Insurance memory _insurance =
            Insurance(_id, now, _endTime, _amount, _target, msg.sender, true);
        insurances.push(_insurance);
        insuranceHoldings[msg.sender].push(_insurance);

        //Calculate liquidity
        uint256 _attributionForIndex =
            _newAttribution.mul(totalCredit).div(totalLiquidity());
        totalAttributions = totalAttributions.add(_newAttribution).sub(
            _attributionForIndex
        );
        if (totalCredit > 0) {
            attributionPerCredit = attributionPerCredit.add(
                _attributionForIndex.mul(1e12).div(totalCredit)
            );
        }

        emit Insured(_id, _amount, _target, now, _endTime, msg.sender);

        return _id;
    }

    /**
     * @notice Redeem an insurance policy
     */
    function redeem(uint256 _id) external {
        Insurance storage insurance = insurances[_id];

        uint256 _payoutNumerator = incident.payoutNumerator;
        uint256 _payoutDenominator = incident.payoutDenominator;
        uint256 _incidentTimestamp = incident.incidentTimestamp;
        bytes32[] memory _targets = incident.targets;
        bool isTarget;

        for (uint256 i = 0; i < _targets.length; i++) {
            if (_targets[i] == insurance.target) isTarget = true;
        }

        require(
            insurance.status == true &&
                insurance.insured == msg.sender &&
                marketStatus == MarketStatus.Payingout &&
                insurance.startTime <= _incidentTimestamp &&
                insurance.endTime >= _incidentTimestamp &&
                isTarget == true,
            "ERROR: INSURANCE_NOT_APPLICABLE"
        );
        insurance.status = false;
        lockedAmount = lockedAmount.sub(insurance.amount);

        uint256 _payoutAmount =
            insurance.amount.mul(_payoutNumerator).div(_payoutDenominator);
        uint256 _deductionFromIndex =
            _payoutAmount.mul(totalCredit).mul(1e8).div(totalLiquidity());

        for (uint256 i = 0; i < indexList.length; i++) {
            if (indexes[indexList[i]].credit > 0) {
                uint256 _shareOfIndex =
                    indexes[indexList[i]].credit.mul(1e8).div(
                        indexes[indexList[i]].credit
                    );
                uint256 _redeemAmount =
                    _divCeil(_deductionFromIndex, _shareOfIndex);
                IIndexTemplate(indexList[i]).compensate(_redeemAmount);
            }
        }

        uint256 _paidAttribution =
            vault.withdrawValue(_payoutAmount, msg.sender);
        uint256 _indexAttribution =
            _paidAttribution.mul(_deductionFromIndex).div(1e8).div(
                _payoutAmount
            );
        totalAttributions = totalAttributions.sub(
            _paidAttribution.sub(_indexAttribution)
        );
        emit Redeemed(
            _id,
            msg.sender,
            insurance.target,
            insurance.amount,
            _payoutAmount
        );
    }

    /**
     * @notice Transfers an active insurance
     */
    function transferInsurance(uint256 _id, address _to) external {
        Insurance storage insurance = insurances[_id];

        require(
            _to != address(0) &&
                insurance.insured == msg.sender &&
                insurance.endTime >= now &&
                insurance.status == true,
            "ERROR: INSURANCE_TRANSFER_BAD_CONDITIONS"
        );

        insurance.insured = _to;
    }

    /**
     * @notice Get how much premium for the specified amound and span
     */
    function getPremium(uint256 _amount, uint256 _span)
        public
        view
        returns (uint256 premium)
    {
        return
            parameters.getPremium(
                _amount,
                _span,
                totalLiquidity(),
                lockedAmount
            );
    }

    /**
     * @notice Get how much fee for the specified amound and span
     */

    function getFee(uint256 _amount, uint256 _span)
        public
        view
        returns (uint256 fee)
    {
        return
            parameters.getFee(_amount, _span, totalLiquidity(), lockedAmount);
    }

    /**
     * Reporting interactions
     */

    /**
     * @notice Decision to make a payout
     */
    function applyCover(
        uint256 _pending,
        uint256 _payoutNumerator,
        uint256 _payoutDenominator,
        uint256 _incidentTimestamp,
        bytes32[] calldata _targets
    ) external onlyOwner {
        require(
            marketStatus != MarketStatus.Payingout,
            "ERROR: UNABLE_TO_APPLY"
        );
        incident.payoutNumerator = _payoutNumerator;
        incident.payoutDenominator = _payoutDenominator;
        incident.incidentTimestamp = _incidentTimestamp;
        incident.targets = _targets;
        marketStatus = MarketStatus.Payingout;
        pendingEnd = now.add(_pending);
        for (uint256 i = 0; i < indexList.length; i++) {
            IIndexTemplate(indexList[i]).lock();
        }
        emit MarketStatusChanged(marketStatus);
    }

    /**
     * @notice Anyone can resume the market after a pending period ends
     */
    function resume() external {
        require(
            marketStatus == MarketStatus.Payingout && pendingEnd < now,
            "ERROR: UNABLE_TO_RESUME"
        );
        marketStatus = MarketStatus.Trading;
        for (uint256 i = 0; i < indexList.length; i++) {
            IIndexTemplate(indexList[i]).resume();
        }
        emit MarketStatusChanged(marketStatus);
    }

    /**
     * iToken functions
     */

    /**
     * @notice See `IERC20.totalSupply`.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice See `IERC20.transfer`.
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @notice See `IERC20.allowance`.
     */
    function allowance(address _owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[_owner][spender];
    }

    /**
     * @notice See `IERC20.approve`.
     */
    function approve(address spender, uint256 value)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @notice See `IERC20.transferFrom`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(amount)
        );
        return true;
    }

    /**
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue)
        );
        return true;
    }

    /**
     * @notice Moves tokens `amount` from `sender` to `recipient`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(
            sender != address(0) && recipient != address(0),
            "ERC20: TRANSFER_BAD_CONDITIONS"
        );

        _beforeTokenTransfer(sender, amount);

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /**
     * @notice Creates `amount` tokens and assigns them to `account`, increasing
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @notice Destoys `amount` tokens from `account`, reducing the
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @notice Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     */
    function _approve(
        address _owner,
        address _spender,
        uint256 _value
    ) internal {
        require(
            _owner != address(0) && _spender != address(0),
            "ERC20: APPROVE_BAD_CONDITIONS"
        );

        _allowances[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
    }

    /**
     * Utilities
     */

    /**
     * @notice Get the underlying balance of the `owner`
     */
    function valueOfUnderlying(address _owner) public view returns (uint256) {
        uint256 _balance = balanceOf(_owner);
        if (_balance == 0) {
            return 0;
        } else {
            return
                _balance.mul(vault.attributionValue(totalAttributions)).div(
                    totalSupply()
                );
        }
    }

    /**
     * @notice Get the accrued value for an index
     */
    function pendingPremium(address _index) external view returns (uint256) {
        uint256 _credit = indexes[_index].credit;
        if (_credit == 0) {
            return 0;
        } else {
            return
                _credit.mul(attributionPerCredit).div(1e12).sub(
                    indexes[_index].rewardDebt
                );
        }
    }

    /**
     * @notice Get token number for the specified underlying value
     */
    function worth(uint256 _value) public view returns (uint256 _amount) {
        uint256 _supply = totalSupply();
        if (_supply > 0 && totalAttributions > 0) {
            _amount = _value.mul(_supply).div(
                vault.attributionValue(totalAttributions)
            );
        } else if (_supply > 0 && totalAttributions == 0) {
            _amount = _value.div(_supply);
        } else {
            _amount = _value;
        }
    }

    /**
     * @notice Get allocated credit
     */
    function allocatedCredit(address _index) public view returns (uint256) {
        return indexes[_index].credit;
    }

    /**
     * @notice Get the number of total insurances
     */
    function allInsuranceCount() public view returns (uint256) {
        return insurances.length;
    }

    /**
     * @notice Get the underlying balance of the `owner`
     */
    function getInsuranceCount(address _user) public view returns (uint256) {
        return insuranceHoldings[_user].length;
    }

    /**
     * @notice Returns the amount of underlying token available for withdrawals
     */
    function availableBalance() public view returns (uint256 _balance) {
        if (totalLiquidity() > 0) {
            return totalLiquidity().sub(lockedAmount);
        } else {
            return 0;
        }
    }

    /**
     * @notice Returns the utilization rate for this pool (should be divided by 1e10 to XX.XXX%)
     */
    function utilizationRate() public view returns (uint256 _rate) {
        if (lockedAmount > 0) {
            return lockedAmount.mul(1e8).div(totalLiquidity());
        } else {
            return 0;
        }
    }

    /**
     * @notice total Liquidity of the pool (how much can the pool sell cover)
     */
    function totalLiquidity() public view returns (uint256 _balance) {
        return vault.attributionValue(totalAttributions).add(totalCredit);
    }

    /**
     * Admin functions
     */

    /**
     * @notice Pause the market and disable new deposit
     */
    function setPaused(bool state) external onlyOwner {
        paused = state;
    }

    /**
     * @notice Change metadata string
     */
    function changeMetadata(string calldata _metadata) external onlyOwner {
        metadata = _metadata;
    }

    /**
     * Internal functions
     */

    /**
     * @notice Internal function to offset withdraw request and latest balance
     */
    function _beforeTokenTransfer(address _from, uint256 _amount) internal {
        //withdraw request operation
        uint256 _after = balanceOf(_from).sub(_amount);
        if (_after < withdrawalReq[_from].amount) {
            withdrawalReq[_from].amount = _after;
        }
    }

    /**
     * @notice Internal function for safe division
     */
    function _divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        if (a % b != 0) c = c + 1;
        return c;
    }

    /**
     * @notice Internal function for safe division
     */
    function _divFloor(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        if (a % b != 0) c = c - 1;
        return c;
    }
}