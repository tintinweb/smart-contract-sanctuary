// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.1;
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
        external
        auth    
    {
        borrowingFee = fee;
        emit FeeSet(fee);
    }

    // ---- Batching ----

    /// @dev Return the cached vault if necessary, preceded by the current vaultId (needed if vaultId == bytes(0)) and cachedId (which is the same as the vaultId)
    /// If refreshing the cache, verifies that msg.sender is the owner of the vault
    function getCachedVault(bytes12 vaultId, bytes12 cachedId, DataTypes.Vault memory vault)
        private view
        returns (bytes12, bytes12, DataTypes.Vault memory)
    {
        require(vaultId != bytes12(0) || cachedId != bytes12(0), "Vault not cached");           // Can't use the cache
        if (vaultId == bytes12(0) || vaultId == cachedId) return (cachedId, cachedId, vault);   // Use the cache
        else return (vaultId, vaultId, getOwnedVault(vaultId));                                 // Refresh the cache
    } 

    /// @dev Submit a series of calls for execution.
    /// Unlike `batch`, this function calls private functions, saving a CALL per function.
    /// It also caches the vault, which is useful in `build` + `pour` and `build` + `serve` combinations.
    function batch(
        Operation[] calldata operations,
        bytes[] calldata data
    ) external payable returns(bytes[] memory results) {
        require(operations.length == data.length, "Mismatched operation data");
        bytes12 cachedId;
        DataTypes.Vault memory vault;

        results = new bytes[](operations.length);

        // Execute all operations in the batch. Conditionals ordered by expected frequency.
        for (uint256 i = 0; i < operations.length; i += 1) {

            Operation operation = operations[i];

            if (operation == Operation.BUILD) {
                (bytes6 seriesId, bytes6 ilkId) = abi.decode(data[i], (bytes6, bytes6));
                (cachedId, vault) = _build(seriesId, ilkId, 0);   // Cache the vault that was just built
                results[i] = abi.encode(cachedId);  // We only return the data that changed
            
            } else if (operation == Operation.FORWARD_PERMIT) {
                (bytes6 id, bool isAsset, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) =
                    abi.decode(data[i], (bytes6, bool, address, uint256, uint256, uint8, bytes32, bytes32));
                _forwardPermit(id, isAsset, spender, amount, deadline, v, r, s);
                results[i] = abi.encode(true);
            
            } else if (operation == Operation.JOIN_ETHER) {
                (bytes6 etherId) = abi.decode(data[i], (bytes6));
                results[i] = abi.encode(_joinEther(etherId));
            
            } else if (operation == Operation.POUR) {
                (bytes12 vaultId, address to, int128 ink, int128 art) = abi.decode(data[i], (bytes12, address, int128, int128));
                (vaultId, cachedId, vault) = getCachedVault(vaultId, cachedId, vault);
                _pour(vaultId, vault, to, ink, art);
                results[i] = abi.encode(true);
            
            } else if (operation == Operation.SERVE) {
                (bytes12 vaultId, address to, uint128 ink, uint128 base, uint128 max) = abi.decode(data[i], (bytes12, address, uint128, uint128, uint128));
                (vaultId, cachedId, vault) = getCachedVault(vaultId, cachedId, vault);
                results[i] = abi.encode(_serve(vaultId, vault, to, ink, base, max));

            } else if (operation == Operation.ROLL) {
                (bytes12 vaultId, bytes6 newSeriesId, uint8 loan, uint128 max) = abi.decode(data[i], (bytes12, bytes6, uint8, uint128));
                (vaultId, cachedId, vault) = getCachedVault(vaultId, cachedId, vault);
                uint256 newDebt;
                (vault, newDebt) = _roll(vaultId, vault, newSeriesId, loan, max);
                results[i] = abi.encode(newDebt);
            
            } else if (operation == Operation.FORWARD_DAI_PERMIT) {
                (bytes6 id, bool isAsset, address spender, uint256 nonce, uint256 deadline, bool allowed, uint8 v, bytes32 r, bytes32 s) =
                    abi.decode(data[i], (bytes6, bool, address, uint256, uint256, bool, uint8, bytes32, bytes32));
                _forwardDaiPermit(id, isAsset, spender, nonce, deadline, allowed, v, r, s);
                results[i] = abi.encode(true);
            
            } else if (operation == Operation.TRANSFER_TO_POOL) {
                (bytes6 seriesId, bool base, uint128 wad) =
                    abi.decode(data[i], (bytes6, bool, uint128));
                IPool pool = getPool(seriesId);
                _transferToPool(pool, base, wad);
                results[i] = abi.encode(true);
            
            } else if (operation == Operation.ROUTE) {
                (bytes6 seriesId, bytes memory poolCall) =
                    abi.decode(data[i], (bytes6, bytes));
                IPool pool = getPool(seriesId);
                results[i] = _route(pool, poolCall);
            
            } else if (operation == Operation.EXIT_ETHER) {
                (address to) = abi.decode(data[i], (address));
                results[i] = abi.encode(_exitEther(payable(to)));
            
            } else if (operation == Operation.CLOSE) {
                (bytes12 vaultId, address to, int128 ink, int128 art) = abi.decode(data[i], (bytes12, address, int128, int128));
                (vaultId, cachedId, vault) = getCachedVault(vaultId, cachedId, vault);
                results[i] = abi.encode(_close(vaultId, vault, to, ink, art));
            
            } else if (operation == Operation.REPAY) {
                (bytes12 vaultId, address to, int128 ink, uint128 min) = abi.decode(data[i], (bytes12, address, int128, uint128));
                (vaultId, cachedId, vault) = getCachedVault(vaultId, cachedId, vault);
                results[i] = abi.encode(_repay(vaultId, vault, to, ink, min));
            
            } else if (operation == Operation.REPAY_VAULT) {
                (bytes12 vaultId, address to, int128 ink, uint128 max) = abi.decode(data[i], (bytes12, address, int128, uint128));
                (vaultId, cachedId, vault) = getCachedVault(vaultId, cachedId, vault);
                results[i] = abi.encode(_repayVault(vaultId, vault, to, ink, max));

            } else if (operation == Operation.REPAY_LADLE) {
                (bytes12 vaultId) = abi.decode(data[i], (bytes12));
                (vaultId, cachedId, vault) = getCachedVault(vaultId, cachedId, vault);
                results[i] = abi.encode(_repayLadle(vaultId, vault));

            } else if (operation == Operation.RETRIEVE) {
                (bytes6 assetId, bool isAsset, address to) = abi.decode(data[i], (bytes6, bool, address));
                results[i] = abi.encode(_retrieve(assetId, isAsset, to));

            } else if (operation == Operation.TRANSFER_TO_FYTOKEN) {
                (bytes6 seriesId, uint256 amount) = abi.decode(data[i], (bytes6, uint256));
                IFYToken fyToken = getSeries(seriesId).fyToken;
                _transferToFYToken(fyToken, amount);
                results[i] = abi.encode(true);
            
            } else if (operation == Operation.REDEEM) {
                (bytes6 seriesId, address to, uint256 amount) = abi.decode(data[i], (bytes6, address, uint256));
                IFYToken fyToken = getSeries(seriesId).fyToken;
                results[i] = abi.encode(_redeem(fyToken, to, amount));
            
            } else if (operation == Operation.STIR) {
                (bytes12 from, bytes12 to, uint128 ink, uint128 art) = abi.decode(data[i], (bytes12, bytes12, uint128, uint128));
                _stir(from, to, ink, art);  // Too complicated to use caching here
                results[i] = abi.encode(true);
            
            } else if (operation == Operation.TWEAK) {
                (bytes12 vaultId, bytes6 seriesId, bytes6 ilkId) = abi.decode(data[i], (bytes12, bytes6, bytes6));
                (vaultId, cachedId, vault) = getCachedVault(vaultId, cachedId, vault);  // Needed to verify ownership
                vault = _tweak(vaultId, seriesId, ilkId);
                results[i] = abi.encode(true);

            } else if (operation == Operation.GIVE) {
                (bytes12 vaultId, address to) = abi.decode(data[i], (bytes12, address));
                (vaultId, cachedId, vault) = getCachedVault(vaultId, cachedId, vault);  // Needed to verify ownership
                _give(vaultId, to);
                results[i] = abi.encode(true);
                delete vault;   // Clear the cache, since the vault doesn't necessarily belong to msg.sender anymore
                cachedId = bytes12(0);

            } else if (operation == Operation.DESTROY) {
                (bytes12 vaultId) = abi.decode(data[i], (bytes12));
                (vaultId, cachedId, vault) = getCachedVault(vaultId, cachedId, vault);  // Needed to verify ownership
                _destroy(vaultId);
                results[i] = abi.encode(true);
                delete vault;   // Clear the cache
                cachedId = bytes12(0);
            
            } else if (operation == Operation.MODULE) {
                (address module, bytes memory moduleCall) = abi.decode(data[i], (address, bytes));
                results[i] = _moduleCall(module, moduleCall);
            
            }
        }
    }

    // ---- Vault management ----

    /// @dev Generate a vaultId. A keccak256 is cheaper than using a counter with a SSTORE, even accounting for eventual collision retries.
    function _generateVaultId(uint8 salt) private view returns (bytes12) {
        return bytes12(keccak256(abi.encodePacked(msg.sender, block.timestamp, salt)));
    }

    /// @dev Create a new vault, linked to a series (and therefore underlying) and a collateral
    function _build(bytes6 seriesId, bytes6 ilkId, uint8 salt)
        private
        returns(bytes12, DataTypes.Vault memory)
    {
        bytes12 vaultId = _generateVaultId(salt);
        try cauldron.build(msg.sender, vaultId, seriesId, ilkId) returns (DataTypes.Vault memory vault) {
            return (vaultId, vault);
        } catch Error (string memory) {
            return _build(seriesId, ilkId, salt + 1);
        }
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
    {
        if (ink > 0) require (cauldron.vaults(from).owner == msg.sender, "Only origin vault owner");
        if (art > 0) require (cauldron.vaults(to).owner == msg.sender, "Only destination vault owner");
        cauldron.stir(from, to, ink, art);
    }

    /// @dev Add collateral and borrow from vault, pull assets from and push borrowed asset to user
    /// Or, repay to vault and remove collateral, pull borrowed asset from and push assets to user
    /// Borrow only before maturity.
    function _pour(bytes12 vaultId, DataTypes.Vault memory vault, address to, int128 ink, int128 art)
        private
    {
        DataTypes.Series memory series;
        if (art != 0) series = getSeries(vault.seriesId);

        int128 fee;
        if (art > 0) fee = ((series.maturity - block.timestamp) * uint256(int256(art)).wmul(borrowingFee)).u128().i128();

        // Update accounting
        cauldron.pour(vaultId, ink, art + fee);

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
        returns (uint128 art)
    {
        IPool pool = getPool(vault.seriesId);
        
        art = pool.buyBasePreview(base);
        _pour(vaultId, vault, address(pool), ink.i128(), art.i128());
        pool.buyBase(to, base, max);
    }

    /// @dev Repay vault debt using underlying token at a 1:1 exchange rate, without trading in a pool.
    /// It can add or remove collateral at the same time.
    /// The debt to repay is denominated in fyToken, even if the tokens pulled from the user are underlying.
    /// The debt to repay must be entered as a negative number, as with `pour`.
    /// Debt cannot be acquired with this function.
    function _close(bytes12 vaultId, DataTypes.Vault memory vault, address to, int128 ink, int128 art)
        private
        returns (uint128 base)
    {
        require (art < 0, "Only repay debt");                                          // When repaying debt in `frob`, art is a negative value. Here is the same for consistency.

        // Calculate debt in fyToken terms
        DataTypes.Series memory series = getSeries(vault.seriesId);
        base = cauldron.debtToBase(vault.seriesId, uint128(-art));

        // Update accounting
        cauldron.pour(vaultId, ink, art);

        // Manage collateral
        if (ink != 0) {
            IJoin ilkJoin = getJoin(vault.ilkId);
            if (ink > 0) ilkJoin.join(vault.owner, uint128(ink));
            if (ink < 0) ilkJoin.exit(to, uint128(-ink));
        }

        // Manage underlying
        IJoin baseJoin = getJoin(series.baseId);
        baseJoin.join(msg.sender, base);
    }

    /// @dev Repay debt by selling base in a pool and using the resulting fyToken
    /// The base tokens need to be already in the pool, unaccounted for.
    /// Only before maturity. After maturity use close.
    function _repay(bytes12 vaultId, DataTypes.Vault memory vault, address to, int128 ink, uint128 min)
        private
        returns (uint128 art)
    {
        DataTypes.Series memory series = getSeries(vault.seriesId);
        IPool pool = getPool(vault.seriesId);

        art = pool.sellBase(address(series.fyToken), min);
        _pour(vaultId, vault, to, ink, -(art.i128()));
    }

    /// @dev Repay all debt in a vault by buying fyToken from a pool with base.
    /// The base tokens need to be already in the pool, unaccounted for. The surplus base will be returned to msg.sender.
    /// Only before maturity. After maturity use close.
    function _repayVault(bytes12 vaultId, DataTypes.Vault memory vault, address to, int128 ink, uint128 max)
        private
        returns (uint128 base)
    {
        DataTypes.Series memory series = getSeries(vault.seriesId);
        IPool pool = getPool(vault.seriesId);

        DataTypes.Balances memory balances = cauldron.balances(vaultId);
        base = pool.buyFYToken(address(series.fyToken), balances.art, max);
        _pour(vaultId, vault, to, ink, -(balances.art.i128()));
        pool.retrieveBase(msg.sender);
    }

    /// @dev Change series and debt of a vault.
    function _roll(bytes12 vaultId, DataTypes.Vault memory vault, bytes6 newSeriesId, uint8 loan, uint128 max)
        private
        returns (DataTypes.Vault memory vault_, uint128 newDebt)
    {
        DataTypes.Series memory series = getSeries(vault.seriesId);
        DataTypes.Series memory newSeries = getSeries(newSeriesId);
        DataTypes.Balances memory balances = cauldron.balances(vaultId);
        
        {
            IPool pool = getPool(newSeriesId);
            IFYToken fyToken = IFYToken(newSeries.fyToken);
            IJoin baseJoin = getJoin(series.baseId);

            // Calculate debt in fyToken terms
            uint128 base = cauldron.debtToBase(vault.seriesId, balances.art);

            // Mint fyToken to the pool, as a kind of flash loan
            fyToken.mint(address(pool), base * loan);                // Loan is the size of the flash loan relative to the debt amount, 2 should be safe most of the time

            // Buy the base required to pay off the debt in series 1, and find out the debt in series 2
            newDebt = pool.buyBase(address(baseJoin), base, max);
            baseJoin.join(address(baseJoin), base);                  // Repay the old series debt

            pool.retrieveFYToken(address(fyToken));                 // Get the surplus fyToken
            fyToken.burn(address(fyToken), (base * loan) - newDebt);    // Burn the surplus
        }

        newDebt += ((newSeries.maturity - block.timestamp) * uint256(newDebt).wmul(borrowingFee)).u128();  // Add borrowing fee, also stops users form rolling to a mature series

        (vault_,) = cauldron.roll(vaultId, newSeriesId, newDebt.i128() - balances.art.i128()); // Change the series and debt for the vault
        
        return (vault_, newDebt);
    }

    // ---- Ladle as a token holder ----

    /// @dev Use fyToken in the Ladle to repay debt.
    function _repayLadle(bytes12 vaultId, DataTypes.Vault memory vault)
        private
        returns (uint256 repaid)
    {
        DataTypes.Series memory series = getSeries(vault.seriesId);
        DataTypes.Balances memory balances = cauldron.balances(vaultId);
        
        uint256 amount = series.fyToken.balanceOf(address(this));
        repaid = amount <= balances.art ? amount : balances.art;

        // Update accounting
        cauldron.pour(vaultId, 0, -(repaid.u128().i128()));
        series.fyToken.burn(address(this), repaid);
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
    receive() external payable { 
        require (msg.sender == address(weth), "Only receive from WETH");
    }

    /// @dev Accept Ether, wrap it and forward it to the WethJoin
    /// This function should be called first in a batch, and the Join should keep track of stored reserves
    /// Passing the id for a join that doesn't link to a contract implemnting IWETH9 will fail
    function _joinEther(bytes6 etherId)
        private
        returns (uint256 ethTransferred)
    {
        ethTransferred = address(this).balance;
        IJoin wethJoin = getJoin(etherId);
        weth.deposit{ value: ethTransferred }();
        IERC20(address(weth)).safeTransfer(address(wethJoin), ethTransferred);
    }

    /// @dev Unwrap Wrapped Ether held by this Ladle, and send the Ether
    /// This function should be called last in a batch, and the Ladle should have no reason to keep an WETH balance
    function _exitEther(address payable to)
        private
        returns (uint256 ethTransferred)
    {
        ethTransferred = weth.balanceOf(address(this));
        weth.withdraw(ethTransferred);
        to.safeTransferETH(ethTransferred);
    }

    // ---- Pool router ----

    /// @dev Allow users to trigger a token transfer to a pool through the ladle, to be used with batch
    function _transferToPool(IPool pool, bool isBase, uint128 wad)
        private
    {
        IERC20 token = isBase ? pool.base() : pool.fyToken();
        token.safeTransferFrom(msg.sender, address(pool), wad);
    }

    /// @dev Allow users to route calls to a pool, to be used with batch
    function _route(IPool pool, bytes memory data)
        private
        returns (bytes memory result)
    {
        bool success;
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
    /// @notice Modules must not do any changes to the vault (owner, seriesId, ilkId),
    /// it would be disastrous in combination with batch vault caching 
    function _moduleCall(address module, bytes memory moduleCall)
        private
        returns (bytes memory result)
    {
        require (modules[module], "Unregistered module");
        bool success;
        (success, result) = module.delegatecall(moduleCall);
        if (!success) revert(RevertMsgExtractor.getRevertMsg(result));
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

    // ==== Helpers ====

    /// @dev Convert a debt amount for a series from base to fyToken terms.
    /// @notice Think about rounding if using, since we are dividing.
    function debtFromBase(bytes6 seriesId, uint128 base) external returns (uint128 art);

    /// @dev Convert a debt amount for a series from fyToken to base terms
    function debtToBase(bytes6 seriesId, uint128 art) external returns (uint128 base);

    // ==== Accounting ====

    /// @dev Record the borrowing rate at maturity for a series
    function mature(bytes6 seriesId) external;
    
    /// @dev Retrieve the rate accrual since maturity, maturing if necessary.
    function accrual(bytes6 seriesId) external returns (uint256);
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
    function burn(address to, uint256 minBaseOut, uint256 minFYTokenOut) external returns (uint256, uint256, uint256);
    function burnForBase(address to, uint256 minBaseOut) external returns (uint256, uint256);
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

// SPDX-License-Identifier: MIT
import "../token/IERC20.sol";

pragma solidity ^0.8.0;


interface IWETH9 is IERC20 {
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    function deposit() external payable;
    function withdraw(uint wad) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.1;


library WMul {
    // Taken from https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol
    /// @dev Multiply an amount by a fixed point factor with 18 decimals, rounds down.
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
        unchecked { z /= 1e18; }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.1;


library CastU256U128 {
    /// @dev Safely cast an uint256 to an uint128
    function u128(uint256 x) internal pure returns (uint128 y) {
        require (x <= type(uint128).max, "Cast overflow");
        y = uint128(x);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.1;


library CastU128I128 {
    /// @dev Safely cast an uint128 to an int128
    function i128(uint128 x) internal pure returns (int128 y) {
        require (x <= uint128(type(int128).max), "Cast overflow");
        y = int128(x);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.1;
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

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
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
  "libraries": {}
}