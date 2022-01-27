// contracts/AstroSwapExchange.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 0.8.0 so no need for safeMath
import "IERC20.sol";
import "AstroSwapFactory.sol";

contract AstroSwapExchange {
    // The address of the factory that made us :)
    AstroSwapFactory public factory;

    // The address of the token we are swapping
    IERC20 public token;

    // The fee each transaction takes. The proportion taken in the inverse of the fee varaiable. Ex: 1% fee is 100
    uint256 public feeAmmount;

    // Keep track of the ethereum and token liquidity pools (both are in wei)
    uint256 public ethPool;
    uint256 public tokenPool;

    // The invariant in the product of the token and ethereum pools we want to keep
    uint256 public invariant;

    // Keep track of investor shares
    mapping (address => uint256) public investorShares;
    uint256 public totalShares;

    event TokenPurchase(address indexed user, address indexed recipient, uint256 ethIn, uint256 tokensOut);
    event EthPurchase(address indexed user, address indexed recipient, uint256 tokensIn, uint256 ethOut);
    event TokenToTokenOut(address indexed user, address indexed recipient, address indexed tokenExchangeAddress, uint256 tokensIn, uint256 ethTransfer);
    event Investment(address indexed user, uint256 indexed sharesPurchased);
    event Divestment(address indexed user, uint256 indexed sharesBurned);


    constructor(IERC20 _token, uint256 _fee) {
        factory = AstroSwapFactory(msg.sender);
        feeAmmount = _fee;
        token = _token;
    }

    modifier hasLiquidity() {
        require(invariant > 0);
        _;
    }

    function seedInvest(uint256 tokenInvestment) public payable {
        require (totalShares == 0, "Liquidity pool is already seeded, use invest() instead");
        require (tokenInvestment > 0 && msg.value > 0, "Must invest ETH and tokens");
        token.transferFrom(msg.sender, address(this), tokenInvestment);
        tokenPool = tokenInvestment;
        ethPool = msg.value;
        invariant = ethPool * tokenPool;
        // Give the starting investor 10000 shares
        investorShares[msg.sender] = 10000;
        totalShares = 10000;
        emit Investment(msg.sender, 10000);
    }

    function invest(uint256 maxTokensInvested) public payable{
        // Amount of tokens to invest is bassed of of the current ratio of eth to token in the pools
        uint256 tokenInvestment = (tokenPool / ethPool) * msg.value;
        require(maxTokensInvested >= tokenInvestment, "Max < required investment");
        require (token.transferFrom(msg.sender, address(this), tokenInvestment));
        uint256 sharesPurchased = (tokenInvestment * totalShares)/ tokenPool;
        ethPool += msg.value;
        tokenPool += tokenInvestment;
        invariant = ethPool * tokenPool;
        // Give the investor their shares
        investorShares[msg.sender] += sharesPurchased;
        totalShares += sharesPurchased;
        emit Investment(msg.sender, sharesPurchased);
    }

    function divest(uint256 shares) public {
        require(investorShares[msg.sender] >= shares, "Not enough shares to divest");
        uint256 ethOut = (ethPool * shares) / totalShares;
        uint256 tokenOut = (tokenPool * shares) / totalShares;
        require(token.transfer(msg.sender, tokenOut));
        payable(msg.sender).call{value:ethOut};
        ethPool -= ethOut;
        tokenPool -= tokenOut;
        invariant = ethPool * tokenPool;
        investorShares[msg.sender] -= shares;
        totalShares -= shares;
        emit Divestment(msg.sender, shares);
    }

    function getShares(address investor) public view returns (uint256) {
        return investorShares[investor];
    }

    function getEthToTokenQuote(uint256 ethValue) public view returns (uint256 tokenQuote) {
        uint256 fee = ethValue / feeAmmount;
        uint256 mockPool = ethPool + ethValue;
        return (tokenPool - (invariant / (mockPool - fee) + 1));
    }

    function getTokenToEthQuote(uint256 tokenValue) public view returns (uint256 ethQuote) {
        uint256 fee = tokenValue / feeAmmount;
        uint256 mockPool = tokenPool + tokenValue;
        return (ethPool - (invariant / (mockPool - fee) + 1));
    }

    function getTokenToTokenQuote(uint256 tokenValue, address tokenOutAddress) public view returns (uint256 tokenQuote) {
        uint256 ethTransfer = getTokenToEthQuote(tokenValue);
        AstroSwapExchange outExchange = AstroSwapExchange(factory.tokenToExchange(tokenOutAddress));
        return outExchange.getEthToTokenQuote(ethTransfer);
    }

    function ethToTokenPrivate(uint256 value) private returns(uint256 tokenToPay){
        uint256 fee = value / feeAmmount;
        ethPool = ethPool + value;
        uint256 tokensPaid = tokenPool - (invariant / (ethPool - fee) + 1); // k = x * y <==> y = k / x, we payout the difference
        // The +1 in the above line is to prevent a rouding error that causes the invariant to lower on transactions where the fee rounds down to 0
        require(tokensPaid <= tokenPool, "Lacking pool tokens"); // Make sure we have enough tokens to pay out
        tokenPool = tokenPool - tokensPaid;
        invariant = tokenPool * ethPool;
        return tokensPaid;
    }

    function tokenToEthPrivate(uint256 tokensIn) private returns(uint256 ethToPay){
        uint256 fee = tokensIn / feeAmmount;
        tokenPool = tokenPool + tokensIn;
        uint256 ethPaid = ethPool - (invariant / (tokenPool - fee) + 1); // k = x * y <==> x = k / y, we payout the difference
        // The +1 in the above line is to prevent a rouding error that causes the invariant to lower on transactions where the fee rounds down to 0
        require(ethPaid <= ethPool, "Lacking pool eth"); // Make sure we have enough eth to pay out
        ethPool = ethPool - ethPaid;
        invariant = tokenPool * ethPool;
        return ethPaid;
    }

    function ethToToken(address recipient, uint256 minTokensOut) public payable hasLiquidity returns(uint256 tokensPaid){
        uint256 tokensPaid = ethToTokenPrivate(msg.value);
        require(tokensPaid >= minTokensOut, "tknsPaid < minTknsOut");
        emit TokenPurchase(msg.sender, recipient, msg.value, tokensPaid);
        require(token.transfer(recipient, tokensPaid), "Tkn OUT transfer fail");
        return tokensPaid;
    }

    function tokenToEth(address recipient, uint256 tokensIn, uint256 minEthOut) public hasLiquidity returns(uint256 ethPaid){
        require(token.transferFrom(msg.sender, address(this), tokensIn), "Tkn IN transfer fail");
        uint256 ethPaid = tokenToEthPrivate(tokensIn);
        require(ethPaid >= minEthOut, "ethPaid < minEthOut");
        emit EthPurchase(msg.sender, recipient, tokensIn, ethPaid);
        payable(recipient).call{value:ethPaid};
        return ethPaid;
    }

    function tokenToToken(address recipient, address tokenOutAddress, uint256 tokensIn, uint256 minTokensOut) public hasLiquidity{
        require(token.transferFrom(msg.sender, address(this), tokensIn), "Tkn IN transfer fail");
        uint256 ethTransfer = tokenToEthPrivate(tokensIn);
        require(ethTransfer > 0, "Eth out is too small");
        address tokenExchangeAddress = factory.tokenToExchange(tokenOutAddress);
        uint256 tokensOut = AstroSwapExchange(tokenExchangeAddress).ethToToken{value: ethTransfer}(recipient, minTokensOut); // Call the outcontract with the value
        require(tokensOut >= minTokensOut, "Output less than minTokensOut");
        emit TokenToTokenOut(msg.sender, recipient, tokenExchangeAddress, tokensIn, ethTransfer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// contracts/AstroSwapFactory.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "AstroSwapExchange.sol";
import "IERC20.sol";

// Almost directly taken from https://github.com/Uniswap/old-solidity-contracts/blob/master/contracts/Exchange/UniswapFactory.sol
contract AstroSwapFactory {
    uint256 public feeRate;
    address[] public tokensAvailable;
    mapping(address => address) public tokenToExchange;
    mapping(address => address) public exchangeToToken;

    constructor(uint256 _fee) {
        feeRate = _fee;
    }

    event TokenExchangeAdded(address indexed tokenExchange, address indexed tokenAddress);

    function convertTokenToExchange(address token) public view returns (address exchange) {
        return tokenToExchange[token];
    }

    function convertExchangeToToken(address exchange) public view returns (address token) {
        return exchangeToToken[exchange];
    }

    function exchangeCount() public view returns (uint256 count) {
        return tokensAvailable.length;
    }

    function addTokenExchange(address tokenAddress) public {
        require(tokenToExchange[tokenAddress] == address(0), "Allready added");
        require(tokenAddress != address(0));
        AstroSwapExchange exchange = new AstroSwapExchange(IERC20(tokenAddress), feeRate);
        tokensAvailable.push(tokenAddress);
        tokenToExchange[tokenAddress] = address(exchange);
        exchangeToToken[address(exchange)] = tokenAddress;
        emit TokenExchangeAdded(address(exchange), tokenAddress);
    }
}