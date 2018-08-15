pragma solidity ^0.4.24;

contract ERC20Interface {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract ERC20Vault{
    mapping (address => uint) public ERC20Balance;
    mapping (address => uint) public ReleaseTimer;
    
    mapping (address => uint) public AddGas;
    mapping (address => mapping(address => bool)) public AllowedTransferAddress;
    
    ERC20Interface MainContract;

    constructor(address target) public {
        MainContract = ERC20Interface(target);
    }
    
    address public owner = msg.sender;

    address gasForward; 

    function setGasForward(address target) public {
        require(msg.sender == owner);
        gasForward = target;
    }


    //0x0000000000000000000000000000000000000000000000000000000000000fff
    // 1000000000000000000
    // stake eth for gas, minimal 1 hour, max 30 days 
    function tokenFallback(address sender, uint value, bytes data) public payable returns (bool) {
        // extract lock time 
        require(msg.sender == address(MainContract));
        require(data.length == 32);
        uint lockTime;
        assembly{
            lockTime := mload(add(data, 0x20))
        }
        
        _updateLock(lockTime, sender);
        ERC20Balance[sender] = ERC20Balance[sender] + value;
    }
    
    function _updateLock(uint lockTime, address who) internal{
        require(lockTime <= (30 days));
        require(lockTime >= (60 minutes));
        ReleaseTimer[who] = now + lockTime;
    } 
    
    function updateLock(uint lockTime) public {
        _updateLock(lockTime, msg.sender);
    }
    
    function delegateGetTokens(address target, uint howMuch) public{ 
        require(AllowedTransferAddress[target][msg.sender]);
        require(ERC20Balance[target] >= howMuch);
        ERC20Balance[target] = ERC20Balance[target] - howMuch;
        //MainContract.transfer(msg.sender,howMuch);
    }
    
    function allowAddress(address which) public {
        AllowedTransferAddress[msg.sender][which] = true;
    }

    function allowAddressDelegate(address which, address from) public {
        require(msg.sender == gasForward);
        AllowedTransferAddress[from][which] = true;
    }
    
    function getTokens(uint howMuch) public{
        require(now >= ReleaseTimer[msg.sender]);
        require(howMuch <= ERC20Balance[msg.sender]);
        ERC20Balance[msg.sender] = ERC20Balance[msg.sender] - howMuch;
        MainContract.transfer(msg.sender, howMuch);
    }
    
    function getAllTokens() public {
        getTokens(ERC20Balance[msg.sender]);
    }
    
    function internalTransfer(int delta, address target, address from) public {
        if (delta < 0){
            require(AllowedTransferAddress[target][from]);
            require(ERC20Balance[target] >= uint(-delta));
            ERC20Balance[from] += uint(-delta);
            ERC20Balance[target] -= uint(-delta);
        }
        else{
            require(tx.origin == from || msg.sender == from);
            require(ERC20Balance[from] >= uint(delta));
            ERC20Balance[from] -= uint(delta);
            ERC20Balance[target] += uint(delta);
        }
    }
}