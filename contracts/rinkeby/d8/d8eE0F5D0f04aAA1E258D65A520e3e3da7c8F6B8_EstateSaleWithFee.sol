/* solhint-disable not-rely-on-time, func-order */
pragma solidity 0.6.5;

import "../common/Libraries/SafeMathWithRequire.sol";
import "./LandToken.sol";
import "../common/Interfaces/ERC1155.sol";
import "../common/Interfaces/ERC20.sol";
import "../common/BaseWithStorage/MetaTransactionReceiver.sol";
import "../ReferralValidator/ReferralValidator.sol";


/// @title Estate Sale contract with referral
/// @notice This contract manages the sale of our lands as Estates
contract EstateSaleWithFee is MetaTransactionReceiver, ReferralValidator {
    using SafeMathWithRequire for uint256;

    event LandQuadPurchased(
        address indexed buyer,
        address indexed to,
        uint256 indexed topCornerId,
        uint256 size,
        uint256 price,
        address token,
        uint256 amountPaid
    );

    /// @notice set the wallet receiving the proceeds
    /// @param newWallet address of the new receiving wallet
    function setReceivingWallet(address payable newWallet) external {
        require(newWallet != address(0), "ZERO_ADDRESS");
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        _wallet = newWallet;
    }

    function rebalanceSand(uint256 newMultiplier) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        _multiplier = newMultiplier;
    }

    function getSandMultiplier() external view returns (uint256) {
        return _multiplier;
    }

    /// @notice buy Land with SAND using the merkle proof associated with it
    /// @param buyer address that perform the payment
    /// @param to address that will own the purchased Land
    /// @param reserved the reserved address (if any)
    /// @param x x coordinate of the Land
    /// @param y y coordinate of the Land
    /// @param size size of the pack of Land to purchase
    /// @param priceInSand price in SAND to purchase that Land
    /// @param proof merkleProof for that particular Land
    function buyLandWithSand(
        address buyer,
        address to,
        address reserved,
        uint256 x,
        uint256 y,
        uint256 size,
        uint256 priceInSand,
        uint256 adjustedPriceInSand,
        bytes32 salt,
        uint256[] calldata assetIds,
        bytes32[] calldata proof,
        bytes calldata referral
    ) external {
        _checkPrices(priceInSand, adjustedPriceInSand);
        _checkValidity(buyer, reserved, x, y, size, priceInSand, salt, assetIds, proof);
        _handleFeeAndReferral(buyer, adjustedPriceInSand, referral);
        _mint(buyer, to, x, y, size, adjustedPriceInSand, address(_sand), adjustedPriceInSand);
        _sendAssets(to, assetIds);
    }

    /// @notice Gets the expiry time for the current sale
    /// @return The expiry time, as a unix epoch
    function getExpiryTime() external view returns (uint256) {
        return _expiryTime;
    }

    /// @notice Gets the Merkle root associated with the current sale
    /// @return The Merkle root, as a bytes32 hash
    function getMerkleRoot() external view returns (bytes32) {
        return _merkleRoot;
    }

    /// @notice enable Admin to withdraw remaining assets from EstateSaleWithFee contract
    /// @param to intended recipient of the asset tokens
    /// @param assetIds the assetIds to be transferred
    /// @param values the quantities of the assetIds to be transferred
    function withdrawAssets(
        address to,
        uint256[] calldata assetIds,
        uint256[] calldata values
    ) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        // require(block.timestamp > _expiryTime, "SALE_NOT_OVER"); // removed to recover in case of misconfigured sales
        _asset.safeBatchTransferFrom(address(this), to, assetIds, values, "");
    }

    function onERC1155Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*id*/
        uint256, /*value*/
        bytes calldata /*data*/
    ) external pure returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address, /*operator*/
        address, /*from*/
        uint256[] calldata, /*ids*/
        uint256[] calldata, /*values*/
        bytes calldata /*data*/
    ) external pure returns (bytes4) {
        return 0xbc197c81;
    }

    function _sendAssets(address to, uint256[] memory assetIds) internal {
        uint256[] memory values = new uint256[](assetIds.length);
        for (uint256 i = 0; i < assetIds.length; i++) {
            values[i] = 1;
        }
        _asset.safeBatchTransferFrom(address(this), to, assetIds, values, "");
    }

    function _checkPrices(uint256 priceInSand, uint256 adjustedPriceInSand) internal view {
        require(adjustedPriceInSand == priceInSand.mul(_multiplier).div(MULTIPLIER_DECIMALS), "INVALID_PRICE");
    }

    function _checkValidity(
        address buyer,
        address reserved,
        uint256 x,
        uint256 y,
        uint256 size,
        uint256 price,
        bytes32 salt,
        uint256[] memory assetIds,
        bytes32[] memory proof
    ) internal view {
        /* solium-disable-next-line security/no-block-members */
        require(block.timestamp < _expiryTime, "SALE_IS_OVER");
        require(buyer == msg.sender || _metaTransactionContracts[msg.sender], "NOT_AUTHORIZED");
        require(reserved == address(0) || reserved == buyer, "RESERVED_LAND");
        bytes32 leaf = _generateLandHash(x, y, size, price, reserved, salt, assetIds);

        require(_verify(proof, leaf), "INVALID_LAND");
    }

    function _mint(
        address buyer,
        address to,
        uint256 x,
        uint256 y,
        uint256 size,
        uint256 price,
        address token,
        uint256 tokenAmount
    ) internal {
        if (size == 1 || _estate == address(0)) {
            _land.mintQuad(to, size, x, y, "");
        } else {
            _land.mintQuad(_estate, size, x, y, abi.encode(to));
        }
        emit LandQuadPurchased(buyer, to, x + (y * GRID_SIZE), size, price, token, tokenAmount);
    }

    function _generateLandHash(
        uint256 x,
        uint256 y,
        uint256 size,
        uint256 price,
        address reserved,
        bytes32 salt,
        uint256[] memory assetIds
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(x, y, size, price, reserved, salt, assetIds));
    }

    function _verify(bytes32[] memory proof, bytes32 leaf) internal view returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash < proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        return computedHash == _merkleRoot;
    }

    function _handleFeeAndReferral(
        address buyer,
        uint256 priceInSand,
        bytes memory referral
    ) internal {
        // send 5% fee to a specially configured instance of FeeDistributor.sol
        uint256 remainingAmountInSand = _handleSandFee(buyer, priceInSand);

        // calculate referral based on 95% of original priceInSand
        handleReferralWithERC20(buyer, remainingAmountInSand, referral, _wallet, address(_sand));
    }

    function _handleSandFee(address buyer, uint256 priceInSand) internal returns (uint256) {
        uint256 feeAmountInSand = priceInSand.mul(FEE).div(100);
        require(_sand.transferFrom(buyer, address(_feeDistributor), feeAmountInSand), "FEE_TRANSFER_FAILED");
        return priceInSand.sub(feeAmountInSand);
    }

    uint256 internal constant GRID_SIZE = 408; // 408 is the size of the Land

    ERC1155 internal immutable _asset;
    LandToken internal immutable _land;
    ERC20 internal immutable _sand;
    address internal immutable _estate;
    address internal immutable _feeDistributor;

    address payable internal _wallet;
    uint256 internal immutable _expiryTime;
    bytes32 internal immutable _merkleRoot;

    uint256 private constant FEE = 5; // percentage of land sale price to be diverted to a specially configured instance of FeeDistributor, shown as an integer

    uint256 private _multiplier = 1000; // multiplier used for rebalancing SAND values, 3 decimal places
    uint256 private constant MULTIPLIER_DECIMALS = 1000;

    constructor(
        address landAddress,
        address sandContractAddress,
        address initialMetaTx,
        address admin,
        address payable initialWalletAddress,
        bytes32 merkleRoot,
        uint256 expiryTime,
        address initialSigningWallet,
        uint256 initialMaxCommissionRate,
        address estate,
        address asset,
        address feeDistributor
    ) public ReferralValidator(initialSigningWallet, initialMaxCommissionRate) {
        _land = LandToken(landAddress);
        _sand = ERC20(sandContractAddress);
        _setMetaTransactionProcessor(initialMetaTx, true);
        _wallet = initialWalletAddress;
        _merkleRoot = merkleRoot;
        _expiryTime = expiryTime;
        _admin = admin;
        _estate = estate;
        _asset = ERC1155(asset);
        _feeDistributor = feeDistributor;
    }
}

pragma solidity 0.6.5;


interface LandToken {
    function mintQuad(
        address to,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes calldata data
    ) external;
}

/* solhint-disable not-rely-on-time, func-order */
pragma solidity 0.6.5;

import "../common/Libraries/SigUtil.sol";
import "../common/Libraries/SafeMathWithRequire.sol";
import "../common/Interfaces/ERC20.sol";
import "../common/BaseWithStorage/Admin.sol";


/// @dev This contract verifies if a referral is valid
contract ReferralValidator is Admin {
    address private _signingWallet;
    uint256 private _maxCommissionRate;

    mapping(address => uint256) private _previousSigningWallets;
    uint256 private _previousSigningDelay = 60 * 60 * 24 * 10;

    event ReferralUsed(
        address indexed referrer,
        address indexed referee,
        address indexed token,
        uint256 amount,
        uint256 commission,
        uint256 commissionRate
    );

    constructor(address initialSigningWallet, uint256 initialMaxCommissionRate) public {
        _signingWallet = initialSigningWallet;
        _maxCommissionRate = initialMaxCommissionRate;
    }

    /**
     * @dev Update the signing wallet
     * @param newSigningWallet The new address of the signing wallet
     */
    function updateSigningWallet(address newSigningWallet) external {
        require(_admin == msg.sender, "Sender not admin");
        _previousSigningWallets[_signingWallet] = now + _previousSigningDelay;
        _signingWallet = newSigningWallet;
    }

    /**
     * @dev signing wallet authorized for referral
     * @return the address of the signing wallet
     */
    function getSigningWallet() external view returns (address) {
        return _signingWallet;
    }

    /**
     * @notice the max commision rate
     * @return the maximum commision rate that a referral can give
     */
    function getMaxCommisionRate() external view returns (uint256) {
        return _maxCommissionRate;
    }

    /**
     * @dev Update the maximum commission rate
     * @param newMaxCommissionRate The new maximum commission rate
     */
    function updateMaxCommissionRate(uint256 newMaxCommissionRate) external {
        require(_admin == msg.sender, "Sender not admin");
        _maxCommissionRate = newMaxCommissionRate;
    }

    function handleReferralWithETH(
        uint256 amount,
        bytes memory referral,
        address payable destination
    ) internal {
        uint256 amountForDestination = amount;

        if (referral.length > 0) {
            (bytes memory signature, address referrer, address referee, uint256 expiryTime, uint256 commissionRate) = decodeReferral(referral);

            uint256 commission = 0;

            if (isReferralValid(signature, referrer, referee, expiryTime, commissionRate)) {
                commission = SafeMathWithRequire.div(SafeMathWithRequire.mul(amount, commissionRate), 10000);

                emit ReferralUsed(referrer, referee, address(0), amount, commission, commissionRate);
                amountForDestination = SafeMathWithRequire.sub(amountForDestination, commission);
            }

            if (commission > 0) {
                payable(referrer).transfer(commission);
            }
        }

        destination.transfer(amountForDestination);
    }

    function handleReferralWithERC20(
        address buyer,
        uint256 amount,
        bytes memory referral,
        address payable destination,
        address tokenAddress
    ) internal {
        ERC20 token = ERC20(tokenAddress);
        uint256 amountForDestination = amount;

        if (referral.length > 0) {
            (bytes memory signature, address referrer, address referee, uint256 expiryTime, uint256 commissionRate) = decodeReferral(referral);

            uint256 commission = 0;

            if (isReferralValid(signature, referrer, referee, expiryTime, commissionRate)) {
                commission = SafeMathWithRequire.div(SafeMathWithRequire.mul(amount, commissionRate), 10000);

                emit ReferralUsed(referrer, referee, tokenAddress, amount, commission, commissionRate);
                amountForDestination = SafeMathWithRequire.sub(amountForDestination, commission);
            }

            if (commission > 0) {
                require(token.transferFrom(buyer, referrer, commission), "commision transfer failed");
            }
        }

        require(token.transferFrom(buyer, destination, amountForDestination), "payment transfer failed");
    }

    /**
     * @notice Check if a referral is valid
     * @param signature The signature to check (signed referral)
     * @param referrer The address of the referrer
     * @param referee The address of the referee
     * @param expiryTime The expiry time of the referral
     * @param commissionRate The commissionRate of the referral
     * @return True if the referral is valid
     */
    function isReferralValid(
        bytes memory signature,
        address referrer,
        address referee,
        uint256 expiryTime,
        uint256 commissionRate
    ) public view returns (bool) {
        if (commissionRate > _maxCommissionRate || referrer == referee || now > expiryTime) {
            return false;
        }

        bytes32 hashedData = keccak256(abi.encodePacked(referrer, referee, expiryTime, commissionRate));

        address signer = SigUtil.recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedData)), signature);

        if (_previousSigningWallets[signer] >= now) {
            return true;
        }

        return _signingWallet == signer;
    }

    function decodeReferral(bytes memory referral)
        public
        pure
        returns (
            bytes memory,
            address,
            address,
            uint256,
            uint256
        )
    {
        (bytes memory signature, address referrer, address referee, uint256 expiryTime, uint256 commissionRate) = abi.decode(
            referral,
            (bytes, address, address, uint256, uint256)
        );

        return (signature, referrer, referee, expiryTime, commissionRate);
    }
}

pragma solidity 0.6.5;


contract Admin {
    address internal _admin;

    /// @dev emitted when the contract administrator is changed.
    /// @param oldAdmin address of the previous administrator.
    /// @param newAdmin address of the new administrator.
    event AdminChanged(address oldAdmin, address newAdmin);

    /// @dev gives the current administrator of this contract.
    /// @return the current administrator of this contract.
    function getAdmin() external view returns (address) {
        return _admin;
    }

    /// @dev change the administrator to be `newAdmin`.
    /// @param newAdmin address of the new administrator.
    function changeAdmin(address newAdmin) external {
        require(msg.sender == _admin, "only admin can change admin");
        emit AdminChanged(_admin, newAdmin);
        _admin = newAdmin;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "only admin allowed");
        _;
    }
}

pragma solidity 0.6.5;

import "./Admin.sol";


contract MetaTransactionReceiver is Admin {
    mapping(address => bool) internal _metaTransactionContracts;

    /// @dev emiited when a meta transaction processor is enabled/disabled
    /// @param metaTransactionProcessor address that will be given/removed metaTransactionProcessor rights.
    /// @param enabled set whether the metaTransactionProcessor is enabled or disabled.
    event MetaTransactionProcessor(address metaTransactionProcessor, bool enabled);

    /// @dev Enable or disable the ability of `metaTransactionProcessor` to perform meta-tx (metaTransactionProcessor rights).
    /// @param metaTransactionProcessor address that will be given/removed metaTransactionProcessor rights.
    /// @param enabled set whether the metaTransactionProcessor is enabled or disabled.
    function setMetaTransactionProcessor(address metaTransactionProcessor, bool enabled) public {
        require(msg.sender == _admin, "only admin can setup metaTransactionProcessors");
        _setMetaTransactionProcessor(metaTransactionProcessor, enabled);
    }

    function _setMetaTransactionProcessor(address metaTransactionProcessor, bool enabled) internal {
        _metaTransactionContracts[metaTransactionProcessor] = enabled;
        emit MetaTransactionProcessor(metaTransactionProcessor, enabled);
    }

    /// @dev check whether address `who` is given meta-transaction execution rights.
    /// @param who The address to query.
    /// @return whether the address has meta-transaction execution rights.
    function isMetaTransactionProcessor(address who) external view returns (bool) {
        return _metaTransactionContracts[who];
    }
}

pragma solidity 0.6.5;


/**
    @title ERC-1155 Multi Token Standard
    @dev See https://eips.ethereum.org/EIPS/eip-1155
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
interface ERC1155 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /**
        @notice Transfers `value` amount of an `id` from  `from` to `to`  (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
        MUST revert if `to` is the zero address.
        MUST revert if balance of holder for token `id` is lower than the `value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param from    Source address
        @param to      Target address
        @param id      ID of the token type
        @param value   Transfer amount
        @param data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `to`
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    /**
        @notice Transfers `values` amount(s) of `ids` from the `from` address to the `to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
        MUST revert if `to` is the zero address.
        MUST revert if length of `ids` is not the same as length of `values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids` is lower than the respective amount(s) in `values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param from    Source address
        @param to      Target address
        @param ids     IDs of each token type (order and length must match _values array)
        @param values  Transfer amounts per token type (order and length must match _ids array)
        @param data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `to`
    */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    /**
        @notice Get the balance of an account's tokens.
        @param owner  The address of the token holder
        @param id     ID of the token
        @return        The _owner's balance of the token type requested
     */
    function balanceOf(address owner, uint256 id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param owners The addresses of the token holders
        @param ids    ID of the tokens
        @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param operator  Address to add to the set of authorized operators
        @param approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address operator, bool approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param owner     The owner of the tokens
        @param operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

pragma solidity 0.6.5;


/// @dev see https://eips.ethereum.org/EIPS/eip-20
interface ERC20 {
    /// @notice emitted when tokens are transfered from one address to another.
    /// @param from address from which the token are transfered from (zero means tokens are minted).
    /// @param to destination address which the token are transfered to (zero means tokens are burnt).
    /// @param value amount of tokens transferred.
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice emitted when owner grant transfer rights to another address
    /// @param owner address allowing its token to be transferred.
    /// @param spender address allowed to spend on behalf of `owner`
    /// @param value amount of tokens allowed.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice return the current total amount of tokens owned by all holders.
    /// @return supply total number of tokens held.
    function totalSupply() external view returns (uint256 supply);

    /// @notice return the number of tokens held by a particular address.
    /// @param who address being queried.
    /// @return balance number of token held by that address.
    function balanceOf(address who) external view returns (uint256 balance);

    /// @notice transfer tokens to a specific address.
    /// @param to destination address receiving the tokens.
    /// @param value number of tokens to transfer.
    /// @return success whether the transfer succeeded.
    function transfer(address to, uint256 value) external returns (bool success);

    /// @notice transfer tokens from one address to another.
    /// @param from address tokens will be sent from.
    /// @param to destination address receiving the tokens.
    /// @param value number of tokens to transfer.
    /// @return success whether the transfer succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);

    /// @notice approve an address to spend on your behalf.
    /// @param spender address entitled to transfer on your behalf.
    /// @param value amount allowed to be transfered.
    /// @param success whether the approval succeeded.
    function approve(address spender, uint256 value) external returns (bool success);

    /// @notice return the current allowance for a particular owner/spender pair.
    /// @param owner address allowing spender.
    /// @param spender address allowed to spend.
    /// @return amount number of tokens `spender` can spend on behalf of `owner`.
    function allowance(address owner, address spender) external view returns (uint256 amount);
}

pragma solidity 0.6.5;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert
 */
library SafeMathWithRequire {
    using SafeMathWithRequire for uint256;

    uint256 constant DECIMALS_18 = 1000000000000000000;
    uint256 constant DECIMALS_12 = 1000000000000;
    uint256 constant DECIMALS_9 = 1000000000;
    uint256 constant DECIMALS_6 = 1000000;

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        require(c / a == b, "overflow");
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "divbyzero");
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "undeflow");
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "overflow");
        return c;
    }

    function sqrt6(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_12);
        uint256 tmp = a.add(1) / 2;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            tmp = ((a / tmp) + tmp) / 2;
        }
    }

    function sqrt3(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_6);
        uint256 tmp = a.add(1) / 2;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            tmp = ((a / tmp) + tmp) / 2;
        }
    }

    function cbrt6(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_18);
        uint256 tmp = a.add(2) / 3;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            uint256 tmpSquare = tmp**2;
            require(tmpSquare > tmp, "overflow");
            tmp = ((a / tmpSquare) + (tmp * 2)) / 3;
        }
        return c;
    }

    function cbrt3(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_9);
        uint256 tmp = a.add(2) / 3;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            uint256 tmpSquare = tmp**2;
            require(tmpSquare > tmp, "overflow");
            tmp = ((a / tmpSquare) + (tmp * 2)) / 3;
        }
        return c;
    }

    // TODO test
    function rt6_3(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_18);
        uint256 tmp = a.add(5) / 6;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            uint256 tmpFive = tmp**5;
            require(tmpFive > tmp, "overflow");
            tmp = ((a / tmpFive) + (tmp * 5)) / 6;
        }
    }
}

pragma solidity 0.6.5;


library SigUtil {
    function recover(bytes32 hash, bytes memory sig) internal pure returns (address recovered) {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28);

        recovered = ecrecover(hash, v, r, s);
        require(recovered != address(0));
    }

    function recoverWithZeroOnFailure(bytes32 hash, bytes memory sig) internal pure returns (address) {
        if (sig.length != 65) {
            return (address(0));
        }

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes memory) {
        return abi.encodePacked("\x19Ethereum Signed Message:\n32", hash);
    }
}