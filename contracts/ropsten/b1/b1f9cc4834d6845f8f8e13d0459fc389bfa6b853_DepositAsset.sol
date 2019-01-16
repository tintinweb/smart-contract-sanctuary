pragma solidity 0.5.0; /*

___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   &#39; /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_

                                                           
                                                           
DDDDDDDDDDDDD                            AAA               
D::::::::::::DDD                        A:::A              
D:::::::::::::::DD                     A:::::A             
DDD:::::DDDDD:::::D                   A:::::::A            
  D:::::D    D:::::D                 A:::::::::A           
  D:::::D     D:::::D               A:::::A:::::A          
  D:::::D     D:::::D              A:::::A A:::::A         
  D:::::D     D:::::D             A:::::A   A:::::A        
  D:::::D     D:::::D            A:::::A     A:::::A       
  D:::::D     D:::::D           A:::::AAAAAAAAA:::::A      
  D:::::D     D:::::D          A:::::::::::::::::::::A     
  D:::::D    D:::::D          A:::::AAAAAAAAAAAAA:::::A    
DDD:::::DDDDD:::::D          A:::::A             A:::::A   
D:::::::::::::::DD          A:::::A               A:::::A  
D::::::::::::DDD           A:::::A                 A:::::A 
DDDDDDDDDDDDD             AAAAAAA                   AAAAAAA
                                                           
                                                           
                                                           
// ----------------------------------------------------------------------------
// &#39;Deposit Asset&#39; Token contract with following functionalities:
//      => Higher control of owner
//      => SafeMath implementation 
//
// Name             : Deposit Asset
// Symbol           : DA
// Decimals         : 15
//
// Copyright (c) 2018 FIRST DECENTRALIZED DEPOSIT PLATFORM ( https://fddp.io )
// Contract designed by: EtherAuthority ( https://EtherAuthority.io ) 
// ----------------------------------------------------------------------------
*/ 


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;  
  mapping(address => uint256) public holdersWithdrows;
  
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    uint256 _buffer = holdersWithdrows[msg.sender].mul(_value).div(balances[msg.sender]);
    holdersWithdrows[_to] += _buffer;
    holdersWithdrows[msg.sender] -= _buffer;
    
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);

    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}
/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);
    require(_value != 0);
    uint256 _buffer = holdersWithdrows[msg.sender].mul(_value).div(balances[msg.sender]);
    holdersWithdrows[_to] += _buffer;
    holdersWithdrows[msg.sender] -= _buffer;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
}
/**
 * TheStocksTokens
 * 
 */
contract DepositAsset is StandardToken {
    
    using SafeMath for uint256;
    
    string public constant name = "Deposit Asset";
  
    string public constant symbol = "DA";
  
    uint32 public constant decimals = 6;

    uint256 private _totalSupply = 200000000000000; // stocks
    
    uint public _totalWithdrow  = 0;
    
    uint public total_withdrows  = 0;
    
    constructor () public {
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

	function totalSupply() public view returns(uint256 total) {
        return _totalSupply;
    }
    
    // get any ethers to contract
    function () external payable {
        if (msg.value == 1 wei) {
            require(balances[msg.sender] > 0);
        
            uint256 _totalDevidends = devidendsOf(msg.sender);
            holdersWithdrows[msg.sender] += _totalDevidends;
            _totalWithdrow += _totalDevidends;
            
            msg.sender.transfer(_totalDevidends);
        }
    }
    
    /* TEST / function holdersWithdrowsOf(address _owner) public constant returns(uint256 hw) {
        return holdersWithdrows[_owner];
    }//*/
    function getDevidends() public returns (bool success){
        require(balances[msg.sender] > 0);
        
        uint256 _totalDevidends = devidendsOf(msg.sender);
        holdersWithdrows[msg.sender] += _totalDevidends;
        _totalWithdrow += _totalDevidends;
        
        msg.sender.transfer(_totalDevidends);
        
        return true;
    }
    function devidendsOf(address _owner) public view returns (uint256 devidends) {
        address self = address(this);
        // определить сумму всех начисленых средств, определить долю и отминусовать ранее снятые дивиденды
        return self.balance
            .add(_totalWithdrow)
            .mul(balances[_owner])
            .div(_totalSupply)
            .sub(holdersWithdrows[_owner]);
    }
   
    function fund() public payable returns(bool success) {
        success = true;
    }
}