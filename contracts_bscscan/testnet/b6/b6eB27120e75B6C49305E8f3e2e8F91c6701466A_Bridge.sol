// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./core/BridgeCore.sol";
import "./interface/ListNodeInterface.sol";

//TODO: onlyTrustedNode has worse filled data. I.e. In func NodeList#addNode the golang node registers himself
// and this means every node who wants to start up can add himself in onlyTrustedNode list.
contract Bridge is BridgeCore {

    constructor (address listNode) {
        _listNode = listNode;
        _owner    = msg.sender;
    }

    modifier onlyTrustedNode() {
        require(ListNodeInterface(_listNode).checkPermissionTrustList(msg.sender) == true, "Only trusted node can invoke");
        _;
    }

    modifier onlyTrustedContract(address receiveSide, address oppositeBridge) {
        require(contractBind[msg.sender][oppositeBridge] == receiveSide, "UNTRUSTED CONTRACT");
        _;
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
        //TODO: When tx in source chain got stuck this code line broke all process. Need some compensation tx ?
        //require(reqId == recreateReqId, 'CONSISTENCY FAILED');
        (bool success, bytes memory data) = receiveSide.call(b);
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'FAILED');
        nonce[bridgeFrom][senderSide] = nonce[bridgeFrom][senderSide] + 1;

        emit ReceiveRequest(reqId, receiveSide, bridgeFrom, senderSide);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract BridgeCore {

    address public _owner;
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

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

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
pragma solidity >=0.7.6 <=0.8.0;

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

