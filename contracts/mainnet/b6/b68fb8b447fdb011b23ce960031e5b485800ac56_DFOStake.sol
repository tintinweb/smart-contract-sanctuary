pragma solidity ^0.7.1;

contract DFOStake {

    address private constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address private WETH_ADDRESS = IUniswapV2Router(UNISWAP_V2_ROUTER).WETH();

    address[] private TOKENS;

    mapping(uint256 => uint256) private _totalPoolAmount;

    uint256[] private TIME_WINDOWS;

    uint256[] private REWARD_MULTIPLIERS;

    uint256[] private REWARD_DIVIDERS;

    uint256[] private REWARD_SPLIT_TRANCHES;

    address private _doubleProxy;

    struct StakeInfo {
        address sender;
        uint256 poolPosition;
        uint256 firstAmount;
        uint256 secondAmount;
        uint256 poolAmount;
        uint256 reward;
        uint256 endBlock;
        uint256[] partialRewardBlockTimes;
        uint256 splittedReward;
    }

    uint256 private _startBlock;

    mapping(uint256 => mapping(uint256 => StakeInfo)) private _stakeInfo;
    mapping(uint256 => uint256) private _stakeInfoLength;

    event Staked(address indexed sender, uint256 indexed tier, uint256 indexed poolPosition, uint256 firstAmount, uint256 secondAmount, uint256 poolAmount, uint256 reward, uint256 endBlock, uint256[] partialRewardBlockTimes, uint256 splittedReward);
    event Withdrawn(address sender, address indexed receiver, uint256 indexed tier, uint256 indexed poolPosition, uint256 firstAmount, uint256 secondAmount, uint256 poolAmount, uint256 reward);
    event PartialWithdrawn(address sender, address indexed receiver, uint256 indexed tier, uint256 reward);

    constructor(uint256 startBlock, address doubleProxy, address[] memory tokens, uint256[] memory timeWindows, uint256[] memory rewardMultipliers, uint256[] memory rewardDividers, uint256[] memory rewardSplitTranches) public {

        _startBlock = startBlock;

        _doubleProxy = doubleProxy;

        for(uint256 i = 0; i < tokens.length; i++) {
            TOKENS.push(tokens[i]);
        }

        assert(timeWindows.length == rewardMultipliers.length && rewardMultipliers.length == rewardDividers.length && rewardDividers.length == rewardSplitTranches.length);
        for(uint256 i = 0; i < timeWindows.length; i++) {
            TIME_WINDOWS.push(timeWindows[i]);
        }

        for(uint256 i = 0; i < rewardMultipliers.length; i++) {
            REWARD_MULTIPLIERS.push(rewardMultipliers[i]);
        }

        for(uint256 i = 0; i < rewardDividers.length; i++) {
            REWARD_DIVIDERS.push(rewardDividers[i]);
        }

        for(uint256 i = 0; i < rewardSplitTranches.length; i++) {
            REWARD_SPLIT_TRANCHES.push(rewardSplitTranches[i]);
        }
    }

    function doubleProxy() public view returns(address) {
        return _doubleProxy;
    }

    function tokens() public view returns(address[] memory) {
        return TOKENS;
    }

    function tierData() public view returns(uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
        return (TIME_WINDOWS, REWARD_MULTIPLIERS, REWARD_DIVIDERS, REWARD_SPLIT_TRANCHES);
    }

    function startBlock() public view returns(uint256) {
        return _startBlock;
    }

    function totalPoolAmount(uint256 poolPosition) public view returns(uint256) {
        return _totalPoolAmount[poolPosition];
    }

    function setDoubleProxy(address newDoubleProxy) public {
        require(IMVDFunctionalitiesManager(IMVDProxy(IDoubleProxy(_doubleProxy).proxy()).getMVDFunctionalitiesManagerAddress()).isAuthorizedFunctionality(msg.sender), "Unauthorized Action!");
        _doubleProxy = newDoubleProxy;
    }

    function emergencyFlush() public {
        IMVDProxy proxy = IMVDProxy(IDoubleProxy(_doubleProxy).proxy());
        require(IMVDFunctionalitiesManager(proxy.getMVDFunctionalitiesManagerAddress()).isAuthorizedFunctionality(msg.sender), "Unauthorized Action!");
        address walletAddress = proxy.getMVDWalletAddress();
        address tokenAddress = proxy.getToken();
        IERC20 token = IERC20(tokenAddress);
        uint256 balanceOf = token.balanceOf(address(this));
        if(balanceOf > 0) {
            token.transfer(walletAddress, balanceOf);
        }
        balanceOf = 0;
        for(uint256 i = 0; i < TOKENS.length; i++) {
            token = IERC20(IUniswapV2Factory(UNISWAP_V2_FACTORY).getPair(tokenAddress, TOKENS[i]));
            balanceOf = token.balanceOf(address(this));
            if(balanceOf > 0) {
                token.transfer(walletAddress, balanceOf);
                _totalPoolAmount[i] = 0;
            }
            balanceOf = 0;
        }
    }

    function stake(uint256 tier, uint256 poolPosition, uint256 originalFirstAmount, uint256 firstAmountMin, uint256 value, uint256 secondAmountMin) public payable {
        require(block.number >= _startBlock, "Staking is still not available");
        require(poolPosition < TOKENS.length, "Unknown Pool");
        require(tier < TIME_WINDOWS.length, "Unknown tier");

        require(originalFirstAmount > 0, "First amount must be greater than 0");

        uint256 originalSecondAmount = TOKENS[poolPosition] == WETH_ADDRESS ? msg.value : value;
        require(originalSecondAmount > 0, "Second amount must be greater than 0");

        IMVDProxy proxy = IMVDProxy(IDoubleProxy(_doubleProxy).proxy());
        address tokenAddress = proxy.getToken();

        _transferTokensAndCheckAllowance(tokenAddress, originalFirstAmount);
        _transferTokensAndCheckAllowance(TOKENS[poolPosition], originalSecondAmount);

        address secondToken = TOKENS[poolPosition];

        (uint256 firstAmount, uint256 secondAmount, uint256 poolAmount) = _createPoolToken(originalFirstAmount, firstAmountMin, originalSecondAmount, secondAmountMin, tokenAddress, secondToken);

        _totalPoolAmount[poolPosition] += poolAmount;

        (uint256 minCap,, uint256 remainingToStake) = getStakingInfo(tier);
        require(firstAmount >= minCap, "Amount to stake is less than the current min cap");
        require(firstAmount <= remainingToStake, "Amount to stake must be less than the current remaining one");

        calculateRewardAndAddStakingPosition(tier, poolPosition, firstAmount, secondAmount, poolAmount, proxy);
    }

    function getStakingInfo(uint256 tier) public view returns(uint256 minCap, uint256 hardCap, uint256 remainingToStake) {
        (minCap, hardCap) = getStakingCap(tier);
        remainingToStake = hardCap;
        uint256 length = _stakeInfoLength[tier];
        for(uint256 i = 0; i < length; i++) {
            if(_stakeInfo[tier][i].endBlock > block.number) {
                remainingToStake -= _stakeInfo[tier][i].firstAmount;
            }
        }
    }

    function getStakingCap(uint256 tier) public view returns(uint256, uint256) {
        IStateHolder stateHolder = IStateHolder(IMVDProxy(IDoubleProxy(_doubleProxy).proxy()).getStateHolderAddress());
        string memory tierString = _toString(tier);
        string memory addressString = _toLowerCase(_toString(address(this)));
        return (
            stateHolder.getUint256(string(abi.encodePacked("staking.", addressString, ".tiers[", tierString, "].minCap"))),
            stateHolder.getUint256(string(abi.encodePacked("staking.", addressString, ".tiers[", tierString, "].hardCap")))
        );
    }

    function _transferTokensAndCheckAllowance(address tokenAddress, uint256 value) private {
        if(tokenAddress == WETH_ADDRESS) {
            return;
        }
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), value);
        if(token.allowance(address(this), UNISWAP_V2_ROUTER) <= value) {
            token.approve(UNISWAP_V2_ROUTER, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        }
    }

    function _createPoolToken(uint256 originalFirstAmount, uint256 firstAmountMin, uint256 originalSecondAmount, uint256 secondAmountMin, address firstToken, address secondToken) private returns(uint256 firstAmount, uint256 secondAmount, uint256 poolAmount) {
        if(secondToken == WETH_ADDRESS) {
            (firstAmount, secondAmount, poolAmount) = IUniswapV2Router(UNISWAP_V2_ROUTER).addLiquidityETH{value: originalSecondAmount}(
                firstToken,
                originalFirstAmount,
                firstAmountMin,
                secondAmountMin,
                address(this),
                block.timestamp + 1000
            );
        } else {
            (firstAmount, secondAmount, poolAmount) = IUniswapV2Router(UNISWAP_V2_ROUTER).addLiquidity(
                firstToken,
                secondToken,
                originalFirstAmount,
                originalSecondAmount,
                firstAmountMin,
                secondAmountMin,
                address(this),
                block.timestamp + 1000
            );
        }
        if(firstAmount < originalFirstAmount) {
            IERC20(firstToken).transfer(msg.sender, originalFirstAmount - firstAmount);
        }
        if(secondAmount < originalSecondAmount) {
            if(secondToken == WETH_ADDRESS) {
                payable(msg.sender).transfer(originalSecondAmount - secondAmount);
            } else {
                IERC20(secondToken).transfer(msg.sender, originalSecondAmount - secondAmount);
            }
        }
    }

    function calculateRewardAndAddStakingPosition(uint256 tier, uint256 poolPosition, uint256 firstAmount, uint256 secondAmount, uint256 poolAmount, IMVDProxy proxy) private {
        uint256 partialRewardSingleBlockTime = TIME_WINDOWS[tier] / REWARD_SPLIT_TRANCHES[tier];
        uint256[] memory partialRewardBlockTimes = new uint256[](REWARD_SPLIT_TRANCHES[tier]);
        if(partialRewardBlockTimes.length > 0) {
            partialRewardBlockTimes[0] = block.number + partialRewardSingleBlockTime;
            for(uint256 i = 1; i < partialRewardBlockTimes.length; i++) {
                partialRewardBlockTimes[i] = partialRewardBlockTimes[i - 1] + partialRewardSingleBlockTime;
            }
        }
        uint256 reward = firstAmount * REWARD_MULTIPLIERS[tier] / REWARD_DIVIDERS[tier];
        StakeInfo memory stakeInfo = StakeInfo(msg.sender, poolPosition, firstAmount, secondAmount, poolAmount, reward, block.number + TIME_WINDOWS[tier], partialRewardBlockTimes, reward / REWARD_SPLIT_TRANCHES[tier]);
        _add(tier, stakeInfo);
        proxy.submit("stakingTransfer", abi.encode(address(0), 0, reward, address(this)));
        emit Staked(msg.sender, tier, poolPosition, firstAmount, secondAmount, poolAmount, reward, stakeInfo.endBlock, partialRewardBlockTimes, stakeInfo.splittedReward);
    }

    function _add(uint256 tier, StakeInfo memory element) private returns(uint256, uint256) {
        _stakeInfo[tier][_stakeInfoLength[tier]] = element;
        _stakeInfoLength[tier] = _stakeInfoLength[tier] + 1;
        return (element.reward, element.endBlock);
    }

    function _remove(uint256 tier, uint256 i) private {
        if(_stakeInfoLength[tier] <= i) {
            return;
        }
        _stakeInfoLength[tier] = _stakeInfoLength[tier] - 1;
        if(_stakeInfoLength[tier] > i) {
            _stakeInfo[tier][i] = _stakeInfo[tier][_stakeInfoLength[tier]];
        }
        delete _stakeInfo[tier][_stakeInfoLength[tier]];
    }

    function length(uint256 tier) public view returns(uint256) {
        return _stakeInfoLength[tier];
    }

    function stakeInfo(uint256 tier, uint256 position) public view returns(
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256[] memory,
        uint256
    ) {
        StakeInfo memory tierStakeInfo = _stakeInfo[tier][position];
        return(
            tierStakeInfo.sender,
            tierStakeInfo.poolPosition,
            tierStakeInfo.firstAmount,
            tierStakeInfo.secondAmount,
            tierStakeInfo.poolAmount,
            tierStakeInfo.reward,
            tierStakeInfo.endBlock,
            tierStakeInfo.partialRewardBlockTimes,
            tierStakeInfo.splittedReward
        );
    }

    function partialReward(uint256 tier, uint256 position) public {
        StakeInfo memory tierStakeInfo = _stakeInfo[tier][position];
        if(block.number >= tierStakeInfo.endBlock) {
            return withdraw(tier, position);
        }
        require(tierStakeInfo.reward > 0, "No more reward for this staking position");
        uint256 reward = 0;
        for(uint256 i = 0; i < tierStakeInfo.partialRewardBlockTimes.length; i++) {
            if(tierStakeInfo.partialRewardBlockTimes[i] > 0 && block.number >= tierStakeInfo.partialRewardBlockTimes[i]) {
                reward += tierStakeInfo.splittedReward;
                tierStakeInfo.partialRewardBlockTimes[i] = 0;
            }
        }
        reward = reward > tierStakeInfo.reward ? tierStakeInfo.reward : reward;
        require(reward > 0, "No reward to redeem");
        IERC20 token = IERC20(IMVDProxy(IDoubleProxy(_doubleProxy).proxy()).getToken());
        token.transfer(tierStakeInfo.sender, reward);
        tierStakeInfo.reward = tierStakeInfo.reward - reward;
        _stakeInfo[tier][position] = tierStakeInfo;
        emit PartialWithdrawn(msg.sender, tierStakeInfo.sender, tier, reward);
    }

    function withdraw(uint256 tier, uint256 position) public {
        StakeInfo memory tierStakeInfo = _stakeInfo[tier][position];
        require(block.number >= tierStakeInfo.endBlock, "Cannot actually withdraw this position");
        IERC20 token = IERC20(IMVDProxy(IDoubleProxy(_doubleProxy).proxy()).getToken());
        if(tierStakeInfo.reward > 0) {
            token.transfer(tierStakeInfo.sender, tierStakeInfo.reward);
        }
        token = IERC20(IUniswapV2Factory(UNISWAP_V2_FACTORY).getPair(address(token), TOKENS[tierStakeInfo.poolPosition]));
        token.transfer(tierStakeInfo.sender, tierStakeInfo.poolAmount);
        _totalPoolAmount[tierStakeInfo.poolPosition] = _totalPoolAmount[tierStakeInfo.poolPosition] - tierStakeInfo.poolAmount;
        emit Withdrawn(msg.sender, tierStakeInfo.sender, tier, tierStakeInfo.poolPosition, tierStakeInfo.firstAmount, tierStakeInfo.secondAmount, tierStakeInfo.poolAmount, tierStakeInfo.reward);
        _remove(tier, position);
    }

    function _toString(uint _i) private pure returns(string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function _toString(address _addr) private pure returns(string memory) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }

    function _toLowerCase(string memory str) private pure returns(string memory) {
        bytes memory bStr = bytes(str);
        for (uint i = 0; i < bStr.length; i++) {
            bStr[i] = bStr[i] >= 0x41 && bStr[i] <= 0x5A ? bytes1(uint8(bStr[i]) + 0x20) : bStr[i];
        }
        return string(bStr);
    }
}

interface IMVDProxy {
    function getToken() external view returns(address);
    function getStateHolderAddress() external view returns(address);
    function getMVDWalletAddress() external view returns(address);
    function getMVDFunctionalitiesManagerAddress() external view returns(address);
    function submit(string calldata codeName, bytes calldata data) external payable returns(bytes memory returnData);
}

interface IStateHolder {
    function setUint256(string calldata name, uint256 value) external returns(uint256);
    function getUint256(string calldata name) external view returns(uint256);
    function getBool(string calldata varName) external view returns (bool);
    function clear(string calldata varName) external returns(string memory oldDataType, bytes memory oldVal);
}

interface IMVDFunctionalitiesManager {
    function isAuthorizedFunctionality(address functionality) external view returns(bool);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IUniswapV2Router {
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
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IDoubleProxy {
    function proxy() external view returns(address);
}