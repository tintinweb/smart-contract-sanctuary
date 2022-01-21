/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

pragma solidity ^0.7.2;

interface ISwap {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address tokenOwner) external view returns (uint balance);

    function transfer(address _to, uint256 _value) external returns (bool success);
}

contract TestAddLiquidity {

    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal constant SUSHISWAP_ROUTER_ADDRESS = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address internal constant UNISWAP_FACTORY_ADDRESS = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address internal constant UNISWAP_PAIR_ADRESS = 0x0D52297D95F66f7069C1B5fA48897a33Bf72dB36;
    address internal constant SUSHISWAP_PAIR_ADRESS = 0x81aaAc709ACA097970409d9579824c1F8541e5Bf;
    address internal constant TOKEN_ADRESS = 0xfb5caC4c3130Fb7EbbeD98c3B9ad0AD59d0Ce340;
    uint public UNISWAP_PERSENTAGE = 70;
    uint public SUSHISWAP_PERSENTAGE = 30;
    uint public MAXIMUM_BUFER = 14000000000000000;
    uint public MINIMUM_CASH = 5000000000000000;
    uint public REWARD_PERCENTAGE = 5;
    uint public current_balance_eth;
    uint public current_balance_tok;
    uint public bufferETH;
    uint public bufferTOK;
    uint public cashETH;
    uint public cashTOK;
    uint public uniswapLP;
    uint public sushiswapLP;

    mapping(address => uint) public balances;
    ISwap public uniswap;
    ISwap public sushiswap;

    constructor() public {
        sushiswap = ISwap(SUSHISWAP_ROUTER_ADDRESS);
        uniswap = ISwap(UNISWAP_ROUTER_ADDRESS);
    }

    function updateBalance(uint newBalance, address sender) private {
        balances[sender] = balances[sender] + newBalance;
    }

    function send_tokens_investment(uint amountToken, uint amountETH, address to) external payable {
        current_balance_eth += amountETH;
        current_balance_tok += amountToken;
        updateBalance(amountETH, to);
        if (cashETH < MINIMUM_CASH) {
            uint cashETHAddition = MINIMUM_CASH - cashETH;
            cashETH += cashETHAddition;
            cashTOK += (amountToken/amountETH) * cashETHAddition;
            amountToken -= (amountToken/amountETH) * cashETHAddition;
            amountETH -= cashETHAddition;
        }
        bufferETH += amountETH;
        bufferTOK += amountToken;
        if (bufferETH >= MAXIMUM_BUFER) {
            uint uniswapValueTok = (bufferTOK * UNISWAP_PERSENTAGE)/100;
            uint sushiswapValueTok = bufferTOK - uniswapValueTok;
            uint uniswapValueETH = (bufferETH * UNISWAP_PERSENTAGE)/100;
            uint sushiswapValueETH = bufferETH - uniswapValueETH;
            IERC20(TOKEN_ADRESS).approve(UNISWAP_ROUTER_ADDRESS, uniswapValueTok);
            (,,uint liquidityUniswap) = uniswap.addLiquidityETH{value : uniswapValueETH}(
                TOKEN_ADRESS,
                uniswapValueTok,
                uniswapValueTok,
                uniswapValueETH,
                address(this),
                block.timestamp + 300
            );
            uniswapLP+=liquidityUniswap;
            IERC20(TOKEN_ADRESS).approve(SUSHISWAP_ROUTER_ADDRESS, sushiswapValueTok);
            (,,uint liquiditySushiswap) = sushiswap.addLiquidityETH{value : sushiswapValueETH}(
                TOKEN_ADRESS,
                sushiswapValueTok,
                sushiswapValueTok,
                sushiswapValueETH,
                address(this),
                block.timestamp + 300
            );
            sushiswapLP += liquiditySushiswap;
            bufferETH -= uniswapValueETH + sushiswapValueETH;
            bufferTOK -= uniswapValueTok + sushiswapValueTok;
            current_balance_eth -= uniswapValueETH + sushiswapValueETH;
            current_balance_tok -= uniswapValueTok + sushiswapValueTok;
        }
    }

    function retrieve_tokens(uint amountTok, uint amountETH) internal {
        IERC20(UNISWAP_PAIR_ADRESS).approve(UNISWAP_ROUTER_ADDRESS, IERC20(UNISWAP_PAIR_ADRESS).balanceOf(address(this)));
        (uint amountUniswapToken,uint amountUniswapETH) = uniswap.removeLiquidityETH(TOKEN_ADRESS, IERC20(UNISWAP_PAIR_ADRESS).balanceOf(address(this)), 0, 0, address(this), block.timestamp + 300);
        IERC20(SUSHISWAP_PAIR_ADRESS).approve(SUSHISWAP_ROUTER_ADDRESS, IERC20(SUSHISWAP_PAIR_ADRESS).balanceOf(address(this)));
        (uint amountSushiswapToken,uint amountSushiswapETH)=sushiswap.removeLiquidityETH(TOKEN_ADRESS, IERC20(SUSHISWAP_PAIR_ADRESS).balanceOf(address(this)), 0, 0, address(this), block.timestamp + 300);
        current_balance_eth += amountUniswapETH + amountSushiswapETH;
        current_balance_tok += amountSushiswapToken + amountUniswapToken;
        cashETH += amountUniswapETH + amountSushiswapETH;
        cashTOK += amountSushiswapToken + amountUniswapToken;
    }

    function send_tokens_to_investors(uint amountTok, uint amountETH, address payable to) external {
        require(balances[to] > amountETH, "No enough balance to retreive tokens");
        balances[to] = balances[to] - amountETH;
        if(cashETH < amountETH) {
            retrieve_tokens(amountTok, amountETH);
        }
        current_balance_eth -= amountETH;
        current_balance_tok -= amountTok;
        cashETH -= amountETH;
        cashTOK -= amountTok;
        to.transfer(amountETH);
        IERC20(TOKEN_ADRESS).transfer(to, amountTok);
    }

    function set_reward_percentage(uint percentage) public {
        require(percentage >= 100, "Percent cant be more than 100");
        REWARD_PERCENTAGE = percentage;
    }

    function set_new_percentages(uint percentageUniswap, uint percentageSushiswap) public {
        require(percentageSushiswap + percentageUniswap != 100, "Sum of percentages must be 100%");
        SUSHISWAP_PERSENTAGE = percentageSushiswap;
        UNISWAP_PERSENTAGE = percentageUniswap;
    }

    function set_maximum_buffer(uint new_buffer) public {
        MAXIMUM_BUFER = new_buffer;
    }

    function set_minimum_cash(uint new_cash) public {
        MINIMUM_CASH = new_cash;
    }

    receive() payable external {}

}