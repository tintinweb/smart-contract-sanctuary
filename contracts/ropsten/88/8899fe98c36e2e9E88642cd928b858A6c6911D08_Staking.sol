// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./pancake-swap/interfaces/IPancakePair.sol";
import "./pancake-swap/interfaces/IPancakeRouter02.sol";
import "./pancake-swap/interfaces/IPancakeFactory.sol";

import "./interfaces/IAsset.sol";
import "./interfaces/IStaking.sol";

import "./lib/AssetLib.sol";

contract Staking is ReentrancyGuard, Context, IStaking {
    struct PoolInfo {
        uint256[3] numOfSharesNow;
        /*
        incomeInfo
        0 - num of shares in pool for _TIME_DURATIONS[0]
        1 - num of shares in pool for _TIME_DURATIONS[1]
        2 - num of shares in pool for _TIME_DURATIONS[2]
        3 - bnb amount in pool for _TIME_DURATIONS[0]
        4 - bnb amount in pool for _TIME_DURATIONS[1]
        5 - bnb amount in pool for _TIME_DURATIONS[2]
         */
        uint256[][6] incomeInfo;
        uint256 bagToDistribute;
        uint256 amountOfPenalties;
    }

    struct StakeInfo {
        address staker;
        uint256 lastIncomeIndex;
        address tokenStaked;
        uint256 amountStaked;
        uint256 timestampStakeStart;
        uint8 timeIntervalIndex;
        bool isClaimed;
    }

    // public variables
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    mapping(address => PoolInfo) public poolInfo;
    mapping(address => StakeInfo[]) public stakeInfo;

    address public immutable YDR_TOKEN;
    address public immutable FACTORY;
    address public immutable DEX_ROUTER;
    address public immutable DEX_FACTORY;
    address public ydrLpToken;

    uint256 public treasuryAmount;

    address[] public tokensToEnter;

    // internal variables
    mapping(address => bool) internal _isAllowedToken;

    // private variables
    uint256[3] private _TIME_DURATIONS = [2592000, 7776000, 31104000];
    // percentages for asset - [0-2] and for assetLP - [3-5]
    uint256[6] private _POOL_PERCENTAGES = [80, 240, 480, 120, 360, 720];
    // percentages for ydr - [0-2] and for ydrLP - [3-5]
    uint256[6] private _YDR_POOL_PERCENTAGES = [300, 900, 1800, 400, 1200, 2400];
    // percentages for penalties ydr - [0-2] and for ydrLP - [3-5]
    uint256[6] private _YDR_POOL_PENALTY_PERCENTAGES = [375, 1125, 2250, 500, 1500, 3000];
    address private immutable weth;

    // modifiers
    modifier onlyFactory {
        require(_msgSender() == FACTORY, "Access error");
        _;
    }
    modifier onlyManagerOrAdmin {
        address sender = _msgSender();
        address factory = FACTORY;
        require(
            AccessControl(factory).hasRole(MANAGER_ROLE, sender) ||
                AccessControl(factory).hasRole(0x00, sender),
            "Access error"
        );
        _;
    }

    constructor(
        address ydrToken,
        address factory,
        address dexRouter,
        address dexFactory
    ) {
        YDR_TOKEN = ydrToken;
        FACTORY = factory;
        DEX_ROUTER = dexRouter;
        DEX_FACTORY = dexFactory;
        weth = IPancakeRouter02(dexRouter).WETH();

        _isAllowedToken[ydrToken] = true;
        tokensToEnter.push(ydrToken);
    }

    receive() external payable {
        address sender = _msgSender();
        require(
            _isAllowedTokenCheck(sender) || sender == weth || sender == DEX_ROUTER,
            "Access error"
        );
    }

    function stakeStart(
        address token,
        uint256 amount,
        uint8 timeIntervalIndex
    ) external override {
        require(token != address(0) && amount > 0 && timeIntervalIndex < 3, "Input error");
        require(_isAllowedTokenCheck(token), "Wrong token");

        address sender = _msgSender();
        AssetLib.safeTransferFrom(token, sender, amount);

        StakeInfo memory stake;
        stake.staker = sender;
        stake.lastIncomeIndex = poolInfo[token].incomeInfo[timeIntervalIndex].length;
        stake.tokenStaked = token;
        stake.amountStaked = amount;
        stake.timeIntervalIndex = timeIntervalIndex;
        stake.timestampStakeStart = block.timestamp;
        stakeInfo[sender].push(stake);

        poolInfo[token].numOfSharesNow[timeIntervalIndex] += amount;
    }

    function stakeEnd(uint256 stakeIndex) external override {
        address sender = _msgSender();
        require(stakeIndex < stakeInfo[sender].length, "Input error");
        require(stakeInfo[sender][stakeIndex].isClaimed == false, "Already claimed");

        uint256 timeIntervalIndex = stakeInfo[sender][stakeIndex].timeIntervalIndex;
        address tokenStaked = stakeInfo[sender][stakeIndex].tokenStaked;
        uint256 amountStaked = stakeInfo[sender][stakeIndex].amountStaked;

        // calculate and send dividends (no penalty)
        (uint256 amountOfDividends, ) =
            _calculateDividends(
                poolInfo[tokenStaked],
                timeIntervalIndex,
                amountStaked,
                stakeInfo[sender][stakeIndex].lastIncomeIndex,
                0
            );
        AssetLib.safeTransfer(address(0), sender, amountOfDividends);

        // send stake token back (may be penalty)
        if (
            block.timestamp >=
            stakeInfo[sender][stakeIndex].timestampStakeStart + _TIME_DURATIONS[timeIntervalIndex]
        ) {
            // no penalty
            AssetLib.safeTransfer(tokenStaked, sender, amountStaked);
        } else {
            // penalty 25%
            uint256 penalty = (amountStaked * 2500) / 1e4;
            _proceedPenalty(tokenStaked, penalty);
            AssetLib.safeTransfer(tokenStaked, sender, amountStaked - penalty);
        }

        stakeInfo[sender][stakeIndex].isClaimed = true;
    }

    function claimDividends(uint256 stakeIndex, uint256 maxDepth) external override {
        address sender = _msgSender();
        require(stakeIndex < stakeInfo[sender].length, "Input error");
        require(stakeInfo[sender][stakeIndex].isClaimed == false, "Already claimed");

        address tokenStaked = stakeInfo[sender][stakeIndex].tokenStaked;
        uint256 amountStaked = stakeInfo[sender][stakeIndex].amountStaked;

        // calculate and send dividends (no penalty)
        (uint256 amountOfDividends, uint256 newIncomeIndex) =
            _calculateDividends(
                poolInfo[tokenStaked],
                stakeInfo[sender][stakeIndex].timeIntervalIndex,
                amountStaked,
                stakeInfo[sender][stakeIndex].lastIncomeIndex,
                maxDepth
            );
        stakeInfo[sender][stakeIndex].lastIncomeIndex = newIncomeIndex;

        AssetLib.safeTransfer(address(0), sender, amountOfDividends);
    }

    function createPool(address token) external override onlyFactory {
        _isAllowedToken[token] = true;
        tokensToEnter.push(token);
    }

    function inputBnb() external payable override {
        require(_isAllowedToken[_msgSender()] == true, "Not asset");
        _inputBnb(_msgSender(), msg.value);
    }

    function treasuryWithdraw() external override onlyManagerOrAdmin {
        uint256 treasuryAmountOld = treasuryAmount;
        treasuryAmount = 0;
        AssetLib.safeTransfer(address(0), _msgSender(), treasuryAmountOld);
    }

    function getNumOfSharesNow(address token, uint8 timeIntervalIndex)
        external
        view
        returns (uint256)
    {
        require(token != address(0) && timeIntervalIndex < 3, "Input error");
        return poolInfo[token].numOfSharesNow[timeIntervalIndex];
    }

    function getIncomeLen(address token, uint8 timeIntervalIndex) external view returns (uint256) {
        require(token != address(0) && timeIntervalIndex < 3, "Input error");
        return poolInfo[token].incomeInfo[timeIntervalIndex].length;
    }

    function getIncomeShares(
        address token,
        uint8 timeIntervalIndex,
        uint256 index
    ) external view returns (uint256) {
        require(token != address(0) && timeIntervalIndex < 3, "Input error");
        uint256 len = poolInfo[token].incomeInfo[timeIntervalIndex].length;
        require(index < len, "Input error 2");
        return poolInfo[token].incomeInfo[timeIntervalIndex][index];
    }

    function getIncomeAmounts(
        address token,
        uint8 timeIntervalIndex,
        uint256 index
    ) external view returns (uint256) {
        require(token != address(0) && timeIntervalIndex < 3, "Input error");
        uint256 len = poolInfo[token].incomeInfo[timeIntervalIndex].length;
        require(index < len, "Input error 2");
        return poolInfo[token].incomeInfo[timeIntervalIndex + 3][index];
    }

    function getBagToDistribute(address token) external view returns (uint256) {
        require(token != address(0), "Input error");
        return poolInfo[token].bagToDistribute;
    }

    function getAmountOfPenalties(address token) external view returns (uint256) {
        require(token != address(0), "Input error");
        return poolInfo[token].amountOfPenalties;
    }

    function getStakeInfoLen(address user) external view returns (uint256) {
        require(user != address(0), "Input error");
        return stakeInfo[user].length;
    }

    function tokensToEnterLen() external view returns(uint256) {
        return tokensToEnter.length;
    }

    function amountOfDIvidendsToUser(address user, uint256 stakeIndex, uint256 maxDepth) external view returns(uint256) {
        require(user != address(0), "Input error");
        uint256 len = stakeInfo[user].length;
        require(stakeIndex < len, "Input error");
        (uint256 dividends,) = _calculateDividends(
            poolInfo[stakeInfo[user][stakeIndex].tokenStaked],
            stakeInfo[user][stakeIndex].timestampStakeStart,
            stakeInfo[user][stakeIndex].amountStaked,
            stakeInfo[user][stakeIndex].lastIncomeIndex,
            maxDepth
        );
        return dividends;
    }

    function _calculateDividends(
        PoolInfo storage pool,
        uint256 timeIntervalIndex,
        uint256 amount,
        uint256 indexFrom,
        uint256 maxDepth
    ) private view returns (uint256, uint256) {
        uint256 lenMax = pool.incomeInfo[timeIntervalIndex].length;
        uint256 indexTo;
        if (maxDepth == 0 || indexFrom + maxDepth > lenMax) {
            indexTo = lenMax;
        } else {
            indexTo = indexFrom + maxDepth;
        }

        uint256 totalDividends;
        for (uint256 i = indexFrom; i < indexTo; ++i) {
            uint256 incomeBnb = pool.incomeInfo[timeIntervalIndex + 3][i];
            uint256 totalShares = pool.incomeInfo[timeIntervalIndex][i];
            totalDividends += (incomeBnb * amount) / totalShares;
        }

        return (totalDividends, indexTo);
    }

    function _inputBnb(address token, uint256 amount) private {
        require(amount > 0, "Amount error");
        address ydrToken = YDR_TOKEN;
        address _ydrLpToken = ydrLpToken;
        address _weth = weth;
        address dexFactory = DEX_FACTORY;
        if (_ydrLpToken == address(0)) {
            _ydrLpToken = IPancakeFactory(dexFactory).getPair(ydrToken, _weth);
            if (_ydrLpToken != address(0)) {
                ydrLpToken = _ydrLpToken;
            }
        }

        address tokenLp = IPancakeFactory(dexFactory).getPair(token, _weth);
        require(_getTokenOutOfLp(token) == token, "Internal error lp");

        uint256 inBagNow = poolInfo[token].bagToDistribute;
        if (inBagNow > 0) {
            amount += inBagNow;
            poolInfo[token].bagToDistribute = 0;
            inBagNow = 0;
        }

        uint256 restAmount = amount;
        if (token != ydrToken && token != _ydrLpToken) {
            /* percentages = _POOL_PERCENTAGES;
            uint256 amountToTokenAndLp =
                _calculcateAmountFor6Percentages(amount, percentages); */
            restAmount = _inputInTokenAndLpPools(
                token,
                tokenLp,
                amount,
                restAmount,
                _POOL_PERCENTAGES
            );

            /* percentages = _YDR_POOL_PERCENTAGES;
            amountToTokenAndLp = _calculcateAmountFor6Percentages(amount, percentages); */
            restAmount = _inputInTokenAndLpPools(
                ydrToken,
                _ydrLpToken,
                amount,
                restAmount,
                _YDR_POOL_PERCENTAGES
            );
        } else {
            // if token == ydrToken || token == ydrLpToken
            /* percentages = _YDR_POOL_PENALTY_PERCENTAGES;
            uint256 amountToTokenAndLp =
                _calculcateAmountFor6Percentages(amount, percentages); */
            restAmount = _inputInTokenAndLpPools(
                ydrToken,
                _ydrLpToken,
                amount,
                restAmount,
                _YDR_POOL_PENALTY_PERCENTAGES
            );
        }

        uint256 calculatedAmountToTreasury = amount * 1000 / 1e4;
        if (calculatedAmountToTreasury > restAmount) {
            calculatedAmountToTreasury = restAmount;
            restAmount = 0;
        } else {
            restAmount -= calculatedAmountToTreasury;
        }
        treasuryAmount += calculatedAmountToTreasury;

        if (restAmount > 0) {
            inBagNow += restAmount;
            poolInfo[token].bagToDistribute = inBagNow;
        }
    }

    function _proceedPenalty(address token, uint256 amount) private {
        address goodToken = _getTokenOutOfLp(token);

        uint256 amountOfPenalties = poolInfo[goodToken].amountOfPenalties;
        if (amountOfPenalties > 0 && token == goodToken) {
            amount += amountOfPenalties;
            poolInfo[goodToken].amountOfPenalties = 0;
            amountOfPenalties = 0;
        }
        (uint256 bnbAmount, bool isValid) = _withdrawTokenToBnb(token, goodToken, amount, (token != goodToken));

        if (isValid == true) {
            poolInfo[goodToken].bagToDistribute += bnbAmount;
        } else {
            // can not be lp token here
            amountOfPenalties += amount;
            poolInfo[goodToken].amountOfPenalties = amountOfPenalties;
        }
    }

    function _getTokenOutOfLp(address token) private view returns (address) {
        address token0;
        address token1;
        try IPancakePair(token).token0() returns (address _token0) {
            token0 = _token0;
        } catch (bytes memory) {
            return token;
        }
        try IPancakePair(token).token1() returns (address _token1) {
            token1 = _token1;
        } catch (bytes memory) {
            return token;
        }

        if (token0 == weth) {
            return token1;
        } else {
            return token0;
        }
    }

    function _withdrawTokenToBnb(
        address token,
        address goodToken,
        uint256 amount,
        bool isLp
    ) private returns(uint256 result, bool isValid) {
        if (token != goodToken) {
            address dexRouter = DEX_ROUTER;
            AssetLib.checkAllowance(token, dexRouter, amount);
            (uint256 amountToken, uint256 amountETH) =
                IPancakeRouter02(dexRouter).removeLiquidityETH(
                    goodToken,
                    amount,
                    0,
                    0,
                    address(this),
                    block.timestamp
                );
            result += amountETH;
            (uint256 result2,) = _withdrawTokenToBnb(goodToken, goodToken, amountToken, false);
            result += result2;
        } else {
            address pair = IPancakeFactory(DEX_FACTORY).getPair(weth, token);
            if (pair == address(0)) {
                return (0, false);
            }
            address dexRouter = DEX_ROUTER;
            AssetLib.checkAllowance(token, dexRouter, amount);
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = weth;
            uint256[] memory amounts = IPancakeRouter02(dexRouter).swapExactTokensForETH(
                amount,
                0,
                path,
                address(this),
                block.timestamp
            );
            result += amounts[1];
        }
        isValid = true;
    }

    function _inputInTokenAndLpPools(
        address token,
        address tokenLp,
        uint256 amount,
        uint256 restAmount,
        uint256[6] memory percentages
    ) private returns (uint256) {
        // input bnb to asset
        restAmount -= _inputInPool(token, amount, [percentages[0], percentages[1], percentages[2]]);

        // input bnb to assetLp
        if (tokenLp != address(0)) {
            restAmount -= _inputInPool(tokenLp, amount, [percentages[3], percentages[4], percentages[5]]);
        }

        return restAmount;
    }

    function _inputInPool(
        address token,
        uint256 amount,
        uint256[3] memory percentages
    ) private returns(uint256) {
        PoolInfo storage pool = poolInfo[token];

        uint256 amountTo0 = (amount * percentages[0]) / 1e4;
        uint256 amountTo1 = (amount * percentages[1]) / 1e4;
        uint256 amountTo2 = (amount * percentages[2]) / 1e4;

        uint256 amountDistributed;

        uint256 numOfSharesNow = pool.numOfSharesNow[0];
        if (numOfSharesNow != 0) {
            pool.incomeInfo[0].push(numOfSharesNow);
            pool.incomeInfo[3].push(amountTo0);
            amountDistributed += amountTo0;
        }

        numOfSharesNow = pool.numOfSharesNow[1];
        if (numOfSharesNow != 0) {
            pool.incomeInfo[1].push(numOfSharesNow);
            pool.incomeInfo[4].push(amountTo1);
            amountDistributed += amountTo1;
        }

        numOfSharesNow = pool.numOfSharesNow[2];
        if (numOfSharesNow != 0) {
            pool.incomeInfo[2].push(numOfSharesNow);
            pool.incomeInfo[5].push(amountTo2);
            amountDistributed += amountTo2;
        }

        return amountDistributed;
    }

    function _isAllowedTokenCheck(address token) private returns (bool) {
        if (_isAllowedToken[token] == true) {
            return true;
        } else {
            address token0;
            try IPancakePair(token).token0() returns (address _token0) {
                token0 = _token0;
            } catch (bytes memory) {
                return false;
            }

            address token1;
            try IPancakePair(token).token1() returns (address _token1) {
                token1 = _token1;
            } catch (bytes memory) {
                return false;
            }

            address goodPair = IPancakeFactory(DEX_FACTORY).getPair(token0, token1);
            if (goodPair != token) {
                return false;
            }

            address _weth = weth;
            if (token0 != _weth && token1 != _weth) {
                return false;
            }

            if (_isAllowedToken[token0] == false && _isAllowedToken[token1] == false) {
                return false;
            }

            _isAllowedToken[token] = true;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAsset {
    function __Asset_init(
        string memory name,
        string memory symbol,
        address[3] memory oracleDexRouterAndZVault,
        uint256[2] memory imeTimeInfo,
        address[] calldata _tokenWhitelist,
        address[] calldata _tokensInAsset,
        uint256[] calldata _tokensDistribution
    ) external;

    function mint(address tokenToPay, uint256 amount) external payable;

    function redeem(uint256 amount, address currencyToPay) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOracle {
    function getData(address[] calldata tokens)
        external
        view
        returns (bool[] memory isValidValue, uint256[] memory tokensPrices);

    function uploadData(address[] calldata tokens, uint256[] calldata values) external;

    function getTimestampsOfLastUploads(address[] calldata tokens)
        external
        view
        returns (uint256[] memory timestamps);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStaking {
    function stakeStart(
        address token,
        uint256 amount,
        uint8 timeIntervalIndex
    ) external;

    function stakeEnd(uint256 stakeIndex) external;

    function claimDividends(uint256 stakeIndex, uint256 maxDepth) external;

    function createPool(address token) external;

    function inputBnb() external payable;

    function treasuryWithdraw() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../pancake-swap/interfaces/IPancakeRouter02.sol";
import "../pancake-swap/interfaces/IWETH.sol";

import "../interfaces/IOracle.sol";

library AssetLib {
    function initTokenToBuyInfo(
        address[] memory tokensToBuy,
        uint256 totalWeight,
        mapping(address => uint256) storage tokensDistribution,
        IOracle oracle
    ) external view returns (uint256[][5] memory, uint256[] memory) {
        /*
        tokenToBuyInfo
        0 - tokens to buy amounts
        1 - actual number to buy (tokens to buy amounts - tokensInAssetNow)
        2 - actual weight to buy
        3 - tokens decimals
        4 - is in asset already
         */
        uint256[][5] memory tokenToBuyInfo;
        for (uint256 i = 0; i < tokenToBuyInfo.length; ++i) {
            tokenToBuyInfo[i] = new uint256[](tokensToBuy.length);
        }

        (bool[] memory isValidValue, uint256[] memory tokensPrices) = oracle.getData(tokensToBuy);
        for (uint256 i = 0; i < tokensToBuy.length; ++i) {
            require(isValidValue[i] == true, "Oracle price error");

            tokenToBuyInfo[3][i] = IERC20Metadata(tokensToBuy[i]).decimals();

            uint256 tokenWeight = (tokensDistribution[tokensToBuy[i]] * totalWeight) / 1e4;
            tokenToBuyInfo[0][i] = (tokenWeight * (10**tokenToBuyInfo[3][i])) / tokensPrices[i];
        }

        return (tokenToBuyInfo, tokensPrices);
    }

    function initTokenToSellInfo(
        address[] memory tokensOld,
        IOracle oracle,
        mapping(address => uint256) storage totalTokenAmount
    ) external view returns (uint256[][3] memory, uint256) {
        uint256[][3] memory tokensOldInfo;
        for (uint256 i = 0; i < tokensOldInfo.length; ++i) {
            tokensOldInfo[i] = new uint256[](tokensOld.length);
        }

        (bool[] memory isValidValue, uint256[] memory tokensPrices) = oracle.getData(tokensOld);
        uint256 oldWeight;
        for (uint256 i = 0; i < tokensOld.length; ++i) {
            tokensOldInfo[0][i] = totalTokenAmount[tokensOld[i]];
            tokensOldInfo[2][i] = IERC20Metadata(tokensOld[i]).decimals();
            require(isValidValue[i] == true, "Oracle error");
            oldWeight += (tokensOldInfo[0][i] * tokensPrices[i]) / (10**tokensOldInfo[2][i]);
        }
        require(oldWeight != 0, "No value in asset");

        return (tokensOldInfo, oldWeight);
    }

    function checkAndWriteDistribution(
        address[] memory newTokensInAsset,
        uint256[] memory distribution,
        address[] memory oldTokens,
        mapping(address => uint256) storage tokensDistribution
    ) external {
        uint256 totalPerc;
        for (uint256 i = 0; i < newTokensInAsset.length; ++i) {
            require(newTokensInAsset[i] != address(0), "Wrong token");
            require(distribution[i] > 0, "Zero distribution");
            for (uint256 j = i + 1; j < newTokensInAsset.length; ++j) {
                require(newTokensInAsset[i] != newTokensInAsset[j], "Input error");
            }
            tokensDistribution[newTokensInAsset[i]] = distribution[i];
            totalPerc += distribution[i];
        }
        require(totalPerc == 1e4, "Perc error");

        for (uint256 i = 0; i < oldTokens.length; ++i) {
            bool isFound = false;
            for (uint256 j = 0; j < newTokensInAsset.length && isFound == false; ++j) {
                if (newTokensInAsset[j] == oldTokens[i]) {
                    isFound = true;
                }
            }

            if (isFound == false) {
                tokensDistribution[oldTokens[i]] = 0;
            }
        }
    }

    function withdrawFromYForOwner(
        address[] memory tokensInAsset,
        uint256[] memory tokenAmounts,
        address sender,
        mapping(address => uint256) storage yVaultAmount,
        mapping(address => uint256) storage yVaultAmountInStaking
    ) external {
        require(tokenAmounts.length == tokensInAsset.length, "Invalid input");
        for (uint256 i = 0; i < tokensInAsset.length; ++i) {
            uint256 yAmount = yVaultAmount[tokensInAsset[i]];
            require(yAmount >= tokenAmounts[i], "Not enough y balance");
            yAmount -= tokenAmounts[i];
            yVaultAmount[tokensInAsset[i]] = yAmount;
            yVaultAmountInStaking[tokensInAsset[i]] += tokenAmounts[i];

            safeTransfer(tokensInAsset[i], sender, tokenAmounts[i]);
        }
    }

    function checkAndWriteWhitelist(
        address[] memory tokenWhitelist,
        mapping(address => uint256) storage _whitelistIndexes,
        mapping(address => bool) storage isTokenWhitelisted
    ) external {
        for (uint256 i = 0; i < tokenWhitelist.length; ++i) {
            require(tokenWhitelist[i] != address(0), "No zero address");
            for (uint256 j = 0; j < i; ++j) {
                require(tokenWhitelist[i] != tokenWhitelist[j], "Whitelist error");
            }
            _whitelistIndexes[tokenWhitelist[i]] = i;
            isTokenWhitelisted[tokenWhitelist[i]] = true;
        }
    }

    function changeWhitelist(
        address token,
        bool value,
        address[] storage tokenWhitelist,
        mapping(address => bool) storage isTokenWhitelisted,
        mapping(address => uint256) storage whitelistIndexes
    ) external {
        require(token != address(0), "Token error");

        bool oldValue = isTokenWhitelisted[token];
        if (value == false && oldValue == true) {
            uint256 index = whitelistIndexes[token];
            uint256 len = tokenWhitelist.length;
            if (index < len - 1) {
                address newToken = tokenWhitelist[len - 1];
                tokenWhitelist[index] = newToken;
                whitelistIndexes[newToken] = index;
            }
            tokenWhitelist.pop();
        } else if (value == true && oldValue == false) {
            whitelistIndexes[token] = tokenWhitelist.length;
            tokenWhitelist.push(token);
        } else {
            revert("Wrong value");
        }

        isTokenWhitelisted[token] = value;
    }

    function fillInformationInSellAndBuyTokens(
        address[] memory tokensInAssetNow,
        uint256[][3] memory tokensInAssetNowInfo,
        address[] memory tokensToBuy,
        uint256[][5] memory tokenToBuyInfo,
        uint256[] memory tokensPrices
    )
        external
        pure
        returns (
            uint256[][3] memory,
            uint256[][5] memory,
            uint256[2] memory
        )
    {
        for (uint256 i = 0; i < tokensInAssetNow.length; ++i) {
            bool isFound = false;
            for (uint256 j = 0; j < tokensToBuy.length && isFound == false; ++j) {
                if (tokensInAssetNow[i] == tokensToBuy[j]) {
                    isFound = true;
                    // mark that we found that token in asset already
                    tokenToBuyInfo[4][j] = 1;

                    if (tokenToBuyInfo[0][j] >= tokensInAssetNowInfo[0][i]) {
                        // if need to buy more than asset already have

                        // amount to sell = 0 (already 0)
                        //tokensInAssetNowInfo[1][i] = 0;

                        // actual amount to buy = (total amount to buy) - (amount in asset already)
                        tokenToBuyInfo[1][j] = tokenToBuyInfo[0][j] - tokensInAssetNowInfo[0][i];
                    } else {
                        // if need to buy less than asset already have

                        // amount to sell = (amount in asset already) - (total amount to buy)
                        tokensInAssetNowInfo[1][i] =
                            tokensInAssetNowInfo[0][i] -
                            tokenToBuyInfo[0][j];

                        // actual amount to buy = 0 (already 0)
                        //tokenToBuyInfo[1][j] = 0;
                    }
                }
            }

            // if we don't find token in _tokensToBuy than we need to sell it all
            if (isFound == false) {
                tokensInAssetNowInfo[1][i] = tokensInAssetNowInfo[0][i];
            }
        }

        // tokenToBuyInfoGlobals info
        // 0 - total weight to buy
        // 1 - number of true tokens to buy
        uint256[2] memory tokenToBuyInfoGlobals;
        for (uint256 i = 0; i < tokensToBuy.length; ++i) {
            if (tokenToBuyInfo[4][i] == 0) {
                // if no found in asset yet

                // actual weight to buy = (amount to buy) * (token price) / decimals
                tokenToBuyInfo[2][i] =
                    (tokenToBuyInfo[0][i] * tokensPrices[i]) /
                    (10**tokenToBuyInfo[3][i]);
            } else if (tokenToBuyInfo[1][i] != 0) {
                // if found in asset and amount to buy != 0

                // actual weight to buy = (actual amount to buy) * (token price) / decimals
                tokenToBuyInfo[2][i] =
                    (tokenToBuyInfo[1][i] * tokensPrices[i]) /
                    (10**tokenToBuyInfo[3][i]);
            } else {
                // if found in asset and amount to buy = 0
                continue;
            }
            // increase total weight
            tokenToBuyInfoGlobals[0] += tokenToBuyInfo[2][i];
            // increase number of true tokens to buy
            ++tokenToBuyInfoGlobals[1];
        }

        return (tokensInAssetNowInfo, tokenToBuyInfo, tokenToBuyInfoGlobals);
    }

    function sellTokensInAssetNow(
        address[] memory tokensInAssetNow,
        uint256[][3] memory tokensInAssetNowInfo,
        address weth,
        address dexRouter,
        mapping(address => uint256) storage totalTokenAmount,
        mapping(address => uint256) storage allowanceToDexInfo
    ) external returns (uint256 availableWeth) {
        for (uint256 i = 0; i < tokensInAssetNow.length; ++i) {
            {
                address temp = tokensInAssetNow[i];
                if (totalTokenAmount[temp] == 0) {
                    totalTokenAmount[temp] = tokensInAssetNowInfo[0][i];
                }
            }

            if (tokensInAssetNowInfo[1][i] == 0) continue;

            if (tokensInAssetNow[i] == address(0)) {
                IWETH(weth).deposit{value: tokensInAssetNowInfo[1][i]}();
                availableWeth += tokensInAssetNowInfo[1][i];
            } else if (tokensInAssetNow[i] == address(weth)) {
                availableWeth += tokensInAssetNowInfo[1][i];
            } else if (tokensInAssetNow[i] != address(weth)) {
                availableWeth += safeSwap(
                    [tokensInAssetNow[i], weth],
                    tokensInAssetNowInfo[1][i],
                    dexRouter,
                    allowanceToDexInfo
                );
            }
            {
                address temp = tokensInAssetNow[i];
                totalTokenAmount[temp] -= tokensInAssetNowInfo[1][i];
            }
        }
    }

    function buyTokensInAssetRebase(
        address[] memory tokensToBuy,
        uint256[][5] memory tokenToBuyInfo,
        uint256[2] memory tokenToBuyInfoGlobals,
        address weth,
        address dexRouter,
        uint256 availableWeth,
        mapping(address => uint256) storage totalTokenAmount,
        mapping(address => uint256) storage allowanceToDexInfo
    ) external returns (uint256[] memory outputAmounts) {
        outputAmounts = new uint256[](tokensToBuy.length);
        if (tokenToBuyInfoGlobals[0] == 0 || availableWeth == 0) {
            return outputAmounts;
        }
        uint256 restWeth = availableWeth;
        for (uint256 i = 0; i < tokensToBuy.length && tokenToBuyInfoGlobals[1] > 0; ++i) {
            uint256 wethToSpend;
            // if actual weight to buy = 0
            if (tokenToBuyInfo[2][i] == 0) {
                continue;
            }
            if (tokenToBuyInfoGlobals[1] > 1) {
                wethToSpend = (availableWeth * tokenToBuyInfo[2][i]) / tokenToBuyInfoGlobals[0];
            } else {
                wethToSpend = restWeth;
            }
            require(wethToSpend > 0 && wethToSpend <= restWeth, "Internal error");

            restWeth -= wethToSpend;
            --tokenToBuyInfoGlobals[1];

            outputAmounts[i] = safeSwap(
                [weth, tokensToBuy[i]],
                wethToSpend,
                dexRouter,
                allowanceToDexInfo
            );

            {
                address temp = tokensToBuy[i];
                totalTokenAmount[temp] += outputAmounts[i];
            }
        }

        require(restWeth == 0, "Internal error");

        return outputAmounts;
    }

    function transferTokenAndSwapToWeth(
        address tokenToPay,
        uint256 amount,
        address sender,
        address weth,
        address dexRouter,
        mapping(address => uint256) storage allowanceToDexInfo
    ) external returns (address, uint256) {
        tokenToPay = transferFromToGoodToken(tokenToPay, sender, amount, weth);
        uint256 totalWeth;
        if (tokenToPay == weth) {
            totalWeth = amount;
        } else {
            totalWeth = safeSwap([tokenToPay, weth], amount, dexRouter, allowanceToDexInfo);
        }

        return (tokenToPay, totalWeth);
    }

    function transferFromToGoodToken(
        address token,
        address user,
        uint256 amount,
        address weth
    ) public returns (address) {
        if (token == address(0)) {
            require(msg.value == amount, "Value error");
            token = weth;
            IWETH(weth).deposit{value: amount}();
        } else {
            require(msg.value == 0, "Value error");
            AssetLib.safeTransferFrom(token, user, amount);
        }
        return token;
    }

    function buyTokensMint(
        uint256 totalWeth,
        address[] memory tokensInAsset,
        address[2] memory wethAndDexRouter,
        mapping(address => uint256) storage tokensDistribution,
        mapping(address => uint256) storage totalTokenAmount,
        mapping(address => uint256) storage allowanceToDexInfo
    ) external returns (uint256[] memory buyAmounts, uint256[] memory oldDistribution) {
        buyAmounts = new uint256[](tokensInAsset.length);
        oldDistribution = new uint256[](tokensInAsset.length);
        uint256 restWeth = totalWeth;
        for (uint256 i = 0; i < tokensInAsset.length; ++i) {
            uint256 wethToThisToken;
            if (i < tokensInAsset.length - 1) {
                wethToThisToken = (totalWeth * tokensDistribution[tokensInAsset[i]]) / 1e4;
            } else {
                wethToThisToken = restWeth;
            }
            require(wethToThisToken > 0 && wethToThisToken <= restWeth, "Internal error");

            restWeth -= wethToThisToken;

            oldDistribution[i] = totalTokenAmount[tokensInAsset[i]];

            buyAmounts[i] = safeSwap(
                [wethAndDexRouter[0], tokensInAsset[i]],
                wethToThisToken,
                wethAndDexRouter[1],
                allowanceToDexInfo
            );

            totalTokenAmount[tokensInAsset[i]] = oldDistribution[i] + buyAmounts[i];
        }
    }

    function getMintAmount(
        address[] memory tokensInAsset,
        uint256[] memory buyAmounts,
        uint256[] memory oldDistribution,
        uint256 totalSupply,
        uint256 decimals,
        IOracle oracle
    ) public view returns (uint256 mintAmount) {
        uint256 totalPriceInAsset;
        uint256 totalPriceUser;
        (bool[] memory isValidValue, uint256[] memory tokensPrices) = oracle.getData(tokensInAsset);
        for (uint256 i = 0; i < tokensInAsset.length; ++i) {
            require(isValidValue[i] == true, "Oracle error");
            uint256 decimalsToken = IERC20Metadata(tokensInAsset[i]).decimals();
            totalPriceInAsset += (oldDistribution[i] * tokensPrices[i]) / (10**decimalsToken);
            totalPriceUser += (buyAmounts[i] * tokensPrices[i]) / (10**decimalsToken);
        }

        if (totalPriceInAsset == 0 || totalSupply == 0) {
            return 10**decimals;
        } else {
            return (totalSupply * totalPriceUser) / totalPriceInAsset;
        }
    }

    function safeSwap(
        address[2] memory path,
        uint256 amount,
        address dexRouter,
        mapping(address => uint256) storage allowanceToDexInfo
    ) public returns (uint256) {
        if (path[0] == path[1]) {
            return amount;
        }

        if (allowanceToDexInfo[path[0]] < amount) {
            IERC20(path[0]).approve(address(dexRouter), type(uint256).max);
            allowanceToDexInfo[path[0]] = type(uint256).max - amount;
        }

        address[] memory _path = new address[](2);
        _path[0] = path[0];
        _path[1] = path[1];
        uint256[] memory amounts = IPancakeRouter02(dexRouter).swapExactTokensForTokens(
            amount,
            0,
            _path,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );

        return amounts[1];
    }

    function redeemAndTransfer(
        uint256[2] memory amountAndTotalSupply,
        address[4] memory userCurrencyToPayWethDexRouter,
        mapping(address => uint256) storage totalTokenAmount,
        mapping(address => uint256) storage allowanceToDexInfo,
        address[] memory tokensInAsset,
        uint256[] memory feePercentages
    )
        public
        returns (
            uint256 feeTotal,
            uint256[] memory inputAmounts,
            uint256 outputAmountTotal
        )
    {
        inputAmounts = new uint256[](tokensInAsset.length);
        for (uint256 i = 0; i < tokensInAsset.length; ++i) {
            inputAmounts[i] =
                (totalTokenAmount[tokensInAsset[i]] * amountAndTotalSupply[0]) /
                amountAndTotalSupply[1];

            uint256 outputAmount = swapToCurrency(
                tokensInAsset[i],
                userCurrencyToPayWethDexRouter[1],
                inputAmounts[i],
                [userCurrencyToPayWethDexRouter[2], userCurrencyToPayWethDexRouter[3]],
                allowanceToDexInfo
            );

            uint256 fee = (outputAmount * feePercentages[i]) / 1e4;
            outputAmountTotal += outputAmount - fee;
            feeTotal += fee;

            totalTokenAmount[tokensInAsset[i]] -= inputAmounts[i];
        }

        if (userCurrencyToPayWethDexRouter[1] == address(0)) {
            IWETH(userCurrencyToPayWethDexRouter[2]).withdraw(outputAmountTotal);
            safeTransfer(address(0), userCurrencyToPayWethDexRouter[0], outputAmountTotal);
        } else {
            safeTransfer(
                userCurrencyToPayWethDexRouter[1],
                userCurrencyToPayWethDexRouter[0],
                outputAmountTotal
            );
        }
    }

    function initTokenInfoFromWhitelist(
        address[] memory tokensWhitelist,
        mapping(address => uint256) storage tokenEntersIme
    ) external view returns (uint256[][3] memory tokensIncomeAmounts) {
        tokensIncomeAmounts[0] = new uint256[](tokensWhitelist.length);
        tokensIncomeAmounts[1] = new uint256[](tokensWhitelist.length);
        tokensIncomeAmounts[2] = new uint256[](tokensWhitelist.length);
        for (uint256 i = 0; i < tokensWhitelist.length; ++i) {
            tokensIncomeAmounts[0][i] = tokenEntersIme[tokensWhitelist[i]];
            tokensIncomeAmounts[2][i] = IERC20Metadata(tokensWhitelist[i]).decimals();
        }
    }

    function calculateXYAfterIme(
        address[] memory tokensInAsset,
        mapping(address => uint256) storage totalTokenAmount,
        mapping(address => uint256) storage xVaultAmount,
        mapping(address => uint256) storage yVaultAmount
    ) external {
        for (uint256 i = 0; i < tokensInAsset.length; ++i) {
            uint256 amountTotal = totalTokenAmount[tokensInAsset[i]];
            uint256 amountToX = (amountTotal * 2000) / 1e4;

            xVaultAmount[tokensInAsset[i]] = amountToX;
            yVaultAmount[tokensInAsset[i]] = amountTotal - amountToX;
        }
    }

    function depositToY(
        address[] memory tokensInAsset,
        uint256[] memory tokenAmountsOfY,
        address[] memory tokensOfDividends,
        uint256[] memory amountOfDividends,
        address sender,
        address dexRouter,
        address weth,
        mapping(address => uint256) storage allowanceToDexInfo,
        mapping(address => uint256) storage yVaultAmountInStaking,
        mapping(address => uint256) storage yVaultAmount
    ) external returns (uint256) {
        require(tokensInAsset.length == tokenAmountsOfY.length, "Input error 1");
        require(tokensOfDividends.length == amountOfDividends.length, "Input error 2");

        for (uint256 i = 0; i < tokensInAsset.length; ++i) {
            uint256 amountInStaking = yVaultAmountInStaking[tokensInAsset[i]];
            require(amountInStaking >= tokenAmountsOfY[i], "Trying to send more");
            amountInStaking -= tokenAmountsOfY[i];
            yVaultAmountInStaking[tokensInAsset[i]] = amountInStaking;
            yVaultAmount[tokensInAsset[i]] += tokenAmountsOfY[i];

            safeTransferFrom(tokensInAsset[i], sender, tokenAmountsOfY[i]);
        }

        uint256 totalWeth;
        for (uint256 i = 0; i < tokensOfDividends.length; ++i) {
            safeTransferFrom(tokensOfDividends[i], sender, amountOfDividends[i]);
            totalWeth += safeSwap(
                [tokensOfDividends[i], weth],
                amountOfDividends[i],
                dexRouter,
                allowanceToDexInfo
            );
        }
        return totalWeth;
    }

    function proceedIme(
        address[] memory tokens,
        IOracle oracle,
        mapping(address => uint256) storage tokenEntersIme
    ) external view returns (uint256, uint256[] memory) {
        (bool[] memory isValidValue, uint256[] memory tokensPrices) = oracle.getData(tokens);

        uint256 totalWeight;
        for (uint256 i = 0; i < tokens.length; ++i) {
            require(isValidValue[i] == true, "Not valid oracle values");
            uint256 decimals_ = IERC20Metadata(tokens[i]).decimals();
            totalWeight += (tokenEntersIme[tokens[i]] * tokensPrices[i]) / (10**decimals_);
        }

        return (totalWeight, tokensPrices);
    }

    function getFeePercentagesRedeem(
        address[] memory tokensInAsset,
        mapping(address => uint256) storage totalTokenAmount,
        mapping(address => uint256) storage xVaultAmount
    ) external view returns (uint256[] memory feePercentages) {
        feePercentages = new uint256[](tokensInAsset.length);

        for (uint256 i = 0; i < tokensInAsset.length; ++i) {
            uint256 totalAmount = totalTokenAmount[tokensInAsset[i]];
            uint256 xAmount = xVaultAmount[tokensInAsset[i]];

            if (xAmount >= (1500 * totalAmount) / 1e4) {
                feePercentages[i] = 200;
            } else if (
                xAmount < (1500 * totalAmount) / 1e4 && xAmount >= (500 * totalAmount) / 1e4
            ) {
                uint256 xAmountPertcentage = (xAmount * 1e4) / totalAmount;
                feePercentages[i] = 600 - (400 * (xAmountPertcentage - 500)) / 1000;
            } else {
                revert("xAmount percentage error");
            }
        }
    }

    function swapToCurrency(
        address inputCurrency,
        address outputCurrency,
        uint256 amount,
        address[2] memory wethAndDexRouter,
        mapping(address => uint256) storage allowanceToDexInfo
    ) internal returns (uint256) {
        require(inputCurrency != address(0), "Internal error");
        if (inputCurrency != outputCurrency) {
            uint256 outputAmount;
            if (outputCurrency == wethAndDexRouter[0] || outputCurrency == address(0)) {
                outputAmount = safeSwap(
                    [inputCurrency, wethAndDexRouter[0]],
                    amount,
                    wethAndDexRouter[1],
                    allowanceToDexInfo
                );
            } else {
                outputAmount = safeSwap(
                    [inputCurrency, wethAndDexRouter[0]],
                    amount,
                    wethAndDexRouter[1],
                    allowanceToDexInfo
                );
                outputAmount = safeSwap(
                    [wethAndDexRouter[0], outputCurrency],
                    outputAmount,
                    wethAndDexRouter[1],
                    allowanceToDexInfo
                );
            }
            return outputAmount;
        } else {
            return amount;
        }
    }

    function safeTransferFrom(
        address token,
        address from,
        uint256 amount
    ) internal {
        if (token == address(0)) {
            require(msg.value == amount, "Value error");
        } else {
            require(IERC20(token).transferFrom(from, address(this), amount), "TransferFrom failed");
        }
    }

    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) public {
        if (to == address(this)) {
            return;
        }
        if (token == address(0)) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = to.call{value: amount}(new bytes(0));
            require(success, "Transfer eth failed");
        } else {
            require(IERC20(token).transfer(to, amount), "Transfer token failed");
        }
    }

    function checkAllowance(
        address token,
        address to,
        uint256 amount
    ) external {
        uint256 allowance = IERC20(token).allowance(address(this), to);

        if (amount > allowance) {
            IERC20(token).approve(to, type(uint256).max);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPancakeERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPancakeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IPancakeERC20.sol";

interface IPancakePair is IPancakeERC20 {
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPancakeRouter01 {
    function factory() external view returns (address);

    function WETH() external view returns (address);

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

pragma solidity ^0.8.0;

import "./IPancakeRouter01.sol";

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

pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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

    constructor () {
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

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

