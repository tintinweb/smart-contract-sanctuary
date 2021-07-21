/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IERC20 {
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint);
  function approve(address spender, uint amount) external returns (bool);
  function mint(address account, uint amount) external;
  function burn(address account, uint amount) external;
  function transferFrom(address sender, address recipient, uint amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

interface IInterestRateModel {
  function systemRate(ILendingPair _pair, address _token) external view returns(uint);
  function supplyRatePerBlock(ILendingPair _pair, address _token) external view returns(uint);
  function borrowRatePerBlock(ILendingPair _pair, address _token) external view returns(uint);
}

interface IRewardDistribution {
  function distributeReward(address _account, address _token) external;
}

interface IController {
  function interestRateModel() external view returns(IInterestRateModel);
  function rewardDistribution() external view returns(IRewardDistribution);
  function feeRecipient() external view returns(address);
  function LIQ_MIN_HEALTH() external view returns(uint);
  function minBorrowUSD() external view returns(uint);
  function liqFeeSystem(address _token) external view returns(uint);
  function liqFeeCaller(address _token) external view returns(uint);
  function liqFeesTotal(address _token) external view returns(uint);
  function colFactor(address _token) external view returns(uint);
  function depositLimit(address _lendingPair, address _token) external view returns(uint);
  function borrowLimit(address _lendingPair, address _token) external view returns(uint);
  function originFee(address _token) external view returns(uint);
  function depositsEnabled() external view returns(bool);
  function borrowingEnabled() external view returns(bool);
  function setFeeRecipient(address _feeRecipient) external;
  function tokenPrice(address _token) external view returns(uint);
  function tokenSupported(address _token) external view returns(bool);
}

interface ILendingPair {
  function checkAccountHealth(address _account) external view;
  function accrueAccount(address _account) external;
  function accrue() external;
  function accountHealth(address _account) external view returns(uint);
  function totalDebt(address _token) external view returns(uint);
  function tokenA() external view returns(address);
  function tokenB() external view returns(address);
  function lpToken(address _token) external view returns(IERC20);
  function debtOf(address _account, address _token) external view returns(uint);
  function pendingDebtTotal(address _token) external view returns(uint);
  function pendingSupplyTotal(address _token) external view returns(uint);
  function deposit(address _token, uint _amount) external;
  function withdraw(address _token, uint _amount) external;
  function borrow(address _token, uint _amount) external;
  function repay(address _token, uint _amount) external;
  function withdrawBorrow(address _token, uint _amount) external;
  function controller() external view returns(IController);

  function borrowBalance(
    address _account,
    address _borrowedToken,
    address _returnToken
  ) external view returns(uint);

  function convertTokenValues(
    address _fromToken,
    address _toToken,
    uint    _inputAmount
  ) external view returns(uint);
}

contract Ownable {

  address public owner;
  address public pendingOwner;

  event OwnershipTransferInitiated(address indexed previousOwner, address indexed newOwner);
  event OwnershipTransferConfirmed(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferConfirmed(address(0), owner);
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function transferOwnership(address _newOwner) external onlyOwner {
    require(_newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferInitiated(owner, _newOwner);
    pendingOwner = _newOwner;
  }

  function acceptOwnership() external {
    require(msg.sender == pendingOwner, "Ownable: caller is not pending owner");
    emit OwnershipTransferConfirmed(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract LPTokenMaster is Ownable {

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);

  mapping (address => uint) public balanceOf;
  mapping (address => mapping (address => uint)) public allowance;

  bool private initialized;
  string public constant name     = "WILD-LP";
  string public constant symbol   = "WILD-LP";
  uint8  public constant decimals = 18;
  uint public totalSupply;

  function initialize() external {
    require(initialized != true, "LPToken: already intialized");
    owner = msg.sender;
    initialized = true;
  }

  function transfer(address _recipient, uint _amount) external returns (bool) {
    _transfer(msg.sender, _recipient, _amount);
    return true;
  }

  function approve(address _spender, uint _amount) external returns (bool) {
    _approve(msg.sender, _spender, _amount);
    return true;
  }

  function transferFrom(address _sender, address _recipient, uint _amount) external returns (bool) {
    _approve(_sender, msg.sender, allowance[_sender][msg.sender] - _amount);
    _transfer(_sender, _recipient, _amount);
    return true;
  }

  function mint(address _account, uint _amount) external onlyOwner {
    _mint(_account, _amount);
  }

  function burn(address _account, uint _amount) external onlyOwner {
    _burn(_account, _amount);
  }

  function selfBurn(uint _amount) external {
    _burn(msg.sender, _amount);
  }

  function lendingPair() external view returns(address) {
    return owner;
  }

  function underlying() public view returns(address) {
    ILendingPair pair = ILendingPair(owner);
    return address(pair.lpToken(pair.tokenA())) == address(this) ? pair.tokenA() : pair.tokenB();
  }

  function _transfer(address _sender, address _recipient, uint _amount) internal {
    require(_sender != address(0), "ERC20: transfer from the zero address");
    require(_recipient != address(0), "ERC20: transfer to the zero address");
    require(balanceOf[_sender] >= _amount, "ERC20: insufficient funds");

    ILendingPair pair = ILendingPair(owner);
    pair.accrueAccount(_sender);
    pair.accrueAccount(_recipient);

    balanceOf[_sender] -= _amount;
    balanceOf[_recipient] += _amount;

    pair.checkAccountHealth(_sender);

    require(
      pair.borrowBalance(_recipient, underlying(), underlying()) == 0,
      "LendingPair: cannot deposit borrowed token"
    );

    emit Transfer(_sender, _recipient, _amount);
  }

  function _mint(address _account, uint _amount) internal {
    require(_account != address(0), "ERC20: mint to the zero address");

    totalSupply += _amount;
    balanceOf[_account] += _amount;
    emit Transfer(address(0), _account, _amount);
  }

  function _burn(address _account, uint _amount) internal {
    require(_account != address(0), "ERC20: burn from the zero address");

    balanceOf[_account] -= _amount;
    totalSupply -= _amount;
    emit Transfer(_account, address(0), _amount);
  }

  function _approve(address _owner, address _spender, uint _amount) internal {
    require(_owner != address(0), "ERC20: approve from the zero address");
    require(_spender != address(0), "ERC20: approve to the zero address");

    allowance[_owner][_spender] = _amount;
    emit Approval(_owner, _spender, _amount);
  }
}