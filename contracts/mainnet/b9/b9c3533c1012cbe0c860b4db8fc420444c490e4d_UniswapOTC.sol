/**
 *Submitted for verification at Etherscan.io on 2020-04-29
*/

pragma solidity ^0.6.0;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


interface IUniswapExchange {
    // Protocol Functions
    function tokenAddress() external view returns (address);

    function factoryAddress() external view returns (address);

    // ERC20 Functions (Keep track of liquidity providers)
    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
        external
        returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256);

    // Pricing functions
    function getEthToTokenInputPrice(uint256 eth_sold)
        external
        view
        returns (uint256);

    function getEthToTokenOutputPrice(uint256 tokens_bought)
        external
        view
        returns (uint256);

    function getTokenToEthInputPrice(uint256 tokens_sold)
        external
        view
        returns (uint256);

    function getTokenToEthOutputPrice(uint256 eth_bought)
        external
        view
        returns (uint256);

    // Add Liquidity
    function setup(address token_addr) external;

    function addLiquidity(
        uint256 min_liquidity,
        uint256 max_tokens,
        uint256 deadline
    ) external payable returns (uint256);

    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline)
        external
        returns (uint256);

    //Eth/Token Swap
    //Sell all ETH
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline)
        external
        payable
        returns (uint256);

    function ethToTokenTransferInput(
        uint256 min_tokens,
        uint256 deadline,
        address recipient
    ) external payable returns (uint256);

    //Sell some ETH and get refund
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline)
        external
        payable
        returns (uint256);

    function ethToTokenTransferOutput(
        uint256 tokens_bought,
        uint256 deadline,
        address recipient
    ) external payable returns (uint256);

    //Token/Eth Swap
    //Sell all tokens
    function tokenToEthSwapInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline
    ) external returns (uint256);

    function tokenToEthTransferInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline,
        address recipient
    ) external returns (uint256);

    //Sell some tokens and get refund
    function tokenToEthSwapOutput(
        uint256 eth_bought,
        uint256 max_tokens,
        uint256 deadline
    ) external returns (uint256);

    function tokenToEthTransferOutput(
        uint256 eth_bought,
        uint256 max_tokens,
        uint256 deadline,
        address recipient
    ) external returns (uint256);

    //Token/Token Swap
    function tokenToTokenSwapInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address token_addr
    ) external returns (uint256);

    function tokenToTokenTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address recipient,
        address token_addr
    ) external returns (uint256);

    function tokenToTokenSwapOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address token_addr
    ) external returns (uint256);

    function tokenToTokenTransferOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address recipient,
        address token_addr
    ) external returns (uint256);

    //Token/Exchange Swap
    function tokenToExchangeSwapInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address exchange_addr
    ) external returns (uint256);

    function tokenToExchangeTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address recipient,
        address exchange_addr
    ) external returns (uint256);

    function tokenToExchangeSwapOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address exchange_addr
    ) external returns (uint256);

    function tokenToExchangeTransferOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address recipient,
        address exchange_addr
    ) external returns (uint256);
}

contract UniswapOTC {
    address public owner;
    address public exchangeAddress;
    address public tokenAddress;

    uint256 public totalClients;
    address[] public clients;
    mapping (address => bool) public clientExists;
    
    mapping (address => uint256) public clientEthBalances;      //Client ETH balance
    mapping (address => uint256) public clientMinTokens;        //Client Limit Order
    mapping (address => uint256) public clientTokenBalances;    //Client Token balance
    mapping (address => uint256) public clientTokenFees;        //Total OTC Fees
    mapping (address => uint256) public purchaseTimestamp;        //Withdrawal timestamp
    uint256 constant ONE_DAY_SECONDS = 86400;
    uint256 constant FIVE_MINUTE_SECONDS = 300;
    
    mapping(address => bool) public triggerAddresses;           //Bot Trigger Addresses

    IERC20 token;
    IUniswapExchange exchange;

    //Min volume values
    uint256 public minEthLimit;     //Min Volume
    uint256 public maxTokenPerEth;  //Min Price
    
    constructor(address _exchangeAddress, uint256 _minEthLimit, uint256 _maxTokenPerEth) public {
        exchange = IUniswapExchange(_exchangeAddress);
        exchangeAddress = _exchangeAddress;
        tokenAddress = exchange.tokenAddress();
        token = IERC20(tokenAddress);
        owner = msg.sender;
        minEthLimit = _minEthLimit;
        maxTokenPerEth = _maxTokenPerEth;
        totalClients = 0;
    }

    /**
     * @dev OTC Provider. Gives right to fee withdrawal.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    /**
     * @dev Authorized Purchase Trigger addresses for mempool bot.
     */
    modifier onlyTrigger() {
        require(msg.sender == owner || triggerAddresses[msg.sender], "Unauthorized");
        _;
    }

    /**
     * @dev Trigger Uniswap contract, drains client's ETH balance.
     *      Computes fee as spread between execution price and limit price.
     */
    function executeLimitOrder(address _client, uint256 deadline)
        public
        onlyTrigger
        returns (uint256, uint256)
    {
        //Avoids Uniswap Assert Failure when no liquidity (gas saving)
        require(token.balanceOf(exchangeAddress) > 0, "No liquidity on Uniswap!"); //27,055 Gas

        uint256 ethBalance = clientEthBalances[_client];
        uint256 tokensBought = exchange.getEthToTokenInputPrice(ethBalance);
        uint256 minTokens = clientMinTokens[_client];

        require(tokensBought >= minTokens, "Purchase amount below min tokens!"); //27,055 Gas

        uint256 spreadFee = tokensBought - minTokens;
        //Tokens bought, set balance 0
        clientEthBalances[_client] = 0; //Reset state
        clientMinTokens[_client] = 0; //Reset state
        clientTokenBalances[_client] += minTokens;  //Add to balance
        clientTokenFees[_client] += spreadFee;      //Add to balance
        purchaseTimestamp[_client] = block.timestamp + ONE_DAY_SECONDS;

        //Call Uniswap contract
        exchange.ethToTokenSwapInput.value(ethBalance)(
            tokensBought,
            deadline
        );

        return (minTokens, spreadFee);
    }

    /**
     * @dev Add Trigger address.
     */
    function setTriggerAddress(address _address, bool _authorized)
        public
        onlyOwner
    {
        triggerAddresses[_address] = _authorized;
    }

    /**
     * @dev Get max limit price.
     */
    function getMaxTokens(uint256 _etherAmount)
        public
        view
        returns (uint256)
    {
        return _etherAmount * maxTokenPerEth;
    }

    /**
     * @dev Fund contract and set limit price (in the form of min purchased tokens).
     * Excess value is refunded to sender in the case of a re-balancing.
     */
    function setLimitOrder(uint256 _tokenAmount, uint256 _etherAmount)
        public
        payable
    {
        require(_etherAmount >= minEthLimit, "Insufficient ETH volume");
        require(_tokenAmount <= maxTokenPerEth  * _etherAmount, "Excessive token per ETH");
        require(_etherAmount == clientEthBalances[msg.sender] + msg.value, "Balance must equal purchase eth amount.");

        if (!clientExists[msg.sender]) {
            clientExists[msg.sender] = true;
            clients.push(msg.sender);
            totalClients += 1;
        }
        
        //Increment client balance
        clientEthBalances[msg.sender] += msg.value;
        clientMinTokens[msg.sender] = _tokenAmount;
    }


    /**
     * @dev Return if purchase would be autherized at current prices
     */
    function canPurchase(address _client)
        public
        view
        returns (bool)
    {
        //Avoids Uniswap Assert Failure when no liquidity (gas saving)
        if (token.balanceOf(exchangeAddress) == 0) {
            return false;
        }

        uint256 ethBalance = clientEthBalances[_client];
        if (ethBalance == 0) {
            return false;
        }
        
        uint256 tokensBought = exchange.getEthToTokenInputPrice(ethBalance);
        uint256 minTokens = clientMinTokens[_client];

        //Only minimum amount of tokens
        return tokensBought >= minTokens;
    }

    /**
     * @dev Withdraw OTC provider fee tokens.
     */
    function withdrawFeeTokens(address _client) public onlyOwner {
        require(clientTokenFees[_client] > 0, "No fees!");
        require(block.timestamp > purchaseTimestamp[_client], "Wait for client withdrawal.");

        uint256 sendFees = clientTokenFees[_client];
        clientTokenFees[_client] = 0;

        token.transfer(msg.sender, sendFees);
    }

    /**
     * @dev Withdraw OTC client purchased tokens.
     */
    function withdrawClientTokens() public {
        require(clientTokenBalances[msg.sender] > 0, "No tokens!");

        uint256 sendTokens = clientTokenBalances[msg.sender];
        clientTokenBalances[msg.sender] = 0;
        purchaseTimestamp[msg.sender] = block.timestamp + FIVE_MINUTE_SECONDS;  //Unlock in 5minutes

        token.transfer(msg.sender, sendTokens);
    }
    

    /**
     * @dev Withdraw OTC client ether.
     */
    function withdrawEther() public {
        require(clientEthBalances[msg.sender] > 0, "No ETH balance!");

        uint256 sendEth = clientEthBalances[msg.sender];
        clientEthBalances[msg.sender] = 0;

        payable(msg.sender).transfer(sendEth);
    }

    /**
     * @dev Get eth balance of contract.
     */
    function contractEthBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Get token balance of contract
     */
    function contractTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

}