/**
 *Submitted for verification at Etherscan.io on 2020-11-18
*/

/**
 *Submitted for verification at Etherscan.io on 2020-07-21
*/

pragma solidity ^0.6.0;

interface DMEX {
    function availableBalanceOf(address token, address user) external view returns (uint256);
    function withdraw(address token, uint256 amount) external returns (bool success);
}

interface UniswapV2ExchangeInterface {
    function WETH() external pure returns (address);

    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

/* Interface for ERC20 Tokens */
interface DMEXTokenInterface {
    function burn(uint256 _value) external returns (bool success);
}

// The DMEX Fee Contract
contract DMEX_Fee_Contract {    

    address DMEX_CONTRACT = address(0x2101e480e22C953b37b9D0FE6551C1354Fe705E6);
    address DMEX_TOKEN = address(0x6263e260fF6597180c9538c69aF8284EDeaCEC80);

    address TOKEN_ETH = address(0x0000000000000000000000000000000000000000);
    address TOKEN_DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address TOKEN_BTC = address(0x5228a22e72ccC52d415EcFd199F99D0665E7733b);

    address uniswapRouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address payable FEE_ACCOUNT;
    address owner;

    uint256 fee_account_share = 618e15;
    uint256 uniswap_share = 382e15;
    
    event Log(uint8 indexed errorId, uint value);

    function extractFees() public {
        uint256 fee_share; 
        uint256 us_share;

        // extract eth
        uint256 eth_balance = DMEX(DMEX_CONTRACT).availableBalanceOf(TOKEN_ETH, address(this));
        
        emit Log(1, eth_balance);
        
        require(DMEX(DMEX_CONTRACT).withdraw(TOKEN_ETH, eth_balance), "Error: failed to withdraw");

        // fee_share = safeMul(eth_balance, fee_account_share) / 1e18;
        // us_share = safeSub(eth_balance, fee_share);        
        
        // emit Log(2, fee_share);
        // emit Log(3, us_share);

        // require(FEE_ACCOUNT.send(fee_share), "Error: eth send failed");

        // // swap eth for DMEX Token
        // address[] memory path = new address[](2);
        // path[0] = UniswapV2ExchangeInterface(uniswapRouter).WETH();
        // path[1] = DMEX_TOKEN;

        // uint[] memory amounts = UniswapV2ExchangeInterface(uniswapRouter).swapExactETHForTokens.value(us_share)(1, path, address(this), 2**256 - 1);
    
        // uint token_bought = amounts[1];
        // DMEXTokenInterface(DMEX_TOKEN).burn(token_bought);

    }

    constructor(
        address payable  initialFeeAccount
    ) public {
        owner = msg.sender;
        FEE_ACCOUNT = initialFeeAccount;
    }


    /** Safe Math **/

    // Safe Multiply Function - prevents integer overflow 
    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    // Safe Subtraction Function - prevents integer overflow 
    function safeSub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    // Safe Addition Function - prevents integer overflow 
    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}