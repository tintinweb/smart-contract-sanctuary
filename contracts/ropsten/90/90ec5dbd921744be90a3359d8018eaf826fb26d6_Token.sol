pragma solidity ^0.4.25;

/// @title ERC20 token example by Andres Sanchez Martinez

//Based on OpenZeppeling MathSafe library for 
//Check for overflow or underflow using require function to revert changes instead of assertion
library SafeMath{

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256){
        uint256 c = a+b;
        require((c>=a) && (c>=b),"Logical problem");
        return c;
    }

    function safeMinus(uint256 a, uint256 b) internal pure returns(uint256){
        require(a>=b, "Logical problem");
        uint256 c = a-b;
        return c;
    }

    function safeMult(uint256 a, uint256 b) internal pure returns(uint256){
        if(a==0) return 0;
        uint256 c = a*b;
        require (c/a == b,"Logical problem");
        return c;
    }
}

//------ Simplified main functions according to the ERC20 standard
contract ERC20{

    function balanceOf(address _owner)                                  public view returns (uint256 balance);
    function transfer(address toAddr, uint256 amount)                   public returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Token is ERC20{
    using SafeMath for uint256;
    
    //------ TOKEN SPECIFICATIONS

    uint256 public initSupply;
    string public name = "SlackToken";
    uint8 public decimals = 2;
    string public symbol = "STK";
    mapping (address => uint256) balances;
    address public creator;

    //Constructor of our token, it will be simple due to the porpuose of demostration
    function Token(){

        creator = msg.sender;
        balances[msg.sender] = 100000;
        initSupply = 100000;
    }

    //BlanceOf returns the amount of tokens saved for an address
    function balanceOf(address addrs) public view returns (uint256 balance){
        
        return balances[addrs];
    }

    //Transfer moves balances from the sender address to the designated one for the value desired 
    function transfer(address toAddr, uint256 amount) public returns (bool success){

        //We prevent any posibility to transfer to 0x0 adress and to self being the amount over 0
        require(toAddr!=0x0 && toAddr!=msg.sender && amount>0);
        balances[msg.sender] = balances[msg.sender].safeMinus(amount);
        balances[toAddr] = balances[toAddr].safeAdd(amount);

        //We broadcast the event
        Transfer(msg.sender,toAddr,amount);
        return true;
    }
}