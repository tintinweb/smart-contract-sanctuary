// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "../Context.sol";
import "../Libraries.sol";

contract FBGSwapper is Operator {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public basisCash;
    IERC20 public basisGovernance;

    address public cashDestoryAddress;

    //circle
    uint256 public startTime = 1614614400;

    //swaper config
    uint256 totalLevelCount = 100;
    uint256 FBGCountPerLevel = 10000;
    uint256 totalFBGCount = totalLevelCount * FBGCountPerLevel;
    uint256 initialSwapRate = 1000; //1000/10000
    uint256 increaseSwapRatePerLevel = 1000; //  1000/10000

    //status
    uint256 currentSwapRate = initialSwapRate;
    uint256 currentLevel = 1; //start from 1 to 100
    uint256 currentLeftFBGCountInLevel = FBGCountPerLevel;
    //sum
    uint256 swapFBGCount = 0;
    uint256 swapFBCCount = 0;

    //event
    event SwapSuccessed(
        address indexed user,
        uint256 fbcCount,
        uint256 fbgCount
    );

    constructor(address basisCash_, address basisGovernance_) public {
        basisCash = IERC20(basisCash_);
        basisGovernance = IERC20(basisGovernance_);
    }

    modifier checkStart() {
        require(block.timestamp >= startTime, "FBGSwapper: not start");
        _;
    }

    function swap(uint256 fbcCount) external checkStart {

        require(fbcCount>0,"FBGSwapper fbc count must > 0");

        uint256 fbgCount;
        uint256 newLevel;
        uint256 newRate;
        uint256 newFBGLeftInLevel;

        (fbgCount, newLevel, newRate, newFBGLeftInLevel) = _caculateSwap(
            fbcCount
        );

        uint256 caculateTotalFBG = swapFBGCount.add(fbgCount);
        require(caculateTotalFBG <= totalFBGCount, "fbg is not enough");

        /////////////////////do swap

        //change status
        currentSwapRate = newRate;
        currentLevel = newLevel;
        currentLeftFBGCountInLevel = newFBGLeftInLevel;

        swapFBGCount = swapFBGCount.add(fbgCount);
        swapFBCCount = swapFBCCount.add(fbcCount);

        //transfer
        basisGovernance.safeTransfer(msg.sender, fbgCount);
        basisCash.safeTransfer(cashDestoryAddress, fbcCount);

        //event
        emit SwapSuccessed(msg.sender, fbcCount, fbgCount);
    }

    function _caculateSwap(uint256 fbcCount)
        public
        view 
        returns (
            uint256 fbgCount,
            uint256 newLevel,
            uint256 newRate,
            uint256 newFBGLeftInLevel
        )
    {
        uint256 destFBGCount = 0;
        uint256 avaliableFBCCount = fbcCount;

        uint256 tmpLevel = currentLevel;
        uint256 tmpRate = currentSwapRate;
        uint256 tmpLeftFBGCountInlevel = currentLeftFBGCountInLevel;

        while (avaliableFBCCount > 0) {
            uint256 leftAvaliableFBCCountInLevel =
                tmpLeftFBGCountInlevel.mul(tmpRate).div(10000);
            uint256 currentFbgCount = 0;
            //current level engouh
            if (leftAvaliableFBCCountInLevel >= avaliableFBCCount) {
                currentFbgCount = avaliableFBCCount.mul(10000).div(tmpRate);
                avaliableFBCCount = 0;
                tmpLeftFBGCountInlevel = tmpLeftFBGCountInlevel.sub(
                    currentFbgCount
                );
            } else {
                //need upgrade to next level
                currentFbgCount = leftAvaliableFBCCountInLevel.mul(10000).div(
                    tmpRate
                );
                avaliableFBCCount = avaliableFBCCount.sub(
                    leftAvaliableFBCCountInLevel
                );

                tmpLevel++;
                tmpRate = tmpRate.add(increaseSwapRatePerLevel);
            }

            destFBGCount = destFBGCount.add(currentFbgCount);
        }

        fbgCount = destFBGCount;
        newLevel = tmpLevel;
        newRate = tmpRate;
        newFBGLeftInLevel = tmpLeftFBGCountInlevel;
    }

    function queryInfo()
        public
        view
        returns (
            uint256 _swappedFBGCount,
            uint256 _avaliableFBGCount,
            uint256 _totalFBGCount,
            uint256 _swappedFBCCount,
            uint256 _swapRate,
            uint256 _currentLevel,
            uint256 _leftCountInLevel
        )
    {
        _swappedFBGCount = swapFBGCount;
        _avaliableFBGCount = totalFBGCount.sub(swapFBGCount);
        _totalFBGCount = totalFBGCount;
        _swappedFBCCount = swapFBCCount;
        _swapRate = currentSwapRate;
        _currentLevel = currentLevel;
        _leftCountInLevel = currentLeftFBGCountInLevel;
    }
}