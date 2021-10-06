/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;
library LCGHandler {
    struct iterator {
        uint256 x;
        uint256 a;  
        uint256 c;
        uint256 m;
    }
    
    function iterate (iterator storage _i) external {
        _i.x =  (_i.a * _i.x + _i.c) % _i.m;
    }
    
    
    // https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity
    function convertPidIteratorToString(iterator storage _i) view external returns (string memory _uintAsString) {
        return string(_convertToBytes(_i.x));
    }
    
    // https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity
    function convertVersionToString(uint256 x) pure external returns (string memory _versionAsString) {
        return string(abi.encodePacked("Version ", string(_convertToBytes(x))));
    }
    
    function convertNumberToString(uint256 x) pure external returns (string memory _uintAsString) {
        return string(_convertToBytes(x));
    }
    
    function _convertToBytes(uint256 x) pure internal returns (bytes memory _uintAsBytes) {
        if (x == 0) {
            return "Version 0";
        }
        uint j = x;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (x != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(x - x / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            x /= 10;
        }
        
        // maybe fill up the remaining digits with zeros
        return bstr;
    }  
    
}


pragma solidity 0.8.4;

interface IENS{

    function setSubnodeRecord(bytes32 node, bytes32 label, address _owner, address _resolver, uint64 ttl) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address _owner) external returns(bytes32);
    function setResolver(bytes32 node, address _resolver) external;
    function setOwner(bytes32 node, address _owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function setApprovalForAll(address operator, bool approved) external;
    function resolver(bytes32 node) external view returns (address);
    function owner(bytes32 node) external view returns (address);
    function recordExists(bytes32 node) external view returns (bool);
    function isApprovedForAll(address _owner, address operator) external view returns (bool);
}


interface IResolver{
    function setText(bytes32 node, string calldata key, string calldata value) external;
}



// import "./LCG.sol";

// contract OpenPID is ERC721 {
    
contract OpenPID {
    
    using LCGHandler for LCGHandler.iterator;
    using LCGHandler for uint256;
    
    IENS public ens = IENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    
    address public deployer;
    bool public rootSettable = true;
    bytes32 public openPidRoot;
    IResolver public mainResolver;
    
    
   
    mapping (bytes32 => uint) public pidVersion;
    uint256 public pidCount = 0;
    uint256 public iterationModulus = 2**64;
    uint256 public iterationSeed;
    LCGHandler.iterator public lastPID = LCGHandler.iterator({
                x:iterationSeed,
                a:6364136223846793005,
                c:1442695040888963407,
                m:iterationModulus});
    
    mapping (bytes32 => mapping(address => bool)) public isOperator;  // unlike the ens operator, this is an operator only for this pid, not for all domains of the domain owner.
    mapping (bytes32 => uint256) public numberOfOperators;
    
    
    constructor () {
        deployer = msg.sender;
    }
    
    function setInitialSeed(uint256 _seed) external {
        require(pidCount==0 && _seed < iterationModulus);
        iterationSeed = _seed;
        lastPID.x = _seed;
    }
    
    function mint(string memory metadataPointer) external {
        
        lastPID.iterate();
        pidCount += 1;
        bytes32 label = keccak256(bytes(lastPID.convertPidIteratorToString()));
        bytes32 node = keccak256(abi.encodePacked(openPidRoot, label));
        ens.setSubnodeRecord(openPidRoot, label, address(this), address(mainResolver), uint64(0));
        mainResolver.setText(node, "Version 1", metadataPointer);
        isOperator[node][msg.sender] = true;
        numberOfOperators[node] += 1;
        pidVersion[node] += 1;
    }
    
    function setOperatorFor(bytes32 pidNode, address newOperator) external onlyOperator(pidNode) {
        isOperator[pidNode][newOperator] = true;
        numberOfOperators[pidNode] += 1;
    }
    
    function withdrawOperatorFrom(bytes32 pidNode, address formerOperator) external onlyOperator(pidNode) {
        require(numberOfOperators[pidNode]>1);
        isOperator[pidNode][formerOperator] = false;
        numberOfOperators[pidNode] -= 1;
    }
    
    function getPIDNodeFromPID(uint256 _pid) view public returns(bytes32) {
        return keccak256(abi.encodePacked(openPidRoot, keccak256(bytes(_pid.convertNumberToString()))));
    }

    function updateFromPID(uint256 _pid, string memory metadataPointer) external {
        bytes32 _pidNode = getPIDNodeFromPID(_pid);
        require(isOperator[_pidNode][msg.sender]);
        mainResolver.setText(_pidNode, pidVersion[_pidNode].convertVersionToString(), metadataPointer); 
    }

    function update(bytes32 pidNode, string memory metadataPointer) external onlyOperator(pidNode) {
        pidVersion[pidNode] += 1;
        mainResolver.setText(pidNode, pidVersion[pidNode].convertVersionToString(), metadataPointer);
    }
    
    
    function iterateForTesting(uint256 iterations) external {
        
        require(msg.sender==deployer && iterations>0 && iterations<2**5);
        
        for (uint256 j; j<iterations; j++){
            lastPID.iterate();
        }
        
        pidCount += iterations;
    }
    

    function setRootAddress(bytes32 _openPidRoot) external deployerOnlyOnce {
        openPidRoot = _openPidRoot;
        mainResolver = IResolver(ens.resolver(openPidRoot));
        rootSettable = false;
    }
    
    
    
    
    
    
    function setTextRecord (bytes32 pidNode, string memory key, string memory value) external onlyOperator(pidNode) {
    // function setTextRecord (bytes32 node, string memory key, string memory value) external {
        // only operators or owners (i.e. this contract) of the node should call this method!
        mainResolver.setText(pidNode,key,value);
    }
    
    
    
    function transferDomainOwnershipBack() external {
        require(msg.sender==deployer);
        ens.setOwner(openPidRoot, deployer);
    }
    
    
    modifier deployerOnlyOnce () {
        require(msg.sender==deployer && rootSettable);
        _;
    }
    
    
    modifier onlyOperator(bytes32 node) {
        require(isOperator[node][msg.sender]);
        _;
    }

    
    
}