/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

//dapp: https://etherscan.io/dapp/0x1603557c3f7197df2ecded659ad04fa72b1e1114#readContract
//

pragma solidity >=0.4.26;

contract UniswapExchangeInterface {
    // Address of ERC20 token sold on this exchange
    function tokenAddress() external view returns (address token);

    // Address of Uniswap Factory
    function factoryAddress() external view returns (address factory);

    // Provide Liquidity
    function addLiquidity(
        uint256 min_liquidity,
        uint256 max_tokens,
        uint256 deadline
    ) external payable returns (uint256);

    function removeLiquidity(
        uint256 amount,
        uint256 min_eth,
        uint256 min_tokens,
        uint256 deadline
    ) external returns (uint256, uint256);

    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold)
        external
        view
        returns (uint256 tokens_bought);

    function getEthToTokenOutputPrice(uint256 tokens_bought)
        external
        view
        returns (uint256 eth_sold);

    function getTokenToEthInputPrice(uint256 tokens_sold)
        external
        view
        returns (uint256 eth_bought);

    function getTokenToEthOutputPrice(uint256 eth_bought)
        external
        view
        returns (uint256 tokens_sold);

    // Trade ETH to ERC20
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline)
        external
        payable
        returns (uint256 tokens_bought);

    function ethToTokenTransferInput(
        uint256 min_tokens,
        uint256 deadline,
        address recipient
    ) external payable returns (uint256 tokens_bought);

    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline)
        external
        payable
        returns (uint256 eth_sold);

    function ethToTokenTransferOutput(
        uint256 tokens_bought,
        uint256 deadline,
        address recipient
    ) external payable returns (uint256 eth_sold);

    // Trade ERC20 to ETH
    function tokenToEthSwapInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline
    ) external returns (uint256 eth_bought);

    function tokenToEthTransferInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline,
        address recipient
    ) external returns (uint256 eth_bought);

    function tokenToEthSwapOutput(
        uint256 eth_bought,
        uint256 max_tokens,
        uint256 deadline
    ) external returns (uint256 tokens_sold);

    function tokenToEthTransferOutput(
        uint256 eth_bought,
        uint256 max_tokens,
        uint256 deadline,
        address recipient
    ) external returns (uint256 tokens_sold);

    // Trade ERC20 to ERC20
    function tokenToTokenSwapInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address token_addr
    ) external returns (uint256 tokens_bought);

    function tokenToTokenTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address recipient,
        address token_addr
    ) external returns (uint256 tokens_bought);

    function tokenToTokenSwapOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address token_addr
    ) external returns (uint256 tokens_sold);

    function tokenToTokenTransferOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address recipient,
        address token_addr
    ) external returns (uint256 tokens_sold);

    // Trade ERC20 to Custom Pool
    function tokenToExchangeSwapInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address exchange_addr
    ) external returns (uint256 tokens_bought);

    function tokenToExchangeTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address recipient,
        address exchange_addr
    ) external returns (uint256 tokens_bought);

    function tokenToExchangeSwapOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address exchange_addr
    ) external returns (uint256 tokens_sold);

    function tokenToExchangeTransferOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address recipient,
        address exchange_addr
    ) external returns (uint256 tokens_sold);

    // ERC20 comaptibility for liquidity tokens
    bytes32 public name;
    bytes32 public symbol;
    uint256 public decimals;

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 value
    ) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    // Never use
    function setup(address token_addr) external;
}

interface ERC20 {
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);

    function decimals() external view returns (uint256 digits);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

/// @title Kyber Network interface
interface KyberNetworkProxyInterface {
    function maxGasPrice() external view returns (uint256);

    function getUserCapInWei(address user) external view returns (uint256);

    function getUserCapInTokenWei(address user, ERC20 token)
        external
        view
        returns (uint256);

    function enabled() external view returns (bool);

    function info(bytes32 id) external view returns (uint256);

    function getExpectedRate(
        ERC20 src,
        ERC20 dest,
        uint256 srcQty
    ) external view returns (uint256 expectedRate, uint256 slippageRate);

    function tradeWithHint(
        ERC20 src,
        uint256 srcAmount,
        ERC20 dest,
        address destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address walletId,
        bytes hint
    ) external payable returns (uint256);

    function swapEtherToToken(ERC20 token, uint256 minRate)
        external
        payable
        returns (uint256);

    function swapTokenToEther(
        ERC20 token,
        uint256 tokenQty,
        uint256 minRate
    ) external returns (uint256);
}

contract Trader {
    ERC20 internal constant ETH_TOKEN_ADDRESS =
        ERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    KyberNetworkProxyInterface public proxy =
        KyberNetworkProxyInterface(0x9AAb3f75489902f3a48495025729a0AF77d4b11e);
    bytes PERM_HINT = "PERM";
    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner, 'Only the owner may execute this function');
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }

    function uniswapEtherToToken(
        address exchangeContractAddress
    ) internal returns (uint256) {
        UniswapExchangeInterface usi =
            UniswapExchangeInterface(exchangeContractAddress);

        return usi.ethToTokenSwapInput.value(msg.value)(1, block.timestamp);
    }

    function uniswapTokenToEther(
        address exchangeContractAddress,
        uint256 tokenQty
    ) internal returns (uint256) {
        UniswapExchangeInterface usi =
            UniswapExchangeInterface(exchangeContractAddress);

        return usi.tokenToEthSwapInput(tokenQty, 0, block.timestamp); //TODO 2nd arg minEth: What value should I use here?
    }

    function kyberEtherToToken(
        KyberNetworkProxyInterface _kyberNetworkProxy,
        ERC20 token
    ) internal returns (uint256) {
        uint256 minRate;
        (, minRate) = _kyberNetworkProxy.getExpectedRate(
            ETH_TOKEN_ADDRESS,
            token,
            msg.value
        );

        //will send back tokens to this contract's address
        uint256 destAmount =
            _kyberNetworkProxy.swapEtherToToken.value(msg.value)(
                token,
                minRate
            );
        return destAmount;
    }

    function kyberTokenToEther(
        KyberNetworkProxyInterface _kyberNetworkProxy,
        ERC20 token
    ) internal returns (uint256) {
        uint256 balance = token.balanceOf(this);
        uint256 minRate = 1;
        (, minRate) = _kyberNetworkProxy.getExpectedRate(
            token,
            ETH_TOKEN_ADDRESS,
            balance
        );

        uint256 destAmount =
            _kyberNetworkProxy.swapTokenToEther(token, balance, minRate);
        return destAmount;
    }

    function kyberToUniswapArb(
        address tokenAddress,
        address uniSwapContract
    ) public payable onlyOwner returns (uint256, uint256) {
        ERC20 otherToken = ERC20(tokenAddress);

        uint256 tokenAmount = kyberEtherToToken(proxy, otherToken);
        require(tokenAmount > 0, 'No ether converted to tokens');

        uint256 ethBack = uniswapTokenToEther(uniSwapContract, tokenAmount);
        require(ethBack > 0, 'No tokens converted back to ether');

        return (msg.value, ethBack);
    }

    function uniswapToKyberArb(
        address tokenAddress,
        address uniSwapContract
    ) public payable onlyOwner returns (uint256, uint256) {
        ERC20 otherToken = ERC20(tokenAddress);

        uint256 tokenAmount = uniswapEtherToToken(uniSwapContract);
        require(tokenAmount > 0, 'No ether converted to tokens');

        uint256 ethBack = kyberTokenToEther(proxy, otherToken);
        require(ethBack > 0, 'No tokens converted back to ether');

        return (msg.value, ethBack);
    }

    function() external payable {}

    function getBalance(address tokenAddress) public constant onlyOwner returns (uint256) {
        ERC20 token = ERC20(tokenAddress);
        return token.balanceOf(this);
    }

    function withdrawETHAndTokens(address tokenAddress) public onlyOwner {
        address(msg.sender).transfer(address(this).balance);

        ERC20 token = ERC20(tokenAddress);
        uint256 currentTokenBalance = token.balanceOf(this);
        token.transfer(msg.sender, currentTokenBalance);
    }

    function displayOwnerAndCaller() public constant returns (address, address) {
        return (owner, msg.sender);
    }
}