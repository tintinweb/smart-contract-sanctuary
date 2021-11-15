// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import '../../library/WhitelistUpgradeable.sol';
import '../../library/SafeToken.sol';

import '../../interfaces/IPancakeRouter02.sol';
import '../../interfaces/IVenusDistribution.sol';
import './VaultVenusBridge.sol';
import './VAIVault.sol';

contract VaultVenusBridgeOwner is WhitelistUpgradeable {
  using SafeMath for uint256;
  using SafeBEP20 for IBEP20;
  using SafeToken for address;

  /* ========== CONSTANTS ============= */

  IPancakeRouter01 private constant PANCAKE_ROUTER =
    IPancakeRouter01(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
  IVenusDistribution private constant VENUS_UNITROLLER =
    IVenusDistribution(0x94d1820b2D1c7c7452A163983Dc888CEC546b77D);
  VaultVenusBridge private constant VENUS_BRIDGE =
    VaultVenusBridge(0x7697be435595d00ef3B6B8c172aFe7077F6A9401);

  address private constant WBNBADDR =
    0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
  address private constant BUSD = 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47;
  IBEP20 private constant XVS =
    IBEP20(0xB9e0E753630434d7863528cc73CB7AC638a7c8ff);
  IBEP20 private constant WBNB =
    IBEP20(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd);

  VAIVault private constant XVS_HOLD_XVS_Claim =
    VAIVault(0x3F047c3022b35Ed59484a4eE12B28849903A8c3B);

  /* ========== INITIALIZER ========== */

  receive() external payable {}

  function initialize() external initializer {
    __WhitelistUpgradeable_init();
    XVS.safeApprove(address(PANCAKE_ROUTER), uint256(-1));
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function addVaultBehalf(
    address vault,
    address token,
    address vToken
  ) public onlyOwner {
    VENUS_BRIDGE.addVault(vault, token, vToken);
    VENUS_BRIDGE.setWhitelist(vault, true);
  }

  function setWhitelistBehalf(address _address, bool _on) external onlyOwner {
    VENUS_BRIDGE.setWhitelist(_address, _on);
  }

  function deposit(address vault, uint256 amount) external payable onlyOwner {
    VaultVenusBridge.MarketInfo memory market = VENUS_BRIDGE.infoOf(vault);
    address[] memory vTokens = new address[](1);
    vTokens[0] = market.vToken;
    if (market.token == WBNBADDR) {
      amount = msg.value;
      VENUS_BRIDGE.deposit{ value: amount }(vault, amount);
    } else {
      IBEP20(market.token).safeTransferFrom(
        owner(),
        address(VENUS_BRIDGE),
        amount
      );
      VENUS_BRIDGE.deposit(vault, amount);
    }
  }

  function getMarket(address vault) public view returns (address marketToken) {
    VaultVenusBridge.MarketInfo memory market = VENUS_BRIDGE.infoOf(vault);
    address[] memory vTokens = new address[](1);
    return market.vToken;
  }

  uint96 public testAmount;

  function getBlockTimeStamp() public view returns (uint256 timestamp) {
    return block.timestamp;
  }

  uint256 public testUpgrades;

  function harvestBehalf(address vault) public {
    VaultVenusBridge.MarketInfo memory market = VENUS_BRIDGE.infoOf(vault);
    address[] memory vTokens = new address[](1);
    vTokens[0] = market.vToken;

    uint256 xvsBefore = XVS.balanceOf(
      address(0xce2Be8b93E2d832b51C7a5dd296FAC6c39a67872)
    );
    VENUS_UNITROLLER.claimVenus(
      address(0xce2Be8b93E2d832b51C7a5dd296FAC6c39a67872),
      vTokens
    );
    uint256 xvsBalance = XVS
      .balanceOf(address(0xce2Be8b93E2d832b51C7a5dd296FAC6c39a67872))
      .sub(xvsBefore);

    if (xvsBalance > 0) {
      // VENUS_BRIDGE.recoverToken(address(XVS), xvsBalance);// if us vaultOwner
      if (market.token == WBNBADDR || market.token == BUSD) {
        uint256 swapBefore = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(0xB9e0E753630434d7863528cc73CB7AC638a7c8ff);
        path[1] = address(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd);
        // XVS.approve(address(PANCAKE_ROUTER), uint256(-1));
        // WBNB.approve(address(PANCAKE_ROUTER), uint256(-1));
        // PANCAKE_ROUTER.addLiquidity(
        //   path[0],
        //   path[1],
        //   10000,
        //   10000,
        //   1,
        //   1,
        //   msg.sender,
        //   1731854234340
        // );

        PANCAKE_ROUTER.swapExactTokensForETH(
          10000,
          0,
          path,
          0xce2Be8b93E2d832b51C7a5dd296FAC6c39a67872,
          1731854234340
        );

        // uint256 swapAmount = address(this).balance.sub(swapBefore);
        // VENUS_BRIDGE.deposit{ value: swapAmount }(vault, swapAmount);
      }
    }
    // XVS_HOLD_XVS_Claim.claim();
    // VENUS_UNITROLLER.claimVenus(address(VENUS_BRIDGE), vTokens);
    // uint256 xvsAfter = XVS.balanceOf(
    //   address(0x7Db4f5cC3bBA3e12FF1F528D2e3417afb0a57118)
    // );

    // uint256 xvsBalance = xvsAfter.sub(xvsBefore);
    // XVS.transfer(
    //   address(0x7Db4f5cC3bBA3e12FF1F528D2e3417afb0a57118),
    //   xvsBalance
    // );
    // if (market.token == WBNB) {
    //   uint256 swapBefore = address(this).balance;
    //   address[] memory path = new address[](2);
    //   path[0] = address(XVS);
    //   path[1] = WBNB;
    //   PANCAKE_ROUTER.swapExactTokensForETH(
    //     xvsBalance,
    //     0,
    //     path,
    //     address(this),
    //     block.timestamp
    //   );

    //   uint256 swapAmount = address(this).balance.sub(swapBefore);
    //   VENUS_BRIDGE.deposit{ value: swapAmount }(vault, swapAmount);
    // } else {
    //   uint256 swapBefore = IBEP20(market.token).balanceOf(address(this));
    //   address[] memory path = new address[](3);
    //   path[0] = address(XVS);
    //   path[1] = WBNB;
    //   path[2] = market.token;
    //   PANCAKE_ROUTER.swapExactTokensForTokens(
    //     xvsBalance,
    //     0,
    //     path,
    //     address(this),
    //     block.timestamp
    //   );

    //   uint256 swapAmount = IBEP20(market.token).balanceOf(address(this)).sub(
    //     swapBefore
    //   );
    //   IBEP20(market.token).safeTransfer(address(VENUS_BRIDGE), swapAmount);
    //   VENUS_BRIDGE.deposit(vault, swapAmount);
    // }
    // }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

contract WhitelistUpgradeable is OwnableUpgradeable {
  mapping(address => bool) private _whitelist;
  bool private _disable; // default - false means whitelist feature is working on. if true no more use of whitelist

  event Whitelisted(address indexed _address, bool whitelist);
  event EnableWhitelist();
  event DisableWhitelist();

  modifier onlyWhitelisted() {
    require(
      _disable || _whitelist[msg.sender],
      'Whitelist: caller is not on the whitelist'
    );
    _;
  }

  function __WhitelistUpgradeable_init() internal initializer {
    __Ownable_init();
  }

  function isWhitelist(address _address) public view returns (bool) {
    return _whitelist[_address];
  }

  function setWhitelist(address _address, bool _on) external onlyOwner {
    _whitelist[_address] = _on;

    emit Whitelisted(_address, _on);
  }

  function disableWhitelist(bool disable) external onlyOwner {
    _disable = disable;
    if (disable) {
      emit DisableWhitelist();
    } else {
      emit EnableWhitelist();
    }
  }

  uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ERC20Interface {
  function balanceOf(address user) external view returns (uint256);
}

library SafeToken {
  function myBalance(address token) internal view returns (uint256) {
    return ERC20Interface(token).balanceOf(address(this));
  }

  function balanceOf(address token, address user)
    internal
    view
    returns (uint256)
  {
    return ERC20Interface(token).balanceOf(user);
  }

  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(0x095ea7b3, to, value)
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      '!safeApprove'
    );
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(0xa9059cbb, to, value)
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      '!safeTransfer'
    );
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(0x23b872dd, from, to, value)
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      '!safeTransferFrom'
    );
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{ value: value }(new bytes(0));
    require(success, '!safeTransferETH');
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IVenusDistribution {
  function oracle() external view returns (address);

  function enterMarkets(address[] memory _vtokens) external;

  function exitMarket(address _vtoken) external;

  function getAssetsIn(address account)
    external
    view
    returns (address[] memory);

  function markets(address vTokenAddress)
    external
    view
    returns (
      bool,
      uint256,
      bool
    );

  function getAccountLiquidity(address account)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  function claimVenus(address holder, address[] memory vTokens) external;

  function venusSpeeds(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';

import '../../library/SafeToken.sol';
import '../../library/Whitelist.sol';
import '../../library/Exponential.sol';

import '../../interfaces/IVaultVenusBridge.sol';
import '../../interfaces/IPancakeRouter02.sol';
import '../../interfaces/IVenusDistribution.sol';
import '../../interfaces/IVBNB.sol';
import '../../interfaces/IVToken.sol';

contract VaultVenusBridge is Whitelist, Exponential, IVaultVenusBridge {
  using SafeMath for uint256;
  using SafeBEP20 for IBEP20;
  using SafeToken for address;

  /* ========== CONSTANTS ============= */

  IPancakeRouter02 private constant PANCAKE_ROUTER =
    IPancakeRouter02(0xC3dc61B32d67429bE41cBd64115A7DAc82DA40Ce);
  IVenusDistribution private constant VENUS_UNITROLLER =
    IVenusDistribution(0x94d1820b2D1c7c7452A163983Dc888CEC546b77D);

  address private constant WBNB = 0x2B65292866a98Fdd77045dB926D59b0571aD87b6;
  IBEP20 private constant XVS =
    IBEP20(0xB9e0E753630434d7863528cc73CB7AC638a7c8ff);
  IVBNB public constant vBNB =
    IVBNB(0x2E7222e51c0f6e98610A1543Aa3836E092CDe62c);

  /* ========== STATE VARIABLES ========== */

  MarketInfo[] private _marketList;
  mapping(address => MarketInfo) markets;

  /* ========== EVENTS ========== */

  event Recovered(address token, uint256 amount);

  /* ========== MODIFIERS ========== */

  modifier updateAvailable(address vault) {
    MarketInfo storage market = markets[vault];
    uint256 tokenBalanceBefore = market.token != WBNB
      ? IBEP20(market.token).balanceOf(address(this))
      : address(this).balance;
    uint256 vTokenAmountBefore = IBEP20(market.vToken).balanceOf(address(this));

    _;

    uint256 tokenBalance = market.token != WBNB
      ? IBEP20(market.token).balanceOf(address(this))
      : address(this).balance;
    uint256 vTokenAmount = IBEP20(market.vToken).balanceOf(address(this));
    market.available = market.available.add(tokenBalance).sub(
      tokenBalanceBefore
    );
    market.vTokenAmount = market.vTokenAmount.add(vTokenAmount).sub(
      vTokenAmountBefore
    );
  }

  /* ========== INITIALIZER ========== */

  receive() external payable {}

  constructor() public {
    XVS.safeApprove(address(PANCAKE_ROUTER), uint256(-1));
  }

  /* ========== VIEW FUNCTIONS ========== */

  function infoOf(address vault)
    public
    view
    override
    returns (MarketInfo memory)
  {
    return markets[vault];
  }

  function availableOf(address vault) public view override returns (uint256) {
    return markets[vault].available;
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function addVault(
    address vault,
    address token,
    address vToken
  ) public onlyOwner {
    require(
      markets[vault].token == address(0),
      'VaultVenusBridge: vault is already set'
    );
    require(
      token != address(0) && vToken != address(0),
      'VaultVenusBridge: invalid tokens'
    );

    MarketInfo memory market = MarketInfo(token, vToken, 0, 0);
    _marketList.push(market);
    markets[vault] = market;

    IBEP20(token).safeApprove(address(PANCAKE_ROUTER), uint256(-1));
    IBEP20(token).safeApprove(vToken, uint256(-1));

    address[] memory venusMarkets = new address[](1);
    venusMarkets[0] = vToken;
    VENUS_UNITROLLER.enterMarkets(venusMarkets);
  }

  function migrateTo(address payable target) external override {
    MarketInfo storage market = markets[msg.sender];
    IVaultVenusBridge newBridge = IVaultVenusBridge(target);

    if (market.token == WBNB) {
      newBridge.deposit{ value: market.available }(
        msg.sender,
        market.available
      );
    } else {
      IBEP20 token = IBEP20(market.token);
      token.safeApprove(address(newBridge), uint256(-1));
      token.safeTransfer(address(newBridge), market.available);
      token.safeApprove(address(newBridge), 0);
      newBridge.deposit(msg.sender, market.available);
    }
    market.available = 0;
    market.vTokenAmount = 0;
  }

  function deposit(address vault, uint256 amount) external payable override {
    MarketInfo storage market = markets[vault];
    market.available = market.available.add(msg.value > 0 ? msg.value : amount);
  }

  function withdraw(address account, uint256 amount) external override {
    MarketInfo storage market = markets[msg.sender];
    market.available = market.available.sub(amount);
    if (market.token == WBNB) {
      SafeToken.safeTransferETH(account, amount);
    } else {
      IBEP20(market.token).safeTransfer(account, amount);
    }
  }

  function harvest() public override updateAvailable(msg.sender) {
    MarketInfo memory market = markets[msg.sender];

    address[] memory vTokens = new address[](1);
    vTokens[0] = market.vToken;

    uint256 before = XVS.balanceOf(address(this));
    VENUS_UNITROLLER.claimVenus(address(this), vTokens);

    uint256 xvsBalance = XVS.balanceOf(address(this)).sub(before);
    if (xvsBalance > 0) {
      if (market.token == WBNB) {
        address[] memory path = new address[](2);
        path[0] = address(XVS);
        path[1] = WBNB;
        PANCAKE_ROUTER.swapExactTokensForETH(
          xvsBalance,
          0,
          path,
          address(this),
          block.timestamp
        );
      } else {
        address[] memory path = new address[](3);
        path[0] = address(XVS);
        path[1] = WBNB;
        path[2] = market.token;
        PANCAKE_ROUTER.swapExactTokensForTokens(
          xvsBalance,
          0,
          path,
          address(this),
          block.timestamp
        );
      }
    }
  }

  function balanceOfUnderlying(address vault)
    external
    override
    returns (uint256)
  {
    MarketInfo memory market = markets[vault];
    Exp memory exchangeRate = Exp({
      mantissa: IVToken(market.vToken).exchangeRateCurrent()
    });
    (MathError mErr, uint256 balance) = mulScalarTruncate(
      exchangeRate,
      market.vTokenAmount
    );
    require(mErr == MathError.NO_ERROR, 'balance could not be calculated');
    return balance;
  }

  /* ========== VENUS FUNCTIONS ========== */

  function mint(uint256 amount) external override updateAvailable(msg.sender) {
    MarketInfo memory market = markets[msg.sender];
    if (market.token == WBNB) {
      vBNB.mint{ value: amount }();
    } else {
      IVToken(market.vToken).mint(amount);
    }
  }

  function redeemUnderlying(uint256 amount)
    external
    override
    updateAvailable(msg.sender)
  {
    MarketInfo memory market = markets[msg.sender];
    IVToken vToken = IVToken(market.vToken);
    vToken.redeemUnderlying(amount);
  }

  function redeemAll() external override updateAvailable(msg.sender) {
    MarketInfo memory market = markets[msg.sender];
    IVToken vToken = IVToken(market.vToken);
    vToken.redeem(market.vTokenAmount);
  }

  function borrow(uint256 amount)
    external
    override
    updateAvailable(msg.sender)
  {
    MarketInfo memory market = markets[msg.sender];
    IVToken vToken = IVToken(market.vToken);
    vToken.borrow(amount);
  }

  function repayBorrow(uint256 amount)
    external
    override
    updateAvailable(msg.sender)
  {
    MarketInfo memory market = markets[msg.sender];
    if (market.vToken == address(vBNB)) {
      vBNB.repayBorrow{ value: amount }();
    } else {
      IVToken(market.vToken).repayBorrow(amount);
    }
  }

  function recoverToken(address token, uint256 amount) external onlyOwner {
    // case0) WBNB salvage
    if (token == WBNB && IBEP20(WBNB).balanceOf(address(this)) >= amount) {
      IBEP20(token).safeTransfer(owner(), amount);
      emit Recovered(token, amount);
      return;
    }

    // case1) vault token - WBNB=>BNB
    for (uint256 i = 0; i < _marketList.length; i++) {
      MarketInfo memory market = _marketList[i];

      if (market.vToken == token) {
        revert('VaultVenusBridge: cannot recover');
      }

      if (market.token == token) {
        uint256 balance = token == WBNB
          ? address(this).balance
          : IBEP20(token).balanceOf(address(this));
        require(
          balance.sub(market.available) >= amount,
          'VaultVenusBridge: cannot recover'
        );

        if (token == WBNB) {
          SafeToken.safeTransferETH(owner(), amount);
        } else {
          IBEP20(token).safeTransfer(owner(), amount);
        }

        emit Recovered(token, amount);
        return;
      }
    }

    // case2) not vault token
    IBEP20(token).safeTransfer(owner(), amount);
    emit Recovered(token, amount);
  }
}

pragma solidity ^0.6.12;
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import './VAIVaultProxy.sol';
import './VAIVaultStorage.sol';
import './VAIVaultErrorReporter.sol';

contract VAIVault is VAIVaultStorage {
  using SafeMath for uint256;
  using SafeBEP20 for IBEP20;

  /// @notice Event emitted when VAI deposit
  event Deposit(address indexed user, uint256 amount);

  /// @notice Event emitted when VAI withrawal
  event Withdraw(address indexed user, uint256 amount);

  /// @notice Event emitted when admin changed
  event AdminTransfered(address indexed oldAdmin, address indexed newAdmin);

  constructor() public {
    admin = msg.sender;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin, 'only admin can');
    _;
  }

  /*** Reentrancy Guard ***/

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   */
  modifier nonReentrant() {
    require(_notEntered, 're-entered');
    _notEntered = false;
    _;
    _notEntered = true; // get a gas-refund post-Istanbul
  }

  /**
   * @notice Deposit VAI to VAIVault for XVS allocation
   * @param _amount The amount to deposit to vault
   */
  function deposit(uint256 _amount) public nonReentrant {
    UserInfo storage user = userInfo[msg.sender];

    updateVault();

    // Transfer pending tokens to user
    updateAndPayOutPending(msg.sender);

    // Transfer in the amounts from user
    if (_amount > 0) {
      vai.safeTransferFrom(address(msg.sender), address(this), _amount);
      user.amount = user.amount.add(_amount);
    }

    user.rewardDebt = user.amount.mul(accXVSPerShare).div(1e18);
    emit Deposit(msg.sender, _amount);
  }

  /**
   * @notice Withdraw VAI from VAIVault
   * @param _amount The amount to withdraw from vault
   */
  function withdraw(uint256 _amount) public nonReentrant {
    _withdraw(msg.sender, _amount);
  }

  /**
   * @notice Claim XVS from VAIVault
   */
  function claim() public nonReentrant {
    _withdraw(msg.sender, 0);
  }

  /**
   * @notice Low level withdraw function
   * @param account The account to withdraw from vault
   * @param _amount The amount to withdraw from vault
   */
  function _withdraw(address account, uint256 _amount) internal {
    UserInfo storage user = userInfo[account];
    require(user.amount >= _amount, 'withdraw: not good');

    updateVault();
    updateAndPayOutPending(account); // Update balances of account this is not withdrawal but claiming XVS farmed

    if (_amount > 0) {
      user.amount = user.amount.sub(_amount);
      vai.safeTransfer(address(account), _amount);
    }
    user.rewardDebt = user.amount.mul(accXVSPerShare).div(1e18);

    emit Withdraw(account, _amount);
  }

  /**
   * @notice View function to see pending XVS on frontend
   * @param _user The user to see pending XVS
   */
  function pendingXVS(address _user) public view returns (uint256) {
    UserInfo storage user = userInfo[_user];

    return user.amount.mul(accXVSPerShare).div(1e18).sub(user.rewardDebt);
  }

  /**
   * @notice Update and pay out pending XVS to user
   * @param account The user to pay out
   */
  function updateAndPayOutPending(address account) internal {
    uint256 pending = pendingXVS(account);

    if (pending > 0) {
      safeXVSTransfer(account, pending);
    }
  }

  /**
   * @notice Safe XVS transfer function, just in case if rounding error causes pool to not have enough XVS
   * @param _to The address that XVS to be transfered
   * @param _amount The amount that XVS to be transfered
   */
  function safeXVSTransfer(address _to, uint256 _amount) internal {
    uint256 xvsBal = xvs.balanceOf(address(this));

    if (_amount > xvsBal) {
      xvs.transfer(_to, xvsBal);
      xvsBalance = xvs.balanceOf(address(this));
    } else {
      xvs.transfer(_to, _amount);
      xvsBalance = xvs.balanceOf(address(this));
    }
  }

  /**
   * @notice Function that updates pending rewards
   */
  function updatePendingRewards() public {
    uint256 newRewards = xvs.balanceOf(address(this)).sub(xvsBalance);

    if (newRewards > 0) {
      xvsBalance = xvs.balanceOf(address(this)); // If there is no change the balance didn't change
      pendingRewards = pendingRewards.add(newRewards);
    }
  }

  /**
   * @notice Update reward variables to be up-to-date
   */
  function updateVault() internal {
    uint256 vaiBalance = vai.balanceOf(address(this));
    if (vaiBalance == 0) {
      // avoids division by 0 errors
      return;
    }

    accXVSPerShare = accXVSPerShare.add(
      pendingRewards.mul(1e18).div(vaiBalance)
    );
    pendingRewards = 0;
  }

  /**
   * @dev Returns the address of the current admin
   */
  function getAdmin() public view returns (address) {
    return admin;
  }

  /**
   * @dev Burn the current admin
   */
  function burnAdmin() public onlyAdmin {
    emit AdminTransfered(admin, address(0));
    admin = address(0);
  }

  /**
   * @dev Set the current admin to new address
   */
  function setNewAdmin(address newAdmin) public onlyAdmin {
    require(newAdmin != address(0), 'new owner is the zero address');
    emit AdminTransfered(admin, newAdmin);
    admin = newAdmin;
  }

  /*** Admin Functions ***/

  function _become(VAIVaultProxy vaiVaultProxy) public {
    require(
      msg.sender == vaiVaultProxy.admin(),
      'only proxy admin can change brains'
    );
    require(
      vaiVaultProxy._acceptImplementation() == 0,
      'change not authorized'
    );
  }

  function setVenusInfo(address _xvs, address _vai) public onlyAdmin {
    xvs = IBEP20(_xvs);
    vai = IBEP20(_vai);

    _notEntered = true;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
pragma solidity ^0.6.12;

interface IPancakeRouter01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import './IBEP20.sol';
import '../../math/SafeMath.sol';
import '../../utils/Address.sol';

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol';

contract Whitelist is Ownable {
  mapping(address => bool) private _whitelist;
  bool private _disable; // default - false means whitelist feature is working on. if true no more use of whitelist

  event Whitelisted(address indexed _address, bool whitelist);
  event EnableWhitelist();
  event DisableWhitelist();

  modifier onlyWhitelisted() {
    require(
      _disable || _whitelist[msg.sender],
      'Whitelist: caller is not on the whitelist'
    );
    _;
  }

  function isWhitelist(address _address) public view returns (bool) {
    return _whitelist[_address];
  }

  function setWhitelist(address _address, bool _on) external onlyOwner {
    _whitelist[_address] = _on;

    emit Whitelisted(_address, _on);
  }

  function disableWhitelist(bool disable) external onlyOwner {
    _disable = disable;
    if (disable) {
      emit DisableWhitelist();
    } else {
      emit EnableWhitelist();
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import './CarefulMath.sol';

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Venus
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath {
  uint256 constant expScale = 1e18;
  uint256 constant doubleScale = 1e36;
  uint256 constant halfExpScale = expScale / 2;
  uint256 constant mantissaOne = expScale;

  struct Exp {
    uint256 mantissa;
  }

  struct Double {
    uint256 mantissa;
  }

  /**
   * @dev Creates an exponential from numerator and denominator values.
   *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
   *            or if `denom` is zero.
   */
  function getExp(uint256 num, uint256 denom)
    internal
    pure
    returns (MathError, Exp memory)
  {
    (MathError err0, uint256 scaledNumerator) = mulUInt(num, expScale);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({ mantissa: 0 }));
    }

    (MathError err1, uint256 rational) = divUInt(scaledNumerator, denom);
    if (err1 != MathError.NO_ERROR) {
      return (err1, Exp({ mantissa: 0 }));
    }

    return (MathError.NO_ERROR, Exp({ mantissa: rational }));
  }

  /**
   * @dev Adds two exponentials, returning a new exponential.
   */
  function addExp(Exp memory a, Exp memory b)
    internal
    pure
    returns (MathError, Exp memory)
  {
    (MathError error, uint256 result) = addUInt(a.mantissa, b.mantissa);

    return (error, Exp({ mantissa: result }));
  }

  /**
   * @dev Subtracts two exponentials, returning a new exponential.
   */
  function subExp(Exp memory a, Exp memory b)
    internal
    pure
    returns (MathError, Exp memory)
  {
    (MathError error, uint256 result) = subUInt(a.mantissa, b.mantissa);

    return (error, Exp({ mantissa: result }));
  }

  /**
   * @dev Multiply an Exp by a scalar, returning a new Exp.
   */
  function mulScalar(Exp memory a, uint256 scalar)
    internal
    pure
    returns (MathError, Exp memory)
  {
    (MathError err0, uint256 scaledMantissa) = mulUInt(a.mantissa, scalar);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({ mantissa: 0 }));
    }

    return (MathError.NO_ERROR, Exp({ mantissa: scaledMantissa }));
  }

  /**
   * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
   */
  function mulScalarTruncate(Exp memory a, uint256 scalar)
    internal
    pure
    returns (MathError, uint256)
  {
    (MathError err, Exp memory product) = mulScalar(a, scalar);
    if (err != MathError.NO_ERROR) {
      return (err, 0);
    }

    return (MathError.NO_ERROR, truncate(product));
  }

  /**
   * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
   */
  function mulScalarTruncateAddUInt(
    Exp memory a,
    uint256 scalar,
    uint256 addend
  ) internal pure returns (MathError, uint256) {
    (MathError err, Exp memory product) = mulScalar(a, scalar);
    if (err != MathError.NO_ERROR) {
      return (err, 0);
    }

    return addUInt(truncate(product), addend);
  }

  /**
   * @dev Divide an Exp by a scalar, returning a new Exp.
   */
  function divScalar(Exp memory a, uint256 scalar)
    internal
    pure
    returns (MathError, Exp memory)
  {
    (MathError err0, uint256 descaledMantissa) = divUInt(a.mantissa, scalar);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({ mantissa: 0 }));
    }

    return (MathError.NO_ERROR, Exp({ mantissa: descaledMantissa }));
  }

  /**
   * @dev Divide a scalar by an Exp, returning a new Exp.
   */
  function divScalarByExp(uint256 scalar, Exp memory divisor)
    internal
    pure
    returns (MathError, Exp memory)
  {
    /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
    (MathError err0, uint256 numerator) = mulUInt(expScale, scalar);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({ mantissa: 0 }));
    }
    return getExp(numerator, divisor.mantissa);
  }

  /**
   * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
   */
  function divScalarByExpTruncate(uint256 scalar, Exp memory divisor)
    internal
    pure
    returns (MathError, uint256)
  {
    (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
    if (err != MathError.NO_ERROR) {
      return (err, 0);
    }

    return (MathError.NO_ERROR, truncate(fraction));
  }

  /**
   * @dev Multiplies two exponentials, returning a new exponential.
   */
  function mulExp(Exp memory a, Exp memory b)
    internal
    pure
    returns (MathError, Exp memory)
  {
    (MathError err0, uint256 doubleScaledProduct) = mulUInt(
      a.mantissa,
      b.mantissa
    );
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({ mantissa: 0 }));
    }

    // We add half the scale before dividing so that we get rounding instead of truncation.
    //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
    // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
    (MathError err1, uint256 doubleScaledProductWithHalfScale) = addUInt(
      halfExpScale,
      doubleScaledProduct
    );
    if (err1 != MathError.NO_ERROR) {
      return (err1, Exp({ mantissa: 0 }));
    }

    (MathError err2, uint256 product) = divUInt(
      doubleScaledProductWithHalfScale,
      expScale
    );
    // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
    assert(err2 == MathError.NO_ERROR);

    return (MathError.NO_ERROR, Exp({ mantissa: product }));
  }

  /**
   * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
   */
  function mulExp(uint256 a, uint256 b)
    internal
    pure
    returns (MathError, Exp memory)
  {
    return mulExp(Exp({ mantissa: a }), Exp({ mantissa: b }));
  }

  /**
   * @dev Multiplies three exponentials, returning a new exponential.
   */
  function mulExp3(
    Exp memory a,
    Exp memory b,
    Exp memory c
  ) internal pure returns (MathError, Exp memory) {
    (MathError err, Exp memory ab) = mulExp(a, b);
    if (err != MathError.NO_ERROR) {
      return (err, ab);
    }
    return mulExp(ab, c);
  }

  /**
   * @dev Divides two exponentials, returning a new exponential.
   *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
   *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
   */
  function divExp(Exp memory a, Exp memory b)
    internal
    pure
    returns (MathError, Exp memory)
  {
    return getExp(a.mantissa, b.mantissa);
  }

  /**
   * @dev Truncates the given exp to a whole number value.
   *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
   */
  function truncate(Exp memory exp) internal pure returns (uint256) {
    // Note: We are not using careful math here as we're performing a division that cannot fail
    return exp.mantissa / expScale;
  }

  /**
   * @dev Checks if first Exp is less than second Exp.
   */
  function lessThanExp(Exp memory left, Exp memory right)
    internal
    pure
    returns (bool)
  {
    return left.mantissa < right.mantissa;
  }

  /**
   * @dev Checks if left Exp <= right Exp.
   */
  function lessThanOrEqualExp(Exp memory left, Exp memory right)
    internal
    pure
    returns (bool)
  {
    return left.mantissa <= right.mantissa;
  }

  /**
   * @dev Checks if left Exp > right Exp.
   */
  function greaterThanExp(Exp memory left, Exp memory right)
    internal
    pure
    returns (bool)
  {
    return left.mantissa > right.mantissa;
  }

  /**
   * @dev returns true if Exp is exactly zero
   */
  function isZeroExp(Exp memory value) internal pure returns (bool) {
    return value.mantissa == 0;
  }

  function safe224(uint256 n, string memory errorMessage)
    internal
    pure
    returns (uint224)
  {
    require(n < 2**224, errorMessage);
    return uint224(n);
  }

  function safe32(uint256 n, string memory errorMessage)
    internal
    pure
    returns (uint32)
  {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

  function add_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({ mantissa: add_(a.mantissa, b.mantissa) });
  }

  function add_(Double memory a, Double memory b)
    internal
    pure
    returns (Double memory)
  {
    return Double({ mantissa: add_(a.mantissa, b.mantissa) });
  }

  function add_(uint256 a, uint256 b) internal pure returns (uint256) {
    return add_(a, b, 'addition overflow');
  }

  function add_(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, errorMessage);
    return c;
  }

  function sub_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({ mantissa: sub_(a.mantissa, b.mantissa) });
  }

  function sub_(Double memory a, Double memory b)
    internal
    pure
    returns (Double memory)
  {
    return Double({ mantissa: sub_(a.mantissa, b.mantissa) });
  }

  function sub_(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub_(a, b, 'subtraction underflow');
  }

  function sub_(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    return a - b;
  }

  function mul_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({ mantissa: mul_(a.mantissa, b.mantissa) / expScale });
  }

  function mul_(Exp memory a, uint256 b) internal pure returns (Exp memory) {
    return Exp({ mantissa: mul_(a.mantissa, b) });
  }

  function mul_(uint256 a, Exp memory b) internal pure returns (uint256) {
    return mul_(a, b.mantissa) / expScale;
  }

  function mul_(Double memory a, Double memory b)
    internal
    pure
    returns (Double memory)
  {
    return Double({ mantissa: mul_(a.mantissa, b.mantissa) / doubleScale });
  }

  function mul_(Double memory a, uint256 b)
    internal
    pure
    returns (Double memory)
  {
    return Double({ mantissa: mul_(a.mantissa, b) });
  }

  function mul_(uint256 a, Double memory b) internal pure returns (uint256) {
    return mul_(a, b.mantissa) / doubleScale;
  }

  function mul_(uint256 a, uint256 b) internal pure returns (uint256) {
    return mul_(a, b, 'multiplication overflow');
  }

  function mul_(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, errorMessage);
    return c;
  }

  function div_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({ mantissa: div_(mul_(a.mantissa, expScale), b.mantissa) });
  }

  function div_(Exp memory a, uint256 b) internal pure returns (Exp memory) {
    return Exp({ mantissa: div_(a.mantissa, b) });
  }

  function div_(uint256 a, Exp memory b) internal pure returns (uint256) {
    return div_(mul_(a, expScale), b.mantissa);
  }

  function div_(Double memory a, Double memory b)
    internal
    pure
    returns (Double memory)
  {
    return
      Double({ mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa) });
  }

  function div_(Double memory a, uint256 b)
    internal
    pure
    returns (Double memory)
  {
    return Double({ mantissa: div_(a.mantissa, b) });
  }

  function div_(uint256 a, Double memory b) internal pure returns (uint256) {
    return div_(mul_(a, doubleScale), b.mantissa);
  }

  function div_(uint256 a, uint256 b) internal pure returns (uint256) {
    return div_(a, b, 'divide by zero');
  }

  function div_(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a / b;
  }

  function fraction(uint256 a, uint256 b)
    internal
    pure
    returns (Double memory)
  {
    return Double({ mantissa: div_(mul_(a, doubleScale), b) });
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

interface IVaultVenusBridge {
  struct MarketInfo {
    address token;
    address vToken;
    uint256 available;
    uint256 vTokenAmount;
  }

  function infoOf(address vault) external view returns (MarketInfo memory);

  function availableOf(address vault) external view returns (uint256);

  function migrateTo(address payable target) external;

  function deposit(address vault, uint256 amount) external payable;

  function withdraw(address account, uint256 amount) external;

  function harvest() external;

  function balanceOfUnderlying(address vault) external returns (uint256);

  function mint(uint256 amount) external;

  function redeemUnderlying(uint256 amount) external;

  function redeemAll() external;

  function borrow(uint256 amount) external;

  function repayBorrow(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IVBNB {
  function totalSupply() external view returns (uint256);

  function mint() external payable;

  function redeem(uint256 redeemTokens) external returns (uint256);

  function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

  function borrow(uint256 borrowAmount) external returns (uint256);

  function repayBorrow() external payable;

  function balanceOfUnderlying(address owner) external returns (uint256);

  function borrowBalanceCurrent(address account) external returns (uint256);

  function totalBorrowsCurrent() external returns (uint256);

  function exchangeRateCurrent() external returns (uint256);

  function exchangeRateStored() external view returns (uint256);

  function supplyRatePerBlock() external view returns (uint256);

  function borrowRatePerBlock() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';

interface IVToken is IBEP20 {
  function underlying() external returns (address);

  function mint(uint256 mintAmount) external returns (uint256);

  function redeem(uint256 redeemTokens) external returns (uint256);

  function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

  function borrow(uint256 borrowAmount) external returns (uint256);

  function repayBorrow(uint256 repayAmount) external returns (uint256);

  function balanceOfUnderlying(address owner) external returns (uint256);

  function borrowBalanceCurrent(address account) external returns (uint256);

  function totalBorrowsCurrent() external returns (uint256);

  function exchangeRateCurrent() external returns (uint256);

  function exchangeRateStored() external view returns (uint256);

  function supplyRatePerBlock() external view returns (uint256);

  function borrowRatePerBlock() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
        return functionCall(target, data, 'Address: low-level call failed');
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import '../GSN/Context.sol';

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

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
pragma solidity ^0.6.12;

/**
 * @title Careful Math
 * @author Venus
 * @notice Derived from OpenZeppelin's SafeMath library
 *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */
contract CarefulMath {
  /**
   * @dev Possible error codes that we can return
   */
  enum MathError {
    NO_ERROR,
    DIVISION_BY_ZERO,
    INTEGER_OVERFLOW,
    INTEGER_UNDERFLOW
  }

  /**
   * @dev Multiplies two numbers, returns an error on overflow.
   */
  function mulUInt(uint256 a, uint256 b)
    internal
    pure
    returns (MathError, uint256)
  {
    if (a == 0) {
      return (MathError.NO_ERROR, 0);
    }

    uint256 c = a * b;

    if (c / a != b) {
      return (MathError.INTEGER_OVERFLOW, 0);
    } else {
      return (MathError.NO_ERROR, c);
    }
  }

  /**
   * @dev Integer division of two numbers, truncating the quotient.
   */
  function divUInt(uint256 a, uint256 b)
    internal
    pure
    returns (MathError, uint256)
  {
    if (b == 0) {
      return (MathError.DIVISION_BY_ZERO, 0);
    }

    return (MathError.NO_ERROR, a / b);
  }

  /**
   * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
   */
  function subUInt(uint256 a, uint256 b)
    internal
    pure
    returns (MathError, uint256)
  {
    if (b <= a) {
      return (MathError.NO_ERROR, a - b);
    } else {
      return (MathError.INTEGER_UNDERFLOW, 0);
    }
  }

  /**
   * @dev Adds two numbers, returns an error on overflow.
   */
  function addUInt(uint256 a, uint256 b)
    internal
    pure
    returns (MathError, uint256)
  {
    uint256 c = a + b;

    if (c >= a) {
      return (MathError.NO_ERROR, c);
    } else {
      return (MathError.INTEGER_OVERFLOW, 0);
    }
  }

  /**
   * @dev add a and b and then subtract c
   */
  function addThenSubUInt(
    uint256 a,
    uint256 b,
    uint256 c
  ) internal pure returns (MathError, uint256) {
    (MathError err0, uint256 sum) = addUInt(a, b);

    if (err0 != MathError.NO_ERROR) {
      return (err0, 0);
    }

    return subUInt(sum, c);
  }
}

pragma solidity ^0.6.12;

import './VAIVaultStorage.sol';
import './VAIVaultErrorReporter.sol';

contract VAIVaultProxy is VAIVaultAdminStorage, VAIVaultErrorReporter {
  /**
   * @notice Emitted when pendingVAIVaultImplementation is changed
   */
  event NewPendingImplementation(
    address oldPendingImplementation,
    address newPendingImplementation
  );

  /**
   * @notice Emitted when pendingVAIVaultImplementation is accepted, which means VAI Vault implementation is updated
   */
  event NewImplementation(address oldImplementation, address newImplementation);

  /**
   * @notice Emitted when pendingAdmin is changed
   */
  event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

  /**
   * @notice Emitted when pendingAdmin is accepted, which means admin is updated
   */
  event NewAdmin(address oldAdmin, address newAdmin);

  constructor() public {
    // Set admin to caller
    admin = msg.sender;
  }

  /*** Admin Functions ***/
  function _setPendingImplementation(address newPendingImplementation)
    public
    returns (uint256)
  {
    if (msg.sender != admin) {
      return
        fail(
          Error.UNAUTHORIZED,
          FailureInfo.SET_PENDING_IMPLEMENTATION_OWNER_CHECK
        );
    }

    address oldPendingImplementation = pendingVAIVaultImplementation;

    pendingVAIVaultImplementation = newPendingImplementation;

    emit NewPendingImplementation(
      oldPendingImplementation,
      pendingVAIVaultImplementation
    );

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Accepts new implementation of VAI Vault. msg.sender must be pendingImplementation
   * @dev Admin function for new implementation to accept it's role as implementation
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _acceptImplementation() public returns (uint256) {
    // Check caller is pendingImplementation
    if (msg.sender != pendingVAIVaultImplementation) {
      return
        fail(
          Error.UNAUTHORIZED,
          FailureInfo.ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK
        );
    }

    // Save current values for inclusion in log
    address oldImplementation = vaiVaultImplementation;
    address oldPendingImplementation = pendingVAIVaultImplementation;

    vaiVaultImplementation = pendingVAIVaultImplementation;

    pendingVAIVaultImplementation = address(0);

    emit NewImplementation(oldImplementation, vaiVaultImplementation);
    emit NewPendingImplementation(
      oldPendingImplementation,
      pendingVAIVaultImplementation
    );

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
   * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
   * @param newPendingAdmin New pending admin.
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setPendingAdmin(address newPendingAdmin) public returns (uint256) {
    // Check caller = admin
    if (msg.sender != admin) {
      return
        fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_ADMIN_OWNER_CHECK);
    }

    // Save current value, if any, for inclusion in log
    address oldPendingAdmin = pendingAdmin;

    // Store pendingAdmin with value newPendingAdmin
    pendingAdmin = newPendingAdmin;

    // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
    emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
   * @dev Admin function for pending admin to accept role and update admin
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _acceptAdmin() public returns (uint256) {
    // Check caller is pendingAdmin
    if (msg.sender != pendingAdmin) {
      return
        fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK);
    }

    // Save current values for inclusion in log
    address oldAdmin = admin;
    address oldPendingAdmin = pendingAdmin;

    // Store admin with value pendingAdmin
    admin = pendingAdmin;

    // Clear the pending value
    pendingAdmin = address(0);

    emit NewAdmin(oldAdmin, admin);
    emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @dev Delegates execution to an implementation contract.
   * It returns to the external caller whatever the implementation returns
   * or forwards reverts.
   */
  // function() external payable {
  //   // delegate all other functions to current implementation
  //   (bool success, ) = vaiVaultImplementation.delegatecall(msg.data);

  //   assembly {
  //     let free_mem_ptr := mload(0x40)
  //     returndatacopy(free_mem_ptr, 0, returndatasize)

  //     switch success
  //     case 0 {
  //       revert(free_mem_ptr, returndatasize)
  //     }
  //     default {
  //       return(free_mem_ptr, returndatasize)
  //     }
  //   }
  // }
}

pragma solidity ^0.6.12;
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';

contract VAIVaultAdminStorage {
  /**
   * @notice Administrator for this contract
   */
  address public admin;

  /**
   * @notice Pending administrator for this contract
   */
  address public pendingAdmin;

  /**
   * @notice Active brains of VAI Vault
   */
  address public vaiVaultImplementation;

  /**
   * @notice Pending brains of VAI Vault
   */
  address public pendingVAIVaultImplementation;
}

contract VAIVaultStorage is VAIVaultAdminStorage {
  /// @notice The XVS TOKEN!
  IBEP20 public xvs;

  /// @notice The VAI TOKEN!
  IBEP20 public vai;

  /// @notice Guard variable for re-entrancy checks
  bool internal _notEntered;

  /// @notice XVS balance of vault
  uint256 public xvsBalance;

  /// @notice Accumulated XVS per share
  uint256 public accXVSPerShare;

  //// pending rewards awaiting anyone to update
  uint256 public pendingRewards;

  /// @notice Info of each user.
  struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
  }

  // Info of each user that stakes tokens.
  mapping(address => UserInfo) public userInfo;
}

pragma solidity ^0.6.12;

contract VAIVaultErrorReporter {
  enum Error {
    NO_ERROR,
    UNAUTHORIZED
  }

  enum FailureInfo {
    ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
    ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
    SET_PENDING_ADMIN_OWNER_CHECK,
    SET_PENDING_IMPLEMENTATION_OWNER_CHECK
  }

  /**
   * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
   * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
   **/
  event Failure(uint256 error, uint256 info, uint256 detail);

  /**
   * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
   */
  function fail(Error err, FailureInfo info) internal returns (uint256) {
    emit Failure(uint256(err), uint256(info), 0);

    return uint256(err);
  }

  /**
   * @dev use this when reporting an opaque error from an upgradeable collaborator contract
   */
  function failOpaque(
    Error err,
    FailureInfo info,
    uint256 opaqueError
  ) internal returns (uint256) {
    emit Failure(uint256(err), uint256(info), opaqueError);

    return uint256(err);
  }
}

