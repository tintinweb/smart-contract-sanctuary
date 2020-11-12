pragma solidity 0.5.12;

import "./IERC777.sol";
import "./IERC20.sol";
import "./LBasicToken.sol";
import "./PDelegate.sol";
import "./Owned.sol";

contract BasicToken is IERC777, IERC20, Owned, PDelegate {

  uint8 public constant decimals = 18;
  uint256 public constant granularity = 1;
  string public name;
  string public symbol;

  LBasicToken.TokenState private tokenState;
  address public extensionContract; // TODO: Move to tokenState?

  event LogContractExtended(address indexed extensionContract);

  constructor(string memory _name, string memory _symbol, uint256 _initialSupply)
    public
  {
    require(bytes(_name).length != 0, "Needs a name");
    require(bytes(_symbol).length != 0, "Needs a symbol");
    name = _name;
    symbol = _symbol;
    LBasicToken.init(tokenState, decimals, _initialSupply);
  }

  modifier onlyOperator(address _holder) {
    require(isOperatorFor(msg.sender, _holder), "Not an operator");
    _;
  }

  // MUST be overriden by any extension contract to avoid recursion of delegateFwd calls.
  function ()
    external
  {
    require(extensionContract != address(0), "Extended functionality contract not found");
    delegatedFwd(extensionContract, msg.data);
  }

  function extend(address _extensionContract)
    external
    onlyOwner
  {
    extensionContract = _extensionContract;
    emit LogContractExtended(_extensionContract);
  }

  function balanceOf(address _holder)
    external
    view
    returns (uint256 balance_)
  {
    balance_ = tokenState.balances[_holder];
  }

  function transfer(address _to, uint256 _value)
    external
    returns (bool success_)
  {
    doSend(msg.sender, msg.sender, _to, _value, "", "", false);
    success_ = true;
  }

  function transferFrom(address _from, address _to, uint256 _value)
    external
    returns (bool success_)
  {
    LBasicToken.transferFrom(tokenState, _from, _to, _value);
    success_ = true;
  }

  function approve(address _spender, uint256 _value)
    external
    returns (bool success_)
  {
    LBasicToken.approve(tokenState, _spender, _value);
    success_ = true;
  }

  function allowance(address _holder, address _spender)
    external
    view
    returns (uint256 remaining_)
  {
    remaining_ = tokenState.approvals[_holder][_spender];
  }

  function defaultOperators()
    external
    view
    returns (address[] memory)
  {
    return tokenState.defaultOperators;
  }

  function authorizeOperator(address _operator)
    external
  {
    LBasicToken.authorizeOperator(tokenState, _operator);
  }

  function revokeOperator(address _operator)
    external
  {
    LBasicToken.revokeOperator(tokenState, _operator);
  }

  function send(address _to, uint256 _amount, bytes calldata _data)
    external
  {
    doSend(msg.sender, msg.sender, _to, _amount, _data, "", true);
  }

  function operatorSend(address _from, address _to, uint256 _amount, bytes calldata _data, bytes calldata _operatorData)
    external
    onlyOperator(_from)
  {
    doSend(msg.sender, _from, _to, _amount, _data, _operatorData, true);
  }

  function burn(uint256 _amount, bytes calldata _data)
    external
  {
    doBurn(msg.sender, msg.sender, _amount, _data, "");
  }

  function operatorBurn(address _from, uint256 _amount, bytes calldata _data, bytes calldata _operatorData)
    external
    onlyOperator(_from)
  {
    doBurn(msg.sender, _from, _amount, _data, _operatorData);
  }

  function totalSupply()
    external
    view
    returns (uint256 totalSupply_)
  {
    totalSupply_ = tokenState.totalSupply;
  }

  function isOperatorFor(address _operator, address _holder)
    public
    view
    returns (bool isOperatorFor_)
  {
    isOperatorFor_ = (_operator == _holder || tokenState.authorizedOperators[_operator][_holder]
        || _operator == address(this) && !tokenState.defaultOperatorIsRevoked[_holder]);
  }

  function doSend(address _operator, address _from, address _to, uint256 _amount, bytes memory _data,
      bytes memory _operatorData, bool _enforceERC777)
    internal
  {
    LBasicToken.doSend(tokenState, _operator, _from, _to, _amount, _data, _operatorData, _enforceERC777);
  }

  function doMint(address _to, uint256 _amount)
    internal
  {
    LBasicToken.doMint(tokenState, _to, _amount);
  }

  function doBurn(address _operator, address _from, uint256 _amount, bytes memory _data, bytes memory _operatorData)
    internal
  {
    LBasicToken.doBurn(tokenState, _operator, _from, _amount, _data, _operatorData);
  }
}