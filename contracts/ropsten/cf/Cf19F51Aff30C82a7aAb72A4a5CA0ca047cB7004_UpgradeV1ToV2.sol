/**
 *Submitted for verification at Etherscan.io on 2021-11-08
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

// File: contracts/utils/ReentrancyGuard.sol

pragma solidity >=0.4.21 <0.6.0;

contract ReentrancyGuard {
    uint256 private _guardCounter;

    constructor () internal {
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
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

// File: contracts/erc20/TokenInterface.sol

pragma solidity >=0.4.21 <0.6.0;
contract TokenInterface{
  function destroyTokens(address _owner, uint _amount) public returns(bool);
  function generateTokens(address _owner, uint _amount) public returns(bool);
}

// File: contracts/core/UpgradeV1ToV2.sol

pragma solidity >=0.4.21 <0.6.0;








contract CFVaultInterface{
  address public target_token; //this is for V2
  address public lp_token; //this is for both V1 and V2
  function withdraw(uint256 _amount) public; //this is for V2
  function deposit(uint256 _amount) public payable; //this is for V1
}


contract UpgradeV1ToV2{
  using SafeERC20 for IERC20;

  CFVaultInterface public v1_vault;
  CFVaultInterface public v2_vault;

  constructor(address _v1, address _v2) public{
    v1_vault = CFVaultInterface(_v1);
    v2_vault = CFVaultInterface(_v2);
  }

  function upgrade(uint256 _amount) public{

    address v1_lp_token = v1_vault.lp_token();
    address v2_lp_token = v2_vault.lp_token();

    require(IERC20(v1_lp_token).balanceOf(msg.sender) >= _amount, "not enough to upgrade");
    TokenInterface(v1_lp_token).destroyTokens(msg.sender, _amount);
    TokenInterface(v1_lp_token).generateTokens(address(this), _amount);

    v1_vault.withdraw(_amount);

    uint256 new_amount = TransferableToken.balanceOfAddr(v2_vault.target_token(), address(this));
    if(v2_vault.target_token() == address(0x0)){
      v2_vault.deposit.value(new_amount)(new_amount);
    }else{
      IERC20(v2_vault.target_token()).safeApprove(address(v2_vault), new_amount);
      v2_vault.deposit(new_amount);
    }
    uint256 t = IERC20(v2_lp_token).balanceOf(address(this));
    IERC20(v2_lp_token).safeTransfer(msg.sender, t);
  }

  function() external payable{}

}