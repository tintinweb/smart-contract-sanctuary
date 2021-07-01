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
    constructor () {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IAMB {
    function messageSender() external view returns (address);

    function maxGasPerTx() external view returns (uint256);

    function transactionHash() external view returns (bytes32);

    function messageId() external view returns (bytes32);

    function messageSourceChainId() external view returns (bytes32);

    function messageCallStatus(bytes32 _messageId) external view returns (bool);

    function failedMessageDataHash(bytes32 _messageId)
        external
        view
        returns (bytes32);

    function failedMessageReceiver(bytes32 _messageId)
        external
        view
        returns (address);

    function failedMessageSender(bytes32 _messageId)
        external
        view
        returns (address);

    function requireToPassMessage(
        address _contract,
        bytes calldata _data,
        uint256 _gas
    ) external returns (bytes32);

    function requireToConfirmMessage(
        address _contract,
        bytes calldata _data,
        uint256 _gas
    ) external returns (bytes32);

    function requireToGetInformation(bytes32 _requestSelector, bytes calldata _data)
        external
        returns (bytes32);

    function sourceChainId() external view returns (uint256);

    function destinationChainId() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface ITokenManagement {
    function fixFailedMessage(bytes32 _dataHash) external;

    function handleBridgedNFT(
        address _recipient,
        uint256 _tokenId,
        string memory _name,
        uint256 _price
    ) external;

    function handleBridgedTokens(address _recipient, uint256 _tokenValue)
        external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWurlaUSD is IERC20 {
    /** @dev A mint funtion which allows the vault and mediator contracts 
     * to mint new tokens.
     */
    function mint(address _account, uint256 _amount) external;

    /** @dev A mint funtion which allows the vault and mediator contracts 
     * to mint new tokens.
     */
    function burn(uint256 _amount) external;

    /** @dev An admin transfer funtion which allows the admin or vault to 
     * transfer token balances of any account.
     */
    function adminTransfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external returns(bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAMB} from "../interfaces/IAMB.sol";
import {ITokenManagement} from "../interfaces/ITokenManagement.sol";

contract AMBMediator is Ownable {
    address public bridgeContractAddress;
    address public otherSideContractAddress;
    uint256 public requestGasLimit;

    mapping(bytes32 => bool) internal messageFixed;
    mapping(bytes32 => address) internal messageRecipient;

    /** @dev Gets an instance of the bridge contract. (IAMB) */
    function bridgeContract() public view returns (IAMB) {
        return IAMB(bridgeContractAddress);
    }

    /** @dev Gets the mediator contract address on the other side. */
    function mediatorContractOnOtherSide() public view returns (address) {
        return otherSideContractAddress;
    }
    
    /** @dev Set the bridge contract address. */
    function setBridgeContract(address _bridgeContract) external onlyOwner {
        _setBridgeContract(_bridgeContract);
    }

    function _setBridgeContract(address _bridgeContract) internal {
        bridgeContractAddress = _bridgeContract;
    }

    /** @dev Set the mediator contract address on the other side. */
    function setMediatorContractOnOtherSide(address _mediatorContract)
        external
        onlyOwner
    {
        _setMediatorContractOnOtherSide(_mediatorContract);
    }

    function _setMediatorContractOnOtherSide(address _mediatorContract)
        internal
    {
        otherSideContractAddress = _mediatorContract;
    }

    /** @dev Set the request gas limit. */
    function setRequestGasLimit(uint256 _requestGasLimit) external onlyOwner {
        _setRequestGasLimit(_requestGasLimit);
    }

    function _setRequestGasLimit(uint256 _requestGasLimit) internal {
        require(
            _requestGasLimit <= bridgeContract().maxGasPerTx(),
            "AMBMediator: Request gas limit exceeds the bridge contract max gas per txn."
        );
        requestGasLimit = _requestGasLimit;
    }

    /** @dev In case handleBridged function fails, the user can call this
     * method to request a fix for the transfer performed.
     */
    function requestFailedMessageFix(bytes32 _messageId) external {
        require(
            !bridgeContract().messageCallStatus(_messageId),
            "AMBMediator: Your message did not fail."
        );
        require(
            bridgeContract().failedMessageReceiver(_messageId) == address(this),
            "AMBMediator: This request is not for this address."
        );
        require(
            bridgeContract().failedMessageSender(_messageId) ==
                mediatorContractOnOtherSide(),
            "AMBMediator: The message sender is not the mediator contract on the other side."
        );

        bytes4 methodSelector = ITokenManagement(address(0))
        .fixFailedMessage
        .selector;
        bytes memory data = abi.encodeWithSelector(methodSelector, _messageId);
        bridgeContract().requireToPassMessage(
            mediatorContractOnOtherSide(),
            data,
            requestGasLimit
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {IWurlaUSD} from "../interfaces/IWurlaUSD.sol";
import {AMBMediator} from "./AMBMediator.sol";

abstract contract ERC20Mediator is AMBMediator {
    IWurlaUSD public token;
    mapping(bytes32 => uint256) internal messageAmount;

    constructor(address _token) {
        token = IWurlaUSD(_token);
    }

    /** @dev relayTokens is called by the user to send their 
     * tokens to this ERC20 mediator contract to lock/burn. The following 
     * action will depend on whether you're calling this on the 
     * foreign or home chain, respectively.
     */
    function relayTokens(uint256 _tokenAmount) external {
        token.transferFrom(msg.sender, address(this), _tokenAmount);
        bridgeSpecificActionsOnTokenTransfer(msg.sender, _tokenAmount);
    }
    
    /** @dev This is the side/bridge/chain specific action which
     * we need to implement in both the foreign and home
     * mediators.
     */
    function bridgeSpecificActionsOnTokenTransfer(
        address _recipient,
        uint256 _tokenAmount
    ) internal virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {ERC20Mediator} from "./ERC20Mediator.sol";
import {ITokenManagement} from "../interfaces/ITokenManagement.sol";

contract ForeignERC20Mediator is ERC20Mediator {
    constructor(
        address _token,
        address _bridge,
        address _otherSideMediator,
        uint256 _gasLimit
    ) ERC20Mediator(_token) {
        _setBridgeContract(_bridge);
        _setMediatorContractOnOtherSide(_otherSideMediator);
        _setRequestGasLimit(_gasLimit);
    }

    modifier onlyMediatorBridgeContract() {
        require(
            msg.sender == address(bridgeContract()),
            "ForeignERC20Mediator: The caller is not the bridge contract."
        );
        require(
            bridgeContract().messageSender() == mediatorContractOnOtherSide(),
            "ForeignERC20Mediator: The message sender is not the mediator contract on the other side."
        );
        _;
    }

    /** @dev Sends a message call to the other side's mediator contract upon
     * the user transferring their tokens into the contract to be sent to the
     * other side.
     */
    function bridgeSpecificActionsOnTokenTransfer(
        address _recipient,
        uint256 _amount
    ) internal override {
        bytes4 methodSelector = ITokenManagement(address(0))
        .handleBridgedTokens
        .selector;
        bytes memory data = abi.encodeWithSelector(
            methodSelector,
            _recipient,
            _amount
        );

        bytes32 messageId = bridgeContract().requireToPassMessage(
            mediatorContractOnOtherSide(),
            data,
            requestGasLimit
        );
        messageAmount[messageId] = _amount;
        messageRecipient[messageId] = _recipient;
    }

    /** @dev Handles a message call from the home side's mediator contract.
     * We transfer the tokens to the _recipient on the this side (foreign).
     */
    function handleBridgedTokens(
        address _recipient,
        uint256 _amount
    ) external onlyMediatorBridgeContract {
        bool success = token.adminTransfer(address(this), _recipient, _amount);
        require(success, "ForeignERC20Mediator: Token transfer failed.");
    }

    /** @dev Allows the user to call requestFailedMessageFix
     * via the bridge and other side's mediator contract.
     */
    function fixFailedMessage(bytes32 _messageId)
        external
        onlyMediatorBridgeContract
    {
        require(!messageFixed[_messageId], "ForeignERC20Mediator: The message has already been fixed.");
        address recipient = messageRecipient[_messageId];
        uint256 amount = messageAmount[_messageId];
        messageFixed[_messageId] = true;
        bool success = token.adminTransfer(address(this), recipient, amount);
        require(success, "ForeignERC20Mediator: Token transfer failed.");
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 800
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}