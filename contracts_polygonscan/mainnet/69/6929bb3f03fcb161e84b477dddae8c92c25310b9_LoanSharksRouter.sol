/**
 *Submitted for verification at polygonscan.com on 2022-01-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


interface QuickSwapRouter{
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract LoanSharksRouter{

    //Contract manager
    address _validator;

    //Arbitrarily long deadline ~ 3 years
    uint internal base_deadline = 10**8; 

    //QuickSwap Router
    address public QSR = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;

    //USDC Address
    address public USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    uint public USDC_DECIMALS = 6;

    //MATIC Address
    address public wMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    uint public MATIC_DECIMALS = 18;

    //QuickSwap Paths
    address[] internal USDC_MATIC_PATH = new address[](2);
    address[] internal MATIC_USDC_PATH = new address[](2);

    //In case of contract failure
    bool public functional = true;

    constructor(){
        _validator = msg.sender;
        USDC_MATIC_PATH[0] = USDC;
        USDC_MATIC_PATH[1] = wMATIC;
        MATIC_USDC_PATH[0] = wMATIC;
        MATIC_USDC_PATH[1] = USDC;
    }   

    function get_usd_matic_rate() public view onlyLive returns(uint){
        return QuickSwapRouter(QSR).getAmountsOut(
            (1)*(10**USDC_DECIMALS),
            USDC_MATIC_PATH
        )[1];
    }

     function get_matic_usd_rate() public view onlyLive returns(uint){
        return QuickSwapRouter(QSR).getAmountsOut(
            (1)*(10**MATIC_DECIMALS),
            MATIC_USDC_PATH
        )[1];
    }

    function swap(address receiver, uint amount_usdc, uint max_drawdown_wei) public onlyLive onlyApproved(msg.sender, amount_usdc) returns(uint[] memory){
        uint deadline = block.timestamp + base_deadline;
        address[] memory path = new address[](2);
        path[0] = address(USDC);
        path[1] = address(wMATIC);
        uint minMaticOut = (QuickSwapRouter(QSR).getAmountsOut(
            amount_usdc, 
            USDC_MATIC_PATH
        )[1])-max_drawdown_wei;
        return QuickSwapRouter(QSR).swapExactTokensForETH(
            amount_usdc,
            minMaticOut,
            USDC_MATIC_PATH,
            receiver,
            deadline
        );
    }

    //Toggle usability of the contract in case of bugs/exploits
    function toggle_live() public onlyValidator{
        functional = !functional;
    }

    //Check for USDC-Quickswap Approval
    function check_for_usdc_approval(address user) public view onlyLive returns(uint){
        return IERC20(USDC).allowance(user, QSR);
    }

    //USDC-Quickswap Approval Modifier
    modifier onlyApproved(address sender, uint amount) {
        require(IERC20(USDC).allowance(sender, QSR) >= amount, "Lacking allowance.");
        _;
    }


    //Functionality modifier
    modifier onlyLive() {
        require(functional, "Contract not live.");
        _;
    }

    //Validator modifier for  changing contract state
    modifier onlyValidator() {
        require(_validator == msg.sender, "Validator only.");
        _;
    }
}