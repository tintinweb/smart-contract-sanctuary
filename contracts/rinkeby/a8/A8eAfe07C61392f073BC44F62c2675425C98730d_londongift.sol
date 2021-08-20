// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20FixedSupply.sol";
import "./Erc721.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract londongift is Ownable, ERC721 {
    using Strings for uint256;

    uint256 constant MAX_MINT_PER_TX = 5;

    ERC20FixedSupply public immutable payableErc20;
    uint256 public immutable mintPrice;
    uint256 public immutable maxMintPerAddress;
    uint256 public immutable maxSupply;

    uint256 public startingIndex = 0;
    uint256 public mintStartAtBlockNum;
    uint256 public revealStartAtBlockNum;

    address public immutable burnaddress;
    string public baseMetadataURI;
    string public contractURI;

    uint256 public tokenIndex;

    mapping(address => uint256) public mintedAmounts;

    constructor (
      string memory name_,
      string memory symbol_,
      address _payableErc20,
      uint256 _mintPrice,
      uint256 _maxMintPerAddress,
      uint256 _maxSupply,
      address _burnaddress
    ) ERC721(name_, symbol_) 
    {
      payableErc20 = ERC20FixedSupply(_payableErc20);
      mintPrice = _mintPrice;
      maxMintPerAddress = _maxMintPerAddress;
      maxSupply = _maxSupply;
      burnaddress = _burnaddress;
    }


    function setBaseMetadataURI(string memory _baseMetadataURI) public onlyOwner {
      baseMetadataURI = _baseMetadataURI;
    }

    function setContractURI(string calldata newContractURI) external onlyOwner {
        contractURI = newContractURI;
    }

    function setRevealStartAtBlockNum(uint256 _revealStartAtBlockNum) public onlyOwner {
      revealStartAtBlockNum = _revealStartAtBlockNum;
    }

  // function setMintStartAtBlockNum(uint256 _mintStartAtBlockNum) public onlyOwner {
  //    mintStartAtBlockNum = _mintStartAtBlockNum;
  //  }

    modifier onlyUnderMaxSupply(uint mintAmount) {
      require(tokenIndex + mintAmount <= maxSupply, 'max supply minted');
      _;
    }

     modifier onlyUnderMaxMintPerAddress() {
       require(mintedAmounts[_msgSender()] < maxMintPerAddress, 'Max supply per address minted');
       _;
     }

    modifier onlyMintUnderMaxPerTx(uint256 mintAmount) {
      require(mintAmount < MAX_MINT_PER_TX, 'too many mints in one go');
      _;
    }

  //  modifier onlyAfterMintStartAtBlockNum() {
  //    require(mintStartAtBlockNum != 0 && block.number > mintStartAtBlockNum, 'too early');
  //    _;
  //  }

    function _baseURI() override internal view virtual returns (string memory) {
      if (startingIndex == 0) {
        return "";
      }
      return baseMetadataURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 id = tokenId;

        string memory baseURI = _baseURI();
        
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, id.toString())) : "";
    }
    
    function mint(uint mintAmount) onlyUnderMaxSupply(mintAmount) onlyMintUnderMaxPerTx(mintAmount) onlyUnderMaxMintPerAddress() public {
      // ensure approval is met
      require(payableErc20.allowance(_msgSender(), address(this)) >= (mintPrice * mintAmount), "Allowance not set to mint");
      require(payableErc20.balanceOf(_msgSender()) >= (mintPrice * mintAmount), "Not enough token to mint");
      // transfer payableERC20
      payableErc20.transferFrom(_msgSender(), burnaddress, (mintPrice * mintAmount));
      for (uint i = 0; i < mintAmount; ++i) {
        // mint token
        _safeMint(_msgSender(), tokenIndex);
        // increment
        tokenIndex++;
      }

      if (startingIndex == 0 && (tokenIndex == maxSupply || (block.number > revealStartAtBlockNum && revealStartAtBlockNum != 0))) {
        startingIndex += 1;
        }
      }
}