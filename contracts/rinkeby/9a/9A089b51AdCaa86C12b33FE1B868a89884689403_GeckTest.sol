// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Library.sol";

contract GeckTest is ERC721Enumerable {
    using Library for uint8;
    using ECDSA for bytes32;

    struct Trait {
        string traitName;
        string traitType;
    }

    struct Claims {
        uint256 tokenId;
        bool claimed;
    }

    // Sale states
    bool public mintActive;
    bool public mintGenesisActive;
    bool public mintIncludeReserveActive;
    bool public mintWhiteListActive;
    bool public burnAndRecycleActive;

    //API for Generation
    string private _baseArtURI;

    //Opensea royalty URI
    string private _baseContractURI;

    //Mappings
    mapping(uint256 => Trait[]) public traitTypes;
    mapping(uint256 => string) public legNames;
    mapping(string => bool) hashToMinted;
    mapping(uint256 => mapping(uint256 => string)) internal tokenIdToHash;
    mapping(uint256 => bool) public _tokenIdToLegendary;
    mapping(uint256 => string) public _tokenIdToLegendaryName;
    mapping(uint256 => uint32) public _tokenIdToLegendaryNumber;
    mapping(uint256 => bool) private _tokenClaimed;
    mapping(uint256 => Claims) public claimlist;
    mapping(uint256 => uint256) public tokenIndex;
    mapping(uint256 => uint256) public maxIndex;

    //uint8
    uint8 public legendariesMinted = 0;

    //uint96
    uint96 public constant royaltyFeeBps = 1000; //10%

    //uint256s
    uint256 public constant MAX_PRIVATE_SUPPLY = 10;
    uint256 public constant MAX_PUBLIC_SUPPLY = 40;
    uint256 public constant MAX_DEV_MINT = 50;
    uint256 public constant MAX_SUPPLY =
        MAX_PRIVATE_SUPPLY + MAX_PUBLIC_SUPPLY + MAX_DEV_MINT;
    uint256 public totalPrivateSupply;
    uint256 public totalPublicSupply;
    uint256 public totalDevMinted;
    uint256 SEED_NONCE = 0;
    uint256 MAX_MINT = 20;
    uint256 MAX_WHITELIST = 1;
    uint256 private burnNTTZ;
    uint256 private price;

    //string arrays
    string[] LETTERS = [
        "a",
        "b",
        "c",
        "d",
        "e",
        "f",
        "g",
        "h",
        "i",
        "j",
        "k",
        "l",
        "m",
        "n",
        "o",
        "p",
        "q",
        "r",
        "s",
        "t",
        "u",
        "v",
        "w",
        "x",
        "y",
        "z"
    ];

    //uint arrays
    uint16[][8] TIERS;

    uint16[][1] LEGENDARY_TIERS;

    //address
    address _owner;
    address payable public payoutAddress;
    // Team - 7.5%
    address t1;
    address t2;
    address t3;
    // Entities Treasury - 92.5%
    address t4;

    //interfaces
    MintPassContract public mintPassContract;
    NTTZToken public nttzToken;

    constructor(
        uint256 _price,
        uint256 _burnNTTZ,
        address _mintPassToken,
        address _nttzToken,
        address _t1,
        address _t2,
        address _t3,
        address _t4,
        string memory baseContractURI,
        string memory baseArtURI
    ) ERC721("GeckTest", "GEX") {
        payoutAddress = payable(msg.sender);
        _owner = msg.sender;
        price = _price;
        burnNTTZ = _burnNTTZ;
        mintPassContract = MintPassContract(_mintPassToken);
        nttzToken = NTTZToken(_nttzToken);
        t1 = _t1;
        t2 = _t2;
        t3 = _t3;
        t4 = _t4;
        _baseContractURI = baseContractURI;
        _baseArtURI = baseArtURI;

        //Declare all the rarity tiers

        LEGENDARY_TIERS[0] = [2, 4, 8, 13, 13, 13, 14, 16, 17];

        //Background
        TIERS[0] = [50, 150, 200, 300, 400, 500, 600, 900, 1200, 5700];
        //Body
        TIERS[1] = [200, 800, 1000, 3000, 5000];
        //Head
        TIERS[2] = [300, 800, 900, 1000, 7000];
        //Mouth
        TIERS[3] = [50, 200, 300, 300, 9150];
        //Eyes
        TIERS[4] = [50, 100, 400, 450, 500, 700, 1800, 2000, 2000, 2000];
        //Weapon
        TIERS[5] = [1428, 1428, 1428, 1429, 1429, 1429, 1429];
        //Body Armor
        TIERS[6] = [2000, 2000, 2000, 2000, 2000];
        //Extra
        TIERS[7] = [20, 70, 721, 1000, 1155, 1200, 1300, 1434, 1541, 1559];
    }

    /**
     * @dev Converts a digit from 0 - 10000 into its corresponding rarity based on the given rarity tier.
     * @param _randinput The input from 0 - 10000 to use for rarity gen.
     * @param _rarityTier The tier to use.
     */
    function rarityGen(uint256 _randinput, uint8 _rarityTier)
        internal
        view
        returns (string memory)
    {
        uint16 currentLowerBound = 0;
        for (uint8 i = 0; i < TIERS[_rarityTier].length; i++) {
            uint16 thisPercentage = TIERS[_rarityTier][i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ) return i.toString();
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert();
    }

    /**
     * @dev Generates random number to decide if tokenId is Legendary mint
     * @param _tokenId The tokenId of the minted token
     * @param limit The number of current Legendaries already minted
     */
    function generateRandomNumber(uint256 _tokenId, uint256 limit)
        internal
        returns (uint256)
    {
        SEED_NONCE++;

        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        _tokenId,
                        msg.sender,
                        SEED_NONCE
                    )
                )
            ) % limit;
    }

    /**
     * @dev Generates a 9 digit hash from a tokenId, address, and random number.
     * @param _t The token id to be used within the hash.
     * @param _a The address to be used within the hash.
     * @param _c The custom nonce to be used within the hash.
     */
    function hash(
        uint256 _t,
        address _a,
        uint256 _c
    ) internal returns (string memory) {
        require(_c < 10);

        // This will generate a 9 character string.
        string memory currentHash = "0";

        for (uint8 i = 0; i < 8; i++) {
            SEED_NONCE++;
            uint16 _randinput = uint16(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            _t,
                            _a,
                            _c,
                            SEED_NONCE
                        )
                    )
                ) % 10000
            );

            currentHash = string(
                abi.encodePacked(currentHash, rarityGen(_randinput, i))
            );
        }

        if (hashToMinted[currentHash]) return hash(_t, _a, _c + 1);

        return currentHash;
    }

    /**
     * @dev Mint internal, this is to avoid code duplication.
     */
    function mintInternal() internal {
        uint256 _totalSupply = totalSupply();
        require(_totalSupply < MAX_SUPPLY);
        require(!Library.isContract(msg.sender));

        uint256 thisTokenId = _totalSupply;

        if (legendariesMinted < 9) {
            uint256 legendaryDecider = generateRandomNumber(
                thisTokenId,
                LEGENDARY_TIERS[0][legendariesMinted]
            );

            if (legendaryDecider == 0) {
                //This is a legendary
                _tokenIdToLegendary[thisTokenId] = true;

                legendariesMinted++;

                //It will assign this legendary
                _tokenIdToLegendaryNumber[thisTokenId] = legendariesMinted;
                _tokenIdToLegendaryName[thisTokenId] = legNames[
                    legendariesMinted
                ];

                tokenIdToHash[thisTokenId][tokenIndex[thisTokenId]] = Library
                    .toString(legendariesMinted);

                _mint(msg.sender, thisTokenId);
                return;
            }
        }

        tokenIdToHash[thisTokenId][tokenIndex[thisTokenId]] = hash(
            thisTokenId,
            msg.sender,
            0
        );

        hashToMinted[
            tokenIdToHash[thisTokenId][tokenIndex[thisTokenId]]
        ] = true;

        _mint(msg.sender, thisTokenId);
    }

    /**
     * @dev Mints new tokens
     */

    function devMint(uint256 amount) public onlyOwner {
        require(totalDevMinted + amount <= MAX_DEV_MINT, "All tokens minted");
        for (uint256 i = 0; i < amount; i++) {
            if (totalDevMinted < MAX_DEV_MINT) {
                totalDevMinted += 1;
                mintInternal();
            }
        }
    }

    function mint(uint256 amount) public payable {
        require(mintActive, "Sale has not started yet.");
        require(msg.sender == tx.origin, "Cannot use a contract to mint");
        require(amount <= MAX_MINT, "Over max limit");
        require(totalSupply() + amount <= MAX_SUPPLY, "All tokens minted");
        require(
            totalPublicSupply + amount <= MAX_PUBLIC_SUPPLY,
            "Over max public limit"
        );
        require(msg.value >= price * amount, "ETH sent is not correct");

        for (uint256 i = 0; i < amount; i++) {
            if (totalPublicSupply < MAX_PUBLIC_SUPPLY) {
                totalPublicSupply += 1;
                mintInternal();
            }
        }
    }

    function mintIncludeReserve(uint256 amount) public payable {
        require(
            mintIncludeReserveActive && !mintActive,
            "Sale has not started yet."
        );
        require(msg.sender == tx.origin, "Cannot use a contract to mint");
        require(amount <= MAX_MINT, "Over max limit");
        require(totalSupply() + amount <= MAX_SUPPLY, "All tokens minted");
        require((totalPublicSupply + totalPrivateSupply + amount) <= (MAX_PUBLIC_SUPPLY + MAX_PRIVATE_SUPPLY));
        require(msg.value >= price * amount, "ETH sent is not correct");

        for (uint256 i = 0; i < amount; i++) {
            if (totalSupply() < MAX_SUPPLY) {
                if (totalPublicSupply < MAX_PUBLIC_SUPPLY) {
                    totalPublicSupply += 1;
                    mintInternal();
                } else if (totalPrivateSupply < MAX_PRIVATE_SUPPLY) {
                    totalPrivateSupply += 1;
                    mintInternal();
                } else revert();
            }
        }
    }

    function genesisMint(uint256[] memory tokenIds) public {
        require(mintGenesisActive, "Sale has not started yet.");
        require(
            tokenIds.length <= 20,
            "Can't claim more than 20 Geckos at once."
        );
        require(msg.sender == tx.origin, "Cannot use a contract for this");
        require(
            totalSupply() + tokenIds.length <= MAX_SUPPLY,
            "All tokens minted"
        );
        require(
            totalPrivateSupply + (tokenIds.length) < MAX_PRIVATE_SUPPLY + 1,
            "Exceeds private supply"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                mintPassContract.ownerOf(tokenIds[i]) == msg.sender,
                "You do not own this token."
            );
            require(
                !isClaimed(tokenIds[i]),
                "Gecko has already been claimed for this token."
            );
            claimlist[tokenIds[i]].tokenId = tokenIds[i];
            claimlist[tokenIds[i]].claimed = true;
            totalPrivateSupply += 1;
            mintInternal();
        }
    }

    function mintWhiteList(uint256 amount, bytes memory signature)
        public
        payable
    {
        require(mintWhiteListActive, "Sale has not started yet.");
        require(
            _verify(_hash(msg.sender), signature),
            "This hash's signature is invalid."
        );
        require(msg.sender == tx.origin, "Cannot use a contract to mint");
        require(amount <= MAX_WHITELIST, "Over max limit");
        require(totalSupply() + amount <= MAX_SUPPLY, "All tokens minted");
        require(
            totalPublicSupply + amount <= MAX_PUBLIC_SUPPLY,
            "Over max public limit"
        );
        require(msg.value >= price * amount, "ETH sent is not correct");

        for (uint256 i; i < amount; i++) {
            if (totalPublicSupply < MAX_PUBLIC_SUPPLY) {
                totalPublicSupply += 1;
                mintInternal();
            }
        }
    }

    function _hash(address _address) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address));
    }

    function _verify(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (bool)
    {
        return (_recover(hash, signature) ==
            0x8f20d89bEe77ea2AbBaF46b5DEF3Ef109ab9d358);
    }

    function _recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        return hash.recover(signature);
    }

    function burnAndRecycle(uint256 tokenId) external {
        require(msg.sender == tx.origin, "Cannot use a contract for this");
        require(
            burnNTTZ <= nttzToken.balanceOf(msg.sender),
            "You don't have enough NTTZ to perform this action"
        );
        require(ownerOf(tokenId) == msg.sender, "You do not own that NFT");
        require(
            _tokenIdToLegendary[tokenId] == false,
            "Cannot change a Legendary"
        );
        nttzToken.burn(msg.sender, burnNTTZ);
        maxIndex[tokenId] = maxIndex[tokenId] + 1;
        tokenIndex[tokenId] = maxIndex[tokenId];
        tokenIdToHash[tokenId][tokenIndex[tokenId]] = hash(
            tokenId,
            msg.sender,
            0
        );
    }

    function chooseImage(uint256 tokenId, uint256 index) external {
        require(ownerOf(tokenId) == msg.sender, "You do not own that NFT");
        require(maxIndex[tokenId] >= index, "Not available");
        require(0 <= index, "Not available");
        tokenIndex[tokenId] = index;
    }

    /**
     * @dev Helper function to reduce pixel size within contract
     */
    function letterToNumber(string memory _inputLetter)
        internal
        view
        returns (uint8)
    {
        for (uint8 i = 0; i < LETTERS.length; i++) {
            if (
                keccak256(abi.encodePacked((LETTERS[i]))) ==
                keccak256(abi.encodePacked((_inputLetter)))
            ) return (i + 1);
        }
        revert();
    }

    /**
     * @dev Returns URI to the API
     */
    function artURI() public view returns (string memory) {
        return _baseArtURI;
    }

    /**
     * @dev Hash to metadata function
     */

    function legToMetadata(string memory legName)
        public
        view
        returns (string memory)
    {
        string memory metadataString;
        metadataString = string(
            abi.encodePacked(
                '{"trait_type":"LEGENDARY"',
                '"value":"',
                legName,
                '"}'
            )
        );
        return metadataString;
    }

    function legToImage(string memory legName)
        public
        view
        returns (string memory)
    {
        string memory metadataString;
        metadataString = string(abi.encodePacked(artURI(), legName, ".png"));
        return metadataString;
    }

    function hashToMetadata(string memory _hash1)
        public
        view
        returns (string memory)
    {
        string memory metadataString;

        for (uint8 i = 0; i < 9; i++) {
            uint8 thisTraitIndex = Library.parseInt(
                Library.substring(_hash1, i, i + 1)
            );

            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"',
                    traitTypes[i][thisTraitIndex].traitType,
                    '","value":"',
                    traitTypes[i][thisTraitIndex].traitName,
                    '"}'
                )
            );

            if (i != 8)
                metadataString = string(abi.encodePacked(metadataString, ","));
        }

        return string(abi.encodePacked("[", metadataString, "]"));
    }

    /**
     * @dev Hash to trait names for output to API
     */
    function hashToTraits(string memory _hash2)
        public
        view
        returns (string memory)
    {
        string memory traitString;

        for (uint8 i = 1; i < 9; i++) {
            uint8 thisTraitIndex = Library.parseInt(
                Library.substring(_hash2, i, i + 1)
            );

            traitString = string(
                abi.encodePacked(
                    traitString,
                    traitTypes[i][thisTraitIndex].traitName
                )
            );

            if (i != 8)
                traitString = string(abi.encodePacked(traitString, "+"));
        }

        return string(abi.encodePacked(artURI(), traitString, ".png"));
    }

    /**
     * @dev Returns the image and metadata for a token Id
     * @param _tokenId The tokenId to return the SVG and metadata for.
     */

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId));

        string memory tokenHash = _tokenIdToHash(_tokenId);
        string memory tokenHash1 = _tokenIdToHashForImage(_tokenId);
        bool tokenIsLegendary = _tokenIdToLegendary[_tokenId];
        if (tokenIsLegendary) {
            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Library.encode(
                            bytes(
                                string(
                                    abi.encodePacked(
                                        '{"name": "GEX #',
                                        Library.toString(_tokenId),
                                        '", "description": "This is just a test. Hopefully it works well.", "image": "',
                                        legToImage(
                                            _tokenIdToLegendaryName[_tokenId]
                                        ),
                                        '","attributes": ',
                                        legToMetadata(
                                            _tokenIdToLegendaryName[_tokenId]
                                        ),
                                        "}"
                                    )
                                )
                            )
                        )
                    )
                );
        }
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Library.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "GEX #',
                                    Library.toString(_tokenId),
                                    '", "description": "This is just a test. Hopefully it works well.", "image": "',
                                    hashToTraits(tokenHash1),
                                    '","attributes":',
                                    hashToMetadata(tokenHash),
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    /**
     * @dev Returns a hash for a given tokenId
     * @param _tokenId The tokenId to return the hash for.
     */
    function _tokenIdToHash(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        string memory tokenHash = tokenIdToHash[_tokenId][0];
        return tokenHash;
    }

    /**
     * @dev Returns a hash for a given tokenId
     * @param _tokenId The tokenId to return the hash for.
     */
    function _tokenIdToHashForImage(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        string memory tokenHash = tokenIdToHash[_tokenId][tokenIndex[_tokenId]];
        return tokenHash;
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

    function isClaimed(uint256 tokenId) public view returns (bool claimed) {
        return claimlist[tokenId].tokenId == tokenId;
    }

    function nttz_SetAddress(address _nttz) external onlyOwner {
        nttzToken = NTTZToken(_nttz);
    }

    function setMintPrice(uint256 val) external onlyOwner {
        price = val;
    }

    function setBurnPrice(uint256 val) external onlyOwner {
        burnNTTZ = val;
    }

    function toggeleMintState() public onlyOwner {
        mintActive = !mintActive;
    }

    function toggeleMintGenesisState() public onlyOwner {
        mintGenesisActive = !mintGenesisActive;
    }

    function toggleMintIncludeReserveState() public onlyOwner {
        mintIncludeReserveActive = !mintIncludeReserveActive;
    }

    function toggeleMintWhiteListState() public onlyOwner {
        mintWhiteListActive = !mintWhiteListActive;
    }

    function toggleBurnAndRecycleState() public onlyOwner {
        burnAndRecycleActive = !burnAndRecycleActive;
    }

    /**
     * @dev Clears the traits.
     */
    function clearTraits() public onlyOwner {
        for (uint256 i = 0; i < 9; i++) {
            delete traitTypes[i];
        }
    }

    /**
     * @dev Add a trait type
     * @param _traitTypeIndex The trait type index
     * @param traits Array of traits to add
     */

    function addTraitType(uint256 _traitTypeIndex, Trait[] memory traits)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < traits.length; i++) {
            traitTypes[_traitTypeIndex].push(
                Trait(traits[i].traitName, traits[i].traitType)
            );
        }

        return;
    }

    function addLegNames(string[] memory names) public onlyOwner {
        for (uint256 i = 0; i < names.length; i++) {
            legNames[i] = names[i];
        }

        return;
    }

    /**
     * @dev Sets the URI to the API for generation
     * @param _artURI The new API URI
     */
    function setArtURI(string memory _artURI) public onlyOwner {
        _baseArtURI = _artURI;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        _baseContractURI = _contractURI;
    }

    function contractURI() public view returns (string memory) {
        return _baseContractURI;
    }

    /**
     * @dev Transfers ownership
     * @param _newOwner The new owner
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _owner = _newOwner;
    }

    function withdraw() public payable onlyOwner {
        uint256 sale1 = (address(this).balance * 25) / 1000;
        uint256 sale2 = (address(this).balance * 25) / 1000;
        uint256 sale3 = (address(this).balance * 25) / 1000;
        uint256 sale4 = (address(this).balance * 925) / 1000;

        require(payable(t1).send(sale1));
        require(payable(t2).send(sale2));
        require(payable(t3).send(sale3));
        require(payable(t4).send(sale4));
    }

    /**
     * @dev Modifier to only allow owner to call functions
     */
    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }
}

interface MintPassContract {
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);
}

interface NTTZToken {
    function burn(address _from, uint256 _amount) external;

    function balanceOf(address account) external view returns (uint256);
}