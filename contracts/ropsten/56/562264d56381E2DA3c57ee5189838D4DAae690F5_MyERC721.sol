/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.0;

 contract Context {
    function _msgSender() public view returns(address payable){
        return msg.sender;
    }
    //function _msgData() public view returns()
}

interface MyIERC721 {
    // interface
    function balanceOf(address owner) external  view returns(uint);
    function ownerOf(uint tokenId) external view returns(address);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint tokenId) external;
    function approve(address to, uint tokenId) external;
    function getApproved(uint tokenId) external view returns(address);
    function setApprovalForAll(address operator,bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns(bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
    
    //IERC165
    //function supportsInterface(address interfaceId) external;
    
    // events
   event Transfer(address from,address to,uint256 tokenId);
   event Approval(address owner,address approved,uint256 tokenId);
   event ApprovalForAll(address owner,address operator,bool approved);
}
contract ERC721StorageURI {
    mapping(uint256 => string) private _tokenURI;
    function _setTokenUri(uint256 tokenId, string memory _uri) internal virtual{
        _tokenURI[tokenId] = _uri;
    }
    function tokenURI(uint256 tokenId) public view virtual returns(string memory){
        //tokenId should exixts
        return _tokenURI[tokenId];
    }
}
contract MyERC721 is MyIERC721,Context, ERC721StorageURI {
    event SpareEvent(string);
    // Token name
    string private _name;
    // Token symbol
    string private _symbol;
    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;
    // Mapping owner address to token count
    mapping(address => uint256) private _balances;
    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;
    
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    /*
    ammar implementation
    _exists, ownerOf, counter
    */
    uint256 private counter = 0;
    constructor() public {
        _name = "MyERC721";
        _symbol = "NFT";
        //_mint(_msgSender(),1);
        mintNFT(_msgSender(), "Genesis URI");
        
    }
    
     //mapping(address => uint256[]) private _balances; // balance, 
    function balanceOf(address owner) public override view returns(uint256) {
        // tokenId should exists
        return _balances[owner];
    }
    function ownerOf(uint256 tokenId) public view override returns(address){
         //tokenId should exist
         return _owners[tokenId];
    }
    
    function approve(address to, uint256 tokenId) public override {
        
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(to != address(0), "to should not be address(0)");
        require(_msgSender() == owner 
        || isApprovedForAll(owner, _msgSender()), "Only owner or operator can approve");
        
        _approve(address(0),tokenId); //_tokenApprovals[tokenId] = to;
        
        emit Approval(_msgSender(),to,tokenId);
    }
    
    function getApproved(uint256 tokenId) public override view returns(address){
        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool _approved) public override {
        require(operator != _msgSender()," operator cannot call");
        _operatorApprovals[_msgSender()][operator] = _approved;
        emit ApprovalForAll(_msgSender(), operator, _approved);
    }
    function isApprovedForAll(address owner, address operator) public view override returns(bool){
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(address from, address to, uint256 tokenId) public override{
        /*
         if caller is not owner, caller must have been allowed 
         to move this NFT by either approve or setApprovalForAll. 
        */
        address owner = ownerOf(tokenId);
        require(_msgSender() == owner || 
        _msgSender() == getApproved(tokenId) ||
        isApprovedForAll(owner,_msgSender()),
        "only owner spender and operator can use");
        
        /*
        _transfer(from,to,tokenId);
        check if `to` is not zero address,
        check if `from` is owner of `tokenId`,
        remove allowance that given by `from`,
        increase balance of `to` by 1,
        decrease balance of `from` by 1,
        traansfer ownership to `to`
        
        */
        _transfer(from,to,tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public override{
        require(_isOwnerOrApprover(_msgSender(), tokenId));
        _transfer(from,to,tokenId);
        
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        
    }
    
    function _transfer(address from,address to,uint256 tokenId) internal {
        require(to != address(0), "`to` should not be address(0)");
        require(ownerOf(tokenId) == from);
        //actual: Clear approvals from the previous owner
        _approve(address(0), tokenId);
        
        _balances[to] += 1;
        _balances[from] -= 1;
        _owners[tokenId] = to;
        emit Transfer(from,to,tokenId);
    }
    
    function _burn(uint256 tokenId) internal virtual {
        require(_exists(tokenId),"cannot burn non-existed token");
        address owner = ownerOf(tokenId);
        _balances[owner] -= 1;
        _approve(address(0),tokenId);
        //same like delete below, _owners[tokenId] = address(0);
        delete _owners[tokenId];
        /*
        cannot call _transfer(owner,address(0),tokenId)
        because of below check
        require(to != address(0));
        */
    }
    function _mint(address to,uint256 tokenId) internal virtual{
        //require, tokenId should not exist
        require(!_exists(tokenId),"its already existed token");
        require(to != address(0));
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }
    
   function _approve(address to, uint256 tokenId) internal {
       _tokenApprovals[tokenId] = to;
       emit Approval(ownerOf(tokenId),to, tokenId);
   }
   function _isOwnerOrApprover(address account, uint256 tokenId) internal view returns(bool){
        address owner = ownerOf(tokenId);
        return (account == owner ||
        isApprovedForAll(owner,account) ||
        account == getApproved(tokenId)
        );
    }
    /*
    Actual Impl commented wali he:
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
    */
    function _exists(uint256 tokenId) internal view returns(bool){
        if(ownerOf(tokenId) != address(0)){
            return true;
        }else {
            return false;
        }
    }
    // extras
    function mintNFT(address to, string memory _tokenURI) public returns(bool){
        counter++;
        uint256 tokenId = counter;
        _mint(to,tokenId);
        _setTokenUri(tokenId, _tokenURI);
        return true;
    }
    function burn(uint256 tokenId) public returns(bool) {
        _burn(tokenId);
        return true;
    }
    /*
    internal functions
    _safeTransferFrom(from, to, tokenId, _data)
    _exists(tokenId)
    _isApprovedOrOwner(spender, tokenId)
    _safeMint(to, tokenId)
    _safeMint(to, tokenId, _data)
    _mint(to, tokenId)
    _burn(owner, tokenId)
    _burn(tokenId)
    _transfer(from, to, tokenId);
    _approve(to, tokenId)
    _beforeTokenTransfer(from,to, tokenId)
    */
}