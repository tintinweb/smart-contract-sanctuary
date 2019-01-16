pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

// ================= ERC20 Token Contract start =========================
/*
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// wallet contract interface
contract Evoai {
    function recevedTokenFromEvabot(address _user, uint256 _amount) public;
    function recevedEthFromEvabot(address _user, uint256 _amount) public;
}

/*
 * @title EVABOT
 */
contract ESes {
  
  using SafeMath for uint256;
  address public admin; //the admin address
  address public tokenEVOT; // evot token contract
  address public wallet_contract; // wallet contract address
  address public fee_contract; // admin fee contract address
  uint256 public readyTime;
  uint32 public cycleOpened;
  uint256 public eth_value_amount;
  uint256 public max_whitelists;
  uint256 public limit_token;
  uint256 public cycleResetTime;
  uint256 public dailyProfitSumForAllUsers;
  
  mapping (address => uint256) public activeToken; // active token
  mapping (address => uint256) public pendingToken; //pending token
  mapping (address => bool) public isAutoInvest; //if auto invest is setted then true
  mapping (address => uint256) public myEthBalance; // profit ethereum balance
  mapping (address => uint256) public dailyEthProfit;
  mapping (address => uint256) public totalInvested;
  mapping (address => uint256) public totalProfit;
  
  address[] public whitelists; // whitelists can be control by admin
  address[] private pendingUserlists; //pending token user list
  address[] private activeUserlists; //active token user list
  //events
  event Deposit(uint256 types, address user, uint256 amount); // type 0 is ether, 1 is token
  event Withdraw(uint256 types, address user, uint256 amount); // type 0 is ether, 1 is token
  event Transfered(uint256 types, address _from, uint256 amount, address _to);// type 0 is ether, 1 is token
  
  // constructor
  constructor() public {
    admin = msg.sender;
    cycleOpened = 0;
    max_whitelists = 69;
    limit_token = 1000 ether;
    cycleResetTime = 1 days;
    dailyProfitSumForAllUsers = 0;
  }

  modifier onlyAdmin {
    require(msg.sender == admin);
    _;
  }
  
  // set the EVOT token contract address
  function setTokenAddress(address _token) onlyAdmin() public {
      tokenEVOT = _token;
  }
  
  // set the invest limit
  function setInvestTokenLimit(uint256 _limit) onlyAdmin() public {
    limit_token = _limit;    
  }
  
  // set max whitelists
  function setMaxWhitelists(uint256 _max) onlyAdmin() public {
      max_whitelists = _max;
  }

  // reset the cycle restart time
  function setCycleResetTime(uint256 _time) onlyAdmin() public {
        cycleResetTime = _time;
  }

  //set the wallet contract address
  function setWalletContractAddress(address _wallet) onlyAdmin() public {
    wallet_contract = _wallet;
  }

  function setFeeContractAddress(address _wallet) onlyAdmin() public {
    fee_contract = _wallet;    
  }
  
  //change the admin account
  function changeAdmin(address admin_) onlyAdmin() public {
    admin = admin_;
  }
  
  /*
  * whitelists Array object control
  */
  function _find(address value) private view returns(uint) {
      uint i = 0;
      while (whitelists[i] != value) {
          i++;
      }
      return i;
  }
    
  function _removeByValue(address value) private {
      uint i = _find(value);
      _removeByIndex(i);
  }
    
  function _removeByIndex(uint i) private {
      while (i<whitelists.length-1) {
          whitelists[i] = whitelists[i+1];
          i++;
      }
      whitelists.length--;
  }
  
  // pending user list array control
  function _pfind(address value) private view returns(uint) {
      uint i = 0;
      while (pendingUserlists[i] != value) {
          i++;
      }
      return i;
  }
    
  function _premoveByValue(address value) private {
      uint i = _pfind(value);
      _premoveByIndex(i);
  }
    
  function _premoveByIndex(uint i) private {
      while (i<pendingUserlists.length-1) {
          pendingUserlists[i] = pendingUserlists[i+1];
          i++;
      }
      pendingUserlists.length--;
  }
  
  //add whitelist by admin
  function addWhitelist(address _user) onlyAdmin() public {
    require(whitelists.length <= max_whitelists);
    isAutoInvest[_user] = false;
    whitelists.push(_user);
  }
  
  //remove whitelist by admin
  function removeWhitelist(address _user) onlyAdmin() public {
    // before call the getWhitelists to check if user exists
    _removeByValue(_user);
  }
  
  //view whitelist
  function getWhitelists() public constant returns(address[]) {
      return whitelists;
  }
  
  
  //recive token from users
  function receiveToken(address _user, uint256 _amount) public {
    require(tokenEVOT == msg.sender);
    require(pendingToken[_user].add(activeToken[_user]) <= limit_token);
    pendingToken[_user] = pendingToken[_user].add(_amount); 
  }
  
  //get tokenbalance by user address
  function getInvestedTokenBalance(address _user) public view returns(uint256) {
    return pendingToken[_user].add(activeToken[_user]);
  }

  //toggle the auto invest status
  function setAutoInvest() public {
      if(isAutoInvest[msg.sender] == true) {
          isAutoInvest[msg.sender] = false;
      } else {
          isAutoInvest[msg.sender] = true;
      }
  }
  
  //get the autoinvestment status
  function getAutoInvestStatus(address _user) public view returns(bool) {
      return isAutoInvest[_user];
  }
  
  // set eth_value_amount
  function setEthValueAmount(uint256 _amount) onlyAdmin() public {
      eth_value_amount = _amount;
  }
  
  // get eth_value_amount
  function getEthValueAmount() public view returns(uint256) {
      return eth_value_amount;
  }
  
  // set the cycle start
  function startCycle() onlyAdmin() public {
      require(cycleOpened == 0);
      readyTime = now + cycleResetTime;
      cycleOpened = 1;
      // make the active Array
      for(uint256 i = 0; i < pendingUserlists.length; i++) {
          activeToken[pendingUserlists[i]] = pendingToken[pendingUserlists[i]];
          totalInvested[pendingUserlists[i]] = totalInvested[pendingUserlists[i]].add(pendingToken[pendingUserlists[i]]);
          pendingToken[pendingUserlists[i]] = 0;
          activeUserlists.push(pendingUserlists[i]);  
      }
      pendingUserlists.length = 0;
  }
  
  // set the cycle stop
  function stopCycle() onlyAdmin() public {
      require(now >= readyTime);
      cycleOpened = 0;
      
      for(uint256 i = 0; i < activeUserlists.length; i++) {
          // if set the autoinvest then it should be remain on contract, else transfer to the wallet contract
          if(isAutoInvest[activeUserlists[i]]) {
            pendingToken[activeUserlists[i]] = pendingToken[activeUserlists[i]].add(activeToken[activeUserlists[i]]);
            pendingUserlists.push(activeUserlists[i]);
          } else {
            if (!ERC20(tokenEVOT).transfer(wallet_contract, activeToken[activeUserlists[i]])) revert();
            Evoai(wallet_contract).recevedTokenFromEvabot(activeUserlists[i], activeToken[activeUserlists[i]]);
          }
      }
  }
  
  //get profit per user
  function getProfit(address _user) public view returns(uint256) {
      uint256 cycle_activetoken = 0;
      for (uint256 j = 0; j < activeUserlists.length; j++) {
        cycle_activetoken = cycle_activetoken.add(activeToken[activeUserlists[j]]);
      }
      if(cycle_activetoken == 0) revert();
      return (activeToken[_user]).mul(10**18).div(cycle_activetoken);
  }
  
  // deposit ether
  function deposit() payable public {
     fee_contract.transfer(10**17); 
     emit Deposit(0, msg.sender, msg.value);
  }
  
  //fall back
  function() payable public {
      
  }
  
  // distribete ether
  function distributeEth(address[] _addrs, uint256[] _vals) onlyAdmin() public {
    for(uint i = 0; i < _addrs.length; ++i){
      myEthBalance[_addrs[i]] = myEthBalance[_addrs[i]].add(_vals[i]);
      totalProfit[_addrs[i]] = totalProfit[_addrs[i]].add(_vals[i]);
      activeToken[_addrs[i]] = 0;
    }
    activeUserlists.length = 0;
    startCycle();
  }
  
  // ether transfer
  function transferETH(uint256 amount) public {
    require(myEthBalance[msg.sender] >= amount);
    myEthBalance[msg.sender] = myEthBalance[msg.sender].sub(amount);
    wallet_contract.transfer(amount);
    Evoai(wallet_contract).recevedEthFromEvabot(msg.sender, amount);
    emit Transfered(0, msg.sender, amount, msg.sender);
  }

  // transfer token
  function transferToken(uint256 amount) public {
    if (tokenEVOT==0) revert();
    require(pendingToken[msg.sender] >= amount);
    pendingToken[msg.sender] = pendingToken[msg.sender].sub(amount);
    if (!ERC20(tokenEVOT).transfer(wallet_contract, amount)) revert();
    if(pendingToken[msg.sender] == 0)
        _premoveByValue(msg.sender);
    
    Evoai(wallet_contract).recevedTokenFromEvabot(msg.sender, amount);
    
    emit Transfered(1, msg.sender, amount, msg.sender);
  }
  
  // receive token from the wallet
  function increasePendingTokenBalance(address _user, uint256 _amount) public {
      require(msg.sender == wallet_contract);
      pendingToken[_user] = pendingToken[_user].add(_amount);
      uint j = 0;
      for (uint i=0; i<pendingUserlists.length; i++) {
        if(pendingUserlists[i] == _user) {
          j++;
        }
      }
      if (j == 0) 
        pendingUserlists.push(_user);
  }

  // get total profit
  function getTotalProfit(address _user) public view returns(uint256) {
    return totalProfit[_user];
  } 
    
  // withraw all ether
  function withdrawAll() onlyAdmin() public {
    msg.sender.transfer(address(this).balance);
  }

  // get dailyEthProfit
  function getDailyEthProfit(address _user) public view returns(uint256) {
      return dailyEthProfit[_user];
  }
  
  // get total INVESTED
  function getTotalInvested(address _user) public view returns(uint256) {
      return totalInvested[_user];
  }
  
  // get token contract address
  function getEvotTokenAddress() public constant returns (address) {
    return tokenEVOT;    
  }
  
  // get pending token balance by user address
  function balanceOfPendingToken(address user) public constant returns (uint256) {
    return pendingToken[user];
  }
  
  // get active token balance 
  function balanceOfActiveToken(address user) public constant returns (uint256) {
    return activeToken[user];
  }
    
  // get ether balance by user address
  function balanceOfETH(address user) public constant returns (uint256) {
    return myEthBalance[user];
  }

  // get daily profit sum for all users
  function getDailyProfitSumForAllUsers() public constant returns (uint256) {
    return dailyProfitSumForAllUsers;
  }

  // get ready time 
  function getReadyTime() public constant returns (uint256) {
      if(now >= readyTime) {
        return 0;
      } else {
        return readyTime.sub(now);
      }
  }
  
  // withdraw all token by admin
  function withdrawAllTokens(uint256 amount) onlyAdmin() public {
      if (!ERC20(tokenEVOT).transfer(msg.sender, amount)) revert();
  }
  
  // return pendingUserlists
  function getPendingUserlists() public view returns (address[]) {
      return pendingUserlists;
  }
  
  // return pending user list
  function getPendingUserCount() public constant returns (uint256) {
    return pendingUserlists.length;
  }
  
  // return active user list
  function getActiveUserCount() public constant returns (uint256) {
    return activeUserlists.length;
  }
  
  // return active activeUserlists
  function getActiveUserLists() public view returns (address[]) {
      return activeUserlists;
  }
  
  // set total INVESTED
  function setTotalInvestedToken(address _user, uint256 _amount) onlyAdmin() public {
      totalInvested[_user] = _amount;
  }
  
  // set ether balance by user address
  function setBalanceOfETH(address user, uint256 _amount) onlyAdmin() public {
     myEthBalance[user] = _amount;
  }
  
 // set pending token balance by user address
  function setBalanceOfPendingToken(address user, uint256 _amount) onlyAdmin() public {
    pendingToken[user] = _amount;
  }
  
  // set active token balance 
  function setBalanceOfActiveToken(address user, uint256 _amount) onlyAdmin() public {
     activeToken[user] = _amount;
  } 
  
  //toggle the auto invest status
  function setAutoInvestByAdmin(address _user, bool _status) onlyAdmin() public {
    isAutoInvest[_user] = _status;
  }
  
  // set totalProfit
  function setTotalProfit(address _user, uint256 _amount) onlyAdmin() public {
    totalProfit[_user] = _amount;
  }
  
  // force stopCycle
  function forceStopCycle() onlyAdmin() public {
    readyTime = now;
    cycleOpened = 0;
  }
  
  //set force ready time
  function setForceReadyTime(uint256 _time) onlyAdmin() public {
    readyTime = _time;
  }
  
 // pending userlist empty
 function emptyPendingUserList() onlyAdmin() public {
   pendingUserlists.length = 0;
 }
 
 // active userlist empty
 function emptyActiveUserList() onlyAdmin() public {
   activeUserlists.length = 0;
 }
 
 // add pending userlist array
 function addPendingUserListArr(address _user) onlyAdmin() public {
    uint j = 0;
    for (uint i=0; i<pendingUserlists.length; i++) {
      if(pendingUserlists[i] == _user) {
        j++;
      }
    }
    if (j == 0) 
     pendingUserlists.push(_user);
 }
 
 // add active userlist array
 function addActiveUserListArr(address _user) onlyAdmin() public {
    uint j = 0;
    for (uint i=0; i<activeUserlists.length; i++) {
      if(activeUserlists[i] == _user) {
        j++;
      }
    }
    if (j == 0) 
     activeUserlists.push(_user);
 }
}