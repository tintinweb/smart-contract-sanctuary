// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

interface ISigsVerifier {
    /**
     * @notice Verifies that a message is signed by a quorum among the signers.
     * @param _msg signed message
     * @param _sigs list of signatures sorted by signer addresses in ascending order
     * @param _signers sorted list of current signers
     * @param _powers powers of current signers
     */
    function verifySigs(
        bytes memory _msg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external view;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

interface IBridge {
    function send(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external;

    function relay(
        bytes calldata _relayRequest,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    function transfers(bytes32 transferId) external view returns (bool);

    function withdraws(bytes32 withdrawId) external view returns (bool);

    /**
     * @notice Verifies that a message is signed by a quorum among the signers.
     * @param _msg signed message
     * @param _sigs list of signatures sorted by signer addresses in ascending order
     * @param _signers sorted list of current signers
     * @param _powers powers of current signers
     */
    function verifySigs(
        bytes memory _msg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external view;

    // ================= peg related =================

    /**
     * @notice Lock original tokens to trigger mint at a remote chain's PeggedTokenBridge
     * @param _token local token address
     * @param _amount locked token amount
     * @param _mintChainId destination chainId to mint tokens
     * @param _mintAccount destination account to receive minted tokens
     * @param _nonce user input to guarantee unique depositId
     */
    function deposit(
        address _token,
        uint256 _amount,
        uint64 _mintChainId,
        address _mintAccount,
        uint64 _nonce
    ) external;

    /**
     * @notice Burn tokens to trigger withdrawal at a remote chain's OriginalTokenVault
     * @param _token local token address
     * @param _amount locked token amount
     * @param _withdrawAccount account who withdraw original tokens on the remote chain
     * @param _nonce user input to guarantee unique depositId
     */
    function burn(
        address _token,
        uint256 _amount,
        address _withdrawAccount,
        uint64 _nonce
    ) external;

    function records(bytes32 recordId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract MsgBusAddr is Ownable {
    address public msgBus;

    function setMsgBus(address _addr) public onlyOwner {
        msgBus = _addr;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "./MsgBusAddr.sol";

abstract contract MsgReceiverApp is MsgBusAddr {
    modifier onlyMessageBus() {
        require(msg.sender == msgBus, "caller is not message bus");
        _;
    }

    // ============== functions called by the MessageBus contract ==============

    function executeMessageWithTransfer(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message
    ) external virtual onlyMessageBus {}

    // only called if executeMessageWithTransfer was reverted
    // app needs to decide what to do with the received tokens
    function executeMessageWithTransferFallback(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message
    ) external virtual onlyMessageBus {}

    function executeMessage(
        address _sender,
        uint64 _srcChainId,
        bytes calldata _message
    ) external virtual onlyMessageBus {}
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "./MessageSender.sol";
import "./MessageReceiver.sol";

contract MessageBus is MessageSender, MessageReceiver {
    constructor(ISigsVerifier _sigsVerifier) MessageSender(_sigsVerifier) {}
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../framework/IBridge.sol";
import "../framework/MsgReceiverApp.sol";

contract MessageReceiver is Ownable {
    enum TransferType {
        Null,
        LqSend, // send through liquidity bridge
        LqWithdraw, // withdraw from liquidity bridge
        PegMint, // mint through pegged token bridge
        PegWithdraw // withdraw from original token vault
    }

    struct TransferInfo {
        TransferType t;
        address sender;
        address receiver;
        address token;
        uint256 amount;
        uint64 seqnum;
        uint64 srcChainId;
        bytes32 refId;
    }

    struct RouteInfo {
        address sender;
        address receiver;
        uint64 srcChainId;
    }

    enum TxStatus {
        Null,
        Success,
        Fail,
        Fallback
    }
    mapping(bytes32 => TxStatus) public executedTransfers; // messages with associated transfer
    mapping(bytes32 => TxStatus) public executedMessages; // messages without associated transfer

    address public liquidityBridge; // liquidity bridge address
    address public pegBridge; // peg bridge address
    address public pegVault; // peg original vault address

    enum MsgType {
        MessageWithTransfer,
        Message
    }
    event Executed(MsgType msgType, bytes32 id, TxStatus status);

    // ============== functions called by executor ==============

    function executeMessageWithTransfer(
        bytes calldata _message,
        TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external {
        bytes32 transferId = verifyTransfer(_transfer);
        require(executedTransfers[transferId] == TxStatus.Null, "transfer already executed");

        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "MessageWithTransfer"));
        IBridge(liquidityBridge).verifySigs(abi.encodePacked(domain, transferId, _message), _sigs, _signers, _powers);
        TxStatus status;
        bool ok = executeMessageWithTransfer(_transfer, _message);
        if (ok) {
            status = TxStatus.Success;
        } else {
            ok = executeMessageWithTransferFallback(_transfer, _message);
            if (ok) {
                status = TxStatus.Fallback;
            } else {
                status = TxStatus.Fail;
            }
        }
        executedTransfers[transferId] = status;
        emit Executed(MsgType.MessageWithTransfer, transferId, status);
    }

    function executeMessage(
        bytes calldata _message,
        RouteInfo calldata _route,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external {
        bytes32 messageId = ComputeMessageId(_route, _message);
        require(executedMessages[messageId] == TxStatus.Null, "message already executed");

        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "Message"));
        IBridge(liquidityBridge).verifySigs(abi.encodePacked(domain, messageId), _sigs, _signers, _powers);
        TxStatus status;
        bool ok = executeMessage(_route, _message);
        if (ok) {
            status = TxStatus.Success;
        } else {
            status = TxStatus.Fail;
        }
        executedTransfers[messageId] = status;
        emit Executed(MsgType.Message, messageId, status);
    }

    // ================= utils (to avoid stack too deep) =================

    function executeMessageWithTransfer(TransferInfo calldata _transfer, bytes calldata _message)
        private
        returns (bool)
    {
        (bool ok, ) = address(_transfer.receiver).call(
            abi.encodeWithSelector(
                MsgReceiverApp.executeMessageWithTransfer.selector,
                _transfer.sender,
                _transfer.token,
                _transfer.amount,
                _transfer.srcChainId,
                _message
            )
        );
        return ok;
    }

    function executeMessageWithTransferFallback(TransferInfo calldata _transfer, bytes calldata _message)
        private
        returns (bool)
    {
        (bool ok, ) = address(_transfer.receiver).call(
            abi.encodeWithSelector(
                MsgReceiverApp.executeMessageWithTransferFallback.selector,
                _transfer.sender,
                _transfer.token,
                _transfer.amount,
                _transfer.srcChainId,
                _message
            )
        );
        return ok;
    }

    function verifyTransfer(TransferInfo calldata _transfer) private view returns (bytes32) {
        bytes32 transferId;
        address bridgeAddr;
        if (_transfer.t == TransferType.LqSend) {
            transferId = keccak256(
                abi.encodePacked(
                    _transfer.sender,
                    _transfer.receiver,
                    _transfer.token,
                    _transfer.amount,
                    _transfer.srcChainId,
                    uint64(block.chainid),
                    _transfer.refId
                )
            );
            bridgeAddr = liquidityBridge;
            require(IBridge(bridgeAddr).transfers(transferId) == true, "bridge relay not exist");
        } else if (_transfer.t == TransferType.LqWithdraw) {
            transferId = keccak256(
                abi.encodePacked(
                    uint64(block.chainid),
                    _transfer.seqnum,
                    _transfer.receiver,
                    _transfer.token,
                    _transfer.amount
                )
            );
            bridgeAddr = liquidityBridge;
            require(IBridge(bridgeAddr).withdraws(transferId) == true, "bridge withdraw not exist");
        } else if (_transfer.t == TransferType.PegMint || _transfer.t == TransferType.PegWithdraw) {
            transferId = keccak256(
                abi.encodePacked(
                    _transfer.receiver,
                    _transfer.token,
                    _transfer.amount,
                    _transfer.sender,
                    _transfer.srcChainId,
                    _transfer.refId
                )
            );
            if (_transfer.t == TransferType.PegMint) {
                bridgeAddr = pegBridge;
            } else {
                bridgeAddr = pegVault;
            }
            require(IBridge(bridgeAddr).records(transferId) == true, "peg record not exist");
        }
        transferId = keccak256(abi.encodePacked(bridgeAddr, transferId));
        return transferId;
    }

    function ComputeMessageId(RouteInfo calldata _route, bytes calldata _message) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_route.sender, _route.receiver, _route.srcChainId, _message));
    }

    function executeMessage(RouteInfo calldata _route, bytes calldata _message) private returns (bool) {
        (bool ok, ) = address(_route.receiver).call(
            abi.encodeWithSelector(MsgReceiverApp.executeMessage.selector, _route.sender, _route.srcChainId, _message)
        );
        return ok;
    }

    // ================= contract addr config =================

    function setLiquidityBridge(address _addr) public onlyOwner {
        liquidityBridge = _addr;
    }

    function setPegBridge(address _addr) public onlyOwner {
        pegBridge = _addr;
    }

    function setPegVault(address _addr) public onlyOwner {
        pegVault = _addr;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/ISigsVerifier.sol";

contract MessageSender is Ownable {
    ISigsVerifier public immutable sigsVerifier;

    uint256 public feeBase;
    uint256 public feePerByte;
    mapping(address => uint256) public withdrawnFees;

    event Message(address indexed sender, address receiver, uint256 dstChainId, bytes message);

    event MessageWithTransfer(
        address indexed sender,
        address receiver,
        uint256 dstChainId,
        address bridge,
        bytes32 srcTransferId,
        bytes message
    );

    constructor(ISigsVerifier _sigsVerifier) {
        sigsVerifier = _sigsVerifier;
    }

    function sendMessage(
        address _receiver,
        uint256 _dstChainId,
        bytes calldata _message
    ) external payable {
        require(msg.value >= feeBase + _message.length * feePerByte, "Insufficient fee");
        emit Message(msg.sender, _receiver, _dstChainId, _message);
    }

    function sendMessageWithTransfer(
        address _receiver,
        uint256 _dstChainId,
        address _bridge,
        bytes32 _srcTransferId,
        bytes calldata _message
    ) external payable {
        require(msg.value >= feeBase + _message.length * feePerByte, "Insufficient fee");
        // SGN needs to verify
        // 1. msg.sender matches sender of the src transfer
        // 2. dstChainId matches dstChainId of the src transfer
        // 3. bridge is either liquidity bridge, peg src vault, or peg dst bridge
        emit MessageWithTransfer(msg.sender, _receiver, _dstChainId, _bridge, _srcTransferId, _message);
    }

    function withdrawFee(
        address _account,
        uint256 _cumulativeFee,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external {
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "withdrawFee"));
        sigsVerifier.verifySigs(abi.encodePacked(domain, _account, _cumulativeFee), _sigs, _signers, _powers);
        uint256 amount = _cumulativeFee - withdrawnFees[_account];
        require(amount > 0, "No new amount to withdraw");
        (bool sent, ) = _account.call{value: amount, gas: 50000}("");
        require(sent, "failed to withdraw fee");
    }

    function setFeePerByte(uint256 _fee) external onlyOwner {
        feePerByte = _fee;
    }

    function setFeeBase(uint256 _fee) external onlyOwner {
        feeBase = _fee;
    }
}