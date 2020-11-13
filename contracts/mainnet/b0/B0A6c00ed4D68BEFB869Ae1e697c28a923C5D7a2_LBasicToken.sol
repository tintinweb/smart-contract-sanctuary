pragma solidity 0.5.12;

import "./IERC1820Registry.sol";
import "./IERC777Sender.sol";
import "./IERC777Recipient.sol";
import "./SafeMath.sol";

library LBasicToken {
  using SafeMath for uint256;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Sent(address indexed operator, address indexed from, address indexed to, uint256 amount, bytes data,
      bytes operatorData);
  event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);
  event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);
  event AuthorizedOperator(address indexed operator, address indexed holder);
  event RevokedOperator(address indexed operator, address indexed holder);

  // Universal address as defined in Registry Contract Address section of https://eips.ethereum.org/EIPS/eip-1820
  IERC1820Registry constant internal ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
  bytes32 constant internal TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
  bytes32 constant internal TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

  struct TokenState {
    uint256 totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) approvals;
    mapping(address => mapping(address => bool)) authorizedOperators;
    address[] defaultOperators;
    mapping(address => bool) defaultOperatorIsRevoked;
  }

  function init(TokenState storage _tokenState, uint8 _decimals, uint256 _initialSupply)
    external
  {
    _tokenState.defaultOperators.push(address(this));
    _tokenState.totalSupply = _initialSupply.mul(10**uint256(_decimals));
    _tokenState.balances[msg.sender] = _tokenState.totalSupply;
    ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC777Token"), address(this));
    ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC20Token"), address(this));
  }

  function transferFrom(TokenState storage _tokenState, address _from, address _to, uint256 _value)
    external
  {
    require(_tokenState.approvals[_from][msg.sender] >= _value, "Amount not approved");
    _tokenState.approvals[_from][msg.sender] = _tokenState.approvals[_from][msg.sender].sub(_value);
    doSend(_tokenState, msg.sender, _from, _to, _value, "", "", false);
  }

  function approve(TokenState storage _tokenState, address _spender, uint256 _value)
    external
  {
    require(_spender != address(0), "Cannot approve to zero address");
    _tokenState.approvals[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
  }

  function authorizeOperator(TokenState storage _tokenState, address _operator)
    external
  {
    require(_operator != msg.sender, "Self cannot be operator");
    if (_operator == address(this))
      _tokenState.defaultOperatorIsRevoked[msg.sender] = false;
    else
      _tokenState.authorizedOperators[_operator][msg.sender] = true;
    emit AuthorizedOperator(_operator, msg.sender);
  }

  function revokeOperator(TokenState storage _tokenState, address _operator)
    external
  {
    require(_operator != msg.sender, "Self cannot be operator");
    if (_operator == address(this))
      _tokenState.defaultOperatorIsRevoked[msg.sender] = true;
    else
      _tokenState.authorizedOperators[_operator][msg.sender] = false;
    emit RevokedOperator(_operator, msg.sender);
  }

  function doMint(TokenState storage _tokenState, address _to, uint256 _amount)
    external
  {
    assert(_to != address(0));

    _tokenState.totalSupply = _tokenState.totalSupply.add(_amount);
    _tokenState.balances[_to] = _tokenState.balances[_to].add(_amount);

    // From ERC777: The token contract MUST call the tokensReceived hook after updating the state.
    receiveHook(address(this), address(0), _to, _amount, "", "", true);

    emit Minted(address(this), _to, _amount, "", "");
    emit Transfer(address(0), _to, _amount);
  }

  function doBurn(TokenState storage _tokenState, address _operator, address _from, uint256 _amount, bytes calldata _data,
      bytes calldata _operatorData)
    external
  {
    assert(_from != address(0));
    // From ERC777: The token contract MUST call the tokensToSend hook before updating the state.
    sendHook(_operator, _from, address(0), _amount, _data, _operatorData);

    _tokenState.balances[_from] = _tokenState.balances[_from].sub(_amount);
    _tokenState.totalSupply = _tokenState.totalSupply.sub(_amount);

    emit Burned(_operator, _from, _amount, _data, _operatorData);
    emit Transfer(_from, address(0), _amount);
  }

  function doSend(TokenState storage _tokenState, address _operator, address _from, address _to, uint256 _amount,
      bytes memory _data, bytes memory _operatorData, bool _enforceERC777)
    public
  {
    assert(_from != address(0));

    require(_to != address(0), "Zero address cannot receive funds");
    // From ERC777: The token contract MUST call the tokensToSend hook before updating the state.
    sendHook(_operator, _from, _to, _amount, _data, _operatorData);

    _tokenState.balances[_from] = _tokenState.balances[_from].sub(_amount);
    _tokenState.balances[_to] = _tokenState.balances[_to].add(_amount);

    emit Sent(_operator, _from, _to, _amount, _data, _operatorData);
    emit Transfer(_from, _to, _amount);

    // From ERC777: The token contract MUST call the tokensReceived hook after updating the state.
    receiveHook(_operator, _from, _to, _amount, _data, _operatorData, _enforceERC777);
  }

  function receiveHook(address _operator, address _from, address _to, uint256 _amount, bytes memory _data,
      bytes memory _operatorData, bool _enforceERC777)
    public
  {
    address implementer = ERC1820_REGISTRY.getInterfaceImplementer(_to, TOKENS_RECIPIENT_INTERFACE_HASH);
    if (implementer != address(0))
      IERC777Recipient(implementer).tokensReceived(_operator, _from, _to, _amount, _data, _operatorData);
    else if (_enforceERC777)
      require(!isContract(_to), "Contract must be registered with ERC1820 as implementing ERC777TokensRecipient");
  }

  function sendHook(address _operator, address _from, address _to, uint256 _amount, bytes memory _data,
      bytes memory _operatorData)
    public
  {
    address implementer = ERC1820_REGISTRY.getInterfaceImplementer(_from, TOKENS_SENDER_INTERFACE_HASH);
    if (implementer != address(0))
      IERC777Sender(implementer).tokensToSend(_operator, _from, _to, _amount, _data, _operatorData);
  }

  function isContract(address _account)
    private
    view
    returns (bool isContract_)
  {
    uint256 size;

    assembly {
      size := extcodesize(_account)
    }

    isContract_ = size != 0;
  }
}