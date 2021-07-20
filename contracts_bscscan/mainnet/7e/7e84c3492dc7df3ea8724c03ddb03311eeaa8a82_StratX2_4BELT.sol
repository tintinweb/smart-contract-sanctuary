/**
 *Submitted for verification at BscScan.com on 2021-04-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./StratX2.sol";

interface IBeltMultiStrategyToken {
    function add_liquidity(uint256[4] memory _uamounts, uint256 _min_mint_amount) external;
}

contract StratX2_4BELT is StratX2 {
    address public token2Address;
    address public token3Address;
    address[] public earnedToToken2Path;
    address[] public earnedToToken3Path;
    address public addLiquidityAddress;
    uint256 public token_ratio = 10000;
    uint256 public token_ratio_max = 10000;

    event SetTokenRatio(uint256 _token_ratio);

    constructor(
        address[] memory _addresses,
        uint256 _pid,
        bool[] memory _flags,
        address[] memory _earnedToCHERRYPath,
        address[] memory _earnedToToken0Path,
        address[] memory _earnedToToken1Path,
        address[] memory _earnedToToken2Path,
        address[] memory _earnedToToken3Path,
        uint256 _controllerFee,
        uint256 _buyBackRate,
        uint256 _entranceFeeFactor,
        uint256 _distributionRatio,
        uint256 _withdrawFeeFactor
    ) public {
        wbnbAddress = _addresses[0];
        govAddress = _addresses[1];
        cherryFarmAddress = _addresses[2];
        CHERRYAddress = _addresses[3];

        wantAddress = _addresses[4];
        token0Address = _addresses[5];
        token1Address = _addresses[6];
        earnedAddress = _addresses[7];

        farmContractAddress = _addresses[8];
        pid = _pid;
        isCAKEStaking = _flags[0];
        isSameAssetDeposit = _flags[1];
        isCherryComp = _flags[2];
        isVaultComp = _flags[3];

        uniRouterAddress = _addresses[9];
        earnedToCHERRYPath = _earnedToCHERRYPath;
        earnedToToken0Path = _earnedToToken0Path;
        earnedToToken1Path = _earnedToToken1Path;
        earnedToToken2Path = _earnedToToken2Path;
        earnedToToken3Path = _earnedToToken3Path;

        controllerFee = _controllerFee;
        rewardsAddress = _addresses[10];
        buyBackRate = _buyBackRate;
        buyBackAddress = _addresses[11];
        depositFeeFundAddress = _addresses[12];
        delegateFundAddress = _addresses[13];
        
        token2Address = _addresses[14];
        token3Address = _addresses[15];
        addLiquidityAddress = _addresses[16];

        entranceFeeFactor = _entranceFeeFactor;
        distributionDepositRatio = _distributionRatio;
        withdrawFeeFactor = _withdrawFeeFactor;

        transferOwnership(cherryFarmAddress);
    }

    function setTokenRatio(uint256 ratio) public virtual onlyAllowGov {
        token_ratio = ratio;
        emit SetTokenRatio(ratio);
    }

    function earn() public override nonReentrant whenNotPaused {
        require(isCherryComp, "!isCherryComp");
        if (onlyGov) {
            require(msg.sender == govAddress, "!gov");
        }

        // Harvest farm tokens
        _unfarm(0);

        if (earnedAddress == wbnbAddress) {
            _wrapBNB();
        }

        // Converts farm tokens into want tokens
        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));

        if (isVaultComp) {
			earnedAmt = distributeFees(earnedAmt);

			IERC20(earnedAddress).safeApprove(uniRouterAddress, 0);
			IERC20(earnedAddress).safeIncreaseAllowance(
				uniRouterAddress,
				earnedAmt
			);

            _safeSwapToken(earnedAmt, earnedToToken0Path);
            _safeSwapToken(earnedAmt, earnedToToken1Path);
            _safeSwapToken(earnedAmt, earnedToToken2Path);
            _safeSwapToken(earnedAmt, earnedToToken3Path);

            uint256[4] memory tokenAmts;
            tokenAmts[0] = setAmt(token0Address);
            tokenAmts[1] = setAmt(token1Address);
            tokenAmts[2] = setAmt(token2Address);
            tokenAmts[3] = setAmt(token3Address);

            uint256 _sum = tokenAmts[0].add(tokenAmts[1]).add(tokenAmts[2]).add(tokenAmts[3]);
            uint256 sum = _sum.mul(token_ratio).div(token_ratio_max);

			IBeltMultiStrategyToken(addLiquidityAddress).add_liquidity(tokenAmts, sum);

			lastEarnBlock = block.number;

			_farm();
		} else {
			delegateFees(earnedAmt);
		}
    }

    function _safeSwapToken(uint256 earnedAmt, address[] memory earnedToTokenPath)
        internal
        virtual
    {
        _safeSwap(
            uniRouterAddress,
            earnedAmt.div(4),
            slippageFactor,
            earnedToTokenPath,
            address(this),
            block.timestamp.add(600)
        );
    }

    function setAmt(address tokenAddress)
        internal
        virtual
        returns (uint256)
    {
		uint256 tokenAmt = IERC20(tokenAddress).balanceOf(address(this));
		IERC20(tokenAddress).safeApprove(addLiquidityAddress, 0);
		IERC20(tokenAddress).safeIncreaseAllowance(addLiquidityAddress, tokenAmt);
        return tokenAmt;
    }

}