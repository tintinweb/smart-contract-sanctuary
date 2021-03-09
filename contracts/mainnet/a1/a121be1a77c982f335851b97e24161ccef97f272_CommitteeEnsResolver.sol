/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

pragma solidity 0.6.12;

interface IContractRegistry {
	function getContract(string calldata contractName) external view returns (address);
}

interface IElections {
	function getCommittee() external view returns (address[] memory committee, uint256[] memory weights, address[] memory orbsAddrs, bool[] memory certification, bytes4[] memory ips);
}

contract CommitteeEnsResolver {

    IContractRegistry   public orbsRegistry;
    bytes32             public parentDomainNameHash;

    constructor(address orbsRegistry_, bytes32 parentDomainNameHash_) public {
        // set defaults
        if (orbsRegistry_ == address(0)) {
            orbsRegistry_ = 0x2C13510F548b5cD963B4D2CB6837c7E34321bBAa; // mainnet orbs V2 contracts registry
        }
    
        if (parentDomainNameHash_ == bytes32(0)) {
            parentDomainNameHash_ = 0xb30b0b22edc109e1bccfd9bf561963d8b0993b8de6025741af1fdd5bb75e1705; // committee.orbs.eth
        }
        
        orbsRegistry = IContractRegistry(orbsRegistry_);
        parentDomainNameHash = parentDomainNameHash_;
    }

    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        // only Ethereum address and text
        return interfaceID == 0x3b3b57de || interfaceID == 0x59d1d43c || interfaceID == 0x01ffc9a7; 
    }

    function addr(bytes32 nodeID) public view returns (address) {
        IElections elections = IElections(orbsRegistry.getContract('elections'));
        (address[] memory committee, , , , ) = elections.getCommittee();
        
        for (uint i = 0; i < committee.length; i++) {
            if (nodeID == namehash(uintToString(i))) {
                return committee[i];
            }
        }
        return address(0);
    }
    
    function text(bytes32 nodeID, string memory key) public view returns (string memory) {
        if (keccak256(bytes(key)) != keccak256(bytes('url'))) {
            return '';
        }
        
        IElections elections = IElections(orbsRegistry.getContract('elections'));
        (, , , , bytes4[] memory ips ) = elections.getCommittee();
        
        for (uint i = 0; i < ips.length; i++) {
            if (nodeID == namehash(uintToString(i))) {
                return string(abi.encodePacked(
                    'http://', 
                    string(abi.encodePacked(byteToString(ips[i][0]), '.')), 
                    string(abi.encodePacked(byteToString(ips[i][1]), '.')), 
                    string(abi.encodePacked(byteToString(ips[i][2]), '.')), 
                    string(abi.encodePacked(byteToString(ips[i][3]), '/'))));
            }
        }
        return '';
        
    }

    function namehash(string memory label) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(parentDomainNameHash, keccak256(bytes(label))));
    }
    
    function byteToString(byte v) internal pure returns (string memory str) {
        return uintToString(uint8(v));
    }
    
    function uintToString(uint v) internal pure returns (string memory str) {
        if (v == 0) {
            return '0';
        }
        
        bytes memory reversed = new bytes(100);
        uint len = 0;
        while (v != 0) {
            uint ls = v % 10;
            v = v / 10;
            reversed[len++] = byte(48 + uint8(ls));
        }
        bytes memory s = new bytes(len);
        for (uint j = 0; j < len; j++) {
            s[j] = reversed[len - 1 - j];
        }
        str = string(s);
    }
    
}