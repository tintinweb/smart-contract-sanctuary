pragma solidity ^0.4.16;

//Base class of token-owner
contract Ownable {
	address public owner;														//owner&#39;s address

	function Ownable() public 
	{
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	/*
	*	Funtion: Transfer owner&#39;s authority 
	*	Type:Public and onlyOwner
	*	Parameters:
			@newOwner:	address of newOwner
	*/
	function transferOwnership(address newOwner) onlyOwner public{
		if (newOwner != address(0)) {
		owner = newOwner;
		}
	}
	
	function kill() onlyOwner public{
		selfdestruct(owner);
	}
}

//Announcement of an interface for recipient approving
interface tokenRecipient { 
	function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData)public; 
}


contract XiaoMuBiaoERC20 is Ownable{
	
	//===================public variables definition start==================
    string public name;															//Name of your Token
    string public symbol;														//Symbol of your Token
    uint8 public decimals;														//Decimals of your Token
    uint256 public totalSupply;													//Maximum amount of Token supplies

    //define dictionaries of balance
    mapping (address => uint256) public balanceOf;								//Announce the dictionary of account&#39;s balance
    mapping (address => mapping (address => uint256)) public allowance;			//Announce the dictionary of account&#39;s available balance
	//===================public variables definition end==================

	
	//===================events definition start==================    
    event Transfer(address indexed from, address indexed to, uint256 value);	//Event on blockchain which notify client
	//===================events definition end==================
	
	
	//===================Contract Initialization Sequence Definition start===================
    function XiaoMuBiaoERC20 () public {
		decimals=7;															//Assignment of Token&#39;s decimals
		totalSupply = 500000000000 * 10 ** uint256(decimals);  				//Assignment of Token&#39;s total supply with decimals
        balanceOf[owner] = totalSupply;                					//Assignment of Token&#39;s creator initial tokens
        name = "XiaoMuBiao";                                   					//Set the name of Token
        symbol = "XMB";                               					//Set the symbol of  Token
        
    }
	//===================Contract Initialization Sequence definition end===================
	
	//===================Contract behavior & funtions definition start===================
	
	/*
	*	Funtion: Transfer funtions
	*	Type:Internal
	*	Parameters:
			@_from:	address of sender&#39;s account
			@_to:	address of recipient&#39;s account
			@_value:transaction amount
	*/
    function _transfer(address _from, address _to, uint _value) internal {
		//Fault-tolerant processing
		require(_to != 0x0);						//
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);

        //Execute transaction
		uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
		
		//Verify transaction
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
	
	
	/*
	*	Funtion: Transfer tokens
	*	Type:Public
	*	Parameters:
			@_to:	address of recipient&#39;s account
			@_value:transaction amount
	*/
    function transfer(address _to, uint256 _value) public {
		
        _transfer(msg.sender, _to, _value);
    }	
	
	/*
	*	Funtion: Transfer tokens from other address
	*	Type:Public
	*	Parameters:
			@_from:	address of sender&#39;s account
			@_to:	address of recipient&#39;s account
			@_value:transaction amount
	*/

    function transferFrom(address _from, address _to, uint256 _value) public 
	returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     					//Allowance verification
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
	/*
	*	Funtion: Approve usable amount for an account
	*	Type:Public
	*	Parameters:
			@_spender:	address of spender&#39;s account
			@_value:	approve amount
	*/
    function approve(address _spender, uint256 _value) public 
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
        }

	/*
	*	Funtion: Approve usable amount for other address and then notify the contract
	*	Type:Public
	*	Parameters:
			@_spender:	address of other account
			@_value:	approve amount
			@_extraData:additional information to send to the approved contract
	*/
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public 
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    /*
	*	Funtion: Transfer owner&#39;s authority and account balance
	*	Type:Public and onlyOwner
	*	Parameters:
			@newOwner:	address of newOwner
	*/
    function transferOwnershipWithBalance(address newOwner) onlyOwner public{
		if (newOwner != address(0)) {
		    _transfer(owner,newOwner,balanceOf[owner]);
		    owner = newOwner;
		}
	}
   //===================Contract behavior & funtions definition end===================
}