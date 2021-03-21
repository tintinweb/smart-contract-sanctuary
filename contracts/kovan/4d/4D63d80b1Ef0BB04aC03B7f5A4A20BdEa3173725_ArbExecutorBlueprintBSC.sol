pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface Uniswap_Router_Interface {
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable returns (uint256[] memory amounts);
    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
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
    function withdraw(uint256 wad) external;
}

contract ArbExecutorBlueprintBSC {
    address public Uniswap_Router_Address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public WETH_Address = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;

    Uniswap_Router_Interface Uniswap_Router;
    WETH_Interface WETH;

    //SECURITY
    //SETUP OWNER ADDRESS VARIABLE
    address payable public owner;
    mapping(address => bool) public operatorsMap;
    address[] public operators;

    event Received(address, uint256);
    event FinalEthOut(uint256);
    event SwapDebugger(address, uint256);

    struct Operation {
        address[] tokens;
        uint256[] minOuts;
    }

    constructor() payable {
        owner = msg.sender; //Setup owner value
        Uniswap_Router = Uniswap_Router_Interface(Uniswap_Router_Address);
        WETH = WETH_Interface(WETH_Address);
        operatorsMap[msg.sender] = true;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function ST4(Operation memory _operation, uint256 amountIn) public onlyOps {
        uint256 out1 =
            Uniswap_EthToToken(_operation.tokens[1], amountIn, _operation.minOuts[0]);
        uint256 tempOut = out1;

        for (uint256 i = 1; i < (_operation.tokens.length - 2); i++) {
            uint256 newOut =
                Uniswap_TokenToToken(_operation.tokens[i], _operation.tokens[i + 1], tempOut, _operation.minOuts[i]);
            tempOut = newOut;
        }

        uint256 finalOut =
            Uniswap_TokenToEth(_operation.tokens[_operation.tokens.length - 2], tempOut, _operation.minOuts[_operation.minOuts.length - 1]);
        emit FinalEthOut(finalOut);
    }

    //UNISWAP: ETH -> TOKEN
    function Uniswap_EthToToken(address token, uint256 amountIn, uint256 amountOutMin) public onlyOps payable returns (uint256 amountOut) {
        address[] memory path = new address[](2);
        uint256 deadline = block.timestamp + 600; //10 Minutes

        path[0] = Uniswap_Router.WETH();
        path[1] = token;

        uint256[] memory amounts = Uniswap_Router.swapExactETHForTokens{value: amountIn} (amountOutMin, path, address(this), deadline);

        return amounts[amounts.length - 1];
    }

    //UNISWAP: TOKEN -> ETH
    function Uniswap_TokenToEth(address token, uint256 amountIn, uint256 amountOutMin) public onlyOps payable returns (uint256 amountOut) {
        require(
            IERC20_Interface(token).approve(
                address(Uniswap_Router),
                (amountIn + 100000)
            ),
            "Smart contract approval failed"
        );

        address[] memory path = new address[](2);
        uint256 deadline = block.timestamp + 600;

        path[0] = token;
        path[1] = WETH_Address;

        uint256[] memory amounts = Uniswap_Router.swapExactTokensForETH(amountIn, amountOutMin, path, address(this), deadline);

        return amounts[amounts.length - 1];
    }

    function Uniswap_TokenToToken(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin) public onlyOps payable returns (uint256 amountOut) {
        require(
            IERC20_Interface(tokenIn).approve(
                address(Uniswap_Router),
                (amountIn + 100000)
            ),
            "Smart contract approval failed"
        );
        address[] memory path = new address[](2);
        uint256 deadline = block.timestamp + 600;

        path[0] = tokenIn;
        path[1] = tokenOut;

        uint256[] memory amounts = Uniswap_Router.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);

        return amounts[amounts.length - 1];
    }

    //SECURITY

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyOps {
        require(operatorsMap[msg.sender] == true);
        _;
    }

    function addOperator(address operatorAddress) public onlyOwner {
        operatorsMap[operatorAddress] = true;
        operators.push(operatorAddress);
    }
    
    function removeOperator(address operatorAddress) public onlyOwner {
        operatorsMap[operatorAddress] = false;
    }

    function resetOperators() public onlyOwner {
        for(uint i=0; i<operators.length; i++) {
            operatorsMap[operators[i]] = false;
        }
        delete operators;
    }

    function drain() external onlyOwner{
        owner.transfer(address(this).balance);
    }

    function byebye() public onlyOwner{
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
        selfdestruct(msg.sender);
    }
}