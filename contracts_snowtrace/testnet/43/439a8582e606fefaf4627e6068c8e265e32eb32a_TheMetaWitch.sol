// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";

contract TheMetaWitch is ERC721, Ownable {
  using SafeMath for uint256;
  uint public constant MAX_NFTS = 10000;
  bool public isActive = false;
  address public feeAddress1 = 0xC59d1e6Cd25A2384e7c1fCF0a48F549ddf42fBab;
  address public feeAddress2 = 0x6aDd12F9e62cAb0ee3cc95d8220695640Ae3f56b;
  address payable feeReceiver3;
  address payable feeReceiver2;

  string public METADATA_PROVENANCE_HASH = "";

  constructor() ERC721("TheMetaWitch","TheMetaWitch")  {
    setBaseURI("https://TheMetaWitch.com/api/nfts/detail/");
    feeReceiver = payable(feeAddress1);
    feeReceiver2 = payable(feeAddress2);

  }


  function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
      // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 index;
      for (index = 0; index < tokenCount; index++) {
        result[index] = tokenOfOwnerByIndex(_owner, index);
      }
      return result;
    }
  }

  function getNfts(uint256 count) public payable {
    require(isActive, "Sales is not started yet");
    require(totalSupply() < MAX_NFTS, "Sale has already ended");
    require(count > 0 && count <= 11, "You can mint minimum 1 and maximum of 11 nft");
    require(totalSupply().add(count) <= MAX_NFTS, "Exceeds MAX_NFTS");
    require(msg.value >= calculatePrice().mul(count), "AVAX value sent is below the price");

    for (uint i = 0; i < count; i++) {
      uint mintIndex = totalSupply() + 1;
      _safeMint(msg.sender, mintIndex);
    }
  }

  function calculatePrice() public view returns (uint256) {
    require(isActive == true, "Sale hasn't started");
    require(totalSupply() < MAX_NFTS, "Sale has already ended");

    //uint currentSupply = totalSupply();


    return 15000000000000000;
  }

  function setProvenanceHash(string memory _hash) public onlyOwner {
    METADATA_PROVENANCE_HASH = _hash;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _setBaseURI(baseURI);
  }

  function startSales() public onlyOwner {
    isActive = true;
  }

  function pauseSales() public onlyOwner {
    isActive = false;
  }


  function serviceFee(uint256 amount) internal pure returns (uint256) {
    uint256 toOwner = SafeMath.mul(amount, 5);

    return SafeMath.div(toOwner, 100);
  }

  function withdraw() public onlyOwner {
    uint256 freeBalance = address(this).balance;
    uint256 balance1 = freeBalance / 2;
    uint256 balance2 = freeBalance - balance1;

    require(payable(feeReceiver).send(balance1));
    require(payable(feeReceiver2).send(balance2));
  }

  function withdrawTokens(address tokenAddress) public onlyOwner
  {
    IERC20 token = IERC20(tokenAddress);

    uint256 amount = token.balanceOf(address(this));
    uint256 amount1 = amount / 2;
    uint256 amount2 = amount - amount1;

    token.approve(address(this), amount);

    token.transferFrom(address(this), feeAddress1, amount1);
    token.transferFrom(address(this), feeAddress2, amount2);
  }

}