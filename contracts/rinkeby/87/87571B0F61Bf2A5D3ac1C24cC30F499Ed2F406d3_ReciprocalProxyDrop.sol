/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IVerifyOwnership {
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IProxyMint {
    function proxyMint(address owner) external payable returns (bool success, uint tokenId);
}

interface IVerifyRatingAmount {
    function balanceOf(address owner) external view returns (uint256);
}

interface IGetNftBalace {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract ReciprocalProxyDrop {

    struct Drop {
        uint supply;
        address[] valuedCompliantCollections;
        string baseUri;
        string name;
        string description;
        address deployer;
        address minterProxy;
        mapping (bytes32 => bool) usedNfts;
        uint rating;
    }

    mapping (uint => Drop) drops;
    uint public currentDropId = 0;
    address governanceTokenAddress = 0x8973e5CE9Ab26152F39083e0945427E0d1f7bC1e;
    mapping (bytes32 => uint) pastRatingAmounts;
    mapping (string => uint) usedNames;


    function initializeDrop(uint supply, address[] memory valuedCompliantCollections, string memory baseUri, string memory name, string memory description, address minterProxy) public returns(uint) {
        require(usedNames[name] == 0, "Name has already been used.");

        incrementDropId();
        Drop storage drop = drops[currentDropId];
        drop.supply = supply;
        drop.baseUri = baseUri;
        drop.name = name;
        drop.description = description;
        drop.deployer = msg.sender;
        drop.minterProxy = minterProxy;
        drop.rating = 0;

        for (uint i = 0; i < valuedCompliantCollections.length; i++) {
            drop.valuedCompliantCollections.push(valuedCompliantCollections[i]);
        }

        addUsedName(drop.name, currentDropId);

        return currentDropId;
    }

    function setMyRating(uint amount, uint dropId) public {
        require(amount <= IVerifyRatingAmount(governanceTokenAddress).balanceOf(msg.sender), "You can only rate equal to your governance token balance.");
        uint prevRatingAmount = pastRatingAmounts[getAddressUintHashed(msg.sender, dropId)];
        if (prevRatingAmount > amount) {
            getDrop(dropId).rating -= (prevRatingAmount - amount);
        } else {
            getDrop(dropId).rating += (amount - prevRatingAmount);
        }
        pastRatingAmounts[getAddressUintHashed(msg.sender, dropId)] = amount;
    }

    function incrementDropId() private {
        currentDropId += 1;
    }

    function geNftBalances(address[] memory contractAddresses, address owner) public view returns(address[] memory, uint[] memory) {
        uint[] memory balances = new uint[](contractAddresses.length);
        for (uint i = 0; i < contractAddresses.length; i++) {
            balances[i] = IGetNftBalace(contractAddresses[i]).balanceOf(owner);
        }
        return (contractAddresses, balances);
    }


    function verifiedNftOwner(address contractAddress, address userAddress, uint tokenId) public view returns(bool) {
        if (IVerifyOwnership(contractAddress).ownerOf(tokenId) == userAddress) {
            return true;
        }
        return false;
    }

    function getDropIdByName(string memory name) public view returns(uint) {
        require(usedNames[name] > 0, "Name has not been used.");
        return usedNames[name];
    }

    function addUsedName(string memory name, uint dropId) private {
        usedNames[name] = dropId;
    }

    function executeProxyMint(address valuedContractAddress, address userAddress, uint tokenId, uint dropId) public payable returns(uint) {
        require(isValued(valuedContractAddress, dropId), "This is not a valued collection by this drop.");
        require(verifiedNftOwner(valuedContractAddress, userAddress, tokenId), "You must be an owner to reciprocal mint.");
        require(isUsedNft(getAddressUintHashed(valuedContractAddress, tokenId), dropId) == false, "This NFT was already used.");
        (bool success, uint proxyTokenId) = IProxyMint(valuedContractAddress).proxyMint{value:msg.value}(userAddress);
        require(success, "Mint failed");
        getDrop(dropId).supply -= 1;
        return proxyTokenId;
    }

    function getAddressUintHashed(address contractAddress, uint value) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(contractAddress, value));
    }
    
    function addUsedNft(address contractAddress, uint tokenId, uint dropId) private {
        getDrop(dropId).usedNfts[getAddressUintHashed(contractAddress, tokenId)] = true;
    }

    function isUsedNft(bytes32 addressTokenHashed, uint dropId) private view returns(bool) {
        return getDrop(dropId).usedNfts[addressTokenHashed] == true;
    }

    function isValued(address contractAddress, uint dropId) public view returns(bool) {
        for (uint i = 0; i < getDrop(dropId).valuedCompliantCollections.length; i++) {
            if (contractAddress == getDrop(dropId).valuedCompliantCollections[i]) {
                return true;
            }
        }
        return false;
    }

    function getDrop(uint dropId) private view returns(Drop storage) {
        return drops[dropId];
    }

    function getName(uint dropId) public view returns(string memory) {
        return getDrop(dropId).name;
    }

    function getDescription(uint dropId) public view returns(string memory) {
        return getDrop(dropId).description;
    }

    function getSupply(uint dropId) public view returns(uint) {
        return getDrop(dropId).supply;
    }

    function getRating(uint dropId) public view returns(uint) {
        return getDrop(dropId).rating;
    }

    function getMyRating(uint dropId) public view returns(uint) {
        return pastRatingAmounts[getAddressUintHashed(msg.sender, dropId)];
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

    function getDropDetails(uint dropId) public view returns(uint, string memory, string memory, string memory, address, address, uint) {
        return (getDrop(dropId).supply, getDrop(dropId).baseUri, getDrop(dropId).name, getDrop(dropId).description, getDrop(dropId).deployer, getDrop(dropId).minterProxy, getDrop(dropId).rating);
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

    function revertTestNoReturn() public pure {
        revert();
    }

    function revertTestYesReturn() public pure returns(uint) {
        if (true) {
            revert();
        }
        return 5;
    }
}