pragma solidity ^0.4.16;

contract owned {
    address public owner;

    function owned() public {  owner = msg.sender;  }
    modifier onlyOwner {  require (msg.sender == owner);    _;   }
    function transferOwnership(address newOwner) onlyOwner public{  owner = newOwner;  }
}

contract token is owned{
    string public name; 
    string public symbol; 
    uint8 public decimals = 10;  
    uint256 public totalSupply; 

    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);  
    event Burn(address indexed from, uint256 value);  
    
    function token(uint256 initialSupply, string tokenName, string tokenSymbol) public {

        totalSupply = initialSupply * 10 ** uint256(decimals);  
        
        balanceOf[msg.sender] = totalSupply; 

        name = tokenName;
        symbol = tokenSymbol;

    }

    function _transfer(address _from, address _to, uint256 _value) internal {

      require(_to != 0x0); 
      require(balanceOf[_from] >= _value); 
      require(balanceOf[_to] + _value > balanceOf[_to]); 
      
      uint previousBalances = balanceOf[_from] + balanceOf[_to]; 
      balanceOf[_from] -= _value; 
      balanceOf[_to] += _value; 
      emit Transfer(_from, _to, _value); 
      assert(balanceOf[_from] + balanceOf[_to] == previousBalances); 

    }

    function transfer(address _to, uint256 _value) public {   _transfer(msg.sender, _to, _value);   }

    function burn(uint256 _value) public onlyOwner returns (bool success) {
        
        require(balanceOf[msg.sender] >= _value);   

		balanceOf[msg.sender] -= _value; 
        totalSupply -= _value; 
        emit Burn(msg.sender, _value);
        return true;
    }
}

contract MyAdvancedToken is token {

    uint256 public buyPrice; 
    uint public amountTotal =0; 
	uint public amountRaised=0;
	bool public crowdFunding = false;  
    uint public deadline = 0; 
    uint public fundingGoal = 0;  

	mapping (address => bool) public frozenAccount; 
    
    event FrozenFunds(address target, bool frozen); 
	event FundTransfer(address _backer, uint _amount, bool _isContribution); 

    function MyAdvancedToken(uint256 initialSupply, string tokenName, string tokenSymbol) public token (initialSupply, tokenName, tokenSymbol) {
        buyPrice  = 10000; 
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0); 
        require (balanceOf[_from] > _value); 
        require (balanceOf[_to] + _value > balanceOf[_to]); 
        require(!frozenAccount[_from]); 
        require(!frozenAccount[_to]);
        
        balanceOf[_from] -= _value; 
        balanceOf[_to] += _value; 
        emit Transfer(_from, _to, _value); 
    }

    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newBuyPrice) public onlyOwner {
        buyPrice = newBuyPrice;
    }
   function () payable public {
	  require (crowdFunding == true);
	  check_status();
	  require (crowdFunding == true);
	  uint amount = msg.value* buyPrice;
	  _transfer(owner, msg.sender, amount);
	  amountTotal += msg.value;
	  amountRaised += msg.value;
      //emit FundTransfer(msg.sender, amount, true);
    }

	function check_status() internal {
	  if (deadline >0 && now >= deadline)
		  crowdFunding = false;
	  if( fundingGoal >0 && amountRaised > fundingGoal )
		  crowdFunding = false;

	  if( crowdFunding == false ){
	      deadline = 0;
		  fundingGoal = 0;
		  amountRaised = 0;
	  }
	}

	function openCrowdFunding(bool bOpen,uint totalEth, uint durationInMinutes) public  onlyOwner {
	    deadline = 0;
	    fundingGoal = 0;
	    amountRaised = 0;
		
		crowdFunding = bOpen;

		if(totalEth >0){
			fundingGoal = totalEth;
		}
		if(durationInMinutes >0)
			deadline = now + durationInMinutes * 1 minutes;
	}
	
    function getEth() public  onlyOwner { //ok
		require( amountTotal >= 100 );
        uint256 amt = amountTotal-100;
        owner.transfer(amt);
        emit FundTransfer(owner, amt, false);
		amountTotal = 100;
    }
}