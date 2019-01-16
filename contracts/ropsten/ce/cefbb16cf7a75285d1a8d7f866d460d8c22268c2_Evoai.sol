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

// Evabot interface
contract Evabot {
    function increasePendingTokenBalance(address _user, uint256 _amount) public;
}

// Evotexchange interface
contract EvotExchange {
    function increaseEthBalance(address _user, uint256 _amount) public;
    function increaseTokenBalance(address _user, uint256 _amount) public;
}

// wallet contract
contract Evoai {
  
  using SafeMath for uint256;
  address private admin; //the admin address
  address private evabot_contract; //evabot contract address
  address private exchange_contract; //exchange contract address
  address private tokenEVOT; // EVOT contract
  uint256 public feeETH; // ETH fee value
  uint256 public feeEVOT; //EVOAI fee value
  uint256 public totalEthFee; // total acount ether fee
  uint256 public totalTokenFee; // total account token fee
  mapping (address => uint256) public tokenBalance; //mapping of token address
  mapping (address => uint256) public etherBalance; //mapping of ether address
  
  //events
  event Deposit(uint256 types, address user, uint256 amount); // type 0 is ether, 1 is token
  event Withdraw(uint256 types, address user, uint256 amount); // type 0 is ether, 1 is token
  event Transfered(uint256 types, address _from, uint256 amount, address _to);// type 0 is ether, 1 is token
  
  // constructor
  constructor() public {
    admin = msg.sender;
    totalEthFee = 0; // init with zero (contract fee)
    totalTokenFee = 0; // init the token fee
  }

  modifier onlyAdmin {
    require(msg.sender == admin);
    _;
  }
  
  // set the EVOT token contract address
  function setTokenAddress(address _token) onlyAdmin() public {
      tokenEVOT = _token;
  }
  
  // set evabot contract address to interact with that
  function setEvabotContractAddress(address _token) onlyAdmin() public {
      evabot_contract = _token;
  }
  
  // set evabot contract address to interact with that
  function setExchangeContractAddress(address _token) onlyAdmin() public {
      exchange_contract = _token;
  }
  
  // set initial fee
  function setETHFee(uint256 amount) onlyAdmin() public {
    feeETH = amount;
  }
  
  // set initial token fee
  function setTokenFee(uint256 amount) onlyAdmin() public {
    feeEVOT = amount;
  }
  
  //change the admin account
  function changeAdmin(address admin_) onlyAdmin() public {
    admin = admin_;
  }

  // ether deposit
  function deposit() payable public {
    totalEthFee = totalEthFee.add(feeETH);
    etherBalance[msg.sender] = (etherBalance[msg.sender]).add(msg.value.sub(feeETH));
    emit Deposit(0, msg.sender, msg.value); // 0 is ether deposit
  }

  function() payable public {
      
  }
  
  // withdraw ether
  function withdraw(uint256 amount) public {
    require(etherBalance[msg.sender] >= amount);
    etherBalance[msg.sender] = etherBalance[msg.sender].sub(amount);
    msg.sender.transfer(amount);
    emit Withdraw(0, msg.sender, amount); // 0 is ether withdraw
  }

  // deposit token
  function depositToken(uint256 amount) public {
    //remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
    if (!ERC20(tokenEVOT).transferFrom(msg.sender, this, amount)) revert();
    totalTokenFee = totalTokenFee.add(feeEVOT);
    tokenBalance[msg.sender] = tokenBalance[msg.sender].add(amount.sub(feeEVOT));
    emit Deposit(1, msg.sender, amount); // 1 is token deposit
  }

  // withdraw token
  function withdrawToken(uint256 amount) public {
    require(tokenBalance[msg.sender] >= amount);
    tokenBalance[msg.sender] = tokenBalance[msg.sender].sub(amount);
    if (!ERC20(tokenEVOT).transfer(msg.sender, amount)) revert();
    emit Withdraw(1, msg.sender, amount); // 1 is token withdraw
  }

  // ether transfer
  function transferETH(uint256 amount) public {
    require(etherBalance[msg.sender] >= amount);
    etherBalance[msg.sender] = etherBalance[msg.sender].sub(amount);
    exchange_contract.transfer(amount);
    EvotExchange(exchange_contract).increaseEthBalance(msg.sender, amount);
    emit Transfered(0, msg.sender, amount, msg.sender);
  }

  // transfer token
  function transferToken(address _receiver, uint256 amount) public {
    if (tokenEVOT==0) revert();
    require(tokenBalance[msg.sender] >= amount);
    tokenBalance[msg.sender] = tokenBalance[msg.sender].sub(amount);
    if (!ERC20(tokenEVOT).transfer(_receiver, amount)) revert();
    if (_receiver == evabot_contract)
        Evabot(evabot_contract).increasePendingTokenBalance(msg.sender, amount);
    if (_receiver == exchange_contract)
        EvotExchange(exchange_contract).increaseTokenBalance(msg.sender, amount);
    emit Transfered(1, msg.sender, amount, msg.sender);
  }
  
  // received ether from evabot_contract
  function recevedEthFromEvabot(address _user, uint256 _amount) public {
    require(msg.sender == evabot_contract);
    etherBalance[_user] = etherBalance[_user].add(_amount);
  }
  
  // received token from evabot_contract
  function recevedTokenFromEvabot(address _user, uint256 _amount) public {
    require(msg.sender == evabot_contract);
    tokenBalance[_user] = tokenBalance[_user].add(_amount);
  }
  
  // received ether from exchange contract
  function recevedEthFromExchange(address _user, uint256 _amount) public {
    require(msg.sender == exchange_contract);
    etherBalance[_user] = etherBalance[_user].add(_amount);
  }
  
  // withdraw ether fee
  function feeWithdrawEthAmount(uint256 amount) onlyAdmin() public {
    require(totalEthFee >= amount);
    totalEthFee = totalEthFee.sub(amount);
    msg.sender.transfer(amount);
  }

  // withrawall ether fee.
  function feeWithdrawEthAll() onlyAdmin() public {
    if (totalEthFee == 0) revert();
    totalEthFee = 0;
    msg.sender.transfer(totalEthFee);
  }

  // withdraw token fee
  function feeWithdrawTokenAmount(uint256 amount) onlyAdmin() public {
    require(totalTokenFee >= amount);
    if (!ERC20(tokenEVOT).transfer(msg.sender, amount)) revert();
    totalTokenFee = totalTokenFee.sub(amount);
  }

  // withdraw all token fee
  function feeWithdrawTokenAll() onlyAdmin() public {
    if (totalTokenFee == 0) revert();
    if (!ERC20(tokenEVOT).transfer(msg.sender, totalTokenFee)) revert();
    totalTokenFee = 0;
  }
  
  // withraw all ether on the contract
  function withrawAllEthOnContract() onlyAdmin() public {
    msg.sender.transfer(address(this).balance);
  }
  
  // withrawall token on the contract
  function withdrawAllTokensOnContract(uint256 _balance) onlyAdmin() public {
    if (!ERC20(tokenEVOT).transfer(msg.sender, _balance)) revert();
  }

  // get token contract address
  function getEvotTokenAddress() public constant returns (address) {
    return tokenEVOT;    
  }
  
  // get evabot contract
  function getEvabotContractAddress() public constant returns (address) {
    return evabot_contract;
  }
  
  // get exchange contract
  function getExchangeContractAddress() public constant returns (address) {
    return exchange_contract;
  }
  
  // get token balance by user address
  function balanceOfToken(address user) public constant returns (uint256) {
    return tokenBalance[user];
  }

  // get ether balance by user address
  function balanceOfETH(address user) public constant returns (uint256) {
    return etherBalance[user];
  }

  // get ether contract fee
  function balanceOfContractFeeEth() public constant returns (uint256) {
    return totalEthFee;
  }

  // get token contract fee
  function balanceOfContractFeeToken() public constant returns (uint256) {
    return totalTokenFee;
  }
  
  // get current ETH fee
  function getCurrentEthFee() public constant returns (uint256) {
      return feeETH;
  }
  
  // get current token fee
  function getCurrentTokenFee() public constant returns (uint256) {
      return feeEVOT;
  }
}