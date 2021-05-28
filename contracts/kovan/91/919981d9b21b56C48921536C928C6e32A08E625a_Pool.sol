// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.1;

import "@yield-protocol/vault-v2/contracts/oracles/chainlink/ChainlinkMultiOracle.sol";
import "@yield-protocol/vault-v2/contracts/oracles/compound/CompoundMultiOracle.sol";
import "@yield-protocol/vault-v2/contracts/Join.sol";
import "@yield-protocol/vault-v2/contracts/JoinFactory.sol";
import "@yield-protocol/vault-v2/contracts/FYToken.sol";
import "@yield-protocol/vault-v2/contracts/Cauldron.sol";
import "@yield-protocol/vault-v2/contracts/Ladle.sol";
import "@yield-protocol/vault-v2/contracts/Witch.sol";
import "@yield-protocol/vault-v2/contracts/Wand.sol";
import "@yield-protocol/yieldspace-v2/contracts/Pool.sol";
import "@yield-protocol/yieldspace-v2/contracts/PoolFactory.sol";
import "@yield-protocol/yieldspace-v2/contracts/PoolRouter.sol";

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@yield-protocol/utils-v2/contracts/access/AccessControl.sol";
import "@yield-protocol/vault-interfaces/IOracle.sol";
import "../../math/CastBytes32Bytes6.sol";
import "./AggregatorV3Interface.sol";


/**
 * @title ChainlinkMultiOracle
 */
contract ChainlinkMultiOracle is IOracle, AccessControl {
    using CastBytes32Bytes6 for bytes32;

    event SourceSet(bytes6 indexed baseId, bytes6 indexed quoteId, address indexed source);

    struct Source {
        address source;
        uint8 decimals;
        bool inverse;
    }

    mapping(bytes6 => mapping(bytes6 => Source)) public sources;

    /**
     * @notice Set or reset an oracle source and its inverse
     */
    function setSource(bytes6 base, bytes6 quote, address source) public auth {
        uint8 decimals = AggregatorV3Interface(source).decimals();
        require (decimals <= 18, "Unsupported decimals");
        sources[base][quote] = Source({
            source: source,
            decimals: decimals,
            inverse: false
        });
        sources[quote][base] = Source({
            source: source,
            decimals: decimals,
            inverse: true
        });
        emit SourceSet(base, quote, source);
        emit SourceSet(quote, base, source);
    }

    /**
     * @notice Set or reset a number of oracle sources and their inverses
     */
    function setSources(bytes6[] memory bases, bytes6[] memory quotes, address[] memory sources_) public auth {
        require(
            bases.length == quotes.length && 
            bases.length == sources_.length,
            "Mismatched inputs"
        );
        for (uint256 i = 0; i < bases.length; i++) {
            setSource(bases[i], quotes[i], sources_[i]);
        }
    }

    /**
     * @notice Retrieve the latest price of the price oracle.
     * @return price
     */
    function _peek(bytes6 base, bytes6 quote) private view returns (uint price, uint updateTime) {
        int rawPrice;
        uint80 roundId;
        uint80 answeredInRound;
        Source memory source = sources[base][quote];
        require (source.source != address(0), "Source not found");
        (roundId, rawPrice,, updateTime, answeredInRound) = AggregatorV3Interface(source.source).latestRoundData();
        require(rawPrice > 0, "Chainlink price <= 0");
        require(updateTime != 0, "Incomplete round");
        require(answeredInRound >= roundId, "Stale price");
        if (source.inverse == true) {
            price = 10 ** (source.decimals + 18) / uint(rawPrice);
        } else {
            price = uint(rawPrice) * 10 ** (18 - source.decimals);
        }  
    }

    /**
     * @notice Retrieve the value of the amount at the latest oracle price.
     * @return value
     */
    function peek(bytes32 base, bytes32 quote, uint256 amount) public virtual override view returns (uint256 value, uint256 updateTime) {
        uint256 price;
        (price, updateTime) = _peek(base.b6(), quote.b6());
        value = price * amount / 1e18;
    }

    /**
     * @notice Retrieve the value of the amount at the latest oracle price.. Same as `peek` for this oracle.
     * @return value
     */
    function get(bytes32 base, bytes32 quote, uint256 amount) public virtual override view returns (uint256 value, uint256 updateTime) {
        uint256 price;
        (price, updateTime) = _peek(base.b6(), quote.b6());
        value = price * amount / 1e18;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@yield-protocol/utils-v2/contracts/access/AccessControl.sol";
import "@yield-protocol/vault-interfaces/IOracle.sol";
import "../../math/CastBytes32Bytes6.sol";
import "./CTokenInterface.sol";


contract CompoundMultiOracle is IOracle, AccessControl {
    using CastBytes32Bytes6 for bytes32;

    event SourceSet(bytes6 indexed baseId, bytes6 indexed kind, address indexed source);

    uint public constant SCALE_FACTOR = 1; // I think we don't need scaling for rate and chi oracles

    mapping(bytes6 => mapping(bytes6 => address)) public sources;

    /**
     * @notice Set or reset one source
     */
    function setSource(bytes6 base, bytes6 kind, address source) public auth {
        sources[base][kind] = source;
        emit SourceSet(base, kind, source);
    }

    /**
     * @notice Set or reset an oracle source
     */
    function setSources(bytes6[] memory bases, bytes6[] memory kinds, address[] memory sources_) public auth {
        require(bases.length == kinds.length && kinds.length == sources_.length, "Mismatched inputs");
        for (uint256 i = 0; i < bases.length; i++)
            setSource(bases[i], kinds[i], sources_[i]);
    }

    /**
     * @notice Retrieve the latest price of a given source.
     * @return price
     */
    function _peek(bytes6 base, bytes6 kind) private view returns (uint price, uint updateTime) {
        uint256 rawPrice;
        address source = sources[base][kind];
        require (source != address(0), "Source not found");

        if (kind == "rate") rawPrice = CTokenInterface(source).borrowIndex();
        else if (kind == "chi") rawPrice = CTokenInterface(source).exchangeRateStored();
        else revert("Unknown oracle type");

        require(rawPrice > 0, "Compound price is zero");

        price = rawPrice * SCALE_FACTOR;
        updateTime = block.timestamp;
    }

    /**
     * @notice Retrieve the value of the amount at the latest oracle price.
     * @return value
     */
    function peek(bytes32 base, bytes32 kind, uint256 amount) public virtual override view returns (uint256 value, uint256 updateTime) {
        uint256 price;
        (price, updateTime) = _peek(base.b6(), kind.b6());
        value = price * amount / 1e18;
    }

    /**
     * @notice Retrieve the value of the amount at the latest oracle price. Same as `peek` for this oracle.
     * @return value
     */
    function get(bytes32 base, bytes32 kind, uint256 amount) public virtual override view returns (uint256 value, uint256 updateTime) {
        uint256 price;
        (price, updateTime) = _peek(base.b6(), kind.b6());
        value = price * amount / 1e18;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "erc3156/contracts/interfaces/IERC3156FlashBorrower.sol";
import "erc3156/contracts/interfaces/IERC3156FlashLender.sol";
import "@yield-protocol/vault-interfaces/IJoin.sol";
import "@yield-protocol/vault-interfaces/IJoinFactory.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import "@yield-protocol/utils-v2/contracts/access/AccessControl.sol";
import "@yield-protocol/utils-v2/contracts/token/AllTransferHelper.sol";
import "./math/WMul.sol";
import "./math/CastU256U128.sol";


contract Join is IJoin, IERC3156FlashLender, AccessControl() {
    using AllTransferHelper for IERC20;
    using WMul for uint256;
    using CastU256U128 for uint256;

    event FlashFeeFactorSet(uint256 indexed fee);

    bytes32 constant internal FLASH_LOAN_RETURN = keccak256("ERC3156FlashBorrower.onFlashLoan");

    address public immutable override asset;
    uint256 public storedBalance;
    uint256 public flashFeeFactor; // Fee on flash loans, as a percentage in fixed point with 18 decimals

    constructor() {
        asset = IJoinFactory(msg.sender).nextAsset();
    }

    /// @dev Set the flash loan fee factor
    function setFlashFeeFactor(uint256 flashFeeFactor_)
        public
        auth
    {
        flashFeeFactor = flashFeeFactor_;
        emit FlashFeeFactorSet(flashFeeFactor_);
    }

    /// @dev Take `amount` `asset` from `user` using `transferFrom`, minus any unaccounted `asset` in this contract.
    function join(address user, uint128 amount)
        external override
        auth
        returns (uint128)
    {
        return _join(user, amount);
    }

    /// @dev Take `amount` `asset` from `user` using `transferFrom`, minus any unaccounted `asset` in this contract.
    function _join(address user, uint128 amount)
        internal
        returns (uint128)
    {
        IERC20 token = IERC20(asset);
        uint256 _storedBalance = storedBalance;
        uint256 available = token.balanceOf(address(this)) - _storedBalance; // Fine to panic if this underflows
        storedBalance = _storedBalance + amount;
        unchecked { if (available < amount) token.safeTransferFrom(user, address(this), amount - available); }
        return amount;        
    }

    /// @dev Transfer `amount` `asset` to `user`
    function exit(address user, uint128 amount)
        external override
        auth
        returns (uint128)
    {
        return _exit(user, amount);
    }

    /// @dev Transfer `amount` `asset` to `user`
    function _exit(address user, uint128 amount)
        internal
        returns (uint128)
    {
        IERC20 token = IERC20(asset);
        storedBalance -= amount;
        token.safeTransfer(user, amount);
        return amount;
    }

    /// @dev Retrieve any tokens other than the `asset`. Useful for airdropped tokens.
    function retrieve(IERC20 token, address to)
        external
        auth
    {
        require(address(token) != address(asset), "Use exit for asset");
        token.safeTransfer(to, token.balanceOf(address(this)));
    }

    /**
     * @dev From ERC-3156. The amount of currency available to be lended.
     * @param token The loan currency. It must be a FYDai contract.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) public view override returns (uint256) {
        return token == asset ? storedBalance : 0;
    }

    /**
     * @dev From ERC-3156. The fee to be charged for a given loan.
     * @param token The loan currency. It must be the asset.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) public view override returns (uint256) {
        require(token == asset, "Unsupported currency");
        return _flashFee(amount);
    }

    /**
     * @dev The fee to be charged for a given loan.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function _flashFee(uint256 amount) internal view returns (uint256) {
        return amount.wmul(flashFeeFactor);
    }

    /**
     * @dev From ERC-3156. Loan `amount` `asset` to `receiver`, which needs to return them plus fee to this contract within the same transaction.
     * If the principal + fee are transferred to this contract, they won't be pulled from the receiver.
     * @param receiver The contract receiving the tokens, needs to implement the `onFlashLoan(address user, uint256 amount, uint256 fee, bytes calldata)` interface.
     * @param token The loan currency. Must be a fyDai contract.
     * @param amount The amount of tokens lent.
     * @param data A data parameter to be passed on to the `receiver` for any custom use.
     */
    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes memory data) public override returns(bool) {
        require(token == asset, "Unsupported currency");
        uint128 _amount = amount.u128();
        uint128 _fee = _flashFee(amount).u128();
        _exit(address(receiver), _amount);

        require(receiver.onFlashLoan(msg.sender, token, _amount, _fee, data) == FLASH_LOAN_RETURN, "Non-compliant borrower");

        _join(address(receiver), _amount + _fee);
        return true;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.8.0;

import "@yield-protocol/vault-interfaces/IJoinFactory.sol";
import "./Join.sol";


/// @dev The JoinFactory can deterministically create new join instances.
contract JoinFactory is IJoinFactory {
  /// Pre-hashing the bytecode allows calculateJoinAddress to be cheaper, and
  /// makes client-side address calculation easier
  bytes32 public constant override JOIN_BYTECODE_HASH = keccak256(type(Join).creationCode);

  address private _nextAsset;

  /// @dev Returns true if `account` is a contract.
  function isContract(address account) internal view returns (bool) {
      // This method relies on extcodesize, which returns 0 for contracts in
      // construction, since the code is only stored at the end of the
      // constructor execution.

      uint256 size;
      // solhint-disable-next-line no-inline-assembly
      assembly { size := extcodesize(account) }
      return size > 0;
  }

  /// @dev Calculate the deterministic addreess of a join, based on the asset token.
  /// @param asset Address of the asset token.
  /// @return The calculated join address.
  function calculateJoinAddress(address asset) external view override returns (address) {
    return _calculateJoinAddress(asset);
  }

  /// @dev Create2 calculation
  function _calculateJoinAddress(address asset)
    private view returns (address calculatedAddress)
  {
    calculatedAddress = address(uint160(uint256(keccak256(abi.encodePacked(
      bytes1(0xff),
      address(this),
      keccak256(abi.encodePacked(asset)),
      JOIN_BYTECODE_HASH
    )))));
  }

  /// @dev Calculate the address of a join, and return address(0) if not deployed.
  /// @param asset Address of the asset token.
  /// @return join The deployed join address.
  function getJoin(address asset) external view override returns (address join) {
    join = _calculateJoinAddress(asset);

    if(!isContract(join)) {
      join = address(0);
    }
  }

  /// @dev Deploys a new join.
  /// The asset address is written to a temporary storage slot to allow for simpler
  /// address calculation, while still allowing the Join contract to store the values as
  /// immutable.
  /// @param asset Address of the asset token.
  /// @return join The join address.
  function createJoin(address asset) external override returns (address) {
    _nextAsset = asset;
    Join join = new Join{salt: keccak256(abi.encodePacked(asset))}();
    _nextAsset = address(0);

    join.grantRole(join.ROOT(), msg.sender);
    join.renounceRole(join.ROOT(), address(this));
    
    emit JoinCreated(asset, address(join));

    return address(join);
  }

  /// @dev Only used by the Join constructor.
  /// @return The address token for the currently-constructing join.
  function nextAsset() external view override returns (address) {
    return _nextAsset;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "erc3156/contracts/interfaces/IERC3156FlashBorrower.sol";
import "erc3156/contracts/interfaces/IERC3156FlashLender.sol";
import "@yield-protocol/utils-v2/contracts/token/ERC20Permit.sol";
import "@yield-protocol/vault-interfaces/IFYToken.sol";
import "@yield-protocol/vault-interfaces/IJoin.sol";
import "@yield-protocol/vault-interfaces/IOracle.sol";
import "@yield-protocol/utils-v2/contracts/access/AccessControl.sol";
import "./math/WMul.sol";
import "./math/WDiv.sol";
import "./math/CastU256U128.sol";
import "./math/CastU256U32.sol";


contract FYToken is IFYToken, IERC3156FlashLender, AccessControl(), ERC20Permit {
    using WMul for uint256;
    using WDiv for uint256;
    using CastU256U128 for uint256;
    using CastU256U32 for uint256;

    event SeriesMatured(uint256 chiAtMaturity);
    event Redeemed(address indexed from, address indexed to, uint256 amount, uint256 redeemed);
    event OracleSet(address indexed oracle);

    bytes32 constant CHI = "chi";

    uint256 constant internal MAX_TIME_TO_MATURITY = 126144000; // seconds in four years
    bytes32 constant internal FLASH_LOAN_RETURN = keccak256("ERC3156FlashBorrower.onFlashLoan");

    IOracle public oracle;                                      // Oracle for the savings rate.
    IJoin public immutable join;                                // Source of redemption funds.
    address public immutable override underlying;
    bytes6 public immutable underlyingId;                             // Needed to access the oracle
    uint256 public immutable override maturity;
    uint256 public chiAtMaturity = type(uint256).max;           // Spot price (exchange rate) between the base and an interest accruing token at maturity 

    constructor(
        bytes6 underlyingId_,
        IOracle oracle_, // Underlying vs its interest-bearing version
        IJoin join_,
        uint256 maturity_,
        string memory name,
        string memory symbol
    ) ERC20Permit(name, symbol, IERC20Metadata(address(IJoin(join_).asset())).decimals()) { // The join asset is this fyToken's underlying, from which we inherit the decimals
        uint256 now_ = block.timestamp;
        require(
            maturity_ > now_ &&
            maturity_ < now_ + MAX_TIME_TO_MATURITY &&
            maturity_ < type(uint32).max,
            "Invalid maturity"
        );

        underlyingId = underlyingId_;
        join = join_;
        maturity = maturity_;
        underlying = address(IJoin(join_).asset());
        setOracle(oracle_);
    }

    modifier afterMaturity() {
        require(
            uint32(block.timestamp) >= maturity,
            "Only after maturity"
        );
        _;
    }

    modifier beforeMaturity() {
        require(
            uint32(block.timestamp) < maturity,
            "Only before maturity"
        );
        _;
    }

    /// @dev Set the oracle parameter
    function setOracle(IOracle oracle_)
        public
        auth    
    {
        oracle = oracle_;
        emit OracleSet(address(oracle_));
    }

    /// @dev Mature the fyToken by recording the chi.
    /// If called more than once, it will revert.
    function mature()
        external override
        afterMaturity
    {
        require (chiAtMaturity == type(uint256).max, "Already matured");
        _mature();
    }

    /// @dev Mature the fyToken by recording the chi.
    function _mature() 
        private
        returns (uint256 _chiAtMaturity)
    {
        (_chiAtMaturity,) = oracle.get(underlyingId, CHI, 1e18);
        chiAtMaturity = _chiAtMaturity;
        emit SeriesMatured(_chiAtMaturity);
    }

    /// @dev Retrieve the chi accrual since maturity, maturing if necessary.
    function accrual()
        external
        afterMaturity
        returns (uint256)
    {
        return _accrual();
    }

    /// @dev Retrieve the chi accrual since maturity, maturing if necessary.
    /// Note: Call only after checking we are past maturity
    function _accrual()
        private
        returns (uint256 accrual_)
    {
        if (chiAtMaturity == type(uint256).max) {  // After maturity, but chi not yet recorded. Let's record it, and accrual is then 1.
            _mature();
        } else {
            (uint256 chi,) = oracle.get(underlyingId, CHI, 1e18);
            accrual_ = chi.wdiv(chiAtMaturity);
        }
        accrual_ = accrual_ >= 1e18 ? accrual_ : 1e18;     // The accrual can't be below 1 (with 18 decimals)
    }

    /// @dev Burn the fyToken after maturity for an amount that increases according to `chi`
    function redeem(address to, uint256 amount)
        external override
        afterMaturity
        returns (uint256 redeemed)
    {
        _burn(msg.sender, amount);
        redeemed = amount.wmul(_accrual());
        join.exit(to, redeemed.u128());
        
        emit Redeemed(msg.sender, to, amount, redeemed);
        return amount;
    }

    /// @dev Mint fyTokens.
    function mint(address to, uint256 amount)
        external override
        beforeMaturity
        auth
    {
        _mint(to, amount);
    }

    /// @dev Burn fyTokens. The user needs to have either transferred the tokens to this contract, or have approved this contract to take them. 
    function burn(address from, uint256 amount)
        external override
        auth
    {
        _burn(from, amount);
    }

    /// @dev Burn fyTokens. 
    /// Any tokens locked in this contract will be burned first and subtracted from the amount to burn from the user's wallet.
    /// This feature allows someone to transfer fyToken to this contract to enable a `burn`, potentially saving the cost of `approve` or `permit`.
    function _burn(address from, uint256 amount)
        internal override
        returns (bool)
    {
        // First use any tokens locked in this contract
        uint256 available = _balanceOf[address(this)];
        if (available >= amount) {
            unchecked { return super._burn(address(this), amount); }
        } else {
            if (available > 0 ) super._burn(address(this), available);
            unchecked { _decreaseAllowance(from, amount - available); }
            unchecked { return super._burn(from, amount - available); }
        }
    }

    /**
     * @dev From ERC-3156. The amount of currency available to be lended.
     * @param token The loan currency. It must be a FYDai contract.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token)
        external view override
        beforeMaturity
        returns (uint256)
    {
        return token == address(this) ? type(uint256).max - _totalSupply : 0;
    }

    /**
     * @dev From ERC-3156. The fee to be charged for a given loan.
     * @param token The loan currency. It must be a FYDai.
     * param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256)
        external view override
        beforeMaturity
        returns (uint256)
    {
        require(token == address(this), "Unsupported currency");
        return 0;
    }

    /**
     * @dev From ERC-3156. Loan `amount` fyDai to `receiver`, which needs to return them plus fee to this contract within the same transaction.
     * Note that if the initiator and the borrower are the same address, no approval is needed for this contract to take the principal + fee from the borrower.
     * If the borrower transfers the principal + fee to this contract, they will be burnt here instead of pulled from the borrower.
     * @param receiver The contract receiving the tokens, needs to implement the `onFlashLoan(address user, uint256 amount, uint256 fee, bytes calldata)` interface.
     * @param token The loan currency. Must be a fyDai contract.
     * @param amount The amount of tokens lent.
     * @param data A data parameter to be passed on to the `receiver` for any custom use.
     */
    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes memory data)
        external override
        beforeMaturity
        returns(bool)
    {
        require(token == address(this), "Unsupported currency");
        _mint(address(receiver), amount);
        require(receiver.onFlashLoan(msg.sender, token, amount, 0, data) == FLASH_LOAN_RETURN, "Non-compliant borrower");
        _burn(address(receiver), amount);
        return true;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "@yield-protocol/vault-interfaces/IFYToken.sol";
import "@yield-protocol/vault-interfaces/IOracle.sol";
import "@yield-protocol/vault-interfaces/DataTypes.sol";
import "@yield-protocol/utils-v2/contracts/access/AccessControl.sol";
import "./math/WMul.sol";
import "./math/WDiv.sol";
import "./math/CastU128I128.sol";
import "./math/CastI128U128.sol";
import "./math/CastU256U32.sol";
import "./math/CastU256I256.sol";

library CauldronMath {
    /// @dev Add a number (which might be negative) to a positive, and revert if the result is negative.
    function add(uint128 x, int128 y) internal pure returns (uint128 z) {
        require (y > 0 || x >= uint128(-y), "Result below zero");
        z = y > 0 ? x + uint128(y) : x - uint128(-y);
    }
}


contract Cauldron is AccessControl() {
    using CauldronMath for uint128;
    using WMul for uint256;
    using WDiv for uint256;
    using CastU128I128 for uint128;
    using CastU256U32 for uint256;
    using CastU256I256 for uint256;
    using CastI128U128 for int128;

    event AuctionIntervalSet(uint32 indexed auctionInterval);
    event AssetAdded(bytes6 indexed assetId, address indexed asset);
    event SeriesAdded(bytes6 indexed seriesId, bytes6 indexed baseId, address indexed fyToken);
    event IlkAdded(bytes6 indexed seriesId, bytes6 indexed ilkId);
    event SpotOracleAdded(bytes6 indexed baseId, bytes6 indexed ilkId, address indexed oracle, uint32 ratio);
    event RateOracleAdded(bytes6 indexed baseId, address indexed oracle);
    event DebtLimitsSet(bytes6 indexed baseId, bytes6 indexed ilkId, uint96 max, uint24 min, uint8 dec);

    event VaultBuilt(bytes12 indexed vaultId, address indexed owner, bytes6 indexed seriesId, bytes6 ilkId);
    event VaultTweaked(bytes12 indexed vaultId, bytes6 indexed seriesId, bytes6 indexed ilkId);
    event VaultDestroyed(bytes12 indexed vaultId);
    event VaultGiven(bytes12 indexed vaultId, address indexed receiver);

    event VaultPoured(bytes12 indexed vaultId, bytes6 indexed seriesId, bytes6 indexed ilkId, int128 ink, int128 art);
    event VaultStirred(bytes12 indexed from, bytes12 indexed to, uint128 ink, uint128 art);
    event VaultRolled(bytes12 indexed vaultId, bytes6 indexed seriesId, uint128 art);
    event VaultLocked(bytes12 indexed vaultId, uint256 indexed timestamp);

    event SeriesMatured(bytes6 indexed seriesId, uint256 rateAtMaturity);

    // ==== Configuration data ====
    mapping (bytes6 => address)                                 public assets;          // Underlyings and collaterals available in Cauldron. 12 bytes still free.
    mapping (bytes6 => DataTypes.Series)                        public series;          // Series available in Cauldron. We can possibly use a bytes6 (3e14 possible series).
    mapping (bytes6 => mapping(bytes6 => bool))                 public ilks;            // [seriesId][assetId] Assets that are approved as collateral for a series

    mapping (bytes6 => IOracle)                                 public rateOracles;     // Rate (borrowing rate) accruals oracle for the underlying
    mapping (bytes6 => mapping(bytes6 => DataTypes.SpotOracle)) public spotOracles;     // [assetId][assetId] Spot price oracles

    // ==== Protocol data ====
    mapping (bytes6 => mapping(bytes6 => DataTypes.Debt))       public debt;            // [baseId][ilkId] Max and sum of debt per underlying and collateral.
    mapping (bytes6 => uint256)                                 public ratesAtMaturity; // Borrowing rate at maturity for a mature series
    uint32                                                      public auctionInterval;// Time that vaults in liquidation are protected from being grabbed by a different engine.

    // ==== User data ====
    mapping (bytes12 => DataTypes.Vault)                        public vaults;          // An user can own one or more Vaults, each one with a bytes12 identifier
    mapping (bytes12 => DataTypes.Balances)                     public balances;        // Both debt and assets
    mapping (bytes12 => uint32)                                 public auctions;        // If grater than zero, time that a vault was timestamped. Used for liquidation.

    // ==== Administration ====

    /// @dev Add a new Asset.
    function addAsset(bytes6 assetId, address asset)
        external
        auth
    {
        require (assetId != bytes6(0), "Asset id is zero");
        require (assets[assetId] == address(0), "Id already used");
        assets[assetId] = asset;
        emit AssetAdded(assetId, address(asset));
    }

    /// @dev Set the maximum and minimum debt for an underlying and ilk pair. Can be reset.
    function setDebtLimits(bytes6 baseId, bytes6 ilkId, uint96 max, uint24 min, uint8 dec)
        external
        auth
    {
        require (assets[baseId] != address(0), "Base not found");
        require (assets[ilkId] != address(0), "Ilk not found");
        DataTypes.Debt memory debt_ = debt[baseId][ilkId];
        debt_.max = max;
        debt_.min = min;
        debt_.dec = dec;
        debt[baseId][ilkId] = debt_;
        emit DebtLimitsSet(baseId, ilkId, max, min, dec);
    }

    /// @dev Set a rate oracle. Can be reset.
    function setRateOracle(bytes6 baseId, IOracle oracle)
        external
        auth
    {
        require (assets[baseId] != address(0), "Base not found");
        rateOracles[baseId] = oracle;
        emit RateOracleAdded(baseId, address(oracle));
    }

    /// @dev Set the interval for which vaults being auctioned can't be grabbed by another liquidation engine
    function setAuctionInterval(uint32 auctionInterval_)
        external
        auth
    {
        auctionInterval = auctionInterval_;
        emit AuctionIntervalSet(auctionInterval_);
    }

    /// @dev Set a spot oracle and its collateralization ratio. Can be reset.
    function setSpotOracle(bytes6 baseId, bytes6 ilkId, IOracle oracle, uint32 ratio)
        external
        auth
    {
        require (assets[baseId] != address(0), "Base not found");
        require (assets[ilkId] != address(0), "Ilk not found");
        spotOracles[baseId][ilkId] = DataTypes.SpotOracle({
            oracle: oracle,
            ratio: ratio                                                                    // With 6 decimals. 1000000 == 100%
        });                                                                                 // Allows to replace an existing oracle.
        emit SpotOracleAdded(baseId, ilkId, address(oracle), ratio);
    }

    /// @dev Add a new series
    function addSeries(bytes6 seriesId, bytes6 baseId, IFYToken fyToken)
        external
        auth
    {
        require (seriesId != bytes6(0), "Series id is zero");
        address base = assets[baseId];
        require (base != address(0), "Base not found");
        require (fyToken != IFYToken(address(0)), "Series need a fyToken");
        require (fyToken.underlying() == base, "Mismatched series and base");
        require (rateOracles[baseId] != IOracle(address(0)), "Rate oracle not found");
        require (series[seriesId].fyToken == IFYToken(address(0)), "Id already used");
        series[seriesId] = DataTypes.Series({
            fyToken: fyToken,
            maturity: fyToken.maturity().u32(),
            baseId: baseId
        });
        emit SeriesAdded(seriesId, baseId, address(fyToken));
    }

    /// @dev Add a new Ilk (approve an asset as collateral for a series).
    function addIlks(bytes6 seriesId, bytes6[] calldata ilkIds)
        external
        auth
    {
        DataTypes.Series memory series_ = series[seriesId];
        require (
            series_.fyToken != IFYToken(address(0)),
            "Series not found"
        );
        for (uint256 i = 0; i < ilkIds.length; i++) {
            require (
                spotOracles[series_.baseId][ilkIds[i]].oracle != IOracle(address(0)),
                "Spot oracle not found"
            );
            ilks[seriesId][ilkIds[i]] = true;
            emit IlkAdded(seriesId, ilkIds[i]);
        }
    }

    // ==== Vault management ====

    /// @dev Create a new vault, linked to a series (and therefore underlying) and a collateral
    function build(address owner, bytes12 vaultId, bytes6 seriesId, bytes6 ilkId)
        external
        auth
        returns(DataTypes.Vault memory vault)
    {
        require (vaultId != bytes12(0), "Vault id is zero");
        require (vaults[vaultId].seriesId == bytes6(0), "Vault already exists");   // Series can't take bytes6(0) as their id
        require (ilks[seriesId][ilkId] == true, "Ilk not added to series");
        vault = DataTypes.Vault({
            owner: owner,
            seriesId: seriesId,
            ilkId: ilkId
        });
        vaults[vaultId] = vault;

        emit VaultBuilt(vaultId, owner, seriesId, ilkId);
    }

    /// @dev Destroy an empty vault. Used to recover gas costs.
    function destroy(bytes12 vaultId)
        external
        auth
    {
        DataTypes.Balances memory balances_ = balances[vaultId];
        require (balances_.art == 0 && balances_.ink == 0, "Only empty vaults");
        delete auctions[vaultId];
        delete vaults[vaultId];
        emit VaultDestroyed(vaultId);
    }

    /// @dev Change a vault series and/or collateral types.
    function _tweak(bytes12 vaultId, DataTypes.Vault memory vault)
        internal
    {
        require (ilks[vault.seriesId][vault.ilkId] == true, "Ilk not added to series");

        vaults[vaultId] = vault;
        emit VaultTweaked(vaultId, vault.seriesId, vault.ilkId);
    }

    /// @dev Change a vault series and/or collateral types.
    /// We can change the series if there is no debt, or assets if there are no assets
    function tweak(bytes12 vaultId, bytes6 seriesId, bytes6 ilkId)
        external
        auth
        returns(DataTypes.Vault memory vault)
    {
        DataTypes.Balances memory balances_ = balances[vaultId];
        vault = vaults[vaultId];
        if (seriesId != vault.seriesId) {
            require (balances_.art == 0, "Only with no debt");
            vault.seriesId = seriesId;
        }
        if (ilkId != vault.ilkId) {
            require (balances_.ink == 0, "Only with no collateral");
            vault.ilkId = ilkId;
        }
        _tweak(vaultId, vault);
    }

    /// @dev Transfer a vault to another user.
    function _give(bytes12 vaultId, address receiver)
        internal
        returns(DataTypes.Vault memory vault)
    {
        vault = vaults[vaultId];
        vault.owner = receiver;
        vaults[vaultId] = vault;
        emit VaultGiven(vaultId, receiver);
    }

    /// @dev Transfer a vault to another user.
    function give(bytes12 vaultId, address receiver)
        external
        auth
        returns(DataTypes.Vault memory vault)
    {
        vault = _give(vaultId, receiver);
    }

    // ==== Asset and debt management ====

    function vaultData(bytes12 vaultId, bool getSeries)
        internal
        view
        returns (DataTypes.Vault memory vault_, DataTypes.Series memory series_, DataTypes.Balances memory balances_)
    {
        vault_ = vaults[vaultId];
        require (vault_.seriesId != bytes6(0), "Vault not found");
        if (getSeries) series_ = series[vault_.seriesId];
        balances_ = balances[vaultId];
    }

    /// @dev Move collateral and debt between vaults.
    function stir(bytes12 from, bytes12 to, uint128 ink, uint128 art)
        external
        auth
        returns (DataTypes.Balances memory, DataTypes.Balances memory)
    {
        (DataTypes.Vault memory vaultFrom, , DataTypes.Balances memory balancesFrom) = vaultData(from, false);
        (DataTypes.Vault memory vaultTo, , DataTypes.Balances memory balancesTo) = vaultData(to, false);

        if (ink > 0) {
            require (vaultFrom.ilkId == vaultTo.ilkId, "Different collateral");
            balancesFrom.ink -= ink;
            balancesTo.ink += ink;
        }
        if (art > 0) {
            require (vaultFrom.seriesId == vaultTo.seriesId, "Different series");
            balancesFrom.art -= art;
            balancesTo.art += art;
        }

        balances[from] = balancesFrom;
        balances[to] = balancesTo;

        if (ink > 0) require(_level(vaultFrom, balancesFrom, series[vaultFrom.seriesId]) >= 0, "Undercollateralized at origin");
        if (art > 0) require(_level(vaultTo, balancesTo, series[vaultTo.seriesId]) >= 0, "Undercollateralized at destination");

        emit VaultStirred(from, to, ink, art);
        return (balancesFrom, balancesTo);
    }

    /// @dev Add collateral and borrow from vault, pull assets from and push borrowed asset to user
    /// Or, repay to vault and remove collateral, pull borrowed asset from and push assets to user
    function _pour(
        bytes12 vaultId,
        DataTypes.Vault memory vault_,
        DataTypes.Balances memory balances_,
        DataTypes.Series memory series_,
        int128 ink,
        int128 art
    )
        internal returns (DataTypes.Balances memory)
    {
        // For now, the collateralization checks are done outside to allow for underwater operation. That might change.
        if (ink != 0) {
            balances_.ink = balances_.ink.add(ink);
        }

        // Modify vault and global debt records. If debt increases, check global limit.
        if (art != 0) {
            DataTypes.Debt memory debt_ = debt[series_.baseId][vault_.ilkId];
            balances_.art = balances_.art.add(art);
            debt_.sum = debt_.sum.add(art);
            uint128 dust = debt_.min * uint128(10) ** debt_.dec;
            uint128 line = debt_.max * uint128(10) ** debt_.dec;
            require (balances_.art == 0 || balances_.art >= dust, "Min debt not reached");
            if (art > 0) require (debt_.sum <= line, "Max debt exceeded");
            debt[series_.baseId][vault_.ilkId] = debt_;
        }
        balances[vaultId] = balances_;

        emit VaultPoured(vaultId, vault_.seriesId, vault_.ilkId, ink, art);
        return balances_;
    }

    /// @dev Manipulate a vault, ensuring it is collateralized afterwards.
    /// To be used by debt management contracts.
    function pour(bytes12 vaultId, int128 ink, int128 art)
        external
        auth
        returns (DataTypes.Balances memory)
    {
        (DataTypes.Vault memory vault_, DataTypes.Series memory series_, DataTypes.Balances memory balances_) = vaultData(vaultId, true);

        balances_ = _pour(vaultId, vault_, balances_, series_, ink, art);

        if (balances_.art > 0 && (ink < 0 || art > 0))                          // If there is debt and we are less safe
            require(_level(vault_, balances_, series_) >= 0, "Undercollateralized");
        return balances_;
    }

    /// @dev Give a non-timestamped vault to another user, and timestamp it.
    /// To be used for liquidation engines.
    function grab(bytes12 vaultId, address receiver)
        external
        auth
    {
        uint32 now_ = uint32(block.timestamp);
        require (auctions[vaultId] + auctionInterval <= now_, "Vault under auction");        // Grabbing a vault protects it for a day from being grabbed by another liquidator. All grabbed vaults will be suddenly released on the 7th of February 2106, at 06:28:16 GMT. I can live with that.

        (DataTypes.Vault memory vault_, DataTypes.Series memory series_, DataTypes.Balances memory balances_) = vaultData(vaultId, true);
        require(_level(vault_, balances_, series_) < 0, "Not undercollateralized");

        auctions[vaultId] = now_;
        _give(vaultId, receiver);

        emit VaultLocked(vaultId, now_);
    }

    /// @dev Reduce debt and collateral from a vault, ignoring collateralization checks.
    /// To be used by liquidation engines.
    function slurp(bytes12 vaultId, uint128 ink, uint128 art)
        external
        auth
        returns (DataTypes.Balances memory)
    {
        (DataTypes.Vault memory vault_, DataTypes.Series memory series_, DataTypes.Balances memory balances_) = vaultData(vaultId, true);

        balances_ = _pour(vaultId, vault_, balances_, series_, -(ink.i128()), -(art.i128()));

        return balances_;
    }

    /// @dev Change series and debt of a vault.
    /// The module calling this function also needs to buy underlying in the pool for the new series, and sell it in pool for the old series.
    function roll(bytes12 vaultId, bytes6 newSeriesId, int128 art)
        external
        auth
        returns (DataTypes.Vault memory, DataTypes.Balances memory)
    {
        (DataTypes.Vault memory vault_, DataTypes.Series memory oldSeries_, DataTypes.Balances memory balances_) = vaultData(vaultId, true);
        DataTypes.Series memory newSeries_ = series[newSeriesId];
        require (oldSeries_.baseId == newSeries_.baseId, "Mismatched bases in series");
        
        // Change the vault series
        vault_.seriesId = newSeriesId;
        _tweak(vaultId, vault_);

        // Change the vault balances
        balances_ = _pour(vaultId, vault_, balances_, newSeries_, 0, art);

        require(_level(vault_, balances_, newSeries_) >= 0, "Undercollateralized");
        emit VaultRolled(vaultId, newSeriesId, balances_.art);

        return (vault_, balances_);
    }

    // ==== Accounting ====

    /// @dev Return the collateralization level of a vault. It will be negative if undercollateralized.
    function level(bytes12 vaultId) public returns (int256) {
        (DataTypes.Vault memory vault_, DataTypes.Series memory series_, DataTypes.Balances memory balances_) = vaultData(vaultId, true);

        return _level(vault_, balances_, series_);
    }

    /// @dev Record the borrowing rate at maturity for a series
    function mature(bytes6 seriesId)
        public
    {
        DataTypes.Series memory series_ = series[seriesId];
        require (uint32(block.timestamp) >= series_.maturity, "Only after maturity");
        require (ratesAtMaturity[seriesId] == 0, "Already matured");
        _mature(seriesId, series_);
    }

    /// @dev Record the borrowing rate at maturity for a series
    function _mature(bytes6 seriesId, DataTypes.Series memory series_)
        internal
    {
        IOracle rateOracle = rateOracles[series_.baseId];
        (uint256 rateAtMaturity,) = rateOracle.get(series_.baseId, bytes32("rate"), 1e18);
        ratesAtMaturity[seriesId] = rateAtMaturity;
        emit SeriesMatured(seriesId, rateAtMaturity);
    }
    

    /// @dev Retrieve the rate accrual since maturity, maturing if necessary.
    function accrual(bytes6 seriesId)
        public
        returns (uint256)
    {
        DataTypes.Series memory series_ = series[seriesId];
        require (uint32(block.timestamp) >= series_.maturity, "Only after maturity");
        return _accrual(seriesId, series_);
    }

    /// @dev Retrieve the rate accrual since maturity, maturing if necessary.
    /// Note: Call only after checking we are past maturity
    function _accrual(bytes6 seriesId, DataTypes.Series memory series_)
        private
        returns (uint256 accrual_)
    {
        uint256 rateAtMaturity = ratesAtMaturity[seriesId];
        if (rateAtMaturity == 0) {  // After maturity, but rate not yet recorded. Let's record it, and accrual is then 1.
            _mature(seriesId, series_);
        } else {
            IOracle rateOracle = rateOracles[series_.baseId];
            (uint256 rate,) = rateOracle.get(series_.baseId, bytes32("rate"), 1e18);
            accrual_ = rate.wdiv(rateAtMaturity);
        }
        accrual_ = accrual_ >= 1e18 ? accrual_ : 1e18;     // The accrual can't be below 1 (with 18 decimals)
    }

    /// @dev Return the collateralization level of a vault. It will be negative if undercollateralized.
    function _level(
        DataTypes.Vault memory vault_,
        DataTypes.Balances memory balances_,
        DataTypes.Series memory series_
    )
        internal
        returns (int256)
    {
        DataTypes.SpotOracle memory spotOracle_ = spotOracles[series_.baseId][vault_.ilkId];
        uint256 ratio = uint256(spotOracle_.ratio) * 1e12;   // Normalized to 18 decimals
        (uint256 inkValue,) = spotOracle_.oracle.get(series_.baseId, vault_.ilkId, balances_.ink);    // ink * spot

        if (uint32(block.timestamp) >= series_.maturity) {
            uint256 accrual_ = _accrual(vault_.seriesId, series_);
            return inkValue.i256() - uint256(balances_.art).wmul(accrual_).wmul(ratio).i256();
        }

        return inkValue.i256() - uint256(balances_.art).wmul(ratio).i256();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "@yield-protocol/vault-interfaces/IFYToken.sol";
import "@yield-protocol/vault-interfaces/IJoin.sol";
import "@yield-protocol/vault-interfaces/ICauldron.sol";
import "@yield-protocol/vault-interfaces/IOracle.sol";
import "@yield-protocol/vault-interfaces/DataTypes.sol";
import "@yield-protocol/yieldspace-interfaces/IPool.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC2612.sol";
import "dss-interfaces/src/dss/DaiAbstract.sol";
import "@yield-protocol/utils-v2/contracts/access/AccessControl.sol";
import "@yield-protocol/utils-v2/contracts/token/AllTransferHelper.sol";
import "@yield-protocol/utils-v2/contracts/interfaces/IWETH9.sol";
import "./math/WMul.sol";
import "./math/CastU256U128.sol";
import "./math/CastU128I128.sol";
import "./LadleStorage.sol";
import "hardhat/console.sol";


/// @dev Ladle orchestrates contract calls throughout the Yield Protocol v2 into useful and efficient user oriented features.
contract Ladle is LadleStorage, AccessControl() {
    using WMul for uint256;
    using CastU256U128 for uint256;
    using CastU128I128 for uint128;
    using AllTransferHelper for IERC20;
    using AllTransferHelper for address payable;

    IWETH9 public immutable weth;

    constructor (ICauldron cauldron, IWETH9 weth_) LadleStorage(cauldron) {
        weth = weth_;
    }

    // ---- Data sourcing ----
    /// @dev Obtains a vault by vaultId from the Cauldron, and verifies that msg.sender is the owner
    function getOwnedVault(bytes12 vaultId)
        internal view returns(DataTypes.Vault memory vault)
    {
        vault = cauldron.vaults(vaultId);
        require (vault.owner == msg.sender, "Only vault owner");
    }

    /// @dev Obtains a series by seriesId from the Cauldron, and verifies that it exists
    function getSeries(bytes6 seriesId)
        internal view returns(DataTypes.Series memory series)
    {
        series = cauldron.series(seriesId);
        require (series.fyToken != IFYToken(address(0)), "Series not found");
    }

    /// @dev Obtains a join by assetId, and verifies that it exists
    function getJoin(bytes6 assetId)
        internal view returns(IJoin join)
    {
        join = joins[assetId];
        require (join != IJoin(address(0)), "Join not found");
    }

    /// @dev Obtains a pool by seriesId, and verifies that it exists
    function getPool(bytes6 seriesId)
        internal view returns(IPool pool)
    {
        pool = pools[seriesId];
        require (pool != IPool(address(0)), "Pool not found");
    }

    // ---- Administration ----

    /// @dev Add a new Join for an Asset, or replace an existing one for a new one.
    /// There can be only one Join per Asset. Until a Join is added, no tokens of that Asset can be posted or withdrawn.
    function addJoin(bytes6 assetId, IJoin join)
        external
        auth
    {
        address asset = cauldron.assets(assetId);
        require (asset != address(0), "Asset not found");
        require (join.asset() == asset, "Mismatched asset and join");
        joins[assetId] = join;
        emit JoinAdded(assetId, address(join));
    }

    /// @dev Add a new Pool for a Series, or replace an existing one for a new one.
    /// There can be only one Pool per Series. Until a Pool is added, it is not possible to borrow Base.
    function addPool(bytes6 seriesId, IPool pool)
        external
        auth
    {
        IFYToken fyToken = getSeries(seriesId).fyToken;
        require (fyToken == pool.fyToken(), "Mismatched pool fyToken and series");
        require (fyToken.underlying() == address(pool.base()), "Mismatched pool base and series");
        pools[seriesId] = pool;
        emit PoolAdded(seriesId, address(pool));
    }

    /// @dev Add or remove a module.
    function setModule(address module, bool set)
        external
        auth
    {
        modules[module] = set;
        emit ModuleSet(module, set);
    }

    /// @dev Set the fee parameter
    function setFee(uint256 fee)
        public
        auth    
    {
        borrowingFee = fee;
        emit FeeSet(fee);
    }

    // ---- Batching ----


    /// @dev Submit a series of calls for execution.
    /// Unlike `batch`, this function calls private functions, saving a CALL per function.
    /// It also caches the vault, which is useful in `build` + `pour` and `build` + `serve` combinations.
    function batch(
        Operation[] calldata operations,
        bytes[] calldata data
    ) external payable {
        require(operations.length == data.length, "Mismatched operation data");
        bytes12 cachedId;
        DataTypes.Vault memory vault;

        // Execute all operations in the batch. Conditionals ordered by expected frequency.
        for (uint256 i = 0; i < operations.length; i += 1) {

            Operation operation = operations[i];

            if (operation == Operation.BUILD) {
                (bytes12 vaultId, bytes6 seriesId, bytes6 ilkId) = abi.decode(data[i], (bytes12, bytes6, bytes6));
                (cachedId, vault) = (vaultId, _build(vaultId, seriesId, ilkId));   // Cache the vault that was just built
            
            } else if (operation == Operation.FORWARD_PERMIT) {
                (bytes6 id, bool isAsset, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) =
                    abi.decode(data[i], (bytes6, bool, address, uint256, uint256, uint8, bytes32, bytes32));
                _forwardPermit(id, isAsset, spender, amount, deadline, v, r, s);
            
            } else if (operation == Operation.JOIN_ETHER) {
                (bytes6 etherId) = abi.decode(data[i], (bytes6));
                _joinEther(etherId);
            
            } else if (operation == Operation.POUR) {
                (bytes12 vaultId, address to, int128 ink, int128 art) = abi.decode(data[i], (bytes12, address, int128, int128));
                if (cachedId != vaultId) (cachedId, vault) = (vaultId, getOwnedVault(vaultId));
                _pour(vaultId, vault, to, ink, art);
            
            } else if (operation == Operation.SERVE) {
                (bytes12 vaultId, address to, uint128 ink, uint128 base, uint128 max) = abi.decode(data[i], (bytes12, address, uint128, uint128, uint128));
                if (cachedId != vaultId) (cachedId, vault) = (vaultId, getOwnedVault(vaultId));
                _serve(vaultId, vault, to, ink, base, max);

            } else if (operation == Operation.ROLL) {
                (bytes12 vaultId, bytes6 newSeriesId, uint8 loan, uint128 max) = abi.decode(data[i], (bytes12, bytes6, uint8, uint128));
                if (cachedId != vaultId) (cachedId, vault) = (vaultId, getOwnedVault(vaultId));
                (vault,) = _roll(vaultId, vault, newSeriesId, loan, max);
            
            } else if (operation == Operation.FORWARD_DAI_PERMIT) {
                (bytes6 id, bool isAsset, address spender, uint256 nonce, uint256 deadline, bool allowed, uint8 v, bytes32 r, bytes32 s) =
                    abi.decode(data[i], (bytes6, bool, address, uint256, uint256, bool, uint8, bytes32, bytes32));
                _forwardDaiPermit(id, isAsset, spender, nonce, deadline, allowed, v, r, s);
            
            } else if (operation == Operation.TRANSFER_TO_POOL) {
                (bytes6 seriesId, bool base, uint128 wad) =
                    abi.decode(data[i], (bytes6, bool, uint128));
                IPool pool = getPool(seriesId);
                _transferToPool(pool, base, wad);
            
            } else if (operation == Operation.ROUTE) {
                (bytes6 seriesId, bytes memory poolCall) =
                    abi.decode(data[i], (bytes6, bytes));
                IPool pool = getPool(seriesId);
                _route(pool, poolCall);
            
            } else if (operation == Operation.EXIT_ETHER) {
                (address to) = abi.decode(data[i], (address));
                _exitEther(payable(to));
            
            } else if (operation == Operation.CLOSE) {
                (bytes12 vaultId, address to, int128 ink, int128 art) = abi.decode(data[i], (bytes12, address, int128, int128));
                if (cachedId != vaultId) (cachedId, vault) = (vaultId, getOwnedVault(vaultId));
                _close(vaultId, vault, to, ink, art);
            
            } else if (operation == Operation.REPAY) {
                (bytes12 vaultId, address to, int128 ink, uint128 min) = abi.decode(data[i], (bytes12, address, int128, uint128));
                if (cachedId != vaultId) (cachedId, vault) = (vaultId, getOwnedVault(vaultId));
                _repay(vaultId, vault, to, ink, min);
            
            } else if (operation == Operation.REPAY_VAULT) {
                (bytes12 vaultId, address to, int128 ink, uint128 max) = abi.decode(data[i], (bytes12, address, int128, uint128));
                if (cachedId != vaultId) (cachedId, vault) = (vaultId, getOwnedVault(vaultId));
                _repayVault(vaultId, vault, to, ink, max);

            } else if (operation == Operation.REPAY_LADLE) {
                (bytes12 vaultId) = abi.decode(data[i], (bytes12));
                if (cachedId != vaultId) (cachedId, vault) = (vaultId, getOwnedVault(vaultId));
                _repayLadle(vaultId, vault);

            } else if (operation == Operation.RETRIEVE) {
                (bytes6 assetId, bool isAsset, address to) = abi.decode(data[i], (bytes6, bool, address));
                _retrieve(assetId, isAsset, to);

            } else if (operation == Operation.TRANSFER_TO_FYTOKEN) {
                (bytes6 seriesId, uint256 amount) = abi.decode(data[i], (bytes6, uint256));
                IFYToken fyToken = getSeries(seriesId).fyToken;
                _transferToFYToken(fyToken, amount);
            
            } else if (operation == Operation.REDEEM) {
                (bytes6 seriesId, address to, uint256 amount) = abi.decode(data[i], (bytes6, address, uint256));
                IFYToken fyToken = getSeries(seriesId).fyToken;
                _redeem(fyToken, to, amount);
            
            } else if (operation == Operation.STIR) {
                (bytes12 from, bytes12 to, uint128 ink, uint128 art) = abi.decode(data[i], (bytes12, bytes12, uint128, uint128));
                _stir(from, to, ink, art);  // Too complicated to use caching here
            
            } else if (operation == Operation.TWEAK) {
                (bytes12 vaultId, bytes6 seriesId, bytes6 ilkId) = abi.decode(data[i], (bytes12, bytes6, bytes6));
                if (cachedId != vaultId) (cachedId, vault) = (vaultId, getOwnedVault(vaultId));
                vault = _tweak(vaultId, seriesId, ilkId);

            } else if (operation == Operation.GIVE) {
                (bytes12 vaultId, address to) = abi.decode(data[i], (bytes12, address));
                if (cachedId != vaultId) (cachedId, vault) = (vaultId, getOwnedVault(vaultId));
                vault = _give(vaultId, to);
                delete vault;   // Clear the cache, since the vault doesn't necessarily belong to msg.sender anymore
                cachedId = bytes12(0);

            } else if (operation == Operation.DESTROY) {
                (bytes12 vaultId) = abi.decode(data[i], (bytes12));
                if (cachedId != vaultId) (cachedId, vault) = (vaultId, getOwnedVault(vaultId));
                _destroy(vaultId);
                delete vault;   // Clear the cache
                cachedId = bytes12(0);
            
            } else if (operation == Operation.MODULE) {
                (address module, bytes memory moduleCall) = abi.decode(data[i], (address, bytes));
                _moduleCall(module, moduleCall);
            
            }
        }
    }

    // ---- Vault management ----

    /// @dev Create a new vault, linked to a series (and therefore underlying) and a collateral
    function _build(bytes12 vaultId, bytes6 seriesId, bytes6 ilkId)
        private
        returns(DataTypes.Vault memory vault)
    {
        return cauldron.build(msg.sender, vaultId, seriesId, ilkId);
    }

    /// @dev Change a vault series or collateral.
    function _tweak(bytes12 vaultId, bytes6 seriesId, bytes6 ilkId)
        private
        returns(DataTypes.Vault memory vault)
    {
        // tweak checks that the series and the collateral both exist and that the collateral is approved for the series
        return cauldron.tweak(vaultId, seriesId, ilkId);
    }

    /// @dev Give a vault to another user.
    function _give(bytes12 vaultId, address receiver)
        private
        returns(DataTypes.Vault memory vault)
    {
        return cauldron.give(vaultId, receiver);
    }

    /// @dev Destroy an empty vault. Used to recover gas costs.
    function _destroy(bytes12 vaultId)
        private
    {
        cauldron.destroy(vaultId);
    }

    // ---- Asset and debt management ----

    /// @dev Move collateral and debt between vaults.
    function _stir(bytes12 from, bytes12 to, uint128 ink, uint128 art)
        private
        returns (DataTypes.Balances memory, DataTypes.Balances memory)
    {
        if (ink > 0) require (cauldron.vaults(from).owner == msg.sender, "Only origin vault owner");
        if (art > 0) require (cauldron.vaults(to).owner == msg.sender, "Only destination vault owner");
        return cauldron.stir(from, to, ink, art);
    }

    /// @dev Add collateral and borrow from vault, pull assets from and push borrowed asset to user
    /// Or, repay to vault and remove collateral, pull borrowed asset from and push assets to user
    /// Borrow only before maturity.
    function _pour(bytes12 vaultId, DataTypes.Vault memory vault, address to, int128 ink, int128 art)
        private
        returns (DataTypes.Balances memory balances)
    {
        DataTypes.Series memory series;
        if (art != 0) series = getSeries(vault.seriesId);

        int128 fee;
        if (art > 0) fee = ((series.maturity - block.timestamp) * uint256(int256(art)).wmul(borrowingFee)).u128().i128();

        // Update accounting
        balances = cauldron.pour(vaultId, ink, art + fee);

        // Manage collateral
        if (ink != 0) {
            IJoin ilkJoin = getJoin(vault.ilkId);
            if (ink > 0) ilkJoin.join(vault.owner, uint128(ink));
            if (ink < 0) ilkJoin.exit(to, uint128(-ink));
        }

        // Manage debt tokens
        if (art != 0) {
            if (art > 0) series.fyToken.mint(to, uint128(art));
            else series.fyToken.burn(msg.sender, uint128(-art));
        }
    }

    /// @dev Add collateral and borrow from vault, so that a precise amount of base is obtained by the user.
    /// The base is obtained by borrowing fyToken and buying base with it in a pool.
    /// Only before maturity.
    function _serve(bytes12 vaultId, DataTypes.Vault memory vault, address to, uint128 ink, uint128 base, uint128 max)
        private
        returns (DataTypes.Balances memory balances, uint128 art)
    {
        IPool pool = getPool(vault.seriesId);
        
        art = pool.buyBasePreview(base);
        balances = _pour(vaultId, vault, address(pool), ink.i128(), art.i128());
        pool.buyBase(to, base, max);
    }

    /// @dev Repay vault debt using underlying token at a 1:1 exchange rate, without trading in a pool.
    /// It can add or remove collateral at the same time.
    /// The debt to repay is denominated in fyToken, even if the tokens pulled from the user are underlying.
    /// The debt to repay must be entered as a negative number, as with `pour`.
    /// Debt cannot be acquired with this function.
    function _close(bytes12 vaultId, DataTypes.Vault memory vault, address to, int128 ink, int128 art)
        private
        returns (DataTypes.Balances memory balances)
    {
        require (art < 0, "Only repay debt");                                          // When repaying debt in `frob`, art is a negative value. Here is the same for consistency.

        // Calculate debt in fyToken terms
        DataTypes.Series memory series = getSeries(vault.seriesId);
        uint128 amt = _debtInBase(vault.seriesId, series, uint128(-art));

        // Update accounting
        balances = cauldron.pour(vaultId, ink, art);

        // Manage collateral
        if (ink != 0) {
            IJoin ilkJoin = getJoin(vault.ilkId);
            if (ink > 0) ilkJoin.join(vault.owner, uint128(ink));
            if (ink < 0) ilkJoin.exit(to, uint128(-ink));
        }

        // Manage underlying
        IJoin baseJoin = getJoin(series.baseId);
        baseJoin.join(msg.sender, amt);
    }

    /// @dev Calculate a debt amount for a series in base terms
    function _debtInBase(bytes6 seriesId, DataTypes.Series memory series, uint128 art)
        private
        returns (uint128 amt)
    {
        if (uint32(block.timestamp) >= series.maturity) {
            amt = uint256(art).wmul(cauldron.accrual(seriesId)).u128();
        } else {
            amt = art;
        }
    }

    /// @dev Repay debt by selling base in a pool and using the resulting fyToken
    /// The base tokens need to be already in the pool, unaccounted for.
    /// Only before maturity. After maturity use close.
    function _repay(bytes12 vaultId, DataTypes.Vault memory vault, address to, int128 ink, uint128 min)
        private
        returns (DataTypes.Balances memory balances, uint128 art)
    {
        DataTypes.Series memory series = getSeries(vault.seriesId);
        IPool pool = getPool(vault.seriesId);

        art = pool.sellBase(address(series.fyToken), min);
        balances = _pour(vaultId, vault, to, ink, -(art.i128()));
    }

    /// @dev Repay all debt in a vault by buying fyToken from a pool with base.
    /// The base tokens need to be already in the pool, unaccounted for. The surplus base will be returned to msg.sender.
    /// Only before maturity. After maturity use close.
    function _repayVault(bytes12 vaultId, DataTypes.Vault memory vault, address to, int128 ink, uint128 max)
        private
        returns (DataTypes.Balances memory balances, uint128 base)
    {
        DataTypes.Series memory series = getSeries(vault.seriesId);
        IPool pool = getPool(vault.seriesId);

        balances = cauldron.balances(vaultId);
        base = pool.buyFYToken(address(series.fyToken), balances.art, max);
        balances = _pour(vaultId, vault, to, ink, -(balances.art.i128()));
        pool.retrieveBase(msg.sender);
    }

    /// @dev Change series and debt of a vault.
    function _roll(bytes12 vaultId, DataTypes.Vault memory vault, bytes6 newSeriesId, uint8 loan, uint128 max)
        private
        returns (DataTypes.Vault memory, DataTypes.Balances memory)
    {
        DataTypes.Series memory series = getSeries(vault.seriesId);
        DataTypes.Series memory newSeries = getSeries(newSeriesId);
        DataTypes.Balances memory balances = cauldron.balances(vaultId);
        
        uint128 newDebt;
        {
            IPool pool = getPool(newSeriesId);
            IFYToken fyToken = IFYToken(newSeries.fyToken);
            IJoin baseJoin = getJoin(series.baseId);

            // Calculate debt in fyToken terms
            uint128 amt = _debtInBase(vault.seriesId, series, balances.art);

            // Mint fyToken to the pool, as a kind of flash loan
            fyToken.mint(address(pool), amt * loan);                // Loan is the size of the flash loan relative to the debt amount, 2 should be safe most of the time

            // Buy the base required to pay off the debt in series 1, and find out the debt in series 2
            newDebt = pool.buyBase(address(baseJoin), amt, max);
            baseJoin.join(address(baseJoin), amt);                  // Repay the old series debt

            pool.retrieveFYToken(address(fyToken));                 // Get the surplus fyToken
            fyToken.burn(address(fyToken), (amt * loan) - newDebt);    // Burn the surplus
        }

        newDebt += ((newSeries.maturity - block.timestamp) * uint256(newDebt).wmul(borrowingFee)).u128();  // Add borrowing fee, also stops users form rolling to a mature series

        return cauldron.roll(vaultId, newSeriesId, newDebt.i128() - balances.art.i128()); // Change the series and debt for the vault
    }

    /// @dev Remove liquidity in a pool and use proceedings to repay debt
    /// The liquidity tokens need to be already in the pool, unaccounted for.
    /// Only before maturity. TODO: After maturity
    /* function _removeAndRepay(bytes12 vaultId, DataTypes.Vault memory vault, address to, uint128 minBaseOut, uint128 minFYTokenOut)
        private
        returns (DataTypes.Balances memory balances)
    {
        DataTypes.Series memory series = getSeries(vault.seriesId);
        balances = cauldron.balances(vaultId);
        IPool pool = getPool(vault.seriesId);
        (, uint256 base, uint256 art) = pool.burn(address(this), minBaseOut, minFYTokenOut);

        uint256 repayment;

        // Update accounting
        if (balances.art > 0) {
            repayment = (art >= balances.art) ? balances.art : art;
            balances = cauldron.pour(vaultId, 0, -(repayment.u128().i128()));
            series.fyToken.burn(address(this), repayment);
        }
        
        // Return base
        IERC20 baseToken = IERC20(cauldron.assets(series.baseId));
        baseToken.safeTransfer(to, base);

        // Return fyToken
        if (art - repayment > 0) {
            IERC20 fyToken = IERC20(address(series.fyToken));
            fyToken.safeTransfer(to, art - repayment);
        }
    } */

    // ---- Ladle as a token holder ----

    /// @dev Use fyToken in the Ladle to repay debt.
    function _repayLadle(bytes12 vaultId, DataTypes.Vault memory vault)
        private
        returns (DataTypes.Balances memory balances)
    {
        DataTypes.Series memory series = getSeries(vault.seriesId);
        balances = cauldron.balances(vaultId);
        
        uint256 amount = series.fyToken.balanceOf(address(this));
        amount = amount <= balances.art ? amount : balances.art;

        // Update accounting
        balances = cauldron.pour(vaultId, 0, -(amount.u128().i128()));
        series.fyToken.burn(address(this), amount);
    }

    /// @dev Retrieve any asset or fyToken in the Ladle
    function _retrieve(bytes6 id, bool isAsset, address to) 
        private
        returns (uint256 amount)
    {
        IERC20 token = IERC20(findToken(id, isAsset));
        amount = token.balanceOf(address(this));
        token.safeTransfer(to, amount);
    }

    // ---- Liquidations ----

    /// @dev Allow liquidation contracts to move assets to wind down vaults
    function settle(bytes12 vaultId, address user, uint128 ink, uint128 art)
        external
        auth
    {
        DataTypes.Vault memory vault = getOwnedVault(vaultId);
        DataTypes.Series memory series = getSeries(vault.seriesId);

        cauldron.slurp(vaultId, ink, art);                                                  // Remove debt and collateral from the vault

        if (ink != 0) {                                                                     // Give collateral to the user
            IJoin ilkJoin = getJoin(vault.ilkId);
            ilkJoin.exit(user, ink);
        }
        if (art != 0) {                                                                     // Take underlying from user
            IJoin baseJoin = getJoin(series.baseId);
            baseJoin.join(user, art);
        }
    }

    // ---- Permit management ----

    /// @dev From an id, which can be an assetId or a seriesId, find the resulting asset or fyToken
    function findToken(bytes6 id, bool isAsset)
        private view returns (address token)
    {
        token = isAsset ? cauldron.assets(id) : address(getSeries(id).fyToken);
        require (token != address(0), "Token not found");
    }

    /// @dev Execute an ERC2612 permit for the selected asset or fyToken
    function _forwardPermit(bytes6 id, bool isAsset, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        private
    {
        IERC2612 token = IERC2612(findToken(id, isAsset));
        token.permit(msg.sender, spender, amount, deadline, v, r, s);
    }

    /// @dev Execute a Dai-style permit for the selected asset or fyToken
    function _forwardDaiPermit(bytes6 id, bool isAsset, address spender, uint256 nonce, uint256 deadline, bool allowed, uint8 v, bytes32 r, bytes32 s)
        private
    {
        DaiAbstract token = DaiAbstract(findToken(id, isAsset));
        token.permit(msg.sender, spender, nonce, deadline, allowed, v, r, s);
    }

    // ---- Ether management ----

    /// @dev The WETH9 contract will send ether to BorrowProxy on `weth.withdraw` using this function.
    receive() external payable { }

    /// @dev Accept Ether, wrap it and forward it to the WethJoin
    /// This function should be called first in a batch, and the Join should keep track of stored reserves
    /// Passing the id for a join that doesn't link to a contract implemnting IWETH9 will fail
    function _joinEther(bytes6 etherId)
        private
        returns (uint256 ethTransferred)
    {
        ethTransferred = address(this).balance;
        IJoin wethJoin = getJoin(etherId);
        weth.deposit{ value: ethTransferred }();   // TODO: Test gas savings using WETH10 `depositTo`
        IERC20(address(weth)).safeTransfer(address(wethJoin), ethTransferred);
    }

    /// @dev Unwrap Wrapped Ether held by this Ladle, and send the Ether
    /// This function should be called last in a batch, and the Ladle should have no reason to keep an WETH balance
    function _exitEther(address payable to)
        private
        returns (uint256 ethTransferred)
    {
        ethTransferred = weth.balanceOf(address(this));
        weth.withdraw(ethTransferred);   // TODO: Test gas savings using WETH10 `withdrawTo`
        to.safeTransferETH(ethTransferred);
    }

    // ---- Pool router ----

    /// @dev Allow users to trigger a token transfer to a pool through the ladle, to be used with batch
    function _transferToPool(IPool pool, bool base, uint128 wad)
        private
    {
        IERC20 token = base ? pool.base() : pool.fyToken();
        token.safeTransferFrom(msg.sender, address(pool), wad);
    }

    /// @dev Allow users to route calls to a pool, to be used with batch
    function _route(IPool pool, bytes memory data)
        private
        returns (bool success, bytes memory result)
    {
        (success, result) = address(pool).call(data);
        if (!success) revert(RevertMsgExtractor.getRevertMsg(result));
    }

    // ---- FYToken router ----

    /// @dev Allow users to trigger a token transfer to a pool through the ladle, to be used with batch
    function _transferToFYToken(IFYToken fyToken, uint256 wad)
        private
    {
        IERC20(fyToken).safeTransferFrom(msg.sender, address(fyToken), wad);
    }

    /// @dev Allow users to redeem fyToken, to be used with batch.
    /// If 0 is passed as the amount to redeem, it redeems the fyToken balance of the Ladle instead.
    function _redeem(IFYToken fyToken, address to, uint256 wad)
        private
        returns (uint256)
    {
        return fyToken.redeem(to, wad != 0 ? wad : fyToken.balanceOf(address(this)));
    }

    // ---- Module router ----

    /// @dev Allow users to use functionality coded in a module, to be used with batch
    function _moduleCall(address module, bytes memory moduleCall)
        private
        returns (bool success, bytes memory result)
    {
        require (modules[module], "Unregistered module");
        (success, result) = module.delegatecall(moduleCall);
        if (!success) revert(RevertMsgExtractor.getRevertMsg(result));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@yield-protocol/utils-v2/contracts/access/AccessControl.sol";
import "@yield-protocol/vault-interfaces/ILadle.sol";
import "@yield-protocol/vault-interfaces/ICauldron.sol";
import "@yield-protocol/vault-interfaces/DataTypes.sol";
import "./math/WMul.sol";
import "./math/WDiv.sol";
import "./math/WDivUp.sol";
import "./math/CastU256U128.sol";


contract Witch is AccessControl() {
    using WMul for uint256;
    using WDiv for uint256;
    using WDivUp for uint256;
    using CastU256U128 for uint256;

    event AuctionTimeSet(uint128 indexed auctionTime);
    event InitialProportionSet(uint128 indexed initialProportion);
    event Bought(bytes12 indexed vaultId, address indexed buyer, uint256 ink, uint256 art);
  
    uint128 public auctionTime = 4 * 60 * 60; // Time that auctions take to go to minimal price and stay there.
    uint128 public initialProportion = 5e17;  // Proportion of collateral that is sold at auction start.

    ICauldron immutable public cauldron;
    ILadle immutable public ladle;
    mapping(bytes12 => address) public vaultOwners;

    constructor (ICauldron cauldron_, ILadle ladle_) {
        cauldron = cauldron_;
        ladle = ladle_;
    }

    /// @dev Set the auction time to calculate liquidation prices
    function setAuctionTime(uint128 auctionTime_) public auth {
        auctionTime = auctionTime_;
        emit AuctionTimeSet(auctionTime_);
    }

    /// @dev Set the proportion of the collateral that will be sold at auction start
    function setInitialProportion(uint128 initialProportion_) public auth {
        require (initialProportion_ <= 1e18, "Only at or under 100%");
        initialProportion = initialProportion_;
        emit InitialProportionSet(initialProportion_);
    }

    /// @dev Put an undercollateralized vault up for liquidation.
    function grab(bytes12 vaultId) public {
        DataTypes.Vault memory vault = cauldron.vaults(vaultId);
        vaultOwners[vaultId] = vault.owner;
        cauldron.grab(vaultId, address(this));
    }

    /// @dev Buy an amount of collateral off a vault in liquidation, paying at most `max` underlying.
    function buy(bytes12 vaultId, uint128 art, uint128 min) public {
        DataTypes.Balances memory balances_ = cauldron.balances(vaultId);

        require (balances_.art > 0, "Nothing to buy");                                      // Cheapest way of failing gracefully if given a non existing vault
        uint256 elapsed = uint32(block.timestamp) - cauldron.auctions(vaultId);           // Auctions will malfunction on the 7th of February 2106, at 06:28:16 GMT, we should replace this contract before then.
        uint256 price;
        {
            // Price of a collateral unit, in underlying, at the present moment, for a given vault
            //
            //                ink                     min(auction, elapsed)
            // price = 1 / (------- * (p + (1 - p) * -----------------------))
            //                art                          auction
            (uint256 auctionTime_, uint256 initialProportion_) = (auctionTime, initialProportion);
            uint256 term1 = uint256(balances_.ink).wdiv(balances_.art);
            uint256 dividend2 = auctionTime_ < elapsed ? auctionTime_ : elapsed;
            uint256 divisor2 = auctionTime_;
            uint256 term2 = initialProportion_ + (1e18 - initialProportion_).wmul(dividend2.wdiv(divisor2));
            price = uint256(1e18).wdiv(term1.wmul(term2));
        }
        uint256 ink = uint256(art).wdivup(price);                                                    // Calculate collateral to sell. Using divdrup stops rounding from leaving 1 stray wei in vaults.
        require (ink >= min, "Not enough bought");

        ladle.settle(vaultId, msg.sender, ink.u128(), art);                                        // Move the assets
        if (balances_.art - art == 0) {                                                             // If there is no debt left, return the vault with the collateral to the owner
            cauldron.give(vaultId, vaultOwners[vaultId]);
            delete vaultOwners[vaultId];
        }

        emit Bought(vaultId, msg.sender, ink, art);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "@yield-protocol/vault-interfaces/ICauldronGov.sol";
import "@yield-protocol/vault-interfaces/ILadleGov.sol";
import "@yield-protocol/vault-interfaces/IMultiOracleGov.sol";
import "@yield-protocol/vault-interfaces/IJoinFactory.sol";
import "@yield-protocol/vault-interfaces/IJoin.sol";
import "@yield-protocol/vault-interfaces/DataTypes.sol";
import "@yield-protocol/yieldspace-interfaces/IPoolFactory.sol";
import "@yield-protocol/utils-v2/contracts/access/AccessControl.sol";
import "./FYToken.sol";


interface IOwnable {
    function transferOwnership(address) external;
}

/// @dev Ladle orchestrates contract calls throughout the Yield Protocol v2 into useful and efficient governance features.
contract Wand is AccessControl {

    bytes4 public constant JOIN = bytes4(keccak256("join(address,uint128)"));
    bytes4 public constant EXIT = bytes4(keccak256("exit(address,uint128)"));
    bytes4 public constant MINT = bytes4(keccak256("mint(address,uint256)"));
    bytes4 public constant BURN = bytes4(keccak256("burn(address,uint256)"));
    
    bytes6 public constant CHI = "chi";
    bytes6 public constant RATE = "rate";

    ICauldronGov public immutable cauldron;
    ILadleGov public immutable ladle;
    IPoolFactory public immutable poolFactory;
    IJoinFactory public immutable joinFactory;

    constructor (ICauldronGov cauldron_, ILadleGov ladle_, IPoolFactory poolFactory_, IJoinFactory joinFactory_) {
        cauldron = cauldron_;
        ladle = ladle_;
        poolFactory = poolFactory_;
        joinFactory = joinFactory_;
    }

    /// @dev Add an existing asset to the protocol, meaning:
    ///  - Add the asset to the cauldron
    ///  - Deploy a new Join, and integrate it with the Ladle
    ///  - If the asset is a base, integrate its rate source
    ///  - If the asset is a base, integrate a spot source and set a debt ceiling for any provided ilks
    function addAsset(
        bytes6 assetId,
        address asset
    ) public auth {
        // Add asset to cauldron, deploy new Join, and add it to the ladle
        require (address(asset) != address(0), "Asset required");
        cauldron.addAsset(assetId, asset);
        AccessControl join = AccessControl(joinFactory.createJoin(asset));  // We need the access control methods of Join
        bytes4[] memory sigs = new bytes4[](2);
        sigs[0] = JOIN;
        sigs[1] = EXIT;
        join.grantRoles(sigs, address(ladle));
        join.grantRole(join.ROOT(), msg.sender);
        // join.renounceRole(join.ROOT(), address(this));  // If Wand gives up ownership it can't create fyToken
        ladle.addJoin(assetId, address(join));
    }

    /// @dev Make a base asset out of a generic asset, by adding rate and chi oracles.
    /// This assumes CompoundMultiOracles, which deliver both rate and chi.
    function makeBase(bytes6 assetId, IMultiOracleGov oracle, address rateSource, address chiSource) public auth {
        require (address(oracle) != address(0), "Oracle required");
        require (rateSource != address(0), "Rate source required");
        require (chiSource != address(0), "Chi source required");

        oracle.setSource(assetId, RATE, rateSource);
        oracle.setSource(assetId, CHI, chiSource);
        cauldron.setRateOracle(assetId, IOracle(address(oracle))); // TODO: Consider adding a registry of chi oracles in cauldron as well
    }

    /// @dev Make an ilk asset out of a generic asset, by adding a spot oracle against a base asset, collateralization ratio, and debt ceiling.
    function makeIlk(bytes6 baseId, bytes6 ilkId, IMultiOracleGov oracle, address spotSource, uint32 ratio, uint96 max, uint24 min, uint8 dec) public auth {
        oracle.setSource(baseId, ilkId, spotSource);
        cauldron.setSpotOracle(baseId, ilkId, IOracle(address(oracle)), ratio);
        cauldron.setDebtLimits(baseId, ilkId, max, min, dec);
    }

    /// @dev Add an existing series to the protocol, by deploying a FYToken, and registering it in the cauldron with the approved ilks
    /// This must be followed by a call to addPool
    function addSeries(
        bytes6 seriesId,
        bytes6 baseId,
        uint32 maturity,
        bytes6[] memory ilkIds,
        string memory name,
        string memory symbol
    ) public auth {
        address base = cauldron.assets(baseId);
        require(base != address(0), "Base not found");

        IJoin baseJoin = ladle.joins(baseId);
        require(address(baseJoin) != address(0), "Join not found");

        IOracle oracle = cauldron.rateOracles(baseId);
        require(address(oracle) != address(0), "Chi oracle not found");

        FYToken fyToken = new FYToken(
            baseId,
            oracle,
            baseJoin,
            maturity,
            name,     // Derive from base and maturity, perhaps
            symbol    // Derive from base and maturity, perhaps
        ); // TODO: Use a FYTokenFactory to make Wand deployable at 20000 runs

        // Allow the fyToken to pull from the base join for redemption
        bytes4[] memory sigs = new bytes4[](1);
        sigs[0] = EXIT;
        AccessControl(address(baseJoin)).grantRoles(sigs, address(fyToken));

        // Allow the ladle to issue and cancel fyToken
        sigs = new bytes4[](2);
        sigs[0] = MINT;
        sigs[1] = BURN;
        fyToken.grantRoles(sigs, address(ladle));

        // Pass ownership of the fyToken to msg.sender
        fyToken.grantRole(fyToken.ROOT(), msg.sender);
        fyToken.renounceRole(fyToken.ROOT(), address(this));

        // Add fyToken/series to the Cauldron and approve ilks for the series
        cauldron.addSeries(seriesId, baseId, fyToken);
        cauldron.addIlks(seriesId, ilkIds);

        // Create the pool for the base and fyToken
        poolFactory.createPool(base, address(fyToken));
        IOwnable pool = IOwnable(poolFactory.calculatePoolAddress(base, address(fyToken)));
        

        // Pass ownership of pool to msg.sender
        pool.transferOwnership(msg.sender);

        // Register pool in Ladle
        ladle.addPool(seriesId, address(pool));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.8.0;

import "@yield-protocol/utils-v2/contracts/access/Ownable.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC20Metadata.sol";
import "@yield-protocol/utils-v2/contracts/token/ERC20Permit.sol";
import "@yield-protocol/utils-v2/contracts/token/SafeERC20Namer.sol";
import "@yield-protocol/utils-v2/contracts/token/TransferHelper.sol";
import "@yield-protocol/yieldspace-interfaces/IPool.sol";
import "@yield-protocol/yieldspace-interfaces/IPoolFactory.sol";
import "@yield-protocol/vault-interfaces/IFYToken.sol";
import "./YieldMath.sol";


library SafeCast256 {
    /// @dev Safely cast an uint256 to an uint112
    function u112(uint256 x) internal pure returns (uint112 y) {
        require (x <= type(uint112).max, "Cast overflow");
        y = uint112(x);
    }

    /// @dev Safely cast an uint256 to an uint128
    function u128(uint256 x) internal pure returns (uint128 y) {
        require (x <= type(uint128).max, "Cast overflow");
        y = uint128(x);
    }

    /// @dev Safe casting from uint256 to int256
    function i256(uint256 x) internal pure returns(int256) {
        require(x <= uint256(type(int256).max), "Cast overflow");
        return int256(x);
    }
}

library SafeCast128 {
    /// @dev Safely cast an uint128 to an int128
    function i128(uint128 x) internal pure returns (int128 y) {
        require (x <= uint128(type(int128).max), "Cast overflow");
        y = int128(x);
    }

    /// @dev Safely cast an uint128 to an uint112
    function u112(uint128 x) internal pure returns (uint112 y) {
        require (x <= uint128(type(uint112).max), "Cast overflow");
        y = uint112(x);
    }
}


/// @dev The Pool contract exchanges base for fyToken at a price defined by a specific formula.
contract Pool is IPool, ERC20Permit, Ownable {
    using SafeCast256 for uint256;
    using SafeCast128 for uint128;
    using TransferHelper for IERC20;

    event Trade(uint32 maturity, address indexed from, address indexed to, int256 bases, int256 fyTokens);
    event Liquidity(uint32 maturity, address indexed from, address indexed to, int256 bases, int256 fyTokens, int256 poolTokens);
    event Sync(uint112 baseCached, uint112 fyTokenCached, uint256 cumulativeBalancesRatio);
    event ParameterSet(bytes32 parameter, int128 k);

    int128 private k1 = int128(uint128(uint256((1 << 64))) / 315576000); // 1 / Seconds in 10 years, in 64.64
    int128 private g1 = int128(uint128(uint256((950 << 64))) / 1000); // To be used when selling base to the pool. All constants are `ufixed`, to divide them they must be converted to uint256
    int128 private k2 = int128(uint128(uint256((1 << 64))) / 315576000); // k is stored twice to be able to recover with 1 SLOAD alongside both g1 and g2
    int128 private g2 = int128(uint128(uint256((1000 << 64))) / 950); // To be used when selling fyToken to the pool. All constants are `ufixed`, to divide them they must be converted to uint256
    uint32 public immutable override maturity;

    IERC20 public immutable override base;
    IFYToken public immutable override fyToken;

    uint112 private baseCached;              // uses single storage slot, accessible via getCache
    uint112 private fyTokenCached;           // uses single storage slot, accessible via getCache
    uint32  private blockTimestampLast;             // uses single storage slot, accessible via getCache

    uint256 public cumulativeBalancesRatio;

    constructor()
        ERC20Permit(
            string(abi.encodePacked("Yield ", SafeERC20Namer.tokenName(IPoolFactory(msg.sender).nextFYToken()), " LP Token")),
            string(abi.encodePacked(SafeERC20Namer.tokenSymbol(IPoolFactory(msg.sender).nextFYToken()), "LP")),
            SafeERC20Namer.tokenDecimals(IPoolFactory(msg.sender).nextBase())
        )
    {
        IFYToken _fyToken = IFYToken(IPoolFactory(msg.sender).nextFYToken());
        fyToken = _fyToken;
        base = IERC20(IPoolFactory(msg.sender).nextBase());

        uint256 _maturity = _fyToken.maturity();
        require (_maturity <= type(uint32).max, "Pool: Maturity too far in the future");
        maturity = uint32(_maturity);
    }

    /// @dev Trading can only be done before maturity
    modifier beforeMaturity() {
        require(
            block.timestamp < maturity,
            "Pool: Too late"
        );
        _;
    }

    // ---- Administration ----

    /// @dev Set the k, g1 or g2 parameters
    function setParameter(bytes32 parameter, int128 value) public onlyOwner {
        if (parameter == "k") k1 = k2 = value;
        else if (parameter == "g1") g1 = value;
        else if (parameter == "g2") g2 = value;
        else revert("Pool: Unrecognized parameter");
        emit ParameterSet(parameter, value);
    }

    /// @dev Get k
    function getK() public view returns (int128) {
        assert(k1 == k2);
        return k1;
    }

    /// @dev Get g1
    function getG1() public view returns (int128) {
        return g1;
    }

    /// @dev Get g2
    function getG2() public view returns (int128) {
        return g2;
    }

    // ---- Balances management ----

    /// @dev Updates the cache to match the actual balances.
    function sync() external {
        _update(getBaseBalance(), getFYTokenBalance(), baseCached, fyTokenCached);
    }

    /// @dev Returns the cached balances & last updated timestamp.
    /// @return Cached base token balance.
    /// @return Cached virtual FY token balance.
    /// @return Timestamp that balances were last cached.
    function getCache() public view returns (uint112, uint112, uint32) {
        return (baseCached, fyTokenCached, blockTimestampLast);
    }

    /// @dev Returns the "virtual" fyToken balance, which is the real balance plus the pool token supply.
    function getFYTokenBalance()
        public view override
        returns(uint112)
    {
        return (fyToken.balanceOf(address(this)) + _totalSupply).u112();
    }

    /// @dev Returns the base balance
    function getBaseBalance()
        public view override
        returns(uint112)
    {
        return base.balanceOf(address(this)).u112();
    }

    /// @dev Retrieve any base tokens not accounted for in the cache
    function retrieveBase(address to)
        external override
        returns(uint128 retrieved)
    {
        retrieved = getBaseBalance() - baseCached; // Cache can never be above balances
        base.safeTransfer(to, retrieved);
        // Now the current balances match the cache, so no need to update the TWAR
    }

    /// @dev Retrieve any fyTokens not accounted for in the cache
    function retrieveFYToken(address to)
        external override
        returns(uint128 retrieved)
    {
        retrieved = getFYTokenBalance() - fyTokenCached; // Cache can never be above balances
        IERC20(address(fyToken)).safeTransfer(to, retrieved);
        // Now the balances match the cache, so no need to update the TWAR
    }

    /// @dev Update cache and, on the first call per block, ratio accumulators
    function _update(uint128 baseBalance, uint128 fyBalance, uint112 _baseCached, uint112 _fyTokenCached) private {
        uint32 blockTimestamp = uint32(block.timestamp);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _baseCached != 0 && _fyTokenCached != 0) {
            uint256 scaledFYTokenCached = uint256(_fyTokenCached) * 1e27;
            cumulativeBalancesRatio += scaledFYTokenCached / _baseCached * timeElapsed;
        }
        baseCached = baseBalance.u112();
        fyTokenCached = fyBalance.u112();
        blockTimestampLast = blockTimestamp;
        emit Sync(baseCached, fyTokenCached, cumulativeBalancesRatio);
    }

    // ---- Liquidity ----

    /// @dev Mint liquidity tokens in exchange for adding base and fyToken
    /// The amount of liquidity tokens to mint is calculated from the amount of unaccounted for base tokens in this contract.
    /// A proportional amount of fyTokens needs to be present in this contract, also unaccounted for.
    /// @param to Wallet receiving the minted liquidity tokens.
    /// @param calculateFromBase Calculate the amount of tokens to mint from the base tokens available, leaving a fyToken surplus.
    /// @param minTokensMinted Minimum amount of liquidity tokens received.
    /// @return The amount of liquidity tokens minted.
    function mint(address to, bool calculateFromBase, uint256 minTokensMinted)
        external override
        returns (uint256, uint256, uint256)
    {
        return _mintInternal(to, calculateFromBase, 0, minTokensMinted);
    }

    /// @dev Mint liquidity tokens in exchange for adding only base
    /// The amount of liquidity tokens is calculated from the amount of fyToken to buy from the pool.
    /// The base tokens need to be present in this contract, unaccounted for.
    /// @param to Wallet receiving the minted liquidity tokens.
    /// @param fyTokenToBuy Amount of `fyToken` being bought in the Pool, from this we calculate how much base it will be taken in.
    /// @param minTokensMinted Minimum amount of liquidity tokens received.
    /// @return The amount of liquidity tokens minted.
    function mintWithBase(address to, uint256 fyTokenToBuy, uint256 minTokensMinted)
        external override
        returns (uint256, uint256, uint256)
    {
        return _mintInternal(to, false, fyTokenToBuy, minTokensMinted);
    }

    /// @dev Mint liquidity tokens in exchange for adding only base, if fyTokenToBuy > 0.
    /// If fyTokenToBuy == 0, mint liquidity tokens for both basea and fyToken.
    /// @param to Wallet receiving the minted liquidity tokens.
    /// @param calculateFromBase Calculate the amount of tokens to mint from the base tokens available, leaving a fyToken surplus.
    /// @param fyTokenToBuy Amount of `fyToken` being bought in the Pool, from this we calculate how much base it will be taken in.
    /// @param minTokensMinted Minimum amount of liquidity tokens received.
    /// @return The amount of liquidity tokens minted.
    function _mintInternal(address to, bool calculateFromBase, uint256 fyTokenToBuy, uint256 minTokensMinted)
        internal
        returns (uint256, uint256, uint256)
    {
        // Gather data
        uint256 supply = _totalSupply;
        (uint112 _baseCached, uint112 _fyTokenCached) =
            (baseCached, fyTokenCached);
        uint256 _realFYTokenCached = _fyTokenCached - supply;    // The fyToken cache includes the virtual fyToken, equal to the supply

        // Calculate trade
        uint256 tokensMinted;
        uint256 baseIn;
        uint256 baseReturned;
        uint256 fyTokenIn;

        if (supply == 0) {
            require (calculateFromBase && fyTokenToBuy == 0, "Pool: Initialize only from base");
            baseIn = base.balanceOf(address(this)) - _baseCached;
            tokensMinted = baseIn;   // If supply == 0 we are initializing the pool and tokensMinted == baseIn; fyTokenIn == 0
        } else {
            // There is an optional virtual trade before the mint
            uint256 baseToSell;
            if (fyTokenToBuy > 0) {     // calculateFromBase == true and fyTokenToBuy > 0 can't happen in this implementation. To implement a virtual trade and calculateFromBase the trade would need to be a BaseToBuy parameter.
                baseToSell = _buyFYTokenPreview(
                    fyTokenToBuy.u128(),
                    _baseCached,
                    _fyTokenCached
                ); 
            }

            if (calculateFromBase) {   // We use all the available base tokens, surplus is in fyTokens
                baseIn = base.balanceOf(address(this)) - _baseCached;
                tokensMinted = (supply * baseIn) / _baseCached;
                fyTokenIn = (_realFYTokenCached * tokensMinted) / supply;
                require(_realFYTokenCached + fyTokenIn <= fyToken.balanceOf(address(this)), "Pool: Not enough fyToken in");
            } else {                   // We use all the available fyTokens, plus a virtual trade if it happened, surplus is in base tokens
                fyTokenIn = fyToken.balanceOf(address(this)) - _realFYTokenCached;
                tokensMinted = (supply * (fyTokenToBuy + fyTokenIn)) / (_realFYTokenCached - fyTokenToBuy);
                baseIn = baseToSell + ((_baseCached + baseToSell) * tokensMinted) / supply;
                uint256 _baseBalance = base.balanceOf(address(this));
                require(_baseBalance - _baseCached >= baseIn, "Pool: Not enough base token in");
                
                // If we did a trade means we came in through `mintWithBase`, and want to return the base token surplus
                if (fyTokenToBuy > 0) baseReturned = (_baseBalance - _baseCached) - baseIn;
            }
        }

        // Slippage
        require (tokensMinted >= minTokensMinted, "Pool: Not enough tokens minted");

        // Update TWAR
        _update(
            (_baseCached + baseIn).u128(),
            (_fyTokenCached + fyTokenIn + tokensMinted).u128(), // Account for the "virtual" fyToken from the new minted LP tokens
            _baseCached,
            _fyTokenCached
        );

        // Execute mint
        _mint(to, tokensMinted);

        // Return any unused base if we did a trade, meaning slippage was involved.
        if (supply > 0 && fyTokenToBuy > 0) base.safeTransfer(to, baseReturned);

        emit Liquidity(maturity, msg.sender, to, -(baseIn.i256()), -(fyTokenIn.i256()), tokensMinted.i256());
        return (baseIn, fyTokenIn, tokensMinted);
    }

    /// @dev Burn liquidity tokens in exchange for base and fyToken.
    /// The liquidity tokens need to be in this contract.
    /// @param to Wallet receiving the base and fyToken.
    /// @return The amount of tokens burned and returned (tokensBurned, bases, fyTokens).
    function burn(address to, uint256 minBaseOut, uint256 minFYTokenOut)
        external override
        returns (uint256, uint256, uint256)
    {
        return _burnInternal(to, false, minBaseOut, minFYTokenOut);
    }

    /// @dev Burn liquidity tokens in exchange for base.
    /// The liquidity provider needs to have called `pool.approve`.
    /// @param to Wallet receiving the base and fyToken.
    /// @return tokensBurned The amount of lp tokens burned.
    /// @return baseOut The amount of base tokens returned.
    function burnForBase(address to, uint256 minBaseOut)
        external override
        returns (uint256 tokensBurned, uint256 baseOut)
    {
        (tokensBurned, baseOut, ) = _burnInternal(to, true, minBaseOut, 0);
    }


    /// @dev Burn liquidity tokens in exchange for base.
    /// The liquidity provider needs to have called `pool.approve`.
    /// @param to Wallet receiving the base and fyToken.
    /// @param tradeToBase Whether the resulting fyToken should be traded for base tokens.
    /// @return The amount of base tokens returned.
    function _burnInternal(address to, bool tradeToBase, uint256 minBaseOut, uint256 minFYTokenOut)
        internal
        returns (uint256, uint256, uint256)
    {
        
        uint256 tokensBurned = _balanceOf[address(this)];
        uint256 supply = _totalSupply;
        uint256 fyTokenBalance = fyToken.balanceOf(address(this));          // use the real balance rather than the virtual one
        uint256 baseBalance = base.balanceOf(address(this));
        (uint112 _baseCached, uint112 _fyTokenCached) =
            (baseCached, fyTokenCached);

        // Calculate trade
        uint256 tokenOut = (tokensBurned * baseBalance) / supply;
        uint256 fyTokenOut = (tokensBurned * fyTokenBalance) / supply;

        if (tradeToBase) {
            (int128 _k, int128 _g2) = (k2, g2);
            tokenOut += YieldMath.baseOutForFYTokenIn(                      // This is a virtual sell
                _baseCached - tokenOut.u128(),                              // Cache, minus virtual burn
                _fyTokenCached - fyTokenOut.u128(),                         // Cache, minus virtual burn
                fyTokenOut.u128(),                                          // Sell the virtual fyToken obtained
                maturity - uint32(block.timestamp),                         // This can't be called after maturity
                _k,
                _g2
            );
            fyTokenOut = 0;
        }

        // Slippage
        require (tokenOut >= minBaseOut, "Pool: Not enough base tokens obtained");
        require (fyTokenOut >= minFYTokenOut, "Pool: Not enough fyToken obtained");

        // Update TWAR
        _update(
            (baseBalance - tokenOut).u128(),
            (fyTokenBalance - fyTokenOut + supply - tokensBurned).u128(),
            _baseCached,
            _fyTokenCached
        );

        // Transfer assets
        _burn(address(this), tokensBurned);
        base.safeTransfer(to, tokenOut);
        if (fyTokenOut > 0) IERC20(address(fyToken)).safeTransfer(to, fyTokenOut);

        emit Liquidity(maturity, msg.sender, to, tokenOut.i256(), fyTokenOut.i256(), -(tokensBurned.i256()));
        return (tokensBurned, tokenOut, 0);
    }

    // ---- Trading ----

    /// @dev Sell base for fyToken.
    /// The trader needs to have transferred the amount of base to sell to the pool before in the same transaction.
    /// @param to Wallet receiving the fyToken being bought
    /// @param min Minimm accepted amount of fyToken
    /// @return Amount of fyToken that will be deposited on `to` wallet
    function sellBase(address to, uint128 min)
        external override
        returns(uint128)
    {
        // Calculate trade
        (uint112 _baseCached, uint112 _fyTokenCached) =
            (baseCached, fyTokenCached);
        uint112 _baseBalance = getBaseBalance();
        uint112 _fyTokenBalance = getFYTokenBalance();
        uint128 baseIn = _baseBalance - _baseCached;
        uint128 fyTokenOut = _sellBasePreview(
            baseIn,
            _baseCached,
            _fyTokenBalance
        );

        // Slippage check
        require(
            fyTokenOut >= min,
            "Pool: Not enough fyToken obtained"
        );

        // Update TWAR
        _update(
            _baseBalance,
            _fyTokenBalance - fyTokenOut,
            _baseCached,
            _fyTokenCached
        );

        // Transfer assets
        IERC20(address(fyToken)).safeTransfer(to, fyTokenOut);

        emit Trade(maturity, msg.sender, to, -(baseIn.i128()), fyTokenOut.i128());
        return fyTokenOut;
    }

    /// @dev Returns how much fyToken would be obtained by selling `baseIn` base
    /// @param baseIn Amount of base hypothetically sold.
    /// @return Amount of fyToken hypothetically bought.
    function sellBasePreview(uint128 baseIn)
        external view override
        returns(uint128)
    {
        (uint112 _baseCached, uint112 _fyTokenCached) =
            (baseCached, fyTokenCached);
        return _sellBasePreview(baseIn, _baseCached, _fyTokenCached);
    }

    /// @dev Returns how much fyToken would be obtained by selling `baseIn` base
    function _sellBasePreview(
        uint128 baseIn,
        uint112 baseBalance,
        uint112 fyTokenBalance
    )
        private view
        beforeMaturity
        returns(uint128)
    {
        (int128 _k, int128 _g1) = (k1, g1);
        uint128 fyTokenOut = YieldMath.fyTokenOutForBaseIn(
            baseBalance,
            fyTokenBalance,
            baseIn,
            maturity - uint32(block.timestamp),             // This can't be called after maturity
            _k,
            _g1
        );

        require(
            fyTokenBalance - fyTokenOut >= baseBalance + baseIn,
            "Pool: fyToken balance too low"
        );

        return fyTokenOut;
    }

    /// @dev Buy base for fyToken
    /// The trader needs to have called `fyToken.approve`
    /// @param to Wallet receiving the base being bought
    /// @param tokenOut Amount of base being bought that will be deposited in `to` wallet
    /// @param max Maximum amount of fyToken that will be paid for the trade
    /// @return Amount of fyToken that will be taken from caller
    function buyBase(address to, uint128 tokenOut, uint128 max)
        external override
        returns(uint128)
    {
        // Calculate trade
        uint128 fyTokenBalance = getFYTokenBalance();
        (uint112 _baseCached, uint112 _fyTokenCached) =
            (baseCached, fyTokenCached);
        uint128 fyTokenIn = _buyBasePreview(
            tokenOut,
            _baseCached,
            _fyTokenCached
        );
        require(
            fyTokenBalance - _fyTokenCached >= fyTokenIn,
            "Pool: Not enough fyToken in"
        );

        // Slippage check
        require(
            fyTokenIn <= max,
            "Pool: Too much fyToken in"
        );

        // Update TWAR
        _update(
            _baseCached - tokenOut,
            _fyTokenCached + fyTokenIn,
            _baseCached,
            _fyTokenCached
        );

        // Transfer assets
        base.safeTransfer(to, tokenOut);

        emit Trade(maturity, msg.sender, to, tokenOut.i128(), -(fyTokenIn.i128()));
        return fyTokenIn;
    }

    /// @dev Returns how much fyToken would be required to buy `tokenOut` base.
    /// @param tokenOut Amount of base hypothetically desired.
    /// @return Amount of fyToken hypothetically required.
    function buyBasePreview(uint128 tokenOut)
        external view override
        returns(uint128)
    {
        (uint112 _baseCached, uint112 _fyTokenCached) =
            (baseCached, fyTokenCached);
        return _buyBasePreview(tokenOut, _baseCached, _fyTokenCached);
    }

    /// @dev Returns how much fyToken would be required to buy `tokenOut` base.
    function _buyBasePreview(
        uint128 tokenOut,
        uint112 baseBalance,
        uint112 fyTokenBalance
    )
        private view
        beforeMaturity
        returns(uint128)
    {
        (int128 _k, int128 _g2) = (k2, g2);
        return YieldMath.fyTokenInForBaseOut(
            baseBalance,
            fyTokenBalance,
            tokenOut,
            maturity - uint32(block.timestamp),             // This can't be called after maturity
            _k,
            _g2
        );
    }

    /// @dev Sell fyToken for base
    /// The trader needs to have transferred the amount of fyToken to sell to the pool before in the same transaction.
    /// @param to Wallet receiving the base being bought
    /// @param min Minimm accepted amount of base
    /// @return Amount of base that will be deposited on `to` wallet
    function sellFYToken(address to, uint128 min)
        external override
        returns(uint128)
    {
        // Calculate trade
        (uint112 _baseCached, uint112 _fyTokenCached) =
            (baseCached, fyTokenCached);
        uint112 _fyTokenBalance = getFYTokenBalance();
        uint112 _baseBalance = getBaseBalance();
        uint128 fyTokenIn = _fyTokenBalance - _fyTokenCached;
        uint128 baseOut = _sellFYTokenPreview(
            fyTokenIn,
            _baseCached,
            _fyTokenCached
        );

        // Slippage check
        require(
            baseOut >= min,
            "Pool: Not enough base obtained"
        );

        // Update TWAR
        _update(
            _baseBalance - baseOut,
            _fyTokenBalance,
            _baseCached,
            _fyTokenCached
        );

        // Transfer assets
        base.safeTransfer(to, baseOut);

        emit Trade(maturity, msg.sender, to, baseOut.i128(), -(fyTokenIn.i128()));
        return baseOut;
    }

    /// @dev Returns how much base would be obtained by selling `fyTokenIn` fyToken.
    /// @param fyTokenIn Amount of fyToken hypothetically sold.
    /// @return Amount of base hypothetically bought.
    function sellFYTokenPreview(uint128 fyTokenIn)
        external view override
        returns(uint128)
    {
        (uint112 _baseCached, uint112 _fyTokenCached) =
            (baseCached, fyTokenCached);
        return _sellFYTokenPreview(fyTokenIn, _baseCached, _fyTokenCached);
    }

    /// @dev Returns how much base would be obtained by selling `fyTokenIn` fyToken.
    function _sellFYTokenPreview(
        uint128 fyTokenIn,
        uint112 baseBalance,
        uint112 fyTokenBalance
    )
        private view
        beforeMaturity
        returns(uint128)
    {
        (int128 _k, int128 _g2) = (k2, g2);
        return YieldMath.baseOutForFYTokenIn(
            baseBalance,
            fyTokenBalance,
            fyTokenIn,
            maturity - uint32(block.timestamp),             // This can't be called after maturity
            _k,
            _g2
        );
    }

    /// @dev Buy fyToken for base
    /// The trader needs to have called `base.approve`
    /// @param to Wallet receiving the fyToken being bought
    /// @param fyTokenOut Amount of fyToken being bought that will be deposited in `to` wallet
    /// @param max Maximum amount of base token that will be paid for the trade
    /// @return Amount of base that will be taken from caller's wallet
    function buyFYToken(address to, uint128 fyTokenOut, uint128 max)
        external override
        returns(uint128)
    {
        // Calculate trade
        uint128 baseBalance = getBaseBalance();
        (uint112 _baseCached, uint112 _fyTokenCached) =
            (baseCached, fyTokenCached);
        uint128 baseIn = _buyFYTokenPreview(
            fyTokenOut,
            _baseCached,
            _fyTokenCached
        );
        require(
            baseBalance - _baseCached >= baseIn,
            "Pool: Not enough base token in"
        );

        // Slippage check
        require(
            baseIn <= max,
            "Pool: Too much base token in"
        );

        // Update TWAR
        _update(
            _baseCached + baseIn,
            _fyTokenCached - fyTokenOut,
            _baseCached,
            _fyTokenCached
        );

        // Transfer assets
        IERC20(address(fyToken)).safeTransfer(to, fyTokenOut);

        emit Trade(maturity, msg.sender, to, -(baseIn.i128()), fyTokenOut.i128());
        return baseIn;
    }

    /// @dev Returns how much base would be required to buy `fyTokenOut` fyToken.
    /// @param fyTokenOut Amount of fyToken hypothetically desired.
    /// @return Amount of base hypothetically required.
    function buyFYTokenPreview(uint128 fyTokenOut)
        external view override
        returns(uint128)
    {
        (uint112 _baseCached, uint112 _fyTokenCached) =
            (baseCached, fyTokenCached);
        return _buyFYTokenPreview(fyTokenOut, _baseCached, _fyTokenCached);
    }

    /// @dev Returns how much base would be required to buy `fyTokenOut` fyToken.
    function _buyFYTokenPreview(
        uint128 fyTokenOut,
        uint128 baseBalance,
        uint128 fyTokenBalance
    )
        private view
        beforeMaturity
        returns(uint128)
    {
        (int128 _k, int128 _g1) = (k1, g1);
        uint128 baseIn = YieldMath.baseInForFYTokenOut(
            baseBalance,
            fyTokenBalance,
            fyTokenOut,
            maturity - uint32(block.timestamp),             // This can't be called after maturity
            _k,
            _g1
        );

        require(
            fyTokenBalance - fyTokenOut >= baseBalance + baseIn,
            "Pool: fyToken balance too low"
        );

        return baseIn;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.8.0;

import "@yield-protocol/yieldspace-interfaces/IPoolFactory.sol";
import "./Pool.sol";


/// @dev The PoolFactory can deterministically create new pool instances.
contract PoolFactory is IPoolFactory {
  /// Pre-hashing the bytecode allows calculatePoolAddress to be cheaper, and
  /// makes client-side address calculation easier
  bytes32 public constant override POOL_BYTECODE_HASH = keccak256(type(Pool).creationCode);

  address private _nextBase;
  address private _nextFYToken;

  /// @dev Returns true if `account` is a contract.
  function isContract(address account) internal view returns (bool) {
      // This method relies on extcodesize, which returns 0 for contracts in
      // construction, since the code is only stored at the end of the
      // constructor execution.

      uint256 size;
      // solhint-disable-next-line no-inline-assembly
      assembly { size := extcodesize(account) }
      return size > 0;
  }

  /// @dev Calculate the deterministic addreess of a pool, based on the base token & fy token.
  /// @param base Address of the base token (such as Base).
  /// @param fyToken Address of the fixed yield token (such as fyToken).
  /// @return The calculated pool address.
  function calculatePoolAddress(address base, address fyToken) external view override returns (address) {
    return _calculatePoolAddress(base, fyToken);
  }

  /// @dev Create2 calculation
  function _calculatePoolAddress(address base, address fyToken)
    private view returns (address calculatedAddress)
  {
    calculatedAddress = address(uint160(uint256(keccak256(abi.encodePacked(
      bytes1(0xff),
      address(this),
      keccak256(abi.encodePacked(base, fyToken)),
      POOL_BYTECODE_HASH
    )))));
  }

  /// @dev Calculate the addreess of a pool, and return address(0) if not deployed.
  /// @param base Address of the base token (such as Base).
  /// @param fyToken Address of the fixed yield token (such as fyToken).
  /// @return pool The deployed pool address.
  function getPool(address base, address fyToken) external view override returns (address pool) {
    pool = _calculatePoolAddress(base, fyToken);

    if(!isContract(pool)) {
      pool = address(0);
    }
  }

  /// @dev Deploys a new pool.
  /// base & fyToken are written to temporary storage slots to allow for simpler
  /// address calculation, while still allowing the Pool contract to store the values as
  /// immutable.
  /// @param base Address of the base token (such as Base).
  /// @param fyToken Address of the fixed yield token (such as fyToken).
  /// @return pool The pool address.
  function createPool(address base, address fyToken) external override returns (address) {
    _nextBase = base;
    _nextFYToken = fyToken;
    Pool pool = new Pool{salt: keccak256(abi.encodePacked(base, fyToken))}();
    _nextBase = address(0);
    _nextFYToken = address(0);

    pool.transferOwnership(msg.sender);
    
    emit PoolCreated(base, fyToken, address(pool));

    return address(pool);
  }

  /// @dev Only used by the Pool constructor.
  /// @return The base token for the currently-constructing pool.
  function nextBase() external view override returns (address) {
    return _nextBase;
  }

  /// @dev Only used by the Pool constructor.
  /// @return The fytoken for the currently-constructing pool.
  function nextFYToken() external view override returns (address) {
    return _nextFYToken;
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >= 0.8.0;

import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC2612.sol";
import "@yield-protocol/utils-v2/contracts/token/AllTransferHelper.sol";
import "@yield-protocol/utils-v2/contracts/utils/RevertMsgExtractor.sol";
import "@yield-protocol/utils-v2/contracts/interfaces/IWETH9.sol";
import "@yield-protocol/yieldspace-interfaces/IPool.sol";
import "@yield-protocol/yieldspace-interfaces/IPoolFactory.sol";
import "@yield-protocol/yieldspace-interfaces/PoolDataTypes.sol";
import "dss-interfaces/src/dss/DaiAbstract.sol";


contract PoolRouter {
    using AllTransferHelper for IERC20;
    using AllTransferHelper for address payable;

    IPoolFactory public immutable factory;
    IWETH9 public immutable weth;

    constructor(IPoolFactory factory_, IWETH9 weth_) {
        factory = factory_;
        weth = weth_;
    }

    struct PoolAddresses {
        address base;
        address fyToken;
        address pool;
    }

    /// @dev Submit a series of calls for execution
    /// The `bases` and `fyTokens` parameters define the pools that will be target for operations
    /// Each trio of `target`, `operation` and `data` define one call:
    ///  - `target` is an index in the `bases` and `fyTokens` arrays, from which contract addresses the target will be determined.
    ///  - `operation` is a numerical identifier for the call to be executed, from the enum `Operation`
    ///  - `data` is an abi-encoded group of parameters, to be consumed by the function encoded in `operation`.
    function batch(
        PoolDataTypes.Operation[] calldata operations,
        bytes[] calldata data
    ) external payable {
        require(operations.length == data.length, "Mismatched operation data");
        PoolAddresses memory cache;

        for (uint256 i = 0; i < operations.length; i += 1) {
            PoolDataTypes.Operation operation = operations[i];
            
            if (operation == PoolDataTypes.Operation.ROUTE) {
                (address base, address fyToken, bytes memory poolcall) = abi.decode(data[i], (address, address, bytes));
                if (cache.base != base || cache.fyToken != fyToken) cache = PoolAddresses(base, fyToken, findPool(base, fyToken));
                _route(cache, poolcall);

            } else if (operation == PoolDataTypes.Operation.TRANSFER_TO_POOL) {
                (address base, address fyToken, address token, uint128 wad) = abi.decode(data[i], (address, address, address, uint128));
                if (cache.base != base || cache.fyToken != fyToken) cache = PoolAddresses(base, fyToken, findPool(base, fyToken));
                _transferToPool(cache, token, wad);

            } else if (operation == PoolDataTypes.Operation.FORWARD_PERMIT) {
                (address base, address fyToken, address token, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) = 
                    abi.decode(data[i], (address, address, address, address, uint256, uint256, uint8, bytes32, bytes32));
                if (cache.base != base || cache.fyToken != fyToken) cache = PoolAddresses(base, fyToken, findPool(base, fyToken));
                _forwardPermit(cache, token, spender, amount, deadline, v, r, s);

            } else if (operation == PoolDataTypes.Operation.FORWARD_DAI_PERMIT) {
                        (address base, address fyToken, address spender, uint256 nonce, uint256 deadline, bool allowed, uint8 v, bytes32 r, bytes32 s) = 
                    abi.decode(data[i], (address, address, address, uint256, uint256, bool, uint8, bytes32, bytes32));
                if (cache.base != base || cache.fyToken != fyToken) cache = PoolAddresses(base, fyToken, findPool(base, fyToken));
                _forwardDaiPermit(cache, spender, nonce, deadline, allowed, v, r, s);

            } else if (operation == PoolDataTypes.Operation.JOIN_ETHER) {
                (address base, address fyToken) = abi.decode(data[i], (address, address));
                if (cache.base != base || cache.fyToken != fyToken) cache = PoolAddresses(base, fyToken, findPool(base, fyToken));
                _joinEther(cache.pool);

            } else if (operation == PoolDataTypes.Operation.EXIT_ETHER) {
                (address to) = abi.decode(data[i], (address));
                _exitEther(to);

            } else {
                revert("Invalid operation");
            }
        }
    }

    /// @dev Return which pool contract matches the base and fyToken
    function findPool(address base, address fyToken)
        private view returns (address pool)
    {
        pool = factory.getPool(base, fyToken);
        require (pool != address(0), "Pool not found");
    }

    /// @dev Allow users to trigger a token transfer to a pool, to be used with multicall
    function transferToPool(address base, address fyToken, address token, uint128 wad)
        external payable
        returns (bool)
    {
        return _transferToPool(
            PoolAddresses(base, fyToken, findPool(base, fyToken)),
            token, wad
        );
    }

    /// @dev Allow users to trigger a token transfer to a pool, to be used with batch
    function _transferToPool(PoolAddresses memory addresses, address token, uint128 wad)
        private
        returns (bool)
    {
        require(token == addresses.base || token == addresses.fyToken || token == addresses.pool, "Mismatched token");
        IERC20(token).safeTransferFrom(msg.sender, address(addresses.pool), wad);
        return true;
    }

    /// @dev Allow users to route calls to a pool, to be used with batch
    function _route(PoolAddresses memory addresses, bytes memory data)
        private
        returns (bool success, bytes memory result)
    {
        (success, result) = addresses.pool.call(data);
        if (!success) revert(RevertMsgExtractor.getRevertMsg(result));
    }

    // ---- Permit management ----

    /// @dev Execute an ERC2612 permit for the selected asset or fyToken, to be used with batch
    function _forwardPermit(PoolAddresses memory addresses, address token, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        private
    {
        require(token == addresses.base || token == addresses.fyToken || token == addresses.pool, "Mismatched token");
        IERC2612(token).permit(msg.sender, spender, amount, deadline, v, r, s);
    }

    /// @dev Execute a Dai-style permit for the selected asset or fyToken, to be used with batch
    function _forwardDaiPermit(PoolAddresses memory addresses, address spender, uint256 nonce, uint256 deadline, bool allowed, uint8 v, bytes32 r, bytes32 s)
        private
    {
        // Only the base token would ever be Dai
        DaiAbstract(addresses.base).permit(msg.sender, spender, nonce, deadline, allowed, v, r, s);
    }

    // ---- Ether management ----

    /// @dev The WETH9 contract will send ether to the PoolRouter on `weth.withdraw` using this function.
    receive() external payable {
        require (msg.sender == address(weth), "Only Weth contract allowed");
    }

    /// @dev Accept Ether, wrap it and forward it to the to a pool
    function _joinEther(address pool)
        private
        returns (uint256 ethTransferred)
    {
        ethTransferred = address(this).balance;

        weth.deposit{ value: ethTransferred }();   // TODO: Test gas savings using WETH10 `depositTo`
        IERC20(weth).safeTransfer(pool, ethTransferred);
    }

    /// @dev Unwrap Wrapped Ether held by this Router, and send the Ether
    function _exitEther(address to)
        private
        returns (uint256 ethTransferred)
    {
        ethTransferred = weth.balanceOf(address(this));

        weth.withdraw(ethTransferred);   // TODO: Test gas savings using WETH10 `withdrawTo`
        payable(to).safeTransferETH(ethTransferred);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;


/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes4` identifier. These are expected to be the 
 * signatures for all the functions in the contract. Special roles should be exposed
 * in the external API and be unique:
 *
 * ```
 * bytes4 public constant ROOT = 0x00000000;
 * ```
 *
 * Roles represent restricted access to a function call. For that purpose, use {auth}:
 *
 * ```
 * function foo() public auth {
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `ROOT`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {setRoleAdmin}.
 *
 * WARNING: The `ROOT` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
contract AccessControl {
    struct RoleData {
        mapping (address => bool) members;
        bytes4 adminRole;
    }

    mapping (bytes4 => RoleData) private _roles;

    bytes4 public constant ROOT = 0x00000000;
    bytes4 public constant LOCK = 0xFFFFFFFF; // Used to disable further permissioning of a function

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role
     *
     * `ROOT` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes4 indexed role, bytes4 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call.
     */
    event RoleGranted(bytes4 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes4 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Give msg.sender the ROOT role and create a LOCK role with itself as the admin role and no members. 
     * Calling setRoleAdmin(msg.sig, LOCK) means no one can grant that msg.sig role anymore.
     */
    constructor () {
        _grantRole(ROOT, msg.sender);   // Grant ROOT to msg.sender
        _setRoleAdmin(LOCK, LOCK);      // Create the LOCK role by setting itself as its own admin, creating an independent role tree
    }

    /**
     * @dev Each function in the contract has its own role, identified by their msg.sig signature.
     * ROOT can give and remove access to each function, lock any further access being granted to
     * a specific action, or even create other roles to delegate admin control over a function.
     */
    modifier auth() {
        require (_hasRole(msg.sig, msg.sender), "Access denied");
        _;
    }

    /**
     * @dev Allow only if the caller has been granted the admin role of `role`.
     */
    modifier admin(bytes4 role) {
        require (_hasRole(_getRoleAdmin(role), msg.sender), "Only admin");
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes4 role, address account) external view returns (bool) {
        return _hasRole(role, account);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes4 role) external view returns (bytes4) {
        return _getRoleAdmin(role);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.

     * If ``role``'s admin role is not `adminRole` emits a {RoleAdminChanged} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function setRoleAdmin(bytes4 role, bytes4 adminRole) external virtual admin(role) {
        _setRoleAdmin(role, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes4 role, address account) external virtual admin(role) {
        _grantRole(role, account);
    }

    
    /**
     * @dev Grants all of `role` in `roles` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - For each `role` in `roles`, the caller must have ``role``'s admin role.
     */
    function grantRoles(bytes4[] memory roles, address account) external virtual {
        for (uint256 i = 0; i < roles.length; i++) {
            require (_hasRole(_getRoleAdmin(roles[i]), msg.sender), "Only admin");
            _grantRole(roles[i], account);
        }
    }

    /**
     * @dev Sets LOCK as ``role``'s admin role. LOCK has no members, so this disables admin management of ``role``.

     * Emits a {RoleAdminChanged} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function lockRole(bytes4 role) external virtual admin(role) {
        _setRoleAdmin(role, LOCK);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes4 role, address account) external virtual admin(role) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes all of `role` in `roles` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - For each `role` in `roles`, the caller must have ``role``'s admin role.
     */
    function revokeRoles(bytes4[] memory roles, address account) external virtual {
        for (uint256 i = 0; i < roles.length; i++) {
            require (_hasRole(_getRoleAdmin(roles[i]), msg.sender), "Only admin");
            _revokeRole(roles[i], account);
        }
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes4 role, address account) external virtual {
        require(account == msg.sender, "Renounce only for self");

        _revokeRole(role, account);
    }

    function _hasRole(bytes4 role, address account) internal view returns (bool) {
        return _roles[role].members[account];
    }

    function _getRoleAdmin(bytes4 role) internal view returns (bytes4) {
        return _roles[role].adminRole;
    }

    function _setRoleAdmin(bytes4 role, bytes4 adminRole) internal virtual {
        if (_getRoleAdmin(role) != adminRole) {
            _roles[role].adminRole = adminRole;
            emit RoleAdminChanged(role, adminRole);
        }
    }

    function _grantRole(bytes4 role, address account) internal {
        if (!_hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes4 role, address account) internal {
        if (_hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /**
     * @notice Doesn't refresh the price, but returns the latest value available without doing any transactional operations:
     * @return value in wei
     */
    function peek(bytes32 base, bytes32 quote, uint256 amount) external view returns (uint256 value, uint256 updateTime);

    /**
     * @notice Does whatever work or queries will yield the most up-to-date price, and returns it.
     * @return value in wei
     */
    function get(bytes32 base, bytes32 quote, uint256 amount) external returns (uint256 value, uint256 updateTime);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library CastBytes32Bytes6 {
    function b6(bytes32 x) internal pure returns (bytes6 y){
        require (bytes32(y = bytes6(x)) == x, "Cast overflow");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.16;

interface CTokenInterface {
    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    function borrowIndex() external view returns (uint);

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() external returns (uint);
    
    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;


interface IERC3156FlashBorrower {

    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;
import "./IERC3156FlashBorrower.sol";


interface IERC3156FlashLender {

    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address token
    ) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";


interface IJoin {
    /// @dev asset managed by this contract
    function asset() external view returns (address);

    /// @dev Add tokens to this contract.
    function join(address user, uint128 wad) external returns (uint128);

    /// @dev Remove tokens to this contract.
    function exit(address user, uint128 wad) external returns (uint128);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;


interface IJoinFactory {
  event JoinCreated(address indexed asset, address pool);

  function JOIN_BYTECODE_HASH() external pure returns (bytes32);
  function calculateJoinAddress(address asset) external view returns (address);
  function getJoin(address asset) external view returns (address);
  function createJoin(address asset) external returns (address);
  function nextAsset() external view returns (address);
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

// SPDX-License-Identifier: GPL-3.0-or-later
// Taken from https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/TransferHelper.sol

pragma solidity >=0.6.0;

import "./IERC20.sol";
import "../utils/RevertMsgExtractor.sol";


// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library AllTransferHelper {
    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with the underlying revert message if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) revert(RevertMsgExtractor.getRevertMsg(data));
    }

    /// @notice Transfers tokens from the targeted address to the given destination
    /// @dev Errors with the underlying revert message if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) revert(RevertMsgExtractor.getRevertMsg(data));
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Errors with the underlying revert message if transfer fails
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address payable to, uint256 value) internal {
        (bool success, bytes memory data) = to.call{value: value}(new bytes(0));
        if (!success) revert(RevertMsgExtractor.getRevertMsg(data));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library WMul {
    // Taken from https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol
    /// @dev Multiply an amount by a fixed point factor with 18 decimals, rounds down.
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
        unchecked { z /= 1e18; }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library CastU256U128 {
    /// @dev Safely cast an uint256 to an uint128
    function u128(uint256 x) internal pure returns (uint128 y) {
        require (x <= type(uint128).max, "Cast overflow");
        y = uint128(x);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Taken from https://github.com/sushiswap/BoringSolidity/blob/441e51c0544cf2451e6116fe00515e71d7c42e2c/contracts/BoringBatchable.sol

pragma solidity >=0.6.0;


library RevertMsgExtractor {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function getRevertMsg(bytes memory returnData)
        internal pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            returnData := add(returnData, 0x04)
        }
        return abi.decode(returnData, (string)); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/53516bc555a454862470e7860a9b5254db4d00f5/contracts/token/ERC20/ERC20Permit.sol
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC2612.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to use their tokens
 * without sending any transactions by setting {IERC20-allowance} with a
 * signature using the {permit} method, and then spend them via
 * {IERC20-transferFrom}.
 *
 * The {permit} signature mechanism conforms to the {IERC2612} interface.
 */
abstract contract ERC20Permit is ERC20, IERC2612 {
    mapping (address => uint256) public override nonces;

    bytes32 public immutable PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private immutable _DOMAIN_SEPARATOR;
    uint256 public immutable deploymentChainId;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_, decimals_) {
        uint256 chainId;
        assembly {chainId := chainid()}
        deploymentChainId = chainId;
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(chainId);
    }

    /// @dev Calculate the DOMAIN_SEPARATOR.
    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version())),
                chainId,
                address(this)
            )
        );
    }

    /// @dev Return the DOMAIN_SEPARATOR.
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        uint256 chainId;
        assembly {chainId := chainid()}
        return chainId == deploymentChainId ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId);
    }

    /// @dev Setting the version as a function so that it can be overriden
    function version() public pure virtual returns(string memory) { return "1"; }

    /**
     * @dev See {IERC2612-permit}.
     *
     * In cases where the free option is not a concern, deadline can simply be
     * set to uint(-1), so it should be seen as an optional parameter
     */
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external virtual override {
        require(deadline >= block.timestamp, "ERC20Permit: expired deadline");

        uint256 chainId;
        assembly {chainId := chainid()}

        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                amount,
                nonces[owner]++,
                deadline
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                chainId == deploymentChainId ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId),
                hashStruct
            )
        );

        address signer = ecrecover(hash, v, r, s);
        require(
            signer != address(0) && signer == owner,
            "ERC20Permit: invalid signature"
        );

        _setAllowance(owner, spender, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";


interface IFYToken is IERC20 {
    /// @dev Asset that is returned on redemption.
    function underlying() external view returns (address);

    /// @dev Unix time at which redemption of fyToken for underlying are possible
    function maturity() external view returns (uint256);
    
    /// @dev Record price data at maturity
    function mature() external;

    /// @dev Burn fyToken after maturity for an amount of underlying.
    function redeem(address to, uint256 amount) external returns (uint256);

    /// @dev Mint fyToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param to Wallet to mint the fyToken in.
    /// @param fyTokenAmount Amount of fyToken to mint.
    function mint(address to, uint256 fyTokenAmount) external;

    /// @dev Burn fyToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param from Wallet to burn the fyToken from.
    /// @param fyTokenAmount Amount of fyToken to burn.
    function burn(address from, uint256 fyTokenAmount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library WDiv { // Fixed point arithmetic in 18 decimal units
    // Taken from https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol
    /// @dev Divide an amount by a fixed point factor with 18 decimals
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * 1e18) / y;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library CastU256U32 {
    /// @dev Safely cast an uint256 to an u32
    function u32(uint256 x) internal pure returns (uint32 y) {
        require (x <= type(uint32).max, "Cast overflow");
        y = uint32(x);
    }
}

// SPDX-License-Identifier: MIT
// Inspired on token.sol from DappHub. Natspec adpated from OpenZeppelin.

pragma solidity ^0.8.0;
import "./IERC20Metadata.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 * 
 * Calls to {transferFrom} do not check for allowance if the caller is the owner
 * of the funds. This allows to reduce the number of approvals that are necessary.
 *
 * Finally, {transferFrom} does not decrease the allowance if it is set to
 * type(uint256).max. This reduces the gas costs without any likely impact.
 */
contract ERC20 is IERC20Metadata {
    uint256                                           internal  _totalSupply;
    mapping (address => uint256)                      internal  _balanceOf;
    mapping (address => mapping (address => uint256)) internal  _allowance;
    string                                            public override name = "???";
    string                                            public override symbol = "???";
    uint8                                             public override decimals = 18;

    /**
     *  @dev Sets the values for {name}, {symbol} and {decimals}.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address guy) external view virtual override returns (uint256) {
        return _balanceOf[guy];
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowance[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint wad) external virtual override returns (bool) {
        return _setAllowance(msg.sender, spender, wad);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - the caller must have a balance of at least `wad`.
     */
    function transfer(address dst, uint wad) external virtual override returns (bool) {
        return _transfer(msg.sender, dst, wad);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `wad`.
     * - the caller is not `src`, it must have allowance for ``src``'s tokens of at least
     * `wad`.
     */
    /// if_succeeds {:msg "TransferFrom - decrease allowance"} msg.sender != src ==> old(_allowance[src][msg.sender]) >= wad;
    function transferFrom(address src, address dst, uint wad) external virtual override returns (bool) {
        _decreaseAllowance(src, wad);

        return _transfer(src, dst, wad);
    }

    /**
     * @dev Moves tokens `wad` from `src` to `dst`.
     * 
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `amount`.
     */
    /// if_succeeds {:msg "Transfer - src decrease"} old(_balanceOf[src]) >= _balanceOf[src];
    /// if_succeeds {:msg "Transfer - dst increase"} _balanceOf[dst] >= old(_balanceOf[dst]);
    /// if_succeeds {:msg "Transfer - supply"} old(_balanceOf[src]) + old(_balanceOf[dst]) == _balanceOf[src] + _balanceOf[dst];
    function _transfer(address src, address dst, uint wad) internal virtual returns (bool) {
        require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
        unchecked { _balanceOf[src] = _balanceOf[src] - wad; }
        _balanceOf[dst] = _balanceOf[dst] + wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    /**
     * @dev Sets the allowance granted to `spender` by `owner`.
     *
     * Emits an {Approval} event indicating the updated allowance.
     */
    function _setAllowance(address owner, address spender, uint wad) internal virtual returns (bool) {
        _allowance[owner][spender] = wad;
        emit Approval(owner, spender, wad);

        return true;
    }

    /**
     * @dev Decreases the allowance granted to the caller by `src`, unless src == msg.sender or _allowance[src][msg.sender] == MAX
     *
     * Emits an {Approval} event indicating the updated allowance, if the allowance is updated.
     *
     * Requirements:
     *
     * - `spender` must have allowance for the caller of at least
     * `wad`, unless src == msg.sender
     */
    /// if_succeeds {:msg "Decrease allowance - underflow"} old(_allowance[src][msg.sender]) <= _allowance[src][msg.sender];
    function _decreaseAllowance(address src, uint wad) internal virtual returns (bool) {
        if (src != msg.sender) {
            uint256 allowed = _allowance[src][msg.sender];
            if (allowed != type(uint).max) {
                require(allowed >= wad, "ERC20: Insufficient approval");
                unchecked { _setAllowance(src, msg.sender, allowed - wad); }
            }
        }

        return true;
    }

    /** @dev Creates `wad` tokens and assigns them to `dst`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     */
    /// if_succeeds {:msg "Mint - balance overflow"} old(_balanceOf[dst]) >= _balanceOf[dst];
    /// if_succeeds {:msg "Mint - supply overflow"} old(_totalSupply) >= _totalSupply;
    function _mint(address dst, uint wad) internal virtual returns (bool) {
        _balanceOf[dst] = _balanceOf[dst] + wad;
        _totalSupply = _totalSupply + wad;
        emit Transfer(address(0), dst, wad);

        return true;
    }

    /**
     * @dev Destroys `wad` tokens from `src`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `src` must have at least `wad` tokens.
     */
    /// if_succeeds {:msg "Burn - balance underflow"} old(_balanceOf[src]) <= _balanceOf[src];
    /// if_succeeds {:msg "Burn - supply underflow"} old(_totalSupply) <= _totalSupply;
    function _burn(address src, uint wad) internal virtual returns (bool) {
        unchecked {
            require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
            _balanceOf[src] = _balanceOf[src] - wad;
            _totalSupply = _totalSupply - wad;
            emit Transfer(src, address(0), wad);
        }

        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IFYToken.sol";
import "./IOracle.sol";


library DataTypes {
    struct Series {
        IFYToken fyToken;                                               // Redeemable token for the series.
        bytes6  baseId;                                                 // Asset received on redemption.
        uint32  maturity;                                               // Unix time at which redemption becomes possible.
        // bytes2 free
    }

    struct Debt {
        uint96 max;                                                     // Maximum debt accepted for a given underlying, across all series
        uint24 min;                                                     // Minimum debt accepted for a given underlying, across all series
        uint8 dec;                                                      // Multiplying factor (10**dec) for max and min 
        uint128 sum;                                                    // Current debt for a given underlying, across all series
    }

    struct SpotOracle {
        IOracle oracle;                                                 // Address for the spot price oracle
        uint32  ratio;                                                  // Collateralization ratio to multiply the price for
        // bytes8 free
    }

    struct Vault {
        address owner;
        bytes6  seriesId;                                                // Each vault is related to only one series, which also determines the underlying.
        bytes6  ilkId;                                                   // Asset accepted as collateral
    }

    struct Balances {
        uint128 art;                                                     // Debt amount
        uint128 ink;                                                     // Collateral amount
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library CastU128I128 {
    /// @dev Safely cast an uint128 to an int128
    function i128(uint128 x) internal pure returns (int128 y) {
        require (x <= uint128(type(int128).max), "Cast overflow");
        y = int128(x);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library CastI128U128 {
    /// @dev Safely cast an int128 to an uint128
    function u128(int128 x) internal pure returns (uint128 y) {
        require (x >= 0, "Cast overflow");
        y = uint128(x);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library CastU256I256 {
    /// @dev Safely cast an uint256 to an int256
    function i256(uint256 x) internal pure returns (int256 y) {
        require (x <= uint256(type(int256).max), "Cast overflow");
        y = int256(x);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IFYToken.sol";
import "./IOracle.sol";
import "./DataTypes.sol";


interface ICauldron {

    /// @dev Rate (borrowing rate) accruals oracle for an underlying
    function rateOracles(bytes6 baseId) external view returns (IOracle);

    /// @dev An user can own one or more Vaults, with each vault being able to borrow from a single series.
    function vaults(bytes12 vault) external view returns (DataTypes.Vault memory);

    /// @dev Series available in Cauldron.
    function series(bytes6 seriesId) external view returns (DataTypes.Series memory);

    /// @dev Assets available in Cauldron.
    function assets(bytes6 assetsId) external view returns (address);

    /// @dev Each vault records debt and collateral balances_.
    function balances(bytes12 vault) external view returns (DataTypes.Balances memory);

    /// @dev Time at which a vault entered liquidation.
    function auctions(bytes12 vault) external view returns (uint32);

    /// @dev Create a new vault, linked to a series (and therefore underlying) and up to 5 collateral types
    function build(address owner, bytes12 vaultId, bytes6 seriesId, bytes6 ilkId) external returns (DataTypes.Vault memory);

    /// @dev Destroy an empty vault. Used to recover gas costs.
    function destroy(bytes12 vault) external;

    /// @dev Change a vault series and/or collateral types.
    function tweak(bytes12 vaultId, bytes6 seriesId, bytes6 ilkId) external returns (DataTypes.Vault memory);

    /// @dev Give a vault to another user.
    function give(bytes12 vaultId, address receiver) external returns (DataTypes.Vault memory);

    /// @dev Move collateral and debt between vaults.
    function stir(bytes12 from, bytes12 to, uint128 ink, uint128 art) external returns (DataTypes.Balances memory, DataTypes.Balances memory);

    /// @dev Manipulate a vault debt and collateral.
    function pour(bytes12 vaultId, int128 ink, int128 art) external returns (DataTypes.Balances memory);

    /// @dev Change series and debt of a vault.
    /// The module calling this function also needs to buy underlying in the pool for the new series, and sell it in pool for the old series.
    function roll(bytes12 vaultId, bytes6 seriesId, int128 art) external returns (DataTypes.Vault memory, DataTypes.Balances memory);

    /// @dev Give a non-timestamped vault to another user, and timestamp it.
    /// To be used for liquidation engines.
    function grab(bytes12 vault, address receiver) external;

    /// @dev Reduce debt and collateral from a vault, ignoring collateralization checks.
    function slurp(bytes12 vaultId, uint128 ink, uint128 art) external returns (DataTypes.Balances memory);

    // ==== Accounting ====

    /// @dev Record the borrowing rate at maturity for a series
    function mature(bytes6 seriesId) external;
    
    /// @dev Retrieve the rate accrual since maturity, maturing if necessary.
    function accrual(bytes6 seriesId) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.0;
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC2612.sol";
import "@yield-protocol/vault-interfaces/IFYToken.sol";


interface IPool is IERC20, IERC2612 {
    function base() external view returns(IERC20);
    function fyToken() external view returns(IFYToken);
    function maturity() external view returns(uint32);
    function getBaseBalance() external view returns(uint112);
    function getFYTokenBalance() external view returns(uint112);
    function retrieveBase(address to) external returns(uint128 retrieved);
    function retrieveFYToken(address to) external returns(uint128 retrieved);
    function sellBase(address to, uint128 min) external returns(uint128);
    function buyBase(address to, uint128 baseOut, uint128 max) external returns(uint128);
    function sellFYToken(address to, uint128 min) external returns(uint128);
    function buyFYToken(address to, uint128 fyTokenOut, uint128 max) external returns(uint128);
    function sellBasePreview(uint128 baseIn) external view returns(uint128);
    function buyBasePreview(uint128 baseOut) external view returns(uint128);
    function sellFYTokenPreview(uint128 fyTokenIn) external view returns(uint128);
    function buyFYTokenPreview(uint128 fyTokenOut) external view returns(uint128);
    function mint(address to, bool calculateFromBase, uint256 minTokensMinted) external returns (uint256, uint256, uint256);
    function mintWithBase(address to, uint256 fyTokenToBuy, uint256 minTokensMinted) external returns (uint256, uint256, uint256);
    function burn(address to, uint256 minBaseOut, uint256 minFYTokenOut) external returns (uint256, uint256, uint256);
    function burnForBase(address to, uint256 minBaseOut) external returns (uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.12;

// https://github.com/makerdao/dss/blob/master/src/dai.sol
interface DaiAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function version() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function nonces(address) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function transfer(address, uint256) external;
    function transferFrom(address, address, uint256) external returns (bool);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function approve(address, uint256) external returns (bool);
    function push(address, uint256) external;
    function pull(address, uint256) external;
    function move(address, address, uint256) external;
    function permit(address, address, uint256, uint256, bool, uint8, bytes32, bytes32) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
import "../token/IERC20.sol";

pragma solidity ^0.8.0;


interface IWETH9 is IERC20 {
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    function deposit() external payable;
    function withdraw(uint wad) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "@yield-protocol/vault-interfaces/ICauldron.sol";
import "@yield-protocol/vault-interfaces/IJoin.sol";
import "@yield-protocol/yieldspace-interfaces/IPool.sol";


/// @dev Ladle orchestrates contract calls throughout the Yield Protocol v2 into useful and efficient user oriented features.
contract LadleStorage {

    enum Operation {
        BUILD,               // 0
        TWEAK,               // 1
        GIVE,                // 2
        DESTROY,             // 3
        STIR,                // 4
        POUR,                // 5
        SERVE,               // 6
        ROLL,                // 7
        CLOSE,               // 8
        REPAY,               // 9
        REPAY_VAULT,         // 10
        REPAY_LADLE,         // 11
        RETRIEVE,            // 12
        FORWARD_PERMIT,      // 13
        FORWARD_DAI_PERMIT,  // 14
        JOIN_ETHER,          // 15
        EXIT_ETHER,          // 16
        TRANSFER_TO_POOL,    // 17
        ROUTE,               // 18
        TRANSFER_TO_FYTOKEN, // 19
        REDEEM,              // 20
        MODULE               // 21
    }

    ICauldron public immutable cauldron;
    uint256 public borrowingFee;

    mapping (bytes6 => IJoin)                   public joins;            // Join contracts available to manage assets. The same Join can serve multiple assets (ETH-A, ETH-B, etc...)
    mapping (bytes6 => IPool)                   public pools;            // Pool contracts available to manage series. 12 bytes still free.
    mapping (address => bool)                   public modules;          // Trusted contracts to execute anything on.

    event JoinAdded(bytes6 indexed assetId, address indexed join);
    event PoolAdded(bytes6 indexed seriesId, address indexed pool);
    event ModuleSet(address indexed module, bool indexed set);
    event FeeSet(uint256 fee);

    constructor (ICauldron cauldron_) {
        cauldron = cauldron_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface ILadle {
    /// @dev Allow liquidation contracts to move assets to wind down vaults
    function settle(bytes12 vaultId, address user, uint128 ink, uint128 art) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library WDivUp { // Fixed point arithmetic in 18 decimal units
    // Taken from https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol
    /// @dev Divide x and y, with y being fixed point. If both are integers, the result is a fixed point factor. Rounds up.
    function wdivup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * 1e18 + y;            // 101 (1.01) / 1000 (10) -> (101 * 100 + 1000 - 1) / 1000 -> 11 (0.11 = 0.101 rounded up).
        unchecked { z -= 1; }       // Can do unchecked subtraction since division in next line will catch y = 0 case anyway
        z /= y;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IFYToken.sol";
import "./IOracle.sol";
import "./DataTypes.sol";


interface ICauldronGov {
    function assets(bytes6) external view returns (address);
    function series(bytes6) external view returns (DataTypes.Series memory);
    function rateOracles(bytes6) external view returns (IOracle);
    function addAsset(bytes6, address) external;
    function addSeries(bytes6, bytes6, IFYToken) external;
    function addIlks(bytes6, bytes6[] memory) external;
    function setRateOracle(bytes6, IOracle) external;
    function setSpotOracle(bytes6, bytes6, IOracle, uint32) external;
    function setDebtLimits(bytes6, bytes6, uint96, uint24, uint8) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IJoin.sol";

interface ILadleGov {
    function joins(bytes6) external view returns (IJoin);
    function addJoin(bytes6, address) external;
    function addPool(bytes6, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMultiOracleGov {
    function setSource(bytes6, bytes6, address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.0;


interface IPoolFactory {
  event PoolCreated(address indexed base, address indexed fyToken, address pool);

  function POOL_BYTECODE_HASH() external pure returns (bytes32);
  function calculatePoolAddress(address base, address fyToken) external view returns (address);
  function getPool(address base, address fyToken) external view returns (address);
  function createPool(address base, address fyToken) external returns (address);
  function nextBase() external view returns (address);
  function nextFYToken() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;


contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    constructor () {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Can only be called by the current owner.
    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.5.0;

import '../utils/AddressStringUtil.sol';

// produces token descriptors from inconsistent or absent ERC20 symbol implementations that can return string or bytes32
// this library will always produce a string symbol to represent the token
library SafeERC20Namer {
    function bytes32ToString(bytes32 x) private pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint256 charCount = 0;
        for (uint256 j = 0; j < 32; j++) {
            bytes1 char = x[j];
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    // assumes the data is in position 2
    function parseStringData(bytes memory b) private pure returns (string memory) {
        uint256 charCount = 0;
        // first parse the charCount out of the data
        for (uint256 i = 32; i < 64; i++) {
            charCount <<= 8;
            charCount += uint8(b[i]);
        }

        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 i = 0; i < charCount; i++) {
            bytesStringTrimmed[i] = b[i + 64];
        }

        return string(bytesStringTrimmed);
    }

    // uses a heuristic to produce a token name from the address
    // the heuristic returns the full hex of the address string in upper case
    function addressToName(address token) private pure returns (string memory) {
        return AddressStringUtil.toAsciiString(token, 40);
    }

    // uses a heuristic to produce a token symbol from the address
    // the heuristic returns the first 6 hex of the address string in upper case
    function addressToSymbol(address token) private pure returns (string memory) {
        return AddressStringUtil.toAsciiString(token, 6);
    }

    // calls an external view token contract method that returns a symbol or name, and parses the output into a string
    function callAndParseStringReturn(address token, bytes4 selector) private view returns (string memory) {
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(selector));
        // if not implemented, or returns empty data, return empty string
        if (!success || data.length == 0) {
            return '';
        }
        // bytes32 data always has length 32
        if (data.length == 32) {
            bytes32 decoded = abi.decode(data, (bytes32));
            return bytes32ToString(decoded);
        } else if (data.length > 64) {
            return abi.decode(data, (string));
        }
        return '';
    }

    // attempts to extract the token symbol. if it does not implement symbol, returns a symbol derived from the address
    function tokenSymbol(address token) public view returns (string memory) {
        // 0x95d89b41 = bytes4(keccak256("symbol()"))
        string memory symbol = callAndParseStringReturn(token, 0x95d89b41);
        if (bytes(symbol).length == 0) {
            // fallback to 6 uppercase hex of address
            return addressToSymbol(token);
        }
        return symbol;
    }

    // attempts to extract the token name. if it does not implement name, returns a name derived from the address
    function tokenName(address token) public view returns (string memory) {
        // 0x06fdde03 = bytes4(keccak256("name()"))
        string memory name = callAndParseStringReturn(token, 0x06fdde03);
        if (bytes(name).length == 0) {
            // fallback to full hex of address
            return addressToName(token);
        }
        return name;
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function tokenDecimals(address token) internal view returns (uint8) {
        // 0x313ce567 = bytes4(keccak256("decimals()"))
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Taken from https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/TransferHelper.sol

pragma solidity >=0.6.0;

import "./IERC20.sol";
import "../utils/RevertMsgExtractor.sol";


// helper methods for transferring ERC20 tokens that do not consistently return true/false
library TransferHelper {
    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with the underlying revert message if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) revert(RevertMsgExtractor.getRevertMsg(data));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.8.0;

import "./Math64x64.sol";

library Exp64x64 {
  /**
   * Raise given number x into power specified as a simple fraction y/z and then
   * multiply the result by the normalization factor 2^(128 * (1 - y/z)).
   * Revert if z is zero, or if both x and y are zeros.
   *
   * @param x number to raise into given power y/z
   * @param y numerator of the power to raise x into
   * @param z denominator of the power to raise x into
   * @return x raised into power y/z and then multiplied by 2^(128 * (1 - y/z))
   */
  function pow(uint128 x, uint128 y, uint128 z)
  internal pure returns(uint128) {
    unchecked {
      require(z != 0);

      if(x == 0) {
        require(y != 0);
        return 0;
      } else {
        uint256 l =
          uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - log_2(x)) * y / z;
        if(l > 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) return 0;
        else return pow_2(uint128(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - l));
      }
    }
  }

  /**
   * Calculate base 2 logarithm of an unsigned 128-bit integer number.  Revert
   * in case x is zero.
   *
   * @param x number to calculate base 2 logarithm of
   * @return base 2 logarithm of x, multiplied by 2^121
   */
  function log_2(uint128 x)
  internal pure returns(uint128) {
    unchecked {
      require(x != 0);

      uint b = x;

      uint l = 0xFE000000000000000000000000000000;

      if(b < 0x10000000000000000) {l -= 0x80000000000000000000000000000000; b <<= 64;}
      if(b < 0x1000000000000000000000000) {l -= 0x40000000000000000000000000000000; b <<= 32;}
      if(b < 0x10000000000000000000000000000) {l -= 0x20000000000000000000000000000000; b <<= 16;}
      if(b < 0x1000000000000000000000000000000) {l -= 0x10000000000000000000000000000000; b <<= 8;}
      if(b < 0x10000000000000000000000000000000) {l -= 0x8000000000000000000000000000000; b <<= 4;}
      if(b < 0x40000000000000000000000000000000) {l -= 0x4000000000000000000000000000000; b <<= 2;}
      if(b < 0x80000000000000000000000000000000) {l -= 0x2000000000000000000000000000000; b <<= 1;}

      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000;} /*
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2;}
      b = b * b >> 127; if(b > 0x100000000000000000000000000000000) l |= 0x1; */

      return uint128(l);
    }
  }

  /**
   * Calculate 2 raised into given power.
   *
   * @param x power to raise 2 into, multiplied by 2^121
   * @return 2 raised into given power
   */
  function pow_2(uint128 x)
  internal pure returns(uint128) {
    unchecked {
      uint r = 0x80000000000000000000000000000000;
      if(x & 0x1000000000000000000000000000000 > 0) r = r * 0xb504f333f9de6484597d89b3754abe9f >> 127;
      if(x & 0x800000000000000000000000000000 > 0) r = r * 0x9837f0518db8a96f46ad23182e42f6f6 >> 127;
      if(x & 0x400000000000000000000000000000 > 0) r = r * 0x8b95c1e3ea8bd6e6fbe4628758a53c90 >> 127;
      if(x & 0x200000000000000000000000000000 > 0) r = r * 0x85aac367cc487b14c5c95b8c2154c1b2 >> 127;
      if(x & 0x100000000000000000000000000000 > 0) r = r * 0x82cd8698ac2ba1d73e2a475b46520bff >> 127;
      if(x & 0x80000000000000000000000000000 > 0) r = r * 0x8164d1f3bc0307737be56527bd14def4 >> 127;
      if(x & 0x40000000000000000000000000000 > 0) r = r * 0x80b1ed4fd999ab6c25335719b6e6fd20 >> 127;
      if(x & 0x20000000000000000000000000000 > 0) r = r * 0x8058d7d2d5e5f6b094d589f608ee4aa2 >> 127;
      if(x & 0x10000000000000000000000000000 > 0) r = r * 0x802c6436d0e04f50ff8ce94a6797b3ce >> 127;
      if(x & 0x8000000000000000000000000000 > 0) r = r * 0x8016302f174676283690dfe44d11d008 >> 127;
      if(x & 0x4000000000000000000000000000 > 0) r = r * 0x800b179c82028fd0945e54e2ae18f2f0 >> 127;
      if(x & 0x2000000000000000000000000000 > 0) r = r * 0x80058baf7fee3b5d1c718b38e549cb93 >> 127;
      if(x & 0x1000000000000000000000000000 > 0) r = r * 0x8002c5d00fdcfcb6b6566a58c048be1f >> 127;
      if(x & 0x800000000000000000000000000 > 0) r = r * 0x800162e61bed4a48e84c2e1a463473d9 >> 127;
      if(x & 0x400000000000000000000000000 > 0) r = r * 0x8000b17292f702a3aa22beacca949013 >> 127;
      if(x & 0x200000000000000000000000000 > 0) r = r * 0x800058b92abbae02030c5fa5256f41fe >> 127;
      if(x & 0x100000000000000000000000000 > 0) r = r * 0x80002c5c8dade4d71776c0f4dbea67d6 >> 127;
      if(x & 0x80000000000000000000000000 > 0) r = r * 0x8000162e44eaf636526be456600bdbe4 >> 127;
      if(x & 0x40000000000000000000000000 > 0) r = r * 0x80000b1721fa7c188307016c1cd4e8b6 >> 127;
      if(x & 0x20000000000000000000000000 > 0) r = r * 0x8000058b90de7e4cecfc487503488bb1 >> 127;
      if(x & 0x10000000000000000000000000 > 0) r = r * 0x800002c5c8678f36cbfce50a6de60b14 >> 127;
      if(x & 0x8000000000000000000000000 > 0) r = r * 0x80000162e431db9f80b2347b5d62e516 >> 127;
      if(x & 0x4000000000000000000000000 > 0) r = r * 0x800000b1721872d0c7b08cf1e0114152 >> 127;
      if(x & 0x2000000000000000000000000 > 0) r = r * 0x80000058b90c1aa8a5c3736cb77e8dff >> 127;
      if(x & 0x1000000000000000000000000 > 0) r = r * 0x8000002c5c8605a4635f2efc2362d978 >> 127;
      if(x & 0x800000000000000000000000 > 0) r = r * 0x800000162e4300e635cf4a109e3939bd >> 127;
      if(x & 0x400000000000000000000000 > 0) r = r * 0x8000000b17217ff81bef9c551590cf83 >> 127;
      if(x & 0x200000000000000000000000 > 0) r = r * 0x800000058b90bfdd4e39cd52c0cfa27c >> 127;
      if(x & 0x100000000000000000000000 > 0) r = r * 0x80000002c5c85fe6f72d669e0e76e411 >> 127;
      if(x & 0x80000000000000000000000 > 0) r = r * 0x8000000162e42ff18f9ad35186d0df28 >> 127;
      if(x & 0x40000000000000000000000 > 0) r = r * 0x80000000b17217f84cce71aa0dcfffe7 >> 127;
      if(x & 0x20000000000000000000000 > 0) r = r * 0x8000000058b90bfc07a77ad56ed22aaa >> 127;
      if(x & 0x10000000000000000000000 > 0) r = r * 0x800000002c5c85fdfc23cdead40da8d6 >> 127;
      if(x & 0x8000000000000000000000 > 0) r = r * 0x80000000162e42fefc25eb1571853a66 >> 127;
      if(x & 0x4000000000000000000000 > 0) r = r * 0x800000000b17217f7d97f692baacded5 >> 127;
      if(x & 0x2000000000000000000000 > 0) r = r * 0x80000000058b90bfbead3b8b5dd254d7 >> 127;
      if(x & 0x1000000000000000000000 > 0) r = r * 0x8000000002c5c85fdf4eedd62f084e67 >> 127;
      if(x & 0x800000000000000000000 > 0) r = r * 0x800000000162e42fefa58aef378bf586 >> 127;
      if(x & 0x400000000000000000000 > 0) r = r * 0x8000000000b17217f7d24a78a3c7ef02 >> 127;
      if(x & 0x200000000000000000000 > 0) r = r * 0x800000000058b90bfbe9067c93e474a6 >> 127;
      if(x & 0x100000000000000000000 > 0) r = r * 0x80000000002c5c85fdf47b8e5a72599f >> 127;
      if(x & 0x80000000000000000000 > 0) r = r * 0x8000000000162e42fefa3bdb315934a2 >> 127;
      if(x & 0x40000000000000000000 > 0) r = r * 0x80000000000b17217f7d1d7299b49c46 >> 127;
      if(x & 0x20000000000000000000 > 0) r = r * 0x8000000000058b90bfbe8e9a8d1c4ea0 >> 127;
      if(x & 0x10000000000000000000 > 0) r = r * 0x800000000002c5c85fdf4745969ea76f >> 127;
      if(x & 0x8000000000000000000 > 0) r = r * 0x80000000000162e42fefa3a0df5373bf >> 127;
      if(x & 0x4000000000000000000 > 0) r = r * 0x800000000000b17217f7d1cff4aac1e1 >> 127;
      if(x & 0x2000000000000000000 > 0) r = r * 0x80000000000058b90bfbe8e7db95a2f1 >> 127;
      if(x & 0x1000000000000000000 > 0) r = r * 0x8000000000002c5c85fdf473e61ae1f8 >> 127;
      if(x & 0x800000000000000000 > 0) r = r * 0x800000000000162e42fefa39f121751c >> 127;
      if(x & 0x400000000000000000 > 0) r = r * 0x8000000000000b17217f7d1cf815bb96 >> 127;
      if(x & 0x200000000000000000 > 0) r = r * 0x800000000000058b90bfbe8e7bec1e0d >> 127;
      if(x & 0x100000000000000000 > 0) r = r * 0x80000000000002c5c85fdf473dee5f17 >> 127;
      if(x & 0x80000000000000000 > 0) r = r * 0x8000000000000162e42fefa39ef5438f >> 127;
      if(x & 0x40000000000000000 > 0) r = r * 0x80000000000000b17217f7d1cf7a26c8 >> 127;
      if(x & 0x20000000000000000 > 0) r = r * 0x8000000000000058b90bfbe8e7bcf4a4 >> 127;
      if(x & 0x10000000000000000 > 0) r = r * 0x800000000000002c5c85fdf473de72a2 >> 127; /*
      if(x & 0x8000000000000000 > 0) r = r * 0x80000000000000162e42fefa39ef3765 >> 127;
      if(x & 0x4000000000000000 > 0) r = r * 0x800000000000000b17217f7d1cf79b37 >> 127;
      if(x & 0x2000000000000000 > 0) r = r * 0x80000000000000058b90bfbe8e7bcd7d >> 127;
      if(x & 0x1000000000000000 > 0) r = r * 0x8000000000000002c5c85fdf473de6b6 >> 127;
      if(x & 0x800000000000000 > 0) r = r * 0x800000000000000162e42fefa39ef359 >> 127;
      if(x & 0x400000000000000 > 0) r = r * 0x8000000000000000b17217f7d1cf79ac >> 127;
      if(x & 0x200000000000000 > 0) r = r * 0x800000000000000058b90bfbe8e7bcd6 >> 127;
      if(x & 0x100000000000000 > 0) r = r * 0x80000000000000002c5c85fdf473de6a >> 127;
      if(x & 0x80000000000000 > 0) r = r * 0x8000000000000000162e42fefa39ef35 >> 127;
      if(x & 0x40000000000000 > 0) r = r * 0x80000000000000000b17217f7d1cf79a >> 127;
      if(x & 0x20000000000000 > 0) r = r * 0x8000000000000000058b90bfbe8e7bcd >> 127;
      if(x & 0x10000000000000 > 0) r = r * 0x800000000000000002c5c85fdf473de6 >> 127;
      if(x & 0x8000000000000 > 0) r = r * 0x80000000000000000162e42fefa39ef3 >> 127;
      if(x & 0x4000000000000 > 0) r = r * 0x800000000000000000b17217f7d1cf79 >> 127;
      if(x & 0x2000000000000 > 0) r = r * 0x80000000000000000058b90bfbe8e7bc >> 127;
      if(x & 0x1000000000000 > 0) r = r * 0x8000000000000000002c5c85fdf473de >> 127;
      if(x & 0x800000000000 > 0) r = r * 0x800000000000000000162e42fefa39ef >> 127;
      if(x & 0x400000000000 > 0) r = r * 0x8000000000000000000b17217f7d1cf7 >> 127;
      if(x & 0x200000000000 > 0) r = r * 0x800000000000000000058b90bfbe8e7b >> 127;
      if(x & 0x100000000000 > 0) r = r * 0x80000000000000000002c5c85fdf473d >> 127;
      if(x & 0x80000000000 > 0) r = r * 0x8000000000000000000162e42fefa39e >> 127;
      if(x & 0x40000000000 > 0) r = r * 0x80000000000000000000b17217f7d1cf >> 127;
      if(x & 0x20000000000 > 0) r = r * 0x8000000000000000000058b90bfbe8e7 >> 127;
      if(x & 0x10000000000 > 0) r = r * 0x800000000000000000002c5c85fdf473 >> 127;
      if(x & 0x8000000000 > 0) r = r * 0x80000000000000000000162e42fefa39 >> 127;
      if(x & 0x4000000000 > 0) r = r * 0x800000000000000000000b17217f7d1c >> 127;
      if(x & 0x2000000000 > 0) r = r * 0x80000000000000000000058b90bfbe8e >> 127;
      if(x & 0x1000000000 > 0) r = r * 0x8000000000000000000002c5c85fdf47 >> 127;
      if(x & 0x800000000 > 0) r = r * 0x800000000000000000000162e42fefa3 >> 127;
      if(x & 0x400000000 > 0) r = r * 0x8000000000000000000000b17217f7d1 >> 127;
      if(x & 0x200000000 > 0) r = r * 0x800000000000000000000058b90bfbe8 >> 127;
      if(x & 0x100000000 > 0) r = r * 0x80000000000000000000002c5c85fdf4 >> 127;
      if(x & 0x80000000 > 0) r = r * 0x8000000000000000000000162e42fefa >> 127;
      if(x & 0x40000000 > 0) r = r * 0x80000000000000000000000b17217f7d >> 127;
      if(x & 0x20000000 > 0) r = r * 0x8000000000000000000000058b90bfbe >> 127;
      if(x & 0x10000000 > 0) r = r * 0x800000000000000000000002c5c85fdf >> 127;
      if(x & 0x8000000 > 0) r = r * 0x80000000000000000000000162e42fef >> 127;
      if(x & 0x4000000 > 0) r = r * 0x800000000000000000000000b17217f7 >> 127;
      if(x & 0x2000000 > 0) r = r * 0x80000000000000000000000058b90bfb >> 127;
      if(x & 0x1000000 > 0) r = r * 0x8000000000000000000000002c5c85fd >> 127;
      if(x & 0x800000 > 0) r = r * 0x800000000000000000000000162e42fe >> 127;
      if(x & 0x400000 > 0) r = r * 0x8000000000000000000000000b17217f >> 127;
      if(x & 0x200000 > 0) r = r * 0x800000000000000000000000058b90bf >> 127;
      if(x & 0x100000 > 0) r = r * 0x80000000000000000000000002c5c85f >> 127;
      if(x & 0x80000 > 0) r = r * 0x8000000000000000000000000162e42f >> 127;
      if(x & 0x40000 > 0) r = r * 0x80000000000000000000000000b17217 >> 127;
      if(x & 0x20000 > 0) r = r * 0x8000000000000000000000000058b90b >> 127;
      if(x & 0x10000 > 0) r = r * 0x800000000000000000000000002c5c85 >> 127;
      if(x & 0x8000 > 0) r = r * 0x80000000000000000000000000162e42 >> 127;
      if(x & 0x4000 > 0) r = r * 0x800000000000000000000000000b1721 >> 127;
      if(x & 0x2000 > 0) r = r * 0x80000000000000000000000000058b90 >> 127;
      if(x & 0x1000 > 0) r = r * 0x8000000000000000000000000002c5c8 >> 127;
      if(x & 0x800 > 0) r = r * 0x800000000000000000000000000162e4 >> 127;
      if(x & 0x400 > 0) r = r * 0x8000000000000000000000000000b172 >> 127;
      if(x & 0x200 > 0) r = r * 0x800000000000000000000000000058b9 >> 127;
      if(x & 0x100 > 0) r = r * 0x80000000000000000000000000002c5c >> 127;
      if(x & 0x80 > 0) r = r * 0x8000000000000000000000000000162e >> 127;
      if(x & 0x40 > 0) r = r * 0x80000000000000000000000000000b17 >> 127;
      if(x & 0x20 > 0) r = r * 0x8000000000000000000000000000058b >> 127;
      if(x & 0x10 > 0) r = r * 0x800000000000000000000000000002c5 >> 127;
      if(x & 0x8 > 0) r = r * 0x80000000000000000000000000000162 >> 127;
      if(x & 0x4 > 0) r = r * 0x800000000000000000000000000000b1 >> 127;
      if(x & 0x2 > 0) r = r * 0x80000000000000000000000000000058 >> 127;
      if(x & 0x1 > 0) r = r * 0x8000000000000000000000000000002c >> 127; */

      r >>= 127 -(x >> 121);

      return uint128(r);
    }
  }
}

/**
 * Ethereum smart contract library implementing Yield Math model.
 */
library YieldMath {
  using Math64x64 for int128;
  using Math64x64 for uint128;
  using Math64x64 for int256;
  using Math64x64 for uint256;
  using Exp64x64 for uint128;

  uint128 public constant ONE = 0x10000000000000000; // In 64.64
  uint256 public constant MAX = type(uint128).max;   // Used for overflow checks

  /**
   * Calculate the amount of fyToken a user would get for given amount of Base.
   * https://www.desmos.com/calculator/5nf2xuy6yb
   * @param baseReserves base reserves amount
   * @param fyTokenReserves fyToken reserves amount
   * @param baseAmount base amount to be traded
   * @param timeTillMaturity time till maturity in seconds
   * @param k time till maturity coefficient, multiplied by 2^64
   * @param g fee coefficient, multiplied by 2^64
   * @return the amount of fyToken a user would get for given amount of Base
   */
  function fyTokenOutForBaseIn(
    uint128 baseReserves, uint128 fyTokenReserves, uint128 baseAmount,
    uint128 timeTillMaturity, int128 k, int128 g)
  public pure returns(uint128) {
    unchecked {
      uint128 a = _computeA(timeTillMaturity, k, g);

      // za = baseReserves ** a
      uint256 za = baseReserves.pow(a, ONE);

      // ya = fyTokenReserves ** a
      uint256 ya = fyTokenReserves.pow(a, ONE);

      // zx = baseReserves + baseAmount
      uint256 zx = uint256(baseReserves) + uint256(baseAmount);
      require(zx <= MAX, "YieldMath: Too much base in");

      // zxa = zx ** a
      uint256 zxa = uint128(zx).pow(a, ONE);

      // sum = za + ya - zxa
      uint256 sum = za + ya - zxa; // z < MAX, y < MAX, a < 1. It can only underflow, not overflow.
      require(sum <= MAX, "YieldMath: Insufficient fyToken reserves");

      // result = fyTokenReserves - (sum ** (1/a))
      uint256 result = uint256(fyTokenReserves) - uint256(uint128(sum).pow(ONE, a));
      require(result <= MAX, "YieldMath: Rounding induced error");

      result = result > 1e12 ? result - 1e12 : 0; // Subtract error guard, flooring the result at zero

      return uint128(result);
    }
  }

  /**
   * Calculate the amount of base a user would get for certain amount of fyToken.
   * https://www.desmos.com/calculator/6jlrre7ybt
   * @param baseReserves base reserves amount
   * @param fyTokenReserves fyToken reserves amount
   * @param fyTokenAmount fyToken amount to be traded
   * @param timeTillMaturity time till maturity in seconds
   * @param k time till maturity coefficient, multiplied by 2^64
   * @param g fee coefficient, multiplied by 2^64
   * @return the amount of Base a user would get for given amount of fyToken
   */
  function baseOutForFYTokenIn(
    uint128 baseReserves, uint128 fyTokenReserves, uint128 fyTokenAmount,
    uint128 timeTillMaturity, int128 k, int128 g)
  public pure returns(uint128) {
    unchecked {
      uint128 a = _computeA(timeTillMaturity, k, g);

      // za = baseReserves ** a
      uint256 za = baseReserves.pow(a, ONE);

      // ya = fyTokenReserves ** a
      uint256 ya = fyTokenReserves.pow(a, ONE);

      // yx = fyDayReserves + fyTokenAmount
      uint256 yx = uint256(fyTokenReserves) + uint256(fyTokenAmount);
      require(yx <= MAX, "YieldMath: Too much fyToken in");

      // yxa = yx ** a
      uint256 yxa = uint128(yx).pow(a, ONE);

      // sum = za + ya - yxa
      uint256 sum = za + ya - yxa; // z < MAX, y < MAX, a < 1. It can only underflow, not overflow.
      require(sum <= MAX, "YieldMath: Insufficient base reserves");

      // result = baseReserves - (sum ** (1/a))
      uint256 result = uint256(baseReserves) - uint256(uint128(sum).pow(ONE, a));
      require(result <= MAX, "YieldMath: Rounding induced error");

      result = result > 1e12 ? result - 1e12 : 0; // Subtract error guard, flooring the result at zero

      return uint128(result);
    }
  }

  /**
   * Calculate the amount of fyToken a user could sell for given amount of Base.
   * https://www.desmos.com/calculator/0rgnmtckvy
   * @param baseReserves base reserves amount
   * @param fyTokenReserves fyToken reserves amount
   * @param baseAmount Base amount to be traded
   * @param timeTillMaturity time till maturity in seconds
   * @param k time till maturity coefficient, multiplied by 2^64
   * @param g fee coefficient, multiplied by 2^64
   * @return the amount of fyToken a user could sell for given amount of Base
   */
  function fyTokenInForBaseOut(
    uint128 baseReserves, uint128 fyTokenReserves, uint128 baseAmount,
    uint128 timeTillMaturity, int128 k, int128 g)
  public pure returns(uint128) {
    unchecked {
      uint128 a = _computeA(timeTillMaturity, k, g);

      // za = baseReserves ** a
      uint256 za = baseReserves.pow(a, ONE);

      // ya = fyTokenReserves ** a
      uint256 ya = fyTokenReserves.pow(a, ONE);

      // zx = baseReserves - baseAmount
      uint256 zx = uint256(baseReserves) - uint256(baseAmount);
      require(zx <= MAX, "YieldMath: Too much base out");

      // zxa = zx ** a
      uint256 zxa = uint128(zx).pow(a, ONE);

      // sum = za + ya - zxa
      uint256 sum = za + ya - zxa; // z < MAX, y < MAX, a < 1. It can only underflow, not overflow.
      require(sum <= MAX, "YieldMath: Resulting fyToken reserves too high");

      // result = (sum ** (1/a)) - fyTokenReserves
      uint256 result = uint256(uint128(sum).pow(ONE, a)) - uint256(fyTokenReserves);
      require(result <= MAX, "YieldMath: Rounding induced error");

      result = result < MAX - 1e12 ? result + 1e12 : MAX; // Add error guard, ceiling the result at max

      return uint128(result);
    }
  }

  /**
   * Calculate the amount of base a user would have to pay for certain amount of fyToken.
   * https://www.desmos.com/calculator/ws5oqj8x5i
   * @param baseReserves Base reserves amount
   * @param fyTokenReserves fyToken reserves amount
   * @param fyTokenAmount fyToken amount to be traded
   * @param timeTillMaturity time till maturity in seconds
   * @param k time till maturity coefficient, multiplied by 2^64
   * @param g fee coefficient, multiplied by 2^64
   * @return the amount of base a user would have to pay for given amount of
   *         fyToken
   */
  function baseInForFYTokenOut(
    uint128 baseReserves, uint128 fyTokenReserves, uint128 fyTokenAmount,
    uint128 timeTillMaturity, int128 k, int128 g)
  public pure returns(uint128) {
    unchecked {
      uint128 a = _computeA(timeTillMaturity, k, g);

      // za = baseReserves ** a
      uint256 za = baseReserves.pow(a, ONE);

      // ya = fyTokenReserves ** a
      uint256 ya = fyTokenReserves.pow(a, ONE);

      // yx = baseReserves - baseAmount
      uint256 yx = uint256(fyTokenReserves) - uint256(fyTokenAmount);
      require(yx <= MAX, "YieldMath: Too much fyToken out");

      // yxa = yx ** a
      uint256 yxa = uint128(yx).pow(a, ONE);

      // sum = za + ya - yxa
      uint256 sum = za + ya - yxa; // z < MAX, y < MAX, a < 1. It can only underflow, not overflow.
      require(sum <= MAX, "YieldMath: Resulting base reserves too high");

      // result = (sum ** (1/a)) - baseReserves
      uint256 result = uint256(uint128(sum).pow(ONE, a)) - uint256(baseReserves);
      require(result <= MAX, "YieldMath: Rounding induced error");

      result = result < MAX - 1e12 ? result + 1e12 : MAX; // Add error guard, ceiling the result at max

      return uint128(result);
    }
  }

  function _computeA(uint128 timeTillMaturity, int128 k, int128 g) private pure returns (uint128) {
    unchecked {
      // t = k * timeTillMaturity
      int128 t = k.mul(timeTillMaturity.fromUInt());
      require(t >= 0, "YieldMath: t must be positive"); // Meaning neither T or k can be negative

      // a = (1 - gt)
      int128 a = int128(ONE).sub(g.mul(t));
      require(a > 0, "YieldMath: Too far from maturity");
      require(a <= int128(ONE), "YieldMath: g must be positive");

      return uint128(a);
    }
  }

  /**
   * Estimate in Base the value of reserves at protocol initialization time.
   *
   * @param baseReserves base reserves amount
   * @param fyTokenReserves fyToken reserves amount
   * @param timeTillMaturity time till maturity in seconds
   * @param k time till maturity coefficient, multiplied by 2^64
   * @param c0 price of base in terms of Base, multiplied by 2^64
   * @return estimated value of reserves
   */
  function initialReservesValue(
    uint128 baseReserves, uint128 fyTokenReserves, uint128 timeTillMaturity,
    int128 k, int128 c0)
  external pure returns(uint128) {
    unchecked {
      uint256 normalizedBaseReserves = c0.mulu(baseReserves);
      require(normalizedBaseReserves <= MAX);

      // a = (1 - k * timeTillMaturity)
      int128 a = int128(ONE).sub(k.mul(timeTillMaturity.fromUInt()));
      require(a > 0);

      uint256 sum =
        uint256(uint128(normalizedBaseReserves).pow(uint128(a), ONE)) +
        uint256(fyTokenReserves.pow(uint128(a), ONE)) >> 1;
      require(sum <= MAX);

      uint256 result = uint256(uint128(sum).pow(ONE, uint128(a))) << 1;
      require(result <= MAX);

      return uint128(result);
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.5.0;

library AddressStringUtil {
    // converts an address to the uppercase hex string, extracting only len bytes (up to 20, multiple of 2)
    function toAsciiString(address addr, uint256 len) internal pure returns (string memory) {
        require(len % 2 == 0 && len > 0 && len <= 40, 'AddressStringUtil: INVALID_LEN');

        bytes memory s = new bytes(len);
        uint256 addrNum = uint256(uint160(addr));
        for (uint256 i = 0; i < len / 2; i++) {
            // shift right and truncate all but the least significant byte to extract the byte at position 19-i
            uint8 b = uint8(addrNum >> (8 * (19 - i)));
            // first hex character is the most significant 4 bits
            uint8 hi = b >> 4;
            // second hex character is the least significant 4 bits
            uint8 lo = b - (hi << 4);
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    // hi and lo are only 4 bits and between 0 and 16
    // this method converts those values to the unicode/ascii code point for the hex representation
    // uses upper case for the characters
    function char(uint8 b) private pure returns (bytes1 c) {
        if (b < 10) {
            return bytes1(b + 0x30);
        } else {
            return bytes1(b + 0x37);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
/*
 *  Math 64.64 Smart Contract Library.  Copyright © 2019 by  Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity >= 0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library Math64x64 {
  /**
   * @dev Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /**
   * @dev Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * @dev Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
    require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
    }
  }

  /**
   * @dev Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
    return int64 (x >> 64);
    }
  }

  /**
   * @dev Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
    require (x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (uint128 (x << 64));
    }
  }

  /**
   * @dev Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
    require (x >= 0);
    return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * @dev Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
    int256 result = x >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
    }
  }

  /**
   * @dev Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
    return int256 (x) << 64;
    }
  }

  /**
   * @dev Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
    int256 result = int256(x) + y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
    }
  }

  /**
   * @dev Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
    int256 result = int256(x) - y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
    }
  }

  /**
   * @dev Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
    int256 result = int256(x) * y >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
    }
  }

  /**
   * @dev Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
    if (x == MIN_64x64) {
      require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
        y <= 0x1000000000000000000000000000000000000000000000000);
      return -y << 63;
    } else {
      bool negativeResult = false;
      if (x < 0) {
        x = -x;
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint256 absoluteResult = mulu (x, uint256 (y));
      if (negativeResult) {
        require (absoluteResult <=
          0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <=
          0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (absoluteResult);
      }
    }
    }
  }

  /**
   * @dev Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
    if (y == 0) return 0;

    require (x >= 0);

    uint256 lo = (uint256 (uint128 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
    uint256 hi = uint256 (uint128 (x)) * (y >> 128);

    require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    hi <<= 64;

    require (hi <=
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
    return hi + lo;
    }
  }

  /**
   * @dev Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
    require (y != 0);
    int256 result = (int256 (x) << 64) / y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
    }
  }

  /**
   * @dev Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
    require (y != 0);

    bool negativeResult = false;
    if (x < 0) {
      x = -x; // We rely on overflow behavior here
      negativeResult = true;
    }
    if (y < 0) {
      y = -y; // We rely on overflow behavior here
      negativeResult = !negativeResult;
    }
    uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
    }
  }

  /**
   * @dev Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
    require (y != 0);
    uint128 result = divuu (x, y);
    require (result <= uint128 (MAX_64x64));
    return int128 (result);
    }
  }

  /**
   * @dev Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
    require (x != MIN_64x64);
    return -x;
    }
  }

  /**
   * @dev Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
    require (x != MIN_64x64);
    return x < 0 ? -x : x;
    }
  }

  /**
   * @dev Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
    require (x != 0);
    int256 result = int256 (0x100000000000000000000000000000000) / x;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
    }
  }

  /**
   * @dev Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
    return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * @dev Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
    int256 m = int256 (x) * int256 (y);
    require (m >= 0);
    require (m <
        0x4000000000000000000000000000000000000000000000000000000000000000);
    return int128 (sqrtu (uint256 (m), uint256 (uint128 (x)) + uint256 (uint128 (y)) >> 1));
    }
  }

  /**
   * @dev Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
    uint256 absoluteResult;
    bool negativeResult = false;
    if (x >= 0) {
      absoluteResult = powu (uint256 (uint128 (x)) << 63, y);
    } else {
      // We rely on overflow behavior here
      absoluteResult = powu (uint256 (uint128 (-x)) << 63, y);
      negativeResult = y & 1 > 0;
    }

    absoluteResult >>= 63;

    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (uint128 (absoluteResult)); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (uint128 (absoluteResult)); // We rely on overflow behavior here
    }
    }
  }

  /**
   * @dev Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
    require (x >= 0);
    return int128 (sqrtu (uint256 (uint128 (x)) << 64, 0x10000000000000000));
    }
  }

  /**
   * @dev Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
    require (x > 0);

    int256 msb = 0;
    int256 xc = x;
    if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
    if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
    if (xc >= 0x10000) { xc >>= 16; msb += 16; }
    if (xc >= 0x100) { xc >>= 8; msb += 8; }
    if (xc >= 0x10) { xc >>= 4; msb += 4; }
    if (xc >= 0x4) { xc >>= 2; msb += 2; }
    if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

    int256 result = msb - 64 << 64;
    uint256 ux = uint256 (uint128 (x)) << uint256(127 - msb);
    for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
      ux *= ux;
      uint256 b = ux >> 255;
      ux >>= 127 + b;
      result += bit * int256 (b);
    }

    return int128 (result);
    }
  }

  /**
   * @dev Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
    require (x > 0);

    return int128 ( uint128 (
        uint256 (uint128 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * @dev Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    uint256 result = 0x80000000000000000000000000000000;

    if (x & 0x8000000000000000 > 0)
      result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
    if (x & 0x4000000000000000 > 0)
      result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
    if (x & 0x2000000000000000 > 0)
      result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
    if (x & 0x1000000000000000 > 0)
      result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
    if (x & 0x800000000000000 > 0)
      result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
    if (x & 0x400000000000000 > 0)
      result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
    if (x & 0x200000000000000 > 0)
      result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
    if (x & 0x100000000000000 > 0)
      result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
    if (x & 0x80000000000000 > 0)
      result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
    if (x & 0x40000000000000 > 0)
      result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
    if (x & 0x20000000000000 > 0)
      result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
    if (x & 0x10000000000000 > 0)
      result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
    if (x & 0x8000000000000 > 0)
      result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
    if (x & 0x4000000000000 > 0)
      result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
    if (x & 0x2000000000000 > 0)
      result = result * 0x1000162E525EE054754457D5995292026 >> 128;
    if (x & 0x1000000000000 > 0)
      result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
    if (x & 0x800000000000 > 0)
      result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
    if (x & 0x400000000000 > 0)
      result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
    if (x & 0x200000000000 > 0)
      result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
    if (x & 0x100000000000 > 0)
      result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
    if (x & 0x80000000000 > 0)
      result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
    if (x & 0x40000000000 > 0)
      result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
    if (x & 0x20000000000 > 0)
      result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
    if (x & 0x10000000000 > 0)
      result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
    if (x & 0x8000000000 > 0)
      result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
    if (x & 0x4000000000 > 0)
      result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
    if (x & 0x2000000000 > 0)
      result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
    if (x & 0x1000000000 > 0)
      result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
    if (x & 0x800000000 > 0)
      result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
    if (x & 0x400000000 > 0)
      result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
    if (x & 0x200000000 > 0)
      result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
    if (x & 0x100000000 > 0)
      result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
    if (x & 0x80000000 > 0)
      result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
    if (x & 0x40000000 > 0)
      result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
    if (x & 0x20000000 > 0)
      result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
    if (x & 0x10000000 > 0)
      result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
    if (x & 0x8000000 > 0)
      result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
    if (x & 0x4000000 > 0)
      result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
    if (x & 0x2000000 > 0)
      result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
    if (x & 0x1000000 > 0)
      result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
    if (x & 0x800000 > 0)
      result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
    if (x & 0x400000 > 0)
      result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
    if (x & 0x200000 > 0)
      result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
    if (x & 0x100000 > 0)
      result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
    if (x & 0x80000 > 0)
      result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
    if (x & 0x40000 > 0)
      result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
    if (x & 0x20000 > 0)
      result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
    if (x & 0x10000 > 0)
      result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
    if (x & 0x8000 > 0)
      result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
    if (x & 0x4000 > 0)
      result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
    if (x & 0x2000 > 0)
      result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
    if (x & 0x1000 > 0)
      result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
    if (x & 0x800 > 0)
      result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
    if (x & 0x400 > 0)
      result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
    if (x & 0x200 > 0)
      result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
    if (x & 0x100 > 0)
      result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
    if (x & 0x80 > 0)
      result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
    if (x & 0x40 > 0)
      result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
    if (x & 0x20 > 0)
      result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
    if (x & 0x10 > 0)
      result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
    if (x & 0x8 > 0)
      result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
    if (x & 0x4 > 0)
      result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
    if (x & 0x2 > 0)
      result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
    if (x & 0x1 > 0)
      result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

    result >>= uint256( uint128 (63 - (x >> 64)));
    require (result <= uint256 (uint128 (MAX_64x64)));

    return int128 (uint128 (result));
    }
  }

  /**
   * @dev Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    return exp_2 (
        int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * @dev Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
    require (y != 0);

    uint256 result;

    if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      result = (x << 64) / y;
    else {
      uint256 msb = 192;
      uint256 xc = x >> 192;
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 hi = result * (y >> 128);
      uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 xh = x >> 192;
      uint256 xl = x << 64;

      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here
      lo = hi << 128;
      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here

      assert (xh == hi >> 128);

      result += xl / y;
    }

    require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    return uint128 (result);
    }
  }

  /**
   * @dev Calculate x^y assuming 0^0 is 1, where x is unsigned 129.127 fixed point
   * number and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x unsigned 129.127-bit fixed point number
   * @param y uint256 value
   * @return unsigned 129.127-bit fixed point number
   */
  function powu (uint256 x, uint256 y) private pure returns (uint256) {
    unchecked {
    if (y == 0) return 0x80000000000000000000000000000000;
    else if (x == 0) return 0;
    else {
      int256 msb = 0;
      uint256 xc = x;
      if (xc >= 0x100000000000000000000000000000000) { xc >>= 128; msb += 128; }
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 xe = msb - 127;
      if (xe > 0) x >>= uint256(xe);
      else x <<= uint256(-xe);

      uint256 result = 0x80000000000000000000000000000000;
      int256 re = 0;

      while (y > 0) {
        if (y & 1 > 0) {
          result = result * x;
          y -= 1;
          re += xe;
          if (result >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            result >>= 128;
            re += 1;
          } else result >>= 127;
          if (re < -127) return 0; // Underflow
          require (re < 128); // Overflow
        } else {
          x = x * x;
          y >>= 1;
          xe <<= 1;
          if (x >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            x >>= 128;
            xe += 1;
          } else x >>= 127;
          if (xe < -127) return 0; // Underflow
          require (xe < 128); // Overflow
        }
      }

      if (re > 0) result <<= uint256(re);
      else if (re < 0) result >>= uint256(-re);

      return result;
    }
    }
  }

  /**
   * @dev Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x, uint256 r) private pure returns (uint128) {
    unchecked {
    if (x == 0) return 0;
    else {
      require (r > 0);
      while (true) {
        uint256 rr = x / r;
        if (r == rr || r + 1 == rr) return uint128 (r);
        else if (r == rr + 1) return uint128 (rr);
        r = r + rr + 1 >> 1;
      }
    }
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.0;


library PoolDataTypes {
  enum TokenType { BASE, FYTOKEN, LP }

  enum Operation {
    ROUTE, // 0
    TRANSFER_TO_POOL, // 1
    FORWARD_PERMIT, // 2
    FORWARD_DAI_PERMIT, // 3
    JOIN_ETHER, // 4
    EXIT_ETHER // 5
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import "@yield-protocol/vault-interfaces/IOracle.sol";


/// @dev An oracle that allows to set the spot price to anyone. It also allows to record spot values and return the accrual between a recorded and current spots.
contract OracleMock is IOracle {

    address public immutable source;

    uint256 public spot;
    uint256 public updated;

    constructor() {
        source = address(this);
    }

    /// @dev Return the value of the amount at the spot price.
    function peek(bytes32, bytes32, uint256 amount) external view virtual override returns (uint256, uint256) {
        return (spot * amount / 1e18, updated);
    }

    /// @dev Return the value of the amount at the spot price.
    function get(bytes32, bytes32, uint256 amount) external virtual override returns (uint256, uint256) {
        updated = block.timestamp;
        return (spot * amount / 1e18, updated = block.timestamp);
    }

    /// @dev Set the spot price with 18 decimals. Overriding contracts with different formats must convert from 18 decimals.
    function set(uint256 spot_) external virtual {
        updated = block.timestamp;
        spot = spot_;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
import "@yield-protocol/utils-v2/contracts/token/ERC20.sol";

pragma solidity ^0.8.0;


contract WETH9Mock is ERC20 {
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    constructor () ERC20("Wrapped Ether", "WETH", 18) { }

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        _balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint wad) public {
        require(_balanceOf[msg.sender] >= wad, "WETH9: Insufficient balance");
        _balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view override returns (uint) {
        return address(this).balance;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import "@yield-protocol/utils-v2/contracts/token/ERC20.sol";


contract DaiMock is ERC20  {

    mapping (address => uint)                      public nonces;

    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
    string  public constant version  = "1";

    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol, 18) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId,
            address(this)
        ));
    }

    /// @dev Give tokens to whoever asks for them.
    function mint(address to, uint256 amount) public virtual {
        _mint(to, amount);
    }

    // --- Approve by signature ---
    function permit(address holder, address spender, uint256 nonce, uint256 expiry,
                    bool allowed, uint8 v, bytes32 r, bytes32 s) external
    {
        bytes32 digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH,
                                     holder,
                                     spender,
                                     nonce,
                                     expiry,
                                     allowed))
        ));

        require(holder != address(0), "Dai/invalid-address-0");
        require(holder == ecrecover(digest, v, r, s), "Dai/invalid-permit");
        require(expiry == 0 || block.timestamp <= expiry, "Dai/permit-expired");
        require(nonce == nonces[holder]++, "Dai/invalid-nonce");
        uint wad = allowed ? type(uint256).max : 0;
        _allowance[holder][spender] = wad;
        emit Approval(holder, spender, wad);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.0;
import "@yield-protocol/utils-v2/contracts/token/ERC20Permit.sol";


contract USDCMock is ERC20Permit {

    constructor() ERC20Permit("USD Coin", "USDC", 6) { }

    function version() public pure override returns(string memory) { return "2"; }

    /// @dev Give tokens to whoever asks for them.
    function mint(address to, uint256 amount) public virtual {
        _mint(to, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import "@yield-protocol/utils-v2/contracts/token/ERC20Permit.sol";


contract ERC20Mock is ERC20Permit  {

    constructor(
        string memory name,
        string memory symbol
    ) ERC20Permit(name, symbol, 18) { }

    /// @dev Give tokens to whoever asks for them.
    function mint(address to, uint256 amount) public virtual {
        _mint(to, amount);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 5000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {
    "@yield-protocol/utils-v2/contracts/token/SafeERC20Namer.sol": {
      "SafeERC20Namer": "0x1fd4C043c74Acfb36FCD8F7EcCD08b1c14E4545A"
    },
    "@yield-protocol/yieldspace-v2/contracts/YieldMath.sol": {
      "YieldMath": "0x227f4d7a2ca2c88ed53ff19cd69886538d623072"
    }
  }
}