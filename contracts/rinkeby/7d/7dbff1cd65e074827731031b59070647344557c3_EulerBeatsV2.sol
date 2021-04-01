// Copyright © 2021 Treum.io, a ConsenSys AG company. All rights reserved.
// BY USING THIS SMART CONTRACT, INCLUDING TO BUY, SELL, CREATE, BURN OR USE TOKENS, YOU AGREE TO EULERBEATS’ TERMS OF SERVICE, AVAILABLE HERE: HTTPS://EULERBEATS.COM/TERMS-OF-SERVICE AND IN THE TRANSACTION DATA OF 0x56ff8befa16e6720f9cf54146c9c5e3be9a1258fd910fe55c287f19ad80b8bc1
// SHA256 of artwork generation script: 65301d8425ba637bdb6328a17dbe7440bf1c7f5032879aad4c00bfa09bddf93f

pragma solidity =0.7.6;

import "Ownable.sol";
import "ERC1155.sol";
import "ReentrancyGuard.sol";
import "Address.sol";
import "Strings.sol";

import "RoyaltyDistributor.sol";


// EulerBeats are generative visual & audio art pieces. The recipe and instructions to re-create the visualization and music reside on Ethereum blockchain.
//
// To recreate your art, you will need to retrieve the script
//
//  STEPS TO RETRIEVE THE SCRIPTS:
// - The artwork re-generation script is written in JavaScript, split into pieces, and stored on chain.
// - Query the contract for the scriptCount - this is the number of pieces of the re-genereation script. You will need all of them.
// - Run the getScriptAtIndex method in the EulerBeats smart contract starting with parameter 0, this is will return a transaction hash
// - The "Input Data" field of this transaction contains the first segment of the script. Convert this into UTF-8 format
// - Repeat these last two steps, incrementing the parameter in the getScriptAtIndex method until the number of script segments matches the scrtipCount

contract EulerBeatsV2 is Ownable, ERC1155, ReentrancyGuard, RoyaltyDistributor {
    using SafeMath for uint256;
    using Strings for uint256;
    using Address for address payable;

    /***********************************|
    |        Variables and Events       |
    |__________________________________*/
    // For Mint, mintPrint, and burnPrint: locks the prices
    bool public mintPrintEnabled = false;
    bool public burnPrintEnabled = false;
    bool public mintEnabled = false;
    bool private _contractMintPrintEnabled = false;

    // For metadata (scripts), when locked it is irreversible
    bool private _locked = false;

    // Number of script sections stored
    uint256 public scriptCount = 0;
    // The scripts that can be used to render the NFT (audio and visual)
    mapping (uint256 => string) public scripts;

    // The bit flag to distinguish prints
    uint256 constant public PRINTS_FLAG_BIT = 1;
    // Supply restriction on prints
    uint256 constant public MAX_PRINT_SUPPLY = 160;
    // Supply restriction on seeds/original NFTs
    uint256 constant public MAX_SEEDS_SUPPLY = 27;

    // Total supply of prints and original NFTs
    mapping(uint256 => uint256) public totalSupply;
    // Total number of original NFTs minted
    uint256 public originalsMinted = 0;
    // Funds reserved for burns
    uint256 public reserve = 0;

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    // Constants for bonding curve pricing
    uint256 constant public A = 12;
    uint256 constant public B = 140;
    uint256 constant public C = 100;
    uint256 constant public SIG_DIGITS = 3;

    // Base uri for overriding ERC1155's uri getter
    string internal _baseURI;

    /**
     * @dev Emitted when an original NFT with a new seed is minted
     */
    event MintOriginal(address indexed to, uint256 seed, uint256 indexed originalsMinted);

    /**
     * @dev Emitted when an print is minted
     */
    event PrintMinted(
        address indexed to,
        uint256 id,
        uint256 indexed seed,
        uint256 pricePaid,
        uint256 nextPrintPrice,
        uint256 nextBurnPrice,
        uint256 printsSupply,
        uint256 royaltyPaid,
        uint256 reserve,
        address indexed royaltyRecipient
    );

    /**
     * @dev Emitted when an print is burned
     */
    event PrintBurned(
        address indexed to,
        uint256 id,
        uint256 indexed seed,
        uint256 priceReceived,
        uint256 nextPrintPrice,
        uint256 nextBurnPrice,
        uint256 printsSupply,
        uint256 reserve
    );

    constructor(string memory _name, string memory _symbol, string memory _uri) ERC1155("") {
        name = _name;
        symbol = _symbol;
        _baseURI = _uri;
    }


    /***********************************|
    |        Modifiers                  |
    |__________________________________*/

    modifier onlyWhenMintEnabled() {
        require(mintEnabled, "Minting originals is disabled");
        _;
    }
    modifier onlyWhenMintPrintEnabled() {
        require(mintPrintEnabled, "Minting prints is disabled");
        _;
    }
    modifier onlyWhenBurnPrintEnabled() {
        require(burnPrintEnabled, "Burning prints is disabled");
        _;
    }
    modifier onlyUnlocked() {
        require(!_locked, "Contract is locked");
        _;
    }


    /***********************************|
    |        User Interactions          |
    |__________________________________*/

    /**
     * @dev Function to mint tokens. Not payable for V2, restricted to owner
     */
    function mint() external onlyOwner onlyWhenMintEnabled returns (uint256) {
        uint256 newOriginalsSupply = originalsMinted.add(1);
        require(
            newOriginalsSupply <= MAX_SEEDS_SUPPLY,
            "Max supply reached"
        );

        // The generated seed  == the original nft token id.
        // Both terms are used throughout and refer to the same thing.
        uint256 seed = _generateSeed(newOriginalsSupply);

        // Increment the supply per original nft (max: 1)
        totalSupply[seed] = totalSupply[seed].add(1);
        assert(totalSupply[seed] == 1);

        // Update total originals minted
        originalsMinted = newOriginalsSupply;

        _mint(msg.sender, seed, 1, "");

        emit MintOriginal(msg.sender, seed, newOriginalsSupply);
        return seed;
    }

    /**
     * @dev Function to mint prints from an existing seed. Msg.value must be sufficient.
     * @param seed The NFT id to mint print of
     * @param _owner The current owner of the seed
     */
    function mintPrint(uint256 seed, address payable _owner)
        external
        payable
        onlyWhenMintPrintEnabled
        nonReentrant
        returns (uint256)
    {
        // Confirm id is a seedId and belongs to _owner
        require(isSeedId(seed) == true, "Invalid seed id");

        // Confirm seed belongs to _owner
        require(balanceOf(_owner, seed) == 1, "Incorrect seed owner");

        // Spam-prevention: restrict msg.sender to only external accounts for an initial mintPrint period
        if (msg.sender != tx.origin) {
            require(_contractMintPrintEnabled == true, "Contracts not allowed to mintPrint");
        }

        // Derive print tokenId from seed
        uint256 tokenId = getPrintTokenIdFromSeed(seed);

        // Increment supply to compute current print price
        uint256 newSupply = totalSupply[tokenId].add(1);

        // Confirm newSupply does not exceed max
        require(newSupply <= MAX_PRINT_SUPPLY, "Maximum supply exceeded");

        // Get price to mint the next print
        uint256 printPrice = getPrintPrice(newSupply);
        require(msg.value >= printPrice, "Insufficient funds");

        totalSupply[tokenId] = newSupply;

        // Reserve cut is amount that will go towards reserve for burn at new supply
        uint256 reserveCut = getBurnPrice(newSupply);

        // Update reserve balance
        reserve = reserve.add(reserveCut);

        // Extract % for seed owner from difference between mintPrint cost and amount held for reserve
        uint256 seedOwnerRoyalty = _getSeedOwnerCut(printPrice.sub(reserveCut));

        // Mint token
        _mint(msg.sender, tokenId, 1, "");

        // Disburse royalties
        if (seedOwnerRoyalty > 0) {
          _distributeRoyalty(seed, _owner, seedOwnerRoyalty);
        }

        // If buyer sent extra ETH as padding in case another purchase was made they are refunded
        _refundSender(printPrice);

        emit PrintMinted(msg.sender, tokenId, seed, printPrice, getPrintPrice(newSupply.add(1)), reserveCut, newSupply, seedOwnerRoyalty, reserve, _owner);
        return tokenId;
    }

    /**
     * @dev Function to burn a print
     * @param seed The seed for the print to burn.
     * @param minimumSupply The minimum token supply for burn to succeed, this is a way to set slippage.
     * Set to 1 to allow burn to go through no matter what the price is.
     */
    function burnPrint(uint256 seed, uint256 minimumSupply) external onlyWhenBurnPrintEnabled nonReentrant {
        // Confirm is valid seed id
        require(isSeedId(seed) == true, "Invalid seed id");

        // Derive token Id from seed
        uint256 tokenId = getPrintTokenIdFromSeed(seed);

        // Supply must meet user's minimum threshold
        uint256 oldSupply = totalSupply[tokenId];
        require(oldSupply >= minimumSupply, 'Min supply not met');

        // burnPrice is the amount of ETH returned for burning this print
        uint256 burnPrice = getBurnPrice(oldSupply);
        uint256 newSupply = totalSupply[tokenId].sub(1);
        totalSupply[tokenId] = newSupply;

        // Update reserve balances
        reserve = reserve.sub(burnPrice);

        _burn(msg.sender, tokenId, 1);

        // Disburse funds
        msg.sender.sendValue(burnPrice);

        emit PrintBurned(msg.sender, tokenId, seed, burnPrice, getPrintPrice(oldSupply), getBurnPrice(newSupply), newSupply, reserve);
    }


    /***********************************|
    |   Public Getters - Pricing        |
    |__________________________________*/

    /**
     * @dev Function to get print price
     * @param printNumber the print number of the print Ex. if there are 2 existing prints, and you want to get the
     * next print price, then this should be 3 as you are getting the price to mint the 3rd print
     */
    function getPrintPrice(uint256 printNumber) public pure returns (uint256 price) {
        uint256 decimals = 10 ** SIG_DIGITS;

        // For prints 0-100, exponent value is < 0.001
        if (printNumber <= 100) {
            price = 0;
        } else if (printNumber < B) {
            // 10/A ^ (B - X)
            price = (10 ** ( B.sub(printNumber) )).mul(decimals).div(A ** ( B.sub(printNumber)));
        } else if (printNumber == B) {
            // A/10 ^ 0 == 1
            price = decimals;     // price = decimals * (A ^ 0)
        } else {
            // A/10 ^ (X - B)
            price = (A ** ( printNumber.sub(B) )).mul(decimals).div(10 ** ( printNumber.sub(B) ));
        }
        // += C*X
        price = price.add(C.mul(printNumber));

        // Convert to wei
        price = price.mul(1 ether).div(decimals);
    }

    /**
     * @dev Function to return amount of funds received when burned
     * @param supply the supply of prints before burning. Ex. if there are 2 existing prints, to get the funds
     * receive on burn the supply should be 2
     */
    function getBurnPrice(uint256 supply) public pure returns (uint256 price) {
        uint256 printPrice = getPrintPrice(supply);
        // 84 % of print price
        price = printPrice.mul(84).div(100);
    }

    /**
     * @dev Function to get prices by supply
     * @param supply the supply of prints before burning. Ex. if there are 2 existing prints, to get the funds
     * receive on burn the supply should be 2
     */
    function getPricesBySupply(uint256 supply) public pure returns (uint256 printPrice, uint256 nextPrintPrice, uint256 burnPrice, uint256 nextBurnPrice) {
        printPrice = getPrintPrice(supply);
        nextPrintPrice = getPrintPrice(supply + 1);
        burnPrice = getBurnPrice(supply);
        nextBurnPrice = getBurnPrice(supply + 1);
    }

    /**
     * @dev Function to get prices & supply by seed
     * @param seed The original NFT token id
     */
    function getPricesBySeed(uint256 seed) external view returns (uint256 printPrice, uint256 nextPrintPrice, uint256 burnPrice, uint256 nextBurnPrice, uint256 supply) {
        supply = seedToPrintsSupply(seed);
        (printPrice, nextPrintPrice, burnPrice, nextBurnPrice) = getPricesBySupply(supply);
    }


    /***********************************|
    | Public Getters - Seed + Prints    |
    |__________________________________*/

    /**
     * @dev Get the number of prints minted for the corresponding seed
     * @param seed The original NFT token id
     */
    function seedToPrintsSupply(uint256 seed)
        public
        view
        returns (uint256)
    {
        uint256 tokenId = getPrintTokenIdFromSeed(seed);
        return totalSupply[tokenId];
    }

    /**
     * @dev The token id for the prints contains the original NFT id
     * @param seed The original NFT token id
     */
    function getPrintTokenIdFromSeed(uint256 seed) public pure returns (uint256) {
        return seed | PRINTS_FLAG_BIT;
    }

    /**
     * @dev Return whether a tokenId is for an original
     * @param tokenId The original NFT token id
     */
    function isSeedId(uint256 tokenId) public pure returns (bool) {
        return tokenId & PRINTS_FLAG_BIT != PRINTS_FLAG_BIT;
    }


    /***********************************|
    |   Public Getters - Metadata       |
    |__________________________________*/

    /**
     * @dev Return the script section for a particular index
     * @param index The index of a script section
     */
    function getScriptAtIndex(uint256 index) external view returns (string memory) {
        require(index < scriptCount, "Index out of bounds");
        return scripts[index];
    }

    /**
    * @notice A distinct Uniform Resource Identifier (URI) for a given token.
    * @dev URIs are defined in RFC 3986.
    *      URIs are assumed to be deterministically generated based on token ID
    * @return URI string
    */
    function uri(uint256 _id) external override view returns (string memory) {
        require(totalSupply[_id] > 0, "URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI, _id.toString(), ".json"));
    }


    /***********************************|
    |Internal Functions - Generate Seed |
    |__________________________________*/

    /**
     * @dev Returns a new seed
     * @param uniqueValue Random input for the seed generation
     */
    function _generateSeed(uint256 uniqueValue) internal view returns (uint256) {
        bytes32 hash = keccak256(abi.encodePacked(block.number, blockhash(block.number.sub(1)), msg.sender, uniqueValue));

        // gridLength 0-5
        uint8 gridLength = uint8(hash[0]) % 15;
        if (gridLength > 5) gridLength = 1;

        // horizontalLever 0-58
        uint8 horizontalLever = uint8(hash[1]) % 59;

        // diagonalLever 0-10
        uint8 diagonalLever = uint8(hash[2]) % 11;

        // palette 4 0-11
        uint8 palette = uint8(hash[3]) % 12;

        // innerShape 0-3 with rarity
        uint8 innerShape = uint8(hash[4]) % 4;

        return uint256(gridLength) << 40 | uint256(horizontalLever) << 32 | uint256(diagonalLever) << 24 | uint256(palette) << 16 | uint256(innerShape) << 8;
    }


    /***********************************|
    |  Internal Functions - Prints      |
    |__________________________________*/

    /**
     * @dev Returns the part of the mintPrint fee reserved for the seed owner royalty
     * @param fee Amount of ETH not added to the contract reserve
     */
    function _getSeedOwnerCut(uint256 fee) internal pure returns (uint256) {
        // Seed owner and Treum split royalties 50/50
        return fee.div(2);
    }

    /**
     * @dev For mintPrint only, send remaining msg.value back to sender
     * @param printPrice Cost to mint current print
     */
    function _refundSender(uint256 printPrice) internal {
        if (msg.value.sub(printPrice) > 0) {
            msg.sender.sendValue(msg.value.sub(printPrice));
        }
    }


    /***********************************|
    |        Admin                      |
    |__________________________________*/

    /**
     * @dev Add a new section of the script
     * @param _script String value of script or pointer
     */
    function addScript(string memory _script) external onlyOwner onlyUnlocked {
        scripts[scriptCount] = _script;
        scriptCount = scriptCount.add(1);
    }

    /**
     * @dev Overwrite a script section at a particular index
     * @param _script String value of script or pointer
     * @param index Index of the script to replace
     */
    function updateScript(string memory _script, uint256 index) external onlyOwner onlyUnlocked {
        require(index < scriptCount, "Index out of bounds");
        scripts[index] = _script;
    }

    /**
     * @dev Reset script index to zero, caller must be owner and the contract unlocked
     */
    function resetScriptCount() external onlyOwner onlyUnlocked {
        scriptCount = 0;
    }

    /**
     * @dev Withdraw earned funds from original Nft sales and print fees. Cannot withdraw the reserve funds.
     */
    function withdraw() external onlyOwner nonReentrant {
        uint256 withdrawableFunds = address(this).balance.sub(reserve);
        msg.sender.sendValue(withdrawableFunds);
    }

    /**
     * @dev Function to enable/disable original minting
     * @param enabled The flag to turn minting on or off
     */
    function setMintEnabled(bool enabled) external onlyOwner {
        mintEnabled = enabled;
    }

    /**
     * @dev Function to enable/disable print minting
     * @param enabled The flag to turn minting on or off
     */
    function setMintPrintEnabled(bool enabled) external onlyOwner {
        mintPrintEnabled = enabled;
    }

    /**
     * @dev Function to enable/disable print burning
     * @param enabled The flag to turn minting on or off
     */
    function setBurnPrintEnabled(bool enabled) external onlyOwner {
        burnPrintEnabled = enabled;
    }

    /**
     * @dev Function to enable/disable print minting via contract
     * @param enabled The flag to turn contract print minting on or off
     */
    function setContractMintPrintEnabled(bool enabled) external onlyOwner {
        _contractMintPrintEnabled = enabled;
    }

    /**
     * @dev Function to lock/unlock the on-chain metadata
     * @param locked The flag turn locked on
     */
    function setLocked(bool locked) external onlyOwner onlyUnlocked {
        _locked = locked;
    }

    /**
     * @dev Function to update the base _uri for all tokens
     * @param newuri The base uri string
     */
    function setURI(string memory newuri) external onlyOwner {
        _baseURI = newuri;
    }
}