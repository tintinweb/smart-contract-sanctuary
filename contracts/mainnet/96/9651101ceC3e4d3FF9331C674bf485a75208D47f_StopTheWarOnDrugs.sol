// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;


import "./nf-token-enumerable.sol";
import "./nf-token-metadata.sol";
import "./owned.sol";
import "./erc2981-per-token-royalties.sol";

contract StopTheWarOnDrugs is NFTokenEnumerable, NFTokenMetadata, 
///Owned, 
ERC2981PerTokenRoyalties {

    /** 
    * @dev error when an NFT is attempted to be minted after the max
    * supply of NFTs has been already reached.
    */
    string constant MAX_TOKENS_MINTED = "0401";

    /** 
    * @dev error when the message for an NFT is trying to be set afet
    * it has been already set.
    */
    string constant MESSAGE_ALREADY_SET = "0402";

    /** 
    * @dev The message doesn't comply with the size restrictions
    */
    string constant NOT_VALID_MSG = "0403";

    /** 
    * @dev Can't pass 0 as value for the argument
    */
    string constant ZERO_VALUE = "0404";

    /** 
    * @dev The maximum amount of NFTs that can be minted in this collection
    */
    uint16 constant MAX_TOKENS = 904;

    /** 
    * @dev Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    * which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    */
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    /**
    * @dev Mapping from NFT ID to message.
    */
    mapping (uint256 => string) private idToMsg;


    constructor(string memory _name, string memory _symbol){
        isOwned();
        nftName = _name;
        nftSymbol = _symbol;
    }

    /**
    * @dev Mints a new NFT.
    * @notice an approveForAll is given to the owner of the contract.
    * This is due to the fact that the marketplae of this project will 
    * own this contract. Therefore, the NFTs will be transactable in 
    * the marketplace by default without any extra step from the user.
    * @param _to The address that will own the minted NFT.
    * @param _tokenId of the NFT to be minted by the msg.sender.
    * @param royaltyRecipient the address that will be entitled for the royalties.
    * @param royaltyValue the percentage (from 0 - 10000) of the royalties
    * @notice royaltyValue is amplified 100 times to be able to write a percentage
    * with 2 decimals of precision. Therefore, 1 => 0.01%; 100 => 1%; 10000 => 100%
    * @notice the URI is build from the tokenId since it is the SHA2-256 of the
    * URI content in IPFS.
    */
    function mint(address _to, uint256 _tokenId, 
                  address royaltyRecipient, uint256 royaltyValue) 
      external onlyOwner 
      {
        _mint(_to, _tokenId);
        //uri setup
        string memory _uri = getURI(_tokenId);
        idToUri[_tokenId] = _uri;
        //royalties setup
         if (royaltyValue > 0) {
            _setTokenRoyalty(_tokenId, royaltyRecipient, royaltyValue);
        }
        //approve marketplace
        if(!ownerToOperators[_to][owner]){
           ownerToOperators[_to][owner] = true;
         }
    }

    /**
    * @dev Mints a new NFT.
    * @param _to The address that will own the minted NFT.
    * @param _tokenId of the NFT to be minted by the msg.sender.
    */
    function _mint( address _to, uint256 _tokenId ) internal override (NFTokenEnumerable, NFToken){
        require( tokens.length < MAX_TOKENS, MAX_TOKENS_MINTED );
        super._mint(_to, _tokenId);
        
    }


    /**
   * @dev Assignes a new NFT to an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _to Address to wich we want to add the NFT.
   * @param _tokenId Which NFT we want to add.
   */
  function _addNFToken(  address _to, uint256 _tokenId ) internal override  (NFTokenEnumerable, NFToken){
    super._addNFToken(_to, _tokenId);
  }

  function addNFToken(address _to, uint256 _tokenId) internal {
        _addNFToken(_to, _tokenId);
    }

    /**
   * @dev Burns a NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * burn function. Its purpose is to show and properly initialize data structures when using this
   * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
   * NFT.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn( uint256 _tokenId ) internal override (NFTokenEnumerable, NFTokenMetadata) {
    super._burn(_tokenId);
  }

  function burn(uint256 _tokenId ) public onlyOwner {
      //clearing the uri
      idToUri[_tokenId] = "";
      //clearing the royalties
      _setTokenRoyalty(_tokenId, address(0), 0);
      //burning the token for good
      _burn( _tokenId);
  }

  /**
   * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
   * extension to remove double storage(gas optimization) of owner nft count.
   * @param _owner Address for whom to query the count.
   * @return Number of _owner NFTs.
   */
  function _getOwnerNFTCount(  address _owner  ) internal override(NFTokenEnumerable, NFToken) view returns (uint256) {
    return super._getOwnerNFTCount(_owner);
  }

  function getOwnerNFTCount(  address _owner  ) public view returns (uint256) {
    return _getOwnerNFTCount(_owner);
  }

/**
   * @dev Removes a NFT from an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _from Address from wich we want to remove the NFT.
   * @param _tokenId Which NFT we want to remove.
   */
  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
    internal
    override (NFTokenEnumerable, NFToken) 
  {
      super._removeNFToken(_from, _tokenId);
  }

  function removeNFToken(address _from, uint256 _tokenId) internal {
      _removeNFToken(_from, _tokenId);
  }


  /**
   * @dev A custom message given for the first NFT buyer.
   * @param _tokenId Id for which we want the message.
   * @return Message of _tokenId.
   */
  function tokenMessage(
    uint256 _tokenId
  )
    external
    view
    validNFToken(_tokenId)
    returns (string memory)
  {
    return idToMsg[_tokenId];
  }

  /**
   * @dev Sets a custom message for the NFT with _tokenId.
   * @notice only the owner of the NFT can do this. Not even approved or 
   * operators can execute this function.
   * @param _tokenId Id for which we want the message.
   * @param _msg the custom message.
   */
  function setTokenMessage(
    uint256 _tokenId,
    string memory _msg
  )
    external
    validNFToken(_tokenId)
  { 
    address tokenOwner = idToOwner[_tokenId];
    require(_msgSender() == tokenOwner, NOT_OWNER);
    require(bytes(idToMsg[_tokenId]).length == 0, MESSAGE_ALREADY_SET);
    bool valid_msg = validateMsg(_msg);
    require(valid_msg, NOT_VALID_MSG);
    idToMsg[_tokenId] = _msg;
  }

  /**
     * @dev Check if the message string has a valid length
     * @param _msg the custom message.
     */
    function validateMsg(string memory _msg) public pure returns (bool){
        bytes memory b = bytes(_msg);
        if(b.length < 1) return false;
        if(b.length > 300) return false; // Cannot be longer than 300 characters
        return true;
    }

 /**
   * @dev returns the list of NFTs owned by certain address.
   * @param _address Id for which we want the message.
   */
  function getNFTsByAddress(
    address _address
  )
    view external returns (uint256[] memory)
  { 
    return ownerToIds[_address];
  }

  /**
    * @dev Builds and return the URL string from the tokenId.
    * @notice the tokenId is the SHA2-256 of the URI content in IPFS.
    * This ensures the complete authenticity of the token minted. The URL is
    * therefore an IPFS URL which follows the pattern: 
    * ipfs://<CID>
    * And the CID can be constructed as follows:
    * CID = F01701220<ID>  
    * F signals that the CID is in hexadecimal format. 01 means CIDv1. 70 signals   
    * dag-pg link-data coding used. 12 references the hashing algorith SHA2-256.
    * 20 is the length in bytes of the hash. In decimal, 32 bytes as specified
    * in the SHA2-256 protocol. Finally, <ID> is the tokenId (the hash).
    * @param _tokenId of the NFT (the SHA2-256 of the URI content).
    */
  function getURI(uint _tokenId) internal pure returns(string memory){
        string memory _hex = uintToHexStr(_tokenId);
        string memory prefix = "ipfs://F01701220";
        string memory result = string(abi.encodePacked(prefix,_hex ));
        return result;
    }

    /**
    * @dev Converts a uint into a hex string of 64 characters. Throws if 0 is passed.
    * @notice that the returned string doesn't prepend the usual "0x".
    * @param _uint number to convert to string.
    */
  function uintToHexStr(uint _uint) internal pure returns (string memory) {
        require(_uint != 0, ZERO_VALUE);
        bytes memory byteStr = new bytes(64);
        for (uint j = 0; j < 64 ;j++){
            uint curr = (_uint & 15); //mask that allows us to filter only the last 4 bits (last character)
            byteStr[63-j] = curr > 9 ? bytes1( uint8(55) + uint8(curr) ) :
                                        bytes1( uint8(48) + uint8(curr) ); // 55 = 65 - 10
            _uint = _uint >> 4;   
        }
        return string(byteStr);
      }

    /**
    * @dev Destroys the contract
    * @notice that, due to the danger that the call of this contract poses, it is required
    * to pass a specific integer value to effectively call this method.
    * @param security_value number to pass security restriction (192837).
    */
      function seflDestruct(uint security_value) external onlyOwner { 
        require(security_value == 192837); //this is just to make sure that this method was not called by accident
        selfdestruct(payable(owner)); 
      }

    /**
    * @dev returns boolean representing the existance of an NFT
    * @param _tokenId of the NFT to look up.
    */
      function exists(uint _tokenId) external view returns (bool) { 
        if( idToOwner[_tokenId] == address(0)){
          return false;
        }else{
          return true;
        }
      }


}