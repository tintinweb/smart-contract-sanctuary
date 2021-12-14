pragma solidity 0.8.7;
 
import "./token.sol";
import "./ownable.sol";
import "./tokenMeta.sol";
import "./erc721.sol";
 
contract collectionsNFT is NFTokenMetadata, Ownable {
    uint256 currentID = 0;
    constructor() payable {
      nftName = "Nebula 41 Collections";
      nftSymbol = "COL";
    }
    fallback() external payable { }
    receive() external payable { }

    address[] public nebulaTeamAddresses;

    function collectionsMint(address _to, string memory _uri) public {
      require(isNebulaTeam(msg.sender));
      currentID = currentID+1;
      
      uint256 _tokenId = currentID;
      super._mint(_to, _tokenId);
      super._setTokenUri(_tokenId, _uri);
    } 
    
    function extractEther() external onlyOwner {
      payable(msg.sender).transfer(address(this).balance);
    }

    function nebulaTeam(address[] calldata _users) public onlyOwner {
      delete nebulaTeamAddresses;
      nebulaTeamAddresses = _users;
    }

    function isNebulaTeam(address _user) public view returns (bool) {
      for (uint i = 0; i < nebulaTeamAddresses.length; i++) {
        if (nebulaTeamAddresses[i] == _user) {
            return true;
        }
      }
      return false;
    }
 }