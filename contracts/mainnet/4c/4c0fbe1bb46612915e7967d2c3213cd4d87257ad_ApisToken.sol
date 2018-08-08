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
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
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


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public newOwner;


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
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        OwnershipTransferred(owner, _newOwner);
        newOwner = _newOwner;
    }

    /**
     * @dev 새로운 관리자가 승인해야만 소유권이 이전된다
     */
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


/**
 * @title APIS Token
 * @dev APIS 토큰을 생성한다
 */
contract ApisToken is StandardToken, Ownable {
    // 토큰의 이름
    string public constant name = "APIS";
    
    // 토큰의 단위
    string public constant symbol = "APIS";
    
    // 소수점 자리수. ETH 18자리에 맞춘다
    uint8 public constant decimals = 18;
    
    // 지갑별로 송금/수금 기능의 잠긴 여부를 저장
    mapping (address => LockedInfo) public lockedWalletInfo;
    
    /**
     * @dev 플랫폼에서 운영하는 마스터노드 스마트 컨트렉트 주소
     */
    mapping (address => bool) public manoContracts;
    
    
    /**
     * @dev 토큰 지갑의 잠김 속성을 정의
     * 
     * @param timeLockUpEnd timeLockUpEnd 시간까지 송/수금에 대한 제한이 적용된다. 이후에는 제한이 풀린다
     * @param sendLock 출금 잠김 여부(true : 잠김, false : 풀림)
     * @param receiveLock 입금 잠김 여부 (true : 잠김, false : 풀림)
     */
    struct LockedInfo {
        uint timeLockUpEnd;
        bool sendLock;
        bool receiveLock;
    } 
    
    
    /**
     * @dev 토큰이 송금됐을 때 발생하는 이벤트
     * @param from 토큰을 보내는 지갑 주소
     * @param to 토큰을 받는 지갑 주소
     * @param value 전달되는 토큰의 양 (Satoshi)
     */
    event Transfer (address indexed from, address indexed to, uint256 value);
    
    /**
     * @dev 토큰 지갑의 송금/입금 기능이 제한되었을 때 발생하는 이벤트
     * @param target 제한 대상 지갑 주소
     * @param timeLockUpEnd 제한이 종료되는 시간(UnixTimestamp)
     * @param sendLock 지갑에서의 송금을 제한하는지 여부(true : 제한, false : 해제)
     * @param receiveLock 지갑으로의 입금을 제한하는지 여부 (true : 제한, false : 해제)
     */
    event Locked (address indexed target, uint timeLockUpEnd, bool sendLock, bool receiveLock);
    
    /**
     * @dev 지갑에 대한 송금/입금 제한을 해제했을 때 발생하는 이벤트
     * @param target 해제 대상 지갑 주소
     */
    event Unlocked (address indexed target);
    
    /**
     * @dev 송금 받는 지갑의 입금이 제한되어있어서 송금이 거절되었을 때 발생하는 이벤트
     * @param from 토큰을 보내는 지갑 주소
     * @param to (입금이 제한된) 토큰을 받는 지갑 주소
     * @param value 전송하려고 한 토큰의 양(Satoshi)
     */
    event RejectedPaymentToLockedUpWallet (address indexed from, address indexed to, uint256 value);
    
    /**
     * @dev 송금하는 지갑의 출금이 제한되어있어서 송금이 거절되었을 때 발생하는 이벤트
     * @param from (출금이 제한된) 토큰을 보내는 지갑 주소
     * @param to 토큰을 받는 지갑 주소
     * @param value 전송하려고 한 토큰의 양(Satoshi)
     */
    event RejectedPaymentFromLockedUpWallet (address indexed from, address indexed to, uint256 value);
    
    /**
     * @dev 토큰을 소각한다. 
     * @param burner 토큰을 소각하는 지갑 주소
     * @param value 소각하는 토큰의 양(Satoshi)
     */
    event Burn (address indexed burner, uint256 value);
    
    /**
     * @dev 아피스 플랫폼에 마스터노드 스마트 컨트렉트가 등록되거나 해제될 때 발생하는 이벤트
     */
    event ManoContractRegistered (address manoContract, bool registered);
    
    /**
     * @dev 컨트랙트가 생성될 때 실행. 컨트렉트 소유자 지갑에 모든 토큰을 할당한다.
     * 발행량이나 이름은 소스코드에서 확인할 수 있도록 변경하였음
     */
    function ApisToken() public {
        // 총 APIS 발행량 (95억 2천만)
        uint256 supplyApis = 9520000000;
        
        // wei 단위로 토큰 총량을 생성한다.
        totalSupply = supplyApis * 10 ** uint256(decimals);
        
        balances[msg.sender] = totalSupply;
        
        Transfer(0x0, msg.sender, totalSupply);
    }
    
    
    /**
     * @dev 지갑을 지정된 시간까지 제한시키거나 해제시킨다. 제한 시간이 경과하면 모든 제한이 해제된다.
     * @param _targetWallet 제한을 적용할 지갑 주소
     * @param _timeLockEnd 제한이 종료되는 시간(UnixTimestamp)
     * @param _sendLock (true : 지갑에서 토큰을 출금하는 기능을 제한한다.) (false : 제한을 해제한다)
     * @param _receiveLock (true : 지갑으로 토큰을 입금받는 기능을 제한한다.) (false : 제한을 해제한다)
     */
    function walletLock(address _targetWallet, uint _timeLockEnd, bool _sendLock, bool _receiveLock) onlyOwner public {
        require(_targetWallet != 0x0);
        
        // If all locks are unlocked, set the _timeLockEnd to zero.
        if(_sendLock == false && _receiveLock == false) {
            _timeLockEnd = 0;
        }
        
        lockedWalletInfo[_targetWallet].timeLockUpEnd = _timeLockEnd;
        lockedWalletInfo[_targetWallet].sendLock = _sendLock;
        lockedWalletInfo[_targetWallet].receiveLock = _receiveLock;
        
        if(_timeLockEnd > 0) {
            Locked(_targetWallet, _timeLockEnd, _sendLock, _receiveLock);
        } else {
            Unlocked(_targetWallet);
        }
    }
    
    /**
     * @dev 지갑의 입급/출금을 지정된 시간까지 제한시킨다. 제한 시간이 경과하면 모든 제한이 해제된다.
     * @param _targetWallet 제한을 적용할 지갑 주소
     * @param _timeLockUpEnd 제한이 종료되는 시간(UnixTimestamp)
     */
    function walletLockBoth(address _targetWallet, uint _timeLockUpEnd) onlyOwner public {
        walletLock(_targetWallet, _timeLockUpEnd, true, true);
    }
    
    /**
     * @dev 지갑의 입급/출금을 영원히(33658-9-27 01:46:39+00) 제한시킨다.
     * @param _targetWallet 제한을 적용할 지갑 주소
     */
    function walletLockBothForever(address _targetWallet) onlyOwner public {
        walletLock(_targetWallet, 999999999999, true, true);
    }
    
    
    /**
     * @dev 지갑에 설정된 입출금 제한을 해제한다
     * @param _targetWallet 제한을 해제하고자 하는 지갑 주소
     */
    function walletUnlock(address _targetWallet) onlyOwner public {
        walletLock(_targetWallet, 0, false, false);
    }
    
    /**
     * @dev 지갑의 송금 기능이 제한되어있는지 확인한다.
     * @param _addr 송금 제한 여부를 확인하려는 지갑의 주소
     * @return isSendLocked (true : 제한되어 있음, 토큰을 보낼 수 없음) (false : 제한 없음, 토큰을 보낼 수 있음)
     * @return until 잠겨있는 시간, UnixTimestamp
     */
    function isWalletLocked_Send(address _addr) public constant returns (bool isSendLocked, uint until) {
        require(_addr != 0x0);
        
        isSendLocked = (lockedWalletInfo[_addr].timeLockUpEnd > now && lockedWalletInfo[_addr].sendLock == true);
        
        if(isSendLocked) {
            until = lockedWalletInfo[_addr].timeLockUpEnd;
        } else {
            until = 0;
        }
    }
    
    /**
     * @dev 지갑의 입금 기능이 제한되어있는지 확인한다.
     * @param _addr 입금 제한 여부를 확인하려는 지갑의 주소
     * @return (true : 제한되어 있음, 토큰을 받을 수 없음) (false : 제한 없음, 토큰을 받을 수 있음)
     */
    function isWalletLocked_Receive(address _addr) public constant returns (bool isReceiveLocked, uint until) {
        require(_addr != 0x0);
        
        isReceiveLocked = (lockedWalletInfo[_addr].timeLockUpEnd > now && lockedWalletInfo[_addr].receiveLock == true);
        
        if(isReceiveLocked) {
            until = lockedWalletInfo[_addr].timeLockUpEnd;
        } else {
            until = 0;
        }
    }
    
    /**
     * @dev 요청자의 지갑에 송금 기능이 제한되어있는지 확인한다.
     * @return (true : 제한되어 있음, 토큰을 보낼 수 없음) (false : 제한 없음, 토큰을 보낼 수 있음)
     */
    function isMyWalletLocked_Send() public constant returns (bool isSendLocked, uint until) {
        return isWalletLocked_Send(msg.sender);
    }
    
    /**
     * @dev 요청자의 지갑에 입금 기능이 제한되어있는지 확인한다.
     * @return (true : 제한되어 있음, 토큰을 보낼 수 없음) (false : 제한 없음, 토큰을 보낼 수 있음)
     */
    function isMyWalletLocked_Receive() public constant returns (bool isReceiveLocked, uint until) {
        return isWalletLocked_Receive(msg.sender);
    }
    
    
    /**
     * @dev 아피스 플랫폼에서 운영하는 스마트 컨트렉트 주소를 등록하거나 해제한다.
     * @param manoAddr 마스터노드 스마트 컨트렉컨트렉트
     * @param registered true : 등록, false : 해제
     */
    function registerManoContract(address manoAddr, bool registered) onlyOwner public {
        manoContracts[manoAddr] = registered;
        
        ManoContractRegistered(manoAddr, registered);
    }
    
    
    /**
     * @dev _to 지갑으로 _apisWei 만큼의 토큰을 송금한다.
     * @param _to 토큰을 받는 지갑 주소
     * @param _apisWei 전송되는 토큰의 양
     */
    function transfer(address _to, uint256 _apisWei) public returns (bool) {
        // 자신에게 송금하는 것을 방지한다
        require(_to != address(this));
        
        // 마스터노드 컨트렉트일 경우, APIS 송수신에 제한을 두지 않는다
        if(manoContracts[msg.sender] || manoContracts[_to]) {
            return super.transfer(_to, _apisWei);
        }
        
        // 송금 기능이 잠긴 지갑인지 확인한다.
        if(lockedWalletInfo[msg.sender].timeLockUpEnd > now && lockedWalletInfo[msg.sender].sendLock == true) {
            RejectedPaymentFromLockedUpWallet(msg.sender, _to, _apisWei);
            return false;
        } 
        // 입금 받는 기능이 잠긴 지갑인지 확인한다
        else if(lockedWalletInfo[_to].timeLockUpEnd > now && lockedWalletInfo[_to].receiveLock == true) {
            RejectedPaymentToLockedUpWallet(msg.sender, _to, _apisWei);
            return false;
        } 
        // 제한이 없는 경우, 송금을 진행한다.
        else {
            return super.transfer(_to, _apisWei);
        }
    }
    
    /**
     * @dev _to 지갑으로 _apisWei 만큼의 APIS를 송금하고 _timeLockUpEnd 시간만큼 지갑을 잠근다
     * @param _to 토큰을 받는 지갑 주소
     * @param _apisWei 전송되는 토큰의 양(wei)
     * @param _timeLockUpEnd 잠금이 해제되는 시간
     */
    function transferAndLockUntil(address _to, uint256 _apisWei, uint _timeLockUpEnd) onlyOwner public {
        require(transfer(_to, _apisWei));
        
        walletLockBoth(_to, _timeLockUpEnd);
    }
    
    /**
     * @dev _to 지갑으로 _apisWei 만큼의 APIS를 송금하고영원히 지갑을 잠근다
     * @param _to 토큰을 받는 지갑 주소
     * @param _apisWei 전송되는 토큰의 양(wei)
     */
    function transferAndLockForever(address _to, uint256 _apisWei) onlyOwner public {
        require(transfer(_to, _apisWei));
        
        walletLockBothForever(_to);
    }
    
    
    /**
     * @dev 함수를 호출하는 지갑의 토큰을 소각한다.
     * 
     * zeppelin-solidity/contracts/token/BurnableToken.sol 참조
     * @param _value 소각하려는 토큰의 양(Satoshi)
     */
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        require(_value <= totalSupply);
        
        address burner = msg.sender;
        balances[burner] -= _value;
        totalSupply -= _value;
        
        Burn(burner, _value);
    }
    
    
    /**
     * @dev Eth은 받을 수 없도록 한다.
     */
    function () public payable {
        revert();
    }
}








/**
 * @title WhiteList
 * @dev ICO 참여가 가능한 화이트 리스트를 관리한다
 */
contract WhiteList is Ownable {
    
    mapping (address => uint8) internal list;
    
    /**
     * @dev 화이트리스트에 변동이 발생했을 때 이벤트
     * @param backer 화이트리스트에 등재하려는 지갑 주소
     * @param allowed (true : 화이트리스트에 추가) (false : 제거)
     */
    event WhiteBacker(address indexed backer, bool allowed);
    
    
    /**
     * @dev 화이트리스트에 등록하거나 해제한다.
     * @param _target 화이트리스트에 등재하려는 지갑 주소
     * @param _allowed (true : 화이트리스트에 추가) (false : 제거) 
     */
    function setWhiteBacker(address _target, bool _allowed) onlyOwner public {
        require(_target != 0x0);
        
        if(_allowed == true) {
            list[_target] = 1;
        } else {
            list[_target] = 0;
        }
        
        WhiteBacker(_target, _allowed);
    }
    
    /**
     * @dev 화이트 리스트에 등록(추가)한다
     * @param _target 추가할 지갑 주소
     */
    function addWhiteBacker(address _target) onlyOwner public {
        setWhiteBacker(_target, true);
    }
    
    /**
     * @dev 화이트리스트에 여러 지갑 주소를 동시에 등재하거나 제거한다.
     * 
     * 가스 소모를 줄여보기 위함
     * @param _backers 대상이 되는 지갑들의 리스트
     * @param _allows 대상이 되는 지갑들의 추가 여부 리스트 (true : 추가) (false : 제거)
     */
    function setWhiteBackersByList(address[] _backers, bool[] _allows) onlyOwner public {
        require(_backers.length > 0);
        require(_backers.length == _allows.length);
        
        for(uint backerIndex = 0; backerIndex < _backers.length; backerIndex++) {
            setWhiteBacker(_backers[backerIndex], _allows[backerIndex]);
        }
    }
    
    /**
     * @dev 화이트리스트에 여러 지갑 주소를 등재한다.
     * 
     * 모든 주소들은 화이트리스트에 추가된다.
     * @param _backers 대상이 되는 지갑들의 리스트
     */
    function addWhiteBackersByList(address[] _backers) onlyOwner public {
        for(uint backerIndex = 0; backerIndex < _backers.length; backerIndex++) {
            setWhiteBacker(_backers[backerIndex], true);
        }
    }
    
    
    /**
     * @dev 해당 지갑 주소가 화이트 리스트에 등록되어있는지 확인한다
     * @param _addr 등재 여부를 확인하려는 지갑의 주소
     * @return (true : 등록되어있음) (false : 등록되어있지 않음)
     */
    function isInWhiteList(address _addr) public constant returns (bool) {
        require(_addr != 0x0);
        return list[_addr] > 0;
    }
    
    /**
     * @dev 요청하는 지갑이 화이트리스트에 등록되어있는지 확인한다.
     * @return (true : 등록되어있음) (false : 등록되어있지 않음)
     */
    function isMeInWhiteList() public constant returns (bool isWhiteBacker) {
        return list[msg.sender] > 0;
    }
}



/**
 * @title APIS Crowd Pre-Sale
 * @dev 토큰의 프리세일을 수행하기 위한 컨트랙트
 */
contract ApisCrowdSale is Ownable {
    
    // 소수점 자리수. Eth 18자리에 맞춘다
    uint8 public constant decimals = 18;
    
    
    // 크라우드 세일의 판매 목표량(APIS)
    uint256 public fundingGoal;
    
    // 현재 진행하는 판매 목표량 
    // QTUM과 공동으로 판매가 진행되기 때문에,  QTUM 쪽 컨트렉트와 합산한 판매량이 총 판매목표를 넘지 않도록 하기 위함
    uint256 public fundingGoalCurrent;
    
    // 1 ETH으로 살 수 있는 APIS의 갯수
    uint256 public priceOfApisPerFund;
    

    // 발급된 Apis 갯수 (예약 + 발행)
    //uint256 public totalSoldApis;
    
    // 발행 대기중인 APIS 갯수
    //uint256 public totalReservedApis;
    
    // 발행되서 출금된 APIS 갯수
    //uint256 public totalWithdrawedApis;
    
    
    // 입금된 투자금의 총액 (예약 + 발행)
    //uint256 public totalReceivedFunds;
    
    // 구매 확정 전 투자금의 총액
    //uint256 public totalReservedFunds;
    
    // 구매 확정된 투자금의 총액
    //uint256 public totalPaidFunds;

    
    // 판매가 시작되는 시간
    uint public startTime;
    
    // 판매가 종료되는 시간
    uint public endTime;

    // 판매가 조기에 종료될 경우를 대비하기 위함
    bool closed = false;
    
	SaleStatus public saleStatus;
    
    // APIS 토큰 컨트렉트
    ApisToken internal tokenReward;
    
    // 화이트리스트 컨트렉트
    WhiteList internal whiteList;

    
    
    mapping (address => Property) public fundersProperty;
    
    /**
     * @dev APIS 토큰 구매자의 자산 현황을 정리하기 위한 구조체
     */
    struct Property {
        uint256 reservedFunds;   // 입금했지만 아직 APIS로 변환되지 않은 Eth (환불 가능)
        uint256 paidFunds;    	// APIS로 변환된 Eth (환불 불가)
        uint256 reservedApis;   // 받을 예정인 토큰
        uint256 withdrawedApis; // 이미 받은 토큰
        uint purchaseTime;      // 구입한 시간
    }
	
	
	/**
	 * @dev 현재 세일의 진행 현황을 확인할 수 있다.
	 * totalSoldApis 발급된 Apis 갯수 (예약 + 발행)
	 * totalReservedApis 발행 대기 중인 Apis
	 * totalWithdrawedApis 발행되서 출금된 APIS 갯수
	 * 
	 * totalReceivedFunds 입금된 투자금의 총액 (예약 + 발행)
	 * totalReservedFunds 구매 확정 전 투자금의 총액
	 * ttotalPaidFunds 구매 확정된 투자금의 총액
	 */
	struct SaleStatus {
		uint256 totalReservedFunds;
		uint256 totalPaidFunds;
		uint256 totalReceivedFunds;
		
		uint256 totalReservedApis;
		uint256 totalWithdrawedApis;
		uint256 totalSoldApis;
	}
    
    
    
    /**
     * @dev APIS를 구입하기 위한 Eth을 입금했을 때 발생하는 이벤트
     * @param beneficiary APIS를 구매하고자 하는 지갑의 주소
     * @param amountOfFunds 입금한 Eth의 양 (wei)
     * @param amountOfApis 투자금에 상응하는 APIS 토큰의 양 (wei)
     */
    event ReservedApis(address beneficiary, uint256 amountOfFunds, uint256 amountOfApis);
    
    /**
     * @dev 크라우드 세일 컨트렉트에서 Eth이 인출되었을 때 발생하는 이벤트
     * @param addr 받는 지갑의 주소
     * @param amount 송금되는 양(wei)
     */
    event WithdrawalFunds(address addr, uint256 amount);
    
    /**
     * @dev 구매자에게 토큰이 발급되었을 때 발생하는 이벤트
     * @param funder 토큰을 받는 지갑의 주소
     * @param amountOfFunds 입금한 투자금의 양 (wei)
     * @param amountOfApis 발급 받는 토큰의 양 (wei)
     */
    event WithdrawalApis(address funder, uint256 amountOfFunds, uint256 amountOfApis);
    
    
    /**
     * @dev 투자금 입금 후, 아직 토큰을 발급받지 않은 상태에서, 환불 처리를 했을 때 발생하는 이벤트
     * @param _backer 환불 처리를 진행하는 지갑의 주소
     * @param _amountFunds 환불하는 투자금의 양
     * @param _amountApis 취소되는 APIS 양
     */
    event Refund(address _backer, uint256 _amountFunds, uint256 _amountApis);
    
    
    /**
     * @dev 크라우드 세일 진행 중에만 동작하도록 제한하고, APIS의 가격도 설정되어야만 한다.
     */
    modifier onSale() {
        require(now >= startTime);
        require(now < endTime);
        require(closed == false);
        require(priceOfApisPerFund > 0);
        require(fundingGoalCurrent > 0);
        _;
    }
    
    /**
     * @dev 크라우드 세일 종료 후에만 동작하도록 제한
     */
    modifier onFinished() {
        require(now >= endTime || closed == true);
        _;
    }
    
    /**
     * @dev 화이트리스트에 등록되어있어야하고 아직 구매완료 되지 않은 투자금이 있어야만 한다.
     */
    modifier claimable() {
        require(whiteList.isInWhiteList(msg.sender) == true);
        require(fundersProperty[msg.sender].reservedFunds > 0);
        _;
    }
    
    
    /**
     * @dev 크라우드 세일 컨트렉트를 생성한다.
     * @param _fundingGoalApis 판매하는 토큰의 양 (APIS 단위)
     * @param _startTime 크라우드 세일을 시작하는 시간
     * @param _endTime 크라우드 세일을 종료하는 시간
     * @param _addressOfApisTokenUsedAsReward APIS 토큰의 컨트렉트 주소
     * @param _addressOfWhiteList WhiteList 컨트렉트 주소
     */
    function ApisCrowdSale (
        uint256 _fundingGoalApis,
        uint _startTime,
        uint _endTime,
        address _addressOfApisTokenUsedAsReward,
        address _addressOfWhiteList
    ) public {
        require (_fundingGoalApis > 0);
        require (_startTime > now);
        require (_endTime > _startTime);
        require (_addressOfApisTokenUsedAsReward != 0x0);
        require (_addressOfWhiteList != 0x0);
        
        fundingGoal = _fundingGoalApis * 10 ** uint256(decimals);
        
        startTime = _startTime;
        endTime = _endTime;
        
        // 토큰 스마트컨트렉트를 불러온다
        tokenReward = ApisToken(_addressOfApisTokenUsedAsReward);
        
        // 화이트 리스트를 가져온다
        whiteList = WhiteList(_addressOfWhiteList);
    }
    
    /**
     * @dev 판매 종료는 1회만 가능하도록 제약한다. 종료 후 다시 판매 중으로 변경할 수 없다
     */
    function closeSale(bool _closed) onlyOwner public {
        require (closed == false);
        
        closed = _closed;
    }
    
    /**
     * @dev 크라우드 세일 시작 전에 1Eth에 해당하는 APIS 량을 설정한다.
     */
    function setPriceOfApis(uint256 price) onlyOwner public {
        require(priceOfApisPerFund == 0);
        
        priceOfApisPerFund = price;
    }
    
    /**
     * @dev 현 시점에서 판매 가능한 목표량을 수정한다.
     * @param _currentFundingGoalAPIS 현 시점의 판매 목표량은 총 판매된 양 이상이어야만 한다.
     */
    function setCurrentFundingGoal(uint256 _currentFundingGoalAPIS) onlyOwner public {
        uint256 fundingGoalCurrentWei = _currentFundingGoalAPIS * 10 ** uint256(decimals);
        require(fundingGoalCurrentWei >= saleStatus.totalSoldApis);
        
        fundingGoalCurrent = fundingGoalCurrentWei;
    }
    
    
    /**
     * @dev APIS 잔고를 확인한다
     * @param _addr 잔고를 확인하려는 지갑의 주소
     * @return balance 지갑에 들은 APIS 잔고 (wei)
     */
    function balanceOf(address _addr) public view returns (uint256 balance) {
        return tokenReward.balanceOf(_addr);
    }
    
    /**
     * @dev 화이트리스트 등록 여부를 확인한다
     * @param _addr 등록 여부를 확인하려는 주소
     * @return addrIsInWhiteList true : 등록되있음, false : 등록되어있지 않음
     */
    function whiteListOf(address _addr) public view returns (string message) {
        if(whiteList.isInWhiteList(_addr) == true) {
            return "The address is in whitelist.";
        } else {
            return "The address is *NOT* in whitelist.";
        }
    }
    
    
    /**
     * @dev 전달받은 지갑이 APIS 지급 요청이 가능한지 확인한다.
     * @param _addr 확인하는 주소
     * @return message 결과 메시지
     */
    function isClaimable(address _addr) public view returns (string message) {
        if(fundersProperty[_addr].reservedFunds == 0) {
            return "The address has no claimable balance.";
        }
        
        if(whiteList.isInWhiteList(_addr) == false) {
            return "The address must be registered with KYC and Whitelist";
        }
        
        else {
            return "The address can claim APIS!";
        }
    }
    
    
    /**
     * @dev 크라우드 세일 컨트렉트로 바로 투자금을 송금하는 경우, buyToken으로 연결한다
     */
    function () onSale public payable {
        buyToken(msg.sender);
    }
    
    /**
     * @dev 토큰을 구입하기 위해 Qtum을 입금받는다.
     * @param _beneficiary 토큰을 받게 될 지갑의 주소
     */
    function buyToken(address _beneficiary) onSale public payable {
        // 주소 확인
        require(_beneficiary != 0x0);
        
        // 크라우드 세일 컨트렉트의 토큰 송금 기능이 정지되어있으면 판매하지 않는다
        bool isLocked = false;
        uint timeLock = 0;
        (isLocked, timeLock) = tokenReward.isWalletLocked_Send(this);
        
        require(isLocked == false);
        
        
        uint256 amountFunds = msg.value;
        uint256 reservedApis = amountFunds * priceOfApisPerFund;
        
        
        // 목표 금액을 넘어서지 못하도록 한다
        require(saleStatus.totalSoldApis + reservedApis <= fundingGoalCurrent);
        require(saleStatus.totalSoldApis + reservedApis <= fundingGoal);
        
        // 투자자의 자산을 업데이트한다
        fundersProperty[_beneficiary].reservedFunds += amountFunds;
        fundersProperty[_beneficiary].reservedApis += reservedApis;
        fundersProperty[_beneficiary].purchaseTime = now;
        
        // 총액들을 업데이트한다
        saleStatus.totalReceivedFunds += amountFunds;
        saleStatus.totalReservedFunds += amountFunds;
        
        saleStatus.totalSoldApis += reservedApis;
        saleStatus.totalReservedApis += reservedApis;
        
        
        // 화이트리스트에 등록되어있으면 바로 출금한다
        if(whiteList.isInWhiteList(_beneficiary) == true) {
            withdrawal(_beneficiary);
        }
        else {
            // 토큰 발행 예약 이벤트 발생
            ReservedApis(_beneficiary, amountFunds, reservedApis);
        }
    }
    
    
    
    /**
     * @dev 관리자에 의해서 토큰을 발급한다. 하지만 기본 요건은 갖춰야만 가능하다
     * 
     * @param _target 토큰 발급을 청구하려는 지갑 주소
     */
    function claimApis(address _target) public {
        // 화이트 리스트에 있어야만 하고
        require(whiteList.isInWhiteList(_target) == true);
        // 예약된 투자금이 있어야만 한다.
        require(fundersProperty[_target].reservedFunds > 0);
        
        withdrawal(_target);
    }
    
    /**
     * @dev 예약한 토큰의 실제 지급을 요청하도록 한다.
     * 
     * APIS를 구매하기 위해 Qtum을 입금할 경우, 관리자의 검토를 위한 7일의 유예기간이 존재한다.
     * 유예기간이 지나면 토큰 지급을 요구할 수 있다.
     */
    function claimMyApis() claimable public {
        withdrawal(msg.sender);
    }
    
    
    /**
     * @dev 구매자에게 토큰을 지급한다.
     * @param funder 토큰을 지급할 지갑의 주소
     */
    function withdrawal(address funder) internal {
        // 구매자 지갑으로 토큰을 전달한다
        assert(tokenReward.transferFrom(owner, funder, fundersProperty[funder].reservedApis));
        
        fundersProperty[funder].withdrawedApis += fundersProperty[funder].reservedApis;
        fundersProperty[funder].paidFunds += fundersProperty[funder].reservedFunds;
        
        // 총액에 반영
        saleStatus.totalReservedFunds -= fundersProperty[funder].reservedFunds;
        saleStatus.totalPaidFunds += fundersProperty[funder].reservedFunds;
        
        saleStatus.totalReservedApis -= fundersProperty[funder].reservedApis;
        saleStatus.totalWithdrawedApis += fundersProperty[funder].reservedApis;
        
        // APIS가 출금 되었음을 알리는 이벤트
        WithdrawalApis(funder, fundersProperty[funder].reservedFunds, fundersProperty[funder].reservedApis);
        
        // 인출하지 않은 APIS 잔고를 0으로 변경해서, Qtum 재입금 시 이미 출금한 토큰이 다시 출금되지 않게 한다.
        fundersProperty[funder].reservedFunds = 0;
        fundersProperty[funder].reservedApis = 0;
    }
    
    
    /**
     * @dev 아직 토큰을 발급받지 않은 지갑을 대상으로, 환불을 진행할 수 있다.
     * @param _funder 환불을 진행하려는 지갑의 주소
     */
    function refundByOwner(address _funder) onlyOwner public {
        require(fundersProperty[_funder].reservedFunds > 0);
        
        uint256 amountFunds = fundersProperty[_funder].reservedFunds;
        uint256 amountApis = fundersProperty[_funder].reservedApis;
        
        // Eth을 환불한다
        _funder.transfer(amountFunds);
        
        saleStatus.totalReceivedFunds -= amountFunds;
        saleStatus.totalReservedFunds -= amountFunds;
        
        saleStatus.totalSoldApis -= amountApis;
        saleStatus.totalReservedApis -= amountApis;
        
        fundersProperty[_funder].reservedFunds = 0;
        fundersProperty[_funder].reservedApis = 0;
        
        Refund(_funder, amountFunds, amountApis);
    }
    
    
    /**
     * @dev 펀딩이 종료된 이후면, 적립된 투자금을 반환한다.
     * @param remainRefundable true : 환불할 수 있는 금액은 남기고 반환한다. false : 모두 반환한다
     */
    function withdrawalFunds(bool remainRefundable) onlyOwner public {
        require(now > endTime || closed == true);
        
        uint256 amount = 0;
        if(remainRefundable) {
            amount = this.balance - saleStatus.totalReservedFunds;
        } else {
            amount = this.balance;
        }
        
        if(amount > 0) {
            msg.sender.transfer(amount);
            
            WithdrawalFunds(msg.sender, amount);
        }
    }
    
    /**
	 * @dev 크라우드 세일이 진행 중인지 여부를 반환한다.
	 * @return isOpened true: 진행 중 false : 진행 중이 아님(참여 불가)
	 */
    function isOpened() public view returns (bool isOpend) {
        if(now < startTime) return false;
        if(now >= endTime) return false;
        if(closed == true) return false;
        
        return true;
    }
}