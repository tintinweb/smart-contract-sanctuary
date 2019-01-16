pragma solidity ^0.5.2;

contract ERC20 {
    // ERC20 comaptibility for liquidity tokens
    bytes32 public name;
    bytes32 public symbol;
    uint256 public decimals;
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
}

contract UniswapFactoryInterface {
    // Public Variables
    address public exchangeTemplate;
    uint256 public tokenCount;
    // Create Exchange
    function createExchange(address token) external returns (address exchange);
    // Get Exchange and Token Info
    function getExchange(address token) external view returns (address exchange);
    function getToken(address exchange) external view returns (address token);
    function getTokenWithId(uint256 tokenId) external view returns (address token);
    // Never use
    function initializeFactory(address template) external;
}

contract UniswapExchangeInterface is ERC20 {
    // Address of ERC20 token sold on this exchange
    function tokenAddress() external view returns (address token);
    // Address of Uniswap Factory
    function factoryAddress() external view returns (address factory);
    // Provide Liquidity
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256 tokens_sold);
    // Trade ETH to ERC20
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns (uint256  tokens_bought);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns (uint256  eth_sold);
    function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256  eth_sold);
    // Trade ERC20 to ETH
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256  eth_bought);
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_tokens, uint256 deadline, address recipient) external returns (uint256  eth_bought);
    function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) external returns (uint256  tokens_sold);
    function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256  tokens_sold);
    // Trade ERC20 to ERC20
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address token_addr) external returns (uint256  tokens_sold);
    function tokenToTokenTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_sold);
    // Trade ERC20 to Custom Pool
    function tokenToExchangeSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address exchange_addr) external returns (uint256  tokens_sold);
    function tokenToExchangeTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_sold);
    // Never use
    function setup(address token_addr) external;
}

contract Unipay {
    UniswapFactoryInterface factory;
    ERC20 outputToken;
    address recipient;

    constructor(address _factory, address _recipient, address _token) public {
        factory = UniswapFactoryInterface(_factory);
        outputToken = ERC20(_token);
        recipient = _recipient;
    }

    function price(
        address inputToken,
        uint256 outputAmount
    ) public view returns (uint256, uint256) {
        UniswapExchangeInterface inExchange =
            UniswapExchangeInterface(factory.getExchange(inputToken));
        UniswapExchangeInterface outExchange =
            UniswapExchangeInterface(factory.getExchange(address(outputToken)));
        uint256 etherCost = outExchange.getEthToTokenOutputPrice(outputAmount);
        uint256 tokenCost = inExchange.getTokenToEthOutputPrice(etherCost);
        return (tokenCost, etherCost);
    }

    function collect(
        address spender,
        address inputToken,
        uint256 outputAmount,
        uint256 deadline
    ) public {
        UniswapExchangeInterface inExchange =
            UniswapExchangeInterface(factory.getExchange(inputToken));
        (uint256 tokenCost, uint256 etherCost) =
            price(inputToken, outputAmount);
        uint256 oldBalance = ERC20(inputToken).balanceOf(address(this));
        require(
            ERC20(inputToken).transferFrom(spender, address(this), tokenCost),
            "Failed to transfer input tokens in."
        );
        require(
            ERC20(inputToken).balanceOf(address(this)) >= oldBalance + tokenCost,
            "Balance validation failed after transfer."
        );
        oldBalance = outputToken.balanceOf(address(this));
        inExchange.tokenToTokenSwapOutput(
            outputAmount,
            tokenCost,
            etherCost,
            deadline,
            address(outputToken)
        );
        require(
            outputToken.balanceOf(address(this)) >= oldBalance + outputAmount,
            "Balance validation failed after swap."
        );
        oldBalance = outputToken.allowance(address(this), recipient);
        require(
            outputToken.approve(recipient, oldBalance + outputAmount),
            "Failed to approve funds for recipient."
        );
        require(
            outputToken.allowance(address(this), recipient) > oldBalance,
            "Allowance validation failed after approval. "
        );
    }
}