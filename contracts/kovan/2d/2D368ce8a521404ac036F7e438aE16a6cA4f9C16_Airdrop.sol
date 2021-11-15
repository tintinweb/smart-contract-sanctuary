pragma solidity 0.4.19;
pragma experimental ABIEncoderV2;

interface ERC20Interface {
    function balanceOf(address user) public view returns (uint256);
}


library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
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
  function percent(uint numerator, uint denominator) internal pure returns(uint quotient) {
         // caution, check safe-to-multiply here
        uint _numerator  = numerator * 10 ** (10);
        // with rounding of last digit
        uint _quotient =  ((_numerator / denominator)) / 10;
        return ( _quotient);
  }
      
}

contract LockSmartContract {
    function depositToken(address likeAddr, uint amount, uint256 expire) public returns (bool);
    function requestWithdraw(address likeAddr) public returns (bool);
    function withdrawToken(address likeAddr, uint amount) public  returns (bool);
    function getLock(address likeAddr, address _sender) view  public returns (uint256);
    function getWithdraw(address likeAddr, address _sender) view public  returns (uint8);
    function getAmount(address likeAddr, address _sender) view public  returns (uint256);
    function getDepositTime(address likeAddr, address _sender) view public returns (uint256);
    function getActiveLock(address likeAddr) view public returns (uint256);
}
contract ERC20_Interface  {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract LBankInterface {
    function totalLIKE() view public returns (uint256);
}
contract Loan {
    function contractLoans(address _borrower) view public returns (address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint8);
}

contract Ownable {
  address public owner;
  address public waitNewOwner;
    //oracle address for feed total lock and reward this address is oracle
  address public oracleAddress;
  event transferOwner(address newOwner);
  
  function Ownable() public{
      owner = msg.sender;
  }
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }
  
  modifier onlyOracleAddress() {
    require(oracleAddress == msg.sender);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   * and safe new contract new owner will be accept owner
   */
  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      waitNewOwner = newOwner;
    }
  }
  function transferOracleAddress(address newOracle) onlyOwner public {
    if (newOracle != address(0)) {
      oracleAddress = newOracle;
    }
  }
  /**
   * this function accept when transfer to new owner and new owner will be accept owner for safe contract free owner
   */
   
  function acceptOwnership() public {
      if(waitNewOwner == msg.sender) {
          owner = msg.sender;
           transferOwner(msg.sender);
      }else{
          revert();
      }
  }

}

contract Airdrop is Ownable{
   using SafeMath for uint;
   function Airdrop(address oracle) public {
          oracleAddress = oracle;
   }
   enum statusAirdrop {
       EXPIRED,
       START
   }
   struct history {
    uint256 lock;
    uint256 rewards;
   }

    //round for claim
   mapping (address => uint256) public Round;
    //total token locked in smart contract  
   mapping (address => mapping (uint256 => uint256)) public TotalLock;
    //total reward in this round
   mapping (address => mapping (uint256 => uint256)) public TotalRewards;
    //user claim
   mapping (address => mapping (address => claim)) public Claim;
    //check status round
   mapping (address => mapping (uint256 => expire)) public CheckExpire;
   
   mapping (address => uint256) public balanceToken;
   
   mapping (address => mapping (uint256 => uint256)) public balanceOfRound;

   mapping (uint256 => history) public historyRewards;
   

   mapping (uint256 => uint256) public BalanceLBank;
   mapping (uint256 => uint256) public BalanceLPCU;
   
  
   address public loanaddr;
   address public lockaddr;
   address public likeaddr;
   address public lbank;
   address public lpcu;


   event GetRewards(address _addr, address _lock, uint256 round, address sender, uint256 reward);
   event UpdateRewards(address _addr, address lock, uint256 rewards, uint256 round, uint256 expire);
   event AdminWithdrawByRound(address _addr, uint256 _round, uint256 balance);
   event AdminWithdraw(address _addr, uint256 balance);
   struct claim {
       uint256 lastTime;
       uint256 round;
       uint256 nextTime;
       uint256 amount;
   }
   struct expire {
       statusAirdrop status;
       uint256 expire;
       uint256 start;
   }


   
    function initAddress(address _loan, address _lock, address _like, address _lbank, address _lpcu) public onlyOwner {
      loanaddr = _loan;
      lockaddr = _lock;
      likeaddr = _like;
      lbank = _lbank;
      lpcu = _lpcu;
    }
    function changeLoan(address addr) onlyOwner public {
        loanaddr = addr;
    }
    function changeLock(address addr) onlyOwner public {
        lockaddr = addr;
    }
    function changeLike(address addr) onlyOwner public {
        likeaddr = addr;
    }
    function changeLBank(address addr) onlyOwner public {
        lbank = addr;
    }
    function changeLPCU(address addr) onlyOwner public {
        lpcu = addr;
    }

    function getLBank(address _addr, address lock) public view returns (uint256) {
        uint256 activeLock = LockSmartContract(lock).getActiveLock(_addr);
        uint256 LBankLock = LBankInterface(lbank).totalLIKE();
        return activeLock.add(LBankLock);
    }
    function getLBankLock() public view returns (uint256) {
      return LBankInterface(lbank).totalLIKE();
    }
    function getActiveLock(address _addr, address lock) public view returns (uint256) {
      uint256 activeLock = LockSmartContract(lock).getActiveLock(_addr);
      return activeLock;
    }
   //this function update round and reward, locked token by Oracle address
   function updateRewards(address _addr, address lock, uint256 rewards, uint256 _expire) onlyOracleAddress public{
        ERC20_Interface(_addr).transferFrom(msg.sender, address(this), rewards);  
        balanceToken[_addr] = balanceToken[_addr].add(rewards);
       //update round in this token address
        Round[_addr] = Round[_addr].add(1);
        uint256 activeLock = getBalanceLockAll(lock, _addr);

        //set Total Lock in this round
        TotalLock[_addr][Round[_addr]] = activeLock;
        //set Total rewards in this round
        TotalRewards[_addr][Round[_addr]] = rewards;
        balanceOfRound[_addr][Round[_addr]] = rewards;
        uint256 currentTime = now;
        //set expire round in this token
        expire memory setExpire = CheckExpire[_addr][Round[_addr]];
        setExpire.status = statusAirdrop.START;
        setExpire.expire = currentTime.add(_expire);
        setExpire.start = currentTime;
        //save state
        CheckExpire[_addr][Round[_addr]] = setExpire;


        //lbank
		    require(vaultAirdrop(_addr, currentTime, activeLock));
        UpdateRewards(_addr, lock, rewards, Round[_addr], currentTime.add(_expire));
   }

   function vaultAirdrop(address _addr, uint256 currentTime, uint256 activeLock) internal returns (bool) {
   		expire memory setExpire = CheckExpire[_addr][Round[_addr]];
		  uint256 ratio = 0;
      ratio = BalanceLBank[Round[likeaddr]].percent(TotalLock[_addr][Round[_addr]]);
      uint256 reward = ratio.mul(TotalRewards[_addr][Round[_addr]]).div(1000000000);
		  claim memory userClaim = Claim[_addr][lbank];
	    balanceToken[_addr] = balanceToken[_addr].sub(reward);
	    balanceOfRound[_addr][Round[_addr]] = balanceOfRound[_addr][Round[_addr]].sub(reward);
	    ERC20_Interface(_addr).transfer(lbank, reward);    

	    userClaim.lastTime = currentTime;
	    userClaim.round = Round[_addr];
	    userClaim.nextTime = setExpire.expire.add(1);
	    userClaim.amount = reward;
	    Claim[_addr][lbank] = userClaim;	

	    //lpcu
      ratio = BalanceLPCU[Round[likeaddr]].percent(TotalLock[_addr][Round[_addr]]);
      reward = ratio.mul(TotalRewards[_addr][Round[_addr]]).div(1000000000);
		  userClaim = Claim[_addr][lpcu];
	    balanceToken[_addr] = balanceToken[_addr].sub(reward);
	    balanceOfRound[_addr][Round[_addr]] = balanceOfRound[_addr][Round[_addr]].sub(reward);
	    ERC20_Interface(_addr).transfer(lpcu, reward);    

	    userClaim.lastTime = currentTime;
	    userClaim.round = Round[_addr];
	    userClaim.nextTime = setExpire.expire.add(1);
	    userClaim.amount = reward;
	    Claim[_addr][lpcu] = userClaim;	  

      history memory reward_record = historyRewards[Round[_addr]];
      reward_record.lock = activeLock.add(BalanceLPCU[Round[likeaddr]]).add(BalanceLBank[Round[likeaddr]]);
      reward_record.rewards = TotalRewards[_addr][Round[_addr]];
      historyRewards[Round[_addr]] = reward_record;

	    return true; 
   }

   function getAmount(address _borrower) public view returns (uint256) {
    uint256 balanceLocked = LockSmartContract(lockaddr).getAmount(likeaddr, _borrower);
    return balanceLocked;
   }
   function getLoans(address _borrower) public view returns (uint256) {
     uint256 sum;
      (,,,,,,sum,,,,) = Loan(loanaddr).contractLoans(_borrower);
      return sum;
   }
   function getAllBalanceView(address _borrower) public view returns (uint256) {
       uint256 sum;
       uint256 balanceLocked = LockSmartContract(lockaddr).getAmount(likeaddr, _borrower);
       (,,,,,,sum,,,,) = Loan(loanaddr).contractLoans(_borrower);
       return sum.add(balanceLocked);
   }
   function getAllBalance(address _borrower) internal view returns (uint256) {
       uint256 sum;
       uint256 balanceLocked = LockSmartContract(lockaddr).getAmount(likeaddr, _borrower);
       (,,,,,,sum,,,,) = Loan(loanaddr).contractLoans(_borrower);
       return sum.add(balanceLocked);
   }
   function getBalanceLockAll(address lock, address _addr) internal view returns (uint256) {


        uint256 activeLock = LockSmartContract(lock).getActiveLock(_addr);
        uint256 LBankLock = LBankInterface(lbank).totalLIKE();
        uint256 LPCULock = LBankInterface(lpcu).totalLIKE();
        BalanceLBank[Round[_addr]] = LBankLock;
        BalanceLPCU[Round[_addr]] = LPCULock;
        return activeLock.add(LBankLock).add(LPCULock);
   }

   function getRewards(address _addr, address _lock) public returns (bool) {
   	  require (lbank != msg.sender); 
   	  require (lpcu != msg.sender); 
      claim memory userClaim = Claim[_addr][msg.sender];
      expire memory setExpire = CheckExpire[_addr][Round[_addr]];
      uint256 currentTime = now;
      require(userClaim.round < Round[_addr]);
      require(setExpire.start > LockSmartContract(_lock).getDepositTime(_addr, msg.sender));
      
      uint256 ratio = 0;
	    uint256 balanceLocked = getAllBalance(msg.sender);
      ratio = balanceLocked.percent(TotalLock[_addr][Round[_addr]]);
      //calculate ratio
      //calculate rewards
      uint256 reward = ratio.mul(TotalRewards[_addr][Round[_addr]]).div(1000000000);
     
      balanceToken[_addr] = balanceToken[_addr].sub(reward);
      balanceOfRound[_addr][Round[_addr]] = balanceOfRound[_addr][Round[_addr]].sub(reward);
      ERC20_Interface(_addr).transfer(msg.sender, reward);    
        //update state
      userClaim.lastTime = currentTime;
      userClaim.round = Round[_addr];
      userClaim.nextTime = setExpire.expire.add(1);
      userClaim.amount = reward;
      Claim[_addr][msg.sender] = userClaim;
   
       GetRewards(_addr, _lock, Round[_addr], msg.sender, reward);
      return true;
   }
   function checkRewards(address _addr, address _lock, address _checker) public view returns (uint256){
      expire memory setExpire = CheckExpire[_addr][Round[_addr]];
    //   return (setExpire.start, LockSmartContract(_lock).getDepositTime(_addr, _checker));
      
      //calculate ratio
      uint256 ratio = 0;
      if(_checker == lbank) {
        ratio = BalanceLBank[Round[likeaddr]].percent(TotalLock[_addr][Round[_addr]]);
      } else if (_checker == lpcu) {
      	ratio = BalanceLPCU[Round[likeaddr]].percent(TotalLock[_addr][Round[_addr]]);
      }else {
        uint256 balanceLocked = getAllBalance(_checker);
        ratio = balanceLocked.percent(TotalLock[_addr][Round[_addr]]);
      } 
    
      //calculate rewards
      uint256 reward = ratio.mul(TotalRewards[_addr][Round[_addr]]).div(1000000000);
      //check time lock user and system
      
      if(setExpire.start > LockSmartContract(_lock).getDepositTime(_addr, _checker)){
          return reward;
      }else{
          return 0;
      }
      
   }
   
   //admin
   function adminWithdrawByRound(address _addr, uint256 _round) onlyOwner public returns (bool) {
       uint256 balance = balanceOfRound[_addr][_round];
       balanceOfRound[_addr][_round] = balanceOfRound[_addr][_round].sub(balance);
       require(balanceOfRound[_addr][_round] == 0);
       
       ERC20_Interface(_addr).transfer(msg.sender, balance);    
        AdminWithdrawByRound(_addr, _round, balance);
       
   }
   function adminWithdraw(address _addr) onlyOwner public returns (bool) {
       uint256 balance = balanceToken[_addr];
       balanceToken[_addr] = balanceToken[_addr].sub(balance);
       require(balanceToken[_addr] == 0);
       
       ERC20_Interface(_addr).transfer(msg.sender, balance);    
        AdminWithdraw(_addr, balance);
       
   }

   function adminWithdrawToken(address _addr, uint256 amount) onlyOwner public returns (bool) {
    ERC20_Interface(_addr).transfer(msg.sender, amount);
     AdminWithdraw(_addr, amount);
   }
}

