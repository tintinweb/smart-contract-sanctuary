/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
contract ERC721{

    mapping(address => uint256) internal _balances;
    mapping(uint256 =>address) internal _owner;
    mapping(address =>mapping(address =>bool) )private _operatorApprovals;
    mapping(uint256 =>address) private _tokenApprovals;
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    // truyền vào address và trả ra số lượng NFTs đang sở hữu
    
    function balanceOf(address owner) external view returns (uint256){
        require(owner != address(0),"Address is zelo"); //Theo chuẩn kiểm tra address khác AAddress 0
        return _balances[owner];
    }
    //truyền id của NFT trả ra address chủ sở hữu
    function ownerOf(uint256 tokenId) public view returns (address){
        address owner =_owner[tokenId];
        require(owner != address(0),"tokenID does not exist");
        return owner;
    }
    // enable or disable an operator
    function setApprovalForAll(address operator, bool approved) external{
        _operatorApprovals[msg.sender][operator]= approved;
        emit ApprovalForAll(msg.sender,operator,approved);
    }
    //kiểm tra nếu một địa chỉ là một operator cho một địa chỉ khác
    function isApprovedForAll(address owner, address operator) public view returns (bool){
        return _operatorApprovals[owner][operator];
    }
    // Updates an approved address for an NFT
    function approve(address approved, uint256 tokenId) public payable{
        address owner =ownerOf(tokenId);
        require(msg.sender==owner || isApprovedForAll(owner,msg.sender),"msg.sender is not the owner or the approved operator");
        _tokenApprovals[tokenId] =approved;
        emit Approval(owner,approved,tokenId);
    }
    // Get the approved address for an NFT
    function getApproved(uint256 tokenId) public view returns (address){
        require(_owner[tokenId] != address(0),"tokenID does not exist");
        return _tokenApprovals[tokenId];
    }
        // tranfer ownership vof a single NFT
    function transferFrom(address from, address to, uint256 tokenId) public payable{
        address owner = ownerOf(tokenId);
        require(
            msg.sender ==owner ||
            getApproved(tokenId)==msg.sender ||
            isApprovedForAll(owner, msg.sender),
            "Msg.sender is not the owner or approved for transfer"
        );
        require( owner==from,"from address is not the owner");
        require(to !=address(0),"address is the zero address");
        require(_owner[tokenId] != address(0),"tokenID does not exist");
        approve(address(0), tokenId);
        _balances[from]-= 1;
        _balances[to]+= 1;
        _owner[tokenId]=to;
        emit Transfer(from, to, tokenId);
    }
            //cũng là method trafer nhuwgn kiểm tra contract nhận có chức năng nhận hay không
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public payable{
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(),"Receiver not implemented");
    }
    //simple version to check for nft receivable of a smart contract
    function _checkOnERC721Received()private pure returns(bool){
        return true;
    }
    // 
    function safeTransferFrom(address from, address to, uint256 tokenId) external payable{
        safeTransferFrom(from, to, tokenId,"");
    }
    //EIP proposal:query if a contract implements another interface
    function supportInterface(bytes4 interfaceID) public pure virtual returns(bool){
        return interfaceID ==0x80ac58cd;
    }
}