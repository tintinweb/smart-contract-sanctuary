/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

pragma solidity ^0.5.10;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
} 

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = 0x97b2d5c1DAa5A0B0f06dDDab05c93627F6f47c43;
    }
            
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract EsportsPro is ERC20Interface, Owned { 
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;
    uint _teamAdvisorsSupply;
    uint _tokenSales;
    uint _companyReserve;
    uint _userbaseReserve;
    uint _airdropReserve;
    
    address public sales_account;
    address public company_reserve;
    uint public unlockDate;
    uint public createdAt;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    constructor() public { 
        name = "EsportsPro";
        symbol = "ESPRO";
        decimals = 18;
        _totalSupply = 1000000000 * 10**uint(decimals);
        _tokenSales = 610000000 * 10**uint(decimals);
        _companyReserve = 250000000 * 10**uint(decimals);
        _userbaseReserve = 320000000 * 10**uint(decimals);
        createdAt = now;
        sales_account = 0x97b2d5c1DAa5A0B0f06dDDab05c93627F6f47c43;
        company_reserve = 0xcAe76f62fd7084eD5435a4bE2fb93941019530e8;
        balances[sales_account] = _tokenSales;
        balances[company_reserve] = _companyReserve;
        emit Transfer(address(0), sales_account, _tokenSales);
        emit Transfer(address(0), company_reserve, _companyReserve);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function Burn(address _address,uint256 value) public  onlyOwner{
        
        balances[_address] = balances[_address].sub(value);
        _totalSupply = _totalSupply.sub(value);
    }
    function Mint(address _address,uint256 value) public  onlyOwner{
        
        balances[_address] = balances[_address].add(value);
        _totalSupply = _totalSupply.add(value);
    }


    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    function () external payable {
        revert();
    }

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
}