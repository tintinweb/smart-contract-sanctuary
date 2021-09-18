//Abdullah Rangoonwala
pragma solidity 0.8.7;
 
import "./token.sol";
import "./ownable.sol";
import "./tokenMeta.sol";
 
contract newNFT is NFTokenMetadata, Ownable {
 
    uint256 constant supply = 10;  
    uint256 currentID = 0;
    string[] uIDs = [
      "ipfs://QmR22aaRY9Jp9Qa4H5Dn2eYkvk6SSYCjtXohjLPHfR37HK"
      "jdjadjh"
      "dajdaj"
      "dkjksajs"
      "ksdkjadhj"
      "jakfhjfha"
      "kjahfjhjf"
      "lafadjfkja"
      "kfjhajfhadj"
      "jfajfnmdfn"
      ]; 
  constructor() payable {
    nftName = "Gezegen NFT";
    nftSymbol = "GFT";
  }
  fallback() external payable { }
  receive() external payable { }
 
  function mint(address _to) public payable {
    require(currentID<supply, "Max Supply Reached");
    require(msg.value >= 10000000000000000 wei, "Invalid ETH Amount");
    currentID = currentID+1;
    uint256 _tokenId = currentID;
    string memory _uri = uIDs[currentID];
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }  
  
  function extractEther() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
 
}