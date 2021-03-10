/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

// File: contracts/utils/Ownable.sol

pragma solidity >=0.4.21 <0.6.0;

contract Ownable {
    address private _contract_owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _contract_owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _contract_owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_contract_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_contract_owner, newOwner);
        _contract_owner = newOwner;
    }
}

// File: contracts/utils/SafeMath.sol

pragma solidity >=0.4.21 <0.6.0;

library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "add");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "sub");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "mul");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "div");
        c = a / b;
    }
}

// File: contracts/utils/Address.sol

pragma solidity >=0.4.21 <0.6.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: contracts/erc20/IERC20.sol

pragma solidity >=0.4.21 <0.6.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/erc20/SafeERC20.sol

pragma solidity >=0.4.21 <0.6.0;




library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).safeAdd(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).safeSub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/core/HPeriod.sol

pragma solidity >=0.4.21 <0.6.0;


contract HPeriod{
  using SafeMath for uint;

  uint256 period_start_block;
  uint256 period_block_num;
  uint256 period_gap_block;

  struct period_info{
    uint256 period;
    uint256 start_block;
    uint256 end_block;    // [start_block, end_block)
  }

  mapping (uint256 => period_info) all_periods;
  uint256 current_period;

  bool is_gapping;

  constructor(uint256 _start_block, uint256 _period_block_num, uint256 _gap_block_num) public{
    period_start_block = _start_block;
    period_block_num = _period_block_num;

    period_gap_block = _gap_block_num;
    current_period = 0;
    is_gapping = true;
  }

  function _end_current_and_start_new_period() internal returns(bool){
    require(block.number >= period_start_block, "1st period not start yet");

    if(is_gapping){
      if(current_period == 0 || block.number.safeSub(all_periods[current_period].end_block) >= period_gap_block){
        current_period = current_period + 1;
        all_periods[current_period].period = current_period;
        all_periods[current_period].start_block = block.number;
        is_gapping = false;
        return true;
      }
    }else{
      if(block.number.safeSub(all_periods[current_period].start_block) >= period_block_num){
        all_periods[current_period].end_block = block.number;
        is_gapping = true;
      }
    }
    return false;
  }


  event HPeriodChanged(uint256 old, uint256 new_period);
  function _change_period(uint256 _period) internal{
    uint256 old = period_block_num;
    period_block_num = _period;
    emit HPeriodChanged(old, period_block_num);
  }

  function getCurrentPeriodStartBlock() public view returns(uint256){
    (, uint256 s, ) = getPeriodInfo(current_period);
    return s;
  }

  function getPeriodInfo(uint256 period) public view returns(uint256 p, uint256 s, uint256 e){
    p = all_periods[period].period;
    s = all_periods[period].start_block;
    e = all_periods[period].end_block;
  }

  function getParamPeriodStartBlock() public view returns(uint256){
    return period_start_block;
  }

  function getParamPeriodBlockNum() public view returns(uint256){
    return period_block_num;
  }

  function getParamPeriodGapNum() public view returns(uint256){
    return period_gap_block;
  }

  function getCurrentPeriod() public view returns(uint256){
    return current_period;
  }

  function isPeriodEnd(uint256 _period) public view returns(bool){
    return all_periods[_period].end_block != 0;
  }

  function isPeriodStart(uint256 _period) public view returns(bool){
    return all_periods[_period].start_block != 0;
  }

}

// File: contracts/core/HPeriodToken.sol

pragma solidity >=0.4.21 <0.6.0;





contract HTokenFactoryInterface{
  function createFixedRatioToken(address _token_addr, uint256 _period, uint256 _ratio, string memory _postfix) public returns(address);
  function createFloatingToken(address _token_addr, uint256 _period, string memory _postfix) public returns(address);
}

contract HTokenInterface{
  function mint(address addr, uint256 amount)public;
  function burnFrom(address addr, uint256 amount) public;
  uint256 public period_number;
  uint256 public ratio; // 0 is for floating
  uint256 public underlying_balance;
  function setUnderlyingBalance(uint256 _balance) public;
  function setTargetToken(address _target) public;
}

contract HPeriodToken is HPeriod, Ownable{

  struct period_token_info{
    address[] period_tokens;

    mapping(bytes32 => address) hash_to_tokens;
  }

  mapping (uint256 => period_token_info) all_period_tokens;

  HTokenFactoryInterface public token_factory;
  address public target_token;


  constructor(address _target_token, uint256 _start_block, uint256 _period, uint256 _gap, address _factory)
    HPeriod(_start_block, _period, _gap) public{
    target_token = _target_token;
    token_factory = HTokenFactoryInterface(_factory);
  }

  function uint2str(uint256 i) internal pure returns (string memory c) {
    if (i == 0) return "0";
    uint256 j = i;
    uint256 length;
    while (j != 0){
        length++;
        j /= 10;
    }
    bytes memory bstr = new bytes(length);
    uint256 k = length - 1;
    while (i != 0){
      bstr[k--] = byte(48 + uint8(i % 10));
      i /= 10;
    }
    c = string(bstr);
  }

  function getOrCreateToken(uint ratio) public onlyOwner returns(address, bool){

    _end_current_and_start_new_period();

    uint256 p = getCurrentPeriod();
    bytes32 h = keccak256(abi.encodePacked(target_token, getParamPeriodBlockNum(), ratio, p + 1));
    address c = address(0x0);

    period_token_info storage pi = all_period_tokens[p + 1];

    bool s  = false;
    if(pi.hash_to_tokens[h] == address(0x0)){
      if(ratio == 0){
        c = token_factory.createFloatingToken(target_token, p + 1, uint2str(getParamPeriodBlockNum()));
      }
      else{
        c = token_factory.createFixedRatioToken(target_token, p + 1, ratio, uint2str(getParamPeriodBlockNum()));
      }
      HTokenInterface(c).setTargetToken(target_token);
      Ownable ow = Ownable(c);
      ow.transferOwnership(owner());
      pi.period_tokens.push(c);
      pi.hash_to_tokens[h] = c;
      s = true;
    }
    c = pi.hash_to_tokens[h];

    return(c, s);
  }

  function updatePeriodStatus() public onlyOwner returns(bool){
    return _end_current_and_start_new_period();
  }

  function isPeriodTokenValid(address _token_addr) public view returns(bool){
    HTokenInterface hti = HTokenInterface(_token_addr);
    bytes32 h = keccak256(abi.encodePacked(target_token, getParamPeriodBlockNum(), hti.ratio(), hti.period_number()));
    period_token_info storage pi = all_period_tokens[hti.period_number()];
    if(pi.hash_to_tokens[h] == _token_addr){
      return true;
    }
    return false;
  }

  function totalAtPeriodWithRatio(uint256 _period, uint256 _ratio) public view returns(uint256) {
    bytes32 h = keccak256(abi.encodePacked(target_token, getParamPeriodBlockNum(), _ratio, _period));
    period_token_info storage pi = all_period_tokens[_period];
    address c = pi.hash_to_tokens[h];
    if(c == address(0x0)) return 0;

    IERC20 e = IERC20(c);
    return e.totalSupply();
  }

  function htokenAtPeriodWithRatio(uint256 _period, uint256 _ratio) public view returns(address){
    bytes32 h = keccak256(abi.encodePacked(target_token, getParamPeriodBlockNum(), _ratio, _period));
    period_token_info storage pi = all_period_tokens[_period];
    address c = pi.hash_to_tokens[h];
    return c;
  }
}

contract HPeriodTokenFactory{

  event NewPeriodToken(address addr);
  function createPeriodToken(address _target_token, uint256 _start_block, uint256 _period, uint256 _gap, address _token_factory) public returns(address){
    HPeriodToken pt = new HPeriodToken(_target_token, _start_block, _period, _gap, _token_factory);

    pt.transferOwnership(msg.sender);
    emit NewPeriodToken(address(pt));
    return address(pt);
  }

}