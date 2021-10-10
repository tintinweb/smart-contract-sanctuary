// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IPancakeFactory.sol";
import "./interfaces/ITokenPresenter.sol";
import "./interfaces/IBurnable.sol";
import "./libraries/VRFConsume.sol";
import "./utils/Adminable.sol";
import "./utils/Maintainable.sol";
import "./utils/EmergencyWithdraw.sol";
import "./utils/CoinDexTools.sol";
import "./utils/AntiWhale.sol";

contract DevilFlipPresenter is
  ITokenPresenter,
  Adminable,
  VRFConsume,
  ReentrancyGuardUpgradeable,
  EmergencyWithdraw,
  AntiWhale,
  CoinDexTools
{
  uint private constant _RATE_NOMINATOR = 10000;
  uint private constant _PRECISION_FACTOR = 1e36;
  uint private constant _MAX_INT = type(uint256).max;
  uint public constant INDEX_DEVIL = 0;

  struct TaxInfo {
    uint tax;
    uint pending;
  }

  struct CycleInfo {
    uint startTime;
    uint duration;
    uint endTime;
    uint winner; // 0: Devil, 1: Angel
    uint amount;
  }

  // ChainLink
  uint internal vrfFee;
  bytes32 internal vrfKeyHash;
  bytes32 internal vrfRequestId;

  // Token
  address public token;

  // Current cycle index, SKIP zero index
  uint public cycleIndex;
  // Cycle duration in seconds
  uint public cycleDuration;
  // cycles[cycleIndex] => CycleInfo
  mapping(uint => CycleInfo) public cycles;

  // Excluded from fee address
  mapping(address => bool) public isExcludedFromFees;

  // Auto add LP, buyback, swap on transfer and sell type
  bool public isAutoDex;

  // Tax collection:
  // 5% for game tokenomics: 2.5 for Angel and 2.5 for Devil -> we just save 2.5%
  // 2% for Wagyu buyback
  // 1% for system
  // 2% added to LP pool
  TaxInfo public devilTax;
  TaxInfo public angelTax;
  TaxInfo public buybackTax;
  address public buybackToken;
  TaxInfo public sysTax;
  TaxInfo public lpTax;
  address public lpAddress;

  // Bank account
  uint public devilBank; // store tokens
  uint public angelBank; // store BNB

  // Spinning: cannot transfer at this time
  bool public isSpinning;

  // Events
  event SpinExt(uint _teamIndex);
  event SpinVRF(bytes32 _requestId);
  event FulfillRandomnessVRF(uint _warTeam);
  event History(uint _time, uint _winner, uint _amount);

  /**
   * @dev Initialize
   * @param _VRFCoordinator Chainlink VRF Coordinator address
   * @param _LINKToken LINK token address
   * @param _VRFKeyHash Chainlink VRF Key Hash
   * @param _VRFFee Chainlink VRF fee
   * @param _token address of the token
   * @param _router dex router
   * @param _admin admin
   */
  function __DevilFlipPresenter_init(
    address _VRFCoordinator,
    address _LINKToken,
    bytes32 _VRFKeyHash,
    uint _VRFFee,
    address _token,
    address _router,
    address _admin,
    uint _cycleDuration,
    address _buybackToken
  ) public initializer {
    __Ownable_init();
    __CoinDexTools_init();
    __ReentrancyGuard_init();
    updateVRFConfig(_VRFCoordinator, _LINKToken, _VRFKeyHash, _VRFFee);
    token = _token;
    setRouter(_router);
    admin = _admin;
    updateTaxInfo(250, 200, 100, 200, true);
    if (_cycleDuration == 0) {
      cycleDuration = 24 hours;
    } else {
      cycleDuration = _cycleDuration;
    }
    buybackToken = _buybackToken;
    // Exclude addresses
    excludeFromFees(owner(), true);
    excludeFromFees(admin, true);
    excludeFromFees(deadAddress, true);
  }

  /**
   * @dev Apply tax and update pending
   * @param _amount raw sending amount
   */
  function _taxCollector(uint _amount) internal returns (uint) {
    uint devilAmount_ = (_amount * devilTax.tax) / _RATE_NOMINATOR;
    devilTax.pending += devilAmount_;
    uint angelAmount_ = (_amount * angelTax.tax) / _RATE_NOMINATOR;
    angelTax.pending += angelAmount_;
    uint buybackAmount_ = (_amount * buybackTax.tax) / _RATE_NOMINATOR;
    buybackTax.pending += buybackAmount_;
    uint sysAmount_ = (_amount * sysTax.tax) / _RATE_NOMINATOR;
    sysTax.pending += sysAmount_;
    uint lpAmount_ = (_amount * lpTax.tax) / _RATE_NOMINATOR;
    lpTax.pending += lpAmount_;
    return devilAmount_ + angelAmount_ + buybackAmount_ + sysAmount_ + lpAmount_;
  }

  /**
   * @dev This is the main function to distribute the tokens call from only main token via external app
   * @param _trigger trigger address
   * @param _from from address
   * @param _to to address
   * @param _amount amount of tokens
   */
  // solhint-disable no-unused-vars
  function receiveTokens(
    address _trigger,
    address _from,
    address _to,
    uint _amount
  ) public override returns (bool) {
    require(_msgSender() == address(token), "Invalid sender");
    require(!isWhale(_from, _to, _amount), "Error: No time for whales!");

    // Transaction type detail
    bool[9] memory flags;
    // Trigger from router
    //bool isViaRouter = _trigger == router;
    flags[0] = _trigger == router;
    // Trigger from lp pair
    //bool isViaLP = _trigger == lpAddress;
    flags[1] = _trigger == lpAddress;
    // Check is to user = _to not router && not lp
    //bool isToUser = (_to != lpAddress && _to != router);
    flags[2] = (_to != lpAddress && _to != router);
    // Check is from user = _from not router && not lp
    //bool isFromUser = (_from != lpAddress && _from != router);
    flags[3] = (_from != lpAddress && _from != router);
    // In case remove LP
    //bool isRemoveLP = (_from == lpAddress && _to == router) || (_from == router && isToUser);
    flags[4] = (_from == lpAddress && _to == router) || (_from == router && flags[2]);
    // In case buy: LP transfer to user directly
    //bool isBuy = isViaLP && _from == lpAddress && isToUser;
    flags[5] = flags[1] && _from == lpAddress && flags[2];
    // In case sell (Same with add LP case): User send to LP via router (using transferFrom)
    //bool isSell = isViaRouter && (isFromUser && _to == lpAddress);
    flags[6] = flags[0] && (flags[3] && _to == lpAddress);
    // In case normal transfer
    //bool isTransfer = !isBuy && !isSell && !isRemoveLP;
    flags[7] = !flags[5] && !flags[6] && !flags[4];
    // Exclude from fees
    //bool isExcluded = isExcludedFromFees[_from] || isExcludedFromFees[_to];
    flags[8] = isExcludedFromFees[_from] || isExcludedFromFees[_to];
    // quit loop
    bool isQuitLoop = _from == address(this);
    // Logic
    bool res = true;
    if (flags[8] || flags[4] || isQuitLoop) {
      if (_to != address(this)) {
        res = IERC20(token).transfer(_to, _amount);
      }
    } else {
      // Dont allow transfer at spinning time
      if (isSpinning) return false;

      // Auto solve LP on current balance
      // Only apply on normal transfer and sell type
      if (isAutoDex && (flags[7] || flags[6])) {
        _solvePendingTaxWithBalance(_amount);
      }

      // solhint-disable reentrancy
      uint taxAmount_ = _taxCollector(_amount);
      if (_to != address(this)) {
        res = IERC20(token).transfer(_to, _amount - taxAmount_);
      }
    }
    return res;
  }

  /**
   * @dev Set exchange router
   * @param _router address of main token
   */
  function setRouter(address _router) public override onlyOwner {
    router = _router;
    IPancakeRouter02 router_ = IPancakeRouter02(router);
    IPancakeFactory factory_ = IPancakeFactory(router_.factory());
    address lpAddress_ = factory_.getPair(address(token), router_.WETH());
    if (lpAddress_ == address(0)) {
      lpAddress_ = factory_.createPair(address(token), router_.WETH());
    }
    lpAddress = lpAddress_;
  }

  /**
   * @dev Update Chainlink VRF config
   * @param _VRFCoordinator Chainlink VRF Coordinator address
   * @param _LINKToken LINK token address
   * @param _VRFKeyHash Chainlink VRF Key Hash
   * @param _VRFFee Chainlink VRF fee
   */
  function updateVRFConfig(
    address _VRFCoordinator,
    address _LINKToken,
    bytes32 _VRFKeyHash,
    uint _VRFFee
  ) public onlyOwner {
    __VRFConsumer_init(_VRFCoordinator, _LINKToken);
    vrfKeyHash = _VRFKeyHash;
    vrfFee = _VRFFee;
  }

  /**
   * @dev Update tax info
   * @param _gameTax tax for one size (devil or angel), default 2.5%
   * @param _buyBack tax for Wagyu buyback, default 2%
   * @param _sysTax tax for System, default 1%
   * @param _lpTax tax for LP, default 2%
   * @param _isAutoDex auto add LP, swap
   */
  function updateTaxInfo(
    uint _gameTax,
    uint _buyBack,
    uint _sysTax,
    uint _lpTax,
    bool _isAutoDex
  ) public onlyOwner {
    devilTax.tax = _gameTax;
    angelTax.tax = _gameTax;
    buybackTax.tax = _buyBack;
    sysTax.tax = _sysTax;
    lpTax.tax = _lpTax;
    isAutoDex = _isAutoDex;
  }

  /**
   * @dev Function to exclude a account from tax
   * @param _account account to exclude
   * @param _excluded state of excluded account true or false
   */
  function excludeFromFees(address _account, bool _excluded) public onlyOwner {
    require(isExcludedFromFees[_account] != _excluded, "Excluded");
    isExcludedFromFees[_account] = _excluded;
  }

  /**
   * @dev Function to update cycle duration
   * @param _duration cycle duration
   */
  function updateCycleDuration(uint _duration) external onlyOwner {
    cycleDuration = _duration;
  }

  /**
   * @dev Function to update cycle duration
   * @param _buybackToken Wagyu buyback token
   */
  function updateBuybackToken(address _buybackToken) external onlyOwner {
    buybackToken = _buybackToken;
  }

  /**
   * @dev Validate stage can be changed.
   * The stage must be in progress at least stageDuration before changing to next stage.
   */
  function canSpin() public view {
    require(
      !isSpinning && ((block.timestamp - cycles[cycleIndex].startTime) > cycles[cycleIndex].duration),
      "Not spin time"
    );
  }

  /**
   * @dev Spin team by external source
   * @param _teamIndex valid team 0, 1 otherwise random in contract
   */
  function spinExt(uint _teamIndex) external onlyAdmin {
    // Admin can bypass VRF lock, for emergency case with VRF issued
    isSpinning = false;
    canSpin();
    isSpinning = true;
    solvePendingTax();
    if (_teamIndex < 2) {
      _spinResult(_teamIndex);
      emit SpinExt(_teamIndex);
    } else {
      uint index_ = uint(keccak256(abi.encode(block.difficulty, block.timestamp, cycleIndex))) % 2;
      _spinResult(index_);
      emit SpinExt(index_);
    }
  }

  /**
   * @dev Requests randomness by VRF source. Everyone can spin
   * https://docs.chain.link/docs/get-a-random-number/
   */
  function spinVRF() external nonReentrant {
    canSpin();
    require(LINK.balanceOf(address(this)) >= vrfFee, "Not enough LINK");
    isSpinning = true;
    vrfRequestId = requestRandomness(vrfKeyHash, vrfFee);
    emit SpinVRF(vrfRequestId);
  }

  /**
   * @dev Callback function used by VRF Coordinator
   * If your fulfillRandomness function uses more than 200k gas, the transaction will fail.
   */
  function fulfillRandomness(bytes32 _requestId, uint256 randomness) internal override {
    require(vrfRequestId == _requestId, "Wrong request id");
    uint teamIndex_ = randomness % 2;
    _spinResult(teamIndex_);
    emit FulfillRandomnessVRF(teamIndex_);
  }

  /**
   * @dev Spin result, buy/sell bank account.
   */
  function _spinResult(uint _teamIndex) private {
    require(isSpinning, "Not spinning");
    require(_teamIndex < 2, "Wrong team");
    isSpinning = false;
    // Update current cycle
    CycleInfo storage cycleNow_ = cycles[cycleIndex];
    cycleNow_.endTime = block.timestamp;
    cycleNow_.winner = _teamIndex;
    if (_teamIndex == INDEX_DEVIL) {
      cycleNow_.amount = devilBank;
      // Devil uses all tokens to sell to Angel
      if (devilBank > 0) {
        uint bal_ = IERC20(token).balanceOf(address(this));
        if (devilBank > bal_) {
          devilBank = bal_;
        }
        uint256 currentBNB_ = address(this).balance;
        _swapTokensForETH(token, devilBank, address(this));
        uint256 swappedBNBAmount_ = address(this).balance - currentBNB_;
        angelBank += swappedBNBAmount_;
        devilBank = 0;
      }
    } else {
      cycleNow_.amount = angelBank;
      // Angel uses all BNB to buy tokens from Devil
      if (angelBank > 0) {
        uint256 bal_ = address(this).balance;
        if (angelBank > bal_) {
          angelBank = bal_;
        }
        uint256 currentTokens_ = IERC20(token).balanceOf(address(this));
        _swapETHForTokens(token, angelBank, address(this));
        uint256 swappedTokensAmount_ = IERC20(token).balanceOf(address(this)) - currentTokens_;
        devilBank += swappedTokensAmount_;
        angelBank = 0;
      }
    }

    // Prepare next cycle
    cycleIndex++;
    CycleInfo storage cycleNext_ = cycles[cycleIndex];
    cycleNext_.duration = cycleDuration;
    cycleNext_.startTime = block.timestamp;

    // Emit event
    emit History(cycleNow_.endTime, cycleNow_.winner, cycleNow_.amount);
  }

  /**
   * @dev Swap angel pending tokens to BNB
   */
  function _solvePendingAngel() private {
    if (angelTax.pending > 0) {
      uint256 currentBNB_ = address(this).balance;
      _swapTokensForETH(token, angelTax.pending, address(this));
      uint256 swappedBNBAmount_ = address(this).balance - currentBNB_;
      angelBank += swappedBNBAmount_;
      angelTax.pending = 0;
    }
  }

  /**
   * @dev Swap devil pending tokens to bank
   */
  function _solvePendingDevil() private {
    if (devilTax.pending > 0) {
      devilBank += devilTax.pending;
      devilTax.pending = 0;
    }
  }

  /**
   * @dev Buyback and burn
   */
  function _solvePendingBuyback() private {
    if (buybackTax.pending > 0) {
      _swapTokensForTokens(token, buybackToken, buybackTax.pending, address(this), true);
      uint buybackAmount_ = IERC20(buybackToken).balanceOf(address(this));
      IBurnable(buybackToken).burn(buybackAmount_);
      buybackTax.pending = 0;
    }
  }

  /**
   * @dev Add LP
   */
  function _solvePendingLP() private {
    if (lpTax.pending > 0) {
      _swapAndLiquify(token, lpTax.pending, owner());
      lpTax.pending = 0;
    }
  }

  /**
   * @dev Swap system pending to BNB
   */
  function _solvePendingSystem() private {
    if (sysTax.pending > 0) {
      if (admin != address(0)) {
        _swapTokensForETH(token, sysTax.pending, admin);
      } else {
        _swapTokensForETH(token, sysTax.pending, owner());
      }
      sysTax.pending = 0;
    }
  }

  /**
   * @dev Solve pending tax
   */
  function solvePendingTax() public nonReentrant {
    _solvePendingTaxWithBalance(0);
  }

  /**
   * @dev Solve pending tax with balance.
   * In transfer case, cannot user the whole current bal to check
   */
  function _solvePendingTaxWithBalance(uint _debt) private {
    uint bal_ = IERC20(token).balanceOf(address(this)) - _debt;

    // Angel tax
    if (angelTax.pending > bal_) {
      angelTax.pending = bal_;
    }
    bal_ -= angelTax.pending;
    _solvePendingAngel();

    // Devil tax
    if (devilTax.pending > bal_) {
      devilTax.pending = bal_;
    }
    bal_ -= devilTax.pending;
    _solvePendingDevil();

    // Buyback tax
    if (buybackTax.pending > bal_) {
      buybackTax.pending = bal_;
    }
    bal_ -= buybackTax.pending;
    _solvePendingBuyback();

    // System tax
    if (sysTax.pending > bal_) {
      sysTax.pending = bal_;
    }
    bal_ -= sysTax.pending;
    _solvePendingSystem();

    // Liquify
    if (lpTax.pending > bal_) {
      lpTax.pending = bal_;
    }
    bal_ -= lpTax.pending;
    _solvePendingLP();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Maintainable is OwnableUpgradeable {
  bool public isMaintenance;
  bool public isOutdated;

  // Check if contract is not in maintenance
  function ifNotMaintenance() internal view {
    require(!isMaintenance, "Maintenance");
    require(!isOutdated, "Outdated");
  }

  // Check if contract on maintenance for restore
  function ifMaintenance() internal view {
    require(isMaintenance, "!Maintenance");
  }

  // Enable maintenance
  function enableMaintenance(bool status) external onlyOwner {
    isMaintenance = status;
  }

  // Enable outdated
  function enableOutdated(bool status) external onlyOwner {
    isOutdated = status;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EmergencyWithdraw is OwnableUpgradeable {
  event Received(address sender, uint amount);

  /**
   * @dev allow contract to receive ethers
   */
  receive() external payable {
    emit Received(_msgSender(), msg.value);
  }

  /**
   * @dev get the eth balance on the contract
   * @return eth balance
   */
  function getEthBalance() external view returns (uint) {
    return address(this).balance;
  }

  /**
   * @dev withdraw eth balance
   */
  function withdrawEthBalance(address _to, uint _amount) external onlyOwner {
    payable(_to).transfer(_amount);
  }

  /**
   * @dev get the token balance
   * @param _tokenAddress token address
   */
  function getTokenBalance(address _tokenAddress) external view returns (uint) {
    IERC20 erc20 = IERC20(_tokenAddress);
    return erc20.balanceOf(address(this));
  }

  /**
   * @dev withdraw token balance
   * @param _tokenAddress token address
   */
  function withdrawTokenBalance(
    address _tokenAddress,
    address _to,
    uint _amount
  ) external onlyOwner {
    IERC20 erc20 = IERC20(_tokenAddress);
    erc20.transfer(_to, _amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IPancakeFactory.sol";

contract CoinDexTools is OwnableUpgradeable {
  address public router;
  address public deadAddress;

  event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
  event SwapTokensForTokens(
    address _tokenAddressFrom,
    address _tokenAddressTo,
    uint256 _tokenAmount,
    address _to,
    bool _keepWETH
  );
  event SwapETHForTokens(address _tokenAddressTo, uint256 _ethAmount, address _to);

  /**
   * @dev Upgradable initializer
   */
  function __CoinDexTools_init() internal virtual initializer {
    deadAddress = 0x000000000000000000000000000000000000dEaD;
  }

  /**
   * @dev set exchange router
   * @param _router address of main token
   */
  function setRouter(address _router) external virtual onlyOwner {
    router = _router;
  }

  /**
   * @dev set the zero Address
   * @param _deadAddress address of zero
   */
  function setDeadAddress(address _deadAddress) external virtual onlyOwner {
    deadAddress = _deadAddress;
  }

  /**
   * @dev swap tokens. Auto swap to ETH directly if _tokenAddressTo == weth
   * @param _tokenAddressFrom address of from token
   * @param _tokenAddressTo address of to token
   * @param _tokenAmount amount of tokens
   * @param _to recipient
   * @param _keepWETH For _tokenAddressTo == weth, _keepWETH = true if you want to keep output WETH instead of ETH native
   */
  function _swapTokensForTokens(
    address _tokenAddressFrom,
    address _tokenAddressTo,
    uint256 _tokenAmount,
    address _to,
    bool _keepWETH
  ) internal virtual {
    IERC20(_tokenAddressFrom).approve(router, _tokenAmount);

    address weth = IPancakeRouter02(router).WETH();
    bool isNotToETH = _tokenAddressTo != weth;
    address[] memory path;
    if (isNotToETH) {
      path = new address[](3);
      path[0] = _tokenAddressFrom;
      path[1] = weth;
      path[2] = _tokenAddressTo;
    } else {
      path = new address[](2);
      path[0] = _tokenAddressFrom;
      path[1] = weth;
    }

    // Make the swap
    if (isNotToETH || _keepWETH) {
      IPancakeRouter02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
        _tokenAmount,
        0,
        path,
        _to,
        block.timestamp
      );
    } else {
      IPancakeRouter02(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
        _tokenAmount,
        0,
        path,
        _to,
        block.timestamp
      );
    }

    emit SwapTokensForTokens(_tokenAddressFrom, _tokenAddressTo, _tokenAmount, _to, _keepWETH);
  }

  /**
   * @dev swap tokens to ETH
   * @param _tokenAddress address of from token
   * @param _tokenAmount amount of tokens
   * @param _to recipient
   */
  function _swapTokensForETH(
    address _tokenAddress,
    uint256 _tokenAmount,
    address _to
  ) internal virtual {
    _swapTokensForTokens(_tokenAddress, IPancakeRouter02(router).WETH(), _tokenAmount, _to, false);
  }

  /**
   * @dev swap tokens to ETH
   * @param _tokenAddressTo address of to token
   * @param _ethAmount eth amount
   * @param _to recipient
   */
  function _swapETHForTokens(
    address _tokenAddressTo,
    uint256 _ethAmount,
    address _to
  ) internal virtual {
    address[] memory path = new address[](2);
    path[0] = IPancakeRouter02(router).WETH();
    path[1] = _tokenAddressTo;

    // Make the swap
    IPancakeRouter02(router).swapExactETHForTokensSupportingFeeOnTransferTokens{ value: _ethAmount }(
      0,
      path,
      _to,
      block.timestamp
    );
    emit SwapETHForTokens(_tokenAddressTo, _ethAmount, _to);
  }

  /**
   * @dev add liquidity in pair
   * @param _tokenAddress address of token
   * @param _tokenAmount amount of tokens
   * @param _ethAmount amount of eth tokens
   * @param _to recipient
   */
  function _addLiquidityETH(
    address _tokenAddress,
    uint256 _tokenAmount,
    uint256 _ethAmount,
    address _to
  ) internal virtual {
    // approve token transfer to cover all possible scenarios
    IERC20(_tokenAddress).approve(router, _tokenAmount);

    // add the liquidity
    IPancakeRouter02(router).addLiquidityETH{ value: _ethAmount }(
      address(_tokenAddress),
      _tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      _to,
      block.timestamp
    );
  }

  /**
   * @dev swap tokens and add liquidity
   * @param _tokenAddress address of token
   * @param _tokenAmount amount of tokens
   * @param _to recipient
   */
  function _swapAndLiquify(
    address _tokenAddress,
    uint256 _tokenAmount,
    address _to
  ) internal virtual {
    // split the contract balance into halves
    uint256 half = _tokenAmount / 2;
    if (half > 0) {
      uint256 otherHalf = _tokenAmount - half;

      // capture the contract's current ETH balance.
      // this is so that we can capture exactly the amount of ETH that the
      // swap creates, and not make the liquidity event include any ETH that
      // has been manually sent to the contract
      uint256 initialBalance = address(this).balance;

      // swap tokens for ETH
      _swapTokensForETH(_tokenAddress, half, address(this));

      // how much ETH did we just swap into?
      uint256 swappedETHAmount = address(this).balance - initialBalance;

      // add liquidity to dex
      if (swappedETHAmount > 0) {
        _addLiquidityETH(_tokenAddress, otherHalf, swappedETHAmount, _to);
        emit SwapAndLiquify(half, swappedETHAmount, otherHalf);
      }
    }
  }

  /**
   * @dev burn by transfer to dead address
   * @param _tokenAddress address of token
   * @param _tokenAmount amount of tokens
   */
  function _burnByDeadAddress(address _tokenAddress, uint256 _tokenAmount) internal virtual {
    IERC20(_tokenAddress).transfer(deadAddress, _tokenAmount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract AntiWhale is OwnableUpgradeable {
  uint256 public startDate;
  uint256 public endDate;
  uint256 public limitWhale;
  bool public antiWhaleActivated;

  /**
   * @dev activate antiwhale
   */
  function activateAntiWhale() external onlyOwner {
    require(antiWhaleActivated == false, "Already activated");
    antiWhaleActivated = true;
  }

  /**
   * @dev deactivate antiwhale
   */
  function deActivateAntiWhale() external onlyOwner {
    require(antiWhaleActivated == true, "Already activated");
    antiWhaleActivated = false;
  }

  /**
   * @dev set antiwhale settings
   * @param _startDate start date of the antiwhale
   * @param _endDate end date of the antiwhale
   * @param _limitWhale limit amount of antiwhale
   */
  function setAntiWhale(
    uint256 _startDate,
    uint256 _endDate,
    uint256 _limitWhale
  ) external onlyOwner {
    startDate = _startDate;
    endDate = _endDate;
    limitWhale = _limitWhale;
    antiWhaleActivated = true;
  }

  /**
   * @dev check if antiwhale is enable and amount should be less than to whale in specify duration
   * @param _from from address
   * @param _to to address
   * @param _amount amount to check antiwhale
   */
  function isWhale(
    address _from,
    address _to,
    uint256 _amount
  ) public view returns (bool) {
    if (_from == owner() || _to == owner() || antiWhaleActivated == false || _amount <= limitWhale) return false;

    if (block.timestamp >= startDate && block.timestamp <= endDate) return true;

    return false;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Adminable is OwnableUpgradeable {
  address public admin;

  function setAdmin(address _admin) public onlyOwner {
    admin = _admin;
  }

  function isAdmin() public view returns (bool) {
    return admin == _msgSender();
  }

  modifier onlyAdmin() {
    require(owner() == _msgSender() || isAdmin(), "Caller is not the admin");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/VRFRequestIDBase.sol";

// Fork from "@chainlink/contracts/src/v0.8/VRFConsume.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsume is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  // solhint-disable var-name-mixedcase
  LinkTokenInterface internal LINK;
  address private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  function __VRFConsumer_init(address _vrfCoordinator, address _link) internal virtual {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ITokenPresenter {
  function receiveTokens(
    address _trigger,
    address _from,
    address _to,
    uint256 _amount
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IPancakeRouter01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  )
    external
    returns (
      uint amountA,
      uint amountB,
      uint liquidity
    );

  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  )
    external
    payable
    returns (
      uint amountToken,
      uint amountETH,
      uint liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);

  function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint amountA, uint amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint amountToken, uint amountETH);

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactETHForTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts);

  function swapTokensForExactETH(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactTokensForETH(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapETHForExactTokens(
    uint amountOut,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts);

  function quote(
    uint amountA,
    uint reserveA,
    uint reserveB
  ) external pure returns (uint amountB);

  function getAmountOut(
    uint amountIn,
    uint reserveIn,
    uint reserveOut
  ) external pure returns (uint amountOut);

  function getAmountIn(
    uint amountOut,
    uint reserveIn,
    uint reserveOut
  ) external pure returns (uint amountIn);

  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IPancakeFactory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function allPairs(uint) external view returns (address pair);

  function allPairsLength() external view returns (uint);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IBurnable {
  function burn(uint amount) external;

  function burnFrom(address account, uint amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}