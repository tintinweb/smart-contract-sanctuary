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

contract Evoai {
  
  using SafeMath for uint256;
  address public admin; //the admin address
  uint256 public feeETH; // ETH fee value
  uint256 public feeEVOT; //EVOAI fee value
  uint256 public totalEthFee; // total acount ether fee
  uint256 public totalTokenFee; // total account token fee
  address private owner;
  address public tokenEVOT;
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

  function() public {
    revert();
  }
  
  modifier onlyAdmin {
    require(msg.sender == admin);
    _;
  }
  
  // set the EVOT token contract address
  function setTokenAddress(address _token) onlyAdmin() public {
      tokenEVOT = _token;
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

  // change the ether fee
  function changeFeeETH(uint256 feeETH_) onlyAdmin() public {
    feeETH = feeETH_;
  }

  // change the token fee
  function changeFeeEVOT(uint256 feeEVOT_) onlyAdmin() public {
    feeEVOT = feeEVOT_;
  }

  // ether deposit
  function deposit() payable public {
    totalEthFee = totalEthFee.sub(feeETH);
    etherBalance[msg.sender] = (etherBalance[msg.sender]).add(msg.value - feeETH);
    emit Deposit(0, msg.sender, msg.value); // 0 is ether deposit
  }

  // withdraw ether
  function withdraw(uint256 amount) public {
    require(etherBalance[msg.sender] >= amount);
    etherBalance[msg.sender] = etherBalance[msg.sender].sub(amount);
    msg.sender.transfer(amount);
    emit Withdraw(0, msg.sender, amount); // 0 is ether withdraw
  }

  // deposit token
  function depositToken(address token, uint256 amount) public {
    require(tokenEVOT == token);
    //remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
    if (!ERC20(token).transferFrom(msg.sender, this, amount)) revert();
    totalTokenFee = totalTokenFee.add(feeEVOT);
    tokenBalance[msg.sender] = tokenBalance[msg.sender].add(amount - feeEVOT);
    emit Deposit(1, msg.sender, amount); // 1 is token deposit
  }

  // withdraw token
  function withdrawToken(address token, uint256 amount) public {
    require(tokenBalance[msg.sender] >= amount);
    tokenBalance[msg.sender] = tokenBalance[msg.sender].sub(amount);
    if (!ERC20(token).transfer(msg.sender, amount)) revert();
    emit Withdraw(1, msg.sender, amount); // 1 is token withdraw
  }

  // ether transfer
  function transferETH(address _receiver, uint256 amount) public {
    require(etherBalance[msg.sender] >= amount);
    etherBalance[msg.sender] = etherBalance[msg.sender].sub(amount);
    _receiver.transfer(amount);
    emit Transfered(0, msg.sender, amount, msg.sender);
  }

  // transfer token
  function transferToken(address token, address _receiver, uint256 amount) public {
    if (token==0) revert();
    require(tokenBalance[msg.sender] >= amount);
    tokenBalance[msg.sender] = tokenBalance[msg.sender].sub(amount);
    if (!ERC20(token).transfer(_receiver, amount)) revert();
    emit Transfered(1, msg.sender, amount, msg.sender);
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
  function feeWithdrawTokenAmount(address token, uint256 amount) onlyAdmin() public {
    require(totalTokenFee >= amount);
    if (!ERC20(token).transfer(msg.sender, amount)) revert();
    totalTokenFee = totalTokenFee.sub(amount);
  }

  // withdraw all token fee
  function feeWithdrawTokenAll(address token) onlyAdmin() public {
    if (totalTokenFee == 0) revert();
    if (!ERC20(token).transfer(msg.sender, totalTokenFee)) revert();
    totalTokenFee = 0;
  }
  
  // get token contract address
  function getEvotTokenAddress() public constant returns (address) {
    return tokenEVOT;    
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