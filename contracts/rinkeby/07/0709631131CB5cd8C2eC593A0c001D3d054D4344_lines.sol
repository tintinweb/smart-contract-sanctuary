// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./Counters.sol";

contract lines is ERC721, ERC721Enumerable, ERC721Burnable, Ownable, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 public PRICE = 11000000000000000; // 0.011 ETH
    uint256 public MAX_SUPPLY = 11111;
    
    mapping(address => bool) internal _whitelist;

    bool public presaleActive = false;
    bool public publicSaleActive = false;
    
    string private _baseURIextended;
    uint256 private _maxMintsAtOnce = 11;

    constructor() ERC721("Project 11111", "LINE"){}
    
    // Modifiers
    modifier requireMint(uint256 numberOfTokens, uint256 maxPerMint) {
        require(numberOfTokens > 0, "Must be greater than 0");
        require(numberOfTokens <= maxPerMint, "Cannot mint more than max");
        require(
            (totalSupply() + numberOfTokens) < MAX_SUPPLY,
            "Exceeded max supply"
        );
        require(
            calculateMintCost(numberOfTokens) == msg.value,
            "Value is not correct"
        );
        _;
    }
    
    // Admin
    function addToWhitelist(address[] calldata addresses)
        public
        onlyRole(ADMIN_ROLE)
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelist[addresses[i]] = true;
        }
    }

    function togglePresale() public onlyRole(ADMIN_ROLE) {
        presaleActive = !presaleActive;
    }

    function togglePublicSale() public onlyRole(ADMIN_ROLE) {
        publicSaleActive = !publicSaleActive;
    }

    function setBaseURI(string memory baseURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _baseURIextended = baseURI;
    }

    function reserveTokens(uint256 numberOfTokens, address recipient)
        public
        onlyRole(ADMIN_ROLE)
    {
        require(numberOfTokens > 0, "Must be greater than 0");
        require(
            (totalSupply() + numberOfTokens) < MAX_SUPPLY,
            "Exceeded max supply"
        );

        _mint(numberOfTokens, recipient);
    }

    // Presale
    function presaleMint(uint256 numberOfTokens)
        public
        payable
        requireMint(numberOfTokens, _maxMintsAtOnce)
    {
        require(presaleActive == true, "Presale must be active");
        require(_whitelist[_msgSender()] == true, "Not on whitelist");
        //require(_presaleMinted[_msgSender()] == false, "Already minted");

        //_presaleMinted[_msgSender()] = true;
        _mint(numberOfTokens, _msgSender());
    }

    // Public Sale
    function mint(uint256 numberOfTokens)
        public
        payable
        requireMint(numberOfTokens, _maxMintsAtOnce)
    {
        require(publicSaleActive == true, "Sale must be active");

        _mint(numberOfTokens, _msgSender());
    }

    // Utility
    function presaleAllowed(address presaleAddress) public view returns (bool) {
        return _whitelist[presaleAddress];
    }

    // Internal
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function _mint(uint256 numberOfTokens, address sender) internal {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(sender, totalSupply());
        }
    }
    
    function withdraw() public onlyRole(ADMIN_ROLE) {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    function calculateMintCost(uint numberOfTokens) internal view returns(uint) {
        return numberOfTokens * PRICE;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}