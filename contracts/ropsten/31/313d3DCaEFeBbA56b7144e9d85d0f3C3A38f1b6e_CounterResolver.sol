/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

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
interface IOracle{
    function getUnderlyingPrice(address cToken) external view returns (uint);
}

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
}


interface ComptrollerInterface {
    /**
     * @notice Marker function used for light validation when updating the comptroller of a market
     * @dev Implementations should simply return true.
     * @return true
     */
    function isComptroller() external view returns (bool);

    function getAccountLiquidity(address account) external view returns (uint, uint, uint);
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
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint);
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
}
interface ICounter {
   // function bal() external view returns (uint);
    
    //function increaseCount(uint256 amount) external;
    function rebalance() external;
}

contract CounterResolver {
    address public immutable POC;
    //uint public lastExecuted = block.timestamp;
    CErc20 cUSDC;
    IERC20 usdc; 
    IOracle oracle;
    ComptrollerInterface CompTroller;
    //uint usdc = IERC20(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
    //uint cUSDC = 0x2973e69b20563bcc66dC63Bde153072c33eF37fe;
    //address oracle = IOracle(0x7bbf806f69ea21ea9b8af061ad0c1c41913063a1);
    //address CompTroller = ComptrollerInterface(0xcfa7b0e37f5AC60f3ae25226F5e39ec59AD26152);
    constructor(address _poc, address _usdc,address compt,address _oracle, address _cusdc) {
        POC = _poc;
        usdc = IERC20(_usdc);
        CompTroller = ComptrollerInterface(compt);
        oracle = IOracle(_oracle);
        cUSDC = CErc20(_cusdc);
        
    }

    function checker() external view returns (bool canExec, bytes memory execPayload)
    {
        uint min_depo =  1000000000000;
        bool canExec = false;
        uint bal = usdc.balanceOf(0x33D843Fc0b2a24483f007DbB8fd2383e8dFA4129);
        (uint error,uint liquidity,uint shortfall)=CompTroller.getAccountLiquidity(0x33D843Fc0b2a24483f007DbB8fd2383e8dFA4129);
        if(liquidity>0&&error==0&&shortfall==0){
        uint price = oracle.getUnderlyingPrice(address(cUSDC));
        uint borrowamt = (liquidity*10**18)/price;
        //cUSDC.borrow(borrowamt*80/100);
        bal+=borrowamt*80/100;

        //if ((block.timestamp - lastExecuted) > 20) {
    
        if (bal>min_depo) {
            canExec = true ;
        }}
        //canExec = true;
        execPayload = abi.encodeWithSelector(ICounter.rebalance.selector);
        return (canExec, execPayload);
    }
    function balance() external view returns(uint) {
        uint bal = usdc.balanceOf(0x33D843Fc0b2a24483f007DbB8fd2383e8dFA4129);
        return bal;
    }
}