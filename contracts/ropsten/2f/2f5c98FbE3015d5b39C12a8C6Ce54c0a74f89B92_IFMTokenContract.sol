/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

pragma solidity 0.4.24;

contract IFMTokenContract {    
    string public constant name = " LUC Token";				
    string public constant symbol = "LUC";						
	uint8 public constant decimals = 0;							
    uint256 public totalSupply = 100000000;					
    address public owner;									
    mapping( address => uint256) balances;						
    mapping( address => mapping( address => uint256)) allowed;	
    
    event Transfer( address indexed _form, address indexed _to, uint256 _value);			
    event Approval( address indexed _owner, address indexed _spender, uint256 _value);		
    
    modifier onlyOwner() {
        if( msg.sender != owner) {	
            revert();
        }
        _;
    }
    
    constructor() public{
        owner = msg.sender;		
    }
    
    function () public payable{
        if(totalSupply > 0 					
			&& balances[msg.sender] == 0	 	
			&& msg.value == 1 ether) {		    	
            totalSupply -= 10000;				
            balances[msg.sender] = 10000;		
        } else {
            revert();						
        }
    }
    
    function balanceOf( address _owner) public view returns ( uint256) {	
        return balances[_owner];	
    }

    function transfer( address _to, uint _amount) public returns( bool) {
        if( _amount > 0  								
			&& balances[msg.sender] >= _amount  			
			&& balances[_to] + _amount > balances[_to]) {	
            balances[msg.sender] -= _amount;			
            balances[_to] += _amount;					
            emit Transfer( msg.sender, _to, _amount);
            return true;								
        } else {
            return false;								
        }
    }
    
    function transferFrom( address _from, address _to, uint256 _amount) public returns( bool) {
        if( _amount > 0  								
			&& balances[_from] >= _amount 				
			&& allowed[_from][msg.sender] >= _amount  	
			&& balances[_to] + _amount > balances[_to]) { 	
            balances[_from] -= _amount;					
            allowed[_from][msg.sender] -= _amount;		
            balances[_to] += _amount;					
            emit Transfer( _from, _to, _amount);		
            return true;								
        } else {
            return false;								
        }
    }
    
    function approve( address _spender, uint256 _amount) public returns(bool) {
        allowed[msg.sender][_spender] = _amount;			
        emit Approval( msg.sender, _spender, _amount);		
        return true;
    }
    
    function allowance( address _owner, address _spender) public view returns( uint256) {
        return allowed[_owner][_spender];
    }
    
    function contractETH() public view returns(uint256){
        return address(this).balance;
    }
    
    function icoEnding() public onlyOwner{
        owner.transfer(address(this).balance);
    }
}