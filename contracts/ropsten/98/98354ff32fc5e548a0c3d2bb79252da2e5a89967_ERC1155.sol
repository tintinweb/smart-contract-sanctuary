/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

//SPDX-License-Identifier: UNLICENSED 
pragma solidity 0.6.12;
//import "./SafeMath.sol";
library safeMath{
    
    function add(uint a, uint b) internal pure returns (uint){
        uint c = a+b;
        assert(c>=a);
        return c;
    }
    
    function sub(uint a, uint b) internal pure returns (uint){
        assert (b<=a);
        return a-b;
    }
    
    function mul(uint a, uint b) internal pure returns (uint){
        uint c = a*b;
        assert (a==0 || c/a ==b);
        return c;
    }
    
    function div(uint a, uint b)internal pure returns (uint){
        uint c = a/b;
        return c;
    }
}   
 interface IERC1155{
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
 }
 
 contract ERC1155 is IERC1155{
     using safeMath for uint256;
     mapping (uint256 => mapping(address => uint256)) public _balances;
     mapping (address => mapping(address => bool)) public _operatorApprovals;
     string public _uri;
     
     constructor(string memory _Turi) public{
         _setURI(_Turi);
     }
     
      function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }
    
     function uri(uint256) public view virtual returns (string memory) {
        return _uri;
    }
    
     function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }
    
     function balanceOfBatch(address[] memory accounts,uint256[] memory ids)
        public view virtual override returns (uint256[] memory){
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");
        uint256[] memory batchBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }
        return batchBalances;
    }
    
     function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data)
        public virtual override{
        require( msg.sender == from || isApprovedForAll(from, msg.sender),
        "ERC1155: caller is not owner nor approved");
        _safeTransferFrom(from, to, id, amount, data);
    }
    
     function safeBatchTransferFrom(address from,address to,uint256[] memory ids,uint256[] memory amounts,bytes memory data)
        public virtual override {
        require( from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155: transfer caller is not owner nor approved");
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }
    
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(msg.sender != operator, "ERC1155: setting approval status for self");
       _operatorApprovals[msg.sender][operator] = approved;
       emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }
   
    function mint(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");
        address operator = msg.sender;
        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);
    }
    
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        address operator = msg.sender;
        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }
        emit TransferBatch(operator, address(0), to, ids, amounts);
    }
    
    function burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        address operator = msg.sender;
        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        _balances[id][account] = accountBalance - amount;
        emit TransferSingle(operator, account, address(0), id, amount);
    }
    
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        address operator = msg.sender;
        for (uint i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            _balances[id][account] = accountBalance - amount;
            emit TransferBatch(operator, account, address(0), ids, amounts);}
    }
    
     function _safeBatchTransferFrom(address from,address to,uint256[] memory ids,uint256[] memory amounts,bytes memory data)
        internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        address operator = msg.sender;
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            _balances[id][from] = fromBalance - amount;
            _balances[id][to] += amount; }
            emit TransferBatch(operator, from, to, ids, amounts);
    }
    
    function _safeTransferFrom(
        address from,address to,uint256 id,uint256 amount, bytes memory data)
        internal virtual{
        require(to != address(0), "ERC1155: transfer to the zero address");
        address operator = msg.sender;
        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        _balances[id][from] = fromBalance - amount;
        _balances[id][to] += amount;
       emit TransferSingle(operator, from, to, id, amount);
    }
}