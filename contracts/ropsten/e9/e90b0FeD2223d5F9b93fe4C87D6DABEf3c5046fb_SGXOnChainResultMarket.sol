/**
 *Submitted for verification at Etherscan.io on 2022-01-16
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

// File: contracts/core/market/interface/DataMarketPlaceInterface.sol

pragma solidity >=0.4.21 <0.6.0;

contract DataMarketPlaceInterface{
  address public payment_token;
  function delegateCallUseData(address _e, bytes memory data) public returns(bytes memory);
}

// File: contracts/plugins/GasRewardTool.sol

pragma solidity >=0.4.21 <0.6.0;

contract GasRewardInterface{
  function reward(address payable to, uint256 amount) public;
}

contract GasRewardTool is Ownable{
  GasRewardInterface public gas_reward_contract;

  modifier rewardGas{
    uint256 gas_start = gasleft();
    _;
    uint256 gasused = (gas_start - gasleft()) * tx.gasprice;
    if(gas_reward_contract != GasRewardInterface(0x0)){
      gas_reward_contract.reward(tx.origin, gasused);
    }
  }

  event ChangeRewarder(address _old, address _new);
  function changeRewarder(address _rewarder) public onlyOwner{
    address old = address(gas_reward_contract);
    gas_reward_contract = GasRewardInterface(_rewarder);
    emit ChangeRewarder(old, _rewarder);
  }
}

// File: contracts/core/PaymentConfirmTool.sol

pragma solidity >=0.4.21 <0.6.0;


contract IPaymentProxy{
  function startTransferRequest() public returns(bytes32);
  function endTransferRequest() public returns(bytes32);
  function currentTransferRequestHash() public view returns(bytes32);
  function getTransferRequestStatus(bytes32 _hash) public view returns(uint8);
}
contract PaymentConfirmTool is Ownable{
  address confirm_proxy;

  event PaymentConfirmRequest(bytes32 hash);
  modifier need_confirm{
    if(confirm_proxy != address(0x0)){
      bytes32 local = IPaymentProxy(confirm_proxy).startTransferRequest();
      _;
      require(local == IPaymentProxy(confirm_proxy).endTransferRequest(), "invalid nonce");
      emit PaymentConfirmRequest(local);
    }else{
      _;
    }
  }

  //@return 0 is init or pending, 1 is for succ, 2 is for fail
  function getTransferRequestStatus(bytes32 _hash) public view returns(uint8){
    return IPaymentProxy(confirm_proxy).getTransferRequestStatus(_hash) ;
  }

  event ChangeConfirmProxy(address old_proxy, address new_proxy);
  function changeConfirmProxy(address new_proxy) public onlyOwner{
    address old = confirm_proxy;
    confirm_proxy = new_proxy;
    emit ChangeConfirmProxy(old, new_proxy);
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

// File: contracts/core/market/onchain/SGXOnChainResultMarket.sol

pragma solidity >=0.4.21 <0.6.0;







contract SGXOnChainResultMarket is Ownable, GasRewardTool, PaymentConfirmTool{
  using SafeERC20 for IERC20;
  DataMarketPlaceInterface public market;

  address public data_lib_address;

  event ChangeMarket(address old_market, address new_market);
  function changeMarket(address _market) public onlyOwner{
    address old = address(market);
    market = DataMarketPlaceInterface(_market);
    emit ChangeMarket(old, address(market));
  }

  event ChangeDataLib(address old_lib, address new_lib);
  function changeDataLib(address _new_lib) public onlyOwner{
    address old = data_lib_address;
    data_lib_address = _new_lib;
    emit ChangeDataLib(old, data_lib_address);
  }


  event SDMarketNewRequestOnChain(bytes32 indexed request_hash, bytes32 indexed vhash, bytes secret, bytes input,
        bytes forward_sig, bytes32 program_hash, uint gas_price, bytes pkey, uint256 amount);
  function requestOnChain(bytes32 _vhash, bytes memory secret,
                          bytes memory input,
                          bytes memory forward_sig,
                          bytes32 program_hash, uint gas_price,
                          bytes memory pkey, uint256 amount) public rewardGas need_confirm returns(bytes32){
    IERC20(market.payment_token()).safeTransferFrom(msg.sender, address(this), amount);
    require(IERC20(market.payment_token()).balanceOf(address(this)) == amount, "invalid amount");

    IERC20(market.payment_token()).safeApprove(address(market), 0);
    IERC20(market.payment_token()).safeApprove(address(market), amount);
    bytes32 request_hash;
    {
      bytes memory data = abi.encodeWithSignature("requestOnChain(bytes32,bytes,bytes,bytes,bytes32,uint256,bytes,uint256)",
        _vhash, secret, input, forward_sig, program_hash, gas_price, pkey, amount);
      bytes memory ret = market.delegateCallUseData(data_lib_address, data);
      (request_hash) = abi.decode(ret, (bytes32));
    }

    {
      bytes memory d2 = abi.encodeWithSignature("internalTransferRequestOwnership(bytes32,bytes32,address)", _vhash, request_hash, msg.sender);
      market.delegateCallUseData(data_lib_address, d2);
    }

    emit SDMarketNewRequestOnChain(request_hash, _vhash, secret, input, forward_sig, program_hash, gas_price, pkey, amount);
    return request_hash;
  }

  event SDMarketSubmitResult(bytes32 indexed request_hash, bytes32 indexed vhash);
  function submitOnChainResult(bytes32 _vhash, bytes32 request_hash, uint64 cost, bytes memory result,
                               bytes memory sig) public rewardGas need_confirm returns(bool){
    bytes memory data = abi.encodeWithSignature("submitOnChainResult(bytes32,bytes32,uint64,bytes,bytes)",
      _vhash, request_hash, cost, result, sig);
    bytes memory ret = market.delegateCallUseData(data_lib_address, data);
    (bool v) = abi.decode(ret, (bool));
    emit SDMarketSubmitResult(request_hash, _vhash);
    return v;
  }

  event SDMarketResultInsufficientFund(bytes32 indexed request_hash, bytes32 indexed vhash, uint256 gap, uint64 cost_gas);
  function remindRequestCost(bytes32 _vhash, bytes32 request_hash, uint64 cost,
                             bytes memory sig) public rewardGas returns(uint256 gap){
    bytes memory data = abi.encodeWithSignature("remindRequestCost(bytes32,bytes32,uint64,bytes)",_vhash, request_hash, cost, sig);
    bytes memory ret = market.delegateCallUseData(data_lib_address, data);
    (uint256 _gap) = abi.decode(ret, (uint256));
    if(_gap > 0){
      emit SDMarketResultInsufficientFund(request_hash, _vhash, _gap, cost);
    }
    return _gap;
  }

  event SDMarketRefundRequest(bytes32 indexed request_hash, bytes32 indexed vhash, uint256 refund_amount);
  function refundRequest(bytes32 _vhash, bytes32 request_hash, uint256 refund_amount) public rewardGas need_confirm{
    bytes memory d1 = abi.encodeWithSignature("internalTransferRequestOwnership(bytes32,bytes32,address)", _vhash, request_hash, address(this));
    market.delegateCallUseData(data_lib_address, d1);

    IERC20(market.payment_token()).safeTransferFrom(msg.sender, address(this), refund_amount);
    IERC20(market.payment_token()).safeApprove(address(market), 0);
    IERC20(market.payment_token()).safeApprove(address(market), refund_amount);

    bytes memory data = abi.encodeWithSignature("refundRequest(bytes32,bytes32,uint256)",_vhash, request_hash, refund_amount);
    market.delegateCallUseData(data_lib_address, data);

    bytes memory d2 = abi.encodeWithSignature("internalTransferRequestOwnership(bytes32,bytes32,address)", _vhash, request_hash, msg.sender);
    market.delegateCallUseData(data_lib_address, d2);
    emit SDMarketRefundRequest(request_hash, _vhash, refund_amount);
  }

  event SDMarketRevokeRequest(bytes32 indexed request_hash, bytes32 indexed vhash);
  function revokeRequest(bytes32 _vhash, bytes32 request_hash) public rewardGas need_confirm{
    bytes memory d1 = abi.encodeWithSignature("internalTransferRequestOwnership(bytes32,bytes32,address)", _vhash, request_hash, address(this));
    market.delegateCallUseData(data_lib_address, d1);

    bytes memory data = abi.encodeWithSignature("revokeRequest(bytes32,bytes32)",_vhash, request_hash);
    bytes memory ret = market.delegateCallUseData(data_lib_address, data);
    (uint256 token_amount) = abi.decode(ret, (uint256));

    bytes memory d2 = abi.encodeWithSignature("internalTransferRequestOwnership(bytes32,bytes32,address)", _vhash, request_hash, msg.sender);
    market.delegateCallUseData(data_lib_address, d2);

    IERC20(market.payment_token()).safeTransfer(msg.sender, token_amount);
    emit SDMarketRevokeRequest(request_hash, _vhash);
  }
}