// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library Finance {
    using SafeMath for uint256;

    /**
     * @notice Calculates the amount of a fee given as basis points
     * @param _amount The amount to calculate the fee for
     * @param _bp The fee in basis points to calculate
     */
    function calculateFeeAmount(uint256 _amount, uint256 _bp)
        internal
        pure
        returns (uint256)
    {
        uint256 _fee = _amount.mul(_bp).div(10000);

        return _fee;
    }

    /**
     * @notice Calculates basis points
     * @param _dividend The value to calculate the basis points for
     * @param _divisor The value to divide the dividend by, generally the whole amount
     */
    function calculateBP(uint256 _dividend, uint256 _divisor)
        internal
        pure
        returns (uint256)
    {
        uint256 _bp = _dividend.mul(10**9).mul(10000).div(_divisor).div(10**9);
        return _bp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//

import "./libraries/Utility.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// Fee Schedule in BP - Initial total fee 13% maximum fee total is 20%
uint256 constant FEE_MAX_TOTAL = 2000;

// Indexes of internal wallets
uint8 constant WALLET_DEV_MARKET = 0;
uint8 constant WALLET_CHARITY = 1;
uint8 constant WALLET_RESOURCE_LIQUIDITY = 2;

uint8 constant FEE_REFLECTION = 0;
uint8 constant FEE_DEV_MARKET = 1;
uint8 constant FEE_CHARITY = 2;
uint8 constant FEE_RESOURCE_LIQUIDITY = 3;

uint256 constant FIRST_TX_DELAY = 1 days;
uint256 constant TX_DELAY = 90;

struct Account {
    uint256 balance;
    bool excluded;
    bool locked;
    uint256 lastReflectedTick;
    uint256 lastTX;
    uint256 firstTX;
    mapping(address => uint256) allowances;
}

contract RetroVisionToken is IERC20, Context, ReentrancyGuard, Ownable {
    using Address for address;

    using SafeMath for uint256;
    using SafeMath for uint16;
    using SafeMath for uint8;

    using Counters for Counters.Counter;

    // Token parameters
    uint256 private _creationTimestamp;
    string private _tokenName;
    string private _tokenSymbol;
    uint8 private _tokenDecimals;
    uint256 private _tokenSupply;

    // Wallets
    mapping(uint16 => address) private _internalWallets;
    mapping(uint16 => bool) private _immutableWallet;

    // Tracking of fee schedules
    mapping(uint16 => uint16) private _feeSchedule;

    // Reflections
    uint256 private _totalReflections;
    Counters.Counter private _totalReflectionTicks;

    uint256 private _totalCollectedReflectionFees;
    uint256 private _totalCollectedDevMarketFees;
    uint256 private _totalCollectedCharityFees;
    uint256 private _totalCollectedResourceLiquidityFees;

    // Balances and allowance of each address
    mapping(address => Account) private _accounts;

    // Token limits
    uint256[] private _limitCapSchedule;
    uint256[] private _limitTxSchedule;
    bool private _tokenGoLive = false;

    /**
     * Constructor
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _supply,
        address _devMarketWallet,
        address _charityWallet
    ) {
        // Initialize token parameters
        _tokenName = _name;
        _tokenSymbol = _symbol;
        _tokenDecimals = _decimals;
        _tokenSupply = _supply.mul(10**uint256(_decimals)); // Convert to retrowei

        _totalReflections = 0;
        _totalReflectionTicks.increment();

        _totalCollectedReflectionFees = 0;
        _totalCollectedDevMarketFees = 0;
        _totalCollectedCharityFees = 0;
        _totalCollectedResourceLiquidityFees = 0;

        // Initial token limits
        _limitCapSchedule = [
            Finance.calculateFeeAmount(_tokenSupply, 50), // 0.5%
            Finance.calculateFeeAmount(_tokenSupply, 100), // 1.0%
            Finance.calculateFeeAmount(_tokenSupply, 500), // 5.0%
            Finance.calculateFeeAmount(_tokenSupply, 1000) // 10.0%
        ];

        // 10%, 25%, 50%, 100%
        _limitTxSchedule = [1000, 2500, 5000, 10000];

        // Initialize internal wallets
        setInternalWalletAddress(WALLET_DEV_MARKET, _devMarketWallet);
        setInternalWalletAddress(WALLET_CHARITY, _charityWallet);
        setInternalWalletAddress(WALLET_RESOURCE_LIQUIDITY, address(this));

        // Set initial fees
        setFee(FEE_REFLECTION, 300);
        setFee(FEE_DEV_MARKET, 200);
        setFee(FEE_CHARITY, 200);
        setFee(FEE_RESOURCE_LIQUIDITY, 200);

        // Calculate seed amounts
        uint256 _devMarketSeed = Finance.calculateFeeAmount(_tokenSupply, 500); // 5%
        uint256 _charitySeed = Finance.calculateFeeAmount(_tokenSupply, 200); // 2%
        uint256 _resourceLiquiditySeed = Finance.calculateFeeAmount(
            _tokenSupply,
            1500
        ); // 15%
        uint256 _remainingSeed = _tokenSupply.sub(
            _devMarketSeed.add(_charitySeed).add(_resourceLiquiditySeed)
        );

        // Seed distributions
        _accounts[_devMarketWallet].balance = _devMarketSeed;
        _accounts[_charityWallet].balance = _charitySeed;
        _accounts[address(this)].balance = _resourceLiquiditySeed;
        _accounts[_msgSender()].balance = _remainingSeed;

        // Exclude addresses from tax calculations
        setAccountExcluded(
            address(0),
            true,
            "Constructor: Burn address exclusion"
        );
        setAccountExcluded(
            _devMarketWallet,
            true,
            "Constructor: Dev Marketing address exclusion"
        );
        setAccountExcluded(
            _charityWallet,
            true,
            "Constructor: Charity address exclusion"
        );
        setAccountExcluded(
            address(this),
            true,
            "Constructor: Resource Liquidity address exclusion"
        );
        setAccountExcluded(
            _msgSender(),
            true,
            "Constructor: Owner address exclusion"
        );

        emit Transfer(address(0), _devMarketWallet, _devMarketSeed);
        emit Transfer(address(0), _charityWallet, _charitySeed);
        emit Transfer(address(0), address(this), _resourceLiquiditySeed);
        emit Transfer(address(0), _msgSender(), _remainingSeed);
    }

    receive() external payable {
        revert("Generic receive");
    }

    fallback() external payable {
        revert("Generic fallback");
    }

    function name() public view virtual returns (string memory) {
        return _tokenName;
    }

    function symbol() public view virtual returns (string memory) {
        return _tokenSymbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _tokenDecimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tokenSupply;
    }

    function isLive() public view returns (bool) {
        return _tokenGoLive;
    }

    function goLive() public onlyOwner {
        require(!_tokenGoLive, "ERC20: Token already live");
        _creationTimestamp = block.timestamp;
        _tokenGoLive = true;

        emit GoLive();
    }

    function reflectionBalanceOf(address _account)
        public
        view
        returns (uint256)
    {
        uint256 _currentReflectionTick = _totalReflectionTicks.current();

        // Return 0 if account is excluded, there are no reflections
        if (
            _accounts[_account].excluded ||
            _totalReflections == 0 ||
            _currentReflectionTick == 0 ||
            _accounts[_account].lastReflectedTick >= _currentReflectionTick
        ) return 0;

        // Reflection balance or "owed" is equal to a percentage of the totalReflections
        // as the accounts ownership share of the total supply minus the total reflections paid
        // RB = (TR * (O / TS)) - RP

        uint256 _ownershipShareBP = Finance.calculateBP(
            _accounts[_account].balance,
            _tokenSupply
        );

        uint256 _reflectionShareBP = Finance.calculateBP(
            _currentReflectionTick.sub(_accounts[_account].lastReflectedTick),
            _currentReflectionTick
        );

        uint256 _reflectionShare = Finance.calculateFeeAmount(
            _totalReflections,
            _reflectionShareBP
        );
        uint256 _reflectionOwed = Finance.calculateFeeAmount(
            _reflectionShare,
            _ownershipShareBP
        );

        return _reflectionOwed;
    }

    function balanceOf(address _account)
        public
        view
        override
        returns (uint256)
    {
        uint256 _tokensOwned = _accounts[_account].balance;
        if (!_accounts[_account].excluded) {
            _tokensOwned = _tokensOwned.add(reflectionBalanceOf(_account));
        }

        return _tokensOwned;
    }

    function setAccountExcluded(
        address _account,
        bool _excluded,
        string memory _reason
    ) public onlyOwner {
        require(_accounts[_account].excluded != _excluded, "ERC20: No change");

        _accounts[_account].excluded = _excluded;

        emit AccountExclusionStatusChanged(_account, _excluded, _reason);
    }

    function isExcluded(address _account) public view returns (bool) {
        return _accounts[_account].excluded;
    }

    function setAccountLocked(
        address _account,
        bool _locked,
        string memory _reason
    ) public onlyOwner {
        require(_accounts[_account].locked != _locked, "ERC20: No change");

        _accounts[_account].locked = _locked;

        emit AccountLockedStatusChanged(_account, _locked, _reason);
    }

    function isLocked(address _account) public view returns (bool) {
        return _accounts[_account].locked;
    }

    function totalReflections() public view returns (uint256) {
        return _totalReflections;
    }

    function allowance(address _owner, address _spender)
        public
        view
        override
        returns (uint256)
    {
        return _accounts[_owner].allowances[_spender];
    }

    function increaseAllowance(address _spender, uint256 _amount)
        public
        virtual
        returns (bool)
    {
        address _sender = _msgSender();
        _approve(
            _sender,
            _spender,
            _accounts[_sender].allowances[_spender].add(_amount)
        );
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _amount)
        public
        virtual
        returns (bool)
    {
        address _sender = _msgSender();
        _approve(
            _sender,
            _spender,
            _accounts[_sender].allowances[_spender].sub(
                _amount,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function approve(address _spender, uint256 _amount)
        public
        override
        nonReentrant
        returns (bool)
    {
        _approve(_msgSender(), _spender, _amount);
        return true;
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        _accounts[_owner].allowances[_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function transferFrom(
        address _spender,
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        address _sender = _msgSender();
        _transfer(_spender, _recipient, _amount);
        _approve(
            _spender,
            _sender,
            _accounts[_spender].allowances[_sender].sub(
                _amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function transfer(address _recipient, uint256 _amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), _recipient, _amount);
        return true;
    }

    function _intitalizeAccount(address _account) private {
        // Set initial tick on new holder account, to set their stake against the total supply
        if (_accounts[_account].firstTX == 0) {
            _accounts[_account].firstTX = block.timestamp;
            _accounts[_account].lastTX = block.timestamp;
            _accounts[_account].lastReflectedTick = _totalReflectionTicks
                .current()
                .add(1);
        }
    }

    function _applyReflectedFunds(address _account)
        internal
        nonReentrant
        returns (uint256)
    {
        if (_accounts[_account].excluded) return 0;

        uint256 _reflectionOwed = reflectionBalanceOf(_account);

        _accounts[_account].balance = _accounts[_account].balance.add(
            _reflectionOwed
        );

        _totalReflections = _totalReflections.sub(_reflectionOwed);

        _accounts[_account].lastReflectedTick = _totalReflectionTicks
            .current()
            .add(1);

        emit ReflectionApplied(_account, _reflectionOwed);

        return _reflectionOwed;
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        if (_sender != owner()) {
            // If pre-golive we emit event and revert TX, only owner can tranfer tokens to other accounts
            // such as a Liquidity pool, vesting contracts or other startup accounts
            if (!_tokenGoLive) {
                emit EarlyTransferFailed(_sender, _recipient, _amount);
                revert("ERC20: token not yet live on-chain");
            }

            if (!_accounts[_sender].excluded) {
                // TX delay enforced on non-excluded accounts
                require(
                    block.timestamp.sub(_accounts[_sender].lastTX) > TX_DELAY,
                    "ERC20: transfer failed, transfer delay not met"
                );

                // TX delay enforced on non-excluded accounts for FIRST_TX_DELAY after account creation
                require(
                    block.timestamp.sub(_accounts[_sender].firstTX) >
                        FIRST_TX_DELAY,
                    "ERC20: transfer failed, intial wait period not met"
                );
            }
        }

        // Reject TX for locked accounts
        require(
            !_accounts[_sender].locked && !_accounts[_recipient].locked,
            "ERC20: transfer failed, account is locked"
        );

        // After fees taken and reflection ticks have incremented we apply reflection balance to sender
        _applyReflectedFunds(_sender);

        // Initialize accounts if not yet initialized
        _intitalizeAccount(_sender);
        _intitalizeAccount(_recipient);

        uint256 _senderBalance = balanceOf(_sender);
        require(
            _amount <= _senderBalance,
            "ERC20: transfer amount exceeds senders balance"
        );
        require(
            _amount > 0,
            "ERC20: transfer amount must be greater than zero"
        );
        require(_sender != _recipient, "ERC20: transfer to self");

        // TODO: Transfer to Zero would equate to a burn, how should this be handled?
        require(_sender != address(0), "ERC20: transfer from the zero address");

        if (_msgSender() != owner()) {
            require(
                _accounts[_recipient].balance.add(_amount) <=
                    getHoldingCap(_recipient),
                "ERC20: transfer will exceed recipient holding cap"
            );
            require(
                _amount <= getTXCap(_sender),
                "ERC20: transfer amount exceeds TX cap"
            );
        }

        uint256 _finalAmount = _amount;
        // TODO: Update to only charge fee on sell
        if (!_accounts[_sender].excluded) {
            uint256 _totalFee = _applyFees(_sender, _amount);

            _finalAmount = _amount.sub(_totalFee);
        }

        _accounts[_sender].balance = _accounts[_sender].balance.sub(
            _amount,
            "ERC20: transfer amount exceeds balance"
        );

        uint256 _recipientBalance = _accounts[_recipient].balance;
        _accounts[_recipient].balance = _recipientBalance.add(_finalAmount);

        _accounts[_sender].lastTX = block.timestamp;
        _accounts[_recipient].lastTX = block.timestamp;

        emit Transfer(_sender, _recipient, _finalAmount);
    }

    /**
     * @notice Applies fees for a given amount of tokens to internally manage wallets
     * @param _sender The address of the sender.
     * @param _amount The amount of tokens to collect fees for.
     * @return The total fees collected.
     */
    function _applyFees(address _sender, uint256 _amount)
        private
        returns (uint256)
    {
        (
            uint256 _reflectionFee,
            uint256 _devMarketFee,
            uint256 _charityFee,
            uint256 _resourceLiquidityFee,
            uint256 _totalFee
        ) = calculateFeeAmounts(_amount, _sender);

        uint256 _devMarketBalance = _accounts[
            _internalWallets[WALLET_DEV_MARKET]
        ].balance;
        uint256 _charityBalance = _accounts[_internalWallets[WALLET_CHARITY]]
            .balance;
        uint256 _resourceLiquidityBalance = _accounts[
            _internalWallets[WALLET_RESOURCE_LIQUIDITY]
        ].balance;

        // Reflection
        _totalReflections = _totalReflections.add(_reflectionFee);
        _totalReflectionTicks.increment();
        _totalCollectedReflectionFees = _totalCollectedReflectionFees.add(
            _reflectionFee
        );

        emit ReflectedAmount(_reflectionFee, _totalReflectionTicks.current());

        // Dev Market
        _accounts[_internalWallets[WALLET_DEV_MARKET]]
            .balance = _devMarketBalance.add(_devMarketFee);

        _totalCollectedDevMarketFees = _totalCollectedDevMarketFees.add(
            _devMarketFee
        );

        emit DevMarketingFeeApplied(_devMarketFee);

        _accounts[_internalWallets[WALLET_CHARITY]].balance = _charityBalance
            .add(_charityFee);

        _totalCollectedCharityFees = _totalCollectedCharityFees.add(
            _charityFee
        );

        emit CharityFeeApplied(_charityFee);

        // Resource Liquidity
        _accounts[_internalWallets[WALLET_RESOURCE_LIQUIDITY]]
            .balance = _resourceLiquidityBalance.add(_resourceLiquidityFee);

        _totalCollectedResourceLiquidityFees = _totalCollectedResourceLiquidityFees
            .add(_resourceLiquidityFee);

        emit ResourceLiquidityFeeApplied(_resourceLiquidityFee);

        return _totalFee;
    }

    /**
     * Fee management
     */

    /**
     * @notice Calculate and return values for current fee schedule based on amount and address exclusion
     * @param _amount Amount of tokens to calculate fees for
     * @param _account Address of the sender, important so we know if there should be fees applied at all
     * @return reflection_fee, dev_market_fee, charity_fee, resource_liquidity_fee, liquidity_fee, total_fee
     */
    function calculateFeeAmounts(uint256 _amount, address _account)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        // Excluded address, no fee calculation
        if (_accounts[_account].excluded) {
            return (0, 0, 0, 0, 0);
        }

        uint256 _reflectionFee = Finance.calculateFeeAmount(
            _amount,
            _feeSchedule[FEE_REFLECTION]
        );
        uint256 _devMarketFee;
        uint256 _charityFee;
        uint256 _resourceLiquidityFee;

        if (_internalWallets[WALLET_DEV_MARKET] != address(0)) {
            _devMarketFee = Finance.calculateFeeAmount(
                _amount,
                _feeSchedule[FEE_DEV_MARKET]
            );
        }

        if (_internalWallets[WALLET_CHARITY] != address(0)) {
            _charityFee = Finance.calculateFeeAmount(
                _amount,
                _feeSchedule[FEE_CHARITY]
            );
        }

        if (_internalWallets[WALLET_RESOURCE_LIQUIDITY] != address(0)) {
            _resourceLiquidityFee = Finance.calculateFeeAmount(
                _amount,
                _feeSchedule[FEE_RESOURCE_LIQUIDITY]
            );
        }

        uint256 _totalFee = _reflectionFee
            .add(_devMarketFee)
            .add(_charityFee)
            .add(_resourceLiquidityFee);

        return (
            _reflectionFee,
            _devMarketFee,
            _charityFee,
            _resourceLiquidityFee,
            _totalFee
        );
    }

    /**
     * @notice Returns the previous and current fee from the schedule for the requested fee type
     * @param _feeType UINT of the FeeTypes ENUM you are requesting
     * @return current fee amount in basis points % = value / 1000
     */
    function getFee(uint16 _feeType) public view returns (uint256) {
        return (_feeSchedule[_feeType]);
    }

    /**
     * @notice Update fee schedule, setting _feeType to new value
     * @param _feeType UINT of the FeeTypes ENUM you are updating
     * @param _newFee UINT of the new fee as a value in basis points
     */
    function setFee(uint8 _feeType, uint16 _newFee) public onlyOwner {
        require(
            (
                _feeSchedule[FEE_REFLECTION]
                    .add(_feeSchedule[FEE_DEV_MARKET])
                    .add(_feeSchedule[FEE_CHARITY])
                    .add(_feeSchedule[FEE_RESOURCE_LIQUIDITY])
                    .add(_newFee)
            ).sub(_feeSchedule[_feeType]) <= FEE_MAX_TOTAL,
            "ERC20: proposed fee schedule exceeds limit of 20%"
        );

        uint16 _oldFee = _feeSchedule[_feeType];
        require(_newFee != _oldFee, "ERC20: fee already set");

        // Update current schedule
        _feeSchedule[_feeType] = _newFee;

        emit FeeUpdated(_feeType, _oldFee, _newFee);
    }

    /**
     * @notice Returns the lifetime totals for each fee type
     * @return total_collected_reflection_fees, total_collected_dev_market_fees,
     *         total_collected_charity_fees, total_collected_resource_liquidity_fees
     */
    function getTotalFeesCollected()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _totalCollectedReflectionFees,
            _totalCollectedDevMarketFees,
            _totalCollectedCharityFees,
            _totalCollectedResourceLiquidityFees
        );
    }

    /**
     * @notice Fetch the current balance for the requested internal wallet
     * @return balance in Token Units
     */
    function getInternalBalance(uint8 _walletType)
        public
        view
        returns (uint256)
    {
        return _accounts[_internalWallets[_walletType]].balance;
    }

    /**
     * @notice Fetch the current address for the requested internal wallet
     * @return address and mutability of the internal wallet
     */
    function getInternalWalletAddress(uint8 _walletType)
        public
        view
        returns (address, bool)
    {
        return (_internalWallets[_walletType], _immutableWallet[_walletType]);
    }

    /**
     * @notice Allow contract owner to update internal addresses in the event of breach or other event.
     * Once project matures this is to be set to a form of contract based wallet at which point that wallet
     * type becomes immutable.
     * @param _walletType the type of internal wallet we are updating the address for
     * @param _newAddress the new address to set the internal wallet too. Set to contract address to freeze type
     */
    function setInternalWalletAddress(uint8 _walletType, address _newAddress)
        public
        onlyOwner
    {
        require(
            _newAddress != address(0),
            "ERC20: internal wallet must not be 0"
        );
        if (_walletType != WALLET_RESOURCE_LIQUIDITY) {
            require(
                _newAddress != address(this),
                "ERC20: internal wallet must not be this contract"
            );
        }
        require(
            _newAddress != _internalWallets[_walletType],
            "ERC20: new address must not be same"
        );
        require(
            !_immutableWallet[_walletType],
            "ERC20: internal address is immutable"
        );

        address _oldAddress = _internalWallets[_walletType];
        _internalWallets[_walletType] = _newAddress;

        emit InternalWalletAddressChanged(
            _walletType,
            _oldAddress,
            _newAddress
        );

        // Freeze this internal wallet type from future change, hope you meant to do this!
        if (_newAddress.isContract()) {
            if (_newAddress != address(this)) {
                _accounts[_newAddress].balance = _accounts[_oldAddress].balance;
                _accounts[_oldAddress].balance = 0;

                _immutableWallet[_walletType] = true;
                emit InternalWalletAddressMadeImmutable(
                    _walletType,
                    _oldAddress,
                    _newAddress
                );
            }
        }
    }

    /**
     * @notice Fetch the current maximum holding cap based on the age of the contract
     * @return number of tokens account may hold as WEI
     */
    function getHoldingCap(address _address) public view returns (uint256) {
        if (_accounts[_address].excluded) {
            return _tokenSupply;
        }

        uint256 _seconds = block.timestamp.sub(_creationTimestamp);

        // After 6 months remove all holding caps
        if (_seconds > 180 days) return _tokenSupply;

        return _limitCapSchedule[Math.min((_seconds.div(30 days)), 3)];
    }

    /**
     * @notice Fetch the current maximum TX cap based on the age of the contract
     * @return number of tokens account may hold as WEI
     */
    function getTXCap(address _address) public view returns (uint256) {
        if (_accounts[_address].excluded) {
            return _tokenSupply;
        }

        uint256 _seconds = block.timestamp.sub(_creationTimestamp);
        uint256 _limit = _limitTxSchedule[Math.min((_seconds.div(30 days)), 3)];
        uint256 _holdingCap = getHoldingCap(_address);

        return Finance.calculateFeeAmount(_holdingCap, _limit);
    }

    /*************************************************************************
     * Events
     *************************************************************************/

    // Emmitted when a fee is updated
    event FeeUpdated(uint8 _feeType, uint16 _oldFee, uint16 _newFee);

    // Emmitted when fee has been applied ie: transferred to wallet
    event DevMarketingFeeApplied(uint256 _amount);
    event CharityFeeApplied(uint256 _amount);
    event ResourceLiquidityFeeApplied(uint256 _amount);

    // Emitted when reflection has been collected to reflection pool
    event ReflectedAmount(uint256 _amount, uint256 _ticks);

    // Emitted when an account has performed an action that results in a reflection
    // liquidity event committing their reflection share to their wallet
    event ReflectionApplied(address indexed _account, uint256 _reflectionOwed);

    // Emmitted when an internal wallet has been updated
    event InternalWalletAddressChanged(
        uint8 _walletType,
        address indexed _oldAddress,
        address indexed _newAddress
    );

    // Emmited when an internal wallet converts to a contract wallet and becomes immutable
    event InternalWalletAddressMadeImmutable(
        uint8 _walletType,
        address indexed _oldAddress,
        address indexed _newAddress
    );

    // Emmitted when an account has been excluded from fees
    event AccountExclusionStatusChanged(
        address _account,
        bool _excluded,
        string _reason
    );

    // Emmitted when an account's locked status has been changed
    event AccountLockedStatusChanged(
        address _account,
        bool _locked,
        string _reason
    );

    // Emmitted when the token goLive has been called and the token TX mechanism has been made globally active
    event GoLive();

    // Emmitted when the transfer function called prior to goLive
    event EarlyTransferFailed(address _from, address _to, uint256 _value);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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