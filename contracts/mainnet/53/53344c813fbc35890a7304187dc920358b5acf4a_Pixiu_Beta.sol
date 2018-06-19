pragma solidity ^0.4.9;

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}

/**
	 * @title ERC20Basic
	 * @dev Simpler version of ERC20 interface
	 * @dev see https://github.com/ethereum/EIPs/issues/20
	 */
contract ERC20Basic {
	  uint256 public totalSupply;
	  function balanceOf(address who) constant returns (uint256);
	  function transfer(address to, uint256 value);
	  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint256 size) {
     require(!(msg.data.length < size + 4));
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implemantation of the basic standart token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)) );

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract Pixiu_Beta is StandardToken {

    uint public decimals = 6;
    bool public isPayable = true;
    bool public isWithdrawable = true;
	
    struct exchangeRate {
        
        uint time1;                                      
        uint time2;                                     
        uint value;
        
    }
    
    struct Member {
         
        bool isExists;                                      
        bool isDividend;                                    
        bool isWithdraw;                                     
        uint256 dividend;                                   
        uint256 withdraw;
        
    }
    
    exchangeRate[] public exchangeRateArray;  

	mapping (address => Member) public members; 
    address[] public adminArray;   
    address[] public memberArray;
	
    address public deposit_address;
    uint256 public INITIAL_SUPPLY = 21000000000000;
    uint256 public tokenExchangeRateInWei = 300000000;

	//不歸零
	uint256 public total_tokenwei = 0; 
	uint256 public min_pay_wei = 0;

	// drawall 歸零
	uint256 public total_devidend = 0; //member
	uint256 public total_withdraw = 0; //member
    uint256 public deposit_amount = 0;  //deposit
    uint256 public withdraw_amount = 0; //deposit
    uint256 public dividend_amount = 0; //admin   
    
    function Pixiu_Beta() {
     
        totalSupply = INITIAL_SUPPLY; 
        adminArray.push(msg.sender);
        admin_set_deposit(msg.sender);
         
    }

    modifier onlyDeposit() {
        
        require(msg.sender == deposit_address);
        _;
        
    }
    
    modifier onlyAdmin() {
        
        bool ok = admin_check(msg.sender);
        require(ok);
        _;
        
    }
    
    modifier adminExists(address admin) {

        bool ok = false;
        if(admin != msg.sender){
            
            ok = admin_check(admin);
        
        }
        require(ok);
        _; 
        
    }
    
    modifier adminDoesNotExist(address admin) {

        bool ok = admin_check(admin);
        require(!ok);
        _;
        
    }
    
    function admin_check(address admin) private constant returns(bool){
        
        bool ok = false;
        
        for (uint i = 0; i < adminArray.length; i++) {
            if (admin == adminArray[i]) {
                ok = true;
                break;
            }
        }
        
        return ok;
        
    }
    
    modifier memberExists(address member) {

        bool ok = false;
        if (members[member].isExists == true) {
            
            ok = true;
            
        }
        require(ok);
        _;
        
    }
    
    modifier isMember() {

        bool ok = false;
        if (members[msg.sender].isExists == true) {            
            ok = true;            
        }
        require(ok);
        _;
        
    }
    
    function admin_deposit(uint xEth) onlyAdmin{
        
        uint256 xwei = xEth * 10**18;
        deposit_amount += xwei;
        
    }
    
    /**	*	管理員發放股息	*	每個會員股息依 	*	*/
    function admin_dividend(uint xEth) onlyAdmin{
        
		uint256 xwei = xEth * 10**18;
		require(xwei <= (deposit_amount-dividend_amount) ); 

		dividend_amount += xwei;
        uint256 len = memberArray.length;	
        uint i = 0;
        address _member;
        
		uint total_balance_dividened=0;
        for( i = 0; i < len; i++){            
            _member = memberArray[i];
			if(members[_member].isDividend){
				total_balance_dividened = balances[_member]; 
			}            
        }
		uint256 perTokenWei = xwei / (total_balance_dividened / 10 ** 6);
            
        for( i = 0; i < len; i++){            
            _member = memberArray[i];
			if(members[_member].isDividend){
				uint256 thisWei = (balances[_member] / 10 ** 6) * perTokenWei;
				members[_member].dividend += thisWei; 
				total_devidend += thisWei;
			}            
        }
    
    }
    
    function admin_set_exchange_rate(uint[] exchangeRates) onlyAdmin{
         
        uint len = exchangeRates.length;
        exchangeRateArray.length = 0;
        
        for(uint i = 0; i < len; i += 3){
            
            uint time1 = exchangeRates[i];
            uint time2 = exchangeRates[i + 1];
            uint value = exchangeRates[i + 2]*1000;
            exchangeRateArray.push(exchangeRate(time1, time2, value));      
            
        }
        
    }

	function get_exchange_wei() constant returns(uint256){

		uint len = exchangeRateArray.length;  
		uint nowTime = block.timestamp;
        for(uint i = 0; i < len; i += 3){
            
			exchangeRate memory rate = exchangeRateArray[i];
            uint time1 = rate.time1;
            uint time2 = rate.time2;
            uint value = rate.value;
			if (nowTime>= time1 && nowTime<=time2) {
				tokenExchangeRateInWei = value;
				return value;
			}
            
        }
		return tokenExchangeRateInWei;
	}
	
	function admin_set_min_pay(uint256 _min_pay) onlyAdmin{
	    
	    require(_min_pay >= 0);
	    min_pay_wei = _min_pay * 10 ** 18;
	    
	}
    
    function get_admin_list() constant returns(address[] _adminArray){
        
        _adminArray = adminArray;
        
    }
    
    function admin_add(address admin) onlyAdmin adminDoesNotExist(admin){
        
        adminArray.push(admin);
        
    }
    
    function admin_del(address admin) onlyAdmin adminExists(admin){
        
        for (uint i = 0; i < adminArray.length - 1; i++)
            if (adminArray[i] == admin) {
                adminArray[i] = adminArray[adminArray.length - 1];
                break;
            }
            
        adminArray.length -= 1;
        
    }
    
    function admin_set_deposit(address addr) onlyAdmin{
        
        deposit_address = addr;
        
    }
    
    function admin_active_payable() onlyAdmin{
    
        isPayable = true;
        
    }
    
    function admin_inactive_payable() onlyAdmin{
        
        isPayable = false;
        
    }
    
    function admin_active_withdrawable() onlyAdmin{
        
        isWithdrawable = true;
        
    }
    
    function admin_inactive_withdrawable() onlyAdmin{
        
        isWithdrawable = false;
        
    }
    
    function admin_active_dividend(address _member) onlyAdmin memberExists(_member){
        
        members[_member].isDividend = true;
        
    }
    
    function admin_inactive_dividend(address _member) onlyAdmin memberExists(_member){
        
        members[_member].isDividend = false;
        
    }
    
    function admin_active_withdraw(address _member) onlyAdmin memberExists(_member){
        
        members[_member].isWithdraw = true;
        
    }
    
    function admin_inactive_withdraw(address _member) onlyAdmin memberExists(_member){
        
        members[_member].isWithdraw = false;
        
    }
    
    function get_total_info() constant returns(uint256 _deposit_amount, uint256 _total_devidend, uint256 _total_remain, uint256 _total_withdraw){

        _total_remain = total_devidend - total_withdraw;
        _deposit_amount = deposit_amount;
        _total_devidend = total_devidend;
        _total_withdraw = total_withdraw;
        
    }
    
    function get_info(address _member) constant returns (uint256 _balance, uint256 _devidend, uint256 _remain, uint256 _withdraw){
        
        _devidend = members[_member].dividend;
        _withdraw = members[_member].withdraw;
        _remain = _devidend - _withdraw;
        _balance = balances[_member];
        
    }
    
    function withdraw() isMember {
        
        uint256 _remain = members[msg.sender].dividend - members[msg.sender].withdraw;
        require(_remain > 0);
        require(isWithdrawable);
        require(members[msg.sender].isWithdraw);
        msg.sender.transfer(_remain);
        members[msg.sender].withdraw += _remain; 
        total_withdraw += _remain;          

    }

    function withdraw_admin(uint xEth) onlyDeposit{

        uint256 _withdraw = xEth * 10**18;
		require( msg.sender == deposit_address );

		require(this.balance > _withdraw);
		msg.sender.transfer(_withdraw);

        withdraw_amount += _withdraw;  
        
    }
    
    function withdraw_all_admin(address _deposit) onlyAdmin {
        
		require( _deposit == deposit_address ); 

		_deposit.transfer(this.balance);

		total_devidend = 0; //member
		total_withdraw = 0; //member
		deposit_amount = 0;  //deposit
		withdraw_amount = 0; //deposit
		dividend_amount = 0; //admin   
        
    }
 
	function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32)     {
		require(_to != deposit_address);
        require(isPayable);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);

		if (members[_to].isExists != true) {		
			members[_to].isExists = true;
			members[_to].isDividend = true;
			members[_to].isWithdraw = true; 
			memberArray.push(_to);		
		}  

		Transfer(msg.sender, _to, _value);
	}
 
	function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32)     {
		require(_to != deposit_address);
		require(_from != deposit_address);
        require(isPayable);
		var _allowance = allowed[_from][msg.sender]; 
		require(_allowance >= _value);

		balances[_to] = balances[_to].add(_value);
		balances[_from] = balances[_from].sub(_value);
		allowed[_from][msg.sender] = _allowance.sub(_value);
		
		if (members[_to].isExists != true) {		
			members[_to].isExists = true;
			members[_to].isDividend = true;
			members[_to].isWithdraw = true; 
			memberArray.push(_to);		
		}  

		Transfer(_from, _to, _value);
	}

    function () payable {
        
        pay();
        
    }
  
    function pay() public payable returns (bool) {
      
        require(msg.value > min_pay_wei);
        require(isPayable);
        
        if(msg.sender == deposit_address){
             deposit_amount += msg.value;
        }else{
        
    		uint256 exchangeWei = get_exchange_wei();
    		uint256 thisTokenWei = exchangeWei * msg.value / 10**18 ;
        
            if (members[msg.sender].isExists != true) {
                
                members[msg.sender].isExists = true;
                members[msg.sender].isDividend = true;
                members[msg.sender].isWithdraw = true; 
                memberArray.push(msg.sender);
                
            }  
    		balances[msg.sender] += thisTokenWei;
    		total_tokenwei += thisTokenWei;
		
        }
        
        return true;
    
    }
            
    function get_this_balance() constant returns(uint256){
      
        return this.balance;
      
    }
    
}