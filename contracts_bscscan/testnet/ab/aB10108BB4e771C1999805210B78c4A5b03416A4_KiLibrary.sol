// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libs/token/ERC20/IERC20.sol";

library KiLibrary {

  address constant public BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
  uint256 constant public ARGS_VERSION = 1;
  bytes32 constant public REQUEST_SPECID = 0x6266643464393434313764303439366261373335373564346462343139616136;
  bytes32 constant public SYN_SPECID = 0x3836313137383965303233343461316339643239653637343839616433393266;
  bytes32 constant public REMOVE_SPECID = 0x3031303763376236666434353439386462363465356636613831326133393164;

  struct UserInfo {
    uint256 nonce;
    mapping(bytes32 => bytes32) commitments;
    mapping(uint256 => mapping(uint256 => Transaction[])) transactions;
    mapping(IERC20 => uint256) tokenBalance;
    mapping(IERC20 => uint256) pendingTokenBalance;
    mapping(IERC20 => uint256) pendingLiquidityBalance;
    mapping(uint256 => bytes32) pendingToChainRequestId;
    mapping(bytes32 => LiquidityRequest) requestData;
  }
  struct TokenInfo {
    bool liquidable;
    bytes4 tokenInFunctionId;
    bytes4 tokenOutFunctionId;
    mapping(uint256 => IERC20) toChainToken;
  }
  struct LiquidityInfo {
    uint256 toAllChainableBalance;
    mapping(uint256 => uint256) pendingLiquidityToChain;
    mapping(uint256 => uint256) fulfilledLiquidityFromChain;
  }
  struct Transaction {
    IERC20 sendToken; 
    uint256 amount;
    IERC20 receiveToken;
    bool isRemoveLiq;
  }
  struct LiquidityRequest {
    bytes32 requestId;
    bytes32 params;
    uint256 expiration;
    IERC20 token;
    uint256 toChainId;
    uint256 amount;
    bool isRemoveLiq;
    bool isSuccess;
  }

  event OracleRequest(
    bytes32 indexed specId,
    address requester,
    bytes32 requestId,
    uint256 payment,
    address callbackAddr,
    bytes4 callbackFunctionId,
    uint256 cancelExpiration,
    uint256 dataVersion,
    bytes data
  );
  event FulfilledTransaction(
    address indexed user, 
    uint256 indexed fromChainId, 
    uint256 indexed toChainId, 
    IERC20 sendToken, 
    IERC20 receiveToken, 
    uint256 amount
  );

  function tonkenInDecimalsAmount(
    IERC20 _token, 
    uint256 _amount
  ) 
    internal 
    view
    returns (uint256 decimalsAmount)
  {
    uint8 decimals = IERC20(_token).decimals();
    decimalsAmount = _amount * 10**(18 - decimals);
  }

  function tonkenOutDecimalsAmount(
    IERC20 _token, 
    uint256 _amount
  ) 
    internal 
    view
    returns (uint256 decimalsAmount)
  {
    uint8 decimals = IERC20(_token).decimals();
    decimalsAmount = _amount / 10**(18 - decimals);
  }

  function liquidityFromChainHelper(
    LiquidityInfo storage _liquidityInfoToken,
    uint256 _chainId,
    uint256 _amount
  ) 
    internal 
  {
    if (_liquidityInfoToken.pendingLiquidityToChain[_chainId] >= _amount) {
      _liquidityInfoToken.pendingLiquidityToChain[_chainId] -= _amount;
    } else {
      _liquidityInfoToken.fulfilledLiquidityFromChain[_chainId] =
      _liquidityInfoToken.fulfilledLiquidityFromChain[_chainId] +
      _amount - _liquidityInfoToken.pendingLiquidityToChain[_chainId];
      _liquidityInfoToken.pendingLiquidityToChain[_chainId] = 0;
    }
  }
  
  function liquidityToChainHelper(
    LiquidityInfo storage _liquidityInfoToken,
    uint256 _chainId,
    uint256 _amount
  ) 
    internal
  {
    if (_liquidityInfoToken.fulfilledLiquidityFromChain[_chainId] >= _amount) {
      _liquidityInfoToken.fulfilledLiquidityFromChain[_chainId] -= _amount;
    } else {
      _liquidityInfoToken.pendingLiquidityToChain[_chainId] = 
      _liquidityInfoToken.pendingLiquidityToChain[_chainId] +
      _amount - _liquidityInfoToken.fulfilledLiquidityFromChain[_chainId];
      _liquidityInfoToken.fulfilledLiquidityFromChain[_chainId] = 0;
    }
  }

  function checkTokenInFunctionId(bytes4 _tokenInFunctionId) internal pure {
    require(
      _tokenInFunctionId == IKiBridge.tokenInReqTransferToChainAddLiq.selector ||
      _tokenInFunctionId == IKiBridge.tokenInBridgeToChain.selector ||
      _tokenInFunctionId == IKiBridge.tokenInBurnToChain.selector ||
      _tokenInFunctionId == IKiBridge.tokenInBurnFromToChain.selector ||
      _tokenInFunctionId == IKiBridge.tokenInBurnToBurnAddrToChain.selector,
       "Must use whitelisted functions"
    );
  }

  function checkTokenOutFunctionId(bytes4 _executeFunctionId) internal pure {
    require(
      _executeFunctionId == IKiBridge.tokenOutTransferToUser.selector ||
      _executeFunctionId == IKiBridge.tokenOutMintToUser.selector,
       "Must use whitelisted functions"
    );
  }

  function tokenInCheck(TokenInfo storage _tokenInfoToken, bytes4 _functionId) internal view {
    require(_tokenInfoToken.tokenInFunctionId == _functionId, "FunctionId Not Permitted");
  }

  function checkAmount(uint256 _amount) internal pure {
    require(_amount > 0,"Amount must be greater than zero");
  }
  function checkMaintenance(bool _maintenance) internal pure {
    require(!_maintenance, "KiBridge: Under maintenance");
  }
  function getWhitelistedFunctionId(
  )
    external 
    pure 
    returns (
      bytes4 tokenInReqTransferToChainAddLiqId, 
      bytes4 tokenInBridgeToChainId, 
      bytes4 tokenInBurnToChainId, 
      bytes4 tokenInBurnFromToChainId, 
      bytes4 tokenInBurnToBurnAddrToChainId, 
      bytes4 tokenOutTransferToUserId, 
      bytes4 tokenOutMintToUserId
    ) 
  {
    return (
      IKiBridge.tokenInReqTransferToChainAddLiq.selector,
      IKiBridge.tokenInBridgeToChain.selector,
      IKiBridge.tokenInBurnToChain.selector,
      IKiBridge.tokenInBurnFromToChain.selector,
      IKiBridge.tokenInBurnToBurnAddrToChain.selector,
      IKiBridge.tokenOutTransferToUser.selector,
      IKiBridge.tokenOutMintToUser.selector
    );
  }
}

interface IKiBridge {

  function tokenInReqTransferToChainAddLiq(
    uint256 toChainId, 
    IERC20 token, 
    uint256 amount
  ) external ;

  function tokenInBridgeToChain(
    uint256 toChainId,
    IERC20 token, 
    uint256 amount
  ) external ;

  function tokenInBurnToChain(
    uint256 toChainId,
    IERC20 token, 
    uint256 amount
  ) external ;

  function tokenInBurnFromToChain(
    uint256 toChainId,
    IERC20 token, 
    uint256 amount
  ) external ;

  function tokenInBurnToBurnAddrToChain(
    uint256 toChainId,
    IERC20 token, 
    uint256 amount
  ) external ;

  function tokenOutTransferToUser(
    address _user, 
    IERC20 _token, 
    uint256 _amount
  ) external ;

  function tokenOutMintToUser(
    address _user, 
    IERC20 _token, 
    uint256 _amount
  ) external ;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
  
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}