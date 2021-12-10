// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../nf-token-metadata.sol";
import "../nf-token-enumerable.sol";
import "../ownable.sol";
import "../safe-math.sol";
import "../strings-utils.sol";

/**
 * @dev This is an example contract implementation of NFToken with enumerable and metadata
 * extensions.
 */
contract EggInfinity is NFTokenEnumerable, NFTokenMetadata, Ownable {

    using SafeMath for uint256;

    struct activityStruct {
        uint256 id;
        uint256 price;
        uint256 count;
        uint256 remain;
        uint256 startTokenId;
        uint256 startUrlId;
        string urlPre;
        string urlExt;
        bool enable;
    }
    mapping (uint256=>activityStruct) public activityMap;
    uint256[] private activityIds;

    address public activityCFOAddress;
    
    /**
    * @dev Contract constructor.
    * @param _name A descriptive name for a collection of NFTs.
    * @param _symbol An abbreviated name for NFTokens.
    */
    constructor(string memory _name, string memory _symbol) {
        nftName = _name;
        nftSymbol = _symbol;
    }
    
    // function setURIPrefix(string memory baseURI) internal {
    // _setBaseURI(baseURI);
    // }

    function setActivityCFOAddress(address _val) external onlyOwner {
        require(_val != address(0));//,"Invalid address");

        activityCFOAddress = _val;
    }

    function getActivityIds() view external onlyOwner returns(uint256[] memory) {
        return activityIds;
    }

    function addActivity(
        uint256 _id, 
        uint256 _price,
        uint256 _count, 
        uint256 _tokenId,
        uint256 _urlId,
        string memory _urlPre,
        string memory _urlExt,
        bool _enable) external onlyOwner{
        require(activityMap[_id].id==0);//,"id has exist");

        activityMap[_id] = activityStruct(_id,_price,_count,_count,_tokenId,_urlId,_urlPre,_urlExt,_enable);
        activityIds.push(_id);
    }
    
    function resetActivity(uint256 _id, uint256 _price, uint256 _count) external onlyOwner {
        _checkActivityExist(_id);
        if (_count > activityMap[_id].count) activityMap[_id].remain = activityMap[_id].remain.add( _count.sub(activityMap[_id].count) );
        if (_count < activityMap[_id].count && _count < activityMap[_id].remain) activityMap[_id].remain = _count;
        activityMap[_id].price = _price;
        activityMap[_id].count = _count;
    }
    
    function setActivityEnable(uint256 _id, bool enable) external onlyOwner {
        _checkActivityExist(_id);
        activityMap[_id].enable = enable;
    }

    function getActivity(uint256 _id) external view returns(uint256 id, uint256 price, uint256 count, uint256 remain) {
        _checkActivityExist(_id);
        id = activityMap[_id].id;
        price = activityMap[_id].price;
        count = activityMap[_id].count;
        remain = activityMap[_id].remain;
    }
    
    function activityBuy(uint256 _id) payable external {
        _checkActivityExist(_id);
        require(activityMap[_id].enable);   //,"activity is disabled");
        require(activityMap[_id].remain > 0 && activityMap[_id].remain <= activityMap[_id].count);   //,"activity has ended");
        require(activityCFOAddress != address(0));   //,"activity cfo address is empty");
        require(msg.value >= activityMap[_id].price);   //,"amount low than price"
        payable(activityCFOAddress).transfer(msg.value);
        
        uint256 countCost = activityMap[_id].count.sub( activityMap[_id].remain );
        uint256 tokenId = activityMap[_id].startTokenId.add( countCost );
        uint256 tokenUrlId = activityMap[_id].startUrlId.add( countCost );
        string memory tokenUrl = Strings.concatString( Strings.concatString(activityMap[_id].urlPre,Strings.toString(tokenUrlId)), activityMap[_id].urlExt );
        super._mint(msg.sender, tokenId);
        super._setTokenUri(tokenId, tokenUrl);
        
        activityMap[_id].remain = activityMap[_id].remain.sub(1);
    }

    function _checkActivityExist(uint256 _id) internal view {
        require(activityMap[_id].id!=0);//,"id not exist");
    }



    /**
    * allows owner to withdraw funds from minting
    */
    // function withdraw() external onlyOwner {
    //     payable(owner()).transfer(address(this).balance);
    // }

    /**
    * @dev Mints a new NFT.
    * @param _to The address that will own the minted NFT.
    * @param _tokenId of the NFT to be minted by the msg.sender.
    * @param _uri String representing RFC 3986 URI.
    */
    function mint(address _to,uint256 _tokenId,string calldata _uri) external onlyOwner {
        super._mint(_to, _tokenId);
        super._setTokenUri(_tokenId, _uri);
    }
    
    /**
    * @dev Removes a NFT from owner.
    * @param _tokenId Which NFT we want to remove.
    */
    function burn(uint256 _tokenId) external onlyOwner {
        super._burn(_tokenId);
    }
    


    function updateTokenUrl(uint256 _tokenId,string calldata _uri) external onlyOwner {
        super._setTokenUri(_tokenId, _uri);
    }
    
    function getAllNFTokens(address _owner) external onlyOwner view returns (uint256[] memory owning_tokens, uint256[] memory destroyed_tokens) {
        owning_tokens = NFTokenEnumerable._getOwnerNFTTokens(_owner);
        destroyed_tokens =  NFToken._getDestroyedNFTokens(_owner);
        //return (owning_tokens,destroyed_tokens);
    }
    
    // function getNFTokens(address _owner) external onlyOwner view returns (uint256[] memory) {
    //     return NFTokenEnumerable._getOwnerNFTTokens(_owner);
    // }

    function advance(uint256 _tokenId, uint256 _costTokenId) external {
        super._advance(_tokenId,_costTokenId);
    }
    
    function destroy(uint256 _tokenId) external {
        super._destroy(_tokenId);
    }

    function getAdvanceCostTokens(uint256 _tokenId) external onlyOwner view returns (uint256[] memory) {
        return NFToken._getAdvanceCostTokens(_tokenId);
    }
    
    function getOwnerOfDestroyedToken(uint256 _tokenId) external onlyOwner view returns (address) {
        return NFToken._getOwnerOfDestroyedToken(_tokenId);
    }
    
    function _advance(uint256 _tokenId, uint256 _costTokenId) internal override(NFToken, NFTokenEnumerable) {
        NFTokenEnumerable._advance(_tokenId,_costTokenId);
    }
    
    function _destroy(uint256 _tokenId) internal override(NFToken, NFTokenEnumerable) {
        NFTokenEnumerable._destroy(_tokenId);
    }
    
  /**
   * @dev Mints a new NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * mint function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @param _to The address that will own the minted NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   */
  function _mint(address _to,uint256 _tokenId) internal override(NFToken, NFTokenEnumerable) virtual {
    NFTokenEnumerable._mint(_to, _tokenId);
  }

  /**
   * @dev Burns a NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * burn function. Its purpose is to show and properly initialize data structures when using this
   * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
   * NFT.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn(uint256 _tokenId) internal override(NFTokenMetadata, NFTokenEnumerable) virtual {
    NFTokenEnumerable._burn(_tokenId);
    if (bytes(idToUri[_tokenId]).length != 0)
    {
      delete idToUri[_tokenId];
    }
  }

  /**
   * @dev Removes a NFT from an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _from Address from wich we want to remove the NFT.
   * @param _tokenId Which NFT we want to remove.
   */
  function _removeNFToken(address _from,uint256 _tokenId) internal override(NFToken, NFTokenEnumerable) {
    NFTokenEnumerable._removeNFToken(_from, _tokenId);
  }

  /**
   * @dev Assigns a new NFT to an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _to Address to wich we want to add the NFT.
   * @param _tokenId Which NFT we want to add.
   */
  function _addNFToken(address _to,uint256 _tokenId) internal override(NFToken, NFTokenEnumerable) {
    NFTokenEnumerable._addNFToken(_to, _tokenId);
  }

   /**
   * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
   * extension to remove double storage(gas optimization) of owner nft count.
   * @param _owner Address for whom to query the count.
   * @return Number of _owner NFTs.
   */
  function _getOwnerNFTCount(address _owner) internal override(NFToken, NFTokenEnumerable) view returns (uint256) {
    return NFTokenEnumerable._getOwnerNFTCount(_owner);
  }

}