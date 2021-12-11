// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

interface IERC20Burnable {
    function burnFrom(address account, uint256 amount) external;
}

interface ISKINContract {
    function mint(address recipient, uint256 amount) external;
}

contract SassySnakes is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    uint256 public constant MAX_PER_CALL = 100;
    // Uncommon < 288 < Common < 768 < Rare < 1536 < Epic < 3840 < Sassy
    uint256[] public RARITY_BOUNDS = [0, 288, 768, 1536, 3840];

    uint256 public MINT_PRICE;
    uint256 public MAX_SUPPLY;
    uint256 public MAX_MINTABLE_SUPPLY;
    uint256 public RAFFLE_TOKEN_ID;
    address public SKIN_ERC20_CONTRACT;
    address private PAYMENT_ADDR_1;
    address private PAYMENT_ADDR_2;
    address private PAYMENT_ADDR_3;

    bool public isMintEnabled;
    string public baseUri;
    mapping(uint256 => uint256) public amountFed;
    mapping(uint256 => uint256[]) public rarities; // token => ([traitId]=rarity)
    mapping(address => bool) public amountFedEditors;
    Counters.Counter private _tokenIdCounter;
    mapping(address => uint256) private _mintCounter;
    mapping(address => bool) private _receivedSkin;
    mapping(address => bool) private _raffleEntered;
    bool private _uniqueSent;
    address[] private _raffle;
    
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _mintPrice,
        uint256 _maxSupply,
        address _snakeskinErc20,
        address _paymentAddr1,
        address _paymentAddr2,
        address _paymentAddr3
    ) ERC721(_name, _symbol) {
        MAX_SUPPLY = _maxSupply;
        MAX_MINTABLE_SUPPLY = MAX_SUPPLY - 1;
        MINT_PRICE = _mintPrice;
        SKIN_ERC20_CONTRACT = _snakeskinErc20;
        PAYMENT_ADDR_1 = _paymentAddr1;
        PAYMENT_ADDR_2 = _paymentAddr2;
        PAYMENT_ADDR_3 = _paymentAddr3;
        isMintEnabled = false;
    }

    modifier onlyAmountFedEditors {
      require(amountFedEditors[msg.sender] == true, "Amount fed can only be edited without cost by approved editors");
      _;
   }

   function supplyMinted() public view returns (uint256) {
       return _tokenIdCounter.current();
   }

    function mintSnake(uint256 numOfTokens) public payable {
        require(isMintEnabled == true, "Mint is not currently open");
        require(numOfTokens > 0 && numOfTokens <= MAX_PER_CALL, "Invalid number of tokens requested");
        require(_tokenIdCounter.current() + numOfTokens <= MAX_MINTABLE_SUPPLY, "Too many tokens requested with too few in supply");
        require(msg.value >= MINT_PRICE.mul(numOfTokens), "More FTM required");

        // Payment splitter
        uint256 totalPayment = msg.value;
        uint256 addr1Payment = (totalPayment.mul(375)).div(1000);
        uint256 addr2Payment = (totalPayment.mul(375)).div(1000);
        uint256 addr3Payment = totalPayment - addr1Payment - addr2Payment;
        payable(PAYMENT_ADDR_1).transfer(addr1Payment);
        payable(PAYMENT_ADDR_2).transfer(addr2Payment);
        payable(PAYMENT_ADDR_3).transfer(addr3Payment);

        for (uint256 i = 0; i < numOfTokens; i++) {
            _mintSnake(msg.sender);
        }
    }

    // Levels increase in increments of 1000, e.g. 1000 to reach level 2, 2000 to reach level 3
    function snakeSize(uint256 tokenId) public view returns (uint256) {
        uint256 sizeCounter = 1;
        uint256 amountFedSnake = amountFed[tokenId];

        while (amountFedSnake >= (sizeCounter.mul(1000 ether))) {
            amountFedSnake = amountFedSnake.sub(sizeCounter.mul(1000 ether));
            sizeCounter = sizeCounter.add(1);
        }

        return sizeCounter;
    }

    /**
     * Contract must first be approved to use $mouse amount before being called
     */
    function feedSnake(uint256 tokenId, uint256 amount) public {
        require(tokenId <= _tokenIdCounter.current(), "Snake does not exist");
        require(ownerOf(tokenId) == msg.sender, "You do not own the snake you are trying to feed");

        // Get the size of the snake and add the mice to it
        amountFed[tokenId] = amountFed[tokenId].add(amount);

        // Burn - Must be approved by MICE_ERC20_CONTRACT to do this transaction
        IERC20Burnable(SKIN_ERC20_CONTRACT).burnFrom(msg.sender, amount);
    }

    function traitRarities(uint256 tokenId) public view returns (uint256[] memory) {
        return rarities[tokenId];
    }

    function snakeRarity(uint256 tokenId) public view returns (uint256) {
        uint256 rarity = 1;

        for (uint256 i = 0; i < rarities[tokenId].length; i++) {
            rarity = rarity.mul(rarities[tokenId][i]);
        }

        uint256 rarityLevel = 0;
        for (uint256 i = 0; i < RARITY_BOUNDS.length; i++) {
            if (rarity >= RARITY_BOUNDS[i]) {
                rarityLevel += 1;
            } else {
                break;
            }
        }

        return rarityLevel;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    ///////////////////////////////////
    //  onlyAmountFedEditors functions
    ///////////////////////////////////

    function increaseAmountFed(uint256 tokenId, uint256 amount) public onlyAmountFedEditors {
        require(tokenId <= _tokenIdCounter.current(), "Snake does not exist");
        amountFed[tokenId] = amountFed[tokenId].add(amount);
    }

    function decreaseAmountFed(uint256 tokenId, uint256 amount) public onlyAmountFedEditors {
        require(tokenId <= _tokenIdCounter.current(), "Snake does not exist");
        amountFed[tokenId] = amountFed[tokenId].sub(amount);
    }

    ///////////////////////////////////
    //  onlyOwner functions
    ///////////////////////////////////

    function adminMintSnake(address recipient, uint256 numOfTokens) public onlyOwner {
        require(numOfTokens > 0 && numOfTokens <= MAX_PER_CALL, "Invalid number of tokens requested");
        require(_tokenIdCounter.current() + numOfTokens <= MAX_MINTABLE_SUPPLY, "Too many tokens requested with too few in supply");

        for (uint256 i = 0; i < numOfTokens; i++) {
            _mintSnake(recipient);
        }
    }

    function enableMinting() public onlyOwner {
        isMintEnabled = true;
    }

    function disableMinting() public onlyOwner {
        isMintEnabled = false;
    }

    function setBaseUri(string memory _uri) public onlyOwner {
        baseUri = _uri;
    }

    function setTraitRarities(uint256 tokenId, uint256[] memory snakeRarities) public onlyOwner {
        require(tokenId <= _tokenIdCounter.current(), "Snake does not exist");
        require(snakeRarities.length == 10, "Rarity score for all 10 attributes is required");

        rarities[tokenId] = snakeRarities;
    }

    function addAmountFedEditor(address account) public onlyOwner {
        amountFedEditors[account] = true;
    }

    function removeAmountFedEditor(address account) public onlyOwner {
        amountFedEditors[account] = false;
    }

    ///////////////////////////////////
    //  private/internal functions
    ///////////////////////////////////

    function _mintSnake(address recipient) private {
        _tokenIdCounter.increment();
        _safeMint(recipient, _tokenIdCounter.current());
        amountFed[_tokenIdCounter.current()] = 0;
        _mintCounter[recipient] += 1;

        if (_mintCounter[recipient] >= 4 && !_receivedSkin[recipient]) {
            _receivedSkin[recipient] = true;
            _sendSkin(recipient, 2000 ether);
        }

        if (_mintCounter[recipient] >= 10 && !_raffleEntered[recipient]) {
            _raffleEntered[recipient] = true;
            _raffle.push(recipient);
        }

        if (_tokenIdCounter.current() == MAX_MINTABLE_SUPPLY) {
            _sendUniqueToRandomMinter();
        }
    }

    function _sendSkin(address recipient, uint256 amount) private {
        ISKINContract(SKIN_ERC20_CONTRACT).mint(recipient, amount);
    }

    function _sendUniqueToRandomMinter() private {
        require(!_uniqueSent, "Raffle already ran");
        _uniqueSent = true;
        address winner = getRaffleWinner();
        _mintSnake(winner);
    }

    function getRaffleWinner() internal view returns (address) {
        uint256 random = uint256(
            keccak256(abi.encodePacked(block.difficulty, block.timestamp, _raffle))
        ) % _raffle.length;

        return _raffle[random];
    }

    // For ERC721Enumerable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }
}