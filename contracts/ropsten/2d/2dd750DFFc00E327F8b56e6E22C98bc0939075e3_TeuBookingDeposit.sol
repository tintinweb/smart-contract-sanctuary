pragma solidity 0.4.18;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control 
 * functions, this simplifies the implementation of "user permissions". 
 */
contract Ownable {
  address public owner;


  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev revert()s if called by any account other than the owner. 
   */
  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to. 
   */
  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}



/**
 * Math operations with safety checks
 */
library SafeMath {
  
  
  function mul256(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div256(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity automatically revert()s when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub256(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add256(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }  
  
  function mod256(uint256 a, uint256 b) internal pure returns (uint256) {
	uint256 c = a % b;
	return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant public returns (uint256);
  function transfer(address to, uint256 value) public;
  event Transfer(address indexed from, address indexed to, uint256 value);
}




/**
 * @title ERC20 interface
 * @dev ERC20 interface with allowances. 
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant public returns (uint256);
  function transferFrom(address from, address to, uint256 value) public;
  function approve(address spender, uint256 value) public;
  event Approval(address indexed owner, address indexed spender, uint256 value);
}




/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       revert();
     }
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public {
    balances[msg.sender] = balances[msg.sender].sub256(_value);
    balances[_to] = balances[_to].add256(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return balances[_owner];
  }

}




/**
 * @title Standard ERC20 token
 * @dev Implemantation of the basic standart token.
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already revert() if this condition is not met
    // if (_value > _allowance) revert();

    balances[_to] = balances[_to].add256(_value);
    balances[_from] = balances[_from].sub256(_value);
    allowed[_from][msg.sender] = _allowance.sub256(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public {

    //  To change the approve amount you first have to reduce the addresses
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }


}



/**
 * @title TeuToken
 * @dev The main TEU token contract
 * 
 */
 
contract TeuToken is StandardToken, Ownable{
  string public name = "20-footEqvUnit";
  string public symbol = "TEU";
  uint public decimals = 18;

  event TokenBurned(uint256 value);
  
  function TeuToken() public {
    totalSupply = (10 ** 8) * (10 ** decimals);
    balances[msg.sender] = totalSupply;
  }

  /**
   * @dev Allows the owner to burn the token
   * @param _value number of tokens to be burned.
   */
  function burn(uint _value) onlyOwner public {
    require(balances[msg.sender] >= _value);
    balances[msg.sender] = balances[msg.sender].sub256(_value);
    totalSupply = totalSupply.sub256(_value);
    TokenBurned(_value);
  }

}

/*
 * Pausable
 * Abstract contract that allows children to implement an
 * emergency stop mechanism.
 */
contract Pausable is Ownable {
  bool public stopped;
  modifier stopInEmergency {
    if (stopped) {
      revert();
    }
    _;
  }
  
  modifier onlyInEmergency {
    if (!stopped) {
      revert();
    }
    _;
  }
  // called by the owner on emergency, triggers stopped state
  function emergencyStop() external onlyOwner {
    stopped = true;
  }
  // called by the owner on end of emergency, returns to normal state
  function release() external onlyOwner onlyInEmergency {
    stopped = false;
  }
}

/**
 * @title teuBookingDeposit 
 * @dev TEU Booking Deposit: A smart contract governing the entitlement of TEU token of two parties for a container shipping booking 
  */
contract TeuBookingDeposit is Ownable, Pausable {
	event eAdjustClientAccountBalance(bytes32 indexed _PartnerID, bytes32 _ClientId, bytes32 _adjustedBy, string _CrDr, uint256 _tokenAmount, string CrDrR, uint256 _tokenRAmount);
	event eAllocateRestrictedTokenTo(bytes32 indexed _PartnerID, bytes32 indexed _clientId, bytes32 _allocatedBy, uint256 _tokenAmount);
	event eAllocateRestrictedTokenToPartner(bytes32 indexed _PartnerID, bytes32 _allocatedBy, uint256 _tokenAmount);
	event eCancelTransactionEvent(bytes32 indexed _PartnerID, string _TxNum, bytes32 indexed _fromClientId, uint256 _tokenAmount, uint256 _rAmount, uint256 _grandTotal);
	event eConfirmReturnToken(bytes32 indexed _PartnerID, string _TxNum, bytes32 indexed _fromClientId, uint256 _tokenAmount, uint256 _rAmount, uint256 _grandTotal);
    event eConfirmTokenTransferToBooking(bytes32 indexed _PartnerID, string _TxNum, bytes32 _fromClientId1, bytes32 _toClientId2, uint256 _amount1, uint256 _rAmount1, uint256 _amount2, uint256 _rAmount2);
    event eKillTransactionEvent(bytes32 _PartnerID, bytes32 _killedBy, string TxHash, string _TxNum);
	event ePartnerAllocateRestrictedTokenTo(bytes32 indexed _PartnerID, bytes32 indexed _clientId, uint256 _tokenAmount);
	event eReceiveTokenByClientAccount(bytes32 indexed _clientId, uint256 _tokenAmount, address _transferFrom);
	event eSetWalletToClientAccount(bytes32 _clientId, address _wallet, bytes32 _setBy);
	event eTransactionFeeForBooking(bytes32 indexed _PartnerID, string _TxNum, bytes32 _fromClientId1, bytes32 _toClientId2, uint256 _amount1, uint256 _rAmount1, uint256 _amount2, uint256 _rAmount2);
	event eWithdrawTokenToClientAccount(bytes32 indexed _clientId, bytes32 _withdrawnBy, uint256 _tokenAmount, address _transferTo);
	event eWithdrawUnallocatedRestrictedToken(uint256 _tokenAmount, bytes32 _withdrawnBy);
	
	
	
    using SafeMath for uint256;
	
	
    TeuToken    private token;
	/*  
    * Failsafe drain
    */
    function drain() onlyOwner public {
        if (!owner.send(this.balance)) revert();
    }
	
	function () payable public {
		if (msg.value!=0) revert();
	}
	
	function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
		bytes memory tempEmptyStringTest = bytes(source);
		if (tempEmptyStringTest.length == 0) {
			return 0x0;
		}

		assembly {
			result := mload(add(source, 32))
		}
	}
	
	function killTransaction(bytes32 _PartnerID, bytes32 _killedBy, string _txHash, string _txNum) onlyOwner stopInEmergency public {
		eKillTransactionEvent(_PartnerID, _killedBy, _txHash, _txNum);
	}
	
		
	function cancelTransaction(bytes32 _PartnerID, string _TxNum, bytes32 _fromClientId1, bytes32 _toClientId2, uint256 _tokenAmount1, uint256 _rAmount1, uint256 _tokenAmount2, uint256 _rAmount2, uint256 _grandTotal) onlyOwner stopInEmergency public {
        eCancelTransactionEvent(_PartnerID, _TxNum, _fromClientId1, _tokenAmount1, _rAmount1, _grandTotal);
		eCancelTransactionEvent(_PartnerID, _TxNum, _toClientId2, _tokenAmount2, _rAmount2, _grandTotal);
	}
	
	
	function AdjustClientAccountBalance(bytes32 _PartnerID, bytes32 _ClientId, bytes32 _allocatedBy, string _CrDr, uint256 _tokenAmount, string CrDrR, uint256 _RtokenAmount) onlyOwner stopInEmergency public {
		eAdjustClientAccountBalance(_PartnerID, _ClientId, _allocatedBy, _CrDr, _tokenAmount, CrDrR, _RtokenAmount);
	}
	
	function setWalletToClientAccount(bytes32 _clientId, address _wallet, bytes32 _setBy) onlyOwner public {
        eSetWalletToClientAccount(_clientId, _wallet, _setBy);
    }
	
    function receiveTokenByClientAccount(string _clientId, uint256 _tokenAmount, address _transferFrom) stopInEmergency public {
        require(_tokenAmount > 0);
        bytes32 _clientId32 = stringToBytes32(_clientId);
		token.transferFrom(_transferFrom, this, _tokenAmount);   
		eReceiveTokenByClientAccount(_clientId32, _tokenAmount, _transferFrom);
    }
	
	function withdrawTokenToClientAccount(bytes32 _clientId, bytes32 _withdrawnBy, address _transferTo, uint256 _tokenAmount) onlyOwner stopInEmergency public {
        require(_tokenAmount > 0);

		token.transfer(_transferTo, _tokenAmount);      

		eWithdrawTokenToClientAccount(_clientId, _withdrawnBy, _tokenAmount, _transferTo);
    }
	

	
    // functions for restricted token management
    function allocateRestrictedTokenTo(bytes32 _PartnerID, bytes32 _clientId, bytes32 _allocatedBy, uint256 _tokenAmount) onlyOwner stopInEmergency public {
		eAllocateRestrictedTokenTo(_PartnerID, _clientId, _allocatedBy, _tokenAmount);
    }
    
    function withdrawUnallocatedRestrictedToken(uint256 _tokenAmount, bytes32 _withdrawnBy) onlyOwner stopInEmergency public {
        //require(_tokenAmount <= token.balanceOf(this).sub256(totalBookingClientToken).sub256(totalClientToken).sub256(totalRestrictedToken));
        token.transfer(msg.sender, _tokenAmount);
		eWithdrawUnallocatedRestrictedToken(_tokenAmount, _withdrawnBy);
    } 

// functions for restricted token management Partner side
    function allocateRestrictedTokenToPartner(bytes32 _PartnerID, bytes32 _allocatedBy, uint256 _tokenAmount) onlyOwner stopInEmergency public {
		eAllocateRestrictedTokenToPartner(_PartnerID, _allocatedBy, _tokenAmount);
    }
	
    function partnerAllocateRestrictedTokenTo(bytes32 _PartnerID, bytes32 _clientId, uint256 _tokenAmount) onlyOwner stopInEmergency public {
		ePartnerAllocateRestrictedTokenTo(_PartnerID, _clientId, _tokenAmount);
    }
	
// functions for transferring token to booking 	
	function confirmTokenTransferToBooking(bytes32 _PartnerID, string _TxNum, bytes32 _fromClientId1, bytes32 _toClientId2, uint256 _tokenAmount1, uint256 _rAmount1, uint256 _tokenAmount2, uint256 _rAmount2, uint256 _txTokenAmount1, uint256 _txRAmount1, uint256 _txTokenAmount2, uint256 _txRAmount2) onlyOwner stopInEmergency public {		
		eConfirmTokenTransferToBooking(_PartnerID, _TxNum, _fromClientId1, _toClientId2, _tokenAmount1, _rAmount1, _tokenAmount2, _rAmount2);
		eTransactionFeeForBooking(_PartnerID, _TxNum, _fromClientId1, _toClientId2, _txTokenAmount1, _txRAmount1, _txTokenAmount2, _txRAmount2);
	}

 
// functions for returning tokens	
	function confirmReturnToken(bytes32 _PartnerID, string _TxNum, bytes32 _fromClientId1, bytes32 _toClientId2, uint256 _tokenAmount1, uint256 _rAmount1, uint256 _tokenAmount2, uint256 _rAmount2, uint256 _grandTotal) onlyOwner stopInEmergency public {
        eConfirmReturnToken(_PartnerID, _TxNum, _fromClientId1, _tokenAmount1, _rAmount1, _grandTotal);
		eConfirmReturnToken(_PartnerID, _TxNum, _toClientId2, _tokenAmount2, _rAmount2, _grandTotal);
	}


// function for Admin
    function getToken() constant public onlyOwner returns (address) {
        return token;
    }
	
    function setToken(address _token) public onlyOwner stopInEmergency {
        require(token == address(0));
        token = TeuToken(_token);
    }

}