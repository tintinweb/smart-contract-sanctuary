// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libs/token/ERC20/IERC20.sol";
import "./interfaces/IKiBridgeV1Factory.sol";
import "./KiBridgeV1LiquidityDeployer.sol";
import "./KiBridgeV1Liquidity.sol";

contract KiBridgeV1Factory is IKiBridgeV1Factory, KiBridgeV1LiquidityDeployer {
  bytes32 public constant INIT_CODE_LIQ_HASH = keccak256(abi.encodePacked(type(KiBridgeV1Liquidity).creationCode));

  mapping(IERC20 => address) public getLiquidity;

  address[] public allLiquidities;

  function createLiquidity(
    IERC20 _token
  ) 
    public 
    override 
    returns (address liquidity)
  {
    require(getLiquidity[_token] == address(0), "Liquidity exists");
    liquidity = deploy(address(this), address(_token));
    getLiquidity[_token] = liquidity;
    allLiquidities.push(liquidity);
    emit LiquidityCreated(_token, liquidity, allLiquidities.length);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IKiBridgeV1LiquidityDeployer.sol";
import "./interfaces/IKiBridgeV1Liquidity.sol";
import "./KiERC20Permit.sol";

contract KiBridgeV1Liquidity is IKiBridgeV1Liquidity, KiERC20Permit {
  address public immutable override bridge;
  address public immutable override token;

  modifier onlyBridge() {
    require(bridge == _msgSender(), "caller is not the bridge");
    _;
  }

  constructor() KiERC20Permit("KiBridge V1 Liquidity", "KiB-V1-LIQ") {
    (bridge, token) = IKiBridgeV1LiquidityDeployer(msg.sender).parameters();
  }
  
  /// @notice Creates `_amount` token to `_to`. Must only be called by the bridge.
  function mint(address _to, uint256 _amount) public override onlyBridge {
    _mint(_to, _amount);
  }

  /**
    * @dev Destroys `amount` tokens from the caller.
    *
    * See {ERC20-_burn}.
    */
  function burn(uint256 amount) public override {
    _burn(_msgSender(), amount);
  }

  /**
    * @dev Destroys `amount` tokens from `account`, deducting from the caller's
    * allowance.
    *
    * See {ERC20-_burn} and {ERC20-allowance}.
    *
    * Requirements:
    *
    * - the caller must have allowance for ``accounts``'s tokens of at least
    * `amount`.
    */
  function burnFrom(address account, uint256 amount) public override {
    uint256 currentAllowance = allowance(account, _msgSender());
    require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
    unchecked {
        _approve(account, _msgSender(), currentAllowance - amount);
    }
    _burn(account, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IKiBridgeV1LiquidityDeployer.sol";
import "./KiBridgeV1Liquidity.sol";

contract  KiBridgeV1LiquidityDeployer is IKiBridgeV1LiquidityDeployer {

  struct Parameters {
    address bridge;
    address token;
  }

  Parameters public override parameters;

  function deploy(
    address _bridge,
    address _token
  ) 
  internal 
  returns (address liquidity) 
  {
    parameters = Parameters({bridge: _bridge, token: _token});
    liquidity = address(new KiBridgeV1Liquidity{salt: keccak256(abi.encode(_bridge, _token))}());
    delete parameters;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../libs/token/ERC20//utils/SafeERC20.sol";
import "../libs/token/ERC20/IERC20.sol";
import "./interfaces/IKiBridgeV1Liquidity.sol";
import "./KiBridgeV1Factory.sol";
import "./KiLibrary.sol";

contract KiBridgeV29 is KiBridgeV1Factory, Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  uint256 constant public BASE_FEE = 0.001 ether;

  address public authorizedNode;
  bool public maintenance = true;

  mapping(address => KiLibrary.UserInfo) private userInfo;
  mapping(IERC20 => KiLibrary.TokenInfo) private tokenInfo;
  mapping(IERC20 => KiLibrary.LiquidityInfo) private liquidityInfo;
  mapping(uint256 => mapping(IERC20 => IERC20)) public fromChainTokenReceiveToken;

  function setFulfillmentPermission(
    address _node
  )
    external
    onlyOwner
  {
    authorizedNode = _node;
  }
  function setMaintenance(
    bool IsMaintenance
  )
    external
    onlyOwner
  {
    maintenance = IsMaintenance;
  }
  function setTokenFromChainInfo(
    IERC20 _token, 
    bytes4 _executeFunctionId,
    uint256 _fromChainId, 
    IERC20 _fromChainToken
  )
    external
    onlyOwner
  {
    KiLibrary.checkTokenOutFunctionId(_executeFunctionId);
    tokenInfo[_token].tokenOutFunctionId = _executeFunctionId;
    fromChainTokenReceiveToken[_fromChainId][_fromChainToken] = _token;
  }
  function setTokenToChainInfo(
    IERC20 _token, 
    bool _liquidable,
    bytes4 _tokenInFunctionId, 
    uint256 _toChainId, 
    IERC20 _toChainToken
  )
    external
    onlyOwner
  {
    require(_toChainId != block.chainid, "Wrong chainId");
    KiLibrary.checkTokenInFunctionId(_tokenInFunctionId);
    tokenInfo[_token].liquidable = _liquidable;
    tokenInfo[_token].tokenInFunctionId = _tokenInFunctionId;
    tokenInfo[_token].toChainToken[_toChainId] = _toChainToken;
  }
  function liquidityFromChain(
    IERC20 _token,
    uint256 _chainId,
    uint256 _amount
  ) 
    private 
  {
    KiLibrary.liquidityFromChainHelper(liquidityInfo[_token], _chainId, _amount);
  }
  function liquidityToChain(
    IERC20 _token,
    uint256 _chainId,
    uint256 _amount
  ) 
    private
  {
    KiLibrary.liquidityToChainHelper(liquidityInfo[_token], _chainId, _amount);
  }
  function oracleRequest(
    bytes32 _specId,
    address _user,
    address _callbackAddress,
    bytes4 _callbackFunctionId,
    uint256 _fromChainId,
    uint256 _toChainId, 
    uint256 _txIndex, 
    bytes memory _data
  )
    private
    checkBaseFee(2)
    checkAddress(authorizedNode)
  {
    KiLibrary.checkMaintenance(maintenance);
    bytes32 requestId = keccak256(abi.encodePacked(_user, userInfo[_user].nonce));
    // solhint-disable-next-line not-rely-on-time
    uint256 expiration = block.timestamp + 5 minutes;
    userInfo[_user].nonce += 1;
    require(userInfo[_user].commitments[requestId] == 0, "Must use a unique ID");
    userInfo[_user].commitments[requestId] = keccak256(abi.encode(_callbackFunctionId,_fromChainId, _toChainId, _txIndex));
    payable(authorizedNode).transfer(address(this).balance);
    emit KiLibrary.OracleRequest(
      _specId,
      _user,
      requestId,
      msg.value,
      _callbackAddress,
      _callbackFunctionId,
      expiration,
      KiLibrary.ARGS_VERSION,
      _data);
  }
  function oracleLiquidityRequest(
    bytes32 _specId,
    address _callbackAddress,
    bytes4 _callbackFunctionId,
    IERC20 _token,
    uint256 _toChainId,
    uint256 _amount,
    bool _isRemoveLiq,
    bytes memory _data
  )
    private
    checkBaseFee(1)
    checkAddress(authorizedNode)
  {
    KiLibrary.checkMaintenance(maintenance);
    bytes32 requestId = keccak256(abi.encodePacked(msg.sender, userInfo[msg.sender].nonce));
    // solhint-disable-next-line not-rely-on-time
    uint256 expiration = block.timestamp + 5 minutes;
    userInfo[msg.sender].nonce += 1;
    require(userInfo[msg.sender].requestData[requestId].params == 0, "Must use a unique ID");
    userInfo[msg.sender].pendingToChainRequestId[_toChainId] = requestId;
    userInfo[msg.sender].requestData[requestId] = KiLibrary.LiquidityRequest({ 
        requestId: requestId,
        params: keccak256(abi.encode(_callbackAddress, _callbackFunctionId, expiration)),
        expiration: expiration,
        token: _token,
        toChainId: _toChainId,
        amount: _amount,
        isRemoveLiq: _isRemoveLiq,
        isSuccess: false
      });
    payable(authorizedNode).transfer(address(this).balance);
    emit KiLibrary.OracleRequest(
      _specId,
      msg.sender,
      requestId,
      msg.value,
      _callbackAddress,
      _callbackFunctionId,
      expiration,
      KiLibrary.ARGS_VERSION,
      _data);
  }
  function cancelLiquidityRequest(
    bytes32 _requestId,
    uint256 _toChainId
  ) 
    external
    nonReentrant
  {
    require(userInfo[msg.sender].pendingToChainRequestId[_toChainId] == _requestId, "RequestId not in pendingQueue");
    KiLibrary.LiquidityRequest memory liquidityRequest = userInfo[msg.sender].requestData[_requestId];
    require(liquidityRequest.params != 0, "Must have params");
    // solhint-disable-next-line not-rely-on-time
    require(liquidityRequest.expiration <= block.timestamp, "Request is not expired");
    delete userInfo[msg.sender].pendingToChainRequestId[_toChainId];
    liquidityFromChain(liquidityRequest.token,liquidityRequest.toChainId,liquidityRequest.amount);
    if (liquidityRequest.isRemoveLiq) {
      userInfo[msg.sender].pendingLiquidityBalance[liquidityRequest.token] -= liquidityRequest.amount;
      liquidityInfo[liquidityRequest.token].toAllChainableBalance += liquidityRequest.amount;
      IKiBridgeV1Liquidity(getLiquidity[liquidityRequest.token]).mint(msg.sender, liquidityRequest.amount);
    } else {
      userInfo[msg.sender].pendingTokenBalance[liquidityRequest.token] -= liquidityRequest.amount;
      uint256 decimalsAmount = KiLibrary.tonkenOutDecimalsAmount(liquidityRequest.token, liquidityRequest.amount);
      liquidityRequest.token.safeTransfer(msg.sender, decimalsAmount);
    }
  }
  function fulfillTransaction(
    bytes32 _requestId, 
    bytes4 _fulfillFunctionId,
    address _user,
    uint256 _fromChainId,
    uint256 _toChainId, 
    uint256 _txIndex, 
    IERC20 _sendToken,
    uint256 _amount,
    IERC20 _receiveToken,
    bool _isRemoveLiq
  ) 
    external 
    onlyAuthorizedNode
  {
    require(
      userInfo[_user].commitments[_requestId] == keccak256(abi.encode(_fulfillFunctionId,_fromChainId, _toChainId, _txIndex)),
       "Params do not match request ID"
    );
    require(
      userInfo[_user].transactions[_fromChainId][_toChainId].length == _txIndex,
       "Transactions index out of order"
    );
    require(_toChainId == block.chainid, "Wrong chainId");
    delete userInfo[_user].commitments[_requestId];
    _receiveToken = fromChainTokenReceiveToken[_fromChainId][_sendToken];
    userInfo[_user].transactions[_fromChainId][_toChainId].push(
      KiLibrary.Transaction({
        sendToken: _sendToken,
        amount: _amount,
        receiveToken: _receiveToken,
        isRemoveLiq: _isRemoveLiq
      })
    );
    userInfo[_user].tokenBalance[_receiveToken] += _amount;
    if (tokenInfo[_receiveToken].liquidable) {
      liquidityFromChain(_receiveToken,_fromChainId,_amount);
    }
    if (tokenInfo[_receiveToken].tokenOutFunctionId == this.tokenOutTransferToUser.selector) {
      tokenOutTransferToUser(_user,_receiveToken,_amount);
    } else if (tokenInfo[_receiveToken].tokenOutFunctionId == this.tokenOutMintToUser.selector) {
      tokenOutMintToUser(_user,_receiveToken,_amount);
    }
    emit KiLibrary.FulfilledTransaction(
      _user, 
      _fromChainId, 
      _toChainId, 
      _sendToken, 
      _receiveToken, 
      _amount
    );
  }
  function fulfillLiquidity(
    bytes32 _requestId, 
    bytes4 _fulfillFunctionId,
    address _user,
    uint256 _expiration, 
    uint256 _calAmount,
    bytes calldata _data
  ) 
    external 
    onlyAuthorizedNode
  {
    (uint256 fromChainId, uint256 toChainId, IERC20 token, uint256 amount) = abi.decode(
      _data, (uint256, uint256, IERC20, uint256));
    require(userInfo[_user].pendingToChainRequestId[toChainId] == _requestId, "RequestId not in pendingQueue");
    require(
      userInfo[_user].requestData[_requestId].params == keccak256(
        abi.encode(address(this),_fulfillFunctionId, _expiration)),
       "Params do not match request ID"
    );
    delete userInfo[_user].pendingToChainRequestId[toChainId];
    delete userInfo[_user].requestData[_requestId].params;
    uint256 refund = amount - _calAmount;
    if (toChainId != block.chainid) liquidityFromChain(token,toChainId,refund);
    if (userInfo[_user].requestData[_requestId].isRemoveLiq) {
      userInfo[_user].pendingLiquidityBalance[token] -= amount;
      liquidityInfo[token].toAllChainableBalance += refund;
      if (refund > 0) IKiBridgeV1Liquidity(getLiquidity[token]).mint(_user, refund);
    } else {
      userInfo[_user].pendingTokenBalance[token] -= amount;
      refund = KiLibrary.tonkenOutDecimalsAmount(token, refund);
      if (refund > 0) token.safeTransfer(_user, refund);
    }
    if (_calAmount == 0) {
      userInfo[_user].requestData[_requestId].isSuccess = false;
      return;
    }
    if (toChainId == block.chainid) {
      _calAmount = KiLibrary.tonkenOutDecimalsAmount(token, _calAmount);
      token.safeTransfer(_user, _calAmount);
    } else {
      (,,KiLibrary.Transaction memory transaction) = abi.decode(_data, (uint256, uint256, KiLibrary.Transaction));
      transaction.amount = _calAmount;
      userInfo[_user].transactions[fromChainId][toChainId].push(transaction);
    }
    userInfo[_user].requestData[_requestId].isSuccess = true;
  }
  function tokenInTransferToChain(
    uint256 _toChainId, 
    IERC20 _token, 
    uint256 _amount
  ) 
    private 
    checkBaseFee(1)
    checkAddress(address(tokenInfo[_token].toChainToken[_toChainId]))
  {
    KiLibrary.checkMaintenance(maintenance);
    KiLibrary.checkAmount(_amount);
    userInfo[msg.sender].transactions[block.chainid][_toChainId].push(
      KiLibrary.Transaction({
        sendToken: _token,
        amount: _amount,
        receiveToken: tokenInfo[_token].toChainToken[_toChainId],
        isRemoveLiq: false
      })
    );
  }
  function tokenInReqTransferToChainAddLiq(
    uint256 _toChainId, 
    IERC20 _token, 
    uint256 _amount
  ) 
    external 
    payable
    checkAddress(address(tokenInfo[_token].toChainToken[_toChainId]))
    nonReentrant
  {
    KiLibrary.checkAmount(_amount);
    KiLibrary.tokenInCheck(tokenInfo[_token], this.tokenInReqTransferToChainAddLiq.selector);
    require(_toChainId != block.chainid, "Wrong chainId");
    require(userInfo[msg.sender].pendingToChainRequestId[_toChainId] == 0, "number of requests exceeded");
    _amount = realTonkenTransferAmount(_token,address(this),_amount);
    userInfo[msg.sender].pendingTokenBalance[_token] += _amount;
    bytes memory data = abi.encode(
      block.chainid, 
      _toChainId,
      KiLibrary.Transaction({
        sendToken: _token,
        amount: _amount,
        receiveToken: tokenInfo[_token].toChainToken[_toChainId],
        isRemoveLiq: false
      }),
      liquidityInfo[_token].fulfilledLiquidityFromChain[_toChainId],
      liquidityInfo[_token].pendingLiquidityToChain[_toChainId]
    );
    liquidityToChain(_token,_toChainId,_amount);
    oracleLiquidityRequest(
      KiLibrary.REQUEST_SPECID,  
      address(this), 
      this.fulfillLiquidity.selector, 
      _token, 
      _toChainId,
      _amount, 
      false,
      data
    );
  }
  function liquidityInRemoveToChain(
    uint256 _toChainId, 
    IERC20 _token, 
    uint256 _amount
  ) 
    private 
  {
    require(userInfo[msg.sender].pendingToChainRequestId[_toChainId] == 0, "number of requests exceeded");
    userInfo[msg.sender].pendingLiquidityBalance[_token] += _amount;
    bytes32 specId;
    bytes memory data;
    if (_toChainId == block.chainid) {
      specId = KiLibrary.REMOVE_SPECID;
      data = abi.encode(
        block.chainid, 
        block.chainid, 
        _token,
        _amount
      );
    } else {
      specId = KiLibrary.REQUEST_SPECID;
      data = abi.encode(
        block.chainid, 
        _toChainId,
        KiLibrary.Transaction({
          sendToken: _token,
          amount: _amount,
          receiveToken: tokenInfo[_token].toChainToken[_toChainId],
          isRemoveLiq: true
        }),
        liquidityInfo[_token].fulfilledLiquidityFromChain[_toChainId],
        liquidityInfo[_token].pendingLiquidityToChain[_toChainId]
      );
      liquidityToChain(_token,_toChainId,_amount);
    }
    oracleLiquidityRequest(
      specId,  
      address(this), 
      this.fulfillLiquidity.selector, 
      _token, 
      _toChainId,
      _amount, 
      true,
      data
    );
  }
  function synTransaction(
    address _user,
    uint256 _synChainId,
    uint256 _txIndex
  ) 
    external 
    payable
    onlyNodeOrUser(_user)
  {
    require(
      userInfo[_user].transactions[_synChainId][block.chainid].length == _txIndex,
       "Transactions index out of order"
    );
    bytes memory data = abi.encode(_synChainId, block.chainid, _txIndex);
    oracleRequest(
      KiLibrary.SYN_SPECID, 
      _user,
      address(this), 
      this.fulfillTransaction.selector, 
      _synChainId,
      block.chainid,
      _txIndex,
      data);
  }

  function addLiquidity(
    IERC20 _token, 
    uint256 _amount
  ) 
    external 
    nonReentrant
  {
    KiLibrary.checkMaintenance(maintenance);
    KiLibrary.checkAmount(_amount);
    require(tokenInfo[_token].liquidable, "Not liquidable");
    _amount = realTonkenTransferAmount(_token,address(this),_amount);
    liquidityInfo[_token].toAllChainableBalance += _amount;
    if (getLiquidity[_token] == address(0)) { 
      createLiquidity(_token); 
    }
    IKiBridgeV1Liquidity(getLiquidity[_token]).mint(msg.sender, _amount);
  }
  function removeLiquidity(
    uint256 _toChainId,
    IERC20 _token,
    uint256 _amount
  ) 
    public
    payable
    nonReentrant
  {
    KiLibrary.checkAmount(_amount);
    require(tokenInfo[_token].liquidable, "Not liquidable");
    IKiBridgeV1Liquidity(getLiquidity[_token]).burnFrom(msg.sender, _amount);
    liquidityInfo[_token].toAllChainableBalance -= _amount;
    liquidityInRemoveToChain(_toChainId, _token, _amount);
  }
  function removeLiquidityWithPermit(
    uint256 _toChainId,
    IERC20 _token,
    uint256 _amount,
    uint256 _deadline,
    uint8 _v, 
    bytes32 _r, 
    bytes32 _s
  ) 
    external 
    payable
  {
    IERC20Permit(getLiquidity[_token]).permit(msg.sender, address(this), _amount, _deadline, _v, _r, _s);
    removeLiquidity(_toChainId, _token, _amount);
  }
  function tokenInBridgeToChain(
    uint256 _toChainId,
    IERC20 _token, 
    uint256 _amount
  ) 
    external 
    payable
    nonReentrant
  {
    KiLibrary.tokenInCheck(tokenInfo[_token], this.tokenInBridgeToChain.selector);
    _amount = realTonkenTransferAmount(_token,address(this),_amount);
    tokenInTransferToChain(_toChainId, _token, _amount);
  }
  function tokenInBurnToChain(
    uint256 _toChainId,
    IERC20 _token, 
    uint256 _amount
  ) 
    external 
    payable
    nonReentrant
  {
    KiLibrary.tokenInCheck(tokenInfo[_token], this.tokenInBurnToChain.selector);
    _amount = realTonkenTransferAmount(_token,address(this),_amount);
    IERC20(_token).burn(_amount);
    tokenInTransferToChain(_toChainId, _token, _amount);
  }
  function tokenInBurnFromToChain(
    uint256 _toChainId,
    IERC20 _token, 
    uint256 _amount
  ) 
    external 
    payable
    nonReentrant
  {
    KiLibrary.tokenInCheck(tokenInfo[_token], this.tokenInBurnFromToChain.selector);
    IERC20(_token).burnFrom(msg.sender,_amount);
    _amount = KiLibrary.tonkenInDecimalsAmount(_token,_amount);
    tokenInTransferToChain(_toChainId, _token, _amount);
  }
  function tokenInBurnToBurnAddrToChain(
    uint256 _toChainId,
    IERC20 _token, 
    uint256 _amount
  ) 
    external 
    payable
    nonReentrant
  {
    KiLibrary.tokenInCheck(tokenInfo[_token], this.tokenInBurnToBurnAddrToChain.selector);
    _amount = realTonkenTransferAmount(_token,KiLibrary.BURN_ADDRESS,_amount);
    tokenInTransferToChain(_toChainId, _token, _amount);
  }
  function realTonkenTransferAmount(
    IERC20 _token, 
    address _receiver,
    uint256 _amount
  ) 
    private 
    returns (uint256 realAmount)
  {
    uint256 balanceBefore = _token.balanceOf(_receiver);
    _token.safeTransferFrom(msg.sender, _receiver, _amount);
    _amount = _token.balanceOf(_receiver) - balanceBefore;
    realAmount = KiLibrary.tonkenInDecimalsAmount(_token,_amount);
  }
  function tokenOutTransferToUser(
    address _user, 
    IERC20 _token, 
    uint256 _amount
  ) 
    public 
    onlyNodeOrUser(_user)
    nonReentrant
  {
    userInfo[_user].tokenBalance[_token] -= _amount;
    _amount = KiLibrary.tonkenOutDecimalsAmount(_token,_amount);
    _token.safeTransfer(_user, _amount);
  }
  function tokenOutMintToUser(
    address _user, 
    IERC20 _token, 
    uint256 _amount
  ) 
    public 
    onlyNodeOrUser(_user)
    nonReentrant
  {
    userInfo[_user].tokenBalance[_token] -= _amount;
    _amount = KiLibrary.tonkenOutDecimalsAmount(_token,_amount);
    IERC20(_token).mint(_user, _amount);
  }
  function getUserTransaction(
    address _user, 
    uint256 _fromChainId, 
    uint256 _toChainId, 
    uint256 _txIndex
  ) 
    external 
    view 
    returns (KiLibrary.Transaction memory) 
  {
    return userInfo[_user].transactions[_fromChainId][_toChainId][_txIndex];
  }
  function getUserTransactionsLength(
    address _user, 
    uint256 _fromChainId, 
    uint256 _toChainId
  )
    external 
    view 
    returns (uint256 length) 
  {
    return userInfo[_user].transactions[_fromChainId][_toChainId].length;
  }
  function getToAllChainableBalance(
    IERC20 _token
  )
    external 
    view 
    returns (uint256 amount) 
  {
    return liquidityInfo[_token].toAllChainableBalance;
  }
  function calculateToAllChainableBalance(
    IERC20 _token,
    uint256 _fulfilled,
    uint256 _pending,
    uint256 _amount
  )
    external 
    view 
    returns (uint256 amount) 
  {
    if (liquidityInfo[_token].toAllChainableBalance + _fulfilled >= _pending + _amount) return _amount;
    else return 0;
  }
  function accumulatePendingLiquidityToChain(
    IERC20 _token,
    uint256 _toChainId,
    uint256 _amount
  )
    external 
    view 
    returns (uint256 amount) 
  {
    return liquidityInfo[_token].pendingLiquidityToChain[_toChainId] + _amount;
  }
  function accumulateFulfilledLiquidityFromChain(
    IERC20 _token,
    uint256 _chainId,
    uint256 _amount
  )
    external 
    view 
    returns (uint256 amount) 
  {
    return liquidityInfo[_token].fulfilledLiquidityFromChain[_chainId] + _amount;
  }
  function getUserNonce(
    address _user
  )
    external 
    view 
    returns (uint256 nonce) 
  {
    return userInfo[_user].nonce;
  }
  function getUserTokenBalance(
    address _user, 
    IERC20 _token
  )
    external 
    view 
    returns (uint256 amount) 
  {
    return userInfo[_user].tokenBalance[_token];
  }
  function getUserPendingLiquidityRequest(
    address _user,
    uint256 _toChainId
  )
    external 
    view 
    returns (KiLibrary.LiquidityRequest memory) 
  {
    bytes32 requestId = userInfo[_user].pendingToChainRequestId[_toChainId];
    return userInfo[_user].requestData[requestId];
  }
  function getUserLiquidityRequest(
    address _user,
    bytes32 _requestId
  )
    external 
    view 
    returns (KiLibrary.LiquidityRequest memory) 
  {
    return userInfo[_user].requestData[_requestId];
  }
  function getTokenInfo(
    IERC20 _token,  
    uint256 _toChainId
  )
    external 
    view 
    returns (
      bool liquidable,
      bytes4 tokenInFunctionId, 
      bytes4 executeFunctionId, 
      IERC20 toChainToken
    ) 
  {
    return (
      tokenInfo[_token].liquidable,
      tokenInfo[_token].tokenInFunctionId,
      tokenInfo[_token].tokenOutFunctionId,
      tokenInfo[_token].toChainToken[_toChainId]
    );
  }
  modifier checkBaseFee(uint256 _multiplier) {
    require(BASE_FEE * _multiplier <= msg.value, "Insufficient Base Fee");
    _;
  }
  modifier checkAddress(address _address) {
    require(_address != address(0), "Invalid address");
    _;
  }

  modifier onlyAuthorizedNode() {
    require(msg.sender == authorizedNode, "Not an authorized node");
    _;
  }
  modifier onlyNodeOrUser(address _user) {
    require(msg.sender == authorizedNode || msg.sender == _user, "Caller is not the node or user");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../libs/token/ERC20/ERC20.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract KiERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name, string memory symbol) ERC20(name,symbol) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

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

import "../../libs/token/ERC20/IERC20.sol";

interface IKiBridgeV1Factory {

  event LiquidityCreated(IERC20 indexed token, address indexed liquidity, uint);

  function createLiquidity(IERC20 _token) external returns (address liquidity);
  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libs/token/ERC20/IERC20.sol";

interface IKiBridgeV1Liquidity is IERC20 {

  function bridge() external view returns (address);

  function token() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKiBridgeV1LiquidityDeployer {

  function parameters() external view returns (address bridge, address token);
  
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "./IERC20.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
abstract contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "../IERC20.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}