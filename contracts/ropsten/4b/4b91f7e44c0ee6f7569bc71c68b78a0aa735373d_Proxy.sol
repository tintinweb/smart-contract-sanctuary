pragma solidity ^0.4.24;


contract BrickAccessControl {

    constructor() public {
        admin = msg.sender;
        nodeToId[admin] = 1;
    }

    address public admin;
    address[] public nodes;
    mapping (address => uint) nodeToId;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized admin");
        _;
    }

    modifier onlyNode() {
        require(nodeToId[msg.sender] != 0, "Not authorized node");
        _;
    }

    function setAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0));

        admin = _newAdmin;
    }

    function getNodes() public view returns (address[]) {
        return nodes;
    }

    function addNode(address _newNode) public onlyAdmin {
        require(_newNode != address(0), "Cannot set to empty address");

        nodeToId[_newNode] = nodes.push(_newNode);
    }

    function removeNode(address _node) public onlyAdmin {
        require(_node != address(0), "Cannot set to empty address");

        uint index = nodeToId[_node] - 1;
        delete nodes[index];
        delete nodeToId[_node];
    }

}

contract Proxy is BrickAccessControl {

    event BrickUpgraded(address indexed _brickAddress);

    address private brickAddress;

    constructor(address _brickAddress) public {
        setBrickAddress(_brickAddress);
    }

    function() public {
        address contractAddress = getBrickAddress();
        require(contractAddress != address(0), "Cannot set address to address(0)");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, contractAddress, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    function getBrickAddress() public view returns (address) {
        return brickAddress;
    }

    function setBrickAddress(address _brickAddress) public onlyAdmin {
        require(_brickAddress != address(0), "Cannot upgrade to the same address.");
        require(_brickAddress != brickAddress, "Cannot upgrade to empty address.");
        brickAddress = _brickAddress;
        emit BrickUpgraded(brickAddress);
    }

}