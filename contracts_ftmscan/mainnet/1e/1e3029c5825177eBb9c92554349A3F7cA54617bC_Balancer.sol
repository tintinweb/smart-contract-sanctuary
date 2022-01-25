/**
 *Submitted for verification at FtmScan.com on 2022-01-25
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// File openzeppelin-solidity/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File openzeppelin-solidity/contracts/access/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File openzeppelin-solidity/contracts/token/ERC20/[email protected]



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


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.6.2;

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


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.6.2;

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


// File @uniswap/v2-core/contracts/interfaces/[email protected]

pragma solidity >=0.5.0;

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


// File contracts/IBalancer.sol

pragma solidity 0.8.1;


interface IBalancer {

    function balanceSale(address swapAddress, uint256 amount) external;

}


// File contracts/IERC20Mintable.sol

pragma solidity 0.8.1;

interface IERC20Mintable is IERC20 {

    function mint(address to, uint256 amount) external;

}


// File contracts/Balancer.sol

pragma solidity ^0.8.1;




contract Balancer is IBalancer, Ownable {

    /* ----- general parameters --------------------------- */
    bool private _active;
    IERC20Mintable private _token;
    mapping(address => address) private _swapToRouter;

    /* ----- balancing parameters --------------------------- */
    uint256 private _saleThreshold = 1 ether;
    uint256 private _liqudityPercentage = 50;
    uint256 private _slippagePercentage = 10;
    uint256[2] private _pegRatioThreshold1 = [1.1 ether, 50];
    uint256[2] private _pegRatioThreshold2 = [1.3 ether, 75];


    constructor(address token){
        _token = IERC20Mintable(token);
    }

    /* ----- balancer activate/deactivate ------------------- */
    function active() external view returns(bool) {
        return _active;
    }
    function toggleActive() external onlyOwner {
        _active = !_active;
    }

    /* ----- router maintenance -------------------------- */
    function setRouterForSwap(address swap, address router) external onlyOwner {
        _swapToRouter[swap] = router;
    }
    function getRouterForSwap(address swap) external view returns(address) {
        return _swapToRouter[swap];
    }

    /* ----- withdrawal/ transfer of assets -------------- */
    function transferToken(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    function withdraw(address payable to, uint256 amount) external onlyOwner {
        to.transfer(amount);
    }

    // this is required so the smart contract can receive ETH from Uniswap. Otherwise the error TransferHelper: ETH_TRANSFER_FAILED is raised.
    receive() payable external {}

    /* ------ configure balancing parameter -------------- */
    function saleThreshold() external view returns(uint256) {
        return _saleThreshold;
    }
    function setSaleThreshold(uint256 newThreshold) external onlyOwner {
        _saleThreshold = newThreshold;
    }

    function liquidityPercentage() external view returns(uint256) {
        return _liqudityPercentage;
    }
    function setLiquidityPercentage(uint256 newPercentageValue) external onlyOwner {
        _liqudityPercentage = newPercentageValue;
    }

    function slippagePercentage() external view returns(uint256) {
        return _slippagePercentage;
    }
    function setSlippagePercentage(uint256 newPercentageValue) external onlyOwner {
        _slippagePercentage = newPercentageValue;
    }

    function pegRatioThreshold1() external view returns(uint256 threshold, uint256 percentage){
        threshold = _pegRatioThreshold1[0];
        percentage = _pegRatioThreshold1[1]; 
    }
    function setPegRatioThreshold1(uint256 threshold, uint256 percentage) external onlyOwner {
        _pegRatioThreshold1[0] = threshold;
        _pegRatioThreshold1[1] = percentage; 
    }

    function pegRatiothreshold2() external view returns(uint256 threshold, uint256 percentage){
        threshold = _pegRatioThreshold2[0];
        percentage = _pegRatioThreshold2[1]; 
    }
    function setPegRatiothreshold2(uint256 threshold, uint256 percentage) external onlyOwner {
        require(threshold > _pegRatioThreshold1[0], "Balancer: PEG threshold 2 needs to be greater than PEG threshold 1.");
        _pegRatioThreshold2[0] = threshold;
        _pegRatioThreshold2[1] = percentage; 
    }

    /* ------- internal calculations ------------------- */
    function _calculateSlippage(uint256 baseValue) private view returns(uint256) {
        return (baseValue - ((baseValue * _slippagePercentage) / 100));
    }

    /** 
     * @param ftmPrice: current USD price of 1 FTM in Wei (this means you have to multiply the price with 1^18)
     * @param nav: net asset value. this parameter will be calculated externally.
     *
     * returns PEG ratio of the token in Wei (1^18)
     */
    function _calculatePegRatio(uint256 ftmPrice, uint256 nav) private view returns(uint256) { 
        uint256 tokenTotalSupply = _token.totalSupply();
        uint256 marketCapInUSD = (tokenTotalSupply * ftmPrice) / 1 ether;
        return (marketCapInUSD / nav);
    }

    /**
     * Calculate the percentage of a token amount that should be sold based on the token's PEG ratio
     * and net asset value.
     */
    function _calculateSalePercentage(uint256 ftmPrice, uint256 nav) private view returns(uint256) {
        uint256 pegRatio = _calculatePegRatio(ftmPrice, nav);

        if (pegRatio >= _pegRatioThreshold2[0]){
            return _pegRatioThreshold2[1];
        }
                
        if (pegRatio >= _pegRatioThreshold1[0]){
            return _pegRatioThreshold1[1];
        }
        return 0;
    }


    /* ----- sale balancing ------------------------------ */
    function balanceSale(address swapAddress, uint256 amount) external override {
        // no implementation currently. but we need the interface to be 
        // active for later updates.
    }

    function _balanceWithCoin(uint256 saleAmount, uint256 ftmPrice, uint256 nav, IUniswapV2Router02 router) private {
        
        // STEP 0 - Calculcate how many tokens to freshly mint and sell
        uint256 salePercentage = _calculateSalePercentage(ftmPrice, nav);
        require(salePercentage > 0, "Balancer: PEG ratio threshold not reached.");

        // define swap route for sale
        address[] memory route = new address[](2);
        route[0] = address(_token);
        route[1] = router.WETH();

        // STEP 1 - mint new tokens & sell them
        uint256 amountTokensToMint = (saleAmount * salePercentage) / 100;
        _token.mint(address(this), amountTokensToMint);

        uint256 ethValueOfTokens = router.getAmountsOut(amountTokensToMint, route)[1];
        IERC20(_token).approve(address(router), amountTokensToMint);
        uint256[] memory swapTokens = router.swapExactTokensForETH(
                                            amountTokensToMint,
                                            _calculateSlippage(ethValueOfTokens),
                                            route,
                                            address(this),
                                            block.timestamp + 5 minutes);


        // STEP 2 - mint new tokens & add liquidity to pool

        // liquidate some of the ETH we just received
        uint256 ethLiq = (swapTokens[1] * _liqudityPercentage) / 100;

        // get the token value of the ETH that should be liquidated
        route[0] = router.WETH();
        route[1] = address(_token);
        uint256 tokenValueOfEth = router.getAmountsOut(ethLiq, route)[1];

        _token.mint(address(this), tokenValueOfEth);
        IERC20(_token).approve(address(router), tokenValueOfEth);

        router.addLiquidityETH
                                {value: ethLiq}
                                (address(_token), 
                                tokenValueOfEth,
                                0,
                                0,
                                address(this),
                                block.timestamp + 5 minutes);
    }

    function _balanceWithToken(uint256 saleAmount, uint256 ftmPrice, uint256 nav, IUniswapV2Router02 router, address swapTokenPartner) private {
        
        // STEP 0 - Calculcate how many tokens to freshly mint and sell
        uint256 salePercentage = _calculateSalePercentage(ftmPrice, nav);
        require(salePercentage > 0, "Balancer: PEG ratio threshold not reached.");

        // define swap route for sale
        address[] memory route = new address[](2);
        route[0] = address(_token);
        route[1] = swapTokenPartner;

        // STEP 1 - mint new tokens & swap them
        uint256 amountTokensToMint = (saleAmount * salePercentage) / 100;
        _token.mint(address(this), amountTokensToMint);

        uint256 partnerTokenValueOfTokens = router.getAmountsOut(amountTokensToMint, route)[1];
        IERC20(_token).approve(address(router), amountTokensToMint);
        uint256[] memory swapTokens = router.swapExactTokensForTokens(
                                            amountTokensToMint,
                                            _calculateSlippage(partnerTokenValueOfTokens),
                                            route,
                                            address(this),
                                            block.timestamp + 5 minutes);


        // STEP 2 - mint new tokens & add liquidity to pool

        // liquidate some of the partner tokens we just received
        uint256 partnerLiq = (swapTokens[1] * _liqudityPercentage) / 100;

        // get the token value of the amount of partner tokens that should be liquidated
        route[0] = swapTokenPartner;
        route[1] = address(_token);
        uint256 tokenValueOfPartnerToken = router.getAmountsOut(partnerLiq, route)[1];

        _token.mint(address(this), tokenValueOfPartnerToken);
        IERC20(_token).approve(address(router), tokenValueOfPartnerToken);
        IERC20(swapTokenPartner).approve(address(router), partnerLiq);

        router.addLiquidity(address(_token),
                            swapTokenPartner,
                            tokenValueOfPartnerToken,
                            partnerLiq,
                            0,
                            0,
                            address(this),
                            block.timestamp + 5 minutes);
    }

    /**
     * Balance a token sale with FTM via the ETH/token swap pair specified via 'swapAddress'.
     *
     * @param swapAddress: address of the swap from that tokens where bought
     * @param saleAmount: amount of tokens that where bought (in 1^18)
     * @param ftmPrice: current USD price of 1 FTM (in 1^18)
     * @param nav: net asset value. this parameter will be calculated externally.
     */
    function balanceSaleViaOracle(address swapAddress, uint256 saleAmount, uint256 ftmPrice, uint256 nav) external onlyOwner {
        // prechecks
        require(_active, "Balancer: Balancer is not active.");
        //require(_msgSender() == address(_token), "Balancer: Only token can call this function.");
        require(_swapToRouter[swapAddress] != address(0), "Balancer: No router maintained for swap.");
        require(saleAmount >= _saleThreshold, "Balancer: Amount does not meet sale balancing threshold.");

        // check if the swap was against another token or WFTM (WETH)
        IUniswapV2Pair swapPair = IUniswapV2Pair(swapAddress);
        IUniswapV2Router02 router = IUniswapV2Router02(_swapToRouter[swapAddress]);

        address swapPartnerAddress = address(0);
        if (swapPair.token0() == address(_token)){
            swapPartnerAddress = swapPair.token1();
        }
        else {
            swapPartnerAddress = swapPair.token0();
        }

        if(swapPartnerAddress == router.WETH()){
            _balanceWithCoin(saleAmount, ftmPrice, nav, router);
        }
        else {
            _balanceWithToken(saleAmount, ftmPrice, nav, router, swapPartnerAddress);
        }
    }   

}