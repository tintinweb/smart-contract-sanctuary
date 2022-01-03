/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

// File: contracts/checked/SafeMath.sol

pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
// File: contracts/checked/ERC20Basic.sol

pragma solidity ^0.4.18;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
// File: contracts/checked/ERC20.sol

pragma solidity ^0.4.18;



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
// File: contracts/checked/BasicToken.sol

pragma solidity ^0.4.18;




/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
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
// File: contracts/checked/StandardToken.sol

pragma solidity ^0.4.18;




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
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}
// File: contracts/checked/Ownable.sol

pragma solidity ^0.4.18;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
// File: contracts/checked/WhiteList.sol

pragma solidity ^0.4.18;


contract WhiteList is Ownable {
    
    mapping (address => uint8) internal list;
    

    event WhiteBacker(address indexed backer, bool allowed);
    
    function setWhiteBacker(address _target, bool _allowed) onlyOwner public {
        require(_target != 0x0);
        
        if(_allowed == true) {
            list[_target] = 1;
        } else {
            list[_target] = 0;
        }
        
        WhiteBacker(_target, _allowed);
    }

    function setWhiteBackersByList(address[] _backers, bool[] _allows) onlyOwner public {
        require(_backers.length > 0);
        require(_backers.length == _allows.length);
        
        for( uint backerIndex = 0; backerIndex < _backers.length; backerIndex++) {
            setWhiteBacker(_backers[backerIndex], _allows[backerIndex]);
        }
    }

    function addWhiteBackersByList(address[] _backers) onlyOwner public {
        for( uint backerIndex = 0; backerIndex < _backers.length; backerIndex++) {
            setWhiteBacker(_backers[backerIndex], true);
        }
    }

    function isInWhiteList(address _addr) public constant returns (bool) {
        require(_addr != 0x0);
        return list[_addr] > 0;
    }
    

    function imInWhiteList() public constant returns (bool) {
        return list[msg.sender] > 0;
    }
}
// File: contracts/checked/ApisToken.sol

pragma solidity ^0.4.18;




contract ApisToken is StandardToken, Ownable {
    string public name;
    
    string public symbol;

    uint8 public constant decimals = 9;
    
    mapping (address => LockedInfo) public lockedWalletInfo;
    
    struct LockedInfo {

        uint timeLockUpEnd;
      
        bool sendLock;
        
        bool receiveLock;
    } 
    
    event Transfer (address indexed from, address indexed to, uint256 value);

    event Locked (address indexed target, uint timeLockUpEnd, bool sendLock, bool receiveLock);

    event Unlocked (address indexed target);

    event RejectedPaymentToLockedUpWallet (address indexed from, address indexed to, uint256 value);

    event RejectedPaymentFromLockedUpWallet (address indexed from, address indexed to, uint256 value);

    event Burn (address indexed burner, uint256 value);

    function ApisToken(uint256 _supply, string _name, string _symbol) public {
        name = _name;
        symbol = _symbol;

        totalSupply = _supply * 10 ** uint256(decimals);
        
        balances[msg.sender] = totalSupply;
        
        Transfer(0x0, msg.sender, totalSupply);
    }

    function walletLock(address _targetWallet, uint _timeLockUpEnd, bool _sendLock, bool _receiveLock) onlyOwner public {
        require(_targetWallet != 0x0);
        
        lockedWalletInfo[_targetWallet].timeLockUpEnd = _timeLockUpEnd;
        lockedWalletInfo[_targetWallet].sendLock = _sendLock;
        lockedWalletInfo[_targetWallet].receiveLock = _receiveLock;
        
        if(_timeLockUpEnd > 0) {
            Locked(_targetWallet, _timeLockUpEnd, _sendLock, _receiveLock);
        } else {
            Unlocked(_targetWallet);
        }
    }
    
    function walletUnlock(address _targetWallet) onlyOwner public {
        walletLock(_targetWallet, 0, false, false);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {

        require(_to != address(this));

        if(lockedWalletInfo[msg.sender].timeLockUpEnd > now && lockedWalletInfo[msg.sender].sendLock == true) {
            RejectedPaymentFromLockedUpWallet(msg.sender, _to, _value);
            return false;
        } 

        else if(lockedWalletInfo[_to].timeLockUpEnd > now && lockedWalletInfo[_to].receiveLock == true) {
            RejectedPaymentToLockedUpWallet(msg.sender, _to, _value);
            return false;
        } 

        else {
            return super.transfer(_to, _value);
        }
    }

    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        require(_value <= totalSupply);
        
        address burner = msg.sender;
        balances[burner] -= _value;
        totalSupply -= _value;
        
        Burn(burner, _value);
    }
}






// File: contracts/checked/ApisCrowdPreSale - Mod - Vest.sol

pragma solidity ^0.4.18;





contract PublicPresale is Ownable {
    

    uint8 public constant decimals = 9; //equal to token decimals - from input data
    uint8 internal saleState = 0;
	
    uint256 public fundingGoal; 
    uint256 public TokenPerETH; //from input data   
    uint256 public soldToken; 

    uint public endTime; 

    bool public enableWL = true; //from input data
	
    uint public maximumAmount; 
    uint public minimumAmount; 

    uint public claimableTime;

    uint public suspensionPeriod; 

    ApisToken internal tokenReward;
    WhiteList internal whiteList;
    
    mapping (address => Property) public fundersProperty;

    struct Property {
        uint256 reservedETH; 
        uint256 paidETH;    	
        uint256 reservedToken;  
        uint256 withdrawedToken; 
        bool withdrawed;        
        uint purchaseTime;
		uint8 claimState;
    }
    
    event ReservedToken(address beneficiary, uint256 amountETH, uint256 amountToken);
    event WithdrawalETH(address addr, uint256 amount);
    event WithdrawalToken(address funder, uint256 amount, bool result);
    event Refund(address _backer, uint256 _amountETH);
    
    modifier onSale() {
        require(saleState == 1);
        require(now < endTime);
        _;
    }
    
    modifier claimable() {
        bool afterClaimableTime = now > claimableTime;
        bool afterSuspension = now > fundersProperty[msg.sender].purchaseTime + suspensionPeriod;
        
        require(afterClaimableTime == true || afterSuspension == true);
        _;
    }

	
    
    function PublicPresale (
        uint256 _fundingGoalToken, //from input data
        uint256 _TokenPerETH, //from input data
        uint _endTime, //from input data
        uint256 _minimumAmount, //e.g: 0.1 - from input data, translate to wei
        uint256 _maximumAmount, //e.g: 1 - from input data, translate to wei
        address _addressOfTokenUsedAsReward, // token to sale - from input data
        address _addressOfWhiteList // default
    ) public {
        require (_fundingGoalToken > 0);
        require (_TokenPerETH > 0);
        require (_endTime > now);
        require (_maximumAmount > 0);
        require (_minimumAmount > 0);
        require (_addressOfTokenUsedAsReward != 0x0);
        require (_addressOfWhiteList != 0x0);
        
        fundingGoal = _fundingGoalToken * 10 ** uint256(decimals);
        TokenPerETH = _TokenPerETH * 10 ** uint256(decimals);
        endTime = _endTime;
        maximumAmount = _maximumAmount; 
        minimumAmount = _minimumAmount; 		
        claimableTime = 99999999999;
        suspensionPeriod = 90 days;
        
        require (fundingGoal > _fundingGoalToken);

        tokenReward = ApisToken(_addressOfTokenUsedAsReward);
        
        whiteList = WhiteList(_addressOfWhiteList);
    }
    
    
    function StartSale() onlyOwner public {
        saleState = 1;
    }

    function FinishSale() onlyOwner public {
        saleState = 2;
    }

    function setsuspensionPeriod(uint _suspensionPeriod) onlyOwner public {
        suspensionPeriod = _suspensionPeriod;
    }

	function NoNeedWL() external onlyOwner {
        enableWL = false;
    }
	function NeedWL() external onlyOwner {
        enableWL = true;
    }

    function ClaimEnable() onlyOwner public {
        claimableTime = now;
    } 

    function setClaimableTime(uint _claimableTime) onlyOwner public {
        claimableTime = _claimableTime;
    }    

    function balanceOf(address _addr) public view returns (uint256 balance) {
        return tokenReward.balanceOf(_addr);
    }

    function () onSale public payable {
        Contribute(msg.sender);
    }
	
    function Contribute(address _beneficiary) onSale public payable {
        require(_beneficiary != 0x0);
        require(msg.value >= minimumAmount);
        require(msg.value <= maximumAmount);
        
        require(whiteList.isInWhiteList(_beneficiary) == enableWL);
        
        uint256 amountETH = msg.value;
        uint256 reservedToken = amountETH * TokenPerETH / (10 ** (18));
        
        assert(soldToken + reservedToken <= fundingGoal);
        assert(fundersProperty[_beneficiary].reservedETH + amountETH <= maximumAmount);
                
        fundersProperty[_beneficiary].reservedETH += amountETH;
        fundersProperty[_beneficiary].reservedToken += reservedToken;
        fundersProperty[_beneficiary].purchaseTime = now;
        fundersProperty[_beneficiary].withdrawed = false;
        
        soldToken += reservedToken;
        
        assert(soldToken >= reservedToken);
        
        ReservedToken(_beneficiary, amountETH, reservedToken);
    }

    function sellingState() public view returns (string) {
        if(saleState == 0) {
            return "Sale is not started yet";
        } else if(saleState == 1) {
            return "Sale Live";
            //startTime = now;
        } else {
            return "Sale Finished";
        }
    }
    
    function claimToken(address _target) onlyOwner public {
        withdrawal(_target);
    }

    function Claim() claimable public {       
        withdrawal(msg.sender);
    }

    function withdrawal40(address funder) internal {
        require(fundersProperty[funder].reservedToken > 0);
		require(fundersProperty[funder].claimState == 0);		

        tokenReward.transfer(funder, fundersProperty[funder].reservedToken*40/100);
        
        fundersProperty[funder].withdrawedToken = fundersProperty[funder].reservedToken*40/100;
        fundersProperty[funder].reservedToken = fundersProperty[funder].reservedToken - fundersProperty[funder].withdrawedToken;
        fundersProperty[funder].paidETH += fundersProperty[funder].reservedETH;
		fundersProperty[funder].claimState = 1;


        //assert(fundersProperty[funder].withdrawedToken >= fundersProperty[funder].reservedToken);  
   
        WithdrawalToken(funder, fundersProperty[funder].reservedToken, fundersProperty[funder].withdrawed);
    }


	function withdrawal(address funder) internal {
        require(fundersProperty[funder].reservedToken > 0);  

        tokenReward.transfer(funder, fundersProperty[funder].reservedToken);
        
        fundersProperty[funder].withdrawedToken += fundersProperty[funder].reservedToken;
        fundersProperty[funder].paidETH += fundersProperty[funder].reservedETH;

        assert(fundersProperty[funder].withdrawedToken >= fundersProperty[funder].reservedToken);  

        fundersProperty[funder].reservedETH = 0;
        fundersProperty[funder].reservedToken = 0;
        fundersProperty[funder].withdrawed = true;

        WithdrawalToken(funder, fundersProperty[funder].reservedToken, fundersProperty[funder].withdrawed);
    }


    function refund(address _funder) onlyOwner public {
        require(fundersProperty[_funder].reservedETH > 0);
        require(fundersProperty[_funder].reservedToken > 0);
        require(fundersProperty[_funder].withdrawed == false);
        
        uint256 amount = fundersProperty[_funder].reservedETH;

        _funder.transfer(amount);
        
        fundersProperty[_funder].reservedETH = 0;
        fundersProperty[_funder].reservedToken = 0;
        fundersProperty[_funder].withdrawed = true;
        
        Refund(_funder, amount);
    }
    
	//transfer eth and remaining token balance from contract to owner
    function FinalizeSale() onlyOwner public {
        require(saleState == 2);
        
        uint256 amount = this.balance;
        if(amount > 0) {
            msg.sender.transfer(amount);
            WithdrawalETH(msg.sender, amount);
        }
        
        uint256 token = tokenReward.balanceOf(this);
        tokenReward.transfer(msg.sender, token);
        WithdrawalToken(msg.sender, token, true);
    }

    function getContractBalance() onlyOwner public constant returns (uint256 balance) {
        return this.balance;
    }

    function EmergencyWithdraw() onlyOwner public {
        
        uint256 amount = this.balance;
        if(amount > 0) {
            msg.sender.transfer(amount);
            WithdrawalETH(msg.sender, amount);
        }
        
        uint256 token = tokenReward.balanceOf(this);
        tokenReward.transfer(msg.sender, token);
        WithdrawalToken(msg.sender, token, true);
    }


}