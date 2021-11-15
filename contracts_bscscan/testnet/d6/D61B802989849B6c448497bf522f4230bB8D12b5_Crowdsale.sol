pragma solidity ^0.8.4;

import './interface/IUniswapV2Factory.sol';
import './interface/IUniswapV2Router02.sol';
import './interface/IUniswapV2Pair.sol';
import './interface/IERC20.sol';

contract Crowdsale {

    struct account {
        uint ethInvested;
        uint claimableTokens;
        bool whitelisted;
    }

    mapping(address => account) public investors;

    IERC20 public token;

    address[] public teamWallets;

    address public tokenAddress;
    address public marketingWallet;
    address public admin;
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;

    IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    uint public end;
    uint public rate;
    uint public availableTokens;
    uint public totalSupply;
    uint public minPurchase;
    uint public maxPurchase;
    uint public totalEthInvested;
    uint public totalTokensBought;
    uint public softCap;
    uint public hardCap;
    uint public reserve;
    uint public teamRate; //in bips, a value of 100 = 1%
    uint public duration;

    uint8 public tokenDecimals;

    string public tokenName;
    string public tokenSymbol;

    bool public released;
    bool public reverted;
    bool public privateBuysOpen;

    //min and max purchase in WEI.
    //rate = tokens per WEI.
    //teamRate = percentage of total supply to reserve for each tem member, total equal to the number of team wallets times this number.

    /*
    FRONTEND FUNC LIST:
    buyTokens()
    claimTokens()
    claimRefund()

    FRONTEND DATA LIST:
    Contract numbers in Wei, should read out to ETH:
    minPurchase
    maxPurchase
    totalEthInvested (soft/hardcap progress)
    softCap
    hardCap
    released - tokens are now claimable
    reverted - presale has been reverted, refunds are claimable

    investors mapping data
    ethInvested - contributed WEI
    claimableTokens - tokens investor will receive (18 decimals)

    duration - time left on public presale. Not applicable for private presale.
    */


    modifier icoActive() {
        require(end > 0 && block.timestamp < end && availableTokens > 0, "ICO must be active");
        _;
    }

    modifier icoNotActive() {
        require(end == 0, 'ICO should not be active');
        _;
    }

    modifier icoEnded() {
        require(end > 0 && (block.timestamp >= end || availableTokens == 0), 'ICO must have ended');
        _;
    }

    modifier tokensNotReleased() {
        require(released == false, 'Tokens must NOT have been released');
        _;
    }

    modifier tokensReleased() {
        require(released == true, 'Tokens must have been released');
        _;
    }

    modifier privateBuyConfig() {
        require(privateBuysOpen == true && investors[msg.sender].whitelisted == true || end > 0 && block.timestamp < end && availableTokens > 0, 'Either you are not whitelisted or public buys are not yet open.');
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, 'You are not admin.');
        _;
    }

    modifier privatePresaleNotOpen() {
      require(privateBuysOpen == false, "The private presale has already been opened.");
      _;
    }

    modifier revertedPresale() {
        require(reverted == true, "The presale has been reverted.");
        _;
    }

    modifier notRevertedPresale() {
        require(reverted == false, "The presale has not been reverted.");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function loadToken(address _tokenAddress) public onlyAdmin privatePresaleNotOpen icoNotActive {
      tokenAddress = _tokenAddress;
      token = IERC20(_tokenAddress);
      tokenDecimals = token.decimals();
      tokenName = token.name();
      tokenSymbol = token.symbol();
    }

    function preparePresale(uint _rate, uint _minPurchase, uint _maxPurchase, uint _softCap, uint _hardCap, uint _duration, uint _reserve) external privatePresaleNotOpen icoNotActive onlyAdmin  {

      require(_duration > 0, 'duration should be > 0');
      uint _totalSupply = token.totalSupply();
      totalSupply = _totalSupply;
      availableTokens = _rate*_hardCap;
      require(availableTokens > 0 && availableTokens <= _totalSupply, 'totalSupply should be > 0 and <= _availableTokens');
      require(_minPurchase > 0, '_minPurchase should be > 0');
      require(_maxPurchase > 0, '_maxPurchase should be > 0');
      rate = _rate;
      minPurchase = _minPurchase;
      maxPurchase = _maxPurchase;
      softCap = _softCap;
      hardCap = _hardCap;
      duration = _duration;
      reserve =_reserve;
    }

    function openPrivatePresale() external onlyAdmin icoNotActive {
        privateBuysOpen = true;
    }

    function openPublicPresale() external onlyAdmin icoNotActive {
        end = duration + block.timestamp;
    }

    function whitelist(address _investor) external onlyAdmin {
      investors[_investor].whitelisted = true;
    }

    function bulkWhitelist(address[] memory investorList) external onlyAdmin {
      for (uint i=0; i<investorList.length; i++) {
        investors[investorList[i]].whitelisted = true;
      }
    }

    function setTeamRate(uint _teamRate) external onlyAdmin icoNotActive privatePresaleNotOpen {
      teamRate = _teamRate;
      for (uint i=0; i<teamWallets.length; i++) {
        investors[teamWallets[i]].claimableTokens = (totalSupply*_teamRate)/10000;
      }
    }

    function setTeamWallets(address[] memory _teamWallets) public onlyAdmin privatePresaleNotOpen icoNotActive {
      teamWallets = _teamWallets;
    }

    function buyTokens() public payable privateBuyConfig notRevertedPresale {
        /*
        Check to see if values are between investor min buy and max buy.
        Calculate number of tokens user can claim.
        Update totalEthInvested, availableTokens, and user account info.
        And on his farm he had some sanity checks,
        Ee Ai Ee Ai O.
        */
        require(msg.value >= minPurchase && (investors[msg.sender].ethInvested + msg.value) <= maxPurchase, 'have to send between minPurchase and maxPurchase');
        uint claimableTokens = rate * msg.value;
        require(claimableTokens <= availableTokens, 'Not enough tokens left for sale');
        totalEthInvested += msg.value;
        availableTokens -= claimableTokens;
        totalTokensBought += claimableTokens;
        investors[msg.sender].claimableTokens += claimableTokens;
        investors[msg.sender].ethInvested += msg.value;
    }

    function sendLiquidity() external onlyAdmin notRevertedPresale {
      // Automatically adjust tokens to add to liquidity to compensate for reserved ETH for overhead.
      // Automatically calculate excess tokens to send to dead address.
      // Pair contract should already exist.
      require(totalEthInvested >= softCap, "Soft cap not yet reached.");
      uint liquidityEth = totalEthInvested - reserve;
      uint liquidityTokens = totalTokensBought; // preserve launch price
      uint liquidityTokensAdjusted = liquidityTokens*(totalEthInvested - reserve)/totalEthInvested; // preserve launch price
      uint teamTokens = ((totalSupply*teamRate)/10000)*teamWallets.length;
      uint burnTokens = totalSupply - (totalTokensBought + liquidityTokensAdjusted + teamTokens);
      //Unsold tokens are sent to dead address.
      token.transfer(deadAddress, burnTokens);
      require(teamTokens + liquidityTokensAdjusted + burnTokens + totalTokensBought == totalSupply);

      //Token transfer is approved and LP is added to pair contract. LP tokens are sent to marketing wallet address.
      token.approve(address(uniswapV2Router), liquidityTokens);
      uniswapV2Router.addLiquidityETH{value: liquidityEth}(
        tokenAddress,
        liquidityTokens,
        liquidityTokens,
        liquidityTokens,
        marketingWallet,
        block.timestamp
        );
    }

    function release() external onlyAdmin tokensNotReleased notRevertedPresale{
      require(totalEthInvested >= softCap, "Soft cap not yet reached.");
      released = true;
    }

    function revertPresale() external onlyAdmin tokensNotReleased {
      reverted = true;
    }

    function claimTokens() external tokensReleased {
      require(investors[msg.sender].claimableTokens>0, "You have no tokens left to claim.");
      uint _tokensClaimable = investors[msg.sender].claimableTokens;
      investors[msg.sender].claimableTokens = 0;
      token.transfer(msg.sender, _tokensClaimable);
    }

    function claimRefund() external revertedPresale {
      require(investors[msg.sender].ethInvested > 0, "You have no refund left to claim.");
      uint _ethClaimable = investors[msg.sender].ethInvested;
      investors[msg.sender].ethInvested = 0;
      payable(msg.sender).transfer(_ethClaimable);
    }

    function selfBalanceOf() public view returns (uint) {
      return token.balanceOf(address(this));
    }

    function tokenBalanceOf(address _claimant) public view returns (uint) {
      return token.balanceOf(_claimant);
    }

    function selfBalanceEth() public view returns (uint) {
      return address(this).balance;
    }

    function withdraw(address payable to, uint amount) external onlyAdmin icoEnded tokensReleased {
        to.transfer(amount);
    }

}

pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity ^0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}



// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

pragma solidity ^0.8.4;

import "./IERC20Metadata.sol";

interface IERC20 is IERC20Metadata {

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC20Metadata {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

