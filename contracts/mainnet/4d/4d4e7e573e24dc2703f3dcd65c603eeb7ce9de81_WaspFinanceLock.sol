pragma solidity ^0.5.17;


contract Wasp {
    function totalSupply() external view returns (uint256 _totalSupply){}
    function balanceOf(address _owner) external view returns (uint256 _balance){}
    function transfer(address _to, uint256 _value) external returns (bool _success){}
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool _success){}
    function approve(address _spender, uint256 _value) external returns (bool _success){}
    function allowance(address _owner, address _spender) external view returns (uint256 _remaining){}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract WaspFinanceLock {
    
     uint256 constant sixmonth = 16136064;
    
     Wasp token;
     
     address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner,"You are not Authorize to call this function");
        _;
    } 
    
     constructor() public {
        owner = msg.sender;
    
        token = Wasp(0x938FD0EB452972A72692631A10DD5eEA29832b6f);
    }
    
    function withdrawOwnerNioxToken(uint256 _tkns) public  onlyOwner returns (bool) {
             require(block.timestamp >= sixmonth);
             require(token.transfer(msg.sender, _tkns));
             return true;
    }
    
}