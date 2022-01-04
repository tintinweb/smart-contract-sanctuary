// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity 0.8.10;

import "./token/ReflectionTrackerToken.sol";

contract Equity_RTT is ReflectionTrackerToken {
    constructor(address[] memory teamAndMarketingWallets_, address uniswapV2Router02Address_, address defaultReflectionTokenAddress_) ReflectionTrackerToken(
        "Equity - Reflection Tracker Token",
        "Equity_RTT",
        uniswapV2Router02Address_,
        defaultReflectionTokenAddress_,
        10800,
        20,
        400000,
        teamAndMarketingWallets_
    ) {}
}

// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity 0.8.10;

import "../access/SharedOwnable.sol";
import "../interfaces/IReflectionTracker.sol";
import "../libraries/IterableMapping.sol";
import "../libraries/SafeMathInt.sol";
import "../libraries/SafeMathUint.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract ReflectionTrackerToken is ERC20, IReflectionTracker, SharedOwnable {
  using SafeMathUint for uint256;
  using SafeMathInt for int256;
  using IterableMapping for IterableMapping.Map;

  address constant private deadAddress = 0x000000000000000000000000000000000000dEaD;
  uint256 constant private magnitude = 2**128;

  address private _reflectiveTokenAddress;
  IUniswapV2Router02 private _uniswapV2Router02;
  address private _reflectiveTokenPairAddress;
  IERC20 private _defaultReflectionToken;
  uint256 private _claimCooldown;
  uint256 private _minimumTokenBalanceForReflections;
  bool _excludedReflectionStateOfBNB;
  mapping(address => bool) private _excludedReflectionTokenState;
  mapping(address => bool) private _excludedFromReflections;
  uint256 private _processingGas;
  mapping(address => bool) private _reflectionInBNBs;
  mapping(address => mapping(address => address)) private _reflectionTokenAddresses;
  IterableMapping.Map private _tokenHolders;
  uint256 private _lastProcessedIndex;
  uint256 private _totalReflectionsTransferred;
  mapping(address => uint256) private _withdrawnReflections;
  mapping(address => uint256) private _lastClaimTimestamps;
  uint256 private _magnifiedReflectionPerShare;
  mapping(address => int256) private _magnifiedReflectionCorrections;

  constructor(string memory name_, string memory symbol_, address uniswapV2Router02Address_, address defaultReflectionTokenAddress_, uint256 claimCooldown_, uint256 minimumTokenBalanceForReflections_, uint256 processingGas_, address[] memory sharedOwners_) ERC20(name_, symbol_) {
    _uniswapV2Router02 = IUniswapV2Router02(uniswapV2Router02Address_);
    _defaultReflectionToken = IERC20(defaultReflectionTokenAddress_);
    _claimCooldown = claimCooldown_;
    _minimumTokenBalanceForReflections = minimumTokenBalanceForReflections_ * (10**decimals());
    _processingGas = processingGas_;

    _excludedFromReflections[address(this)] = true;
    _excludedFromReflections[deadAddress] = true;
    _excludedFromReflections[uniswapV2Router02Address_] = true;

    _defaultReflectionToken.totalSupply();
    _getTokenPair(_uniswapV2Router02, defaultReflectionTokenAddress_);

    uint sharedOwnersLength = sharedOwners_.length;
    for (uint i = 0; i < sharedOwnersLength; i++)
      setSharedOwner(sharedOwners_[i]);

    _excludedFromReflections[msg.sender] = true;
  }

  modifier onlyReflectiveToken() {
      require(_reflectiveTokenAddress == msg.sender, "ReflectionTrackerToken: caller is not the reflective token");
      _;
  }

  receive() external payable {}

  function isBoundTo(address reflectiveTokenAddress) external view returns (bool) {
    return _reflectiveTokenAddress == reflectiveTokenAddress;
  }

  function bindTo(address reflectiveTokenAddress) external onlySharedOwners {
    if (_reflectiveTokenAddress != address(0))
      revert("ReflectionTrackerToken: already bound");

    _reflectiveTokenAddress = reflectiveTokenAddress;
    _reflectiveTokenPairAddress = _getTokenPair(_uniswapV2Router02, _reflectiveTokenAddress);

    _excludedReflectionTokenState[_reflectiveTokenAddress] = true;
    _excludedFromReflections[_reflectiveTokenAddress] = true;
    _excludedFromReflections[_reflectiveTokenPairAddress] = true;

    (IERC20(_reflectiveTokenAddress)).totalSupply();
    setSharedOwner(_reflectiveTokenAddress);
  }

  function getBalanceOf(address account) external view returns (uint256) {
    return _getBalanceOf(account, false);
  }

  function setBalanceOf(address account, uint256 balance) external onlyReflectiveToken {
    _setBalanceOf(account, balance);
  }

  function refreshBalanceOf(address account) external {
    _setBalanceOf(account, IERC20(_reflectiveTokenAddress).balanceOf(account));
  }

  function refreshBalance() external {    
    _setBalanceOf(msg.sender, IERC20(_reflectiveTokenAddress).balanceOf(msg.sender));
  }

  function getUniswapV2Router02Address() external view returns (address) {
    return address(_uniswapV2Router02);
  }

  function setUniswapV2Router02Address(address uniswapV2Router02Address) external onlySharedOwners {
    address oldUniswapV2Router02Address = address(_uniswapV2Router02);
    if (oldUniswapV2Router02Address != uniswapV2Router02Address) {
      address oldReflectiveTokenPairAddress = _reflectiveTokenPairAddress;
      IUniswapV2Router02 uniswapV2Router02 = IUniswapV2Router02(uniswapV2Router02Address);
      address reflectiveTokenPairAddress = _getTokenPair(uniswapV2Router02, _reflectiveTokenAddress);

      _getTokenPair(uniswapV2Router02, address(_defaultReflectionToken));

      if (oldReflectiveTokenPairAddress != reflectiveTokenPairAddress) {
        _setExcludedFromReflectionsOf(oldReflectiveTokenPairAddress, false);
        _setExcludedFromReflectionsOf(reflectiveTokenPairAddress, true);
        _reflectiveTokenPairAddress = reflectiveTokenPairAddress;
      }

      _setExcludedFromReflectionsOf(oldUniswapV2Router02Address, false);
      _setExcludedFromReflectionsOf(uniswapV2Router02Address, true);
      _uniswapV2Router02 = uniswapV2Router02;
      emit UniswapV2Router02AddressUpdated(oldUniswapV2Router02Address, uniswapV2Router02Address);
    }
  }

  function getDefaultReflectionTokenAddress() external view returns (address) {
    return address(_defaultReflectionToken);
  }

  function setDefaultReflectionTokenAddress(address defaultReflectionTokenAddress) external onlySharedOwners {
    if (_excludedReflectionTokenState[defaultReflectionTokenAddress])
      revert("ReflectionTrackerToken: excluded reflection token");

    address oldDefaultReflectionTokenAddress = address(_defaultReflectionToken);
    if (oldDefaultReflectionTokenAddress != defaultReflectionTokenAddress) {
      IERC20 defaultReflectionToken = IERC20(defaultReflectionTokenAddress);

      defaultReflectionToken.totalSupply();
      _getTokenPair(_uniswapV2Router02, defaultReflectionTokenAddress);

      _defaultReflectionToken = defaultReflectionToken;
      emit DefaultReflectionTokenAddressUpdated(oldDefaultReflectionTokenAddress, defaultReflectionTokenAddress);
    }
  }

  function getClaimCooldown() external view returns (uint256) {
    return _claimCooldown;
  }

  function setClaimCooldown(uint256 claimCooldown) external onlySharedOwners {
    uint256 oldClaimCooldown = _claimCooldown;
    if (oldClaimCooldown != claimCooldown) {
      _claimCooldown = claimCooldown;
      emit ClaimCooldownUpdated(oldClaimCooldown, claimCooldown);
    }
  }

  function getMinimumTokenBalanceForReflections() external view returns (uint256) {
    return _minimumTokenBalanceForReflections;
  }

  function setMinimumTokenBalanceForReflections(uint256 minimumTokenBalanceForReflections) external onlySharedOwners {
    minimumTokenBalanceForReflections *= (10**decimals());
    uint256 oldMinimumTokenBalanceForReflections = _minimumTokenBalanceForReflections;
    if (oldMinimumTokenBalanceForReflections != minimumTokenBalanceForReflections) {
      _minimumTokenBalanceForReflections = minimumTokenBalanceForReflections;
      emit MinimumTokenBalanceForReflectionsUpdated(oldMinimumTokenBalanceForReflections, minimumTokenBalanceForReflections);
    }
  }

  function getExcludedReflectionStateOfBNB() external view returns (bool) {
    return _excludedReflectionStateOfBNB;
  }

  function setExcludedReflectionStateOfBNB(bool excludedReflectionStateOfBNB) external onlySharedOwners {
    bool oldExcludedReflectionStateOfBNB = _excludedReflectionStateOfBNB;
    if (oldExcludedReflectionStateOfBNB != excludedReflectionStateOfBNB) {
      _excludedReflectionStateOfBNB = excludedReflectionStateOfBNB;
      emit ExcludedReflectionStateOfBNBUpdated(oldExcludedReflectionStateOfBNB, excludedReflectionStateOfBNB);
    }
  }

  function getExcludedReflectionTokenStateOf(address account) external view returns (bool) {
    return _excludedReflectionTokenState[account];
  }

  function setExcludedReflectionTokenStateOf(address account, bool excludedReflectionTokenState) external onlySharedOwners {
    bool oldExcludedReflectionTokenState = _excludedFromReflections[account];
    if (oldExcludedReflectionTokenState != excludedReflectionTokenState) {
      _excludedReflectionTokenState[account] = excludedReflectionTokenState;
      emit ExcludedReflectionTokenStateUpdated(account, oldExcludedReflectionTokenState, excludedReflectionTokenState);
    }
  }

  function getExcludedFromReflectionsOf(address account) external view returns (bool) {
    return _excludedFromReflections[account];
  }

  function setExcludedFromReflectionsOf(address account, bool excludedFromReflections) external onlySharedOwners {
    _setExcludedFromReflectionsOf(account, excludedFromReflections);
  }

  function getProcessingGas() external view returns (uint256) {
    return _processingGas;
  }

  function setProcessingGas(uint256 processingGas) external onlySharedOwners {
    uint256 oldProcessingGas = _processingGas;
    if (oldProcessingGas != processingGas) {
      _processingGas = processingGas;
      emit ProcessingGasUpdated(oldProcessingGas, processingGas);
    }
  }

  function getReflectionInBNB() external view returns (bool) {
    return _reflectionInBNBs[msg.sender];
  }

  function setReflectionInBNB(bool reflectionInBNB) external {
    if (_excludedReflectionStateOfBNB)
      revert("ReflectionTrackerToken: excluded reflection in bnb");

    bool oldReflectionInBNB = _reflectionInBNBs[msg.sender];
    if (oldReflectionInBNB != reflectionInBNB) {
      _reflectionInBNBs[msg.sender] = reflectionInBNB;
      delete _reflectionTokenAddresses[address(_uniswapV2Router02)][msg.sender];
      emit ReflectionInBNBUpdated(msg.sender, oldReflectionInBNB, reflectionInBNB);
    }
  }

  function getReflectionTokenAddress() external view returns (address) {
    return _reflectionTokenAddresses[address(_uniswapV2Router02)][msg.sender];
  }

  function setReflectionTokenAddress(address reflectionTokenAddress) external {
    if (_excludedReflectionTokenState[reflectionTokenAddress])
      revert("ReflectionTrackerToken: excluded reflection token address");

    address oldReflectionTokenAddress = _reflectionTokenAddresses[address(_uniswapV2Router02)][msg.sender];
    if (oldReflectionTokenAddress != reflectionTokenAddress) {
      IERC20 reflectionToken = IERC20(reflectionTokenAddress);

      reflectionToken.totalSupply();
      _getTokenPair(_uniswapV2Router02, reflectionTokenAddress);

      _reflectionTokenAddresses[address(_uniswapV2Router02)][msg.sender] = reflectionTokenAddress;
      delete _reflectionInBNBs[msg.sender];
      emit ReflectionTokenAddressUpdated(msg.sender, oldReflectionTokenAddress, reflectionTokenAddress);
    }
  }

  function getNumberOfHolders() external view returns (uint256) {
    return _tokenHolders.keys.length;
  }

  function getLastProcessedIndex() external view returns (uint256) {
    return _lastProcessedIndex;
  }

  function getTotalReflectionsTransferred() external view returns (uint256) {
    return _totalReflectionsTransferred;
  }

  function getWithdrawnReflectionsOf(address account) external view returns (uint256) {
    return _withdrawnReflections[account];
  }

  function getWithdrawableReflectionsOf(address account) external view returns (uint256) {
    return _getWithdrawableReflectionsOf(account);
  }

  function getAccountInfoOf(address account) external view returns (AccountInfo memory) {
    return _getAccountInfo(account);
  }

  function getAccountInfoAtIndex(uint256 index) external view returns (AccountInfo memory) {
    if (index >= _tokenHolders.size())
      return AccountInfo(address(0), -1, -1, 0, 0, 0, 0, 0);

    address account = _tokenHolders.getKeyAtIndex(index);
    return _getAccountInfo(account);
  }

  function _getAccountInfo(address account) private view returns (AccountInfo memory accountInfo) {
      accountInfo.account = account;
      accountInfo.index = _tokenHolders.getIndexOfKey(account);
      accountInfo.iterationsUntilProcessed = -1;

      if (accountInfo.index >= 0) {
          if (uint256(accountInfo.index) > _lastProcessedIndex)
              accountInfo.iterationsUntilProcessed = accountInfo.index - int256(_lastProcessedIndex);
          else {
              uint256 processesUntilEndOfArray = _tokenHolders.keys.length > _lastProcessedIndex ? _tokenHolders.keys.length -_lastProcessedIndex : 0;
              accountInfo.iterationsUntilProcessed = accountInfo.index + int256(processesUntilEndOfArray);
          }
      }

      accountInfo.withdrawableReflections = _getWithdrawableReflectionsOf(account);
      accountInfo.totalReflections = _accumulativeReflectionOf(account);
      accountInfo.lastClaimTimestamp = _lastClaimTimestamps[account];
      accountInfo.nextClaimTimestamp = accountInfo.lastClaimTimestamp > 0 ? accountInfo.lastClaimTimestamp + _claimCooldown : 0;
      accountInfo.secondsUntilAutoClaimAvailable = accountInfo.nextClaimTimestamp > block.timestamp ? accountInfo.nextClaimTimestamp - block.timestamp : 0;
  }

  function transferReflections() external payable onlyReflectiveToken {
    _transferReflections(msg.sender, msg.value);
  }

  function transferReflections(uint256 amount) external onlyReflectiveToken {
    _transferReflections(msg.sender, amount);
  }

  function process() external returns (bool) {
    return _process(msg.sender, false);
  }

  function processAll() external onlySharedOwners returns (uint256 gasUsed, uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
    return _processAll(_processingGas);
  }

  function processAll(uint256 processingGas) external onlySharedOwners returns (uint256 gasUsed, uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
    return _processAll(processingGas);
  }

  function _transfer(address, address, uint256) internal override pure {
    revert("ReflectionTrackerToken: transfer is not allowed");
  }

  function _mint(address account, uint256 amount) internal override {
    super._mint(account, amount);
    _magnifiedReflectionCorrections[account] -= (_magnifiedReflectionPerShare * amount).toInt256Safe();
  }

  function _burn(address account, uint256 amount) internal override {
    super._burn(account, amount);
    _magnifiedReflectionCorrections[account] += (_magnifiedReflectionPerShare * amount).toInt256Safe();
  }

  function _getTokenPair(IUniswapV2Router02 uniswapV2Router02, address tokenAddress) private view returns (address) {
    address tokenPair = IUniswapV2Factory(uniswapV2Router02.factory()).getPair(tokenAddress, uniswapV2Router02.WETH());
    if (tokenPair == address(0))
      revert("ReflectionTrackerToken: no valid token pair");

    return tokenPair;
  }
  function _getBalanceOf(address account, bool ignoreExcludedFromReflections) private view returns (uint256) {
    return ignoreExcludedFromReflections || !_excludedFromReflections[account] ? balanceOf(account) : 0;
  }

  function _setBalanceOf(address account, uint256 balance) private {
    if (balance == 0 || _excludedFromReflections[account]) {
      _updateBalanceOf(account, 0);
      _tokenHolders.remove(account);
    } else {
      _updateBalanceOf(account, balance);
      _tokenHolders.set(account, balance);
      _process(account, true);
    }
  }

  function _updateBalanceOf(address account, uint256 balance) private {
    uint256 currentBalance = _getBalanceOf(account, true);

    if (balance > currentBalance) {
      uint256 mintAmount = balance - currentBalance;
      _mint(account, mintAmount);
    } else if (balance < currentBalance) {
      uint256 burnAmount = currentBalance - balance;
      _burn(account, burnAmount);
    }
  }

  function _setExcludedFromReflectionsOf(address account, bool excludedFromReflections) private {
    bool oldExcludedFromReflections = _excludedFromReflections[account];
    if (oldExcludedFromReflections != excludedFromReflections) {
      _excludedFromReflections[account] = excludedFromReflections;
      _setBalanceOf(account, IERC20(_reflectiveTokenAddress).balanceOf(account));
      emit ExcludedFromReflectionsUpdated(account, oldExcludedFromReflections, excludedFromReflections);
    }
  }

  function _getWithdrawableReflectionsOf(address account) private view returns (uint256) {
    return _accumulativeReflectionOf(account) - _withdrawnReflections[account];
  }

  function _accumulativeReflectionOf(address account) private view returns (uint256) {
    return ((_magnifiedReflectionPerShare * _getBalanceOf(account, false)).toInt256Safe() + _magnifiedReflectionCorrections[account]).toUint256Safe() / magnitude;
  }

  function _transferReflections(address account, uint256 amount) private {
    if (totalSupply() > 0 && amount > 0) {
      _magnifiedReflectionPerShare += (amount * magnitude) / totalSupply();
      emit ReflectionsTransferred(account, amount);
      _totalReflectionsTransferred += amount;
    }
  }

  function _canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    return lastClaimTime > block.timestamp ? false : block.timestamp - lastClaimTime >= _claimCooldown;
  }

  function _process(address account, bool automatic) private returns (bool) {
    if (_getBalanceOf(account, false) >= _minimumTokenBalanceForReflections) {
      uint256 withdrawnReflections = _withdrawReflectionOf(account, automatic);

      if (withdrawnReflections > 0) {
        _lastClaimTimestamps[account] = block.timestamp;
        return true;
      }
    }

    return false;
  }

  function _processAll(uint256 gas) private returns (uint256 gasUsed, uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
    uint256 numberOfTokenHolders = _tokenHolders.keys.length;
    if (numberOfTokenHolders == 0)
      return (0, 0, 0, _lastProcessedIndex);

    lastProcessedIndex = _lastProcessedIndex;

    uint256 gasLeft = gasleft();
    while(gasUsed < gas && iterations < numberOfTokenHolders) {
      _lastProcessedIndex++;
      if (_lastProcessedIndex >= _tokenHolders.keys.length)
        _lastProcessedIndex = 0;

      address account = _tokenHolders.keys[_lastProcessedIndex];
      if (_canAutoClaim(_lastClaimTimestamps[account]) && _process(account, true))
        claims++;
      iterations++;

      uint256 newGasLeft = gasleft();
      if (gasLeft > newGasLeft)
        gasUsed += gasLeft - newGasLeft;
      gasLeft = newGasLeft;
    }

    _lastProcessedIndex = lastProcessedIndex;
    return (gasUsed, iterations, claims, lastProcessedIndex);
  }

  function _withdrawReflectionOf(address account, bool automatic) private returns (uint256) {
    address reflectionTokenAddress = _reflectionTokenAddresses[address(_uniswapV2Router02)][account];
    IERC20 reflectionToken = reflectionTokenAddress == address(0) || _excludedReflectionTokenState[reflectionTokenAddress] ? _defaultReflectionToken : IERC20(reflectionTokenAddress);
    uint256 withdrawableReflection = _getWithdrawableReflectionsOf(account);
    if (withdrawableReflection > 0) {
      bool success;

      if (_reflectionInBNBs[account] && !_excludedReflectionStateOfBNB) {
        address[] memory path = new address[](2);
        path[0] = address(_defaultReflectionToken);
        path[1] = _uniswapV2Router02.WETH();

        try _defaultReflectionToken.approve(address(_uniswapV2Router02), withdrawableReflection) {} catch {}

        uint256 bnbAmountBeforeSwap = account.balance;
        try _uniswapV2Router02.swapExactTokensForETHSupportingFeeOnTransferTokens(withdrawableReflection, 0, path, account, block.timestamp) {} catch {}
        uint256 bnbAmountAfterSwap = account.balance;

        success = bnbAmountAfterSwap > bnbAmountBeforeSwap;
        uint256 bnbAmount = bnbAmountAfterSwap - bnbAmountBeforeSwap;

        if (success)
          emit ReflectionBNBClaimed(account, bnbAmount, automatic);
      } else {
        uint256 reflectionTokenAmount;

        if (reflectionToken != _defaultReflectionToken) {
          address[] memory path = new address[](3);
          path[0] = address(_defaultReflectionToken);
          path[1] = _uniswapV2Router02.WETH();
          path[2] = address(reflectionToken);

          _defaultReflectionToken.approve(address(_uniswapV2Router02), withdrawableReflection);

          uint256 tokenAmountBeforeSwap = reflectionToken.balanceOf(account);
          _uniswapV2Router02.swapExactTokensForTokensSupportingFeeOnTransferTokens(withdrawableReflection, 0, path, account, block.timestamp);
          uint256 tokenAmountAfterSwap = reflectionToken.balanceOf(account);

          success = tokenAmountAfterSwap > tokenAmountBeforeSwap;
          reflectionTokenAmount = tokenAmountAfterSwap - tokenAmountBeforeSwap;
        } else {
          success = reflectionToken.transfer(account, withdrawableReflection);
          reflectionTokenAmount = withdrawableReflection;
        }
        
        if (success)
          emit ReflectionTokenClaimed(account, address(reflectionToken), reflectionTokenAmount, automatic);
      }
      
      if (success) {
        _withdrawnReflections[account] += withdrawableReflection;
        return withdrawableReflection;
      }
    }

    return 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);

    return b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library SafeMathInt {
  function toUint256Safe(int256 a) internal pure returns (uint256) {
    require(a >= 0);

    return uint256(a);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library IterableMapping {
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function size(Map storage map) internal view returns (uint256) {
        return map.keys.length;
    }

    function get(Map storage map, address key) internal view returns (uint256) {
        return map.values[key];
    }

    function getKeyAtIndex(Map storage map, uint256 index) internal view returns (address) {
        return map.keys[index];
    }

    function getIndexOfKey(Map storage map, address key) internal view returns (int256) {
        return map.inserted[key] ? int256(map.indexOf[key]) : -1;
    }

    function set(Map storage map, address key, uint256 val) internal {
        if (map.inserted[key])
            map.values[key] = val;
        else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) internal {
        if (!map.inserted[key])
            return;

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity 0.8.10;

interface IReflectionTracker {
  struct AccountInfo {
    address account;
    int256 index;
    int256 iterationsUntilProcessed;
    uint256 withdrawableReflections;
    uint256 totalReflections;
    uint256 lastClaimTimestamp;
    uint256 nextClaimTimestamp;
    uint256 secondsUntilAutoClaimAvailable;
  }

  event UniswapV2Router02AddressUpdated(address indexed oldUniswapV2Router02Address, address indexed newUniswapV2Router02Address);
  event DefaultReflectionTokenAddressUpdated(address indexed oldDefaultReflectionTokenAddress, address indexed newDefaultReflectionTokenAddress);
  event ClaimCooldownUpdated(uint256 oldClaimCooldown, uint256 newClaimCooldown);
  event MinimumTokenBalanceForReflectionsUpdated(uint256 oldMinimumTokenBalanceForReflections, uint256 newMinimumTokenBalanceForReflections);
  event ExcludedReflectionStateOfBNBUpdated(bool oldExcludedReflectionStateOfBNB, bool newExcludedReflectionStateOfBNB);
  event ExcludedReflectionTokenStateUpdated(address indexed account, bool oldExcludedReflectionTokenState, bool newExcludedReflectionTokenState);
  event ExcludedFromReflectionsUpdated(address indexed account, bool oldExcludedFromReflections, bool newExcludedFromReflections);
  event ProcessingGasUpdated(uint256 oldProcessingGas, uint256 newProcessingGas);

  event ReflectionInBNBUpdated(address indexed account, bool oldReflectionInBNB, bool newReflectionInBNB);
  event ReflectionTokenAddressUpdated(address indexed account, address oldReflectionTokenAddress, address newReflectionTokenAddress);

  event ReflectionsTransferred(address indexed account, uint256 defaultReflectionTokenAmount);

  event ReflectionBNBClaimed(address indexed account, uint256 bnbAmount, bool automatic);
  event ReflectionTokenClaimed(address indexed account, address tokenAddress, uint256 tokenAmount, bool automatic);

  function isBoundTo(address reflectiveTokenAddress) external view returns (bool);
  function bindTo(address reflectiveTokenAddress) external;

  function getBalanceOf(address account) external view returns (uint256);
  function setBalanceOf(address account, uint256 balance) external;
  function refreshBalanceOf(address account) external;
  function refreshBalance() external;

  function getUniswapV2Router02Address() external view returns (address);
  function setUniswapV2Router02Address(address uniswapV2Router02Address) external;
  function getDefaultReflectionTokenAddress() external view returns (address);
  function setDefaultReflectionTokenAddress(address defaultReflectionTokenAddress) external;
  function getClaimCooldown() external view returns (uint256);
  function setClaimCooldown(uint256 claimCooldown) external;
  function getMinimumTokenBalanceForReflections() external view returns (uint256);
  function setMinimumTokenBalanceForReflections(uint256 minimumTokenBalanceForReflections) external;
  function getExcludedReflectionStateOfBNB() external view returns (bool);
  function setExcludedReflectionStateOfBNB(bool excludedReflectionStateOfBNB) external;
  function getExcludedReflectionTokenStateOf(address account) external view returns (bool);
  function setExcludedReflectionTokenStateOf(address account, bool excludedReflectionTokenState) external;
  function getExcludedFromReflectionsOf(address account) external view returns (bool);
  function setExcludedFromReflectionsOf(address account, bool excludedFromReflections) external;
  function getProcessingGas() external view returns (uint256);
  function setProcessingGas(uint256 processingGas) external;

  function getReflectionInBNB() external view returns (bool);
  function setReflectionInBNB(bool reflectionInBNB) external;
  function getReflectionTokenAddress() external view returns (address);
  function setReflectionTokenAddress(address reflectionTokenAddress) external;

  function getNumberOfHolders() external view returns (uint256);
  function getLastProcessedIndex() external view returns (uint256);
  function getTotalReflectionsTransferred() external view returns (uint256);

  function getWithdrawnReflectionsOf(address account) external view returns (uint256);
  function getWithdrawableReflectionsOf(address account) external view returns (uint256);

  function getAccountInfoOf(address account) external view returns (AccountInfo memory);
  function getAccountInfoAtIndex(uint256 index) external view returns (AccountInfo memory);

  function transferReflections() external payable;
  function transferReflections(uint256 amount) external;

  function process() external returns (bool);
  function processAll() external returns (uint256 gasUsed, uint256 iterations, uint256 claims, uint256 lastProcessedIndex);
  function processAll(uint256 processingGas) external returns (uint256 gasUsed, uint256 iterations, uint256 claims, uint256 lastProcessedIndex);
}

// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract SharedOwnable is Ownable {
    address private _creator;
    mapping(address => bool) private _sharedOwners;
    
    event SharedOwnershipAdded(address indexed sharedOwner);

    constructor() Ownable() {
        _creator = msg.sender;
        _setSharedOwner(msg.sender);
        renounceOwnership();
    }

    modifier onlySharedOwners() {
        require(_sharedOwners[msg.sender], "SharedOwnable: caller is not a shared owner");
        _;
    }

    function getCreator() external view returns (address) {
        return _creator;
    }

    function isSharedOwner(address account) external view returns (bool) {
        return _sharedOwners[account];
    }

    function setSharedOwner(address account) internal onlySharedOwners {
        _setSharedOwner(account);
    }

    function _setSharedOwner(address account) private {
        _sharedOwners[account] = true;
        emit SharedOwnershipAdded(account);
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}