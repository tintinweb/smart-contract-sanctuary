// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IFxERC1155} from "../../tokens/IFxERC1155.sol";
import {ERC1155Holder} from "../../lib/ERC1155Holder.sol" ;
import { Create2 } from "../..//lib/Create2.sol";
import { FxBaseChildTunnel } from "../../tunnel/FxBaseChildTunnel.sol";

contract FxERC1155ChildTunnel is FxBaseChildTunnel, Create2, ERC1155Holder {
      bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
      bytes32 public constant DEPOSIT_BATCH = keccak256("DEPOSIT_BATCH");
      bytes32 public constant WITHDRAW = keccak256("WITHDRAW");
      bytes32 public constant WITHDRAW_BATCH = keccak256("WITHDRAW_BATCH");
      bytes32 public constant MAP_TOKEN = keccak256("MAP_TOKEN");
      //string public constant URI = "FXERC1155URI" ;
      
      event TokenMapped(address indexed rootToken, address indexed childToken);
      // root to child token
      mapping(address => address) public rootToChildToken;
      address public tokenTemplate;
      
      constructor(address _fxChild, address _tokenTemplate) FxBaseChildTunnel(_fxChild) {
        tokenTemplate = _tokenTemplate;
        require(_isContract(_tokenTemplate), "Token template is not contract");
      }
      
      function withdraw(address childToken, uint256 id, uint256 amount, bytes memory data) public {
          IFxERC1155 childTokenContract = IFxERC1155(childToken);
          address rootToken = childTokenContract.connectedToken();
          
          require(
            childToken != address(0x0) &&
            rootToken != address(0x0) && 
            childToken == rootToChildToken[rootToken], 
            "FxERC1155ChildTunnel: NO_MAPPED_TOKEN"
        );
        
        childTokenContract.burn(msg.sender, id, amount);
        
         bytes memory message = abi.encode(WITHDRAW, abi.encode(rootToken, childToken, msg.sender, id, amount, data));
         _sendMessageToRoot(message);
      } 
      
      function withdrawBatch(address childToken, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public {
          IFxERC1155 childTokenContract = IFxERC1155(childToken);
          address rootToken = childTokenContract.connectedToken();
          
          require(
            childToken != address(0x0) &&
            rootToken != address(0x0) && 
            childToken == rootToChildToken[rootToken], 
            "FxERC1155ChildTunnel: NO_MAPPED_TOKEN"
        );
        
        childTokenContract.burnBatch(msg.sender, ids, amounts);
        
        bytes memory message = abi.encode(WITHDRAW_BATCH, abi.encode(rootToken, childToken, msg.sender, ids, amounts, data));
         _sendMessageToRoot(message);
      } 
     
     function _processMessageFromRoot(uint256 /* stateId */, address sender, bytes memory data)
        internal
        override
        validateSender(sender) {
            
            (bytes32 syncType, bytes memory syncData) = abi.decode(data, (bytes32, bytes));
            
            if(syncType == MAP_TOKEN) {
                _mapToken(syncData);
            }
            
            else if(syncType == DEPOSIT) {
                _syncDeposit(syncData);
            }
            
            else if(syncType == DEPOSIT_BATCH) {
                _syncDepositBatch(syncData);
            }
            
            else {
                revert("FxERC1155ChildTunnel: INVALID_SYNC_TYPE");
            }
      }
      
      function _mapToken(bytes memory syncData) internal returns (address) {
          (address rootToken, string memory uri) = abi.decode(syncData , (address, string));
          
          address childToken = rootToChildToken[rootToken];
          require(childToken == address(0x0), "FxERC1155ChildTunnel: ALREADY_MAPPED");
          
          bytes32 salt = keccak256(abi.encodePacked(rootToken));
          childToken = createClone(salt, tokenTemplate);
          IFxERC1155(childToken).initialize(address(this),rootToken, string(abi.encodePacked(uri)));
          
          rootToChildToken[rootToken] = childToken;
          emit TokenMapped(rootToken, childToken);

          return childToken;
      }
      
      function _syncDeposit(bytes memory syncData) internal {
          (address rootToken, address depositor, address user, uint256 id, uint256 amount, bytes memory data) = abi.decode(syncData, (address, address, address, uint256, uint256, bytes));
          
          address childToken = rootToChildToken[rootToken];
          IFxERC1155 childTokenContract = IFxERC1155(childToken);
          
          childTokenContract.mint(user, id, amount, data);
          
      }
      
      function _syncDepositBatch(bytes memory syncData) internal {
          (address rootToken, address depositor, address user, uint256[] memory ids, uint256[] memory amounts, bytes memory data) = abi.decode(syncData, (address, address, address, uint256[], uint256[], bytes));
          
          address childToken = rootToChildToken[rootToken];
          IFxERC1155 childTokenContract = IFxERC1155(childToken);
          
          childTokenContract.mintBatch(user, ids, amounts, data);
    
      }
      
     
      function _isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFxERC1155 {
    function fxManager() external returns(address);
    function initialize(address fxManager_, address connectedToken_, string memory uri_) external;
    function connectedToken() external returns(address);
    function mint(address user, uint256 id, uint256 amount, bytes memory data) external;
    function mintBatch(address user, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
    function burn(address user, uint256 id, uint256 amount) external;
    function burnBatch(address user, uint256[] memory ids, uint256[] memory amounts) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// Create2 adds common methods for minimal proxy with create2
abstract contract Create2 {
    // creates clone using minimal proxy
    function createClone(bytes32 _salt, address _target) internal returns (address _result) {
        bytes20 _targetBytes = bytes20(_target);

        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), _targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            _result := create2(0, clone, 0x37, _salt)
        }

        require(_result != address(0), "Create2: Failed on minimal deploy");
    }

    // get minimal proxy creation code
    function minimalProxyCreationCode(address logic) internal pure returns (bytes memory) {
        bytes10 creation = 0x3d602d80600a3d3981f3;
        bytes10 prefix = 0x363d3d373d3d3d363d73;
        bytes20 targetBytes = bytes20(logic);
        bytes15 suffix = 0x5af43d82803e903d91602b57fd5bf3;
        return abi.encodePacked(creation, prefix, targetBytes, suffix);
    }

    // get computed create2 address
    function computedCreate2Address(bytes32 salt, bytes32 bytecodeHash, address deployer) public pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

/**
* @notice Mock child tunnel contract to receive and send message from L2
*/
abstract contract FxBaseChildTunnel is IFxMessageProcessor{
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory message) virtual internal;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155Receiver.sol";
import "./ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId
            || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

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

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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