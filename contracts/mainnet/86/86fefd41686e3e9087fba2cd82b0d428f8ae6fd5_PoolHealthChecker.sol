/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

// SPDX-License-Identifier:  AGPL-3.0-or-later // hevm: flattened sources of contracts/PoolHealthChecker.sol
pragma solidity =0.8.7 >=0.8.7 <0.9.0;

////// contracts/interfaces/Interfaces.sol
/* pragma solidity 0.8.7; */

interface IPoolLike {

    function claim(address loan_, address dlFactory_) external returns (uint256[7] memory claimInfo_);

    function debtLockers(address loan_, address dlFactory_) external returns (address debtLockers_);

    function deposit(uint256 amount_) external;

    function fundLoan(address loan_, address debtLockerFactory_, uint256 amount_) external;

    function interestSum() external view returns (uint256 interestSum_);

    function liquidityAsset() external view returns (address liquidityAsset_);

    function liquidityCap() external view returns (uint256 liquidityCap_);

    function liquidityLocker() external view returns (address liquidityLocker_);

    function poolLosses() external view returns (uint256 poolLossess_);

    function principalOut() external view returns (uint256 principalOut_);

    function setLiquidityCap(uint256 liquidityCap_) external;

    function totalSupply() external view returns (uint256 totalSupply_);

    function triggerDefault(address loan_, address dlFactory_) external;

}

////// modules/erc20/src/interfaces/IERC20.sol
/* pragma solidity ^0.8.7; */

/// @title Interface of the ERC20 standard as defined in the EIP.
interface IERC20 {

    /**
     * @dev   Emits an event indicating that tokens have moved from one account to another.
     * @param owner_     Account that tokens have moved from.
     * @param recipient_ Account that tokens have moved to.
     * @param amount_    Amount of tokens that have been transferred.
     */
    event Transfer(address indexed owner_, address indexed recipient_, uint256 amount_);

    /**
     * @dev   Emits an event indicating that one account has set the allowance of another account over their tokens.
     * @param owner_   Account that tokens are approved from.
     * @param spender_ Account that tokens are approved for.
     * @param amount_  Amount of tokens that have been approved.
     */
    event Approval(address indexed owner_, address indexed spender_, uint256 amount_);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory name_);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory symbol_);

    /**
     * @dev Returns the decimal precision used by the token.
     */
    function decimals() external view returns (uint8 decimals_);

    /**
     * @dev Returns the total amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256 totalSupply_);

    /**
     * @dev   Returns the amount of tokens owned by a given account.
     * @param account_ Account that owns the tokens.
     */
    function balanceOf(address account_) external view returns (uint256 balance_);

    /**
     * @dev   Function that returns the allowance that one account has given another over their tokens.
     * @param owner_   Account that tokens are approved from.
     * @param spender_ Account that tokens are approved for.
     */
    function allowance(address owner_, address spender_) external view returns (uint256 allowance_);

    /**
     * @dev    Function that allows one account to set the allowance of another account over their tokens.
     *         Emits an {Approval} event.
     * @param  spender_ Account that tokens are approved for.
     * @param  amount_  Amount of tokens that have been approved.
     * @return success_ Boolean indicating whether the operation succeeded.
     */
    function approve(address spender_, uint256 amount_) external returns (bool success_);

    /**
     * @dev    Moves an amount of tokens from `msg.sender` to a specified account.
     *         Emits a {Transfer} event.
     * @param  recipient_ Account that receives tokens.
     * @param  amount_    Amount of tokens that are transferred.
     * @return success_   Boolean indicating whether the operation succeeded.
     */
    function transfer(address recipient_, uint256 amount_) external returns (bool success_);

    /**
     * @dev    Moves a pre-approved amount of tokens from a sender to a specified account.
     *         Emits a {Transfer} event.
     *         Emits an {Approval} event.
     * @param  owner_     Account that tokens are moving from.
     * @param  recipient_ Account that receives tokens.
     * @param  amount_    Amount of tokens that are transferred.
     * @return success_   Boolean indicating whether the operation succeeded.
     */
    function transferFrom(address owner_, address recipient_, uint256 amount_) external returns (bool success_);

}

////// contracts/PoolHealthChecker.sol
/* pragma solidity 0.8.7; */

/* import { IERC20 } from "../modules/erc20/src/interfaces/IERC20.sol"; */

/* import { IPoolLike } from "./interfaces/Interfaces.sol"; */

contract PoolHealthChecker {

    uint256 constant WAD = 10 ** 18;

    /**
     * @dev   Pool accounting invariant, to be checked by smart contract monitoring tools.
     * @param pool_ The address of the pool.
     * @return      isMaintained_ Invariant result.
    */
    function poolAccountingInvariant(address pool_) external view returns (
        bool isMaintained_,
        uint256 fdtTotalSupply_,
        uint256 interestSum_,
        uint256 poolLosses_,
        uint256 liquidityLockerBal_,
        uint256 principalOut_
    ) {
        // Pool Accounting Law: fdtTotalSupply + interestSum - poolLosses <= liquidityLockerBal + principalOut.
        IPoolLike pool = IPoolLike(pool_);

        IERC20 liquidityAsset = IERC20(pool.liquidityAsset());
        uint256 liquidityAssetDecimals = liquidityAsset.decimals();

        fdtTotalSupply_ = pool.totalSupply() * (10 ** liquidityAssetDecimals) / WAD;
        interestSum_    = pool.interestSum();
        poolLosses_     = pool.poolLosses();

        liquidityLockerBal_ = liquidityAsset.balanceOf(pool.liquidityLocker());
        principalOut_       = pool.principalOut();

        isMaintained_ = fdtTotalSupply_ + interestSum_ - poolLosses_ <= liquidityLockerBal_ + principalOut_;
    }

}