// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../iface/ILoopringWalletV2.sol";

import "../lib/EIP712.sol";
import "../lib/ERC20.sol";
import "../lib/ERC1271.sol";
import "../lib/ReentrancyGuard.sol";
import "../thirdparty/erc165/IERC165.sol";
import "../thirdparty/erc1155/ERC1155Holder.sol";
import "../thirdparty/erc721/ERC721Holder.sol";

import "./libwallet/ERC20Lib.sol";
import "./libwallet/ERC1271Lib.sol";
import "./libwallet/WalletData.sol";
import "./libwallet/LockLib.sol";
import "./libwallet/GuardianLib.sol";
import "./libwallet/InheritanceLib.sol";
import "./libwallet/MetaTxLib.sol";
import "./libwallet/WhitelistLib.sol";
import "./libwallet/QuotaLib.sol";
import "./libwallet/RecoverLib.sol";
import "./libwallet/UpgradeLib.sol";


/// @title SmartWallet
/// @dev Main smart wallet contract
/// @author Brecht Devos - <[email protected]>
contract SmartWallet is ILoopringWalletV2, ERC1271, IERC165, ERC721Holder, ERC1155Holder
{
    using ERC20Lib          for Wallet;
    using ERC1271Lib        for Wallet;
    using LockLib           for Wallet;
    using GuardianLib       for Wallet;
    using InheritanceLib    for Wallet;
    using MetaTxLib         for Wallet;
    using WhitelistLib      for Wallet;
    using QuotaLib          for Wallet;
    using RecoverLib        for Wallet;
    using UpgradeLib        for Wallet;

    bytes32     public immutable DOMAIN_SEPARATOR;
    PriceOracle public immutable priceOracle;
    address     public immutable blankOwner;

    // WARNING: Do not delete wallet state data to make this implementation
    // compatible with early versions.
    //
    //  ----- DATA LAYOUT BEGINS -----
    // Always needs to be first
    address internal masterCopy;

    bool internal isImplementationContract;

    Wallet public wallet;
    //  ----- DATA LAYOUT ENDS -----

    /// @dev We need to make sure the implemenation contract cannot be initialized
    ///      and used to do delegate calls to arbitrary contracts.
    modifier disableInImplementationContract
    {
        require(!isImplementationContract, "DISALLOWED_ON_IMPLEMENTATION_CONTRACT");
        _;
    }

    modifier onlyFromWalletOrOwnerWhenUnlocked()
    {
        // If the wallet's signature verfication passes, the wallet must be unlocked.
        require(
            msg.sender == address(this) ||
            (msg.sender == wallet.owner && !wallet.locked),
             "NOT_FROM_WALLET_OR_OWNER_OR_WALLET_LOCKED"
        );
        wallet.touchLastActiveWhenRequired();
        _;
    }

    modifier canTransferOwnership()
    {
        require(
            msg.sender == blankOwner &&
            wallet.owner == blankOwner,
            "NOT_ALLOWED_TO_SET_OWNER"
        );
        _;
    }

    constructor(
        PriceOracle _priceOracle,
        address     _blankOwner
        )
    {
        isImplementationContract = true;

        DOMAIN_SEPARATOR = EIP712.hash(
            EIP712.Domain("LoopringWallet", "2.0.0", address(this))
        );

        priceOracle = _priceOracle;
        blankOwner = _blankOwner;
    }

    /// @dev Set up this wallet.
    ///
    ///      Note that calling this method more than once will throw.
    ///
    /// @param owner The owner of this wallet, must not be address(0).
    /// @param guardians The guardians of this wallet.
    function initialize(
        address             owner,
        address[] calldata  guardians,
        uint                quota,
        address             inheritor,
        address             feeRecipient,
        address             feeToken,
        uint                feeAmount
        )
        external
        override
        disableInImplementationContract
    {
        require(wallet.owner == address(0), "INITIALIZED_ALREADY");
        require(owner != address(0), "INVALID_OWNER");

        wallet.owner = owner;
        wallet.creationTimestamp = uint64(block.timestamp);
        wallet.addGuardiansImmediately(guardians);

        if (quota != 0) {
            wallet.setQuota(quota, 0);
        }

        if (inheritor != address(0)) {
            wallet.setInheritor(inheritor, 365 days);
        }

        // Pay for the wallet creation using wallet funds
        if (feeRecipient != address(0) && feeAmount > 0) {
            ERC20Lib.transfer(feeToken, feeRecipient, feeAmount);
        }
    }

    receive()
        external
        payable
    {
    }

    function getOwner()
        public
        view
        override
        returns (address)
    {
        return wallet.owner;
    }

    function getCreationTimestamp()
        public
        view
        override
        returns (uint64)
    {
        return wallet.creationTimestamp;
    }

    //
    // Owner
    //
    function transferOwnership(
        address _owner
        )
        external
        canTransferOwnership
    {
        require(_owner != address(0), "INVALID_OWNER");
        wallet.owner = _owner;
    }

    //
    // ERC1271
    //
    function isValidSignature(
        bytes32      signHash,
        bytes memory signature
        )
        public
        view
        override
        returns (bytes4 magicValue)
    {
        return wallet.isValidSignature(
            ERC1271_MAGICVALUE,
            signHash,
            signature
        );
    }

    //
    // Upgrade
    //

    function changeMasterCopy(
        Approval calldata approval,
        address           newMasterCopy
        )
        external
        returns (bytes32 approvedHash)
    {
        approvedHash = wallet.changeMasterCopy(
            DOMAIN_SEPARATOR,
            approval,
            newMasterCopy
        );
        masterCopy = newMasterCopy;
    }

    function getMasterCopy()
        public
        view
        returns (address)
    {
        return masterCopy;
    }

    //
    // Guardians
    //

    function addGuardian(
        address guardian
        )
        external
        onlyFromWalletOrOwnerWhenUnlocked
    {
        wallet.addGuardian(guardian);
    }

    function addGuardianWA(
        Approval calldata approval,
        address           guardian
        )
        external
        returns (bytes32 approvedHash)
    {
        approvedHash = wallet.addGuardianWA(DOMAIN_SEPARATOR, approval, guardian);
    }

    function removeGuardian(
        address guardian
        )
        external
        onlyFromWalletOrOwnerWhenUnlocked
    {
        wallet.removeGuardian(guardian);
    }

     function removeGuardianWA(
        Approval calldata approval,
        address           guardian
        )
        external
        returns (bytes32 approvedHash)
    {
        approvedHash = wallet.removeGuardianWA(DOMAIN_SEPARATOR, approval, guardian);
    }

     function resetGuardians(
         address[] calldata newGuardians
         )
         external
         onlyFromWalletOrOwnerWhenUnlocked
     {
         wallet.resetGuardians(newGuardians);
     }

     function resetGuardiansWA(
         Approval  calldata approval,
         address[] calldata newGuardians
         )
         external
         returns (bytes32 approvedHash)
     {
         approvedHash = wallet.resetGuardiansWA(DOMAIN_SEPARATOR, approval, newGuardians);
     }

     function isGuardian(address addr, bool includePendingAddition)
         public
         view
         returns (bool)
     {
         return wallet.isGuardian(addr, includePendingAddition);
     }

     function getGuardians(bool includePendingAddition)
         public
         view
         returns (Guardian[] memory )
     {
         return GuardianLib.guardians(wallet, includePendingAddition);
     }

    //
    // Inheritance
    //

    function setInheritor(
        address inheritor,
        uint32  waitingPeriod
        )
        external
        onlyFromWalletOrOwnerWhenUnlocked
    {
        wallet.setInheritor(inheritor, waitingPeriod);
    }

    function inherit(
        address newOwner
        )
        external
    {
        wallet.inherit(newOwner);
    }

    //
    // Lock
    //

    function lock()
        external
    {
        wallet.lock();
    }

    function unlock(
        Approval calldata approval
        )
        external
        returns (bytes32 approvedHash)
    {
        approvedHash = wallet.unlock(DOMAIN_SEPARATOR, approval);
    }

    //
    // Quota
    //

    function changeDailyQuota(
        uint newQuota
        )
        external
        onlyFromWalletOrOwnerWhenUnlocked
    {
        wallet.changeDailyQuota(newQuota);
    }

    function changeDailyQuotaWA(
        Approval calldata approval,
        uint              newQuota
        )
        external
        returns (bytes32 approvedHash)
    {
        approvedHash = wallet.changeDailyQuotaWA(DOMAIN_SEPARATOR, approval, newQuota);
    }

    //
    // MetaTx
    //

    function executeMetaTx(
        address to,
        uint    nonce,
        address gasToken,
        uint    gasPrice,
        uint    gasLimit,
        uint    gasOverhead,
        address feeRecipient,
        bool    requiresSuccess,
        bytes   calldata data,
        bytes   memory   signature
        )
        external
        returns (bool)
    {
        MetaTxLib.MetaTx memory metaTx = MetaTxLib.MetaTx(
            to,
            nonce,
            gasToken,
            gasPrice,
            gasLimit,
            gasOverhead,
            feeRecipient,
            requiresSuccess,
            data,
            signature
        );

        return wallet.executeMetaTx(
            DOMAIN_SEPARATOR,
            priceOracle,
            metaTx
        );
    }

    function batchCall(
        address[] calldata to,
        bytes[]   calldata data
        )
        external
        onlyFromWalletOrOwnerWhenUnlocked
    {
        wallet.batchCall(to, data);
    }

    //
    // Recover
    //

    function recover(
        Approval calldata  approval,
        address            newOwner,
        address[] calldata newGuardians
        )
        external
        returns (bytes32 approvedHash)
    {
        approvedHash = wallet.recover(
            DOMAIN_SEPARATOR,
            approval,
            newOwner,
            newGuardians
        );
    }

    //
    // Whitelist
    //

    function addToWhitelist(
        address addr
        )
        external
        onlyFromWalletOrOwnerWhenUnlocked
    {
        wallet.addToWhitelist(addr);
    }

    function addToWhitelistWA(
        Approval calldata approval,
        address           addr
        )
        external
        returns (bytes32 approvedHash)
    {
        approvedHash = wallet.addToWhitelistWA(
            DOMAIN_SEPARATOR,
            approval,
            addr
        );
    }

    function removeFromWhitelist(
        address addr
        )
        external
        onlyFromWalletOrOwnerWhenUnlocked
    {
        wallet.removeFromWhitelist(addr);
    }

    function getWhitelistEffectiveTime(
        address addr
        )
        public
        view
        returns (uint)
    {
        return wallet.whitelisted[addr];
    }

    function isWhitelisted(
        address addr
        )
        public
        view
        returns (bool) {
        return wallet.isAddressWhitelisted(addr);
    }

    //
    // ERC20
    //

    function transferToken(
        address        token,
        address        to,
        uint           amount,
        bytes calldata logdata,
        bool           forceUseQuota
        )
        external
        onlyFromWalletOrOwnerWhenUnlocked
    {
        wallet.transferToken(
            priceOracle,
            token,
            to,
            amount,
            logdata,
            forceUseQuota
        );
    }

    function transferTokenWA(
        Approval calldata approval,
        address           token,
        address           to,
        uint              amount,
        bytes    calldata logdata
        )
        external
        returns (bytes32 approvedHash)
    {
        approvedHash = wallet.transferTokenWA(
            DOMAIN_SEPARATOR,
            approval,
            token,
            to,
            amount,
            logdata
        );
    }

    function callContract(
        address          to,
        uint             value,
        bytes   calldata data,
        bool             forceUseQuota
        )
        external
        onlyFromWalletOrOwnerWhenUnlocked
        returns (bytes memory)
    {
        return wallet.callContract(
            priceOracle,
            to,
            value,
            data,
            forceUseQuota
        );
    }

    function callContractWA(
        Approval calldata approval,
        address           to,
        uint              value,
        bytes    calldata data
        )
        external
        returns (bytes32 approvedHash, bytes memory returnData)
    {
        (approvedHash, returnData) = wallet.callContractWA(
            DOMAIN_SEPARATOR,
            approval,
            to,
            value,
            data
        );
    }

    function approveToken(
        address token,
        address to,
        uint    amount,
        bool    forceUseQuota
        )
        external
        onlyFromWalletOrOwnerWhenUnlocked
    {
        wallet.approveToken(
            priceOracle,
            token,
            to,
            amount,
            forceUseQuota
        );
    }

    function approveTokenWA(
        Approval calldata approval,
        address           token,
        address           to,
        uint              amount
        )
        external
        returns (bytes32 approvedHash)
    {
        approvedHash = wallet.approveTokenWA(
            DOMAIN_SEPARATOR,
            approval,
            token,
            to,
            amount
        );
    }

    function approveThenCallContract(
        address          token,
        address          to,
        uint             amount,
        uint             value,
        bytes   calldata data,
        bool             forceUseQuota
        )
        external
        onlyFromWalletOrOwnerWhenUnlocked
        returns (bytes memory)
    {
        return wallet.approveThenCallContract(
            priceOracle,
            token,
            to,
            amount,
            value,
            data,
            forceUseQuota
        );
    }

    function approveThenCallContractWA(
        Approval calldata approval,
        address           token,
        address           to,
        uint              amount,
        uint              value,
        bytes    calldata data
        )
        external
        returns (bytes32 approvedHash, bytes memory returnData)
    {
        (approvedHash, returnData) = wallet.approveThenCallContractWA(
            DOMAIN_SEPARATOR,
            approval,
            token,
            to,
            amount,
            value,
            data
        );
    }

    // ERC165
    function supportsInterface(
        bytes4 interfaceId
        )
        external
        pure
        override
        returns (bool)
    {
        return  interfaceId == type(ERC1271).interfaceId ||
                interfaceId == type(IERC165).interfaceId ||
                interfaceId == type(IERC721Receiver).interfaceId ||
                interfaceId == type(IERC1155Receiver).interfaceId;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;


/// @title Loopring SmartWallet V2 interface
/// @author Brecht Devos - <[email protected]>
abstract contract ILoopringWalletV2
{
    /// @dev Initializes the smart wallet.
    /// @param owner The wallet owner address.
    /// @param guardians The initial wallet guardians.
    /// @param quota The initial wallet quota.
    /// @param inheritor The inheritor of the wallet.
    /// @param feeRecipient The address receiving the fee for creating the wallet.
    /// @param feeToken The token to use for the fee payment.
    /// @param feeAmount The amount of tokens paid to the fee recipient.
    function initialize(
        address             owner,
        address[] calldata  guardians,
        uint                quota,
        address             inheritor,
        address             feeRecipient,
        address             feeToken,
        uint                feeAmount
        )
        external
        virtual;

    /// @dev Returns the timestamp the wallet was created.
    /// @return The timestamp the wallet was created.
    function getCreationTimestamp()
        public
        view
        virtual
        returns (uint64);

    /// @dev Returns the current wallet owner.
    /// @return The current wallet owner.
    function getOwner()
        public
        view
        virtual
        returns (address);
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


library EIP712
{
    struct Domain {
        string  name;
        string  version;
        address verifyingContract;
    }

    bytes32 constant internal EIP712_DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    string constant internal EIP191_HEADER = "\x19\x01";

    function hash(Domain memory domain)
        internal
        pure
        returns (bytes32)
    {
        uint _chainid;
        assembly { _chainid := chainid() }

        return keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(domain.name)),
                keccak256(bytes(domain.version)),
                _chainid,
                domain.verifyingContract
            )
        );
    }

    function hashPacked(
        bytes32 domainSeparator,
        bytes32 dataHash
        )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                EIP191_HEADER,
                domainSeparator,
                dataHash
            )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;


/// @title ERC20 Token Interface
/// @dev see https://github.com/ethereum/EIPs/issues/20
/// @author Daniel Wang - <[email protected]>
abstract contract ERC20
{
    function totalSupply()
        public
        view
        virtual
        returns (uint);

    function balanceOf(
        address who
        )
        public
        view
        virtual
        returns (uint);

    function allowance(
        address owner,
        address spender
        )
        public
        view
        virtual
        returns (uint);

    function transfer(
        address to,
        uint value
        )
        public
        virtual
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint    value
        )
        public
        virtual
        returns (bool);

    function approve(
        address spender,
        uint    value
        )
        public
        virtual
        returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

abstract contract ERC1271 {
    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 constant internal ERC1271_MAGICVALUE = 0x1626ba7e;

    function isValidSignature(
        bytes32      _hash,
        bytes memory _signature)
        public
        view
        virtual
        returns (bytes4 magicValue);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;


/// @title ReentrancyGuard
/// @author Brecht Devos - <[email protected]>
/// @dev Exposes a modifier that guards a function against reentrancy
///      Changing the value of the same storage value multiple times in a transaction
///      is cheap (starting from Istanbul) so there is no need to minimize
///      the number of times the value is changed
contract ReentrancyGuard
{
    //The default value must be 0 in order to work behind a proxy.
    uint private _guardValue;

    modifier nonReentrant()
    {
        require(_guardValue == 0, "REENTRANCY");
        _guardValue = 1;
        _;
        _guardValue = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is IERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC721Receiver.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers.
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../thirdparty/SafeERC20.sol";
import "../../lib/ERC20.sol";
import "../../lib/MathUint.sol";
import "../../lib/AddressUtil.sol";
import "../../iface/PriceOracle.sol";
import "./WhitelistLib.sol";
import "./QuotaLib.sol";
import "./ApprovalLib.sol";


/// @title ERC20Lib
/// @author Brecht Devos - <[email protected]>
/// @author Daniel Wang - <[email protected]>
library ERC20Lib
{
    using AddressUtil   for address;
    using MathUint      for uint;
    using WhitelistLib  for Wallet;
    using QuotaLib      for Wallet;
    using ApprovalLib   for Wallet;
    using SafeERC20     for ERC20;

    event Transfered     (address token, address to,      uint amount, bytes logdata);
    event Approved       (address token, address spender, uint amount);
    event ContractCalled (address to,    uint    value,   bytes data);

    bytes32 public constant TRANSFER_TOKEN_TYPEHASH = keccak256(
        "transferToken(address wallet,uint256 validUntil,address token,address to,uint256 amount,bytes logdata)"
    );
    bytes32 public constant APPROVE_TOKEN_TYPEHASH = keccak256(
        "approveToken(address wallet,uint256 validUntil,address token,address to,uint256 amount)"
    );
    bytes32 public constant CALL_CONTRACT_TYPEHASH = keccak256(
        "callContract(address wallet,uint256 validUntil,address to,uint256 value,bytes data)"
    );
    bytes32 public constant APPROVE_THEN_CALL_CONTRACT_TYPEHASH = keccak256(
        "approveThenCallContract(address wallet,uint256 validUntil,address token,address to,uint256 amount,uint256 value,bytes data)"
    );

    function transferToken(
        Wallet storage wallet,
        PriceOracle    priceOracle,
        address        token,
        address        to,
        uint           amount,
        bytes calldata logdata,
        bool           forceUseQuota
        )
        external
    {
        if (forceUseQuota || !wallet.isAddressWhitelisted(to)) {
            wallet.checkAndAddToSpent(priceOracle, token, amount);
        }
        _transferWithEvent(token, to, amount, logdata);
    }

    function transferTokenWA(
        Wallet   storage  wallet,
        bytes32           domainSeparator,
        Approval calldata approval,
        address           token,
        address           to,
        uint              amount,
        bytes    calldata logdata
        )
        external
        returns (bytes32 approvedHash)
    {
        approvedHash = wallet.verifyApproval(
            domainSeparator,
            SigRequirement.MAJORITY_OWNER_REQUIRED,
            approval,
            abi.encode(
                TRANSFER_TOKEN_TYPEHASH,
                approval.wallet,
                approval.validUntil,
                token,
                to,
                amount,
                keccak256(logdata)
            )
        );

        _transferWithEvent(token, to, amount, logdata);
    }

    function callContract(
        Wallet  storage  wallet,
        PriceOracle      priceOracle,
        address          to,
        uint             value,
        bytes   calldata data,
        bool             forceUseQuota
        )
        external
        returns (bytes memory returnData)
    {
        if (forceUseQuota || !wallet.isAddressWhitelisted(to)) {
            wallet.checkAndAddToSpent(priceOracle, address(0), value);
        }

        return _callContractInternal(to, value, data, priceOracle);
    }

    function callContractWA(
        Wallet   storage  wallet,
        bytes32           domainSeparator,
        Approval calldata approval,
        address           to,
        uint              value,
        bytes    calldata data
        )
        external
        returns (bytes32 approvedHash, bytes memory returnData)
    {
        approvedHash = wallet.verifyApproval(
            domainSeparator,
            SigRequirement.MAJORITY_OWNER_REQUIRED,
            approval,
            abi.encode(
                CALL_CONTRACT_TYPEHASH,
                approval.wallet,
                approval.validUntil,
                to,
                value,
                keccak256(data)
            )
        );

        returnData = _callContractInternal(to, value, data, PriceOracle(0));
    }

    function approveToken(
        Wallet      storage wallet,
        PriceOracle         priceOracle,
        address             token,
        address             to,
        uint                amount,
        bool                forceUseQuota
        )
        external
    {
        uint additionalAllowance = _approveInternal(token, to, amount);

        if (forceUseQuota || !wallet.isAddressWhitelisted(to)) {
            wallet.checkAndAddToSpent(priceOracle, token, additionalAllowance);
        }
    }

    function approveTokenWA(
        Wallet   storage  wallet,
        bytes32           domainSeparator,
        Approval calldata approval,
        address           token,
        address           to,
        uint              amount
        )
        external
        returns (bytes32 approvedHash)
    {
        approvedHash = wallet.verifyApproval(
            domainSeparator,
            SigRequirement.MAJORITY_OWNER_REQUIRED,
            approval,
            abi.encode(
                APPROVE_TOKEN_TYPEHASH,
                approval.wallet,
                approval.validUntil,
                token,
                to,
                amount
            )
        );

        _approveInternal(token, to, amount);
    }

    function approveThenCallContract(
        Wallet  storage  wallet,
        PriceOracle      priceOracle,
        address          token,
        address          to,
        uint             amount,
        uint             value,
        bytes   calldata data,
        bool             forceUseQuota
        )
        external
        returns (bytes memory returnData)
    {
        uint additionalAllowance = _approveInternal(token, to, amount);

        if (forceUseQuota || !wallet.isAddressWhitelisted(to)) {
            wallet.checkAndAddToSpent(priceOracle, token, additionalAllowance);
            wallet.checkAndAddToSpent(priceOracle, address(0), value);
        }

        return _callContractInternal(to, value, data, priceOracle);
    }

    function approveThenCallContractWA(
        Wallet   storage  wallet,
        bytes32           domainSeparator,
        Approval calldata approval,
        address           token,
        address           to,
        uint              amount,
        uint              value,
        bytes    calldata data
        )
        external
        returns (bytes32 approvedHash, bytes memory returnData)
    {
        approvedHash = wallet.verifyApproval(
            domainSeparator,
            SigRequirement.MAJORITY_OWNER_REQUIRED,
            approval,
            abi.encode(
                APPROVE_THEN_CALL_CONTRACT_TYPEHASH,
                approval.wallet,
                approval.validUntil,
                token,
                to,
                amount,
                value,
                keccak256(data)
            )
        );

        _approveInternal(token, to, amount);
        returnData = _callContractInternal(to, value, data, PriceOracle(0));
    }

    function transfer(
        address token,
        address to,
        uint    amount
        )
        public
    {
        if (token == address(0)) {
            to.sendETHAndVerify(amount, gasleft());
        } else {
            ERC20(token).safeTransfer(to, amount);
        }
    }

    // --- Internal functions ---

    function _transferWithEvent(
        address token,
        address to,
        uint    amount,
        bytes   calldata logdata
        )
        private
    {
        transfer(token, to, amount);
        emit Transfered(token, to, amount, logdata);
    }

    function _approveInternal(
        address token,
        address spender,
        uint    amount
        )
        private
        returns (uint additionalAllowance)
    {
        // Current allowance
        uint allowance = ERC20(token).allowance(address(this), spender);

        if (amount != allowance) {
            // First reset the approved amount if needed
            if (allowance > 0) {
                ERC20(token).safeApprove(spender, 0);
            }
            // Now approve the requested amount
            ERC20(token).safeApprove(spender, amount);
        }

        // If we increased the allowance, calculate by how much
        if (amount > allowance) {
            additionalAllowance = amount.sub(allowance);
        }
        emit Approved(token, spender, amount);
    }

    function _callContractInternal(
        address              to,
        uint                 value,
        bytes       calldata txData,
        PriceOracle          priceOracle
        )
        private
        returns (bytes memory returnData)
    {
        require(to != address(this), "SELF_CALL_DISALLOWED");

        if (priceOracle != PriceOracle(0)) {
            // Disallow general calls to token contracts (for tokens that have price data
            // so the quota is actually used).
            require(priceOracle.tokenValue(to, 1e18) == 0, "CALL_DISALLOWED");
        }

        bool success;
        (success, returnData) = to.call{value: value}(txData);
        require(success, "CALL_FAILED");

        emit ContractCalled(to, value, txData);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../lib/SignatureUtil.sol";
import "./WalletData.sol";


/// @title ERC1271Lib
/// @author Brecht Devos - <[email protected]>
library ERC1271Lib
{
    using SignatureUtil     for bytes32;

    // Note that we allow chained wallet ownership:
    // Wallet1 owned by Wallet2, Wallet2 owned by Wallet3, ..., WaleltN owned by an EOA.
    // The verificaiton of Wallet1's signature will succeed if the final EOA's signature is
    // valid.
    function isValidSignature(
        Wallet storage wallet,
        bytes4         ERC1271_MAGICVALUE,
        bytes32        signHash,
        bytes memory   signature
        )
        public
        view
        returns (bytes4 magicValue)
    {
        if (wallet.locked) {
            return 0;
        }

        if (signHash.verifySignature(wallet.owner, signature)) {
            return ERC1271_MAGICVALUE;
        } else {
            return 0;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

enum SigRequirement
{
    MAJORITY_OWNER_NOT_ALLOWED,
    MAJORITY_OWNER_ALLOWED,
    MAJORITY_OWNER_REQUIRED,
    OWNER_OR_ANY_GUARDIAN,
    ANY_GUARDIAN
}

struct Approval
{
    address[] signers;
    bytes[]   signatures;
    uint      validUntil;
    address   wallet;
}

// Optimized to fit into 64 bytes (2 slots)
struct Quota
{
    uint128 currentQuota;
    uint128 pendingQuota;
    uint128 spentAmount;
    uint64  spentTimestamp;
    uint64  pendingUntil;
}

enum GuardianStatus
{
    REMOVE,    // Being removed or removed after validUntil timestamp
    ADD        // Being added or added after validSince timestamp.
}

// Optimized to fit into 32 bytes (1 slot)
struct Guardian
{
    address addr;
    uint8   status;
    uint64  timestamp; // validSince if status = ADD; validUntil if adding = REMOVE;
}

struct Wallet
{
    address owner;
    uint64  creationTimestamp;

    // relayer => nonce
    uint nonce;
    // hash => consumed
    mapping (bytes32 => bool) hashes;

    bool    locked;

    Guardian[] guardians;
    mapping (address => uint)  guardianIdx;

    address    inheritor;
    uint32     inheritWaitingPeriod;
    uint64     lastActive; // the latest timestamp the owner is considered to be active

    Quota quota;

    // whitelisted address => effective timestamp
    mapping (address => uint) whitelisted;
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./ApprovalLib.sol";
import "./WalletData.sol";
import "./GuardianLib.sol";


/// @title LockLib
/// @author Brecht Devos - <[email protected]>
library LockLib
{
    using GuardianLib   for Wallet;
    using ApprovalLib   for Wallet;

    event WalletLocked (
        address         by,
        bool            locked
    );

    bytes32 public constant LOCK_TYPEHASH = keccak256(
        "lock(address wallet,uint256 validUntil)"
    );
    bytes32 public constant UNLOCK_TYPEHASH = keccak256(
        "unlock(address wallet,uint256 validUntil)"
    );

    function lock(Wallet storage wallet)
        public
    {
        require(
            msg.sender == address(this) ||
            msg.sender == wallet.owner ||
            wallet.isGuardian(msg.sender, false),
            "NOT_FROM_WALLET_OR_OWNER_OR_GUARDIAN"
        );

        setLock(wallet, msg.sender, true);
    }

    function unlock(
        Wallet   storage  wallet,
        bytes32           domainSeparator,
        Approval calldata approval
        )
        public
        returns (bytes32 approvedHash)
    {
        approvedHash = wallet.verifyApproval(
            domainSeparator,
            SigRequirement.MAJORITY_OWNER_REQUIRED,
            approval,
            abi.encode(
                UNLOCK_TYPEHASH,
                approval.wallet,
                approval.validUntil
            )
        );

        setLock(wallet, msg.sender, false);
    }

    function setLock(
        Wallet storage wallet,
        address        by,
        bool           locked
        )
        internal
    {
        wallet.locked = locked;
        emit WalletLocked(by, locked);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./WalletData.sol";
import "./ApprovalLib.sol";
import "../../lib/SignatureUtil.sol";
import "../../thirdparty/SafeCast.sol";


/// @title GuardianModule
/// @author Brecht Devos - <[email protected]>
/// @author Daniel Wang - <[email protected]>
library GuardianLib
{
    using AddressUtil   for address;
    using SafeCast      for uint;
    using SignatureUtil for bytes32;
    using ApprovalLib   for Wallet;

    uint public constant MAX_GUARDIANS           = 10;
    uint public constant GUARDIAN_PENDING_PERIOD = 3 days;

    bytes32 public constant ADD_GUARDIAN_TYPEHASH = keccak256(
        "addGuardian(address wallet,uint256 validUntil,address guardian)"
    );
    bytes32 public constant REMOVE_GUARDIAN_TYPEHASH = keccak256(
        "removeGuardian(address wallet,uint256 validUntil,address guardian)"
    );
    bytes32 public constant RESET_GUARDIANS_TYPEHASH = keccak256(
        "resetGuardians(address wallet,uint256 validUntil,address[] guardians)"
    );

    event GuardianAdded   (address guardian, uint effectiveTime);
    event GuardianRemoved (address guardian, uint effectiveTime);

    function addGuardiansImmediately(
        Wallet    storage wallet,
        address[] memory  _guardians
        )
        external
    {
        address guardian = address(0);
        for (uint i = 0; i < _guardians.length; i++) {
            require(_guardians[i] > guardian, "INVALID_ORDERING");
            guardian = _guardians[i];
            _addGuardian(wallet, guardian, 0, true);
        }
    }

    function addGuardian(
        Wallet storage wallet,
        address guardian
        )
        external
    {
        _addGuardian(wallet, guardian, GUARDIAN_PENDING_PERIOD, false);
    }

    function addGuardianWA(
        Wallet   storage  wallet,
        bytes32           domainSeparator,
        Approval calldata approval,
        address  guardian
        )
        external
        returns (bytes32 approvedHash)
    {
        approvedHash = wallet.verifyApproval(
            domainSeparator,
            SigRequirement.MAJORITY_OWNER_REQUIRED,
            approval,
            abi.encode(
                ADD_GUARDIAN_TYPEHASH,
                approval.wallet,
                approval.validUntil,
                guardian
            )
        );

        _addGuardian(wallet, guardian, 0, true);
    }

    function removeGuardian(
        Wallet storage wallet,
        address guardian
        )
        external
    {
        _removeGuardian(wallet, guardian, GUARDIAN_PENDING_PERIOD, false);
    }

    function removeGuardianWA(
        Wallet   storage  wallet,
        bytes32           domainSeparator,
        Approval calldata approval,
        address  guardian
        )
        external
        returns (bytes32 approvedHash)
    {
        approvedHash = wallet.verifyApproval(
            domainSeparator,
            SigRequirement.MAJORITY_OWNER_REQUIRED,
            approval,
            abi.encode(
                REMOVE_GUARDIAN_TYPEHASH,
                approval.wallet,
                approval.validUntil,
                guardian
            )
        );

        _removeGuardian(wallet, guardian, 0, true);
    }

    function resetGuardians(
        Wallet    storage  wallet,
        address[] calldata newGuardians
        )
        external
    {
        Guardian[] memory allGuardians = guardians(wallet, true);
        for (uint i = 0; i < allGuardians.length; i++) {
            _removeGuardian(wallet, allGuardians[i].addr, GUARDIAN_PENDING_PERIOD, false);
        }

        for (uint j = 0; j < newGuardians.length; j++) {
            _addGuardian(wallet, newGuardians[j], GUARDIAN_PENDING_PERIOD, false);
        }
    }

    function resetGuardiansWA(
        Wallet    storage  wallet,
        bytes32            domainSeparator,
        Approval  calldata approval,
        address[] calldata newGuardians
        )
        external
        returns (bytes32 approvedHash)
    {
        approvedHash = wallet.verifyApproval(
            domainSeparator,
            SigRequirement.MAJORITY_OWNER_REQUIRED,
            approval,
            abi.encode(
                RESET_GUARDIANS_TYPEHASH,
                approval.wallet,
                approval.validUntil,
                keccak256(abi.encodePacked(newGuardians))
            )
        );

        removeAllGuardians(wallet);
        for (uint i = 0; i < newGuardians.length; i++) {
            _addGuardian(wallet, newGuardians[i], 0, true);
        }
    }

    function requireMajority(
        Wallet         storage wallet,
        address[]      memory  signers,
        SigRequirement         requirement
        )
        internal
        view
        returns (bool)
    {
        // We always need at least one signer
        if (signers.length == 0) {
            return false;
        }

        // Calculate total group sizes
        Guardian[] memory allGuardians = guardians(wallet, false);
        require(allGuardians.length > 0, "NO_GUARDIANS");

        address lastSigner;
        bool walletOwnerSigned = false;
        address owner = wallet.owner;
        for (uint i = 0; i < signers.length; i++) {
            // Check for duplicates
            require(signers[i] > lastSigner, "INVALID_SIGNERS_ORDER");
            lastSigner = signers[i];

            if (signers[i] == owner) {
                walletOwnerSigned = true;
            } else {
                bool _isGuardian = false;
                for (uint j = 0; j < allGuardians.length; j++) {
                    if (allGuardians[j].addr == signers[i]) {
                        _isGuardian = true;
                        break;
                    }
                }
                require(_isGuardian, "SIGNER_NOT_GUARDIAN");
            }
        }

        if (requirement == SigRequirement.OWNER_OR_ANY_GUARDIAN) {
            return signers.length == 1;
        } else if (requirement == SigRequirement.ANY_GUARDIAN) {
            require(!walletOwnerSigned, "WALLET_OWNER_SIGNATURE_NOT_ALLOWED");
            return signers.length == 1;
        }

        // Check owner requirements
        if (requirement == SigRequirement.MAJORITY_OWNER_REQUIRED) {
            require(walletOwnerSigned, "WALLET_OWNER_SIGNATURE_REQUIRED");
        } else if (requirement == SigRequirement.MAJORITY_OWNER_NOT_ALLOWED) {
            require(!walletOwnerSigned, "WALLET_OWNER_SIGNATURE_NOT_ALLOWED");
        }

        uint numExtendedSigners = allGuardians.length;
        if (walletOwnerSigned) {
            numExtendedSigners += 1;
            require(signers.length > 1, "NO_GUARDIAN_SIGNED_BESIDES_OWNER");
        }

        return signers.length >= (numExtendedSigners >> 1) + 1;
    }

    function isGuardian(
        Wallet storage wallet,
        address addr,
        bool    includePendingAddition
        )
        public
        view
        returns (bool)
    {
        Guardian memory g = _getGuardian(wallet, addr);
        return _isActiveOrPendingAddition(g, includePendingAddition);
    }

    function guardians(
        Wallet storage wallet,
        bool    includePendingAddition
        )
        public
        view
        returns (Guardian[] memory _guardians)
    {
        _guardians = new Guardian[](wallet.guardians.length);
        uint index = 0;
        for (uint i = 0; i < wallet.guardians.length; i++) {
            Guardian memory g = wallet.guardians[i];
            if (_isActiveOrPendingAddition(g, includePendingAddition)) {
                _guardians[index] = g;
                index++;
            }
        }
        assembly { mstore(_guardians, index) }
    }

    function numGuardians(
        Wallet storage wallet,
        bool    includePendingAddition
        )
        public
        view
        returns (uint count)
    {
        for (uint i = 0; i < wallet.guardians.length; i++) {
            Guardian memory g = wallet.guardians[i];
            if (_isActiveOrPendingAddition(g, includePendingAddition)) {
                count++;
            }
        }
    }

     function removeAllGuardians(
        Wallet storage wallet
        )
        internal
    {
        uint size = wallet.guardians.length;
        if (size == 0) return;

        for (uint i = 0; i < wallet.guardians.length; i++) {
            delete wallet.guardianIdx[wallet.guardians[i].addr];
        }
        delete wallet.guardians;
    }

    function cancelPendingGuardians(Wallet storage wallet)
        internal
    {
        bool cancelled = false;
        for (uint i = 0; i < wallet.guardians.length; i++) {
            Guardian memory g = wallet.guardians[i];
            if (_isPendingAddition(g)) {
                wallet.guardians[i].status = uint8(GuardianStatus.REMOVE);
                wallet.guardians[i].timestamp = 0;
                cancelled = true;
            }
            if (_isPendingRemoval(g)) {
                wallet.guardians[i].status = uint8(GuardianStatus.ADD);
                wallet.guardians[i].timestamp = 0;
                cancelled = true;
            }
        }
        _cleanRemovedGuardians(wallet, true);
    }

    function storeGuardian(
        Wallet storage wallet,
        address addr,
        uint    validSince,
        bool    alwaysOverride
        )
        internal
        returns (uint)
    {
        require(validSince >= block.timestamp, "INVALID_VALID_SINCE");
        require(addr != address(0), "ZERO_ADDRESS");
        require(addr != address(this), "INVALID_ADDRESS");

        uint pos = wallet.guardianIdx[addr];

        if (pos == 0) {
            // Add the new guardian
            Guardian memory _g = Guardian(
                addr,
                uint8(GuardianStatus.ADD),
                validSince.toUint64()
            );
            wallet.guardians.push(_g);
            wallet.guardianIdx[addr] = wallet.guardians.length;

            _cleanRemovedGuardians(wallet, false);
            return validSince;
        }

        Guardian memory g = wallet.guardians[pos - 1];

        if (_isRemoved(g)) {
            wallet.guardians[pos - 1].status = uint8(GuardianStatus.ADD);
            wallet.guardians[pos - 1].timestamp = validSince.toUint64();
            return validSince;
        }

        if (_isPendingRemoval(g)) {
            wallet.guardians[pos - 1].status = uint8(GuardianStatus.ADD);
            wallet.guardians[pos - 1].timestamp = 0;
            return 0;
        }

        if (_isPendingAddition(g)) {
            if (!alwaysOverride) return g.timestamp;

            wallet.guardians[pos - 1].timestamp = validSince.toUint64();
            return validSince;
        }

        require(_isAdded(g), "UNEXPECTED_RESULT");
        return 0;
    }

    function deleteGuardian(
        Wallet storage wallet,
        address addr,
        uint    validUntil,
        bool    alwaysOverride
        )
        internal
        returns (uint)
    {
        require(validUntil >= block.timestamp, "INVALID_VALID_UNTIL");
        require(addr != address(0), "ZERO_ADDRESS");

        uint pos = wallet.guardianIdx[addr];
        require(pos > 0, "GUARDIAN_NOT_EXISTS");

        Guardian memory g = wallet.guardians[pos - 1];

        if (_isAdded(g)) {
            wallet.guardians[pos - 1].status = uint8(GuardianStatus.REMOVE);
            wallet.guardians[pos - 1].timestamp = validUntil.toUint64();
            return validUntil;
        }

        if (_isPendingAddition(g)) {
            wallet.guardians[pos - 1].status = uint8(GuardianStatus.REMOVE);
            wallet.guardians[pos - 1].timestamp = 0;
            return 0;
        }

        if (_isPendingRemoval(g)) {
            if (!alwaysOverride) return g.timestamp;

            wallet.guardians[pos - 1].timestamp = validUntil.toUint64();
            return validUntil;
        }

        require(_isRemoved(g), "UNEXPECTED_RESULT");
        return 0;
    }

    // --- Internal functions ---

    function _addGuardian(
        Wallet storage wallet,
        address guardian,
        uint    pendingPeriod,
        bool    alwaysOverride
        )
        internal
    {
        uint _numGuardians = numGuardians(wallet, true);
        require(_numGuardians < MAX_GUARDIANS, "TOO_MANY_GUARDIANS");
        require(guardian != wallet.owner, "GUARDIAN_CAN_NOT_BE_OWNER");

        uint validSince = block.timestamp;
        if (_numGuardians >= 2) {
            validSince = block.timestamp + pendingPeriod;
        }
        validSince = storeGuardian(wallet, guardian, validSince, alwaysOverride);
        emit GuardianAdded(guardian, validSince);
    }

    function _removeGuardian(
        Wallet storage wallet,
        address guardian,
        uint    pendingPeriod,
        bool    alwaysOverride
        )
        private
    {
        uint validUntil = block.timestamp + pendingPeriod;
        validUntil = deleteGuardian(wallet, guardian, validUntil, alwaysOverride);
        emit GuardianRemoved(guardian, validUntil);
    }

    function _getGuardian(
        Wallet storage wallet,
        address addr
        )
        private
        view
        returns (Guardian memory guardian)
    {
        uint pos = wallet.guardianIdx[addr];
        if (pos > 0) {
            guardian = wallet.guardians[pos - 1];
        }
    }

    function _isAdded(Guardian memory guardian)
        private
        view
        returns (bool)
    {
        return guardian.status == uint8(GuardianStatus.ADD) &&
            guardian.timestamp <= block.timestamp;
    }

    function _isPendingAddition(Guardian memory guardian)
        private
        view
        returns (bool)
    {
        return guardian.status == uint8(GuardianStatus.ADD) &&
            guardian.timestamp > block.timestamp;
    }

    function _isRemoved(Guardian memory guardian)
        private
        view
        returns (bool)
    {
        return guardian.status == uint8(GuardianStatus.REMOVE) &&
            guardian.timestamp <= block.timestamp;
    }

    function _isPendingRemoval(Guardian memory guardian)
        private
        view
        returns (bool)
    {
         return guardian.status == uint8(GuardianStatus.REMOVE) &&
            guardian.timestamp > block.timestamp;
    }

    function _isActive(Guardian memory guardian)
        private
        view
        returns (bool)
    {
        return _isAdded(guardian) || _isPendingRemoval(guardian);
    }

    function _isActiveOrPendingAddition(
        Guardian memory guardian,
        bool includePendingAddition
        )
        private
        view
        returns (bool)
    {
        return _isActive(guardian) || includePendingAddition && _isPendingAddition(guardian);
    }

    function _cleanRemovedGuardians(
        Wallet storage wallet,
        bool    force
        )
        private
    {
        uint count = wallet.guardians.length;
        if (!force && count < 10) return;

        for (int i = int(count) - 1; i >= 0; i--) {
            Guardian memory g = wallet.guardians[uint(i)];
            if (_isRemoved(g)) {
                Guardian memory lastGuardian = wallet.guardians[wallet.guardians.length - 1];

                if (g.addr != lastGuardian.addr) {
                    wallet.guardians[uint(i)] = lastGuardian;
                    wallet.guardianIdx[lastGuardian.addr] = uint(i) + 1;
                }
                wallet.guardians.pop();
                delete wallet.guardianIdx[g.addr];
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./WalletData.sol";
import "./GuardianLib.sol";
import "./LockLib.sol";
import "./Utils.sol";


/// @title InheritanceLib
/// @author Brecht Devos - <[email protected]>
library InheritanceLib
{
    using GuardianLib     for Wallet;
    using InheritanceLib  for Wallet;
    using LockLib         for Wallet;
    using Utils           for address;

    // The minimal number of guardians for recovery and locking.
    uint public constant TOUCH_GRACE_PERIOD = 30 days;

    event Inherited(
        address         inheritor,
        address         newOwner
    );

    event InheritorChanged(
        address         inheritor,
        uint32          waitingPeriod
    );

    function touchLastActiveWhenRequired(Wallet storage wallet)
        internal
    {
        if (wallet.inheritor != address(0) &&
            block.timestamp > wallet.lastActive + TOUCH_GRACE_PERIOD) {
            wallet.lastActive = uint64(block.timestamp);
        }
    }

    function setInheritor(
        Wallet storage wallet,
        address        inheritor,
        uint32         waitingPeriod
        )
        internal
    {
        wallet.inheritor = inheritor;
        wallet.inheritWaitingPeriod = waitingPeriod;
        wallet.lastActive = uint64(block.timestamp);
    }

    function inherit(
        Wallet storage wallet,
        address        newOwner
        )
        external
    {
        require(wallet.inheritor == msg.sender, "UNAUTHORIZED");
        require(wallet.owner != newOwner, "IS_WALLET_OWNER");
        require(newOwner.isValidWalletOwner(), "INVALID_NEW_WALLET_OWNER");
        require(uint(wallet.lastActive) + uint(wallet.inheritWaitingPeriod) <= block.timestamp, "TOO_EARLY");

        wallet.removeAllGuardians();
        wallet.setInheritor(address(0), 0);
        wallet.setLock(address(this), false);

        wallet.owner = newOwner;

        emit Inherited(wallet.inheritor, newOwner);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../lib/AddressUtil.sol";
import "../../lib/EIP712.sol";
import "../../lib/ERC20.sol";
import "../../lib/MathUint.sol";
import "../../lib/SignatureUtil.sol";
import "../../thirdparty/BytesUtil.sol";
import "./WalletData.sol";
import "./ERC20Lib.sol";
import "./QuotaLib.sol";
import "../SmartWallet.sol";


/// @title MetaTxLib
/// @dev A module to support wallet meta-transactions.
library MetaTxLib
{
    using AddressUtil   for address;
    using BytesUtil     for bytes;
    using MathUint      for uint;
    using SignatureUtil for bytes32;
    using QuotaLib      for Wallet;
    using ERC20Lib      for Wallet;

    bytes32 public constant META_TX_TYPEHASH = keccak256(
        "MetaTx(address to,uint256 nonce,address gasToken,uint256 gasPrice,uint256 gasLimit,uint256 gasOverhead,address feeRecipient,bytes data,bytes32 approvedHash)"
    );

    event MetaTxExecuted(
        uint    nonce,
        bytes32 approvedHash,
        bytes32 metaTxHash,
        bool    success,
        uint    gasUsed
    );

    struct MetaTx
    {
        address to;
        uint    nonce;
        address gasToken;
        uint    gasPrice;
        uint    gasLimit;
        uint    gasOverhead;
        address feeRecipient;
        bool    requiresSuccess;
        bytes   data;
        bytes   signature;
    }

    function validateMetaTx(
        Wallet  storage wallet,
        bytes32 DOMAIN_SEPARATOR,
        MetaTx  memory  metaTx,
        bool            success,
        bytes   memory  returnData
        )
        public
        view
        returns (bytes32)
    {
        // If this is a dataless meta-tx the user only signs the function selector,
        // not the full function calldata.
        bytes memory data = metaTx.nonce == 0 ? metaTx.data.slice(0, 4) : metaTx.data;
        // Extracted the approved hash for dataless transactions
        // The approved hash always needs to be the first value returned by the called function
        // If the call failed we cannot deduce the approved hash so throw a nice
        // error message here instead of failing in the signature check.
        require(success || metaTx.nonce != 0, "APPROVED_HASH_UNKNOWN");
        bytes32 approvedHash = metaTx.nonce == 0 ? returnData.toBytes32(0) : bytes32(0);

        bytes32 encodedHash = keccak256(
            abi.encode(
                META_TX_TYPEHASH,
                metaTx.to,
                metaTx.nonce,
                metaTx.gasToken,
                metaTx.gasPrice,
                metaTx.gasLimit,
                metaTx.gasOverhead,
                metaTx.feeRecipient,
                metaTx.requiresSuccess,
                keccak256(data),
                approvedHash
            )
        );
        bytes32 metaTxHash = EIP712.hashPacked(DOMAIN_SEPARATOR, encodedHash);
        require(
            metaTxHash.verifySignature(wallet.owner, metaTx.signature),
            "METATX_INVALID_SIGNATURE"
        );
        return metaTxHash;
    }

    function executeMetaTx(
        Wallet      storage wallet,
        bytes32             DOMAIN_SEPARATOR,
        PriceOracle         priceOracle,
        MetaTx      memory  metaTx
        )
        public
        returns (bool success)
    {
        uint gasLeft = gasleft();
        require(gasLeft >= (metaTx.gasLimit.mul(64) / 63), "OPERATOR_INSUFFICIENT_GAS");

        require(msg.sender != address(this), "RECURSIVE_METATXS_DISALLOWED");

        // Only self calls allowed for now
        require(metaTx.to == address(this));

        // Update the nonce before the call to protect against reentrancy
        require(isNonceValid(wallet, metaTx), "INVALID_NONCE");
        if (metaTx.nonce != 0) {
            wallet.nonce = metaTx.nonce;
        }

        // Do the actual call
        bytes memory returnData;
        (success, returnData) = metaTx.to.call{gas: metaTx.gasLimit}(metaTx.data);

        // These checks are done afterwards to use the latest state post meta-tx call
        require(!wallet.locked, "WALLET_LOCKED");

        bytes32 metaTxHash = validateMetaTx(
            wallet,
            DOMAIN_SEPARATOR,
            metaTx,
            success,
            returnData
        );

        uint gasUsed = gasLeft - gasleft() + metaTx.gasOverhead;

        // Reimburse
        if (metaTx.gasPrice > 0 && (!metaTx.requiresSuccess || success)) {
            uint gasToReimburse = gasUsed <= metaTx.gasLimit ? gasUsed : metaTx.gasLimit;
            uint gasCost = gasToReimburse.mul(metaTx.gasPrice);

            wallet.checkAndAddToSpent(
                priceOracle,
                metaTx.gasToken,
                gasCost
            );

            ERC20Lib.transfer(metaTx.gasToken, metaTx.feeRecipient, gasCost);
        }

        emit MetaTxExecuted(
            metaTx.nonce,
            metaTx.nonce == 0 ? returnData.toBytes32(0) : bytes32(0),
            metaTxHash,
            success,
            gasUsed
        );
    }

    function batchCall(
        Wallet    storage  /*wallet*/,
        address[] calldata to,
        bytes[]   calldata data
        )
        public
    {
        require(to.length == data.length, "INVALID_DATA");

        for (uint i = 0; i < to.length; i++) {
            require(to[i] == address(this));
            (bool success, ) = to[i].call(data[i]);
            require(success, "BATCHED_CALL_FAILED");
        }
    }

    function isNonceValid(
        Wallet  storage wallet,
        MetaTx  memory  metaTx
        )
        public
        view
        returns (bool)
    {
        return (metaTx.nonce > wallet.nonce && (metaTx.nonce >> 128) <= block.number) ||
               isDataless(metaTx);
    }

    function isDataless(
        MetaTx memory metaTx
        )
        public
        pure
        returns (bool)
    {
        // We don't require any data in the meta tx when
        // - the meta-tx has no nonce
        // - the meta-tx needs to be successful
        // - a function is called that requires a majority of guardians and fails when replayed
        bytes4 methodId = metaTx.data.toBytes4(0);
        return metaTx.nonce == 0 &&
               metaTx.requiresSuccess &&
               (methodId == SmartWallet.changeMasterCopy.selector ||
                methodId == SmartWallet.addGuardianWA.selector ||
                methodId == SmartWallet.removeGuardianWA.selector ||
                methodId == SmartWallet.resetGuardiansWA.selector ||
                methodId == SmartWallet.unlock.selector ||
                methodId == SmartWallet.changeDailyQuotaWA.selector ||
                methodId == SmartWallet.recover.selector ||
                methodId == SmartWallet.addToWhitelistWA.selector ||
                methodId == SmartWallet.transferTokenWA.selector ||
                methodId == SmartWallet.callContractWA.selector ||
                methodId == SmartWallet.approveTokenWA.selector ||
                methodId == SmartWallet.approveThenCallContractWA.selector);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./ApprovalLib.sol";
import "./WalletData.sol";
import "../../lib/MathUint.sol";


/// @title WhitelistLib
/// @dev This store maintains a wallet's whitelisted addresses.
library WhitelistLib
{
    using MathUint          for uint;
    using WhitelistLib      for Wallet;
    using ApprovalLib       for Wallet;

    uint public constant WHITELIST_PENDING_PERIOD = 1 days;

    bytes32 public constant ADD_TO_WHITELIST_TYPEHASH = keccak256(
        "addToWhitelist(address wallet,uint256 validUntil,address addr)"
    );

    event Whitelisted(
        address addr,
        bool    whitelisted,
        uint    effectiveTime
    );

    function addToWhitelist(
        Wallet  storage wallet,
        address         addr
        )
        external
    {
        wallet._addToWhitelist(
            addr,
            block.timestamp.add(WHITELIST_PENDING_PERIOD)
        );
    }

    function addToWhitelistWA(
        Wallet   storage  wallet,
        bytes32           domainSeparator,
        Approval calldata approval,
        address           addr
        )
        external
        returns (bytes32 approvedHash)
    {
        approvedHash = wallet.verifyApproval(
            domainSeparator,
            SigRequirement.MAJORITY_OWNER_REQUIRED,
            approval,
            abi.encode(
                ADD_TO_WHITELIST_TYPEHASH,
                approval.wallet,
                approval.validUntil,
                addr
            )
        );

        wallet._addToWhitelist(
            addr,
            block.timestamp
        );
    }

    function removeFromWhitelist(
        Wallet  storage  wallet,
        address          addr
        )
        external
    {
        wallet._removeFromWhitelist(addr);
    }

    function isAddressWhitelisted(
        Wallet storage wallet,
        address addr
        )
        internal
        view
        returns (bool)
    {
        uint effectiveTime = wallet.whitelisted[addr];
        return effectiveTime > 0 && effectiveTime <= block.timestamp;
    }

    // --- Internal functions ---

    function _addToWhitelist(
        Wallet storage wallet,
        address        addr,
        uint           effectiveTime
        )
        internal
    {
        require(wallet.whitelisted[addr] == 0, "ADDRESS_ALREADY_WHITELISTED");
        uint effective = effectiveTime >= block.timestamp ? effectiveTime : block.timestamp;
        wallet.whitelisted[addr] = effective;
        emit Whitelisted(addr, true, effective);
    }

    function _removeFromWhitelist(
        Wallet storage wallet,
        address        addr
        )
        internal
    {
        delete wallet.whitelisted[addr];
        emit Whitelisted(addr, false, 0);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./ApprovalLib.sol";
import "./WalletData.sol";
import "../../iface/PriceOracle.sol";
import "../../lib/MathUint.sol";
import "../../thirdparty/SafeCast.sol";


/// @title QuotaLib
/// @dev This store maintains daily spending quota for each wallet.
///      A rolling daily limit is used.
library QuotaLib
{
    using MathUint      for uint;
    using SafeCast      for uint;
    using ApprovalLib   for Wallet;

    uint128 public constant MAX_QUOTA = uint128(-1);
    uint    public constant QUOTA_PENDING_PERIOD = 1 days;

    bytes32 public constant CHANGE_DAILY_QUOTE_TYPEHASH = keccak256(
        "changeDailyQuota(address wallet,uint256 validUntil,uint256 newQuota)"
    );

    event QuotaScheduled(
        address wallet,
        uint    pendingQuota,
        uint64  pendingUntil
    );

    function changeDailyQuota(
        Wallet storage wallet,
        uint           newQuota
        )
        public
    {
        setQuota(wallet, newQuota, block.timestamp.add(QUOTA_PENDING_PERIOD));
    }

    function changeDailyQuotaWA(
        Wallet   storage   wallet,
        bytes32            domainSeparator,
        Approval calldata  approval,
        uint               newQuota
        )
        public
        returns (bytes32 approvedHash)
    {
        approvedHash = wallet.verifyApproval(
            domainSeparator,
            SigRequirement.MAJORITY_OWNER_REQUIRED,
            approval,
            abi.encode(
                CHANGE_DAILY_QUOTE_TYPEHASH,
                approval.wallet,
                approval.validUntil,
                newQuota
            )
        );
        setQuota(wallet, newQuota, 0);
    }

    function checkAndAddToSpent(
        Wallet      storage wallet,
        PriceOracle         priceOracle,
        address             token,
        uint                amount
        )
        internal
    {
        Quota memory q = wallet.quota;
        uint available = _availableQuota(q);
        if (available != MAX_QUOTA) {
            uint value = (token == address(0)) ?
                amount :
                ((address(priceOracle) == address(0)) ?
                 0 :
                 priceOracle.tokenValue(token, amount));

            if (value > 0) {
                require(available >= value, "QUOTA_EXCEEDED");
                _addToSpent(wallet, q, value);
            }
        }
    }

    // 0 for newQuota indicates unlimited quota, or daily quota is disabled.
    function setQuota(
        Wallet storage wallet,
        uint           newQuota,
        uint           effectiveTime
        )
        internal
    {
        require(newQuota <= MAX_QUOTA, "INVALID_VALUE");
        if (newQuota == MAX_QUOTA) {
            newQuota = 0;
        }

        uint __currentQuota = currentQuota(wallet);
        // Always allow the quota to be changed immediately when the quota doesn't increase
        if ((__currentQuota >= newQuota && newQuota != 0) || __currentQuota == 0) {
            effectiveTime = 0;
        }

        Quota storage quota = wallet.quota;
        quota.currentQuota = __currentQuota.toUint128();
        quota.pendingQuota = newQuota.toUint128();
        quota.pendingUntil = effectiveTime.toUint64();

        emit QuotaScheduled(
            address(this),
            newQuota,
            quota.pendingUntil
        );
    }

    // Returns 0 to indiciate unlimited quota
    function currentQuota(Wallet storage wallet)
        internal
        view
        returns (uint)
    {
        return _currentQuota(wallet.quota);
    }

    // Returns 0 to indiciate unlimited quota
    function pendingQuota(Wallet storage wallet)
        internal
        view
        returns (
            uint __pendingQuota,
            uint __pendingUntil
        )
    {
        return _pendingQuota(wallet.quota);
    }

    function spentQuota(Wallet storage wallet)
        internal
        view
        returns (uint)
    {
        return _spentQuota(wallet.quota);
    }

    function availableQuota(Wallet storage wallet)
        internal
        view
        returns (uint)
    {
        return _availableQuota(wallet.quota);
    }

    function hasEnoughQuota(
        Wallet storage wallet,
        uint               requiredAmount
        )
        internal
        view
        returns (bool)
    {
        return _hasEnoughQuota(wallet.quota, requiredAmount);
    }

    // --- Internal functions ---

    function _currentQuota(Quota memory q)
        private
        view
        returns (uint)
    {
        return q.pendingUntil <= block.timestamp ? q.pendingQuota : q.currentQuota;
    }

    function _pendingQuota(Quota memory q)
        private
        view
        returns (
            uint __pendingQuota,
            uint __pendingUntil
        )
    {
        if (q.pendingUntil > 0 && q.pendingUntil > block.timestamp) {
            __pendingQuota = q.pendingQuota;
            __pendingUntil = q.pendingUntil;
        }
    }

    function _spentQuota(Quota memory q)
        private
        view
        returns (uint)
    {
        uint timeSinceLastSpent = block.timestamp.sub(q.spentTimestamp);
        if (timeSinceLastSpent < 1 days) {
            return uint(q.spentAmount).sub(timeSinceLastSpent.mul(q.spentAmount) / 1 days);
        } else {
            return 0;
        }
    }

    function _availableQuota(Quota memory q)
        private
        view
        returns (uint)
    {
        uint quota = _currentQuota(q);
        if (quota == 0) {
            return MAX_QUOTA;
        }
        uint spent = _spentQuota(q);
        return quota > spent ? quota - spent : 0;
    }

    function _hasEnoughQuota(
        Quota   memory q,
        uint    requiredAmount
        )
        private
        view
        returns (bool)
    {
        return _availableQuota(q) >= requiredAmount;
    }

    function _addToSpent(
        Wallet storage wallet,
        Quota   memory q,
        uint    amount
        )
        private
    {
        Quota storage s = wallet.quota;
        s.spentAmount = _spentQuota(q).add(amount).toUint128();
        s.spentTimestamp = uint64(block.timestamp);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./ApprovalLib.sol";
import "./WalletData.sol";
import "./GuardianLib.sol";
import "./LockLib.sol";
import "./Utils.sol";


/// @title RecoverLib
/// @author Brecht Devos - <[email protected]>
library RecoverLib
{
    using GuardianLib   for Wallet;
    using LockLib       for Wallet;
    using ApprovalLib   for Wallet;
    using Utils         for address;

    event Recovered(address newOwner);

    bytes32 public constant RECOVER_TYPEHASH = keccak256(
        "recover(address wallet,uint256 validUntil,address newOwner,address[] newGuardians)"
    );

    /// @dev Recover a wallet by setting a new owner and guardians.
    /// @param approval The approval.
    /// @param newOwner The new owner address to set.
    /// @param newGuardians The new guardians addresses to set.
    function recover(
        Wallet   storage   wallet,
        bytes32            domainSeparator,
        Approval calldata  approval,
        address            newOwner,
        address[] calldata newGuardians
        )
        external
        returns (bytes32 approvedHash)
    {
        require(wallet.owner != newOwner, "IS_SAME_OWNER");
        require(newOwner.isValidWalletOwner(), "INVALID_NEW_WALLET_OWNER");

        approvedHash = wallet.verifyApproval(
            domainSeparator,
            SigRequirement.MAJORITY_OWNER_NOT_ALLOWED,
            approval,
            abi.encode(
                RECOVER_TYPEHASH,
                approval.wallet,
                approval.validUntil,
                newOwner,
                keccak256(abi.encodePacked(newGuardians))
            )
        );

        wallet.owner = newOwner;
        wallet.setLock(address(this), false);

        if (newGuardians.length > 0) {
            for (uint i = 0; i < newGuardians.length; i++) {
                require(newGuardians[i] != newOwner, "INVALID_NEW_WALLET_GUARDIAN");
            }
            wallet.removeAllGuardians();
            wallet.addGuardiansImmediately(newGuardians);
        } else {
            if (wallet.isGuardian(newOwner, true)) {
                wallet.deleteGuardian(newOwner, block.timestamp, true);
            }
            wallet.cancelPendingGuardians();
        }

        emit Recovered(newOwner);
    }

}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./ApprovalLib.sol";
import "./WalletData.sol";


/// @title UpgradeLib
/// @author Brecht Devos - <[email protected]>
library UpgradeLib
{
    using ApprovalLib     for Wallet;

    event ChangedMasterCopy (address masterCopy);

    bytes32 public constant CHANGE_MASTER_COPY_TYPEHASH = keccak256(
        "changeMasterCopy(address wallet,uint256 validUntil,address masterCopy)"
    );

    function changeMasterCopy(
        Wallet   storage  wallet,
        bytes32           domainSeparator,
        Approval calldata approval,
        address           newMasterCopy
        )
        external
        returns (bytes32 approvedHash)
    {
        require(newMasterCopy != address(0), "INVALID_MASTER_COPY");

        approvedHash = wallet.verifyApproval(
            domainSeparator,
            SigRequirement.MAJORITY_OWNER_REQUIRED,
            approval,
            abi.encode(
                CHANGE_MASTER_COPY_TYPEHASH,
                approval.wallet,
                approval.validUntil,
                newMasterCopy
            )
        );

        emit ChangedMasterCopy(newMasterCopy);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// Taken from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol

pragma solidity >=0.6.0 <0.8.0;

import "./Address.sol";
import "../lib/ERC20.sol";
import "../lib/MathUint.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using MathUint for uint256;
    using Address  for address;

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(ERC20 token, bytes memory data) private {
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

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;


/// @title Utility Functions for uint
/// @author Daniel Wang - <[email protected]>
library MathUint
{
    function mul(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a * b;
        require(a == 0 || c / a == b, "MUL_OVERFLOW");
    }

    function sub(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint)
    {
        require(b <= a, "SUB_UNDERFLOW");
        return a - b;
    }

    function add(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a + b;
        require(c >= a, "ADD_OVERFLOW");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;


/// @title Utility Functions for addresses
/// @author Daniel Wang - <[email protected]>
/// @author Brecht Devos - <[email protected]>
library AddressUtil
{
    using AddressUtil for *;

    function isContract(
        address addr
        )
        internal
        view
        returns (bool)
    {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(addr) }
        return (codehash != 0x0 &&
                codehash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
    }

    function toPayable(
        address addr
        )
        internal
        pure
        returns (address payable)
    {
        return payable(addr);
    }

    // Works like address.send but with a customizable gas limit
    // Make sure your code is safe for reentrancy when using this function!
    function sendETH(
        address to,
        uint    amount,
        uint    gasLimit
        )
        internal
        returns (bool success)
    {
        if (amount == 0) {
            return true;
        }
        address payable recipient = to.toPayable();
        /* solium-disable-next-line */
        (success,) = recipient.call{value: amount, gas: gasLimit}("");
    }

    // Works like address.transfer but with a customizable gas limit
    // Make sure your code is safe for reentrancy when using this function!
    function sendETHAndVerify(
        address to,
        uint    amount,
        uint    gasLimit
        )
        internal
        returns (bool success)
    {
        success = to.sendETH(amount, gasLimit);
        require(success, "TRANSFER_FAILURE");
    }

    // Works like call but is slightly more efficient when data
    // needs to be copied from memory to do the call.
    function fastCall(
        address to,
        uint    gasLimit,
        uint    value,
        bytes   memory data
        )
        internal
        returns (bool success, bytes memory returnData)
    {
        if (to != address(0)) {
            assembly {
                // Do the call
                success := call(gasLimit, to, value, add(data, 32), mload(data), 0, 0)
                // Copy the return data
                let size := returndatasize()
                returnData := mload(0x40)
                mstore(returnData, size)
                returndatacopy(add(returnData, 32), 0, size)
                // Update free memory pointer
                mstore(0x40, add(returnData, add(32, size)))
            }
        }
    }

    // Like fastCall, but throws when the call is unsuccessful.
    function fastCallAndVerify(
        address to,
        uint    gasLimit,
        uint    value,
        bytes   memory data
        )
        internal
        returns (bytes memory returnData)
    {
        bool success;
        (success, returnData) = fastCall(to, gasLimit, value, data);
        if (!success) {
            assembly {
                revert(add(returnData, 32), mload(returnData))
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;


/// @title PriceOracle
interface PriceOracle
{
    // @dev Return's the token's value in ETH
    function tokenValue(address token, uint amount)
        external
        view
        returns (uint value);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../lib/EIP712.sol";
import "../../lib/SignatureUtil.sol";
import "./GuardianLib.sol";
import "./WalletData.sol";


/// @title ApprovalLib
/// @dev Utility library for better handling of signed wallet requests.
///      This library must be deployed and linked to other modules.
///
/// @author Daniel Wang - <[email protected]>
library ApprovalLib {
    using SignatureUtil for bytes32;

    function verifyApproval(
        Wallet  storage wallet,
        bytes32         domainSeparator,
        SigRequirement  sigRequirement,
        Approval memory approval,
        bytes    memory encodedRequest
        )
        internal
        returns (bytes32 approvedHash)
    {
        require(address(this) == approval.wallet, "INVALID_WALLET");
        require(block.timestamp <= approval.validUntil, "EXPIRED_SIGNED_REQUEST");

        approvedHash = EIP712.hashPacked(domainSeparator, keccak256(encodedRequest));

        // Save hash to prevent replay attacks
        require(!wallet.hashes[approvedHash], "HASH_EXIST");
        wallet.hashes[approvedHash] = true;

        require(
            approvedHash.verifySignatures(approval.signers, approval.signatures),
            "INVALID_SIGNATURES"
        );

        require(
            GuardianLib.requireMajority(
                wallet,
                approval.signers,
                sigRequirement
            ),
            "PERMISSION_DENIED"
        );
    }
}

// SPDX-License-Identifier: MIT
// Token from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/90ed1af972299070f51bf4665a85da56ac4d355e/contracts/utils/Address.sol

pragma solidity >=0.6.2 <0.8.0;

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
        //require(address(this).balance >= value, "Address: insufficient balance for call");
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../thirdparty/BytesUtil.sol";
import "./AddressUtil.sol";
import "./ERC1271.sol";
import "./MathUint.sol";


/// @title SignatureUtil
/// @author Daniel Wang - <[email protected]>
/// @dev This method supports multihash standard. Each signature's last byte indicates
///      the signature's type.
library SignatureUtil
{
    using BytesUtil     for bytes;
    using MathUint      for uint;
    using AddressUtil   for address;

    enum SignatureType {
        ILLEGAL,
        INVALID,
        EIP_712,
        ETH_SIGN,
        WALLET   // deprecated
    }

    bytes4 constant internal ERC1271_MAGICVALUE = 0x1626ba7e;

    function verifySignatures(
        bytes32          signHash,
        address[] memory signers,
        bytes[]   memory signatures
        )
        internal
        view
        returns (bool)
    {
        require(signers.length == signatures.length, "BAD_SIGNATURE_DATA");
        address lastSigner;
        for (uint i = 0; i < signers.length; i++) {
            require(signers[i] > lastSigner, "INVALID_SIGNERS_ORDER");
            lastSigner = signers[i];
            if (!verifySignature(signHash, signers[i], signatures[i])) {
                return false;
            }
        }
        return true;
    }

    function verifySignature(
        bytes32        signHash,
        address        signer,
        bytes   memory signature
        )
        internal
        view
        returns (bool)
    {
        if (signer == address(0)) {
            return false;
        }

        return signer.isContract()?
            verifyERC1271Signature(signHash, signer, signature):
            verifyEOASignature(signHash, signer, signature);
    }

    function recoverECDSASigner(
        bytes32      signHash,
        bytes memory signature
        )
        internal
        pure
        returns (address)
    {
        if (signature.length != 65) {
            return address(0);
        }

        bytes32 r;
        bytes32 s;
        uint8   v;
        // we jump 32 (0x20) as the first slot of bytes contains the length
        // we jump 65 (0x41) per signature
        // for v we load 32 bytes ending with v (the first 31 come from s) then apply a mask
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := and(mload(add(signature, 0x41)), 0xff)
        }
        // See https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }
        if (v == 27 || v == 28) {
            return ecrecover(signHash, v, r, s);
        } else {
            return address(0);
        }
    }

    function verifyEOASignature(
        bytes32        signHash,
        address        signer,
        bytes   memory signature
        )
        private
        pure
        returns (bool success)
    {
        if (signer == address(0)) {
            return false;
        }

        uint signatureTypeOffset = signature.length.sub(1);
        SignatureType signatureType = SignatureType(signature.toUint8(signatureTypeOffset));

        // Strip off the last byte of the signature by updating the length
        assembly {
            mstore(signature, signatureTypeOffset)
        }

        if (signatureType == SignatureType.EIP_712) {
            success = (signer == recoverECDSASigner(signHash, signature));
        } else if (signatureType == SignatureType.ETH_SIGN) {
            bytes32 hash = keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", signHash)
            );
            success = (signer == recoverECDSASigner(hash, signature));
        } else {
            success = false;
        }

        // Restore the signature length
        assembly {
            mstore(signature, add(signatureTypeOffset, 1))
        }

        return success;
    }

    function verifyERC1271Signature(
        bytes32 signHash,
        address signer,
        bytes   memory signature
        )
        private
        view
        returns (bool)
    {
        bytes memory callData = abi.encodeWithSelector(
            ERC1271.isValidSignature.selector,
            signHash,
            signature
        );
        (bool success, bytes memory result) = signer.staticcall(callData);
        return (
            success &&
            result.length == 32 &&
            result.toBytes4(0) == ERC1271_MAGICVALUE
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
// Taken from https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
pragma solidity ^0.7.0;

library BytesUtil {
    function slice(
        bytes memory _bytes,
        uint _start,
        uint _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint _start) internal  pure returns (address) {
        require(_bytes.length >= (_start + 20));
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint _start) internal  pure returns (uint8) {
        require(_bytes.length >= (_start + 1));
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint _start) internal  pure returns (uint16) {
        require(_bytes.length >= (_start + 2));
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint24(bytes memory _bytes, uint _start) internal  pure returns (uint24) {
        require(_bytes.length >= (_start + 3));
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint _start) internal  pure returns (uint32) {
        require(_bytes.length >= (_start + 4));
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint _start) internal  pure returns (uint64) {
        require(_bytes.length >= (_start + 8));
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint _start) internal  pure returns (uint96) {
        require(_bytes.length >= (_start + 12));
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint _start) internal  pure returns (uint128) {
        require(_bytes.length >= (_start + 16));
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint(bytes memory _bytes, uint _start) internal  pure returns (uint256) {
        require(_bytes.length >= (_start + 32));
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes4(bytes memory _bytes, uint _start) internal  pure returns (bytes4) {
        require(_bytes.length >= (_start + 4));
        bytes4 tempBytes4;

        assembly {
            tempBytes4 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes4;
    }

    function toBytes32(bytes memory _bytes, uint _start) internal  pure returns (bytes32) {
        require(_bytes.length >= (_start + 32));
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function fastSHA256(
        bytes memory data
        )
        internal
        view
        returns (bytes32)
    {
        bytes32[] memory result = new bytes32[](1);
        bool success;
        assembly {
             let ptr := add(data, 32)
             success := staticcall(sub(gas(), 2000), 2, ptr, mload(data), add(result, 32), 32)
        }
        require(success, "SHA256_FAILED");
        return result[0];
    }
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/SafeCast.sol

pragma solidity ^0.7.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value < 2**96, "SafeCast: value doesn\'t fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value < 2**40, "SafeCast: value doesn\'t fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./WalletData.sol";
import "../../lib/AddressUtil.sol";

/// @title Utils
/// @author Brecht Devos - <[email protected]>
library Utils
{
    using AddressUtil for address;

    function isValidWalletOwner(address addr)
        view
        internal
        returns (bool)
    {
        return addr != address(0) && !addr.isContract();
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 100000
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
  "libraries": {
    "contracts/base/libwallet/ERC1271Lib.sol": {
      "ERC1271Lib": "0x138a1e094f8dcc609cc734873b73566922e03a01"
    },
    "contracts/base/libwallet/ERC20Lib.sol": {
      "ERC20Lib": "0x20d3474b44dfc9ffe89054b2fb0ab326b8f5feef"
    },
    "contracts/base/libwallet/GuardianLib.sol": {
      "GuardianLib": "0x87981f325f58461965ce3fb29a7537397c1043d1"
    },
    "contracts/base/libwallet/InheritanceLib.sol": {
      "InheritanceLib": "0xd164b2669c08960bff7b61a32083b0c951b8243a"
    },
    "contracts/base/libwallet/LockLib.sol": {
      "LockLib": "0xfbdd11c07c3c2187f39f665a243dcbb605eb187f"
    },
    "contracts/base/libwallet/MetaTxLib.sol": {
      "MetaTxLib": "0x62b3cac981ca3af650fa5667709bd57ff978a9ad"
    },
    "contracts/base/libwallet/QuotaLib.sol": {
      "QuotaLib": "0xb84bd2175b6169b5a2f2e0688dcceed3b0ec93f9"
    },
    "contracts/base/libwallet/RecoverLib.sol": {
      "RecoverLib": "0x306e0fccecf5ea050446334575d8969f7b91584b"
    },
    "contracts/base/libwallet/UpgradeLib.sol": {
      "UpgradeLib": "0x71e8cccf36c53c4711cfc07a7a46cbfee0c24c46"
    },
    "contracts/base/libwallet/WhitelistLib.sol": {
      "WhitelistLib": "0xce66c3a66ea70d6653b663d3c0dbd9ee9c72001f"
    }
  }
}