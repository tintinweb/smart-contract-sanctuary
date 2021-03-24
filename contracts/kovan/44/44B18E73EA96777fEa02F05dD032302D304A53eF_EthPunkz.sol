// SPDX-License-Identifier: UNLICENSED
pragma solidity <=0.7.4;

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function totalSupply() external view returns(string memory);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function mint(address to, uint256 tokenId, string memory uri) external;
}

contract EthPunkz {

     string private _name;
     string private _symbol;
     uint256 private _totalSupply;
     address public admin;

     mapping(uint256 => address) private _owners;
     mapping(address => uint256) private _balances;
     mapping(uint256 => address) private _tokenApprovals;
     mapping(address => mapping(address => bool)) private _operatorApprovals;
     mapping(uint256 => string) private _tokenURI;
     mapping(address => bool) private _governor;

     event Approval(address indexed from, address indexed to, uint256 tokenId);
     event ApprovalForAll(address indexed owner, address indexed operator,bool approved);
     event Transfer(address indexed from, address indexed to, uint256 tokenId);
    
     modifier exists(uint256 tokenId){
        require(
            _owners[tokenId] != address(0),"Invalid TokenId"
        );
        _;
     }

     modifier isAdmin(){
         require(
            msg.sender == admin, "Access Error : Caller Not Admin"
         );
         _;
     }

     modifier onlyGovernor(){
         require(
             _governor[msg.sender], "Access Error : Caller Not Governor"
         );
         _;
     }

     constructor(string memory name_ , string memory symbol_ , address admin_){
         _name = name_;
         _symbol = symbol_;
         admin = admin_;
     }

     function name() public view virtual returns(string memory){
         return _name;
     }

     function symbol() public view virtual returns(string memory){
         return _symbol;
     }

     function totalSupply() public view virtual returns(uint256){
         return _totalSupply;
     }

     function balanceOf(address owner) public view virtual returns(uint256){
         require(
             owner != address(0), "Query Error : Zero Address : 01"
         );
         return _balances[owner];
     }

     function ownerOf(uint256 tokenId) public view virtual returns(address){
         address owner = _owners[tokenId];
         require(owner != address(0),"Query Error : Zero Address : 01");
         return owner;
     }

     function tokenURI(uint256 tokenId) public view virtual exists(tokenId) returns(string memory){
         return _tokenURI[tokenId];
     }

     function approve(address to, uint256 tokenId) public virtual{
         address owner = _owners[tokenId];
         require(to != owner, "Error : Approval to Owner : 02");
         require(
             msg.sender == owner || isApprovedForAll(owner,msg.sender),
            "Error Approval : 02"
         );
         _approve(to,tokenId);
     }

    function _approve(address to, uint256 tokenId) internal virtual{
         _tokenApprovals[tokenId] = to;
         emit Approval(ownerOf(tokenId), to, tokenId);
     }

     function getApproved(uint256 tokenId) public view virtual exists(tokenId) returns(address){
         return _tokenApprovals[tokenId];
     }

     function setApprovalForAll(address operator, bool approved) public virtual {
         require(operator != address(0),"Error : Zero Address : 01");
         _operatorApprovals[msg.sender][operator] = approved;
         emit ApprovalForAll(msg.sender, operator, approved);
     }

    function isApprovedForAll(address owner, address operator) public view virtual returns(bool){
        return _operatorApprovals[owner][operator];
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        /* solhint-disable */
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function transferFrom(address from, address to,uint256 tokenId) public virtual{
        require(
            _isApprovedOrOwner(msg.sender,tokenId),"Access Error : 03"
        );
        _transfer(from,to,tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual {
        safeTransferFrom(from,to,tokenId,"");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual{
        require(
            _isApprovedOrOwner(msg.sender,tokenId),"Access Error : No Owner : 04"
        );
        _safeTransfer(from, to, tokenId, data);
    }

    function mint(address to, uint256 tokenId, string memory _uri) public virtual onlyGovernor {
        mint(to,tokenId,_uri,"");
    }

    function mint(address to, uint256 tokenId,string memory _uri , bytes memory _data) public virtual onlyGovernor {
        _mint(to,tokenId,_uri);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "Error : Unsupported Address"
        );
    }

    function _mint(address to, uint256 tokenId, string memory _uri) internal virtual{
        require( to != address(0),"Error : Zero Address : 01");
        require( _owners[tokenId] == address(0), "Error, Already Minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;
        _totalSupply += 1;
        _tokenURI[tokenId] = _uri;

        emit Transfer(address(0),to,tokenId);

    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual{
        _transfer(from,to,tokenId);
        require(_checkOnERC721Received(from,to,tokenId,_data),"Error : Unsupported Contract");
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "Access Error : No Owner : 04");
        require(to != address(0),"Error : Zero Address : 01");
        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0),tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _isApprovedOrOwner(address spender,uint256 tokenId) internal view virtual exists(tokenId) returns(bool){
        address owner = ownerOf(tokenId);
        return(
            spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner,spender)
        );
    }

    function addGovernor(address _newGovernor) public virtual returns(bool){
        _governor[_newGovernor] = true;
        return true;
    }

    function removeGovernor(address _oldGovernor) public virtual returns(bool){
        _governor[_oldGovernor] = false;
        return true;
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /* solhint-disable */
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }

}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}