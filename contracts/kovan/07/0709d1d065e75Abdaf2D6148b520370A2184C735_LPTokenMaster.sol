/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IOwnable {
  function owner() external view returns(address);
  function transferOwnership(address _newOwner) external;
  function acceptOwnership() external;
}

interface IERC20 {
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns(uint);
  function transfer(address recipient, uint256 amount) external returns(bool);
  function allowance(address owner, address spender) external view returns(uint);
  function decimals() external view returns(uint8);
  function approve(address spender, uint amount) external returns(bool);
  function transferFrom(address sender, address recipient, uint amount) external returns(bool);
}

interface ILPTokenMaster is IOwnable, IERC20 {
  function initialize(address _underlying, address _lendingController) external;
  function underlying() external view returns(address);
  function lendingPair() external view returns(address);
}

interface ILendingPair {

  function tokenA() external view returns(address);
  function tokenB() external view returns(address);
  function lpToken(address _token) external view returns(address);
  function deposit(address _account, address _token, uint _amount) external;
  function withdraw(address _token, uint _amount) external;
  function withdrawAll(address _token) external;
  function transferLp(address _token, address _from, address _to, uint _amount) external;
  function supplySharesOf(address _token, address _account) external view returns(uint);
  function totalSupplyShares(address _token) external view returns(uint);
  function totalSupplyAmount(address _token) external view returns(uint);
  function totalDebtShares(address _token) external view returns(uint);
  function totalDebtAmount(address _token) external view returns(uint);
  function supplyOf(address _token, address _account) external view returns(uint);

  function supplyBalanceConverted(
    address _account,
    address _suppliedToken,
    address _returnToken
  ) external view returns(uint);
}

interface ILendingController is IOwnable {
  function interestRateModel() external view returns(address);
  function liqFeeSystem(address _token) external view returns(uint);
  function liqFeeCaller(address _token) external view returns(uint);
  function uniMinOutputPct() external view returns(uint);
  function colFactor(address _token) external view returns(uint);
  function depositLimit(address _lendingPair, address _token) external view returns(uint);
  function borrowLimit(address _lendingPair, address _token) external view returns(uint);
  function depositsEnabled() external view returns(bool);
  function borrowingEnabled() external view returns(bool);
  function tokenPrice(address _token) external view returns(uint);
  function tokenPrices(address _tokenA, address _tokenB) external view returns (uint, uint);
  function tokenSupported(address _token) external view returns(bool);
}

contract Ownable is IOwnable {

  uint public constant RENOUNCE_TIMEOUT = 12 hours;

  address public override owner;
  address public pendingOwner;
  uint public renouncedAt;

  event OwnershipTransferInitiated(address indexed previousOwner, address indexed newOwner);
  event OwnershipTransferConfirmed(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferConfirmed(address(0), msg.sender);
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function transferOwnership(address _newOwner) external override onlyOwner {
    require(_newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferInitiated(owner, _newOwner);
    pendingOwner = _newOwner;
  }

  function acceptOwnership() external override {
    require(msg.sender == pendingOwner, "Ownable: caller is not pending owner");
    emit OwnershipTransferConfirmed(msg.sender, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }

  function initiateRenounceOwnership() external onlyOwner {
    require(renouncedAt == 0, "Ownable: already initiated");
    renouncedAt = block.timestamp;
  }

  function acceptRenounceOwnership() external onlyOwner {
    require(renouncedAt > 0, "Ownable: not initiated");
    require(block.timestamp - renouncedAt > RENOUNCE_TIMEOUT, "Ownable: too early");
    owner = address(0);
    pendingOwner = address(0);
    renouncedAt = 0;
  }

  function cancelRenounceOwnership() external onlyOwner {
    require(renouncedAt > 0, "Ownable: not initiated");
    renouncedAt = 0;
  }
}

contract LPTokenMaster is ILPTokenMaster, Ownable {

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
  event NameChange(string _name, string _symbol);

  mapping (address => mapping (address => uint)) public override allowance;

  address public override underlying;
  address public lendingController;
  string  public name   = "WILD-LP";
  string  public symbol = "WILD-LP";
  bool    private initialized;
  uint8   public constant override decimals = 18;

  modifier onlyOperator() {
    require(msg.sender == ILendingController(lendingController).owner(), "LPToken: caller is not an operator");
    _;
  }

  function initialize(address _underlying, address _lendingController) external override {
    require(initialized != true, "LPToken: already intialized");
    owner = msg.sender;
    underlying = _underlying;
    lendingController = _lendingController;
    initialized = true;
  }

  // LP tokens can be created by anyone. Some tokens are not suitable for automated naming.
  // This function allow the operator to set a unique name for each LP token.
  function updateName(string memory _name, string memory _symbol) external onlyOperator {
    name   = _name;
    symbol = _symbol;
    emit NameChange(_name, _symbol);
  }

  function transfer(address _recipient, uint _amount) external override returns(bool) {
    _transfer(msg.sender, _recipient, _amount);
    return true;
  }

  function approve(address _spender, uint _amount) external override returns(bool) {
    _approve(msg.sender, _spender, _amount);
    return true;
  }

  function transferFrom(address _sender, address _recipient, uint _amount) external override returns(bool) {
    _approve(_sender, msg.sender, allowance[_sender][msg.sender] - _amount);
    _transfer(_sender, _recipient, _amount);
    return true;
  }

  function lendingPair() external view override returns(address) {
    return owner;
  }

  function balanceOf(address _account) external view override returns(uint) {
    return ILendingPair(owner).supplySharesOf(underlying, _account);
  }

  function totalSupply() external view override returns(uint) {
    return ILendingPair(owner).totalSupplyShares(underlying);
  }

  function _transfer(address _sender, address _recipient, uint _amount) internal {
    require(_sender != address(0), "ERC20: transfer from the zero address");
    require(_recipient != address(0), "ERC20: transfer to the zero address");

    ILendingPair(owner).transferLp(underlying, _sender, _recipient, _amount);

    emit Transfer(_sender, _recipient, _amount);
  }

  function _approve(address _owner, address _spender, uint _amount) internal {
    require(_owner != address(0), "ERC20: approve from the zero address");
    require(_spender != address(0), "ERC20: approve to the zero address");

    allowance[_owner][_spender] = _amount;
    emit Approval(_owner, _spender, _amount);
  }
}