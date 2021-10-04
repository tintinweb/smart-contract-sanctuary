pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract TheMaskedChildren is ERC721Enumerable, Ownable {

    uint256 public constant MAX_CHILDREN = 7000;
    uint256 public constant PRICE = .06 ether;
    uint256 public constant WHITELIST_MAX_TO_MINT = 5;
    uint256 public constant PUBLIC_MAX_TO_MINT = 20;

    bool public whitelistIsActive = false;
    bool public publicIsActive = false;

    string public baseTokenURI;

    mapping(address => bool) private _whitelist;
    mapping(address => uint256) private _amountClaimed;


    constructor() ERC721 ("TheMaskedChildren", "TMC") {}

    function toggleWhitelistSaleState() public onlyOwner {
        whitelistIsActive = !whitelistIsActive;
    }

    function togglePublicSaleState() public onlyOwner {
        publicIsActive = !publicIsActive;
    }

    function addToWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add a null address");
            _whitelist[addresses[i]] = true;
            _amountClaimed[addresses[i]] > 0 ? _amountClaimed[addresses[i]] : 0;
        }
    }

    function onWhitelist(address addr) external view returns(bool) {
        return _whitelist[addr];
    }

    function removeFromWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add a null address");
            _whitelist[addresses[i]] = false;
        }
    }

    function whitelistMint(uint amountToMint) public payable {
        uint256 total = totalSupply();
        require(whitelistIsActive, "Whitelist sale is not active.");
        require(_whitelist[msg.sender], "You are not on the whitelist.");
        require(amountToMint > 0, "You have to mint at least 1 child.");
        require(amountToMint <= WHITELIST_MAX_TO_MINT, "Can only mint 5 tokens.");
        require(_amountClaimed[msg.sender] + amountToMint <= WHITELIST_MAX_TO_MINT, "Purchase would exceed the max to mint.");
        require(amountToMint + total <= MAX_CHILDREN, "The number exceeds the amount of available children to mint.");
        require(total < MAX_CHILDREN, "The sale is complete.");
        require(PRICE * amountToMint == msg.value, "Incorrect ETH amount.");

        for(uint i = 0; i < amountToMint; i++) {
            if (totalSupply() < MAX_CHILDREN) {
                _amountClaimed[msg.sender] += 1;
                _safeMint(msg.sender, totalSupply());
            }
        }
    }

    function publicMint(uint amountToMint) public payable {
        uint256 total = totalSupply();
        require(publicIsActive, "Public sale is not active.");
        require(amountToMint > 0, "You have to mint at least 1 child.");
        require(amountToMint <= PUBLIC_MAX_TO_MINT, "Can only mint 20 tokens at a time.");
        require(amountToMint + total <= MAX_CHILDREN, "The number exceeds the amount of available children to mint.");
        require(total < MAX_CHILDREN, "The sale is complete.");
        require(PRICE * amountToMint == msg.value, "Incorrect ETH amount.");


        for(uint i = 0; i < amountToMint; i++) {
            if (totalSupply() < MAX_CHILDREN) {
                _safeMint(msg.sender, totalSupply());
            }
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ETH is available to withdraw.");
        payable(msg.sender).transfer(balance);
    }

}