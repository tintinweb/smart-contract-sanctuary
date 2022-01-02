// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity 0.8.10;

import "./token/ReflectiveToken.sol";

contract Equity is ReflectiveToken {
    constructor(address[] memory teamWallets_, address marketingWallet_, address uniswapV2Router02Address_) ReflectiveToken(
        "Test",
        "Test",
        1020000,
        teamWallets_,
        12500,
        marketingWallet_,
        50000,
        uniswapV2Router02Address_,
        500,
        ReflectiveToken.TransferFee(20, 30),
        31536000
    ) {}
}

// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity 0.8.10;

import "../access/SharedOwnable.sol";
import "../interfaces/IReflectionTracker.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract ReflectiveToken is ERC20, SharedOwnable {
    struct TimeLock {
        bool isLocked;
        uint256 constraintUntil;
    }

    struct TransferFee {
        uint256 asSender;
        uint256 asRecipient;
    }

    struct ExcludedFromFee {
        bool asSender;
        bool asRecipient;
    }

    event UniswapV2Router02Updated(address indexed oldUniswapV2Router02Address, address indexed newUniswapV2Router02Address);
    event IsUniswapV2PairUpdated(address indexed account, bool oldIsUniswapV2Pair, bool newIsUniswapV2Pair);
    event ReflectionTrackerUpdated(address indexed oldReflectionTrackerAddress, address indexed newReflectionTrackerAddress);
    event MinimumTokenBalanceForSwapAndSendReflectionsUpdated(uint256 oldMinimumTokenBalanceForSwapAndSendReflections, uint256 newMinimumTokenBalanceForSwapAndSendReflections);
    event RegularTransferAllowed();
    event DefaultUniswapV2PairTransferFeeUpdated(TransferFee oldDefaultUniswapV2PairTransferFee, TransferFee newDefaultUniswapV2PairTransferFee);
    event TransferFeeOfUpdated(address indexed account, TransferFee oldTransferFee, TransferFee newTransferFee);
    event ExcludedFromFeeOfUpdated(address indexed account, ExcludedFromFee oldExcludedFromFee, ExcludedFromFee newExcludedFromFee);
    event AutomatedReflectionTrackerCallsUpdated(bool oldAutomatedReflectionTrackerCalls, bool newAutomatedReflectionTrackerCalls);

    event ReflectionsSent(address tokenAddress, uint256 tokenAmount);
    event ReflectionsProcessed(uint256 gasUsed, uint256 iterations, uint256 claims, uint256 lastProcessedIndex, bool automatic, address indexed processor);

    address constant private _deadAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 constant private _maxFee = 35;

    address[] private _teamWallets;
    address private _marketingWallet;
    IUniswapV2Router02 private _uniswapV2Router02;
    mapping(address => bool) private _isUniswapV2Pair;
    uint256 private _minimumTokenBalanceForSwapAndSendReflections;
    bool private _regularTransferAllowed;
    TransferFee private _defaultUniswapV2PairTransferFee;
    IReflectionTracker private _reflectionTracker;
    mapping(address => TimeLock) private _timeLockOf;
    mapping(address => TransferFee) private _transferFeeOf;
    mapping(address => ExcludedFromFee) private _excludedFromFeeOf;
    bool _automatedReflectionTrackerCalls;
    bool private _inTransferSubStep;

    constructor(string memory name_, string memory symbol_, uint256 supply_, address[] memory teamWallets_, uint256 teamWalletShare_, address marketingWallet_, uint256 marketingWalletShare_ , address uniswapV2Router02Address_, uint256 minimumTokenBalanceForSwapAndSendReflections_, TransferFee memory defaultUniswapV2PairTransferFee_, uint256 teamAndMarketingWalletsTimeLockInSeconds_) ERC20(name_, symbol_) {
        _teamWallets = teamWallets_;
    	_marketingWallet = marketingWallet_;
        _uniswapV2Router02 = IUniswapV2Router02(uniswapV2Router02Address_);
        _minimumTokenBalanceForSwapAndSendReflections = minimumTokenBalanceForSwapAndSendReflections_ * (10**decimals());
        _regularTransferAllowed = false;
        _defaultUniswapV2PairTransferFee = defaultUniswapV2PairTransferFee_;

        address uniswapV2Pair = _getOrCreateTokenPair(_uniswapV2Router02, address(this));
        _isUniswapV2Pair[uniswapV2Pair] = true;
        _transferFeeOf[uniswapV2Pair] = _defaultUniswapV2PairTransferFee;
        _excludedFromFeeOf[address(this)] = ExcludedFromFee(true, true);
        _excludedFromFeeOf[_deadAddress] = ExcludedFromFee(true, true);
        _excludedFromFeeOf[uniswapV2Router02Address_] = ExcludedFromFee(true, true);

        uint teamWalletsLength = _teamWallets.length;
        for (uint i = 0; i < teamWalletsLength; i++)
            _setDeveloperWalletOptions(_teamWallets[i], teamAndMarketingWalletsTimeLockInSeconds_, teamWalletShare_);
        _setDeveloperWalletOptions(_marketingWallet, teamAndMarketingWalletsTimeLockInSeconds_, marketingWalletShare_);

        _automatedReflectionTrackerCalls = true;

        _excludedFromFeeOf[msg.sender] = ExcludedFromFee(true, true);
        _mint(msg.sender, (supply_ - teamWalletShare_ - marketingWalletShare_) * (10**decimals()));
    }

    receive() external payable {}

    function getUniswapV2Router02Address() external view returns (address) {
        return address(_uniswapV2Router02);
    }

    function setUniswapV2Router02Address(address uniswapV2Router02Address) external onlySharedOwners {
        address oldUniswapV2Router02Address = address(_uniswapV2Router02);
        if (oldUniswapV2Router02Address != uniswapV2Router02Address) {
            IUniswapV2Router02 uniswapV2Router02 = IUniswapV2Router02(uniswapV2Router02Address);
            
            address oldUniswapV2Pair = _getOrCreateTokenPair(_uniswapV2Router02, address(this));
            address uniswapV2Pair = _getOrCreateTokenPair(uniswapV2Router02, address(this));
            if (oldUniswapV2Pair != uniswapV2Pair) {
                _setIsUniswapV2Pair(oldUniswapV2Pair, false);
                _setIsUniswapV2Pair(uniswapV2Pair, true);
            }

            _uniswapV2Router02 = uniswapV2Router02;
            emit UniswapV2Router02Updated(oldUniswapV2Router02Address, uniswapV2Router02Address);
            if (address(_reflectionTracker) != address(0))
                _reflectionTracker.setUniswapV2Router02Address(uniswapV2Router02Address);
        }
    }

    function getIsUniswapV2Pair(address account) external view returns (bool) {
        return _isUniswapV2Pair[account];
    }

    function setIsUniswapV2Pair(address account, bool isUniswapV2Pair) external onlySharedOwners {
        _setIsUniswapV2Pair(account, isUniswapV2Pair);
    }

    function _setIsUniswapV2Pair(address account, bool isUniswapV2Pair) private {
        bool oldIsUniswapV2Pair = _isUniswapV2Pair[account];
        if (oldIsUniswapV2Pair != isUniswapV2Pair) {
            _isUniswapV2Pair[account] = isUniswapV2Pair;
            _setTransferFeeOf(account, isUniswapV2Pair ? _defaultUniswapV2PairTransferFee : TransferFee(0, 0));
            _setExcludedFromFeeOf(account, ExcludedFromFee(false, false));
            emit IsUniswapV2PairUpdated(account, oldIsUniswapV2Pair, isUniswapV2Pair);
            if (address(_reflectionTracker) != address(0))
                _reflectionTracker.setExcludedFromReflectionsOf(account, isUniswapV2Pair);
        }
    }

    function getMinimumTokenBalanceForSwapAndSendReflections() external view returns (uint256) {
        return _minimumTokenBalanceForSwapAndSendReflections;
    }

    function setMinimumTokenBalanceForSwapAndSendReflections(uint256 minimumTokenBalanceForSwapAndSendReflections) external onlySharedOwners {
        minimumTokenBalanceForSwapAndSendReflections *= (10**decimals());
        uint256 oldMinimumTokenBalanceForSwapAndSendReflections = _minimumTokenBalanceForSwapAndSendReflections;
        if (oldMinimumTokenBalanceForSwapAndSendReflections != minimumTokenBalanceForSwapAndSendReflections) {
            _minimumTokenBalanceForSwapAndSendReflections = minimumTokenBalanceForSwapAndSendReflections;
            emit MinimumTokenBalanceForSwapAndSendReflectionsUpdated(oldMinimumTokenBalanceForSwapAndSendReflections, minimumTokenBalanceForSwapAndSendReflections);
        }
    }

    function isRegularTransferAllowed() external view returns (bool) {
        return _regularTransferAllowed;
    }

    function allowRegularTransfer() external onlySharedOwners {
        if (!_regularTransferAllowed) {
            _regularTransferAllowed = true;
            emit RegularTransferAllowed();
        }
    }

    function getDefaultUniswapV2PairTransferFee() external view returns (TransferFee memory) {
        return _defaultUniswapV2PairTransferFee;
    }

    function setDefaultUniswapV2PairTransferFee(TransferFee memory defaultUniswapV2PairTransferFee) external onlySharedOwners {
        if (defaultUniswapV2PairTransferFee.asSender > _maxFee)
            revert("ReflectiveToken: max default uniswap v2 pair transfer fee as sender exceeded");

        if (defaultUniswapV2PairTransferFee.asRecipient > _maxFee)
            revert("ReflectiveToken: max default uniswap v2 pair transfer fee as recipient exceeded");

        TransferFee memory oldDefaultUniswapV2PairTransferFee = _defaultUniswapV2PairTransferFee;
        if (oldDefaultUniswapV2PairTransferFee.asSender != defaultUniswapV2PairTransferFee.asSender || oldDefaultUniswapV2PairTransferFee.asRecipient != defaultUniswapV2PairTransferFee.asRecipient) {
            _defaultUniswapV2PairTransferFee = defaultUniswapV2PairTransferFee;
            emit DefaultUniswapV2PairTransferFeeUpdated(oldDefaultUniswapV2PairTransferFee, defaultUniswapV2PairTransferFee);
        }
    }

    function getReflectionTrackerAddress() external view returns (address) {
        return address(_reflectionTracker);
    }

    function setReflectionTrackerAddress(address reflectionTrackerAddress) external onlySharedOwners {
        address oldReflectionTrackerAddress = address(_reflectionTracker);
        if (oldReflectionTrackerAddress != reflectionTrackerAddress) {
            IReflectionTracker reflectionTracker = IReflectionTracker(reflectionTrackerAddress);
            if (!reflectionTracker.isBoundTo(address(this)))
                revert("ReflectiveToken: reflection tracker is not bound to this contract");

            _reflectionTracker = reflectionTracker;
            emit ReflectionTrackerUpdated(oldReflectionTrackerAddress, reflectionTrackerAddress);
        }
    }

    function getTimeLockOf(address account) external view returns (bool) {
        return _timeLockOf[account].isLocked;
    }

    function unlockTimeLockOf(address account) external onlySharedOwners {
        if (!_timeLockOf[account].isLocked)
            revert("ReflectiveToken: address is not locked");
        
        if (_timeLockOf[account].constraintUntil > block.timestamp)
            revert("ReflectiveToken: constraint still active");

        _timeLockOf[account].isLocked = false;
    }

    function getTransferFeeOf(address account) external view returns (TransferFee memory) {
        return _transferFeeOf[account];
    }

    function setTransferFeeOf(address account, TransferFee memory transferFee) external onlySharedOwners {
        return _setTransferFeeOf(account, transferFee);
    }

    function getExcludedFromFeeOf(address account) external view returns (ExcludedFromFee memory) {
        return _excludedFromFeeOf[account];
    }

    function setExcludedFromFeeOf(address account, ExcludedFromFee memory excludedFromFee) external onlySharedOwners {
        return _setExcludedFromFeeOf(account, excludedFromFee);
    }

    function getAutomatedReflectionTrackerCalls() external view returns (bool) {
        return _automatedReflectionTrackerCalls;
    }

    function setAutomatedReflectionTrackerCalls(bool automatedReflectionTrackerCalls) external onlySharedOwners {
        bool oldAutomatedReflectionTrackerCalls = _automatedReflectionTrackerCalls;
        if (oldAutomatedReflectionTrackerCalls != automatedReflectionTrackerCalls) {
            _automatedReflectionTrackerCalls = automatedReflectionTrackerCalls;
            emit AutomatedReflectionTrackerCallsUpdated(oldAutomatedReflectionTrackerCalls, automatedReflectionTrackerCalls);
        }
    }

    function swapAndSendReflections(uint256 amount) external onlySharedOwners {
        _swapAndSendReflections(amount);
    }

	function processAll(uint256 gas) external onlySharedOwners {
        if (address(_reflectionTracker) != address(0)) {
            (uint256 gasUsed, uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = _reflectionTracker.processAll(gas);
            emit ReflectionsProcessed(gasUsed, iterations, claims, lastProcessedIndex, false, tx.origin);
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(!_timeLockOf[sender].isLocked, "ReflectiveToken: transfer from a locked address");
        require(!_timeLockOf[recipient].isLocked, "ReflectiveToken: transfer to a locked address");

        bool transferExcludedFromFees = _excludedFromFeeOf[sender].asSender || _excludedFromFeeOf[recipient].asRecipient;
        require(_regularTransferAllowed || transferExcludedFromFees, "ReflectiveToken: transfer with fees");
        
        if (!transferExcludedFromFees) {
            if (_automatedReflectionTrackerCalls && _isUniswapV2Pair[recipient] && !_inTransferSubStep && balanceOf(address(this)) >= _minimumTokenBalanceForSwapAndSendReflections) {
                _inTransferSubStep = true;
                _swapAndSendReflections((_minimumTokenBalanceForSwapAndSendReflections / 100) * _getRandomNumber());
                _inTransferSubStep = false;
            }

            if (!_inTransferSubStep) {
                uint256 feePercentage = _transferFeeOf[sender].asSender + _transferFeeOf[recipient].asRecipient;
                if (feePercentage > 0) {
                    uint256 feeAmount = (amount / 100) * feePercentage;
                    amount = amount - feeAmount;
                    super._transfer(sender, address(this), feeAmount);
                }
            }
        }

        super._transfer(sender, recipient, amount);

        try _reflectionTracker.setBalanceOf(sender, balanceOf(sender)) {} catch {}
        try _reflectionTracker.setBalanceOf(recipient, balanceOf(recipient)) {} catch {}

        if (_automatedReflectionTrackerCalls && !_inTransferSubStep) {
            _inTransferSubStep = true;
	    	try _reflectionTracker.processAll() returns (uint256 gasUsed, uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ReflectionsProcessed(gasUsed, iterations, claims, lastProcessedIndex, true, tx.origin);
	    	} catch {}
            _inTransferSubStep = false;
        }
    }

    function _getOrCreateTokenPair(IUniswapV2Router02 uniswapV2Router02, address tokenAddress) private returns (address) {
        address tokenPair = IUniswapV2Factory(uniswapV2Router02.factory()).getPair(tokenAddress, uniswapV2Router02.WETH());
        if (tokenPair == address(0))
            tokenPair = IUniswapV2Factory(uniswapV2Router02.factory()).createPair(tokenAddress, uniswapV2Router02.WETH());

        return tokenPair;
    }    

    function _setDeveloperWalletOptions(address account, uint256 timeLockInSeconds, uint256 share) private {
        setSharedOwner(account);
        _excludedFromFeeOf[account] = ExcludedFromFee(true, true);
        _timeLockOf[account] = TimeLock(true, block.timestamp + timeLockInSeconds);
        if (share > 0)
            _mint(account, share * (10**decimals()));
    }

    function _setTransferFeeOf(address account, TransferFee memory transferFee) private {
        if (transferFee.asSender > _maxFee)
            revert("ReflectiveToken: max transfer fee as sender exceeded");

        if (transferFee.asRecipient > _maxFee)
            revert("ReflectiveToken: max transfer fee as recipient exceeded");

        TransferFee memory oldTransferFee = _transferFeeOf[account];
        if (oldTransferFee.asSender != transferFee.asSender || oldTransferFee.asRecipient != transferFee.asRecipient) {
            _transferFeeOf[account] = transferFee;
            emit TransferFeeOfUpdated(account, oldTransferFee, transferFee);
        }
    }

    function _setExcludedFromFeeOf(address account, ExcludedFromFee memory excludedFromFee) private {
        ExcludedFromFee memory oldExcludedFromFee = _excludedFromFeeOf[account];
        if (oldExcludedFromFee.asSender != excludedFromFee.asSender || oldExcludedFromFee.asRecipient != excludedFromFee.asRecipient) {
            _excludedFromFeeOf[account] = excludedFromFee;
            emit ExcludedFromFeeOfUpdated(account, oldExcludedFromFee, excludedFromFee);
        }
    }

    function _swapAndSendReflections(uint256 amount) private {
        if (address(_reflectionTracker) == address(0))
            return;

        IERC20 defaultReflectionTokenContract = IERC20(_reflectionTracker.getDefaultReflectionTokenAddress());

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = _uniswapV2Router02.WETH();
        path[2] = address(defaultReflectionTokenContract);

        _approve(address(this), address(_uniswapV2Router02), amount);

        address reflectionTrackerAddress = address(_reflectionTracker);
        uint256 defaultReflectionTokenAmountBeforeSwap = defaultReflectionTokenContract.balanceOf(reflectionTrackerAddress);
        _uniswapV2Router02.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, 0, path, reflectionTrackerAddress, block.timestamp);
        uint256 defaultReflectionTokenAmountAfterSwap = defaultReflectionTokenContract.balanceOf(reflectionTrackerAddress);

        if (defaultReflectionTokenAmountAfterSwap > defaultReflectionTokenAmountBeforeSwap) {
            uint256 defaultReflectionTokenAmount = defaultReflectionTokenAmountAfterSwap -defaultReflectionTokenAmountBeforeSwap;
            _reflectionTracker.transferReflections(defaultReflectionTokenAmount);
            emit ReflectionsSent(address(defaultReflectionTokenContract), defaultReflectionTokenAmount);
        }
    }
    
    function _getRandomNumber() private view returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp + block.difficulty + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) + block.gaslimit + ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) + block.number)));
        uint256 number = (seed - ((seed / 100) * 100));
        return number == 0 ? 1 : number;
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

    function getCreator() public view returns (address) {
        return _creator;
    }

    function isSharedOwner(address account) public view returns (bool) {
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