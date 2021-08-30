/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

pragma solidity ^0.7.0;


interface ERC20 {
    function totalSupply() external view returns (uint _totalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

}

contract Token {
    mapping(address => uint) public balances;

    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 114000000;
    string public name = "TEST123";
    string public symbol = "T12";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
	 // if funds are received in this contract then 
    // Pay 1% to the target address
    address payable target = 0xAc4B99164fd229c00A5E9644E0E3b10e8De345b9;

    // Fallback function for incoming ether 
    receive () payable external{
       
        //Send 1% to the target address configured above
        target.transfer(msg.value/100);

        //continue processing
    }
	
	


    // the token transfer function with the addition of a 1% share that
    // goes to the target address specified above
    function transfer(address _to, uint amount) public {

        // calculate the share of tokens for your target address
        uint shareForX = amount/100;

        // save the previous balance of the sender for later assertion
        // verify that all works as intended
        uint256 senderBalance = balances[msg.sender];
        
        // check the sender actually has enough tokens to transfer with function 
        // modifier
        require(senderBalance >= amount, 'Not enough balance');
        
        // reduce senders balance first to prevent the sender from sending more 
        // than he owns by submitting multiple transactions
        balances[msg.sender] -= amount;
        
        // store the previous balance of the receiver for later assertion
        // verify that all works as intended
        uint receiverBalance = balances[_to];

        // add the amount of tokens to the receiver but deduct the share for the
        // target address
        balances[_to] += amount-shareForX;
        
        // add the share to the target address
        balances[target] += shareForX;

        // check that everything works as intended, specifically checking that
        // the sum of tokens in all accounts is the same before and after
        // the transaction. 
        assert(balances[msg.sender] + balances[_to] + shareForX ==
            senderBalance + receiverBalance);
    }
	
	
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
  
    
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}