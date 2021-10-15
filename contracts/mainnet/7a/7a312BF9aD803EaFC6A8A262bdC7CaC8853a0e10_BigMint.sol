/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.12;
interface A { 
function createProtonForSale(  address creator,  address receiver,  string memory tokenMetaUri,  uint256 annuityPercent,  uint256 royaltiesPercent,  uint256 salePrice) external returns (uint256 newTokenId);
}

contract BigMint{
    
     address payable public owner;
        uint32 public NFTcount=0;
        event mintSuccessful(uint256, uint32);
    mapping (uint256 => bool) public TokenIds;
   constructor() public payable {
     owner = msg.sender;
   }
    function mint_nft() public payable returns (uint256 tokenId){
   A minter = A(0x63174FA9680C674a5580f7d747832B2a2133Ad8f);
  require(msg.value >= 100000000000000000 || msg.sender==owner);
      require(NFTcount<10000);  
     NFTcount++;
      tokenId=minter.createProtonForSale(owner,msg.sender,string(abi.encodePacked('https://ipfs.io/ipfs/QmaVP2ka3cH3fvoRTZXoimQJu4DEpmZqmpnaLEk3wC22Dr/', uint2str(NFTcount), '.json'))
    ,0,300,0);
    TokenIds[tokenId]=true;
     emit mintSuccessful(tokenId,NFTcount);
    return tokenId;
    }
     function uint2str(
  uint256 _i
)
  internal
  pure
  returns (string memory str)
{
  if (_i == 0)
  {
    return "0";
  }
  uint256 j = _i;
  uint256 length;
  while (j != 0)
  {
    length++;
    j /= 10;
  }
  bytes memory bstr = new bytes(length);
  uint256 k = length;
  j = _i;
  while (j != 0)
  {
    bstr[--k] = bytes1(uint8(48 + j % 10));
    j /= 10;
  }
  str = string(bstr);
}
    function totalBalance() external view returns(uint) {
     return payable(address(this)).balance;
   }
 function withdrawFunds() external {
          require(msg.sender == owner);
     msg.sender.transfer(this.totalBalance());
   }
   

}