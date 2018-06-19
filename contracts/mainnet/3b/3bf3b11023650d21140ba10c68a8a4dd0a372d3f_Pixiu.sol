pragma solidity ^0.4.13;

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

contract Pixiu is StandardToken {

    uint public decimals = 6;
    bool public isPayable = true;
    bool public isWithdrawable = true;
    bool public isRequireData = false;
	
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
    
	 
    uint256 public tokenExchangeRateInWei = 300*10**6;
	
	/*
    *虛擬帳號   共20碼
    *1-4 固定 0xFFFFFFFF 
    *5-8 繳費期限
    *9-11 流水號 商家代碼 0x000000-0xFFFFFF
    *12-15 商家自訂 4碼=8位 0-F
    *16-18 金額
    *19 :0x30 +4bit候補零
    * 當 BYTE19 = 00  12-18 為商家自訂
    *20 檢查碼 
    */
    mapping (address => uint) public shopStoreId; 
    mapping (uint => address) public shopStoreAddress; 
    uint256 public shopStorePrice = 1*10**6;
    uint256 public shopStoreNextId = 0;
    address public Apply_Store_Id_Fee;
	uint256 public total_tokenwei = 0; 
	uint256 public min_pay_wei = 0;
	uint256 public total_devidend = 0; 
	uint256 public total_withdraw = 0; 
    uint256 public withdraw_amount = 0; 
    uint256 public dividend_amount = 0; 
    
    event Paydata(address indexed payer, uint256 value, bytes data, uint256 thisTokenWei);
    
    function Pixiu() {
        totalSupply = 21000000000000; 
        adminArray.push(msg.sender);
        admin_set_Apply_Store_Id_Fee(msg.sender);
         
    }
    
    function get_orderAddress(address _address,uint _expire_day,uint _userdata,uint _pixiu, uint _wei) constant returns (address){
        
        uint256 storeid = shopStoreId[_address];
        uint160 result = uint152(0xffffffff<<120) + uint120((_expire_day * 86400 + now)<<88) + uint88(storeid<<64); 
        uint _zero = 0;
        uint256 _amount2 = _pixiu * 10 ** 6 + _wei;
        uint256 _amount = _amount2;
        while(_amount2 % 10 == 0){
            
            _amount2 /= 10;
            _zero++;
            
        }
        
        _userdata = _userdata<<24;
        _userdata += _amount;
        
        result += uint64(_userdata<<8);
        result += uint8(0x30+_zero);
        uint8 crc = uint8(sha256(uint152(result) ));
        return address((result << 8) + crc);
    }
    
    function isLeading4FF(address _sender ) private  returns(bool){
        uint32 ff4= uint32(uint256(_sender) >> 128);
        return (ff4 == 0xffffffff);
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
    
    function admin_dividend(int _Eth, int _Wei) onlyAdmin {
        
        int xWei = _Eth * 10 ** 18 + _Wei;
		bool is_add = true;

        if(xWei > 0){
            
            dividend_amount += uint256(xWei);
            
        }else{
            
            xWei *= -1;
            is_add = false;
            dividend_amount -= uint256(xWei * -1);
            
        } 
        
        uint256 len = memberArray.length;	
        uint i = 0;
        address _member;
        
		uint total_balance_dividened=0;
        for( i = 0; i < len; i++){            
            _member = memberArray[i];
			if(members[_member].isDividend){
				total_balance_dividened += balances[_member]; 
			}            
        }
            
        for( i = 0; i < len; i++){            
            _member = memberArray[i];
			if(members[_member].isDividend){
				uint256 thisWei = balances[_member] * uint256(xWei) / total_balance_dividened;
				if(is_add){
				    members[_member].dividend += thisWei; 
				    total_devidend += thisWei;
				}else{
				    members[_member].dividend -= thisWei; 
				    total_devidend -= thisWei;
				}
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
    
    function admin_set_Apply_Store_Id_Fee(address _address) onlyAdmin{
        
        Apply_Store_Id_Fee = _address;
        
    }
    
    function admin_set_ExchangeRateInWei(uint256 exchangeRates) onlyAdmin{
        
        tokenExchangeRateInWei = exchangeRates;
        
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
	    min_pay_wei = _min_pay;
	    
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
    
    function admin_set_shopStorePrice(uint256 _shopStorePrice) onlyAdmin{
        
        shopStorePrice = _shopStorePrice;
        
    }
    
    function admin_set_isRequireData(bool _requireData) onlyAdmin{
    
        isRequireData = _requireData;
        
    }
    
    function admin_set_payable(bool _payable) onlyAdmin{
    
        isPayable = _payable;
        
    }
    
    function admin_set_withdrawable(bool _withdrawable) onlyAdmin{
        
        isWithdrawable = _withdrawable;
        
    }
    
    function admin_set_dividend(address _member, bool _dividend) onlyAdmin memberExists(_member){
        
        members[_member].isDividend = _dividend;
        
    }
    
    function admin_set_withdraw(address _member, bool _withdraw) onlyAdmin memberExists(_member){
        
        members[_member].isWithdraw = _withdraw;
        
    }
    
    function get_total_info() constant returns(uint256 _total_devidend, uint256 _total_remain, uint256 _total_withdraw){

        _total_remain = total_devidend - total_withdraw;
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

    function admin_withdraw(uint xWei){

        uint256 _withdraw = xWei;
		require( msg.sender == Apply_Store_Id_Fee );

		require(this.balance > _withdraw);
		msg.sender.transfer(_withdraw);

        withdraw_amount += _withdraw;  
        
    }
    
    function admin_withdraw_all(address _ApplyStoreIdFee) onlyAdmin {
        
		require( _ApplyStoreIdFee == Apply_Store_Id_Fee ); 

		_ApplyStoreIdFee.transfer(this.balance);

		total_devidend = 0; //member
		total_withdraw = 0; //member
		withdraw_amount = 0; //deposit
		dividend_amount = 0; //admin   
        
    }
    
    function admin_transfer(address _to, uint256 _value) onlyAdmin onlyPayloadSize(2 * 32)     {
        
        require(_to != Apply_Store_Id_Fee);
        require(total_tokenwei <= totalSupply - _value);
        balances[_to] = balances[_to].add(_value);
        
        total_tokenwei += _value;
    
        if (members[_to].isExists != true) {  
            members[_to].isExists = true;
            members[_to].isDividend = true;
            members[_to].isWithdraw = true; 
            memberArray.push(_to);  
        }
        
    }
 
	function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32)     {
	    
		require(_to != msg.sender);
        require(isPayable);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		
		if(_to == Apply_Store_Id_Fee){
		    
		    require(_value == shopStorePrice);
		    shopStoreNextId++;
		    shopStoreId[msg.sender] = shopStoreNextId;
		    shopStoreAddress[shopStoreNextId] = msg.sender;
		
		} else { 
		    
		    if(isLeading4FF(_to)){
		    
    		    uint256 to256 = uint256(_to);
                uint32 expire = uint32(to256>>96);
                uint32 storeid = uint24(to256>>72);
                uint8 byte19_1 = uint8(uint8(to256>>8)>>4);
                uint8 byte19_2 = uint8(uint8(to256>>8)<<4);
                byte19_2 = byte19_2>>4;
                uint24 byte1618 = uint24(to256>>16);
                
                require(uint32(now)<expire || expire==0);
                
                require(uint8(sha256(uint152(to256>>8)))==uint8(to256));
                
                _to = shopStoreAddress[uint(storeid)];
                require(uint(_to)>0);
    
                if(byte19_1 == 3){
                
                    for(int i = 0; i < byte19_2; i++){
                        byte1618 *= 10;
                    }
                    
                    require(byte1618 == _value);
                
                }
    		
    		}
		    
    		balances[_to] = balances[_to].add(_value);
    		if (members[_to].isExists != true) {		
    			members[_to].isExists = true;
    			members[_to].isDividend = true;
    			members[_to].isWithdraw = true; 
    			memberArray.push(_to);		
    		}  

        }

		Transfer(msg.sender, _to, _value);
	}
	
	function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32)     {
		require(_to != Apply_Store_Id_Fee);
		require(_from != Apply_Store_Id_Fee);
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
  
    function pay() public payable  returns (bool) {
        
        require(!isLeading4FF(msg.sender));
        require(msg.value > min_pay_wei);
        require(isPayable);
        
        if(msg.sender == Apply_Store_Id_Fee){

        }else{
            
            if(isRequireData){
                require(uint32(msg.data[0]) == uint32(0xFFFFFFFF));   
            }
        
    		uint256 exchangeWei = get_exchange_wei();
    		uint256 thisTokenWei = exchangeWei * msg.value / 10**18 ;
    		
    		require(total_tokenwei <= totalSupply - thisTokenWei);
        
            if (members[msg.sender].isExists != true) {
                
                members[msg.sender].isExists = true;
                members[msg.sender].isDividend = true;
                members[msg.sender].isWithdraw = true; 
                memberArray.push(msg.sender);
                
            }  
    		balances[msg.sender] += thisTokenWei;
    		total_tokenwei += thisTokenWei;
    		
    		Paydata(msg.sender, msg.value, msg.data, thisTokenWei);
    		Transfer(this, msg.sender, thisTokenWei);
		
        }
        
        return true;
    
    }
            
    function get_this_balance() constant returns(uint256){
      
        return this.balance;
      
    }
    
}