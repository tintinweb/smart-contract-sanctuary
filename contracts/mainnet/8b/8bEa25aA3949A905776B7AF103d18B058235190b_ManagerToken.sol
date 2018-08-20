/* ==================================================================== */
/* Copyright (c) 2018 The TokenTycoon Project.  All rights reserved.
/* 
/* https://tokentycoon.io
/*  
/* authors <span class="__cf_email__" data-cfemail="6e1c070d05061b001a0b1c401d060b002e09030f0702400d0103">[email&#160;protected]</span>   
/*         <span class="__cf_email__" data-cfemail="1566667066607b717c7b72557278747c793b767a78">[email&#160;protected]</span>            
/* ==================================================================== */
pragma solidity ^0.4.23;

/// @title ERC-165 Standard Interface Detection
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
contract ERC721 is ERC165 {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function approve(address _approved, uint256 _tokenId) public;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard
interface ERC721TokenReceiver {
	function onERC721Received(address _from, uint256 _tokenId, bytes data) external returns(bytes4);
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
interface ERC721Metadata /* is ERC721 */ {
    function name() external pure returns (string _name);
    function symbol() external pure returns (string _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string);
}

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
interface ERC721Enumerable /* is ERC721 */ {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

interface ERC721MetadataProvider {
    function tokenURI(uint256 _tokenId) external view returns (string);
}

contract AccessAdmin {
    bool public isPaused = false;
    address public addrAdmin;  

    event AdminTransferred(address indexed preAdmin, address indexed newAdmin);

    constructor() public {
        addrAdmin = msg.sender;
    }  


    modifier onlyAdmin() {
        require(msg.sender == addrAdmin);
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused);
        _;
    }

    modifier whenPaused {
        require(isPaused);
        _;
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0));
        emit AdminTransferred(addrAdmin, _newAdmin);
        addrAdmin = _newAdmin;
    }

    function doPause() external onlyAdmin whenNotPaused {
        isPaused = true;
    }

    function doUnpause() external onlyAdmin whenPaused {
        isPaused = false;
    }
}

interface TokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract ManagerToken is ERC721, ERC721Metadata, ERC721Enumerable, AccessAdmin {
    /// @dev All manangers array(tokenId => gene)
    uint256[] public managerArray;
    /// @dev Mananger tokenId vs owner address
    mapping (uint256 => address) tokenIdToOwner;
    /// @dev Manangers owner by the owner (array)
    mapping (address => uint256[]) ownerToManagerArray;
    /// @dev Mananger token ID search in owner array
    mapping (uint256 => uint256) tokenIdToOwnerIndex;
    /// @dev The authorized address for each TTM
    mapping (uint256 => address) tokenIdToApprovals;
    /// @dev The authorized operators for each address
    mapping (address => mapping (address => bool)) operatorToApprovals;
    /// @dev Trust contract
    mapping (address => bool) safeContracts;
    /// @dev Metadata provider
    ERC721MetadataProvider public providerContract;

    /// @dev This emits when the approved address for an TTM is changed or reaffirmed.
    event Approval
    (
        address indexed _owner, 
        address indexed _approved,
        uint256 _tokenId
    );

    /// @dev This emits when an operator is enabled or disabled for an owner.
    event ApprovalForAll
    (
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    /// @dev This emits when the equipment ownership changed 
    event Transfer
    (
        address indexed from,
        address indexed to,
        uint256 tokenId
    );
    
    constructor() public {
        addrAdmin = msg.sender;
        managerArray.length += 1;
    }

    // modifier
    /// @dev Check if token ID is valid
    modifier isValidToken(uint256 _tokenId) {
        require(_tokenId >= 1 && _tokenId <= managerArray.length, "TokenId out of range");
        require(tokenIdToOwner[_tokenId] != address(0), "Token have no owner"); 
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        address owner = tokenIdToOwner[_tokenId];
        require(msg.sender == owner || msg.sender == tokenIdToApprovals[_tokenId] || operatorToApprovals[owner][msg.sender], "Can not transfer");
        _;
    }

    // ERC721
    function supportsInterface(bytes4 _interfaceId) external view returns(bool) {
        // ERC165 || ERC721 || ERC165^ERC721
        return (_interfaceId == 0x01ffc9a7 || _interfaceId == 0x80ac58cd || _interfaceId == 0x8153916a) && (_interfaceId != 0xffffffff);
    }

    function name() public pure returns(string) {
        return "Token Tycoon Managers";
    }

    function symbol() public pure returns(string) {
        return "TTM";
    }

    function tokenURI(uint256 _tokenId) external view returns (string) {
        if (address(providerContract) == address(0)) {
            return "";
        }
        return providerContract.tokenURI(_tokenId);
    }

    /// @dev Search for token quantity address
    /// @param _owner Address that needs to be searched
    /// @return Returns token quantity
    function balanceOf(address _owner) external view returns(uint256) {
        require(_owner != address(0), "Owner is 0");
        return ownerToManagerArray[_owner].length;
    }

    /// @dev Find the owner of an TTM
    /// @param _tokenId The tokenId of TTM
    /// @return Give The address of the owner of this TTM
    function ownerOf(uint256 _tokenId) external view returns (address owner) {
        return tokenIdToOwner[_tokenId];
    }

    /// @dev Transfers the ownership of an TTM from one address to another address
    /// @param _from The current owner of the TTM
    /// @param _to The new owner
    /// @param _tokenId The TTM to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) 
        external
        whenNotPaused
    {
        _safeTransferFrom(_from, _to, _tokenId, data);
    }

    /// @dev Transfers the ownership of an TTM from one address to another address
    /// @param _from The current owner of the TTM
    /// @param _to The new owner
    /// @param _tokenId The TTM to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) 
        external
        whenNotPaused
    {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    /// @dev Transfer ownership of an TTM, &#39;_to&#39; must be a vaild address, or the TTM will lost
    /// @param _from The current owner of the TTM
    /// @param _to The new owner
    /// @param _tokenId The TTM to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId)
        external
        whenNotPaused
        isValidToken(_tokenId)
        canTransfer(_tokenId)
    {
        address owner = tokenIdToOwner[_tokenId];
        require(owner != address(0), "Owner is 0");
        require(_to != address(0), "Transfer target address is 0");
        require(owner == _from, "Transfer to self");
        
        _transfer(_from, _to, _tokenId);
    }

    /// @dev Set or reaffirm the approved address for an TTM
    /// @param _approved The new approved TTM controller
    /// @param _tokenId The TTM to approve
    function approve(address _approved, uint256 _tokenId) public whenNotPaused {
        address owner = tokenIdToOwner[_tokenId];
        require(owner != address(0));
        require(msg.sender == owner || operatorToApprovals[owner][msg.sender]);

        tokenIdToApprovals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    /// @dev Enable or disable approval for a third party ("operator") to manage all your asset.
    /// @param _operator Address to add to the set of authorized operators.
    /// @param _approved True if the operators is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) 
        external 
        whenNotPaused
    {
        operatorToApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @dev Get the approved address for a single TTM
    /// @param _tokenId The TTM to find the approved address for
    /// @return The approved address for this TTM, or the zero address if there is none
    function getApproved(uint256 _tokenId) 
        external 
        view 
        isValidToken(_tokenId) 
        returns (address) 
    {
        return tokenIdToApprovals[_tokenId];
    }

    /// @dev Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the TTMs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorToApprovals[_owner][_operator];
    }

    /// @dev Count TTMs tracked by this contract
    /// @return A count of valid TTMs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256) {
        return managerArray.length - 1;
    }

    /// @dev Enumerate valid TTMs
    /// @param _index A counter less than totalSupply
    /// @return The token identifier for the `_index`th TTM,
    function tokenByIndex(uint256 _index) 
        external
        view 
        returns (uint256) 
    {
        require(_index < managerArray.length);
        return _index;
    }

    /// @notice Enumerate TTMs assigned to an owner
    /// @param _owner Token owner address
    /// @param _index A counter less than balanceOf(_owner)
    /// @return The TTM tokenId
    function tokenOfOwnerByIndex(address _owner, uint256 _index) 
        external 
        view 
        returns (uint256) 
    {
        require(_owner != address(0));
        require(_index < ownerToManagerArray[_owner].length);
        return ownerToManagerArray[_owner][_index];
    }

    /// @dev Do the real transfer with out any condition checking
    /// @param _from The old owner of this TTM(If created: 0x0)
    /// @param _to The new owner of this TTM 
    /// @param _tokenId The tokenId of the TTM
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        if (_from != address(0)) {
            uint256 indexFrom = tokenIdToOwnerIndex[_tokenId];
            uint256[] storage ttmArray = ownerToManagerArray[_from];
            require(ttmArray[indexFrom] == _tokenId);

            if (indexFrom != ttmArray.length - 1) {
                uint256 lastTokenId = ttmArray[ttmArray.length - 1];
                ttmArray[indexFrom] = lastTokenId; 
                tokenIdToOwnerIndex[lastTokenId] = indexFrom;
            }
            ttmArray.length -= 1; 
            
            if (tokenIdToApprovals[_tokenId] != address(0)) {
                delete tokenIdToApprovals[_tokenId];
            }      
        }

        tokenIdToOwner[_tokenId] = _to;
        ownerToManagerArray[_to].push(_tokenId);
        tokenIdToOwnerIndex[_tokenId] = ownerToManagerArray[_to].length - 1;
        
        emit Transfer(_from != address(0) ? _from : this, _to, _tokenId);
    }

    /// @dev Actually perform the safeTransferFrom
    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) 
        internal
        isValidToken(_tokenId) 
        canTransfer(_tokenId)
    {
        address owner = tokenIdToOwner[_tokenId];
        require(owner != address(0));
        require(_to != address(0));
        require(owner == _from);
        
        _transfer(_from, _to, _tokenId);

        // Do the callback after everything is done to avoid reentrancy attack
        uint256 codeSize;
        assembly { codeSize := extcodesize(_to) }
        if (codeSize == 0) {
            return;
        }
        bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(_from, _tokenId, data);
        // bytes4(keccak256("onERC721Received(address,uint256,bytes)")) = 0xf0b9e5ba;
        require(retval == 0xf0b9e5ba);
    }
    
    function setSafeContract(address _actionAddr, bool _useful) external onlyAdmin {
        safeContracts[_actionAddr] = _useful;
    }

    function getSafeContract(address _actionAddr) external view onlyAdmin returns(bool) {
        return safeContracts[_actionAddr];
    }

    function setMetadataProvider(address _provider) external onlyAdmin {
        providerContract = ERC721MetadataProvider(_provider);
    }

    function getOwnTokens(address _owner) external view returns(uint256[]) {
        require(_owner != address(0));
        return ownerToManagerArray[_owner];
    }

    function safeGiveByContract(uint256 _tokenId, address _to) 
        external 
        whenNotPaused
    {
        require(safeContracts[msg.sender]);
        // Only the token&#39;s owner is this can use this function
        require(tokenIdToOwner[_tokenId] == address(this));
        require(_to != address(0));

        _transfer(address(this), _to, _tokenId);
    }

    /// @dev Safe transfer by trust contracts
    function safeTransferByContract(uint256 _tokenId, address _to) 
        external
        whenNotPaused
    {
        require(safeContracts[msg.sender]);

        require(_tokenId >= 1 && _tokenId <= managerArray.length);
        address owner = tokenIdToOwner[_tokenId];
        require(owner != address(0));
        require(_to != address(0));
        require(owner != _to);

        _transfer(owner, _to, _tokenId);
    }

    function initManager(uint256 _gene, uint256 _count) external {
        require(safeContracts[msg.sender] || msg.sender == addrAdmin);
        require(_gene > 0 && _count <= 128);
        
        address owner = address(this);
        uint256[] storage ttmArray = ownerToManagerArray[owner];
        uint256 newTokenId;
        for (uint256 i = 0; i < _count; ++i) {
            newTokenId = managerArray.length;
            managerArray.push(_gene);
            tokenIdToOwner[newTokenId] = owner;
            tokenIdToOwnerIndex[newTokenId] = ttmArray.length;
            ttmArray.push(newTokenId);
            emit Transfer(address(0), owner, newTokenId);
        }
    }

    function approveAndCall(address _spender, uint256 _tokenId, bytes _extraData)
        external
        whenNotPaused
        returns (bool success) 
    {
        TokenRecipient spender = TokenRecipient(_spender);
        approve(_spender, _tokenId);
        spender.receiveApproval(msg.sender, _tokenId, this, _extraData);
        return true;
    }

    function getProtoIdByTokenId(uint256 _tokenId)
        external 
        view 
        returns(uint256 protoId) 
    {
        if (_tokenId > 0 && _tokenId < managerArray.length) {
            return managerArray[_tokenId];
        }
    }

    function getOwnerTokens(address _owner)
        external
        view 
        returns(uint256[] tokenIdArray, uint256[] protoIdArray) 
    {
        uint256[] storage ownTokens = ownerToManagerArray[_owner];
        uint256 count = ownTokens.length;
        tokenIdArray = new uint256[](count);
        protoIdArray = new uint256[](count);
        for (uint256 i = 0; i < count; ++i) {
            tokenIdArray[i] = ownTokens[i];
            protoIdArray[i] = managerArray[tokenIdArray[i]];
        }
    }
}