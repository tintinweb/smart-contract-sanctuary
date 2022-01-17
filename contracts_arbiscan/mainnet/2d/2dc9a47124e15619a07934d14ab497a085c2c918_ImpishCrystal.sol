// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

abstract contract ISpiralStaking {
  struct TokenIdInfo {
      uint256 ownedTokensIndex;
      address owner;
  }
  mapping(uint256 => TokenIdInfo) public stakedTokenOwners;
}

contract ImpishCrystal is ERC721, ERC721Enumerable, ERC721Burnable, Ownable, ReentrancyGuard {
    // Next TokenID
    uint32 public _tokenIdCounter;

    // Base URI
    string private _baseTokenURI;

    // Entropy
    bytes32 public entropy;

    // Contract addresses
    address public spirals;
    address public spiralStaking;
    address public SpiralBits;

    // How many spiralbits it takes to grow per size per sym
    uint192 constant public SPIRALBITS_PER_SYM_PER_SIZE = 1000 ether;
    uint256 constant public SPIRALBITS_PER_SYM = 20000 ether;

    // Struct that has info about a Crystal
    struct CrystalInfo {
      uint8 size;
      uint8 generation;
      uint8 sym;
      uint32 seed;
      uint192 spiralBitsStored;
    }
    // Crystal TokenID => CrystalInfo
    mapping(uint256 => CrystalInfo) public crystals;

    // SpiralTokenID -> bitMap of generations, indicating of token was
    struct MintedSpiralInfo {
      bool minted;
      uint32 tokenId;
    }
    // SpiralTokenID => gen number => MintedSpiralInfo
    mapping(uint256 => mapping(uint256 => MintedSpiralInfo)) public mintedSpirals;

    constructor(address _spirals, address _spiralStaking, address _spiralbits) ERC721("ImpishCrystal", "Crystal") {
      // Set BaseURI
      _baseTokenURI = "https://impishdao.com/crystalapi/crystal/metadata/";

      // Contract addresses
      spirals = _spirals;
      spiralStaking = _spiralStaking;
      SpiralBits = _spiralbits;

      // Mint 100 at startup for marketing and giveaways
      for (uint8 i = 0; i < 100; i++) {
        _mintCrystal(0);  // Initial tokens are 0 gen
        crystals[i].size = 70; // With size 70
      }
    }

    // Only owner can set the BaseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // Increment the entropy
    function _nextEntropy() internal {
      entropy = keccak256(abi.encode(
            block.timestamp,
            blockhash(block.number),
            msg.sender,
            entropy));
    }

    event CrystalChangeEvent(uint32 indexed crystalTokenId, uint8 indexed eventType, uint8 size);
    
    function _mintCrystal(uint8 gen) internal {      
      uint32 tokenId = _tokenIdCounter;
      _tokenIdCounter += 1;

      _nextEntropy();

      uint32 seed = uint32(uint256(entropy) & 0xFFFFFF);
      uint8 sym = uint8((uint256(entropy) >> 32) & 0x03) + 5 + gen; // Number between 5 and 8 inclusive
      
      // Newly born crystals always have length 30, and have 0 SPIRALBITS stored.
      crystals[tokenId] = CrystalInfo(30, gen, sym, seed, 0);      
      _safeMint(msg.sender, tokenId);

      emit CrystalChangeEvent(tokenId, 0, 0);
    }

    function mintCrystals(uint32[] calldata spiralTokenIds, uint8 gen) public payable nonReentrant {
      // Only 5 gens per Spiral
      require(gen < 5, "InvalidGen");

      // Make sure there was enough ETH sent.
      // Mint prices are [0, 0.01 ether, 0.1 ether, 1 ether, 10 ether];
      uint256 mintPrice = 0;
      
      // Only the first gen is free. Each subsequent gen is 10x more expensive
      if (gen > 0) {
        mintPrice = 0.01 ether * uint256(10) ** uint256(gen-1);
        require (msg.value == mintPrice * spiralTokenIds.length, "NotEnoughETH");

        // All the ETH is dev fee
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "TransferFailed");
      }
      
      for (uint256 i = 0; i < spiralTokenIds.length; i++) {
        uint256 spiralTokenId = uint256(spiralTokenIds[i]);
        
        // Ensure user owns the spiralTokenID or has it staked
        (, address spiralOwner) = ISpiralStaking(spiralStaking).stakedTokenOwners(spiralTokenId);
        require(IERC721(spirals).ownerOf(spiralTokenId) == msg.sender 
            || spiralOwner == msg.sender, "NotOwnerOrStaker");

        // Make sure this gen has not been minted for the spiral
        require(mintedSpirals[spiralTokenId][gen].minted == false, "AlreadyMintedThisGen");

        // Mark this spiral's gen as minted. The tokenID will be the current tokenId counter
        mintedSpirals[spiralTokenId][gen] = MintedSpiralInfo(true, _tokenIdCounter);
        _mintCrystal(gen);
      }
    }


    function grow(uint32 tokenId, uint8 size) external nonReentrant {      
      require(ownerOf(tokenId) == msg.sender, "NotYoursToGrow");
      require(crystals[tokenId].size > 0, "DoesntExist");
      require(crystals[tokenId].size + size <= 100, "TooMuchGrowth");

      // Check if enough SpiralBits were sent
      uint256 SpiralBitsNeeded = uint256(size) * uint256(crystals[tokenId].sym) * SPIRALBITS_PER_SYM_PER_SIZE;
      require(IERC20(SpiralBits).balanceOf(msg.sender) >= SpiralBitsNeeded, "NotEnough SPIRALBITS");

      // Transfer the SpiralBits in
      IERC20(SpiralBits).transferFrom(msg.sender, address(this), SpiralBitsNeeded);

      // Burn half and store the rest
      uint256 spiralBitsToStore = SpiralBitsNeeded/2;
      ERC20Burnable(SpiralBits).burn(SpiralBitsNeeded - spiralBitsToStore);
      crystals[tokenId].spiralBitsStored += uint192(spiralBitsToStore);

      crystals[tokenId].size += size;

      emit CrystalChangeEvent(tokenId, 1, size);
    }

    function addSym(uint32 tokenId, uint8 numSymstoAdd) external nonReentrant {
      require(ownerOf(tokenId) == msg.sender, "NotYoursToAddSym");

      CrystalInfo memory c = crystals[tokenId];
      require(c.size > 0, "DoesntExist");
      require(c.sym + numSymstoAdd <= 20, "TooMuchSym");
      
      // Check if enough SpiralBits were sent
      uint256 SpiralBitsNeeded = SPIRALBITS_PER_SYM * uint256(numSymstoAdd);
      require(IERC20(SpiralBits).balanceOf(msg.sender) >= SpiralBitsNeeded, "NotEnough SPIRALBITS");

      // Reduce length proportionally
      uint8 newLength = uint8( uint256(c.size) * uint256(c.sym) / uint256(c.sym + numSymstoAdd) );
      require(newLength >= 30, "CrystalWouldBeTooSmall");

      // Burn ALL the SpiralBits
      IERC20(SpiralBits).transferFrom(msg.sender, address(this), SpiralBitsNeeded);
      ERC20Burnable(SpiralBits).burn(SpiralBitsNeeded);

      // Record the new size
      crystals[tokenId].size = newLength;
      crystals[tokenId].sym += numSymstoAdd;

      emit CrystalChangeEvent(tokenId, 2, numSymstoAdd);
    }

    function decSym(uint32 tokenId, uint8 numSymstoRemove) external nonReentrant {
      require(ownerOf(tokenId) == msg.sender, "NotYoursToAddSym");
      require(crystals[tokenId].size > 0, "DoesntExist");
      require(crystals[tokenId].sym - numSymstoRemove >= 3, "TooFewSym");

      // Check if enough SpiralBits were sent
      uint256 SpiralBitsNeeded = SPIRALBITS_PER_SYM * uint256(numSymstoRemove);
      require(IERC20(SpiralBits).balanceOf(msg.sender) >= SpiralBitsNeeded, "NotEnough SPIRALBITS");

      // Burn ALL the SpiralBits
      IERC20(SpiralBits).transferFrom(msg.sender, address(this), SpiralBitsNeeded);
      ERC20Burnable(SpiralBits).burn(SpiralBitsNeeded);

      // Record the new length
      crystals[tokenId].sym -= numSymstoRemove;

      emit CrystalChangeEvent(tokenId, 3, numSymstoRemove);
    }

    function shatter(uint32 tokenId) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "NotYoursToShatter");
        require(crystals[tokenId].size > 0, "DoesntExist");

        uint256 spiralBitsToReturn = crystals[tokenId].spiralBitsStored;

        _burn(tokenId);
        delete crystals[tokenId];

        // Refund the spiralBits
        IERC20(SpiralBits).transfer(msg.sender, spiralBitsToReturn);

        emit CrystalChangeEvent(tokenId, 4, 0);
    }

    // Returns a list of token Ids owned by _owner.
    function walletOfOwner(address _owner) public view
        returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        }

        uint256[] memory result = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            result[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return result;
    }

    // Returns a bitmap of all spirals generated for this spiralTokenId
    function mintedSpiralsForSpiral(uint256 spiralTokenId) public view returns (uint256 mintedBitMap) {
      for (uint256 i = 0; i < 5; i++) {
        bool isMinted = mintedSpirals[spiralTokenId][i].minted;
        mintedBitMap = (mintedBitMap << 1) | (isMinted ? 1 : 0);
      }
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}