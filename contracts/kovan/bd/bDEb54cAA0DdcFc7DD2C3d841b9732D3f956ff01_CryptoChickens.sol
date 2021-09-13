pragma solidity >=0.4.21 <0.6.0;

import "./ERC721Full.sol";
import "./Ownable.sol";

contract CryptoChickens is ERC721Full, Ownable {
  using SafeMath for uint256;

  uint256 public constant MAX_MEMEPACK = 100;
  uint256 public constant MAX_MEMEBREED = 45;
  uint256 public constant MAX_RAREPACK = 260;
  uint256 public constant MAX_COMMONPACK = 300;
  uint256 public constant reveal_timestamp = 1631497200000;
  uint256 public constant MEMEPRICE = 1 * 10**17;
  uint256 public constant RAREPRICE = 2 * 10**16;
  uint256 public constant COMMONPRICE = 1 * 10**15;
  uint256 public constant BREEDERFEE = 1 * 10**15;

  address payable public constant creatorAddress = 0xd2A68f34cFbe1901338999D4508428F7DB1B692F;
  address payable public constant donationAddress = 0xF1bCe759Fc679B573A24FB2C0a1AB62ce34f2aF0;

  uint256 public MEMEPACK = 0;
  uint256 public MEMEBREED = 0;
  uint256 public RAREPACK = 0;
  uint256 public COMMONPACK = 0;

  event CreateMemeChicken(uint256 indexed id);
  event CreateRareChicken(uint256 indexed id);
  event CreateCommonChicken(uint256 indexed id);
  constructor() ERC721Full("CryptoChickens", "MEMORY") public {
  }

  function totalMint() public view returns (uint256) {
    return totalSupply();
  }

  function starterMint(address _to, string memory _tokenURI) public {
    uint _tokenId = totalSupply().add(1);
    _mint(_to, _tokenId);
    _setTokenURI(_tokenId, _tokenURI);
  }

  function mintMemePack(address _to, string memory _tokenURI) public payable {
    require(msg.value >= MEMEPRICE);
    require(MEMEPACK < MAX_MEMEPACK);
    uint _tokenId = totalSupply().add(1);
    _mint(_to, _tokenId);
    _setTokenURI(_tokenId, _tokenURI);
    MEMEPACK++;
    emit CreateMemeChicken(_tokenId);
  }

  function mintMemeBreed(address _to, string memory _tokenURI) public payable {
    require(msg.value >= BREEDERFEE);
    require(MEMEBREED < MAX_MEMEBREED);
    uint _tokenId = totalSupply().add(1);
    _mint(_to, _tokenId);
    _setTokenURI(_tokenId, _tokenURI);
    MEMEBREED++;
    emit CreateMemeChicken(_tokenId);
  }

  function mintRarePack(address _to, string memory _tokenURI) public payable {
    require(msg.value >= RAREPRICE);
    require(RAREPACK < MAX_RAREPACK);
    uint _tokenId = totalSupply().add(1);
    _mint(_to, _tokenId);
    _setTokenURI(_tokenId, _tokenURI);
    RAREPACK++;
    emit CreateRareChicken(_tokenId);
  }

  function mintRareBreed(address _to, string memory _tokenURI) public payable {
    require(msg.value >= BREEDERFEE);
    uint _tokenId = totalSupply().add(1);
    _mint(_to, _tokenId);
    _setTokenURI(_tokenId, _tokenURI);
    emit CreateRareChicken(_tokenId);
  }

  function mintCommonPack(address _to, string memory _tokenURI) public payable {
    require(msg.value >= COMMONPRICE);
    require(COMMONPACK < MAX_COMMONPACK);
    uint _tokenId = totalSupply().add(1);
    _mint(_to, _tokenId);
    _setTokenURI(_tokenId, _tokenURI);
    COMMONPACK++;
    emit CreateCommonChicken(_tokenId);
  }

  function generalBreed(address _to, string memory _tokenURI) public payable {
    require(msg.value >= BREEDERFEE);
    uint _tokenId = totalSupply().add(1);
    _mint(_to, _tokenId);
    _setTokenURI(_tokenId, _tokenURI);
  }

  function withdrawALL() public payable onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0);
    donationAddress.transfer(balance.mul(35).div(100));
    creatorAddress.transfer(address(this).balance);
  }

}