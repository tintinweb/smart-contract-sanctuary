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

// File: contracts/TrustListTools.sol

pragma solidity >=0.4.21 <0.6.0;


contract TrustListInterface{
  function is_trusted(address addr) public returns(bool);
}
contract TrustListTools is Ownable{
  TrustListInterface public trustlist;

  modifier is_trusted(address addr){
    require(trustlist != TrustListInterface(0x0), "trustlist is 0x0");
    require(trustlist.is_trusted(addr), "not a trusted issuer");
    _;
  }

  event ChangeTrustList(address _old, address _new);
  function changeTrustList(address _addr) public onlyOwner{
    address old = address(trustlist);
    trustlist = TrustListInterface(_addr);
    emit ChangeTrustList(old, _addr);
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

// File: contracts/utils/TokenClaimer.sol

pragma solidity >=0.4.21 <0.6.0;


contract TokenClaimer{

    event ClaimedTokens(address indexed _token, address indexed _to, uint _amount);
    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
  function _claimStdTokens(address _token, address payable to) internal {
        if (_token == address(0x0)) {
            (bool status, ) = to.call.value(address(this).balance)("");
            require(status, "TokenClaimer transfer eth failed");
            return;
        }
        uint balance = IERC20(_token).balanceOf(address(this));

        (bool status,) = _token.call(abi.encodeWithSignature("transfer(address,uint256)", to, balance));
        require(status, "call failed");
        emit ClaimedTokens(_token, to, balance);
  }
}

// File: contracts/core/IPERC20.sol

pragma solidity >=0.4.21 <0.6.0;


interface IPERC {
  function confirmTransfer(address _to, uint256 _amount) external returns (bool);
  function is_proxy_required() external view returns(bool);
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

// File: contracts/core/PaymentPool.sol

pragma solidity >=0.4.21 <0.6.0;








contract PaymentPool is Ownable, TokenClaimer, TrustListTools{
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  string public bank_name;
  uint256 public nonce;
  bool public tx_lock;

  struct tx_info{
    address token;
    address from;
    address to;
    uint256 amount;
    uint256 nonce;
  }
  struct request_info{
    bool exist;
    address from;
    uint8 status; //0 is init or pending, 1 is for succ, 2 is for fail
    tx_info[] txs;
  }
  mapping (bytes32 => request_info) public requests;
  mapping (address => mapping (address => uint256)) public pending_balance;

  event withdraw_token(address token, address to, uint256 amount);
  event issue_token(address token, address to, uint256 amount);

  event RecvETH(uint256 v);
  function() external payable{
    emit RecvETH(msg.value);
  }

  constructor(string memory name) public{
    bank_name = name;
    nonce = 0;
  }


  function claimStdTokens(address _token, address payable to)
    public onlyOwner{
      _claimStdTokens(_token, to);
  }

  function balance(address erc20_token_addr) public view returns(uint){
    if(erc20_token_addr == address(0x0)){
      return address(this).balance;
    }
    return IERC20(erc20_token_addr).balanceOf(address(this));
  }

  function transfer(address erc20_token_addr, address payable to, uint tokens)
    public
    onlyOwner
    returns (bool success){
    require(tokens <= balance(erc20_token_addr), "Pool not enough tokens");
    if(erc20_token_addr == address(0x0)){
      (bool _success, ) = to.call.value(tokens)("");
      require(_success, "Pool transfer eth failed");
      emit withdraw_token(erc20_token_addr, to, tokens);
      return true;
    }
    IERC20(erc20_token_addr).safeTransfer(to, tokens);
    emit withdraw_token(erc20_token_addr, to, tokens);
    return true;
  }

  function startTransferRequest() public is_trusted(msg.sender) returns(bytes32){
    require(!tx_lock, "startTransferRequest cannot be nested");
    tx_lock = true;
    nonce ++;
    bytes32 h = currentTransferRequestHash();
    requests[h].exist = true;
    requests[h].from = msg.sender;
    requests[h].status = 1; //by default, it's succ until we get transfer requests.
    return h;
  }

  function endTransferRequest() public is_trusted(msg.sender) returns(bytes32){
    tx_lock = false;
    return keccak256(abi.encodePacked(nonce));
  }

  function currentTransferRequestHash() public view returns(bytes32){
    return keccak256(abi.encodePacked(nonce));
  }

  function getTransferRequestStatus(bytes32 _hash) public view returns(uint8){
    return requests[_hash].status;
  }

  function getPendingBalance(address _owner, address token_addr) public view returns(uint256){
    return pending_balance[_owner][token_addr];
  }

  event TransferRequest(bytes32 request_hash, address token_addr, address from, address to, uint256 amount);

  function transferRequest(address token_addr, address _from, address _to, uint256 _amount) public is_trusted(msg.sender){
    if (IPERC(token_addr).is_proxy_required()) {
      require(tx_lock, "proxy required");
      bytes32 h = currentTransferRequestHash();
      requests[h].status = 0; //since we have transfers, we make it pending
      tx_info storage transaction  = requests[h].txs[requests[h].txs.length++];
      transaction.token = token_addr;
      transaction.from = _from;
      transaction.to = _to;
      transaction.nonce = nonce;
      transaction.amount = _amount;
      pending_balance[_from][token_addr] = pending_balance[_from][token_addr].safeAdd(_amount);
      emit TransferRequest(h, token_addr, _from, _to, _amount);
    }
    else{
      IPERC(token_addr).confirmTransfer(_to, _amount);
    }
  }

  function transferCommit(bytes32 _hash, bool _status) public is_trusted(msg.sender){
    request_info storage request = requests[_hash];
    if(_status){
      request.status = 1;
    }else{
      request.status = 2;
    }
    for (uint i = 0; i < request.txs.length; i++){
      tx_info storage transaction = request.txs[i];
      if(_status){
        IPERC(transaction.token).confirmTransfer(transaction.to, transaction.amount);
      }else{
        IPERC(transaction.token).confirmTransfer(transaction.from, transaction.amount);
      }
      pending_balance[transaction.from][transaction.token] = pending_balance[transaction.from][transaction.token].safeSub(transaction.amount);
    }
  }

}


contract PaymentPoolFactory {
  event CreatePaymentPool(string name, address addr);

  function newPaymentPool(string memory name) public returns(address){
    PaymentPool addr = new PaymentPool(name);
    emit CreatePaymentPool(name, address(addr));
    addr.transferOwnership(msg.sender);
    return address(addr);
  }
}