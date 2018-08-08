pragma solidity ^0.4.23;

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
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20FXT {

    using SafeMath for uint256;

    string public name = "ERC20FX Token";
    string public symbol = "ERC20FXT";
    uint8 public decimals = 0;

    uint256 public totalSupply = 10000000 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event Withdraw(address indexed by,uint256 amount);
    event WithdrawlStateChanged(uint8 state, address addr);
    event PaymentCreated(uint amount, address contractAddr, address paidBy, uint paidAt);
    event PaymentUpdated(address contractAddr, address _admin);
    event AccountFrozen(address addr, address indexed by);
    event AccountCleared(address addr, address indexed by);
    event ERC20Moved(address contractAddr, uint256 amount);
    // KYC status value, compressed to uint8
    enum KYCStatus {
        unknown, // 0: Initial status when nothing has been done for the address yet
        cleared, // 1: Address cleared by owner or KYC partner
        frozen // 2: Address frozen by owner or KYC partner
    }
    //
    enum WithdrawlStatus {
        all,
        approved,
        none
    }
    // Payment List
    struct PaymentList {
        uint _amount;
        address _contractAddr;
        address _paidBy;
        uint _paidAt;
    }

    PaymentList[] public payments;

    address public admin;
    uint8 private withdrawlState;

    uint256 public scaling = uint256(10) ** 8;
    uint256 public scaledRemainder = 0;
    uint256 public scaledRewardPerToken;

    mapping(address =>uint8) public addressKYCStatus;
    mapping(address => uint256) public scaledRewardBalanceOf;
    mapping(address => uint256) public scaledRewardCreditedTo;
    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) public balanceOf;

    constructor() public {
      admin = msg.sender;
      withdrawlState = 0;
      // Address KYCStatus
      addressKYCStatus[admin] = uint8(KYCStatus.cleared);
      // Initially assign all  tokens to the contract&#39;s creator.
      balanceOf[msg.sender] = totalSupply;
      emit Transfer(address(0), msg.sender, totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == admin);
        _;
    }

    modifier onlyHolder() {
        require(balanceOf[msg.sender] > 0);
        _;
    }

    function update(address account) internal {
       uint256 owed = scaledRewardPerToken - scaledRewardCreditedTo[account];
       scaledRewardBalanceOf[account] += balanceOf[account] * owed;
       scaledRewardCreditedTo[account] = scaledRewardPerToken;
    }



    function transfer(address to, uint256 value) public returns (bool success) {
      require(balanceOf[msg.sender] >= value);

      update(msg.sender);
      update(to);

      balanceOf[msg.sender] -= value;
      balanceOf[to] += value;

      emit Transfer(msg.sender, to, value);
      return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success)
    {
      require(value <= balanceOf[from]);
      require(value <= allowance[from][msg.sender]);

      update(from);
      update(to);

      balanceOf[from] -= value;
      balanceOf[to] += value;

      allowance[from][msg.sender] -= value;
      emit Transfer(from, to, value);
      return true;
    }

    function() public payable {
      // scale the deposit and add the previous remainder
      uint256 available = (msg.value * scaling) + scaledRemainder;

      scaledRewardPerToken += available / totalSupply;

      // compute the new remainder
      scaledRemainder = available % totalSupply;


    }



    function deposit() public payable {
      // scale the deposit and add the previous remainder
      uint256 available = (msg.value * scaling) + scaledRemainder;

      scaledRewardPerToken += available / totalSupply;

      // compute the new remainder
      scaledRemainder = available % totalSupply;

    }

    function withdraw() public onlyHolder {
      uint8 status = addressKYCStatus[msg.sender];
      // Already frozen
      if(status == uint8(KYCStatus.frozen)) {
        revert();
      }
      // None are allowed to withdraw
      if(withdrawlState == uint8(WithdrawlStatus.none)){
        revert();
      }
      // Only approved users are allowed to withdraw
      if(withdrawlState == uint8(WithdrawlStatus.approved) && status != uint8(KYCStatus.cleared)){
        revert();
      }

      update(msg.sender);
      uint256 amount = scaledRewardBalanceOf[msg.sender] / scaling;
      scaledRewardBalanceOf[msg.sender] %= scaling;  // retain the remainder
      msg.sender.transfer(amount);
      emit Withdraw(msg.sender, amount);
    }

    function approve(address spender, uint256 value) public returns (bool success)
    {
      allowance[msg.sender][spender] = value;
      emit Approval(msg.sender, spender, value);
      return true;
    }

    function pendingRewardsOf(address _addr) constant external returns (uint256) {
      uint256 amount = scaledRewardBalanceOf[_addr];
      return (amount);
    }


    function emergencyERC20Drain(address _contract, uint _amount) public onlyOwner {
      ERC20 token = ERC20(_contract);
      // owner can drain tokens that are sent here by mistake
      token.transfer(msg.sender, _amount);
      emit ERC20Moved(_contract, _amount);
    }


    function depositPayment(address _contractAddr) public payable returns (uint, uint, address, address, uint) {
      uint PaymentId = payments.length++;
      PaymentList storage PaymentData = payments[PaymentId];
      PaymentData._amount = msg.value;
      PaymentData._paidBy = msg.sender;
      PaymentData._paidAt = block.number;
      PaymentData._contractAddr = _contractAddr;
      emit PaymentCreated(PaymentData._amount, PaymentData._contractAddr,PaymentData._paidBy, PaymentData._paidAt);
      return (PaymentId, payments[PaymentId]._amount, payments[PaymentId]._contractAddr, payments[PaymentId]._paidBy, payments[PaymentId]._paidAt);

    }

    function updatePayment(uint PaymentId, address _contractAddr) public onlyOwner {
      PaymentList storage payment = payments[PaymentId];
      payment._contractAddr = _contractAddr;
      emit PaymentUpdated(_contractAddr, msg.sender);
    }

    function getPaymentsCount() constant public returns(uint) {
      uint paymentsNum = payments.length;
      return(paymentsNum);
    }



    function getPayment(uint PaymentId) view public returns ( uint, address, address, uint) {
      return (payments[PaymentId]._amount, payments[PaymentId]._contractAddr, payments[PaymentId]._paidBy, payments[PaymentId]._paidAt);
    }


    function changeAdmin(address newAdmin) public onlyOwner {
      // owner can re-assign the admin
      admin = newAdmin;
      emit AdminTransferred(admin, newAdmin);
    }

    function changeWithdrawState(uint8 status) public onlyOwner {
      require(status <= uint8(WithdrawlStatus.none));
      withdrawlState = status;
      emit WithdrawlStateChanged(withdrawlState, msg.sender);
    }


    function getAddressStatus(address addr) public constant returns (uint8) {
      return uint8(addressKYCStatus[addr]);
    }

    function clearAccount(address addr) public onlyOwner {
      uint8 status = addressKYCStatus[addr];
      // Already frozen
      if(status == uint8(KYCStatus.cleared)) {
        revert();
      }
      addressKYCStatus[addr] = uint8(KYCStatus.cleared);
      emit AccountCleared(addr, msg.sender);
    }


    function freezeAccount(address addr) public onlyOwner {
      uint8 status = addressKYCStatus[addr];
      // Already frozen
      if(status == uint8(KYCStatus.frozen)) {
        revert();
      }

      addressKYCStatus[addr] = uint8(KYCStatus.frozen);
      emit AccountFrozen(addr, msg.sender);
    }

}