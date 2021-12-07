pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "hardhat/console.sol";

import "./JSONBuilder.sol";
import "./interfaces/IClipNFT.sol";
import "./interfaces/IFutura.sol";
import "./FuturaMetadata.sol";

/*
    Clips: Individual audio samples that can be assigned to a particular cell. These are tokenized in a separate contract
    Section: Parts of a song, eg "Intro", "Bass drop", "Verse 1"
    Stem: Particular instrumental layer of the music, eg "Vocals", "Bass", "Drums"
    Cell: A stem & stection combination

    Cell layout example:

    Section   0   1   2   3
    Layer 0   0   1   2   3
    Layer 1   4   5   6   7
    Layer 2   8   9  10  11
    Layer 3  12  13  14  15

    Each cell will have an array of Clips available, cellClipIDs
    Repeated clip IDs allow for weighted distribution when randomly selecting clips
    Example

    Cell 0: [0, 0, 1, 1, 2, 5]
    Cell 1: [1, 2, 3, 3, 4]
    Cell 2: [2, 2, 2, 3]
    Cell 3: [1, 2, 3, 4, 5]
    ...

    TokenData.ClipIDs, clip token IDs assignments for each cell

    Masters: artist-curated reserved tokens, cannot be burned
    Mixes: randomly generated tokens mintable in exchange for a MixPass ERC1155
      mixes are limited to a supply of 8080, and the dropStage must be set to MIXES_AVAILABLE
      clipID tokens won't have media associated until after mix minting is closed
    Remixes: generated from two input mixes or masters, one of both of the inputs can be burned

    Generation 0 => Master
    Generation 1 => Mix
    Generation 2+=> Remix 

*/


/// @title EulerBeats Futura token drop 2021
/// @notice ERC721 for minting random mixes and remixing, music generated from a set of available clips in the clipNFT 721 contract
contract Futura is IFutura, ERC721, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // CONSTANTS
    address constant private ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // Reserved # of masters
    uint256 constant RESERVED_MASTERS = 11;

    // Reserved number of mixes at 8080 + RESERVED_MASTERS = 8090
    uint256 constant MAX_MIX_TOKEN_ID = 8080 + RESERVED_MASTERS;

    // NFT contract with tokens representing each clip, leave this as upgradeable
    address public clipNFTAddress;

    // External contract for retreiving metadata JSON for a particular token
    FuturaMetadata public futuraMetadata;

    // Identifies the state of the drop, settable by owner
    enum DropStage {
        SETUP,    // Default: for admin configuring
        MIXES_AVAILABLE,  // Redemption of 1155s are open for minting Mixes
        SALE_COMPLETE,    // Mixes are no longer available, this phase is for uploading the Clip Token Metadata & Creating the Master Tokens
        REMIXING_ENABLED  // Remixing is now live
    }

    // Maps tokenId to struct of token data
    mapping (uint256 => TokenData) public tokenData;

    // Maps hash(tokenData.clipIDs) => tokenId, enforces uniqueness
    mapping (bytes32 => uint256) public clipHashToToken;

    // Map a cell to its array of weighted available clip IDs, 0 == NULL
    // eg availableCellClipIDs[cellID] = [0,0,0,0,4,4,5,6] has 50% chance of NULL selection, 25% chance of 4, .125 chance of 5 and 6
    uint256[][] public availableCellClipIDs;

    // Array of string names for all sections & stems
    uint256 public sectionCount;
    uint256 public layerCount;

    string public playerUri;

    // Available bpms for mixes remixes & masters
    uint256 public availableBpmCount;

    // Editable price to remix a mix
    uint256 public priceToRemix = 0.05 ether;
    uint256 public priceToRemixOneBurn = 0.025 ether;
    uint256 public priceToRemixTwoBurns = 0;
    uint256 public priceToRemixWithPass = 0.0375 ether;

    uint256 public royaltyBps = 5000;   // Initialize at 50% of payments distributed via royalties

    // Initial drop stage
    DropStage public dropStage = DropStage.SETUP;

    // Locks to prevent further editing of masters, remix prices, or royalty bps
    bool private _isEditingMastersLocked = false;
    bool private _isEditingPricesLocked = false;
    bool private _isEditingRoyaltyBpsLocked = false;

    // First token ID to allocate for random mixes (11)
    uint256 private _nextTokenId = RESERVED_MASTERS + 1;

    // Token Type and data for discount NFTs - tokens that if held by tx.origin allow for a % ETH discount on cost of remixing
    enum TokenType { ERC721, ERC1155 }

    struct DiscountNFT {
        address tokenAddress;
        uint256 tokenId;  // Optional
        TokenType tokenType;
    }
    // Mapping to act as an array of discountNFTs that if held by tx.origin, result in a discounted remix price
    mapping (uint256 => DiscountNFT) public discountNFTs;

    // WETH ERC20 address for payments
    address public paymentTokenAddress;

    // Cryptovoxels ERC1155 address & tokenID required to be redeemed for a mix
    address public redemptionTokenAddress;
    uint256 public redemptionTokenID;

    // TODO: Hard code the ERC721 name, symbol, and URI
    constructor(address paymentTokenAddressParam, address redemptionTokenAddressParam, uint256 redemptionTokenIDParam) ERC721("EulerBeats: Futura", "eBEATS") {
        paymentTokenAddress = paymentTokenAddressParam;
        redemptionTokenAddress = redemptionTokenAddressParam;
        redemptionTokenID = redemptionTokenIDParam;
    }

    /***********************************|
    |        EXTERNAL                   |
    |__________________________________*/
	
    // Implement onERC1155*Received to support receiving 1155s
	function onERC1155Received(
		address operator,
		address from,
		uint256 id,
		uint256 value,
		bytes calldata data
	) external returns(bytes4){
		return this.onERC1155Received.selector;
	}

	function onERC1155BatchReceived(
		address operator,
		address from,
		uint256[] calldata ids,
		uint256[] calldata values,
		bytes calldata data
	) external returns(bytes4){
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @notice Get tokenURI for a tokenId
     * @param tokenId uint256
     * @return data URI encoding of JSON string
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return futuraMetadata.tokenURI(tokenId);
    }

    /**
     * @notice Mint many random mixes
     */
    function mintManyMixes(uint256 count) public {
        require(count <= 10, "Cannot mint more than 10 at once");
        for (uint256 i = 0; i < count; i++) {
            mintMix();
        }
    }

    /**
     * @notice Mint a random mix
     */
    function mintMix() public nonReentrant {
        require(dropStage == DropStage.MIXES_AVAILABLE, "Invalid stage");

        uint256 tokenId = _nextTokenId;

        require(tokenId + 1 <= MAX_MIX_TOKEN_ID, "No more mixes available");

        // Increment _nextTokenId by 2 for both mixes
        _nextTokenId = _nextTokenId + 2;

        // Transfer 1 mixpass to this contract
        IERC1155(redemptionTokenAddress).safeTransferFrom(msg.sender, address(this), redemptionTokenID, 1, "");

        // Generate first mix
        uint256 seed = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, tokenId)));
        (uint8 bpmIndex, uint256[] memory clipIDs) = _generateMix(seed);

        _mint(msg.sender, tokenId);
        // will revert if token already taken
        _setTokenData(tokenId, TokenData(msg.sender, bpmIndex, 1, clipIDs));

        // Generate second mix
        tokenId = tokenId + 1;
        seed = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, tokenId)));
        (bpmIndex, clipIDs) = _generateMix(seed);

        _mint(msg.sender, tokenId);
        // will revert if token already taken
        _setTokenData(tokenId, TokenData(msg.sender, bpmIndex, 1, clipIDs));
    }

    /**
     * @notice Mint a remix from two held token
     * @param tokenIdLeft uint256
     * @param tokenIdRight uint256
     * @param bpmIndex uint8
     * @param clipIDs uint256[]
     */
    function mintRemixWithNoBurn(uint256 tokenIdLeft, uint256 tokenIdRight, uint8 bpmIndex, uint256[] memory clipIDs) public nonReentrant {
        TokenData memory remixData = _checkRemixAndGetData(tokenIdLeft, tokenIdRight, bpmIndex, clipIDs);

        uint256 tokenId = _nextTokenId++;

        uint256 price = getRemixPrice(tx.origin, 0);
        _sendWETHPayment(msg.sender, address(this), price);
        
        // Mint tokenIdNew to the msg.sender, and set its clipHash
        _mint(msg.sender, tokenId);
        _setTokenData(tokenId, remixData);

        uint256 royaltyAmount = getRoyaltyAmount(price);
        if (royaltyAmount > 0) {
          IClipNFT(clipNFTAddress).addRoyalty(royaltyAmount, clipIDs);
        }
    }

    /**
     * @notice Mint a remix from one burned token and one held token
     * @param tokenIdLeftKeep uint256
     * @param tokenIdRightBurn uint256
     * @param bpmIndex uint8
     * @param clipIDs uint256[]
     */
    function mintRemixWithOneBurn(uint256 tokenIdLeftKeep, uint256 tokenIdRightBurn, uint8 bpmIndex, uint256[] memory clipIDs) public {
        TokenData memory remixData = _checkRemixAndGetData(tokenIdLeftKeep, tokenIdRightBurn, bpmIndex, clipIDs);
        uint256 tokenId = _nextTokenId++;

        // send remix price in ETH to this contract
        uint256 price = getRemixPrice(tx.origin, 1);
        _sendWETHPayment(msg.sender, address(this), price);
        
        // Burn the tokenIdBurn and free up its clipHash
        require(tokenIdRightBurn > RESERVED_MASTERS, "Cannot burn a master token");
        _clearTokenData(tokenIdRightBurn);
        _burn(tokenIdRightBurn);

        // Mint tokenIdNew to the msg.sender, and set its clipHash
        _mint(msg.sender, tokenId);
        _setTokenData(tokenId, remixData);

        // send a percent of the payment out as royalties, rest is kept in this contract
        uint256 royaltyAmount = getRoyaltyAmount(price);
        if (royaltyAmount > 0) {
          IClipNFT(clipNFTAddress).addRoyalty(royaltyAmount, clipIDs);
        }
    }

    /**
     * @notice Mint a remix from two burned tokens
     * @param tokenIdLeftBurn uint256
     * @param tokenIdRightBurn uint256
     * @param bpmIndex uint8
     * @param clipIDs uint256[]
     */
    function mintRemixWithTwoBurns(uint256 tokenIdLeftBurn, uint256 tokenIdRightBurn, uint8 bpmIndex, uint256[] memory clipIDs) public nonReentrant {
        TokenData memory remixData = _checkRemixAndGetData(tokenIdLeftBurn, tokenIdRightBurn, bpmIndex, clipIDs);
        uint256 tokenId = _nextTokenId++;

        uint256 price = getRemixPrice(tx.origin, 2);
        _sendWETHPayment(msg.sender, address(this), price);

        // Burn the tokenIdBurn and free up its clipHash
        require(tokenIdLeftBurn > RESERVED_MASTERS && tokenIdRightBurn > RESERVED_MASTERS, "Cannot burn a master token");

        _burn(tokenIdLeftBurn);
        _clearTokenData(tokenIdLeftBurn);

        _burn(tokenIdRightBurn);
        _clearTokenData(tokenIdRightBurn);

        // Mint tokenIdNew to the msg.sender, and set its clipHash
        _mint(msg.sender, tokenId);
        _setTokenData(tokenId, remixData);

        // If any price charged, send royalty to clips
        uint256 royaltyAmount = getRoyaltyAmount(price);
        if (royaltyAmount > 0) {
          IClipNFT(clipNFTAddress).addRoyalty(royaltyAmount, clipIDs);
        }
    }


    /**
     * @notice Public view function to get the amount of the remix price that is distributed as royalties
     * @param sentAmount uint256
     * @return royaltyAmount uint256 amount to distribute as royalties
     */
    function getRoyaltyAmount(uint256 sentAmount) public view returns (uint256 royaltyAmount) {
        royaltyAmount = royaltyBps * sentAmount / 10000;
    }


    /**
     * @notice Public view function to get a price for remixing, given a tx.origin address & number of burns.
     * @param origin address
     * @param numberOfBurns uint256
     * @return price uint256 price of remixing
     */
    function getRemixPrice(address origin, uint256 numberOfBurns) public view returns (uint256 price) {
        // Free minting when burning two tokens
        if (numberOfBurns > 1) {
            return priceToRemixTwoBurns;
        }

        if (numberOfBurns == 1) {
            return priceToRemixOneBurn;
        }

        // If tx.origin has particular tokens, give them a discount

        uint256 index = 0;

        // Loop through discountNFTs until an empty record found
        while(discountNFTs[index].tokenAddress != ZERO_ADDRESS) {
            // Once a discount NFT is found that tx.origin owns, return 
            if (discountNFTs[index].tokenType == TokenType.ERC1155) {
                if (IERC1155(discountNFTs[index].tokenAddress).balanceOf(origin, discountNFTs[index].tokenId) > 0) return priceToRemixWithPass;
            } else {
                // For 721s, we wouldn't require a specific tokenID be owned as that doesn't scale
                if (IERC721(discountNFTs[index].tokenAddress).balanceOf(origin) > 0) return priceToRemixWithPass;
            }

            index = index + 1;
        }

        return priceToRemix;
    }

    /***********************************|
    |        Admin                      |
    |__________________________________*/


    /**
     * @notice Specify the section and stem names for cell matrix
     * @param sectionCountParam uint256
     * @param layerCountParam uint256
     */
    function setLayout(uint256 sectionCountParam, uint256 layerCountParam) public onlyOwner {
        require(dropStage == DropStage.SETUP, "Layout not editable");
        require(availableCellClipIDs.length == sectionCountParam  * layerCountParam, "Invalid input size");

        sectionCount = sectionCountParam;
        layerCount = layerCountParam;
    }


    /**
     * @notice Set the player URI, effectively "reveals" the token metadata
     * @param playerUriParam uint256
     */
    function setPlayerUri(string memory playerUriParam) public onlyOwner {
        playerUri = playerUriParam;
    }

    /**
     * @notice Specify the number of available bpms
     * @param bpmCount uint256
     */
    function setupBpmCount(uint256 bpmCount) public onlyOwner {
        require(dropStage == DropStage.SETUP, "availableCellClipIDs not editabled");

        require(bpmCount > 0, "Invalid input length");

        availableBpmCount = bpmCount;
    }

    /**
     * @notice Specify the available clip IDs for all cells
     * @param cellIDs uint256[]
     * @param cellClipIDs uint256[][]
     */
    function setupCells(uint256[] memory cellIDs, uint256[][] memory cellClipIDs) public onlyOwner {
        require(dropStage == DropStage.SETUP, "availableCellClipIDs not editabled");

        require(cellIDs.length == cellClipIDs.length, "Input length mismatch");
        require(cellIDs.length > 0, "Invalid input length");
        require(cellClipIDs.length > 0, "Invalid input length");

        // Require that cellIDs is increasing from existing availableCellClipIDs in storage
        for (uint256 i = 0; i < cellClipIDs.length; i++) {
            require(cellIDs[i] == availableCellClipIDs.length, "Invalid cellID input");
            availableCellClipIDs.push(new uint256[](cellClipIDs[i].length));

            for (uint256 j = 0; j < cellClipIDs[i].length; j++) {
                availableCellClipIDs[cellIDs[i]][j] = cellClipIDs[i][j];
            }
        }
    }

    /**
     * @notice Owner restricted, updates what stage drop is in
     */
    function setStage(DropStage stage) external onlyOwner {
        dropStage = stage;
    }

    /**
     * @notice Owner restricted, withdraw contract's balance of WETH to msg.sender
     */
    function withdraw() external onlyOwner {
        uint256 balance = IERC20(paymentTokenAddress).balanceOf(address(this));
        _sendWETHPayment(address(this), msg.sender, balance);
    }


    /**
     * @notice Owner restricted, creation of reserved tokens 1-10, the artist-curated Masters
     * @param tokenId uint256
     * @param bpmIndex uint8
     * @param clipIDs uint256[] Array of clip NFT tokenIds for each cell in the mix matrix
     */
    function mintMaster(uint256 tokenId, uint8 bpmIndex, uint256[] memory clipIDs) external onlyOwner {
        require(tokenId <= RESERVED_MASTERS && tokenId > 0, "Invalid master tokenId");
        require(dropStage == DropStage.SALE_COMPLETE, "Invalid drop stage");

        // Will revert if token ID not available
        _mint(msg.sender, tokenId);

        // Note: Masters should each use at least one clipID that is not available for random Mixes, otherwise there is a small chance that a remix will "find" a master combination

        // Set token data
        _setTokenData(tokenId, TokenData(msg.sender, bpmIndex, 0, clipIDs));
    }


    /**
     * @notice Owner restricted, allow for editing the 1-10 tokens in case of mistakes made during creation, lockable via setEditMastersLock()
     * @param tokenId uint256
     * @param bpmIndex uint8
     * @param clipIDs uint256[] Array of clip NFT tokenIds for each cell in the mix matrix
     */
    function editMaster(uint256 tokenId, uint8 bpmIndex, uint256[] memory clipIDs) external onlyOwner {
        require(_isEditingMastersLocked == false, "Edits to masters not allowed");
        require(tokenId <= RESERVED_MASTERS && tokenId > 0, "Invalid master tokenId");

        _clearTokenData(tokenId);
        _setTokenData(tokenId, TokenData(msg.sender, bpmIndex, 0, clipIDs));
    }

    /**
     * @notice Owner restricted, warning: permanent, locks the editing of all master tokens
     */
    function setEditMastersLock() external onlyOwner {
        _isEditingMastersLocked = true;
    }

    /**
     * @notice Owner restricted, warning: permanent, locks the editing of remix prices
     */
    function setEditRemixPriceLock() external onlyOwner {
        _isEditingPricesLocked = true;
    }

    /**
     * @notice Owner restricted, warning: permanent, locks the editing of remix prices
     */
    function setEditRoyaltyBpsLock() external onlyOwner {
        _isEditingRoyaltyBpsLocked = true;
    }

    /**
     * @notice Owner restricted, warning: permanent, locks the editing of remix prices
     */
    function setRoyaltyBps(uint256 royaltyBpsParam) external onlyOwner {
        require(_isEditingRoyaltyBpsLocked == false, "Edits to royalty not allowed");
        require(royaltyBpsParam <= 10000, "Invalid input");
        royaltyBps = royaltyBpsParam;
    }

    /**
     * @notice Owner restricted, allows the setting of remix prices
     * @param remixPrice uint256
     * @param remixOneBurnPrice uint256
     * @param remixTwoBurnPrice uint256
     * @param remixWithPassPrice uint256
     */
    function setPrices(uint256 remixPrice, uint256 remixOneBurnPrice, uint256 remixTwoBurnPrice, uint256 remixWithPassPrice) external onlyOwner {
        require(_isEditingPricesLocked == false, "Edits to remix price not allowed");
        priceToRemix = remixPrice;
        priceToRemixOneBurn = remixOneBurnPrice;
        priceToRemixTwoBurns = remixTwoBurnPrice;
        priceToRemixWithPass = remixWithPassPrice;
    }

    // For testing we might need this, otherwise it will probably not be used
    /**
     * @notice Owner restricted, allows the resetting of redemption NFT address & tokenId
     * @param redemptionTokenAddressParam address
     * @param redemptionTokenIDParam uint256
     */
    function setRedemptionTokens(address redemptionTokenAddressParam, uint256 redemptionTokenIDParam) external onlyOwner {
        redemptionTokenAddress = redemptionTokenAddressParam;
        redemptionTokenID = redemptionTokenIDParam;
    }

    /**
     * @notice Owner restricted, allows the setting of discount NFTs that allow for a reduced remix price without burning
     * @param tokenAddresses address[]
     * @param tokenIds uint256[]
     * @param tokenTypes TokenType[]
     */
    function setDiscountNFTs(address[] memory tokenAddresses, uint256[] memory tokenIds, TokenType[] memory tokenTypes) external onlyOwner {
        require(tokenAddresses.length == tokenIds.length, "Invalid input length");
        require(tokenTypes.length == tokenIds.length, "Invalid input length");

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            discountNFTs[i] = DiscountNFT(tokenAddresses[i], tokenIds[i], tokenTypes[i]);
        }
        
        // Set the end of the length this way
        discountNFTs[tokenAddresses.length] = DiscountNFT(ZERO_ADDRESS, 0, TokenType.ERC721);
    }

    /**
     * @notice Owner restricted, allows the setting of the metadata address where logic for forming the tokenURIs will live
     * @param metadataAddress address
     */
    function setMetadataAddress(address metadataAddress) external onlyOwner {
        futuraMetadata = FuturaMetadata(metadataAddress);
    }

    /**
     * @notice Owner restricted, sets the clip NFT address & approves it for transferring part of the payment as royalties on behalf of this contract
     * @param clipAddress address
     */
    function setClipNFTAddress(address clipAddress) external onlyOwner {
        _setClipNFT(clipAddress);
    }

    // Note: Is this valuable in case we need to update to a new WETH version?
    /**
     * @notice Owner restricted, sets the payment token address, in case WETH needs to change for any reason
     * @param paymentTokenAddressParam address
     */
    function setPaymentTokenAddress(address paymentTokenAddressParam) external onlyOwner {
        paymentTokenAddress = paymentTokenAddressParam;
    }


    /***********************************|
    |        Internal                   |
    |__________________________________*/

    /**
     * @notice Returns a hash of an array of clipIDs
     * @param clipIDs uint256[]
     * @return hash bytes32
     */
    function _hashClipIDs(uint256[] memory clipIDs) internal returns (bytes32 hash) {
        hash = keccak256(abi.encodePacked(clipIDs));
    }

    /**
     * @notice Sets the tokenData for a token ID. Validates input lengths, uniquness of cellClips
     * @param tokenId uint256
     * @param data TokenData
     */
    function _setTokenData(uint256 tokenId, TokenData memory data) internal {
        require(data.clipIDs.length == availableCellClipIDs.length, "Invalid number of clips set");
        require(data.bpmIndex < availableBpmCount, "Invalid bpm");
        require(clipHashToToken[_hashClipIDs(data.clipIDs)] == 0, "Clip IDs already taken");

        tokenData[tokenId] = data;

        clipHashToToken[_hashClipIDs(data.clipIDs)] = tokenId;
    }

    /**
     * @notice Clears the tokenData for a token ID, reverts if not set. Does not _burn(), which must be called separately
     * @param tokenId uint256
     */
    function _clearTokenData(uint256 tokenId) internal {
        require(tokenData[tokenId].clipIDs.length > 0, "Cannot clear TokenData; not set");
        clipHashToToken[_hashClipIDs(tokenData[tokenId].clipIDs)] = 0;
        tokenData[tokenId] = TokenData(ZERO_ADDRESS, 0, 0, new uint256[](0));
    }

    /**
     * @notice Return an array of clipIDs and a bpmIndex generated from a random seed
     * @param seed uint256
     */
    function _generateMix(uint256 seed) internal returns (uint8 bpmIndex, uint256[] memory clipIDs) {
        clipIDs = new uint256[](availableCellClipIDs.length);

        for (uint256 i = 0; i < availableCellClipIDs.length; i++) {
            clipIDs[i] = availableCellClipIDs[i][seed % availableCellClipIDs[i].length];

            // Refresh the seed on each iteration
            seed = uint256(keccak256(abi.encodePacked(seed)));
        }

        bpmIndex = uint8(seed % availableBpmCount);
    }

    /**
     * @notice Generate remix TokenData and validate it against the two inputted tracks
     * @param tokenIdLeft uint256
     * @param tokenIdRight uint256
     * @param bpmIndex uint8
     * @param clipIDs uint256[]
     * @return remixData TokenData memory
     */
    function _checkRemixAndGetData(uint256 tokenIdLeft, uint256 tokenIdRight, uint8 bpmIndex, uint256[] memory clipIDs) internal returns (TokenData memory remixData) {
        require(tokenIdLeft != tokenIdRight, "Cannot remix two of the same tokens");
        require(clipIDs.length > 0, "Zero length input");
        require(dropStage == DropStage.REMIXING_ENABLED, "Remixing not enabled");
        require(clipIDs.length == availableCellClipIDs.length, "Invalid input length");
        require(bpmIndex < availableBpmCount, "Invalid input");  // Is this excessive?
        require(_isApprovedOrOwner(msg.sender, tokenIdLeft) && _isApprovedOrOwner(msg.sender, tokenIdRight), "Not authorized");

        TokenData memory leftData = tokenData[tokenIdLeft];
        TokenData memory rightData = tokenData[tokenIdRight];

        uint256 greatestGeneration = leftData.generation;

        if (rightData.generation > greatestGeneration) {
            greatestGeneration = rightData.generation;
        }

        remixData = TokenData(msg.sender, bpmIndex, greatestGeneration + 1, clipIDs);
        _validateRemix(leftData, rightData, remixData);
    }

    /**
     * @notice Raises exception if remixed tokenData is invalid given two inputs
     * @param left TokenData memory
     * @param right TokenData memory
     * @param remix TokenData memory
     */
    function _validateRemix(TokenData memory left, TokenData memory right, TokenData memory remix) internal {
        require(left.clipIDs.length == right.clipIDs.length, "Invalid input length");
        require(remix.clipIDs.length == right.clipIDs.length, "Invalid input length");
        for (uint256 i = 0; i < left.clipIDs.length; i++) {
            require(left.clipIDs[i] == remix.clipIDs[i] || right.clipIDs[i] == remix.clipIDs[i], "Invalid remix");
        }

        require(left.bpmIndex == remix.bpmIndex || right.bpmIndex == remix.bpmIndex, "Invalid bpmIndex");
    }

    /**
     * @notice Sets the Clip NFT Token address
     * @param clipAddress address
     */
    function _setClipNFT(address clipAddress) internal {
        clipNFTAddress = clipAddress;
        // approve the clip address to pull eth from this contract from the payment token
        IERC20(paymentTokenAddress).approve(clipNFTAddress, type(uint256).max);
    }

    /**
     * @notice Helper for sending WETH
     * @param from address
     * @param to address
     * @param amount amount
     */
    function _sendWETHPayment(address from, address to, uint256 amount) internal {
        if (amount > 0) {
            if (from == address(this)) {
                IERC20(paymentTokenAddress).safeTransfer(to, amount);
            } else {
                IERC20(paymentTokenAddress).safeTransferFrom(from, to, amount);
            }
        }
    }

    /***********************************|
    |        GETTERS                    |
    |__________________________________*/

    /**
     * @notice Returns tokenData for a given tokenId
     * @param tokenId uint256
     * @return TokenData memory
     */
    function getTokenData(uint256 tokenId) external view returns (TokenData memory) {
        return tokenData[tokenId];
    }

    /**
     * @notice Returns number of cells
     * @return uint256
     */
    function availableCellCount() external view returns (uint256) {
        return availableCellClipIDs.length;
    }

    /**
     * @notice Returns array of available cells
     * @param cellIndex uint256
     * @return uint256[] memory
     */
    function getAvailableCellClipIDs(uint256 cellIndex) external view returns (uint256[] memory) {
        return availableCellClipIDs[cellIndex];
    }

    /**
     * @notice Returns royaltyInfo of a tokenID & salePrice per EIP 2981
     * @param tokenId uint256
     * @param salePrice uint256
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        (receiver, royaltyAmount) = futuraMetadata.royaltyInfo(tokenId, salePrice);
    }

    /**
     * @notice Override supportsInterface to account for EIP 2981
     * @return bool
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || interfaceId == _INTERFACE_ID_ERC2981;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

pragma solidity 0.8.9;

import "base64-sol/base64.sol";
import "./interfaces/IMetadataContract.sol";

contract JSONBuilder is IMetadataContract {
    enum Type {
        ARRAY,
        OBJECT,
        STRING,
        NUMBER,
        BOOLEAN
    }

    struct Item {
        Type itemType;
        bytes value;
    }

    struct NamedItem {
        Type itemType;
        bytes value;
        string name;
    }

    function decodeItem(Item memory item) public view returns (string memory) {
        string memory stringResult;
        if (item.itemType == Type.STRING) {
            // (stringResult) = abi.decode(item.value, (string));
            (stringResult) = string(item.value);
            return string(abi.encodePacked('"', stringResult, '"'));
        } else if (item.itemType == Type.NUMBER) {
            uint256 numberResult;
            (numberResult) = abi.decode(item.value, (uint256));
            stringResult = uint2str(numberResult);
            return stringResult;
        } else if (item.itemType == Type.BOOLEAN) {
            bool boolResult = abi.decode(item.value, (bool));
            if (boolResult == true) {
                stringResult = "true";
            } else {
                stringResult = "false"; 
            }
            return stringResult;
        } else if (item.itemType == Type.ARRAY) {
            Item[] memory data;
            (data) = abi.decode(item.value, (Item[]));

            stringResult = "[";
            for (uint256 i =0; i < data.length; i++) {
                if (i + 1 == data.length) {
                    stringResult = string(abi.encodePacked(stringResult, decodeItem(data[i])));
                } else {
                    stringResult = string(abi.encodePacked(stringResult, decodeItem(data[i]), ","));
                }
            }
            stringResult = string(abi.encodePacked(stringResult, "]"));

            return stringResult;
        } else if (item.itemType == Type.OBJECT) {
            NamedItem[] memory data;
            (data) = abi.decode(item.value, (NamedItem[]));

            stringResult = "{";
            Item memory item;

            // For now assume keys won't repeat
            for (uint256 i = 0; i < data.length; i++) {
                item = Item(data[i].itemType, data[i].value);
                if (i + 1 == data.length) {
                    stringResult = string(abi.encodePacked(stringResult, '"', data[i].name, '":', decodeItem(item)));
                } else {
                    stringResult = string(abi.encodePacked(stringResult, '"', data[i].name, '":', decodeItem(item), ","));
                }
            }
            stringResult = string(abi.encodePacked(stringResult, "}"));
            return stringResult;
        }
    }

    function encodeJSONDataURI(string memory json) public pure returns (string memory dataURI) {
        dataURI = string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    function getTokenJSON(uint256 tokenId) public view virtual returns (string memory) {}

	function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        return encodeJSONDataURI(getTokenJSON(tokenId));
	}

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

interface IClipNFT {
    struct TokenData {
        string name;
        uint256 colorPaletteIndex;
        uint256 shapeIndex;
        bool distortion;
        bool subtraction;
        uint256[] enabledEffectIndices;
    }

    function availableEffects(uint256) external view returns (string memory);
    function availableColorPalettes(uint256) external view returns (string memory);
    function availableShapes(uint256) external view returns (string memory);
    function getBpm(uint256) external view returns (uint256);
    function getName(uint256) external view returns (string memory);
    function getColorPalette(uint256[] memory) external view returns (string memory);
    function getColorPaletteIndex(uint256[] memory) external view returns (uint256);
    function getNoteShape(uint256[] memory) external view returns (string memory);
    function getNoteShapeIndex(uint256[] memory) external view returns (uint256);
    function getEffects(uint256[] memory) external view returns (bool[] memory);
    function getSubtraction(uint256[] memory) external view returns (bool);
    function getDistortion(uint256[] memory) external view returns (bool);
    function getSectionName(uint256) external view returns (string memory);
    function getLayerName(uint256) external view returns (string memory);
    function addRoyalty(uint256, uint256[] memory) external;
    function getTokenData(uint256) external view returns (TokenData memory);
}

interface IFutura {
    struct TokenData {
        address mixer;
        uint8 bpmIndex;
        uint256 generation;
        uint256[] clipIDs;
    }

    function availableBpmCount() external view returns (uint256);
    function availableCellCount() external view returns (uint256);
    function sectionCount() external view returns (uint256);
    function layerCount() external view returns (uint256);

    function clipNFTAddress() external view returns (address);

    function playerUri() external view returns (string memory);
    

    function getTokenData(uint256) external view returns (TokenData memory);
}

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import "base64-sol/base64.sol";

import "./interfaces/IFutura.sol";
import "./interfaces/IClipNFT.sol";
import "./JSONBuilder.sol";
import "./Clip721.sol";
import "./FuturaSVG.sol";


// Read only methods that access public data from the parent Futura contract and generate a tokenURI
contract FuturaMetadata is JSONBuilder, Ownable {
    IFutura public futura;
    FuturaSVG public futuraSVG;

    // Royalty bps / 10,000, per EIP 2981
    uint256 public royaltyBps = 0;

    constructor(address futuraAddressParam) {
        futura = IFutura(futuraAddressParam);
        // Deploy SVG generation code here
        futuraSVG = new FuturaSVG();
    }

    /** 
     * @notice Owner restricted, update the SVG generation contract address
     * @param futuraSVGAddress address
     */
    function setSVGAddress(address futuraSVGAddress) public onlyOwner {
        futuraSVG = FuturaSVG(futuraSVGAddress);
    }

    /** 
     * @notice Owner restricted, update the royalty bps
     * @param royaltyBpsParam uint256
     */
    function setRoyaltyBps(uint256 royaltyBpsParam) public onlyOwner {
        require(royaltyBpsParam <= 10000, "Invalid royalty bps");
        royaltyBps = royaltyBpsParam;
    }

    /** 
     * @notice Return full playerURI for a particular token
     * @param playerUri string memory
     * @param tokenData IFutura.TokenData memory
     * @return string memory
     */
    function getPlayerURI(string memory playerUri, IFutura.TokenData memory tokenData) public view returns (string memory) {
        bool distortion = getDistortion(tokenData);
        string memory distortionStr = "false";

        if (distortion == true)
            distortionStr = "true";

        return string(
            abi.encodePacked(
                playerUri,
                "?mix=", getMixStr(tokenData),
                "&tempo=", uint2str(getBpm(tokenData.bpmIndex)),
                "&palette=", uint2str(getColorPaletteIndex(tokenData)),
                "&distortion=", distortionStr,
                "&twists=", uint2str(getTwists(tokenData)),
                "&noteShape=", getNoteShape(tokenData)
            )
        );
    }

    /** 
     * @notice Return comma separated string of clip identifiers
     * @param tokenData IFutura.TokenData memory
     * @return mixStr string memory
     */
    function getMixStr(IFutura.TokenData memory tokenData) public view returns (string memory mixStr) {
        for (uint256 i = 0; i < tokenData.clipIDs.length; i++) {
            if (i == 0) {
                mixStr = uint2str(tokenData.clipIDs[i]);
            } else {
                mixStr = string(abi.encodePacked(mixStr, ',', uint2str(tokenData.clipIDs[i])));
            }
        }
    }

    /** 
     * @notice Return JSON string of tokenURI for unrevealed token
     * @param tokenId uint256
     * @return result string memory
     */
    function getTokenJSONUnrevealed(uint256 tokenId) public view returns (string memory result) {
        IFutura.TokenData memory tokenData = futura.getTokenData(tokenId);
        require(tokenData.clipIDs.length != 0, "Non existent token");

        Item[] memory attributes = new Item[](0);

        NamedItem[] memory toplevelJson = new NamedItem[](3);
        toplevelJson[0] = NamedItem(Type.ARRAY, abi.encode(attributes), "attributes");
        toplevelJson[1] = NamedItem(Type.STRING, bytes(getTokenName(tokenId, tokenData)), "name");
        toplevelJson[2] = NamedItem(Type.STRING, bytes(getSVGRawUnrevealed(tokenData)), "image");
        Item memory json = Item(Type.OBJECT, abi.encode(toplevelJson));
        result = decodeItem(json);
    }

    /** 
     * @notice Return token name given its tokenData
     * @param tokenData IFutura.TokenData memory
     * @return name string memory
     */
    function getTokenName(uint256 tokenId, IFutura.TokenData memory tokenData) public pure returns (string memory name) {
        string memory tokenType = "Master";
        if (tokenData.generation == 1) {
            tokenType = "Mix";
        } else if (tokenData.generation > 1) {
            tokenType = "Remix";
        }
        name = string(abi.encodePacked(tokenType, " #", uint2str(tokenId)));
    }

    /** 
     * @notice Return JSON string of tokenURI for revealed token
     * @param tokenId uint256
     * @return result string memory
     */
    function getTokenJSON(uint256 tokenId) public view virtual override returns (string memory result) {
        IFutura.TokenData memory tokenData = futura.getTokenData(tokenId);
        require(tokenData.clipIDs.length != 0, "Non existent token");


        string memory playerUri = futura.playerUri();
        if (bytes(playerUri).length == 0) return getTokenJSONUnrevealed(tokenId);

        uint256[] memory clipIDs = tokenData.clipIDs;
        bool[] memory effectFlags = getEffects(tokenData);

        Item[] memory attributes = new Item[](clipIDs.length + effectFlags.length + 7);

        NamedItem[] memory attribute = new NamedItem[](2);

        // Add attribute for each cell => clip, using "None" if id = 0
        for (uint256 i = 0; i < clipIDs.length; i++) {
            string memory attributeName = string(abi.encodePacked(getSectionName(i), " ", getLayerName(i)));
            attribute[0] = NamedItem(Type.STRING, bytes(attributeName), "trait_type");
            string memory attributeValue = IClipNFT(futura.clipNFTAddress()).getName(clipIDs[i]);
            attribute[1] = NamedItem(Type.STRING, bytes(attributeValue), "value");

            attributes[i] = Item(Type.OBJECT, abi.encode(attribute));
        }

        // Add attribute for each effect, true if enabled for any cell else false
        for (uint256 i = 0; i < effectFlags.length; i++) {
            // Effect name; eg "Lightning"
            string memory attributeName = IClipNFT(futura.clipNFTAddress()).availableEffects(i);
            attribute[0] = NamedItem(Type.STRING, bytes(attributeName), "trait_type");

            // Effect value, boolean
            attribute[1] = NamedItem(Type.STRING, bytes(getBoolStr(effectFlags[i])), "value");
            attributes[clipIDs.length + i] = Item(Type.OBJECT, abi.encode(attribute));
        }


        // Extra 1: BPM
        attribute[0] = NamedItem(Type.STRING, bytes("Bpm"), "trait_type");
        attribute[1] = NamedItem(Type.STRING, bytes(uint2str(getBpm(tokenData.bpmIndex))), "value");
        attributes[clipIDs.length + effectFlags.length] = Item(Type.OBJECT, abi.encode(attribute));

        // Extra 2: Generation
        attribute[0] = NamedItem(Type.STRING, bytes("Generation"), "trait_type");
        attribute[1] = NamedItem(Type.STRING, bytes(uint2str(tokenData.generation)), "value");
        attributes[clipIDs.length + effectFlags.length + 1] = Item(Type.OBJECT, abi.encode(attribute));

        // Extra 3: Color Palette
        attribute[0] = NamedItem(Type.STRING, bytes("Color Palette"), "trait_type");
        attribute[1] = NamedItem(Type.STRING, bytes(getColorPalette(tokenData)), "value");
        attributes[clipIDs.length + effectFlags.length + 2] = Item(Type.OBJECT, abi.encode(attribute));

        // Extra 4: Note shape
        attribute[0] = NamedItem(Type.STRING, bytes("Note Shape"), "trait_type");
        attribute[1] = NamedItem(Type.STRING, bytes(getNoteShape(tokenData)), "value");
        attributes[clipIDs.length + effectFlags.length + 3] = Item(Type.OBJECT, abi.encode(attribute));

        // Extra 5: Twists
        attribute[0] = NamedItem(Type.STRING, bytes("Twists"), "trait_type");
        attribute[1] = NamedItem(Type.STRING, bytes(uint2str(getTwists(tokenData))), "value");
        attributes[clipIDs.length + effectFlags.length + 4] = Item(Type.OBJECT, abi.encode(attribute));

        // Extra 6: Distortion
        attribute[0] = NamedItem(Type.STRING, bytes("Distortion"), "trait_type");
        attribute[1] = NamedItem(Type.STRING, bytes(getBoolStr(getDistortion(tokenData))), "value");
        attributes[clipIDs.length + effectFlags.length + 5] = Item(Type.OBJECT, abi.encode(attribute));

        //// Extra 7: Mobius
        bool isMobius = getTwists(tokenData) % 2 == 1;
        attribute[0] = NamedItem(Type.STRING, bytes("\u004D\u00F6\u0062\u0069\u0075\u0073"), "trait_type");
        attribute[1] = NamedItem(Type.STRING, bytes(getBoolStr(isMobius)), "value");
        attributes[clipIDs.length + effectFlags.length + 6] = Item(Type.OBJECT, abi.encode(attribute));

        NamedItem[] memory toplevelJson = new NamedItem[](4);
        toplevelJson[0] = NamedItem(Type.ARRAY, abi.encode(attributes), "attributes");
        toplevelJson[1] = NamedItem(Type.STRING, bytes(getTokenName(tokenId, tokenData)), "name");
        toplevelJson[2] = NamedItem(Type.STRING, bytes(getSVGRaw(tokenData)), "image");
        toplevelJson[3] = NamedItem(Type.STRING, bytes(getPlayerURI(playerUri, tokenData)), "animation_url");
        Item memory json = Item(Type.OBJECT, abi.encode(toplevelJson));
        result = decodeItem(json);
    }

    /** 
     * @notice Return string value for a bool input
     * @param input bool
     * @return string memory
     */
    function getBoolStr(bool input) public view returns (string memory) {
        if (input == true) return 'true';
        return 'false';
    }

    /** 
     * @notice Return SVG for an unrevealed tokenId
     * @param tokenData IFutura.TokenData memory
     * @return string memory
     */
    function getSVGRawUnrevealed(IFutura.TokenData memory tokenData) public view returns (string memory) {
        return string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(futuraSVG.unrevealedSVG()))));
    }

    /** 
     * @notice Return SVG for a revealed token
     * @param tokenData IFutura.TokenData memory
     * @return string memory
     */
    function getSVGRaw(IFutura.TokenData memory tokenData) public view returns (string memory) {
        return string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(futuraSVG.buildSVG(
            getColorPaletteIndex(tokenData),
            getNoteShapeIndex(tokenData),
            tokenData.generation,
            getTwists(tokenData),
            getDistortion(tokenData),
            getEffects(tokenData)
        )))));
    }

    /** 
     * @notice Return colorPalette string for tokenData
     * @param tokenData IFutura.TokenData memory
     * @return string memory
     */
    function getColorPalette(IFutura.TokenData memory tokenData) public view returns (string memory) {
        return IClipNFT(futura.clipNFTAddress()).getColorPalette(tokenData.clipIDs);
    }

    /** 
     * @notice Return colorPalette index for tokenData
     * @param tokenData IFutura.TokenData memory
     * @return uint256
     */
    function getColorPaletteIndex(IFutura.TokenData memory tokenData) public view returns (uint256) {
        return IClipNFT(futura.clipNFTAddress()).getColorPaletteIndex(tokenData.clipIDs);
    }

    /** 
     * @notice Return bpm value for a given bpmIndex
     * @param bpmIndex uint256
     * @return uint256
     */
    function getBpm(uint256 bpmIndex) public view returns (uint256) {
        return IClipNFT(futura.clipNFTAddress()).getBpm(bpmIndex);
    }

    /** 
     * @notice Return note shape string for tokenData
     * @param tokenData IFutura.TokenData memory
     * @return string memory
     */
    function getNoteShape(IFutura.TokenData memory tokenData) public view returns (string memory) {
        return IClipNFT(futura.clipNFTAddress()).getNoteShape(tokenData.clipIDs);
    }

    /** 
     * @notice Return note shape index for tokenData
     * @param tokenData IFutura.TokenData memory
     * @return uint256
     */
    function getNoteShapeIndex(IFutura.TokenData memory tokenData) public view returns (uint256) {
        return IClipNFT(futura.clipNFTAddress()).getNoteShapeIndex(tokenData.clipIDs);
    }

    /** 
     * @notice Return effect bool array given tokenData
     * @param tokenData IFutura.TokenData memory
     * @return bool[] memory
     */
    function getEffects(IFutura.TokenData memory tokenData) public view returns (bool[] memory) {
        return IClipNFT(futura.clipNFTAddress()).getEffects(tokenData.clipIDs);
    }

    /** 
     * @notice Return number of twists given tokenData
     * @param tokenData IFutura.TokenData memory
     * @return twists uint256
     */
    function getTwists(IFutura.TokenData memory tokenData) public view returns (uint256 twists) {
        uint256 generation = tokenData.generation;

        if (generation == 0) {
            twists = 1;
        } else if (generation == 1) {
            twists = 3;
        } else {
            twists = 5;
        }

        bool subtract = IClipNFT(futura.clipNFTAddress()).getSubtraction(tokenData.clipIDs);
        if (subtract == true) twists = twists - 1;
    }

    /** 
     * @notice Return whether a tokenData has distorted enabled
     * @param tokenData IFutura.TokenData memory
     * @return bool
     */
    function getDistortion(IFutura.TokenData memory tokenData) public view returns (bool) {
        return IClipNFT(futura.clipNFTAddress()).getDistortion(tokenData.clipIDs);
    }

    /** 
     * @notice Return the section name for a particular cell index
     * @param cellIndex uint256
     * @return string memory
     */
    function getSectionName(uint256 cellIndex) public view returns (string memory) {
        return IClipNFT(futura.clipNFTAddress()).getSectionName(cellIndex);
    }

    /** 
     * @notice Return the layer name for a particular cell index
     * @param cellIndex uint256
     * @return string memory
     */
    function getLayerName(uint256 cellIndex) public view returns (string memory) {
        return IClipNFT(futura.clipNFTAddress()).getLayerName(cellIndex);
    }

    /** 
     * @notice Return the royaltyInfo per EIP2981
     * @param tokenId uint256
     * @param salePrice uint256
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        IFutura.TokenData memory tokenData = futura.getTokenData(tokenId);
        receiver = tokenData.mixer;
        royaltyAmount = royaltyBps * salePrice / 10000;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

interface IMetadataContract {
    function tokenURI(uint256) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./TokenRoyalties.sol";
import "./JSONBuilder.sol";
import "./interfaces/IMetadataContract.sol";
import "./interfaces/IFutura.sol";
import "./interfaces/IClipNFT.sol";

contract Clip721 is IClipNFT, ERC721, TokenRoyalties {
    mapping(uint256 => string) sampleName; // TODO: Make this settable? If so, require unique?

    string[] public availableColorPalettes;
    string[] public availableEffects;
    string[] public availableShapes;
    uint256[] public availableBpms;
    string[] public layerNames;
    string[] public sectionNames;

    mapping (uint256 => TokenData) public tokenData;

    address public futuraAddress;

    IMetadataContract public metadataContract;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}


    /***********************************|
    |        Admin                      |
    |__________________________________*/

    /**
     * @notice Setup the contract with payment token, metadata contract address, color palettes, efects, and shapes. If string names need to change, requires new contract deployed
     * @param paymentTokenAddressParam address
     * @param metadataAddress address
     * @param colorPalettes string[] memory
     * @param effects string[] memory
     * @param shapeNames string[] memory
     */
    function setup(address paymentTokenAddressParam, address metadataAddress, string[] memory colorPalettes, string[] memory effects, string[] memory shapeNames, uint256[] memory availableBpmParam, string[] memory sectionNamesParam, string[] memory layerNamesParam) public onlyOwner {
        setPaymentTokenAddress(paymentTokenAddressParam);
        setMetadataContract(metadataAddress);
        _setTraitsData(colorPalettes, effects, shapeNames, availableBpmParam, sectionNamesParam, layerNamesParam);
    }

    /**
     * @notice Allow owner to set or update futura address, restricts royalty payout to originate from that address
     * @param futuraAddressParam address
     */
    function setFuturaAddress(address futuraAddressParam) public onlyOwner {
        require(availableColorPalettes.length > 0, "Clips not setup yet");
        futuraAddress = futuraAddressParam;

        // Validation that futura and clip contract have matching configurations
        require(IFutura(futuraAddress).availableBpmCount() == availableBpms.length, "Invalid bpm count");
        require(IFutura(futuraAddress).sectionCount() == sectionNames.length, "Invalid layout");
        require(IFutura(futuraAddress).layerCount() == layerNames.length, "Invalid layout");
        require(IFutura(futuraAddress).availableCellCount() == sectionNames.length * layerNames.length, "Invalid layout");
    }

    /**
     * @notice Allow owner to update payment token address in case a change ever needed
     * @param paymentTokenAddressParam address
     */
    function setPaymentTokenAddress(address paymentTokenAddressParam) public onlyOwner {
        _setPaymentTokenAddress(paymentTokenAddressParam);
	}

    /**
     * @notice Allow owner to update clip metadata contract address in case a change ever needed
     * @param metadataAddress address
     */
    function setMetadataContract(address metadataAddress) public onlyOwner {
        metadataContract = IMetadataContract(metadataAddress);
    }


    /**
     * @notice Owner creates clip tokens and associates token data with them
     * @param tokenId uint256
     * @param name string memory
     * @param colorPaletteIndex uint256
     * @param shapeIndex uint256
     * @param distortion bool
     * @param subtraction bool
     * @param enabledEffectsParam uint256[] memory
     */
    function mintClip(uint256 tokenId, string memory name, uint256 colorPaletteIndex, uint256 shapeIndex, bool distortion, bool subtraction, uint256[] memory enabledEffectsParam) public onlyOwner {
        require(enabledEffectsParam.length <= 1, "Invalid input length");
        require(tokenId > 0, "Invalid tokenId"); // TokenID 0 reserved for null value
        require(colorPaletteIndex < availableColorPalettes.length, "Invalid colorPaletteIndex input");
        require(shapeIndex < availableColorPalettes.length, "Invalid shapeIndex input");
        uint256[] memory enabledEffects = new uint256[](enabledEffectsParam.length);

        for (uint256 i = 0; i < enabledEffectsParam.length; i++) {
            require(enabledEffectsParam[i] < availableEffects.length, "Invalid effectIndex input");
            enabledEffects[i] = enabledEffectsParam[i];
        }

        _mint(msg.sender, tokenId);
        tokenData[tokenId] = TokenData(name, colorPaletteIndex, shapeIndex, distortion, subtraction, enabledEffectsParam);
    }

    /**
     * @notice Owner creates many clip tokens and associates token data with them
     * @param tokenIds uint256[]
     * @param names string[] memory
     * @param colorPaletteIndices uint256[]
     * @param shapeIndices uint256[]
     * @param distortions bool[]
     * @param subtractions bool[]
     * @param enabledEffectsParams uint256[][] memory
     */
    function mintManyClips(uint256[] memory tokenIds, string[] memory names, uint256[] memory colorPaletteIndices, uint256[] memory shapeIndices, bool[] memory distortions, bool[] memory subtractions, uint256[][] memory enabledEffectsParams) public onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            mintClip(tokenIds[i], names[i], colorPaletteIndices[i], shapeIndices[i], distortions[i], subtractions[i], enabledEffectsParams[i]);
        }
    }

    /***********************************|
    |        Internal                   |
    |__________________________________*/

    /**
     * @notice Internal method for setting global string names used in metadata generation
     * @param colorPalettes string[] memory
     * @param effects string[] memory
     * @param shapeNames string[] memory
     * @param availableBpmParam uint256[] memory
     */
    function _setTraitsData(string[] memory colorPalettes, string[] memory effects, string[] memory shapeNames, uint256[] memory availableBpmParam, string[] memory sectionNamesParam, string[] memory layerNamesParam) internal {
        require(colorPalettes.length > 0, "Zero length input");
        require(effects.length > 0, "Zero length input");
        require(shapeNames.length > 0, "Zero length input");
        require(availableBpmParam.length > 0, "Zero length input");
        require(sectionNamesParam.length > 0, "Zero length input");
        require(layerNamesParam.length > 0, "Zero length input");

        availableEffects = new string[](effects.length);
        availableColorPalettes = new string[](colorPalettes.length);
        availableShapes = new string[](shapeNames.length);
        availableBpms = new uint256[](availableBpmParam.length);
        sectionNames = new string[](sectionNamesParam.length);
        layerNames = new string[](layerNamesParam.length);

        uint i;

        for (i = 0; i < colorPalettes.length; i++) {
            availableColorPalettes[i] = colorPalettes[i];
        }
        for (i = 0; i < effects.length; i++) {
            availableEffects[i] = effects[i];
        }
        for (i = 0; i < shapeNames.length; i++) {
            availableShapes[i] = shapeNames[i];
        }
        for (i = 0; i < availableBpmParam.length; i++) {
            availableBpms[i] = availableBpmParam[i];
        }
        for (i = 0; i < sectionNamesParam.length; i++) {
            sectionNames[i] = sectionNamesParam[i];
        }
        for (i = 0; i < layerNamesParam.length; i++) {
            layerNames[i] = layerNamesParam[i];
        }
    }


    /***********************************|
    |        External                   |
    |__________________________________*/


    /**
     * @notice Allows tokenId owner to withdraw their share of accumulated royalties in WETH
     * @param tokenId uint256
     */
    function withdraw(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Only owner can withdraw");
        _withdraw(tokenId, msg.sender);
    }

    /**
     * @notice Allows tokenId array owner to withdraw their share of accumulated royalties in WETH
     * @param tokenIDs uint256[]
     */
    function withdrawMany(uint256[] memory tokenIDs) public {
        require(tokenIDs.length > 0, "Zero length input");
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            require(_isApprovedOrOwner(msg.sender, tokenIDs[i]), "Only owner can withdraw");
        }
        _withdrawMany(tokenIDs, msg.sender);
    }

    /**
     * @notice Returns tokenURI for a particular token
     * @param tokenId uint256
     * @return string memory
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return metadataContract.tokenURI(tokenId);
    }

    /**
     * @notice Sends an amount of weth to this, and credits tokenIDs with respective amounts
     * @param amount uint256
     * @param tokenIDs uint256[]
     */
    function addRoyalty(uint256 amount, uint256[] memory tokenIDs) public {
        require(amount > 0, "Amount must not be zero");
        require(msg.sender == futuraAddress, "Invalid caller");
        require(tokenIDs.length > 0, "Zero length input");

		// Note: this does not confirm that tokenIDs are valid
        _accountRoyaltiesBatch(amount, tokenIDs);
    }

    /***********************************|
    |        Getters                    |
    |__________________________________*/


    /**
     * @notice Returns name for a particular token
     * @param tokenId uint256
     * @return string memory
     */
    function getName(uint256 tokenId) external view returns (string memory) {
        if (tokenId > 0) return tokenData[tokenId].name;
        return "None";
    }

    /**
     * @notice Returns tokenData struct for a particular token
     * @param tokenId uint256
     * @return data TokenData memory
     */
    function getTokenData(uint256 tokenId) external view returns (TokenData memory data) {
        data = tokenData[tokenId];
    }

    // METADATA HELPERS

    /**
     * @notice Returns derived colorPalette string given an array of tokenIDs
     * @param tokenIDs uint256[]
     * @return string memory
     */
    function getColorPalette(uint256[] memory tokenIDs) external view returns (string memory) {
        return availableColorPalettes[getColorPaletteIndex(tokenIDs)];
    }

    function getColorPaletteIndex(uint256[] memory tokenIDs) public view returns (uint256) {
        uint256[] memory counters = new uint256[](availableColorPalettes.length);

        uint256 paletteIndex;
        uint256 maxPaletteIndex;

        for (uint256 i = 0; i < tokenIDs.length; i++) {
            if (tokenIDs[i] > 0) {
                paletteIndex = tokenData[tokenIDs[i]].colorPaletteIndex;
                counters[paletteIndex] = counters[paletteIndex] + 1;
                if (paletteIndex != maxPaletteIndex && counters[paletteIndex] > counters[maxPaletteIndex]) {
                    maxPaletteIndex = paletteIndex;
                }
            }
        }
        return maxPaletteIndex;
    }

    /**
     * @notice Returns derived note shape string given an array of tokenIDs
     * @param tokenIDs uint256[]
     * @return string memory
     */
    function getNoteShape(uint256[] memory tokenIDs) external view returns (string memory) {
        return availableShapes[getNoteShapeIndex(tokenIDs)];
    }

    function getNoteShapeIndex(uint256[] memory tokenIDs) public view returns (uint256) {
        uint256[] memory counters = new uint256[](availableShapes.length);

        uint256 shapeIndex;
        uint256 maxShapeIndex;

        for (uint256 i = 0; i < tokenIDs.length; i++) {
            if (tokenIDs[i] > 0) {
                shapeIndex = tokenData[tokenIDs[i]].shapeIndex;
                counters[shapeIndex] = counters[shapeIndex] + 1;
                if (shapeIndex != maxShapeIndex && counters[shapeIndex] > counters[maxShapeIndex]) {
                    maxShapeIndex = shapeIndex;
                }
            }
        }
        return maxShapeIndex;
    }

    /**
     * @notice Returns on/off flags for each effects given an array of tokenIDs
     * @param tokenIDs uint256[]
     * @return resultFlags bool[] memory
     */
    function getEffects(uint256[] memory tokenIDs) external view returns (bool[] memory resultFlags) {
        resultFlags = new bool[](availableEffects.length);
        TokenData memory data;

        for (uint256 i = 0; i < tokenIDs.length; i++) {
            if (tokenIDs[i] > 0) {
                data = tokenData[tokenIDs[i]];
                for (uint256 j = 0; j < data.enabledEffectIndices.length; j++) {
                    resultFlags[data.enabledEffectIndices[j]] = true;
                }
            }
        }
    }

    /**
     * @notice Returns bool flag for if subtraction is on or off given an array of tokenIDs
     * @param tokenIDs uint256[]
     * @return bool
     */
    function getSubtraction(uint256[] memory tokenIDs) external view returns (bool) {
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            if (tokenData[tokenIDs[i]].subtraction == true) return true;
        }
        return false;
    }

    /**
     * @notice Returns bool flag for if distortion is on or off given an array of tokenIDs
     * @param tokenIDs uint256[]
     * @return bool
     */
    function getDistortion(uint256[] memory tokenIDs) external view returns (bool) {
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            if (tokenData[tokenIDs[i]].distortion == true) return true;
        }
        return false;
    }


    /**
     * @notice Returns bpm value for a given bpmIndex
     * @param bpmIndex uint256
     * @return uint256
     */
    function getBpm(uint256 bpmIndex) external view returns (uint256) {
        return availableBpms[bpmIndex];
    }


    /**
     * @notice Returns layer name for a cell index
     * @param cellIndex uint256
     * @return string memory
     */
    function getLayerName(uint256 cellIndex) external view returns (string memory) {
        return layerNames[cellIndex / sectionNames.length];
    }

    /**
     * @notice Returns section name for a cell index
     * @param cellIndex uint256
     * @return string memory
     */
    function getSectionName(uint256 cellIndex) external view returns (string memory) {
        return sectionNames[cellIndex % sectionNames.length];
    }
}

pragma solidity 0.8.9;

interface IExternalStatic {
    function getSVG() external pure returns (string memory);
}


contract UnrevealedSVG1 is IExternalStatic {
	function getSVG() external pure returns (string memory) {
		return '<svg width="500" height="500" viewBox="0 0 500 500" fill="none" xmlns="http://www.w3.org/2000/svg">'
			'<g clip-path="url(#clip0_1004:953)">'
			'<rect width="500" height="500" fill="black"/>'
			'<path d="M580 249.5C580 430.926 432.926 578 251.5 578C70.0745 578 -77 430.926 -77 249.5C-77 68.0745 70.0745 -79 251.5 -79C432.926 -79 580 68.0745 580 249.5Z" fill="#333333"/>'
			'<circle cx="248.5" cy="250.5" r="281.5" fill="#333333" stroke="black" stroke-width="2"/>'
			'<circle cx="247" cy="247" r="234" fill="#333333" stroke="black" stroke-width="2"/>'
			'<circle cx="250" cy="246" r="178" fill="#333333" stroke="black" stroke-width="2"/>';
	}
}

contract UnrevealedSVG2 is IExternalStatic {
	function getSVG() external pure returns (string memory) {
		return '<path d="M250 374C319.036 374 375 318.036 375 249C375 179.964 319.036 124 250 124C180.964 124 125 179.964 125 249C125 318.036 180.964 374 250 374Z" fill="#3A3A3A"/>'
			'<path d="M258.923 373.687C320.853 369.319 370.328 319.838 374.687 257.906L336.685 219.771L334.715 217.934L228.143 240.057L178.791 218.236L161.222 275.985L163.574 278.486L258.923 373.687Z" fill="#6A00F4"/>'
			'<path d="M307.575 207.728C282.827 207.728 261.482 222.487 249.993 232.286C246.912 229.792 242.866 227.174 238.604 224.322C222.147 213.312 206.61 207.728 192.425 207.728C169.667 207.728 151.153 226.243 151.153 249C151.153 271.757 169.667 290.272 192.425 290.272C217.173 290.272 238.504 275.525 249.993 265.726C253.074 268.219 257.134 270.826 261.396 273.678C277.853 284.688 293.389 290.272 307.575 290.272C330.332 290.272 348.847 271.757 348.847 249C348.847 226.243 330.333 207.728 307.575 207.728ZM192.425 265.858C183.129 265.858 175.567 258.295 175.567 249C175.567 239.705 183.129 232.142 192.425 232.142C205.826 232.142 221.178 241.366 231.564 249.279C222.445 256.56 207.79 265.858 192.425 265.858ZM307.575 265.858C294.174 265.858 278.822 256.634 268.436 248.721C277.556 241.44 292.21 232.143 307.575 232.143C316.871 232.143 324.433 239.705 324.433 249C324.433 258.296 316.871 265.858 307.575 265.858Z" fill="#F20089"/>'
			'<path d="M307.575 207.728C283.023 207.728 261.55 222.484 249.993 232.286V265.727C253.075 268.22 257.134 270.827 261.396 273.678C277.853 284.689 293.389 290.272 307.575 290.272C330.332 290.272 348.847 271.758 348.847 249C348.847 226.243 330.332 207.728 307.575 207.728ZM307.575 265.858C294.174 265.858 278.822 256.634 268.436 248.721C277.556 241.44 292.21 232.143 307.575 232.143C316.871 232.143 324.433 239.705 324.433 249C324.433 258.296 316.871 265.858 307.575 265.858Z" fill="#D100D1"/>'
			'<path d="M20.5234 41.3906C20.5547 39.5312 20.7656 38.0625 21.1562 36.9844C21.5469 35.9062 22.3438 34.7109 23.5469 33.3984L26.6172 30.2344C27.9297 28.75 28.5859 27.1562 28.5859 25.4531C28.5859 23.8125 28.1562 22.5312 27.2969 21.6094C26.4375 20.6719 25.1875 20.2031 23.5469 20.2031C21.9531 20.2031 20.6719 20.625 19.7031 21.4688C18.7344 22.3125 18.25 23.4453 18.25 24.8672H13.9141C13.9453 22.3359 14.8438 20.2969 16.6094 18.75C18.3906 17.1875 20.7031 16.4062 23.5469 16.4062C26.5 16.4062 28.7969 17.2031 30.4375 18.7969C32.0938 20.375 32.9219 22.5469 32.9219 25.3125C32.9219 28.0469 31.6562 30.7422 29.125 33.3984L26.5703 35.9297C25.4297 37.1953 24.8594 39.0156 24.8594 41.3906H20.5234ZM20.3359 48.8203C20.3359 48.1172 20.5469 47.5312 20.9688 47.0625C21.4062 46.5781 22.0469 46.3359 22.8906 46.3359C23.7344 46.3359 24.375 46.5781 24.8125 47.0625C25.25 47.5312 25.4688 48.1172 25.4688 48.8203C25.4688 49.5234 25.25 50.1094 24.8125 50.5781C24.375 51.0312 23.7344 51.2578 22.8906 51.2578C22.0469 51.2578 21.4062 51.0312 20.9688 50.5781C20.5469 50.1094 20.3359 49.5234 20.3359 48.8203Z" fill="#F20089"/>'
			'<path d="M20.5234 101.391C20.5547 99.5312 20.7656 98.0625 21.1562 96.9844C21.5469 95.9062 22.3438 94.7109 23.5469 93.3984L26.6172 90.2344C27.9297 88.75 28.5859 87.1562 28.5859 85.4531C28.5859 83.8125 28.1562 82.5312 27.2969 81.6094C26.4375 80.6719 25.1875 80.2031 23.5469 80.2031C21.9531 80.2031 20.6719 80.625 19.7031 81.4688C18.7344 82.3125 18.25 83.4453 18.25 84.8672H13.9141C13.9453 82.3359 14.8438 80.2969 16.6094 78.75C18.3906 77.1875 20.7031 76.4062 23.5469 76.4062C26.5 76.4062 28.7969 77.2031 30.4375 78.7969C32.0938 80.375 32.9219 82.5469 32.9219 85.3125C32.9219 88.0469 31.6562 90.7422 29.125 93.3984L26.5703 95.9297C25.4297 97.1953 24.8594 99.0156 24.8594 101.391H20.5234ZM20.3359 108.82C20.3359 108.117 20.5469 107.531 20.9688 107.062C21.4062 106.578 22.0469 106.336 22.8906 106.336C23.7344 106.336 24.375 106.578 24.8125 107.062C25.25 107.531 25.4688 108.117 25.4688 108.82C25.4688 109.523 25.25 110.109 24.8125 110.578C24.375 111.031 23.7344 111.258 22.8906 111.258C22.0469 111.258 21.4062 111.031 20.9688 110.578C20.5469 110.109 20.3359 109.523 20.3359 108.82Z" fill="#F20089"/>'
			'<path d="M20.5234 161.391C20.5547 159.531 20.7656 158.062 21.1562 156.984C21.5469 155.906 22.3438 154.711 23.5469 153.398L26.6172 150.234C27.9297 148.75 28.5859 147.156 28.5859 145.453C28.5859 143.812 28.1562 142.531 27.2969 141.609C26.4375 140.672 25.1875 140.203 23.5469 140.203C21.9531 140.203 20.6719 140.625 19.7031 141.469C18.7344 142.312 18.25 143.445 18.25 144.867H13.9141C13.9453 142.336 14.8438 140.297 16.6094 138.75C18.3906 137.188 20.7031 136.406 23.5469 136.406C26.5 136.406 28.7969 137.203 30.4375 138.797C32.0938 140.375 32.9219 142.547 32.9219 145.312C32.9219 148.047 31.6562 150.742 29.125 153.398L26.5703 155.93C25.4297 157.195 24.8594 159.016 24.8594 161.391H20.5234ZM20.3359 168.82C20.3359 168.117 20.5469 167.531 20.9688 167.062C21.4062 166.578 22.0469 166.336 22.8906 166.336C23.7344 166.336 24.375 166.578 24.8125 167.062C25.25 167.531 25.4688 168.117 25.4688 168.82C25.4688 169.523 25.25 170.109 24.8125 170.578C24.375 171.031 23.7344 171.258 22.8906 171.258C22.0469 171.258 21.4062 171.031 20.9688 170.578C20.5469 170.109 20.3359 169.523 20.3359 168.82Z" fill="#F20089"/>';
	}
}

contract UnrevealedSVG3 is IExternalStatic {
	function getSVG() external pure returns (string memory) {
		return '<path d="M20.5234 221.391C20.5547 219.531 20.7656 218.062 21.1562 216.984C21.5469 215.906 22.3438 214.711 23.5469 213.398L26.6172 210.234C27.9297 208.75 28.5859 207.156 28.5859 205.453C28.5859 203.812 28.1562 202.531 27.2969 201.609C26.4375 200.672 25.1875 200.203 23.5469 200.203C21.9531 200.203 20.6719 200.625 19.7031 201.469C18.7344 202.312 18.25 203.445 18.25 204.867H13.9141C13.9453 202.336 14.8438 200.297 16.6094 198.75C18.3906 197.188 20.7031 196.406 23.5469 196.406C26.5 196.406 28.7969 197.203 30.4375 198.797C32.0938 200.375 32.9219 202.547 32.9219 205.312C32.9219 208.047 31.6562 210.742 29.125 213.398L26.5703 215.93C25.4297 217.195 24.8594 219.016 24.8594 221.391H20.5234ZM20.3359 228.82C20.3359 228.117 20.5469 227.531 20.9688 227.062C21.4062 226.578 22.0469 226.336 22.8906 226.336C23.7344 226.336 24.375 226.578 24.8125 227.062C25.25 227.531 25.4688 228.117 25.4688 228.82C25.4688 229.523 25.25 230.109 24.8125 230.578C24.375 231.031 23.7344 231.258 22.8906 231.258C22.0469 231.258 21.4062 231.031 20.9688 230.578C20.5469 230.109 20.3359 229.523 20.3359 228.82Z" fill="#F20089"/>'
			'<path d="M20.5234 281.391C20.5547 279.531 20.7656 278.062 21.1562 276.984C21.5469 275.906 22.3438 274.711 23.5469 273.398L26.6172 270.234C27.9297 268.75 28.5859 267.156 28.5859 265.453C28.5859 263.812 28.1562 262.531 27.2969 261.609C26.4375 260.672 25.1875 260.203 23.5469 260.203C21.9531 260.203 20.6719 260.625 19.7031 261.469C18.7344 262.312 18.25 263.445 18.25 264.867H13.9141C13.9453 262.336 14.8438 260.297 16.6094 258.75C18.3906 257.188 20.7031 256.406 23.5469 256.406C26.5 256.406 28.7969 257.203 30.4375 258.797C32.0938 260.375 32.9219 262.547 32.9219 265.312C32.9219 268.047 31.6562 270.742 29.125 273.398L26.5703 275.93C25.4297 277.195 24.8594 279.016 24.8594 281.391H20.5234ZM20.3359 288.82C20.3359 288.117 20.5469 287.531 20.9688 287.062C21.4062 286.578 22.0469 286.336 22.8906 286.336C23.7344 286.336 24.375 286.578 24.8125 287.062C25.25 287.531 25.4688 288.117 25.4688 288.82C25.4688 289.523 25.25 290.109 24.8125 290.578C24.375 291.031 23.7344 291.258 22.8906 291.258C22.0469 291.258 21.4062 291.031 20.9688 290.578C20.5469 290.109 20.3359 289.523 20.3359 288.82Z" fill="#F20089"/>'
			'<path d="M20.5234 341.391C20.5547 339.531 20.7656 338.062 21.1562 336.984C21.5469 335.906 22.3438 334.711 23.5469 333.398L26.6172 330.234C27.9297 328.75 28.5859 327.156 28.5859 325.453C28.5859 323.812 28.1562 322.531 27.2969 321.609C26.4375 320.672 25.1875 320.203 23.5469 320.203C21.9531 320.203 20.6719 320.625 19.7031 321.469C18.7344 322.312 18.25 323.445 18.25 324.867H13.9141C13.9453 322.336 14.8438 320.297 16.6094 318.75C18.3906 317.188 20.7031 316.406 23.5469 316.406C26.5 316.406 28.7969 317.203 30.4375 318.797C32.0938 320.375 32.9219 322.547 32.9219 325.312C32.9219 328.047 31.6562 330.742 29.125 333.398L26.5703 335.93C25.4297 337.195 24.8594 339.016 24.8594 341.391H20.5234ZM20.3359 348.82C20.3359 348.117 20.5469 347.531 20.9688 347.062C21.4062 346.578 22.0469 346.336 22.8906 346.336C23.7344 346.336 24.375 346.578 24.8125 347.062C25.25 347.531 25.4688 348.117 25.4688 348.82C25.4688 349.523 25.25 350.109 24.8125 350.578C24.375 351.031 23.7344 351.258 22.8906 351.258C22.0469 351.258 21.4062 351.031 20.9688 350.578C20.5469 350.109 20.3359 349.523 20.3359 348.82Z" fill="#F20089"/>'
			'<path d="M20.5234 401.391C20.5547 399.531 20.7656 398.062 21.1562 396.984C21.5469 395.906 22.3438 394.711 23.5469 393.398L26.6172 390.234C27.9297 388.75 28.5859 387.156 28.5859 385.453C28.5859 383.812 28.1562 382.531 27.2969 381.609C26.4375 380.672 25.1875 380.203 23.5469 380.203C21.9531 380.203 20.6719 380.625 19.7031 381.469C18.7344 382.312 18.25 383.445 18.25 384.867H13.9141C13.9453 382.336 14.8438 380.297 16.6094 378.75C18.3906 377.188 20.7031 376.406 23.5469 376.406C26.5 376.406 28.7969 377.203 30.4375 378.797C32.0938 380.375 32.9219 382.547 32.9219 385.312C32.9219 388.047 31.6562 390.742 29.125 393.398L26.5703 395.93C25.4297 397.195 24.8594 399.016 24.8594 401.391H20.5234ZM20.3359 408.82C20.3359 408.117 20.5469 407.531 20.9688 407.062C21.4062 406.578 22.0469 406.336 22.8906 406.336C23.7344 406.336 24.375 406.578 24.8125 407.062C25.25 407.531 25.4688 408.117 25.4688 408.82C25.4688 409.523 25.25 410.109 24.8125 410.578C24.375 411.031 23.7344 411.258 22.8906 411.258C22.0469 411.258 21.4062 411.031 20.9688 410.578C20.5469 410.109 20.3359 409.523 20.3359 408.82Z" fill="#F20089"/>'
			'<path d="M20.5234 461.391C20.5547 459.531 20.7656 458.062 21.1562 456.984C21.5469 455.906 22.3438 454.711 23.5469 453.398L26.6172 450.234C27.9297 448.75 28.5859 447.156 28.5859 445.453C28.5859 443.812 28.1562 442.531 27.2969 441.609C26.4375 440.672 25.1875 440.203 23.5469 440.203C21.9531 440.203 20.6719 440.625 19.7031 441.469C18.7344 442.312 18.25 443.445 18.25 444.867H13.9141C13.9453 442.336 14.8438 440.297 16.6094 438.75C18.3906 437.188 20.7031 436.406 23.5469 436.406C26.5 436.406 28.7969 437.203 30.4375 438.797C32.0938 440.375 32.9219 442.547 32.9219 445.312C32.9219 448.047 31.6562 450.742 29.125 453.398L26.5703 455.93C25.4297 457.195 24.8594 459.016 24.8594 461.391H20.5234ZM20.3359 468.82C20.3359 468.117 20.5469 467.531 20.9688 467.062C21.4062 466.578 22.0469 466.336 22.8906 466.336C23.7344 466.336 24.375 466.578 24.8125 467.062C25.25 467.531 25.4688 468.117 25.4688 468.82C25.4688 469.523 25.25 470.109 24.8125 470.578C24.375 471.031 23.7344 471.258 22.8906 471.258C22.0469 471.258 21.4062 471.031 20.9688 470.578C20.5469 470.109 20.3359 469.523 20.3359 468.82Z" fill="#F20089"/>'
			'</g><defs><clipPath id="clip0_1004:953"><rect width="500" height="500" fill="white"/></clipPath></defs></svg>';
	}
}

interface IExternalEffect {
    function getEffect(string memory color) external pure returns (string memory);
}

contract LightFlickering1 is IExternalEffect {
    function getEffect(string memory color) external pure returns (string memory) {
        return string(abi.encodePacked('<g clip-path="url(#clip0_1009:1297)"><path d="M19.7068 8.52866C22.9899 9.29415 25.6327 11.8978 26.4398 15.1616C27.2494 18.436 26.3228 21.7735 23.9612 24.0894C23.1258 24.9087 22.627 26.2218 22.627 27.6021V27.8224C22.627 28.7313 22.2304 29.5492 21.6016 30.1128V31.924C21.6016 33.6202 20.2216 35.0001 18.5254 35.0001H16.4746C14.7784 35.0001 13.3985 33.6202 13.3985 31.924V30.1128C12.7696 29.5492 12.3731 28.7314 12.3731 27.8224V27.5981C12.3731 26.2388 11.8476 24.9007 10.9674 24.0187C9.22897 22.2764 8.27153 19.9614 8.27153 17.5001C8.27153 11.6158 13.7245 7.13427 19.7068 8.52866ZM15.4493 31.924C15.4493 32.4894 15.9092 32.9494 16.4746 32.9494H18.5254C19.0908 32.9494 19.5508 32.4894 19.5508 31.924V30.8986H15.4493V31.924ZM12.4192 22.5701C13.6932 23.8468 14.4239 25.6794 14.4239 27.5981V27.8224C14.4239 28.3878 14.8839 28.8478 15.4493 28.8478H19.5508C20.1162 28.8478 20.5762 28.3878 20.5762 27.8224V27.6021C20.5762 25.6539 21.2867 23.8399 22.5253 22.6253C24.3635 20.8226 25.0826 18.2166 24.449 15.6539C23.8253 13.131 21.781 11.118 19.2411 10.5259C14.5468 9.43128 10.3223 12.9357 10.3223 17.5001C10.3223 19.4145 11.067 21.215 12.4192 22.5701Z" fill="', color, '"/><path d="M25.4757 8.07409L28.376 5.17387C28.7763 4.77342 29.4256 4.77342 29.8261 5.17387C30.2265 5.57432 30.2265 6.22353 29.8261 6.62398L26.9258 9.5242C26.5254 9.92465 25.8761 9.92465 25.4757 9.5242C25.0752 9.12375 25.0752 8.47454 25.4757 8.07409Z" fill="', color, '"/><path d="M29.8047 16.4746H33.9746C34.5409 16.4746 35 16.9337 35 17.5C35 18.0663 34.5409 18.5254 33.9746 18.5254H29.8047C29.2384 18.5254 28.7793 18.0663 28.7793 17.5C28.7793 16.9337 29.2384 16.4746 29.8047 16.4746Z" fill="', color, '"/>'));
    }
}

contract LightFlickering2 is IExternalEffect {
    function getEffect(string memory color) external pure returns (string memory) {
        return string(abi.encodePacked('<path d="M1.02539 16.4746H5.19531C5.7616 16.4746 6.2207 16.9337 6.2207 17.5C6.2207 18.0663 5.7616 18.5254 5.19531 18.5254H1.02539C0.459102 18.5254 0 18.0663 0 17.5C0 16.9337 0.459102 16.4746 1.02539 16.4746Z" fill="', color, '"/><path d="M5.17392 5.17387C5.57424 4.77342 6.22351 4.77342 6.62403 5.17387L9.52431 8.07409C9.92476 8.47447 9.92476 9.12375 9.52431 9.5242C9.12393 9.92465 8.47465 9.92465 8.07421 9.5242L5.17392 6.62398C4.77348 6.2236 4.77348 5.57432 5.17392 5.17387Z" fill="', color, '"/><path d="M17.5 0C18.0663 0 18.5254 0.459102 18.5254 1.02539V5.19531C18.5254 5.7616 18.0663 6.2207 17.5 6.2207C16.9337 6.2207 16.4746 5.7616 16.4746 5.19531V1.02539C16.4746 0.459102 16.9337 0 17.5 0Z" fill="', color, '"/><path d="M17.5 12.373C17.9215 12.373 18.3508 12.4236 18.7754 12.523C20.5435 12.9357 22.0237 14.3912 22.4586 16.1446C22.5949 16.6943 22.2598 17.2504 21.7102 17.3867C21.1605 17.523 20.6045 17.1879 20.4681 16.6383C20.2179 15.6295 19.3302 14.7584 18.3085 14.5199C18.0363 14.4562 17.7642 14.4238 17.5 14.4238C16.9337 14.4238 16.4746 13.9647 16.4746 13.3984C16.4746 12.8321 16.9337 12.373 17.5 12.373Z" fill="', color, '"/></g><defs><clipPath id="clip0_1009:1297"><rect width="35" height="35" fill="white" transform="matrix(-1 0 0 1 35 0)"/></clipPath></defs>'));
    }
}

interface IExternalBaseSVG {
	function getBaseSVG(string[5] memory, uint256, uint256, bool) external pure returns (string memory);
}

contract BaseSVG1 is IExternalBaseSVG {
	function getBaseSVG(string[5] memory colorLayers, uint256 generation, uint256 twists, bool distortion) public pure returns (string memory) {
		string memory svgString = '<svg width="500" height="500" viewBox="0 0 500 500" fill="none" xmlns="http://www.w3.org/2000/svg">'
    		'<g clip-path="url(#clip0_1110:953)">'
    		'<rect width="500" height="500" fill="black"/>'
    		'<path d="M580 249.5C580 430.926 432.926 578 251.5 578C70.0745 578 -77 430.926 -77 249.5C-77 68.0745 70.0745 -79 251.5 -79C432.926 -79 580 68.0745 580 249.5Z" fill="#333333"/>'
    		'<circle cx="248.5" cy="250.5" r="281.5" fill="#333333" stroke="black" stroke-width="2"/>'
    		'<circle cx="247" cy="247" r="234" fill="#333333" stroke="black" stroke-width="2"/>'
    		'<circle cx="250" cy="246" r="178" fill="#333333" stroke="black" stroke-width="2"/>';
		return svgString;
	}
}

contract BaseSVG2 is IExternalBaseSVG {
	function getBaseSVG(string[5] memory colorLayers, uint256 generation, uint256 twists, bool distortion) public pure returns (string memory) {
		string memory svgString = string(abi.encodePacked('<path d="M250 374C319.036 374 375 318.036 375 249C375 179.964 319.036 124 250 124C180.964 124 125 179.964 125 249C125 318.036 180.964 374 250 374Z" fill="#3A3A3A"/>'
    		'<path d="M258.923 373.687C320.853 369.319 370.328 319.838 374.687 257.906L336.685 219.771L334.715 217.934L228.143 240.057L178.791 218.236L161.222 275.985L163.574 278.486L258.923 373.687Z" fill="', colorLayers[4], '"/>'
    		'<path d="M307.575 207.728C282.827 207.728 261.482 222.487 249.993 232.286C246.912 229.792 242.866 227.174 238.604 224.322C222.147 213.312 206.61 207.728 192.425 207.728C169.667 207.728 151.153 226.243 151.153 249C151.153 271.757 169.667 290.272 192.425 290.272C217.173 290.272 238.504 275.525 249.993 265.726C253.074 268.219 257.134 270.826 261.396 273.678C277.853 284.688 293.389 290.272 307.575 290.272C330.332 290.272 348.847 271.757 348.847 249C348.847 226.243 330.333 207.728 307.575 207.728ZM192.425 265.858C183.129 265.858 175.567 258.295 175.567 249C175.567 239.705 183.129 232.142 192.425 232.142C205.826 232.142 221.178 241.366 231.564 249.279C222.445 256.56 207.79 265.858 192.425 265.858V265.858ZM307.575 265.858C294.174 265.858 278.822 256.634 268.436 248.721C277.556 241.44 292.21 232.143 307.575 232.143C316.871 232.143 324.433 239.705 324.433 249C324.433 258.296 316.871 265.858 307.575 265.858Z" fill="', colorLayers[0], '"/>'
    		'<path d="M307.575 207.728C283.023 207.728 261.55 222.484 249.993 232.286V265.727C253.075 268.22 257.134 270.827 261.397 273.678C277.853 284.689 293.389 290.272 307.575 290.272C330.333 290.272 348.847 271.758 348.847 249C348.847 226.243 330.333 207.728 307.575 207.728V207.728ZM307.575 265.858C294.174 265.858 278.822 256.634 268.436 248.721C277.556 241.44 292.21 232.143 307.575 232.143C316.871 232.143 324.433 239.705 324.433 249C324.433 258.296 316.871 265.858 307.575 265.858Z" fill="', colorLayers[3], '"/>'));
		return svgString;
	}
}

contract BaseSVG3 is IExternalBaseSVG {
	function getBaseSVG(string[5] memory colorLayers, uint256 generation, uint256 twists, bool distortion) public pure returns (string memory) {
		string memory svgString = string(abi.encodePacked('<g transform="translate(0 -4)">'
    		'<rect x="462" y="448" width="24" height="20" fill="white"/>'
    		'<rect x="462" y="472" width="24" height="20" fill="white"/>'
    		'<rect x="462" y="425" width="24" height="20" fill="white"/>'
    		'<path d="M410.335 428.028H407.822V435H406.796V428.028H404.288V427.18H410.335V428.028ZM413.268 432.535L413.418 433.566L413.639 432.637L415.186 427.18H416.056L417.565 432.637L417.78 433.582L417.946 432.529L419.16 427.18H420.197L418.301 435H417.361L415.75 429.301L415.626 428.705L415.502 429.301L413.832 435H412.892L411.001 427.18H412.033L413.268 432.535ZM422.453 435H421.421V427.18H422.453V435ZM426.647 431.514C425.763 431.26 425.118 430.948 424.714 430.58C424.313 430.207 424.112 429.749 424.112 429.205C424.112 428.589 424.358 428.08 424.848 427.679C425.342 427.275 425.983 427.072 426.771 427.072C427.308 427.072 427.786 427.176 428.205 427.384C428.628 427.591 428.953 427.878 429.183 428.243C429.415 428.608 429.532 429.008 429.532 429.441H428.495C428.495 428.968 428.345 428.598 428.044 428.329C427.743 428.057 427.319 427.921 426.771 427.921C426.263 427.921 425.865 428.034 425.579 428.259C425.296 428.481 425.154 428.791 425.154 429.188C425.154 429.507 425.289 429.778 425.557 430C425.829 430.218 426.289 430.418 426.938 430.601C427.589 430.784 428.098 430.986 428.463 431.208C428.832 431.426 429.104 431.682 429.279 431.976C429.458 432.27 429.548 432.615 429.548 433.013C429.548 433.646 429.301 434.155 428.807 434.538C428.312 434.918 427.652 435.107 426.825 435.107C426.288 435.107 425.786 435.005 425.321 434.801C424.855 434.594 424.495 434.311 424.241 433.953C423.991 433.595 423.865 433.188 423.865 432.733H424.902C424.902 433.206 425.076 433.58 425.423 433.856C425.774 434.128 426.241 434.264 426.825 434.264C427.369 434.264 427.786 434.153 428.076 433.931C428.366 433.709 428.511 433.407 428.511 433.023C428.511 432.64 428.377 432.345 428.108 432.137C427.84 431.926 427.353 431.718 426.647 431.514ZM436.278 428.028H433.764V435H432.738V428.028H430.23V427.18H436.278V428.028ZM439.656 431.514C438.772 431.26 438.127 430.948 437.723 430.58C437.322 430.207 437.121 429.749 437.121 429.205C437.121 428.589 437.366 428.08 437.857 427.679C438.351 427.275 438.992 427.072 439.78 427.072C440.317 427.072 440.795 427.176 441.214 427.384C441.636 427.591 441.962 427.878 442.191 428.243C442.424 428.608 442.541 429.008 442.541 429.441H441.504C441.504 428.968 441.354 428.598 441.053 428.329C440.752 428.057 440.328 427.921 439.78 427.921C439.271 427.921 438.874 428.034 438.587 428.259C438.305 428.481 438.163 428.791 438.163 429.188C438.163 429.507 438.297 429.778 438.566 430C438.838 430.218 439.298 430.418 439.946 430.601C440.598 430.784 441.106 430.986 441.472 431.208C441.84 431.426 442.113 431.682 442.288 431.976C442.467 432.27 442.557 432.615 442.557 433.013C442.557 433.646 442.31 434.155 441.815 434.538C441.321 434.918 440.661 435.107 439.833 435.107C439.296 435.107 438.795 435.005 438.33 434.801C437.864 434.594 437.504 434.311 437.25 433.953C436.999 433.595 436.874 433.188 436.874 432.733H437.911C437.911 433.206 438.084 433.58 438.432 433.856C438.783 434.128 439.25 434.264 439.833 434.264C440.378 434.264 440.795 434.153 441.085 433.931C441.375 433.709 441.52 433.407 441.52 433.023C441.52 432.64 441.386 432.345 441.117 432.137C440.849 431.926 440.362 431.718 439.656 431.514Z" fill="white"/>'
    		'<rect x="462" y="402" width="24" height="20" fill="white"/>'
    		'<text x="470" y="416" fill="', colorLayers[0], '" font-size="12" font-family="Arial">', uint2str(generation), '</text>'
    		'<text x="470" y="439" fill="', colorLayers[0], '" font-size="12" font-family="Arial">', uint2str(twists), '</text>'));
    
		return svgString;
	}
}

contract BaseSVG4 is IExternalBaseSVG {
	function getBaseSVG(string[5] memory colorLayers, uint256 generation, uint256 twists, bool distortion) public pure returns (string memory) {
		string memory distortionValueA = 'NO';
		string memory distortionValueB = '12';
		if (distortion == true) {
			distortionValueA = 'YES';
			distortionValueB = '9';
		}

		string memory svgString = string(abi.encodePacked('<text x="465" y="462" fill="', colorLayers[0], '" font-size="', distortionValueB, '" font-family="Arial">', distortionValueA, '</text>'
    		'<path d="M419.886 410.974C419.621 411.354 419.25 411.638 418.774 411.828C418.301 412.014 417.75 412.107 417.12 412.107C416.482 412.107 415.917 411.959 415.422 411.662C414.928 411.361 414.545 410.935 414.273 410.383C414.004 409.832 413.867 409.193 413.859 408.466V407.784C413.859 406.606 414.133 405.693 414.681 405.044C415.233 404.396 416.006 404.072 417.001 404.072C417.818 404.072 418.475 404.282 418.973 404.701C419.47 405.116 419.775 405.707 419.886 406.473H418.854C418.661 405.438 418.045 404.921 417.007 404.921C416.316 404.921 415.791 405.164 415.433 405.651C415.079 406.135 414.9 406.837 414.896 407.757V408.396C414.896 409.273 415.097 409.972 415.498 410.491C415.899 411.006 416.441 411.264 417.125 411.264C417.512 411.264 417.85 411.221 418.14 411.135C418.43 411.049 418.67 410.904 418.86 410.7V408.944H417.05V408.106H419.886V410.974ZM426.03 408.385H422.641V411.157H426.578V412H421.61V404.18H426.524V405.028H422.641V407.542H426.03V408.385ZM433.872 412H432.835L428.898 405.974V412H427.862V404.18H428.898L432.846 410.233V404.18H433.872V412Z" fill="white"/>'
    		'<path d="M382.39 461V453.18H384.597C385.278 453.18 385.879 453.33 386.402 453.631C386.925 453.932 387.327 454.36 387.61 454.915C387.897 455.47 388.042 456.107 388.045 456.827V457.326C388.045 458.064 387.902 458.71 387.616 459.265C387.333 459.82 386.926 460.246 386.396 460.543C385.87 460.841 385.256 460.993 384.554 461H382.39ZM383.421 454.028V460.157H384.506C385.301 460.157 385.918 459.91 386.359 459.416C386.803 458.921 387.025 458.218 387.025 457.305V456.848C387.025 455.96 386.815 455.271 386.396 454.78C385.981 454.286 385.39 454.035 384.624 454.028H383.421ZM390.715 461H389.684V453.18H390.715V461ZM394.91 457.514C394.025 457.26 393.381 456.948 392.976 456.58C392.575 456.207 392.375 455.749 392.375 455.205C392.375 454.589 392.62 454.08 393.11 453.679C393.604 453.275 394.245 453.072 395.033 453.072C395.57 453.072 396.048 453.176 396.467 453.384C396.89 453.591 397.216 453.878 397.445 454.243C397.678 454.608 397.794 455.008 397.794 455.441H396.757C396.757 454.968 396.607 454.598 396.306 454.329C396.005 454.057 395.581 453.921 395.033 453.921C394.525 453.921 394.127 454.034 393.841 454.259C393.558 454.481 393.417 454.791 393.417 455.188C393.417 455.507 393.551 455.778 393.819 456C394.091 456.218 394.552 456.418 395.2 456.601C395.851 456.784 396.36 456.986 396.725 457.208C397.094 457.426 397.366 457.682 397.542 457.976C397.721 458.27 397.81 458.615 397.81 459.013C397.81 459.646 397.563 460.155 397.069 460.538C396.575 460.918 395.914 461.107 395.087 461.107C394.55 461.107 394.049 461.005 393.583 460.801C393.118 460.594 392.758 460.311 392.503 459.953C392.253 459.595 392.127 459.188 392.127 458.733H393.164C393.164 459.206 393.338 459.58 393.685 459.856C394.036 460.128 394.503 460.264 395.087 460.264C395.631 460.264 396.048 460.153 396.338 459.931C396.628 459.709 396.773 459.407 396.773 459.023C396.773 458.64 396.639 458.345 396.371 458.137C396.102 457.926 395.615 457.718 394.91 457.514ZM404.54 454.028H402.026V461H401V454.028H398.492V453.18H404.54V454.028ZM411.565 457.342C411.565 458.109 411.437 458.778 411.179 459.351C410.921 459.92 410.556 460.355 410.083 460.656C409.61 460.957 409.059 461.107 408.429 461.107C407.813 461.107 407.267 460.957 406.791 460.656C406.314 460.352 405.944 459.92 405.679 459.362C405.417 458.8 405.283 458.15 405.276 457.412V456.848C405.276 456.096 405.407 455.432 405.668 454.855C405.929 454.279 406.298 453.839 406.774 453.534C407.254 453.226 407.802 453.072 408.418 453.072C409.045 453.072 409.596 453.224 410.072 453.529C410.552 453.83 410.921 454.268 411.179 454.845C411.437 455.418 411.565 456.085 411.565 456.848V457.342ZM410.54 456.837C410.54 455.91 410.353 455.199 409.981 454.705C409.609 454.207 409.088 453.958 408.418 453.958C407.766 453.958 407.252 454.207 406.876 454.705C406.504 455.199 406.312 455.887 406.302 456.768V457.342C406.302 458.241 406.49 458.948 406.866 459.464C407.245 459.976 407.766 460.232 408.429 460.232C409.095 460.232 409.61 459.99 409.976 459.507C410.341 459.02 410.529 458.323 410.54 457.417V456.837ZM415.98 457.836H414.144V461H413.107V453.18H415.696C416.577 453.18 417.253 453.38 417.726 453.781C418.202 454.182 418.44 454.766 418.44 455.532C418.44 456.019 418.308 456.444 418.043 456.805C417.782 457.167 417.416 457.437 416.947 457.616L418.784 460.936V461H417.678L415.98 457.836ZM414.144 456.993H415.728C416.24 456.993 416.646 456.861 416.947 456.596C417.252 456.331 417.404 455.976 417.404 455.532C417.404 455.049 417.259 454.678 416.969 454.42C416.682 454.163 416.267 454.032 415.723 454.028H414.144V456.993ZM424.864 454.028H422.351V461H421.325V454.028H418.816V453.18H424.864V454.028ZM427.131 461H426.1V453.18H427.131V461ZM435.037 457.342C435.037 458.109 434.908 458.778 434.65 459.351C434.393 459.92 434.027 460.355 433.555 460.656C433.082 460.957 432.531 461.107 431.9 461.107C431.285 461.107 430.738 460.957 430.262 460.656C429.786 460.352 429.415 459.92 429.15 459.362C428.889 458.8 428.755 458.15 428.748 457.412V456.848C428.748 456.096 428.878 455.432 429.14 454.855C429.401 454.279 429.77 453.839 430.246 453.534C430.726 453.226 431.274 453.072 431.89 453.072C432.516 453.072 433.068 453.224 433.544 453.529C434.024 453.83 434.393 454.268 434.65 454.845C434.908 455.418 435.037 456.085 435.037 456.848V457.342ZM434.011 456.837C434.011 455.91 433.825 455.199 433.453 454.705C433.08 454.207 432.559 453.958 431.89 453.958C431.238 453.958 430.724 454.207 430.348 454.705C429.976 455.199 429.784 455.887 429.773 456.768V457.342C429.773 458.241 429.961 458.948 430.337 459.464C430.717 459.976 431.238 460.232 431.9 460.232C432.566 460.232 433.082 459.99 433.447 459.507C433.812 459.02 434 458.323 434.011 457.417V456.837ZM442.594 461H441.558L437.621 454.974V461H436.584V453.18H437.621L441.568 459.233V453.18H442.594V461Z" fill="white"/>'
    		'<path d="M385.101 485H384.064L380.127 478.974V485H379.09V477.18H380.127L384.075 483.233V477.18H385.101V485ZM392.948 481.342C392.948 482.109 392.819 482.778 392.561 483.351C392.303 483.92 391.938 484.355 391.465 484.656C390.993 484.957 390.441 485.107 389.811 485.107C389.195 485.107 388.649 484.957 388.173 484.656C387.697 484.352 387.326 483.92 387.061 483.362C386.8 482.8 386.665 482.15 386.658 481.412V480.848C386.658 480.096 386.789 479.432 387.05 478.855C387.312 478.279 387.681 477.839 388.157 477.534C388.637 477.226 389.184 477.072 389.8 477.072C390.427 477.072 390.978 477.224 391.455 477.529C391.934 477.83 392.303 478.268 392.561 478.845C392.819 479.418 392.948 480.085 392.948 480.848V481.342ZM391.922 480.837C391.922 479.91 391.736 479.199 391.363 478.705C390.991 478.207 390.47 477.958 389.8 477.958C389.149 477.958 388.635 478.207 388.259 478.705C387.886 479.199 387.695 479.887 387.684 480.768V481.342C387.684 482.241 387.872 482.948 388.248 483.464C388.628 483.976 389.149 484.232 389.811 484.232C390.477 484.232 390.993 483.99 391.358 483.507C391.723 483.02 391.911 482.323 391.922 481.417V480.837ZM399.748 478.028H397.234V485H396.208V478.028H393.7V477.18H399.748V478.028ZM405.328 481.385H401.939V484.157H405.876V485H400.908V477.18H405.822V478.028H401.939V480.542H405.328V481.385ZM412.192 481.514C411.308 481.26 410.663 480.948 410.259 480.58C409.858 480.207 409.657 479.749 409.657 479.205C409.657 478.589 409.903 478.08 410.393 477.679C410.887 477.275 411.528 477.072 412.316 477.072C412.853 477.072 413.331 477.176 413.75 477.384C414.173 477.591 414.498 477.878 414.728 478.243C414.96 478.608 415.077 479.008 415.077 479.441H414.04C414.04 478.968 413.89 478.598 413.589 478.329C413.288 478.057 412.864 477.921 412.316 477.921C411.807 477.921 411.41 478.034 411.124 478.259C410.841 478.481 410.699 478.791 410.699 479.188C410.699 479.507 410.833 479.778 411.102 480C411.374 480.218 411.834 480.418 412.482 480.601C413.134 480.784 413.643 480.986 414.008 481.208C414.377 481.426 414.649 481.682 414.824 481.976C415.003 482.27 415.093 482.615 415.093 483.013C415.093 483.646 414.846 484.155 414.352 484.538C413.857 484.918 413.197 485.107 412.37 485.107C411.833 485.107 411.331 485.005 410.866 484.801C410.4 484.594 410.04 484.311 409.786 483.953C409.535 483.595 409.41 483.188 409.41 482.733H410.447C410.447 483.206 410.62 483.58 410.968 483.856C411.319 484.128 411.786 484.264 412.37 484.264C412.914 484.264 413.331 484.153 413.621 483.931C413.911 483.709 414.056 483.407 414.056 483.023C414.056 482.64 413.922 482.345 413.653 482.137C413.385 481.926 412.898 481.718 412.192 481.514ZM422.43 485H421.393V481.385H417.451V485H416.419V477.18H417.451V480.542H421.393V477.18H422.43V485ZM428.676 482.959H425.4L424.664 485H423.601L426.587 477.18H427.489L430.481 485H429.423L428.676 482.959ZM425.711 482.11H428.37L427.038 478.453L425.711 482.11ZM432.565 481.938V485H431.534V477.18H434.418C435.274 477.18 435.943 477.398 436.427 477.835C436.914 478.272 437.157 478.85 437.157 479.57C437.157 480.329 436.919 480.914 436.443 481.326C435.97 481.734 435.292 481.938 434.407 481.938H432.565ZM432.565 481.095H434.418C434.969 481.095 435.392 480.966 435.686 480.708C435.979 480.447 436.126 480.071 436.126 479.581C436.126 479.115 435.979 478.743 435.686 478.463C435.392 478.184 434.989 478.039 434.477 478.028H432.565V481.095ZM442.894 481.385H439.504V484.157H443.441V485H438.473V477.18H443.388V478.028H439.504V480.542H442.894V481.385Z" fill="white"/>'));
    
		return svgString;
	}
}

function uint2str(uint _i) pure returns (string memory _uintAsString) {
	if (_i == 0) {
		return "0";
	}
	uint j = _i;
	uint len;
	while (j != 0) {
		len++;
		j /= 10;
	}
	bytes memory bstr = new bytes(len);
	uint k = len;
	while (_i != 0) {
		k = k-1;
		uint8 temp = (48 + uint8(_i - _i / 10 * 10));
		bytes1 b1 = bytes1(temp);
		bstr[k] = b1;
		_i /= 10;
	}
	return string(bstr);
}

contract FuturaSVG {
    IExternalEffect public lightFlickeringAddress1;
    IExternalEffect public lightFlickeringAddress2;

    IExternalBaseSVG public baseSVG1;
    IExternalBaseSVG public baseSVG2;
    IExternalBaseSVG public baseSVG3;
    IExternalBaseSVG public baseSVG4;
	
	IExternalStatic public unrevealedSVG1;
	IExternalStatic public unrevealedSVG2;
	IExternalStatic public unrevealedSVG3;

    constructor() {
        // Split up effects into multiple contracts if stack too deep reached0
        lightFlickeringAddress1 = IExternalEffect(new LightFlickering1());
        lightFlickeringAddress2 = IExternalEffect(new LightFlickering2());

        // Split up baseSVG text into multiple contracts if stack too deep reached0
        baseSVG1 = IExternalBaseSVG(new BaseSVG1());
        baseSVG2 = IExternalBaseSVG(new BaseSVG2());
        baseSVG3 = IExternalBaseSVG(new BaseSVG3());
        baseSVG4 = IExternalBaseSVG(new BaseSVG4());

		unrevealedSVG1 = IExternalStatic(new UnrevealedSVG1());
		unrevealedSVG2 = IExternalStatic(new UnrevealedSVG2());
		unrevealedSVG3 = IExternalStatic(new UnrevealedSVG3());
    }

    enum ShapeEnum { SQUARE, LINE, TRIANGLE }

    enum EffectsEnum { LIGHT_PULSE, SHAKING, LIGHT_FLICKERING, ORBITING_PARTICLES, SPHERES, LIGHT_WAVES, LASER, LIGHTNING }

    enum ColorPalette { NEON, TERMINAL, CLOUDS, SAKURA, ATLANTIS, ARES, TOOTHPASTE, ULTRAVIOLET, METAL, SASHIMI, BRIGHT, CHILL, MACAW, NEBULA }

    function getColors(ColorPalette color) public pure returns (string[5] memory colors) {
        if (color == ColorPalette.NEON) return ['#f20089', '#db00b6', '#d100d1', '#b100e8', '#6a00f4'];
        else if (color == ColorPalette.TERMINAL) return ['#92e5a1', '#beff0a', '#80ce87', '#22b455', '#204829'];
        else if (color == ColorPalette.CLOUDS) return ['#5688fe', '#6a98ff', '#ccdbfd', '#ffb340', '#ff9d89'];
        else if (color == ColorPalette.SAKURA) return ['#fc856f', '#f7674a', '#ff320c', '#f79f56', '#f99a49'];
        else if (color == ColorPalette.ATLANTIS) return ['#1e6091', '#168aad', '#168aad', '#76c893', '#99d98c'];
        else if (color == ColorPalette.ARES) return ['#ffd361', '#ffba08', '#f48c06', '#e85d04', '#dc2f02'];
        else if (color == ColorPalette.TOOTHPASTE) return ['#e63946', '#a8dadc', '#457b9d', '#1d3557', '#ee6352'];
        else if (color == ColorPalette.ULTRAVIOLET) return ['#fdc500', '#ffee32', '#ffd500', '#5c0099', '#3d0066'];
        else if (color == ColorPalette.METAL) return ['#8d99ae', '#edf2f4', '#ef233c', '#d90429', '#7b0217'];
        else if (color == ColorPalette.SASHIMI) return ['#f8ad9d', '#ffdab9', '#fbc4ab', '#f4978e', '#f08080'];
        else if (color == ColorPalette.BRIGHT) return ['#f86624', '#ea3546', '#662e9b', '#43bccd', '#5dd39e'];
        else if (color == ColorPalette.CHILL) return ['#faa275', '#ffed66', '#ff5e5b', '#00cecb', '#25a18e'];
        else if (color == ColorPalette.MACAW) return ['#ff595e', '#ffca3a', '#8ac926', '#1982c4', '#6a4c93'];
        else if (color == ColorPalette.NEBULA) return ['#6930c3', '#5390d9', '#48bfe3', '#72efdd', '#06d6a0'];
    }

    function getNoteShape(ShapeEnum shape, string memory color) public view returns (string memory) {
        if (shape == ShapeEnum.SQUARE) return string(abi.encodePacked('<rect x="466" y="474" width="16" height="16" fill="', color, '"/>'));
        else if (shape == ShapeEnum.LINE) return string(abi.encodePacked('<rect x="467" y="480" width="13" height="2" fill="', color, '"/>'));
        else if (shape == ShapeEnum.TRIANGLE) return string(abi.encodePacked('<path d="M474 474L482.66 489H465.34L474 474Z" fill="', color, '"/>'));
    }

    function getEffects(bool[] memory effectFlags, string memory color) public view returns (string memory) {
        uint256 index = 0;
        string memory effectsSvg = '<g transform="translate(12 12)">';

        for (uint256 i = 0; i < effectFlags.length; i++) {
            if (effectFlags[i] == true) {
                effectsSvg = string(abi.encodePacked(effectsSvg, '<g transform="translate(0 ', uint2str(index * 48), ')">', getEffect(EffectsEnum(i), color), '</g>'));
                index++;
            }
        }
        effectsSvg = string(abi.encodePacked(effectsSvg, '</g>'));
        return effectsSvg;
    }

    function getEffect(EffectsEnum effect, string memory color) public view returns (string memory) {
        if (effect == EffectsEnum.LIGHT_PULSE) return string(abi.encodePacked('<path d="M19.4783 32H19.3808C19.0949 31.9757 18.8225 31.8504 18.6009 31.6413C18.3793 31.4321 18.2192 31.1493 18.1426 30.8316L12.2156 6.39145L8.2226 16.7309C8.10296 16.9967 7.92088 17.2187 7.69707 17.3715C7.47327 17.5242 7.2167 17.6018 6.95652 17.5952H1.39129C1.02229 17.5952 0.668419 17.4265 0.407498 17.1264C0.146578 16.8262 0 16.4191 0 15.9947C0 15.5702 0.146578 15.163 0.407498 14.8629C0.668419 14.5627 1.02229 14.3941 1.39129 14.3941H6.05219L11.2556 0.933578C11.374 0.636482 11.5686 0.388219 11.8133 0.22212C12.058 0.0560205 12.341 -0.0199356 12.6243 0.00446954C12.9076 0.0288747 13.1776 0.152461 13.3981 0.358627C13.6185 0.564793 13.7788 0.843651 13.8574 1.15772L19.7843 25.6779L23.7774 15.3385C23.8871 15.0577 24.0649 14.8192 24.2895 14.6517C24.5141 14.4842 24.7758 14.3948 25.0435 14.3941H30.6087C30.9777 14.3941 31.3316 14.5628 31.5925 14.8629C31.8534 15.1631 32 15.5702 32 15.9947C32 16.4192 31.8534 16.8263 31.5925 17.1264C31.3316 17.4266 30.9777 17.5952 30.6087 17.5952H25.9478L20.7444 31.0557C20.6346 31.3365 20.4568 31.5749 20.2323 31.7424C20.0077 31.9099 19.7459 31.9994 19.4783 32V32Z" fill="', color, '"/>'));
        else if (effect == EffectsEnum.SHAKING) return string(abi.encodePacked('<path d="M6.39472 32C5.95992 32 5.52146 31.875 5.17253 31.6175L0.605297 28.2686C0.232611 27.9963 0.0152106 27.6093 0.000595508 27.2015C-0.0121927 26.7936 0.181458 26.3977 0.535875 26.1105L3.81149 23.4418L0.535875 20.7732C-0.17844 20.1912 -0.17844 19.2505 0.535875 18.6686L3.81149 15.9999L0.535875 13.3313C-0.17844 12.7493 -0.17844 11.8087 0.535875 11.2267L3.81149 8.55803L0.535875 5.88937C0.181458 5.60062 -0.0121927 5.2062 0.000595508 4.79839C0.0152106 4.39057 0.232611 4.00359 0.605297 3.73122L5.17253 0.382366C5.92338 -0.168335 7.07615 -0.11773 7.7521 0.492506C8.42622 1.10423 8.36594 2.04489 7.61691 2.5941L4.48014 4.89364L7.68633 7.50575C8.40065 8.0877 8.40065 9.02836 7.68633 9.61032L4.41071 12.279L7.68633 14.9476C8.40065 15.5296 8.40065 16.4703 7.68633 17.0522L4.41071 19.7209L7.68633 22.3895C8.40065 22.9715 8.40065 23.9122 7.68633 24.4941L4.48014 27.1062L7.61691 29.4058C8.36594 29.955 8.42622 30.8956 7.7521 31.5073C7.3922 31.8333 6.89346 32 6.39472 32Z" fill="', color, '"/><path d="M25.6053 32C25.1066 32 24.6078 31.8333 24.2479 31.5073C23.5738 30.8956 23.6341 29.955 24.3831 29.4058L27.5199 27.1062L24.3137 24.4941C23.5994 23.9122 23.5994 22.9715 24.3137 22.3895L27.5893 19.7209L24.3137 17.0522C23.5994 16.4703 23.5994 15.5296 24.3137 14.9476L27.5893 12.279L24.3137 9.61032C23.5994 9.02836 23.5994 8.0877 24.3137 7.50575L27.5199 4.89364L24.3831 2.5941C23.6341 2.04489 23.5738 1.10423 24.2479 0.492506C24.9239 -0.11773 26.0785 -0.168335 26.8275 0.382366L31.3947 3.73122C31.7674 4.00359 31.9848 4.39057 31.9994 4.79839C32.0122 5.2062 31.8186 5.60211 31.4642 5.88937L28.1885 8.55803L31.4642 11.2267C32.1785 11.8087 32.1785 12.7493 31.4642 13.3313L28.1885 15.9999L31.4642 18.6686C32.1785 19.2505 32.1785 20.1912 31.4642 20.7732L28.1885 23.4418L31.4642 26.1105C31.8186 26.3992 32.0122 26.7936 31.9994 27.2015C31.9848 27.6093 31.7674 27.9948 31.3947 28.2686L26.8275 31.6175C26.4786 31.8735 26.0401 32 25.6053 32Z" fill="', color, '"/>'));
        else if (effect == EffectsEnum.LIGHT_FLICKERING) return string(abi.encodePacked(lightFlickeringAddress1.getEffect(color), lightFlickeringAddress2.getEffect(color)));
        else if (effect == EffectsEnum.ORBITING_PARTICLES) return string(abi.encodePacked('<path d="M15.9991 8.32495C20.1943 8.32495 23.5944 11.7252 23.5944 15.9198C23.5944 20.114 20.1943 23.5141 15.9991 23.5141C11.8049 23.5141 8.4043 20.114 8.4043 15.9198C8.4043 11.7251 11.8049 8.32495 15.9991 8.32495Z" fill="', color, '"/><path d="M15.9992 0C14.0058 0 12.1038 0.382952 10.3431 1.05197C10.7277 1.4426 11.0458 1.89728 11.29 2.39599C12.7685 1.88149 14.3495 1.58863 16 1.58863C23.9462 1.58863 30.4101 8.05465 30.4101 15.9992C30.4101 23.9437 23.9462 30.411 15.9992 30.411C8.05384 30.411 1.5895 23.9445 1.5895 16.0001C1.5895 13.3236 2.33618 10.8247 3.6119 8.6746C3.17469 8.33991 2.78918 7.9386 2.48045 7.48135C0.917929 9.95113 0 12.8671 0 16.0001C0 24.8223 7.17686 32.0001 15.9992 32.0001C24.8223 32.0001 32 24.8224 32 16.0001C32 7.17774 24.8223 0 15.9992 0Z" fill="', color, '"/><path d="M6.7098 1.49512C8.52087 1.49512 9.98869 2.96294 9.98869 4.77401C9.98869 6.58508 8.52087 8.0529 6.7098 8.0529C4.89917 8.0529 3.43091 6.58508 3.43091 4.77401C3.43091 2.96294 4.89917 1.49512 6.7098 1.49512Z" fill="', color, '"/>'));
        else if (effect == EffectsEnum.SPHERES) return string(abi.encodePacked('<path d="M7.11111 14.2222C11.0385 14.2222 14.2222 11.0385 14.2222 7.11111C14.2222 3.18375 11.0385 0 7.11111 0C3.18375 0 0 3.18375 0 7.11111C0 11.0385 3.18375 14.2222 7.11111 14.2222Z" fill="', color, '"/><path d="M16 31.9999C18.9455 31.9999 21.3334 29.6121 21.3334 26.6666C21.3334 23.7211 18.9455 21.3333 16 21.3333C13.0545 21.3333 10.6667 23.7211 10.6667 26.6666C10.6667 29.6121 13.0545 31.9999 16 31.9999Z" fill="', color, '"/><path d="M28.4444 14.2222C30.4081 14.2222 32 12.6303 32 10.6666C32 8.70296 30.4081 7.11108 28.4444 7.11108C26.4807 7.11108 24.8889 8.70296 24.8889 10.6666C24.8889 12.6303 26.4807 14.2222 28.4444 14.2222Z" fill="', color, '"/>'));

        else if (effect == EffectsEnum.LIGHT_WAVES) return string(abi.encodePacked('<path d="M22.4671 31.9999C26.0474 31.9977 29.197 30.7158 30.8924 28.5706C31.6167 27.6531 32 26.6203 32 25.5837V10.2399C32 9.05015 30.5528 8.0855 28.7677 8.0855C26.9826 8.0855 25.5353 9.05015 25.5353 10.2399V25.5837C25.5353 25.9238 25.4096 26.2621 25.1724 26.5626C24.4361 27.4945 23.292 27.6906 22.4623 27.691H22.4591C21.6155 27.691 20.7876 27.483 20.1878 27.1203C19.5538 26.7364 19.2324 26.2196 19.2324 25.5837V6.42306C19.2324 4.05104 17.3709 1.95216 14.2541 0.808236C11.1367 -0.335686 7.48066 -0.261648 4.47314 1.00688C1.67207 2.18868 0 4.21348 0 6.42265V22.5201C0 23.7104 1.44728 24.6746 3.23234 24.6746C5.0174 24.6746 6.46469 23.7104 6.46469 22.5201V6.42306C6.46469 5.69873 7.01278 5.03544 7.93089 4.64782C9.351 4.04893 10.6454 4.4029 11.1361 4.58311C11.6267 4.76271 12.7677 5.30283 12.7677 6.4232V25.5838C12.7677 27.4327 13.8601 29.1115 15.8434 30.311C17.6184 31.3847 20.0287 32 22.4591 32L22.4671 31.9999Z" fill="', color, '"/>'));
        else if (effect == EffectsEnum.LASER) return string(abi.encodePacked('<path d="M22.0312 25.418H18.0807C18.0112 25.123 17.9134 24.8423 17.791 24.5803L29.5847 10.2275C29.928 9.8158 29.928 9.1481 29.5849 8.73611C29.2416 8.3244 28.6852 8.32413 28.3419 8.73584L16.5477 23.0886C16.3296 22.9414 16.0954 22.8241 15.8498 22.7409V1.05469C15.8498 0.472137 15.4561 0 14.9709 0C14.4855 0 14.092 0.472137 14.092 1.05469V22.7409C13.8462 22.8244 13.612 22.9414 13.3937 23.0886L1.5995 9.73584C1.25641 9.32385 0.699997 9.32385 0.356674 9.73584C0.0133514 10.1476 0.0133514 10.8152 0.356674 11.2272L12.1506 24.5803C12.028 24.8423 11.9302 25.123 11.8609 25.418H7.91014C7.42468 25.418 7.03123 25.8901 7.03123 26.4727C7.03123 27.0552 7.42468 27.5273 7.91014 27.5273H11.8609C11.9302 27.8223 12.028 28.103 12.1506 28.3651L9.35667 31.7181C9.01335 32.1298 9.01335 32.7978 9.35667 33.2095C9.52834 33.4155 9.7531 33.5185 9.97809 33.5185C10.2031 33.5185 10.4281 33.4155 10.5995 33.2095L13.3937 29.8567C13.612 30.0039 13.8462 30.1212 14.092 30.2044V34.9453C14.092 35.5279 14.4855 36 14.9709 36C15.4561 36 15.8498 35.5279 15.8498 34.9453V30.2044C16.0954 30.1209 16.3296 30.0039 16.5477 29.8567L19.3419 33.2095C19.5135 33.4155 19.7383 33.5185 19.9633 33.5185C20.1883 33.5185 20.4133 33.4155 20.5847 33.2095C20.928 32.7978 20.928 32.1301 20.5847 31.7181L17.7907 28.3653C17.9134 28.1033 18.0112 27.8223 18.0807 27.5273H22.0312C22.5167 27.5273 22.9101 27.0552 22.9101 26.4727C22.9101 25.8901 22.5167 25.418 22.0312 25.418Z" fill="', color, '"/>'));
        else if (effect == EffectsEnum.LIGHTNING) return string(abi.encodePacked('<path d="M31.7124 16.3489C31.3853 15.9735 30.8235 15.7504 30.2226 15.7504H17.778V1.31306C17.778 0.693563 17.1913 0.158071 16.37 0.0294475C15.5344 -0.101801 14.7166 0.21582 14.3753 0.780187L0.152912 24.4049C-0.092418 24.8091 -0.0390888 25.2816 0.288021 25.6517C0.61514 26.0245 1.17693 26.2502 1.77782 26.2502H14.2224V40.6875C14.2224 41.307 14.8091 41.8425 15.6304 41.9711C15.7549 41.9895 15.8793 42 16.0002 42C16.69 42 17.3336 41.7034 17.6251 41.2204L31.8475 17.5957C32.0893 17.1888 32.0431 16.7216 31.7124 16.3489Z" fill="', color, '"/>'));
    }

    function buildSVG(uint256 colorPaletteIndex, uint256 noteShapeIndex, uint256 generation, uint256 twists, bool distortion, bool[] memory effectFlags) public view returns (string memory) {
		string[5] memory colorLayers = getColors(ColorPalette(colorPaletteIndex));

		string memory svgString = string(abi.encodePacked(baseSVG1.getBaseSVG(colorLayers, generation, twists, distortion), baseSVG2.getBaseSVG(colorLayers, generation, twists, distortion)));

		// add effects
		svgString = string(abi.encodePacked(svgString, getEffects(effectFlags, colorLayers[0])));

		// Add details about generation, twists, distortion
		svgString = string(abi.encodePacked(svgString, baseSVG3.getBaseSVG(colorLayers, generation, twists, distortion)));
		svgString = string(abi.encodePacked(svgString, baseSVG4.getBaseSVG(colorLayers, generation, twists, distortion)));

		// Add note shape
		svgString = string(abi.encodePacked(svgString, getNoteShape(ShapeEnum(noteShapeIndex), colorLayers[0])));

		svgString = string(abi.encodePacked(svgString, '</g>'
			'</g>'
			'<defs>'
			'<clipPath id="clip0_1110:953">'));

		svgString = string(abi.encodePacked(svgString, '<rect width="500" height="500" fill="white"/>'
			'</clipPath>'
			'</defs>'
			'</svg>'));

		return svgString;
    }

	function unrevealedSVG() external view returns (string memory) {
		return string(abi.encodePacked(unrevealedSVG1.getSVG(), unrevealedSVG2.getSVG(), unrevealedSVG3.getSVG()));
	}
}

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// WARNING: This contract expects its inheriting contract to implement the logic to verify that 
//    correct payments are received for royalties and correct owners of tokens can withdraw their royalties
// TODO: handle the 0-tokenId condition as a null token, with no royalty payout

contract TokenRoyalties is Ownable {
    using SafeERC20 for IERC20;

    // Mapping of tokenId to the amount of royalties its owner can withdraw
    mapping(uint256 => uint256) public tokenRoyalties;
    // Accounts for the sum of tokenRoyalties waiting to be withdrawn
    uint256 public pendingWithdraw = 0;
	// Address of the WETH token contract
    address public paymentTokenAddress;


    /***********************************|
    |        Admin                      |
    |__________________________________*/


    /**
     * @notice Let owner of the contract withdraw remainder balances
     */
    function withdrawRemainder() public onlyOwner {
        uint256 contractBalance = IERC20(paymentTokenAddress).balanceOf(address(this));
        uint256 remainingDifference = contractBalance - pendingWithdraw;
        IERC20(paymentTokenAddress).safeTransferFrom(address(this), msg.sender, remainingDifference);
    }

    /***********************************|
    |        Internal                   |
    |__________________________________*/


    /**
     * @notice Lets the inheriting contract set the weth contract
     * @param paymentTokenAddressParam address
     */
    function _setPaymentTokenAddress(address paymentTokenAddressParam) internal {
        paymentTokenAddress = paymentTokenAddressParam;
    }

    /**
     * @notice Divideds up amount by the number of nonzero tokenIDs, distributes it to each nonzero token
     * @param amount uint256
     * @param tokenIds uint256[]
     */
    function _accountRoyaltiesBatch(uint256 amount, uint256[] memory tokenIds) internal {
        // Transfer 'amount' of paymentToken from msg.sender to this contract
        IERC20(paymentTokenAddress).safeTransferFrom(msg.sender, address(this), amount);

        uint256 nonzeroTokenLength = 0;

        // Count the number of non-zero tokens
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] != 0) {
                nonzeroTokenLength = nonzeroTokenLength + 1;
            }
        }

        // Compute a distribution per-token
        uint256 distribution = amount / nonzeroTokenLength;

        // For each nonzero token, credit the distribution to it
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] != 0) {
                tokenRoyalties[tokenIds[i]] += distribution;
            }
        }

        // Track the sum of pending royalties so contract owner can withdraw remainder
        pendingWithdraw = pendingWithdraw + distribution * nonzeroTokenLength;
    }

    /**
     * @notice Withdraw pending balance for 1 token. Note: caller needs to validate ownership
     * @param tokenId uint256
     * @param recipient address
     */
    function _withdraw(uint256 tokenId, address recipient) internal {
        uint256 withdrawAmount = tokenRoyalties[tokenId];
        pendingWithdraw = pendingWithdraw - withdrawAmount;
        tokenRoyalties[tokenId] = 0;

        IERC20(paymentTokenAddress).safeTransferFrom(address(this), recipient, withdrawAmount);
    }

    /**
     * @notice Withdraw many balances for more array of token. Note: caller needs to validate tokenIds ownership
     * @param tokenIds uint256[]
     * @param recipient address
     */
    function _withdrawMany(uint256[] memory tokenIds, address recipient) internal {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _withdraw(tokenIds[i], recipient);
        }
    }
}