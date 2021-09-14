// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC165.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721TokenReceiver.sol";
import "./Strings.sol";
import "./Address.sol";
// import "./Context.sol";
// import "./IERC721Enumerable.sol";

contract ERC721_SaleToken is ERC165, IERC721, IERC721Metadata{
    
     using Strings for uint256;
     using Address for address;
 
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _owners;

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    string private _name;
    string private _symbol;
    
    uint256 private _totalSupply = 12;
    uint256 private _tokenSupply = 0;
    
    address public tokenOwner;
    uint256 public _tokenPrice;
    string internal _baseURI;
    
    uint256 private _saleStartDate = block.timestamp + 30;
    uint256 private _saleEndDate = _saleStartDate + 30 days;

    
    // ---------------------------------------------------------------Mofifiers---------------------------------------------------/
    
    
    modifier onlyOwner() {
        require(tokenOwner == msg.sender,"Not token owner");
        _;
    }
    
    
    modifier isSaleOn() {
        require(block.timestamp >= _saleStartDate  && block.timestamp <= _saleEndDate,"Ops! Sale isn't started");
        require(_tokenPrice > 0,"token price msut be valid");
        _;
    }
    
    
    // -----------------------------------------------------------Constructor----------------------------------------------------/

    constructor(){
    
        _name = "ERC721_SaleToken";
        _symbol = "ERC721-S-Token";
        
        tokenOwner = msg.sender;
        
        // _totalSupply = 12;
        
        // register the supported interfaces to conform to ERC721 via ERC165
        // _registerInterface(_INTERFACE_ID_ERC721);
    }
    
    // ------------------------------------------------------------ERC165 Interface----------------------------------------------/
    
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    
      /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    
    
    // -----------------------------------------------------------Helper Functions--------------------------------------/
    
    function _exists(uint256 tokenId) internal view virtual returns(bool){
         return _owners[tokenId] != address(0);
     }
     
                        //          EOA/msg.sender
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
        // return (spender == owner || _tokenApprovals[tokenId] == spender || _operatorApprovals[owner][spender]);   //alternate of above return
    }
    

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }
    
    
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        // _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
    

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    
        
    
    // -----------------------------------------------------------Metadata-------------------------------------------------------/
    
 
    function name() public view virtual override returns(string memory){
        return _name;
    }
    
    
    function symbol() public view virtual override returns(string memory){
        return _symbol;
    }
    

    function tokenURI(uint256 tokenId) public view virtual override returns(string memory){
        
        require(_exists(tokenId),"URI query for nonexistent token");
        
        // string memory baseURI = _baseURI;
        
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString())) : "";
    } 
    

    function _setBaseURI(string memory URI) public onlyOwner {
        
        _baseURI = URI;  // https://my-json-server.typicode.com/javaidrauf/testNFT/tokens/
    }
    
    
    // ------------------------------------------------------------Owner & balanceOf---------------------------------------/
    
    
    function balanceOf(address owner) public view virtual override returns(uint256){
        
        require(owner != address(0),"Batch13-NFT: balance query for the zero address");
        
        return _balances[owner];
    }
    
    
    
    function balanceOfCont() public view returns(uint256){
        
        return address(this).balance;
    }
    
    
    function ownerOf(uint256 tokenId) public view virtual override returns(address){
        
        require(_owners[tokenId] != address(0),"Batch13-NFT:owner query for nonexistent token");
        
        return _owners[tokenId];
    } 
    
    
    // -------------------------------------------------------------Approval Functions--------------------------------------/
    
    
    function setApprovalForAll(address operator, bool approved) public virtual override{
        
        require(operator != msg.sender,"ERC721: approve to caller");
        
        require(_balances[msg.sender] > 0,"caller should have token balance");  //added myself
        
        _operatorApprovals[msg.sender][operator] = approved;
        
        emit ApprovalForAll(msg.sender,operator,approved);
        
    }
    
    
    function isApprovedForAll(address owner, address operator) public view virtual override returns(bool){
        
        return _operatorApprovals[owner][operator];
        
    }
    
    
    
    function approve(address to, uint256 tokenId) public virtual override{
        
        address owner = ownerOf(tokenId);
        
        require(_exists(tokenId),"approval query for nonexistent token");
        
        require(to != owner,"ERC721: approval to current owner");
        
        require(msg.sender == owner || isApprovedForAll(owner,msg.sender),"ERC721: approve caller is neither an owner nor approved for all");
        
        
        _approve(to,tokenId);
        
        // _approve(to,tokenid) has following code:
        // function _approve(address to, uint256 tokenId) internal virtual {
        // _tokenApprovals[tokenId] = to;
        // emit Approval(ownerOf(tokenId), to, tokenId);
        // }
    }
    
    
        
    function getApproved(uint256 tokenId) public view virtual override returns(address operator){
        
        require(_exists(tokenId),"ERC721: approved query for nonexistent of tokenId");
        
        return _tokenApprovals[tokenId];
        
    }
    
    
    // -----------------------------------------------------------------Tranfer Functions---------------------------------------/
    
    
    function transferFrom(address from, address to, uint256 tokenId) public virtual override{
        
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        
        // function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        // require(exists(tokenId), "ERC721: operator query for nonexistent token");
        // address owner = ownerOf(tokenId);
        // return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
        // }
        
        _transfer(from, to, tokenId);
        
    //   _transfer(fro,to,tokenId) has following code:
    //     function _transfer(address from, address to, uint256 tokenId) internal virtual {
    //     require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
    //     require(to != address(0), "ERC721: transfer to the zero address");

    //     // _beforeTokenTransfer(from, to, tokenId);

    //     // Clear approvals from the previous owner
    //     _approve(address(0), tokenId);

    //     _balances[from] -= 1;
    //     _balances[to] += 1;
    //     _owners[tokenId] = to;

    //     emit Transfer(from, to, tokenId);
    //     }
    }
    
    
    function safeTransferFrom(address from, address to, uint256 tokenId,bytes calldata data) public virtual override{
    
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        
        _safeTransfer(from, to, tokenId, data);
        
        // function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        // _transfer(from, to, tokenId);
        // require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
        
    }
    

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override{
        
        // safeTransferFrom(from,to,tokenId,"");
    }
  
    
    
    function _checkOnERC721Received(address from,address to,uint256 tokenId,bytes memory data) private returns (bool) {
        if (to.isContract()) {
            try IERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721TokenReceiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    
    
    // --------------------------------------------------------------Sales Token----------------------------------------/
    
    
    //   modifier isSaleOn() {
    //     require(block.timestamp >= _saleStartDate  && block.timestamp <= _saleEndDate,"Ops! Sale isn't started");
    //     _;
    // }
    
    function tokenPrice(uint256 _setTokenPrice) public onlyOwner {
        
        _tokenPrice = _setTokenPrice * 10 ** 18;
        
    }
    
    
    // function saleStarts(uint256 _setTokenPrice) public onlyOwner {
        
    //     require(_setTokenPrice > 0,"token price must be valid");
        
    //     _saleStartDate = block.timestamp;
        
    //     _saleEndDate = _saleStartDate + 30;
        
    //     _tokenPrice = _setTokenPrice;
    // }
    
    
    function mint(address to, uint256 tokenId) internal virtual {
        
       require(to != address(0),"ERC721: mint to the zero address");
       
       require(!_exists(tokenId),"ERC721: token already minted");
       
       require(_tokenSupply <= _totalSupply,"No more token available for minting");
       
       _owners[tokenId] = to;
       
       _balances[to] += 1;
      
      emit Transfer(address(0),to,tokenId);
       
   }
   
   
   
   function buyToken(address to) public payable isSaleOn {
       
       require(to != tokenOwner," recipient should not be tokenOwner");
       
       require(msg.value == _tokenPrice && to != address(0), "Amount should be valid(equal to _tokenPrice)and recipient must be valid address");
       
      _tokenSupply++;
       
       mint(to,_tokenSupply);
   }
   
   
   function burn(uint256 tokenId) public virtual{
       
       address owner = ownerOf(tokenId);
       
    //   clear approvals
    _approve(address(0), tokenId);
    
    _balances[owner] -= tokenId;
    
    delete _owners[tokenId];
    
    emit Transfer(owner, address(0), tokenId);
    
   }
      
   
   fallback() external payable{}
   
   receive() external payable{}
  
}