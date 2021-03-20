pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface Uniswap_Router_Interface {
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable returns (uint256[] memory amounts);
    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadlin) external returns (uint256[] memory amounts);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function WETH() external returns (address);
}

interface IERC20_Interface {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface WETH_Interface {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function deposit() external payable;
    function withdraw(uint wad) external;
}

contract ArbExecutorBlueprint {
    address public Uniswap_Router_Address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public WETH_Address = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;

    Uniswap_Router_Interface Uniswap_Router;
    WETH_Interface WETH;

    //SETUP OWNER ADDRESS VARIABLE
    address payable public owner;

    event Received(address, uint256);

    constructor() payable {
        owner = msg.sender; //Setup owner value
        Uniswap_Router = Uniswap_Router_Interface(Uniswap_Router_Address);
        WETH = WETH_Interface(WETH_Address);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function ST1OP1(address token, uint256 amountIn) public {

        uint256 startGas = gasleft();


        uint256 out1 = Uniswap_EthToToken(token, amountIn, 1);
        uint out2 = Uniswap_TokenToEth(token, out1, 1);

        //require(out2 > amountIn, "Arbitrage operation was no longer available!");

        uint256 gasUsed = startGas - gasleft();


    }

    //UNISWAP: ETH -> TOKEN
    function Uniswap_EthToToken(address token, uint256 amountIn, uint256 amountOutMin) public payable returns (uint256 amountOut) {
        address[] memory path = new address[](2);
        uint256 deadline = block.timestamp + 600; //10 Minutes

        path[0] = Uniswap_Router.WETH();
        path[1] = token;

        uint256[] memory amounts = Uniswap_Router.swapExactETHForTokens{value: amountIn}(
            amountOutMin, //MINIMUM TOKENS
            path,
            address(this),
            deadline
        );

        return amounts[amounts.length-1];

    }

    //UNISWAP: TOKEN -> ETH
    function Uniswap_TokenToEth(address token, uint256 amountIn, uint256 amountOutMin) public payable returns (uint256 amountOut) {
        require(
            IERC20_Interface(token).approve(address(Uniswap_Router), (amountIn + 100000)),
            "Smart contract approval failed"
        );
        address[] memory path = new address[](2);
        uint256 deadline = block.timestamp + 600;

        path[0] = token;
        path[1] = WETH_Address;

        uint256[] memory amounts = Uniswap_Router.swapExactTokensForETH(
            amountIn,
            amountOutMin, //MIN FIXED TO 1 FOR TESTING
            path,
            address(this),
            deadline
        );

        return amounts[amounts.length-1];
    }

function Uniswap_TokenToToken(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin) public payable returns (uint256 amountOut) {
        require(
            IERC20_Interface(tokenIn).approve(address(Uniswap_Router), (amountIn + 100000)),
            "Smart contract approval failed"
        );
        address[] memory path = new address[](2);
        uint256 deadline = block.timestamp + 600;

        path[0] = tokenIn;
        path[1] = tokenOut;

        uint256[] memory amounts = Uniswap_Router.swapExactTokensForTokens(
            amountIn,
            amountOutMin, //MIN FIXED TO 1 FOR TESTING
            path,
            address(this),
            deadline
        );

        return amounts[amounts.length-1];
}

    function drain() external {
        owner.transfer(address(this).balance);
    }

    function byebye() public {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
        selfdestruct(msg.sender);
    }


}