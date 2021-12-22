/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

pragma solidity ^0.4.24;

contract Artwork {
    address public owner;

    struct artwork {
        string title;
        string author;
        string ipfsHash;
        uint256 productionYear;
        uint256 price;
        address owner;
        bytes32 hashCode;
    }

    mapping(address => artwork[]) public clientArtworks;

    artwork[] public artworks;

    constructor() public {
        bytes32 hashCode;
        artwork memory newArtwork;

        owner = msg.sender;

        hashCode = keccak256(
            abi.encodePacked("Test admin 1", "Johnna", uint256(2002))
        );
        newArtwork = artwork(
            "Test admin 1",
            "Johnna",
            "QmU8D6xiBHPX7DB5oQr18Zaq85dNMtv126nCwQfdt2qsDj",
            2002,
            2 ether,
            owner,
            hashCode
        );
        artworks.push(newArtwork);
        clientArtworks[owner].push(newArtwork);

        hashCode = keccak256(
            abi.encodePacked("Test admin 2", "Jenny", uint256(2003))
        );
        newArtwork = artwork(
            "Test admin 2",
            "Jenny",
            "QmU8D6xiBHPX7DB5oQr18Zaq85dNMtv126nCwQfdt2qsDj",
            2003,
            2 ether,
            owner,
            hashCode
        );
        artworks.push(newArtwork);
        clientArtworks[owner].push(newArtwork);

        hashCode = keccak256(
            abi.encodePacked("Test admin 3", "Tete", uint256(2004))
        );
        newArtwork = artwork(
            "Test admin 3",
            "Tete",
            "QmU8D6xiBHPX7DB5oQr18Zaq85dNMtv126nCwQfdt2qsDj",
            2004,
            2 ether,
            owner,
            hashCode
        );
        artworks.push(newArtwork);
        clientArtworks[owner].push(newArtwork);
    }

    function addArtwork(
        string memory _title,
        string memory _author,
        string memory _ipfsHash,
        uint256 _productionYear,
        uint256 _price
    ) public {
        bytes32 hashCode;

        hashCode = keccak256(
            abi.encodePacked(_title, _author, _productionYear)
        );
        artwork memory newArtwork = artwork(
            _title,
            _author,
            _ipfsHash,
            _productionYear,
            _price,
            msg.sender,
            hashCode
        );

        clientArtworks[msg.sender].push(newArtwork);

        artworks.push(newArtwork);
    }

    function buyArtwork(uint256 _artworkIndex) public payable {
        artwork storage boughtArtwork = artworks[_artworkIndex];

        require(msg.value == boughtArtwork.price);

        // 1. Pay to the owner of the artwork
        address oldOwner = boughtArtwork.owner;

        oldOwner.transfer(msg.value);

        // 2. Delete the artwork from the list of the old owner
        artwork[] memory oldOwnerArtworks = clientArtworks[oldOwner];

        for (uint256 i; i < oldOwnerArtworks.length; i++) {
            artwork memory oldOwnerArtwork = oldOwnerArtworks[i];

            if (boughtArtwork.hashCode == oldOwnerArtwork.hashCode) {
                delete clientArtworks[oldOwner][i];
            }
        }

        // 3. Add the artwork to the list of the new owner
        boughtArtwork.owner = msg.sender;

        clientArtworks[msg.sender].push(boughtArtwork);
    }

    modifier Owner(address _address) {
        require(_address == msg.sender, "Access denied! You are not the owner");
        _;
    }

    function deleteArtwork(
        uint256 _artworkIndex,
        bytes32 _hashCodeArtwork,
        address _artworkOwner
    ) public Owner(_artworkOwner) {
        // 1. Delete the artwork from the list of the client
        delete clientArtworks[msg.sender][_artworkIndex];

        // 2. Delete the artwork from the list of all artworks
        uint256 total = artworks.length;

        for (uint256 i; i < total; i++) {
            artwork memory aartwork = artworks[i];

            if (_hashCodeArtwork == aartwork.hashCode) {
                delete artworks[i];
                break;
            }
        }
    }

    function editArtwork(
        uint256 _artworkIndex,
        bytes32 _hashCodeArtwork,
        address _artworkOwner,
        string memory _title,
        string memory _author,
        string memory _ipfsHash,
        uint256 _productionYear,
        uint256 _price
    ) public Owner(_artworkOwner) {
        bytes32 newHashCodeArtwork;

        newHashCodeArtwork = keccak256(
            abi.encodePacked(_title, _author, _productionYear)
        );
        // 1. Update the artwork from the list of the client
        artwork storage artworkClient = clientArtworks[msg.sender][
            _artworkIndex
        ];

        artworkClient.title = _title;
        artworkClient.author = _author;
        artworkClient.ipfsHash = _ipfsHash;
        artworkClient.productionYear = _productionYear;
        artworkClient.price = _price;
        artworkClient.hashCode = newHashCodeArtwork;

        // 2. Update the artwork from the list of all artworks
        uint256 total = artworks.length;

        for (uint256 i; i < total; i++) {
            artwork storage aartwork = artworks[i];

            if (_hashCodeArtwork == aartwork.hashCode) {
                aartwork.title = _title;
                aartwork.author = _author;
                aartwork.ipfsHash = _ipfsHash;
                aartwork.productionYear = _productionYear;
                aartwork.price = _price;
                aartwork.hashCode = newHashCodeArtwork;
                break;
            }
        }
    }

    function totalArtworks() public view returns (uint256) {
        return artworks.length;
    }

    function myTotalArtworks() public view returns (uint256) {
        return clientArtworks[msg.sender].length;
    }
}