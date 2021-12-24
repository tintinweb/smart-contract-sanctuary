//SPDX-License-Identifier: MIT
// contracts/ERC721.sol
// upgradeable contract

pragma solidity >=0.8.0;

import "./ERC721Upgradeable.sol";
import "./Counters.sol";
import "./Pausable.sol";
import "./IGoose.sol";

contract GooseRunMain is IGoose, ERC721Upgradeable, Pausable {
    // Royalty
    address private _owner;
    address private _royaltiesAddr; // royality receiver
    uint256 public royaltyPercentage; // royalty based on sales price
    mapping(address => bool) public excludedList; // list of people who dont have to pay fee

    // cost to mint
    uint256 public mintFeeAmount;

    // // NFT Meta data
    string public baseURL;

    uint256 public constant maxSupply = 10000;

    // number of tokens have been minted so far
    uint16 public minted = 0;

    // enable flag for public
    bool public openForPublic;

    // define GooseRun struct
    struct GooseRun {
        uint256 tokenId;
        address mintedBy;
        address currentOwner;
        uint256 previousPrice;
        uint256 price;
        uint256 numberOfTransfers;
        bool forSale;
        uint256 kg;
        uint64 forSalLog;
    }



    mapping(uint256 => uint256) public existingCombinations;
    // mapping from tokenId to a struct containing the token's traits
    mapping(uint256 => GooseRunParts) public tokenTraits;

    // list of aliases for Walker's Alias algorithm
    uint8[][9] public rarities;
    uint8[][9] public aliases;

  constructor() { 
    // goose
    rarities[0] = [243, 189, 133, 133, 57, 95, 152, 135, 133, 57, 222, 168, 57, 57, 38, 114, 114, 114, 255, 255, 57, 57, 38, 114, 114, 114, 255, 255];
    aliases[0] = [0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 9];
    // head
    rarities[1] = [243, 189, 133, 133, 57, 95, 152, 135, 133, 57, 222, 168, 57, 57, 38, 114, 114, 114, 255, 255, 57, 57, 38, 114, 114, 114, 255, 255];
    aliases[1] = [0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 9];
    // ears
    rarities[2] = [243, 189, 133, 133, 57, 95, 152, 135, 133, 57, 222, 168, 57, 57, 38, 114, 114, 114, 255, 255, 57, 57, 38, 114, 114, 114, 255, 255];
    aliases[2] = [0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 9];
    // eyes
    rarities[3] = [243, 189, 133, 133, 57, 95, 152, 135, 133, 57, 222, 168, 57, 57, 38, 114, 114, 114, 255, 255, 57, 57, 38, 114, 114, 114, 255, 255];
    aliases[3] = [0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 9];
    // nose
    rarities[4] = [243, 189, 133, 133, 57, 95, 152, 135, 133, 57, 222, 168, 57, 57, 38, 114, 114, 114, 255, 255, 57, 57, 38, 114, 114, 114, 255, 255];
    aliases[4] = [0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 9];
    // mouth
    rarities[5] = [243, 189, 133, 133, 57, 95, 152, 135, 133, 57, 222, 168, 57, 57, 38, 114, 114, 114, 255, 255, 57, 57, 38, 114, 114, 114, 255, 255];
    aliases[5] = [0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 9];
    // neck
    rarities[6] = [243, 189, 133, 133, 57, 95, 152, 135, 133, 57, 222, 168, 57, 57, 38, 114, 114, 114, 255, 255, 57, 57, 38, 114, 114, 114, 255, 255];
    aliases[6] = [0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 9];
    // feet
    rarities[7] = [243, 189, 133, 133, 57, 95, 152, 135, 133, 57, 222, 168, 57, 57, 38, 114, 114, 114, 255, 255, 57, 57, 38, 114, 114, 114, 255, 255];
    aliases[7] = [0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 9];
    // alphaIndex
    rarities[8] = [243, 189, 133, 133, 57, 95, 152, 135, 133, 57, 222, 168, 57, 57, 38, 114, 114, 114, 255, 255, 57, 57, 38, 114, 114, 114, 255, 255];
    aliases[8] = [0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 9];
  }

  function selectTrait(uint16 seed, uint8 traitType) public view returns (uint8) {
    uint8 trait = uint8(seed) % uint8(rarities[traitType].length);
    return aliases[traitType][trait];
  }

  function selectTraits(uint256 seed) internal view returns (GooseRunParts memory t) {    
    seed >>= 16;
    t.background = selectTrait(uint16(seed & 0xFFFF), 0);
    seed >>= 16;
    t.feather = selectTrait(uint16(seed & 0xFFFF), 1);
    seed >>= 16;
    t.head = selectTrait(uint16(seed & 0xFFFF), 2);
    seed >>= 16;
    t.mouth = selectTrait(uint16(seed & 0xFFFF), 3);
    seed >>= 16;
    t.neck = selectTrait(uint16(seed & 0xFFFF), 4);
    seed >>= 16;
    t.belly = selectTrait(uint16(seed & 0xFFFF), 5);
    seed >>= 16;
    t.wing = selectTrait(uint16(seed & 0xFFFF), 6);
    seed >>= 16;
    t.tail = selectTrait(uint16(seed & 0xFFFF), 7);
    seed >>= 16;
    t.feet = selectTrait(uint16(seed & 0xFFFF), 8);
  }

    /**
   * converts a struct to a 256 bit hash to check for uniqueness
   * @param s the struct to pack into a hash
   * @return the 256 bit hash of the struct
   */
  function structToHash(GooseRunParts memory s) internal pure returns (uint256) {
    return uint256(bytes32(
      abi.encodePacked(
        s.background,
        s.feather,
        s.head,
        s.mouth,
        s.neck,
        s.belly,
        s.wing,
        s.tail,
        s.feet
      )
    ));
  }


    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // map id to GooseRun obj
    mapping(uint256 => GooseRun) public allGooseRun;

    //  implement the IERC721Enumerable which no longer come by default in openzeppelin 4.x
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    function initialize(
        address _contractOwner,
        address _royaltyReceiver,
        uint256 _royaltyPercentage,
        uint256 _mintFeeAmount,
        string memory _baseURL,
        bool _openForPublic
    ) public initializer {
        __ERC721_init("GOOSE", "GOOSE");
        royaltyPercentage = _royaltyPercentage;
        _owner = _contractOwner;
        _royaltiesAddr = _royaltyReceiver;
        mintFeeAmount = _mintFeeAmount;
        excludedList[_contractOwner] = true; // add owner to exclude list
        excludedList[_royaltyReceiver] = true; // add artist to exclude list
        baseURL = _baseURL;
        openForPublic = _openForPublic;
    }

    function toggleOpenForPublic(bool status) external {
        require(msg.sender == _owner, "Only owner");
        openForPublic = status;
    }




    function mint(uint256 numberOfToken) public payable {
        // check if thic fucntion caller is not an zero address account
        require(openForPublic == true, "not open");
        require(msg.sender != address(0));
        require(
            _allTokens.length + numberOfToken <= maxSupply,
            "max supply"
        );
        require(numberOfToken > 0, "Min 1");
        require(numberOfToken <= 100, "Max 100");
        uint256 price = 0;
        // pay for minting cost
        if (excludedList[msg.sender] == false) {
            // send token's worth of ethers to the owner
            price = mintFeeAmount * numberOfToken;
            require(msg.value >= price, "Not enough fee");
            payable(_royaltiesAddr).transfer(msg.value);
        } else {
            // return money to sender // since its free
            payable(msg.sender).transfer(msg.value);
        }
        uint256 seed;
        for (uint256 i = 1; i <= numberOfToken; i++) {
            minted++;
            seed = uint(keccak256(abi.encodePacked(minted)));
            _safeMint(msg.sender, minted);
            generate(minted, seed);
            GooseRun memory newGooseRun = GooseRun(
                minted,
                msg.sender,
                msg.sender,
                0,
                price,
                0,
                false,
                100,
                0      
                );            
            allGooseRun[minted] = newGooseRun;
        }
    }

    function generate(uint256 tokenId, uint256 seed) internal returns (GooseRunParts memory t) {
    t = selectTraits(seed);
    if (existingCombinations[structToHash(t)] == 0) {
      tokenTraits[tokenId] = t;
      existingCombinations[structToHash(t)] = tokenId;
      return t;
    }
        seed = uint(keccak256(abi.encodePacked(minted)));
        seed = seed % 1000;
        return generate(tokenId, seed);
    }

    function changeUrl(string memory url) external {
        require(msg.sender == _owner, "Only owner");
        baseURL = url;
    }

    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    // allow airdrop token to address
    function airdropTokens(uint256 numberOfToken, address toAddress) external {
        require(msg.sender == _owner, "Only owner");
        require(
            numberOfToken + _allTokens.length < maxSupply,
            "Max supply"
        );
        uint256 price = 0;
        uint256 seed;
        for (uint256 i = 1; i <= numberOfToken; i++) {
            minted++;
            seed = uint(keccak256(abi.encodePacked(minted)));
            _safeMint(msg.sender, minted);
            generate(minted, seed);
            GooseRun memory newGooseRun = GooseRun(
                minted,
                msg.sender,
                toAddress,
                0,
                price,
                0,
                false,
                100,
                0      
                );
            // add the token id to the allGooseRun
            allGooseRun[minted] = newGooseRun;
        }
    }

    function setPriceForSale(
        uint256 _tokenId,
        uint256 _newPrice,
        bool isForSale
    ) external {
        require(_exists(_tokenId));
        address tokenOwner = ownerOf(_tokenId);
        require(tokenOwner == msg.sender);
        GooseRun memory goose = allGooseRun[_tokenId];
        goose.price = _newPrice;
        goose.forSale = isForSale;
        goose.forSalLog = uint64(block.timestamp);
        allGooseRun[_tokenId] = goose;
    }

    function getAllSaleTokens() public view returns (uint256[] memory) {
        uint256 _totalSupply = totalSupply();
        uint256[] memory _tokenForSales = new uint256[](_totalSupply);
        uint256 counter = 0;
        for (uint256 i = 1; i <= _totalSupply; i++) {
            if (allGooseRun[i].forSale == true) {
                _tokenForSales[counter] = allGooseRun[i].tokenId;
                counter++;
            }
        }
        return _tokenForSales;
    }

    // by a token by passing in the token's id
    function buyToken(uint256 _tokenId) public payable {
        // check if the token id of the token being bought exists or not
        require(_exists(_tokenId));
        // get the token's owner
        address tokenOwner = ownerOf(_tokenId);
        // token's owner should not be an zero address account
        require(tokenOwner != address(0));
        // the one who wants to buy the token should not be the token's owner
        require(tokenOwner != msg.sender);
        // get that token from all GooseRun mapping and create a memory of it defined as (struct => GooseRun)
        GooseRun memory goose = allGooseRun[_tokenId];
        // price sent in to buy should be equal to or more than the token's price
        require(msg.value >= goose.price);
        // token should be for sale
        require(goose.forSale);
        uint256 amount = msg.value;
        uint256 _royaltiesAmount = (amount * royaltyPercentage) / 100;
        uint256 payOwnerAmount = amount - _royaltiesAmount;
        payable(_royaltiesAddr).transfer(_royaltiesAmount);
        payable(goose.currentOwner).transfer(payOwnerAmount);
        goose.previousPrice = goose.price;
        allGooseRun[_tokenId] = goose;
        _transfer(tokenOwner, msg.sender, _tokenId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256)
    {
        require(index < balanceOf(owner), "out of bounds");
        return _ownedTokens[owner][index];
    }

    //  URI Storage override functions
    /** Overrides ERC-721's _baseURI function */
    function _baseURI()
        internal
        view
        virtual
        override(ERC721Upgradeable)
        returns (string memory)
    {
        return baseURL;
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
        GooseRun memory goose = allGooseRun[tokenId];
        goose.currentOwner = to;
        goose.numberOfTransfers += 1;
        goose.forSale = false;
        allGooseRun[tokenId] = goose;
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

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        uint256 lastTokenIndex = balanceOf(from) - 1;
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

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    // upgrade the contract
    function setKg(uint256 _tokenId, uint256 _newKg) external {
        require(msg.sender == _owner, "Only owner");
        GooseRun memory goose = allGooseRun[_tokenId];
        goose.kg = _newKg;
        // set and update that token in the mapping
        allGooseRun[_tokenId] = goose;
    }
}