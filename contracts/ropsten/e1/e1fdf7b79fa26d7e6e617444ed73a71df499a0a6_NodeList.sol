pragma solidity ^0.4.24;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts/NodeList.sol

// pragma experimental ABIEncoderV2;

// import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
// import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";



contract NodeList is Ownable {
    using SafeMath for uint256;

    struct NodeInfo {
        bytes16 ipAddr;
        uint16 portNumber;
    }

    // index to nodeID
    mapping(uint256=>uint256) private nodeIndex;
    // nodeID to index
    mapping(uint256=>uint256) private nodeIndexLookup;
    uint256 nodeIndexLength;
    NodeInfo[] private allNodes;

    function registerNode(bytes16 ipAddr, uint16 portNumber) public onlyOwner {
        NodeInfo memory nodeInfo = NodeInfo(ipAddr, portNumber);
        allNodes.push(nodeInfo);
        uint256 nodeID = allNodes.length.sub(1);
        nodeIndex[nodeIndexLength] = nodeID;
        nodeIndexLookup[nodeID] = nodeIndexLength;
        nodeIndexLength = nodeIndexLength.add(1);
    }

    // function getNode() public view returns(NodeInfo[]) {
    //     NodeInfo[] memory availableNodeInfo = new NodeInfo[](nodeIndexLength);
    //     for (uint256 i = 0; i < nodeIndexLength; i++) {
    //         availableNodeInfo[i] = allNodes[nodeIndex[i]];
    //     }
    //     return availableNodeInfo;
    // }

    function getNodeLength() public view returns(uint256) {
        return nodeIndexLength;
    }

    function getNodeByIndex(uint256 index) public view returns(uint256, bytes16, uint16) {
        require(index < nodeIndexLength, "invalid index");
        return (
            nodeIndex[index],
            allNodes[nodeIndex[index]].ipAddr,
            allNodes[nodeIndex[index]].portNumber
        );
    }

    function unregisterNode(uint256 nodeID) public onlyOwner {
        uint256 unregisterNodeIndex = nodeIndexLookup[nodeID];
        require(nodeIndex[unregisterNodeIndex] == nodeID, "nodeID not found");
        uint256 lastNodeID = nodeIndex[nodeIndexLength.sub(1)];
        uint256 lastNodeIndex = nodeIndexLookup[lastNodeID];
        nodeIndex[unregisterNodeIndex] = lastNodeIndex;
        nodeIndexLookup[lastNodeID] = unregisterNodeIndex;
        nodeIndexLength = nodeIndexLength.sub(1);
    }
}