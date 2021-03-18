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

// File: contracts/core/CRVExchange.sol

pragma solidity >=0.4.21 <0.6.0;






contract CFControllerInterfaceForEx{
  function refundTarget(uint256 _amount) public;
}

contract CFETHControllerInterfaceForEx{
  function refundTarget() public payable;
}

contract SushiUniInterfaceERC20{
  function getAmountsOut(uint256 amountIn, address[] memory path) public view returns(uint256[] memory);
  function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 amountIn,   uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external ;
  function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
}


contract CRVExchange is Ownable{
  address public crv_token;
  using AddressArray for address[];
  using SafeERC20 for IERC20;

  struct path_info{
    address dex;
    address[] path;
  }
  mapping(bytes32 => path_info) public paths;
  bytes32[] public path_indexes;

  address weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  constructor(address _crv) public{
    if(_crv == address(0x0)){
      crv_token = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    }else{
      crv_token = _crv;
    }
  }
  function path_from_addr(uint index) public view returns(address){
    return paths[path_indexes[index]].path[0];
  }
  function path_to_addr(uint index) public view returns(address){
    return paths[path_indexes[index]].path[paths[path_indexes[index]].path.length - 1];
  }

  function handleCRV(address target_token, uint256 amount, uint min_amount) public{
    handleExtraToken(crv_token, target_token, amount, min_amount);
  }

  function handleExtraToken(address from, address target_token, uint256 amount, uint min_amount) public{
    uint256 maxOut = 0;
    uint256 fpi = 0;

    for(uint pi = 0; pi < path_indexes.length; pi ++){
      if(path_from_addr(pi) != from || path_to_addr(pi) != target_token){
        continue;
      }
      uint256 t = get_out_for_dex_path(pi, amount);
      if( t > maxOut ){
        fpi = pi;
        maxOut = t;
      }
    }

    address dex = paths[path_indexes[fpi]].dex;
    IERC20(from).safeTransferFrom(msg.sender, address(this), amount);
    IERC20(from).safeApprove(dex, amount);
    if(target_token == weth){
      SushiUniInterfaceERC20(dex).swapExactTokensForETHSupportingFeeOnTransferTokens(amount, min_amount, paths[path_indexes[fpi]].path, address(this), block.timestamp + 10800);
      uint256 target_amount = address(this).balance;
      require(target_amount >= min_amount, "slippage screwed you");
      CFETHControllerInterfaceForEx(msg.sender).refundTarget.value(target_amount)();
    }else{
      SushiUniInterfaceERC20(dex).swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, min_amount, paths[path_indexes[fpi]].path, address(this), block.timestamp + 10800);
      uint256 target_amount = IERC20(target_token).balanceOf(address(this));
      require(target_amount >= min_amount, "slippage screwed you");
      IERC20(target_token).safeApprove(address(msg.sender), target_amount);
      CFControllerInterfaceForEx(msg.sender).refundTarget(target_amount);
    }
  }

  function get_out_for_dex_path(uint pi, uint256 _amountIn) internal view returns(uint256) {
    address dex = paths[path_indexes[pi]].dex;
    uint256[] memory ret = SushiUniInterfaceERC20(dex).getAmountsOut(_amountIn, paths[path_indexes[pi]].path);
    return ret[ret.length - 1];
  }

  event AddPath(bytes32 hash, address dex, address[] path);
  function addPath(address dex, address[] memory path) public onlyOwner{
    SushiUniInterfaceERC20(dex).getAmountsOut(1e18, path); //This is a double check 
    bytes32 hash = keccak256(abi.encodePacked(dex, path));
    require(paths[hash].path.length == 0, "already exist path");
    path_indexes.push(hash);
    paths[hash].path = path;
    paths[hash].dex = dex;
    emit AddPath(hash, dex, path);
  }

  event RemovePath(bytes32 hash);
  function removePath(address dex, address[] memory path) public onlyOwner{
    bytes32 hash = keccak256(abi.encodePacked(dex, path));
    removePathWithHash(hash);
  }

  function removePathWithHash(bytes32 hash) public onlyOwner{
    require(paths[hash].path.length != 0, "path not exist");
    delete paths[hash];
    for(uint i = 0; i < path_indexes.length; i++){
      if(path_indexes[i] == hash){
          path_indexes[i] = path_indexes[path_indexes.length - 1];
          delete path_indexes[path_indexes.length - 1];
          path_indexes.length --;
          emit RemovePath(hash);
          break;
      }
    }
  }

  function() external payable{}
}