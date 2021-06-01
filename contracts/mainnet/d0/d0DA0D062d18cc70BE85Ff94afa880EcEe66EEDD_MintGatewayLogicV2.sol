pragma solidity ^0.5.17;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/upgrades/contracts/upgradeability/InitializableAdminUpgradeabilityProxy.sol";

import "../Governance/Claimable.sol";
import "../libraries/String.sol";
import "./RenERC20.sol";
import "./interfaces/IGateway.sol";
import "../libraries/CanReclaimTokens.sol";
import "./MintGatewayV1.sol";

contract MintGatewayStateV2 {
    struct Burn {
        uint256 _blocknumber;
        bytes _to;
        uint256 _amount;
        // Optional
        string _chain;
        bytes _payload;
    }

    mapping(uint256 => Burn) internal burns;

    bytes32 public selectorHash;
}

/// @notice Gateway handles verifying mint and burn requests. A mintAuthority
/// approves new assets to be minted by providing a digital signature. An owner
/// of an asset can request for it to be burnt.
contract MintGatewayLogicV2 is
    Initializable,
    Claimable,
    CanReclaimTokens,
    IGateway,
    MintGatewayStateV1,
    MintGatewayStateV2
{
    using SafeMath for uint256;

    event LogMintAuthorityUpdated(address indexed _newMintAuthority);
    event LogMint(
        address indexed _to,
        uint256 _amount,
        uint256 indexed _n,
        // Log the nHash instead of sHash so that it can be queried without
        // knowing the sHash.
        bytes32 indexed _nHash
    );
    event LogBurn(
        bytes _to,
        uint256 _amount,
        uint256 indexed _n,
        bytes indexed _indexedTo
    );

    /// @notice Only allow the Darknode Payment contract.
    modifier onlyOwnerOrMintAuthority() {
        require(
            msg.sender == mintAuthority || msg.sender == owner(),
            "MintGateway: caller is not the owner or mint authority"
        );
        _;
    }

    /// @param _token The RenERC20 this Gateway is responsible for.
    /// @param _feeRecipient The recipient of burning and minting fees.
    /// @param _mintAuthority The address of the key that can sign mint
    ///        requests.
    /// @param _mintFee The amount subtracted each mint request and
    ///        forwarded to the feeRecipient. In BIPS.
    /// @param _burnFee The amount subtracted each burn request and
    ///        forwarded to the feeRecipient. In BIPS.
    function initialize(
        RenERC20LogicV1 _token,
        address _feeRecipient,
        address _mintAuthority,
        uint16 _mintFee,
        uint16 _burnFee,
        uint256 _minimumBurnAmount
    ) public initializer {
        Claimable.initialize(msg.sender);
        CanReclaimTokens.initialize(msg.sender);
        minimumBurnAmount = _minimumBurnAmount;
        token = _token;
        mintFee = _mintFee;
        burnFee = _burnFee;
        updateMintAuthority(_mintAuthority);
        updateFeeRecipient(_feeRecipient);
    }

    /// @param _selectorHash Hash of the token and chain selector.
    ///        The hash should calculated from
    ///        `SHA256(4 bytes of selector length, selector)`
    function updateSelectorHash(bytes32 _selectorHash) public onlyOwner {
        selectorHash = _selectorHash;
    }

    /// @notice Allow the owner to update the token symbol.
    function updateSymbol(string memory symbol) public onlyOwner {
        token.updateSymbol(symbol);
    }

    // Public functions ////////////////////////////////////////////////////////

    /// @notice Claims ownership of the token passed in to the constructor.
    /// `transferStoreOwnership` must have previously been called.
    /// Anyone can call this function.
    function claimTokenOwnership() public {
        token.claimOwnership();
    }

    /// @notice Allow the owner to update the owner of the RenERC20 token.
    function transferTokenOwnership(MintGatewayLogicV2 _nextTokenOwner)
        public
        onlyOwner
    {
        token.transferOwnership(address(_nextTokenOwner));
        _nextTokenOwner.claimTokenOwnership();
    }

    /// @notice Allow the owner to update the mint authority.
    ///
    /// @param _nextMintAuthority The new mint authority address.
    function updateMintAuthority(address _nextMintAuthority)
        public
        onlyOwnerOrMintAuthority
    {
        // The mint authority should not be set to 0, which is the result
        // returned by ecrecover for an invalid signature.
        require(
            _nextMintAuthority != address(0),
            "MintGateway: mintAuthority cannot be set to address zero"
        );
        mintAuthority = _nextMintAuthority;
        emit LogMintAuthorityUpdated(mintAuthority);
    }

    /// @notice Allow the owner to update the minimum burn amount.
    ///
    /// @param _minimumBurnAmount The new min burn amount.
    function updateMinimumBurnAmount(uint256 _minimumBurnAmount)
        public
        onlyOwner
    {
        minimumBurnAmount = _minimumBurnAmount;
    }

    /// @notice Allow the owner to update the fee recipient.
    ///
    /// @param _nextFeeRecipient The address to start paying fees to.
    function updateFeeRecipient(address _nextFeeRecipient) public onlyOwner {
        // 'mint' and 'burn' will fail if the feeRecipient is 0x0
        require(
            _nextFeeRecipient != address(0x0),
            "MintGateway: fee recipient cannot be 0x0"
        );

        feeRecipient = _nextFeeRecipient;
    }

    /// @notice Allow the owner to update the 'mint' fee.
    ///
    /// @param _nextMintFee The new fee for minting and burning.
    function updateMintFee(uint16 _nextMintFee) public onlyOwner {
        mintFee = _nextMintFee;
    }

    /// @notice Allow the owner to update the burn fee.
    ///
    /// @param _nextBurnFee The new fee for minting and burning.
    function updateBurnFee(uint16 _nextBurnFee) public onlyOwner {
        burnFee = _nextBurnFee;
    }

    /// @notice Allow the owner to update the mint and burn fees.
    ///
    /// @param _nextMintFee The new fee for minting and burning.
    /// @param _nextBurnFee The new fee for minting and burning.
    function updateFees(uint16 _nextMintFee, uint16 _nextBurnFee)
        public
        onlyOwner
    {
        mintFee = _nextMintFee;
        burnFee = _nextBurnFee;
    }

    /// @notice mint verifies a mint approval signature from RenVM and creates
    ///         tokens after taking a fee for the `_feeRecipient`.
    ///
    /// @param _pHash (payload hash) The hash of the payload associated with the
    ///        mint.
    /// @param _amountUnderlying The amount of the token being minted, in its smallest
    ///        value. (e.g. satoshis for BTC).
    /// @param _nHash (nonce hash) The hash of the nonce, amount and pHash.
    /// @param _sig The signature of the hash of the following values:
    ///        (pHash, amount, msg.sender, nHash), signed by the mintAuthority.
    function mint(
        bytes32 _pHash,
        uint256 _amountUnderlying,
        bytes32 _nHash,
        bytes memory _sig
    ) public returns (uint256) {
        // Calculate the hash signed by RenVM.
        bytes32 sigHash =
            hashForSignature(_pHash, _amountUnderlying, msg.sender, _nHash);

        // Calculate the v0.2 signature hash for backwards-compatibility.
        bytes32 legacySigHash =
            _legacy_hashForSignature(
                _pHash,
                _amountUnderlying,
                msg.sender,
                _nHash
            );

        // Check that neither signature has been redeemed.
        require(
            status[sigHash] == false && status[legacySigHash] == false,
            "MintGateway: nonce hash already spent"
        );

        // If both signatures fail verification, throw an error. If any one of
        // them passed the verification, continue.
        if (
            !verifySignature(sigHash, _sig) &&
            !verifySignature(legacySigHash, _sig)
        ) {
            // Return a detailed string containing the hash and recovered
            // signer. This is somewhat costly but is only run in the revert
            // branch.
            revert(
                String.add8(
                    "MintGateway: invalid signature. pHash: ",
                    String.fromBytes32(_pHash),
                    ", amount: ",
                    String.fromUint(_amountUnderlying),
                    ", msg.sender: ",
                    String.fromAddress(msg.sender),
                    ", _nHash: ",
                    String.fromBytes32(_nHash)
                )
            );
        }

        // Update the status for both signature hashes. This is to ensure that
        // legacy signatures can't be re-redeemed if `updateSelectorHash` is
        // ever called - thus changing the result of `sigHash` but not
        // `legacySigHash`.
        status[sigHash] = true;
        status[legacySigHash] = true;

        uint256 amountScaled = token.fromUnderlying(_amountUnderlying);

        // Mint `amount - fee` for the recipient and mint `fee` for the minter
        uint256 absoluteFeeScaled =
            amountScaled.mul(mintFee).div(BIPS_DENOMINATOR);
        uint256 receivedAmountScaled =
            amountScaled.sub(
                absoluteFeeScaled,
                "MintGateway: fee exceeds amount"
            );

        // Mint amount minus the fee
        token.mint(msg.sender, receivedAmountScaled);
        // Mint the fee
        if (absoluteFeeScaled > 0) {
            token.mint(feeRecipient, absoluteFeeScaled);
        }

        // Emit a log with a unique identifier 'n'.
        uint256 receivedAmountUnderlying =
            token.toUnderlying(receivedAmountScaled);
        emit LogMint(msg.sender, receivedAmountUnderlying, nextN, _nHash);
        nextN += 1;

        return receivedAmountScaled;
    }

    /// @notice burn destroys tokens after taking a fee for the `_feeRecipient`,
    ///         allowing the associated assets to be released on their native
    ///         chain.
    ///
    /// @param _to The address to receive the un-bridged asset. The format of
    ///        this address should be of the destination chain.
    ///        For example, when burning to Bitcoin, _to should be a
    ///        Bitcoin address.
    /// @param _amount The amount of the token being burnt, in its
    ///        smallest value. (e.g. satoshis for BTC)
    function burn(bytes memory _to, uint256 _amount) public returns (uint256) {
        // The recipient must not be empty. Better validation is possible,
        // but would need to be customized for each destination ledger.
        require(_to.length != 0, "MintGateway: to address is empty");

        // Calculate fee, subtract it from amount being burnt.
        uint256 fee = _amount.mul(burnFee).div(BIPS_DENOMINATOR);
        uint256 amountAfterFee =
            _amount.sub(fee, "MintGateway: fee exceeds amount");

        // If the scaled token can represent more precision than the underlying
        // token, the difference is lost. This won't exceed 1 sat, so is
        // negligible compared to burning and transaction fees.
        uint256 amountAfterFeeUnderlying = token.toUnderlying(amountAfterFee);

        // Burn the whole amount, and then re-mint the fee.
        token.burn(msg.sender, _amount);
        if (fee > 0) {
            token.mint(feeRecipient, fee);
        }

        require(
            // Must be strictly greater, to that the release transaction is of
            // at least one unit.
            amountAfterFeeUnderlying > minimumBurnAmount,
            "MintGateway: amount is less than the minimum burn amount"
        );

        emit LogBurn(_to, amountAfterFeeUnderlying, nextN, _to);

        // Store burn so that it can be looked up instead of relying on event
        // logs.
        bytes memory payload;
        MintGatewayStateV2.burns[nextN] = Burn({
            _blocknumber: block.number,
            _to: _to,
            _amount: amountAfterFeeUnderlying,
            _chain: "",
            _payload: payload
        });

        nextN += 1;

        return amountAfterFeeUnderlying;
    }

    function getBurn(uint256 _n)
        public
        view
        returns (
            uint256 _blocknumber,
            bytes memory _to,
            uint256 _amount,
            // Optional
            string memory _chain,
            bytes memory _payload
        )
    {
        Burn memory burnStruct = MintGatewayStateV2.burns[_n];
        require(burnStruct._to.length > 0, "MintGateway: burn not found");
        return (
            burnStruct._blocknumber,
            burnStruct._to,
            burnStruct._amount,
            burnStruct._chain,
            burnStruct._payload
        );
    }

    /// @notice verifySignature checks the the provided signature matches the
    /// provided parameters.
    function verifySignature(bytes32 _sigHash, bytes memory _sig)
        public
        view
        returns (bool)
    {
        return mintAuthority == ECDSA.recover(_sigHash, _sig);
    }

    /// @notice hashForSignature hashes the parameters so that they can be
    /// signed.
    function hashForSignature(
        bytes32 _pHash,
        uint256 _amount,
        address _to,
        bytes32 _nHash
    ) public view returns (bytes32) {
        return
            keccak256(abi.encode(_pHash, _amount, selectorHash, _to, _nHash));
    }

    /// @notice _legacy_hashForSignature calculates the signature hash used by
    /// the 0.2 version of RenVM. It's kept here for backwards-compatibility.
    function _legacy_hashForSignature(
        bytes32 _pHash,
        uint256 _amount,
        address _to,
        bytes32 _nHash
    ) public view returns (bytes32) {
        return
            keccak256(abi.encode(_pHash, _amount, address(token), _to, _nHash));
    }
}

/* solium-disable-next-line no-empty-blocks */
contract MintGatewayProxy is InitializableAdminUpgradeabilityProxy {

}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

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
     * NOTE: This call _does not revert_ if the signature is invalid, or
     * if the signer is otherwise unable to be retrieved. In those scenarios,
     * the zero address is returned.
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
            revert("ECDSA: signature length is invalid");
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
            revert("ECDSA: signature.s is in the wrong range");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: signature.v is in the wrong range");
        }

        // If the signature is valid (and not malleable), return the signer address
        return ecrecover(hash, v, r, s);
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

pragma solidity ^0.5.0;

import './BaseAdminUpgradeabilityProxy.sol';
import './InitializableUpgradeabilityProxy.sol';

/**
 * @title InitializableAdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with an initializer for 
 * initializing the implementation, admin, and init data.
 */
contract InitializableAdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy, InitializableUpgradeabilityProxy {
  /**
   * Contract initializer.
   * @param _logic address of the initial implementation.
   * @param _admin Address of the proxy administrator.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(address _logic, address _admin, bytes memory _data) public payable {
    require(_implementation() == address(0));
    InitializableUpgradeabilityProxy.initialize(_logic, _data);
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(_admin);
  }
}

pragma solidity ^0.5.17;

import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Initializable, Ownable {
    address public pendingOwner;

    function initialize(address _nextOwner) public initializer {
        Ownable.initialize(_nextOwner);
    }

    modifier onlyPendingOwner() {
        require(
            _msgSender() == pendingOwner,
            "Claimable: caller is not the pending owner"
        );
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != owner() && newOwner != pendingOwner,
            "Claimable: invalid new owner"
        );
        pendingOwner = newOwner;
    }

    // Allow skipping two-step transfer if the recipient is known to be a valid
    // owner, for use in smart-contracts only.
    function _directTransferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function claimOwnership() public onlyPendingOwner {
        _transferOwnership(pendingOwner);
        delete pendingOwner;
    }
}

pragma solidity ^0.5.17;

library String {
    /// @notice Convert a uint value to its decimal string representation
    // solium-disable-next-line security/no-assign-params
    function fromUint(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    /// @notice Convert a bytes32 value to its hex string representation.
    function fromBytes32(bytes32 _value) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(32 * 2 + 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 32; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(_value[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(_value[i] & 0x0f))];
        }
        return string(str);
    }

    /// @notice Convert an address to its hex string representation.
    function fromAddress(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(20 * 2 + 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(value[i + 12] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }

    /// @notice Append eight strings.
    function add8(
        string memory a,
        string memory b,
        string memory c,
        string memory d,
        string memory e,
        string memory f,
        string memory g,
        string memory h
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e, f, g, h));
    }
}

pragma solidity ^0.5.16;

import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/upgrades/contracts/upgradeability/InitializableAdminUpgradeabilityProxy.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Detailed.sol";

import "../Governance/Claimable.sol";
import "../libraries/CanReclaimTokens.sol";
import "./ERC20WithRate.sol";
import "./ERC20WithPermit.sol";

/// @notice RenERC20 represents a digital asset that has been bridged on to
/// the Ethereum ledger. It exposes mint and burn functions that can only be
/// called by it's associated Gateway contract.
contract RenERC20LogicV1 is
    Initializable,
    ERC20,
    ERC20Detailed,
    ERC20WithRate,
    ERC20WithPermit,
    Claimable,
    CanReclaimTokens
{
    /* solium-disable-next-line no-empty-blocks */
    function initialize(
        uint256 _chainId,
        address _nextOwner,
        uint256 _initialRate,
        string memory _version,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public initializer {
        ERC20Detailed.initialize(_name, _symbol, _decimals);
        ERC20WithRate.initialize(_nextOwner, _initialRate);
        ERC20WithPermit.initialize(
            _chainId,
            _version,
            _name,
            _symbol,
            _decimals
        );
        Claimable.initialize(_nextOwner);
        CanReclaimTokens.initialize(_nextOwner);
    }

    function updateSymbol(string memory symbol) public onlyOwner {
        ERC20Detailed._symbol = symbol;
    }

    /// @notice mint can only be called by the tokens' associated Gateway
    /// contract. See Gateway's mint function instead.
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    /// @notice burn can only be called by the tokens' associated Gateway
    /// contract. See Gateway's burn functions instead.
    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        // Disallow sending tokens to the ERC20 contract address - a common
        // mistake caused by the Ethereum transaction's `to` needing to be
        // the token's address.
        require(
            recipient != address(this),
            "RenERC20: can't transfer to token address"
        );
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        // Disallow sending tokens to the ERC20 contract address (see comment
        // in `transfer`).
        require(
            recipient != address(this),
            "RenERC20: can't transfer to token address"
        );
        return super.transferFrom(sender, recipient, amount);
    }
}

/* solium-disable-next-line no-empty-blocks */
contract RenERC20Proxy is InitializableAdminUpgradeabilityProxy {

}

pragma solidity ^0.5.17;

interface IMintGateway {
    function mint(
        bytes32 _pHash,
        uint256 _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) external returns (uint256);

    function mintFee() external view returns (uint256);
}

interface IBurnGateway {
    function burn(bytes calldata _to, uint256 _amountScaled)
        external
        returns (uint256);

    function burnFee() external view returns (uint256);
}

// TODO: In ^0.6.0, should be `interface IGateway is IMintGateway,IBurnGateway {}`
interface IGateway {
    // is IMintGateway
    function mint(
        bytes32 _pHash,
        uint256 _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) external returns (uint256);

    function mintFee() external view returns (uint256);

    // is IBurnGateway
    function burn(bytes calldata _to, uint256 _amountScaled)
        external
        returns (uint256);

    function burnFee() external view returns (uint256);
}

pragma solidity ^0.5.17;

import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "../Governance/Claimable.sol";

contract CanReclaimTokens is Claimable {
    using SafeERC20 for ERC20;

    mapping(address => bool) private recoverableTokensBlacklist;

    function initialize(address _nextOwner) public initializer {
        Claimable.initialize(_nextOwner);
    }

    function blacklistRecoverableToken(address _token) public onlyOwner {
        recoverableTokensBlacklist[_token] = true;
    }

    /// @notice Allow the owner of the contract to recover funds accidentally
    /// sent to the contract. To withdraw ETH, the token should be set to `0x0`.
    function recoverTokens(address _token) external onlyOwner {
        require(
            !recoverableTokensBlacklist[_token],
            "CanReclaimTokens: token is not recoverable"
        );

        if (_token == address(0x0)) {
            msg.sender.transfer(address(this).balance);
        } else {
            ERC20(_token).safeTransfer(
                msg.sender,
                ERC20(_token).balanceOf(address(this))
            );
        }
    }
}

pragma solidity 0.5.17;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/upgrades/contracts/upgradeability/InitializableAdminUpgradeabilityProxy.sol";

import "../Governance/Claimable.sol";
import "../libraries/String.sol";
import "./RenERC20.sol";
import "./interfaces/IGateway.sol";
import "../libraries/CanReclaimTokens.sol";

contract MintGatewayStateV1 {
    uint256 constant BIPS_DENOMINATOR = 10000;
    uint256 public minimumBurnAmount;

    /// @notice Each Gateway is tied to a specific RenERC20 token.
    RenERC20LogicV1 public token;

    /// @notice The mintAuthority is an address that can sign mint requests.
    address public mintAuthority;

    /// @dev feeRecipient is assumed to be an address (or a contract) that can
    /// accept erc20 payments it cannot be 0x0.
    /// @notice When tokens are mint or burnt, a portion of the tokens are
    /// forwarded to a fee recipient.
    address public feeRecipient;

    /// @notice The mint fee in bips.
    uint16 public mintFee;

    /// @notice The burn fee in bips.
    uint16 public burnFee;

    /// @notice Each signature can only be seen once.
    mapping(bytes32 => bool) public status;

    // LogMint and LogBurn contain a unique `n` that identifies
    // the mint or burn event.
    uint256 public nextN = 0;
}

/// @notice Gateway handles verifying mint and burn requests. A mintAuthority
/// approves new assets to be minted by providing a digital signature. An owner
/// of an asset can request for it to be burnt.
contract MintGatewayLogicV1 is
    Initializable,
    Claimable,
    CanReclaimTokens,
    IGateway,
    MintGatewayStateV1
{
    using SafeMath for uint256;

    event LogMintAuthorityUpdated(address indexed _newMintAuthority);
    event LogMint(
        address indexed _to,
        uint256 _amount,
        uint256 indexed _n,
        bytes32 indexed _signedMessageHash
    );
    event LogBurn(
        bytes _to,
        uint256 _amount,
        uint256 indexed _n,
        bytes indexed _indexedTo
    );

    /// @notice Only allow the Darknode Payment contract.
    modifier onlyOwnerOrMintAuthority() {
        require(
            msg.sender == mintAuthority || msg.sender == owner(),
            "Gateway: caller is not the owner or mint authority"
        );
        _;
    }

    /// @param _token The RenERC20 this Gateway is responsible for.
    /// @param _feeRecipient The recipient of burning and minting fees.
    /// @param _mintAuthority The address of the key that can sign mint
    ///        requests.
    /// @param _mintFee The amount subtracted each mint request and
    ///        forwarded to the feeRecipient. In BIPS.
    /// @param _burnFee The amount subtracted each burn request and
    ///        forwarded to the feeRecipient. In BIPS.
    function initialize(
        RenERC20LogicV1 _token,
        address _feeRecipient,
        address _mintAuthority,
        uint16 _mintFee,
        uint16 _burnFee,
        uint256 _minimumBurnAmount
    ) public initializer {
        Claimable.initialize(msg.sender);
        CanReclaimTokens.initialize(msg.sender);
        minimumBurnAmount = _minimumBurnAmount;
        token = _token;
        mintFee = _mintFee;
        burnFee = _burnFee;
        updateMintAuthority(_mintAuthority);
        updateFeeRecipient(_feeRecipient);
    }

    // Public functions ////////////////////////////////////////////////////////

    /// @notice Claims ownership of the token passed in to the constructor.
    /// `transferStoreOwnership` must have previously been called.
    /// Anyone can call this function.
    function claimTokenOwnership() public {
        token.claimOwnership();
    }

    /// @notice Allow the owner to update the owner of the RenERC20 token.
    function transferTokenOwnership(MintGatewayLogicV1 _nextTokenOwner)
        public
        onlyOwner
    {
        token.transferOwnership(address(_nextTokenOwner));
        _nextTokenOwner.claimTokenOwnership();
    }

    /// @notice Allow the owner to update the mint authority.
    ///
    /// @param _nextMintAuthority The new mint authority address.
    function updateMintAuthority(address _nextMintAuthority)
        public
        onlyOwnerOrMintAuthority
    {
        // The mint authority should not be set to 0, which is the result
        // returned by ecrecover for an invalid signature.
        require(
            _nextMintAuthority != address(0),
            "Gateway: mintAuthority cannot be set to address zero"
        );
        mintAuthority = _nextMintAuthority;
        emit LogMintAuthorityUpdated(mintAuthority);
    }

    /// @notice Allow the owner to update the minimum burn amount.
    ///
    /// @param _minimumBurnAmount The new min burn amount.
    function updateMinimumBurnAmount(uint256 _minimumBurnAmount)
        public
        onlyOwner
    {
        minimumBurnAmount = _minimumBurnAmount;
    }

    /// @notice Allow the owner to update the fee recipient.
    ///
    /// @param _nextFeeRecipient The address to start paying fees to.
    function updateFeeRecipient(address _nextFeeRecipient) public onlyOwner {
        // 'mint' and 'burn' will fail if the feeRecipient is 0x0
        require(
            _nextFeeRecipient != address(0x0),
            "Gateway: fee recipient cannot be 0x0"
        );

        feeRecipient = _nextFeeRecipient;
    }

    /// @notice Allow the owner to update the 'mint' fee.
    ///
    /// @param _nextMintFee The new fee for minting and burning.
    function updateMintFee(uint16 _nextMintFee) public onlyOwner {
        mintFee = _nextMintFee;
    }

    /// @notice Allow the owner to update the burn fee.
    ///
    /// @param _nextBurnFee The new fee for minting and burning.
    function updateBurnFee(uint16 _nextBurnFee) public onlyOwner {
        burnFee = _nextBurnFee;
    }

    /// @notice mint verifies a mint approval signature from RenVM and creates
    ///         tokens after taking a fee for the `_feeRecipient`.
    ///
    /// @param _pHash (payload hash) The hash of the payload associated with the
    ///        mint.
    /// @param _amountUnderlying The amount of the token being minted, in its smallest
    ///        value. (e.g. satoshis for BTC).
    /// @param _nHash (nonce hash) The hash of the nonce, amount and pHash.
    /// @param _sig The signature of the hash of the following values:
    ///        (pHash, amount, msg.sender, nHash), signed by the mintAuthority.
    function mint(
        bytes32 _pHash,
        uint256 _amountUnderlying,
        bytes32 _nHash,
        bytes memory _sig
    ) public returns (uint256) {
        // Calculate the hash signed by RenVM.
        bytes32 sigHash =
            hashForSignature(_pHash, _amountUnderlying, msg.sender, _nHash);

        //

        // Check that the signature hasn't been redeemed.
        require(status[sigHash] == false, "Gateway: nonce hash already spent");

        // If the signature fails verification, throw an error. If any one of
        // them passed the verification, continue.
        if (!verifySignature(sigHash, _sig)) {
            // Return a detailed string containing the hash and recovered
            // signer. This is somewhat costly but is only run in the revert
            // branch.
            revert(
                String.add8(
                    "Gateway: invalid signature. pHash: ",
                    String.fromBytes32(_pHash),
                    ", amount: ",
                    String.fromUint(_amountUnderlying),
                    ", msg.sender: ",
                    String.fromAddress(msg.sender),
                    ", _nHash: ",
                    String.fromBytes32(_nHash)
                )
            );
        }

        // Update the status for the signature hash so that it can't be used
        // again.
        status[sigHash] = true;

        uint256 amountScaled = token.fromUnderlying(_amountUnderlying);

        // Mint `amount - fee` for the recipient and mint `fee` for the minter
        uint256 absoluteFeeScaled =
            amountScaled.mul(mintFee).div(BIPS_DENOMINATOR);
        uint256 receivedAmountScaled =
            amountScaled.sub(absoluteFeeScaled, "Gateway: fee exceeds amount");

        // Mint amount minus the fee
        token.mint(msg.sender, receivedAmountScaled);
        // Mint the fee
        token.mint(feeRecipient, absoluteFeeScaled);

        // Emit a log with a unique identifier 'n'.
        uint256 receivedAmountUnderlying =
            token.toUnderlying(receivedAmountScaled);
        emit LogMint(msg.sender, receivedAmountUnderlying, nextN, sigHash);
        nextN += 1;

        return receivedAmountScaled;
    }

    /// @notice burn destroys tokens after taking a fee for the `_feeRecipient`,
    ///         allowing the associated assets to be released on their native
    ///         chain.
    ///
    /// @param _to The address to receive the un-bridged asset. The format of
    ///        this address should be of the destination chain.
    ///        For example, when burning to Bitcoin, _to should be a
    ///        Bitcoin address.
    /// @param _amount The amount of the token being burnt, in its
    ///        smallest value. (e.g. satoshis for BTC)
    function burn(bytes memory _to, uint256 _amount) public returns (uint256) {
        // The recipient must not be empty. Better validation is possible,
        // but would need to be customized for each destination ledger.
        require(_to.length != 0, "Gateway: to address is empty");

        // Calculate fee, subtract it from amount being burnt.
        uint256 fee = _amount.mul(burnFee).div(BIPS_DENOMINATOR);
        uint256 amountAfterFee =
            _amount.sub(fee, "Gateway: fee exceeds amount");

        // If the scaled token can represent more precision than the underlying
        // token, the difference is lost. This won't exceed 1 sat, so is
        // negligible compared to burning and transaction fees.
        uint256 amountAfterFeeUnderlying = token.toUnderlying(amountAfterFee);

        // Burn the whole amount, and then re-mint the fee.
        token.burn(msg.sender, _amount);
        token.mint(feeRecipient, fee);

        require(
            // Must be strictly greater, to that the release transaction is of
            // at least one unit.
            amountAfterFeeUnderlying > minimumBurnAmount,
            "Gateway: amount is less than the minimum burn amount"
        );

        emit LogBurn(_to, amountAfterFeeUnderlying, nextN, _to);
        nextN += 1;

        return amountAfterFeeUnderlying;
    }

    /// @notice verifySignature checks the the provided signature matches the
    /// provided parameters.
    function verifySignature(bytes32 _sigHash, bytes memory _sig)
        public
        view
        returns (bool)
    {
        return mintAuthority == ECDSA.recover(_sigHash, _sig);
    }

    /// @notice hashForSignature hashes the parameters so that they can be
    /// signed.
    function hashForSignature(
        bytes32 _pHash,
        uint256 _amount,
        address _to,
        bytes32 _nHash
    ) public view returns (bytes32) {
        return
            keccak256(abi.encode(_pHash, _amount, address(token), _to, _nHash));
    }
}

contract BTCGateway is InitializableAdminUpgradeabilityProxy {}

contract ZECGateway is InitializableAdminUpgradeabilityProxy {}

contract BCHGateway is InitializableAdminUpgradeabilityProxy {}

pragma solidity ^0.5.0;

import './UpgradeabilityProxy.sol';

/**
 * @title BaseAdminUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Emitted when the administration has been transferred.
   * @param previousAdmin Address of the previous admin.
   * @param newAdmin Address of the new admin.
   */
  event AdminChanged(address previousAdmin, address newAdmin);

  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */

  bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  /**
   * @dev Modifier to check whether the `msg.sender` is the admin.
   * If it is, it will run the function. Otherwise, it will delegate the call
   * to the implementation.
   */
  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

  /**
   * @return The address of the proxy admin.
   */
  function admin() external ifAdmin returns (address) {
    return _admin();
  }

  /**
   * @return The address of the implementation.
   */
  function implementation() external ifAdmin returns (address) {
    return _implementation();
  }

  /**
   * @dev Changes the admin of the proxy.
   * Only the current admin can call this function.
   * @param newAdmin Address to transfer proxy administration to.
   */
  function changeAdmin(address newAdmin) external ifAdmin {
    require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy.
   * Only the admin can call this function.
   * @param newImplementation Address of the new implementation.
   */
  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy and call a function
   * on the new implementation.
   * This is useful to initialize the proxied contract.
   * @param newImplementation Address of the new implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
  function upgradeToAndCall(address newImplementation, bytes calldata data) payable external ifAdmin {
    _upgradeTo(newImplementation);
    (bool success,) = newImplementation.delegatecall(data);
    require(success);
  }

  /**
   * @return The admin slot.
   */
  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }

  /**
   * @dev Sets the address of the proxy admin.
   * @param newAdmin Address of the new proxy admin.
   */
  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;

    assembly {
      sstore(slot, newAdmin)
    }
  }

  /**
   * @dev Only fall back when the sender is not the admin.
   */
  function _willFallback() internal {
    require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");
    super._willFallback();
  }
}

pragma solidity ^0.5.0;

import './BaseUpgradeabilityProxy.sol';

/**
 * @title InitializableUpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with an initializer for initializing
 * implementation and init data.
 */
contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract initializer.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(address _logic, bytes memory _data) public payable {
    require(_implementation() == address(0));
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }
  }  
}

pragma solidity ^0.5.0;

import './BaseUpgradeabilityProxy.sol';

/**
 * @title UpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with a constructor for initializing
 * implementation and init data.
 */
contract UpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract constructor.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  constructor(address _logic, bytes memory _data) public payable {
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }
  }  
}

pragma solidity ^0.5.0;

import './Proxy.sol';
import '../utils/Address.sol';

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Returns the current implementation.
   * @return Address of the current implementation
   */
  function _implementation() internal view returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    require(OpenZeppelinUpgradesAddress.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}

pragma solidity ^0.5.0;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
contract Proxy {
  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  function () payable external {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() internal view returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize)

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize)

      switch result
      // delegatecall returns 0 on error.
      case 0 { revert(0, returndatasize) }
      default { return(0, returndatasize) }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal {
  }

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}

pragma solidity ^0.5.0;

/**
 * Utility library of inline functions on addresses
 *
 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/v2.1.3/contracts/utils/Address.sol
 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts
 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the
 * build/artifacts folder) as well as the vanilla Address implementation from an openzeppelin version.
 */
library OpenZeppelinUpgradesAddress {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "../GSN/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

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
contract Context is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
contract ERC20 is Initializable, Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./IERC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is Initializable, IERC20 {
    string private _name;
    string internal _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    function initialize(string memory name, string memory symbol, uint8 decimals) public initializer {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    uint256[50] private ______gap;
}

pragma solidity ^0.5.17;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

import "../Governance/Claimable.sol";

/// @notice ERC20WithRate allows for a more dynamic fee model by storing a rate
/// that tracks the number of the underlying asset's unit represented by a
/// single ERC20 token.
contract ERC20WithRate is Initializable, Ownable, ERC20 {
    using SafeMath for uint256;

    uint256 public constant _rateScale = 1e18;
    uint256 internal _rate;

    event LogRateChanged(uint256 indexed _rate);

    /* solium-disable-next-line no-empty-blocks */
    function initialize(address _nextOwner, uint256 _initialRate)
        public
        initializer
    {
        Ownable.initialize(_nextOwner);
        _setRate(_initialRate);
    }

    function setExchangeRate(uint256 _nextRate) public onlyOwner {
        _setRate(_nextRate);
    }

    function exchangeRateCurrent() public view returns (uint256) {
        require(_rate != 0, "ERC20WithRate: rate has not been initialized");
        return _rate;
    }

    function _setRate(uint256 _nextRate) internal {
        require(_nextRate > 0, "ERC20WithRate: rate must be greater than zero");
        _rate = _nextRate;
    }

    function balanceOfUnderlying(address _account)
        public
        view
        returns (uint256)
    {
        return toUnderlying(balanceOf(_account));
    }

    function toUnderlying(uint256 _amount) public view returns (uint256) {
        return _amount.mul(_rate).div(_rateScale);
    }

    function fromUnderlying(uint256 _amountUnderlying)
        public
        view
        returns (uint256)
    {
        return _amountUnderlying.mul(_rateScale).div(_rate);
    }
}

pragma solidity ^0.5.17;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Detailed.sol";

/// @notice Taken from the DAI token.
contract ERC20WithPermit is Initializable, ERC20, ERC20Detailed {
    using SafeMath for uint256;

    mapping(address => uint256) public nonces;

    // If the token is redeployed, the version is increased to prevent a permit
    // signature being used on both token instances.
    string public version;

    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    // PERMIT_TYPEHASH is the value returned from
    // keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)")
    bytes32 public constant PERMIT_TYPEHASH =
        0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    function initialize(
        uint256 _chainId,
        string memory _version,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public initializer {
        ERC20Detailed.initialize(_name, _symbol, _decimals);
        version = _version;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name())),
                keccak256(bytes(version)),
                _chainId,
                address(this)
            )
        );
    }

    // --- Approve by signature ---
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            holder,
                            spender,
                            nonce,
                            expiry,
                            allowed
                        )
                    )
                )
            );

        require(holder != address(0), "ERC20WithRate: address must not be 0x0");
        require(
            holder == ecrecover(digest, v, r, s),
            "ERC20WithRate: invalid signature"
        );
        require(
            expiry == 0 || now <= expiry,
            "ERC20WithRate: permit has expired"
        );
        require(nonce == nonces[holder]++, "ERC20WithRate: invalid nonce");
        uint256 amount = allowed ? uint256(-1) : 0;
        _approve(holder, spender, amount);
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
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
  "libraries": {}
}