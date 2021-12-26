// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./core/BridgeCore.sol";
import "./interface/ListNodeInterface.sol";

//TODO: onlyTrustedNode has worse filled data. I.e. In func NodeList#addNode the golang node registers himself
// and this means every node who wants to start up can add himself in onlyTrustedNode list.
contract Bridge is BridgeCore {
    string public versionRecipient = "2.2.3";

    constructor (address listNode, address forwarder) {
        _listNode = listNode;

        /* hotfix: due error go run wrappers-builder/main.go --json "hardhat/artifacts/contracts/bridge"/Bridge.sol --pkg wrappers --out wrappers
         * FATA[0000] duplicated identifier "_owner"(normalized "Owner"), use --alias for renaming 
         * Should delete in future
         */
        //_owner    = msg.sender; 
        _setTrustedForwarder(forwarder);
    }

    modifier onlyTrustedNode() {
        require(ListNodeInterface(_listNode).checkPermissionTrustList(msg.sender) == true, "Only trusted node can invoke");
        _;
    }

    modifier onlyTrustedContract(address receiveSide, address oppositeBridge) {
        require(contractBind[msg.sender][oppositeBridge] == receiveSide, "UNTRUSTED CONTRACT");
        _;
    }

    function setTrustedForwarder(address _forwarder) external onlyOwner {
       return _setTrustedForwarder(_forwarder);
    }

    function transmitRequestV2(
        bytes memory _selector,
        address receiveSide,
        address oppositeBridge,
        uint256 chainId
    )
        external
        onlyTrustedContract(receiveSide, oppositeBridge)
        returns (bytes32){

        bytes32 requestId = prepareRqId(_selector, oppositeBridge, chainId, receiveSide);
        nonce[oppositeBridge][receiveSide] = nonce[oppositeBridge][receiveSide] + 1;
        emit OracleRequest("setRequest", address(this), requestId, _selector, receiveSide, oppositeBridge, chainId);
        return requestId;
    }

    function receiveRequestV2(
        bytes32 reqId,
        bytes memory b,
        address receiveSide,
        address bridgeFrom
    ) external onlyTrustedNode {

        address senderSide = contractBind[receiveSide][bridgeFrom];
        bytes32 recreateReqId = keccak256(abi.encodePacked(nonce[bridgeFrom][senderSide], b, block.chainid));
        //TODO refactor check synced crosschain nonces
//        require(reqId == recreateReqId, 'CONSISTENCY FAILED');
        (bool success, bytes memory data) = receiveSide.call(b);
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'FAILED');
        nonce[bridgeFrom][senderSide] = nonce[bridgeFrom][senderSide] + 1;

        emit ReceiveRequest(reqId, receiveSide, bridgeFrom, senderSide);
    }
}

// SPDX-License-Identifier: MIT

import "../../amm_pool/RelayRecipient.sol";

pragma solidity ^0.8.0;

contract BridgeCore is RelayRecipient {

    /* hotfix: due error go run wrappers-builder/main.go --json "hardhat/artifacts/contracts/bridge"/Bridge.sol --pkg wrappers --out wrappers
     * FATA[0000] duplicated identifier "_owner"(normalized "Owner"), use --alias for renaming 
     * Should delete in future
     */
    //address public _owner;
    address public _listNode;

    /* bridge => nonce */
    mapping(address => mapping(address => uint256)) internal nonce;
    mapping(address => mapping(address => address)) internal contractBind;
    mapping(address => bool) private is_in;

    event OracleRequest(
        string  requestType,
        address bridge,
        bytes32 requestId,
        bytes   selector,
        address receiveSide,
        address oppositeBridge,
        uint chainid
    );

    event ReceiveRequest(bytes32 reqId, address receiveSide, address bridgeFrom, address senderSide);

    /*modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }*/

    /**
       Mandatory for participants who wants to use a own contracts
       1. Contract A (chain A) should be bind with Contract B (chain B) only once! It's not allowed to  switch Contract A (chain A) to Contract C (chain B). This mandatory
       for prevent malicious behaviour.
       2. Contract A (chain A) could be bind with several contracts where every contract from another chain. For ex: Contract A (chain A) --> Contract B (chain B) + Contract A (chain A) --> Contract B' (chain B') ... etc
    */
    function addContractBind(address from, address oppositeBridge, address to) external {
        require(to   != address(0), "NULL ADDRESS TO");
        require(from != address(0), "NULL ADDRESS FROM");
        require(is_in[to] == false, "TO ALREADY EXIST");
        // for prevent malicious behaviour like switching between older and newer contracts
        require(contractBind[from][oppositeBridge] == address(0), "UPDATE DOES NOT ALLOWED");
        contractBind[from][oppositeBridge] = to;
        is_in[to] = true;

    }

    function prepareRqId(bytes memory  _selector, address oppositeBridge, uint256 chainId, address receiveSide) internal view returns (bytes32) {
        bytes32 requestId = keccak256(abi.encodePacked(nonce[oppositeBridge][receiveSide], _selector, chainId));
        return requestId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice  List of registred nodes
 * 
 * @dev This should be implemented every part of bridge.
 */
interface ListNodeInterface {
	/**
	*  @notice Should has prmission for invoke bridge
	*/
	function checkPermissionTrustList(address node) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-newone/access/Ownable.sol";
import "@openzeppelin/contracts-newone/utils/Context.sol";

abstract contract RelayRecipient is Context, Ownable {
   
    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }

}

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