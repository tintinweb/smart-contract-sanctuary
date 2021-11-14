// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./Context.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract CheekySnails is Ownable, ReentrancyGuard, ERC721Enumerable {
    using SafeMath for uint256;
    using Strings for uint256;

    // Public variables
    uint256 public MAX_NFT_SUPPLY = 3;
    uint256 public MINT_PRICE = 15*10**15; // presale, public, collab
    uint256 public state;
    string public _baseTokenURI;
    uint256 private _randomNum = 626;
    mapping (address => uint256) private wlBalance;

    // Events
    event ChangeState(uint256 currentState);
    event Mint(address minter, uint256 quantity);
    event Reveal(uint256 index);

    /**
     * @dev Initialize
     */
    constructor(string memory baseURI) ERC721("Cheeky Snails", "CS"){
        // set url
        setBaseURI(baseURI);
    }

    /**
     * @dev Gets base url
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Sets base url. In case of emergency
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Sets price. In case of emergency
     */
    function setPrice(uint256 _price) public onlyOwner {
        MINT_PRICE = _price;
    }

    /**
    * @dev Sets state.  0 - sales are paused; 1 - prsale,  2 - sale
    */
    function setState(uint256 val) external onlyOwner {
        state = val;

        // event
        emit ChangeState(val);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

    /**
    * @dev List NFTs owned by address
    */
    function listNFTs(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    /**
    * @dev Mints for public launch
    */
    function mint(uint256 quantity) external nonReentrant payable {
        require(state == 2, "Sale is paused");
        require(quantity>= 1 && quantity<= 20, "Amount of minted NFTs at once should be in [1,20] interval");
        require(msg.value == MINT_PRICE.mul(quantity), "Wrong ETH amount");

        // mint
        _mintBase(_msgSender(), quantity);

        // event
        emit Mint(_msgSender(), quantity);
    }

    /**
    * @dev Mints for airdrops
    */
    function mintAirdrop(uint256 quantity, address reciever) external onlyOwner {
        // Just natural limit in case of typo
        require(quantity>= 1 && quantity<= 100, "Amount of minted NFTs at once should be in [1,100] interval");
        _mintBase(reciever, quantity);
    }

    /**
    * @dev base mint
    */
    function _mintBase(address to, uint256 quantity) private {
        for (uint i=0; i<quantity; i++){
            // mint
            uint256 mintIndex = totalSupply();
            _safeMint(to, mintIndex);
            require(totalSupply() <= MAX_NFT_SUPPLY, "Sale has already ended OR not enough NFTs left");
        }
    }

    /**
    * @dev Withdraw ether
    */
    function withdraw() public onlyOwner {
        // get balance
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");
        Address.sendValue(payable(owner()), balance);
    }

    fallback() external payable {
    }

    receive() external payable {
    }
}