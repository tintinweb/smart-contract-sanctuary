// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

/**
 * @title Generic Erc-20 Interface
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Generic Cash Token Interface
 */
interface ICash is IERC20 {
    function mint(address account, uint128 principal) external returns (uint);
    function burn(address account, uint amount) external returns (uint128);
    function setFutureYield(uint128 nextYield, uint128 nextIndex, uint nextYieldStartAt) external;
    function getCashIndex() external view returns (uint128);
}

/**
 * @title Non-Standard Erc-20 Interface for tokens which do not return from `transfer` or `transferFrom`
 */
interface INonStandardERC20 {
    function transfer(address recipient, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;
pragma abicoder v2;

import "./ICash.sol";

/**
 * @title Compound Chain Starport
 * @author Compound Finance
 * @notice Contract to link Ethereum to Compound Chain
 */
contract Starport {
    ICash immutable public cash;

    address immutable public admin;
    address constant public ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    bytes4 constant MAGIC_HEADER = "ETH:";
    string constant ETH_CHAIN = "ETH";
    address[] public authorities;
    mapping(address => uint) public supplyCaps;

    uint public eraId; // TODO: could bitpack here and use uint32
    mapping(bytes32 => bool) public isNoticeInvoked;

    event NoticeInvoked(uint32 indexed eraId, uint32 indexed eraIndex, bytes32 indexed noticeHash, bytes result);
    event NoticeReplay(bytes32 indexed noticeHash);

    event Lock(address indexed asset, address indexed sender, string chain, bytes32 indexed recipient, uint amount);
    event LockCash(address indexed sender, string chain, bytes32 indexed recipient, uint amount, uint128 principal);
    event ExecTrxRequest(address indexed account, string trxRequest);
    event Unlock(address indexed account, uint amount, address asset);
    event UnlockCash(address indexed account, uint amount, uint128 principal);
    event ChangeAuthorities(address[] newAuthorities);
    event SetFutureYield(uint128 nextCashYield, uint128 nextCashYieldIndex, uint nextCashYieldStart);
    event ExecuteProposal(string title, bytes[] extrinsics);
    event NewSupplyCap(address indexed asset, uint supplyCap);

    constructor(ICash cash_, address admin_) {
        cash = cash_;
        admin = admin_;
    }

    /**
     * Section: Ethereum Asset Interface
     */

    /**
     * @notice Transfer an asset to Compound Chain via locking it in the Starport
     * @dev Use `lockEth` to lock Ether. Note: locking CASH will burn the CASH from Ethereum.
     * @param amount The amount (in the asset's native wei) to lock
     * @param asset The asset to lock in the Starport
     */
    function lock(uint amount, address asset) external {
        lockTo(amount, asset, ETH_CHAIN, toBytes32(msg.sender));
    }

    /**
     * @notice Transfer an asset to Compound Chain via locking it in the Starport
     * @dev Use `lockEth` to lock Ether. Note: locking CASH will burn the CASH from Ethereum.
     * @param amount The amount (in the asset's native wei) to lock
     * @param asset The asset to lock in the Starport
     * @param chain The chain of the recipient, e.g. "ETH" for Ethereum
     * @param recipient The recipient of the asset in Compound Chain
     */
    function lockTo(uint amount, address asset, string memory chain, bytes32 recipient) public {
        require(asset != ETH_ADDRESS, "Please use lockEth");

        if (asset == address(cash)) {
            lockCashInternal(amount, chain, recipient);
        } else {
            lockAssetInternal(amount, asset, chain, recipient);
        }
    }

    /*
     * @notice Transfer Eth to Compound Chain via locking it in the Starport
     * @dev Use `lock` to lock CASH or collateral assets.
     */
    function lockEth() public payable {
        lockEthTo(ETH_CHAIN, toBytes32(msg.sender));
    }

    /*
     * @notice Transfer Eth to Compound Chain via locking it in the Starport
     * @param chain The chain of the recipient, e.g. "ETH" for Ethereum
     * @param recipient The recipient of the Eth on Compound Chain
     * @dev Use `lock` to lock CASH or collateral assets.
     */
    function lockEthTo(string memory chain, bytes32 recipient) public payable {
        require(address(this).balance <= supplyCaps[ETH_ADDRESS], "Supply Cap Exceeded");
        emit Lock(ETH_ADDRESS, msg.sender, chain, recipient, msg.value);
    }

    /*
     * @notice Emits an event s.t. a given trx request will execute as if called by `msg.sender`
     * @dev Externally-owned accounts may call `execTrxRequest` with a signed message to avoid Ethereum fees.
     * @param trxRequest An ASCII-encoded transaction request
     */
    function execTrxRequest(string calldata trxRequest) public payable {
        emit ExecTrxRequest(msg.sender, trxRequest);
    }

    /**
     * @notice Internal function for locking CASH (as opposed to collateral assets)
     * @dev Locking CASH will burn the CASH (as it's being transfer to Compound Chain)
     * @param amount The amount of CASH to lock and burn.
     * @param chain The chain of the recipient, e.g. "ETH" for Ethereum
     * @param recipient The recipient of the asset in Compound Chain
     */
    function lockCashInternal(uint amount, string memory chain, bytes32 recipient) internal {
        uint128 principal = cash.burn(msg.sender, amount);
        emit LockCash(msg.sender, chain, recipient, amount, principal);
    }

    /**
     * @notice Internal function for locking non-ETH collateral assets
     * @param amount The amount of the asset to lock.
     * @param asset The asset to lock.
     * @param chain The chain of the recipient, e.g. "ETH" for Ethereum
     * @param recipient The recipient of the asset in Compound Chain
     */
    function lockAssetInternal(uint amount, address asset, string memory chain, bytes32 recipient) internal {
        uint amountTransferred = transferAssetIn(msg.sender, amount, asset);
        require(IERC20(asset).balanceOf(address(this)) <= supplyCaps[asset], "Supply Cap Exceeded");
        emit Lock(asset, msg.sender, chain, recipient, amountTransferred);
    }

    // Transfer in an asset, returning the balance actually accrued (i.e. less token fees)
    // Note: do not use for Ether or CASH
    function transferAssetIn(address from, uint amount, address asset) internal returns (uint) {
        uint balanceBefore = IERC20(asset).balanceOf(address(this));
        INonStandardERC20(asset).transferFrom(from, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {                       // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                      // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of external call
                }
                default {                      // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "transferAssetIn failed");

        uint balanceAfter = IERC20(asset).balanceOf(address(this));
        return balanceAfter - balanceBefore;
    }

    // Transfer out an asset
    // Note: we do not check fees here, since we do not account for them on transfer out
    function transferAssetOut(address to, uint amount, address asset) internal {
        INonStandardERC20(asset).transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {                       // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                      // This is a complaint ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of external call
                }
                default {                      // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "transferAssetOut failed");
    }

    /**
     * @notice Executes governance proposal on Compound Chain
     * @dev This must be called from the admin, which should be the Compound Timelock
     * @param extrinsics SCALE-encoded extrinsics that can execute on Compound Chain
     */
    function executeProposal(string calldata title, bytes[] calldata extrinsics) external {
        require(msg.sender == admin, "Call must originate from admin");

        emit ExecuteProposal(title, extrinsics);
    }

    /*
     * @notice Transfer Eth to Compound Chain via locking it in the Starport
     * @dev This is a shortcut for `lockEth`. See `lockEth` for more details.
     */
    receive() external payable {
        lockEth();
    }

    /**
     * Section: L2 Message Ports
     **/

    /**
     * @notice Invoke a signed notice from the Starport, which will execute a function such as unlock.
     * @dev Notices are generated by certain actions from Compound Chain and signed by validators.
     * @param notice The notice generated by Compound Chain, encoded for Ethereum.
     * @param signatures Signatures from a quorum of validator nodes from Compound Chain.
     * @return The result of the invokation of the action of the notice.
     */
    function invoke(bytes calldata notice, bytes[] calldata signatures) external returns (bytes memory) {
        bytes32 noticeHash = hashNotice(notice);
        checkNoticeSignerAuthorized(noticeHash, authorities, signatures);

        return invokeNoticeInternal(notice, noticeHash);
    }

    /**
     * @notice Invoke a notice by passing a chain of notices the head of which has already been accepted
     * @dev As an alternative to `invoke`, for instance, after authorities have been rotated.
     * @param notice The notice generated by Compound Chain, encoded for Ethereum.
     * @param notices A chain of notices, the tail of which must have already been accepted
     * @return The result of the invokation of the action of the notice.
     */
    function invokeChain(bytes calldata notice, bytes[] calldata notices) external returns (bytes memory) {
        bytes32 noticeHash = hashNotice(notice);
        checkNoticeChainAuthorized(noticeHash, notices);

        return invokeNoticeInternal(notice, noticeHash);
    }

    // Invoke without authorization checks used by external functions
    function invokeNoticeInternal(bytes calldata notice, bytes32 noticeHash) internal returns (bytes memory) {
        if (isNoticeInvoked[noticeHash]) {
            emit NoticeReplay(noticeHash);
            return "";
        }

        isNoticeInvoked[noticeHash] = true;

        require(notice.length >= 100, "Must have full header"); // 4 + 3 * 32
        require(notice[0] == MAGIC_HEADER[0], "Invalid header[0]");
        require(notice[1] == MAGIC_HEADER[1], "Invalid header[1]");
        require(notice[2] == MAGIC_HEADER[2], "Invalid header[2]");
        require(notice[3] == MAGIC_HEADER[3], "Invalid header[3]");

        (uint noticeEraId, uint noticeEraIndex, bytes32 noticeParent) =
            abi.decode(notice[4:100], (uint, uint, bytes32));

        noticeParent; // unused

        bool startNextEra = noticeEraId == eraId + 1 && noticeEraIndex == 0;

        require(
            noticeEraId <= eraId || startNextEra,
            "Notice must use existing era or start next era"
        );

        if (startNextEra) {
            eraId++;
        }

        bytes memory calldata_ = bytes(notice[100:]);
        (bool success, bytes memory callResult) = address(this).call(calldata_);
        if (!success) {
            require(false, _getRevertMsg(callResult));
        }

        emit NoticeInvoked(uint32(noticeEraId), uint32(noticeEraIndex), noticeHash, callResult);

        return callResult;
    }

    /**
     * @notice Unlock the given asset from the Starport
     * @dev This must be called from `invoke` via passing in a signed notice from Compound Chain.
     * @dev Note: for Cash token, we would expect to use `unlockCash` which mints the CASH.
     * @param asset The Asset to unlock
     * @param amount The amount of the asset to unlock in its native token units
     * @param account The account to transfer the asset to
     */
    function unlock(address asset, uint amount, address payable account) external {
        require(msg.sender == address(this), "Call must originate locally");

        emit Unlock(account, amount, asset);

        if (asset == ETH_ADDRESS) {
            account.transfer(amount);
        } else {
            transferAssetOut(account, amount, asset);
        }
    }

    /**
     * @notice Unlock CASH from the Starport by minting
     * @dev This must be called from `invoke` via passing in a signed notice from Compound Chain.
     * @param account The account to transfer the asset to
     * @param principal The principal of CASH to unlock
     */
    function unlockCash(address account, uint128 principal) external {
        require(msg.sender == address(this), "Call must originate locally");

        uint256 amount = cash.mint(account, principal);
        emit UnlockCash(account, amount, principal);
    }

    /**
     * @notice Rotates authorities which can be used to sign notices for the Staport
     * @dev This must be called from `invoke` via passing in a signed notice from Compound Chain or by the admin.
     * @param newAuthorities The new authorities which may sign notices for execution by the Starport
     */
    function changeAuthorities(address[] calldata newAuthorities) external {
        require(msg.sender == address(this) || msg.sender == admin, "Call must be by notice or admin");
        require(newAuthorities.length > 0, "New authority set can not be empty");

        emit ChangeAuthorities(newAuthorities);

        authorities = newAuthorities;
    }

    /**
     * @notice Sets the supply cap for a given asset.
     * @dev This must be called from `invoke` via passing in a signed notice from Compound Chain or by the admin.
     * @dev Note: supply caps start at zero. This must be called to allow an asset to be locked in the Starport.
     * @param asset The asset to set the supply cap for. This may be Ether Token but may not be CASH.
     * @param supplyCap The cap to put on the asset, in its native token units.
     */
    function setSupplyCap(address asset, uint supplyCap) external {
        require(msg.sender == address(this) || msg.sender == admin, "Call must be by notice or admin");
        require(asset != address(cash), "Cash does not accept supply cap");

        emit NewSupplyCap(asset, supplyCap);

        supplyCaps[asset] = supplyCap;
    }

    /**
     * @notice Sets the yield of the CASH token for some future time.
     * @dev This must be called from `invoke` via passing in a signed notice from Compound Chain or by the admin.
     * @param nextCashYield The yield to set
     * @param nextCashYieldIndex The pre-calculated index at change-over for error correction
     * @param nextCashYieldStart When the yield change-over should occur
     */
    function setFutureYield(uint128 nextCashYield, uint128 nextCashYieldIndex, uint nextCashYieldStart) external {
        require(msg.sender == address(this) || msg.sender == admin, "Call must be by notice or admin");

        emit SetFutureYield(nextCashYield, nextCashYieldIndex, nextCashYieldStart);
        cash.setFutureYield(nextCashYield, nextCashYieldIndex, nextCashYieldStart);
    }

    /**
     * Section: View Helpers
     */

    /**
     * @notice Returns the current authority nodes
     * @return The current authority node addresses
     */
    function getAuthorities() public view returns (address[] memory) {
        return authorities;
    }

    /**
     * @notice Checks that the given notice is authorized
     * @dev Notices are authorized by having a quorum of signatures from the `authorities` set
     * @dev Notices can be separately validated by a notice chain
     * @dev Reverts if notice is not authorized
     * @param noticeHash Hash of the given notice
     * @param authorities_ A set of authorities to check the notice against
     * @param signatures The signatures to verify
     */
    function checkNoticeSignerAuthorized(
        bytes32 noticeHash,
        address[] memory authorities_,
        bytes[] calldata signatures
    ) internal pure {
        address[] memory sigs = new address[](signatures.length);
        uint sigsLen = 0;
        uint authorityCount = authorities_.length;

        for (uint i = 0; i < signatures.length; i++) {
            address signer = recover(noticeHash, signatures[i]);
            bool duplicate = contains(sigs, signer, sigsLen);
            bool authorized = contains(authorities_, signer, authorityCount);
            if (authorized && !duplicate) {
                sigs[sigsLen++] = signer;
            }
        }

        require(sigsLen >= getQuorum(authorities_.length), "Below quorum threshold");
    }

    /**
     * @notice Checks that the given target notice is valid by chaining
     * @dev Notices each contain a hash of the parent, and thus any previous notice can be
     * @dev included by showing a chain of notices connecting to an already accepted notice.
     * @param targetHash Hash of the target notice to verify
     * @param notices A list of notices where the tail notice must already be accepted in the chain
     */
    function checkNoticeChainAuthorized(
        bytes32 targetHash,
        bytes[] calldata notices
    ) internal view {
        bytes32 currHash = targetHash;

        for (uint i = 0; i < notices.length; i++) {
            require(getParentHash(notices[i]) == currHash, "Notice hash mismatch");
            currHash = hashNotice(notices[i]);
        }

        require(isNoticeInvoked[currHash] == true, "Tail notice must have been accepted");
    }

    /**
     * Section: Pure Function Helpers
     */

    // Helper function to hash a notice
    function hashNotice(bytes calldata data) internal pure returns (bytes32) {
        return keccak256((abi.encodePacked(data)));
    }

    // Helper function to check if a given list contains an element
    function contains(address[] memory arr, address elem, uint len) internal pure returns (bool) {
        for (uint i = 0; i < len; i++) {
            if (arr[i] == elem) {
                return true;
            }
        }
        return false;
    }

    // Helper function to get parent hash from a notice
    // Note: we don't check much about the notices, but since we're verifying
    //       by notice hashes, we should be secure.
    // TODO: Consider if we should use the full decoding check from above?
    function getParentHash(bytes calldata notice) pure internal returns (bytes32) {
        require(notice.length >= 100, "Must have full header"); // 4 + 3 * 32
        (bytes32 noticeParent) =
            abi.decode(notice[68:100], (bytes32));

        return noticeParent;
    }

    // Quorum is >1/3 authorities approving (XXX TODO: 1/3??)
    function getQuorum(uint authorityCount) internal pure returns (uint) {
        return (authorityCount / 3) + 1;
    }

    // Adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol
    function recover(bytes32 digest, bytes memory signature) internal pure returns (address) {
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

        // XXX Does this mean EIP-155 signatures are considered invalid?
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(digest, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return 'Call failed';

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    function toBytes32(address addr) public pure returns (bytes32) {
        return bytes32(bytes20(addr));
    }
}