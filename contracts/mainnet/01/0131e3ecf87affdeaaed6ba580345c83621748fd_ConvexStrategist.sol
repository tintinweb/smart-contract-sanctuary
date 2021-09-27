// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./IERC20.sol";
import "./IBooster.sol";
import "./IConvexPooL.sol";
import "./ICurvePooLSize2.sol";
import "./ICurvePooLSize3.sol";
import "./ICurvePooLSize4.sol";
import "./ICurveRegistry.sol";
import "./Ownable.sol";

contract ConvexStrategist is Ownable {
    
    mapping(address => bool) public whitelist;
    address constant crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address constant cvx = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address constant curveRegistry = 0x90E00ACe148ca3b23Ac1bC8C240C2a7Dd9c2d7f5;
    address constant cvxBooster = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;

    /**
     * (see depositAndStakeFor() function.)
     * @param amount            : amount of _token deposited
     * @param nCoins            : Number of coins inside Curve PooL
     * @param indexInAmounts    : Index of the coin deposited inside the amounts array
     * @param inner             : used to decide where are located the tokens
     * @param token             : the ERC20 token deposited in Curve
     * @param curvePooL         : curve pool associated to _token
     * @param convexPooL        : convex pool associated to _token
     * @param curveLPToken      : the liquidity provider token for the current curvePooL
     */
    struct Deposit {
        uint256 amount;
        uint256 nCoins;
        uint256 indexInAmounts;
        bool inner;
        address token;
        address curvePooL;
        address convexPooL;
        address curveLPToken;
    }

    /**
     * (see harvestAndDeposit() function.)
     * @param crvSwapTxData  : paraswap buildTx data to swap tokens within this contract
     * @param cvxSwapTxData  : paraswap buildTx data to swap tokens within this contract
     * @param tokenTo        : destination token swap
     * @param curvePooL      : any curve pool
     * @param convexPooL     : any convex pool
     * @param curveLPToken   : Curve LP Token
     * @param crvAmount      : crv amount to be harvested
     * @param cvxAmount      : cvx amount to be harvested
     * @param nCoins         : Number of coins inside Curve PooL
     * @param indexInAmounts : Index of the coin deposited inside the amounts array
     * @param crvDex         : chosen dex to swap crv
     * @param cvxDex         : chosen dex to swap cvx
     */
    struct Harvest {
        bytes crvSwapTxData;
        bytes cvxSwapTxData;
        address tokenTo;
        address curvePooL;
        address convexPooL;
        address curveLPToken;
        uint256 crvAmount;
        uint256 cvxAmount;
        uint256 nCoins;
        uint256 indexInAmounts;
        address crvDex;
        address cvxDex;
    }

    constructor(address[] memory _whiteListed, address[] memory _approved) {
        for (uint256 i = 0; i < _whiteListed.length; i++) {
            whitelist[_whiteListed[i]] = true;
        }
        for (uint256 i = 0; i < _approved.length; i++) {
            IERC20(crv).approve(_approved[i], type(uint256).max);
            IERC20(cvx).approve(_approved[i], type(uint256).max);
        }
    }

    modifier onlyWhitelisted(address dex) {
        require(isWhitelisted(dex), "!whitelist");
        _;
    }

    function addToWhiteList(address _address) external onlyOwner {
        whitelist[_address] = true;
    }

    function removeFromWhiteList(address _address) external onlyOwner {
        delete whitelist[_address];
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    function setApprovals(
        address _token,
        address _spender,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).approve(_spender, _amount);
    }

    /**
     * Withdraw any ERC20
     * @param _to     : recipient
     * @param _token  : token to withdraw
     * @param _amount : amount to withdraw
     */

    function withdrawERC20(
        address _to,
        address _token,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).transfer(_to, _amount);
    }

    /**
     * Handle deposit in multiple Curve pool according to the token number within the pool.
     * @param  _curvePooL       : curve pool were we deposit token
     * @param  _amount          : amount of token to deposit
     * @param _curveLPToken     : the liquidity provider token for the current _curvePooL
     * @param _nCoins           : number of tokens in the current _curvePooL
     * @param _indexInAmounts   : index of the token in the _curvePooL token list
     * @return minted           : the minted amount returned
     */
    function addCustomLiquidity(
        address _curvePooL,
        uint256 _amount,
        address _curveLPToken,
        uint256 _nCoins,
        uint256 _indexInAmounts
    ) internal returns (uint256 minted) {
        uint256 minMintAmout;
        uint256 initialBalance = IERC20(_curveLPToken).balanceOf(address(this));
        require(_amount > 0, "!addCustomLiquidity: _amount > 0");
        if (_nCoins == 2) {
            uint256[2] memory amounts;
            amounts[_indexInAmounts] = _amount;
            minMintAmout = 0;
            ICurvePooLSize2(_curvePooL).add_liquidity(amounts, minMintAmout);
        } else if (_nCoins == 3) {
            uint256[3] memory amounts;
            amounts[_indexInAmounts] = _amount;
            minMintAmout = 0;
            ICurvePooLSize3(_curvePooL).add_liquidity(amounts, minMintAmout);
        } else if (_nCoins == 4) {
            uint256[4] memory amounts;
            amounts[_indexInAmounts] = _amount;
            minMintAmout = 0;
            ICurvePooLSize4(_curvePooL).add_liquidity(amounts, minMintAmout);
        } else revert("!addCustomLiquidity");
        uint256 finalBalance = IERC20(_curveLPToken).balanceOf(address(this));
        return (finalBalance - initialBalance);
    }

    /**
     * Deposit & stake _token on msg.sender behalf, in Curve & Convex PooLs.
     * @param params    : see the Deposit struct.
     * @return          : the return value of stakeFor() from Convex PooL
     */
    function depositAndStakeFor(Deposit memory params) public returns (bool) {
        if (!params.inner) require(IERC20(params.token).transferFrom(msg.sender, address(this), params.amount), "!transferFrom");
        IERC20(params.token).approve(params.curvePooL, params.amount);
        uint256 minted = addCustomLiquidity(params.curvePooL, params.amount, params.curveLPToken, params.nCoins, params.indexInAmounts);
        address lpToken = ICurveRegistry(curveRegistry).get_lp_token(params.curvePooL);
        require(IERC20(lpToken).approve(cvxBooster, minted), "!approve");
        IBooster(cvxBooster).deposit(IConvexPooL(params.convexPooL).pid(), minted, false);
        address stakingToken = IConvexPooL(params.convexPooL).stakingToken();
        require(IERC20(stakingToken).approve(params.convexPooL, minted), "!approve");
        return IConvexPooL(params.convexPooL).stakeFor(msg.sender, minted);
    }

    /**
     * Perform a swap that has been build off chain.
     * @param  _tokenFrom   : token to swap
     * @param  _amountIn    : amount of _tokenFrom to swap
     * @param  _data        : swap data to be executed
     * @param  _dex         : dex address used to swap
     */
    function swapReward(
        address _tokenFrom,
        uint256 _amountIn,
        address _dex,
        bytes memory _data
    ) private onlyWhitelisted(_dex) {
        IERC20(_tokenFrom).transferFrom(msg.sender, address(this), _amountIn);
        (bool success, ) = _dex.call(_data);
        require(success, _tokenFrom == crv ? "!swap crv" : "!swap cvx");
    }

    /**
     * Harvest a defined amount of CRV and CVX, then dump them to increase the actual deposit
     * @param params         : see the Harvest struct.
     */
    function harvestAndDeposit(Harvest memory params) external returns (bool) {
        uint256 initial = IERC20(params.tokenTo).balanceOf(address(this));
        require(IConvexPooL(params.convexPooL).getReward(msg.sender, true), "!getReward");
        swapReward(crv, params.crvAmount, params.crvDex, params.crvSwapTxData);
        swapReward(cvx, params.cvxAmount, params.cvxDex, params.cvxSwapTxData);
        uint256 harvested = IERC20(params.tokenTo).balanceOf(address(this)) - initial;
        return
            depositAndStakeFor(
                Deposit(
                    harvested,
                    params.nCoins,
                    params.indexInAmounts,
                    true,
                    params.tokenTo,
                    params.curvePooL,
                    params.convexPooL,
                    params.curveLPToken
                )
            );
    }

    fallback() external payable {
        revert("!fallback");
    }

    receive() external payable {
        revert("!receive");
    }
}