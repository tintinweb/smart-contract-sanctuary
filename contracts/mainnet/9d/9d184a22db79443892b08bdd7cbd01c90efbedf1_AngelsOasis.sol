// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";

contract AngelsOasis is ERC721, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_ANGELS = 8888;
    uint256 public reservedAngels = 88;
    uint256 public presaleSupply = 2000;
    uint256 public mintPrice = 0.05 ether;
    uint256 public presaleMintcap = 10;
    uint256 public mintCap = 10;

    // Withdrawal addresses
    address public constant ADD = 0xaeF33e18FC210a22dD42AF5578837758B2349770;

    bool public preSale;
    bool public publicSale;
    bool public revealed;

    mapping(address => bool) public presalerList;
    mapping(address => uint256) public presalerListPurchases;

    string public defaultURI =
        "https://angelsoasis.mypinata.cloud/ipfs/QmbLaePgdLq1y9SKGRdEJ2pBEeS6ow6GUo5npiNhSVrGrL";

    constructor() ERC721("Angels Oasis", "AO") {}

    function addToPresaleList(address[] calldata entries) external onlyOwner {
        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            require(!presalerList[entry], "DUPLICATE_ENTRY");

            presalerList[entry] = true;
        }
    }

    function removeFromPresaleList(address[] calldata entries)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");

            presalerList[entry] = false;
        }
    }

    function gift(address[] calldata receivers) external onlyOwner {
        require(totalSupply() + receivers.length <= MAX_ANGELS, "MAX_MINT");
        require(receivers.length <= reservedAngels, "No reserved angels left");

        for (uint256 i = 0; i < receivers.length; i++) {
            reservedAngels--;
            _safeMint(receivers[i], totalSupply());
        }
    }

    function mintPreSale(uint256 num) public payable returns (bool) {
        uint256 currentSupply = totalSupply();
        require(preSale, "The pre-sale has NOT started, please wait.");
        require(presalerList[msg.sender], "Not qualified for presale");
        require(
            presalerListPurchases[msg.sender] + num <= presaleMintcap,
            "Exceeded presale allocation"
        );
        require(
            currentSupply + num <= MAX_ANGELS - reservedAngels,
            "Exceeding total supply"
        );
        require(
            currentSupply + num <= presaleSupply,
            "Exceeding presale supply."
        );
        require(msg.value >= mintPrice * num, "Ether sent is not sufficient.");
        require(!_isContract(msg.sender), "Caller cannot be contract");

        for (uint256 i = 0; i < num; i++) {
            presalerListPurchases[msg.sender]++;
            uint256 tokenIndex = totalSupply();
            if (tokenIndex < MAX_ANGELS) _safeMint(_msgSender(), tokenIndex);
        }

        return true;
    }

    function mintPublicSale(uint256 num) public payable returns (bool) {
        uint256 currentSupply = totalSupply();
        require(publicSale, "The public sale has NOT started, please wait.");
        require(num <= mintCap, "You are trying to mint too many.");
        require(
            currentSupply + num <= MAX_ANGELS - reservedAngels,
            "Exceeding total supply"
        );
        require(msg.value >= num * mintPrice, "Ether sent is not sufficient.");
        require(!_isContract(msg.sender), "Caller cannot be contract");

        for (uint256 i = 0; i < num; i++) {
            presalerListPurchases[msg.sender]++;
            uint256 tokenIndex = totalSupply();
            if (tokenIndex < MAX_ANGELS) _safeMint(_msgSender(), tokenIndex);
        }

        return true;
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 i; i < tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(tokenId < totalSupply(), "Token not exist.");

        // show default image before reveal
        if (!revealed) {
            return defaultURI;
        }

        string memory _tokenURI = _tokenUriMapping[tokenId];

        //return tokenURI if it is set
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        //If tokenURI is not set, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(baseURI(), tokenId.toString(), ".json"));
    }

    /*
     * Only the owner can do these things
     */
    function togglePublicSale() public onlyOwner {
        publicSale = !publicSale;
    }

    function togglePresale() public onlyOwner {
        preSale = !preSale;
    }

    function toggleReveal() public onlyOwner {
        revealed = !revealed;
    }

    function setDefaultURI(string memory _defaultURI) public onlyOwner {
        defaultURI = _defaultURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _setBaseURI(_newBaseURI);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        public
        onlyOwner
    {
        _setTokenURI(tokenId, _tokenURI);
    }

    function setPresaleSupply(uint256 _presaleSupply) public onlyOwner {
        presaleSupply = _presaleSupply;
    }

    function setPreSalePrice(uint256 _newPrice) public onlyOwner {
        mintPrice = _newPrice;
    }

    function setMintCap(uint256 _mintCap) public onlyOwner {
        mintCap = _mintCap;
    }

    function setPresaleMintCap(uint256 _presaleMintCap) public onlyOwner {
        presaleMintcap = _presaleMintCap;
    }

    function withdrawAll() public payable onlyOwner {
        //withdraw all
        require(
            payable(ADD).send(address(this).balance),
            "Withdraw Unsuccessful"
        );
    }

    function isWhiteListed(address entry) external view returns (bool) {
        return presalerList[entry];
    }

    function _isContract(address _addr) internal view returns (bool) {
        uint32 _size;
        assembly {
            _size := extcodesize(_addr)
        }
        return (_size > 0);
    }
}