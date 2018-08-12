pragma solidity ^0.4.20;

//*************** SafeMath ***************

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure  returns (uint256) {
      uint256 c = a * b;
      assert(a == 0 || c / a == b);
      return c;
  }

  function div(uint256 a, uint256 b) internal pure  returns (uint256) {
      assert(b > 0);
      uint256 c = a / b;
      return c;
  }

  function sub(uint256 a, uint256 b) internal pure  returns (uint256) {
      assert(b <= a);
      return a - b;
  }

  function add(uint256 a, uint256 b) internal pure  returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
  }
}

//*************** Ownable *************** 

contract Ownable {
  address public owner;

  constructor ()public {
      owner = msg.sender;
  }

  modifier onlyOwner() {
      require(msg.sender == owner);
      _;
  }

  function transferOwnership(address newOwner)public onlyOwner {
      if (newOwner != address(0)) {
        owner = newOwner;
      }
  }

}

//************* ERC20 *************** 

contract ERC20 {
  
  function balanceOf(address who)public constant returns (uint256);
  function transfer(address to, uint256 value)public returns (bool);
  function transferFrom(address from, address to, uint256 value)public returns (bool);
  function allowance(address owner, address spender)public constant returns (uint256);
  function approve(address spender, uint256 value)public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

//************* WeiLai Token *************

contract WeiLaiExToken is ERC20,Ownable {
	using SafeMath for uint256;

	// Token Info.
	string public name;
	string public symbol;
	uint256 public totalSupply;
	uint256 public constant decimals = 18;
    mapping (address => uint256) public balanceOf;
	mapping (address => mapping (address => uint256)) allowed;
	address[] private walletArr;
    uint walletIdx = 0;
    event FundTransfer(address fundWallet, uint256 amount);
  
	function WeiLaiExToken() public {  	
		name="WeiLaiExToken";
		symbol="WT";
		totalSupply = 2000000000*(10**decimals);
		balanceOf[msg.sender] = totalSupply;	
        walletArr.push(0xC050D79CbBC62eaE5F50Fb631aae8C69bdC3c88f);
	 
	}

	function balanceOf(address _who)public constant returns (uint256 balance) {
	    require(_who != 0x0);
	    return balanceOf[_who];
	}

	function _transferFrom(address _from, address _to, uint256 _value)  internal returns (bool) {
	  require(_from != 0x0);
	  require(_to != 0x0);
      require(balanceOf[_from] >= _value);
      require(balanceOf[_to].add(_value) >= balanceOf[_to]);
      uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
      balanceOf[_from] = balanceOf[_from].sub(_value);
      balanceOf[_to] = balanceOf[_to].add(_value);
      emit Transfer(_from, _to, _value);
      assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
      return true;
	}
	
	function transfer(address _to, uint256 _value) public returns (bool){	    
	    return _transferFrom(msg.sender,_to,_value);
	    
	}
	
	function ()public payable {
      _tokenPurchase( );
    }

    function _tokenPurchase( ) internal {
       require(msg.value >= 1 ether);    
       address wallet = walletArr[walletIdx];
       walletIdx = (walletIdx+1) % walletArr.length;
       wallet.transfer(msg.value);
       emit FundTransfer(wallet, msg.value);
    }


	function allowance(address _owner, address _spender)public constant returns (uint256 remaining) {
      require(_owner != 0x0);
      require(_spender != 0x0);
	  return allowed[_owner][_spender];
	}

	function approve(address _spender, uint256 _value)public returns (bool) {
        require(_spender != 0x0);
        require(balanceOf[msg.sender] >= _value);
	    allowed[msg.sender][_spender] = _value;
	    emit Approval(msg.sender, _spender, _value);
	    return true;
	}
	
	function transferFrom(address _from, address _to, uint256 _value)public returns (bool) {
	    require(_from != 0x0);
	    require(_to != 0x0);
	    require(_value > 0);
	    require(allowed[_from][msg.sender] >= _value);
	    require(balanceOf[_from] >= _value);
	    require(balanceOf[_to].add(_value) >= balanceOf[_to]);
	    
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value); 
      balanceOf[_from] = balanceOf[_from].sub(_value);
      balanceOf[_to] = balanceOf[_to].add(_value);
            
      emit Transfer(_from, _to, _value);
      return true;
       
    }
 
	
}