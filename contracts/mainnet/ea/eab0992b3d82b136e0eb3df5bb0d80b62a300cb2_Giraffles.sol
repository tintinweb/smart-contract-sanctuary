// SPDX-License-Identifier: GPL-3.0
// Giraffles x MysteryMints 2022 - The Ultimate NFT Prize Draw
// Huge thanks to ToyBoogers & Pagzi Tech for the optimised ERC721 (goodbye high gas fees)
pragma solidity ^0.8.11;
import "./ERC721Enum.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./VRFConsumerBase.sol";

contract Giraffles is ERC721Enum, Ownable, ReentrancyGuard, VRFConsumerBase {
    using Strings for uint256;
    string public baseURI;
    
    // Chainlink VRF
    bytes32 public keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    uint256 public fee = 2 * 10 ** 18; // 2 LINK
    
    // prize blocknumbers (4 draws per month)
    uint256 public constant SALE_START_BLOCK = 14019615;        // 16th Jan 2022 ~6PM EST
    uint256 public draw_block_1 = SALE_START_BLOCK + 25928;     // 20th Jan 2022 ~5PM EST
    uint256 public draw_block_2 = SALE_START_BLOCK + 58680;     // 25th Jan 2022 ~5PM EST
    uint256 public draw_block_3 = SALE_START_BLOCK + 91432;     // 30th Jan 2022 ~5PM EST
    
    // current draw number (so that we can assign the randomness result to the correct draw)
    uint256 public currentDrawNumber = 0;
    
    // draw randomness results (set from Chainlink)
    uint256 public randomness_testing = 0;
    uint256 public randomness_draw_1 = 0;
    uint256 public randomness_draw_2 = 0;
    uint256 public randomness_draw_3 = 0;
    
    //sale settings
    uint256 public constant SALE_START_TIMESTAMP = 1642374000; // Sunday, January 16th 2022 11:00:00 PM (GMT)
    uint256 public price = 0.05 ether;
    uint256 public whitelistPrice = 0.02 ether;
    uint256 public whitelistMaxSupply = 1200;
    uint256 public whitelistMinted = 0;
    uint256 public maxSupply = 5000;
    uint256 public reserved = 80; // NFTs reserved for giveaways etc
    uint256 public maxMint = 20;
    bool public salePaused = false;

    // whitelist
    address public constant WHITELIST_SIGNER = 0x8430e0B7be3315735C303b82E4471D59AC152Aa5;
    
    string _name = "Giraffles";
    string _symbol = "Giraffles";
    string _initBaseURI = "https://mysterymints.io:7776/api/opensea/1/";
    
    constructor() ERC721P(_name, _symbol) VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
        ){
        setBaseURI(_initBaseURI);
    }

    /** 
     * Requests true on-chain randomness so we can test everything is working correctly
     */
    function randomnessTest() public onlyOwner {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract");
        
        // set current draw number to 0 (testing) so we can assign the randomness result
        currentDrawNumber = 0;
        
        // request randomness via Chainlink VRF
        requestRandomness(keyHash, fee);
    }
    
    /** 
     * Returns the randomness result for a given draw (0 if draw has not occured yet)
     */
    function randomnessForDraw(uint256 drawNumber) public view returns (uint256) {
        if(drawNumber == 1) {
            return randomness_draw_1;
        }
        else if(drawNumber == 2) {
            return randomness_draw_2;
        }
        else if(drawNumber == 3) {
            return randomness_draw_3;
        }
        else {
            return randomness_testing;
        }
    }
    
    /** 
     * For a given draw, returns the block number which must be reached before the draw can be executed
     */
    function blockThresholdForDraw(uint256 drawNumber) public view returns (uint256) {
        require(drawNumber > 0 && drawNumber <= 3, "Invalid drawNumber: must be 1-3");
        if(drawNumber == 1) {
            return draw_block_1;
        }
        else if(drawNumber == 2) {
            return draw_block_2;
        }
        else if(drawNumber == 3) {
            return draw_block_3;
        }
        return 0;
    }
    
    /** 
     * Requests true on-chain randomness for a given draw so that winners can be fairly chosen
     * Randomness can only be requested and set once for a given draw
     */
    function prizeDraw(uint256 drawNumber) public onlyOwner {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract");
        require(drawNumber > 0 && drawNumber <= 3, "Invalid drawNumber: must be 1-3");
        require(blockThresholdForDraw(drawNumber) <= block.number, "Prize block not reached yet");
        require(randomnessForDraw(drawNumber) == 0, "Randomness already generated for this draw");
        
        // set current draw number so we can correctly assign the randomness result
        currentDrawNumber = drawNumber;
        
        // request randomness via Chainlink VRF
        requestRandomness(keyHash, fee);
    }
    
    /**
     * Callback function used by VRF Coordinator
     * Sets the randomness result to a given draw, which is then used to determine the winners
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        if(currentDrawNumber == 1) {
            randomness_draw_1 = randomness;
        }
        else if(currentDrawNumber == 2) {
            randomness_draw_2 = randomness;
        }
        else if(currentDrawNumber == 3) {
            randomness_draw_3 = randomness;
        }
        else {
            randomness_testing = randomness;
        }
    }

    // internal
    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }
    
    function mintingHasStarted() public view returns (bool) {
        return block.timestamp >= SALE_START_TIMESTAMP;
    }

    function getWhitelistMinted() public view returns (uint256) {
        return whitelistMinted;
    }

    function whitelistCanMint() public view returns (bool) {
        return whitelistMinted < whitelistMaxSupply;
    }
    
    /**
     * @dev Gets current NFT Price
     */
    function getNFTPrice() public view returns (uint256) {
        return price;
    }

    /**
     * @dev Gets current NFT Price (whitelist)
     */
    function getWhitelistNFTPrice() public view returns (uint256) {
        return whitelistPrice;
    }
    
    /* whitelist */
    function isWhitelisted(address user, bytes memory signature) public pure returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(user));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        return recoverSigner(ethSignedMessageHash, signature) == WHITELIST_SIGNER;
    }
    
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }
    
    function splitSignature(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    // public minting
    function mintNFT(uint256 numberOfNfts, bytes memory signature, bool whitelist) public payable nonReentrant {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started");
        uint256 s = totalSupply();
        require(!salePaused, "Sale Paused");
        require(numberOfNfts > 0 && numberOfNfts <= maxMint, "Invalid numberOfNfts");
        require((s + numberOfNfts) <= (maxSupply - reserved), "Exceeds Max Supply");
        
        // user requesting cheaper mint price - verify they are whitelisted
        if(whitelist) {
            require(whitelistMinted < whitelistMaxSupply);
            require(msg.value >= whitelistPrice * numberOfNfts, "Not Enough ETH");
            require(isWhitelisted(msg.sender, signature), "Address not whitelisted");
            whitelistMinted += numberOfNfts;
        }
        // user requesting regular mint price
        else {
            require(msg.value >= price * numberOfNfts, "Not Enough ETH");
        }
        for (uint256 i = 0; i < numberOfNfts; ++i) {
            _safeMint(msg.sender, s + i, "");
        }
        delete s;
    }

    // admin minting for reserved NFTs
    function giftNFT(uint256[] calldata quantity, address[] calldata recipient) external onlyOwner {
        require(quantity.length == recipient.length, "Invalid quantities and recipients (length mismatch)");
        uint256 totalQuantity = 0;
        uint256 s = totalSupply();
        for (uint256 i = 0; i < quantity.length; ++i) {
            totalQuantity += quantity[i];
        }
        require(s + totalQuantity <= maxSupply, "Exceeds Max Supply");
        require(totalQuantity <= reserved, "Exceeds Max Reserved");

        // update remaining reserved count
        reserved -= totalQuantity;

        delete totalQuantity;
        for (uint256 i = 0; i < recipient.length; ++i) {
            for (uint256 j = 0; j < quantity[i]; ++j) {
                _safeMint(recipient[i], s++, "");
            }
        }
        delete s;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
    }

    /** 
     * Set the block number which must be reached before a given draw can be executed (callable by Owner only)
     */
    function setDrawBlock(uint256 drawNumber, uint256 blockNumber) public onlyOwner {
        require(drawNumber > 0 && drawNumber <= 3, "Invalid drawNumber: must be 1-3");
        if(drawNumber == 1) {
            draw_block_1 = blockNumber;
        }
        else if(drawNumber == 2) {
            draw_block_2 = blockNumber;
        }
        else if(drawNumber == 3) {
            draw_block_3 = blockNumber;
        }
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setWhitelistPrice(uint256 _newPrice) public onlyOwner {
        whitelistPrice = _newPrice;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMint = _newMaxMintAmount;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setWhitelistMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        whitelistMaxSupply = _newMaxSupply;
    }

    function setReserved(uint256 _newReserved) public onlyOwner {
        reserved = _newReserved;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setSalePaused(bool _salePaused) public onlyOwner {
        salePaused = _salePaused;
    }

    // the following function were added for transparency regarding ETH raised and prize pool calculations
    uint256 totalWithdrawn = 0;

    function getTotalWithdrawn() public view returns (uint256) {
        return totalWithdrawn;
    }

    function getTotalBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTotalRaised() public view returns (uint256) {
        return getTotalWithdrawn() + getTotalBalance();
    }

    /**
     * Withdraw ETH from the contract (callable by Owner only)
     */
    function withdraw() public payable onlyOwner {
        uint256 val = address(this).balance;
        (bool success, ) = payable(msg.sender).call{
            value: val
        }("");
        require(success);
        totalWithdrawn += val;
        delete val;
    }

    /**
     * Withdraw LINK tokens from the contract (callable by Owner only)
     */
    function withdrawLINK() public onlyOwner {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }
}