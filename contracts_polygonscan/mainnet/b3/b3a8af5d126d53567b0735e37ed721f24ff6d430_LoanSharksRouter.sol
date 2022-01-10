/**
 *Submitted for verification at polygonscan.com on 2022-01-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

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
    uint internal BASE_DEADLINE = 10**8; 

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
            SafeMath.mul((1),(10**USDC_DECIMALS)),
            USDC_MATIC_PATH
        )[1];
    }

     function get_matic_usd_rate() public view onlyLive returns(uint){
        return QuickSwapRouter(QSR).getAmountsOut(
            SafeMath.mul((1),(10**MATIC_DECIMALS)),
            MATIC_USDC_PATH
        )[1];
    }

    function swap(address receiver, uint amount_usdc, uint max_drawdown_wei) public onlyLive returns(uint[] memory){
        uint deadline = SafeMath.add(block.timestamp, BASE_DEADLINE);
        address[] memory path = new address[](2);
        path[0] = address(USDC);
        path[1] = address(wMATIC);
        IERC20(USDC).transferFrom(msg.sender, address(this), amount_usdc);
        uint minMaticOut = SafeMath.sub((QuickSwapRouter(QSR).getAmountsOut(
            amount_usdc, 
            USDC_MATIC_PATH
        )[1]),max_drawdown_wei);
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

    //Check for USDC-LSR Approval
    function check_for_usdc_approval(address user) public view onlyLive returns(uint){
        return IERC20(USDC).allowance(user, address(this));
    }

    //Set Contract Allowance
    function set_contract_allowance(uint amount) public onlyLive onlyValidator returns(bool){
        return IERC20(USDC).approve(QSR, amount);
    }

    //USDC-LSR Approval Modifier
    modifier onlyApproved(address sender, uint amount) {
        require(IERC20(USDC).allowance(sender, address(this)) >= amount, "Lacking allowance.");
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