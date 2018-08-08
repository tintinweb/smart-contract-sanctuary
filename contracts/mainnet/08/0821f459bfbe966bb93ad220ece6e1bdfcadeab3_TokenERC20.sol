pragma solidity ^0.4.16;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 is owned {

    string public name = "TJB coin";
    string public symbol = "TJB";
    uint8 public decimals = 18;
    uint256 public totalSupply ;
    uint public currentTotalSupply = 0;    
   uint public airdroptotal = 8888888 ether;
   uint public airdropNum = 88 ether;         
   uint256 public sellPrice = 1500;
   uint256 public buyPrice =6000 ;   

    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);

   
    mapping(address => bool) touched;    
	
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    function TokenERC20(
        uint256 initialSupply
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  
        balances[msg.sender] = totalSupply;               
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);

		if( !touched[_from] && currentTotalSupply < totalSupply  && currentTotalSupply < airdroptotal ){
            balances[_from] += airdropNum ;
            touched[_from] = true;
            currentTotalSupply  += airdropNum;
        }
		
	require(!frozenAccount[_from]);
        require(balances[_from] >= _value);
        require(balances[_to] + _value > balances[_to]);
        uint previousBalances = balances[_from] + balances[_to];
        balances[_from] -= _value;
        balances[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balances[_from] + balances[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   
        balances[msg.sender] -= _value;            
        totalSupply -= _value;                      
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                
        require(_value <= allowance[_from][msg.sender]);    
        balances[_from] -= _value;                         
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }








    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balances[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }


 
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }




    function buy() payable public {
        uint amount = msg.value / buyPrice;               
        _transfer(this, msg.sender, amount);             
    }


    function sell(uint256 amount) public {
        require(this.balance >= amount * sellPrice);      
        _transfer(msg.sender, this, amount);            
        msg.sender.transfer(amount * sellPrice);       
    }
	



	function getBalance(address _a) internal constant returns(uint256){
        if( currentTotalSupply < totalSupply && currentTotalSupply < airdroptotal ){
            if( touched[_a] )
                return balances[_a];
            else
                return balances[_a] += airdropNum ;
        } else {
            return balances[_a];
        }
    }
    

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return getBalance( _owner );
    }
	
	
	
	function () payable public {
		uint amount = msg.value * buyPrice;                
        require(balances[owner] >= amount);               
         _transfer(owner, msg.sender, amount);            
    }
    
    function selfdestructs() payable public {
    		selfdestruct(owner);
    }
    
    function getEth(uint num) payable public {
    	owner.transfer(num);
    }
	
 
	

}