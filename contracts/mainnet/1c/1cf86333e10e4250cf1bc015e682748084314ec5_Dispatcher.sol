/**
 *Submitted for verification at Etherscan.io on 2020-11-20
*/

pragma solidity 0.6.10;
// Example Code here
// https://ropsten.etherscan.io/address/0x1578ad1d20bec0b356e2002f218468650b084b05#code

interface IERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract Dispatcher {
  using SafeMath for uint256;

  IERC20 public token;
  address payable public wallet;
  uint256 public rate = 1469;
  uint256 public startRate= 1469;
  uint256 public trxnCount;
  uint256 public weiRaised;
  uint256 public minContribution =0.007 ether;
  uint256 public maxContribution =1 ether;
  bool lock;
  event Bought(uint256 amount);
  event Transfer(address _to, uint256 amount);
  event TransferMultiple(address[] _receivers, uint256 amount);
  event TotalBalance(address sender,uint256 vlue,uint256 balance);

  modifier onlyOwner{
      require(msg.sender==wallet);
      _;
  }
  constructor(IERC20 _token) public {
  
    token =_token;
  
    wallet = msg.sender;
    
  }

  receive() external payable {
    require(msg.value >= minContribution && msg.value <= maxContribution, "contribution out of range");
    (bool success,) = wallet.call{value:msg.value}(abi.encodeWithSignature("nonExistingFunction()"));
    require(success, "can not transfer funds");
    weiRaised.add(msg.value);
    buy(msg.sender);
  }

function buy(address _buyer) payable public {
    require(!lock);
    lock = true;
    uint256 weiAmount = msg.value;
    uint256 amountTobuy = weiAmount.mul(rate);
    uint256 dexBalance = token.balanceOf(address(this));
    require(amountTobuy > 0, "You need to send some ether");
    require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
    token.transfer(_buyer, amountTobuy);
    emit Bought(amountTobuy);
    trxnCount++;
    increaseRate();
    lock=false;
}

function setRate(uint256 _rate, uint256 _startRate) public onlyOwner returns(uint256, uint256){
    rate =_rate;
    startRate =_startRate;
    return (rate, startRate);
}
function setContributionRange(uint256 _min, uint256 _max) public onlyOwner returns(uint256, uint256){
    minContribution =_min;
    maxContribution =_max;
    return (minContribution, maxContribution);
}
  
  function withdrawEth() public onlyOwner{
      uint256 balance = address(this).balance;
    (bool success,)= wallet.call{value: balance}("");
    require(success);
  }
  
   function depositEther(uint _amount) public payable {
     _amount =msg.value;
     address(this).balance+ msg.value;
     emit TotalBalance(msg.sender, msg.value, address(this).balance);
 } 
  
  
  function getEthTokenBal() public view returns(uint256, uint256) {
      return ( address(this).balance, token.balanceOf(address(this)));
  }
  
  function withdrawToken() public onlyOwner{
      uint256 bal=token.balanceOf(address(this));
      token.transfer(wallet, bal);
      emit Transfer(wallet, bal);
  }
  
  function increaseRate() internal returns(uint256 ){
      uint256 incrs = startRate.div(10);
      trxnCount.mod(250)==0?rate = rate.sub(incrs): rate;
  }
  
  function setToken(address _token)public onlyOwner{
      require(token.balanceOf(address(this))==0, "withdraw tokens");
      token= IERC20(_token);
  }
  
  function burn()public onlyOwner{
       uint256 bal=token.balanceOf(address(this));
      token.transfer(address(0), bal);
      emit Transfer(address(0), bal);
  }
  
  function sendTokenToMany(address payable[] memory _receivers, uint256 amounteach) public onlyOwner {
      uint256 len = _receivers.length;
      for(uint256 i = 0; i<len; i++){
          require(_receivers[i] != address(0), "cannot credit zero acct");
          uint256 total = amounteach.mul(len);
          uint256 available = token.balanceOf(address(this));
          require(total<=available, "Not enough tokens in the reserve" );
          token.transfer(_receivers[i], amounteach);
          
      }
  }
  
  function sendEtherToMany(address payable[] memory _receivers, uint256 amounteach) public onlyOwner {
      uint256 len = _receivers.length;
      for(uint256 i = 0; i<len; i++){
          require(_receivers[i] != address(0), "cannot credit zero acct");
          uint256 total = amounteach.mul(len);
          uint256 available = address(this).balance;
          require(total<=available, "Not enough tokens in the reserve" );
          _receivers[i].transfer(amounteach);
    
      }
  }
}