/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2021 Berinike Tech <[email protected]>, Jannis Pilgrim <[email protected]>

pragma solidity ^0.8.0;

interface FactoryInterface {
    function createToken(
        string memory _uri,
        string memory _nftName,
        string memory _nftSymbol,
        address _sender
    ) external returns (address);
}

contract NFTtheWorld {
    FactoryInterface factoryInterface;

    uint256 percentageLimit;

    uint256 public numberOfDrops;

    struct NFTOwnership {
        address payable owner;
        string uri;
        uint256 dropId;
        uint256 dropTime;
        uint256 reservedUntil;
        uint256 reservationTimeoutSeconds;
        address reservedFor;
        uint256 weiPrice;
        string nftSymbol;
        string nftName;
    }

    struct dropInformation {
        address creator;
        string nftSymbol;
        string nftName;
        uint256 numberOfURIs;
        uint256 reservedCount;
        uint256 pricePerNFT;
        uint256 dropTime;
    }

    // To check if an address is an admin
    mapping(address => bool) private isAdminAddress;
    //To check if an address is a verified Partner
    mapping(address => bool) private isPartnerAddress;
    // Dictionary of form <dropHash>: list of NFTOwnerships
    mapping(uint256 => NFTOwnership[]) private nftOwnerships;
    // Dictionary of form <user address>: <<dropHash>: <number of reserved NFTs>>
    mapping(address => mapping(uint256 => uint256)) private nftReservations;
    // Dictionary of form <dropHash>: <list of nftHashes>
    mapping(uint256 => string[]) private availableNFTs;
    // Dictionary of form  <dropHash>: <nftCount>
    mapping(uint256 => uint256) private availableNFTsCount;
    // Dictionary of form <dropHash>: <maximal number of NFTs a user can reserve/buy from this drop>
    mapping(uint256 => uint256) private maxNumberOfNFTsToBuy;
    // Dictionary of form <dropHash>: <dropInformation>
    mapping(uint256 => dropInformation) public dropData;

    mapping(address => mapping(uint256 => string[]))
        private nftReservationInformationOfUsers;

    // Used to track which addresses have joined the drop
    mapping(uint256 => address[]) private joinedUsers;

    mapping(address => address[]) public mintedNFTContracts;

    //TODO add all of us in list of admins
    constructor() {
        isAdminAddress[msg.sender] = true;
        isPartnerAddress[msg.sender] = true;
        isAdminAddress[0xbdE09a05d825038A131E4538e5228ca2F983a829] = true;
        isAdminAddress[0xE48407CF4337A8ffC12Aa1a9d49115cDA75fCf58] = true;
        isPartnerAddress[0xbdE09a05d825038A131E4538e5228ca2F983a829] = true;
        isPartnerAddress[0xE48407CF4337A8ffC12Aa1a9d49115cDA75fCf58] = true;
    }

    //Other contract-file with "Token Factory" inside should be deployed first and address copied
    //Following function should be executed with just-copied address
    function setFactoryInterface(address _address) external onlyByAdmins {
        factoryInterface = FactoryInterface(_address);
    }

    // This function lets a user create a drop by specifiyng a drop time in UnixTime, an array of URIs, a Price in Wei, the TimeOut in UnixTime for reverting unbought
    // reservations, the name of the NFT and the Symbol of the NFT.
    // During the creation of the drop, the maximum number of NFTs a user can reserve/buy in this drop is calculated.
    // It is one for a total number of NFTs lower than 20 and 5% otherwise.

    function createDrop(
        uint256 _dropTime,
        string[] memory _uris,
        uint256 _weiPrice,
        uint256 _reservationTimeoutSeconds,
        string memory _nftName,
        string memory _nftSymbol
    ) public onlyByPartners {
        uint256 dropHash = numberOfDrops;
        dropInformation storage dropInfo = dropData[dropHash];
        dropInfo.creator = msg.sender;
        dropInfo.nftSymbol = _nftSymbol;
        dropInfo.nftName = _nftName;
        dropInfo.numberOfURIs = _uris.length;
        dropInfo.pricePerNFT = _weiPrice;
        dropInfo.dropTime = _dropTime;
        dropInfo.reservedCount = 0;

        for (uint256 i = 0; i < _uris.length; i++) {
            NFTOwnership memory nftOwnership;
            nftOwnership.uri = _uris[i];
            nftOwnership.owner = payable(msg.sender);
            nftOwnership.reservedFor = msg.sender;
            nftOwnership.dropTime = _dropTime;
            nftOwnership.reservedUntil = 0;
            nftOwnership.reservationTimeoutSeconds = _reservationTimeoutSeconds;
            nftOwnership.dropId = dropHash;
            nftOwnership.weiPrice = _weiPrice;
            nftOwnership.nftName = _nftName;
            nftOwnership.nftSymbol = _nftSymbol;
            nftOwnerships[dropHash].push(nftOwnership);
            availableNFTs[dropHash].push(_uris[i]);
        }

        // We need to let users buy 1 NFT instead of 5% if there are less than 20
        if (_uris.length < 20) {
            maxNumberOfNFTsToBuy[dropHash] = 1;
        } else {
            maxNumberOfNFTsToBuy[dropHash] = (_uris.length * 5) / 100;
        }
        availableNFTsCount[dropHash] = availableNFTs[dropHash].length;
        numberOfDrops += 1;
    }

    // This function lets a user join a drop by specifying the number of NFTs she would like to reserve.
    function joinDrop(uint256 _numberOfNFTs, uint256 _dropHash) public {
        require(
            dropData[_dropHash].reservedCount !=
                dropData[_dropHash].numberOfURIs,
            "Cannot join the drop anymore."
        );
        require(
            (_numberOfNFTs + nftReservations[msg.sender][_dropHash]) <=
                maxNumberOfNFTsToBuy[_dropHash],
            "Sorry, you can't reserve more that 5% of the NFTs."
        );
        require(_numberOfNFTs > 0, "The number oft NFTs can't be Zero.");
        // We have to make sure that not more NFTs get reserved by users than we have NFTs available
        require(
            _numberOfNFTs <=
                availableNFTs[_dropHash].length -
                    dropData[_dropHash].reservedCount,
            "Sorry, not enough NFTs left for your request"
        );
        dropData[_dropHash].reservedCount += _numberOfNFTs;
        nftReservations[msg.sender][_dropHash] = _numberOfNFTs;
        shuffle(_dropHash);
        for (uint256 j = 0; j < nftReservations[msg.sender][_dropHash]; j++) {
            uint256 nftElement = getNFTIndex(
                availableNFTs[_dropHash][j],
                _dropHash
            );
            nftOwnerships[_dropHash][nftElement].reservedFor = msg.sender;
            nftOwnerships[_dropHash][nftElement].reservedUntil =
                nftOwnerships[_dropHash][nftElement].reservationTimeoutSeconds +
                block.timestamp +
                dropData[_dropHash].dropTime;
            nftReservationInformationOfUsers[msg.sender][_dropHash].push(
                nftOwnerships[_dropHash][nftElement].uri
            );
            remove(j, _dropHash);
        }
        joinedUsers[_dropHash].push(msg.sender);
    }

    // This function lets a user buy her reserved NFTs
    function buyNFT(uint256 _dropHash) public payable {
        require(
            nftOwnerships[_dropHash][0].dropTime <= block.timestamp,
            "Droptime not yet reached!"
        );
        require(
            nftOwnerships[_dropHash][0].weiPrice *
                nftReservationInformationOfUsers[msg.sender][_dropHash]
                    .length <=
                msg.value,
            "Not enough funds"
        );
        for (
            uint256 i;
            i < nftReservationInformationOfUsers[msg.sender][_dropHash].length;
            i++
        ) {
            string storage uri = nftReservationInformationOfUsers[msg.sender][
                _dropHash
            ][i];
            uint256 nftIndex = getNFTIndex(uri, _dropHash);
            address contractAddress = factoryInterface.createToken(
                uri,
                nftOwnerships[_dropHash][nftIndex].nftName,
                nftOwnerships[_dropHash][nftIndex].nftSymbol,
                msg.sender
            );
            mintedNFTContracts[msg.sender].push(contractAddress);
            nftOwnerships[_dropHash][nftIndex].owner.transfer(
                nftOwnerships[_dropHash][nftIndex].weiPrice
            );
            nftOwnerships[_dropHash][nftIndex].owner = payable(msg.sender);
        }
    }

    // To be called automatically from backend
    // Checks whether reservation has timed out & if so, if reservedFor != owner, meaning it wasnt bought,
    // reinstate as if drop was executed but NFT wasnt reserved
    function revertTimedoutReservations(uint256 _dropHash)
        public
        returns (uint256)
    {
        uint256 reservationsReverted = 0;
        for (uint256 i; i < nftOwnerships[_dropHash].length; i++) {
            if (
                nftOwnerships[_dropHash][i].reservedUntil >= 0 &&
                nftOwnerships[_dropHash][i].reservedUntil <= block.timestamp &&
                nftOwnerships[_dropHash][i].owner !=
                nftOwnerships[_dropHash][i].reservedFor
            ) {
                nftReservationInformationOfUsers[
                    nftOwnerships[_dropHash][i].reservedFor
                ][_dropHash].pop();
                nftOwnerships[_dropHash][i].reservedUntil = 0;
                dropData[_dropHash].reservedCount -= nftReservations[
                    nftOwnerships[_dropHash][i].reservedFor
                ][_dropHash];
                nftReservations[nftOwnerships[_dropHash][i].reservedFor][
                    _dropHash
                ] = 0;
                nftOwnerships[_dropHash][i].reservedFor = nftOwnerships[
                    _dropHash
                ][i].owner;
                availableNFTs[_dropHash].push(nftOwnerships[_dropHash][i].uri);
                reservationsReverted++;
            }
        }
        return reservationsReverted;
    }

    function getNotBoughtNFTs(uint256 _dropHash)
        public
        view
        returns (string[] memory notBought)
    {
        require(
            nftOwnerships[_dropHash][0].reservedUntil >= 0 &&
                nftOwnerships[_dropHash][0].reservedUntil <= block.timestamp,
            "Reservation period hasn't ended yet."
        );
        NFTOwnership[] memory nfts = nftOwnerships[_dropHash];
        // Dynamic arrays can't be used in memory in functions. That's why we need to create a too large array first
        // and then copy the not minted uris in a new one of correct size
        string[] memory notBoughtNFTs = new string[](nfts.length);
        uint256 notBoughtNFTs_index = 0;
        for (uint256 i = 0; i < nfts.length; i++) {
            if (nfts[i].owner == msg.sender) {
                notBoughtNFTs[notBoughtNFTs_index] = (nfts[i].uri);
                notBoughtNFTs_index++;
            }
        }

        string[] memory trimmedNotBoughtNFTs = new string[](
            notBoughtNFTs.length
        );
        for (uint256 j = 0; j < notBoughtNFTs.length; j++) {
            trimmedNotBoughtNFTs[j] = notBoughtNFTs[j];
        }
        return trimmedNotBoughtNFTs;
    }

    function getAllURIs(uint256 _dropHash)
        public
        view
        returns (string[] memory allURIs)
    {
        NFTOwnership[] memory nfts = nftOwnerships[_dropHash];
        string[] memory uris = new string[](nfts.length);
        for (uint256 i = 0; i < nfts.length; i++) {
            uris[i] = (nfts[i].uri);
        }
        return uris;
    }

    // Helper function to remove NFT from list of available NFTs
    function remove(uint256 _index, uint256 _dropHash) internal {
        if (_index >= availableNFTs[_dropHash].length) return;

        for (uint256 i = _index; i < availableNFTs[_dropHash].length - 1; i++) {
            availableNFTs[_dropHash][i] = availableNFTs[_dropHash][i + 1];
        }
        availableNFTs[_dropHash].pop();
        availableNFTsCount[_dropHash] = availableNFTs[_dropHash].length;
    }

    // Helper function to shuffle a list
    function shuffle(uint256 _dropHash) internal {
        for (uint256 i = 0; i < availableNFTs[_dropHash].length; i++) {
            uint256 n = i +
                (uint256(keccak256(abi.encodePacked(block.timestamp))) %
                    (availableNFTs[_dropHash].length - i));
            string memory temp = availableNFTs[_dropHash][n];
            availableNFTs[_dropHash][n] = availableNFTs[_dropHash][i];
            availableNFTs[_dropHash][i] = temp;
        }
    }

    // Helper function to get the index of an NFT in the nftOwnerships mapping
    function getNFTIndex(string memory _uri, uint256 _dropHash)
        internal
        view
        returns (uint256 index)
    {
        NFTOwnership[] memory nfts = nftOwnerships[_dropHash];
        for (uint256 i = 0; i < nfts.length; i++) {
            if (compareStrings(nfts[i].uri, _uri)) {
                return i;
            }
        }
    }

    function compareStrings(string memory a, string memory b)
        private
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    // Modifier to check if msg.sender is elligible
    modifier onlyByAdmins() {
        require(isAdminAddress[msg.sender] == true, "You are not an admin");
        _;
    }

    function addToAdmins(address payable _addressToAdd) public onlyByAdmins {
        isAdminAddress[_addressToAdd] = true;
        addToPartners(_addressToAdd);
    }

    function removeFromAdmins(address payable _addressToRemove)
        public
        onlyByAdmins
    {
        require(msg.sender != _addressToRemove, "You can't remove yourself");
        isAdminAddress[_addressToRemove] = false;
    }

    modifier onlyByPartners() {
        require(isPartnerAddress[msg.sender] == true, "You are not a partner");
        _;
    }

    function addToPartners(address payable _addressToAdd) public onlyByAdmins {
        isPartnerAddress[_addressToAdd] = true;
    }

    function removeFromPartners(address payable _addressToRemove)
        public
        onlyByAdmins
    {
        isPartnerAddress[_addressToRemove] = false;
    }
}