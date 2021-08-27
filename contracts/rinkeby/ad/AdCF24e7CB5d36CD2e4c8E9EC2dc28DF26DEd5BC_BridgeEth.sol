pragma solidity ^0.8.0;
//SPDX-License-Identifier:MIT

import "./IToken.sol";
import "./IERC20.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

contract BridgeEth is Initializable {

  address public admin;
  IToken public token;
  IERC20 public token_;

  uint public nonce;
  address public feepayer;
  mapping(uint => bool) public processedNonces;

  // mapping(address => mapping(uint => bool)) public processedNonces;

  enum Step { TransferTo, TransferFrom }
  event Transfer(
    address from,
    address to,
    uint amount,
    uint date,
    uint nonce,
    Step indexed step
  );

  event OwnershipTransferred(address indexed _from, address indexed _to);

  function initialize(address _token) public initializer{
    admin = msg.sender;
    token = IToken(_token);
    token_ = IERC20(_token);
  }

   // transfer Ownership to other address
  function transferOwnership(address _newOwner) public {
      require(_newOwner != address(0x0));
      require(msg.sender == admin);   
      emit OwnershipTransferred(admin,_newOwner);
      admin = _newOwner; 
  }
    
  // transfer Ownership to other address
  function transferTokenOwnership(address _newOwner) public {
      require(_newOwner != address(0x0));
      require(msg.sender == admin);
      token.changeOwnership(_newOwner);
  }    

  function transferToContract(address to, uint amount) external { 
    token_.transferFrom(address(msg.sender), address(this), amount);
    emit Transfer(
      msg.sender,
      to,
      amount,
      block.timestamp,
      nonce,
      Step.TransferTo
    );
    nonce++;
  }

  function transferFromContract(address to, uint amount, uint otherChainNonce) external { 
    require(msg.sender == admin, 'only admin');
    require(processedNonces[otherChainNonce] == false, 'transfer already processed');
    processedNonces[otherChainNonce] = true;
    token_.transfer(to, amount);
    emit Transfer(
      msg.sender,
      to,
      amount,
      block.timestamp,
      otherChainNonce,
      Step.TransferFrom
    );
  }
}

pragma solidity ^0.8.0;

//SPDX-License-Identifier:MIT

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

pragma solidity ^0.8.0;
//SPDX-License-Identifier:MIT

interface IToken {
  function mint(address to, uint amount) external;
  function burn(address owner, uint amount) external;
  function changeOwnership(address  _newOwner) external;
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}