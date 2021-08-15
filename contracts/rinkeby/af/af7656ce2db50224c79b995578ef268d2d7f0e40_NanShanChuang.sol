/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

pragma solidity ^0.4.24;

/**
 * Math operations with safety checks
 */
contract SafeMath {
  //internal > private 
    //internal < public
    //修饰的函数只能在合约的内部或者子合约中使用
    //乘法
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    //assert断言函数，需要保证函数参数返回值是true，否则抛异常
    assert(a == 0 || c / a == b);
    return c;
  }
//除法
  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    //   a = 11
    //   b = 10
    //   c = 1
      
      //b*c = 10
      //a %b = 1
      //11
    assert(a == b * c + a % b);
    return c;
  }

    //减法
  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    assert(b >=0);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}


contract NanShanChuang is SafeMath{
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
	address public owner;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    
    
    //key:授权人                key:被授权人  value: 配额
    mapping (address => mapping (address => uint256)) public allowance;
    
    mapping (address => uint256) public freezeOf;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
	
	/* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);
	
	/* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    
    //1000000, "NanShanChuang", "NSC"
     constructor(
        uint256 _initialSupply, //发行数量 
        string _tokenName, //token的名字 HTCoin
        //uint8 _decimalUnits, //最小分割，小数点后面的尾数 1ether = 10** 18wei
        string _tokenSymbol //HTC
        ) public {
            
        decimals = 18;//_decimalUnits;                           // Amount of decimals for display purposes
        balanceOf[msg.sender] = _initialSupply * 10 ** 18;              // Give the creator all initial tokens
        totalSupply = _initialSupply * 10 ** 18;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
     
		owner = msg.sender;
    }

    /* Send coins */
    //某个人花费自己的币
    function transfer(address _to, uint256 _value) public {
        require(_to == 0x0);
        require(_value <= 0);
        require(balanceOf[msg.sender] < _value);

        require(balanceOf[_to] + _value < balanceOf[_to]);
//         if (_to == 0x0) throw;                               // Prevent transfer to 0x0 address. Use burn() instead
// 		if (_value <= 0) throw; 
//         if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
//         if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                     // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    //找一个人A帮你花费token，这部分钱并不打A的账户，只是对A进行花费的授权
    //A： 1万
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
	
	    require(_value <= 0);
	    //if (_value <= 0) throw; 
        //allowance[管理员][A] = 1万
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       

    /* A contract attempts to get the coins */
    function transferFrom(address _from /*管理员*/, address _to, uint256 _value)  public returns (bool success) {
        
        require(_to == 0x0);
        require(_value <= 0);
        require(balanceOf[_from] < _value);
        require(balanceOf[_to] + _value < balanceOf[_to]);
        require(_value > allowance[_from][msg.sender]);
        
        
//         if (_to == 0x0) throw;                                // Prevent transfer to 0x0 address. Use burn() instead
// 		if (_value <= 0) throw; 
//         if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        
//         if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        
//         if (_value > allowance[_from][msg.sender]) throw;     // Check allowance
           // mapping (address => mapping (address => uint256)) public allowance;
           
           
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                           // Subtract from the sender
        
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             // Add the same to the recipient
       
        //allowance[管理员][A] = 1万-五千 = 五千
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value)public returns (bool success) {
       
       require(balanceOf[msg.sender] < _value);
       require(_value <= 0);
       
//         if (balanceOf[msg.sender] < _value) throw;            // Check if the sender has enough
// 		if (_value <= 0) throw; 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
	
	function freeze(uint256 _value) public returns (bool success) {
        
        require(balanceOf[msg.sender] < _value);
        require(_value <= 0);
        
//         if (balanceOf[msg.sender] < _value) throw;            // Check if the sender has enough
// 		if (_value <= 0) throw; 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                                // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint256 _value) public returns (bool success) {
        
        require(freezeOf[msg.sender] < _value);
        require(_value <= 0);
        
//         if (freezeOf[msg.sender] < _value) throw;            // Check if the sender has enough
// 		if (_value <= 0) throw; 
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                      // Subtract from the sender
		balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
	
	// transfer balance to owner
	function withdrawEther(uint256 amount) public {
		
		require(msg.sender != owner);
		
		//if(msg.sender != owner)throw;
		owner.transfer(amount);
	}
	
	// can accept ether
	function()public payable {
    }
}