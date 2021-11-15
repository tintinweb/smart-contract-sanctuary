// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./Dubi.sol";
import "./IHodl.sol";
import "./MintMath.sol";

contract Purpose is ERC20 {
    // The DUBI contract, required for auto-minting DUBI on burn.
    Dubi private immutable _dubi;

    // The HODL contract, required for burning locked PRPS.
    IHodl private immutable _hodl;

    modifier onlyHodl() {
        require(msg.sender == _hodlAddress, "PRPS-1");
        _;
    }

    constructor(
        uint256 initialSupply,
        address optIn,
        address dubi,
        address hodl,
        address externalAddress1,
        address externalAddress2,
        address externalAddress3
    )
        public
        ERC20(
            "Purpose",
            "PRPS",
            optIn,
            hodl,
            externalAddress1,
            externalAddress2,
            externalAddress3
        )
    {
        _dubi = Dubi(dubi);
        _hodl = IHodl(hodl);

        _mintInitialSupply(msg.sender, initialSupply);
    }

    /**
     * @dev Returns the address of the {HODL} contract used for burning locked PRPS.
     */
    function hodl() external view returns (address) {
        return address(_hodl);
    }

    /**
     * @dev Returns the hodl balance of the given `tokenHolder`
     */
    function hodlBalanceOf(address tokenHolder) public view returns (uint256) {
        // The hodl balance follows after the first 96 bits in the packed data.
        return uint96(_packedData[tokenHolder] >> 96);
    }

    /**
     * @dev Transfer `amount` PRPS from `from` to the Hodl contract.
     *
     * This can only be called by the Hodl contract.
     */
    function hodlTransfer(address from, uint96 amount) external onlyHodl {
        _move(from, address(_hodl), amount);
    }

    /**
     * @dev Increase the hodl balance of `account` by `hodlAmount`. This is
     * only used as part of the migration.
     */
    function migrateHodlBalance(address account, uint96 hodlAmount)
        external
        onlyHodl
    {
        UnpackedData memory unpacked = _unpackPackedData(_packedData[account]);

        unpacked.hodlBalance += hodlAmount;
        _packedData[account] = _packUnpackedData(unpacked);
    }

    /**
     * @dev Increase the hodl balance of `to` by moving `amount` PRPS from `from`'s balance.
     *
     * This can only be called by the Hodl contract.
     */
    function increaseHodlBalance(
        address from,
        address to,
        uint96 amount
    ) external onlyHodl {
        UnpackedData memory unpackedDataFrom = _unpackPackedData(
            _packedData[from]
        );
        UnpackedData memory unpackedDataTo;

        // We only need to unpack twice if from != to
        if (from != to) {
            unpackedDataTo = _unpackPackedData(_packedData[to]);
        } else {
            unpackedDataTo = unpackedDataFrom;
        }

        // `from` must have enough balance
        require(unpackedDataFrom.balance >= amount, "PRPS-3");

        // Subtract balance from `from`
        unpackedDataFrom.balance -= amount;
        // Add to `hodlBalance` from `to`
        unpackedDataTo.hodlBalance += amount;

        // We only need to pack twice if from != to
        if (from != to) {
            _packedData[to] = _packUnpackedData(unpackedDataTo);
        }

        _packedData[from] = _packUnpackedData(unpackedDataFrom);
    }

    /**
     * @dev Decrease the hodl balance of `from` by `hodlAmount` and increase
     * the regular balance by `refundAmount.
     *
     * `refundAmount` might be less than `hodlAmount`.
     *
     * E.g. when burning fuel in locked PRPS
     *
     * This can only be called by the Hodl contract.
     */
    function decreaseHodlBalance(
        address from,
        uint96 hodlAmount,
        uint96 refundAmount
    ) external onlyHodl {
        require(hodlAmount >= refundAmount, "PRPS-4");

        UnpackedData memory unpackedDataFrom = _unpackPackedData(
            _packedData[from]
        );

        // `from` must have enough balance
        require(unpackedDataFrom.hodlBalance >= hodlAmount, "PRPS-5");

        // Subtract amount from hodl balance
        unpackedDataFrom.hodlBalance -= hodlAmount;

        if (refundAmount > 0) {
            // Add amount to balance
            unpackedDataFrom.balance += refundAmount;
        }

        // Write to storage
        _packedData[from] = _packUnpackedData(unpackedDataFrom);
    }

    /**
     * @dev Revert the hodl balance change caused by `from` on `to`.
     *
     * E.g. when reverting a pending hodl.
     *
     * This can only be called by the Hodl contract.
     */
    function revertHodlBalance(
        address from,
        address to,
        uint96 amount
    ) external onlyHodl {
        UnpackedData memory unpackedDataFrom = _unpackPackedData(
            _packedData[from]
        );
        UnpackedData memory unpackedDataTo;

        // We only need to unpack twice if from != to
        if (from != to) {
            unpackedDataTo = _unpackPackedData(_packedData[to]);
        } else {
            unpackedDataTo = unpackedDataFrom;
        }

        // `to` must have enough hodl balance
        require(unpackedDataTo.hodlBalance >= amount, "PRPS-5");

        // Subtract hodl balance from `to`
        unpackedDataTo.hodlBalance -= amount;
        // Add to `balance` from `from`
        unpackedDataFrom.balance += amount;

        // We only need to pack twice if from != to
        if (from != to) {
            _packedData[to] = _packUnpackedData(unpackedDataTo);
        }

        _packedData[from] = _packUnpackedData(unpackedDataFrom);
    }

    /**
     * @dev Mint DUBI when burning PRPS
     * @param from address token holder address
     * @param transferAmount amount of tokens to burn
     * @param occupiedAmount amount of tokens that are occupied
     * @param createdAt equal to block.timestamp if not finalizing a pending op, otherwise
     * it corresponds to op.createdAt
     * @param finalizing boolean indicating whether this is a finalizing transaction or not. Changes
     * how the `amount` is interpreted.
     *
     * When burning PRPS, we first try to burn unlocked PRPS.
     * If burning an amount that exceeds the unlocked PRPS of `from`, we attempt to burn the
     * difference from locked PRPS.
     *
     * If the desired `amount` cannot be filled by taking locked and unlocked PRPS into account,
     * this function reverts.
     *
     * Burning locked PRPS means reducing the `hodlBalance` while burning unlocked PRPS means reducing
     * the regular `balance`.
     *
     * This function returns the actual unlocked PRPS that needs to be removed from `balance`.
     *
     */
    function _beforeBurn(
        address from,
        UnpackedData memory unpacked,
        uint96 transferAmount,
        uint96 occupiedAmount,
        uint32 createdAt,
        FuelBurn memory fuelBurn,
        bool finalizing
    ) internal override returns (uint96) {
        uint96 totalDubiToMint;
        uint96 lockedPrpsToBurn;
        uint96 burnableUnlockedPrps;

        // Depending on whether this is a finalizing burn or not,
        // the amount of locked/unlocked PRPS is determined differently.
        if (finalizing) {
            // For a finalizing burn, we use the occupied amount, since we already know how much
            // locked PRPS we are going to burn. This amount represents the `pendingLockedPrps`
            // on the hodl items.
            lockedPrpsToBurn = occupiedAmount;

            // Since `transferAmount` is the total amount of PRPS getting burned, we need to subtract
            // the `occupiedAmount` to get the actual amount of unlocked PRPS.

            // Sanity check
            assert(transferAmount >= occupiedAmount);
            transferAmount -= occupiedAmount;

            // Set the unlocked PRPS to burn to the updated `transferAmount`
            burnableUnlockedPrps = transferAmount;
        } else {
            // For a direct burn, we start off with the full amounts, since we don't know the exact
            // amounts initially.

            lockedPrpsToBurn = transferAmount;
            burnableUnlockedPrps = unpacked.balance;
        }

        // 1) Try to burn unlocked PRPS
        if (burnableUnlockedPrps > 0) {
            // Nice, we can burn unlocked PRPS

            // Catch underflow i.e. don't burn more than we need to
            if (burnableUnlockedPrps > transferAmount) {
                burnableUnlockedPrps = transferAmount;
            }

            // Calculate DUBI to mint based on unlocked PRPS we can burn
            totalDubiToMint = MintMath.calculateDubiToMintMax(
                burnableUnlockedPrps
            );

            // Subtract the amount of burned unlocked PRPS from the locked PRPS we
            // need to burn if this is NOT a finalizing burn, because in that case we
            // already have the exact amount locked PRPS we want to burn.
            if (!finalizing) {
                lockedPrpsToBurn -= burnableUnlockedPrps;
            }
        }

        // 2) Burn locked PRPS if there's not enough unlocked PRPS

        // Burn an additional amount of locked PRPS equal to the fuel if any
        if (fuelBurn.fuelType == FuelType.LOCKED_PRPS) {
            // The `burnFromLockedPrps` call will fail, if not enough PRPS can be burned.
            lockedPrpsToBurn += fuelBurn.amount;
        }

        if (lockedPrpsToBurn > 0) {
            uint96 dubiToMintFromLockedPrps = _burnFromLockedPrps({
                from: from,
                unpacked: unpacked,
                lockedPrpsToBurn: lockedPrpsToBurn,
                createdAt: createdAt,
                finalizing: finalizing
            });

            // We check 'greater than or equal' because it's possible to mint 0 new DUBI
            // e.g. when called right after a hodl where not enough time passed to generate new DUBI.
            uint96 dubiToMint = totalDubiToMint + dubiToMintFromLockedPrps;
            require(dubiToMint >= totalDubiToMint, "PRPS-6");

            totalDubiToMint = dubiToMint;
        } else {
            // Sanity check for finalizes that don't touch locked PRPS
            assert(occupiedAmount == 0);
        }

        // Burn minted DUBI equal to the fuel if any
        if (fuelBurn.fuelType == FuelType.AUTO_MINTED_DUBI) {
            require(totalDubiToMint >= fuelBurn.amount, "PRPS-7");
            totalDubiToMint -= fuelBurn.amount;
        }

        // Mint DUBI taking differences between burned locked/unlocked into account
        if (totalDubiToMint > 0) {
            _dubi.purposeMint(from, totalDubiToMint);
        }

        return burnableUnlockedPrps;
    }

    function _burnFromLockedPrps(
        address from,
        UnpackedData memory unpacked,
        uint96 lockedPrpsToBurn,
        uint32 createdAt,
        bool finalizing
    ) private returns (uint96) {
        // Reverts if the exact amount needed cannot be burned
        uint96 dubiToMintFromLockedPrps = _hodl.burnLockedPrps({
            from: from,
            amount: lockedPrpsToBurn,
            dubiMintTimestamp: createdAt,
            burnPendingLockedPrps: finalizing
        });

        require(unpacked.hodlBalance >= lockedPrpsToBurn, "PRPS-8");

        unpacked.hodlBalance -= lockedPrpsToBurn;

        return dubiToMintFromLockedPrps;
    }

    function _callerIsDeployTimeKnownContract()
        internal
        override
        view
        returns (bool)
    {
        if (msg.sender == address(_dubi)) {
            return true;
        }

        return super._callerIsDeployTimeKnownContract();
    }

    //---------------------------------------------------------------
    // Fuel
    //---------------------------------------------------------------

    /**
     * @dev Burns `fuel` from `from`. Can only be called by one of the deploy-time known contracts.
     */
    function burnFuel(address from, TokenFuel memory fuel) public override {
        require(_callerIsDeployTimeKnownContract(), "PRPS-2");
        _burnFuel(from, fuel);
    }

    function _burnFuel(address from, TokenFuel memory fuel) private {
        require(fuel.amount <= MAX_BOOSTER_FUEL, "PRPS-10");
        require(from != address(0) && from != msg.sender, "PRPS-11");

        if (fuel.tokenAlias == TOKEN_FUEL_ALIAS_UNLOCKED_PRPS) {
            // Burn fuel from unlocked PRPS
            UnpackedData memory unpacked = _unpackPackedData(_packedData[from]);
            require(unpacked.balance >= fuel.amount, "PRPS-7");
            unpacked.balance -= fuel.amount;
            _packedData[from] = _packUnpackedData(unpacked);
            return;
        }

        if (fuel.tokenAlias == TOKEN_FUEL_ALIAS_LOCKED_PRPS) {
            // Burn fuel from locked PRPS
            UnpackedData memory unpacked = _unpackPackedData(_packedData[from]);
            require(unpacked.hodlBalance >= fuel.amount, "PRPS-7");
            unpacked.hodlBalance -= fuel.amount;

            // We pass a mint timestamp, but that doesn't mean that DUBI is minted.
            // The returned DUBI that should be minted is ignored.
            // Reverts if not enough locked PRPS can be burned.
            _hodl.burnLockedPrps({
                from: from,
                amount: fuel.amount,
                dubiMintTimestamp: uint32(block.timestamp),
                burnPendingLockedPrps: false
            });

            _packedData[from] = _packUnpackedData(unpacked);
            return;
        }

        revert("PRPS-12");
    }

    /**
     *@dev Burn the fuel of a `boostedSend`
     */
    function _burnBoostedSendFuel(
        address from,
        BoosterFuel memory fuel,
        UnpackedData memory unpacked
    ) internal override returns (FuelBurn memory) {
        FuelBurn memory fuelBurn;

        if (fuel.unlockedPrps > 0) {
            require(fuel.unlockedPrps <= MAX_BOOSTER_FUEL, "PRPS-10");

            require(unpacked.balance >= fuel.unlockedPrps, "PRPS-7");
            unpacked.balance -= fuel.unlockedPrps;

            fuelBurn.amount = fuel.unlockedPrps;
            fuelBurn.fuelType = FuelType.UNLOCKED_PRPS;
            return fuelBurn;
        }

        if (fuel.lockedPrps > 0) {
            require(fuel.lockedPrps <= MAX_BOOSTER_FUEL, "PRPS-10");

            // We pass a mint timestamp, but that doesn't mean that DUBI is minted.
            // The returned DUBI that should be minted is ignored.
            // Reverts if not enough locked PRPS can be burned.
            _hodl.burnLockedPrps({
                from: from,
                amount: fuel.lockedPrps,
                dubiMintTimestamp: uint32(block.timestamp),
                burnPendingLockedPrps: false
            });

            require(unpacked.hodlBalance >= fuel.lockedPrps, "PRPS-7");
            unpacked.hodlBalance -= fuel.lockedPrps;

            fuelBurn.amount = fuel.lockedPrps;
            fuelBurn.fuelType = FuelType.LOCKED_PRPS;
            return fuelBurn;
        }

        // If the fuel is DUBI, then we have to reach out to the DUBI contract.
        if (fuel.dubi > 0) {
            // Reverts if the requested amount cannot be burned
            _dubi.burnFuel(
                from,
                TokenFuel({
                    tokenAlias: TOKEN_FUEL_ALIAS_DUBI,
                    amount: fuel.dubi
                })
            );

            fuelBurn.amount = fuel.dubi;
            fuelBurn.fuelType = FuelType.DUBI;
            return fuelBurn;
        }

        return fuelBurn;
    }

    /**
     *@dev Burn the fuel of a `boostedBurn`
     */
    function _burnBoostedBurnFuel(
        address from,
        BoosterFuel memory fuel,
        UnpackedData memory unpacked
    ) internal override returns (FuelBurn memory) {
        FuelBurn memory fuelBurn;

        if (fuel.unlockedPrps > 0) {
            require(fuel.unlockedPrps <= MAX_BOOSTER_FUEL, "PRPS-10");

            require(unpacked.balance >= fuel.unlockedPrps, "PRPS-7");
            unpacked.balance -= fuel.unlockedPrps;

            fuelBurn.amount = fuel.unlockedPrps;
            fuelBurn.fuelType = FuelType.UNLOCKED_PRPS;
            return fuelBurn;
        }

        if (fuel.lockedPrps > 0) {
            require(fuel.lockedPrps <= MAX_BOOSTER_FUEL, "PRPS-10");

            require(unpacked.hodlBalance >= fuel.lockedPrps, "PRPS-7");
            // Fuel is taken from hodl balance in _beforeBurn
            // unpacked.hodlBalance -= fuel.lockedPrps;

            fuelBurn.amount = fuel.lockedPrps;
            fuelBurn.fuelType = FuelType.LOCKED_PRPS;

            return fuelBurn;
        }

        if (fuel.intrinsicFuel > 0) {
            require(fuel.intrinsicFuel <= MAX_BOOSTER_FUEL, "PRPS-10");

            fuelBurn.amount = fuel.intrinsicFuel;
            fuelBurn.fuelType = FuelType.AUTO_MINTED_DUBI;

            return fuelBurn;
        }

        // If the fuel is DUBI, then we have to reach out to the DUBI contract.
        if (fuel.dubi > 0) {
            // Reverts if the requested amount cannot be burned
            _dubi.burnFuel(
                from,
                TokenFuel({
                    tokenAlias: TOKEN_FUEL_ALIAS_DUBI,
                    amount: fuel.dubi
                })
            );

            fuelBurn.amount = fuel.dubi;
            fuelBurn.fuelType = FuelType.DUBI;
            return fuelBurn;
        }

        // No fuel at all
        return fuelBurn;
    }

    //---------------------------------------------------------------
    // Pending ops
    //---------------------------------------------------------------

    function _getHasherContracts()
        internal
        override
        returns (address[] memory)
    {
        address[] memory hashers = new address[](5);
        hashers[0] = address(this);
        hashers[1] = address(_dubi);
        hashers[2] = _hodlAddress;
        hashers[3] = _externalAddress1;
        hashers[4] = _externalAddress2;

        return hashers;
    }

    /**
     * @dev Create a pending transfer by moving the funds of `spender` to this contract.
     * Special behavior applies to pending burns to account for locked PRPS.
     */
    function _createPendingTransferInternal(
        OpHandle memory opHandle,
        address spender,
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) internal override returns (PendingTransfer memory) {
        if (opHandle.opType != OP_TYPE_BURN) {
            return
                // Nothing special to do for non-burns so just call parent implementation
                super._createPendingTransferInternal(
                    opHandle,
                    spender,
                    from,
                    to,
                    amount,
                    data
                );
        }

        // When burning, we first use unlocked PRPS and match the remaining amount with locked PRPS from the Hodl contract.

        // Sanity check
        assert(amount < 2**96);
        uint96 transferAmount = uint96(amount);
        uint96 lockedPrpsAmount = transferAmount;

        UnpackedData memory unpacked = _unpackPackedData(_packedData[from]);
        // First try to move as much unlocked PRPS as possible to the PRPS address
        uint96 unlockedPrpsToMove = transferAmount;
        if (unlockedPrpsToMove > unpacked.balance) {
            unlockedPrpsToMove = unpacked.balance;
        }

        // Update the locked PRPS we have to use
        lockedPrpsAmount -= unlockedPrpsToMove;

        if (unlockedPrpsToMove > 0) {
            _move({from: from, to: address(this), amount: unlockedPrpsToMove});
        }

        // If we still need locked PRPS, call into the Hodl contract.
        // This will also take pending hodls into account, if `from` has
        // some.
        if (lockedPrpsAmount > 0) {
            // Reverts if not the exact amount can be set to pending
            _hodl.setLockedPrpsToPending(from, lockedPrpsAmount);
        }

        // Create pending transfer
        return
            PendingTransfer({
                spender: spender,
                transferAmount: transferAmount,
                to: to,
                occupiedAmount: lockedPrpsAmount,
                data: data
            });
    }

    /**
     * @dev Hook that is called during revert of a pending op.
     * Reverts any changes to locked PRPS when 'opType' is burn.
     */
    function _onRevertPendingOp(
        address user,
        uint8 opType,
        uint64 opId,
        uint96 transferAmount,
        uint96 occupiedAmount
    ) internal override {
        if (opType != OP_TYPE_BURN) {
            return;
        }

        // Extract the pending locked PRPS from the amount.
        if (occupiedAmount > 0) {
            _hodl.revertLockedPrpsSetToPending(user, occupiedAmount);
        }
    }

    //---------------------------------------------------------------
    // Shared pending ops for Hodl
    //---------------------------------------------------------------

    /**
     * @dev Creates a new opHandle with the given type for `user`. Hodl and Prps share the same
     * opCounter to enforce a consistent order in which pending ops are finalized/reverted
     * across contracts. This function can only be called by Hodl.
     */
    function createNewOpHandleShared(
        IOptIn.OptInStatus memory optInStatus,
        address user,
        uint8 opType
    ) public onlyHodl returns (OpHandle memory) {
        return _createNewOpHandle(optInStatus, user, opType);
    }

    /**
     * @dev Delete the op handle with the given `opId` from `user`. Hodl and Prps share the same
     * opCounter to enforce a consistent order in which pending ops are finalized/reverted
     * across contracts. This function can only be called by Hodl.
     */
    function deleteOpHandleShared(address user, OpHandle memory opHandle)
        public
        onlyHodl
        returns (bool)
    {
        _deleteOpHandle(user, opHandle);
        return true;
    }

    /**
     * @dev Get the next op id for `user`. Hodl and Prps share the same
     * opCounter to enforce a consistent order in which pending ops are finalized/reverted
     * across contracts. This function can only be called by Hodl.
     */
    function assertFinalizeFIFOShared(address user, uint64 opId)
        public
        onlyHodl
        returns (bool)
    {
        _assertFinalizeFIFO(user, opId);
        return true;
    }

    /**
     * @dev Get the next op id for `user`. Hodl and Prps share the same
     * opCounter to enforce a consistent order in which pending ops are finalized/reverted
     * across contracts. This function can only be called by Hodl.
     */
    function assertRevertLIFOShared(address user, uint64 opId)
        public
        onlyHodl
        returns (bool)
    {
        _assertRevertLIFO(user, opId);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/introspection/IERC1820Registry.sol";
import "./IBoostableERC20.sol";
import "./BoostableERC20.sol";

/**
 * @dev This is a heavily modified fork of @openzeppelin/contracts/token/ERC20/ERC20.sol (3.1.0)
 */
abstract contract ERC20 is IERC20, IBoostableERC20, BoostableERC20, Ownable {
    using SafeMath for uint256;

    // NOTE: In contrary to the Transfer event, the Burned event always
    // emits the amount including the burned fuel if any.
    // The amount is stored in the lower 96 bits of `amountAndFuel`,
    // followed by 3 bits to encode the type of fuel used and finally
    // another 96 bits for the fuel amount.
    //
    // 0         96        99                 195             256
    //   amount    fuelType      fuelAmount         padding
    //
    event Burned(uint256 amountAndFuel, bytes data);

    enum FuelType {NONE, UNLOCKED_PRPS, LOCKED_PRPS, DUBI, AUTO_MINTED_DUBI}

    struct FuelBurn {
        FuelType fuelType;
        uint96 amount;
    }

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    address internal immutable _hodlAddress;

    address internal immutable _externalAddress1;
    address internal immutable _externalAddress2;
    address internal immutable _externalAddress3;

    IERC1820Registry internal constant _ERC1820_REGISTRY = IERC1820Registry(
        0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24
    );

    // Mapping of address to packed data.
    // For efficiency reasons the token balance is a packed uint96 alongside
    // other data. The packed data has the following layout:
    //
    //   MSB                      uint256                      LSB
    //      uint64 nonce | uint96 hodlBalance | uint96 balance
    //
    // balance: the balance of a token holder that can be transferred freely
    // hodlBalance: the balance of a token holder that is hodled
    // nonce: a sequential number used for booster replay protection
    //
    // Only PRPS utilizes `hodlBalance`. For DUBI it is always 0.
    //
    mapping(address => uint256) internal _packedData;

    struct UnpackedData {
        uint96 balance;
        uint96 hodlBalance;
        uint64 nonce;
    }

    function _unpackPackedData(uint256 packedData)
        internal
        pure
        returns (UnpackedData memory)
    {
        UnpackedData memory unpacked;

        // 1) Read balance from the first 96 bits
        unpacked.balance = uint96(packedData);

        // 2) Read hodlBalance from the next 96 bits
        unpacked.hodlBalance = uint96(packedData >> 96);

        // 3) Read nonce from the next 64 bits
        unpacked.nonce = uint64(packedData >> (96 + 96));

        return unpacked;
    }

    function _packUnpackedData(UnpackedData memory unpacked)
        internal
        pure
        returns (uint256)
    {
        uint256 packedData;

        // 1) Write balance to the first 96 bits
        packedData |= unpacked.balance;

        // 2) Write hodlBalance to the the next 96 bits
        packedData |= uint256(unpacked.hodlBalance) << 96;

        // 3) Write nonce to the next 64 bits
        packedData |= uint256(unpacked.nonce) << (96 + 96);

        return packedData;
    }

    // ERC20-allowances
    mapping(address => mapping(address => uint256)) private _allowances;

    //---------------------------------------------------------------
    // Pending state for non-boosted operations while opted-in
    //---------------------------------------------------------------
    uint8 internal constant OP_TYPE_SEND = BOOST_TAG_SEND;
    uint8 internal constant OP_TYPE_BURN = BOOST_TAG_BURN;

    struct PendingTransfer {
        // NOTE: For efficiency reasons balances are stored in a uint96 which is sufficient
        // since we only use 18 decimals.
        //
        // Two amounts are associated with a pending transfer, to allow deriving contracts
        // to store extra information.
        //
        // E.g. PRPS makes use of this by encoding the pending locked PRPS in the
        // `occupiedAmount` field.
        //
        address spender;
        uint96 transferAmount;
        address to;
        uint96 occupiedAmount;
        bytes data;
    }

    // A mapping of hash(user, opId) to pending transfers. Pending burns are also considered regular transfers.
    mapping(bytes32 => PendingTransfer) private _pendingTransfers;

    //---------------------------------------------------------------

    constructor(
        string memory name,
        string memory symbol,
        address optIn,
        address hodl,
        address externalAddress1,
        address externalAddress2,
        address externalAddress3
    ) public Ownable() BoostableERC20(optIn) {
        _name = name;
        _symbol = symbol;

        _hodlAddress = hodl;
        _externalAddress1 = externalAddress1;
        _externalAddress2 = externalAddress2;
        _externalAddress3 = externalAddress3;

        // register interfaces
        _ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            keccak256("BoostableERC20Token"),
            address(this)
        );
        _ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            keccak256("ERC20Token"),
            address(this)
        );
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals.
     */
    function decimals() public pure returns (uint8) {
        return 18;
    }

    /**
     * @dev Returns the current nonce of `account`
     */
    function getNonce(address account) external override view returns (uint64) {
        UnpackedData memory unpacked = _unpackPackedData(_packedData[account]);
        return unpacked.nonce;
    }

    /**
     * @dev Returns the total supply
     */
    function totalSupply()
        external
        override(IBoostableERC20, IERC20)
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by an account (`tokenHolder`).
     */
    function balanceOf(address tokenHolder)
        public
        override(IBoostableERC20, IERC20)
        view
        returns (uint256)
    {
        // Return the balance of the holder that is not hodled (i.e. first 96 bits of the packeData)
        return uint96(_packedData[tokenHolder]);
    }

    /**
     * @dev Returns the unpacked data struct of `tokenHolder`
     */
    function unpackedDataOf(address tokenHolder)
        public
        view
        returns (UnpackedData memory)
    {
        return _unpackPackedData(_packedData[tokenHolder]);
    }

    /**
     * @dev Mints `amount` new tokens for `to`.
     *
     * To make things more efficient, the total supply is optionally packed into the passed
     * amount where the first 96 bits are used for the actual amount and the following 96 bits
     * for the total supply.
     *
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _mintInitialSupply(address to, uint256 amount) internal {
        // _mint does not update the totalSupply by default, unless the second 96 bits
        // passed are non-zero - in which case the non-zero value becomes the new total supply.
        // So in order to get the correct initial supply, we have to mirror the lower 96 bits
        // to the following 96 bits.
        amount = amount | (amount << 96);
        _mint(to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "ERC20-1");

        // The actual amount to mint (=lower 96 bits)
        uint96 amountToMint = uint96(amount);

        // The new total supply, which may be 0 in which case no update is performed.
        uint96 updatedTotalSupply = uint96(amount >> 96);

        // Update state variables
        if (updatedTotalSupply > 0) {
            _totalSupply = updatedTotalSupply;
        }

        // Update packed data and check for uint96 overflow
        UnpackedData memory unpacked = _unpackPackedData(_packedData[to]);
        uint96 updatedBalance = unpacked.balance + amountToMint;

        // The overflow check also takes the hodlBalance into account
        require(
            updatedBalance + unpacked.hodlBalance >= unpacked.balance,
            "ERC20-2"
        );

        unpacked.balance = updatedBalance;
        _packedData[to] = _packUnpackedData(unpacked);

        emit Transfer(address(0), to, amountToMint);
    }

    /**
     * @dev Transfer `amount` from msg.sender to `recipient`
     */
    function transfer(address recipient, uint256 amount)
        public
        override(IBoostableERC20, IERC20)
        returns (bool)
    {
        _assertSenderRecipient(msg.sender, recipient);

        // Never create a pending transfer if msg.sender is a deploy-time known contract
        if (!_callerIsDeployTimeKnownContract()) {
            // Create pending transfer if sender is opted-in and the permaboost is active
            address from = msg.sender;
            IOptIn.OptInStatus memory optInStatus = getOptInStatus(from);
            if (optInStatus.isOptedIn && optInStatus.permaBoostActive) {
                _createPendingTransfer({
                    opType: OP_TYPE_SEND,
                    spender: msg.sender,
                    from: msg.sender,
                    to: recipient,
                    amount: amount,
                    data: "",
                    optInStatus: optInStatus
                });

                return true;
            }
        }

        _move({from: msg.sender, to: recipient, amount: amount});

        return true;
    }

    /**
     * @dev Burns `amount` of msg.sender.
     *
     * Also emits a {IERC20-Transfer} event for ERC20 compatibility.
     */
    function burn(uint256 amount, bytes memory data) public {
        // Create pending burn if sender is opted-in and the permaboost is active
        IOptIn.OptInStatus memory optInStatus = getOptInStatus(msg.sender);
        if (optInStatus.isOptedIn && optInStatus.permaBoostActive) {
            _createPendingTransfer({
                opType: OP_TYPE_BURN,
                spender: msg.sender,
                from: msg.sender,
                to: address(0),
                amount: amount,
                data: data,
                optInStatus: optInStatus
            });

            return;
        }

        _burn({
            from: msg.sender,
            amount: amount,
            data: data,
            incrementNonce: false
        });
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`.
     *
     * Can only be used by deploy-time known contracts.
     *
     * IBoostableERC20 extension
     */
    function boostedTransferFrom(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data
    ) public override returns (bool) {
        _assertSenderRecipient(sender, recipient);

        IOptIn.OptInStatus memory optInStatus = getOptInStatus(sender);

        // Only transfer if `sender` is a deploy-time known contract, otherwise
        // revert.
        require(
            _isDeployTimeKnownContractAndCanTransfer(
                sender,
                recipient,
                amount,
                optInStatus,
                data
            ),
            "ERC20-17"
        );

        _move({from: sender, to: recipient, amount: amount});
        return true;
    }

    function _isDeployTimeKnownContractAndCanTransfer(
        address sender,
        address recipient,
        uint256 amount,
        IOptIn.OptInStatus memory optInStatus,
        bytes memory data
    ) private view returns (bool) {
        // If the caller not a deploy-time known contract, the transfer is not allowed
        if (!_callerIsDeployTimeKnownContract()) {
            return false;
        }

        if (msg.sender != _externalAddress3) {
            return true;
        }

        // _externalAddress3 passes a flag via `data` that indicates whether it is a boosted transaction
        // or not.
        uint8 isBoostedBits;
        assembly {
            // Load flag using a 1-byte offset, because `mload` always reads
            // 32-bytes at once and the first 32 bytes of `data` contain it's length.
            isBoostedBits := mload(add(data, 0x01))
        }

        // Reading into a 'bool' directly doesn't work for some reason
        if (isBoostedBits & 1 == 1) {
            return true;
        }

        //  If the latter, then _externalAddress3 can only transfer the funds if either:
        // - the permaboost is not active
        // - `sender` is not opted-in to begin with
        //
        // If `sender` is opted-in and the permaboost is active, _externalAddress3 cannot
        // take funds, except when boosted. Here the booster trusts _externalAddress3, since it already
        // verifies that `sender` provided a valid signature.
        //
        // This is special to _externalAddress3, other deploy-time known contracts do not make use of `data`.
        if (optInStatus.permaBoostActive && optInStatus.isOptedIn) {
            return false;
        }

        return true;
    }

    /**
     * @dev Verify the booster payload against the nonce that is stored in the packed data of an account.
     * The increment happens outside of this function, when the balance is updated.
     */
    function _verifyNonce(BoosterPayload memory payload, uint64 currentNonce)
        internal
        pure
    {
        require(currentNonce == payload.nonce - 1, "ERC20-5");
    }

    //---------------------------------------------------------------
    // Boosted functions
    //---------------------------------------------------------------

    /**
     * @dev Perform multiple `boostedSend` calls in a single transaction.
     *
     * NOTE: Booster extension
     */
    function boostedSendBatch(
        BoostedSend[] memory sends,
        Signature[] memory signatures
    ) external {
        require(
            sends.length > 0 && sends.length == signatures.length,
            "ERC20-6"
        );

        for (uint256 i = 0; i < sends.length; i++) {
            boostedSend(sends[i], signatures[i]);
        }
    }

    /**
     * @dev Perform multiple `boostedBurn` calls in a single transaction.
     *
     * NOTE: Booster extension
     */
    function boostedBurnBatch(
        BoostedBurn[] memory burns,
        Signature[] memory signatures
    ) external {
        require(
            burns.length > 0 && burns.length == signatures.length,
            "ERC20-6"
        );

        for (uint256 i = 0; i < burns.length; i++) {
            boostedBurn(burns[i], signatures[i]);
        }
    }

    /**
     * @dev Send `amount` tokens from `sender` to recipient`.
     * The `sender` must be opted-in and the `msg.sender` must be a trusted booster.
     *
     * NOTE: Booster extension
     */
    function boostedSend(BoostedSend memory send, Signature memory signature)
        public
    {
        address from = send.sender;
        address to = send.recipient;

        UnpackedData memory unpackedFrom = _unpackPackedData(_packedData[from]);
        UnpackedData memory unpackedTo = _unpackPackedData(_packedData[to]);

        // We verify the nonce separately, since it's stored next to the balance
        _verifyNonce(send.boosterPayload, unpackedFrom.nonce);

        _verifyBoostWithoutNonce(
            send.sender,
            hashBoostedSend(send, msg.sender),
            send.boosterPayload,
            signature
        );

        FuelBurn memory fuelBurn = _burnBoostedSendFuel(
            from,
            send.fuel,
            unpackedFrom
        );

        _moveUnpacked({
            from: send.sender,
            unpackedFrom: unpackedFrom,
            to: send.recipient,
            unpackedTo: unpackedTo,
            amount: send.amount,
            fuelBurn: fuelBurn,
            incrementNonce: true
        });
    }

    /**
     * @dev Burn the fuel of a `boostedSend`. Returns a `FuelBurn` struct containing information about the burn.
     */
    function _burnBoostedSendFuel(
        address from,
        BoosterFuel memory fuel,
        UnpackedData memory unpacked
    ) internal virtual returns (FuelBurn memory);

    /**
     * @dev Burn `amount` tokens from `account`.
     * The `account` must be opted-in and the `msg.sender` must be a trusted booster.
     *
     * NOTE: Booster extension
     */
    function boostedBurn(
        BoostedBurn memory message,
        // A signature, that is compared against the function payload and only accepted if signed by 'sender'
        Signature memory signature
    ) public {
        address from = message.account;
        UnpackedData memory unpacked = _unpackPackedData(_packedData[from]);

        // We verify the nonce separately, since it's stored next to the balance
        _verifyNonce(message.boosterPayload, unpacked.nonce);

        _verifyBoostWithoutNonce(
            message.account,
            hashBoostedBurn(message, msg.sender),
            message.boosterPayload,
            signature
        );

        FuelBurn memory fuelBurn = _burnBoostedBurnFuel(
            from,
            message.fuel,
            unpacked
        );

        _burnUnpacked({
            from: message.account,
            unpacked: unpacked,
            amount: message.amount,
            data: message.data,
            incrementNonce: true,
            fuelBurn: fuelBurn
        });
    }

    /**
     * @dev Burn the fuel of a `boostedSend`. Returns a `FuelBurn` struct containing information about the burn.
     */
    function _burnBoostedBurnFuel(
        address from,
        BoosterFuel memory fuel,
        UnpackedData memory unpacked
    ) internal virtual returns (FuelBurn memory);

    function burnFuel(address from, TokenFuel memory fuel)
        external
        virtual
        override
    {}

    //---------------------------------------------------------------

    /**
     * @dev Get the allowance of `spender` for `holder`
     */
    function allowance(address holder, address spender)
        public
        override(IBoostableERC20, IERC20)
        view
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    /**
     * @dev Increase the allowance of `spender` by `value` for msg.sender
     */
    function approve(address spender, uint256 value)
        public
        override(IBoostableERC20, IERC20)
        returns (bool)
    {
        address holder = msg.sender;
        _assertSenderRecipient(holder, spender);
        _approve(holder, spender, value);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _assertSenderRecipient(msg.sender, spender);
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _assertSenderRecipient(msg.sender, spender);
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue, "ERC20-18")
        );
        return true;
    }

    /**
     * @dev Transfer `amount` from `holder` to `recipient`.
     *
     * `msg.sender` requires an allowance >= `amount` of `holder`.
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) public override(IBoostableERC20, IERC20) returns (bool) {
        _assertSenderRecipient(holder, recipient);

        address spender = msg.sender;

        // Create pending transfer if the token holder is opted-in and the permaboost is active
        IOptIn.OptInStatus memory optInStatus = getOptInStatus(holder);
        if (optInStatus.isOptedIn && optInStatus.permaBoostActive) {
            // Ignore allowances if holder is opted-in
            require(holder == spender, "ERC20-7");

            _createPendingTransfer({
                opType: OP_TYPE_SEND,
                spender: spender,
                from: holder,
                to: recipient,
                amount: amount,
                data: "",
                optInStatus: optInStatus
            });

            return true;
        }

        // Not opted-in, but we still need to check approval of the given spender

        _approve(
            holder,
            spender,
            _allowances[holder][spender].sub(amount, "ERC20-4")
        );

        _move({from: holder, to: recipient, amount: amount});

        return true;
    }

    /**
     * @dev Burn tokens
     * @param from address token holder address
     * @param amount uint256 amount of tokens to burn
     * @param data bytes extra information provided by the token holder
     * @param incrementNonce whether to increment the nonce or not - only true for boosted burns
     */
    function _burn(
        address from,
        uint256 amount,
        bytes memory data,
        bool incrementNonce
    ) internal virtual {
        require(from != address(0), "ERC20-8");

        UnpackedData memory unpacked = _unpackPackedData(_packedData[from]);

        // Empty fuel burn
        FuelBurn memory fuelBurn;

        _burnUnpacked({
            from: from,
            unpacked: unpacked,
            amount: amount,
            data: data,
            incrementNonce: incrementNonce,
            fuelBurn: fuelBurn
        });
    }

    function _burnUnpacked(
        address from,
        UnpackedData memory unpacked,
        uint256 amount,
        bytes memory data,
        bool incrementNonce,
        FuelBurn memory fuelBurn
    ) internal {
        // _beforeBurn allows deriving contracts to run additional logic and affect the amount
        // that is actually getting burned. E.g. when burning PRPS, a portion of it might be taken
        // from the `hodlBalance`. Thus the returned `burnAmount` overrides `amount` and will be
        // subtracted from the actual `balance`.

        uint96 actualBurnAmount = _beforeBurn({
            from: from,
            unpacked: unpacked,
            transferAmount: uint96(amount),
            occupiedAmount: 0,
            createdAt: uint32(block.timestamp),
            fuelBurn: fuelBurn,
            finalizing: false
        });

        // Update to new balance

        if (incrementNonce) {
            // The nonce uses 64 bits, so a overflow is pretty much impossible
            // via increments of 1.
            unpacked.nonce++;
        }

        if (actualBurnAmount > 0) {
            require(unpacked.balance >= actualBurnAmount, "ERC20-9");
            unpacked.balance -= actualBurnAmount;
        }

        // Update packed data by writing to storage
        _packedData[from] = _packUnpackedData(unpacked);

        // Total supply can be updated in batches elsewhere, shaving off another >5k gas.
        // _totalSupply = _totalSupply.sub(amount);

        // The `Burned` event is emitted with the total amount that got burned.
        // Furthermore, the fuel used is encoded in the upper bits.
        uint256 amountAndFuel;

        // Set first 96 bits to amount
        amountAndFuel |= uint96(amount);

        // Set next 3 bits to fuel type
        uint8 fuelType = uint8(fuelBurn.fuelType);
        amountAndFuel |= uint256(fuelType) << 96;

        // Set next 96 bits to fuel amount
        amountAndFuel |= uint256(fuelBurn.amount) << (96 + 3);

        emit Burned(amountAndFuel, data);

        // We emit a transfer event with the actual burn amount excluding burned `hodlBalance`.
        emit Transfer(from, address(0), actualBurnAmount);
    }

    /**
     * @dev Allow deriving contracts to prepare a burn. By default it behaves like an identity function
     * and just returns the amount passed in.
     */
    function _beforeBurn(
        address from,
        UnpackedData memory unpacked,
        uint96 transferAmount,
        uint96 occupiedAmount,
        uint32 createdAt,
        FuelBurn memory fuelBurn,
        bool finalizing
    ) internal virtual returns (uint96) {
        return transferAmount;
    }

    function _move(
        address from,
        address to,
        uint256 amount
    ) internal {
        UnpackedData memory unpackedFrom = _unpackPackedData(_packedData[from]);
        UnpackedData memory unpackedTo = _unpackPackedData(_packedData[to]);

        // Empty fuel burn
        FuelBurn memory fuelBurn;

        _moveUnpacked({
            from: from,
            unpackedFrom: unpackedFrom,
            to: to,
            unpackedTo: unpackedTo,
            amount: amount,
            incrementNonce: false,
            fuelBurn: fuelBurn
        });
    }

    function _moveUnpacked(
        address from,
        UnpackedData memory unpackedFrom,
        address to,
        UnpackedData memory unpackedTo,
        uint256 amount,
        bool incrementNonce,
        FuelBurn memory fuelBurn
    ) internal {
        require(from != to, "ERC20-19");

        // Increment nonce of sender if it's a boosted send
        if (incrementNonce) {
            // The nonce uses 64 bits, so a overflow is pretty much impossible
            // via increments of 1.
            unpackedFrom.nonce++;
        }

        // Check if sender has enough tokens
        uint96 transferAmount = uint96(amount);
        require(unpackedFrom.balance >= transferAmount, "ERC20-10");

        // Subtract transfer amount from sender balance
        unpackedFrom.balance -= transferAmount;

        // Check that recipient balance doesn't overflow
        uint96 updatedRecipientBalance = unpackedTo.balance + transferAmount;
        require(updatedRecipientBalance >= unpackedTo.balance, "ERC20-12");
        unpackedTo.balance = updatedRecipientBalance;

        _packedData[from] = _packUnpackedData(unpackedFrom);
        _packedData[to] = _packUnpackedData(unpackedTo);

        // The transfer amount does not include any used fuel
        emit Transfer(from, to, transferAmount);
    }

    /**
     * @dev See {ERC20-_approve}.
     */
    function _approve(
        address holder,
        address spender,
        uint256 value
    ) internal {
        _allowances[holder][spender] = value;
        emit Approval(holder, spender, value);
    }

    function _assertSenderRecipient(address sender, address recipient)
        private
        pure
    {
        require(sender != address(0) && recipient != address(0), "ERC20-13");
    }

    /**
     * @dev Checks whether msg.sender is a deploy-time known contract or not.
     */
    function _callerIsDeployTimeKnownContract()
        internal
        virtual
        view
        returns (bool)
    {
        if (msg.sender == _hodlAddress) {
            return true;
        }

        if (msg.sender == _externalAddress1) {
            return true;
        }

        if (msg.sender == _externalAddress2) {
            return true;
        }

        if (msg.sender == _externalAddress3) {
            return true;
        }

        return false;
    }

    //---------------------------------------------------------------
    // Pending ops
    //---------------------------------------------------------------

    /**
     * @dev Create a pending transfer
     */
    function _createPendingTransfer(
        uint8 opType,
        address spender,
        address from,
        address to,
        uint256 amount,
        bytes memory data,
        IOptIn.OptInStatus memory optInStatus
    ) private {
        OpHandle memory opHandle = _createNewOpHandle(
            optInStatus,
            from,
            opType
        );

        PendingTransfer memory pendingTransfer = _createPendingTransferInternal(
            opHandle,
            spender,
            from,
            to,
            amount,
            data
        );

        _pendingTransfers[_getOpKey(from, opHandle.opId)] = pendingTransfer;

        // Emit PendingOp event
        emit PendingOp(from, opHandle.opId, opHandle.opType);
    }

    /**
     * @dev Create a pending transfer by moving the funds of `spender` to this contract.
     * Deriving contracts may override this function.
     */
    function _createPendingTransferInternal(
        OpHandle memory opHandle,
        address spender,
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) internal virtual returns (PendingTransfer memory) {
        // Move funds into this contract

        // Reverts if `from` has less than `amount` tokens.
        _move({from: from, to: address(this), amount: amount});

        // Create op
        PendingTransfer memory pendingTransfer = PendingTransfer({
            transferAmount: uint96(amount),
            spender: spender,
            occupiedAmount: 0,
            to: to,
            data: data
        });

        return pendingTransfer;
    }

    /**
     * @dev Finalize a pending op
     */
    function finalizePendingOp(address user, OpHandle memory opHandle) public {
        uint8 opType = opHandle.opType;

        // Assert that the caller (msg.sender) is allowed to finalize the given op
        uint32 createdAt = uint32(_assertCanFinalize(user, opHandle));

        // Reverts if opId doesn't exist
        PendingTransfer storage pendingTransfer = _safeGetPendingTransfer(
            user,
            opHandle.opId
        );

        // Cleanup
        // NOTE: We do not delete the pending transfer struct, because it only makes it
        // more expensive since we already hit the gas refund limit.
        //
        // delete _pendingTransfers[_getOpKey(user, opHandle.opId)];
        //
        // The difference is ~13k gas.
        //
        // Deleting the op handle is enough to invalidate an opId forever:
        _deleteOpHandle(user, opHandle);

        // Call op type specific finalize
        if (opType == OP_TYPE_SEND) {
            _finalizeTransferOp(pendingTransfer, user, createdAt);
        } else if (opType == OP_TYPE_BURN) {
            _finalizePendingBurn(pendingTransfer, user, createdAt);
        } else {
            revert("ERC20-15");
        }

        // Emit event
        emit FinalizedOp(user, opHandle.opId, opType);
    }

    /**
     * @dev Finalize a pending transfer
     */
    function _finalizeTransferOp(
        PendingTransfer storage pendingTransfer,
        address from,
        uint32 createdAt
    ) private {
        address to = pendingTransfer.to;

        uint96 transferAmount = pendingTransfer.transferAmount;

        address _this = address(this);
        UnpackedData memory unpackedThis = _unpackPackedData(
            _packedData[_this]
        );
        UnpackedData memory unpackedTo = _unpackPackedData(_packedData[to]);

        // Check that sender balance does not overflow
        require(unpackedThis.balance >= transferAmount, "ERC20-2");
        unpackedThis.balance -= transferAmount;

        // Check that recipient doesn't overflow
        uint96 updatedBalanceRecipient = unpackedTo.balance + transferAmount;
        require(updatedBalanceRecipient >= unpackedTo.balance, "ERC20-2");

        unpackedTo.balance = updatedBalanceRecipient;

        _packedData[_this] = _packUnpackedData(unpackedThis);
        _packedData[to] = _packUnpackedData(unpackedTo);

        // Transfer event is emitted with original sender
        emit Transfer(from, to, transferAmount);
    }

    /**
     * @dev Finalize a pending burn
     */
    function _finalizePendingBurn(
        PendingTransfer storage pendingTransfer,
        address from,
        uint32 createdAt
    ) private {
        uint96 transferAmount = pendingTransfer.transferAmount;

        // We pass the packedData of `from` to `_beforeBurn`, because it PRPS needs to update
        // the `hodlBalance` which is NOT on the contract's own packedData.
        UnpackedData memory unpackedFrom = _unpackPackedData(_packedData[from]);

        // Empty fuel burn
        FuelBurn memory fuelBurn;

        uint96 burnAmountExcludingLockedPrps = _beforeBurn({
            from: from,
            unpacked: unpackedFrom,
            transferAmount: transferAmount,
            occupiedAmount: pendingTransfer.occupiedAmount,
            createdAt: createdAt,
            fuelBurn: fuelBurn,
            finalizing: true
        });

        // Update to new balance
        // NOTE: We change the balance of this contract, because that's where
        // the pending PRPS went to.
        address _this = address(this);
        UnpackedData memory unpackedOfContract = _unpackPackedData(
            _packedData[_this]
        );
        require(
            unpackedOfContract.balance >= burnAmountExcludingLockedPrps,
            "ERC20-2"
        );

        unpackedOfContract.balance -= burnAmountExcludingLockedPrps;
        _packedData[_this] = _packUnpackedData(unpackedOfContract);
        _packedData[from] = _packUnpackedData(unpackedFrom);

        // Furthermore, total supply can be updated elsewhere, shaving off another >5k gas.
        // _totalSupply = _totalSupply.sub(amount);

        // Emit events using the same `transferAmount` instead of what `_beforeBurn`
        // returned which is only used for updating the balance correctly.
        emit Burned(transferAmount, pendingTransfer.data);
        emit Transfer(from, address(0), transferAmount);
    }

    /**
     * @dev Revert a pending operation.
     *
     * Only the opted-in booster can revert a transaction if it provides a signed and still valid booster message
     * from the original sender.
     */
    function revertPendingOp(
        address user,
        OpHandle memory opHandle,
        bytes memory boosterMessage,
        Signature memory signature
    ) public {
        // Prepare revert, including permission check and prevents reentrancy for same opHandle.
        _prepareOpRevert({
            user: user,
            opHandle: opHandle,
            boosterMessage: boosterMessage,
            signature: signature
        });

        // Now perform the actual revert of the pending op
        _revertPendingOp(user, opHandle.opType, opHandle.opId);
    }

    /**
     * @dev Revert a pending transfer
     */
    function _revertPendingOp(
        address user,
        uint8 opType,
        uint64 opId
    ) private {
        PendingTransfer storage pendingTransfer = _safeGetPendingTransfer(
            user,
            opId
        );

        uint96 transferAmount = pendingTransfer.transferAmount;
        uint96 occupiedAmount = pendingTransfer.occupiedAmount;

        // Move funds from this contract back to the original sender. Transfers and burns
        // are reverted the same way. We only transfer back the `transferAmount` - that is the amount
        // that actually got moved into this contract. The occupied amount is released during `onRevertPendingOp`
        // by the deriving contract.
        _move({from: address(this), to: user, amount: transferAmount});

        // Call hook to allow deriving contracts to perform additional cleanup
        _onRevertPendingOp(user, opType, opId, transferAmount, occupiedAmount);

        // NOTE: we do not clean up the ops mapping, because we already hit the
        // gas refund limit.
        // delete _pendingTransfers[_getOpKey(user, opHandle.opId)];

        // Emit event
        emit RevertedOp(user, opId, opType);
    }

    /**
     * @dev Hook that is called during revert of a pending transfer.
     * Allows deriving contracts to perform additional cleanup.
     */
    function _onRevertPendingOp(
        address user,
        uint8 opType,
        uint64 opId,
        uint96 transferAmount,
        uint96 occupiedAmount
    ) internal virtual {}

    /**
     * @dev Safely get a pending transfer. Reverts if it doesn't exist.
     */
    function _safeGetPendingTransfer(address user, uint64 opId)
        private
        view
        returns (PendingTransfer storage)
    {
        PendingTransfer storage pendingTransfer = _pendingTransfers[_getOpKey(
            user,
            opId
        )];

        require(pendingTransfer.spender != address(0), "ERC20-16");

        return pendingTransfer;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./Purpose.sol";

contract Dubi is ERC20 {
    Purpose private immutable _prps;

    constructor(
        uint256 initialSupply,
        address optIn,
        address purpose,
        address hodl,
        address externalAddress1,
        address externalAddress2,
        address externalAddress3
    )
        public
        ERC20(
            "Decentralized Universal Basic Income",
            "DUBI",
            optIn,
            hodl,
            externalAddress1,
            externalAddress2,
            externalAddress3
        )
    {
        _mintInitialSupply(msg.sender, initialSupply);

        _prps = Purpose(purpose);
    }

    function hodlMint(address to, uint256 amount) public {
        require(msg.sender == _hodlAddress, "DUBI-2");
        _mint(to, amount);
    }

    function purposeMint(address to, uint256 amount) public {
        require(msg.sender == address(_prps), "DUBI-3");
        _mint(to, amount);
    }

    function _callerIsDeployTimeKnownContract()
        internal
        override
        view
        returns (bool)
    {
        if (msg.sender == address(_prps)) {
            return true;
        }

        return super._callerIsDeployTimeKnownContract();
    }

    //---------------------------------------------------------------
    // Fuel
    //---------------------------------------------------------------

    /**
     * @dev Burns `fuel` from `from`. Can only be called by one of the deploy-time known contracts.
     */
    function burnFuel(address from, TokenFuel memory fuel) public override {
        require(_callerIsDeployTimeKnownContract(), "DUBI-1");
        _burnFuel(from, fuel);
    }

    function _burnFuel(address from, TokenFuel memory fuel) private {
        require(fuel.amount <= MAX_BOOSTER_FUEL, "DUBI-5");
        require(from != address(0) && from != msg.sender, "DUBI-6");

        if (fuel.tokenAlias == TOKEN_FUEL_ALIAS_DUBI) {
            // Burn fuel from DUBI
            UnpackedData memory unpacked = _unpackPackedData(_packedData[from]);
            require(unpacked.balance >= fuel.amount, "DUBI-7");
            unpacked.balance -= fuel.amount;
            _packedData[from] = _packUnpackedData(unpacked);
            return;
        }

        revert("DUBI-8");
    }

    /**
     *@dev Burn the fuel of a `boostedSend`
     */
    function _burnBoostedSendFuel(
        address from,
        BoosterFuel memory fuel,
        UnpackedData memory unpacked
    ) internal override returns (FuelBurn memory) {
        FuelBurn memory fuelBurn;

        if (fuel.dubi > 0) {
            require(fuel.dubi <= MAX_BOOSTER_FUEL, "DUBI-5");

            // From uses his own DUBI to fuel the boost
            require(unpacked.balance >= fuelBurn.amount, "DUBI-7");
            unpacked.balance -= fuel.dubi;

            fuelBurn.amount = fuel.dubi;
            fuelBurn.fuelType = FuelType.DUBI;

            return fuelBurn;
        }

        // If the fuel is PRPS, then we have to reach out to the PRPS contract.
        if (fuel.unlockedPrps > 0) {
            // Reverts if the requested amount cannot be burned
            _prps.burnFuel(
                from,
                TokenFuel({
                    tokenAlias: TOKEN_FUEL_ALIAS_UNLOCKED_PRPS,
                    amount: fuel.unlockedPrps
                })
            );

            fuelBurn.amount = fuel.unlockedPrps;
            fuelBurn.fuelType = FuelType.UNLOCKED_PRPS;
            return fuelBurn;
        }

        if (fuel.lockedPrps > 0) {
            // Reverts if the requested amount cannot be burned
            _prps.burnFuel(
                from,
                TokenFuel({
                    tokenAlias: TOKEN_FUEL_ALIAS_LOCKED_PRPS,
                    amount: fuel.lockedPrps
                })
            );

            fuelBurn.amount = fuel.lockedPrps;
            fuelBurn.fuelType = FuelType.LOCKED_PRPS;
            return fuelBurn;
        }

        // No fuel at all
        return fuelBurn;
    }

    /**
     *@dev Burn the fuel of a `boostedBurn`
     */
    function _burnBoostedBurnFuel(
        address from,
        BoosterFuel memory fuel,
        UnpackedData memory unpacked
    ) internal override returns (FuelBurn memory) {
        FuelBurn memory fuelBurn;

        // If the fuel is DUBI, then we can remove it directly
        if (fuel.dubi > 0) {
            require(fuel.dubi <= MAX_BOOSTER_FUEL, "DUBI-5");

            require(unpacked.balance >= fuel.dubi, "DUBI-7");
            unpacked.balance -= fuel.dubi;

            fuelBurn.amount = fuel.dubi;
            fuelBurn.fuelType = FuelType.DUBI;

            return fuelBurn;
        }

        // If the fuel is PRPS, then we have to reach out to the PRPS contract.
        if (fuel.unlockedPrps > 0) {
            // Reverts if the requested amount cannot be burned
            _prps.burnFuel(
                from,
                TokenFuel({
                    tokenAlias: TOKEN_FUEL_ALIAS_UNLOCKED_PRPS,
                    amount: fuel.unlockedPrps
                })
            );

            fuelBurn.amount = fuel.unlockedPrps;
            fuelBurn.fuelType = FuelType.UNLOCKED_PRPS;

            return fuelBurn;
        }

        if (fuel.lockedPrps > 0) {
            // Reverts if the requested amount cannot be burned
            _prps.burnFuel(
                from,
                TokenFuel({
                    tokenAlias: TOKEN_FUEL_ALIAS_LOCKED_PRPS,
                    amount: fuel.lockedPrps
                })
            );

            // No direct fuel, but we still return a indirect fuel so that it can be added
            // to the burn event.
            fuelBurn.amount = fuel.lockedPrps;
            fuelBurn.fuelType = FuelType.LOCKED_PRPS;
            return fuelBurn;
        }

        // DUBI has no intrinsic fuel
        if (fuel.intrinsicFuel > 0) {
            revert("DUBI-8");
        }

        // No fuel at all
        return fuelBurn;
    }

    //---------------------------------------------------------------
    // Pending ops
    //---------------------------------------------------------------
    function _getHasherContracts()
        internal
        override
        returns (address[] memory)
    {
        address[] memory hashers = new address[](5);
        hashers[0] = address(this);
        hashers[1] = address(_prps);
        hashers[2] = _hodlAddress;
        hashers[3] = _externalAddress1;
        hashers[4] = _externalAddress2;

        return hashers;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IHodl {
    /**
     * @dev Lock the given amount of PRPS for the specified period (or infinitely)
     * for DUBI.
     */
    function hodl(
        uint24 id,
        uint96 amountPrps,
        uint16 duration,
        address dubiBeneficiary,
        address prpsBeneficiary
    ) external;

    /**
     * @dev Release a hodl of `prpsBeneficiary` with the given `creator` and `id`.
     */
    function release(
        uint24 id,
        address prpsBeneficiary,
        address creator
    ) external;

    /**
     * @dev Withdraw can be used to withdraw DUBI from infinitely locked PRPS.
     * The amount of DUBI withdrawn depends on the time passed since the last withdrawal.
     */
    function withdraw(
        uint24 id,
        address prpsBeneficiary,
        address creator
    ) external;

    /**
     * @dev Burn `amount` of `from`'s locked and/or pending PRPS.
     *
     * This function is supposed to be only called by the PRPS contract.
     *
     * Returns the amount of DUBI that needs to be minted.
     */
    function burnLockedPrps(
        address from,
        uint96 amount,
        uint32 dubiMintTimestamp,
        bool burnPendingLockedPrps
    ) external returns (uint96);

    /**
     * @dev Set `amount` of `from`'s locked PRPS to pending.
     *
     * This function is supposed to be only called by the PRPS contract.
     *
     * Returns the amount of locked PRPS that could be set to pending.
     */
    function setLockedPrpsToPending(address from, uint96 amount) external;

    /**
     * @dev Revert `amount` of `from`'s pending locked PRPS to not pending.
     *
     * This function is supposed to be only called by the PRPS contract and returns
     */
    function revertLockedPrpsSetToPending(address account, uint96 amount)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// NOTE: we ignore leap-seconds etc.
library MintMath {
    // The maximum number of seconds per month (365 * 24 * 60 * 60 / 12)
    uint32 public constant SECONDS_PER_MONTH = 2628000;
    // The maximum number of days PRPS can be finitely locked for
    uint16 public constant MAX_FINITE_LOCK_DURATION_DAYS = 365;
    // The maximum number of seconds PRPS can be finitely locked for
    uint32 public constant MAX_FINITE_LOCK_DURATION_SECONDS = uint32(
        MAX_FINITE_LOCK_DURATION_DAYS
    ) *
        24 *
        60 *
        60;

    /**
     * @dev Calculates the DUBI to mint based on the given amount of PRPS and duration in days.
     * NOTE: We trust the caller to ensure that the duration between 1 and 365.
     */
    function calculateDubiToMintByDays(
        uint256 amountPrps,
        uint16 durationInDays
    ) internal pure returns (uint96) {
        uint32 durationInSeconds = uint32(durationInDays) * 24 * 60 * 60;
        return calculateDubiToMintBySeconds(amountPrps, durationInSeconds);
    }

    /**
     * @dev Calculates the DUBI to mint based on the given amount of PRPS and duration in seconds.
     */
    function calculateDubiToMintBySeconds(
        uint256 amountPrps,
        uint32 durationInSeconds
    ) internal pure returns (uint96) {
        // NOTE: We do not use safe math for efficiency reasons

        uint256 _percentage = percentage(
            durationInSeconds,
            MAX_FINITE_LOCK_DURATION_SECONDS,
            18 // precision in WEI, 10^18
        ) * 4; // A full lock grants 4%, so multiply by 4.

        // Multiply PRPS by the percentage and then divide by the precision (=10^8)
        // from the previous step
        uint256 _dubiToMint = (amountPrps * _percentage) / (1 ether * 100); // multiply by 100, because we deal with percentages

        // Assert that the calculated DUBI never overflows uint96
        assert(_dubiToMint < 2**96);

        return uint96(_dubiToMint);
    }

    function calculateDubiToMintMax(uint96 amount)
        internal
        pure
        returns (uint96)
    {
        return
            calculateDubiToMintBySeconds(
                amount,
                MAX_FINITE_LOCK_DURATION_SECONDS
            );
    }

    function calculateMintDuration(uint32 _now, uint32 lastWithdrawal)
        internal
        pure
        returns (uint32)
    {
        require(lastWithdrawal > 0 && lastWithdrawal <= _now, "MINT-1");

        // NOTE: we don't use any safe math here for efficiency reasons. The assert above
        // is already a pretty good guarantee that nothing goes wrong. Also, all numbers involved
        // are very well smaller than uint256 in the first place.
        uint256 _elapsedTotal = _now - lastWithdrawal;
        uint256 _proRatedYears = _elapsedTotal / SECONDS_PER_MONTH / 12;
        uint256 _elapsedInYear = _elapsedTotal %
            MAX_FINITE_LOCK_DURATION_SECONDS;

        //
        // Examples (using months instead of seconds):
        // calculation formula: (monthsSinceWithdrawal % 12) + (_proRatedYears * 12)

        // 1) Burn after 11 months since last withdrawal (number of years = 11 / 12 + 1 = 1)
        // => (11 % 12) + (years * 12) => 23 months worth of DUBI
        // => 23 months

        // 1) Burn after 4 months since last withdrawal (number of years = 4 / 12 + 1 = 1)
        // => (4 % 12) + (years * 12) => 16 months worth of DUBI
        // => 16 months

        // 2) Burn 0 months after withdrawal after 4 months (number of years = 0 / 12 + 1 = 1):
        // => (0 % 12) + (years * 12) => 12 months worth of DUBI (+ 4 months worth of withdrawn DUBI)
        // => 16 months

        // 3) Burn after 36 months since last withdrawal (number of years = 36 / 12 + 1 = 4)
        // => (36 % 12) + (years * 12) => 48 months worth of DUBI
        // => 48 months

        // 4) Burn 1 month after withdrawal after 35 months (number of years = 1 / 12 + 1 = 1):
        // => (1 % 12) + (years * 12) => 12 month worth of DUBI (+ 35 months worth of withdrawn DUBI)
        // => 47 months
        uint32 _mintDuration = uint32(
            _elapsedInYear + _proRatedYears * MAX_FINITE_LOCK_DURATION_SECONDS
        );

        return _mintDuration;
    }

    function percentage(
        uint256 numerator,
        uint256 denominator,
        uint256 precision
    ) internal pure returns (uint256) {
        return
            ((numerator * (uint256(10)**(precision + 1))) / denominator + 5) /
            uint256(10);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     *  @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     *  @param account Address of the contract for which to update the cache.
     *  @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not.
     *  If the result is not cached a direct lookup on the contract address is performed.
     *  If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     *  {updateERC165Cache} with the contract address.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// Token agnostic fuel struct that is passed around when the fuel is burned by a different (token) contract.
// The contract has to explicitely support the desired token that should be burned.
struct TokenFuel {
    // A token alias that must be understood by the target contract
    uint8 tokenAlias;
    uint96 amount;
}

/**
 * @dev Extends the interface of the ERC20 standard as defined in the EIP with
 * `boostedTransferFrom` to perform transfers without having to rely on an allowance.
 */
interface IBoostableERC20 {
    // ERC20
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // Extension

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`.
     *
     * If the caller is known by the callee, then the implementation should skip approval checks.
     * Also accepts a data payload, similar to ERC721's `safeTransferFrom` to pass arbitrary data.
     *
     */
    function boostedTransferFrom(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    /**
     * @dev Burns `fuel` from `from`.
     */
    function burnFuel(address from, TokenFuel memory fuel) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Boostable.sol";
import "./BoostableLib.sol";

/**
 * @dev EIP712 boostable primitives related to ERC20 for the Purpose domain
 */
abstract contract BoostableERC20 is Boostable {
    /**
     * @dev A struct representing the payload of the ERC20 `boostedSend` function.
     */
    struct BoostedSend {
        uint8 tag;
        address sender;
        address recipient;
        uint256 amount;
        bytes data;
        BoosterFuel fuel;
        BoosterPayload boosterPayload;
    }

    /**
     * @dev A struct representing the payload of the ERC20 `boostedBurn` function.
     */
    struct BoostedBurn {
        uint8 tag;
        address account;
        uint256 amount;
        bytes data;
        BoosterFuel fuel;
        BoosterPayload boosterPayload;
    }

    uint8 internal constant BOOST_TAG_SEND = 0;
    uint8 internal constant BOOST_TAG_BURN = 1;

    bytes32 internal constant BOOSTED_SEND_TYPEHASH = keccak256(
        "BoostedSend(uint8 tag,address sender,address recipient,uint256 amount,bytes data,BoosterFuel fuel,BoosterPayload boosterPayload)BoosterFuel(uint96 dubi,uint96 unlockedPrps,uint96 lockedPrps,uint96 intrinsicFuel)BoosterPayload(address booster,uint64 timestamp,uint64 nonce,bool isLegacySignature)"
    );

    bytes32 internal constant BOOSTED_BURN_TYPEHASH = keccak256(
        "BoostedBurn(uint8 tag,address account,uint256 amount,bytes data,BoosterFuel fuel,BoosterPayload boosterPayload)BoosterFuel(uint96 dubi,uint96 unlockedPrps,uint96 lockedPrps,uint96 intrinsicFuel)BoosterPayload(address booster,uint64 timestamp,uint64 nonce,bool isLegacySignature)"
    );

    constructor(address optIn) public Boostable(optIn) {}

    /**
     * @dev Returns the hash of `boostedSend`.
     */
    function hashBoostedSend(BoostedSend memory send, address booster)
        internal
        view
        returns (bytes32)
    {
        return
            BoostableLib.hashWithDomainSeparator(
                _DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        BOOSTED_SEND_TYPEHASH,
                        BOOST_TAG_SEND,
                        send.sender,
                        send.recipient,
                        send.amount,
                        keccak256(send.data),
                        BoostableLib.hashBoosterFuel(send.fuel),
                        BoostableLib.hashBoosterPayload(
                            send.boosterPayload,
                            booster
                        )
                    )
                )
            );
    }

    /**
     * @dev Returns the hash of `boostedBurn`.
     */
    function hashBoostedBurn(BoostedBurn memory burn, address booster)
        internal
        view
        returns (bytes32)
    {
        return
            BoostableLib.hashWithDomainSeparator(
                _DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        BOOSTED_BURN_TYPEHASH,
                        BOOST_TAG_BURN,
                        burn.account,
                        burn.amount,
                        keccak256(burn.data),
                        BoostableLib.hashBoosterFuel(burn.fuel),
                        BoostableLib.hashBoosterPayload(
                            burn.boosterPayload,
                            booster
                        )
                    )
                )
            );
    }

    /**
     * @dev Tries to interpret the given boosterMessage and
     * return it's hash plus creation timestamp.
     */
    function decodeAndHashBoosterMessage(
        address targetBooster,
        bytes memory boosterMessage
    ) external override view returns (bytes32, uint64) {
        require(boosterMessage.length > 0, "PB-7");

        uint8 tag = _readBoosterTag(boosterMessage);
        if (tag == BOOST_TAG_SEND) {
            BoostedSend memory send = abi.decode(boosterMessage, (BoostedSend));
            return (
                hashBoostedSend(send, targetBooster),
                send.boosterPayload.timestamp
            );
        }

        if (tag == BOOST_TAG_BURN) {
            BoostedBurn memory burn = abi.decode(boosterMessage, (BoostedBurn));
            return (
                hashBoostedBurn(burn, targetBooster),
                burn.boosterPayload.timestamp
            );
        }

        // Unknown tag, so just return an empty result
        return ("", 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ProtectedBoostable.sol";

/**
 * @dev Purpose Boostable primitives using the EIP712 standard
 */
abstract contract Boostable is ProtectedBoostable {
    // "Purpose", "Dubi" and "Hodl" are all under the "Purpose" umbrella
    constructor(address optIn)
        public
        ProtectedBoostable(
            optIn,
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256("Purpose"),
                    keccak256("1"),
                    _getChainId(),
                    address(this)
                )
            )
        )
    {}

    // Fuel alias constants - used when fuel is burned from external contract calls
    uint8 internal constant TOKEN_FUEL_ALIAS_UNLOCKED_PRPS = 0;
    uint8 internal constant TOKEN_FUEL_ALIAS_LOCKED_PRPS = 1;
    uint8 internal constant TOKEN_FUEL_ALIAS_DUBI = 2;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

struct BoosterFuel {
    uint96 dubi;
    uint96 unlockedPrps;
    uint96 lockedPrps;
    uint96 intrinsicFuel;
}

struct BoosterPayload {
    address booster;
    uint64 timestamp;
    uint64 nonce;
    // Fallback for 'personal_sign' when e.g. using hardware wallets that don't support
    // EIP712 signing (yet).
    bool isLegacySignature;
}

// Library for Boostable hash functions that are completely inlined.
library BoostableLib {
    bytes32 private constant BOOSTER_PAYLOAD_TYPEHASH = keccak256(
        "BoosterPayload(address booster,uint64 timestamp,uint64 nonce,bool isLegacySignature)"
    );

    bytes32 internal constant BOOSTER_FUEL_TYPEHASH = keccak256(
        "BoosterFuel(uint96 dubi,uint96 unlockedPrps,uint96 lockedPrps,uint96 intrinsicFuel)"
    );

    /**
     * @dev Returns the hash of the packed DOMAIN_SEPARATOR and `messageHash` and is used for verifying
     * a signature.
     */
    function hashWithDomainSeparator(
        bytes32 domainSeparator,
        bytes32 messageHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, messageHash)
            );
    }

    /**
     * @dev Returns the hash of `payload` using the provided booster (i.e. `msg.sender`).
     */
    function hashBoosterPayload(BoosterPayload memory payload, address booster)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    BOOSTER_PAYLOAD_TYPEHASH,
                    booster,
                    payload.timestamp,
                    payload.nonce,
                    payload.isLegacySignature
                )
            );
    }

    function hashBoosterFuel(BoosterFuel memory fuel)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    BOOSTER_FUEL_TYPEHASH,
                    fuel.dubi,
                    fuel.unlockedPrps,
                    fuel.lockedPrps,
                    fuel.intrinsicFuel
                )
            );
    }

    /**
     * @dev Returns the tag found in the given `boosterMessage`.
     */
    function _readBoosterTag(bytes memory boosterMessage)
        internal
        pure
        returns (uint8)
    {
        // The tag is either the 32th byte or the 64th byte depending on whether
        // the booster message contains dynamic bytes or not.
        //
        // If it contains a dynamic byte array, then the first word points to the first
        // data location.
        //
        // Therefore, we read the 32th byte and check if it's >= 32 and if so,
        // simply read the (32 + first word)th byte to get the tag.
        //
        // This imposes a limit on the number of tags we can support (<32), but
        // given that it is very unlikely for so many tags to exist it is fine.
        //
        // Read the 32th byte to get the tag, because it is a uint8 padded to 32 bytes.
        // i.e.
        // -----------------------------------------------------------------v
        // 0x0000000000000000000000000000000000000000000000000000000000000001
        //   ...
        //
        uint8 tag = uint8(boosterMessage[31]);
        if (tag >= 32) {
            // Read the (32 + tag) byte. E.g. if tag is 32, then we read the 64th:
            // --------------------------------------------------------------------
            // 0x0000000000000000000000000000000000000000000000000000000000000020 |
            //   0000000000000000000000000000000000000000000000000000000000000001 <
            //   ...
            //
            tag = uint8(boosterMessage[31 + tag]);
        }

        return tag;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./EIP712Boostable.sol";
import "./IOptIn.sol";
import "./ProtectedBoostableLib.sol";

abstract contract ProtectedBoostable is EIP712Boostable {
    //---------------------------------------------------------------
    // State for non-boosted operations while opted-in and the OPT_IN permaboost is active
    //---------------------------------------------------------------

    uint256 private constant MAX_PENDING_OPS = 25;

    // A mapping of account to an opCounter.
    mapping(address => OpCounter) internal _opCounters;

    // A mapping of account to an array containing all it's pending ops.
    mapping(address => OpHandle[]) internal _pendingOpsByAddress;

    // A mapping of keccak256(address,opId) to a struct holding metadata like the associated user account and creation timestamp.
    mapping(bytes32 => OpMetadata) internal _opMetadata;

    // Event that is emitted whenever a pending op is created
    // NOTE: returning an OpHandle in the event flattens it into an array for some reason
    // i.e. emit PendingOp(0x123.., OpHandle(1, 0)) => { from: 0x123, opHandle: ['1', '0']}
    event PendingOp(address from, uint64 opId, uint8 opType);
    // Event that is emitted whenever a pending op is finalized
    event FinalizedOp(address from, uint64 opId, uint8 opType);
    // Event that is emitted whenever a pending op is reverted
    event RevertedOp(address from, uint64 opId, uint8 opType);

    constructor(address optIn, bytes32 domainSeparator)
        public
        EIP712Boostable(optIn, domainSeparator)
    {}

    //---------------------------------------------------------------
    // Pending ops
    //---------------------------------------------------------------

    /**
     * @dev Returns the metadata of an op. Returns a zero struct if it doesn't exist.
     */
    function getOpMetadata(address user, uint64 opId)
        public
        virtual
        view
        returns (OpMetadata memory)
    {
        return _opMetadata[_getOpKey(user, opId)];
    }

    /**
     * @dev Returns the metadata of an op. Returns a zero struct if it doesn't exist.
     */
    function getOpCounter(address user)
        public
        virtual
        view
        returns (OpCounter memory)
    {
        return _opCounters[user];
    }

    /**
     * @dev Returns the metadata of an op. Reverts if it doesn't exist or
     * the opType mismatches.
     */
    function safeGetOpMetadata(address user, OpHandle memory opHandle)
        public
        virtual
        view
        returns (OpMetadata memory)
    {
        OpMetadata storage metadata = _opMetadata[_getOpKey(
            user,
            opHandle.opId
        )];

        // If 'createdAt' is zero, then it's non-existent for us
        require(metadata.createdAt > 0, "PB-1");
        require(metadata.opType == opHandle.opType, "PB-2");

        return metadata;
    }

    /**
     * @dev Get the next op id for `user`
     */
    function _getNextOpId(address user) internal returns (uint64) {
        OpCounter storage counter = _opCounters[user];
        // NOTE: we always increase by 1, so it cannot overflow as long as this
        // is the only place increasing the counter.
        uint64 nextOpId = counter.value + 1;

        // This also updates the nextFinalize/Revert values
        if (counter.nextFinalize == 0) {
            // Only gets updated if currently pointing to "nothing", because FIFO
            counter.nextFinalize = nextOpId;
        }

        // nextRevert is always updated to the new opId, because LIFO
        counter.nextRevert = nextOpId;
        counter.value = nextOpId;

        // NOTE: It is safe to downcast to uint64 since it's practically impossible to overflow.
        return nextOpId;
    }

    /**
     * @dev Creates a new opHandle with the given type for `user`.
     */
    function _createNewOpHandle(
        IOptIn.OptInStatus memory optInStatus,
        address user,
        uint8 opType
    ) internal virtual returns (OpHandle memory) {
        uint64 nextOpId = _getNextOpId(user);
        OpHandle memory opHandle = OpHandle({opId: nextOpId, opType: opType});

        // NOTE: we have a hard limit of 25 pending OPs and revert if that
        // limit is exceeded.
        require(_pendingOpsByAddress[user].length < MAX_PENDING_OPS, "PB-3");

        address booster = optInStatus.optedInTo;

        _pendingOpsByAddress[user].push(opHandle);
        _opMetadata[_getOpKey(user, nextOpId)] = OpMetadata({
            createdAt: uint64(block.timestamp),
            booster: booster,
            opType: opType
        });

        return opHandle;
    }

    /**
     * @dev Delete the given `opHandle` from `user`.
     */
    function _deleteOpHandle(address user, OpHandle memory opHandle)
        internal
        virtual
    {
        OpHandle[] storage _opHandles = _pendingOpsByAddress[user];
        OpCounter storage opCounter = _opCounters[user];

        ProtectedBoostableLib.deleteOpHandle(
            user,
            opHandle,
            _opHandles,
            opCounter,
            _opMetadata
        );
    }

    /**
     * @dev Assert that the caller is allowed to finalize a pending op.
     *
     * Returns the user and createdAt timestamp of the op on success in order to
     * save some gas by minimizing redundant look-ups.
     */
    function _assertCanFinalize(address user, OpHandle memory opHandle)
        internal
        returns (uint64)
    {
        OpMetadata memory metadata = safeGetOpMetadata(user, opHandle);

        uint64 createdAt = metadata.createdAt;

        // First check if the user is still opted-in. If not, then anyone
        // can finalize since it is no longer associated with the original booster.
        IOptIn.OptInStatus memory optInStatus = getOptInStatus(user);
        if (!optInStatus.isOptedIn) {
            return createdAt;
        }

        // Revert if not FIFO order
        _assertFinalizeFIFO(user, opHandle.opId);

        return ProtectedBoostableLib.assertCanFinalize(metadata, optInStatus);
    }

    /**
     * @dev Asserts that the caller (msg.sender) is allowed to revert a pending operation.
     * The caller must be opted-in by user and provide a valid signature from the user
     * that hasn't expired yet.
     */
    function _assertCanRevert(
        address user,
        OpHandle memory opHandle,
        uint64 opTimestamp,
        bytes memory boosterMessage,
        Signature memory signature
    ) internal {
        // Revert if not LIFO order
        _assertRevertLIFO(user, opHandle.opId);

        IOptIn.OptInStatus memory optInStatus = getOptInStatus(user);

        require(
            optInStatus.isOptedIn && msg.sender == optInStatus.optedInTo,
            "PB-6"
        );

        // In order to verify the boosterMessage, we need the hash and timestamp of when it
        // was signed. To interpret the boosterMessage, consult all available hasher contracts and
        // take the first non-zero result.
        address[] memory hasherContracts = _getHasherContracts();

        // Call external library function, which performs the actual assertion. The reason
        // why it is not inlined, is that the need to reduce bytecode size.
        ProtectedBoostableLib.verifySignatureForRevert(
            user,
            opTimestamp,
            optInStatus,
            boosterMessage,
            hasherContracts,
            signature
        );
    }

    function _getHasherContracts() internal virtual returns (address[] memory);

    /**
     * @dev Asserts that the given opId is the next to be finalized for `user`.
     */
    function _assertFinalizeFIFO(address user, uint64 opId) internal virtual {
        OpCounter storage counter = _opCounters[user];
        require(counter.nextFinalize == opId, "PB-9");
    }

    /**
     * @dev Asserts that the given opId is the next to be reverted for `user`.
     */
    function _assertRevertLIFO(address user, uint64 opId) internal virtual {
        OpCounter storage counter = _opCounters[user];
        require(counter.nextRevert == opId, "PB-10");
    }

    /**
     * @dev Prepare an op revert.
     * - Asserts that the caller is allowed to revert the given op
     * - Deletes the op handle to minimize risks of reentrancy
     */
    function _prepareOpRevert(
        address user,
        OpHandle memory opHandle,
        bytes memory boosterMessage,
        Signature memory signature
    ) internal {
        OpMetadata memory metadata = safeGetOpMetadata(user, opHandle);

        _assertCanRevert(
            user,
            opHandle,
            metadata.createdAt,
            boosterMessage,
            signature
        );

        // Delete opHandle, which prevents reentrancy since `safeGetOpMetadata`
        // will fail afterwards.
        _deleteOpHandle(user, opHandle);
    }

    /**
     * @dev Returns the hash of (user, opId) which is used as a look-up
     * key in the `_opMetadata` mapping.
     */
    function _getOpKey(address user, uint64 opId)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(user, opId));
    }

    /**
     * @dev Deriving contracts can override this function to accept a boosterMessage for a given booster and
     * interpret it into a hash and timestamp.
     */
    function decodeAndHashBoosterMessage(
        address targetBooster,
        bytes memory boosterMessage
    ) external virtual view returns (bytes32, uint64) {}

    /**
     * @dev Returns the tag found in the given `boosterMesasge`.
     */
    function _readBoosterTag(bytes memory boosterMessage)
        internal
        pure
        returns (uint8)
    {
        // The tag is either the 32th byte or the 64th byte depending on whether
        // the booster message contains dynamic bytes or not.
        //
        // If it contains a dynamic byte array, then the first word points to the first
        // data location.
        //
        // Therefore, we read the 32th byte and check if it's >= 32 and if so,
        // simply read the (32 + first word)th byte to get the tag.
        //
        // This imposes a limit on the number of tags we can support (<32), but
        // given that it is very unlikely for so many tags to exist it is fine.
        //
        // Read the 32th byte to get the tag, because it is a uint8 padded to 32 bytes.
        // i.e.
        // -----------------------------------------------------------------v
        // 0x0000000000000000000000000000000000000000000000000000000000000001
        //   ...
        //
        uint8 tag = uint8(boosterMessage[31]);
        if (tag >= 32) {
            // Read the (32 + tag) byte. E.g. if tag is 32, then we read the 64th:
            // --------------------------------------------------------------------
            // 0x0000000000000000000000000000000000000000000000000000000000000020 |
            //   0000000000000000000000000000000000000000000000000000000000000001 <
            //   ...
            //
            tag = uint8(boosterMessage[31 + tag]);
        }

        return tag;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "./IOptIn.sol";
import "./BoostableLib.sol";
import "./IBoostableERC20.sol";

/**
 * @dev Boostable base contract
 *
 * All deriving contracts are expected to implement EIP712 for the message signing.
 *
 */
abstract contract EIP712Boostable {
    using ECDSA for bytes32;

    // solhint-disable-next-line var-name-mixedcase
    IOptIn internal immutable _OPT_IN;
    // solhint-disable-next-line var-name-mixedcase
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 private constant BOOSTER_PAYLOAD_TYPEHASH = keccak256(
        "BoosterPayload(address booster,uint64 timestamp,uint64 nonce,bool isLegacySignature)"
    );

    bytes32 internal constant BOOSTER_FUEL_TYPEHASH = keccak256(
        "BoosterFuel(uint96 dubi,uint96 unlockedPrps,uint96 lockedPrps,uint96 intrinsicFuel)"
    );

    // The boost fuel is capped to 10 of the respective token that will be used for payment.
    uint96 internal constant MAX_BOOSTER_FUEL = 10 ether;

    // A magic booster permission prefix
    bytes6 private constant MAGIC_BOOSTER_PERMISSION_PREFIX = "BOOST-";

    constructor(address optIn, bytes32 domainSeparator) public {
        _OPT_IN = IOptIn(optIn);
        _DOMAIN_SEPARATOR = domainSeparator;
    }

    // A mapping of mappings to keep track of used nonces by address to
    // protect against replays. Each 'Boostable' contract maintains it's own
    // state for nonces.
    mapping(address => uint64) private _nonces;

    //---------------------------------------------------------------

    function getNonce(address account) external virtual view returns (uint64) {
        return _nonces[account];
    }

    function getOptInStatus(address account)
        internal
        view
        returns (IOptIn.OptInStatus memory)
    {
        return _OPT_IN.getOptInStatus(account);
    }

    /**
     * @dev Called by every 'boosted'-function to ensure that `msg.sender` (i.e. a booster) is
     * allowed to perform the call for `from` (the origin) by verifying that `messageHash`
     * has been signed by `from`. Additionally, `from` provides a nonce to prevent
     * replays. Boosts cannot be verified out of order.
     *
     * @param from the address that the boost is made for
     * @param messageHash the reconstructed message hash based on the function input
     * @param payload the booster payload
     * @param signature the signature of `from`
     */
    function verifyBoost(
        address from,
        bytes32 messageHash,
        BoosterPayload memory payload,
        Signature memory signature
    ) internal {
        uint64 currentNonce = _nonces[from];
        require(currentNonce == payload.nonce - 1, "AB-1");

        _nonces[from] = currentNonce + 1;

        _verifyBoostWithoutNonce(from, messageHash, payload, signature);
    }

    /**
     * @dev Verify a boost without verifying the nonce.
     */
    function _verifyBoostWithoutNonce(
        address from,
        bytes32 messageHash,
        BoosterPayload memory payload,
        Signature memory signature
    ) internal view {
        // The sender must be the booster specified in the payload
        require(msg.sender == payload.booster, "AB-2");

        (bool isOptedInToSender, uint256 optOutPeriod) = _OPT_IN.isOptedInBy(
            msg.sender,
            from
        );

        // `from` must be opted-in to booster
        require(isOptedInToSender, "AB-3");

        // The given timestamp must not be greater than `block.timestamp + 1 hour`
        // and at most `optOutPeriod(booster)` seconds old.
        uint64 _now = uint64(block.timestamp);
        uint64 _optOutPeriod = uint64(optOutPeriod);

        bool notTooFarInFuture = payload.timestamp <= _now + 1 hours;
        bool belowMaxAge = true;

        // Calculate the absolute difference. Because of the small tolerance, `payload.timestamp`
        // may be greater than `_now`:
        if (payload.timestamp <= _now) {
            belowMaxAge = _now - payload.timestamp <= _optOutPeriod;
        }

        // Signature must not be expired
        require(notTooFarInFuture && belowMaxAge, "AB-4");

        // NOTE: Currently, hardware wallets (e.g. Ledger, Trezor) do not support EIP712 signing (specifically `signTypedData_v4`).
        // However, a user can still sign the EIP712 hash with the caveat that it's signed using `personal_sign` which prepends
        // the prefix '"\x19Ethereum Signed Message:\n" + len(message)'.
        //
        // To still support that, we add the prefix to the hash if `isLegacySignature` is true.
        if (payload.isLegacySignature) {
            messageHash = messageHash.toEthSignedMessageHash();
        }

        // Valid, if the recovered address from `messageHash` with the given `signature` matches `from`.

        address signer = ecrecover(
            messageHash,
            signature.v,
            signature.r,
            signature.s
        );

        if (!payload.isLegacySignature && signer != from) {
            // As a last resort we try anyway, in case the caller simply forgot the `isLegacySignature` flag.
            signer = ecrecover(
                messageHash.toEthSignedMessageHash(),
                signature.v,
                signature.r,
                signature.s
            );
        }

        require(from == signer, "AB-5");
    }

    /**
     * @dev Returns the hash of `payload` using the provided booster (i.e. `msg.sender`).
     */
    function hashBoosterPayload(BoosterPayload memory payload, address booster)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    BOOSTER_PAYLOAD_TYPEHASH,
                    booster,
                    payload.timestamp,
                    payload.nonce
                )
            );
    }

    function _getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

struct Signature {
    bytes32 r;
    bytes32 s;
    uint8 v;
}

interface IOptIn {
    struct OptInStatus {
        bool isOptedIn;
        bool permaBoostActive;
        address optedInTo;
        uint32 optOutPeriod;
    }

    function getOptInStatusPair(address accountA, address accountB)
        external
        view
        returns (OptInStatus memory, OptInStatus memory);

    function getOptInStatus(address account)
        external
        view
        returns (OptInStatus memory);

    function isOptedInBy(address _sender, address _account)
        external
        view
        returns (bool, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "./IOptIn.sol";

struct OpHandle {
    uint8 opType;
    uint64 opId;
}

struct OpMetadata {
    uint8 opType; // the operation type
    uint64 createdAt; // the creation timestamp of an op
    address booster; // the booster at the time of when the op has been created
}

struct OpCounter {
    // The current value of the counter
    uint64 value;
    // Contains the opId that is to be finalized next - i.e. FIFO order
    uint64 nextFinalize;
    // Contains the opId that is to be reverted next - i.e. LIFO order
    uint64 nextRevert;
}

// Library containing public functions for pending ops - those will never be inlined
// to reduce the bytecode size of individual contracts.
library ProtectedBoostableLib {
    using ECDSA for bytes32;

    function deleteOpHandle(
        address user,
        OpHandle memory opHandle,
        OpHandle[] storage opHandles,
        OpCounter storage opCounter,
        mapping(bytes32 => OpMetadata) storage opMetadata
    ) public {
        uint256 length = opHandles.length;
        assert(length > 0);

        uint64 minOpId; // becomes next LIFO
        uint64 maxOpId; // becomes next FIFO

        // Pending ops are capped to MAX_PENDING_OPS. We always perform
        // MIN(length, MAX_PENDING_OPS) look-ups to do a "swap-and-pop" and
        // for updating the opCounter LIFO/FIFO pointers.
        for (uint256 i = 0; i < length; i++) {
            uint64 currOpId = opHandles[i].opId;
            if (currOpId == opHandle.opId) {
                // Overwrite item at i with last
                opHandles[i] = opHandles[length - 1];

                // Continue, to ignore this opId when updating
                // minOpId and maxOpId.
                continue;
            }

            // Update minOpId
            if (minOpId == 0 || currOpId < minOpId) {
                minOpId = currOpId;
            }

            // Update maxOpId
            if (currOpId > maxOpId) {
                maxOpId = currOpId;
            }
        }

        // Might be 0 when everything got finalized/reverted
        opCounter.nextFinalize = minOpId;
        // Might be 0 when everything got finalized/reverted
        opCounter.nextRevert = maxOpId;

        // Remove the last item
        opHandles.pop();

        // Remove metadata
        delete opMetadata[_getOpKey(user, opHandle.opId)];
    }

    function assertCanFinalize(
        OpMetadata memory metadata,
        IOptIn.OptInStatus memory optInStatus
    ) public view returns (uint64) {
        // Now there are three valid scenarios remaining:
        //
        // - msg.sender is the original booster
        // - op is expired
        // - getBoosterAddress returns a different booster than the original booster
        //
        // In the second and third case, anyone can call finalize.
        address originalBooster = metadata.booster;

        if (originalBooster == msg.sender) {
            return metadata.createdAt; // First case
        }

        address currentBooster = optInStatus.optedInTo;
        uint256 optOutPeriod = optInStatus.optOutPeriod;

        bool isExpired = block.timestamp >= metadata.createdAt + optOutPeriod;
        if (isExpired) {
            return metadata.createdAt; // Second case
        }

        if (currentBooster != originalBooster) {
            return metadata.createdAt; // Third case
        }

        revert("PB-4");
    }

    function verifySignatureForRevert(
        address user,
        uint64 opTimestamp,
        IOptIn.OptInStatus memory optInStatus,
        bytes memory boosterMessage,
        address[] memory hasherContracts,
        Signature memory signature
    ) public {
        require(hasherContracts.length > 0, "PB-12");

        // Result of hasher contract call
        uint64 signedAt;
        bytes32 boosterHash;
        bool signatureVerified;

        for (uint256 i = 0; i < hasherContracts.length; i++) {
            // Call into the hasher contract and take the first non-zero result.
            // The contract must implement the following function:
            //
            // decodeAndHashBoosterMessage(
            //     address targetBooster,
            //     bytes memory boosterMessage
            // )
            //
            // If it doesn't, then the call will fail (success=false) and we try the next one.
            // If it succeeds (success = true), then we try to decode the result.
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory result) = address(hasherContracts[i])
                .call(
                // keccak256("decodeAndHashBoosterMessage(address,bytes)")
                abi.encodeWithSelector(
                    0xaf6eec54,
                    msg.sender, /* msg.sender becomes the target booster */
                    boosterMessage
                )
            );

            if (!success) {
                continue;
            }

            // The result is exactly 2 words long = 512 bits = 64 bytes
            // 32 bytes for the expected message hash
            // 8 bytes (padded to 32 bytes) for the expected timestamp
            if (result.length != 64) {
                continue;
            }

            // NOTE: A contract with malintent could return any hash that we would
            // try to recover against. But there is no harm done in doing so since
            // the user must have signed it.
            //
            // However, it might return an unrelated timestamp, that the user hasn't
            // signed - so it could prolong the expiry of a signature which is a valid
            // concern whose risk we minimize by using also the op timestamp which guarantees
            // that a signature eventually expires.

            // Decode and recover signer
            (boosterHash, signedAt) = abi.decode(result, (bytes32, uint64));
            address signer = ecrecover(
                boosterHash,
                signature.v,
                signature.r,
                signature.s
            );

            if (user != signer) {
                // NOTE: Currently, hardware wallets (e.g. Ledger, Trezor) do not support EIP712 signing (specifically `signTypedData_v4`).
                // However, a user can still sign the EIP712 hash with the caveat that it's signed using `personal_sign` which prepends
                // the prefix '"\x19Ethereum Signed Message:\n" + len(message)'.
                //
                // To still support that, we also add the prefix and try to use the recovered address instead:
                signer = ecrecover(
                    boosterHash.toEthSignedMessageHash(),
                    signature.v,
                    signature.r,
                    signature.s
                );
            }

            // If we recovered `user` from the signature, then we have a valid signature.
            if (user == signer) {
                signatureVerified = true;
                break;
            }

            // Keep trying
        }

        // Revert if signature couldn't be verified with any of the returned hashes
        require(signatureVerified, "PB-8");

        // Lastly, the current time must not be older than:
        // MIN(opTimestamp, signedAt) + optOutPeriod * 3
        uint64 _now = uint64(block.timestamp);
        // The maximum age is equal to whichever is lowest:
        //      opTimestamp + optOutPeriod * 3
        //      signedAt + optOutPeriod * 3
        uint64 maximumAge;
        if (opTimestamp > signedAt) {
            maximumAge = signedAt + uint64(optInStatus.optOutPeriod * 3);
        } else {
            maximumAge = opTimestamp + uint64(optInStatus.optOutPeriod * 3);
        }

        require(_now <= maximumAge, "PB-11");
    }

    function _getOpKey(address user, uint64 opId)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(user, opId));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

