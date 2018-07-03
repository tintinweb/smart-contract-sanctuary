pragma solidity ^0.4.24;

library SafeMath
{
    function mul(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    {
        assert(b <= a);

        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);

        return c;
    }
}

contract OwnerHelper
{
    address public owner;

    event OwnerTransferPropose(address indexed _from, address indexed _to);

    modifier onlyOwner
    {
        require(msg.sender == owner);
        _;
    }

    constructor() public
    {
        owner = msg.sender;
    }

    function transferOwnership(address _to) onlyOwner public
    {
        require(_to != owner);
        require(_to != address(0x0));
        owner = _to;
        emit OwnerTransferPropose(owner, _to);
    }
}

contract Token {
    bytes32 public name;
    bytes32 public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    function transfer(address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function showMsgSender() public  view returns (address);
}

contract TokenController is OwnerHelper
{
    using SafeMath for uint; 
    
    mapping (address => uint) public depositEth;    // personal deposit data
    mapping (address => bool) public personalLock;
    
    address[] members;

    constructor() public
    {
        members.push(0xe400971e92228481E789Ac5e99e2E47F8717bEf8);
        members.push(0xe400971e92228481E789Ac5e99e2E47F8717bEf8);
        members.push(0xe400971e92228481E789Ac5e99e2E47F8717bEf8);
        members.push(0xe400971e92228481E789Ac5e99e2E47F8717bEf8);
    }
    
    function () payable public  
    {
        depositEth[msg.sender] = depositEth[msg.sender].add(msg.value);
    }
    
    function showArrayLength() public view returns (uint)
    {
        return members.length;
    }
    
    function deleteArray() public 
    {
        members.length--;
    }
    
    function depositToken(address _token, uint _amount) public 
    {
        uint amount = _amount * (10 ** 18);
        Token(_token).transferFrom(msg.sender, address(this), amount);
    }

    function transferToken(address _token, address _to ,uint _amount) public
    {
        Token(_token).transfer(_to, _amount);
    }
    
    function approveToken(address _token, uint _amount) public returns (bool)
    {
        uint amount = _amount * (10 ** 18);
        return address(Token(_token)).delegatecall(bytes4(keccak256(&quot;approve(address,uint256)&quot;)), address(this), amount);
    }
    
    function tokenTotalSupply(address _token) public view returns (uint)
    {
        return Token(_token).totalSupply();
    }
    
    function tokenBalance(address _token, address _who) public view returns (uint)
    {
        return Token(_token).balanceOf(_who);
    }
    
    function showApproveToken(address _token) public view returns (uint)
    {
        return Token(_token).allowance(msg.sender, this);
    }
    
    function showContractMsgSender(address _token) public view returns (address)
    {
        return Token(_token).showMsgSender();
    }
    function showDelegateMsgSender(address _token) public
    {
        bool a;
        a = address(Token(_token)).delegatecall(msg.data);
    }
}