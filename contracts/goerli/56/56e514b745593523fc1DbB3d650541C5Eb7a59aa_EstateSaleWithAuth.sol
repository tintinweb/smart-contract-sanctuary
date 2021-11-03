/* solhint-disable not-rely-on-time, func-order */

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./AuthValidator.sol";
import "../common/Libraries/SafeMathWithRequire.sol";
import "../common/interfaces/ILandToken.sol";
import "../common/interfaces/IERC1155.sol";
import "../common/BaseWithStorage/WithReferralValidator.sol";
import "@openzeppelin/contracts-0.8/metatx/ERC2771Context.sol";

/// @title Estate Sale contract with referral
/// @notice This contract manages the sale of our lands as Estates
contract EstateSaleWithAuth is ERC2771Context, WithReferralValidator {
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

    uint256 internal constant GRID_SIZE = 408; // 408 is the size of the Land

    IERC1155 internal immutable _asset;
    LandToken internal immutable _land;
    IERC20 internal immutable _sand;
    address internal immutable _estate;
    address internal immutable _feeDistributor;

    address payable internal _wallet;
    AuthValidator internal _authValidator;
    uint256 internal immutable _expiryTime;
    bytes32 internal immutable _merkleRoot;

    uint256 private constant FEE = 5; // percentage of land sale price to be diverted to a specially configured instance of FeeDistributor, shown as an integer

    uint256 private constant X_INDEX = 0;
    uint256 private constant Y_INDEX = 1;
    uint256 private constant SIZE_INDEX = 2;
    uint256 private constant PRICE_INDEX = 3;

    // need to use struct to avoid "Stack Too Deep" error. Since there are too many parameters.
    struct Parameters {
        IERC1155 asset;
        LandToken landAddress;
        IERC20 sandContractAddress;
        address admin;
        address estate;
        address feeDistributor;
        address payable initialWalletAddress;
        AuthValidator authValidator;
        uint256 expiryTime;
        bytes32 merkleRoot;
        address trustedForwarder;
        address initialSigningWallet;
        uint256 initialMaxCommissionRate;
    }

    constructor(Parameters memory p)
        ERC2771Context(p.trustedForwarder)
        WithReferralValidator(p.initialSigningWallet, p.initialMaxCommissionRate, p.admin)
    {
        _asset = p.asset;
        _land = p.landAddress;
        _sand = p.sandContractAddress;
        _admin = p.admin;
        _estate = p.estate;
        _feeDistributor = p.feeDistributor;
        _wallet = p.initialWalletAddress;
        _authValidator = p.authValidator;
        _expiryTime = p.expiryTime;
        _merkleRoot = p.merkleRoot;
    }

    /// @notice set the wallet receiving the proceeds
    /// @param newWallet address of the new receiving wallet
    function setReceivingWallet(address payable newWallet) external {
        require(newWallet != address(0), "ZERO_ADDRESS");
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        _wallet = newWallet;
    }

    /// Note: Using struct to avoid the "Stack too deep" issue.
    /// @param buyer address that perform the payment
    /// @param to address that will own the purchased Land
    /// @param reserved the reserved address (if any)
    struct Addresses {
        address buyer;
        address to;
        address reserved;
    }
    /// @param addrs struct of addresses.
    /// @param info [X_INDEX=0] x coordinate of the Land [Y_INDEX=1] y coordinate of the Land [SIZE_INDEX=2] size of the pack of Land to purchase [PRICE_INDEX=3] price in SAND to purchase that Land
    /// @param proof merkleProof for that particular Land
    struct Arguments {
        uint256[] info;
        bytes32 salt;
        uint256[] assetIds;
        bytes32[] proof;
        bytes referral;
        bytes signature;
    }

    /// @notice buy Land with SAND using the merkle proof associated with it
    /// Note: Using structs to avoid "Stack too deep" error
    function buyLandWithSand(Addresses calldata addrs, Arguments calldata args) external {
        _checkAddressesAndExpiryTime(addrs.buyer, addrs.reserved);
        _checkAuthAndProofValidity(
            addrs.to,
            addrs.reserved,
            args.info,
            args.salt,
            args.assetIds,
            args.proof,
            args.signature
        );
        _handleFeeAndReferral(addrs.buyer, args.info[PRICE_INDEX], args.referral);
        _mint(addrs.buyer, addrs.to, args.info);
        _sendAssets(addrs.to, args.assetIds);
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

    // NOTE: _checkAddressesAndExpiryTime & _checkAuthAndProofValidity were split due to a stack too deep issue
    function _checkAddressesAndExpiryTime(address buyer, address reserved) internal view {
        /* solium-disable-next-line security/no-block-members */
        require(block.timestamp < _expiryTime, "SALE_IS_OVER");
        require(buyer == msg.sender || isTrustedForwarder(msg.sender), "NOT_AUTHORIZED");
        require(reserved == address(0) || reserved == buyer, "RESERVED_LAND");
    }

    // NOTE: _checkAddressesAndExpiryTime & _checkAuthAndProofValidity were split due to a stack too deep issue
    function _checkAuthAndProofValidity(
        address to,
        address reserved,
        uint256[] memory info,
        bytes32 salt,
        uint256[] memory assetIds,
        bytes32[] memory proof,
        bytes memory signature
    ) internal view {
        bytes32 hashedData =
            keccak256(
                abi.encodePacked(
                    to,
                    reserved,
                    info[X_INDEX],
                    info[Y_INDEX],
                    info[SIZE_INDEX],
                    info[PRICE_INDEX],
                    salt,
                    keccak256(abi.encodePacked(assetIds)),
                    keccak256(abi.encodePacked(proof))
                )
            );
        require(_authValidator.isAuthValid(signature, hashedData), "INVALID_AUTH");

        bytes32 leaf =
            _generateLandHash(
                info[X_INDEX],
                info[Y_INDEX],
                info[SIZE_INDEX],
                info[PRICE_INDEX],
                reserved,
                salt,
                assetIds
            );
        require(_verify(proof, leaf), "INVALID_LAND");
    }

    function _mint(
        address buyer,
        address to,
        uint256[] memory info
    ) internal {
        if (info[SIZE_INDEX] == 1 || _estate == address(0)) {
            _land.mintQuad(to, info[SIZE_INDEX], info[X_INDEX], info[Y_INDEX], "");
        } else {
            _land.mintQuad(_estate, info[SIZE_INDEX], info[X_INDEX], info[Y_INDEX], abi.encode(to));
        }

        emit LandQuadPurchased(
            buyer,
            to,
            info[X_INDEX] + (info[Y_INDEX] * GRID_SIZE),
            info[SIZE_INDEX],
            info[PRICE_INDEX],
            address(_sand),
            info[PRICE_INDEX]
        );
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
        uint256 feeAmountInSand = (priceInSand * FEE) / 100;
        require(_sand.transferFrom(buyer, address(_feeDistributor), feeAmountInSand), "FEE_TRANSFER_FAILED");
        return priceInSand - feeAmountInSand;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../common/Libraries/SafeMathWithRequire.sol";
import "../common/BaseWithStorage/WithAdmin.sol";
import "@openzeppelin/contracts-0.8/utils/cryptography/ECDSA.sol";

contract AuthValidator is WithAdmin {
    address public _signingAuthWallet;

    event SigningWallet(address indexed signingWallet);

    constructor(address adminWallet, address initialSigningWallet) {
        _admin = adminWallet;
        _updateSigningAuthWallet(initialSigningWallet);
    }

    function updateSigningAuthWallet(address newSigningWallet) external onlyAdmin {
        _updateSigningAuthWallet(newSigningWallet);
    }

    function _updateSigningAuthWallet(address newSigningWallet) internal {
        require(newSigningWallet != address(0), "INVALID_SIGNING_WALLET");
        _signingAuthWallet = newSigningWallet;
        emit SigningWallet(newSigningWallet);
    }

    function isAuthValid(bytes memory signature, bytes32 hashedData) public view returns (bool) {
        address signer =
            ECDSA.recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedData)), signature);
        return signer == _signingAuthWallet;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/utils/math/SafeMath.sol";

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert
 */
library SafeMathWithRequire {
    using SafeMath for uint256;

    uint256 private constant DECIMALS_18 = 1000000000000000000;
    uint256 private constant DECIMALS_12 = 1000000000000;
    uint256 private constant DECIMALS_9 = 1000000000;
    uint256 private constant DECIMALS_6 = 1000000;

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
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface LandToken {
    function batchTransferQuad(
        address from,
        address to,
        uint256[] calldata sizes,
        uint256[] calldata xs,
        uint256[] calldata ys,
        bytes calldata data
    ) external;

    function transferQuad(
        address from,
        address to,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes calldata data
    ) external;

    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external;

    function mintQuad(
        address to,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes calldata data
    ) external;
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://eips.ethereum.org/EIPS/eip-1155
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
interface IERC1155 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

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

/* solhint-disable not-rely-on-time, func-order */

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./WithAdmin.sol";
import "../Libraries/SafeMathWithRequire.sol";
import "@openzeppelin/contracts-0.8/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/ERC20.sol";

/**
 * @title Referral Validator
 * @notice This contract verifies if a referral is valid
 */
contract WithReferralValidator is WithAdmin {
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

    constructor(
        address initialSigningWallet,
        uint256 initialMaxCommissionRate,
        address admin
    ) {
        _signingWallet = initialSigningWallet;
        _maxCommissionRate = initialMaxCommissionRate;
        _admin = admin;
    }

    /**
     * @notice Update the signing wallet
     * @param newSigningWallet The new address of the signing wallet
     */
    function updateSigningWallet(address newSigningWallet) external {
        require(_admin == msg.sender, "Sender not admin");
        _previousSigningWallets[_signingWallet] = block.timestamp + _previousSigningDelay;
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
     * @dev Update the maximum commission rate
     * @param newMaxCommissionRate The new maximum commission rate
     */
    function updateMaxCommissionRate(uint256 newMaxCommissionRate) external {
        require(_admin == msg.sender, "Sender not admin");
        _maxCommissionRate = newMaxCommissionRate;
    }

    /**
     * @notice the max commision rate
     * @return the maximum commision rate that a referral can give
     */
    function getMaxCommisionRate() external view returns (uint256) {
        return _maxCommissionRate;
    }

    function handleReferralWithETH(
        uint256 amount,
        bytes memory referral,
        address payable destination
    ) internal {
        uint256 amountForDestination = amount;

        if (referral.length > 0) {
            (bytes memory signature, address referrer, address referee, uint256 expiryTime, uint256 commissionRate) =
                decodeReferral(referral);

            uint256 commission = 0;

            if (isReferralValid(signature, referrer, referee, expiryTime, commissionRate)) {
                commission = SafeMath.div(SafeMath.mul(amount, commissionRate), 10000);

                emit ReferralUsed(referrer, referee, address(0), amount, commission, commissionRate);
                amountForDestination = SafeMath.sub(amountForDestination, commission);
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
            (bytes memory signature, address referrer, address referee, uint256 expiryTime, uint256 commissionRate) =
                decodeReferral(referral);

            uint256 commission = 0;

            if (isReferralValid(signature, referrer, referee, expiryTime, commissionRate)) {
                commission = SafeMath.div(SafeMath.mul(amount, commissionRate), 10000);

                emit ReferralUsed(referrer, referee, tokenAddress, amount, commission, commissionRate);
                amountForDestination = SafeMath.sub(amountForDestination, commission);
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
        if (commissionRate > _maxCommissionRate || referrer == referee || block.timestamp > expiryTime) {
            return false;
        }

        bytes32 hashedData = keccak256(abi.encodePacked(referrer, referee, expiryTime, commissionRate));

        address signer =
            ECDSA.recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedData)), signature);

        if (_previousSigningWallets[signer] >= block.timestamp) {
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
        (bytes memory signature, address referrer, address referee, uint256 expiryTime, uint256 commissionRate) =
            abi.decode(referral, (bytes, address, address, uint256, uint256));

        return (signature, referrer, referee, expiryTime, commissionRate);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/*
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    address immutable _trustedForwarder;

    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns(bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly { sender := shr(96, calldataload(sub(calldatasize(), 20))) }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length-20];
        } else {
            return super._msgData();
        }
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

contract WithAdmin {
    address internal _admin;

    /// @dev Emits when the contract administrator is changed.
    /// @param oldAdmin The address of the previous administrator.
    /// @param newAdmin The address of the new administrator.
    event AdminChanged(address oldAdmin, address newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == _admin, "ADMIN_ONLY");
        _;
    }

    /// @dev Get the current administrator of this contract.
    /// @return The current administrator of this contract.
    function getAdmin() external view returns (address) {
        return _admin;
    }

    /// @dev Change the administrator to be `newAdmin`.
    /// @param newAdmin The address of the new administrator.
    function changeAdmin(address newAdmin) external {
        require(msg.sender == _admin, "ADMIN_ACCESS_DENIED");
        emit AdminChanged(_admin, newAdmin);
        _admin = newAdmin;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
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
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}