/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2021 Berinike Tech <[email protected]>

pragma solidity ^0.8.0;

contract NFTtheWorld {

    struct Addresses {
        address[] _items;
    }

    address payable nftOwner;

    uint256 percentageLimit;

    uint256[] public availableNFTs;

    address public user;

    uint256 public availableNFTsCount;

    uint256 public reservedNFTsCount;

    uint256 public maxNumberOfNFTsToBuy;

    struct NFTOwnership {
        address owner;
        uint256 nftId;
        uint256 dropTime;
        address reservedFor;
    }

    mapping(uint256 => NFTOwnership) public nftOwnerships;
    mapping(address => uint256) public nftReservations;

    // Used to track which addresses have joined the drop
    // address[] private joinedUsers;
    Addresses joinedUsers;

    // This function lets a user create a drop by specifiyng a drop time and the number of available NFTs.
    // During the creation of the drop, the maximum number of NFTs a user can reserve/buy in this drop is calculated.
    // It is one for a total number of NFTs lower than 20 and 5% otherwise.
    function createDrop(uint256 _dropTime, uint256 _numberOfNFTS) public {
        for (uint256 i = 0; i < _numberOfNFTS; i++) {
            // hardcoded address for testing reasons, to be replaced with msg.sender
            mockNFT(_dropTime, i + 1, payable(0xC77787e364E3420c0609a249F18De47430900f0C));
        }
        // We need to let users buy 1 NFT instead of 5% if there are less than 20
        if (_numberOfNFTS < 20) {
            maxNumberOfNFTsToBuy = 1;
        } else {
            maxNumberOfNFTsToBuy = (_numberOfNFTS * 5) / 100;
        }
    }

    // Create mock NFTs for drop by creating a list of hashes.
    function mockNFT(uint256 _dropTime, uint256 _number, address _nftOwner) internal {
        uint256 nftHash = generateRandomNumber(_number);
        NFTOwnership memory nftOwnership;
        nftOwnership.nftId = nftHash;
        nftOwnership.owner = _nftOwner;
        nftOwnership.reservedFor = _nftOwner;
        nftOwnership.dropTime = _dropTime;
        nftOwnerships[nftHash] = nftOwnership;
        availableNFTs.push(nftHash);
        availableNFTsCount = availableNFTs.length;
    }

    // This function lets a user join a drop by specifying the number of NFTs she would like to reserve.
    function joinDrop(uint256 _numberOfNFTs) public {

        require(
            reservedNFTsCount != availableNFTs.length,
            "You cannot join the drop anymore."
        );
        require(
            _numberOfNFTs <= maxNumberOfNFTsToBuy,
            "Sorry, you can't reserve more that 5% of the NFTs."
        );
        // We have to make sure that not more NFTs get reserved by users than we have NFTs available
        require(
            _numberOfNFTs <= availableNFTs.length - reservedNFTsCount,
            "Sorry, not enough NFTs left for your request"
        );
        reservedNFTsCount += _numberOfNFTs;
        nftReservations[msg.sender] = _numberOfNFTs;
        joinedUsers._items.push(msg.sender);
    }

    // This function executes a drop.
    // During the execution all joined users get their previously specificed number of NFTs randomly assigned.
    // To make sure no NFT gets assigned to multiple users, it is removed from the list of available NFTs.
    function drop() public {
        require(
            nftOwnerships[availableNFTs[0]].dropTime <= block.timestamp,
            "Droptime not yet reached!"
        );
        uint256 nftElement;
        uint256 nftHash;
        for (uint256 i = 0; i < joinedUsers._items.length; i++) {
            for (
                uint256 j = 0;
                j < nftReservations[joinedUsers._items[i]];
                j++
            ) {
                nftElement = generateRandomNumber(j) % availableNFTs.length;
                nftHash = availableNFTs[nftElement];
                remove(nftElement);
                nftOwnerships[nftHash].reservedFor = joinedUsers._items[i];
            }
        }
    }

    // This function lets a user buy her reserved NFTs (one at a time)
    //TODO: Think about a time span during which the reserved NFTs have to be bought
    function buyNFT(uint256 _price, uint256 _nftHash) public payable {
        require(
            nftOwnerships[_nftHash].dropTime <= block.timestamp,
            "Droptime not yet reached!"
        );
        require(
            nftOwnerships[_nftHash].reservedFor == msg.sender,
            "This NFT wasn't assigned to you"
        );
        require(
            nftOwnerships[_nftHash].owner != msg.sender,
            "This NFT already belongs to you"
        );
        // string(abi.encodePacked("Drop has not started yet! ",((nftOwnerships[_nftHash].droptime-block.timestamp)/86400)," Days, ",((nftOwnerships[_nftHash].droptime-block.timestamp)/3600)," Hours,", ((nftOwnerships[_nftHash].droptime-block.timestamp)/60)," Minutes, and ", ((nftOwnerships[_nftHash].droptime-block.timestamp))," Seconds left.")));
        _price = msg.value;
        nftOwner.transfer(_price);
        nftOwnerships[_nftHash].owner = msg.sender;
    }

    // Helper function to created hashes
    function generateRandomNumber(uint256 number)
        internal
        view
        returns (uint256)
    {
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.number, number))
        ) % 1000;
        return randomNumber;
    }

    // Helper function to remove NFT from list of available NFTs
    function remove(uint256 index) internal {
        if (index >= availableNFTs.length) return;

        for (uint256 i = index; i < availableNFTs.length - 1; i++) {
            availableNFTs[i] = availableNFTs[i + 1];
        }
        availableNFTs.pop();
        availableNFTsCount = availableNFTs.length;
    }

    // Helper function for testing
    function getJoinedUser(uint256 index) public {
        user = joinedUsers._items[index];
    }
}