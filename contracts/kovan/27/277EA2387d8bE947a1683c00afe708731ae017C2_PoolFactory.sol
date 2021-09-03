// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

import "@yield-protocol/utils-v2/contracts/access/AccessControl.sol";
import "@yield-protocol/yieldspace-interfaces/IPoolFactory.sol";
import "./Pool.sol";


/// @dev The PoolFactory can deterministically create new pool instances.
contract PoolFactory is IPoolFactory, AccessControl {
  event ParameterSet(bytes32 parameter, int128 value);

  /// Pre-hashing the bytecode allows calculatePoolAddress to be cheaper, and
  /// makes client-side address calculation easier
  bytes32 public constant override POOL_BYTECODE_HASH = keccak256(type(Pool).creationCode);

  address public override nextBase;
  address public override nextFYToken;
  int128 public override k = int128(uint128(uint256((1 << 64))) / 315576000); // 1 / Seconds in 10 years, in 64.64
  int128 public override g1 = int128(uint128(uint256((950 << 64))) / 1000); // To be used when selling base to the pool. All constants are `ufixed`, to divide them they must be converted to uint256
  int128 public override g2 = int128(uint128(uint256((1000 << 64))) / 950); // To be used when selling fyToken to the pool. All constants are `ufixed`, to divide them they must be converted to uint256

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
  function createPool(address base, address fyToken)
    external override
    auth
    returns (address)
  {
    nextBase = base;
    nextFYToken = fyToken;
    Pool pool = new Pool{salt: keccak256(abi.encodePacked(base, fyToken))}();
    nextBase = address(0);
    nextFYToken = address(0);
    
    emit PoolCreated(base, fyToken, address(pool));

    return address(pool);
  }

  /// @dev Set the k, g1 or g2 parameters
  function setParameter(bytes32 parameter, int128 value)
      external
      auth
  {
      if (parameter == "k") k = value;
      else if (parameter == "g1") g1 = value;
      else if (parameter == "g2") g2 = value;
      else revert("Pool: Unrecognized parameter");
      emit ParameterSet(parameter, value);
  }
}

// SPDX-License-Identifier: MIT

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


interface IPoolFactory {
  event PoolCreated(address indexed base, address indexed fyToken, address pool);

  function POOL_BYTECODE_HASH() external pure returns (bytes32);
  function calculatePoolAddress(address base, address fyToken) external view returns (address);
  function getPool(address base, address fyToken) external view returns (address);
  function createPool(address base, address fyToken) external returns (address);
  function nextBase() external view returns (address);
  function nextFYToken() external view returns (address);
  function k() external view returns (int128);
  function g1() external view returns (int128);
  function g2() external view returns (int128);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC20Metadata.sol";
import "@yield-protocol/utils-v2/contracts/token/ERC20Permit.sol";
import "@yield-protocol/utils-v2/contracts/token/SafeERC20Namer.sol";
import "@yield-protocol/utils-v2/contracts/token/MinimalTransferHelper.sol";
import "@yield-protocol/utils-v2/contracts/cast/CastU256U128.sol";
import "@yield-protocol/utils-v2/contracts/cast/CastU256U112.sol";
import "@yield-protocol/utils-v2/contracts/cast/CastU256I256.sol";
import "@yield-protocol/utils-v2/contracts/cast/CastU128U112.sol";
import "@yield-protocol/utils-v2/contracts/cast/CastU128I128.sol";
import "@yield-protocol/yieldspace-interfaces/IPool.sol";
import "@yield-protocol/yieldspace-interfaces/IPoolFactory.sol";
import "@yield-protocol/vault-interfaces/IFYToken.sol";
import "./YieldMath.sol";


/// @dev The Pool contract exchanges base for fyToken at a price defined by a specific formula.
contract Pool is IPool, ERC20Permit {
    using CastU256U128 for uint256;
    using CastU256U112 for uint256;
    using CastU256I256 for uint256;
    using CastU128U112 for uint128;
    using CastU128I128 for uint128;
    using MinimalTransferHelper for IERC20;

    event Trade(uint32 maturity, address indexed from, address indexed to, int256 bases, int256 fyTokens);
    event Liquidity(uint32 maturity, address indexed from, address indexed to, address indexed fyTokenTo, int256 bases, int256 fyTokens, int256 poolTokens);
    event Sync(uint112 baseCached, uint112 fyTokenCached, uint256 cumulativeBalancesRatio);

    int128 public immutable k;              // 1 / Seconds in 10 years, in 64.64
    int128 public immutable g1;             // To be used when selling base to the pool
    int128 public immutable g2;             // To be used when selling fyToken to the pool
    uint32 public immutable override maturity;
    uint96 public immutable scaleFactor;    // Scale up to 18 low decimal tokens to get the right precision in YieldMath

    IERC20 public immutable override base;
    IFYToken public immutable override fyToken;

    uint112 private baseCached;              // uses single storage slot, accessible via getCache
    uint112 private fyTokenCached;           // uses single storage slot, accessible via getCache
    uint32  private blockTimestampLast;      // uses single storage slot, accessible via getCache

    uint256 public cumulativeBalancesRatio;  // Fixed point factor with 27 decimals (ray)

    constructor()
        ERC20Permit(
            string(abi.encodePacked("Yield ", SafeERC20Namer.tokenName(IPoolFactory(msg.sender).nextFYToken()), " LP Token")),
            string(abi.encodePacked(SafeERC20Namer.tokenSymbol(IPoolFactory(msg.sender).nextFYToken()), "LP")),
            SafeERC20Namer.tokenDecimals(IPoolFactory(msg.sender).nextBase())
        )
    {
        IPoolFactory _factory = IPoolFactory(msg.sender);
        IFYToken _fyToken = IFYToken(_factory.nextFYToken());
        IERC20 _base = IERC20(_factory.nextBase());
        fyToken = _fyToken;
        base = _base;

        uint256 _maturity = _fyToken.maturity();
        require (_maturity <= type(uint32).max, "Pool: Maturity too far in the future");
        maturity = uint32(_maturity);

        k = _factory.k();
        g1 = _factory.g1();
        g2 = _factory.g2();

        scaleFactor = uint96(10 ** (18 - SafeERC20Namer.tokenDecimals(address(_base))));
    }

    /// @dev Trading can only be done before maturity
    modifier beforeMaturity() {
        require(
            block.timestamp < maturity,
            "Pool: Too late"
        );
        _;
    }

    // ---- Balances management ----

    /// @dev Updates the cache to match the actual balances.
    function sync() external {
        _update(_getBaseBalance(), _getFYTokenBalance(), baseCached, fyTokenCached);
    }

    /// @dev Returns the cached balances & last updated timestamp.
    /// @return Cached base token balance.
    /// @return Cached virtual FY token balance.
    /// @return Timestamp that balances were last cached.
    function getCache()
        external view
        returns (uint112, uint112, uint32)
    {
        return (baseCached, fyTokenCached, blockTimestampLast);
    }

    /// @dev Returns the "virtual" fyToken balance, which is the real balance plus the pool token supply.
    function getFYTokenBalance()
        public view override
        returns(uint112)
    {
        return _getFYTokenBalance();
    }

    /// @dev Returns the base balance
    function getBaseBalance()
        public view override
        returns(uint112)
    {
        return _getBaseBalance();
    }

    /// @dev Returns the "virtual" fyToken balance, which is the real balance plus the pool token supply.
    function _getFYTokenBalance()
        internal view
        returns(uint112)
    {
        return (fyToken.balanceOf(address(this)) + _totalSupply).u112();
    }

    /// @dev Returns the base balance
    function _getBaseBalance()
        internal view
        returns(uint112)
    {
        return base.balanceOf(address(this)).u112();
    }

    /// @dev Retrieve any base tokens not accounted for in the cache
    function retrieveBase(address to)
        external override
        returns(uint128 retrieved)
    {
        retrieved = _getBaseBalance() - baseCached; // Cache can never be above balances
        base.safeTransfer(to, retrieved);
        // Now the current balances match the cache, so no need to update the TWAR
    }

    /// @dev Retrieve any fyTokens not accounted for in the cache
    function retrieveFYToken(address to)
        external override
        returns(uint128 retrieved)
    {
        retrieved = _getFYTokenBalance() - fyTokenCached; // Cache can never be above balances
        IERC20(address(fyToken)).safeTransfer(to, retrieved);
        // Now the balances match the cache, so no need to update the TWAR
    }

    /// @dev Update cache and, on the first call per block, ratio accumulators
    function _update(uint128 baseBalance, uint128 fyBalance, uint112 _baseCached, uint112 _fyTokenCached) private {
        uint32 blockTimestamp = uint32(block.timestamp);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _baseCached != 0 && _fyTokenCached != 0) {
            // We multiply by 1e27 here so that r = t * y/x is a fixed point factor with 27 decimals 
            uint256 scaledFYTokenCached = uint256(_fyTokenCached) * 1e27;
            cumulativeBalancesRatio += scaledFYTokenCached  * timeElapsed / _baseCached;
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

        emit Liquidity(maturity, msg.sender, to, address(0), -(baseIn.i256()), -(fyTokenIn.i256()), tokensMinted.i256());
        return (baseIn, fyTokenIn, tokensMinted);
    }

    /// @dev Burn liquidity tokens in exchange for base and fyToken.
    /// The liquidity tokens need to be in this contract.
    /// @param baseTo Wallet receiving the base.
    /// @param fyTokenTo Wallet receiving the fyToken.
    /// @return The amount of tokens burned and returned (tokensBurned, bases, fyTokens).
    function burn(address baseTo, address fyTokenTo, uint256 minBaseOut, uint256 minFYTokenOut)
        external override
        returns (uint256, uint256, uint256)
    {
        return _burnInternal(baseTo, fyTokenTo, false, minBaseOut, minFYTokenOut);
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
        (tokensBurned, baseOut, ) = _burnInternal(to, address(0), true, minBaseOut, 0);
    }


    /// @dev Burn liquidity tokens in exchange for base.
    /// The liquidity provider needs to have called `pool.approve`.
    /// @param baseTo Wallet receiving the base.
    /// @param fyTokenTo Wallet receiving the fyToken.
    /// @param tradeToBase Whether the resulting fyToken should be traded for base tokens.
    /// @return tokensBurned The amount of pool tokens burned.
    /// @return tokenOut The amount of base tokens returned.
    /// @return fyTokenOut The amount of fyTokens returned.
    function _burnInternal(address baseTo, address fyTokenTo, bool tradeToBase, uint256 minBaseOut, uint256 minFYTokenOut)
        internal
        returns (uint256 tokensBurned, uint256 tokenOut, uint256 fyTokenOut)
    {
        
        tokensBurned = _balanceOf[address(this)];
        uint256 supply = _totalSupply;
        uint256 fyTokenBalance = fyToken.balanceOf(address(this));          // use the real balance rather than the virtual one
        uint256 baseBalance = base.balanceOf(address(this));
        (uint112 _baseCached, uint112 _fyTokenCached) =
            (baseCached, fyTokenCached);

        // Calculate trade
        tokenOut = (tokensBurned * baseBalance) / supply;
        fyTokenOut = (tokensBurned * fyTokenBalance) / supply;

        if (tradeToBase) {
            tokenOut += YieldMath.baseOutForFYTokenIn(                      // This is a virtual sell
                (_baseCached - tokenOut.u128()) * scaleFactor,              // Cache, minus virtual burn
                (_fyTokenCached - fyTokenOut.u128()) * scaleFactor,         // Cache, minus virtual burn
                fyTokenOut.u128() * scaleFactor,                            // Sell the virtual fyToken obtained
                maturity - uint32(block.timestamp),                         // This can't be called after maturity
                k,
                g2
            ) / scaleFactor;
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
        base.safeTransfer(baseTo, tokenOut);
        if (fyTokenOut > 0) IERC20(address(fyToken)).safeTransfer(fyTokenTo, fyTokenOut);

        emit Liquidity(maturity, msg.sender, baseTo, fyTokenTo, tokenOut.i256(), fyTokenOut.i256(), -(tokensBurned.i256()));
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
        uint112 _baseBalance = _getBaseBalance();
        uint112 _fyTokenBalance = _getFYTokenBalance();
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
        uint128 fyTokenOut = YieldMath.fyTokenOutForBaseIn(
            baseBalance * scaleFactor,
            fyTokenBalance * scaleFactor,
            baseIn * scaleFactor,
            maturity - uint32(block.timestamp),             // This can't be called after maturity
            k,
            g1
        ) / scaleFactor;

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
        uint128 fyTokenBalance = _getFYTokenBalance();
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
        return YieldMath.fyTokenInForBaseOut(
            baseBalance * scaleFactor,
            fyTokenBalance * scaleFactor,
            tokenOut * scaleFactor,
            maturity - uint32(block.timestamp),             // This can't be called after maturity
            k,
            g2
        ) / scaleFactor;
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
        uint112 _fyTokenBalance = _getFYTokenBalance();
        uint112 _baseBalance = _getBaseBalance();
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
        return YieldMath.baseOutForFYTokenIn(
            baseBalance * scaleFactor,
            fyTokenBalance * scaleFactor,
            fyTokenIn * scaleFactor,
            maturity - uint32(block.timestamp),             // This can't be called after maturity
            k,
            g2
        ) / scaleFactor;
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
        uint128 baseBalance = _getBaseBalance();
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
        uint128 baseIn = YieldMath.baseInForFYTokenOut(
            baseBalance * scaleFactor,
            fyTokenBalance * scaleFactor,
            fyTokenOut * scaleFactor,
            maturity - uint32(block.timestamp),             // This can't be called after maturity
            k,
            g1
        ) / scaleFactor;

        require(
            fyTokenBalance - fyTokenOut >= baseBalance + baseIn,
            "Pool: fyToken balance too low"
        );

        return baseIn;
    }

    /// @dev Calculate the invariant for this pool
    function invariant()
        public view returns (uint128)
    {
        return YieldMath.invariant(
            getBaseBalance(),
            getFYTokenBalance(),
            _totalSupply,
            maturity - uint32(block.timestamp),
            k
        );
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

pragma solidity >=0.5.0;

import "../token/IERC20Metadata.sol";
import "../utils/AddressStringUtil.sol";

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
            return "";
        }
        // bytes32 data always has length 32
        if (data.length == 32) {
            bytes32 decoded = abi.decode(data, (bytes32));
            return bytes32ToString(decoded);
        } else if (data.length > 64) {
            return abi.decode(data, (string));
        }
        return "";
    }

    // attempts to extract the token symbol. if it does not implement symbol, returns a symbol derived from the address
    function tokenSymbol(address token) public view returns (string memory) {
        string memory symbol = callAndParseStringReturn(token, IERC20Metadata.symbol.selector);
        if (bytes(symbol).length == 0) {
            // fallback to 6 uppercase hex of address
            return addressToSymbol(token);
        }
        return symbol;
    }

    // attempts to extract the token name. if it does not implement name, returns a name derived from the address
    function tokenName(address token) public view returns (string memory) {
        string memory name = callAndParseStringReturn(token, IERC20Metadata.name.selector);
        if (bytes(name).length == 0) {
            // fallback to full hex of address
            return addressToName(token);
        }
        return name;
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function tokenDecimals(address token) public view returns (uint8) {
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(IERC20Metadata.decimals.selector));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/TransferHelper.sol

pragma solidity >=0.6.0;

import "./IERC20.sol";
import "../utils/RevertMsgExtractor.sol";


// helper methods for transferring ERC20 tokens that do not consistently return true/false
library MinimalTransferHelper {
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
pragma solidity ^0.8.0;


library CastU256U128 {
    /// @dev Safely cast an uint256 to an uint128
    function u128(uint256 x) internal pure returns (uint128 y) {
        require (x <= type(uint128).max, "Cast overflow");
        y = uint128(x);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library CastU256U112 {
    /// @dev Safely cast an uint256 to an uint112
    function u112(uint256 x) internal pure returns (uint112 y) {
        require (x <= type(uint112).max, "Cast overflow");
        y = uint112(x);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library CastU128U112 {
    /// @dev Safely cast an uint128 to an uint112
    function u112(uint128 x) internal pure returns (uint112 y) {
        require (x <= uint128(type(uint112).max), "Cast overflow");
        y = uint112(x);
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

// SPDX-License-Identifier: MIT
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
    function burn(address baseTo, address fyTokenTo, uint256 minBaseOut, uint256 minFYTokenOut) external returns (uint256, uint256, uint256);
    function burnForBase(address to, uint256 minBaseOut) external returns (uint256, uint256);
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
pragma solidity 0.8.6;

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

      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000;} /*
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) l |= 0x1; */

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
  uint256 public constant VAR = 1e12;                // The logarithm math used is not precise to the wei, but can deviate up to 1e12 from the real value.

  /**
   * Calculate a YieldSpace pool invariant according to the whitepaper
   */
  function invariant(uint128 baseReserves, uint128 fyTokenReserves, uint256 totalSupply, uint128 timeTillMaturity, int128 k)
      public pure returns(uint128)
  {
    if (totalSupply == 0) return 0;

    unchecked {
      // a = (1 - k * timeTillMaturity)
      int128 a = int128(ONE).sub(k.mul(timeTillMaturity.fromUInt()));
      require (a > 0, "YieldMath: Too far from maturity");

      uint256 sum =
      uint256(baseReserves.pow(uint128 (a), ONE)) +
      uint256(fyTokenReserves.pow(uint128 (a), ONE)) >> 1;
      require(sum < MAX, "YieldMath: Sum overflow");

      uint256 result = uint256(uint128(sum).pow(ONE, uint128(a))) / totalSupply;
      require (result < MAX, "YieldMath: Result overflow");

      return uint128(result);
    }
  }

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

      result = result > VAR ? result - VAR : 0; // Subtract error guard, flooring the result at zero

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

      result = result > VAR ? result - VAR : 0; // Subtract error guard, flooring the result at zero

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

      result = result < MAX - VAR ? result + VAR : MAX; // Add error guard, ceiling the result at max

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

      result = result < MAX - VAR ? result + VAR : MAX; // Add error guard, ceiling the result at max

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

// SPDX-License-Identifier: MIT
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

pragma solidity >=0.5.0;

library AddressStringUtil {
    // converts an address to the uppercase hex string, extracting only len bytes (up to 20, multiple of 2)
    function toAsciiString(address addr, uint256 len) internal pure returns (string memory) {
        require(len % 2 == 0 && len > 0 && len <= 40, "AddressStringUtil: INVALID_LEN");
        bytes memory s = new bytes(len);
        uint256 addrNum = uint256(uint160(addr));
        for (uint256 ii = 0; ii < len ; ii +=2) {
            uint8 b = uint8(addrNum >> (4 * (38 - ii)));
            s[ii] = char(b >> 4);
            s[ii + 1] = char(b & 0x0f);
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: BUSL-1.1
/*
 *  Math 64.64 Smart Contract Library.  Copyright © 2019 by  Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity 0.8.6;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library Math64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
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
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
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
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
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
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
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
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
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
   * Calculate x + y.  Revert on overflow.
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
   * Calculate x - y.  Revert on overflow.
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
   * Calculate x * y rounding down.  Revert on overflow.
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
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
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
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
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

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
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
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
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
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
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
   * Calculate -x.  Revert on overflow.
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
   * Calculate |x|.  Revert on overflow.
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
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
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
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
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
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
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
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
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
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
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
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
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

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
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
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
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
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x8) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1500
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
      "SafeERC20Namer": "0xfb1d3cc0cd8ae9cf73b3b4aeb5d508edb0691e5d"
    },
    "@yield-protocol/yieldspace-v2/contracts/YieldMath.sol": {
      "YieldMath": "0x323f233680945569ca4cc09a084b43ab9b37baf5"
    }
  }
}