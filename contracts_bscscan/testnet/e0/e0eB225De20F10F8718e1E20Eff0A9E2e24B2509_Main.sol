pragma solidity ^0.5.0;

import "./ERC721.sol";

contract Main is ERC721Full {
    using SafeMath for uint256;

    uint256 public mintFee = 0.01 ether;
    uint256 public platformFee = 0.0015 ether;
    uint256 public streamFee = 0.01 ether;
    address payable public admin;

    mapping(address => mapping(uint256 => uint256)) public streamTime;

    event SongMinted(address creator, uint256 tokenId, string tokenURI);
    event SongPurchased(address buyer, uint256 tokenId, uint256 newTime);

    constructor(address _admin) public ERC721Full("Zub Token", "ZT") {
        require(_admin != address(0), "Zero admin address");
        admin = address(uint160(_admin));
    }

    function createSong(string memory _tokenURI) public payable returns (bool) {
        require(bytes(_tokenURI).length > 0, "Invalid URI");
        require(msg.value == mintFee, "Wrong Minting fee");
        uint256 tokenId = totalSupply().add(1);
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        admin.transfer(msg.value);
        emit SongMinted(msg.sender, tokenId, _tokenURI);
        return true;
    }

    function createAlbum(
        string memory _tokenURI,
        uint256 noOfSongs //,
    )
        public
        payable
        returns (
            // uint256[] memory tokenId
            bool
        )
    {
        require(msg.value == noOfSongs.mul(mintFee), "Wrong Minting fee");
        // require(noOfSongs == tokenId.length, "Incorrect length");
        for (uint256 i = 0; i < noOfSongs; i++) {
            uint256 tokenId = totalSupply().add(1);
            _mint(msg.sender, tokenId);
            _setTokenURI(tokenId, _tokenURI);
            emit SongMinted(msg.sender, tokenId, _tokenURI);
        }
        admin.transfer(msg.value);
        // totalSupply().add(noOfSongs);
        return true;
    }

    function buySong(uint256 tokenId, uint256 noOfDays)
        public
        payable
        returns (bool)
    {
        require(_exists(tokenId), "Invalid tokenId");
        require(ownerOf(tokenId) != msg.sender, "Can't buy own song");
        require(
            msg.value == (streamFee.mul(noOfDays)).add(platformFee),
            "Wrong streaming fee"
        );
        if (streamTime[msg.sender][tokenId] == 0) {
            uint256 day = block.timestamp.add(noOfDays.mul(86400));
            streamTime[msg.sender][tokenId] = streamTime[msg.sender][tokenId]
            .add(day);
        } else {
            streamTime[msg.sender][tokenId] = streamTime[msg.sender][tokenId]
            .add(noOfDays.mul(86400));
        }
        address payable owner = address(uint160(ownerOf(tokenId)));
        owner.transfer(streamFee.mul(noOfDays));
        admin.transfer(platformFee);
        emit SongPurchased(
            msg.sender,
            tokenId,
            streamTime[msg.sender][tokenId]
        );
        return true;
    }

    function buyMultiple(uint256[] memory tokenId, uint256 noOfDays)
        public
        payable
        returns (bool)
    {
        require(
            msg.value ==
                (streamFee.mul(noOfDays.mul(tokenId.length))).add(
                    platformFee.mul(tokenId.length)
                ),
            "Wrong streaming fee"
        );
        for (uint256 i = 0; i < tokenId.length; i++) {
            require(_exists(tokenId[i]), "Invalid tokenId");
            require(ownerOf(tokenId[i]) != msg.sender, "Can't buy own song");
            if (streamTime[msg.sender][tokenId[i]] == 0) {
                uint256 day = block.timestamp.add(noOfDays.mul(86400));
                streamTime[msg.sender][tokenId[i]] = streamTime[msg.sender][
                    tokenId[i]
                ]
                .add(day);
            } else {
                streamTime[msg.sender][tokenId[i]] = streamTime[msg.sender][
                    tokenId[i]
                ]
                .add(noOfDays.mul(86400));
            }
            address payable owner = address(uint160(ownerOf(tokenId[i])));
            owner.transfer(streamFee.mul(noOfDays));
            emit SongPurchased(
                msg.sender,
                tokenId[i],
                streamTime[msg.sender][tokenId[i]]
            );
        }
        admin.transfer(platformFee.mul(tokenId.length));
        return true;
    }

    function valid(uint256 tokenId) public view returns (bool) {
        if (ownerOf(tokenId) == msg.sender) return true;
        return (streamTime[msg.sender][tokenId] > block.timestamp);
    }
}