pragma solidity ^0.8.4;

import './interface/IUniswapV2Factory.sol';
import './interface/IUniswapV2Router02.sol';
import './interface/IUniswapV2Pair.sol';
import './interface/IERC20.sol';

contract Crowdsale {

    //IRL crowdsale contract. Handles public and private presales for the same token
    //Designed to perform a private presale and then a public presale, in that order. The two conditions are mutually exclusive.
    //

    struct account {
        uint claimableTokens;
        uint refundAllowance;
        uint privateEthInvested;
        bool whitelisted;
    }

    //token allocations, in bips, e.g. 10000 = 100%, 500 = 5%.
    struct tokenAllocations{
      uint16 denominator;
      uint16 percentToDevs;
      uint16 percentToMarketing;
      uint16 percentToPrivate;
      uint16 percentToPublic;
      uint16 percentToLiquidity;
      uint16 percentToBurn;
    }

    mapping(address => account) public investors;

    IERC20 public token;

    address[] public teamWallets;

    address public tokenAddress;
    address public marketingWallet;
    address public admin;
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;

    IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    //state controls
    uint public end;
    bool public released;
    bool public reverted;
    bool public privateBuysOpen;
    uint public duration;

    //global
    uint public minPurchase;

    tokenAllocations TokenAllocations;

    //private sale specific
    uint public privatePresaleTokens;
    uint public privatePresaleEth;
    uint public privateMaxPurchase;
    uint public privateCap;

    //public sale specific
    uint public publicPresaleTokens;
    uint public publicMaxPurchase;
    uint public publicTokensBought;
    uint public publicEthInvested;
    uint public softCap;
    uint public hardCap;
    uint public publicReserveRate; //In bips

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

   TODO: separate out presale contract
   */

   constructor(uint16 _percentToDevs,
        uint16 _percentToMarketing,
        uint16 _percentToPrivate,
        uint16 _percentToPublic,
        uint16 _percentToLiquidity,
        uint16 _percentToBurn) {

       admin = msg.sender;
       _setTokenAllocations(_percentToDevs, _percentToMarketing, _percentToPrivate, _percentToPublic, _percentToLiquidity, _percentToBurn);
   }

   //WHOO NELLY, use a struct to save on gas
   function _setTokenAllocations(
     uint16 _percentToDevs,
     uint16 _percentToMarketing,
     uint16 _percentToPrivate,
     uint16 _percentToPublic,
     uint16 _percentToLiquidity,
     uint16 _percentToBurn
     ) internal {
     require(
     _percentToDevs +
     _percentToMarketing +
     _percentToPrivate +
     _percentToPublic +
     _percentToLiquidity +
     _percentToBurn ==
     uint16(10000), "Your allocations must sum to 10000 (bips)"); {
       TokenAllocations = tokenAllocations({
         denominator: 10000,
         percentToDevs: _percentToDevs,
         percentToMarketing: _percentToMarketing,
         percentToPrivate: _percentToPrivate,
         percentToPublic: _percentToPublic,
         percentToLiquidity: _percentToLiquidity,
         percentToBurn: _percentToBurn
       });
     }
   }

    modifier icoActive() {
        require(end > 0 && block.timestamp < end, "ICO must be active");
        _;
    }

    modifier icoNotActive() {
        require(end == 0, 'ICO should not be active');
        _;
    }

    modifier icoEnded() {
        require(end > 0 && (block.timestamp >= end), 'ICO must have ended');
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
        require(privateBuysOpen == true || end > 0 && block.timestamp < end, 'Presales are currently closed.');
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
    //Global config functions

    function loadToken(address _tokenAddress) external onlyAdmin privatePresaleNotOpen icoNotActive {
      tokenAddress = _tokenAddress;
      token = IERC20(_tokenAddress);
    }

    function preparePresale(uint _minPurchase, uint _privateMaxPurchase, uint _publicMaxPurchase, uint _privateCap, uint _softCap, uint _hardCap, uint _publicPresaleDuration) external privatePresaleNotOpen icoNotActive onlyAdmin  {

      require(_publicPresaleDuration >= 21600, 'duration should be > 21600'); //in seconds, e.g. 21600 = 1 hr.
      require(_publicMaxPurchase > 0 && _softCap > 0 && _hardCap > 0, 'You must initialize public rates, softCap, hardCap.');

      privatePresaleTokens = (TokenAllocations.percentToPrivate * totalSupply()) / TokenAllocations.denominator;
      publicPresaleTokens = (TokenAllocations.percentToPublic * totalSupply()) / TokenAllocations.denominator;

      minPurchase = _minPurchase;
      privateMaxPurchase = _privateMaxPurchase;
      publicMaxPurchase = _publicMaxPurchase;

      softCap = _softCap;
      privateCap = _privateCap;
      hardCap = _hardCap;

      duration = _publicPresaleDuration;
    }

    //Private presale functions

    function openPrivatePresale() external onlyAdmin icoNotActive {
        privateBuysOpen = true;
    }

    function closePrivatePresale() public onlyAdmin icoNotActive {
        privateBuysOpen = false;
    }

    function openPublicPresale() external onlyAdmin icoNotActive {
      closePrivatePresale();
      end = duration + block.timestamp;
    }

    //private presale related functions

    function whitelist(address _investor) external onlyAdmin {
      investors[_investor].whitelisted = true;
    }

    function bulkWhitelist(address[] memory investorList) external onlyAdmin {
      for (uint i=0; i<investorList.length; i++) {
        investors[investorList[i]].whitelisted = true;
      }
    }

    function setTeamWallets(address[] memory _teamWallets) public onlyAdmin privatePresaleNotOpen icoNotActive {
      teamWallets = _teamWallets;
    }

    function buyTokens() public payable privateBuyConfig notRevertedPresale tokensNotReleased returns(bool success) {
      require(investors[msg.sender].whitelisted == true && privateBuysOpen == true || end > 0 && block.timestamp < end, "You cannot buy");
        /*
        Check to see if values are between investor min buy and max buy.
        Calculate number of tokens user can claim.
        Update totalEthInvested, availableTokens, and user account info.
        */
        success = false;
        //loop just for SPECIAL BOYS.
        if(investors[msg.sender].whitelisted == true && privateBuysOpen == true){
          require(msg.value >= minPurchase && (investors[msg.sender].privateEthInvested + msg.value) <= privateMaxPurchase, 'Must buy between minPurchase and privateMaxPurchase');
          uint claimableTokens = getPrivatePrice() * msg.value;
          require(claimableTokens <= privatePresaleTokens, 'Not enough tokens left for sale');
          privatePresaleTokens -= claimableTokens;
          investors[msg.sender].claimableTokens += claimableTokens;
          investors[msg.sender].privateEthInvested += msg.value;
          privatePresaleEth += msg.value;
          success = true;
        }
        //loop for NON-SPECIAL BOYS. Private and public presale conditions should be mutually exclusive.
        if(end > 0 && block.timestamp < end) {
          require(msg.value >= minPurchase && (investors[msg.sender].refundAllowance + msg.value) <= publicMaxPurchase, 'Must buy between minPurchase and publicMaxPurchase');
          uint claimableTokens = getPublicPrice() * msg.value;
          require(claimableTokens <= publicPresaleTokens, 'Not enough tokens left for sale');
          publicPresaleTokens -= claimableTokens;
          investors[msg.sender].claimableTokens += claimableTokens;
          investors[msg.sender].refundAllowance += msg.value;
          success = true;
        }
        return success;
    }

    /* function sendLiquidity() external onlyAdmin notRevertedPresale tokensReleased {
      // Automatically adjust tokens to add to liquidity to compensate for reserved ETH for overhead.
      // Automatically calculate excess tokens to send to dead address.
      // Pair contract should already exist.
      uint liquidityEth = totalEthInvested;
      uint liquidityTokens = totalTokensBought; // preserve launch price
      uint liquidityTokensAdjusted = liquidityTokens*(totalEthInvested - reserve)/totalEthInvested; // preserve launch price
      uint teamTokens = ((totalSupply*teamTokens)/10000)*teamWallets.length;
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
    } */

    function release() external onlyAdmin tokensNotReleased notRevertedPresale{
      //reverse-engineer tokens left to equal totalEthInvested;
      //redo this if I have to
      uint totalEthInvested = publicPresaleTokens / getPublicPrice();
      require(totalEthInvested >= softCap, "Soft cap not yet reached.");
      released = true;
    }

    function revertPresale() external onlyAdmin tokensNotReleased {
      reverted = true;
    }

    function withdrawPrivatePresaleEth(address payable to) external onlyAdmin privatePresaleNotOpen {
      uint amount = privatePresaleEth;
      privatePresaleEth = 0;
      to.transfer(amount);
    }

    function claimTokens() external tokensReleased {
      require(investors[msg.sender].claimableTokens>0, "You have no tokens left to claim.");
      uint _tokensClaimable = investors[msg.sender].claimableTokens;
      investors[msg.sender].claimableTokens = 0;
      bool confirm = token.transfer(msg.sender, _tokensClaimable);
      require(confirm = true);
    }

    function claimRefund() external revertedPresale {
      require(investors[msg.sender].refundAllowance > 0, "You have no refund left to claim.");
      uint _ethClaimable = investors[msg.sender].refundAllowance;
      investors[msg.sender].refundAllowance = 0;
      payable(msg.sender).transfer(_ethClaimable);
    }

    //tokenomic getters

    /* function getPublicPrice() public view returns(uint numerator, uint denominator) {
      uint priceDenominator = 10000;
      return (publicPresaleTokens*10000 / hardCap, priceDenominator);
    }

    function getPrivatePrice() public view returns(uint numerator, uint denominator) {
      uint priceDenominator = 10000;
      return (privatePresaleTokens * priceDenominator / privateCap, priceDenominator);
    } */

    function getPublicPrice() public view returns(uint) {
      return (publicPresaleTokens / hardCap);
    }

    function getPrivatePrice() public view returns(uint) {
      return (privatePresaleTokens / privateCap);
    }

    /* function getLaunchPrice() public view returns (uint) {
      //returns tokens per WEI
      uint denominator = TokenAllocations.denominator;
      return ((percentToLiquidity*denominator)/percentToPublic) / (denominator - publicReserveRate) * (publicRate) / (denominator);
    } */

    function selfBalanceOf() public view returns (uint) {
      return token.balanceOf(address(this));
    }

    function tokenBalanceOf(address _claimant) public view returns (uint) {
      return token.balanceOf(_claimant);
    }

    function selfBalanceEth() public view returns (uint) {
      return address(this).balance;
    }

    function tokenName() public view returns (string memory name) {
      return(token.name());
    }

    function tokenSymbol() public view returns (string memory symbol) {
      return(token.symbol());
    }

    function tokenDecimals() public view returns (uint8) {
      return(token.decimals());
    }

    function totalSupply() public view returns (uint) {
      return(token.totalSupply());
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

