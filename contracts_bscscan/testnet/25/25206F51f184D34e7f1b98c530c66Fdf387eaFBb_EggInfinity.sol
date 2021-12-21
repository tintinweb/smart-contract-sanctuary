// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./nf-token-metadata.sol";
import "./nf-token-enumerable.sol";
import "./ownable.sol";

/**
 * @dev This is an example contract implementation of NFToken with enumerable and metadata
 * extensions.
 */
contract EggInfinity is NFTokenEnumerable, NFTokenMetadata, Ownable {
    
    bool public extMintEnable;
    mapping (address=>bool) public extMintAddressEnableMap;
    address[] private extMintAddressList;
    
    mapping (address=>bool) public discardTokenAddressEnableMap;
    address[] private discardTokenAddressList;

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
    //     _setBaseURI(baseURI);
    // }

    function getExtMintAddressList() view external onlyOwner returns(address[] memory) {
        return extMintAddressList;
    }

    function setExtMintEnable(bool _enable) external onlyOwner {
        extMintEnable = _enable;
    }

    function setExtMintAddress(address _address, bool _enable) external onlyOwner {
        require(_address != address(0));

        extMintAddressEnableMap[_address] = _enable;

        bool status = false;
        for (uint256 i= 0; i< extMintAddressList.length; i++) {
            if (extMintAddressList[i]==_address) {
                status = true;
                break;
            }
        }
        if (!status) {
            extMintAddressList.push(_address);
        }
    }

    //caller: outer contract
    //msg.sender: outer contract address
    //tx.origin: outer contract caller
    function extMint(address _to,uint256 _tokenId,string memory _uri) external {
        require(extMintEnable);
        require(extMintAddressEnableMap[msg.sender]);

        super._mint(_to, _tokenId);
        super._setTokenUri(_tokenId, _uri);
    }
    
    
    function getDiscardTokenAddressList() view external onlyOwner returns(address[] memory) {
        return discardTokenAddressList;
    }

    function setDiscardTokenAddress(address _address, bool _enable) external onlyOwner {
        require(_address != address(0));

        discardTokenAddressEnableMap[_address] = _enable;

        bool status = false;
        for (uint256 i= 0; i< discardTokenAddressList.length; i++) {
            if (discardTokenAddressList[i]==_address) {
                status = true;
                break;
            }
        }
        if (!status) {
            discardTokenAddressList.push(_address);
        }
    }

    //caller: outer contract
    function discardToken(address _owner, uint256 _tokenId) external returns(bool) {
        require(discardTokenAddressEnableMap[msg.sender]);

        return NFToken._discardToken(_owner, _tokenId);
    }



    function getNFTokens(address _owner) external view returns (uint256[] memory) {
        return NFTokenEnumerable._getOwnerNFTTokens(_owner);
    }

    function updateTokenUrl(uint256 _tokenId,string calldata _uri) external onlyOwner {
        super._setTokenUri(_tokenId, _uri);
    }
    
    function batchMint(address[] memory _toAddresses,uint256[] memory _tokenIds,string[] calldata _tokenUris) external onlyOwner {
        require(_toAddresses.length == _tokenIds.length && _toAddresses.length == _tokenUris.length);
        
        for (uint256 i= 0; i< _toAddresses.length; i++) {
            super._mint(_toAddresses[i], _tokenIds[i]);
            super._setTokenUri(_tokenIds[i], _tokenUris[i]);
        }
    }

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