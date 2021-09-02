/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

pragma solidity >=0.4.21 <0.6.0;
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

pragma solidity >=0.4.21 <0.6.0;

contract TokenBankInterface{
  function issue(address token_addr, address payable _to, uint _amount) public returns (bool success);
}

pragma solidity >=0.4.21 <0.6.0;
contract TokenInterface{
  function destroyTokens(address _owner, uint _amount) public returns(bool);
  function generateTokens(address _owner, uint _amount) public returns(bool);
}

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

pragma solidity >=0.4.21 <0.6.0;

contract IPDispatcher{
  function getTarget(bytes32 _key) public view returns (address);
}

pragma solidity >=0.4.21 <0.6.0;

contract IPLiquidate{
  function liquidate_asset(address payable _sender, uint256 _target_amount, uint256 _stable_amount) public ;
}

pragma solidity >=0.4.21 <0.6.0;

contract IPMBParams{
  uint256 public ratio_base;
  uint256 public withdraw_fee_ratio;

  uint256 public mortgage_ratio;
  uint256 public liquidate_fee_ratio;
  uint256 public minimum_deposit_amount;

  address payable public plut_fee_pool;
}


contract PLiquidateAgent is Ownable{

  using SafeMath for uint256;
  address public target_token;
  address public target_token_pool;
  address public stable_token;
  address public target_fee_pool;

  IPDispatcher public dispatcher;
  address public caller;

  bytes32 public param_key;
  constructor(address _target_token, address _target_token_pool, address _stable_token, address _dispatcher) public{
    target_token = _target_token;
    target_token_pool = _target_token_pool;
    stable_token = _stable_token;
    dispatcher = IPDispatcher(_dispatcher);
    param_key = keccak256(abi.encodePacked(target_token, stable_token, "param"));
  }

  modifier onlyCaller{
    require(msg.sender == caller, "not caller");
    _;
  }

  function liquidate_asset(address payable _sender, uint256 _target_amount, uint256 _stable_amount) public onlyCaller{
    IPMBParams param = IPMBParams(dispatcher.getTarget(param_key));

    require(IERC20(stable_token).balanceOf(_sender) >= _stable_amount, "insufficient stable token");
    TokenInterface(stable_token).destroyTokens(_sender, _stable_amount);
    if(param.liquidate_fee_ratio() != 0 && param.plut_fee_pool() != address(0x0)){
      uint256 t = param.liquidate_fee_ratio().safeMul(_target_amount).safeDiv(param.ratio_base());
      TokenBankInterface(target_token_pool).issue(target_token, param.plut_fee_pool(), t);
      TokenBankInterface(target_token_pool).issue(target_token, _sender, _target_amount.safeSub(t));
    }else{
      TokenBankInterface(target_token_pool).issue(target_token, _sender, _target_amount);
    }
  }

  function changeCaller(address _caller) public onlyOwner{
    caller = _caller;
  }

}