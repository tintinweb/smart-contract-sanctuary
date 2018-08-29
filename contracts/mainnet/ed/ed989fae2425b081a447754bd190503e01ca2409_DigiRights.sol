pragma solidity ^0.4.24;

/*
* This contract implements the ERC721 standard and provides services for DigiRights platform 
*/
interface ERC721 {
    
    /*
    * Mandatory functions of ERC721 standard
    */
    function totalSupply() external view returns (uint256 total);
    function balanceOf(bytes32 _owner) external view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (bytes32 owner);
    function approve(bytes32 _from,bytes32 _to, uint256 _tokenId) external;
    function transferFrom(bytes32 _from, bytes32 _to, uint256 _tokenId) external;

        
    /*
    * Events 
    */
    event Transfer(bytes32 from, bytes32 to, uint256 tokenId);
    event Approval(bytes32 owner, bytes32 approved, uint256 tokenId);

    // ERC-165 Compatibility
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract DigiRights is ERC721 {

    string private NAME = "Ionixx DigiRights";
    string private SYMBOL = "INX DIGI";

    bytes4 constant InterfaceID_ERC165 =
    bytes4(keccak256("supportsInterface(bytes4)"));

    bytes4 constant InterfaceID_ERC721 =
    bytes4(keccak256("name()")) ^
    bytes4(keccak256("symbol()")) ^
    bytes4(keccak256("totalSupply()")) ^
    bytes4(keccak256("balanceOf(bytes32)")) ^
    bytes4(keccak256("ownerOf(uint256)")) ^
    bytes4(keccak256("approve(bytes32,uint256)")) ^
    bytes4(keccak256("transfer(bytes32,uint256)")) ^
    bytes4(keccak256("transferFrom(bytes32,bytes32,uint256)")) ^
    bytes4(keccak256("tokensOfOwner(bytes32)"));

    /*  @desc Metadata of the token implemented as a structure
        @attributes owner: Creator of the Token
        @attributes name: Name of the file
        @attributes descripton: descripton of the file
        @attributes file_hash: hash of the file
    */
    struct Token {
        bytes32 owner;
        string name;
        string description;
        string file_hash;
        uint256 token_id;
        uint256 timestamp;
        string file_type;
        string extension;
    }

    Token[] tokens;

    mapping (uint256 => bytes32) public ownerOf;
    mapping (bytes32 => uint256) ownerTokenCount;
    mapping (uint256 => bytes32) public tokenIndexToApproved;   
    mapping(string => bool) filehash;
    
    event Created(bytes32 owner, uint256 tokenId);
    
    
 
    /*  @desc provides the name of the token
        @return string: name of the token
    */
    function name() external view returns (string) {
        return NAME;
    }
    
    /*  @desc provides the symbol of the token
        @return string: symbol of the token
    */
    function symbol() external view returns (string) {
        return SYMBOL;
    }
    
    /*  @desc provides the total supply limit of the token
        @return uint256: total supply
    */
    function totalSupply() external view returns (uint256) {
        return tokens.length;
    }
    
    /*  @desc provides the total number of tokens owned by the user
        @param _owner: owner hash
        @return uint256: number of tokens
    */
    function balanceOf(bytes32 _owner) external view returns (uint256) {
        return ownerTokenCount[_owner];
    }
    
    /*  @desc provides the owner of the given token
        @param _tokenId: token ID
        @return uint256: number of tokens
    */
    function ownerOf(uint256 _tokenId) external view returns (bytes32 owner) {
        owner = ownerOf[_tokenId];
    }
    
    /*  @desc approves a user to use his/her token
        @param _from: from hash
        @param _to: to hash
        @param _tokenId: token ID
    */
    function approve(bytes32 _from,bytes32 _to, uint256 _tokenId) external {
        require(_owns(_from, _tokenId));

        tokenIndexToApproved[_tokenId] = _to;
        emit Approval(ownerOf[_tokenId], tokenIndexToApproved[_tokenId], _tokenId);
    }
    
    /*  @desc transfers token from one hash to another hash when they have approval
        @param _from: from hash
        @param _to: to hash
        @param _tokenId: token ID
    */
    function transferFrom(bytes32 _from, bytes32 _to, uint256 _tokenId) external {
        require(_to.length != 0 );
        require(_to != _from);
        require(_owns(_from, _tokenId));

        _transfer(_from, _to, _tokenId);
    }

    /*  @desc provides the tokens owned by an user
        @param _owner: owner hash
        @param tokenIds: token ID as array
    */
    function tokensOfOwner(bytes32 _owner) external view returns (uint256[]) {
        uint256 balance = this.balanceOf(_owner);

        if (balance == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](balance);
            uint256 maxTokenId = this.totalSupply();
            uint256 idx = 0;

            uint256 tokenId;
            for (tokenId = 0; tokenId <= maxTokenId; tokenId++) {
                if (ownerOf[tokenId] == _owner) {
                    result[idx] = tokenId;
                    idx++;
                }
            }
            return result;
        }

    }
    
    /*  @desc obtains ther token details
        @param _owner: owner hash 
        @param _tokenId: token ID 
        @return owner: owner hash
        @return name: file name
        @return description: file description
        @return hash: file hash
    */
    function getToken(bytes32 _owner,uint256 _tokenId) external view returns (bytes32 owner,string token_name,string description,string file_hash,
        uint256 token_id,
        uint256 timestamp,
        string file_type,string extension) {
        require(_owns(_owner,_tokenId) == true);
        uint256 length = this.totalSupply();
        require(_tokenId < length);
        Token memory token = tokens[_tokenId];
        owner = token.owner;
        token_name = token.name;
        description = token.description;
        file_hash = token.file_hash;
        token_id = token.token_id;
        timestamp = token.timestamp;
        file_type=token.file_type;
        extension=token.extension;
    }

    /*  @desc checks if the contract supports interface
        @param _interfaceID: interface ID 
        @return bool: flag if the interface is implemented or not
    */
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return ((_interfaceID == InterfaceID_ERC165) || (_interfaceID == InterfaceID_ERC721));
    }
    
    /*  @desc creates a new token and assigns it to the user
        @param _from: from hash
        @param name: file name
        @param description: file description
        @param hash: file hash
    */
    function createToken(bytes32 _from,string token_name,string description,string file_hash,string file_type , string extension) public {
        require(_from.length != 0 );
        require(filehash[file_hash] == false);
        filehash[file_hash] = true;
        mint(_from,token_name,description,file_hash ,file_type,extension);
        
    }
    
    /*
    * Internal functions
    */
    function _owns(bytes32 _claimant, uint256 _tokenId) internal view returns (bool) {
        return ownerOf[_tokenId] == _claimant;
    }

    function _approvedFor(bytes32 _claimant, uint256 _tokenId) internal view returns (bool) {
        return tokenIndexToApproved[_tokenId] == _claimant;
    }

    function _transfer(bytes32 _from, bytes32 _to, uint256 _tokenId) internal {
        
        ownerTokenCount[_to]++;
        ownerOf[_tokenId] = _to;

        if (_from.length != 0 ) {
            ownerTokenCount[_from]--;
            delete tokenIndexToApproved[_tokenId];
        }

        emit Transfer(_from, _to, _tokenId);
    }
    
    function mint(bytes32 owner,string token_name,string description,string hash,string file_type, string extension) internal {
        Token memory token = Token({
            owner:owner,
            name:token_name,
            description:description,
            file_hash:hash,
            file_type: file_type,
            extension: extension,
            token_id: this.totalSupply(),
            timestamp:block.timestamp
        });
        uint256 tokenId =tokens.push(token) - 1;
        emit Created(owner, tokenId);
        _transfer(0, owner, tokenId);
    }
}