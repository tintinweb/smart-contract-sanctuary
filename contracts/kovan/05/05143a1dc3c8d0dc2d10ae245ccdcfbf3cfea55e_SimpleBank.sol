/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

pragma solidity ^0.6.4;

interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}
contract SimpleBank{
    ERC20 coin;
    mapping (address=> uint) balances; //balances[msg.seender ] will return the depositors deposited amount
    mapping (address=> bool) hasDeposit; // hasDeposit[msg.sender] will return true or false
    //address[] depositors;
    
    constructor( address _tokenContract) public {
        coin = ERC20(_tokenContract);
    }
    
    function deposit(uint amt) public returns (bool)  {
        require(amt != 0 , "deposit amount cannot be zero");
        require(coin.balanceOf(msg.sender)> amt, "insufficient balance");
        coin.approve(address(this), amt);
        coin.transferFrom(msg.sender, address(this), amt);
        balances[msg.sender]+=amt;
        hasDeposit[msg.sender]=true;
        return true;
    }
    
    function release() public returns (bool)  {
        require(balances[msg.sender] != 0 , "no deposit balance found");
        require(hasDeposit[msg.sender]= true, "no previous deposit");
        coin.transfer(msg.sender,balances[msg.sender]  );
        balances[msg.sender]= 0;
        hasDeposit[msg.sender]= false;
        return true;
    }
}