/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

pragma solidity 0.5.0;

contract ERC20{
    //Constructtor
    //set the total number of tokens
    //read the total number of tokens
    string public name ="MSI Token";
    string public symbol="MSI";
    string public standerd="MSI Token 1.0";
    uint public totalSupply;
    event Transfer(address indexed _from,address indexed _to,uint amount);
    mapping(address=>uint) public balanceof;//address can be EOA or a contract address
    mapping(address=>mapping(address=>uint))public allowance;
    event Approve(address indexed _from,address indexed _to,uint amount);
    constructor(uint _initialSupply) public{
        //allocate tokens
        balanceof[msg.sender]=_initialSupply;
        totalSupply = _initialSupply;//how many tokens are applicable     
        
    }
    //
    function transfer(address _to,uint _value)public returns(bool success){
        //The function should thrown ,if the _form account balance does not have enough tokens to spend
        require(balanceof[msg.sender] >= _value);
        balanceof[msg.sender] -=_value;
        balanceof[_to] +=_value;
        emit Transfer(msg.sender,_to,_value);
        success=true;

    }
    //approve will allow someone to spend tokens on their behalf
    //Account A approves accountB to approve C amount of tokens on their behalf
    //transfer from  (delegated transfer) third part will transfer with our behalf
    //allowance -->alloted amount we approved to transfer
    //If Account A allowed Account B to spend the DAP tokens then that amount is stored in this allowance
    function approve(address _spender,uint _value)public returns(bool success){
        //Allowance
        allowance[msg.sender][_spender]=_value;
        emit Approve(msg.sender,_spender,_value);
        //Approve
        success=true;
    }
    function transferFrom(address _from,address _to,uint _value)public returns(bool success){
        require(allowance[_from][msg.sender] >= _value && balanceof[_from] >=_value);
        balanceof[_from] -=_value;
        balanceof[_to] +=_value;
        allowance[_from][msg.sender] -=_value;
        emit Transfer(_from,_to,_value);
        success=true;
    }

    

}