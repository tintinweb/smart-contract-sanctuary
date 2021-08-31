/**
 *Submitted for verification at polygonscan.com on 2021-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

library BpLibrary {
    using SafeMathUpgradeable for uint256;

    function bp(uint256 value, uint256 bpValue)
        internal
        pure
        returns (uint256)
    {
        return value.mul(bpValue).div(10000);
    }
}

// File: exchange-v2/contracts/LibFeeSide.sol

library LibFeeSide {
    enum FeeSide {
        NONE,
        MAKE,
        TAKE
    }

    function getFeeSide(bytes4 make, bytes4 take)
        internal
        pure
        returns (FeeSide)
    {
        if (make == LibAsset.ETH_ASSET_CLASS) {
            return FeeSide.MAKE;
        }
        if (take == LibAsset.ETH_ASSET_CLASS) {
            return FeeSide.TAKE;
        }
        if (make == LibAsset.ERC20_ASSET_CLASS) {
            return FeeSide.MAKE;
        }
        if (take == LibAsset.ERC20_ASSET_CLASS) {
            return FeeSide.TAKE;
        }
        if (make == LibAsset.ERC1155_ASSET_CLASS) {
            return FeeSide.MAKE;
        }
        if (take == LibAsset.ERC1155_ASSET_CLASS) {
            return FeeSide.TAKE;
        }
        return FeeSide.NONE;
    }
}

// File: exchange-v2/rarible/lazy-mint/contracts/erc-1155/LibERC1155LazyMint.sol

library LibERC1155LazyMint {
    bytes4 public constant ERC1155_LAZY_ASSET_CLASS =
        bytes4(keccak256("ERC1155_LAZY"));
    bytes4 constant _INTERFACE_ID_MINT_AND_TRANSFER = 0x6db15a0f;

    struct Mint1155Data {
        uint256 tokenId;
        string tokenURI;
        uint256 supply;
        LibPart.Part[] creators;
        LibPart.Part[] royalties;
        bytes[] signatures;
    }

    bytes32 public constant MINT_AND_TRANSFER_TYPEHASH =
        keccak256(
            "Mint1155(uint256 tokenId,uint256 supply,string tokenURI,Part[] creators,Part[] royalties)Part(address account,uint96 value)"
        );

    function hash(Mint1155Data memory data) internal pure returns (bytes32) {
        bytes32[] memory royaltiesBytes = new bytes32[](data.royalties.length);
        for (uint256 i = 0; i < data.royalties.length; i++) {
            royaltiesBytes[i] = LibPart.hash(data.royalties[i]);
        }
        bytes32[] memory creatorsBytes = new bytes32[](data.creators.length);
        for (uint256 i = 0; i < data.creators.length; i++) {
            creatorsBytes[i] = LibPart.hash(data.creators[i]);
        }
        return
            keccak256(
                abi.encode(
                    MINT_AND_TRANSFER_TYPEHASH,
                    data.tokenId,
                    data.supply,
                    keccak256(bytes(data.tokenURI)),
                    keccak256(abi.encodePacked(creatorsBytes)),
                    keccak256(abi.encodePacked(royaltiesBytes))
                )
            );
    }
}

// File: exchange-v2/rarible/lazy-mint/contracts/erc-721/LibERC721LazyMint.sol

library LibERC721LazyMint {
    bytes4 public constant ERC721_LAZY_ASSET_CLASS =
        bytes4(keccak256("ERC721_LAZY"));
    bytes4 constant _INTERFACE_ID_MINT_AND_TRANSFER = 0x8486f69f;

    struct Mint721Data {
        uint256 tokenId;
        string tokenURI;
        LibPart.Part[] creators;
        LibPart.Part[] royalties;
        bytes[] signatures;
    }

    bytes32 public constant MINT_AND_TRANSFER_TYPEHASH =
        keccak256(
            "Mint721(uint256 tokenId,string tokenURI,Part[] creators,Part[] royalties)Part(address account,uint96 value)"
        );

    function hash(Mint721Data memory data) internal pure returns (bytes32) {
        bytes32[] memory royaltiesBytes = new bytes32[](data.royalties.length);
        for (uint256 i = 0; i < data.royalties.length; i++) {
            royaltiesBytes[i] = LibPart.hash(data.royalties[i]);
        }
        bytes32[] memory creatorsBytes = new bytes32[](data.creators.length);
        for (uint256 i = 0; i < data.creators.length; i++) {
            creatorsBytes[i] = LibPart.hash(data.creators[i]);
        }
        return
            keccak256(
                abi.encode(
                    MINT_AND_TRANSFER_TYPEHASH,
                    data.tokenId,
                    keccak256(bytes(data.tokenURI)),
                    keccak256(abi.encodePacked(creatorsBytes)),
                    keccak256(abi.encodePacked(royaltiesBytes))
                )
            );
    }
}

// File: exchange-v2/rarible/royalties/contracts/IRoyaltiesProvider.sol

interface IRoyaltiesProvider {
    function getRoyalties(address token, uint256 tokenId)
        external
        returns (LibPart.Part[] memory);
}

// File: exchange-v2/contracts/RaribleTransferManager.sol

// File: exchange-v2/openzeppelin/contracts-upgradeable/proxy/Initializable.sol

// solhint-disable-next-line compiler-version

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(
            _initializing || _isConstructor() || !_initialized,
            "Initializable: contract is already initialized"
        );

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File: exchange-v2/openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// File: exchange-v2/openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

// File: exchange-v2/contracts/ITransferManager.sol

// File: exchange-v2/contracts/ITransferExecutor.sol

abstract contract ITransferExecutor {
    //events
    event Transfer(
        LibAsset.Asset asset,
        address from,
        address to,
        bytes4 transferDirection,
        bytes4 transferType
    );

    function transfer(
        LibAsset.Asset memory asset,
        address from,
        address to,
        bytes4 transferDirection,
        bytes4 transferType
    ) internal virtual;
}

abstract contract ITransferManager is ITransferExecutor {
    //transfer directions:
    bytes4 constant TO_MAKER = bytes4(keccak256("TO_MAKER"));
    bytes4 constant TO_TAKER = bytes4(keccak256("TO_TAKER"));
    bytes4 constant TO_LOCK = bytes4(keccak256("TO_LOCK"));

    //transfer types:
    bytes4 constant PROTOCOL = bytes4(keccak256("PROTOCOL"));
    bytes4 constant ROYALTY = bytes4(keccak256("ROYALTY"));
    bytes4 constant ORIGIN = bytes4(keccak256("ORIGIN"));
    bytes4 constant PAYOUT = bytes4(keccak256("PAYOUT"));
    bytes4 constant LOCK = bytes4(keccak256("LOCK"));
    bytes4 constant UNLOCK = bytes4(keccak256("UNLOCK"));

    function doTransfers(
        LibAsset.AssetType memory makeMatch,
        LibAsset.AssetType memory takeMatch,
        LibFill.FillResult memory fill,
        LibOrder.Order memory leftOrder,
        LibOrder.Order memory rightOrder
    ) internal virtual returns (uint256 totalMakeValue, uint256 totalTakeValue);

    function calculateTotalAmount(
        uint256 amount,
        uint256 feeOnTopBp,
        LibPart.Part[] memory orderOriginFees
    ) internal view virtual returns (uint256 total);

    function getOrderProtocolFee(LibOrder.Order memory order, bytes32 hash)
        internal
        view
        virtual
        returns (uint256);

    function getProtocolFee() internal view virtual returns (uint256);
}

abstract contract RaribleTransferManager is
    OwnableUpgradeable,
    ITransferManager
{
    using BpLibrary for uint256;
    using SafeMathUpgradeable for uint256;

    uint256 public protocolFee;
    IRoyaltiesProvider public royaltiesRegistry;

    address public defaultFeeReceiver;
    mapping(address => address) public feeReceivers;

    /// @dev struct that stores protocolFee for both orders in a match
    struct MatchProtocolFees {
        uint256 feeSide;
        uint256 nftSide;
    }

    function __RaribleTransferManager_init_unchained(
        uint256 newProtocolFee,
        address newDefaultFeeReceiver,
        IRoyaltiesProvider newRoyaltiesProvider
    ) internal initializer {
        protocolFee = newProtocolFee;
        defaultFeeReceiver = newDefaultFeeReceiver;
        royaltiesRegistry = newRoyaltiesProvider;
    }

    function setRoyaltiesRegistry(IRoyaltiesProvider newRoyaltiesRegistry)
        external
        onlyOwner
    {
        royaltiesRegistry = newRoyaltiesRegistry;
    }

    function setProtocolFee(uint256 newProtocolFee) external onlyOwner {
        protocolFee = newProtocolFee;
    }

    function setDefaultFeeReceiver(address payable newDefaultFeeReceiver)
        external
        onlyOwner
    {
        defaultFeeReceiver = newDefaultFeeReceiver;
    }

    function setFeeReceiver(address token, address wallet) external onlyOwner {
        feeReceivers[token] = wallet;
    }

    function getFeeReceiver(address token) internal view returns (address) {
        address wallet = feeReceivers[token];
        if (wallet != address(0)) {
            return wallet;
        }
        return defaultFeeReceiver;
    }

    function doTransfers(
        LibAsset.AssetType memory makeMatch,
        LibAsset.AssetType memory takeMatch,
        LibFill.FillResult memory fill,
        LibOrder.Order memory leftOrder,
        LibOrder.Order memory rightOrder
    )
        internal
        override
        returns (uint256 totalMakeValue, uint256 totalTakeValue)
    {
        LibFeeSide.FeeSide feeSide = LibFeeSide.getFeeSide(
            makeMatch.assetClass,
            takeMatch.assetClass
        );
        totalMakeValue = fill.makeValue;
        totalTakeValue = fill.takeValue;
        if (feeSide == LibFeeSide.FeeSide.MAKE) {
            totalMakeValue = doTransfersWithFees(
                fill.makeValue,
                leftOrder.maker,
                getMatchProtocolFees(leftOrder, rightOrder, feeSide),
                LibOrderData.parse(leftOrder),
                LibOrderData.parse(rightOrder),
                makeMatch,
                takeMatch,
                TO_TAKER
            );
            transferPayouts(
                takeMatch,
                fill.takeValue,
                rightOrder.maker,
                LibOrderData.parse(leftOrder).payouts,
                TO_MAKER
            );
        } else if (feeSide == LibFeeSide.FeeSide.TAKE) {
            totalTakeValue = doTransfersWithFees(
                fill.takeValue,
                rightOrder.maker,
                getMatchProtocolFees(leftOrder, rightOrder, feeSide),
                LibOrderData.parse(rightOrder),
                LibOrderData.parse(leftOrder),
                takeMatch,
                makeMatch,
                TO_MAKER
            );
            transferPayouts(
                makeMatch,
                fill.makeValue,
                leftOrder.maker,
                LibOrderData.parse(rightOrder).payouts,
                TO_TAKER
            );
        } else {
            transferPayouts(
                makeMatch,
                fill.makeValue,
                leftOrder.maker,
                LibOrderData.parse(rightOrder).payouts,
                TO_TAKER
            );
            transferPayouts(
                takeMatch,
                fill.takeValue,
                rightOrder.maker,
                LibOrderData.parse(leftOrder).payouts,
                TO_MAKER
            );
        }
    }

    function doTransfersWithFees(
        uint256 amount,
        address from,
        MatchProtocolFees memory matchProtocolFee,
        LibOrderDataV1.DataV1 memory dataCalculate,
        LibOrderDataV1.DataV1 memory dataNft,
        LibAsset.AssetType memory matchCalculate,
        LibAsset.AssetType memory matchNft,
        bytes4 transferDirection
    ) internal returns (uint256 totalAmount) {
        totalAmount = calculateTotalAmount(
            amount,
            matchProtocolFee.feeSide,
            dataCalculate.originFees
        );
        uint256 rest = transferProtocolFee(
            totalAmount,
            amount,
            from,
            matchProtocolFee,
            matchCalculate,
            transferDirection
        );
        rest = transferRoyalties(
            matchCalculate,
            matchNft,
            rest,
            amount,
            from,
            transferDirection
        );
        (rest, ) = transferFees(
            matchCalculate,
            rest,
            amount,
            dataCalculate.originFees,
            from,
            transferDirection,
            ORIGIN
        );
        (rest, ) = transferFees(
            matchCalculate,
            rest,
            amount,
            dataNft.originFees,
            from,
            transferDirection,
            ORIGIN
        );
        transferPayouts(
            matchCalculate,
            rest,
            from,
            dataNft.payouts,
            transferDirection
        );
    }

    function transferProtocolFee(
        uint256 totalAmount,
        uint256 amount,
        address from,
        MatchProtocolFees memory matchProtocolFee,
        LibAsset.AssetType memory matchCalculate,
        bytes4 transferDirection
    ) internal returns (uint256) {
        (uint256 rest, uint256 fee) = subFeeInBp(
            totalAmount,
            amount,
            matchProtocolFee.feeSide + matchProtocolFee.nftSide
        );
        if (fee > 0) {
            address tokenAddress = address(0);
            if (matchCalculate.assetClass == LibAsset.ERC20_ASSET_CLASS) {
                tokenAddress = abi.decode(matchCalculate.data, (address));
            } else if (
                matchCalculate.assetClass == LibAsset.ERC1155_ASSET_CLASS
            ) {
                uint256 tokenId;
                (tokenAddress, tokenId) = abi.decode(
                    matchCalculate.data,
                    (address, uint256)
                );
            }
            transfer(
                LibAsset.Asset(matchCalculate, fee),
                from,
                getFeeReceiver(tokenAddress),
                transferDirection,
                PROTOCOL
            );
        }
        return rest;
    }

    function transferRoyalties(
        LibAsset.AssetType memory matchCalculate,
        LibAsset.AssetType memory matchNft,
        uint256 rest,
        uint256 amount,
        address from,
        bytes4 transferDirection
    ) internal returns (uint256) {
        LibPart.Part[] memory fees = getRoyaltiesByAssetType(matchNft);

        (uint256 result, uint256 totalRoyalties) = transferFees(
            matchCalculate,
            rest,
            amount,
            fees,
            from,
            transferDirection,
            ROYALTY
        );
        require(totalRoyalties <= 5000, "Royalties are too high (>50%)");
        return result;
    }

    function getRoyaltiesByAssetType(LibAsset.AssetType memory matchNft)
        internal
        returns (LibPart.Part[] memory)
    {
        if (
            matchNft.assetClass == LibAsset.ERC1155_ASSET_CLASS ||
            matchNft.assetClass == LibAsset.ERC721_ASSET_CLASS
        ) {
            (address token, uint256 tokenId) = abi.decode(
                matchNft.data,
                (address, uint256)
            );
            return royaltiesRegistry.getRoyalties(token, tokenId);
        } else if (
            matchNft.assetClass == LibERC1155LazyMint.ERC1155_LAZY_ASSET_CLASS
        ) {
            (address token, LibERC1155LazyMint.Mint1155Data memory data) = abi
                .decode(
                    matchNft.data,
                    (address, LibERC1155LazyMint.Mint1155Data)
                );
            return data.royalties;
        } else if (
            matchNft.assetClass == LibERC721LazyMint.ERC721_LAZY_ASSET_CLASS
        ) {
            (address token, LibERC721LazyMint.Mint721Data memory data) = abi
                .decode(
                    matchNft.data,
                    (address, LibERC721LazyMint.Mint721Data)
                );
            return data.royalties;
        }
        LibPart.Part[] memory empty;
        return empty;
    }

    function transferFees(
        LibAsset.AssetType memory matchCalculate,
        uint256 rest,
        uint256 amount,
        LibPart.Part[] memory fees,
        address from,
        bytes4 transferDirection,
        bytes4 transferType
    ) internal returns (uint256 restValue, uint256 totalFees) {
        totalFees = 0;
        restValue = rest;
        for (uint256 i = 0; i < fees.length; i++) {
            totalFees = totalFees.add(fees[i].value);
            (uint256 newRestValue, uint256 feeValue) = subFeeInBp(
                restValue,
                amount,
                fees[i].value
            );
            restValue = newRestValue;
            if (feeValue > 0) {
                transfer(
                    LibAsset.Asset(matchCalculate, feeValue),
                    from,
                    fees[i].account,
                    transferDirection,
                    transferType
                );
            }
        }
    }

    function transferPayouts(
        LibAsset.AssetType memory matchCalculate,
        uint256 amount,
        address from,
        LibPart.Part[] memory payouts,
        bytes4 transferDirection
    ) internal {
        uint256 sumBps = 0;
        uint256 restValue = amount;
        for (uint256 i = 0; i < payouts.length - 1; i++) {
            uint256 currentAmount = amount.bp(payouts[i].value);
            sumBps = sumBps.add(payouts[i].value);
            if (currentAmount > 0) {
                restValue = restValue.sub(currentAmount);
                transfer(
                    LibAsset.Asset(matchCalculate, currentAmount),
                    from,
                    payouts[i].account,
                    transferDirection,
                    PAYOUT
                );
            }
        }
        LibPart.Part memory lastPayout = payouts[payouts.length - 1];
        sumBps = sumBps.add(lastPayout.value);
        require(sumBps == 10000, "Sum payouts Bps not equal 100%");
        if (restValue > 0) {
            transfer(
                LibAsset.Asset(matchCalculate, restValue),
                from,
                lastPayout.account,
                transferDirection,
                PAYOUT
            );
        }
    }

    function calculateTotalAmount(
        uint256 amount,
        uint256 feeOnTopBp,
        LibPart.Part[] memory orderOriginFees
    ) internal pure override returns (uint256 total) {
        total = amount.add(amount.bp(feeOnTopBp));
        for (uint256 i = 0; i < orderOriginFees.length; i++) {
            total = total.add(amount.bp(orderOriginFees[i].value));
        }
    }

    function subFeeInBp(
        uint256 value,
        uint256 total,
        uint256 feeInBp
    ) internal pure returns (uint256 newValue, uint256 realFee) {
        return subFee(value, total.bp(feeInBp));
    }

    function subFee(uint256 value, uint256 fee)
        internal
        pure
        returns (uint256 newValue, uint256 realFee)
    {
        if (value > fee) {
            newValue = value.sub(fee);
            realFee = fee;
        } else {
            newValue = 0;
            realFee = value;
        }
    }

    /// @dev rutrns MatchProtocolFees struct with protocol fees of both orders in a match
    function getMatchProtocolFees(
        LibOrder.Order memory leftOrder,
        LibOrder.Order memory rightOrder,
        LibFeeSide.FeeSide feeSide
    ) internal view returns (MatchProtocolFees memory) {
        MatchProtocolFees memory result;
        uint256 leftFee = getOrderProtocolFee(
            leftOrder,
            LibOrder.hashKey(leftOrder)
        );
        uint256 rightFee = getOrderProtocolFee(
            rightOrder,
            LibOrder.hashKey(rightOrder)
        );
        if (feeSide == LibFeeSide.FeeSide.MAKE) {
            result.feeSide = leftFee;
            result.nftSide = rightFee;
        } else if (feeSide == LibFeeSide.FeeSide.TAKE) {
            result.feeSide = rightFee;
            result.nftSide = leftFee;
        } else {
            revert("unexpected feeSide = NONE");
        }

        return result;
    }

    uint256[46] private __gap;
}

// File: exchange-v2/rarible/royalties/contracts/LibPart.sol

library LibPart {
    bytes32 public constant TYPE_HASH =
        keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

// File: exchange-v2/contracts/LibOrderDataV1.sol

library LibOrderDataV1 {
    bytes4 public constant V1 = bytes4(keccak256("V1"));

    struct DataV1 {
        LibPart.Part[] payouts;
        LibPart.Part[] originFees;
    }

    function decodeOrderDataV1(bytes memory data)
        internal
        pure
        returns (DataV1 memory orderData)
    {
        orderData = abi.decode(data, (DataV1));
    }
}

// File: exchange-v2/contracts/LibOrderData.sol

library LibOrderData {
    function parse(LibOrder.Order memory order)
        internal
        pure
        returns (LibOrderDataV1.DataV1 memory dataOrder)
    {
        if (order.dataType == LibOrderDataV1.V1) {
            dataOrder = LibOrderDataV1.decodeOrderDataV1(order.data);
            if (dataOrder.payouts.length == 0) {
                dataOrder = payoutSet(order.maker, dataOrder);
            }
        } else if (order.dataType == 0xffffffff) {
            dataOrder = payoutSet(order.maker, dataOrder);
        } else {
            revert("Unknown Order data type");
        }
    }

    function payoutSet(
        address orderAddress,
        LibOrderDataV1.DataV1 memory dataOrderOnePayoutIn
    ) internal pure returns (LibOrderDataV1.DataV1 memory) {
        LibPart.Part[] memory payout = new LibPart.Part[](1);
        payout[0].account = payable(orderAddress);
        payout[0].value = 10000;
        dataOrderOnePayoutIn.payouts = payout;
        return dataOrderOnePayoutIn;
    }
}

// File: exchange-v2/contracts/lib/LibTransfer.sol

library LibTransfer {
    function transferEth(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "transfer failed");
    }
}

// File: exchange-v2/openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: exchange-v2/rarible/exchange-interfaces/contracts/IERC20TransferProxy.sol

interface IERC20TransferProxy {
    function erc20safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) external;
}

// File: exchange-v2/openzeppelin/contracts-upgradeable/introspection/IERC165Upgradeable.sol

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: exchange-v2/openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: exchange-v2/openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// File: exchange-v2/rarible/exchange-interfaces/contracts/INftTransferProxy.sol

interface INftTransferProxy {
    function erc721safeTransferFrom(
        IERC721Upgradeable token,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function erc1155safeTransferFrom(
        IERC1155Upgradeable token,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;
}

// File: exchange-v2/rarible/exchange-interfaces/contracts/ITransferProxy.sol

interface ITransferProxy {
    function transfer(
        LibAsset.Asset calldata asset,
        address from,
        address to
    ) external;
}

// File: exchange-v2/contracts/TransferExecutor.sol

abstract contract TransferExecutor is
    Initializable,
    OwnableUpgradeable,
    ITransferExecutor
{
    using LibTransfer for address;

    mapping(bytes4 => address) proxies;

    event ProxyChange(bytes4 indexed assetType, address proxy);

    function __TransferExecutor_init_unchained(
        INftTransferProxy transferProxy,
        IERC20TransferProxy erc20TransferProxy
    ) internal {
        proxies[LibAsset.ERC20_ASSET_CLASS] = address(erc20TransferProxy);
        proxies[LibAsset.ERC721_ASSET_CLASS] = address(transferProxy);
        proxies[LibAsset.ERC1155_ASSET_CLASS] = address(transferProxy);
    }

    function setTransferProxy(bytes4 assetType, address proxy)
        external
        onlyOwner
    {
        proxies[assetType] = proxy;
        emit ProxyChange(assetType, proxy);
    }

    function transfer(
        LibAsset.Asset memory asset,
        address from,
        address to,
        bytes4 transferDirection,
        bytes4 transferType
    ) internal override {
        if (asset.assetType.assetClass == LibAsset.ETH_ASSET_CLASS) {
            to.transferEth(asset.value);
        } else if (asset.assetType.assetClass == LibAsset.ERC20_ASSET_CLASS) {
            address token = abi.decode(asset.assetType.data, (address));
            IERC20TransferProxy(proxies[LibAsset.ERC20_ASSET_CLASS])
                .erc20safeTransferFrom(
                    IERC20Upgradeable(token),
                    from,
                    to,
                    asset.value
                );
        } else if (asset.assetType.assetClass == LibAsset.ERC721_ASSET_CLASS) {
            (address token, uint256 tokenId) = abi.decode(
                asset.assetType.data,
                (address, uint256)
            );
            require(asset.value == 1, "erc721 value error");
            INftTransferProxy(proxies[LibAsset.ERC721_ASSET_CLASS])
                .erc721safeTransferFrom(
                    IERC721Upgradeable(token),
                    from,
                    to,
                    tokenId
                );
        } else if (asset.assetType.assetClass == LibAsset.ERC1155_ASSET_CLASS) {
            (address token, uint256 tokenId) = abi.decode(
                asset.assetType.data,
                (address, uint256)
            );
            INftTransferProxy(proxies[LibAsset.ERC1155_ASSET_CLASS])
                .erc1155safeTransferFrom(
                    IERC1155Upgradeable(token),
                    from,
                    to,
                    tokenId,
                    asset.value,
                    ""
                );
        } else {
            ITransferProxy(proxies[asset.assetType.assetClass]).transfer(
                asset,
                from,
                to
            );
        }
        emit Transfer(asset, from, to, transferDirection, transferType);
    }

    uint256[49] private __gap;
}

// File: exchange-v2/contracts/IAssetMatcher.sol

pragma experimental ABIEncoderV2;

interface IAssetMatcher {
    function matchAssets(
        LibAsset.AssetType memory leftAssetType,
        LibAsset.AssetType memory rightAssetType
    ) external view returns (LibAsset.AssetType memory);
}

// File: exchange-v2/contracts/AssetMatcher.sol

abstract contract AssetMatcher is Initializable, OwnableUpgradeable {
    bytes constant EMPTY = "";
    mapping(bytes4 => address) matchers;

    event MatcherChange(bytes4 indexed assetType, address matcher);

    function setAssetMatcher(bytes4 assetType, address matcher)
        external
        onlyOwner
    {
        matchers[assetType] = matcher;
        emit MatcherChange(assetType, matcher);
    }

    function matchAssets(
        LibAsset.AssetType memory leftAssetType,
        LibAsset.AssetType memory rightAssetType
    ) internal view returns (LibAsset.AssetType memory) {
        LibAsset.AssetType memory result = matchAssetOneSide(
            leftAssetType,
            rightAssetType
        );
        if (result.assetClass == 0) {
            return matchAssetOneSide(rightAssetType, leftAssetType);
        } else {
            return result;
        }
    }

    function matchAssetOneSide(
        LibAsset.AssetType memory leftAssetType,
        LibAsset.AssetType memory rightAssetType
    ) private view returns (LibAsset.AssetType memory) {
        bytes4 classLeft = leftAssetType.assetClass;
        bytes4 classRight = rightAssetType.assetClass;
        if (classLeft == LibAsset.ETH_ASSET_CLASS) {
            if (classRight == LibAsset.ETH_ASSET_CLASS) {
                return leftAssetType;
            }
            return LibAsset.AssetType(0, EMPTY);
        }
        if (classLeft == LibAsset.ERC20_ASSET_CLASS) {
            if (classRight == LibAsset.ERC20_ASSET_CLASS) {
                return simpleMatch(leftAssetType, rightAssetType);
            }
            return LibAsset.AssetType(0, EMPTY);
        }
        if (classLeft == LibAsset.ERC721_ASSET_CLASS) {
            if (classRight == LibAsset.ERC721_ASSET_CLASS) {
                return simpleMatch(leftAssetType, rightAssetType);
            }
            return LibAsset.AssetType(0, EMPTY);
        }
        if (classLeft == LibAsset.ERC1155_ASSET_CLASS) {
            if (classRight == LibAsset.ERC1155_ASSET_CLASS) {
                return simpleMatch(leftAssetType, rightAssetType);
            }
            return LibAsset.AssetType(0, EMPTY);
        }
        address matcher = matchers[classLeft];
        if (matcher != address(0)) {
            return
                IAssetMatcher(matcher).matchAssets(
                    leftAssetType,
                    rightAssetType
                );
        }
        if (classLeft == classRight) {
            return simpleMatch(leftAssetType, rightAssetType);
        }
        revert("not found IAssetMatcher");
    }

    function simpleMatch(
        LibAsset.AssetType memory leftAssetType,
        LibAsset.AssetType memory rightAssetType
    ) private view returns (LibAsset.AssetType memory) {
        bytes32 leftHash = keccak256(leftAssetType.data);
        bytes32 rightHash = keccak256(rightAssetType.data);
        if (leftHash == rightHash) {
            return leftAssetType;
        }
        return LibAsset.AssetType(0, EMPTY);
    }

    uint256[49] private __gap;
}

// File: exchange-v2/openzeppelin/contracts-upgradeable/drafts/EIP712Upgradeable.sol

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version)
        internal
        initializer
    {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version)
        internal
        initializer
    {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return
            _buildDomainSeparator(
                _TYPE_HASH,
                _EIP712NameHash(),
                _EIP712VersionHash()
            );
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 name,
        bytes32 version
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    name,
                    version,
                    _getChainId(),
                    address(this)
                )
            );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash)
        internal
        view
        virtual
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash)
            );
    }

    function _getChainId() private view returns (uint256 chainId) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal view virtual returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal view virtual returns (bytes32) {
        return _HASHED_VERSION;
    }

    uint256[50] private __gap;
}

// File: exchange-v2/openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // solhint-disable-next-line no-inline-assembly
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// File: exchange-v2/contracts/lib/LibSignature.sol

library LibSignature {
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
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
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

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );

        // If the signature is valid (and not malleable), return the signer address
        // v > 30 is a special case, we need to adjust hash with "\x19Ethereum Signed Message:\n32"
        // and v = v - 4
        address signer;
        if (v > 30) {
            require(
                v - 4 == 27 || v - 4 == 28,
                "ECDSA: invalid signature 'v' value"
            );
            signer = ecrecover(toEthSignedMessageHash(hash), v - 4, r, s);
        } else {
            require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");
            signer = ecrecover(hash, v, r, s);
        }

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
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}

// File: exchange-v2/contracts/interfaces/ERC1271.sol

interface ERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param _hash Hash of the data signed on the behalf of address(this)
     * @param _signature Signature byte array associated with _data
     *
     * MUST return the bytes4 magic value 0x1626ba7e when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes32 _hash, bytes calldata _signature)
        external
        view
        virtual
        returns (bytes4 magicValue);
}

// File: exchange-v2/contracts/OrderValidator.sol

abstract contract OrderValidator is
    Initializable,
    ContextUpgradeable,
    EIP712Upgradeable
{
    using LibSignature for bytes32;
    using AddressUpgradeable for address;

    bytes4 internal constant MAGICVALUE = 0x1626ba7e;

    function __OrderValidator_init_unchained() internal initializer {
        __EIP712_init_unchained("Exchange", "2");
    }

    function validate(LibOrder.Order memory order, bytes memory signature)
        internal
        view
    {
        if (order.salt == 0) {
            require(_msgSender() == order.maker, "maker is not tx sender");
        } else {
            if (_msgSender() != order.maker) {
                bytes32 hash = LibOrder.hash(order);
                if (_hashTypedDataV4(hash).recover(signature) != order.maker) {
                    if (order.maker.isContract()) {
                        require(
                            ERC1271(order.maker).isValidSignature(
                                _hashTypedDataV4(hash),
                                signature
                            ) == MAGICVALUE,
                            "contract order signature verification error"
                        );
                    } else {
                        revert("order signature verification error");
                    }
                }
            }
        }
    }

    uint256[50] private __gap;
}

// File: exchange-v2/openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}

// File: exchange-v2/rarible/lib-asset/contracts/LibAsset.sol

library LibAsset {
    bytes4 public constant ETH_ASSET_CLASS = bytes4(keccak256("ETH"));
    bytes4 public constant ERC20_ASSET_CLASS = bytes4(keccak256("ERC20"));
    bytes4 public constant ERC721_ASSET_CLASS = bytes4(keccak256("ERC721"));
    bytes4 public constant ERC1155_ASSET_CLASS = bytes4(keccak256("ERC1155"));

    bytes32 constant ASSET_TYPE_TYPEHASH =
        keccak256("AssetType(bytes4 assetClass,bytes data)");

    bytes32 constant ASSET_TYPEHASH =
        keccak256(
            "Asset(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)"
        );

    struct AssetType {
        bytes4 assetClass;
        bytes data;
    }

    struct Asset {
        AssetType assetType;
        uint256 value;
    }

    function hash(AssetType memory assetType) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ASSET_TYPE_TYPEHASH,
                    assetType.assetClass,
                    keccak256(assetType.data)
                )
            );
    }

    function hash(Asset memory asset) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(ASSET_TYPEHASH, hash(asset.assetType), asset.value)
            );
    }
}

// File: exchange-v2/openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol

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
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: exchange-v2/contracts/lib/LibMath.sol

library LibMath {
    using SafeMathUpgradeable for uint256;

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    ///      Reverts if rounding error is >= 0.1%
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return partialAmount value of target rounded down.
    function safeGetPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (uint256 partialAmount) {
        if (isRoundingErrorFloor(numerator, denominator, target)) {
            revert("rounding error");
        }
        partialAmount = numerator.mul(target).div(denominator);
    }

    /// @dev Checks if rounding error >= 0.1% when rounding down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return isError Rounding error is present.
    function isRoundingErrorFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (bool isError) {
        if (denominator == 0) {
            revert("division by zero");
        }

        // The absolute rounding error is the difference between the rounded
        // value and the ideal value. The relative rounding error is the
        // absolute rounding error divided by the absolute value of the
        // ideal value. This is undefined when the ideal value is zero.
        //
        // The ideal value is `numerator * target / denominator`.
        // Let's call `numerator * target % denominator` the remainder.
        // The absolute error is `remainder / denominator`.
        //
        // When the ideal value is zero, we require the absolute error to
        // be zero. Fortunately, this is always the case. The ideal value is
        // zero iff `numerator == 0` and/or `target == 0`. In this case the
        // remainder and absolute error are also zero.
        if (target == 0 || numerator == 0) {
            return false;
        }

        // Otherwise, we want the relative rounding error to be strictly
        // less than 0.1%.
        // The relative error is `remainder / (numerator * target)`.
        // We want the relative error less than 1 / 1000:
        //        remainder / (numerator * target)  <  1 / 1000
        // or equivalently:
        //        1000 * remainder  <  numerator * target
        // so we have a rounding error iff:
        //        1000 * remainder  >=  numerator * target
        uint256 remainder = mulmod(target, numerator, denominator);
        isError = remainder.mul(1000) >= numerator.mul(target);
    }

    function safeGetPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (uint256 partialAmount) {
        if (isRoundingErrorCeil(numerator, denominator, target)) {
            revert("rounding error");
        }
        partialAmount = numerator.mul(target).add(denominator.sub(1)).div(
            denominator
        );
    }

    /// @dev Checks if rounding error >= 0.1% when rounding up.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return isError Rounding error is present.
    function isRoundingErrorCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (bool isError) {
        if (denominator == 0) {
            revert("division by zero");
        }

        // See the comments in `isRoundingError`.
        if (target == 0 || numerator == 0) {
            // When either is zero, the ideal value and rounded value are zero
            // and there is no rounding error. (Although the relative error
            // is undefined.)
            return false;
        }
        // Compute remainder as before
        uint256 remainder = mulmod(target, numerator, denominator);
        remainder = denominator.sub(remainder) % denominator;
        isError = remainder.mul(1000) >= numerator.mul(target);
        return isError;
    }
}

// File: exchange-v2/contracts/LibOrder.sol

library LibOrder {
    using SafeMathUpgradeable for uint256;

    bytes32 constant ORDER_TYPEHASH =
        keccak256(
            "Order(address maker,Asset makeAsset,address taker,Asset takeAsset,uint256 salt,uint256 start,uint256 end,bytes4 dataType,bytes data)Asset(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)"
        );

    struct Order {
        address maker;
        LibAsset.Asset makeAsset;
        address taker;
        LibAsset.Asset takeAsset;
        uint256 salt;
        uint256 start;
        uint256 end;
        bytes4 dataType;
        bytes data;
    }

    function calculateRemaining(Order memory order, uint256 fill)
        internal
        pure
        returns (uint256 makeValue, uint256 takeValue)
    {
        takeValue = order.takeAsset.value.sub(fill);
        makeValue = LibMath.safeGetPartialAmountFloor(
            order.makeAsset.value,
            order.takeAsset.value,
            takeValue
        );
    }

    function hashKey(Order memory order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    order.maker,
                    LibAsset.hash(order.makeAsset.assetType),
                    LibAsset.hash(order.takeAsset.assetType),
                    order.salt
                )
            );
    }

    function hash(Order memory order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.maker,
                    LibAsset.hash(order.makeAsset),
                    order.taker,
                    LibAsset.hash(order.takeAsset),
                    order.salt,
                    order.start,
                    order.end,
                    order.dataType,
                    keccak256(order.data)
                )
            );
    }

    function validate(LibOrder.Order memory order) internal view {
        require(
            order.start == 0 || order.start < block.timestamp,
            "Order start validation failed"
        );
        require(
            order.end == 0 || order.end > block.timestamp,
            "Order end validation failed"
        );
    }
}

// File: exchange-v2/contracts/LibFill.sol

library LibFill {
    using SafeMathUpgradeable for uint256;

    struct FillResult {
        uint256 makeValue;
        uint256 takeValue;
    }

    /**
     * @dev Should return filled values
     * @param leftOrder left order
     * @param rightOrder right order
     * @param leftOrderFill current fill of the left order (0 if order is unfilled)
     * @param rightOrderFill current fill of the right order (0 if order is unfilled)
     */
    function fillOrder(
        LibOrder.Order memory leftOrder,
        LibOrder.Order memory rightOrder,
        uint256 leftOrderFill,
        uint256 rightOrderFill
    ) internal pure returns (FillResult memory) {
        (uint256 leftMakeValue, uint256 leftTakeValue) = LibOrder
            .calculateRemaining(leftOrder, leftOrderFill);
        (uint256 rightMakeValue, uint256 rightTakeValue) = LibOrder
            .calculateRemaining(rightOrder, rightOrderFill);

        //We have 3 cases here:
        if (rightTakeValue > leftMakeValue) {
            //1nd: left order should be fully filled
            return
                fillLeft(
                    leftMakeValue,
                    leftTakeValue,
                    rightOrder.makeAsset.value,
                    rightOrder.takeAsset.value
                );
        } //2st: right order should be fully filled or 3d: both should be fully filled if required values are the same
        return
            fillRight(
                leftOrder.makeAsset.value,
                leftOrder.takeAsset.value,
                rightMakeValue,
                rightTakeValue
            );
    }

    function fillRight(
        uint256 leftMakeValue,
        uint256 leftTakeValue,
        uint256 rightMakeValue,
        uint256 rightTakeValue
    ) internal pure returns (FillResult memory result) {
        uint256 makerValue = LibMath.safeGetPartialAmountFloor(
            rightTakeValue,
            leftMakeValue,
            leftTakeValue
        );
        require(makerValue <= rightMakeValue, "fillRight: unable to fill");
        return FillResult(rightTakeValue, makerValue);
    }

    function fillLeft(
        uint256 leftMakeValue,
        uint256 leftTakeValue,
        uint256 rightMakeValue,
        uint256 rightTakeValue
    ) internal pure returns (FillResult memory result) {
        uint256 rightTake = LibMath.safeGetPartialAmountFloor(
            leftTakeValue,
            rightMakeValue,
            rightTakeValue
        );
        require(rightTake <= leftMakeValue, "fillLeft: unable to fill");
        return FillResult(leftMakeValue, leftTakeValue);
    }
}

// File: exchange-v2/contracts/ExchangeV2Core.sol

abstract contract ExchangeV2Core is
    Initializable,
    OwnableUpgradeable,
    AssetMatcher,
    TransferExecutor,
    OrderValidator,
    ITransferManager
{
    using SafeMathUpgradeable for uint256;
    using LibTransfer for address;

    uint256 private constant UINT256_MAX = 2**256 - 1;

    //state of the orders
    mapping(bytes32 => uint256) public fills; // take-side fills

    //on-chain orders
    mapping(bytes32 => OrderAndFee) public onChainOrders;

    //struct to hold on-chain order and its protocol fee, fee is updated if order is updated
    struct OrderAndFee {
        LibOrder.Order order;
        uint256 fee;
    }

    //events
    event Cancel(
        bytes32 hash,
        address maker,
        LibAsset.AssetType makeAssetType,
        LibAsset.AssetType takeAssetType
    );
    event Match(
        bytes32 leftHash,
        bytes32 rightHash,
        address leftMaker,
        address rightMaker,
        uint256 newLeftFill,
        uint256 newRightFill,
        LibAsset.AssetType leftAsset,
        LibAsset.AssetType rightAsset
    );
    event UpsertOrder(LibOrder.Order order);

    /// @dev Creates new or updates an on-chain order
    function upsertOrder(LibOrder.Order memory order) external payable {
        bytes32 orderKeyHash = LibOrder.hashKey(order);

        //checking if order is correct
        require(_msgSender() == order.maker, "order.maker must be msg.sender");
        require(
            order.takeAsset.value > fills[orderKeyHash],
            "such take value is already filled"
        );

        uint256 newTotal = getTotalValue(order, orderKeyHash);

        //value of makeAsset that needs to be transfered with tx
        uint256 sentValue = newTotal;

        if (checkOrderExistance(orderKeyHash)) {
            uint256 oldTotal = getTotalValue(
                onChainOrders[orderKeyHash].order,
                orderKeyHash
            );

            sentValue = (newTotal > oldTotal) ? newTotal.sub(oldTotal) : 0;

            //value of makeAsset that needs to be returned to order.maker due to updating of the order
            uint256 returnValue = (oldTotal > newTotal)
                ? oldTotal.sub(newTotal)
                : 0;

            transferLockedAsset(
                LibAsset.Asset(order.makeAsset.assetType, returnValue),
                address(this),
                order.maker,
                UNLOCK,
                TO_MAKER
            );
        }

        if (order.makeAsset.assetType.assetClass == LibAsset.ETH_ASSET_CLASS) {
            require(
                order.takeAsset.assetType.assetClass !=
                    LibAsset.ETH_ASSET_CLASS,
                "wrong order: ETH to ETH trades are forbidden"
            );
            require(msg.value >= sentValue, "not enough eth");

            if (sentValue > 0) {
                emit Transfer(
                    LibAsset.Asset(order.makeAsset.assetType, sentValue),
                    order.maker,
                    address(this),
                    TO_LOCK,
                    LOCK
                );
            }

            //returning "change" ETH if msg.value > sentValue
            if (msg.value > sentValue) {
                address(order.maker).transferEth(msg.value.sub(sentValue));
            }
        } else {
            //locking only ETH for now, not locking tokens
        }

        onChainOrders[orderKeyHash].fee = getProtocolFee();
        onChainOrders[orderKeyHash].order = order;

        emit UpsertOrder(order);
    }

    function cancel(LibOrder.Order memory order) external {
        require(_msgSender() == order.maker, "not a maker");
        require(order.salt != 0, "0 salt can't be used");

        bytes32 orderKeyHash = LibOrder.hashKey(order);

        //if it's an on-chain order
        if (checkOrderExistance(orderKeyHash)) {
            LibOrder.Order memory temp = onChainOrders[orderKeyHash].order;

            //for now locking only ETH, so returning only locked ETH also
            if (
                temp.makeAsset.assetType.assetClass == LibAsset.ETH_ASSET_CLASS
            ) {
                transferLockedAsset(
                    LibAsset.Asset(
                        temp.makeAsset.assetType,
                        getTotalValue(temp, orderKeyHash)
                    ),
                    address(this),
                    temp.maker,
                    UNLOCK,
                    TO_MAKER
                );
            }
            delete onChainOrders[orderKeyHash];
        }

        fills[orderKeyHash] = UINT256_MAX;

        emit Cancel(
            orderKeyHash,
            order.maker,
            order.makeAsset.assetType,
            order.takeAsset.assetType
        );
    }

    function matchOrders(
        LibOrder.Order memory orderLeft,
        bytes memory signatureLeft,
        LibOrder.Order memory orderRight,
        bytes memory signatureRight
    ) external payable {
        validateFull(orderLeft, signatureLeft);
        validateFull(orderRight, signatureRight);
        if (orderLeft.taker != address(0)) {
            require(
                orderRight.maker == orderLeft.taker,
                "leftOrder.taker verification failed"
            );
        }
        if (orderRight.taker != address(0)) {
            require(
                orderRight.taker == orderLeft.maker,
                "rightOrder.taker verification failed"
            );
        }
        matchAndTransfer(orderLeft, orderRight);
    }

    function matchAndTransfer(
        LibOrder.Order memory orderLeft,
        LibOrder.Order memory orderRight
    ) internal {
        (
            LibAsset.AssetType memory makeMatch,
            LibAsset.AssetType memory takeMatch
        ) = matchAssets(orderLeft, orderRight);
        bytes32 leftOrderKeyHash = LibOrder.hashKey(orderLeft);
        bytes32 rightOrderKeyHash = LibOrder.hashKey(orderRight);
        uint256 leftOrderFill = getOrderFill(orderLeft, leftOrderKeyHash);
        uint256 rightOrderFill = getOrderFill(orderRight, rightOrderKeyHash);
        LibFill.FillResult memory newFill = LibFill.fillOrder(
            orderLeft,
            orderRight,
            leftOrderFill,
            rightOrderFill
        );
        require(newFill.takeValue > 0, "nothing to fill");

        if (orderLeft.salt != 0) {
            fills[leftOrderKeyHash] = leftOrderFill.add(newFill.takeValue);
        }
        if (orderRight.salt != 0) {
            fills[rightOrderKeyHash] = rightOrderFill.add(newFill.makeValue);
        }

        (uint256 totalMakeValue, uint256 totalTakeValue) = doTransfers(
            makeMatch,
            takeMatch,
            newFill,
            orderLeft,
            orderRight
        );

        emit Match(
            leftOrderKeyHash,
            rightOrderKeyHash,
            orderLeft.maker,
            orderRight.maker,
            newFill.takeValue,
            newFill.makeValue,
            makeMatch,
            takeMatch
        );

        bool ethRequired = matchingRequiresEth(
            orderLeft,
            orderRight,
            leftOrderKeyHash,
            rightOrderKeyHash
        );

        if (makeMatch.assetClass == LibAsset.ETH_ASSET_CLASS && ethRequired) {
            require(takeMatch.assetClass != LibAsset.ETH_ASSET_CLASS);
            require(msg.value >= totalMakeValue, "not enough eth");
            if (msg.value > totalMakeValue) {
                address(msg.sender).transferEth(msg.value.sub(totalMakeValue));
            }
        } else if (
            takeMatch.assetClass == LibAsset.ETH_ASSET_CLASS && ethRequired
        ) {
            require(msg.value >= totalTakeValue, "not enough eth");
            if (msg.value > totalTakeValue) {
                address(msg.sender).transferEth(msg.value.sub(totalTakeValue));
            }
        }

        deleteFilledOrder(orderLeft, leftOrderKeyHash);
        deleteFilledOrder(orderRight, rightOrderKeyHash);
    }

    function getOrderFill(LibOrder.Order memory order, bytes32 hash)
        internal
        view
        returns (uint256 fill)
    {
        if (order.salt == 0) {
            fill = 0;
        } else {
            fill = fills[hash];
        }
    }

    function matchAssets(
        LibOrder.Order memory orderLeft,
        LibOrder.Order memory orderRight
    )
        internal
        view
        returns (
            LibAsset.AssetType memory makeMatch,
            LibAsset.AssetType memory takeMatch
        )
    {
        makeMatch = matchAssets(
            orderLeft.makeAsset.assetType,
            orderRight.takeAsset.assetType
        );
        require(makeMatch.assetClass != 0, "assets don't match");
        takeMatch = matchAssets(
            orderLeft.takeAsset.assetType,
            orderRight.makeAsset.assetType
        );
        require(takeMatch.assetClass != 0, "assets don't match");
    }

    function validateFull(LibOrder.Order memory order, bytes memory signature)
        internal
        view
    {
        LibOrder.validate(order);

        //no need to validate signature of an on-chain order
        if (isTheSameAsOnChain(order, LibOrder.hashKey(order))) {
            return;
        }

        validate(order, signature);
    }

    /// @dev Checks order for existance on-chain by orderKeyHash
    function checkOrderExistance(bytes32 orderKeyHash)
        public
        view
        returns (bool)
    {
        if (onChainOrders[orderKeyHash].order.maker != address(0)) {
            return true;
        } else {
            return false;
        }
    }

    /// @dev Tranfers assets to lock or unlock them
    function transferLockedAsset(
        LibAsset.Asset memory asset,
        address from,
        address to,
        bytes4 transferType,
        bytes4 transferDirection
    ) internal {
        if (asset.value == 0) {
            return;
        }

        transfer(asset, from, to, transferDirection, transferType);
    }

    /// @dev Calculates total make amount of order, including fees and fill
    function getTotalValue(LibOrder.Order memory order, bytes32 hash)
        internal
        view
        returns (uint256)
    {
        (uint256 remainingMake, ) = LibOrder.calculateRemaining(
            order,
            getOrderFill(order, hash)
        );
        uint256 totalAmount = calculateTotalAmount(
            remainingMake,
            getOrderProtocolFee(order, hash),
            LibOrderData.parse(order).originFees
        );
        return totalAmount;
    }

    /// @dev Checks if order is fully filled, if true then deletes it
    function deleteFilledOrder(LibOrder.Order memory order, bytes32 hash)
        internal
    {
        if (!isTheSameAsOnChain(order, hash)) {
            return;
        }

        uint256 takeValueLeft = order.takeAsset.value.sub(
            getOrderFill(order, hash)
        );
        if (takeValueLeft == 0) {
            delete onChainOrders[hash];
        }
    }

    /// @dev Checks if matching such orders requires ether sent with the transaction
    function matchingRequiresEth(
        LibOrder.Order memory orderLeft,
        LibOrder.Order memory orderRight,
        bytes32 leftOrderKeyHash,
        bytes32 rightOrderKeyHash
    ) internal view returns (bool) {
        //ether is required when one of the orders is simultaneously offchain and has makeAsset = ETH
        if (
            orderLeft.makeAsset.assetType.assetClass == LibAsset.ETH_ASSET_CLASS
        ) {
            if (!isTheSameAsOnChain(orderLeft, leftOrderKeyHash)) {
                return true;
            }
        }

        if (
            orderRight.makeAsset.assetType.assetClass ==
            LibAsset.ETH_ASSET_CLASS
        ) {
            if (!isTheSameAsOnChain(orderRight, rightOrderKeyHash)) {
                return true;
            }
        }

        return false;
    }

    /// @dev Checks if order is the same as his on-chain version
    function isTheSameAsOnChain(LibOrder.Order memory order, bytes32 hash)
        internal
        view
        returns (bool)
    {
        if (LibOrder.hash(order) == LibOrder.hash(onChainOrders[hash].order)) {
            return true;
        }
        return false;
    }

    uint256[48] private __gap;
}

// File: exchange-v2/contracts/ExchangeV2.sol

contract ExchangeV2 is ExchangeV2Core, RaribleTransferManager {
    function __ExchangeV2_init(
        INftTransferProxy _transferProxy,
        IERC20TransferProxy _erc20TransferProxy,
        uint256 newProtocolFee,
        address newDefaultFeeReceiver,
        IRoyaltiesProvider newRoyaltiesProvider
    ) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __TransferExecutor_init_unchained(_transferProxy, _erc20TransferProxy);
        __RaribleTransferManager_init_unchained(
            newProtocolFee,
            newDefaultFeeReceiver,
            newRoyaltiesProvider
        );
        __OrderValidator_init_unchained();
    }

    function getOrderProtocolFee(LibOrder.Order memory order, bytes32 hash)
        internal
        view
        override
        returns (uint256)
    {
        if (isTheSameAsOnChain(order, hash)) {
            return onChainOrders[hash].fee;
        } else {
            return protocolFee;
        }
    }

    function getProtocolFee() internal view override returns (uint256) {
        return protocolFee;
    }
}