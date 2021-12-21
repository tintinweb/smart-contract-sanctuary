/**
 *Submitted for verification at Etherscan.io on 2021-12-21
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

// File: contracts/utils/SafeMath.sol

pragma solidity >=0.4.21 <0.6.0;

library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "add");
    }
    function safeSubR(uint a, uint b, string memory s) public pure returns (uint c) {
        require(b <= a, s);
        c = a - b;
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
    function safeDivR(uint a, uint b, string memory s) public pure returns (uint c) {
        require(b > 0, s);
        c = a / b;
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

// File: contracts/core/IPool.sol

pragma solidity >=0.4.21 <0.6.0;

contract ICurvePool{
  function deposit(uint256 _amount) public;
  function withdraw(uint256 _amount) public;

  function get_virtual_price() public view returns(uint256);

  function get_lp_token_balance() public view returns(uint256);

  function get_lp_token_addr() public view returns(address);

  string public name;
}

// File: contracts/utils/AddressArray.sol

pragma solidity >=0.4.21 <0.6.0;

library AddressArray{
  function exists(address[] memory self, address addr) public pure returns(bool){
    for (uint i = 0; i< self.length;i++){
      if (self[i]==addr){
        return true;
      }
    }
    return false;
  }

  function index_of(address[] memory self, address addr) public pure returns(uint){
    for (uint i = 0; i< self.length;i++){
      if (self[i]==addr){
        return i;
      }
    }
    require(false, "AddressArray:index_of, not exist");
  }

  function remove(address[] storage self, address addr) public returns(bool){
    uint index = index_of(self, addr);
    self[index] = self[self.length - 1];

    delete self[self.length-1];
    self.length--;
    return true;
  }
}

// File: contracts/utils/TransferableToken.sol

pragma solidity >=0.4.21 <0.6.0;



contract TransferableTokenHelper{
  uint256 public decimals;
}

library TransferableToken{
  using SafeERC20 for IERC20;

  function transfer(address target_token, address payable to, uint256 amount) public {
    if(target_token == address(0x0)){
      (bool status, ) = to.call.value(address(this).balance)("");
      require(status, "TransferableToken, transfer eth failed");
    }else{
      IERC20(target_token).safeTransfer(to, amount);
    }
  }

  function balanceOfAddr(address target_token, address _of) public view returns(uint256){
    if(target_token == address(0x0)){
      return address(_of).balance;
    }else{
      return IERC20(target_token).balanceOf(address(_of));
    }
  }

  function decimals(address target_token) public view returns(uint256) {
    if(target_token == address(0x0)){
      return 18;
    }else{
      return TransferableTokenHelper(target_token).decimals();
    }
  }
}

// File: contracts/core/ConvexInterface.sol

pragma solidity >=0.4.21 <0.6.0;

contract ConvexRewardInterface{
function getReward(address, bool) external returns(bool);
function withdraw(uint256, bool) external returns(bool);
}

contract ConvexBoosterInterface{
  function poolInfo(uint256) external view returns(address,address,address,address,address,bool);
  function poolLength() external view returns (uint256);
  function depositAll(uint256 _pid, bool _stake) external returns(bool);
  function withdraw(uint256 _pid, uint256 _amount) public returns(bool);
}

// File: contracts/core/CFController.sol

pragma solidity >=0.4.21 <0.6.0;









contract YieldHandlerInterface{
  function handleExtraToken(address from, address target_token, uint256 amount, uint min_amount) public;
}


contract CFControllerV2 is Ownable{
  using SafeERC20 for IERC20;
  using TransferableToken for address;
  using AddressArray for address[];
  using SafeMath for uint256;
  using Address for address;

  address[] public all_pools;

  address public current_pool;

  uint256 public last_earn_block;
  uint256 public earn_gap;
  address public crv_token;
  address public target_token;

  address public fee_pool;
  uint256 public harvest_fee_ratio;
  uint256 public ratio_base;

  address[] public extra_yield_tokens;

  YieldHandlerInterface public yield_handler;

  ConvexBoosterInterface public convex_booster;
  address public vault;
  address weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  //@param _target, when it's 0, means ETH
  constructor(address _crv, address _target, uint256 _earn_gap) public{
    last_earn_block = 0;
    require(_crv != address(0x0), "invalid crv address");
    //require(_target != address(0x0), "invalid target address");
    require(_earn_gap != 0, "invalid earn gap");
    convex_booster= ConvexBoosterInterface(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    crv_token = _crv;
    target_token = _target;
    earn_gap = _earn_gap;
    ratio_base = 10000;
  }

  function setVault(address _vault) public onlyOwner{
    require(_vault != address(0x0), "invalid vault");
    vault = _vault;
  }

  modifier onlyVault{
    require(msg.sender == vault, "only vault can call this");
    _;
  }

  function get_current_pool() public view returns(ICurvePool) {
    return ICurvePool(current_pool);
  }

  function add_pool(address addr) public onlyOwner{
    require(!all_pools.exists(addr), "already exist");
    if(current_pool == address(0x0)){
      current_pool = addr;
    }
    all_pools.push(addr);
  }

  function remove_pool(address addr) public onlyOwner{
    require(all_pools.exists(addr), "not exist");
    require(current_pool != addr, "active, cannot remove");
    all_pools.remove(addr);
  }

  event ChangeCurrentPool(address old, address _new);
  function change_current_pool(address addr) public onlyOwner{
    require(all_pools.exists(addr), "not exist");
    require(current_pool != addr, "already active");

    emit ChangeCurrentPool(current_pool, addr);
    //pull out all target token
    uint256 cur = ICurvePool(current_pool).get_lp_token_balance();
    if(cur == 0){
      return ;
    }

    uint256 index = get_pid(ICurvePool(current_pool).get_lp_token_addr());
    (,,,address crvRewards,,) = convex_booster.poolInfo(index);
    ConvexRewardInterface(crvRewards).withdraw(cur, false);
    convex_booster.withdraw(index, cur);
    address lp_token = ICurvePool(current_pool).get_lp_token_addr();
    require(IERC20(lp_token).balanceOf(address(this)) == cur, "invalid lp token amount");
    IERC20(lp_token).safeTransfer(current_pool, cur);

    ICurvePool(current_pool).withdraw(cur);
    uint256 b = TransferableToken.balanceOfAddr(target_token, address(this));
    current_pool = addr;

    //deposit to new pool
    TransferableToken.transfer(target_token, current_pool.toPayable(), b);
    _deposit(b);
  }

  function _deposit(uint256 _amount) internal{
    require(current_pool != address(0x0), "cannot deposit with 0x0 pool");
    ICurvePool(current_pool).deposit(_amount);
    address lp_token = ICurvePool(current_pool).get_lp_token_addr();
    IERC20(lp_token).approve(address(convex_booster), 0);
    IERC20(lp_token).approve(address(convex_booster), IERC20(lp_token).balanceOf(address(this)));
    convex_booster.depositAll(get_pid(ICurvePool(current_pool).get_lp_token_addr()), true);
  }

  function deposit(uint256 _amount) public onlyVault{
    _deposit(_amount);
  }

  mapping(address=>uint256) public cached_lp_token_pids;
  function get_pid(address lp_token_addr) internal returns(uint256) {
    if(cached_lp_token_pids[lp_token_addr] != 0){
      return cached_lp_token_pids[lp_token_addr];
    }

    for(uint i = 0; i < convex_booster.poolLength(); i++){
      (address lp_token,,,,,bool shutdown) = convex_booster.poolInfo(i);
      if(!shutdown && lp_token == lp_token_addr){
        cached_lp_token_pids[lp_token_addr] = i;
        return i;
      }
    }
    require(false, "not support pool");
  }

  function withdraw(uint256 _amount) public onlyVault{
    uint256 index = get_pid(ICurvePool(current_pool).get_lp_token_addr());
    (,,,address crvRewards,,) = convex_booster.poolInfo(index);
    ConvexRewardInterface(crvRewards).withdraw(_amount, false);
    convex_booster.withdraw(index, _amount);
    address lp_token = ICurvePool(current_pool).get_lp_token_addr();
    require(IERC20(lp_token).balanceOf(address(this)) == _amount, "invalid lp token amount");
    IERC20(lp_token).safeTransfer(current_pool, _amount);

    ICurvePool(current_pool).withdraw(_amount);

    uint256 b = TransferableToken.balanceOfAddr(target_token, address(this));
    require(b != 0, "too small target token");
    TransferableToken.transfer(target_token, msg.sender, b);
  }

  event EarnExtra(address addr, address token, uint256 amount);
  //at least min_amount blocks to call this
  function earnReward(uint min_amount) public onlyOwner{
    require(block.number.safeSub(last_earn_block) >= earn_gap, "not long enough");
    last_earn_block = block.number;

    uint256 index = get_pid(ICurvePool(current_pool).get_lp_token_addr());
    (,,,address crvRewards,,) = convex_booster.poolInfo(index);
    ConvexRewardInterface(crvRewards).getReward(address(this), true);

    for(uint i = 0; i < extra_yield_tokens.length; i++){
      uint256 amount = IERC20(extra_yield_tokens[i]).balanceOf(address(this));
      if(amount > 0){
        require(yield_handler != YieldHandlerInterface(0x0), "invalid yield handler");
        IERC20(extra_yield_tokens[i]).approve(address(yield_handler), amount);
        if(target_token == address(0x0)){
          yield_handler.handleExtraToken(extra_yield_tokens[i], weth, amount, min_amount);
        }else{
          yield_handler.handleExtraToken(extra_yield_tokens[i], target_token, amount, min_amount);
        }
      }
    }

    uint256 amount = TransferableToken.balanceOfAddr(target_token, address(this));
    _refundTarget(amount);
  }


  event CFFRefund(uint256 amount, uint256 fee);
  function _refundTarget(uint256 _amount) internal{
    if(_amount == 0){
      return ;
    }
    if(harvest_fee_ratio != 0 && fee_pool != address(0x0)){
      uint256 f = _amount.safeMul(harvest_fee_ratio).safeDiv(ratio_base);
      emit CFFRefund(_amount, f);
      _amount = _amount.safeSub(f);
      if(f != 0){
        TransferableToken.transfer(target_token, fee_pool.toPayable(), f);
      }
    }else{
      emit CFFRefund(_amount, 0);
    }
    TransferableToken.transfer(target_token, current_pool.toPayable(), _amount);
    _deposit(_amount);
  }

  function pause() public onlyOwner{
    current_pool = address(0x0);
  }

  event AddExtraToken(address _new);
  function addExtraToken(address _new) public onlyOwner{
    require(_new != address(0x0), "invalid extra token");
    extra_yield_tokens.push(_new);
    emit AddExtraToken(_new);
  }

  event RemoveExtraToken(address _addr);
  function removeExtraToken(address _addr) public onlyOwner{
    require(_addr != address(0x0), "invalid address");
    uint len = extra_yield_tokens.length;
    for(uint i = 0; i < len; i++){
      if(extra_yield_tokens[i] == _addr){
        extra_yield_tokens[i] = extra_yield_tokens[len - 1];
        extra_yield_tokens[len - 1] =address(0x0);
        extra_yield_tokens.length = len - 1;
        emit RemoveExtraToken(_addr);
      }
    }
  }

  event ChangeYieldHandler(address old, address _new);
  function changeYieldHandler(address _new) public onlyOwner{
    address old = address(yield_handler);
    yield_handler = YieldHandlerInterface(_new);
    emit ChangeYieldHandler(old, address(yield_handler));
  }

  event ChangeFeePool(address old, address _new);
  function changeFeePool(address _fp) public onlyOwner{
    address old = fee_pool;
    fee_pool = _fp;
    emit ChangeFeePool(old, fee_pool);
  }

  event ChangeHarvestFee(uint256 old, uint256 _new);
  function changeHarvestFee(uint256 _fee) public onlyOwner{
    require(_fee < ratio_base, "invalid fee");
    uint256 old = harvest_fee_ratio;
    harvest_fee_ratio = _fee;
    emit ChangeHarvestFee(old, harvest_fee_ratio);
  }
  function clearCachedPID(address lp_token) public onlyOwner{
    delete cached_lp_token_pids[lp_token];
  }

  function() external payable{}
}

contract CFControllerV2Factory{
  event NewCFController(address addr);
  function createCFController(address _crv, address _target, uint256 _earn_gap) public returns(address){
    CFControllerV2 cf = new CFControllerV2(_crv, _target, _earn_gap);
    emit NewCFController(address(cf));
    cf.transferOwnership(msg.sender);
    return address(cf);
  }
}