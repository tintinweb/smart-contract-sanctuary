/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

pragma solidity ^0.4.20;

         
contract IaunToken721{
    
    mapping(address => uint256) private _ownedTokensCount;
    mapping(uint256 => address) private _tokenOwner;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(uint256 => bool) _tokenValid;
    mapping(uint256 => string) _tokenURI;
    address ownerContract = msg.sender;
    
    modifier onlyOwner {
        require(ownerContract == msg.sender);
        _;
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);


    function mint(uint256 _tokenId, string _uri, address _to) onlyOwner external {
        require(_tokenValid[_tokenId] == false);
        _tokenURI[_tokenId] = _uri;
        _tokenOwner[_tokenId] = _to;
        _tokenValid[_tokenId] = true;
        _ownedTokensCount[_to] += 1;
    }
    
     function getTokenURI(uint256 _tokenId) external view returns (string memory){
        return _tokenURI[_tokenId];
    }
    
    function balanceOf(address _owner) external view returns (uint256){
        require(_owner != address(0));
        return _ownedTokensCount[_owner];
    }
    
    function ownerOf(uint256 _tokenId) public view returns (address){
        address owner = _tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }
    
    function isApprovedForAll(address _owner, address _operator) public view returns (bool){
        return _operatorApprovals[_owner][_operator];   
    }
    
    function approve(address to, uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        require(owner != to);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) public{
        address owner = ownerOf(_tokenId);
        require(_tokenValid[_tokenId]);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));
        require(_from == owner);
        require(_to != 0);
        
        _tokenOwner[_tokenId] = _to;
        _ownedTokensCount[_from] -= 1;
        _ownedTokensCount[_to] += 1;
        
        emit Transfer(_from , _to, _tokenId);
    }
    
     function setApprovalForAll(address _operator, bool _approved) external{
         require(_operator != msg.sender);
         _operatorApprovals[msg.sender][_operator] = _approved;
         emit ApprovalForAll(msg.sender,_operator,_approved);
     }
     
     function getApproved(uint256 _tokenId) external view returns (address){
        require(_tokenValid[_tokenId]);
        address _approve =  _tokenApprovals[_tokenId];
        require(_approve != address(0));
        return _approve;
     }
     
     function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external{
        transferFrom(_from, _to, _tokenId);
     }
     
     function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        transferFrom(_from, _to, _tokenId);   
     }
    
}