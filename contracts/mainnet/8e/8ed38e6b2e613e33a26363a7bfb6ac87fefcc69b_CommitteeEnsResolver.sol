/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

pragma solidity 0.6.12;

interface IContractRegistry {
	function getContract(string calldata contractName) external view returns (address);
}

interface IElections {
	function getCommittee() external view returns (address[] memory committee, uint256[] memory weights, address[] memory orbsAddrs, bool[] memory certification, bytes4[] memory ips);
}

contract CommitteeEnsResolver {

    IContractRegistry constant orbsRegistry = IContractRegistry(0xD859701C81119aB12A1e62AF6270aD2AE05c7AB3); // mainnet orbs V2 contracts registry;
    bytes32 constant parentDomainNameHash = 0xb30b0b22edc109e1bccfd9bf561963d8b0993b8de6025741af1fdd5bb75e1705; // committee.orbs.eth;

    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        // only Ethereum address and text
        return interfaceID == 0x3b3b57de || interfaceID == 0x59d1d43c || interfaceID == 0x01ffc9a7; 
    }

    function addr(bytes32 nodeID) public view returns (address) {
        IElections elections = IElections(orbsRegistry.getContract('elections'));
        (address[] memory committee, uint256[] memory weights, , ,bytes4[] memory ips) = elections.getCommittee();
        sortByWeightAndAddress(weights, committee, ips);
        
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
        (address[] memory committee, uint256[] memory weights, , , bytes4[] memory ips) = elections.getCommittee();
        sortByWeightAndAddress(weights, committee, ips);
        
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

    function namehash(string memory label) internal pure returns (bytes32) {
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
    
    function sortByWeightAndAddress(uint256[] memory weights, address[] memory addresses, bytes4[] memory ips) internal pure {
       quickSortDesc(weights, addresses, ips, int(0), int(weights.length - 1));
    }
    
    function quickSortDesc(uint256[] memory weights, address[] memory addresses, bytes4[] memory ips, int left, int right) pure internal{
        int i = left;
        int j = right;
        if(i==j) return;
        uint pivotIndex = uint(left + (right - left) / 2);
        uint pivotWeight = weights[pivotIndex];
        address pivotAddress = addresses[pivotIndex];
        while (i <= j) {
            while (weights[uint(i)] > pivotWeight || weights[uint(i)] == pivotWeight && addresses[uint(i)] > pivotAddress) i++;
            while (pivotWeight > weights[uint(j)] || weights[uint(j)] == pivotWeight && pivotAddress > addresses[uint(j)]) j--;
            if (i <= j) {
                // switch in all three arrays together
                (weights[uint(i)], weights[uint(j)]) = (weights[uint(j)], weights[uint(i)]);
                (addresses[uint(i)], addresses[uint(j)]) = (addresses[uint(j)], addresses[uint(i)]);
                (ips[uint(i)], ips[uint(j)]) = (ips[uint(j)], ips[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSortDesc(weights, addresses, ips, left, j);
        if (i < right)
            quickSortDesc(weights, addresses, ips, i, right);
    }
}