//SPDX-License-Identifier: MIT" 
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../interfaces/ILPPool.sol";
import "../../interfaces/ICurveFi.sol";
import "../../interfaces/IUniswapV2Pair.sol";
import "../../interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FAANGStrategy is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;


    struct mAsset {
        uint256 weight;
        IERC20 mAssetToken;
        ILPPool lpPool;
        IERC20 lpToken;
        uint amountOfATotal;
        uint amountOfBTotal;
    }

    IERC20 constant ust = IERC20(0xa47c8bf37f92aBed4A126BDA807A7b7498661acD);
    IERC20 constant mir = IERC20(0x09a3EcAFa817268f77BE1283176B946C4ff2E608);
    ICurveFi public constant curveFi = ICurveFi(0x890f4e345B1dAED0367A877a1612f86A1f86985f); 
    IUniswapV2Router02 public constant router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory public constant factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    
    address public vault;
    address public treasuryWallet;
    
    address private constant mirustPairAddress = 0x87dA823B6fC8EB8575a235A824690fda94674c88;
    address constant DAIToken = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant mirUstPooltoken = 0x87dA823B6fC8EB8575a235A824690fda94674c88;
    ILPPool mirustPool;

    mapping(address => int128) curveIds;
    mapping(IERC20 => uint256) public userTotalLPToken;
    mapping(IERC20 => uint256) public amountInPool;
    mapping(ILPPool => uint256) public poolStakedMIRLPToken;
    mAsset[] public mAssets;

    uint reInvestedMirUstPooltoken;

    modifier onlyVault {
        require(msg.sender == vault, "only vault");
        _;
    }    

    constructor(
        address _treasuryWallet, 
        address _mirustPool,
        uint[] memory weights,
        IERC20[] memory mAssetsTokens,
        ILPPool[] memory lpPools,
        IERC20[] memory lpTokens

        ) {
        
        
        curveIds[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = 2;
        curveIds[0xdAC17F958D2ee523a2206206994597C13D831ec7] = 3;
        curveIds[0x6B175474E89094C44Da98b954EedeAC495271d0F] = 1;

        treasuryWallet = _treasuryWallet;
        mirustPool = ILPPool(_mirustPool);

        IERC20(0x87dA823B6fC8EB8575a235A824690fda94674c88).approve(_mirustPool, type(uint).max); //approve mirUST uniswap LP token to stake on mirror
        ust.approve(address(router), type(uint256).max);
        ust.approve(address(curveFi), type(uint256).max);
        mir.approve(address(router), type(uint256).max);
        //DAI
        IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F).approve(address(router), type(uint256).max);
        IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F).approve(address(curveFi), type(uint256).max);
        //USDC
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).approve((address(router)), type(uint).max);
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).approve((address(curveFi)), type(uint).max);
        //USDT
        IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7).safeApprove(address(router), type(uint).max);
        IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7).safeApprove((address(curveFi)), type(uint).max);

        for(uint i=0; i<weights.length; i++) {
            mAssets.push(mAsset({
                weight: weights[i],
                mAssetToken : mAssetsTokens[i],
                lpPool:lpPools[i],
                lpToken:lpTokens[i],
                amountOfATotal: 0,
                amountOfBTotal: 0
            }));

            mAssetsTokens[i].approve(address(router), type(uint).max);
            lpTokens[i].approve(_mirustPool, type(uint).max);
            lpTokens[i].approve(address(lpPools[i]), type(uint).max);
            lpTokens[i].approve(address(router), type(uint).max);
            IERC20(mirUstPooltoken).approve(address(router), type(uint).max);
        }



    }
    /**
        @param _amount Amount of tokens to deposit in original decimals
        @param _token Token to deposit
     */
    function deposit(uint256 _amount, IERC20 _token) external onlyVault {
        require(_amount > 0, 'Invalid amount');

        _token.safeTransferFrom(address(vault), address(this), _amount);

        
        address[] memory path = new address[](2);
        path[0] = address(_token);
        path[1] = address(ust);

        uint256 ustAmount = curveFi.exchange_underlying(curveIds[address(_token)], 0, _amount, 0);
        
        uint256[] memory amounts;        

        for (uint256 i = 0; i < mAssets.length; i++) {
            address addr_ = address(mAssets[i].mAssetToken);
            // UST -> mAsset on Uniswap
            path[0] = address(ust);
            path[1] = addr_;
            uint _ustAmount = ustAmount.mul(mAssets[i].weight).div(10000);
            amounts = router.swapExactTokensForTokens(
                _ustAmount,
                0,
                path,
                address(this),
                block.timestamp
            );

            (, , uint256 poolTokenAmount) = router.addLiquidity(addr_,  address(ust), amounts[1], _ustAmount, 0, 0, address(this), block.timestamp);

            // stake LPToken to LPPool
            //no incentives for mFB pool tokens so address(0)
            if(address(mAssets[i].lpPool) != address(0)) {  
                mAssets[i].lpPool.stake(poolTokenAmount);
            }
                        

            userTotalLPToken[mAssets[i].lpToken] = userTotalLPToken[mAssets[i].lpToken].add(poolTokenAmount);
            mAssets[i].amountOfATotal = mAssets[i].amountOfATotal.add(amounts[1]);
            mAssets[i].amountOfBTotal = mAssets[i].amountOfBTotal.add(_ustAmount);
            
        }

        
    }

    /**
        @param _amount Amount of tokens to withdraw. Should be scaled to 18 decimals
        @param _token Token to withdraw
     */
    function withdraw(uint256 _amount, IERC20 _token) external onlyVault {
        require(_amount > 0, "Invalid Amount");
        address[] memory path = new address[](2);
        path[0] = address(mir);
        path[1] = address(ust);

        uint valueInPool = getTotalValueInPool();
        
        for (uint256 i = 0; i < mAssets.length; i++) {
            //_amount should be 18 decimals
            uint amounOfLpTokenToRemove = getDataFromLPPool(address(mAssets[i].lpToken), _amount, valueInPool);
            
            //uniswap LPTokens for mFb-UST are not staked. For others, we need to get from mirror pool
            if(address(mAssets[i].lpPool) != address(0)) {
                mAssets[i].lpPool.withdraw(amounOfLpTokenToRemove);
            } 

            (uint256 mAssetAmount, uint256 ustAmount) =
                router.removeLiquidity(
                    address(mAssets[i].mAssetToken),
                    address(ust),
                    amounOfLpTokenToRemove, 
                    0,
                    0,
                    address(this),
                    block.timestamp
                );
            uint adjustedAmountATotal = mAssets[i].amountOfATotal < mAssetAmount ? mAssets[i].amountOfATotal : mAssetAmount;
            uint adjustedAmountBTotal = mAssets[i].amountOfBTotal < ustAmount ? mAssets[i].amountOfBTotal : ustAmount;
            mAssets[i].amountOfATotal = mAssets[i].amountOfATotal.sub(adjustedAmountATotal);
            mAssets[i].amountOfBTotal = mAssets[i].amountOfBTotal.sub(adjustedAmountBTotal);

            // mAsset -> UST on Uniswap
            path[0] = address(mAssets[i].mAssetToken);
            path[1] = address(ust);
            uint256[] memory amounts =
                router.swapExactTokensForTokens(
                    mAssetAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
            // UST -> principalToken on Uniswap
            curveFi.exchange_underlying(0, curveIds[address(_token)], amounts[1].add(ustAmount), 0);

            userTotalLPToken[mAssets[i].lpToken] = userTotalLPToken[mAssets[i].lpToken].sub(amounOfLpTokenToRemove);

            
        }

        withdrawFromMirUstPool(_amount, valueInPool, false);
        _token.safeTransfer(msg.sender, _token.balanceOf(address(this)));
    }

    function withdrawFromMirUstPool(uint _amount, uint _valueInPool, bool _withdrawAll) internal {
        
        if(reInvestedMirUstPooltoken != 0) {  
    
            address[] memory path = new address[](2);
            uint amountToWithdraw;
            path[0] = address(mir);
            path[1] = address(ust);
 
           
            //_withdrawAll is true only during emergencyWIthdraw and migrateFunds.
            if(_withdrawAll == true) {
                amountToWithdraw = reInvestedMirUstPooltoken;
                mirustPool.getReward();
            } else {
                amountToWithdraw = reInvestedMirUstPooltoken.mul(_amount).div(_valueInPool);
                amountToWithdraw = amountToWithdraw > reInvestedMirUstPooltoken ? reInvestedMirUstPooltoken : amountToWithdraw;
            }           
            
            mirustPool.withdraw(amountToWithdraw);
            
                    router.removeLiquidity(
                        address(mir),
                        address(ust),
                        amountToWithdraw, 
                        0,
                        0,
                        address(this),
                        block.timestamp
                    );

            router.swapExactTokensForTokens(
                        mir.balanceOf(address(this)),
                        0,
                        path,
                        address(this),
                        block.timestamp
                    );

            reInvestedMirUstPooltoken = reInvestedMirUstPooltoken.sub(amountToWithdraw);
        }



    }

    /** @notice This function reinvests the farmed MIR into varioud pools
     */
    function yield() external onlyVault{
        uint256 totalEarnedMIR;
        address[] memory path = new address[](2);
        for (uint256 i = 0; i < mAssets.length; i++) {        
            
            //no incentive on mFB-UST farm
            if(address(mAssets[i].lpPool) != address(0)) {
                uint earnedMIR = mAssets[i].lpPool.earned(address(this));
                if(earnedMIR != 0) {
                    path[0] = address(mir);
                    path[1] = address(ust);
                    mAssets[i].lpPool.getReward();

                    totalEarnedMIR = totalEarnedMIR.add(earnedMIR);
                    //45% of MIR is used in MIR-UST farm. Convert half of MIR(22.5%) to UST 
                    //router.swapExactTokensForTokens(earnedMIR.mul(2250).div(10000), 0, path, address(this), block.timestamp);

                    //45 - MIRUST farm, 10 - to wallet, remaining 45 (22.5 UST, 22.5 mAsset)

                    //22.5(mirUst) + 22.5(mAssetUST)
                    uint[] memory amounts = router.swapExactTokensForTokens(earnedMIR.mul(450).div(1000), 0, path, address(this), block.timestamp);
                    uint _ustAmount = amounts[1].div(2);
                    path[1] = address(mAssets[i].mAssetToken);

                    //22.5% mir to mAsset
                    uint _mirAmount = earnedMIR.mul(2250).div(10000);

                    //pair doesn;t exists for some tokens
                    if(factory.getPair(address(mir), address(mAssets[i].mAssetToken)) == address(0)) {
                        address[] memory pathTemp = new address[](3);
                        uint[] memory amountsTemp ; 
                        pathTemp[0] = address(mir);
                        pathTemp[1] = address(ust);
                        pathTemp[2] = address(mAssets[i].mAssetToken);
                        amountsTemp = router.swapExactTokensForTokens(_mirAmount, 0, pathTemp, address(this), block.timestamp);  
                        amounts[1] = amountsTemp[2];
                    } else {
                        amounts = router.swapExactTokensForTokens(_mirAmount, 0, path, address(this), block.timestamp);
                    }
                    

                    (,,uint poolTokenAmount) = router.addLiquidity(address(mAssets[i].mAssetToken), address(ust), amounts[1], _ustAmount, 0, 0, address(this), block.timestamp);
                    mAssets[i].lpPool.stake(poolTokenAmount);

                    userTotalLPToken[mAssets[i].lpToken] = userTotalLPToken[mAssets[i].lpToken].add(poolTokenAmount);
                    mAssets[i].amountOfATotal = mAssets[i].amountOfATotal.add(amounts[1]);
                    mAssets[i].amountOfBTotal = mAssets[i].amountOfBTotal.add(_ustAmount);
                }
            }
        }

        totalEarnedMIR = totalEarnedMIR.add(mirustPool.earned(address(this)));
        mirustPool.getReward();
        if(totalEarnedMIR > 0) {
            mir.safeTransfer(treasuryWallet, totalEarnedMIR.div(10));//10 % 
                
            (,, uint poolTokenAmount) = router.addLiquidity(address(mir), address(ust), mir.balanceOf(address(this)), ust.balanceOf(address(this)), 0, 0, address(this), block.timestamp);
            mirustPool.stake(poolTokenAmount);

            reInvestedMirUstPooltoken = reInvestedMirUstPooltoken.add(poolTokenAmount);
        }

        
    }

    /**
        @param weights Percentage of mAssets - 750 means 7.5
        @dev Used to change the percentage of funds allocated to each pool
     */
    function reBalance(uint[] memory weights) external onlyOwner{
        require(weights.length == mAssets.length, "Weight length mismatch");
        uint _weightsSum;
        for(uint i=0; i<weights.length; i++) {
            mAsset memory _masset = mAssets[i];
            _masset.weight = weights[i];
            mAssets[i] = _masset;      
            _weightsSum = _weightsSum.add(weights[i]);
        }

        require(_weightsSum == 5000, "Invalid weights percentages"); //50% mAssets 50% UST
    }

    function withdrawAllFunds(IERC20 _tokenToConvert) external onlyVault {

        address[] memory path = new address[](2);
        path[1] = address(ust);
        for(uint i=0; i<mAssets.length; i++) {
            uint amounOfLpTokenToRemove = mAssets[i].lpToken.balanceOf(address(this));

            if(address(mAssets[i].lpPool) != address(0)) {
                mAssets[i].lpPool.getReward(); //withdraw rewards
                //tokens are in mirror's lpPool contract
                amounOfLpTokenToRemove = mAssets[i].lpPool.balanceOf(address(this));
                if(amounOfLpTokenToRemove != 0) {
                    mAssets[i].lpPool.withdraw(amounOfLpTokenToRemove);

                }
            }
            
            if(amounOfLpTokenToRemove != 0) {
                (uint256 mAssetAmount, ) = router.removeLiquidity(address(mAssets[i].mAssetToken), address(ust),amounOfLpTokenToRemove, 0, 0, address(this), block.timestamp);
                path[0] = address(mAssets[i].mAssetToken);
            
                router.swapExactTokensForTokens(
                    mAssetAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );    

                //setting value to zero , since all amounts are withdrawn
                mAssets[i].amountOfATotal = 0;
                mAssets[i].amountOfBTotal = 0;
                userTotalLPToken[mAssets[i].lpToken] = 0;
            }
        
        }
        withdrawFromMirUstPool(0,0, true);

        uint mirWithdrawn = mir.balanceOf(address(this));
        if(mirWithdrawn > 0) {
            path[0] = address(mir);
            router.swapExactTokensForTokens(mirWithdrawn, 0, path, address(this), block.timestamp);
        }

        if(ust.balanceOf(address(this)) != 0) {
            curveFi.exchange_underlying(0, curveIds[address(_tokenToConvert)], ust.balanceOf(address(this)), 0);
            _tokenToConvert.safeTransfer(address(vault), _tokenToConvert.balanceOf(address(this)));
        }
        
    }

    function setVault (address _vault) external onlyOwner{
        require(vault == address(0), "Cannot set vault");
        vault = _vault;
    }


    /**
        @dev amount of mAsset multiplied by price of mAssetInUst
        @return value Returns the value of all funds in all pools (in terms of UST)
     */
    function getTotalValueInPool() public view returns (uint256 value) {
        //get price of mAsset interms of UST
        //value = (amountOfmAsset*priceInUst) + amountOfUST
        address[] memory path = new address[](2);
        for (uint256 i = 0; i < mAssets.length; i++) {
            
            path[0] = address(mAssets[i].mAssetToken);
            path[1] = address(ust);
            uint[] memory priceInUst = router.getAmountsOut(1e18, path);
            
            value = value.add((priceInUst[1].mul(mAssets[i].amountOfATotal)).div(1e18)).add(mAssets[i].amountOfBTotal);
            
        }
        
        //get value of tokens in mirust pool
        (uint mirAmount, uint ustAmount) = calculateAmountWithdrawable(reInvestedMirUstPooltoken);
        
        if(mirAmount > 0) {
            path[0] = address(mir);
            path[1] = address(ust);
            value = value.add(router.getAmountsOut(mirAmount, path)[1]).add(ustAmount);
            //cacluate amount of mir+ust using reInvestedMirUstPooltoken. add to value
        }
        

    }

    /**
        @notice Function to calculate the amount of LPTokens needs to be removed from uniswap.
        @param _lpToken Address of uniswapPool
        @param _amount Amount of tokens needs to be withdrawn
        @param _valueInPool TotalValue in Pool
        @return amounOfLpTokenToRemove Amount of LPTokens to be removed from pool, to get the targetted amount.
       */

    function getDataFromLPPool(address _lpToken, uint _amount, uint _valueInPool) internal view returns (uint amounOfLpTokenToRemove){

        uint lpTokenBalance = userTotalLPToken[IERC20(_lpToken)];        

        amounOfLpTokenToRemove = lpTokenBalance.mul(_amount).div(_valueInPool);
        amounOfLpTokenToRemove = amounOfLpTokenToRemove > lpTokenBalance ? lpTokenBalance : amounOfLpTokenToRemove;
        
    }

    /**
        @dev Function to calculate the amount to tokens that will be received from MIRUST pool, when a specific amount of LPTokens are removed 
        @param _lpTokenAmount Amount of uniswap LPTokens
        @return amountMIR amount of MIR that will be received
        @return amountUST amount of UST that will be received
     */
    function calculateAmountWithdrawable(uint _lpTokenAmount) internal view returns(uint amountMIR , uint amountUST) {
        //get reserves
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(mirustPairAddress).getReserves();
        uint totalLpTOkenSupply = IUniswapV2Pair(mirustPairAddress).totalSupply();
        
        amountMIR = _lpTokenAmount.mul(reserve0).div(totalLpTOkenSupply);
        amountUST = _lpTokenAmount.mul(reserve1).div(totalLpTOkenSupply);

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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.7.4;


interface ILPPool {
    //================== Callers ==================//
    //function mir() external view returns (IERC20);
    function balanceOf(address account) external view returns (uint256);

    function startTime() external view returns (uint256);

    function totalReward() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    //================== Transactors ==================//

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function exit() external;

    function getReward() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

interface ICurveFi {

  function get_virtual_price() external view returns (uint256);
  function get_dy(
    int128 i,
    int128 j,
    uint256 dx
  ) external view returns (uint256);

  function get_dy_underlying(
    int128 i,
    int128 j,
    uint256 dx
  ) external view returns (uint256);

  function coins(int128 arg0) external view returns (address);

  function underlying_coins(int128 arg0) external view returns (address);

  function balances(int128 arg0) external view returns (uint256);

  function add_liquidity(
    uint256[2] calldata amounts,
    uint256 deadline
  ) external;

  function exchange(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
    //uint256 deadline
  ) external returns (uint256);

  function exchange_underlying(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external returns (uint256);

  function remove_liquidity(
    uint256 _amount,
    uint256 deadline,
    uint256[2] calldata min_amounts
  ) external;

  function remove_liquidity_imbalance(
    uint256[2] calldata amounts,
    uint256 deadline
  ) external;
}

pragma solidity 0.7.6;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

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

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}