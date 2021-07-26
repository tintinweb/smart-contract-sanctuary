pragma solidity 0.5.17;

import "./ERC721Token.sol";
import "./ERC20Interface.sol";
import "./Freezable.sol";

/**
 * @title Base ERC721 token
 * @author Prashant Prabhakar Singh [[email protected]]
 * This contract implements basic ERC721 token functionality with bulk functionalities
 */
contract BaseERC721 is ERC721Token, Freezable {

  constructor(string memory name, string memory symbol, string memory _baseTokenURI) public  ERC721Token(name, symbol){
    baseTokenURI = _baseTokenURI;
  }

  /**
   * @dev Updates the base URL of token
   * Reverts if the sender is not owner
   * @param _newURI New base URL
   */
  function updateBaseTokenURI(string memory _newURI)
    public
    onlyOwner
    noEmergencyFreeze
  {
    baseTokenURI = _newURI;
  }

  /**
   * @dev Mints new token on blockchain
   * Reverts if the sender is not operator with level 1
   * @param _id Id of NFT to be minted
   * @dev URI is not provided because URI will be deducted based on baseURL
   */
  function mint(uint256 _id, address _to)
    public
    onlyDeputyOrOwner
    noEmergencyFreeze
    returns (bool)
  {
    super._mint(_to, _id);
    return true;
  }

  function bulkMint(uint[] memory _ids, address[] memory _users)
    public
    onlyDeputyOrOwner
    noEmergencyFreeze
    returns (bool)
  {
    require(_ids.length == _users.length, "Invalid params");
    for(uint i=0; i<_ids.length; i++) {
      super._mint(_users[i], _ids[i]);
    }
    return true;
  }

  /**
   * @dev Transfer tokens (similar to ERC-20 transfer)
   * Reverts if the sender is not owner of the NFT or approved
   * @param _to address to which token is transferred
   * @param _tokenId Id of NFT being transferred
   */
  function transfer(address _to, uint256 _tokenId)
    public
    noEmergencyFreeze
    returns (bool)
  {
    safeTransferFrom(msg.sender, _to, _tokenId);
    return true;
  }

  /**
   * @dev Burn an existing NFT
   * @param _id Id of NFT to be burned
   */
  function burn(uint _id)
    public
    noEmergencyFreeze
    returns (bool)
  {
    super._burn(msg.sender, _id);
    return true;
  }

  //////////////////////////////////////////
  // PUBLICLY ACCESSIBLE METHODS (CONSTANT)
  //////////////////////////////////////////

}