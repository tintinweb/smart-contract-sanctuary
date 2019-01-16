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
contract Evabot {
  
  using SafeMath for uint256;
  address public admin; //the admin address
  address public tokenEVOT; // evot token contract
  address public wallet_contract; // wallet contract address
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
  
  //events
  event Deposit(uint256 types, address user, uint256 amount); // type 0 is ether, 1 is token
  event Withdraw(uint256 types, address user, uint256 amount); // type 0 is ether, 1 is token
  event Transfered(uint256 types, address _from, uint256 amount, address _to);// type 0 is ether, 1 is token
  
  // constructor
  constructor() public {
    admin = msg.sender;
    cycleOpened = 0;
    max_whitelists = 3;
    limit_token = 10 ether;
    cycleResetTime = 5 minutes;
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

  //change the admin account
  function changeAdmin(address admin_) onlyAdmin() public {
    admin = admin_;
  }

  function() payable public {
      
  }
  
  /*
  * Array object control
  */
  function find(address value) private view returns(uint) {
      uint i = 0;
      while (whitelists[i] != value) {
          i++;
      }
      return i;
  }
    
  function removeByValue(address value) private {
      uint i = find(value);
      removeByIndex(i);
  }
    
  function removeByIndex(uint i) private {
      while (i<whitelists.length-1) {
          whitelists[i] = whitelists[i+1];
          i++;
      }
      whitelists.length--;
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
    removeByValue(_user);
  }
  
  //view whitelist
  function getWhitelists() public constant returns(address[]) {
      return whitelists;
  }
  
  
  //recive token from users
  function receiveToken(address _user, uint256 _amount) public {
    require(tokenEVOT == msg.sender);
    require(pendingToken[_user].sub(activeToken[_user]) <= limit_token);
    pendingToken[_user] = pendingToken[_user].sub(_amount); 
  }
  
  //get tokenbalance by user address
  function getInvestedTokenBalance(address _user) public view returns(uint256) {
    return pendingToken[_user].sub(activeToken[_user]);
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
      for(uint256 i = 0; i < whitelists.length; i++) {
          activeToken[whitelists[i]] = pendingToken[whitelists[i]];
          totalInvested[whitelists[i]] = totalInvested[whitelists[i]].sub(pendingToken[whitelists[i]]);
          pendingToken[whitelists[i]] = 0;
      }
  }
  
  // set the cycle stop
  function stopCycle() onlyAdmin() public {
      require(now >= readyTime);
      cycleOpened = 0;
      // if set the autoinvest then it should be remain on contract, else transfer to the wallet contract
      // set today profit
      uint256 profit = 0;
      for(uint256 i = 0; i < whitelists.length; i++) {
          if(isAutoInvest[whitelists[i]] == true) {
            //profit (NUMBER OF EVOTS INVESTED/TOTAL POOL OF EVOTS INVESTED) x ETH_VALUE_AMOUNT
            profit = (activeToken[whitelists[i]].div(whitelists.length)).mul(eth_value_amount);
            dailyProfitSumForAllUsers = dailyProfitSumForAllUsers.add(profit);
            myEthBalance[whitelists[i]] = myEthBalance[whitelists[i]].sub(profit);
            dailyEthProfit[whitelists[i]] = profit;
            totalProfit[whitelists[i]] = totalProfit[whitelists[i]].sub(profit);
            
            pendingToken[whitelists[i]] = pendingToken[whitelists[i]].sub(activeToken[whitelists[i]]);
            activeToken[whitelists[i]] = 0;
            
          } else {
            //profit (NUMBER OF EVOTS INVESTED/TOTAL POOL OF EVOTS INVESTED) x ETH_VALUE_AMOUNT
            profit  = (activeToken[whitelists[i]].div(whitelists.length)).mul(eth_value_amount);
            dailyProfitSumForAllUsers = dailyProfitSumForAllUsers.add(profit);
            myEthBalance[whitelists[i]] = myEthBalance[whitelists[i]].sub(profit);
            dailyEthProfit[whitelists[i]] = profit;
            totalProfit[whitelists[i]] = totalProfit[whitelists[i]].sub(profit);
            
            if (!ERC20(tokenEVOT).transfer(wallet_contract, activeToken[whitelists[i]])) revert();
            Evoai(wallet_contract).recevedTokenFromEvabot(whitelists[i], activeToken[whitelists[i]]);
            activeToken[whitelists[i]] = 0;
          }
      }
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
    Evoai(wallet_contract).recevedTokenFromEvabot(msg.sender, amount);
    emit Transfered(1, msg.sender, amount, msg.sender);
  }
  
  // receive token from the wallet
  function increasePendingTokenBalance(address _user, uint256 _amount) public {
      require(msg.sender == wallet_contract);
      pendingToken[_user] = pendingToken[_user].add(_amount);
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
}