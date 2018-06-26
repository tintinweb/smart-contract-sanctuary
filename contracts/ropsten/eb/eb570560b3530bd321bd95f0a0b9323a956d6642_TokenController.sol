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
    bytes32 public standard;
    bytes32 public name;
    bytes32 public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    bool public allowTransactions; 
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    function transfer(address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract TokenController is OwnerHelper
{
    using SafeMath for uint;
    
    // add by John
    struct poolInfo 
    {
        string poolName;
        address poolContract;
        address ownerWallet;
        uint cap;
        uint total;
        uint max;
        uint min;
        uint maxInvestPerPerson;
        uint feeRate;
        uint tokenPerEth;
        uint fee;
        uint recvToken;
        uint withdrawCount;
        address[] poolMembers;
    
    }
    mapping (uint => poolInfo) public poolInfoData;                       
    mapping (address => uint) internal poolNumbers;    // _poolOwner, _poolNum 
    mapping (address => bool) internal poolExist;
    mapping (uint => mapping (address => uint)) internal poolInvestData;    // _poolNum, _investor, _value
    mapping (address => uint) internal depositEth;                          // personal deposit data
    uint public poolNumber;
    uint public E18 = 10 ** 18;
    uint public safeShareFee = 5;

    constructor() public
    {
        poolNumber = 0;
    }
    
    function () payable public  
    {
        depositEth[msg.sender] = depositEth[msg.sender].add(msg.value);
    }
    
    function createPool(string _poolName, address _poolContract, uint _cap, uint _min, uint _max, uint _maxInvestPerPerson, uint _feeRate, uint _tokenPerEth) public
    {
        require(poolExist[msg.sender] == false);
        
        poolInfoData[poolNumber].poolName = _poolName;
        poolInfoData[poolNumber].poolContract = _poolContract;
        poolInfoData[poolNumber].ownerWallet = msg.sender;
        poolInfoData[poolNumber].cap = _cap * E18;
        poolInfoData[poolNumber].total = 0;
        poolInfoData[poolNumber].min = _min * E18;
        poolInfoData[poolNumber].max = _max * E18;
        poolInfoData[poolNumber].maxInvestPerPerson = _maxInvestPerPerson * E18;
        poolInfoData[poolNumber].feeRate = _feeRate;
        poolInfoData[poolNumber].tokenPerEth = _tokenPerEth;

        poolNumbers[msg.sender] = poolNumber;
        poolNumber = poolNumber + 1;
        poolExist[msg.sender] = true;
    }
    
    function joinToPool(uint _poolNum, uint _value) public
    {
        uint value = _value * E18;
        
        require(poolInfoData[_poolNum].cap >= poolInfoData[_poolNum].total.add(value));
        require(poolInfoData[_poolNum].min <= value && poolInfoData[_poolNum].max >= value);
        require(poolInfoData[_poolNum].maxInvestPerPerson >= poolInvestData[_poolNum][msg.sender].add(value));
        require(depositEth[msg.sender] >= value);
        
        poolInfoData[_poolNum].poolMembers.push(msg.sender);
        depositEth[msg.sender] = depositEth[msg.sender].sub(value);
        poolInvestData[_poolNum][msg.sender] = poolInvestData[_poolNum][msg.sender].add(value);
        poolInfoData[_poolNum].total = poolInfoData[_poolNum].total.add(value);
    }
    
    function outFromPool(uint _poolNum) public 
    {
        require(poolInvestData[_poolNum][msg.sender] > 0);
        
        deleteMember(_poolNum);
        
        poolInfoData[_poolNum].total = poolInfoData[_poolNum].total.sub(poolInvestData[_poolNum][msg.sender]);
        depositEth[msg.sender] = depositEth[msg.sender].add(poolInvestData[_poolNum][msg.sender]);
        delete poolInvestData[_poolNum][msg.sender];
    }
    
    function withdrawToPoolOwner(uint _poolNum) payable public
    {
        require(poolInfoData[_poolNum].ownerWallet == msg.sender);
        
        // payment of fee
        uint contractFee = poolInfoData[_poolNum].total.div(1000).mul(safeShareFee);
        poolInfoData[poolNumber].fee = poolInfoData[_poolNum].total.div(1000).mul(poolInfoData[_poolNum].feeRate);
        poolInfoData[_poolNum].total = poolInfoData[_poolNum].total.sub(contractFee + poolInfoData[poolNumber].fee);
        
        // calculrating total token
        poolInfoData[_poolNum].recvToken = poolInfoData[_poolNum].total.mul(poolInfoData[_poolNum].tokenPerEth);
        
        // send Eth to pool owner
        poolInfoData[_poolNum].ownerWallet.transfer(poolInfoData[_poolNum].total);
    }
    
    function withdrawToPoolOwnerFee(uint _poolNum) payable public
    {
        require(poolInfoData[_poolNum].ownerWallet == msg.sender);
        
        poolInfoData[_poolNum].ownerWallet.transfer(poolInfoData[_poolNum].fee);
    }
    
    function refundEther() payable public
    {
        require(depositEth[msg.sender] > 0);
        
        msg.sender.transfer(depositEth[msg.sender]);
        delete depositEth[msg.sender];
    }
    
    function multipleTokenDistribute(uint _poolNum) public
    {
        require(poolInfoData[_poolNum].ownerWallet == msg.sender);
        
        uint token;
        
        for(uint i = 0; i < poolInfoData[_poolNum].poolMembers.length ; i++)
        {
            token = poolInvestData[_poolNum][poolInfoData[_poolNum].poolMembers[i]].mul(poolInfoData[_poolNum].tokenPerEth);    // investEth * tokenRate
            token = token - (token.div(1000).mul(poolInfoData[_poolNum].feeRate + safeShareFee));                               // fee payment
            
            Token(poolInfoData[_poolNum].poolContract).transfer(poolInfoData[_poolNum].poolMembers[i], token);                  // transfer Token
            delete poolInvestData[_poolNum][poolInfoData[_poolNum].poolMembers[i]];
        }
        
        poolExist[msg.sender] = false;
        delete poolInfoData[_poolNum];
    }
    
    function withdrawToken(uint _poolNum) public
    {
        require(poolInvestData[_poolNum][msg.sender] > 0);
        
        uint token;
        
        token = poolInvestData[_poolNum][msg.sender].mul(poolInfoData[_poolNum].tokenPerEth);
        token = token - (token.div(1000).mul(poolInfoData[_poolNum].feeRate + safeShareFee));   
        
        poolInfoData[_poolNum].withdrawCount = poolInfoData[_poolNum].withdrawCount + 1;
        
        Token(poolInfoData[_poolNum].poolContract).transfer(msg.sender, token);
        delete poolInvestData[_poolNum][msg.sender];
    }
    
    function relievePool(uint _poolNum) public 
    {
        require(msg.sender == poolInfoData[_poolNum].ownerWallet);
        require(poolInfoData[_poolNum].withdrawCount == poolInfoData[_poolNum].poolMembers.length);
        
        poolExist[poolInfoData[_poolNum].ownerWallet] = false;
        delete poolInfoData[_poolNum];
    }
    
    function showPoolMembers(uint _poolNum) public view returns (address[])
    {
        return poolInfoData[_poolNum].poolMembers;
    }
    
    function showInvestEther(address _investor ,uint _poolNum) public view returns (uint)
    {
        return poolInvestData[_poolNum][_investor];
    }
    
    function showDepositEther(address _who) public view returns (uint)
    {
        return depositEth[_who];
    }
    
    function showPoolNumber(address _poolOnwer) public view returns (uint)
    {
        return poolNumbers[_poolOnwer];
    }
    
    function withDrawEther() onlyOwner payable public
    {
        owner.transfer(address(this).balance);
    }
    
    function indexOf(address[] members, address targetAddress) pure public returns (uint)
    {
        uint index;
        
        for(uint i = 0; i < members.length; i++)
        {
            if(members[i] == targetAddress)
            {
                index = i;
                break;
            }
        }
        return index;
    }
    
    function deleteMember(uint _poolNum) public
    {
        uint index = indexOf(poolInfoData[_poolNum].poolMembers, msg.sender);
        
        for(uint i = 0 ; i < poolInfoData[_poolNum].poolMembers.length - 1 ; i++)
        {
            if(i < index)
            {
                poolInfoData[_poolNum].poolMembers[i] = poolInfoData[_poolNum].poolMembers[i];
            }
            else if(i >= index)
            {
                poolInfoData[_poolNum].poolMembers[i] = poolInfoData[_poolNum].poolMembers[i+1];
            }
        }
        poolInfoData[_poolNum].poolMembers.length--;
    }
}