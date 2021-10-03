/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IVerifyOwnership {
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IProxyMint {
    function proxyMint(address userAddress) external returns (uint);
}


contract ReciprocalProxyDrop {

    struct Drop {
        uint supply;
        mapping (address => bool) valuedCollections;
        string baseUri;
        address deployer;
        address minterProxy;
        mapping (bytes32 => bool) usedNfts;
    }

    mapping (uint => Drop) drops;
    uint public currentDropId = 0;

    function initializeDrop(uint supply, address[] memory valuedCollections, string memory baseUri, address minterProxy) public returns(uint) {
        incrementDropId();
        Drop storage drop = drops[currentDropId];
        drop.supply = supply;
        drop.baseUri = baseUri;
        drop.deployer = msg.sender;
        drop.minterProxy = minterProxy;

        for (uint i = 0; i < valuedCollections.length; i++) {
            drop.valuedCollections[valuedCollections[i]] = true;
        }

        return currentDropId;
    }

    function incrementDropId() private {
        currentDropId += 1;
    }

    function verifiedNftOwner(address contractAddress, address userAddress, uint tokenId) public view returns(bool) {
        if (IVerifyOwnership(contractAddress).ownerOf(tokenId) == userAddress) {
            return true;
        }
        return false;
    }
    
    function executeProxyMint(address contractAddress, address userAddress, uint tokenId, uint dropId) public returns(uint) {
        require(isValued(contractAddress, dropId), "This is not a valued collection by this drop.");
        require(verifiedNftOwner(contractAddress, userAddress, tokenId), "You must be an owner to reciprocal mint.");
        require(isUsedNft(getAddressTokenHashed(contractAddress, tokenId), dropId) == false, "This NFT was already used.");
        return IProxyMint(contractAddress).proxyMint(userAddress);
    }

    function getAddressTokenHashed(address contractAddress, uint tokenId) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(contractAddress, tokenId));
    }

    function addUsedNft(address contractAddress, uint tokenId, uint dropId) private {
        getDrop(dropId).usedNfts[getAddressTokenHashed(contractAddress, tokenId)] = true;
    }

    function isUsedNft(bytes32 addressTokenHashed, uint dropId) private view returns(bool) {
        return getDrop(dropId).usedNfts[addressTokenHashed] == true;
    }

    function isValued(address contractAddress, uint dropId) public view returns(bool) {
        return getDrop(dropId).valuedCollections[contractAddress];
    }

    function getDrop(uint dropId) private view returns(Drop storage) {
        return drops[dropId];
    }

    function getSupply(uint dropId) public view returns(uint) {
        return getDrop(dropId).supply;
    }

    function getBaseUri(uint dropId) public view returns(string memory) {
        return getDrop(dropId).baseUri;
    }
    
    function getTokenUri(uint dropId, uint tokenId) public view returns(string memory) {
        return string(abi.encodePacked(getDrop(dropId).baseUri, "/", toString(tokenId)));
    }

    function getDeployer(uint dropId) public view returns(address) {
        return getDrop(dropId).deployer;
    }
    
    function getMinterProxy(uint dropId) public view returns (address) {
        return getDrop(dropId).minterProxy;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    


}