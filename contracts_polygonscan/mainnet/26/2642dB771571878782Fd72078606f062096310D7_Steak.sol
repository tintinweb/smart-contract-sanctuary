// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./HotPotato.sol";
import "./NFTRouter.sol";

contract Steak is ERC20 {

  address private _owner;
  address private _hptAddress;
  address private _finisherAddress;

  mapping (address => bool) private _managers;

  mapping (uint256 => uint256) private _epochStakes;
  mapping (address => uint256) private _stakeEpoch;
  mapping (address => bool) private _isStaked;
  mapping (uint256 => mapping(address => uint256)) private _epochContributingStakes;

  address private _nftRouterAddress;

  mapping (address => bool) private _avoidClear;

  event Stake(
    address account,
    uint256 amount,
    uint256 epoch,
    uint256 timestamp
  );

  event Unstake(
    address account,
    uint256 amount,
    uint256 epoch,
    uint256 timestamp
  );
  
  constructor() ERC20("Steak", "STK") {
    _owner = msg.sender;
  }

  function addManager(address _account) public {
    require(msg.sender == _owner);
    _managers[_account] = true;
  }

  function removeManager(address _account) public {
    require(msg.sender == _owner);
    _managers[_account] = false;
  }

  function setHPT(address hptAddress_) public {
    require(msg.sender == _owner, "Steak: Only the contract owner can set the HPT address");
    _hptAddress = hptAddress_;
  }

  function setFinisher(address finisherAddress_) public {
    require(msg.sender == _owner, "Steak: Only the contract owner can set the finisher address");
    _finisherAddress = finisherAddress_;
  }

  function setNFTRouterAddress(address nftRouterAddress_) public {
    require(msg.sender == _owner);
    _nftRouterAddress = nftRouterAddress_;
  }

  function nftRouter() private view returns (NFTRouter) {
    return NFTRouter(_nftRouterAddress);
  }

  function enter(address account, uint256 amount, uint256 epoch) public {
    require(msg.sender == _hptAddress, "Steak: Only the HPT contract can call enter");
    _avoidClear[account] = true;
    _mint(account, amount);
    increaseEpochStakes(epoch, amount);
    increaseEpochContribution(account, epoch, amount);
    _avoidClear[account] = false;
    
    emit Stake(account, amount, epoch, block.timestamp);
  }

  function exit(address account, uint256 amount, uint256 epoch) public {
    require(msg.sender == _hptAddress, "Steak: Only the HPT contract can call exit");

    _avoidClear[account] = true;
    _burn(account, amount);
    
    reduceEpochContribution(account, epoch, amount);

    if (balanceOf(account) == 0) {
      setUnstaked(account);
    }
    _avoidClear[account] = false;

    nftRouter().burnCurrentCard(account, 2);

    emit Unstake(account, amount, epoch, block.timestamp);
  }

  function mint(address account, uint256 amount) public  {
    require(msg.sender == _hptAddress || msg.sender == _finisherAddress, "Steak: Only the HPT contract can call mint");
    _avoidClear[account] = true;
    _mint(account, amount);
    _avoidClear[account] = false;
  }

  function airdrop(address account, uint256 amount) public {
    require(msg.sender == _owner);

    HotPotato hotPotato = HotPotato(_hptAddress);
    require(hotPotato.getCurrentEpoch() <= 50);

    _mint(account, amount);
  }

  function getEpochStakedIn(address account) public view returns (uint256) {
    return _stakeEpoch[account];
  }

  function getEpochStakes(uint256 epoch) public view returns (uint256) {
    return _epochStakes[epoch];
  }

  function isStaked(address account) public view returns (bool) {
    return _isStaked[account];
  }

  function getEpochContribution(address account, uint256 epoch) public view returns (uint256) {
    return _epochContributingStakes[epoch][account];
  }

  function setStaked(address account, uint256 epoch) public {
    require(msg.sender == _hptAddress, "Steak: Only the HPT contract can call setStaked");
    _stakeEpoch[account] = epoch;
    _isStaked[account] = true;
  }

  function setUnstaked(address account) private {
    _stakeEpoch[account] = 0;
    _isStaked[account] = false;
  }

  function increaseEpochStakes(uint256 epoch, uint256 amount) public {
    require(msg.sender == _hptAddress, "Steak: Only the HPT contract can call increaseEpochStakes");
    _epochStakes[epoch] += amount;
  }

  function reduceEpochStakes(uint256 epoch, uint256 amount) private {
    if (_epochStakes[epoch] > amount) {
      _epochStakes[epoch] -= amount;
    } else {
      _epochStakes[epoch] = 0;
    }
  }

  function increaseEpochContribution(address account, uint256 epoch, uint256 amount) private {
    _epochContributingStakes[epoch][account] += amount;
  }

  function reduceEpochContribution(address account, uint256 epoch, uint256 amount) private {
    HotPotato hotPotato = HotPotato(_hptAddress);

    if (getEpochContribution(account, epoch) > amount) {
      _epochContributingStakes[epoch][account] -= amount;
    } else {
      _epochContributingStakes[epoch][account] = 0;
    }

    if (hotPotato.getCurrentEpoch() == epoch) {
      reduceEpochStakes(epoch, amount);
    }
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
    if (!_avoidClear[from]) {
      clearStakingRewards(from);
    }
  }

  function clearStakingRewards(address _account) private {
    uint256 epoch = _stakeEpoch[_account];
    
    uint256 epochContribution = _epochContributingStakes[epoch][_account];

    reduceEpochContribution(_account, epoch, epochContribution);

    setUnstaked(_account);
  }

  function decayRate(uint256 stakeEpoch, uint256 currentEpoch) public pure returns (uint256) {
    if (stakeEpoch == 0) {
      return 0;
    } else {
      uint256 remainder = currentEpoch - stakeEpoch;
      if (remainder <= 1) {
        return 0;
      } else if (remainder < 12) {
        return (remainder - 1) * 10;
      } else {
        return 100;
      }
    }
  }

  function stakingReward(
    address account, 
    uint256 currentEpoch, 
    uint256 deposits, 
    uint256 slashFactor, 
    uint256 rewardRate
  ) public view returns (uint256) {
    uint256 stakeEpoch = getEpochStakedIn(account);

    uint256 bonus = 1;

    if (nftRouter().getCurrentAbilityKind(account) == 2) {
      bonus = nftRouter().getCurrentAbilityAmount(account);
    }

    if (stakeEpoch > 0) {

      uint256 epochIndex = stakeEpoch;
      if (epochIndex == currentEpoch) {
        return 0;
      } else {
        uint256 totalStaked = getEpochStakes(epochIndex);
        uint256 accountStake = getEpochContribution(account, epochIndex);

        if (totalStaked == 0 || (accountStake > totalStaked)) {
          return 0;
        } else {
          uint256 remainder = deposits - (deposits / slashFactor);

          uint256 reward = (remainder * accountStake * rewardRate) / (100 * totalStaked);

          reward = (reward - ((reward * decayRate(epochIndex, currentEpoch)) / 100));

          return bonus * reward;
        }
      }
    } else {
      return 0;
    }
  }

  function burn(address account, uint256 amount) public {
    require((msg.sender == _owner) || _managers[msg.sender]);
    _burn(account, amount);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./HotPotato.sol";
import "./IAwards.sol";

contract NFTRouter {

  // TODO: Add method for list of owned contracts

  address private _hptAddress;
  address private _steakAddress;
  address private _currentAwardAddress;
  address private _owner;

  mapping (address => bool) private _ownedContracts;
  mapping (address => NFTReference) private _activatedNFTs;

  mapping (address => bool) private _managers;

  struct NFTReference {
    address contractAddress;
    uint256 id;
  }

  event Award(
    address contractAddress,
    address recipient,
    uint256 id
  );

  constructor(address treasurer) {
    _owner = msg.sender;
    _managers[treasurer] = true;
  }

  function addManager(address _account) public {
    require(msg.sender == _owner);
    _managers[_account] = true;
  }

  function removeManager(address _account) public {
    require(msg.sender == _owner);
    _managers[_account] = false;
  }

  function setHPT(address hptAddress_) public {
    require(msg.sender == _owner);
    _hptAddress = hptAddress_;
  }

  function setSteak(address steakAddress_) public {
    require(msg.sender == _owner);
    _steakAddress = steakAddress_;
  }

  function setCurrentContract(address contractAddress) public {
    require(msg.sender == _owner);
    _currentAwardAddress = contractAddress;
  }

  function award(address contractAddress, address recipient, uint256 id) public {
    require(msg.sender == _owner || msg.sender == _hptAddress || _managers[msg.sender]);
    IAwards awards = IAwards(contractAddress);
    uint256 _id = awards.generate(recipient, id);

    if (_id != 0) {
      emit Award(contractAddress, recipient, id);
    }
  }

  function awardFromAction(address recipient, uint256 amount, uint256 slashFactor, uint256 randomness) public {
    require(msg.sender == _hptAddress);
    IAwards awards = IAwards(_currentAwardAddress);

    uint256 id = awards.generateFromAction(recipient, amount, slashFactor, randomness);

    if (id != 0) {
      emit Award(_currentAwardAddress, recipient, id);
    }
  }

  function getCurrentAbilityKind(address account) public view returns (uint256) {
    if (_activatedNFTs[account].id != 0) {
      return getAbilityKind(_activatedNFTs[account].contractAddress, _activatedNFTs[account].id);
    } else {
      return 0;
    }
  }

  function getCurrentAbilityAmount(address account) public view returns (uint256) {
    if (_activatedNFTs[account].id != 0) {
      return getAbilityAmount(_activatedNFTs[account].contractAddress, _activatedNFTs[account].id);
    } else {
      return 0;
    }
  }

  function getAbilityKind(address contractAddress, uint256 id) public view returns (uint256) {
    IAwards awards = IAwards(contractAddress);
    return awards.getAbilityKind(id);
  }

  function getAbilityAmount(address contractAddress, uint256 id) public view returns (uint256) {
    IAwards awards = IAwards(contractAddress);
    return awards.getAbilityAmount(id);
  }

  function addContract(address contractAddress, bool setCurrent) public {
    require(msg.sender == _owner);
    _ownedContracts[contractAddress] = true;
    if (setCurrent == true) {
      _currentAwardAddress = contractAddress;
    }
  }

  function isOwnedContract(address nftAddress) public view returns (bool) {
    return _ownedContracts[nftAddress];
  }

  function activateNFT(address nftAddress, uint256 id) public {
    ERC1155 nft = ERC1155(nftAddress);
    require(nft.balanceOf(msg.sender, id) > 0);

    require(isOwnedContract(nftAddress));

    _activatedNFTs[msg.sender] = NFTReference(nftAddress, id);

    HotPotato hpt = HotPotato(_hptAddress);

    hpt.setActiveNFTIndex(msg.sender, getCurrentAbilityKind(msg.sender));
    hpt.setActiveNFTAmount(msg.sender, getCurrentAbilityAmount(msg.sender));
  }

  function deactivateNFT(address nftAddress, uint256 id) public {
    ERC1155 nft = ERC1155(nftAddress);
    require(nft.balanceOf(msg.sender, id) > 0);

    require(isOwnedContract(nftAddress));

    _activatedNFTs[msg.sender] = NFTReference(0x0000000000000000000000000000000000000000, 0);

    HotPotato hpt = HotPotato(_hptAddress);

    hpt.setActiveNFTIndex(msg.sender, 0);
    hpt.setActiveNFTAmount(msg.sender, 0);
  }

  function activatedNFT(address account) public view returns (uint256) {
    return _activatedNFTs[account].id;
  }

  // need manager to be able to burn card in instances like shadow
  function burnCurrentCard(address account, uint256 typeId) public {
    require(msg.sender == _hptAddress || msg.sender == _steakAddress || _managers[msg.sender]);
    NFTReference storage nftRef = _activatedNFTs[account];
    
    if (nftRef.id != 0) {
      if (getAbilityKind(nftRef.contractAddress, nftRef.id) == typeId) {
        IAwards awards = IAwards(nftRef.contractAddress);
        awards.use(account, nftRef.id);
        _activatedNFTs[account] = NFTReference(0x0000000000000000000000000000000000000000, 0);

        HotPotato hpt = HotPotato(_hptAddress);

        hpt.setActiveNFTIndex(account, 0);
        hpt.setActiveNFTAmount(account, 0);
      }
    }
  }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IEpochFinisher {

  function fetchNextEpoch(address _caller) external returns (bytes32 requestId);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAwards {

  function generate(address recipient, uint256 id) external returns (uint256);

  function generateFromAction(address recipient, uint256 amount, uint256 slashFactor, uint256 randomness) external returns (uint256);

  function getAbilityKind(uint256 id) external view returns (uint256);

  function getAbilityAmount(uint256 id) external view returns (uint256);

  function use(address account, uint256 id) external;

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./Steak.sol";
import "./IEpochFinisher.sol";
import "./NFTRouter.sol";

contract HotPotato is Context, IERC20, IERC20Metadata {

  mapping (address => uint256) private _whitelist; 
  address private _owner;
  address private _stakingTokenAddress;

  address private _epochFinisherAddress;

  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;

  uint256 private _currentEpoch;
  uint256 private _finalMintingEpoch;
  mapping (uint256 => Epoch) private _epochs;
  mapping (address => uint256) private _accountEpochs;
  mapping (uint256 => mapping(address => uint256)) private _epochBalances;
  mapping (uint256 => mapping(address => uint256)) private _epochEntries;
  mapping (uint256 => mapping(address => bool)) private _epochEntered;

  mapping (address => uint256) private _slashRewards;

  mapping (uint256 => uint256) private _epochDeposits;

  uint256 private _baseSupply;
  uint256 private _currentMaticFee;

  uint256 private _stakerRewardRate;

  address payable _paymentReceiver;

  bool private _requirePaymentMode;
  bool private _locked;

  address private _nftRouterAddress;

  mapping (uint256 => uint256) private _epochRandomness;

  mapping (address => uint256) private _activeNFTIndexes;
  mapping (address => uint256) private _activeNFTAmounts;

  uint256 private _lastGasCost;
  uint256 private _gasCostMultiple;
  uint256 private _gasSoftCap;


  struct Epoch {
    uint256 id;
    uint256 index;
    uint256 startTime;
    uint256 duration;
    uint256 returnNumerator;
    // uint256 slashDenominator;
  }

  event Migrate(
    address account,
    uint256 timestamp
  );

  event Lock(
    uint256 timestamp
  );

  event Unlock(
    uint256 timestamp
  );

  event Claim(
    address account,
    uint256 amount,
    uint256 epoch,
    uint256 timestamp
  );

  mapping (uint256 => uint256) private _epochSlashes;

  constructor(uint256 finalMintingEpoch_) {
    _finalMintingEpoch = finalMintingEpoch_;
    _name = "Hot Potato";
    _symbol = "HPT";
    _owner = msg.sender;

    _currentEpoch = 1;
    _epochs[_currentEpoch] = Epoch(1, 1, block.timestamp, 3600, 50);
    _currentMaticFee = 1 * (10 ** 18); // start at 1 matic
    _requirePaymentMode = false;
    _locked = false;
    _stakerRewardRate = 50; // start by giving stakers 50% of slash
    _baseSupply = 107000 * (10 ** 18);
  }

  function setPaymentReceiver(address payable paymentReceiver_) public {
    require(msg.sender == _owner);
    _paymentReceiver = paymentReceiver_;
  }

  function getCurrentEpoch() public view returns (uint256) {
    return _currentEpoch;
  }

  function setGasCostVariables(uint256 gasCostMultiple_, uint256 gasSoftCap_) public {
    require(msg.sender == _owner);
    _gasCostMultiple = gasCostMultiple_;
    _gasSoftCap = gasSoftCap_;
  }

  function resetLastGasCost() public {
    require(msg.sender == _owner || msg.sender == _epochFinisherAddress);
    _lastGasCost = 0;
  }

  function maxGasPrice() public view returns (uint256) {
    // e.g. 10 gwei * 15 / 10 => 15 gwei (1.5X)
    uint256 result = (_lastGasCost * _gasCostMultiple) / 10;
    if (result < _gasSoftCap) {
      return _gasSoftCap;
    } else {
      return result;  
    }
  }

  function setActiveNFTIndex(address account, uint256 index) public {
    require(msg.sender == _nftRouterAddress);
    _activeNFTIndexes[account] = index;
  }

  function setActiveNFTAmount(address account, uint256 index) public {
    require(msg.sender == _nftRouterAddress);
    _activeNFTAmounts[account] = index;
  }

  function unlockContract() public {
    require(msg.sender == _owner || msg.sender == _epochFinisherAddress, "HPT: Can only be modified by allowed addresses.");
    _locked = false;
    emit Unlock(block.timestamp);
  }

  function setStakerRewardRate(uint256 _newRate) public {
    require(msg.sender == _owner);
    _stakerRewardRate = _newRate;
  }

  function setNFTRouterAddress(address nftRouterAddress_) public {
    require(msg.sender == _owner);
    _nftRouterAddress = nftRouterAddress_;
  }

  function lockContract() private {
    _locked = true;
    emit Lock(block.timestamp);
  }

  function ownerLock() public {
    require(msg.sender == _owner);
    _locked = true;
    emit Lock(block.timestamp);
  }

  function contractLocked() public view returns (bool) {
    return _locked;
  }

  function getCurrentMaticFee() public view returns (uint256) {
    Epoch memory epoch = _epochs[_currentEpoch];

    uint256 secondsExpired = block.timestamp - epoch.startTime;

    if (secondsExpired >= epoch.duration) {
      return 0;
    } else {
      return (_currentMaticFee * (epoch.duration - secondsExpired) /  epoch.duration);
    }
  }

  function discountedMaticFee(address account) public view returns (uint256) {
    uint256 discount = 0;

    if (_activeNFTIndexes[account] == 1) {
      discount = _activeNFTAmounts[account];
    }

    uint256 currentFee = getCurrentMaticFee();

    return (currentFee - ((currentFee * discount) / 100));
  }

  function setNextMaticFee(uint256 price) public {
    require(msg.sender == _epochFinisherAddress);
    _currentMaticFee = price;
  }

  function turnOnPayments() public {
    require(msg.sender == _owner);
    _requirePaymentMode = true;
  }

  function getCurrentEpochDuration() public view returns (uint256) {
    Epoch memory epoch = _epochs[_currentEpoch];
    return epoch.duration;
  }

  function baseSupply() public view returns (uint256) {
    return _baseSupply;
  }

  function setBaseSupply(uint256 supply) public {
    require(msg.sender == _owner);
    _baseSupply = supply;
  }

  function getCurrentEpochReturnRate() public view returns (uint256) {
    Epoch memory epoch = _epochs[_currentEpoch];
    return epoch.returnNumerator;
  }

  function getUserEpochSlashAmount(address account) public view returns (uint256) {
    uint256 epoch = getEpochForAccount(account);
    if (epoch == _currentEpoch) {
      return 0;
    } else {
      return _epochSlashes[epoch];
    }
  }

  function getCurrentEpochTimeRemaining() public view returns (uint256) {
    Epoch memory epoch = _epochs[_currentEpoch];
    uint256 timeElapsed = block.timestamp - epoch.startTime;
    if (timeElapsed < epoch.duration) {
      return epoch.duration - timeElapsed;
    } else {
      return 0;
    }
  }

  function getEpochStakedIn(address account) public view returns (uint256) {
    Steak steak = Steak(_stakingTokenAddress);
    return steak.getEpochStakedIn(account);
  }

  function canClaimTokens(address _account) public view returns (bool) {
    return (_currentEpoch <= _finalMintingEpoch) && whitelisted(_account);
  }

  function whitelisted(address _account) public view returns (bool) {
    return _whitelist[_account] > 0;
  }

  function whitelist(address _account, uint256 _amount) public {
    require(msg.sender == _owner, "Tater: Whitelist only callable by contract owner.");
    _whitelist[_account] = _amount;
  }

  function stakeAll() public {
    require(!_locked, "HPT: Contract is locked");
    // BUG: We should probably be subtracting total supply here -- before migrating!
    // ---> by migrating first, we bypass the reduce total supply check in stake()
    migrateToCurrentEpoch(msg.sender);
    uint256 amount = balanceOf(msg.sender);
    require(amount > 0, "HPT: Must have balance greater than 0");
    stake(amount);
  }

  function unstakeAll() public {
    require(!_locked, "HPT: Contract is locked");
    Steak steak = Steak(_stakingTokenAddress);
    uint256 amount = steak.balanceOf(msg.sender);
    require(amount > 0, "HPT: Must have balance greater than 0");
    unstake(amount);
    steak.setStaked(msg.sender, _currentEpoch);
  }

  function stake(uint256 amount) public {
    require(!_locked);

    if (_lastGasCost > 0) {
      require(tx.gasprice <= maxGasPrice(), "HPT: Gas price set too high!");
    }

    _lastGasCost = tx.gasprice;

    Steak steak = Steak(_stakingTokenAddress);

    if (!_epochEntered[_currentEpoch][msg.sender]) {
      _totalSupply -= balanceOf(msg.sender);
      _epochDeposits[_currentEpoch] += balanceOf(msg.sender);
      migrateToCurrentEpoch(msg.sender);
    }

    if (!steak.isStaked(msg.sender) || steak.balanceOf(msg.sender) == 0) {
      steak.setStaked(msg.sender, _currentEpoch);
    }

    require(steak.getEpochStakedIn(msg.sender) == _currentEpoch, "HPT: Cannot have stake in multiple epochs. Unstake previously staked tokens to proceed.");
    require(balanceOf(msg.sender) >= amount, "HPT: Cannot stake more tokens than you have.");


    reduceEpochBalance(_currentEpoch, msg.sender, rawBalanceToSubtract(amount, msg.sender));
    reduceEpochDeposits(_currentEpoch, rebasedSendAmount(msg.sender, amount));
    
    steak.enter(msg.sender, amount, _currentEpoch);
  }

  function unstake(uint256 amount) public {
    require(!_locked);

    Steak steak = Steak(_stakingTokenAddress);

    uint256 stakeEpoch = steak.getEpochStakedIn(msg.sender);
    uint256 accountEpoch = _accountEpochs[msg.sender];

    uint256 reward = stakingReward(msg.sender);

    if (_currentEpoch != stakeEpoch && _currentEpoch != accountEpoch) {
      reduceTotalSupply(balanceOf(msg.sender));
    }

    uint256 steakBalance = steak.balanceOf(msg.sender);

    require(steakBalance >= amount, "HTP: Cannot unstake more than you have staked.");
    migrateToCurrentEpoch(msg.sender);

    if (_currentEpoch != stakeEpoch && _currentEpoch != accountEpoch) {
      _epochDeposits[_currentEpoch] += balanceOf(msg.sender);
    }
    
    if (steakBalance > 0) {
      if (stakeEpoch == _currentEpoch) {
        customMint(msg.sender, amount, false);
      } else {
        uint256 amountWithReward = amount + reward;
        customMint(msg.sender, amountWithReward, false);
      }
            
      steak.exit(msg.sender, amount, stakeEpoch);
    }
  }

  function stakingReward(address account) public view returns (uint256) {
    Steak steak = Steak(_stakingTokenAddress);
    uint256 stakeEpoch = steak.getEpochStakedIn(account);
    return steak.stakingReward(
      account, 
      _currentEpoch, 
      _epochDeposits[stakeEpoch],
      _epochSlashes[stakeEpoch], 
      _stakerRewardRate
    );
  }

  function totalCurrentDeposits() public view returns (uint256) {
    return _epochDeposits[_currentEpoch];
  }

  function setStakingTokenAddress(address tokenAddress) public {
    require(msg.sender == _owner, "HPT: Only contract owner can set staking address.");
    _stakingTokenAddress = tokenAddress;
  }

  function setEpochFinisherAddress(address finisherAddress) public {
    require(msg.sender == _owner, "HPT: Only contract owner can set epoch finisher address.");
    _epochFinisherAddress = finisherAddress;
  }

  function claim() public {
    require(!_locked);
    require(whitelisted(msg.sender), "Tater: Only whitelisted addresses can claim tokens.");
    require(_currentEpoch <= _finalMintingEpoch, "Tater: Can no longer claim tokens.");
    
    uint256 amount = _whitelist[msg.sender];
    
    customMint(msg.sender, amount, true);


    _whitelist[msg.sender] = 0;

    emit Claim(msg.sender, amount, _currentEpoch, block.timestamp);
  }

  function timeInCurrentEpoch(address _account) public view returns (uint256) {
    uint256 entryTime = _epochEntries[_currentEpoch][_account];
    return block.timestamp - entryTime;
  }

  function currentEpochDeposit(address _account) public view returns (uint256) {
    return _epochBalances[_currentEpoch][_account];
  }

  function finishEpoch() public payable {
    require(!_locked);
    if (_requirePaymentMode) {
      require(msg.value >= discountedMaticFee(msg.sender));
      _paymentReceiver.transfer(msg.value);
    }
    lockContract();
    IEpochFinisher epochFinisher = IEpochFinisher(_epochFinisherAddress);
    epochFinisher.fetchNextEpoch(msg.sender);

    nftRouter().burnCurrentCard(msg.sender, 1);
  }

  function setNextEpoch(uint256 slashDenominator, uint256 durationSeconds, uint256 returnNumerator, uint256 randomness) public {
    require(msg.sender == _epochFinisherAddress);
    _epochSlashes[_currentEpoch] = slashDenominator;
    _totalSupply += _epochDeposits[_currentEpoch] / _epochSlashes[_currentEpoch];
    _currentEpoch += 1;
    _epochs[_currentEpoch] = Epoch(_currentEpoch, _currentEpoch, block.timestamp, durationSeconds, returnNumerator);
    _epochRandomness[_currentEpoch] = randomness;
  }

  function rewardCaller(address _caller, uint256 _amount) public {
    require(msg.sender == _epochFinisherAddress);
    _slashRewards[_caller] = _amount;
  }

  function availableSlashRewards(address account) public view returns (uint256) {
    return _slashRewards[account];
  }

  function claimSlashRewards() public {
    require(_slashRewards[msg.sender] > 0);
    Steak steak = Steak(_stakingTokenAddress);
    steak.mint(msg.sender, _slashRewards[msg.sender]);

    _slashRewards[msg.sender] = 0;
 
    nftRouter().burnCurrentCard(msg.sender, 3);
  }

  function getEpochForAccount(address _account) public view returns (uint256) {
    return _accountEpochs[_account];
  }

  function nftRouter() private view returns (NFTRouter) {
    return NFTRouter(_nftRouterAddress);
  }

  function customMint(address account, uint256 amount, bool registerMintContribution) internal {
    require(account != address(0), "ERC20: mint to the zero address");

    if (!_epochEntered[_currentEpoch][account]) {
      _epochEntries[_currentEpoch][account] = block.timestamp;
      _epochEntered[_currentEpoch][account] = true;
    }

    uint256 rebasedAmount = rebasedSendAmount(account, amount);

    _epochBalances[_currentEpoch][account] += rebasedAmount;
    _accountEpochs[account] = _currentEpoch;

    _epochDeposits[_currentEpoch] += rebasedAmount;

    if (registerMintContribution) {
      _baseSupply += rebasedAmount;
    }

    emit Transfer(address(0), account, rebasedAmount);
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
    uint256 accountEpoch = _accountEpochs[account];
    if (accountEpoch > 0) {
      Epoch memory epoch = _epochs[accountEpoch];
      uint256 balance = _epochBalances[accountEpoch][account];
      uint256 entryTime = _epochEntries[accountEpoch][account];
      
      if (isCurrentEpoch(epoch.id)) {
        uint256 accountSecondsExpired = block.timestamp - entryTime;
        uint256 epochSecondsExpired = block.timestamp - epoch.startTime;

        if (epochSecondsExpired > epoch.duration) {
          return balance;
        } else {  
          uint256 returnAmount = ((balance * epoch.returnNumerator) / 100);
          return (balance + ((returnAmount * accountSecondsExpired) / epoch.duration));
        }
      } else {
        return balance / _epochSlashes[epoch.id];
      }
    } else {
      return 0;
    }
  }

  function baseBalanceOf(address account) public view returns (uint256) {
    uint256 accountEpoch = _accountEpochs[account];
    return _epochBalances[accountEpoch][account];
  }

  function rawBalanceToSubtract(uint256 amount, address account) private view returns (uint256) {
    uint256 accountEpoch = _accountEpochs[account];
    uint256 balance = balanceOf(account);
    uint256 deposit = _epochBalances[accountEpoch][account];
    
    return (amount * deposit) / balance;
  }

  function rebasedSendAmount(address recipient, uint256 amount) public view returns (uint256) {
    Epoch memory epoch = _epochs[_currentEpoch];

    uint256 entryTime = _epochEntries[_currentEpoch][recipient];
    uint256 secondsExpired = block.timestamp - entryTime;

    return (amount * 100 * epoch.duration) / ((100 * epoch.duration) + (epoch.returnNumerator * secondsExpired));
  }

  function migrateToCurrentEpoch(address _account) private {
    if (!_epochEntered[_currentEpoch][_account]) {

      _epochEntered[_currentEpoch][_account] = true;
      uint256 accountEpoch = _accountEpochs[_account];

      uint256 originalBalance = _epochBalances[accountEpoch][_account];
      uint256 slashFactor = _epochSlashes[accountEpoch];
      uint256 randomness = _epochRandomness[accountEpoch];

      // Check for active card
      uint256 bypass = slashFactor;

      if (_activeNFTIndexes[_account] == 4) {
        bypass = _activeNFTAmounts[_account];
        _epochBalances[accountEpoch][_account] = (_epochBalances[accountEpoch][_account] * slashFactor) / bypass;
      }

      nftRouter().awardFromAction(_account, originalBalance, slashFactor, randomness);

      _epochBalances[_currentEpoch][_account] = balanceOf(_account);
      _epochBalances[accountEpoch][_account] = 0;

      _accountEpochs[_account] = _currentEpoch;
      _epochEntries[_currentEpoch][_account] = block.timestamp;

      nftRouter().burnCurrentCard(_account, 4);
    }
  }

  function preloadedRewardCut(address account) public view returns (uint256) {
    if (_activeNFTIndexes[account] == 3) {
      return _activeNFTAmounts[account];
    } else {
      return 0;
    }
  }

  function migrateSelfToCurrent() public {
    require(!_locked);
    uint256 accountEpoch = _accountEpochs[msg.sender];
    require(_currentEpoch != accountEpoch);

    reduceTotalSupply(balanceOf(msg.sender)); 
    migrateToCurrentEpoch(msg.sender);
    increaseEpochDeposits(_currentEpoch, balanceOf(msg.sender));

    emit Migrate(msg.sender, block.timestamp);
  }

  function reduceEpochBalance(uint256 _epoch, address _account, uint256 _amount) private {
    uint256 balance = _epochBalances[_epoch][_account];
    if (_amount >= balance) {
      _epochBalances[_epoch][_account] = 0;
    } else {
      _epochBalances[_epoch][_account] -= _amount;
    }
  }

  function increaseEpochBalance(uint256 _epoch, address _account, uint256 _amount) private {
    _epochBalances[_epoch][_account] += _amount;
  }

  function reduceTotalSupply(uint256 _amount) private {
    if (_totalSupply > _amount) {
      _totalSupply -= _amount;
    } else {
      _totalSupply = 0;
    }
  }

  function increaseEpochDeposits(uint256 _epoch, uint256 _amount) private {
    _epochDeposits[_epoch] += _amount;
  }

  function reduceEpochDeposits(uint256 _epoch, uint256 _amount) private {
    uint256 balance = _epochDeposits[_epoch];
    if (_amount >= balance) {
      _epochDeposits[_epoch] = 0;
    } else {
      _epochDeposits[_epoch] -= _amount;
    }
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(!_locked);
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    require(balanceOf(sender) >= amount, "ERC20: transfer amount exceeds balance");

    if (!isCurrentEpoch(_accountEpochs[sender])) {
      reduceTotalSupply(balanceOf(sender));      
      migrateToCurrentEpoch(sender);
      reduceEpochBalance(_currentEpoch, sender, amount);
      increaseEpochDeposits(_currentEpoch, balanceOf(sender));
      increaseEpochDeposits(_currentEpoch, amount);
    } else {
      _epochEntries[_currentEpoch][sender] = block.timestamp; // ==> this removes epoch rewards if you send during epoch
      uint256 amountToSubtract = rawBalanceToSubtract(amount, sender);
      reduceEpochBalance(_currentEpoch, sender, amountToSubtract);
    }
    
    // BUG: We should probably be reducing total supply here!
    migrateToCurrentEpoch(recipient);
    increaseEpochBalance(_currentEpoch, recipient, rebasedSendAmount(recipient, amount));

    emit Transfer(sender, recipient, rebasedSendAmount(recipient, amount));
  }

  // todo: rename to epochDeposits
  function totalDeposits(uint256 _epochIndex) public view returns (uint256) {
    return _epochDeposits[_epochIndex];
  }

  function isCurrentEpoch(uint256 _epochID) internal view returns (bool) {
    return _epochID == _currentEpoch;
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function decimals() public view virtual override returns (uint8) {
    return 18;
  }

  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

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

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
      _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

    return true;
  }

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

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}