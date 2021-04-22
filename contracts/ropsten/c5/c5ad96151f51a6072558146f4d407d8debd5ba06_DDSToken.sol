/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;


interface ERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);
    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

string constant FROM_EQUAL_TO = "FROM address equal to TO one";
string constant ALREADY_OWNER = "OWNER already purchased this token";
string constant NFT_NOT_EXISTS = "NFT not available, create it!";
string constant TOO_LOW_BID = "Higher payment required";

contract DDSToken is ERC721{
    
    
    string nftName = "DDS 2020/21 NFT";
    string nftSymbol = "DDS";
    
    mapping (uint256 => string) idToUri;

    mapping (uint256 => address) tokensOwner;
    
    mapping (address => uint256) ownersBalance;
    
    mapping (uint256 => address) idToOwner;

    mapping (uint256 => bytes) idData;
    
    mapping (uint256 => uint) idToValue; //wei

    uint256 mintedTokens = 0;
    

    function balanceOf(address _owner) external override view returns (uint256){
        return ownersBalance[_owner];
    } 
    
    function ownerOf(uint256 _tokenId) external override view returns (address){
        return idToOwner[_tokenId];
    }
    
    function _transfer(address _from, address _to, uint256 _tokenId) internal{
        tokensOwner[_tokenId]=_to;
        
        if (_from != address(0)){ //minted NFT 
            ownersBalance[_from] = ownersBalance[_from] - 1;
        }
        
        ownersBalance[_to] = ownersBalance[_to] + 1;
        
        idToOwner[_tokenId] = _to;
        
        emit Transfer(_from, _to, _tokenId);
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) override external payable{
        require(_from!=_to,FROM_EQUAL_TO);
        require(tokensOwner[_tokenId]!=_to,ALREADY_OWNER);
        require(msg.value > idToValue[_tokenId], TOO_LOW_BID);
        idData[_tokenId] = data;

        _transfer(_from, _to, _tokenId);

    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) override external payable{
        require(_from!=_to,FROM_EQUAL_TO);
        require(tokensOwner[_tokenId]!=_to,ALREADY_OWNER);
        require(msg.value > idToValue[_tokenId], TOO_LOW_BID);
        
        _transfer(_from, _to, _tokenId);
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) external override payable{
        _transfer(_from, _to, _tokenId);
    }
    
    function approve(address _approved, uint256 _tokenId) external override payable{
        // NOT IMPLEMENTED
    }
    
    function setApprovalForAll(address _operator, bool _approved) external override{
        // NOT IMPLEMENTED    
    }
    
    function getApproved(uint256 _tokenId) external override view returns (address){
        // NOT IMPLEMENTED
    }
    
    function isApprovedForAll(address _owner, address _operator) external override view returns (bool){
        // NOT IMPLEMENTED            
    }
        
    function createNFT(address _owner, string memory url) external payable{
            uint256 _tokenId = mintedTokens;
            idToUri[_tokenId] = url;
            idToValue[_tokenId] = msg.value;
            _transfer(address(0), _owner, _tokenId);
            mintedTokens = mintedTokens + 1;
    }
    
    function name() external view returns (string memory){
        return nftName;
    }
    
    function symbol() external view returns (string memory){
        return nftSymbol;
    }
    
    function tokenURI(uint256 _tokenId) external view returns (string memory){
        return idToUri[_tokenId];          
    }

}