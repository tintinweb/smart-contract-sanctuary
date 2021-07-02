/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');
        return c;
    }
    function sub(uint256 a,uint256 b) internal pure returns (uint256) {
        require(b <= a, 'SafeMath: subtraction overflow');
        uint256 c = a - b;
        return c;
    }
}
interface nftToken {
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    function _exists(uint256 tokenId) external view returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
}
interface ERCMetadata {
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
}
contract nft is nftToken , ERCMetadata {
    using SafeMath for uint256;
    string _name;
    string _symbol;
    address public admin1;
    mapping(uint256 => address) public ownerAddress;      // Mapping from tokenId to ownerAddress
    mapping(address => uint256) public balance;          // Mapping from ownerAddress to token count
    mapping(uint256 => address) public approvedAddress; // Mapping from tokenId to approved address
    mapping(address => mapping(address => bool)) public tokenApprovals; // owner sets or unsets approval for address
    constructor(string memory name, string memory symbol) public {
        admin1=msg.sender;
        _name=name;
        _symbol=symbol;
    }
    function balanceOf(address _owner) public override view returns(uint256) {
        require(_owner!=address(0),"Invalid Address");
        return balance[_owner];
    }
    function ownerOf(uint256 _tokenId) public override view returns (address) {
        address owner = ownerAddress[_tokenId];
        require(owner!=address(0),"TokenId does not exists");
        return owner;
    }
    function name() public override view returns(string memory) {
        return _name;
    }
    function symbol() public override view returns(string memory) {
        return _symbol;
    }
    function approve(address _approved, uint256 _tokenId) public override payable {
        address owner = ownerOf(_tokenId);
        require(owner!=_approved,"Approval for self");
        require(msg.sender==owner,"Calling address is not the owner of given tokenId");
        approvedAddress[_tokenId]=_approved;
        emit Approval(ownerOf(_tokenId), _approved, _tokenId);
    }
    function getApproved(uint256 _tokenId) public override view returns(address) {
        address owner = ownerOf(_tokenId);
        require(owner!=address(0),"TokenId does not exists");
        return approvedAddress[_tokenId];
    }
    function setApprovalForAll(address _operator, bool _approved) public override {
        require(msg.sender!=_operator,"Approval for current address");
        tokenApprovals[msg.sender][_operator]=_approved;
         emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    function isApprovedForAll(address _owner, address _operator) public override view returns(bool) {
        return tokenApprovals[_owner][_operator];
    }
    function transferFrom(address _from, address _to, uint256 _tokenId) public override payable {
        address owner = ownerAddress[_tokenId];
        require(owner!=address(0),"TokenId does not exists");
        //checking whether msg.sender has approval for sending given TokenId
        require((_from==msg.sender && msg.sender==owner) || getApproved(_tokenId)==msg.sender || isApprovedForAll(owner,msg.sender),"Calling address is not approved");
        //require(,"From address is not the owner of given address");
        require(_to!=address(0),"Receiver address must not be zeo address");
        balance[_from]=balance[_from].sub(1);
        balance[_to]=balance[_to].add(1);
        ownerAddress[_tokenId]=_to;
        emit Transfer(_from, _to, _tokenId);
    }
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override payable {
        safeTransferFrom(_from,_to,_tokenId,"");
    }
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public override payable {
        address owner = ownerAddress[_tokenId];
        require(owner!=address(0),"TokenId does not exists");
        require(msg.sender==owner || getApproved(_tokenId)==msg.sender || isApprovedForAll(owner,msg.sender),"Calling address is not approved");
        require(_from==owner,"From address is not the owner of given address");
        require(_to!=address(0),"Receiver address must not be zeo address");
        data="";
        balance[_from]=balance[_from].sub(1);
        balance[_to]=balance[_to].add(1);
        ownerAddress[_tokenId]=_to;
        emit Transfer(_from, _to, _tokenId);
    }
    function _exists(uint256 tokenId) public override view returns (bool) {
        return ownerAddress[tokenId] != address(0);
    }
    modifier onlyAdmin {
        require(msg.sender==admin1,"Only admin is allowed to access");
        _;
    }
    function mint(address _to, uint256 _tokenId) public onlyAdmin {
         require(_to != address(0), "Mint to the zero address");
         require(!_exists(_tokenId), "TokenId already minted");
         balance[_to]=balance[_to].add(1);
         ownerAddress[_tokenId] = _to;
         emit Transfer(address(0), _to, _tokenId);
     }
    function burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        balance[owner] =balance[owner].sub(1);
        delete ownerAddress[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }
}