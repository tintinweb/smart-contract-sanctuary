/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface CErc20 {
    function mint(uint256) external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function repayBorrow(uint256) external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint);

    function balanceOfUnderlying(address account) external returns (uint);

    function exchangeRateCurrent() external returns (uint);
    function borrowBalanceStored(address) external view returns (uint);
}

interface ComptrollerInterface {
    /**
     * @notice Marker function used for light validation when updating the comptroller of a market
     * @dev Implementations should simply return true.
     * @return true
     */
    function isComptroller() external view returns (bool);
    //close factor is the maximum percentage of borrowed tokens that can be repayed
    function closeFactorMantissa() external view returns(uint);
    //liquidation incentive is your incentive amount to liquidate the contract
    function liquidationIncentiveMantissa() external view returns(uint);
    function getAccountLiquidity(address account) external view returns (uint, uint, uint);
    //function liquidateCalculateSeizeTokens(address cTokenBorrowed, address cTokenCollateral, uint actualRepayAmount) external view returns (uint, uint);
    function liquidateBorrow(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) external returns (uint);

    function claimComp(address holder) external;
    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cToken) external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address cToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(address cToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address cToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address cToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address cToken, address borrower, uint borrowAmount) external returns (uint);
    function borrowVerify(address cToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);
    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) external;

    function liquidateBorrowAllowed(
        address liquidator,
        address borrower,
        uint repayAmount) external view returns (bool);
    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);
    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address cToken, address src, address dst, uint transferTokens) external returns (uint);
    function transferVerify(address cToken, address src, address dst, uint transferTokens) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount) external view returns (uint, uint);
        
    function updateContributorRewards(address contributor) external;
    function getBlockNumber() external view returns (uint);
}

interface CTokenInterface {
    

    /*** User Interface ***/

    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);


    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint);
    function _acceptAdmin() external returns (uint);
    function _setComptroller(ComptrollerInterface newComptroller) external returns (uint);
    function _setReserveFactor(uint newReserveFactorMantissa) external returns (uint);
    function _reduceReserves(uint reduceAmount) external returns (uint);
    //function _setInterestRateModel(InterestRateModel newInterestRateModel) public returns (uint);
}

interface ICounter {
    function cTokenBorrowed() external view returns(address[] memory);
    //function liquidator() external view returns(address[] memory);
    function borrowerArray() external view returns(address[] memory);
    //function repayAmount() external view returns(uint);
    function liquidateBorrow(address borrower, uint repayAmount) external view returns (bool);
    function borrowBalanceStored(address) external view returns (uint);
}

contract CounterResolver {
    address public immutable POC;
    ComptrollerInterface CompTroller;
    CErc20 cUSDC;
    constructor(address _poc){
        POC = _poc;
        CompTroller = ComptrollerInterface(0xcfa7b0e37f5AC60f3ae25226F5e39ec59AD26152);
    }
    
    function checker(address[] calldata borrowerArr) external view returns (bool canExec, bytes memory execPayload)
    {   
        canExec = false;
        address borrowerToLiquidate;
        uint repayAmount;
        address liquidator = address(this);
        address[] memory borrower = ICounter(POC).borrowerArray();
        for (uint i = 0; i < borrower.length; i++){
            uint closeFactorMantissa = CompTroller.closeFactorMantissa();
            uint borrowBalance = ICounter(POC).borrowBalanceStored(borrower[i]);
            repayAmount = ((closeFactorMantissa * borrowBalance) / 10**18) -1 ;
        if (CompTroller.liquidateBorrowAllowed(liquidator,borrower[i], repayAmount)) {
            borrowerToLiquidate = borrower[i];
            if(borrowerToLiquidate != address(0)) {
            canExec = true ;
            break;
             }}}
        execPayload = abi.encodeWithSelector(ICounter.liquidateBorrow.selector,address(borrowerToLiquidate), uint(repayAmount));
        return (canExec, execPayload); 
    }
}