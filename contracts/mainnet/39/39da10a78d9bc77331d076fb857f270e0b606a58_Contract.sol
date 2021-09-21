pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./Ownable.sol";

contract Contract is ERC721, Ownable {
    using SafeMath for uint256;

    string public PROVENANCE = "";
    string public LICENSE_TEXT = "";

    uint256 public constant price = 0.04 * 10**18;
    uint256 public constant presalePrice = 0.05 * 10**18;
    uint256 public constant MAX = 8888;

    uint256 public constant maxPurchase = 20;

    bool public saleIsActive = true;
    bool public presaleIsActive = true;
    bool licenseLocked = false;

    address payable user1 = 0x23992951637DE01651efeF536A0e13b4B04cc16B;
    address payable user2 = 0xffCF9020799B4f03A63E11260e8C2e75CEB5c505;
    uint256 user1Fraction = 765;
    uint256 user2Fraction = 35;

    mapping(uint256 => string) public names;

    uint256 public reserve = 222;

    event nameChange(address _by, uint256 _tokenId, string _name);
    event licenseIsLocked(string _licenseText);

    constructor() public ERC721("Club Name", "SHORTCODE") {}

    function withdraw() public onlyOwner {
        uint256 u1total = (address(this).balance * user1Fraction) / 1000;
        uint256 u2total = (address(this).balance * user2Fraction) / 1000;
        user1.transfer(u1total);
        user2.transfer(u2total);
        msg.sender.transfer(address(this).balance);
    }

    function reserveTokens(address _to, uint256 _reserveAmount)
        public
        onlyOwner
    {
        uint256 supply = totalSupply();
        require(
            _reserveAmount > 0 && _reserveAmount <= reserve,
            "Not enough reserve left for the team"
        );
        for (uint256 i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, supply + i);
        }
        reserve = reserve.sub(_reserveAmount);
    }

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        PROVENANCE = _provenanceHash;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        _setBaseURI(_baseURI);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPresaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function tokenLicense(uint256 _id) public view returns (string memory) {
        require(_id < totalSupply(), "Choose a NFT within range!");
        return LICENSE_TEXT;
    }

    function lockLicense() public onlyOwner {
        licenseLocked = true;
        emit licenseIsLocked(LICENSE_TEXT);
    }

    function changeLicense(string memory _license) public onlyOwner {
        require(licenseLocked == false, "License already locked!");
        LICENSE_TEXT = _license;
    }

    function mint(uint256 _numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint NFT...");
        require(
            _numberOfTokens > 0 && _numberOfTokens <= maxPurchase,
            "Can only mint 20 tokens at a time!"
        );
        require(
            totalSupply().add(_numberOfTokens) <= MAX,
            "Not enough tokens available for minting..."
        );
        require(
            msg.value >= price.mul(_numberOfTokens),
            "Ether value sent is not enough..."
        );
        if (presaleIsActive) {
            require(
                msg.value >= presalePrice.mul(_numberOfTokens),
                "Ether value sent is not enough..."
            );
        } else {
            require(
                msg.value >= price.mul(_numberOfTokens),
                "Ether value sent is not enough..."
            );
        }

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function changeName(uint256 _tokenId, string memory _name) public {
        require(
            ownerOf(_tokenId) == msg.sender,
            "Hey, your wallet doesn't own this NFT!"
        );
        require(sha256(bytes(_name)) != sha256(bytes(names[_tokenId])));
        names[_tokenId] = _name;

        emit nameChange(msg.sender, _tokenId, _name);
    }

    function viewName(uint256 _tokenId) public view returns (string memory) {
        require(_tokenId < totalSupply(), "Choose a NFT within range.");
        return names[_tokenId];
    }

    function namesOfOwners(address _owner)
        external
        view
        returns (string[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new string[](0);
        } else {
            string[] memory result = new string[](tokenCount);
            for (uint256 index = 0; index < tokenCount; index++) {
                result[index] = names[tokenOfOwnerByIndex(_owner, index)];
            }
            return result;
        }
    }
}