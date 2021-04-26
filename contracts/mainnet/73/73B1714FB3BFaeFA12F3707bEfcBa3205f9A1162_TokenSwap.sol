/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

// File: access/HasAdmin.sol

pragma solidity 0.5.17;


contract HasAdmin {
  event AdminChanged(address indexed _oldAdmin, address indexed _newAdmin);
  event AdminRemoved(address indexed _oldAdmin);

  address public admin;

  modifier onlyAdmin {
    require(msg.sender == admin, "HasAdmin: not admin");
    _;
  }

  constructor() internal {
    admin = msg.sender;
    emit AdminChanged(address(0), admin);
  }

  function changeAdmin(address _newAdmin) external onlyAdmin {
    require(_newAdmin != address(0), "HasAdmin: new admin is the zero address");
    emit AdminChanged(admin, _newAdmin);
    admin = _newAdmin;
  }

  function removeAdmin() external onlyAdmin {
    emit AdminRemoved(admin);
    admin = address(0);
  }
}

// File: token/erc20/IERC20.sol

pragma solidity 0.5.17;


interface IERC20 {
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function totalSupply() external view returns (uint256 _supply);
  function balanceOf(address _owner) external view returns (uint256 _balance);

  function approve(address _spender, uint256 _value) external returns (bool _success);
  function allowance(address _owner, address _spender) external view returns (uint256 _value);

  function transfer(address _to, uint256 _value) external returns (bool _success);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool _success);
}

// File: MainchainGateway.sol

pragma solidity 0.5.17;


contract MainchainGateway {
  function depositERC20For(address _user, address _token, uint256 _amount) external returns (uint256);
}

// File: TokenSwap.sol

pragma solidity 0.5.17;





/**
  * Smart contract wallet to support swapping between old ERC-20 token to a new contract.
  * It also supports swap and deposit into mainchainGateway in a single transaction.
  * Pre-requisites: New token needs to be transferred to this contract.
  * Dev should check that the decimals and supply of old token and new token are identical.
 */
contract TokenSwap is HasAdmin {
  IERC20 public oldToken;
  IERC20 public newToken;
  MainchainGateway public mainchainGateway;

  constructor(
    IERC20 _oldToken,
    IERC20 _newToken
  )
    public
  {
    oldToken = _oldToken;
    newToken = _newToken;
  }

  function setGateway(MainchainGateway _mainchainGateway) external onlyAdmin {
    if (address(mainchainGateway) != address(0)) {
      require(newToken.approve(address(mainchainGateway), 0));
    }

    mainchainGateway = _mainchainGateway;
    require(newToken.approve(address(mainchainGateway), uint256(-1)));
  }

  function swapToken() external {
    uint256 _balance = oldToken.balanceOf(msg.sender);
    require(oldToken.transferFrom(msg.sender, address(this), _balance));
    require(newToken.transfer(msg.sender, _balance));
  }

  function swapAndBridge(address _recipient, uint256 _amount) external {
    require(_recipient != address(0), "TokenSwap: recipient is the zero address");
    uint256 _balance = oldToken.balanceOf(msg.sender);
    require(oldToken.transferFrom(msg.sender, address(this), _balance));

    require(_amount <= _balance);
    require(newToken.transfer(msg.sender, _balance - _amount));
    mainchainGateway.depositERC20For(_recipient, address(newToken), _amount);
  }

  function swapAndBridgeAll(address _recipient) external {
    require(_recipient != address(0), "TokenSwap: recipient is the zero address");
    uint256 _balance = oldToken.balanceOf(msg.sender);
    require(oldToken.transferFrom(msg.sender, address(this), _balance));
    mainchainGateway.depositERC20For(_recipient, address(newToken), _balance);
  }

  // Used when some old token lost forever
  function withdrawToken() external onlyAdmin {
    newToken.transfer(msg.sender, newToken.balanceOf(address(this)));
  }
}