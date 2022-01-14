//SourceUnit: PlanB.sol

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
interface ITRC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event PayEventUsdt(address indexed owner, address indexed spender, uint256 value);
    event PayEventCan(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}
// helper methods for interacting with TRC20 tokens  that do not consistently return true/false
library TransferHelper {
    //TODO: Replace in deloy script
    address constant USDTAddr = 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C;

    function safeApprove(address token, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransfer(address token, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        if (token == USDTAddr) {
            return success;
        }
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }
}
contract Owend {
    address public _owner;

    constructor () internal {
        _owner = msg.sender;
    }
   
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
}
contract PlanB is ITRC20, Owend{
    using SafeMath for uint256;
    using TransferHelper for address;
    ITRC20 _canToken;
    ITRC20 _usdtToken;
    mapping(address => address) public referrals;

    mapping(address => uint256) public _defalutReferrals;
    
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => uint256) private _balances;

    mapping (address => uint256) private _totalConsumption;
    
    address public _platformOutAddress=address(0);

    address public _platformUsdtAddress=address(0);

    address public _platformCanAddress=address(0);


    address public _symbolAddress=address(0);

    address public _usdtAddress=address(0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C);

    address public _canAddress=address(0);


    uint256 private _totalSupply=0;
    string private _name ="PlanB";
    string private _symbol="PlanB";
    uint256 private _decimals = 6;
    uint256 private _rate = 50;
    uint256 private _rewardV1 = 10;
    uint256 private _rewardV2 = 20;
    uint256 private _rewardV3 = 30;
    uint256 private _V1 = 2000*10**6;
    uint256 private _V2 = 5000*10**6;
    uint256 private _V3 = 10000*10**6;
  
    constructor()public{
        _defalutReferrals[msg.sender]=1;
        referrals[msg.sender]=msg.sender;
    }



    function buy(uint256 _payAmount)public{
        require(_platformUsdtAddress!=address(0),"please contract admin setup  platform usdt address");
        require(_platformCanAddress!=address(0),"please contract admin setup  platform can address");
        require(_symbolAddress!=address(0),"please contract admin setup  symbol address");
        require(_usdtAddress!=address(0),"please contract admin setup usdt address");
        require(_canAddress!=address(0),"please contract admin setup can address");
        require(_payAmount>0,"Error: amount must greater zero");
        uint256 _usdtAmount=_usdtToken.balanceOf(_symbolAddress);
        require(_usdtAmount!=0,"Please add liquidity first");
        uint256 _canAmount=_canToken.balanceOf(_symbolAddress);
        require(_canAmount!=0,"Please add liquidity first");
        

        uint256 _payUsdtAmount=_payAmount.mul(_rate).div(100);
        uint256 _payCanAmount=(_payAmount.sub(_payUsdtAmount)).mul(_canAmount).div(_usdtAmount);
        
        address _upAddress = getUpAddress(msg.sender);
        uint256 _reward=0;
        if(_upAddress!=address(0)){
            uint256 _upConsumption =_totalConsumption[_upAddress];
            if(_upConsumption>=_V3){
                _reward=_rewardV3;
            }else if(_upConsumption>=_V2){
                _reward=_rewardV2;
            }else if(_upConsumption>=_V1){
                _reward=_rewardV1;
            }else{
                _reward=0;
            }
        }
        if(_reward!=0){
            uint256 _upRewardAmount=_payUsdtAmount.mul(_reward).div(100);
            _payUsdtAmount=_payUsdtAmount.sub(_upRewardAmount);
            require(address(_usdtToken).safeTransferFrom(msg.sender, _upAddress, _upRewardAmount));
        }

        require(address(_usdtToken).safeTransferFrom(msg.sender, _platformUsdtAddress, _payUsdtAmount));

        require(address(_canToken).safeTransferFrom(msg.sender, _platformCanAddress, _payCanAmount));

        _totalConsumption[msg.sender]=_totalConsumption[msg.sender].add(_payAmount);
        emit PayEventUsdt(msg.sender,_platformUsdtAddress,_payUsdtAmount);
        emit PayEventCan(msg.sender,_platformCanAddress,_payCanAmount);
    }
    
    function activiteAccount(address _upAddress)  public{
        require(referrals[msg.sender]==address(0),"Error: address is activited");
        if(_defalutReferrals[_upAddress]==1){
            referrals[msg.sender]=_upAddress;
        }else{
            require(msg.sender!=_upAddress,"Error: not recommend yourself");
            require(referrals[_upAddress]!=address(0),"Error: upaddress's referrer is null");
            referrals[msg.sender]=_upAddress;
        }
    }
    
    function setDefalutReferrals(address _address) public onlyOwner{
        _defalutReferrals[_address]=1;
        if(referrals[_address]!=address(0)){
            referrals[_address]=_owner;
        }
    }

    function removeDefalutReferrals(address _address) public onlyOwner{
        _defalutReferrals[_address]=0;
    }
    function getUpAddress(address _account) view public returns(address){
        return referrals[_account];
    }
    
    function setRate(uint _r) public onlyOwner{
        require(_r>=0&&_r<=100,"error ");
        _rate=_r;
    }

    function setRewardV(uint256 vRate1,uint256 vRate2,uint256 vRate3) public onlyOwner{
        require(vRate1>=0 && vRate1<=100,"error rate");
        require(vRate2>=0 && vRate2<=100,"error rate");
        require(vRate3>=0 && vRate3<=100,"error rate");
        _rewardV1= vRate1;
        _rewardV2= vRate2;
        _rewardV3= vRate3;
    }

    function setVAmount(uint256 v1,uint256 v2,uint256 v3) public onlyOwner{
        
        _V1= v1;
        _V2= v2;
        _V3= v3;
    }
    

    function setUsdtAddress(address _uAddress) public onlyOwner{
        require(_uAddress!=address(0),"error address is null");
        _usdtAddress=_uAddress;
        _usdtToken=ITRC20(_usdtAddress);
    }
    function setCanAddress(address _cAddress) public onlyOwner{
        require(_cAddress!=address(0),"error  address is null");
        _canAddress=_cAddress;
        _canToken=ITRC20(_canAddress);
    }
    function setOutAddress(address _outAddress) public onlyOwner{
        require(_outAddress!=address(0),"error  address is null");
        _platformOutAddress=_outAddress;
    }
    function setSymbolAddress(address _cAddress) public onlyOwner{
        require(_cAddress!=address(0),"error  address is null");
        _symbolAddress=_cAddress;
    }
    function setPlatFromUsdtAddress(address _address)public onlyOwner{
        require(_address!=address(0),"Error: address is null");
        _platformUsdtAddress=_address;
    }
    function setPlatFromCanAddress(address _address)public onlyOwner{
        require(_address!=address(0),"Error: address is null");
        _platformCanAddress=_address;
    }
   
    function _transfer(address _from,address _to,uint256 _value) private{
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value > 0, "Transfer amount must be greater than zero");
        require(_balances[_from]>=_value,"Balance insufficient");
        _balances[_from] =_balances[_from].sub(_value);
        _balances[_to]=_balances[_to].add(_value);
        emit Transfer(_from,_to,_value);
     } 
     
        
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(amount >0, "ERC20: amount must more than zero ");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

   function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function totalConsumptionOf(address account) public view returns(uint256){
        return _totalConsumption[account];
    }
    function platformIncomeAddress() public view returns(address){
        return _platformOutAddress;
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(amount >0, "ERC20: amount must more than zero ");
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        require(amount >0, "ERC20: amount must more than zero ");
    
        _approve(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(amount >0, "ERC20: amount must more than zero ");
        require(_allowances[sender][msg.sender] >=amount, "transfer amount exceeds allowance ");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "transfer amount exceeds allowance"));
     return true;
    }


             
}