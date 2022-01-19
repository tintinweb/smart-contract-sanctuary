// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "./GaucheBase.sol";
import "./LibGauche.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Price is .0777e per mint
// Max mint is 10
// Price for a max mint is .777e
//                    ,@
//               #@@       @                                  @@
//              @@             @    @@  @@@  @@%   @@    [email protected]@  @@,  @@    @@@*   @
//             @@@  %@@@%%@@@     @@@@  @@@  @@% @@@       @  @@   @@  @@@@@@@@@@@
//             @@@      @ @@&  @@@,  @  @@@  @@% @@           @@   @@  @@
//              @@@       @@& @@@    @  @@@  @@% @@@          @@   @@  @@@
//      @@@@@      @@(   @@@& (@@@ @@@  @@@ %@@%   @@@   @@@  @@   @@    @@@   @@@
//  @@@       @           @                                @
// @@.            @@@  @       @@@  @@@  @@@   @@@@@@@@         @@   @  #@@@    @@
//&@@     @, @@@  @@@     @@@  @@@  @@@  @@@ @@  @@@@  @@  @@@  @@     @@@@@@@@@@@
// @@      @ @@@  @@@     @@@  @@@  @@@  @@@ @@ @@@@@@ @@  @@@  @@     @@
//  @@       @@@  @@@     @@@  @@@  @@@  @@@  @@      @@.  @@@  @@      @@
//    (@@@*@@@@@ @@@@     @@@@ @@@*[email protected]@@ @@@@    @@@@@@    @@@@ @@@@       @@@ @@@
//
//                       [[               ####
//                       [[[[        ########
//                       [[[[[      [[#######
//               %@#(#@@@@@(##     [[[@@#(%@@@@@
//              (([*.*[((@@@@#(   ([[(([*.*[(#@@@*
//             @([*   *[(@@@@(#   ##@([.   *((@@@@
//              @((([(((@@@@@##  ###[@((([(((@@@@*
//               %@@@@@@@@@(#######[[[@@@@@@@@@@
//                       [######[[[[[[[[[[[[[*
//                      [[[[[[[[[[[[[[#########
//        %%%%%%%%%%%#([[[[[[[[[[[[[(############[[[[[[
//        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(#[[[[
//          %%%%%@@@,,,@@@@,,%@@@*,,@@@@,,,,,%%%%[[[[[[[[[[[
//             %%%%%#,,,@[,,,,,@,[[[[[@,,,,,,%%%#[[[
//              [[%%%%%%%%,,[[[[[[[[[[[[[[%%%%%[[[[[[[#####([[[
//                 [[[(%%%%%%%%%%%%%%%%%%%%%%[[[[[[#####
//              .[[[[[#######((#%%%%%%([[[[[[[[[[[###########
//           [[[[[[[[[##############[[[[[[[[[[[[[[#############[[[
//          [[[[[[[[[[[############[[[[[[[[[[[[[[[[###########[[[[[[[[
//          [[[[[[[[[[[[[[######[[[[[[[[[[[[[[[[[[[[[(#####([[[[[[[[[[
//         #####(   [[[[[[ [[[[[[[[[[[#### ####([[[[[[[     *[[[[[######,
//       ####      ##  [  [[[[[[[[[[(#####     #    [[[[           ########
//      [                 [[[[[[[[[[#######            ,[                ####
//                       .[[[[[[[[[[########
//                       [[[[[[[[[[[[[#######
//                       [(#####[[[[[[[[[[[[[
//                      .## #######[[[   [[[[[
//                      ##                 [[[

/// @title A contract that implements the Gauche protocol.
/// @author Yuut - Soc#0903
/// @notice This contract implements minting of tokens and implementation of new projects for extending a single token into owning multiple generative works.
contract GaucheGrimoire is GaucheBase {

    /// @notice This keeps the max level of the project constrained to our offsets overflow value.
    uint256 constant internal MAX_LEVEL = 255;

    /// @notice This event fires when a word is added to the registry, enabling it to express a new form of art.
    /// @param tokenId The token which leveled up.
    /// @param wordHash The hash of the word we inserted.
    /// @param offsetSlot The storage offset of the word in tokenHashes
    /// @param level The project that the word is associated with.
    event WordAdded(uint256 indexed tokenId, bytes32 wordHash, uint256 offsetSlot, uint256 level);

    /// @notice This event fires when a token is created, and when a token has its reality changed.
    /// @param tokenId The token which leveled up.
    /// @param hash The hash of the word we inserted.
    event HashUpdated(uint256 indexed tokenId, bytes32 hash);

    /// @notice This event fires when a project is added.
    /// @param projectId The project # which was added.
    /// @param project GaucheLevel(uint8 wordPrice, uint64 price, address artistAddress, string baseURI)
    event ProjectAdded(uint256 indexed projectId, GaucheLevel project);

    /// @notice This event fires when a level has its properties changed.
    /// @param projectId The project # which was changed
    /// @param project GaucheLevel(uint8 wordPrice, uint64 price, address artistAddress, string baseURI)
    event ProjectUpdated(uint256 indexed projectId, GaucheLevel project);

    /// @notice This event fires when token is burned.
    /// @param tokenId The token that was burned
    event TokenBurned(uint256 indexed tokenId);

    /// @notice This mapping persists all of the token hashes and any hashes they own as a result of leveling up.
    mapping(uint256 => bytes32) public tokenHashes; // Offset of tokenId + wordId. Tracked by spent total in gaucheToken

    /// @notice This array persists all of the projects added to the contract.
    GaucheLevel[] public gaucheLevels;

    /// @notice ERC721a does not allow burn to 0. This is a workaround because I don't wanna touch their contract.
    address constant internal burnAddress = 0x000000000000000000000000000000000000dEaD;

    /// @notice When instantiating the contract we need to update the first level (0) as everyone starts with that as their base identity.
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _baseURI,
        uint64 _pricePerToken,
        address _accessTokenAddress,
        address _artistAddress,
        address _developerAddress
    ) GaucheBase(_tokenName, _tokenSymbol, _pricePerToken, _accessTokenAddress, _artistAddress, _developerAddress) {
        gaucheLevels.push(GaucheLevel(1, _pricePerToken, artistAddress, "https://neophorion.art/api/projects/GaucheGrimoire/metadata/"));
    }

    /**
     * @dev Ensures that we arent inserting 0x0 as a hash. Users can pick their hash on submission.
     *  The contract only provides verification for words that are keccak256(string).
     *  No confirmation is done of what the hash is when inserted, because we want to keep it a secret only the user knows.
     */
    modifier notNullWord(bytes32 _wordHash) {
        checkNotNullWord(_wordHash);
        _;
    }

    /**
     * @dev Cannot go above the max level.
     */
    modifier mustBeBelowMaxLevel(uint256 _tokenId) {
        checkMaxLevel(_tokenId);
        _;
    }

    /**
     * @dev Tokens gotta exist to be queried, so we check that the token exists.
     */
    modifier tokenExists(uint256 _tokenId) {
        checkTokenExists(_tokenId);
        _;
    }

    /**
     * @notice This is the way to retrieve project details after they are added to the blockchain.
     * This is useful for front ends that may want to display the project details live.
     * @param _projectId The project to get the details from
     * @return _project GaucheLevel(uint8 wordPrice, uint64 price, address artistAddress, string baseURI)
     */
    function getProjectDetails(uint256 _projectId) public view returns (GaucheLevel memory _project) {
        require(_projectId < gaucheLevels.length, "GG: Must be in range of projects");
        _project = gaucheLevels[_projectId];
        return _project;
    }

    /**
     * @notice Current max level of art works ownable
     * @return A number 255 or less.
     */
    function getProjectLevel() public view returns (uint256) {
        return gaucheLevels.length;
    }

    /**
     * @notice Adds a project to the registry.
     * @param _wordPrice The price in levels, if there is one.
     * @param _price The price in ETH to mint, if there is one.
     * @param _artistAddress The artists ethereum address
     * @param _tokenURI The tokenURI, without a tokenId
     */
    function addProject(uint8 _wordPrice, uint64 _price, address _artistAddress, string memory _tokenURI)  onlyOwner public {
        require(gaucheLevels.length < MAX_LEVEL, "GG: Max 255");
        GaucheLevel memory project = GaucheLevel(_wordPrice, _price, _artistAddress, _tokenURI);
        emit ProjectAdded(gaucheLevels.length, project);
        gaucheLevels.push(project);
    }

    /**
     * @notice Allows an existing project to be updated. EX: Centralized host -> IPFS migration
     * @param _projectId The project to get the details from
     * @param _wordPrice The price in levels, if there is one.
     * @param _price The price in ETH to mint, if there is one.
     * @param _artistAddress The artists ethereum address
     * @param _tokenURI The tokenURI, without a tokenId
     */
    function editProject(uint256 _projectId, uint8 _wordPrice, uint64 _price, address _artistAddress, string memory _tokenURI) onlyOwner public {
        require( _projectId < gaucheLevels.length, "GG: Must be in range");
        GaucheLevel memory project = GaucheLevel(_wordPrice, _price, _artistAddress, _tokenURI);
        emit ProjectUpdated(_projectId, project);
        gaucheLevels[_projectId] = project;
    }

    /**
     * @notice Allows a token to insert a hash to gain a level and access to a new work of art
     * @param _tokenToChange The token we are adding state to
     * @param _wordHash The keccak256(word) hash generated off chain by the user. NO VALIDATION IS DONE HERE.
     */
    function spendRealityChange(uint256 _tokenToChange, bytes32 _wordHash)
        onlyIfTokenOwner(_tokenToChange)
        isNotMode(SalesState.Finalized)
        notNullWord(_wordHash)
        mustBeBelowMaxLevel(_tokenToChange)
    public payable {
        uint256 tokenLevel = getLevel(_tokenToChange);
        GaucheLevel memory project = gaucheLevels[tokenLevel];
        require(getFree(_tokenToChange) >= project.wordPrice, "GG: No free lvl");
        require(msg.value >= project.price, "GG: Too cheap");

        _changeReality(_tokenToChange, _wordHash, tokenLevel, project.wordPrice);
    }

    /**
     * @notice Allows a token to be burnt into another token, confering its free levels + 1 for its life
     * @param _tokenToBurn The token we are burning, moving its free levels +1 into the _tokenToChange.
     * @param _tokenToChange The token we are adding state to
     */
    function burnIntoToken(uint256 _tokenToBurn, uint256 _tokenToChange)
        onlyIfTokenOwner(_tokenToBurn)
        onlyIfTokenOwner(_tokenToChange)
        mustBeBelowMaxLevel(_tokenToChange)
        isMode(SalesState.Maintenance)
    public {
        uint256 burntTokenFree = getFree(_tokenToBurn);
        uint256 tokenTotalFreeLevels = getFree(_tokenToChange);
        require(tokenTotalFreeLevels + burntTokenFree + 1 <= 255, "GG: Max 255");

        bytes32 newHash = bytes32((uint256(tokenHashes[_tokenToChange]) + uint(0x01) + burntTokenFree));
        tokenHashes[_tokenToChange] = newHash;
        emit HashUpdated(_tokenToChange, newHash);

        _burn(msg.sender, _tokenToBurn);
    }

    /**
     * @notice Allows for a tokens hash to be verified without revealing it on chain.
     * @param _tokenId The token we are checking
     * @param _level The level we want to verify against.
     * @param _word The plain text word we are submitting. NEVER call this from a contract transaction as it will leak your word!
     */
    function verifyTruth(uint256 _tokenId, uint256 _level, string calldata _word)
        tokenExists(_tokenId)
     public view returns (bool answer) {
        require(_level < tokenLevel(_tokenId) && _level != 0, "GG: Word slot out of bounds");
        bytes32 word = tokenHashes[getShifted(_tokenId) + _level];
        bytes32 assertedTruth = keccak256(abi.encodePacked(_word));

        return (word == assertedTruth);
    }

    /**
     * @notice Returns the completed token URI for base token. We use this even though we have a projectURI for entry 0 as its standard and only costs dev gas.
     * @param tokenId The token we are checking.
     * @return string tokenURI
     */
    function tokenURI(uint256 tokenId)
        tokenExists(tokenId)
     public view virtual override returns (string memory) {
        GaucheLevel memory project = gaucheLevels[0];
        require(bytes(project.baseURI).length != 0, "GG: No base URI");
        return string(abi.encodePacked(project.baseURI, Strings.toString(tokenId)));
    }

    /**
     * @notice Returns the completed token URI for a project hosted in the contract
     * @param _tokenId The token we are checking.
     * @param _projectId The project we are checking.
     * @return tokenURI string with qualified url
     */
    function tokenProjectURI(uint256 _tokenId, uint256 _projectId)
        tokenExists(_tokenId)
    public view returns (string memory tokenURI) {
        require(_projectId < gaucheLevels.length, "GG: Must be within project range");
        require(tokenHashes[_tokenId] != 0, "GG: Token not found");
        require(_projectId < getLevel(_tokenId) , "GG: Level too low");
        tokenURI = string(abi.encodePacked(gaucheLevels[_projectId].baseURI, Strings.toString(_tokenId)));
        return tokenURI;
    }

    /**
     * @notice Returns the full decoded data as a struct for the token. This is the only way to get the state of a burned token.
     * @param _tokenId The token we are checking.
     * @return token GaucheToken( uint256 tokenId, uint256 free, uint256 spent, bool burned, bytes32[] ownedHashes )
     */
    function tokenFullData(uint256 _tokenId)
    public view returns (GaucheToken memory token) {
        return  GaucheToken(_tokenId, getFree(_tokenId), getLevel(_tokenId), getBurned(_tokenId), getOwnedHashes(_tokenId));
    }

    /**
     * @notice Returns the completed token URI for a project hosted in the contract
     * @param _tokenId The token we are checking.
     * @return bytes32 base tokenhash for the token
     */
    function tokenHash(uint256 _tokenId)
        tokenExists(_tokenId)
    public view returns (bytes32) {
        return tokenHashes[_tokenId];
    }

    /**
     * @notice Returns the completed token URI for a project hosted in the contract
     * @param _tokenId The token we are checking.
     * @param _level The token we are checking.
     * @return bytes32 project tokenHash for the token for a given project level.
     */
    function tokenProjectHash(uint256 _tokenId, uint256 _level)
        tokenExists(_tokenId)
    public view returns (bytes32) {
        require(_level != 0, "GG: Level must be non-zero");
        require(getLevel(_tokenId) > _level , "GG: Level too low");
        return tokenHashes[getShifted(_tokenId) + _level];
    }

    /**
     * @notice Checks if the token has been burnt.
     * @param _tokenId The token we are checking.
     * @return _burned bool. only true if the token has been burned
     */
    function tokenBurned(uint256 _tokenId) public view returns (bool _burned) {
        return getBurned(_tokenId);
    }

    /**
     * @notice Gets the hashes for each level a token has achieved.
     * @param _tokenId The token we are checking.
     * @return ownedHashes bytes32[] Full list of hashes owned by the token
     */
    function tokenHashesOwned(uint256 _tokenId)
        tokenExists(_tokenId)
    public view returns (bytes32[] memory ownedHashes) {
        return getOwnedHashes(_tokenId);
    }

    /**
     * @notice Gets the hashes for each level a token has achieved
     * @param _tokenId The token we are checking.
     * @return uint How many free levels the token has
     */
    function tokenFreeChanges(uint256 _tokenId)
        tokenExists(_tokenId)
    public view returns (uint) {
        return getFree(_tokenId);
    }

    /**
     * @notice Gets the tokens current level
     * @param _tokenId The token we are checking.
     * @return uint  How many levels the token has
     */
    function tokenLevel(uint256 _tokenId)
        tokenExists(_tokenId)
    public view returns (uint) {
        return getLevel(_tokenId);
    }

    function getBurnedCount() public view returns(uint256) {
        return balanceOf(burnAddress);
    }

    function getTotalSupply() public view returns(uint256) {
        return totalSupply() - getBurnedCount();
    }

    // We use this function to shift the tokenid 16bits to the left, since we use the last 8bits to store injected hashes
    // Example: Token 0x03e9 (1001) becomes 0x03e90000 . With 0x0000 storing the traits, and 0x0001+ storing new hashes
    // Overflow within this schema is impossible as there is 65535 entries between tokens in this schema and our max level is 255
    function getShifted(uint256 _tokenId) internal view returns(uint256) {
        return (_tokenId << 16);
    }

    // Internal functions used for modifiers and such.
    function checkNotNullWord(bytes32 _wordHash) internal view {
        require(_wordHash != 0x0, "GG: Cannot insert a null word");
    }

    function checkMaxLevel(uint256 _tokenId) internal view {
        require(getLevel(_tokenId) < gaucheLevels.length , "GG: Max level reached");
    }

    function getFree(uint256 _tokenId) internal view returns(uint256) {
        uint256 free = uint256(tokenHashes[_tokenId]) & 0xFF;
        return free;
    }

    function getLevel(uint256 _tokenId) internal view returns(uint256) {
        uint256 level = uint256(tokenHashes[_tokenId]) & 0xFF00;
        return level >> 8;
    }

    function getBurned(uint256 _tokenId) internal view returns(bool) {
        return (ownerOf(_tokenId) == burnAddress ? true : false);
    }

    function getOwnedHashes(uint256 _tokenId) internal view returns(bytes32[] memory ownedHashes) {
        uint256 tokenShiftedId = getShifted(_tokenId);
        uint256 tokenLevel = getLevel(_tokenId);
        ownedHashes = new bytes32[](tokenLevel);
        ownedHashes[0] = tokenHashes[_tokenId];

        for (uint256 i = 1; i < tokenLevel; i++) {
            ownedHashes[i] = tokenHashes[tokenShiftedId + i];
        }
        return ownedHashes;
    }

    /**
     * @dev This goes with the modifier tokenExists
     */
    function checkTokenExists(uint256 _tokenId) internal view returns (bool) {
        require(_exists(_tokenId) && ownerOf(_tokenId) != burnAddress, "GG: Token does not exist");
    }

    function _mintToken(address _toAddress, uint256 _count, bool _batch) internal override returns (uint256[] memory _tokenIds) {
        uint256 currentSupply = totalSupply();

        if (_batch) {
            _safeMint(_toAddress, _count);
            _tokenIds = new uint256[](_count);
        } else {
            _safeMint(_toAddress, 1);
            _tokenIds = new uint256[](1);
        }
        // This is ugly buts its kinda peak performance. We use the final two bytes of the hash to store free uses
        // Then we use the two bytes preceeding that for the level.
        // We also bitshift the tokenid so we can use the hashes mapping to store words

        for(uint256 i = 0; i < _count; i++) {
            uint256 tokenId = currentSupply + i;
            bytes32 level0hash = bytes32( ( uint256(keccak256(abi.encodePacked(block.number, _msgSender(), tokenId)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000) + uint(0x0100) + ( _batch ? uint(0x01) : _count) ) );
            tokenHashes[tokenId] = level0hash;
            emit HashUpdated(tokenId, level0hash); // This is to inform frontend services that we have new properties in hash 0
            _tokenIds[i] = tokenId;
            if(!_batch) {
                break;
            }
        }

        return _tokenIds;
    }

    function _changeReality(uint256 _tokenId, bytes32 _wordHash, uint256 _newSlot, uint256 _levelWordPrice) internal  {
        uint256 wordSlot = getShifted(_tokenId) +_newSlot;
        // Store the incoming word
        tokenHashes[wordSlot] = _wordHash;

        bytes32 levelZeroHash = bytes32((((uint256(tokenHashes[_tokenId]) + uint(0x0100) )- _levelWordPrice)));

        tokenHashes[_tokenId] = levelZeroHash;
        emit WordAdded(_tokenId, _wordHash, _newSlot, wordSlot);
        emit HashUpdated(_tokenId, levelZeroHash); // This is to inform frontend services that we have new properties in hash 0
    }

    function _burn(address owner, uint256 tokenId) internal virtual {
        transferFrom(owner, burnAddress, tokenId);
        emit TokenBurned(tokenId);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "./LibGauche.sol";

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title A contract that implements the sale state machine
/// @author Yuut - Soc#0903
/// @notice This contract implements the sale state machine.
abstract contract GaucheBase is ERC721A, Ownable {
    /// @notice Tier 0 artist address. Yes we save this elsewhere, but this is used specifically for the public sale.
    address public artistAddress;

    /// @notice Developer address. Maintains the contract and allows for the dev to get paid.
    address public developerAddress;

    /// @notice Sale state machine. Holds all defs related to token sale.
    GaucheSale internal sale;

    /// @notice Controls the proof of use for Wassilike tokens.
    mapping(uint256 => bool) public accessTokenUsed;

    /// @notice Controls the contract URI
    string internal ContractURI = "https://neophorion.art/api/projects/GaucheGrimoire/contractURI";

    /// @notice Sale status event for front end event listeners.
    /// @param state Controls the frontend sale state.
    event SaleStateChanged(SalesState state);

/// @notice Creates a new instance of the contract and sets required params before initialization.
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint64 _pricePerToken,
        address _accessTokenAddress,
        address _artistAddress,
        address _developerAddress
    ) ERC721A(_tokenName, _tokenSymbol, 10, 3333) {
        sale = GaucheSale(SalesState.Closed, 0x0BB9, _pricePerToken, _accessTokenAddress);
        artistAddress = _artistAddress;
        developerAddress = _developerAddress;
    }

    /// @notice Confirms the caller owns the token
    /// @param _tokenId The token id to check ownership of
    modifier onlyIfTokenOwner(uint256 _tokenId) {
        _checkTokenOwner(_tokenId);
        _;
    }

    /// @notice Confirms the sale mode is in the matching state
    /// @param _mode Mode to Match
    modifier isMode(SalesState _mode) {
        _checkMode(_mode);
        _;
    }

    /// @notice Confirms the sale mode is NOT in the matching state
    /// @param _mode Mode to Match
    modifier isNotMode(SalesState _mode) {
        _checkNotMode(_mode);
        _;
    }

    /// @notice MultiMint to allow multiple tokens to be minted at the same time. Price is .0777e per count
    /// @param _count Total number of tokens to mint
    /// @return _tokenIds An array of tokenids, 1 entry per token minted.
    function multiMint(uint256 _count) public payable isMode(SalesState.Active) returns (uint256[] memory _tokenIds) {
        uint256 price = sale.pricePerToken * _count;
        require(msg.value >= price, "GG: Ether amount is under set price");
        require(_count >= 1, "GG: Token count must be 1 or more");
        require(totalSupply() < sale.maxPublicTokens, "GG: Max tokens reached");

        return  _mintToken(_msgSender(), _count, true);
    }

    /// @notice Single mint to allow high level tokens to be minted. Price is .0777e per count
    /// @param _count Total number of levels to mint with
    /// @return _tokenIds An array of tokenids, 1 entry per token minted.
    function mint(uint256 _count) public payable isMode(SalesState.Active) returns (uint256[] memory _tokenIds) {
        uint256 price = sale.pricePerToken * _count;
        require(msg.value >= price, "Ether amount is under set price");
        require(_count >= 1, "GG: Min Lvl 1"); // Must buy atleast 1 level, since all tokens start at level 1
        require(_count <= 255, "GG: Max 255 lvl"); // We stop at 254 because we have a max combined level of 255, as all tokens start at level 1
        require(totalSupply() + _count < sale.maxPublicTokens, "GG: Max tokens reached");

        return  _mintToken(_msgSender(), _count, false);
    }

    /// @notice Single mint to allow level 3 tokens to be minted using a Wassilikes token
    /// @param _tokenId Wassilikes Token Id
     /// @return _tokenIds An array of tokenids, 1 entry per token minted.
    function mintAccessToken(uint256 _tokenId) isMode(SalesState.AccessToken) public payable returns (uint256[] memory _tokenIds) {
        require(msg.value >= sale.pricePerToken, "Ether amount is under set price");
        IERC721 accessToken = IERC721(sale.accessTokenAddress);
        require(accessToken.ownerOf(_tokenId) == _msgSender(), "Access token not owned");
        require(accessTokenUsed[_tokenId] == false, "Access token already used");

        accessTokenUsed[_tokenId] = true;

        // Wassilikes holders get 1 mint with 3 levels.
        return _mintToken(_msgSender(), 3, false);
    }

    /// @notice Mints reserved tokens for artist + developer + team
    /// @return _tokenIds An array of tokenids, 1 entry per token minted.
    function reservedMint() isMode(SalesState.Closed) onlyOwner public returns (uint256[] memory _tokenIds) {
        require(totalSupply() < 20, "GG: Must be less than 20");
        _mintToken(owner(), 1, false); // The owner takes token 0 to prevent it from ever destroying state
        _mintToken(artistAddress, 10, false); // Artist and dev get 10 levels to ensure all art can be minted later
        _mintToken(developerAddress, 10, false);
        _mintToken(owner(), 10, true); // 10 tokens are the max mint
        _mintToken(owner(), 7, true); // 7 tokens this wraps up the giveaway reservations
    }

    /// @notice Used for checking if a token has been used for claiming or not.
    /// @param _tokenId Wassilikes Token Id
    /// @return bool True if used, false if not
    function checkIfAccessTokenIsUsed(uint256 _tokenId) public view returns (bool) {
        return accessTokenUsed[_tokenId];
    }

    /// @notice Grabs the sale state from the contract
    /// @return uint The current sale state
    function getSaleState() public view returns(uint)  {
        return uint(sale.saleState);
    }

    /// @notice Grabs the contractURI
    /// @return string The current URI for the contract
    function contractURI() public view returns (string memory) {
        return ContractURI;
    }

    /// @notice Cha-Ching. Heres how we get paid!
    function withdrawFunds() public onlyOwner {
        uint256 share =  address(this).balance / 20;
        uint256 artistPayout = share * 13;
        uint256 developerPayout =   share * 7;

        if (artistPayout > 0) {
            (bool sent, bytes memory data) = payable(artistAddress).call{value: artistPayout}("");
            require(sent, "Failed to send Ether");
        }

        if (developerPayout > 0) {
            (bool sent, bytes memory data) =  payable(developerAddress).call{value: developerPayout}("");
            require(sent, "Failed to send Ether");
        }
    }

    /// @notice Pushes the sale state forward. Can skip to any state but never go back.
    /// @param _state the integer of the state to move to
    function updateSaleState(SalesState _state) public onlyOwner {
        require(sale.saleState != SalesState.Finalized, "GB: Can't change state if Finalized");
        require( _state > sale.saleState, "GB: Can't reverse state");
        sale.saleState = _state;
        emit SaleStateChanged(_state);
    }

    /// @notice Changes the contractURI
    /// @param _contractURI The new contracturi
    function updateContractURI(string memory _contractURI) public onlyOwner {
        ContractURI = _contractURI;
    }

    /// @notice Changes the artists withdraw address
    /// @param _artistAddress The new address to withdraw to
    function updateArtistAddress(address _artistAddress) public {
        require(msg.sender == artistAddress, "GB: Only artist");
        artistAddress = _artistAddress;
    }

    /// @notice Changes the developers withdraw address
    /// @param _developerAddress The new address to withdraw to
    function updateDeveloperAddress(address _developerAddress) public  {
        require(msg.sender == developerAddress, "GB: Only dev");
        developerAddress = _developerAddress;
    }

    function _checkMode(SalesState _mode) internal view {
        require(_mode == sale.saleState ,"GG: Contract must be in matching mode");
    }

    function _checkNotMode(SalesState _mode) internal view {
        require(_mode != sale.saleState ,"GG: Contract must not be in matching mode");
    }

    function _checkTokenOwner(uint256 _tokenId) internal view {
        require(ERC721A.ownerOf(_tokenId) == _msgSender(),"ERC721: Must own token to call this function");
    }

    function _mintToken(address _toAddress, uint256 _count, bool _batch) internal virtual returns (uint256[] memory _tokenId);
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity =0.8.11;

enum SalesState {
    Closed,
    Active,
    AccessToken,
    Maintenance,
    Finalized
}

struct GaucheSale {
    SalesState saleState;
    uint16 maxPublicTokens;
    uint64 pricePerToken;
    address accessTokenAddress;
}
struct GaucheToken {
    uint256 tokenId;
    uint256 free;
    uint256 spent;
    bool burned;
    bytes32[] ownedHashes;
}

struct GaucheLevel {
    uint8 wordPrice;
    uint64 price;
    address artistAddress;
    string baseURI;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

pragma solidity =0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Assumes the number of issuable tokens (collection size) is capped and fits in a uint128.
 *
 * Does not support burning tokens to address(0).
 */
contract ERC721A is
  Context,
  ERC165,
  IERC721,
  IERC721Metadata,
  IERC721Enumerable
{
  using Address for address;
  using Strings for uint256;

  struct TokenOwnership {
    address addr;
    uint64 startTimestamp;
  }

  struct AddressData {
    uint128 balance;
    uint128 numberMinted;
  }

  uint256 private currentIndex = 0;

  uint256 internal immutable collectionSize;
  uint256 internal immutable maxBatchSize;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to ownership details
  // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
  mapping(uint256 => TokenOwnership) private _ownerships;

  // Mapping owner address to address data
  mapping(address => AddressData) private _addressData;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /**
   * @dev
   * `maxBatchSize` refers to how much a minter can mint at a time.
   * `collectionSize_` refers to how many tokens are in the collection.
   */
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) {
    require(
      collectionSize_ > 0,
      "ERC721A: collection must have a nonzero supply"
    );
    require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
    _name = name_;
    _symbol = symbol_;
    maxBatchSize = maxBatchSize_;
    collectionSize = collectionSize_;
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return currentIndex;
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) public view override returns (uint256) {
    require(index < totalSupply(), "ERC721A: global index out of bounds");
    return index;
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   * This read function is O(collectionSize). If calling from a separate contract, be sure to test gas first.
   * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    override
    returns (uint256)
  {
    require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
    uint256 numMintedSoFar = totalSupply();
    uint256 tokenIdsIdx = 0;
    address currOwnershipAddr = address(0);
    for (uint256 i = 0; i < numMintedSoFar; i++) {
      TokenOwnership memory ownership = _ownerships[i];
      if (ownership.addr != address(0)) {
        currOwnershipAddr = ownership.addr;
      }
      if (currOwnershipAddr == owner) {
        if (tokenIdsIdx == index) {
          return i;
        }
        tokenIdsIdx++;
      }
    }
    revert("ERC721A: unable to get token of owner by index");
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), "ERC721A: balance query for the zero address");
    return uint256(_addressData[owner].balance);
  }

  function _numberMinted(address owner) internal view returns (uint256) {
    require(
      owner != address(0),
      "ERC721A: number minted query for the zero address"
    );
    return uint256(_addressData[owner].numberMinted);
  }

  function ownershipOf(uint256 tokenId)
    internal
    view
    returns (TokenOwnership memory)
  {
    require(_exists(tokenId), "ERC721A: owner query for nonexistent token");

    uint256 lowestTokenToCheck;
    if (tokenId >= maxBatchSize) {
      lowestTokenToCheck = tokenId - maxBatchSize + 1;
    }

    for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
      TokenOwnership memory ownership = _ownerships[curr];
      if (ownership.addr != address(0)) {
        return ownership;
      }
    }

    revert("ERC721A: unable to determine the owner of token");
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return ownershipOf(tokenId).addr;
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
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
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
  function approve(address to, uint256 tokenId) public override {
    address owner = ERC721A.ownerOf(tokenId);
    require(to != owner, "ERC721A: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721A: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), "ERC721A: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public override {
    require(operator != _msgSender(), "ERC721A: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
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
  ) public override {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721A: transfer to non ERC721Receiver implementer"
    );
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return tokenId < currentIndex;
  }

  function _safeMint(address to, uint256 quantity) internal {
    _safeMint(to, quantity, "");
  }

  /**
   * @dev Mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - there must be `quantity` tokens remaining unminted in the total collection.
   * - `to` cannot be the zero address.
   * - `quantity` cannot be larger than the max batch size.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal {
    uint256 startTokenId = currentIndex;
    require(to != address(0), "ERC721A: mint to the zero address");
    // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
    require(!_exists(startTokenId), "ERC721A: token already minted");
    require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    AddressData memory addressData = _addressData[to];
    _addressData[to] = AddressData(
      addressData.balance + uint128(quantity),
      addressData.numberMinted + uint128(quantity)
    );
    _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

    uint256 updatedIndex = startTokenId;

    for (uint256 i = 0; i < quantity; i++) {
      emit Transfer(address(0), to, updatedIndex);
      require(
        _checkOnERC721Received(address(0), to, updatedIndex, _data),
        "ERC721A: transfer to non ERC721Receiver implementer"
      );
      updatedIndex++;
    }

    currentIndex = updatedIndex;
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
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
  ) private {
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);

    bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
      getApproved(tokenId) == _msgSender() ||
      isApprovedForAll(prevOwnership.addr, _msgSender()));

    require(
      isApprovedOrOwner,
      "ERC721A: transfer caller is not owner nor approved"
    );

    require(
      prevOwnership.addr == from,
      "ERC721A: transfer from incorrect owner"
    );
    require(to != address(0), "ERC721A: transfer to the zero address");

    _beforeTokenTransfers(from, to, tokenId, 1);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, prevOwnership.addr);

    _addressData[from].balance -= 1;
    _addressData[to].balance += 1;
    _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));

    // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
    // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
    uint256 nextTokenId = tokenId + 1;
    if (_ownerships[nextTokenId].addr == address(0)) {
      if (_exists(nextTokenId)) {
        _ownerships[nextTokenId] = TokenOwnership(
          prevOwnership.addr,
          prevOwnership.startTimestamp
        );
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(
    address to,
    uint256 tokenId,
    address owner
  ) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  uint256 public nextOwnerToExplicitlySet = 0;

  /**
   * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
   */
  function _setOwnersExplicit(uint256 quantity) internal {
    uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
    require(quantity > 0, "quantity must be nonzero");
    uint256 endIndex = oldNextOwnerToSet + quantity - 1;
    if (endIndex > collectionSize - 1) {
      endIndex = collectionSize - 1;
    }
    // We know if the last one in the group exists, all in the group exist, due to serial ordering.
    require(_exists(endIndex), "not enough minted yet for this cleanup");
    for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
      if (_ownerships[i].addr == address(0)) {
        TokenOwnership memory ownership = ownershipOf(i);
        _ownerships[i] = TokenOwnership(
          ownership.addr,
          ownership.startTimestamp
        );
      }
    }
    nextOwnerToExplicitlySet = endIndex + 1;
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
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver(to).onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721A: transfer to non ERC721Receiver implementer");
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
   * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  /**
   * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
   * minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero.
   * - `from` and `to` are never both zero.
   */
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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