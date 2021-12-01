// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract GiftyKidsXmasCharity is ERC721, Ownable {
    using Address for address;
    using Strings for uint256;
    
    // metadata
    mapping(uint256 => string) public giftMessage;
    bool public metadataLocked = false;
    string public baseURI = "";

    // supply and days
    //uint256 public constant SUPPLY_PER_DAY = 100;
    uint256 public constant SUPPLY_PER_DAY = 3;
    //uint256 public constant DAY_DURATION = 1 days;
    uint256 public constant DAY_DURATION = 10 minutes;
    uint256 public constant TOTAL_DAYS = 24;
    mapping(uint256 => uint256) public totalMintedForDay;
    uint256 public startTimestamp;

    // sale
    bool public mintPaused = true;

    // pricing
    uint256 public priceWeth = 0.025 ether;
    uint256 public priceMatic = 65 ether;
    IERC20 public wethToken = IERC20(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection
     */
    constructor()
        ERC721("GiftyKidsXmasCharity", "GIFTY")
    {}
    
    /**
     * ------------ METADATA ------------ 
     */

    /**
     * @dev Gets base metadata URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    /**
     * @dev Sets base metadata URI, callable by owner
     */
    function setBaseUri(string memory _uri) external onlyOwner {
        require(metadataLocked == false);
        baseURI = _uri;
    }
    
    /**
     * @dev Lock metadata URI forever, callable by owner
     */
    function lockMetadata() external onlyOwner {
        require(metadataLocked == false);
        metadataLocked = true;
    }
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        
        string memory base = _baseURI();
        return string(abi.encodePacked(base, tokenId.toString()));
    }
    
    /**
     * ------------ SALE CONFIG ------------ 
     */

    /**
     * @dev Pause/unpause sale or presale
     */
    function togglePauseMinting() external onlyOwner {
        require(startTimestamp > 0, "Start sale first");
        mintPaused = !mintPaused;
    }

    /**
     * @dev Edit sale parameters: price points
     */
    function editParameters(uint256 _priceWeth, uint256 _priceMatic) external onlyOwner {
        priceWeth = _priceWeth;
        priceMatic = _priceMatic;
    }

    /**
     * @dev Set start timestamp and unpause minting
     */
    function setScheduledSaleStart(uint256 _startTimestamp) external onlyOwner {
        startTimestamp = _startTimestamp;
        mintPaused = false;
    }

    /**
     * @dev Set start timestamp to current timestamp and unpause minting
     */
    function startSaleNow() external onlyOwner {
        startTimestamp = block.timestamp;
        mintPaused = false;
    }

    /**
     * @dev Set WETH token address
     */
    function setWethTokenAddress(address _wethToken) external onlyOwner {
        wethToken = IERC20(_wethToken);
    }
     
    /**
     * ------------ MINTING ------------ 
     */
    
    /**
     * @dev Public minting - internal function
     */
    function mint(address receiver, string calldata message) internal {
        require(!mintPaused, "Minting is currently paused");
        require(block.timestamp >= startTimestamp, "You're too early");
        require(msg.sender != receiver, "You must gift it :)");

        uint256 currentDay = (block.timestamp - startTimestamp) / DAY_DURATION;
        require(currentDay < TOTAL_DAYS, "Sale ended");
        require(totalMintedForDay[currentDay] + 1 <= SUPPLY_PER_DAY, "Supply exceeded");   

        uint256 tokenId = totalMintedForDay[currentDay] + currentDay * SUPPLY_PER_DAY;
        _mint(receiver, tokenId);
        totalMintedForDay[currentDay]++;

        giftMessage[tokenId] = message;
    }

    /**
     * @dev Owner minting
     */
    function mintOwner(address[] calldata receivers, string[] calldata messages, uint256[] calldata tokenDays) external onlyOwner {
        require(receivers.length == messages.length && messages.length == tokenDays.length, "Bad lengths");

        for (uint256 i = 0; i < receivers.length; i++) {
            require(tokenDays[i] < TOTAL_DAYS, "Bad day");
            require(totalMintedForDay[tokenDays[i]] + 1 <= SUPPLY_PER_DAY, "Supply exceeded");
            uint256 tokenId = totalMintedForDay[tokenDays[i]] + tokenDays[i] * SUPPLY_PER_DAY;
            
            _mint(receivers[i], tokenId);
            totalMintedForDay[tokenDays[i]]++;

            giftMessage[tokenId] = messages[i];
        }
    }

    /**
     * @dev Public minting (paying with MATIC)
     */
    function mintWithMatic(address receiver, string calldata message) external payable{
        require(msg.value == priceMatic, "Matic value incorrect");        
        mint(receiver, message);
    }

    /**
     * @dev Public minting (paying with WETH)
     */
    function mintWithWETH(address receiver, string calldata message) external {
        wethToken.transferFrom(msg.sender, address(this), priceWeth);
        mint(receiver, message);
    }

    /**
     * @dev Withdraw matic from this contract, callable by owner
     */
    function withdrawMatic() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * @dev Withdraw WETH from this contract, callable by owner
     */
    function withdrawWETH() external onlyOwner {
        uint256 balance = wethToken.balanceOf(address(this));
        wethToken.transfer(msg.sender, balance);
    }

    /**
     * ------------ VIEW FUNCTIONS ------------ 
     */

    /**
     * @dev Return current day; view function
     */
    function getCurrentDay() public view returns (uint256) {
        return (block.timestamp - startTimestamp) / DAY_DURATION;
    }
}