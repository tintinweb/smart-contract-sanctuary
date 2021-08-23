//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IDES is IERC20 {
  function owner() external view returns (address);
}

contract DesBridgeETHEREUM {
  
  IDES private token;

  bytes32 public constant ETHEREUM_CHAIN_HASH = keccak256("ETHEREUM_CHAIN_HASH");
  bytes32 public constant BSC_CHAIN_HASH = keccak256("BSC_CHAIN_HASH");
  bytes32 public constant HECO_CHAIN_HASH = keccak256("HECO_CHAIN_HASH");

  uint public nonce;
  uint public platformFee;    //1000 = 1%
  address public admin;
  address public platformWallet;
  
  mapping(bytes32 => mapping(uint => bool)) private processedNonces;

  enum Step { 
    Burn, 
    Mint 
  }
  
  event Trigger(
    address from,
    address to,
    uint amount,
    uint date,
    uint nonce,
    bytes32 fromChain,
    bytes32 toChain,
    Step indexed step
  );

  event FeeSet(
    address owner,
    uint fee,
    uint timestamp
  );

  event WalletSet(
    address owner,
    address wallet,
    uint timestamp
  );

  event AdminSet(
    address owner,
    address admin,
    uint timestamp
  );

  constructor(
    address _token,
    address _admin,
    address _platformWallet,
    uint _platformFee
    ) {

    token = IDES(_token);
    admin = _admin;
    platformWallet = _platformWallet;
    platformFee = _platformFee;
  }

  modifier onlyValidChain(
    bytes32 chainHash
    ) {

    require(
      chainHash == BSC_CHAIN_HASH
      || chainHash == HECO_CHAIN_HASH,
      "Error: invalid chain hash"
    );
    _;
  }

  modifier onlyOwner() {
    
    require(
      msg.sender == token.owner(),
      "Only token contract owner"
    );
    _;
  }

  function bridge(
    address to, 
    uint amount,
    bytes32 chainToMint
    ) external onlyValidChain(chainToMint) {
    
    uint fee = (amount * platformFee) / (100 * 1000);
    uint actual = amount - fee;

    require(
      token
        .transferFrom(
          msg.sender, 
          address(this),
          actual
        )
      &&
      token
        .transferFrom(
          msg.sender,
          platformWallet,
          fee
        ),
      "Error: failed to collect tokens from user"
    );

    bytes32 fromChainHash = ETHEREUM_CHAIN_HASH;
    uint nonce_ = nonce;
    nonce++;
    
    emit Trigger(
      msg.sender,
      to,
      actual,
      block.timestamp,
      nonce_,
      fromChainHash,
      chainToMint,
      Step.Burn
    );
  }

  function mint(
    address to, 
    uint amount, 
    uint fromChainNonce,
    bytes32 fromChainHash
    ) external onlyValidChain(fromChainHash) {
    
    require(
      msg.sender == admin, 
      "Error: only admin function"
    );

    require(
      !processedNonces[fromChainHash][fromChainNonce], 
      "Error: transfer has already been processed"
    );

    processedNonces[fromChainHash][fromChainNonce] = true;
    
    require(
      token
        .transfer(
          to,
          amount
        ),
      "Error: failed to send tokens to user"
    );

    bytes32 toChainHash = ETHEREUM_CHAIN_HASH;

    emit Trigger(
      msg.sender,
      to,
      amount,
      block.timestamp,
      fromChainNonce,
      fromChainHash,
      toChainHash,
      Step.Mint
    );
  }

  function setFee(
    uint _fee
    ) external onlyOwner() {

    platformFee = _fee;
    
    emit FeeSet(
      msg.sender,
      _fee, 
      block.timestamp
    );
  }

  function setPlatformWallet(
    address _platformWallet
    ) external onlyOwner() {

    platformWallet = _platformWallet;
    
    emit WalletSet(
      msg.sender,
      _platformWallet, 
      block.timestamp
    );
  }

  function setAdmin(
    address _admin
    ) external onlyOwner() {

    admin = _admin;
    
    emit AdminSet(
      msg.sender,
      _admin, 
      block.timestamp
    );
  }

  function hasProcessedNonce(
    uint _nonce,
    bytes32 chainHash
    ) external 
    view 
    onlyValidChain(chainHash) returns(bool) {

    return processedNonces[chainHash][_nonce];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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