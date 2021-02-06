// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

library Constants {
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _launchSupply = 1 * 10**6 * 10**9;
    uint256 private constant _largeTotal = (MAX - (MAX % _launchSupply));

    uint256 private constant _deployerCost = 5 ether;

    uint256 private constant _baseExpansionFactor = 100;
    uint256 private constant _baseContractionFactor = 100;
    uint256 private constant _incentivePot = 50;
    uint256 private constant _baseUtilityFee = 50;
    uint256 private constant _baseContractionCap = 1000;

    uint256 private constant _stabilizerFee = 250;
    uint256 private constant _stabilizationLowerBound = 50;
    uint256 private constant _stabilizationLowerReset = 75;
    uint256 private constant _stabilizationUpperBound = 150;
    uint256 private constant _stabilizationUpperReset = 125;
    uint256 private constant _stabilizePercent = 10;

    uint256 private constant _treasuryFee = 250;

    uint256 private constant _presaleIndividualCap = 1 ether;
    uint256 private constant _presaleCap = 1 * 10**5 * 10**9;
    uint256 private constant _maxPresaleGas = 200000000000;

    uint256 private constant _epochLength = 4 hours;

    uint256 private constant _liquidityReward = 25 * 10**9;
    uint256 private constant _minForLiquidity = 500 * 10**9;
    uint256 private constant _minForCallerLiquidity = 500 * 10**9;

    address private constant _routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant _factoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address payable private constant _deployerAddress = 0xCEe3101c0A8167f083F34B95A2f243c9b0BEF6a6;
    address private constant _treasuryAddress = 0x3363Defd7447f14b7f696c0843AA96516Bc04808;

    string private constant _name = "XSTABLE.PROTOCOL";
    string private constant _symbol = "XST";
    uint8 private constant _decimals = 9;

    /****** Getters *******/
    function getLaunchSupply() internal pure returns (uint256) {
        return _launchSupply;
    }
    function getLargeTotal() internal pure returns (uint256) {
        return _largeTotal;
    }
    function getDeployerCost() internal pure returns (uint256) {
        return _deployerCost;
    }
    function getPresaleCap() internal pure returns (uint256) {
        return _presaleCap;
    }
    function getPresaleIndividualCap() internal pure returns (uint256) {
        return _presaleIndividualCap;
    }
    function getMaxPresaleGas() internal pure returns (uint256) {
        return _maxPresaleGas;
    }
    function getBaseExpansionFactor() internal pure returns (uint256) {
        return _baseExpansionFactor;
    }
    function getBaseContractionFactor() internal pure returns (uint256) {
        return _baseContractionFactor;
    }
    function getIncentivePot() internal pure returns (uint256) {
        return _incentivePot;
    }
    function getBaseContractionCap() internal pure returns (uint256) {
        return _baseContractionCap;
    }
    function getBaseUtilityFee() internal pure returns (uint256) {
        return _baseUtilityFee;
    }
    function getStabilizerFee() internal pure returns (uint256) {
        return _stabilizerFee;
    }
    function getStabilizationLowerBound() internal pure returns (uint256) {
        return _stabilizationLowerBound;
    }
    function getStabilizationLowerReset() internal pure returns (uint256) {
        return _stabilizationLowerReset;
    }
    function getStabilizationUpperBound() internal pure returns (uint256) {
        return _stabilizationUpperBound;
    }
    function getStabilizationUpperReset() internal pure returns (uint256) {
        return _stabilizationUpperReset;
    }
    function getStabilizePercent() internal pure returns (uint256) {
        return _stabilizePercent;
    }
    function getTreasuryFee() internal pure returns (uint256) {
        return _treasuryFee;
    }
    function getEpochLength() internal pure returns (uint256) {
        return _epochLength;
    }
    function getLiquidityReward() internal pure returns (uint256) {
        return _liquidityReward;
    }
    function getMinForLiquidity() internal pure returns (uint256) {
        return _minForLiquidity;
    }
    function getMinForCallerLiquidity() internal pure returns (uint256) {
        return _minForCallerLiquidity;
    }
    function getRouterAdd() internal pure returns (address) {
        return _routerAddress;
    }
    function getFactoryAdd() internal pure returns (address) {
        return _factoryAddress;
    }
    function getDeployerAdd() internal pure returns (address payable) {
        return _deployerAddress;
    }
    function getTreasuryAdd() internal pure returns (address) {
        return _treasuryAddress;
    }
    function getName() internal pure returns (string memory)  {
        return _name;
    }
    function getSymbol() internal pure returns (string memory) {
        return _symbol;
    }
    function getDecimals() internal pure returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./external/IUniswapV2Factory.sol";
import "./external/IUniswapV2Router02.sol";
import "./Constants2.sol";
import "./State.sol";

contract Getters2 is State {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function getLargeBalances(address account) public view returns (uint256) {
        return _largeBalances[account];
    }
    function getAllowances(address account, address spender) public view returns (uint256) {
        return _allowances[account][spender];
    } 
    function getSupportedPools(uint256 index) public view returns (address) {
        return _supportedPools[index];
    }
    function getPoolCounters(address pool) public view returns (address, uint256, uint256, uint256, uint256, uint256) {
        PoolCounter memory pc = _poolCounters[pool];
        return (pc.pairToken, pc.tokenBalance, pc.pairTokenBalance, pc.lpBalance, pc.startTokenBalance, pc.startPairTokenBalance);
    }
    function isSupportedPool(address pool) public view returns (bool) {
        return _isSupportedPool[pool];
    }
    function mainPool() public view returns (address) {
        return _mainPool;
    }
    function getCurrentEpoch() public view returns (uint256) {
        return _currentEpoch;
    }
    function getLockBoxes(uint256 box) public view returns (address, uint256, uint256, bool) {
        LockBox memory lb = _lockBoxes[box];
        return (lb.beneficiary, lb.lockedBalance, lb.unlockTime, lb.locked);
    }
    function getLockedBalance(address account) public view returns (uint256) {
        return _lockedBalance[account];
    }
    function hasLockedBalance(address account) public view returns (bool) {
        return _hasLockedBalance[account];
    }
    function getTotalLockedBalance() public view returns (uint256) {
        return _totalLockedBalance;
    }
    function getLargeTotal() public view returns (uint256) {
        return _largeTotal;
    }
    function getTotalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function getLiquidityReserve() public view returns (address) {
        return _liquidityReserve;
    }
    function getStabilizer() public view returns (address) {
        return _stabilizer;
    }
    function isPresaleDone() public view returns (bool) {
        return _presaleDone;
    }
    function getPresaleAddress() public view returns (address) {
        return _presaleCon;
    }
    function isPaused() public view returns (bool) {
        return _paused;
    }
    function isTaxLess() public view returns (bool) {
        return _taxLess;
    }
    function isTaxlessSetter(address account) public view returns (bool) {
        return _isTaxlessSetter[account];
    }
    function getUniswapRouter() public view returns (IUniswapV2Router02) {
        return IUniswapV2Router02(Constants.getRouterAdd());
    }
    function getUniswapFactory() public view returns (IUniswapV2Factory) {
        return IUniswapV2Factory(Constants.getFactoryAdd());
    }
    function getFactor() public view returns(uint256) {
        if (_presaleDone) {
            return _largeTotal.div(_totalSupply);
        } else {
            return _largeTotal.div(Constants.getLaunchSupply());
        }
    }
    function getUpdatedPoolCounters(address pool, address pairToken) public view returns (uint256, uint256, uint256) {
        uint256 lpBalance = IERC20(pool).totalSupply();
        uint256 tokenBalance = IERC20(address(this)).balanceOf(pool);
        uint256 pairTokenBalance = IERC20(address(pairToken)).balanceOf(pool);
        return (tokenBalance, pairTokenBalance, lpBalance);
    }
    function getMintRate(address pool) external view returns (uint256) {
        uint256 expansionR = (_poolCounters[pool].pairTokenBalance).mul(_poolCounters[pool].startTokenBalance).mul(100).div(_poolCounters[pool].startPairTokenBalance).div(_poolCounters[pool].tokenBalance);
        if (expansionR > (Constants.getBaseExpansionFactor()).add(10000).div(100)) {
            uint256 mintFactor = expansionR.mul(expansionR);
            return mintFactor.sub(10000);
        } else {
            return Constants.getBaseExpansionFactor();
        }
    }
    function getBurnRate(address pool) public view returns (uint256) {
        uint256 contractionR = (_poolCounters[pool].tokenBalance).mul(_poolCounters[pool].startPairTokenBalance).mul(100).div(_poolCounters[pool].pairTokenBalance).div(_poolCounters[pool].startTokenBalance);
        uint256 burnRate;
        if (contractionR > (Constants.getBaseContractionFactor().add(10000)).div(100)) {
            uint256 burnFactor = contractionR.mul(contractionR);
            burnRate = burnFactor.sub(10000);
            if (burnRate > Constants.getBaseContractionCap()) {
                return Constants.getBaseContractionCap();
            }
            return burnRate;

        } else {
            return Constants.getBaseContractionFactor();
        }
    }

    function getUtilityFee(uint256 amount) internal view returns(uint256, uint256) {
        uint256 currentFactor = getFactor();
        uint256 utilityFee = amount.mul(Constants.getBaseUtilityFee()).div(10000);
        return (utilityFee, utilityFee.mul(currentFactor));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Constants2.sol";
import "./State.sol";
import "./Getters2.sol";

contract Setters2 is State, Getters2 {
    function setAllowances(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
    }
    function addToAccount(address account, uint256 amount) internal {
        uint256 currentFactor = getFactor();
        uint256 largeAmount = amount.mul(currentFactor);
        _largeBalances[account] = _largeBalances[account].add(largeAmount);
        _totalSupply = _totalSupply.add(amount);
    }
    function addToAll(uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
    }
    function initializeEpoch() internal {
        _currentEpoch = now;
    }
    function updateEpoch() internal {
        initializeEpoch();
        for (uint256 i=0; i<_supportedPools.length; i++) {
            _poolCounters[_supportedPools[i]].startTokenBalance = _poolCounters[_supportedPools[i]].tokenBalance;
            _poolCounters[_supportedPools[i]].startPairTokenBalance = _poolCounters[_supportedPools[i]].pairTokenBalance;
        }
    }
    function syncPair(address pool) internal returns(bool) {
        (uint256 tokenBalance, uint256 pairTokenBalance, uint256 lpBalance) = getUpdatedPoolCounters(pool, _poolCounters[pool].pairToken);
        bool lpBurn = lpBalance < _poolCounters[pool].lpBalance;
        _poolCounters[pool].lpBalance = lpBalance;
        _poolCounters[pool].tokenBalance = tokenBalance;
        _poolCounters[pool].pairTokenBalance = pairTokenBalance;
        return (lpBurn);
    }
    function silentSyncPair(address pool) public {
        (uint256 tokenBalance, uint256 pairTokenBalance, uint256 lpBalance) = getUpdatedPoolCounters(pool, _poolCounters[pool].pairToken);
        _poolCounters[pool].lpBalance = lpBalance;
        _poolCounters[pool].tokenBalance = tokenBalance;
        _poolCounters[pool].pairTokenBalance = pairTokenBalance;
    }
    function addSupportedPool(address pool, address pairToken) internal {
        require(!isSupportedPool(pool),"This pool is already supported");
        _isSupportedPool[pool] = true;
        _supportedPools.push(pool);
        (uint256 tokenBalance, uint256 pairTokenBalance, uint256 lpBalance) = getUpdatedPoolCounters(pool, pairToken);
        _poolCounters[pool] = PoolCounter(pairToken, tokenBalance, pairTokenBalance, lpBalance, tokenBalance, pairTokenBalance);
    }
    function removeSupportedPool(address pool) internal {
        require(isSupportedPool(pool), "This pool is currently not supported");
        for (uint256 i = 0; i < _supportedPools.length; i++) {
            if (_supportedPools[i] == pool) {
                _supportedPools[i] = _supportedPools[_supportedPools.length - 1];
                _isSupportedPool[pool] = false;
                delete _poolCounters[pool];
                _supportedPools.pop();
                break;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

contract State {

    mapping (address => uint256) _largeBalances;
    mapping (address => mapping (address => uint256)) _allowances;

    // Supported pools and data for measuring mint & burn factors
    struct PoolCounter {
        address pairToken;
        uint256 tokenBalance;
        uint256 pairTokenBalance;
        uint256 lpBalance;
        uint256 startTokenBalance;
        uint256 startPairTokenBalance;
    }
    address[] _supportedPools;
    mapping (address => PoolCounter) _poolCounters;
    mapping (address => bool) _isSupportedPool;
    address _mainPool;

    uint256 _currentEpoch;
    
    //Creating locked balances
    struct LockBox {
        address beneficiary;
        uint256 lockedBalance;
        uint256 unlockTime;
        bool locked;
    }
    LockBox[] _lockBoxes;
    mapping(address => uint256) _lockedBalance;
    mapping(address => bool) _hasLockedBalance;
    uint256 _totalLockedBalance;
 
    uint256 _largeTotal;
    uint256 _totalSupply;

    address _liquidityReserve;
    address _stabilizer;

    bool _presaleDone;
    address _presaleCon;
    
    bool _paused;
    
    bool _taxLess;
    mapping(address=>bool) _isTaxlessSetter;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./external/IUniswapV2Factory.sol";
import "./external/IUniswapV2Router02.sol";
import "./external/IWETH.sol";
import "./Constants2.sol";
import "./Setters2.sol";

contract XStable2 is Setters2, Initializable, ContextUpgradeable, IERC20Upgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    uint256 _currentPot;
    struct SellDetails {
            uint256 burnSize;
            uint256 largeBurnSize;
            uint256 potSize;
            uint256 largePotSize;
            uint256 utilityFee;
            uint256 largeUtilityFee;
            uint256 actualTransferAmount;
            uint256 largeTransferAmount;
        }

    modifier onlyTaxless {
        require(isTaxlessSetter(_msgSender()),"not taxless");
        _;
    }
    modifier onlyPresale {
        require(_msgSender()==getPresaleAddress(),"not presale");
        require(!isPresaleDone(), "Presale over");
        _;
    }
    modifier pausable {
        require(!isPaused(), "Paused");
        _;
    }
    modifier taxlessTx {
        _taxLess = true;
        _;
        _taxLess = false;
    }

    function name() public view returns (string memory) {
        return Constants.getName();
    }
    
    function symbol() public view returns (string memory) {
        return Constants.getSymbol();
    }
    
    function decimals() public view returns (uint8) {
        return Constants.getDecimals();
    }
    
    function totalSupply() public view override returns (uint256) {
        return getTotalSupply();
    }
    
    function circulatingSupply() public view returns (uint256) {
        uint256 currentFactor = getFactor();
        return getTotalSupply().sub(getTotalLockedBalance().div(currentFactor)).sub(balanceOf(address(this))).sub(balanceOf(getStabilizer()));
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        uint256 currentFactor = getFactor();
        if (hasLockedBalance(account)) return (getLargeBalances(account).add(getLockedBalance(account)).div(currentFactor));
        return getLargeBalances(account).div(currentFactor);
    }
    
    function unlockedBalanceOf(address account) public view returns (uint256) {
        uint256 currentFactor = getFactor();
        return getLargeBalances(account).div(currentFactor); 
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return getAllowances(owner,spender);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), getAllowances(sender,_msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, getAllowances(_msgSender(),spender).add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, getAllowances(_msgSender(),spender).sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function mint(address to, uint256 amount) public onlyPresale {
        addToAccount(to,amount);
        emit Transfer(address(0),to,amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        setAllowances(owner, spender, amount);
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private pausable {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= balanceOf(sender),"Amount exceeds balance");
        require(amount <= unlockedBalanceOf(sender),"Amount exceeds unlocked balance");
        require(isPresaleDone(),"Presale yet to close");
        if (now > getCurrentEpoch().add(Constants.getEpochLength())) updateEpoch();
        uint256 currentFactor = getFactor();
        uint256 largeAmount = amount.mul(currentFactor);
        uint256 txType;
        if (isTaxLess()) {
            txType = 3;
        } else {
            bool lpBurn;
            if (isSupportedPool(sender)) {
                lpBurn = syncPair(sender);
            } else if (isSupportedPool(recipient)){
                silentSyncPair(recipient);
            } else {
                silentSyncPair(_mainPool);
            }
            txType = _getTxType(sender, recipient, lpBurn);
        }
        // Buy Transaction from supported pools - requires mint, no utility fee
        if (txType == 1) {
            _implementBuy(sender, recipient, amount, largeAmount, currentFactor);
        }
        // Sells to supported pools or unsupported transfer - requires exit burn and utility fee
        else if (txType == 2) {
            _implementSell(sender, recipient, amount, largeAmount, currentFactor);
        } 
        // Add Liquidity via interface or Remove Liquidity Transaction to supported pools - no fee of any sort
        else if (txType == 3) {
            _largeBalances[sender] = _largeBalances[sender].sub(largeAmount);
            _largeBalances[recipient] = _largeBalances[recipient].add(largeAmount);
            emit Transfer(sender, recipient, amount);
        }
    }

    function _implementBuy(address sender, address recipient, uint256 amount, uint256 largeAmount, uint256 currentFactor) private {
        (uint256 stabilizerMint, uint256 treasuryMint, uint256 totalMint, uint256 incentive) = getMintValue(sender, amount);
        // uint256 mintSize = amount.div(100);
        _largeBalances[sender] = _largeBalances[sender].sub(largeAmount);
        _largeBalances[recipient] = _largeBalances[recipient].add(largeAmount);
        _largeBalances[getStabilizer()] = _largeBalances[getStabilizer()].add(stabilizerMint.mul(currentFactor));
        _largeBalances[Constants.getTreasuryAdd()] = _largeBalances[Constants.getTreasuryAdd()].add(treasuryMint.mul(currentFactor));
        _totalSupply = _totalSupply.add(totalMint);
        if (incentive > 0) {
            _largeBalances[recipient] = _largeBalances[recipient].add(incentive.mul(currentFactor));
            _largeBalances[address(this)] = _largeBalances[address(this)].sub(incentive.mul(currentFactor));
            _currentPot = _currentPot.sub(incentive);
            emit Transfer(address(this), recipient, incentive);
        }
        emit Transfer(sender, recipient, amount);
        emit Transfer(address(0),getStabilizer(),stabilizerMint);
        emit Transfer(address(0),Constants.getTreasuryAdd(),treasuryMint);
    }

    function _implementSell(address sender, address recipient, uint256 amount, uint256 largeAmount, uint256 currentFactor) private {
        SellDetails memory sell;
        (sell.burnSize, sell.largeBurnSize, sell.potSize, sell.largePotSize) = getBurnValues(recipient, amount);
        (sell.utilityFee, sell.largeUtilityFee) = getUtilityFee(amount);
        sell.actualTransferAmount = amount.sub(sell.burnSize).sub(sell.potSize);
        sell.actualTransferAmount = sell.actualTransferAmount.sub(sell.utilityFee);
        sell.largeTransferAmount = sell.actualTransferAmount.mul(currentFactor);
        _largeBalances[sender] = _largeBalances[sender].sub(largeAmount);
        _largeBalances[recipient] = _largeBalances[recipient].add(sell.largeTransferAmount);
        _largeBalances[_liquidityReserve] = _largeBalances[_liquidityReserve].add(sell.largeUtilityFee);
        if (sell.potSize > 0) {
            _largeBalances[address(this)] = _largeBalances[address(this)].add(sell.largePotSize);
            _currentPot = _currentPot.add(sell.potSize);
            emit Transfer(sender, address(this), sell.potSize);
        }
        _totalSupply = _totalSupply.sub(sell.burnSize);
        _largeTotal = _largeTotal.sub(sell.largeBurnSize);
        emit Transfer(sender, recipient, sell.actualTransferAmount);
        emit Transfer(sender, address(0), sell.burnSize);
        emit Transfer(sender, _liquidityReserve, sell.utilityFee);
    }

    function _getTxType(address sender, address recipient, bool lpBurn) private returns(uint256) {
        uint256 txType = 2;
        if (isSupportedPool(sender)) {
            if (lpBurn) {
                txType = 3;
            } else {
                txType = 1;
            }
        } else if (sender == Constants.getRouterAdd()) {
            txType = 3;
        }
        return txType;
    }

    function unlockTranche(uint256 tranche) external {
        require(hasLockedBalance(_msgSender()),"Caller has no locked balance");
        (address beneficiary, uint256 balance, uint256 unlockTime, bool locked) = getLockBoxes(tranche);
        require(unlockTime <= now,"This tranche cannot be unlocked yet");
        require(beneficiary == _msgSender(),"You are not the owner of this tranche");
        require(locked ==  true, "This tranche has already been unlocked");
        _totalLockedBalance = _totalLockedBalance.sub(balance);
        _largeBalances[_msgSender()] = _largeBalances[_msgSender()].add(balance);
        _lockedBalance[_msgSender()] = _lockedBalance[_msgSender()].sub(balance);
        if (_lockedBalance[_msgSender()] <= 0) _hasLockedBalance[_msgSender()] = false;
        _lockBoxes[tranche].lockedBalance = 0;
        _lockBoxes[tranche].locked = false;
    }

    function reassignTranche(uint256 tranche, address beneficiary) external onlyOwner() {
        (address oldBeneficiary, uint256 balance, uint256 unlockTime, bool locked) = getLockBoxes(tranche);
        require(locked == true, "This tranche has already been unlocked");
        require(unlockTime > now,"This tranche has already been vested");
        _lockedBalance[oldBeneficiary] = _lockedBalance[oldBeneficiary].sub(balance);
        _lockedBalance[beneficiary] = _lockedBalance[beneficiary].add(balance);
        if (_lockedBalance[oldBeneficiary] == 0) _hasLockedBalance[oldBeneficiary] = false;
        _hasLockedBalance[beneficiary] = true; 
        _lockBoxes[tranche].beneficiary = beneficiary;
        uint256 currentFactor = getFactor();
        emit Transfer(oldBeneficiary,beneficiary,balance.div(currentFactor));
    }

    function createTokenPool(address pairToken, uint256 amount) external onlyOwner() taxlessTx {
        IUniswapV2Router02 uniswapRouterV2 = getUniswapRouter();
        IUniswapV2Factory uniswapFactory = getUniswapFactory();
        address tokenUniswapPair;
        if (uniswapFactory.getPair(pairToken, address(this)) == address(0)) {
            tokenUniswapPair = uniswapFactory.createPair(
            pairToken, address(this));
        } else {
            tokenUniswapPair = uniswapFactory.getPair(pairToken,address(this));
        }
        require(uniswapFactory.getPair(pairToken,address(uniswapRouterV2.WETH())) != address(0), "Eth pairing does not exist");
        require(balanceOf(address(this)) >= amount, "Amount exceeds the token balance");
        uint256 toConvert = amount.div(2);
        uint256 toAdd = amount.sub(toConvert);
        uint256 initialBalance = IERC20(pairToken).balanceOf(address(this));
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapRouterV2.WETH();
        path[2] = pairToken;
        _approve(address(this), address(uniswapRouterV2), toConvert);
        uniswapRouterV2.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            toConvert, 0, path, address(this), block.timestamp);
        uint256 newBalance = IERC20(pairToken).balanceOf(address(this)).sub(initialBalance);
        _approve(address(this), address(uniswapRouterV2), toAdd);
        IERC20(pairToken).approve(address(uniswapRouterV2), newBalance);
        uniswapRouterV2.addLiquidity(address(this),pairToken,toAdd,newBalance,0,0,address(this),block.timestamp);
        addSupportedPool(tokenUniswapPair, pairToken);
    }

    function addNewSupportedPool(address pool, address pairToken) external onlyOwner() {
        addSupportedPool(pool, pairToken);
    }

    function removeOldSupportedPool(address pool) external onlyOwner() {
        removeSupportedPool(pool);
    }

    function setTaxlessSetter(address cont) external onlyOwner() {
        require(!isTaxlessSetter(cont),"already setter");
        _isTaxlessSetter[cont] = true;
    }

    function setTaxless(bool flag) public onlyTaxless {
        _taxLess = flag;
    }

    function removeTaxlessSetter(address cont) external onlyOwner() {
        require(isTaxlessSetter(cont),"not setter");
        _isTaxlessSetter[cont] = false;
    }

    function setLiquidityReserve(address reserve) external onlyOwner() {
        require(AddressUpgradeable.isContract(reserve),"Need a contract");
        _isTaxlessSetter[_liquidityReserve] = false;
        uint256 oldBalance = balanceOf(_liquidityReserve);
        if (oldBalance > 0) {
            _transfer(_liquidityReserve, reserve, oldBalance);
            emit Transfer(_liquidityReserve, reserve, oldBalance);
        }
        _liquidityReserve = reserve;
        _isTaxlessSetter[reserve] = true;
    }

    function setStabilizer(address reserve) external onlyOwner() taxlessTx {
        require(AddressUpgradeable.isContract(reserve),"Need a contract");
        _isTaxlessSetter[_stabilizer] = false;
        uint256 oldBalance = balanceOf(_stabilizer);
        if (oldBalance > 0) {
            _transfer(_stabilizer, reserve, oldBalance);
            emit Transfer(_stabilizer, reserve, oldBalance);
        }
        _stabilizer = reserve;
        _isTaxlessSetter[reserve] = true;
    }
    
    function pauseContract(bool flag) external onlyOwner() {
        _paused = flag;
    }

    function getCurrentPot() public view returns (uint256) {
        return _currentPot;
    }
    function getMintValue(address sender, uint256 amount) internal view returns(uint256, uint256, uint256, uint256) {
        uint256 expansionR = (_poolCounters[sender].pairTokenBalance).mul(_poolCounters[sender].startTokenBalance).mul(100);
        expansionR = expansionR.div(_poolCounters[sender].startPairTokenBalance).div(_poolCounters[sender].tokenBalance);
        uint256 mintAmount;
        uint256 incentive;
        if (expansionR > (Constants.getBaseExpansionFactor()).add(10000).div(100)) {
            uint256 mintFactor = expansionR.mul(expansionR);
            mintAmount = amount.mul(mintFactor.sub(10000)).div(10000);
        } else {
            mintAmount = amount.mul(Constants.getBaseExpansionFactor()).div(10000);
            uint256 burnRate = getBurnRate(sender);
            if (burnRate > Constants.getBaseContractionFactor() && _currentPot > 0) {
                incentive = (burnRate.sub(Constants.getBaseContractionFactor())).div(2).mul(amount).div(10000);
                if (incentive > _currentPot) {
                    incentive = _currentPot;
                }
            }
        }
        return (mintAmount.mul(Constants.getStabilizerFee()).div(10000),mintAmount.mul(Constants.getTreasuryFee()).div(10000),mintAmount,incentive);
    }

    function getBurnValues(address recipient, uint256 amount) internal view returns(uint256, uint256, uint256, uint256) {
        uint256 currentFactor = getFactor();
        uint256 contractionR;
        uint256 potAmount;
        uint256 netBurn;
        if (isSupportedPool(recipient)) {
            contractionR = (_poolCounters[recipient].tokenBalance).mul(_poolCounters[recipient].startPairTokenBalance).mul(100);
            contractionR = contractionR.div(_poolCounters[recipient].pairTokenBalance).div(_poolCounters[recipient].startTokenBalance);
        } else {
            contractionR = (_poolCounters[_mainPool].tokenBalance).mul(_poolCounters[_mainPool].startPairTokenBalance).mul(100).div(_poolCounters[_mainPool].pairTokenBalance).div(_poolCounters[_mainPool].startTokenBalance);
        }
        uint256 burnAmount;
        if (contractionR > (Constants.getBaseContractionFactor().add(10000)).div(100)) {
            uint256 burnFactor = contractionR.mul(contractionR);
            burnAmount = amount.mul(burnFactor.sub(10000)).div(10000);
            if (burnAmount > amount.mul(Constants.getBaseContractionCap()).div(10000)) burnAmount = amount.mul(Constants.getBaseContractionCap()).div(10000);
            potAmount = burnAmount.mul(Constants.getIncentivePot()).div(100);
            netBurn = burnAmount.sub(potAmount);
        } else {
            burnAmount = amount.mul(Constants.getBaseContractionFactor()).div(10000);
            netBurn = burnAmount;
        }
        return (netBurn, netBurn.mul(currentFactor), potAmount, potAmount.mul(currentFactor));
    }

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

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
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

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/ContextUpgradeable.sol";
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
library SafeMathUpgradeable {
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
        require(c >= a, "SafeMath: addition overflow");

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
        return sub(a, b, "SafeMath: subtraction overflow");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        require(c / a == b, "SafeMath: multiplication overflow");

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
        return div(a, b, "SafeMath: division by zero");
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        return mod(a, b, "SafeMath: modulo by zero");
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


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
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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