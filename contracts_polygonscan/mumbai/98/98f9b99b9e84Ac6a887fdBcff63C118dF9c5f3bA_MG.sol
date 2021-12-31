// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import {ECDSA} from "./ECDSA.sol";
import {Strings} from "./Strings.sol";
import {Counters} from "./Counters.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract MG is ERC721Enumerable, Ownable, ReentrancyGuard {
	using SafeMath for uint256;
  using Counters for Counters.Counter;

  uint256 public constant MaxNFT = 10000;
  uint256 public constant MaxMarketingNFT = 200;
  uint256 public constant SaleMintableMax = 10;
  uint256 public constant PresaleMintableMax = 1;

  bool public presale;
  bool public sale;
  bool private _singleWithdrawal;
  bool private _metaUrlLocked;
  uint256 public price = 0.05 ether;
  uint256 public saleEndTimestamp;

  // centralizing Metadata for now to provide extra features such as name change and more
  string public metaUrl = "https://api.mousegangnft.com/meta/";

  address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
  address public mgAddress = 0xE3Af2fb66c545b77BFD7Bfc10F5FaE3fEbdEeFC4;
  address public signerAddress = 0xE3Af2fb66c545b77BFD7Bfc10F5FaE3fEbdEeFC4;
  address private constant _beneficiaryAddress = 0xE3Af2fb66c545b77BFD7Bfc10F5FaE3fEbdEeFC4;
 
  Counters.Counter private _tokenIdTracker;

  constructor() ERC721("MG", "MG") {}

  // SALE
  function buy(bool isPresale, bytes memory signature, uint256 timestamp, uint256 amount) external payable nonReentrant {
    require(isPresale ? presale : sale, "MG_SALE_NOT_LIVE");
    require(price.mul(amount) <= msg.value, "MG_NOT_ENOUGH_ETH");
    if (isPresale) {
      require(balanceOf(_msgSender()).add(amount) <= PresaleMintableMax, "MG_LIMIT_REACHED");
    } else {
      require(amount <= SaleMintableMax, "MG_LIMIT_REACHED");
    }
    require(tokenCount().add(amount) <= MaxNFT, "MG_MAX_REACHED");
    address signer = _getSigner(_msgSender(), timestamp, signature);
    require(signerAddress == signer, "MG_FORBIDDEN");

    for(uint256 i = 0; i < amount; i++) {
      if (tokenCount() < MaxNFT) {
        _safeMint(_msgSender(), tokenCount());
        _tokenIdTracker.increment();
      }
    }
  }

  function tokenCount() public view returns (uint256) {
    return _tokenIdTracker.current();
  }

  function isApprovedForAll(address owner_, address operator) override public view returns (bool){
      // Whitelist OpenSea proxy contract for easy trading.
      ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
      if (address(proxyRegistry.proxies(owner_)) == operator) {
          return true;
      }

      return super.isApprovedForAll(owner_, operator);
  }

  // REFUND 50% of price
  function isRefundActive() public view returns (bool) {
    return (block.timestamp < (saleEndTimestamp + 30 days));
  }

  function refund(uint256 _tokenId) external nonReentrant {
    require(mgAddress != address(0), "MG_NULL_ADDRESS");
    require(isRefundActive(), "MG_REFUND_EXPIRED");
    require(_isApprovedOrOwner(_msgSender(), _tokenId), "MG_FORBIDDEN");

    _transfer(_msgSender(), mgAddress, _tokenId);
    payable(_msgSender()).transfer(price.div(2));
  }

  // ADMIN
  function setPrice(uint256 _price) external onlyOwner {
    require(!presale, "MG_PRESALE_LIVE");
    require(!sale, "MG_SALE_LIVE");
    price = _price;
  }

  function toggleState(bool _presale, bool _sale) external onlyOwner {
    if (_presale) {
      if (!presale) {
        require(mgAddress != address(0), "MG_NULL_ADDRESS");
      }

      presale  = !presale;
    }

    if (_sale) {
      if (sale) {
        saleEndTimestamp = block.timestamp;
      } else {
        require(mgAddress != address(0), "MG_NULL_ADDRESS");
      }

      sale = !sale;
    }
  }

  function reserve(address addr, uint256 amount, bool marketing) external onlyOwner {
    require(!presale, "MG_PRESALE_LIVE");
    require(!sale, "MG_SALE_LIVE");

    uint256 index = tokenCount();
    uint256 take = index.add(amount);

    uint256 max = marketing ? MaxMarketingNFT : MaxNFT;
    take = take > max ? max : take;

    for (uint256 i = index; i < take; i++) {
      _safeMint(addr, tokenCount());
      _tokenIdTracker.increment();
    }
  }

  function withdraw(bool singleHalf) external onlyOwner nonReentrant {
    if (singleHalf && _singleWithdrawal) return;

    uint256 balance = address(this).balance;
    if (balance <= 0) return;
    if (singleHalf) balance = balance.div(2);

    require(mgAddress != address(0), "MG_NULL_ADDRESS");
    if (!singleHalf) require(!isRefundActive() && !presale && !sale, "MG_REFUND_ACTIVE_OR_SALE");

    uint256 beneficiaryBalance = balance.mul(7).div(10);
    payable(_beneficiaryAddress).transfer(beneficiaryBalance);
    payable(mgAddress).transfer(balance.sub(beneficiaryBalance));
    
    if (singleHalf) _singleWithdrawal = true;
  }

  function setMGAddress(address _address) external onlyOwner {
    mgAddress = _address;
  }

  function setSignerAddress(address _address) external onlyOwner {
    signerAddress = _address;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), "MG_TOKEN_NOT_FOUND");
    return string(abi.encodePacked(metaUrl, Strings.toString(tokenId)));
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    require(!_metaUrlLocked, "MG_META_LOCKED");
    metaUrl = baseURI;
  }

  function lockMetadata() external onlyOwner {
    _metaUrlLocked = true;
  }

  function burnMany(uint256[] calldata tokenIds) external onlyOwner {
     for (uint256 i = 0; i < tokenIds.length; i++) {
     _burn(tokenIds[i]);
    }
  }

  // HELPERS
  function _getSigner(address _address, uint256 timestamp, bytes memory signature) private pure returns (address) {
    bytes32 hash = keccak256(abi.encodePacked(
      "\x19Ethereum Signed Message:\n32",
      keccak256(abi.encodePacked(_address, timestamp)))
    );
    return ECDSA.recover(hash, signature);
  }
}