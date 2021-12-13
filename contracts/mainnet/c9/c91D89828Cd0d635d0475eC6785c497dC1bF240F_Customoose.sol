// contracts/CustoMoose.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IToken.sol";
import "./Library.sol";
import "./TraitLibrary.sol";
import "./BytesLib.sol";

contract Customoose is ERC721Enumerable, Ownable {
    using BytesLib for bytes;
    using SafeMath for uint256;
    using Library for uint8;

    //Mappings
    mapping(uint256 => string) internal tokenIdToConfig;
    mapping(uint256 => uint256) internal tokenIdToStoredTrax;

    //uint256s
    uint256 MAX_SUPPLY = 10000;
    uint256 MINTS_PER_TIER = 1000;

    uint256 MINT_START = 1639418400;
    uint256 MINT_START_ETH = MINT_START.add(86400);

    uint256 MINT_DELAY = 43200;
    uint256 START_PRICE = 70000000000000000;
    uint256 MIN_PRICE = 20000000000000000;
    uint256 PRICE_DIFF = 5000000000000000;

    uint256 START_PRICE_TRAX = 10000000000000000000;
    uint256 PRICE_DIFF_TRAX = 10000000000000000000;

    //address
    address public mooseAddress;
    address public traxAddress;
    address public libraryAddress;
    address _owner;

    constructor(address _mooseAddress, address _traxAddress, address _libraryAddress) ERC721("Frame", "FRAME") {
        _owner = msg.sender;
        setMooseAddress(_mooseAddress);
        setTraxAddress(_traxAddress);
        setLibraryAddress(_libraryAddress);

        // test mint
        mintInternal();
    }

    /*
  __  __ _     _   _             ___             _   _             
 |  \/  (_)_ _| |_(_)_ _  __ _  | __|  _ _ _  __| |_(_)___ _ _  ___
 | |\/| | | ' \  _| | ' \/ _` | | _| || | ' \/ _|  _| / _ \ ' \(_-<
 |_|  |_|_|_||_\__|_|_||_\__, | |_| \_,_|_||_\__|\__|_\___/_||_/__/
                         |___/                                     
   */

    /**
     * @dev Generates an 8 digit config
     */
    function config() internal pure returns (string memory) {
        // This will generate an 9 character string.
        // All of them will start as 0
        string memory currentConfig = "000000000";
        return currentConfig;
    }

    /**
     * @dev Mint internal, this is to avoid code duplication.
     */
    function mintInternal() internal returns (uint256 tokenId) {
        uint256 _totalSupply = totalSupply();
        require(_totalSupply < MAX_SUPPLY);
        require(!Library.isContract(msg.sender));

        uint256 thisTokenId = _totalSupply;

        tokenIdToConfig[thisTokenId] = config();
        tokenIdToStoredTrax[thisTokenId] = 0;
        _mint(msg.sender, thisTokenId);
        return thisTokenId;
    }

    /**
     * @dev Mints new frame using TRAX
     */
    function mintFrameWithTrax(uint8 _times) public {
        require(block.timestamp >= MINT_START, "Minting has not started");
        uint256 allowance = IToken(traxAddress).allowance(msg.sender, address(this));
        require(allowance >= _times * getMintPriceTrax(), "Check the token allowance");

        IToken(traxAddress).burnFrom(msg.sender, _times * getMintPriceTrax());
        for(uint256 i=0; i< _times; i++){
            mintInternal();
        }
    }

    /**
     * @dev Mints new frame using ETH
     */
    function mintFrameWithEth(uint8 _times) public payable {
        require(block.timestamp >= MINT_START_ETH, "Minting for ETH has not started");
        require((_times > 0 && _times <= 20));
        require(msg.value >= _times * getMintPriceEth());

        for(uint256 i=0; i< _times; i++){
            mintInternal();
        }
    }

    /**
     * @dev Mints new frame with customizations using ETH
     */
    function mintCustomooseWithEth(string memory tokenConfig) public payable {
        require(block.timestamp >= MINT_START_ETH, "Minting for ETH has not started");
        require(msg.value >= getMintPriceEth(), "Not enough ETH");

        uint256 tokenId = mintInternal();
        setTokenConfig(tokenId, tokenConfig);
    }

    /**
     * @dev Mints new frame with customizations using TRAX
     */
    function mintCustomooseWithTrax(string memory tokenConfig) public payable {
        require(block.timestamp >= MINT_START, "Minting has not started");
        uint256 allowance = IToken(traxAddress).allowance(msg.sender, address(this));
        require(allowance >= getMintPriceTrax(), "Check the token allowance");

        IToken(traxAddress).burnFrom(msg.sender, getMintPriceTrax());
        uint256 tokenId = mintInternal();
        setTokenConfig(tokenId, tokenConfig);
    }

    /**
     * @dev Burns a frame and returns TRAX
     */
    function burnFrameForTrax(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender);

        //Burn token
        _transfer(
            msg.sender,
            0x000000000000000000000000000000000000dEaD,
            _tokenId
        );

        //Return the TRAX
        IToken(traxAddress).transfer(
            msg.sender,
            tokenIdToStoredTrax[_tokenId]
        );
    }

    /**
     * @dev Sets a trait for a token
     */
    function setTokenTrait(uint256 _tokenId, uint8 _traitIndex, uint8 _traitValue) public onlyOwner {
        string memory tokenConfig = tokenIdToConfig[_tokenId];
        string memory newTokenConfig = Library.stringReplace(tokenConfig, _traitIndex, Library.toString(_traitValue));

        tokenIdToConfig[_tokenId] = newTokenConfig;
    }

    /**
     * @dev Sets the config for a token
     */
    function setTokenConfig(uint256 _tokenId, string memory _newConfig) public {
        require(keccak256(abi.encodePacked(tokenIdToConfig[_tokenId])) !=
            keccak256(abi.encodePacked(_newConfig)), "Config must be different");

        uint256 allowance = IToken(traxAddress).allowance(msg.sender, address(this));
        (uint256 price, uint256 valueDiff, bool valueIncreased) = getCustomizationPrice(_tokenId, _newConfig);
        uint256 balance = IToken(traxAddress).balanceOf(msg.sender);
        require(allowance >= price, "Check the token allowance");
        require(balance >= price, "You need more TRAX");

        if(valueDiff >= 0 && valueIncreased) {
            IToken(traxAddress).transferFrom(
                msg.sender,
                address(this),
                valueDiff
            );
            IToken(traxAddress).burnFrom(msg.sender, price.sub(valueDiff));
            tokenIdToStoredTrax[_tokenId] += valueDiff;
        } else if(valueDiff >= 0 && !valueIncreased) {
            tokenIdToStoredTrax[_tokenId] -= valueDiff;
        }
        tokenIdToConfig[_tokenId] = _newConfig;
    }

    /**
     * @dev Takes an array of trait changes and gets the new config
     */
    function getNewTokenConfig(uint256 _tokenId, uint8[2][] calldata _newTraits)
        public
        view
        returns (string memory)
    {
        string memory tokenConfig = tokenIdToConfig[_tokenId];
        
        string memory newTokenConfig = tokenConfig;
        for (uint8 i = 0; i < _newTraits.length; i++) {
            string memory newTraitValue = Library.toString(_newTraits[i][1]);
            newTokenConfig = Library.stringReplace(newTokenConfig, _newTraits[i][0], newTraitValue);
        }
        return (newTokenConfig);
    }

    /**
     * @dev Gets the price of a newly minted frame
     */
    function getMintCustomizationPrice(string memory _newConfig)
        public
        view
        returns (uint256 price)
    {
        price = 0;
        for (uint8 i = 0; i < 9; i++) {
            uint8 traitValue = convertInt(bytes(_newConfig).slice(i, 1).toUint8(0));
            uint256 traitPrice = TraitLibrary(libraryAddress).getPrice(i, traitValue);
            price = price.add(traitPrice);
        }

        price = price.mul(10**16);
        return price;
    }

    /**
     * @dev Gets the price given a tokenId and new config
     */
    function getCustomizationPrice(uint256 _tokenId, string memory _newConfig)
        public
        view
        returns (uint256 price, uint256 valueDiff, bool increased)
    {
        string memory tokenConfig = tokenIdToConfig[_tokenId];
        uint256 currentValue = tokenIdToStoredTrax[_tokenId];
        
        price = 0;
        uint256 futureValue = 0;
        for (uint8 i = 0; i < 9; i++) {
            uint8 traitValue = convertInt(bytes(_newConfig).slice(i, 1).toUint8(0));
            uint256 traitPrice = TraitLibrary(libraryAddress).getPrice(i, traitValue);
            bool isChanged = keccak256(abi.encodePacked(bytes(tokenConfig).slice(i, 1))) !=
                keccak256(abi.encodePacked(bytes(_newConfig).slice(i, 1)));

            futureValue = futureValue.add(traitPrice);
            if(isChanged) {
                price = price.add(traitPrice);
            }
        }

        price = price.mul(10**16);
        futureValue = futureValue.mul(10**16).div(100).mul(80);
        if(futureValue == currentValue) {
            valueDiff = 0;
            increased = true;
        } else if(futureValue > currentValue) {
            valueDiff = futureValue.sub(currentValue);
            increased = true;
        } else {
            valueDiff = currentValue.sub(futureValue);
            increased = false;
        }

        return (price, valueDiff, increased);
    }

    /**
     * @dev Gets the price of a specified trait
     */
    function getTraitPrice(uint256 typeIndex, uint256 nameIndex)
        public
        view
        returns (uint256 traitPrice)
    {
        traitPrice = TraitLibrary(libraryAddress).getPrice(typeIndex, nameIndex);
        return traitPrice;
    }

    /**
     * @dev Gets the current mint price in ETH for a new frame
     */
    function getMintPriceEth()
        public
        view
        returns (uint256 price)
    {
        if(block.timestamp < MINT_START_ETH) {
            return START_PRICE;
        }

        uint256 _mintTiersComplete = block.timestamp.sub(MINT_START_ETH).div(MINT_DELAY);
        if(PRICE_DIFF.mul(_mintTiersComplete) >= START_PRICE.sub(MIN_PRICE)) {
            return MIN_PRICE;
        } else {
            return START_PRICE - (PRICE_DIFF * _mintTiersComplete);
        }
    }

    /**
     * @dev Gets the current mint price in TRAX for a new frame
     */
    function getMintPriceTrax()
        public
        view
        returns (uint256 price)
    {
        uint256 _totalSupply = totalSupply();

        if(_totalSupply == 0) return START_PRICE_TRAX;

        uint256 _mintTiersComplete = _totalSupply.div(MINTS_PER_TIER);
        price = START_PRICE_TRAX.add(_mintTiersComplete.mul(PRICE_DIFF_TRAX));
        return price;
    }

    /*
 ____     ___   ____  ___        _____  __ __  ____     __ ______  ____  ___   ____   _____
|    \   /  _] /    ||   \      |     ||  |  ||    \   /  ]      ||    |/   \ |    \ / ___/
|  D  ) /  [_ |  o  ||    \     |   __||  |  ||  _  | /  /|      | |  ||     ||  _  (   \_ 
|    / |    _]|     ||  D  |    |  |_  |  |  ||  |  |/  / |_|  |_| |  ||  O  ||  |  |\__  |
|    \ |   [_ |  _  ||     |    |   _] |  :  ||  |  /   \_  |  |   |  ||     ||  |  |/  \ |
|  .  \|     ||  |  ||     |    |  |   |     ||  |  \     | |  |   |  ||     ||  |  |\    |
|__|\_||_____||__|__||_____|    |__|    \__,_||__|__|\____| |__|  |____|\___/ |__|__| \___|
                                                                                           
*/

    /**
     * @dev Convert a raw assembly int value to a pixel location
     */
    function convertInt(uint8 _inputInt)
        internal
        pure
        returns (uint8)
    {
        if (
            (_inputInt >= 48) &&
            (_inputInt <= 57)
        ) {
            _inputInt -= 48;
            return _inputInt;
        } else {
            _inputInt -= 87;
            return _inputInt;

        }
    }

    /**
     * @dev Config to SVG function
     */
    function configToSVG(string memory _config)
        public
        view
        returns (string memory)
    {
        string memory svgString;

        for (uint8 i = 0; i < 9; i++) {
            uint8 thisTraitIndex = convertInt(bytes(_config).slice(i, 1).toUint8(0));
            bytes memory traitRects = TraitLibrary(libraryAddress).getRects(i, thisTraitIndex);

            if(bytes(traitRects).length == 0) continue;
            bool isRow = traitRects.slice(0, 1).equal(bytes("r"));

            uint16 j = 1;
            string memory thisColor = "";
            bool newColor = true;
            while(j < bytes(traitRects).length)
            {
                if(newColor) {
                    // get the color
                    thisColor = string(traitRects.slice(j, 3));
                    j += 3;
                    newColor = false;
                    continue;
                } else {
                    // if pipe, new color
                    if (
                        traitRects.slice(j, 1).equal(bytes("|"))
                    ) {
                        newColor = true;
                        j += 1;
                        continue;
                    } else {
                        // else add rects
                        bytes memory thisRect = traitRects.slice(j, 3);

                        uint8 x = convertInt(thisRect.slice(0, 1).toUint8(0));
                        uint8 y = convertInt(thisRect.slice(1, 1).toUint8(0));
                        uint8 length = convertInt(thisRect.slice(2, 1).toUint8(0)) + 1;

                        if(isRow) {
                            svgString = string(
                                abi.encodePacked(
                                    svgString,
                                    "<rect class='c",
                                    thisColor,
                                    "' x='",
                                    x.toString(),
                                    "' y='",
                                    y.toString(),
                                    "' width='",
                                    length.toString(),
                                    "px' height='1px'",
                                    "/>"
                                )
                            );
                            j += 3;
                            continue;
                        } else {
                            svgString = string(
                                abi.encodePacked(
                                    svgString,
                                    "<rect class='c",
                                    thisColor,
                                    "' x='",
                                    x.toString(),
                                    "' y='",
                                    y.toString(),
                                    "' height='",
                                    length.toString(),
                                    "px' width='1px'",
                                    "/>"
                                )
                            );
                            j += 3;
                            continue;
                        }
                    }
                }
            }
        }

        svgString = string(
            abi.encodePacked(
                '<svg id="moose-svg" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 32 32">',
                svgString,
                "<style>rect.bg{width:32px;height:32px;} #moose-svg{shape-rendering: crispedges;}",
                TraitLibrary(libraryAddress).getColors(),
                "</style></svg>"
            )
        );

        return svgString;
    }

    /**
     * @dev Config to metadata function
     */
    function configToMetadata(string memory _config)
        public
        view
        returns (string memory)
    {
        string memory metadataString;

        for (uint8 i = 0; i < 9; i++) {
            uint8 thisTraitIndex = convertInt(bytes(_config).slice(i, 1).toUint8(0));

            (string memory traitName, string memory traitType) = TraitLibrary(libraryAddress).getTraitInfo(i, thisTraitIndex);
            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"',
                    traitType,
                    '","value":"',
                    traitName,
                    '"}'
                )
            );

            if (i != 8)
                metadataString = string(abi.encodePacked(metadataString, ","));
        }

        return string(abi.encodePacked("[", metadataString, "]"));
    }

    /**
     * @dev Returns the SVG and metadata for a token Id
     * @param _tokenId The tokenId to return the SVG and metadata for.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId));

        string memory tokenConfig = _tokenIdToConfig(_tokenId);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Library.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "FRAME Edition 0, Token #',
                                    Library.toString(_tokenId),
                                    '", "description": "FRAME tokens are fully customizable on-chain pixel art. Edition 0 is a collection of 32x32 Moose avatars.", "image": "data:image/svg+xml;base64,',
                                    Library.encode(
                                        bytes(configToSVG(tokenConfig))
                                    ),
                                    '","attributes":',
                                    configToMetadata(tokenConfig),
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    /**
     * @dev Returns a config for a given tokenId
     * @param _tokenId The tokenId to return the config for.
     */
    function _tokenIdToConfig(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        string memory tokenConfig = tokenIdToConfig[_tokenId];
        return tokenConfig;
    }

    /**
     * @dev Returns the current amount of TRAX stored for a given tokenId
     * @param _tokenId The tokenId to look up.
     */
    function _tokenIdToStoredTrax(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        uint256 storedTrax = tokenIdToStoredTrax[_tokenId];
        return storedTrax;
    }

    /**
     * @dev Returns the wallet of a given wallet. Mainly for ease for frontend devs.
     * @param _wallet The wallet to get the tokens of.
     */
    function walletOfOwner(address _wallet)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_wallet);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokensId;
    }

    /*
  ___   __    __  ____     ___  ____       _____  __ __  ____     __ ______  ____  ___   ____   _____
 /   \ |  |__|  ||    \   /  _]|    \     |     ||  |  ||    \   /  ]      ||    |/   \ |    \ / ___/
|     ||  |  |  ||  _  | /  [_ |  D  )    |   __||  |  ||  _  | /  /|      | |  ||     ||  _  (   \_ 
|  O  ||  |  |  ||  |  ||    _]|    /     |  |_  |  |  ||  |  |/  / |_|  |_| |  ||  O  ||  |  |\__  |
|     ||  `  '  ||  |  ||   [_ |    \     |   _] |  :  ||  |  /   \_  |  |   |  ||     ||  |  |/  \ |
|     | \      / |  |  ||     ||  .  \    |  |   |     ||  |  \     | |  |   |  ||     ||  |  |\    |
 \___/   \_/\_/  |__|__||_____||__|\_|    |__|    \__,_||__|__|\____| |__|  |____|\___/ |__|__| \___|
                                                                                                     
    */

    /**
     * @dev Sets the ERC721 token address
     * @param _mooseAddress The NFT address
     */

    function setMooseAddress(address _mooseAddress) public onlyOwner {
        mooseAddress = _mooseAddress;
    }

    /**
     * @dev Sets the ERC20 token address
     * @param _traxAddress The token address
     */

    function setTraxAddress(address _traxAddress) public onlyOwner {
        traxAddress = _traxAddress;
    }

   /**
     * @dev Sets the trait library address
     * @param _libraryAddress The token address
     */

    function setLibraryAddress(address _libraryAddress) public onlyOwner {
        libraryAddress = _libraryAddress;
    }

    /**
     * @dev Withdraw ETH to owner
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Library.sol";

contract TraitLibrary is Ownable {
    using Library for uint16;

    struct Trait {
        string traitName;
        string traitType;
        string rects;
        uint32 price;
    }

    //addresses
    address _owner;

    //uint arrays
    uint32[][9] PRICES;

    //byte arrays
    bytes[9] TYPES;
    bytes[][9] NAMES;
    bytes[][9] RECTS;
    bytes COLORS;

    constructor() {
        _owner = msg.sender;

        // Declare initial values
        TYPES = [
                bytes("background"),
                bytes("body"),
                bytes("eye"),
                bytes("antler"),
                bytes("hat"),
                bytes("neck"),
                bytes("mouth"),
                bytes("nose"),
                bytes("accessory")
        ];

        PRICES[0] = [0];
        PRICES[1] = [0];
        PRICES[2] = [0];
        PRICES[3] = [0];
        PRICES[4] = [0];
        PRICES[5] = [0];
        PRICES[6] = [0];
        PRICES[7] = [0];
        PRICES[8] = [0];

        NAMES[0] = [
                bytes("")
        ];
            

        NAMES[1] = [
                bytes("")
        ];
            

        NAMES[2] = [
                bytes("")
        ];
            

        NAMES[3] = [
                bytes("")
        ];
            

        NAMES[4] = [
                bytes("")
        ];
            

        NAMES[5] = [
                bytes("")
        ];
            

        NAMES[6] = [
                bytes("")
        ];
            

        NAMES[7] = [
                bytes("")
        ];
            

        NAMES[8] = [
                bytes("")
        ];
            

        RECTS[0] = [
                bytes("")
        ];

        RECTS[1] = [
                bytes("")
        ];

        RECTS[2] = [
                bytes("")
        ];

        RECTS[3] = [
                bytes("")
        ];

        RECTS[4] = [
                bytes("")
        ];
            
        RECTS[5] = [
                bytes("")

        ];
            
        RECTS[6] = [
                bytes("")

        ];

        RECTS[7] = [
                bytes("")
        ];

        RECTS[8] = [
                bytes("")
        ];
    }

    /**
     * @dev Gets the rects a trait from storage
     * @param traitIndex The trait type index
     * @param traitValue The location within the array
     */

    function getRects(uint256 traitIndex, uint256 traitValue)
        public
        view
        returns (bytes memory rects)
    {
        // return string(abi.encodePacked(RECTS[traitIndex][traitValue]));
        return RECTS[traitIndex][traitValue];
    }

    /**
     * @dev Gets a trait from storage
     * @param traitIndex The trait type index
     * @param traitValue The location within the array
     */

    function getTraitInfo(uint256 traitIndex, uint256 traitValue)
        public
        view
        returns (string memory traitName, string memory traitType)
    {
        return (
            string(abi.encodePacked(NAMES[traitIndex][traitValue])),
            string(abi.encodePacked(TYPES[traitIndex]))
        );
    }

    /**
     * @dev Gets the price of a trait from storage
     * @param traitIndex The trait type index
     * @param traitValue The location within the array
     */

    function getPrice(uint256 traitIndex, uint256 traitValue)
        public
        view
        returns (uint32 price)
    {
        return PRICES[traitIndex][traitValue];
    }

    /**
     * @dev Adds entries to trait metadata
     * @param _traitTypeIndex The trait type index
     * @param traits Array of traits to add
     */

    function addTraits(uint256 _traitTypeIndex, Trait[] memory traits)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < traits.length; i++) {
            PRICES[_traitTypeIndex].push(traits[i].price);
            NAMES[_traitTypeIndex].push(bytes(abi.encodePacked(traits[i].traitName)));
            RECTS[_traitTypeIndex].push(bytes(abi.encodePacked(traits[i].rects)));
        }

        return;
    }

    /**
     * @dev Clear entries to trait metadata
     * @param _traitTypeIndex The trait type index
     */

    function clearTrait(uint256 _traitTypeIndex)
        public
        onlyOwner
    {
        PRICES[_traitTypeIndex] = [0];
        NAMES[_traitTypeIndex] = [bytes("")];
        RECTS[_traitTypeIndex] = [bytes("")];
        return;
    }


   /**
     * @dev Gets the color string
     */

    function getColors()
        public
        pure
        returns (string memory colors)
    {
        return ".c000{fill:#000000}.c001{fill:#000008}.c002{fill:#00000a}.c003{fill:#00000b}.c004{fill:#000101}.c005{fill:#000202}.c006{fill:#001efd}.c007{fill:#001eff}.c008{fill:#002259}.c009{fill:#005189}.c010{fill:#006bff}.c011{fill:#008544}.c012{fill:#00881d}.c013{fill:#00aa0c}.c014{fill:#00b09e}.c015{fill:#00b4ff}.c016{fill:#00c7f1}.c017{fill:#00eaff}.c018{fill:#010000}.c019{fill:#010001}.c020{fill:#010101}.c021{fill:#017db1}.c022{fill:#020100}.c023{fill:#020202}.c024{fill:#022d00}.c025{fill:#024d01}.c026{fill:#02b4da}.c027{fill:#030202}.c028{fill:#030303}.c029{fill:#035223}.c030{fill:#040303}.c031{fill:#040309}.c032{fill:#0456c7}.c033{fill:#050505}.c034{fill:#051429}.c035{fill:#051c3e}.c036{fill:#060405}.c037{fill:#060605}.c038{fill:#070404}.c039{fill:#070707}.c040{fill:#080500}.c041{fill:#080604}.c042{fill:#080808}.c043{fill:#0879df}.c044{fill:#0904eb}.c045{fill:#090500}.c046{fill:#09897b}.c047{fill:#09f200}.c048{fill:#0a0a0a}.c049{fill:#0a0e13}.c050{fill:#0ad200}.c051{fill:#0b0907}.c052{fill:#0b0a09}.c053{fill:#0b0b0b}.c054{fill:#0b7b08}.c055{fill:#0b87f7}.c056{fill:#0b8f08}.c057{fill:#0d031e}.c058{fill:#0d0c0d}.c059{fill:#0d0d0d}.c060{fill:#0e0603}.c061{fill:#0e09c5}.c062{fill:#0e0d0d}.c063{fill:#0e0e0e}.c064{fill:#0f0602}.c065{fill:#0f095e}.c066{fill:#0f09f9}.c067{fill:#100603}.c068{fill:#101010}.c069{fill:#104b01}.c070{fill:#106ae7}.c071{fill:#107a46}.c072{fill:#1098b8}.c073{fill:#110502}.c074{fill:#110968}.c075{fill:#121111}.c076{fill:#131313}.c077{fill:#141414}.c078{fill:#141515}.c079{fill:#146b00}.c080{fill:#150f2d}.c081{fill:#156103}.c082{fill:#161616}.c083{fill:#17f4dd}.c084{fill:#18120a}.c085{fill:#182257}.c086{fill:#18371e}.c087{fill:#1a0db0}.c088{fill:#1a0eac}.c089{fill:#1c31c9}.c090{fill:#1d0ed1}.c091{fill:#1e1300}.c092{fill:#1e1b1c}.c093{fill:#1e1d1c}.c094{fill:#1f170d}.c095{fill:#2110ec}.c096{fill:#212121}.c097{fill:#215a36}.c098{fill:#231e1e}.c099{fill:#232222}.c100{fill:#252627}.c101{fill:#25b5f8}.c102{fill:#262929}.c103{fill:#272321}.c104{fill:#27ec0d}.c105{fill:#281900}.c106{fill:#29050a}.c107{fill:#299b01}.c108{fill:#2b3635}.c109{fill:#2c2729}.c110{fill:#2c27f3}.c111{fill:#2c2a28}.c112{fill:#2d130c}.c113{fill:#2e2113}.c114{fill:#2e260d}.c115{fill:#2e47ff}.c116{fill:#2e6a4b}.c117{fill:#2e9e40}.c118{fill:#2f0041}.c119{fill:#313021}.c120{fill:#323333}.c121{fill:#332eec}.c122{fill:#333a02}.c123{fill:#349d92}.c124{fill:#353537}.c125{fill:#364643}.c126{fill:#372014}.c127{fill:#372501}.c128{fill:#3a4703}.c129{fill:#3c2402}.c130{fill:#3d1005}.c131{fill:#3d301d}.c132{fill:#3d320e}.c133{fill:#3e383a}.c134{fill:#3e3e3e}.c135{fill:#3f3fed}.c136{fill:#3f4c03}.c137{fill:#410000}.c138{fill:#412ce5}.c139{fill:#422de5}.c140{fill:#424244}.c141{fill:#425c5a}.c142{fill:#435303}.c143{fill:#436060}.c144{fill:#448f61}.c145{fill:#44d0e6}.c146{fill:#451a08}.c147{fill:#464b64}.c148{fill:#473f42}.c149{fill:#47ffee}.c150{fill:#482e20}.c151{fill:#484a4a}.c152{fill:#494334}.c153{fill:#4a443f}.c154{fill:#4a4aff}.c155{fill:#4b1e0b}.c156{fill:#4b4545}.c157{fill:#4b4643}.c158{fill:#4b4a05}.c159{fill:#4c4c4c}.c160{fill:#4c8020}.c161{fill:#4d3b4d}.c162{fill:#4d4c48}.c163{fill:#4d5466}.c164{fill:#4f3533}.c165{fill:#4f4f51}.c166{fill:#4f5049}.c167{fill:#503820}.c168{fill:#504c47}.c169{fill:#513222}.c170{fill:#516d63}.c171{fill:#518d3c}.c172{fill:#520169}.c173{fill:#534016}.c174{fill:#535254}.c175{fill:#535556}.c176{fill:#535e9c}.c177{fill:#54ccff}.c178{fill:#554c4f}.c179{fill:#55aa48}.c180{fill:#564c4e}.c181{fill:#580002}.c182{fill:#582f19}.c183{fill:#585341}.c184{fill:#585858}.c185{fill:#595a5a}.c186{fill:#5a3200}.c187{fill:#5a5a5b}.c188{fill:#5a5a5c}.c189{fill:#5a9346}.c190{fill:#5c311a}.c191{fill:#5c5115}.c192{fill:#5c5a5b}.c193{fill:#5c8e8c}.c194{fill:#5d1d0c}.c195{fill:#5e341f}.c196{fill:#5e3700}.c197{fill:#5e5e5e}.c198{fill:#5fa551}.c199{fill:#604b31}.c200{fill:#614327}.c201{fill:#615c3c}.c202{fill:#624c3f}.c203{fill:#625e40}.c204{fill:#626262}.c205{fill:#632b1c}.c206{fill:#63564a}.c207{fill:#63605c}.c208{fill:#654f21}.c209{fill:#6574a4}.c210{fill:#6593eb}.c211{fill:#676767}.c212{fill:#684a11}.c213{fill:#686868}.c214{fill:#69ac0f}.c215{fill:#69bf9c}.c216{fill:#6a0500}.c217{fill:#6b3d02}.c218{fill:#6ba6db}.c219{fill:#6c0104}.c220{fill:#6d6949}.c221{fill:#6da25a}.c222{fill:#6e3421}.c223{fill:#6e6d6d}.c224{fill:#6f0809}.c225{fill:#700b00}.c226{fill:#707070}.c227{fill:#70c4ce}.c228{fill:#716e70}.c229{fill:#725e15}.c230{fill:#727877}.c231{fill:#72daff}.c232{fill:#737373}.c233{fill:#73b95a}.c234{fill:#73cd46}.c235{fill:#74bf2d}.c236{fill:#757575}.c237{fill:#75daf2}.c238{fill:#774000}.c239{fill:#775e07}.c240{fill:#776d6d}.c241{fill:#787e91}.c242{fill:#7b6c48}.c243{fill:#7d0600}.c244{fill:#7e0310}.c245{fill:#7e4002}.c246{fill:#7f4121}.c247{fill:#7f5203}.c248{fill:#807f7f}.c249{fill:#816f6f}.c250{fill:#824903}.c251{fill:#82682f}.c252{fill:#830316}.c253{fill:#83eceb}.c254{fill:#840915}.c255{fill:#848484}.c256{fill:#848999}.c257{fill:#850500}.c258{fill:#850915}.c259{fill:#858585}.c260{fill:#85db67}.c261{fill:#868787}.c262{fill:#87b037}.c263{fill:#880198}.c264{fill:#8ae586}.c265{fill:#8b4b00}.c266{fill:#8c170c}.c267{fill:#8c898b}.c268{fill:#8cbb2f}.c269{fill:#8d0015}.c270{fill:#8e23f2}.c271{fill:#8e5345}.c272{fill:#8e5900}.c273{fill:#8e5c00}.c274{fill:#8e7a16}.c275{fill:#8f6948}.c276{fill:#915e3c}.c277{fill:#916302}.c278{fill:#919191}.c279{fill:#920505}.c280{fill:#929192}.c281{fill:#930900}.c282{fill:#94910c}.c283{fill:#952318}.c284{fill:#95d8f5}.c285{fill:#96a3b1}.c286{fill:#974c0e}.c287{fill:#977730}.c288{fill:#989898}.c289{fill:#99ceec}.c290{fill:#9b0413}.c291{fill:#9b0993}.c292{fill:#9b3e00}.c293{fill:#9b8301}.c294{fill:#9c5582}.c295{fill:#9c8a22}.c296{fill:#9d7b10}.c297{fill:#9d8664}.c298{fill:#9eaecd}.c299{fill:#9ecfbe}.c300{fill:#9f0206}.c301{fill:#9f4c85}.c302{fill:#9fdcf7}.c303{fill:#a0a0a2}.c304{fill:#a0e066}.c305{fill:#a163a0}.c306{fill:#a17a01}.c307{fill:#a25201}.c308{fill:#a26adc}.c309{fill:#a27f08}.c310{fill:#a29da0}.c311{fill:#a37909}.c312{fill:#a3a3a3}.c313{fill:#a50001}.c314{fill:#a50311}.c315{fill:#a50f10}.c316{fill:#a642b6}.c317{fill:#a67b0d}.c318{fill:#a6d5c5}.c319{fill:#a7a3a6}.c320{fill:#a8895d}.c321{fill:#a8b1a8}.c322{fill:#aa7d54}.c323{fill:#abaaa6}.c324{fill:#ae8f6b}.c325{fill:#af0101}.c326{fill:#af5803}.c327{fill:#af8719}.c328{fill:#afe3fa}.c329{fill:#b00101}.c330{fill:#b0acac}.c331{fill:#b0acaf}.c332{fill:#b1b1b1}.c333{fill:#b20000}.c334{fill:#b2272b}.c335{fill:#b3362a}.c336{fill:#b40909}.c337{fill:#b4b0aa}.c338{fill:#b51f17}.c339{fill:#b58f6d}.c340{fill:#b69012}.c341{fill:#b6b6b7}.c342{fill:#b6eaff}.c343{fill:#b709be}.c344{fill:#b7875c}.c345{fill:#b7905a}.c346{fill:#b8b9b9}.c347{fill:#b9263d}.c348{fill:#ba0010}.c349{fill:#ba9a04}.c350{fill:#bc1622}.c351{fill:#bc2e2e}.c352{fill:#bea101}.c353{fill:#c06c00}.c354{fill:#c0834d}.c355{fill:#c1bcbc}.c356{fill:#c20417}.c357{fill:#c29f01}.c358{fill:#c32a1c}.c359{fill:#c3762a}.c360{fill:#c3a812}.c361{fill:#c4b299}.c362{fill:#c504a9}.c363{fill:#c5c8c9}.c364{fill:#c80409}.c365{fill:#c900cb}.c366{fill:#cad0c9}.c367{fill:#cc3443}.c368{fill:#cccccc}.c369{fill:#ccced1}.c370{fill:#cd7079}.c371{fill:#cda601}.c372{fill:#cda65d}.c373{fill:#cdc3c3}.c374{fill:#cdcfd2}.c375{fill:#cdd0d2}.c376{fill:#cebd22}.c377{fill:#cfcfcf}.c378{fill:#cfd0d0}.c379{fill:#d08507}.c380{fill:#d095f5}.c381{fill:#d15b2b}.c382{fill:#d20000}.c383{fill:#d22121}.c384{fill:#d27935}.c385{fill:#d27dd4}.c386{fill:#d2b52a}.c387{fill:#d31017}.c388{fill:#d4a0f7}.c389{fill:#d4cd16}.c390{fill:#d59702}.c391{fill:#d5d5d5}.c392{fill:#d5ff84}.c393{fill:#d6b19f}.c394{fill:#d6d6d6}.c395{fill:#d70101}.c396{fill:#d7b2a0}.c397{fill:#d7b943}.c398{fill:#d8d85c}.c399{fill:#d8d8d8}.c400{fill:#d9b3fa}.c401{fill:#d9c6ab}.c402{fill:#db0d0d}.c403{fill:#db5c0f}.c404{fill:#dbb348}.c405{fill:#dbecf2}.c406{fill:#dd2a2a}.c407{fill:#dd3ea3}.c408{fill:#dd4638}.c409{fill:#dedede}.c410{fill:#dfba39}.c411{fill:#e08811}.c412{fill:#e1ebff}.c413{fill:#e25245}.c414{fill:#e26012}.c415{fill:#e27a04}.c416{fill:#e3c0b4}.c417{fill:#e3e3e3}.c418{fill:#e3edff}.c419{fill:#e3f1ff}.c420{fill:#e45526}.c421{fill:#e4c6bc}.c422{fill:#e4d954}.c423{fill:#e4effe}.c424{fill:#e504e7}.c425{fill:#e5b53b}.c426{fill:#e5c688}.c427{fill:#e5e5e5}.c428{fill:#e60e0e}.c429{fill:#e6de04}.c430{fill:#e812f5}.c431{fill:#e870d2}.c432{fill:#e92828}.c433{fill:#e936a8}.c434{fill:#e9392d}.c435{fill:#e9fadf}.c436{fill:#ea8700}.c437{fill:#eb362d}.c438{fill:#eba3ba}.c439{fill:#ebacc0}.c440{fill:#ebf4f7}.c441{fill:#ec2eab}.c442{fill:#ece401}.c443{fill:#ed6dd1}.c444{fill:#edd2b7}.c445{fill:#ee5c07}.c446{fill:#eec06e}.c447{fill:#eeca00}.c448{fill:#eeeeee}.c449{fill:#ef402c}.c450{fill:#efcb00}.c451{fill:#efeb89}.c452{fill:#efeded}.c453{fill:#f08306}.c454{fill:#f0d74d}.c455{fill:#f0e110}.c456{fill:#f19949}.c457{fill:#f1f1f1}.c458{fill:#f23289}.c459{fill:#f2584a}.c460{fill:#f2f0f0}.c461{fill:#f327ae}.c462{fill:#f33a84}.c463{fill:#f34080}.c464{fill:#f3c87b}.c465{fill:#f3f0f0}.c466{fill:#f4ab3a}.c467{fill:#f4f0f0}.c468{fill:#f4f1f1}.c469{fill:#f5596e}.c470{fill:#f5735d}.c471{fill:#f57859}.c472{fill:#f6f2f2}.c473{fill:#f7d81e}.c474{fill:#f7f4f4}.c475{fill:#f7f6f6}.c476{fill:#f8f6f6}.c477{fill:#f8f8f8}.c478{fill:#f90808}.c479{fill:#f9ce6b}.c480{fill:#f9dc3b}.c481{fill:#f9e784}.c482{fill:#f9ec76}.c483{fill:#fa1a02}.c484{fill:#faf569}.c485{fill:#faf6f6}.c486{fill:#fbdd4b}.c487{fill:#fbf6f6}.c488{fill:#fc0000}.c489{fill:#fc00ff}.c490{fill:#fcf301}.c491{fill:#fdde60}.c492{fill:#fde80c}.c493{fill:#fde85e}.c494{fill:#febc0e}.c495{fill:#fec02a}.c496{fill:#fec901}.c497{fill:#fee85d}.c498{fill:#feed84}.c499{fill:#fef601}.c500{fill:#ff0000}.c501{fill:#ff002a}.c502{fill:#ff00f6}.c503{fill:#ff2626}.c504{fill:#ff2a2f}.c505{fill:#ff7200}.c506{fill:#ff9000}.c507{fill:#ffb400}.c508{fill:#ffd627}.c509{fill:#ffd800}.c510{fill:#ffe646}.c511{fill:#fff201}.c512{fill:#fff383}.c513{fill:#fff600}.c514{fill:#ffffff}";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Library {

    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
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

    function parseInt(string memory _a)
        internal
        pure
        returns (uint8 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint8 mint = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function stringReplace(string memory _string, uint256 _pos, string memory _letter) internal pure returns (string memory) {
        bytes memory _stringBytes = bytes(_string);
        bytes memory result = new bytes(_stringBytes.length);

        for(uint i = 0; i < _stringBytes.length; i++) {
            result[i] = _stringBytes[i];
            if(i==_pos)
            result[i]=bytes(_letter)[0];
        }
        return  string(result);
    }

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
}

// contracts/IToken.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IToken is IERC20 {
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
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

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
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