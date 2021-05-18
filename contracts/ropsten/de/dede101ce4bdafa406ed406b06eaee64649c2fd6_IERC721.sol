/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

//SPDX-License-Identifier: Unidentified
pragma solidity ^0.6.12;

library SafeMath 
{
    function add(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }
    function sub(uint256 a,uint256 b,string memory errorMessage ) internal pure returns (uint256) 
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256)
    {
        if (a == 0) 
        {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256)
    {
        return div(a, b, 'SafeMath: division by zero');
    }
    function div(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256)
    {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return mod(a, b, 'SafeMath: modulo by zero');
    }
    function mod(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) 
    {
        require(b != 0, errorMessage);
        return a % b;
    }
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) 
    {
        z = x < y ? x : y;
    }
    function sqrt(uint256 y) internal pure returns (uint256 z) 
    {
        if (y > 3)
        {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z)
            {
                z = x;
                x = (y / x + x) / 2;
            }
        } 
        else if (y != 0)
        {
            z = 1;
        }
    }
}

interface ERC721
{
    function balanceOf(address _owner) external view returns (uint256);
    
    function ownerOf(uint256 _tokenId) external view returns (address);
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    
    function approve(address _approved, uint256 _tokenId) external payable;
    
    function setApprovalForAll(address _operator, bool _approved) external;
    
    function getApproved(uint256 _tokenId) external view returns (address);
    
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

}

contract IERC721 is ERC721
{
    using SafeMath for uint256;
    string public name;
    string public symbol;
    
    mapping (uint256 => address) public _owners;
    
    mapping (address => uint256) public _balances;

    mapping (uint256 => address) public _tokenApprovals;

    mapping (address => mapping (address => bool)) public _operatorApprovals;
    
    constructor (string memory _name, string memory _symbol) public
    {
        name = _name;
        symbol = _symbol;
    }
    
    function balanceOf(address _owner) public view override returns (uint256)
    {
        require(_owner != address(0), "ERC721: balance query for the zero address");
        return _balances[_owner];
    }
    
    function ownerOf(uint256 _tokenId) public view override returns (address)
    {
        address owner = _owners[_tokenId];
        require(owner != address(0), "owner query for nonexistent token");
        return owner;
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public override payable
    {
        safeTransferFrom(_from, _to, _tokenId, data);
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override payable
    {
        address owner = _owners[_tokenId];
        require(_from != address(0),"invalid address");
        require(_to!= address(0),"invalid address");
        require(_tokenId >=0,"Give valid Input Id");
        require(msg.sender==owner || getApproved(_tokenId)==msg.sender || isApprovedForAll(owner,msg.sender),"Calling address is not approved");
        _balances[_from] = _balances[_from].sub(1);
        _balances[_to] = _balances[_to].add(1);
        emit Transfer(_from, _to, _tokenId);
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) public override payable
    {
        address owner = _owners[_tokenId];
        require(_from != address(0),"invalid address");
        require(_to!= address(0),"invalid address");
        require(_tokenId >=0,"Give valid Input Id");
        
        require(msg.sender==owner || getApproved(_tokenId)==msg.sender || isApprovedForAll(owner,msg.sender),"Calling address is not approved");
        _balances[_from] = _balances[_from].sub(1);
        _balances[_to] = _balances[_to].add(1);
        emit Transfer(_from, _to, _tokenId);   
    }
    
    function approve(address _approved, uint256 _tokenId) public override payable
    {
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(ownerOf(_tokenId), _approved, _tokenId);
    }
    
    function setApprovalForAll(address _operator, bool _approved) public override
    {
        require(_operator != msg.sender, " Not Approve caller");
        require(_operator!= address(0),"Invalid address");
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
    function getApproved(uint256 _tokenId) public view override returns (address)
    {
        require(_exists(_tokenId), "Nonexistent token");
        require(_tokenId> 0,"Input valid tokenId");
        return _tokenApprovals[_tokenId];
    }
    
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool)
    {
        require(_owner!= address(0), "Invalid address");
        require(_operator!= address(0), "Invalid address");
        return _operatorApprovals[_owner][_operator];
    }
    
    function _exists(uint256 tokenId) internal view  returns (bool) 
    {
        return _owners[tokenId] != address(0);
    }
    
    function _mint(address to, uint256 tokenId) public
    {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _balances[to] =_balances[to].add(1);
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }
    
    function _burn(uint256 tokenId) public
    {
        address owner = ownerOf(tokenId);
        approve(address(0), tokenId);
        _balances[owner]=_balances[owner].sub(1);
        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }
}