/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;

contract ERC721 /* is ERC165 */ {
    // Các sự kiện để theo dõi smart contract, sử dụng để broadcast cho phía client biết là có chức năng nào đó đã được thực thi.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    // Hàm đếm tất cả NFT thuộc địa chỉ của chủ sở hữu
    mapping(address => uint256) internal _balances; // Khai báo biến số lượng nft: _balances.
    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "Invalid address");
        return _balances[owner];
    }
    // Trả về chủ sở hữu của NFT
    mapping(uint256 => address) internal _owners;
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        return owner;
    }

    // Giao quyền operator cho 1 address (ở đây là address của OpenSea), có quyền quản lý tất cả nft
    mapping(address => mapping(address => bool)) private _operatorApprovals; // Biến mapping 2 chiều 
    function setApprovalForAll(address operator, bool approved) external {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    // Kiểm tra xem address có phải là operator của địa chỉ thứ 2 hay không (có quyền quản lý tất cả nft của owner address)
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // Giao quyền approval cho address, có quyền quản lý 1 nft
    mapping(uint256 => address) private _tokenApprovals;
    function approve(address approved, uint256 tokenId) public payable {
        address owner = ownerOf(tokenId);
        // Kiểm tra chỉ có chủ (owner của nft) hoặc operator mới có quyền gọi hàm approve
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "msg.sender is not an Owner or Operator");
        _tokenApprovals[tokenId] = approved;
        emit Approval(owner, approved, tokenId);
    }
    function getApproved(uint256 tokenId) public view returns (address) {
        // Kiểm tra owners của tokenId phải khác địa chỉ 0
        require(_owners[tokenId] != address(0), "TokenId does not exist");
        return _tokenApprovals[tokenId];
    }


    // Chuyển tokenId từ from -> to 
    function transferFrom(address from, address to, uint256 tokenId) external payable {
        address owner = ownerOf(tokenId);
        // Chỉ có owner, operator hoặc address được owner ủy quyền mới có quyền transfer
        require(msg.sender == owner || getApproved(tokenId) == msg.sender || isApprovedForAll(owner, msg.sender),
        "Msg.sender is not the owner or approval for transfer");
        // Check lỗi owner không được trùng với from
        require(owner == from, "from address is not the owner");
        // Check lỗi không cho phép chuyển về address(0)
        require(to != address(0), "Address is the zero address");

        // Reset onwer của tokenId về address(0), trước khi update
        approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
    // function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;
    // function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

}