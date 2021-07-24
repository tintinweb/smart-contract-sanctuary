pragma solidity ^0.7.6;

/**
 * @title Liquity.
 * @dev Lending & Borrowing.
 */
import {
    BorrowerOperationsLike,
    TroveManagerLike,
    StabilityPoolLike,
    StakingLike,
    CollateralSurplusLike,
    LqtyTokenLike
} from "./interface.sol";
import { Stores } from "../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract LiquityResolver is Events, Helpers {


    /* Begin: Trove */

    /**
     * @dev Deposit native ETH and borrow LUSD
     * @notice Opens a Trove by depositing ETH and borrowing LUSD
     * @param depositAmount The amount of ETH to deposit
     * @param maxFeePercentage The maximum borrow fee that this transaction should permit 
     * @param borrowAmount The amount of LUSD to borrow
     * @param upperHint Address of the Trove near the upper bound of where the user's Trove should now sit in the ordered Trove list
     * @param lowerHint Address of the Trove near the lower bound of where the user's Trove should now sit in the ordered Trove list
     * @param getIds Optional (default: 0) Optional storage slot to get deposit & borrow amounts stored using other spells
     * @param setIds Optional (default: 0) Optional storage slot to set deposit & borrow amounts to be used in future spells
    */
    function open(
        uint depositAmount,
        uint maxFeePercentage,
        uint borrowAmount,
        address upperHint,
        address lowerHint,
        uint[] memory getIds,
        uint[] memory setIds
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {

        depositAmount = getUint(getIds[0], depositAmount);
        borrowAmount = getUint(getIds[1], borrowAmount);

        depositAmount = depositAmount == uint(-1) ? address(this).balance : depositAmount;

        borrowerOperations.openTrove{value: depositAmount}(
            maxFeePercentage,
            borrowAmount,
            upperHint,
            lowerHint
        );

        setUint(setIds[0], depositAmount);
        setUint(setIds[1], borrowAmount);

        _eventName = "LogOpen(address,uint256,uint256,uint256,uint256[],uint256[])";
        _eventParam = abi.encode(address(this), maxFeePercentage, depositAmount, borrowAmount, getIds, setIds);
    }

    /**
     * @dev Repay LUSD debt from the DSA account's LUSD balance, and withdraw ETH to DSA
     * @notice Closes a Trove by repaying LUSD debt
     * @param setId Optional storage slot to store the ETH withdrawn from the Trove
    */
    function close(uint setId) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint collateral = troveManager.getTroveColl(address(this));
        borrowerOperations.closeTrove();

        // Allow other spells to use the collateral released from the Trove
        setUint(setId, collateral);
         _eventName = "LogClose(address,uint256)";
        _eventParam = abi.encode(address(this), setId);
    }

    /**
     * @dev Deposit ETH to Trove
     * @notice Increase Trove collateral (collateral Top up)
     * @param amount Amount of ETH to deposit into Trove
     * @param upperHint Address of the Trove near the upper bound of where the user's Trove should now sit in the ordered Trove list
     * @param lowerHint Address of the Trove near the lower bound of where the user's Trove should now sit in the ordered Trove list
     * @param getId Optional storage slot to retrieve the ETH from
     * @param setId Optional storage slot to set the ETH deposited
    */
    function deposit(
        uint amount,
        address upperHint,
        address lowerHint,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam)  {

        uint _amount = getUint(getId, amount);

        _amount = _amount == uint(-1) ? address(this).balance : _amount;

        borrowerOperations.addColl{value: _amount}(upperHint, lowerHint);

        setUint(setId, _amount);

        _eventName = "LogDeposit(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(this), _amount, getId, setId);
    }

    /**
     * @dev Withdraw ETH from Trove
     * @notice Move Trove collateral from Trove to DSA
     * @param amount Amount of ETH to move from Trove to DSA
     * @param upperHint Address of the Trove near the upper bound of where the user's Trove should now sit in the ordered Trove list
     * @param lowerHint Address of the Trove near the lower bound of where the user's Trove should now sit in the ordered Trove list
     * @param getId Optional storage slot to get the amount of ETH to withdraw
     * @param setId Optional storage slot to store the withdrawn ETH in
    */
   function withdraw(
        uint amount,
        address upperHint,
        address lowerHint,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam)  {
        uint _amount = getUint(getId, amount);

        _amount = _amount == uint(-1) ? troveManager.getTroveColl(address(this)) : _amount;

        borrowerOperations.withdrawColl(_amount, upperHint, lowerHint);

        setUint(setId, _amount);
        _eventName = "LogWithdraw(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(this), _amount, getId, setId);
    }
    
    /**
     * @dev Mints LUSD tokens
     * @notice Borrow LUSD via an existing Trove
     * @param maxFeePercentage The maximum borrow fee that this transaction should permit 
     * @param amount Amount of LUSD to borrow
     * @param upperHint Address of the Trove near the upper bound of where the user's Trove should now sit in the ordered Trove list
     * @param lowerHint Address of the Trove near the lower bound of where the user's Trove should now sit in the ordered Trove list
     * @param getId Optional storage slot to retrieve the amount of LUSD to borrow
     * @param setId Optional storage slot to store the final amount of LUSD borrowed
    */
    function borrow(
        uint maxFeePercentage,
        uint amount,
        address upperHint,
        address lowerHint,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam)  {
        uint _amount = getUint(getId, amount);

        borrowerOperations.withdrawLUSD(maxFeePercentage, _amount, upperHint, lowerHint);

        setUint(setId, _amount);

        _eventName = "LogBorrow(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(this), _amount, getId, setId);
    }

    /**
     * @dev Send LUSD to repay debt
     * @notice Repay LUSD Trove debt
     * @param amount Amount of LUSD to repay
     * @param upperHint Address of the Trove near the upper bound of where the user's Trove should now sit in the ordered Trove list
     * @param lowerHint Address of the Trove near the lower bound of where the user's Trove should now sit in the ordered Trove list
     * @param getId Optional storage slot to retrieve the amount of LUSD from
     * @param setId Optional storage slot to store the final amount of LUSD repaid
    */
    function repay(
        uint amount,
        address upperHint,
        address lowerHint,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam)  {
        uint _amount = getUint(getId, amount);

        if (_amount == uint(-1)) {
            uint _lusdBal = lusdToken.balanceOf(address(this));
            uint _totalDebt = troveManager.getTroveDebt(address(this));
            _amount = _lusdBal > _totalDebt ? _totalDebt : _lusdBal;
        }

        borrowerOperations.repayLUSD(_amount, upperHint, lowerHint);

        setUint(setId, _amount);

        _eventName = "LogRepay(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(this), _amount, getId, setId);
    }

    /**
     * @dev Increase or decrease Trove ETH collateral and LUSD debt in one transaction
     * @notice Adjust Trove debt and/or collateral
     * @param maxFeePercentage The maximum borrow fee that this transaction should permit 
     * @param withdrawAmount Amount of ETH to withdraw
     * @param depositAmount Amount of ETH to deposit
     * @param borrowAmount Amount of LUSD to borrow
     * @param repayAmount Amount of LUSD to repay
     * @param upperHint Address of the Trove near the upper bound of where the user's Trove should now sit in the ordered Trove list
     * @param lowerHint Address of the Trove near the lower bound of where the user's Trove should now sit in the ordered Trove list
     * @param getIds Optional Get Ids for deposit, withdraw, borrow & repay
     * @param setIds Optional Set Ids for deposit, withdraw, borrow & repay
    */
    function adjust(
        uint maxFeePercentage,
        uint depositAmount,
        uint withdrawAmount,
        uint borrowAmount,
        uint repayAmount,
        address upperHint,
        address lowerHint,
        uint[] memory getIds,
        uint[] memory setIds
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        AdjustTrove memory adjustTrove;

        adjustTrove.maxFeePercentage = maxFeePercentage;

        depositAmount = getUint(getIds[0], depositAmount);
        adjustTrove.depositAmount = depositAmount == uint(-1) ? address(this).balance : depositAmount;

        withdrawAmount = getUint(getIds[1], withdrawAmount);
        adjustTrove.withdrawAmount = withdrawAmount == uint(-1) ? troveManager.getTroveColl(address(this)) : withdrawAmount;

        adjustTrove.borrowAmount = getUint(getIds[2], borrowAmount);

        repayAmount = getUint(getIds[3], repayAmount);
        if (repayAmount == uint(-1)) {
            uint _lusdBal = lusdToken.balanceOf(address(this));
            uint _totalDebt = troveManager.getTroveDebt(address(this));
            repayAmount = _lusdBal > _totalDebt ? _totalDebt : _lusdBal;
        }
        adjustTrove.repayAmount = repayAmount;

        adjustTrove.isBorrow = borrowAmount > 0;

        borrowerOperations.adjustTrove{value: adjustTrove.depositAmount}(
            adjustTrove.maxFeePercentage,
            adjustTrove.withdrawAmount,
            adjustTrove.borrowAmount,
            adjustTrove.isBorrow,
            upperHint,
            lowerHint
        );
        
        setUint(setIds[0], adjustTrove.depositAmount);
        setUint(setIds[1], adjustTrove.withdrawAmount);
        setUint(setIds[2], adjustTrove.borrowAmount);
        setUint(setIds[3], adjustTrove.repayAmount);

        _eventName = "LogAdjust(address,uint256,uint256,uint256,uint256,uint256,uint256[],uint256[])";
        _eventParam = abi.encode(address(this), maxFeePercentage, adjustTrove.depositAmount, adjustTrove.withdrawAmount, adjustTrove.borrowAmount, adjustTrove.repayAmount, getIds, setIds);
    }

    /**
     * @dev Withdraw remaining ETH balance from user's redeemed Trove to their DSA
     * @param setId Optional storage slot to store the ETH claimed
     * @notice Claim remaining collateral from Trove
    */
    function claimCollateralFromRedemption(uint setId) external payable returns(string memory _eventName, bytes memory _eventParam) {
        uint amount = collateralSurplus.getCollateral(address(this));
        borrowerOperations.claimCollateral();
        setUint(setId, amount);

        _eventName = "LogClaimCollateralFromRedemption(address,uint256,uint256)";
        _eventParam = abi.encode(address(this), amount, setId);
    }
    /* End: Trove */

    /* Begin: Stability Pool */

    /**
     * @dev Deposit LUSD into Stability Pool
     * @notice Deposit LUSD into Stability Pool
     * @param amount Amount of LUSD to deposit into Stability Pool
     * @param frontendTag Address of the frontend to make this deposit against (determines the kickback rate of rewards)
     * @param getDepositId Optional storage slot to retrieve the amount of LUSD from
     * @param setDepositId Optional storage slot to store the final amount of LUSD deposited
     * @param setEthGainId Optional storage slot to store any ETH gains in
     * @param setLqtyGainId Optional storage slot to store any LQTY gains in
    */
    function stabilityDeposit(
        uint amount,
        address frontendTag,
        uint getDepositId,
        uint setDepositId,
        uint setEthGainId,
        uint setLqtyGainId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        amount = getUint(getDepositId, amount);

        amount = amount == uint(-1) ? lusdToken.balanceOf(address(this)) : amount;

        uint ethGain = stabilityPool.getDepositorETHGain(address(this));
        uint lqtyBalanceBefore = lqtyToken.balanceOf(address(this));
        
        stabilityPool.provideToSP(amount, frontendTag);
        
        uint lqtyBalanceAfter = lqtyToken.balanceOf(address(this));
        uint lqtyGain = sub(lqtyBalanceAfter, lqtyBalanceBefore);

        setUint(setDepositId, amount);
        setUint(setEthGainId, ethGain);
        setUint(setLqtyGainId, lqtyGain);

        _eventName = "LogStabilityDeposit(address,uint256,uint256,uint256,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(this), amount, ethGain, lqtyGain, frontendTag, getDepositId, setDepositId, setEthGainId, setLqtyGainId);
    }

    /**
     * @dev Withdraw user deposited LUSD from Stability Pool
     * @notice Withdraw LUSD from Stability Pool
     * @param amount Amount of LUSD to withdraw from Stability Pool
     * @param getWithdrawId Optional storage slot to retrieve the amount of LUSD to withdraw from
     * @param setWithdrawId Optional storage slot to store the withdrawn LUSD
     * @param setEthGainId Optional storage slot to store any ETH gains in
     * @param setLqtyGainId Optional storage slot to store any LQTY gains in
    */
    function stabilityWithdraw(
        uint amount,
        uint getWithdrawId,
        uint setWithdrawId,
        uint setEthGainId,
        uint setLqtyGainId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        amount = getUint(getWithdrawId, amount);

        amount = amount == uint(-1) ? stabilityPool.getCompoundedLUSDDeposit(address(this)) : amount;

        uint ethGain = stabilityPool.getDepositorETHGain(address(this));
        uint lqtyBalanceBefore = lqtyToken.balanceOf(address(this));
        
        stabilityPool.withdrawFromSP(amount);
        
        uint lqtyBalanceAfter = lqtyToken.balanceOf(address(this));
        uint lqtyGain = sub(lqtyBalanceAfter, lqtyBalanceBefore);

        setUint(setWithdrawId, amount);
        setUint(setEthGainId, ethGain);
        setUint(setLqtyGainId, lqtyGain);

        _eventName = "LogStabilityWithdraw(address,uint256,uint256,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(this), amount, ethGain, lqtyGain, getWithdrawId, setWithdrawId, setEthGainId, setLqtyGainId);
    }

    /**
     * @dev Increase Trove collateral by sending Stability Pool ETH gain to user's Trove
     * @notice Moves user's ETH gain from the Stability Pool into their Trove
     * @param upperHint Address of the Trove near the upper bound of where the user's Trove should now sit in the ordered Trove list
     * @param lowerHint Address of the Trove near the lower bound of where the user's Trove should now sit in the ordered Trove list
    */
    function stabilityMoveEthGainToTrove(
        address upperHint,
        address lowerHint
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint amount = stabilityPool.getDepositorETHGain(address(this));
        stabilityPool.withdrawETHGainToTrove(upperHint, lowerHint);
        _eventName = "LogStabilityMoveEthGainToTrove(address,uint256)";
        _eventParam = abi.encode(address(this), amount);
    }
    /* End: Stability Pool */

    /* Begin: Staking */

    /**
     * @dev Sends LQTY tokens from user to Staking Pool
     * @notice Stake LQTY in Staking Pool
     * @param amount Amount of LQTY to stake
     * @param getStakeId Optional storage slot to retrieve the amount of LQTY to stake
     * @param setStakeId Optional storage slot to store the final staked amount (can differ if requested with max balance: uint(-1))
     * @param setEthGainId Optional storage slot to store any ETH gains
     * @param setLusdGainId Optional storage slot to store any LUSD gains
    */
    function stake(
        uint amount,
        uint getStakeId,
        uint setStakeId,
        uint setEthGainId,
        uint setLusdGainId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        amount = getUint(getStakeId, amount);
        amount = amount == uint(-1) ? lqtyToken.balanceOf(address(this)) : amount;

        uint ethGain = staking.getPendingETHGain(address(this));
        uint lusdGain = staking.getPendingLUSDGain(address(this));

        staking.stake(amount);
        setUint(setStakeId, amount);
        setUint(setEthGainId, ethGain);
        setUint(setLusdGainId, lusdGain);

        _eventName = "LogStake(address,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(this), amount, getStakeId, setStakeId, setEthGainId, setLusdGainId);
    }

    /**
     * @dev Sends LQTY tokens from Staking Pool to user
     * @notice Unstake LQTY in Staking Pool
     * @param amount Amount of LQTY to unstake
     * @param getUnstakeId Optional storage slot to retrieve the amount of LQTY to unstake
     * @param setUnstakeId Optional storage slot to store the unstaked LQTY
     * @param setEthGainId Optional storage slot to store any ETH gains
     * @param setLusdGainId Optional storage slot to store any LUSD gains
    */
    function unstake(
        uint amount,
        uint getUnstakeId,
        uint setUnstakeId,
        uint setEthGainId,
        uint setLusdGainId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        amount = getUint(getUnstakeId, amount);
        amount = amount == uint(-1) ? staking.stakes(address(this)) : amount;

        uint ethGain = staking.getPendingETHGain(address(this));
        uint lusdGain = staking.getPendingLUSDGain(address(this));

        staking.unstake(amount);
        setUint(setUnstakeId, amount);
        setUint(setEthGainId, ethGain);
        setUint(setLusdGainId, lusdGain);

        _eventName = "LogUnstake(address,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(this), amount, getUnstakeId, setUnstakeId, setEthGainId, setLusdGainId);
    }

    /**
     * @dev Sends ETH and LUSD gains from Staking to user
     * @notice Claim ETH and LUSD gains from Staking
     * @param setEthGainId Optional storage slot to store the claimed ETH
     * @param setLusdGainId Optional storage slot to store the claimed LUSD
    */
    function claimStakingGains(
        uint setEthGainId,
        uint setLusdGainId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint ethGain = staking.getPendingETHGain(address(this));
        uint lusdGain = staking.getPendingLUSDGain(address(this));

        // Gains are claimed when a user's stake is adjusted, so we unstake 0 to trigger the claim
        staking.unstake(0);
        setUint(setEthGainId, ethGain);
        setUint(setLusdGainId, lusdGain);
        
        _eventName = "LogClaimStakingGains(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(this), ethGain, lusdGain, setEthGainId, setLusdGainId);
    }
    /* End: Staking */

}

contract ConnectV2Liquity is LiquityResolver {
    string public name = "Liquity-v1";
}

pragma solidity ^0.7.6;

interface BorrowerOperationsLike {
    function openTrove(
        uint256 _maxFee,
        uint256 _LUSDAmount,
        address _upperHint,
        address _lowerHint
    ) external payable;

    function addColl(address _upperHint, address _lowerHint) external payable;

    function withdrawColl(
        uint256 _amount,
        address _upperHint,
        address _lowerHint
    ) external;

    function withdrawLUSD(
        uint256 _maxFee,
        uint256 _amount,
        address _upperHint,
        address _lowerHint
    ) external;

    function repayLUSD(
        uint256 _amount,
        address _upperHint,
        address _lowerHint
    ) external;

    function closeTrove() external;

    function adjustTrove(
        uint256 _maxFee,
        uint256 _collWithdrawal,
        uint256 _debtChange,
        bool isDebtIncrease,
        address _upperHint,
        address _lowerHint
    ) external payable;

    function claimCollateral() external;
}

interface TroveManagerLike {
    function getTroveColl(address _borrower) external view returns (uint);
    function getTroveDebt(address _borrower) external view returns (uint);
}

interface StabilityPoolLike {
    function provideToSP(uint _amount, address _frontEndTag) external;
    function withdrawFromSP(uint _amount) external;
    function withdrawETHGainToTrove(address _upperHint, address _lowerHint) external;
    function getDepositorETHGain(address _depositor) external view returns (uint);
    function getDepositorLQTYGain(address _depositor) external view returns (uint);
    function getCompoundedLUSDDeposit(address _depositor) external view returns (uint);
}

interface StakingLike {
    function stake(uint _LQTYamount) external;
    function unstake(uint _LQTYamount) external;
    function getPendingETHGain(address _user) external view returns (uint);
    function getPendingLUSDGain(address _user) external view returns (uint);
    function stakes(address owner) external view returns (uint);
}

interface CollateralSurplusLike { 
    function getCollateral(address _account) external view returns (uint);
}

interface LqtyTokenLike {
    function balanceOf(address account) external view returns (uint256);
}

pragma solidity ^0.7.0;

import { MemoryInterface, InstaMapping } from "./interfaces.sol";


abstract contract Stores {

  /**
   * @dev Return ethereum address
   */
  address constant internal ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /**
   * @dev Return Wrapped ETH address
   */
  address constant internal wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  /**
   * @dev Return memory variable address
   */
  MemoryInterface constant internal instaMemory = MemoryInterface(0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F);

  /**
   * @dev Return InstaDApp Mapping Addresses
   */
  InstaMapping constant internal instaMapping = InstaMapping(0xe81F70Cc7C0D46e12d70efc60607F16bbD617E88);

  /**
   * @dev Get Uint value from InstaMemory Contract.
   */
  function getUint(uint getId, uint val) internal returns (uint returnVal) {
    returnVal = getId == 0 ? val : instaMemory.getUint(getId);
  }

  /**
  * @dev Set Uint value in InstaMemory Contract.
  */
  function setUint(uint setId, uint val) virtual internal {
    if (setId != 0) instaMemory.setUint(setId, val);
  }

}

pragma solidity ^0.7.6;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";

import { TokenInterface } from "../../common/interfaces.sol";

import {
    BorrowerOperationsLike,
    TroveManagerLike,
    StabilityPoolLike,
    StakingLike,
    CollateralSurplusLike,
    LqtyTokenLike
} from "./interface.sol";

abstract contract Helpers is DSMath, Basic {

    BorrowerOperationsLike internal constant borrowerOperations = BorrowerOperationsLike(0x24179CD81c9e782A4096035f7eC97fB8B783e007);
    TroveManagerLike internal constant troveManager = TroveManagerLike(0xA39739EF8b0231DbFA0DcdA07d7e29faAbCf4bb2);
    StabilityPoolLike internal constant stabilityPool = StabilityPoolLike(0x66017D22b0f8556afDd19FC67041899Eb65a21bb);
    StakingLike internal constant staking = StakingLike(0x4f9Fbb3f1E99B56e0Fe2892e623Ed36A76Fc605d);
    CollateralSurplusLike internal constant collateralSurplus = CollateralSurplusLike(0x3D32e8b97Ed5881324241Cf03b2DA5E2EBcE5521);
    LqtyTokenLike internal constant lqtyToken = LqtyTokenLike(0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D);
    TokenInterface internal constant lusdToken = TokenInterface(0x5f98805A4E8be255a32880FDeC7F6728C6568bA0);
    
    // Prevents stack-too-deep error
    struct AdjustTrove {
        uint maxFeePercentage;
        uint withdrawAmount;
        uint depositAmount;
        uint borrowAmount;
        uint repayAmount;
        bool isBorrow;
    }

}

pragma solidity ^0.7.6;

contract Events {

    /* Trove */
    event LogOpen(
        address indexed borrower,
        uint maxFeePercentage,
        uint depositAmount,
        uint borrowAmount,
        uint256[] getIds,
        uint256[] setIds
    );
    event LogClose(address indexed borrower, uint setId);
    event LogDeposit(address indexed borrower, uint amount, uint getId, uint setId);
    event LogWithdraw(address indexed borrower, uint amount, uint getId, uint setId);
    event LogBorrow(address indexed borrower, uint amount, uint getId, uint setId);
    event LogRepay(address indexed borrower, uint amount, uint getId, uint setId);
    event LogAdjust(
        address indexed borrower,
        uint maxFeePercentage,
        uint depositAmount,
        uint withdrawAmount,
        uint borrowAmount,
        uint repayAmount,
        uint256[] getIds,
        uint256[] setIds
    );
    event LogClaimCollateralFromRedemption(address indexed borrower, uint amount, uint setId);

    /* Stability Pool */
    event LogStabilityDeposit(
        address indexed borrower,
        uint amount,
        uint ethGain,
        uint lqtyGain,
        address frontendTag,
        uint getDepositId,
        uint setDepositId,
        uint setEthGainId,
        uint setLqtyGainId
    );
    event LogStabilityWithdraw(address indexed borrower,
        uint amount,
        uint ethGain,
        uint lqtyGain,
        uint getWithdrawId,
        uint setWithdrawId,
        uint setEthGainId,
        uint setLqtyGainId
    );
    event LogStabilityMoveEthGainToTrove(address indexed borrower, uint amount);

    /* Staking */
    event LogStake(address indexed borrower, uint amount, uint getStakeId, uint setStakeId, uint setEthGainId, uint setLusdGainId);
    event LogUnstake(address indexed borrower, uint amount, uint getUnstakeId, uint setUnstakeId, uint setEthGainId, uint setLusdGainId);
    event LogClaimStakingGains(address indexed borrower, uint ethGain, uint lusdGain, uint setEthGainId, uint setLusdGainId);
}

pragma solidity ^0.7.0;

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

interface MemoryInterface {
    function getUint(uint id) external returns (uint num);
    function setUint(uint id, uint val) external;
}

interface InstaMapping {
    function cTokenMapping(address) external view returns (address);
    function gemJoinMapping(bytes32) external view returns (address);
}

interface AccountInterface {
    function enable(address) external;
    function disable(address) external;
    function isAuth(address) external view returns (bool);
}

pragma solidity ^0.7.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

contract DSMath {
  uint constant WAD = 10 ** 18;
  uint constant RAY = 10 ** 27;

  function add(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(x, y);
  }

  function sub(uint x, uint y) internal virtual pure returns (uint z) {
    z = SafeMath.sub(x, y);
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.mul(x, y);
  }

  function div(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.div(x, y);
  }

  function wmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
  }

  function wdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
  }

  function rdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, RAY), y / 2) / y;
  }

  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), RAY / 2) / RAY;
  }

  function toInt(uint x) internal pure returns (int y) {
    y = int(x);
    require(y >= 0, "int-overflow");
  }

  function toRad(uint wad) internal pure returns (uint rad) {
    rad = mul(wad, 10 ** 27);
  }

}

pragma solidity ^0.7.0;

import { TokenInterface } from "./interfaces.sol";
import { Stores } from "./stores.sol";
import { DSMath } from "./math.sol";

abstract contract Basic is DSMath, Stores {

    function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }

    function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function getTokenBal(TokenInterface token) internal view returns(uint _amt) {
        _amt = address(token) == ethAddr ? address(this).balance : token.balanceOf(address(this));
    }

    function getTokensDec(TokenInterface buyAddr, TokenInterface sellAddr) internal view returns(uint buyDec, uint sellDec) {
        buyDec = address(buyAddr) == ethAddr ?  18 : buyAddr.decimals();
        sellDec = address(sellAddr) == ethAddr ?  18 : sellAddr.decimals();
    }

    function encodeEvent(string memory eventName, bytes memory eventParam) internal pure returns (bytes memory) {
        return abi.encode(eventName, eventParam);
    }

    function approve(TokenInterface token, address spender, uint256 amount) internal {
        try token.approve(spender, amount) {

        } catch {
            token.approve(spender, 0);
            token.approve(spender, amount);
        }
    }

    function changeEthAddress(address buy, address sell) internal pure returns(TokenInterface _buy, TokenInterface _sell){
        _buy = buy == ethAddr ? TokenInterface(wethAddr) : TokenInterface(buy);
        _sell = sell == ethAddr ? TokenInterface(wethAddr) : TokenInterface(sell);
    }

    function convertEthToWeth(bool isEth, TokenInterface token, uint amount) internal {
        if(isEth) token.deposit{value: amount}();
    }

    function convertWethToEth(bool isEth, TokenInterface token, uint amount) internal {
       if(isEth) {
            approve(token, address(token), amount);
            token.withdraw(amount);
        }
    }
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
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