// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";

contract TheNinjaHideout is ERC721, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_NINJAS = 8888;
    uint256 public reservedNinjas = 88;
    uint256 public presaleSupply = 2500;
    uint256 public mintPrice = 0.05 ether;
    uint256 public presaleMintcap = 2;
    uint256 public mintCap = 5;

    // Withdrawal addresses
    address public constant ADD = 0xa64b407D4363E203F682f7D95eB13241B039E580;

    bool public preSale;
    bool public publicSale;
    bool public revealed;

    uint256 public reservedMintedAmount;

    mapping(address => bool) public presalerList;
    mapping(address => uint256) public presalerListPurchases;

    string public defaultURI =
        "https://theninjahideout.mypinata.cloud/ipfs/QmfJc4PfhvUjxRYjiAvR72AecnikbRoySknGGrawuWrzn1";

    constructor(string memory baseURI) ERC721("The Ninja Hideout", "TNH") {
        setBaseURI(baseURI);
    }

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
        require(totalSupply() + receivers.length <= MAX_NINJAS, "MAX_MINT");
        // require(
        //     reservedMintedAmount + receivers.length <= reservedNinjas,
        //     "GIFTS_EMPTY"
        // );
        require(receivers.length <= reservedNinjas, "No reserved ninjas left");

        for (uint256 i = 0; i < receivers.length; i++) {
            reservedNinjas--;
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
            currentSupply + num <= MAX_NINJAS - reservedNinjas,
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
            if (tokenIndex < MAX_NINJAS) _safeMint(_msgSender(), tokenIndex);
        }

        return true;
    }

    function mintPublicSale(uint256 num) public payable returns (bool) {
        uint256 currentSupply = totalSupply();
        require(publicSale, "The public sale has NOT started, please wait.");
        require(num <= mintCap, "You are trying to mint too many.");
        require(
            currentSupply + num <= MAX_NINJAS - reservedNinjas,
            "Exceeding total supply"
        );
        require(msg.value >= num * mintPrice, "Ether sent is not sufficient.");
        require(!_isContract(msg.sender), "Caller cannot be contract");


        for (uint256 i = 0; i < num; i++) {
            presalerListPurchases[msg.sender]++;
            uint256 tokenIndex = totalSupply();
            if (tokenIndex < MAX_NINJAS) _safeMint(_msgSender(), tokenIndex);
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

        tokenId += 1;
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
        //withdraw half
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