/**
 *Submitted for verification at Etherscan.io on 2021-03-18
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

// File: contracts/core/IPool.sol

pragma solidity >=0.4.21 <0.6.0;

contract ICurvePool{
  function deposit(uint256 _amount) public;
  function withdraw(uint256 _amount) public;

  function get_virtual_price() public view returns(uint256);

  function get_lp_token_balance() public view returns(uint256);

  function get_lp_token_addr() public view returns(address);

  function earn_crv() public;

  string public name;
}

contract ICurvePoolForETH{
  function deposit() public payable;
  function withdraw(uint256 _amount) public;

  function get_virtual_price() public view returns(uint256);

  function get_lp_token_balance() public view returns(uint256);

  function get_lp_token_addr() public view returns(address);

  function earn_crv() public;

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

// File: contracts/core/CFETHController.sol

pragma solidity >=0.4.21 <0.6.0;






contract CRVHandlerETHInterface{
  function handleCRV(address target_token, uint256 amount, uint min_amount) public;
  function handleExtraToken(address from, address target_token, uint256 amount, uint min_amount) public;
}

contract CFETHController is Ownable{
  using SafeERC20 for IERC20;
  using AddressArray for address[];
  using SafeMath for uint256;

  address[] public all_pools;

  address public current_pool;

  uint256 public last_earn_block;
  uint256 public earn_gap;
  address public crv_token;
  address public target_token;

  address payable public fee_pool;
  uint256 public harvest_fee_ratio;
  uint256 public ratio_base;

  address public extra_yield_token;
  CRVHandlerETHInterface public crv_handler;

  constructor(address _crv, uint256 _earn_gap) public{
    last_earn_block = 0;
    if(_earn_gap == 0){
      earn_gap = 5760;
    }else{
      earn_gap = _earn_gap;
    }

    last_earn_block = block.number;
    if(_crv == address(0x0)){
      crv_token = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    }else{
      crv_token = _crv;
    }

    ratio_base = 10000;
  }

  function get_current_pool() public view returns(ICurvePoolForETH) {
    return ICurvePoolForETH(current_pool);
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
    uint256 cur = ICurvePoolForETH(current_pool).get_lp_token_balance();
    ICurvePoolForETH(current_pool).withdraw(cur);
    uint256 b = address(this).balance;
    current_pool = addr;

    //deposit to new pool
    ICurvePoolForETH(current_pool).deposit.value(b)();
  }

  address weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  event EarnCRV(address addr, uint256 amount);
  event EarnExtra(address addr, address token, uint256 amount);
  //at least 24 hours to call this
  function earnCRV(uint crv_min_amount, uint extra_min_amount) public onlyOwner{
    require(block.number.safeSub(last_earn_block) >= earn_gap, "not long enough");
    last_earn_block = block.number;

    ICurvePoolForETH(current_pool).earn_crv();

    uint256 amount = IERC20(crv_token).balanceOf(address(this));
    emit EarnCRV(address(this), amount);

    if(amount > 0){
      require(crv_handler != CRVHandlerETHInterface(0x0), "invalid crv handler");
      IERC20(crv_token).approve(address(crv_handler), amount);
      crv_handler.handleCRV(weth, amount, crv_min_amount);
    }

    if(extra_yield_token != address(0x0)){
      amount = IERC20(extra_yield_token).balanceOf(address(this));
      emit EarnExtra(address(this), extra_yield_token, amount);
      if(amount > 0){
        IERC20(extra_yield_token).approve(address(crv_handler), amount);
        crv_handler.handleExtraToken(extra_yield_token, weth, amount, extra_min_amount);
      }
    }
  }

  event CFFRefund(uint256 amount, uint256 fee);
  function refundTarget() public payable{
    //IERC20(target_token).safeTransferFrom(msg.sender, address(this), _amount);
    uint _amount = msg.value;
    if(harvest_fee_ratio != 0 && fee_pool != address(0x0)){
      uint256 f = _amount.safeMul(harvest_fee_ratio).safeDiv(ratio_base);
      emit CFFRefund(_amount, f);
      _amount = _amount.safeSub(f);
      if(f != 0){
        fee_pool.transfer(_amount);
      }
    }else{
      emit CFFRefund(_amount, 0);
    }
    ICurvePoolForETH(current_pool).deposit.value(_amount)();
  }

  function pauseAndTransferTo(address payable _target) public onlyOwner{
    //pull out all target token
    uint256 cur = ICurvePoolForETH(current_pool).get_lp_token_balance();
    ICurvePoolForETH(current_pool).withdraw(cur);
    uint b = address(this).balance;
    _target.transfer(b);

    current_pool = address(0x0);
  }

  event ChangeExtraToken(address old, address _new);
  function changeExtraToken(address _new) public onlyOwner{
    address old = extra_yield_token;
    extra_yield_token = _new;
    emit ChangeExtraToken(old, extra_yield_token);
  }

  event ChangeCRVHandler(address old, address _new);
  function changeCRVHandler(address _new) public onlyOwner{
    address old = address(crv_handler);
    crv_handler = CRVHandlerETHInterface(_new);
    emit ChangeCRVHandler(old, address(crv_handler));
  }

  event ChangeFeePool(address old, address _new);
  function changeFeePool(address payable _fp) public onlyOwner{
    address payable old = fee_pool;
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

  function() external payable{}

}

contract CFETHControllerFactory{
  event NewCFETHController(address addr);
  function createCFETHController(address _crv, uint256 _earn_gap) public returns(address){
    CFETHController cf = new CFETHController(_crv, _earn_gap);
    emit NewCFETHController(address(cf));
    cf.transferOwnership(msg.sender);
    return address(cf);
  }
}