//SPDX-License-Identifier: Apache License Version 2.0
pragma solidity =0.8.4;

import {EFITokenV2} from "./EFITokenV2.sol";
import {EIP712} from "../utils/EIP712.sol";
import {EIP712Domain} from "./EIP712Domain.sol";
import {EIP3009} from "./EIP3009.sol";
import {EIP2612} from "./EIP2612.sol";

/// @title EFI Token V2.1
/// @author Enjin Team
contract EFITokenV2_1 is EFITokenV2, EIP3009, EIP2612 {
    bool internal _v2Initialized;

    /// @notice Initialize v2
    function initializeV2() external {
        // solhint-disable-next-line reason-string
        require(!_v2Initialized, "Efinity Token: v2 already initialized");
        DOMAIN_SEPARATOR = EIP712.makeDomainSeparator(name(), "2");
        _v2Initialized = true;
    }

    /// @notice Execute a transfer with a signed authorization
    /// @param from          Payer's address (Authorizer)
    /// @param to            Payee's address
    /// @param value         Amount to be transferred
    /// @param validAfter    The time after which this is valid (unix time)
    /// @param validBefore   The time before which this is valid (unix time)
    /// @param nonce         Unique nonce
    /// @param v             v of the signature
    /// @param r             r of the signature
    /// @param s             s of the signature
    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual {
        _transferWithAuthorization(
            from,
            to,
            value,
            validAfter,
            validBefore,
            nonce,
            v,
            r,
            s
        );
    }

    /// @notice Receive a transfer with a signed authorization from the payer
    /// @dev This has an additional check to ensure that the payee's address
    /// matches the caller of this function to prevent front-running attacks.
    /// @param from          Payer's address (Authorizer)
    /// @param to            Payee's address
    /// @param value         Amount to be transferred
    /// @param validAfter    The time after which this is valid (unix time)
    /// @param validBefore   The time before which this is valid (unix time)
    /// @param nonce         Unique nonce
    /// @param v             v of the signature
    /// @param r             r of the signature
    /// @param s             s of the signature
    function receiveWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual {
        _receiveWithAuthorization(
            from,
            to,
            value,
            validAfter,
            validBefore,
            nonce,
            v,
            r,
            s
        );
    }

    /// @notice Attempt to cancel an authorization
    /// @dev Works only if the authorization is not yet used.
    /// @param authorizer    Authorizer's address
    /// @param nonce         Nonce of the authorization
    /// @param v             v of the signature
    /// @param r             r of the signature
    /// @param s             s of the signature
    function cancelAuthorization(
        address authorizer,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual {
        _cancelAuthorization(authorizer, nonce, v, r, s);
    }

    /// @notice Update allowance with a signed permit
    /// @param owner       Token owner's address (Authorizer)
    /// @param spender     Spender's address
    /// @param value       Amount of allowance
    /// @param deadline    Expiration time, seconds since the epoch
    /// @param v           v of the signature
    /// @param r           r of the signature
    /// @param s           s of the signature
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual {
        _permit(owner, spender, value, deadline, v, r, s);
    }

    /// @notice Version string for the EIP712 domain separator
    /// @return Version string
    function version() external pure virtual returns (string memory) {
        return "3";
    }
}

//SPDX-License-Identifier: Apache License Version 2.0
pragma solidity =0.8.4;

import "./ERC20UpgradeableV2.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// @title EFI Token V2
/// @author Enjin Team
contract EFITokenV2 is ERC20UpgradeableV2 {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice address of the invited owner
    address public invitedOwner;

    /// @notice the address of the current owner of the contract
    address public owner;

    event NewOwnerInvited(
        address indexed currentOwner,
        address indexed invitedOwner
    );

    event InvitationRevoked(
        address indexed currentOwner,
        address indexed invitedOwner
    );

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @param initialSupply the initial supply of tokens
    /// @param _owner Address owning the total supply
    function initialize(uint256 initialSupply, address _owner)
        public
        initializer
    {
        __ERC20_init("Efinity Token", "EFI");
        _mint(_owner, initialSupply);
        owner = _owner;
        emit OwnershipTransferred(address(0), _owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Efinity Token: caller is not the owner");

        _;
    }

    /// @notice As Owner, invite another account to take ownership of the contract
    /// @param _invitedOwner address of the invited owner
    function inviteNewOwner(address _invitedOwner) external virtual onlyOwner {
        invitedOwner = _invitedOwner;

        emit NewOwnerInvited(owner, _invitedOwner);
    }

    /// @notice As Owner, revoke the invitation sent to an account
    /// @param _invitedOwner address of the invited owner
    function revokeInvitation(address _invitedOwner)
        external
        virtual
        onlyOwner
    {
        require(
            invitedOwner == _invitedOwner,
            "Efinity Token: not invited owner"
        );

        delete invitedOwner;

        emit InvitationRevoked(owner, _invitedOwner);
    }

    /// @notice As the Invited Owner, accept the invitation to take ownership of the contract
    function acceptOwnership() external virtual {
        require(
            msg.sender == invitedOwner,
            "Efinity Token: caller is not invited owner"
        );

        delete invitedOwner;

        emit OwnershipTransferred(owner, msg.sender);

        owner = msg.sender;
    }

    /// @notice As Owner, withdraw tokens sent to this account
    /// @param _token address of the token contract
    /// @param _to recipient address
    /// @param _amount number of tokens to transfer
    /// @return true if successful
    function withdrawTokens(
        address _token,
        address _to,
        uint256 _amount
    ) external virtual onlyOwner returns (bool) {
        IERC20Upgradeable(_token).safeTransfer(_to, _amount);

        return true;
    }

    /// @notice safely transfer tokens to externally-owned accounts or contracts
    /// @param recipient recipient address
    /// @param amount number of tokens to transfer
    /// @return true if successful
    function safeTransfer(address recipient, uint256 amount)
        public
        virtual
        returns (bool)
    {
        super.transfer(recipient, amount);

        address operator = msg.sender;

        _doSafeTransferAcceptanceCheck(
            operator,
            operator,
            recipient,
            amount,
            ""
        );

        return true;
    }

    /// @notice safely transfer tokens to externally-owned accounts or contracts
    /// @dev for transfers that include arbitrary data for the recipient
    /// @param recipient recipient address
    /// @param amount number of tokens to transfer
    /// @param data arbitrary data for the recipient
    /// @return true if successful
    function safeTransfer(
        address recipient,
        uint256 amount,
        bytes memory data
    ) public virtual returns (bool) {
        super.transfer(recipient, amount);

        address operator = msg.sender;

        _doSafeTransferAcceptanceCheck(
            operator,
            operator,
            recipient,
            amount,
            data
        );

        return true;
    }

    /// @notice safely transfer tokens from one account to another externally-owned account or contract
    /// @param recipient recipient address
    /// @param amount number of tokens to transfer
    /// @return true if successful
    function safeTransferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual returns (bool) {
        super.transferFrom(sender, recipient, amount);

        address operator = msg.sender;

        _doSafeTransferAcceptanceCheck(operator, sender, recipient, amount, "");

        return true;
    }

    /// @notice safely transfer tokens from one account to another externally-owned account or contract
    /// @dev for transfers that include arbitrary data for the recipient
    /// @param recipient recipient address
    /// @param amount number of tokens to transfer
    /// @param data arbitrary data for the recipient
    /// @return true if successful
    function safeTransferFrom(
        address sender,
        address recipient,
        uint256 amount,
        bytes memory data
    ) public virtual returns (bool) {
        super.transferFrom(sender, recipient, amount);

        address operator = msg.sender;

        _doSafeTransferAcceptanceCheck(
            operator,
            sender,
            recipient,
            amount,
            data
        );

        return true;
    }

    /// @notice transfer tokens from one account to multiple accounts
    /// @dev for transfers that include arbitrary data for the recipient
    /// @param recipients array of recipient address
    /// @param amounts array of number of tokens to transfer
    /// @return true if successful
    function bulkTransfer(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) public virtual returns (bool) {
        _bulkTransfer(msg.sender, recipients, amounts);

        return true;
    }

    /// @notice transfer tokens from one account to multiple accounts provided the caller has proper approval
    /// @dev for transfers that include arbitrary data for the recipient
    /// @param sender sender address
    /// @param recipients array of recipient addresses
    /// @param amounts array of number of tokens to transfer
    /// @return true if successful
    function bulkTransferFrom(
        address sender,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) public virtual returns (bool) {
        uint256 totalAmount = _bulkTransfer(sender, recipients, amounts);

        _processApproval(sender, totalAmount);

        return true;
    }

    /// @notice safely transfer tokens from one account to multiple accounts
    /// @dev for transfers that include arbitrary data for the recipient
    /// @param recipients array of recipient address
    /// @param amounts array of number of tokens to transfer
    /// @param data array arbitrary data for the respective recipient
    /// @return true if successful
    function safeBulkTransfer(
        address[] calldata recipients,
        uint256[] calldata amounts,
        bytes[] calldata data
    ) public virtual returns (bool) {
        address operator = msg.sender;

        _safeBulkTransfer(operator, operator, recipients, amounts, data);

        return true;
    }

    /// @notice safely transfer tokens from one account to multiple accounts provided the caller has proper approval
    /// @dev for transfers that include arbitrary data for the recipient
    /// @param sender sender address
    /// @param recipients array of recipient address
    /// @param amounts array of number of tokens to transfer
    /// @param data array arbitrary data for the respective recipient
    /// @return true if successful
    function safeBulkTransferFrom(
        address sender,
        address[] calldata recipients,
        uint256[] calldata amounts,
        bytes[] calldata data
    ) public virtual returns (bool) {
        address operator = msg.sender;

        uint256 totalAmount =
            _safeBulkTransfer(operator, operator, recipients, amounts, data);

        _processApproval(sender, totalAmount);
        return true;
    }

    function _processApproval(address sender, uint256 totalAmount) private {
        uint256 currentAllowance = allowance(sender, msg.sender);

        require(
            currentAllowance >= totalAmount,
            "Efinity Token: transfer amount exceeds allowance"
        );

        _approve(sender, msg.sender, currentAllowance - totalAmount);
    }
}

//SPDX-License-Identifier: Apache License Version 2.0
pragma solidity =0.8.4;

import {ECRecover} from "./ECRecover.sol";

/// @title EIP712
/// @notice A library that provides EIP712 helper functions
library EIP712 {
    /// @notice Make EIP712 domain separator
    /// @param name      Contract name
    /// @param version   Contract version
    /// @return Domain separator
    function makeDomainSeparator(string memory name, string memory version)
        internal
        view
        returns (bytes32)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return
            keccak256(
                abi.encode(
                    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    chainId,
                    address(this)
                )
            );
    }

    /// @notice Recover signer's address from a EIP712 signature
    /// @param domainSeparator   Domain separator
    /// @param v                 v of the signature
    /// @param r                 r of the signature
    /// @param s                 s of the signature
    /// @param typeHashAndData   Type hash concatenated with data
    /// @return Signer's address
    function recover(
        bytes32 domainSeparator,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes memory typeHashAndData
    ) internal pure returns (address) {
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(typeHashAndData)
                )
            );
        return ECRecover.recover(digest, v, r, s);
    }
}

//SPDX-License-Identifier: Apache License Version 2.0
pragma solidity =0.8.4;

/// @title EIP712 Domain
contract EIP712Domain {
    /// @dev EIP712 Domain Separator
    bytes32 public DOMAIN_SEPARATOR;
}

//SPDX-License-Identifier: Apache License Version 2.0
pragma solidity =0.8.4;

import {AbstractEFIMethods} from "./AbstractEFIMethods.sol";
import {EIP712Domain} from "./EIP712Domain.sol";
import {EIP712} from "../utils/EIP712.sol";

/// @title EIP-3009
/// @notice Provide internal implementation for gas-abstracted transfers
/// @dev Contracts that inherit from this must wrap these with publicly
///      accessible functions, optionally adding modifiers where necessary
abstract contract EIP3009 is AbstractEFIMethods, EIP712Domain {
    // keccak256("TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
    bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
        0x7c7c6cdb67a18743f49ec6fa9b35f50d52ed05cbed4cc592e13b44501c1a2267;

    // keccak256("ReceiveWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
    bytes32 public constant RECEIVE_WITH_AUTHORIZATION_TYPEHASH =
        0xd099cc98ef71107a616c4f0f941f04c322d8e254fe26b3c6668db87aae413de8;

    // keccak256("CancelAuthorization(address authorizer,bytes32 nonce)")
    bytes32 public constant CANCEL_AUTHORIZATION_TYPEHASH =
        0x158b0a9edf7a828aad02f63cd515c68ef2f50ba807396f6d12842833a1597429;

    /// @dev authorizer address => nonce => bool (true if nonce is used)
    mapping(address => mapping(bytes32 => bool)) private _authorizationStates;

    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);
    event AuthorizationCanceled(
        address indexed authorizer,
        bytes32 indexed nonce
    );

    /// @notice Returns the state of an authorization
    /// @dev Nonces are randomly generated 32-byte data unique to the
    /// authorizer's address
    /// @param authorizer    Authorizer's address
    /// @param nonce         Nonce of the authorization
    /// @return              True if the nonce is used
    function authorizationState(address authorizer, bytes32 nonce)
        external
        view
        returns (bool)
    {
        return _authorizationStates[authorizer][nonce];
    }

    /// @notice Execute a transfer with a signed authorization
    /// @param from          Payer's address (Authorizer)
    /// @param to            Payee's address
    /// @param value         Amount to be transferred
    /// @param validAfter    The time after which this is valid (unix time)
    /// @param validBefore   The time before which this is valid (unix time)
    /// @param nonce         Unique nonce
    /// @param v             v of the signature
    /// @param r             r of the signature
    /// @param s             s of the signature
    function _transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        _requireValidAuthorization(from, nonce, validAfter, validBefore);

        bytes memory data =
            abi.encode(
                TRANSFER_WITH_AUTHORIZATION_TYPEHASH,
                from,
                to,
                value,
                validAfter,
                validBefore,
                nonce
            );
        require(
            EIP712.recover(DOMAIN_SEPARATOR, v, r, s, data) == from,
            "Efinity Token: invalid signature"
        );

        _markAuthorizationAsUsed(from, nonce);
        _transfer(from, to, value);
    }

    /// @notice Receive a transfer with a signed authorization from the payer
    /// @dev This has an additional check to ensure that the payee's address
    ///      matches the caller of this function to prevent front-running attacks.
    ///      https://eips.ethereum.org/EIPS/eip-3009#security-considerations
    /// @param from          Payer's address (Authorizer)
    /// @param to            Payee's address
    /// @param value         Amount to be transferred
    /// @param validAfter    The time after which this is valid (unix time)
    /// @param validBefore   The time before which this is valid (unix time)
    /// @param nonce         Unique nonce
    /// @param v             v of the signature
    /// @param r             r of the signature
    /// @param s             s of the signature
    function _receiveWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        require(to == msg.sender, "Efinity Token: caller must be the payee");
        _requireValidAuthorization(from, nonce, validAfter, validBefore);

        bytes memory data =
            abi.encode(
                RECEIVE_WITH_AUTHORIZATION_TYPEHASH,
                from,
                to,
                value,
                validAfter,
                validBefore,
                nonce
            );
        require(
            EIP712.recover(DOMAIN_SEPARATOR, v, r, s, data) == from,
            "Efinity Token: invalid signature"
        );

        _markAuthorizationAsUsed(from, nonce);
        _transfer(from, to, value);
    }

    /// @notice Attempt to cancel an authorization
    /// @param authorizer    Authorizer's address
    /// @param nonce         Nonce of the authorization
    /// @param v             v of the signature
    /// @param r             r of the signature
    /// @param s             s of the signature
    function _cancelAuthorization(
        address authorizer,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        _requireUnusedAuthorization(authorizer, nonce);

        bytes memory data =
            abi.encode(CANCEL_AUTHORIZATION_TYPEHASH, authorizer, nonce);
        require(
            EIP712.recover(DOMAIN_SEPARATOR, v, r, s, data) == authorizer,
            "Efinity Token: invalid signature"
        );

        _authorizationStates[authorizer][nonce] = true;
        emit AuthorizationCanceled(authorizer, nonce);
    }

    /// @notice Check that an authorization is unused
    /// @param authorizer    Authorizer's address
    /// @param nonce         Nonce of the authorization
    function _requireUnusedAuthorization(address authorizer, bytes32 nonce)
        private
        view
    {
        require(
            !_authorizationStates[authorizer][nonce],
            "Efinity Token: authorization is used or canceled"
        );
    }

    /// @notice Check that authorization is valid
    /// @param authorizer    Authorizer's address
    /// @param nonce         Nonce of the authorization
    /// @param validAfter    The time after which this is valid (unix time)
    /// @param validBefore   The time before which this is valid (unix time)
    function _requireValidAuthorization(
        address authorizer,
        bytes32 nonce,
        uint256 validAfter,
        uint256 validBefore
    ) private view {
        require(
            block.timestamp > validAfter,
            "Efinity Token: authorization is not yet valid"
        );
        require(
            block.timestamp < validBefore,
            "Efinity Token: authorization is expired"
        );
        _requireUnusedAuthorization(authorizer, nonce);
    }

    /// @notice Mark an authorization as used
    /// @param authorizer    Authorizer's address
    /// @param nonce         Nonce of the authorization
    function _markAuthorizationAsUsed(address authorizer, bytes32 nonce)
        private
    {
        _authorizationStates[authorizer][nonce] = true;
        emit AuthorizationUsed(authorizer, nonce);
    }
}

//SPDX-License-Identifier: Apache License Version 2.0
pragma solidity =0.8.4;

import {AbstractEFIMethods} from "./AbstractEFIMethods.sol";
import {EIP712Domain} from "./EIP712Domain.sol";
import {EIP712} from "../utils/EIP712.sol";

/// @title EIP-2612
/// @notice Provide internal implementation for gas-abstracted approvals
abstract contract EIP2612 is AbstractEFIMethods, EIP712Domain {
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    mapping(address => uint256) private _permitNonces;

    /// @notice Nonces for permit
    /// @param owner Token owner's address (Authorizer)
    /// @return Next nonce
    function nonces(address owner) external view returns (uint256) {
        return _permitNonces[owner];
    }

    /// @notice Verify a signed approval permit and execute if valid
    /// @param owner     Token owner's address (Authorizer)
    /// @param spender   Spender's address
    /// @param value     Amount of allowance
    /// @param deadline  The time at which this expires (unix time)
    /// @param v         v of the signature
    /// @param r         r of the signature
    /// @param s         s of the signature
    function _permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        require(
            deadline >= block.timestamp,
            "Efinity Token: permit is expired"
        );

        bytes memory data =
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                _permitNonces[owner],
                deadline
            );
        require(
            EIP712.recover(DOMAIN_SEPARATOR, v, r, s, data) == owner,
            "Efinity Token: invalid signature"
        );

        _permitNonces[owner]++;

        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../interfaces/IERC20Receiver.sol";
import "./AbstractEFIMethods.sol";

/// @dev Implementation of the {IERC20} interface.
/// This implementation is agnostic to the way tokens are created. This means
/// that a supply mechanism has to be added in a derived contract using {_mint}.
/// For a generic mechanism see {ERC20PresetMinterPauser}.
/// TIP: For a detailed writeup see our guide
/// https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
/// to implement supply mechanisms].
/// We have followed general OpenZeppelin guidelines: functions revert instead
/// of returning `false` on failure. This behavior is nonetheless conventional
/// and does not conflict with the expectations of ERC20 applications.
/// Additionally, an {Approval} event is emitted on calls to {transferFrom}.
/// This allows applications to reconstruct the allowance for all accounts just
/// by listening to said events. Other implementations of the EIP may not emit
/// these events, as it isn't required by the specification.
/// Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
/// functions have been added to mitigate the well-known issues around setting
/// allowances. See {IERC20-approve}.
contract ERC20UpgradeableV2 is
    Initializable,
    ContextUpgradeable,
    IERC20Upgradeable,
    IERC20MetadataUpgradeable,
    AbstractEFIMethods
{
    using AddressUpgradeable for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /// @dev Sets the values for {name} and {symbol}.
    /// The default value of {decimals} is 18. To select a different value for
    /// {decimals} you should overload it.
    /// All two of these values are immutable: they can only be set once during
    /// construction.
    function __ERC20_init(string memory name_, string memory symbol_)
        internal
        initializer
    {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_)
        internal
        initializer
    {
        _name = name_;
        _symbol = symbol_;
    }

    /// @dev Returns the name of the token.
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /// @dev Returns the symbol of the token, usually a shorter version of the
    /// name.
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /// @dev Returns the number of decimals used to get its user representation.
    /// For example, if `decimals` equals `2`, a balance of `505` tokens should
    /// be displayed to a user as `5,05` (`505 / 1 2`).
    /// Tokens usually opt for a value of 18, imitating the relationship between
    /// Ether and Wei. This is the value {ERC20} uses, unless this function is
    /// overridden;
    /// NOTE: This information is only used for _display_ purposes: it in
    /// no way affects any of the arithmetic of the contract, including
    /// {IERC20-balanceOf} and {IERC20-transfer}.
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /// @dev See {IERC20-totalSupply}.
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /// @dev See {IERC20-balanceOf}.
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /// @dev See {IERC20-transfer}.
    /// Requirements:
    /// - `recipient` cannot be the zero address.
    /// - the caller must have a balance of at least `amount`.
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /// @dev See {IERC20-allowance}.
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /// @dev See {IERC20-approve}.
    /// Requirements:
    /// - `spender` cannot be the zero address.
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /// @dev See {IERC20-transferFrom}.
    /// Emits an {Approval} event indicating the updated allowance. This is not
    /// required by the EIP. See the note at the beginning of {ERC20}.
    /// Requirements:
    /// - `sender` and `recipient` cannot be the zero address.
    /// - `sender` must have a balance of at least `amount`.
    /// - the caller must have allowance for ``sender``'s tokens of at least
    /// `amount`.
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "Efinity Token: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /// @dev Atomically increases the allowance granted to `spender` by the caller.
    /// This is an alternative to {approve} that can be used as a mitigation for
    /// problems described in {IERC20-approve}.
    /// Emits an {Approval} event indicating the updated allowance.
    /// Requirements:
    /// - `spender` cannot be the zero address.
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    /// @dev Atomically decreases the allowance granted to `spender` by the caller.
    /// This is an alternative to {approve} that can be used as a mitigation for
    /// problems described in {IERC20-approve}.
    /// Emits an {Approval} event indicating the updated allowance.
    /// Requirements:
    /// - `spender` cannot be the zero address.
    /// - `spender` must have allowance for the caller of at least
    /// `subtractedValue`.
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "Efinity Token: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /// @dev Moves tokens `amount` from `sender` to `recipient`.
    /// This is internal function is equivalent to {transfer}, and can be used to
    /// e.g. implement automatic token fees, slashing mechanisms, etc.
    /// Emits a {Transfer} event.
    /// Requirements:
    /// - `sender` cannot be the zero address.
    /// - `recipient` cannot be the zero address.
    /// - `sender` must have a balance of at least `amount`.
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(
            sender != address(0),
            "Efinity Token: transfer from the zero address"
        );
        require(
            recipient != address(0),
            "Efinity Token: transfer to the zero address"
        );

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "Efinity Token: transfer amount exceeds balance"
        );
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /// @dev Moves tokens as per respective amount from `sender` to corresponding recipient.
    /// This is internal function is equivalent to {bulkTransfer}
    /// Emits {Transfer} events for each transfer.
    /// Requirements:
    /// - `sender` cannot be the zero address.
    /// - each `recipient` cannot be the zero address.
    /// - `sender` must have a balance of at least total amount being transferred.
    function _bulkTransfer(
        address sender,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) internal virtual returns (uint256 totalAmount) {
        uint256 length = recipients.length;

        require(
            sender != address(0),
            "Efinity Token: transfer from the zero address"
        );
        require(length == amounts.length, "Efinity Token: unequal length");

        for (uint256 index = 0; index < length; index++) {
            require(
                recipients[index] != address(0),
                "Efinity Token: transfer to the zero address"
            );

            totalAmount += amounts[index];
            _balances[recipients[index]] += amounts[index];
            emit Transfer(sender, recipients[index], amounts[index]);
        }

        _updateSenderBalance(sender, totalAmount);
    }

    /// @dev Moves tokens as per respective amount from `sender` to corresponding recipient with required data.
    /// This is internal function is equivalent to {safeBulkTransfer}
    /// Emits {Transfer} events for each transfer.
    /// Requirements:
    /// - `sender` cannot be the zero address.
    /// - each `recipient` cannot be the zero address.
    /// - `sender` must have a balance of at least total amount being transferred.
    function _safeBulkTransfer(
        address sender,
        address operator,
        address[] calldata recipients,
        uint256[] calldata amounts,
        bytes[] calldata data
    ) internal virtual returns (uint256 totalAmount) {
        uint256 length = recipients.length;

        require(
            sender != address(0),
            "Efinity Token: transfer from the zero address"
        );
        require(
            length == amounts.length && length == data.length,
            "Efinity Token: unequal length"
        );
        for (uint256 index = 0; index < length; index++) {
            require(
                recipients[index] != address(0),
                "Efinity Token: transfer to the zero address"
            );

            totalAmount += amounts[index];
            _balances[recipients[index]] += amounts[index];
            emit Transfer(sender, recipients[index], amounts[index]);

            _doSafeTransferAcceptanceCheck(
                operator,
                sender,
                recipients[index],
                amounts[index],
                data[index]
            );
        }

        _updateSenderBalance(sender, totalAmount);
    }

    /// @dev Creates `amount` tokens and assigns them to `account`, increasing
    /// the total supply.
    /// Emits a {Transfer} event with `from` set to the zero address.
    /// Requirements:
    /// - `account` cannot be the zero address.
    function _mint(address account, uint256 amount) internal virtual {
        require(
            account != address(0),
            "Efinity Token: mint to the zero address"
        );

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /// @dev Destroys `amount` tokens from `account`, reducing the
    /// total supply.
    /// Emits a {Transfer} event with `to` set to the zero address.
    /// Requirements:
    /// - `account` cannot be the zero address.
    /// - `account` must have at least `amount` tokens.
    function _burn(address account, uint256 amount) internal virtual {
        require(
            account != address(0),
            "Efinity Token: burn from the zero address"
        );

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(
            accountBalance >= amount,
            "Efinity Token: burn amount exceeds balance"
        );
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /// @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
    /// This internal function is equivalent to `approve`, and can be used to
    /// e.g. set automatic allowances for certain subsystems, etc.
    /// Emits an {Approval} event.
    /// Requirements:
    /// - `owner` cannot be the zero address.
    /// - `spender` cannot be the zero address.
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual override {
        require(
            owner != address(0),
            "Efinity Token: approve from the zero address"
        );
        require(
            spender != address(0),
            "Efinity Token: approve to the zero address"
        );

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// @dev Check that recipient contract account implements onERC20Received
    /// @param operator the msg.sender
    /// @param from transfer from account
    /// @param to transfer to account
    /// @param amount number of tokens to transfer
    /// @param data arbitrary data for the recipient
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (to.isContract()) {
            try
                IERC20Receiver(to).onERC20Received(operator, from, amount, data)
            returns (bytes4 response) {
                if (response != IERC20Receiver(to).onERC20Received.selector) {
                    revert("Efinity Token: ERC20Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert(
                    "Efinity Token: transfer to non ERC20Receiver implementer"
                );
            }
        }
    }

    /// @dev Helper function updating sender balance during bulk updates
    function _updateSenderBalance(address sender, uint256 totalAmount) private {
        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= totalAmount,
            "Efinity Token: transfer amounts exceeds balance"
        );
        _balances[sender] = senderBalance - totalAmount;
    }

    /// @dev Hook that is called before any transfer of tokens. This includes
    /// minting and burning.
    /// Calling conditions:
    /// - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
    /// will be to transferred to `to`.
    /// - when `from` is zero, `amount` tokens will be minted for `to`.
    /// - when `to` is zero, `amount` of ``from``'s tokens will be burned.
    /// - `from` and `to` are never both zero.
    /// To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

//SPDX-License-Identifier: Apache License Version 2.0
pragma solidity =0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IERC20Receiver is IERC165 {
    /// @dev Handles the receipt of a single ERC20 token type. This function is
    /// called at the end of a `safeTransferFrom` after the balance has been updated.
    /// To accept the transfer, this must return
    /// `bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"))`
    /// (i.e. its own function selector).
    /// @param operator The address which initiated the transfer (i.e. msg.sender)
    /// @param from The address which previously owned the token
    /// @param value The amount of tokens being transferred
    /// @param data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"))` if transfer is allowed
    function onERC20Received(
        address operator,
        address from,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
}

//SPDX-License-Identifier: Apache License Version 2.0
pragma solidity =0.8.4;

abstract contract AbstractEFIMethods {
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal virtual;

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
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

//SPDX-License-Identifier: Apache License Version 2.0
pragma solidity =0.8.4;

/// @title ECRecover
/// @notice A library that provides a safe ECDSA recovery function
library ECRecover {
    /// @notice Recover signer's address from a signed message
    /// @dev Adapted from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/65e4ffde586ec89af3b7e9140bdc9235d1254853/contracts/cryptography/ECDSA.sol
    /// Modifications: Accept v, r, and s as separate arguments
    /// @param digest    Keccak-256 hash digest of the signed message
    /// @param v         v of the signature
    /// @param r         r of the signature
    /// @param s         s of the signature
    /// @return Signer address
    function recover(
        bytes32 digest,
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
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert("ECRecover: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECRecover: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(digest, v, r, s);
        require(signer != address(0), "ECRecover: invalid signature");

        return signer;
    }
}

{
  "optimizer": {
    "enabled": true,
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}