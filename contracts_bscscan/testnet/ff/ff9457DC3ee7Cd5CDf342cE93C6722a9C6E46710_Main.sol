pragma solidity ^0.5.0;

import "./ERC721.sol";

contract Main is ERC721Full {
    using SafeMath for uint256;

    uint256 public mintFee = 0.01 ether;
    uint256 public platformFee = 0.0015 ether;
    uint256 public streamFee = 0.01 ether;
    address payable public admin;

    mapping(address => mapping(uint256 => bool)) public valid;
    mapping(address => uint256[]) public userSongs;

    event SongMinted(address creator, uint256 tokenId, string tokenURI);
    event SongPurchased(address buyer, uint256 tokenId);

    constructor(address _admin) public ERC721Full("Zub Token", "ZT") {
        require(_admin != address(0), "Zero admin address");
        admin = address(uint160(_admin));
    }

    function changeFees(
        uint256 _mintFee,
        uint256 _platformFee,
        uint256 _streamFee
    ) external returns (bool) {
        require(msg.sender == admin, "Only admin");
        mintFee = _mintFee;
        platformFee = _platformFee;
        streamFee = _streamFee;
        return true;
    }

    function changeAdmin(address _admin) external returns (bool) {
        require(msg.sender == admin, "Only admin");
        require(_admin != address(0), "Zero address");
        admin = address(uint160(_admin));
        return true;
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
        require(bytes(_tokenURI).length > 0, "Invalid URI");
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

    function buySong(uint256 tokenId) public payable returns (bool) {
        require(_exists(tokenId), "Invalid tokenId");
        require(ownerOf(tokenId) != msg.sender, "Can't buy own song");
        require(
            msg.value == (streamFee).add(platformFee),
            "Wrong streaming fee"
        );
        require(!valid[msg.sender][tokenId], "Already bought this song");
        valid[msg.sender][tokenId] = true;
        address payable owner = address(uint160(ownerOf(tokenId)));
        owner.transfer(streamFee);
        admin.transfer(platformFee);
        userSongs[msg.sender].push(tokenId);
        emit SongPurchased(msg.sender, tokenId);
        return true;
    }

    function buyMultiple(uint256[] memory tokenId)
        public
        payable
        returns (bool)
    {
        require(
            msg.value ==
                (streamFee.mul(tokenId.length)).add(
                    platformFee.mul(tokenId.length)
                ),
            "Wrong streaming fee"
        );
        for (uint256 i = 0; i < tokenId.length; i++) {
            require(_exists(tokenId[i]), "Invalid tokenId");
            require(ownerOf(tokenId[i]) != msg.sender, "Can't buy own song");
            require(!valid[msg.sender][tokenId[i]], "Already bought this song");
            valid[msg.sender][tokenId[i]] = true;
            address payable owner = address(uint160(ownerOf(tokenId[i])));
            owner.transfer(streamFee);
            userSongs[msg.sender].push(tokenId[i]);
            emit SongPurchased(msg.sender, tokenId[i]);
        }
        admin.transfer(platformFee.mul(tokenId.length));
        return true;
    }
}
// 0xa4523b1fEC25C43641eB828BbC938747d83f1594