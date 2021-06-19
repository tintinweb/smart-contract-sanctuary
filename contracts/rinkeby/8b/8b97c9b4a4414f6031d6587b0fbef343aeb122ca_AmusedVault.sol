/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

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

interface IAmused is IERC20 {
    function taxPercentage() external returns(uint256);
    function setVault(address _vault) external;
    function amusedVaultMint(uint256 _amount) external;
}

contract AmusedVault is Ownable, ReentrancyGuard {
    IUniswapV2Factory public uniswapV2Factory;
    IUniswapV2Router02 public uniswapV2Router;

    IAmused public AmusedToken;
    uint256 public taxPercentage;
    uint256 public valutRewardPercentage;
    uint256 public totalTokenLocked;
    uint256 public rewardsInterval;

    mapping(address => Stake) public stakes;

    struct Stake {
        address user;
        uint256 stakes;
        uint256 timestamp;
    }

    event NewStake(address user, uint256 stakes, uint256 timestamp);
    event UnStake(address user, uint256 tokenValue, uint256 ethValue, uint256 timestamp);

    constructor(IAmused _amusedToken) {
        AmusedToken = _amusedToken;
        taxPercentage = 10;
        valutRewardPercentage = 1;
        rewardsInterval = 5 minutes;
        /* 
            instantiate uniswapV2Router & uniswapV2Factory
            uniswapV2Router address: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
            pancakeswapV2Router address: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        */
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Factory = IUniswapV2Factory(uniswapV2Router.factory());
    }

    receive() external payable {  }
    
    function stake(uint256  _amount) external {
        require(stakes[_msgSender()].stakes == 0, "AmusedVault: Active stakes found");
        require(!_isContract(_msgSender()), "AmusedVault: Not a valid EOC");

        /*
            Note:: Amused deduct tax on token transfer.
            A way to mitigate this is to mint the taxed amount back into the Vault contract so the vault will be receiving the amount sent by the user
        */
        AmusedToken.transferFrom(_msgSender(), address(this), _amount);
        uint256 _tokenTax = AmusedToken.taxPercentage();
        uint256 _deductedTax = (_amount * _tokenTax) / 100;
        // mint the deducted tax back to the Vault contract
        AmusedToken.amusedVaultMint(_deductedTax);

        (uint256 _finalAmount, uint256 _taxAmount) = _tax(_amount);

        totalTokenLocked += _finalAmount;
        stakes[_msgSender()] = Stake(_msgSender(), _finalAmount, block.timestamp);
        _addLiquity(_taxAmount);
        emit NewStake(_msgSender(), _amount, block.timestamp);
    }

    function unstake() external nonReentrant {
        require(stakes[_msgSender()].stakes > 0, "AmusedVault: No active stake found");

        (uint256 _finalAmount, uint256 _taxAmount) = _tax(stakes[_msgSender()].stakes);
        (uint256 _tokenValueEarned, uint256 _ethValueEarned) = calculateRewards(_msgSender());

        // mint the rewards earned from staking to contract and swap for ETH later
        AmusedToken.amusedVaultMint(_tokenValueEarned);
        _swapExactTokensForETH(_tokenValueEarned);

        // clear user record in the Vault
        totalTokenLocked -= _finalAmount;
        stakes[_msgSender()] = Stake(_msgSender(), 0, block.timestamp);

        // transfer remaining locked tokens
        AmusedToken.transfer(_msgSender(), _finalAmount);
        // transfer ETH rewards
        (bool _success,) = payable(_msgSender()).call{ value: _ethValueEarned }("");
        require(_success, "AmusedVault: ETH rewards transfer failed");

        // inject tax into liquidity
        _addLiquity(_taxAmount);
        emit UnStake(_msgSender(), _finalAmount, _ethValueEarned,  block.timestamp);
    }

    function calculateRewards(address _account) public view returns(uint256 _tokenValueEarned, uint256 _ethValueEarned) {
        uint256[] memory amounts;

        uint256 _stakedDays = (block.timestamp - stakes[_account].timestamp) / rewardsInterval;
        uint256 _rewardsPerDay = (stakes[_account].stakes * valutRewardPercentage) / 100;
        _tokenValueEarned = _stakedDays * _rewardsPerDay;
        amounts = getAmountsOut(address(AmusedToken), uniswapV2Router.WETH(), _tokenValueEarned);
        return (_tokenValueEarned, amounts[1]);
    }

    function _tax(uint256 _amount) internal view returns(uint256 _finalAmount, uint256 _taxAmount) {
        _taxAmount = (_amount * taxPercentage) / 100;
        _finalAmount = _amount - _taxAmount;
        return(_finalAmount, _taxAmount);
    }

    function setTaxPercentage(uint256 _amount) external onlyOwner {
        taxPercentage = _amount;
    }

    function setValutRewardPercentage(uint256 _percentage) external onlyOwner {
        valutRewardPercentage = _percentage;
    }

    function setRewardsInterval(uint _interval) external onlyOwner {
        rewardsInterval = _interval;
    }

    function _isContract(address account) internal view returns(bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function _addLiquity(uint256 _tokenAmount) internal {
        address[] memory path = new address[](2);
        uint256[] memory amounts;

        path[0] = address(AmusedToken);
        path[1] = uniswapV2Router.WETH();

        uint256 _splitAmount = _tokenAmount / 2;
        amounts = getAmountsOut(address(AmusedToken), uniswapV2Router.WETH(), _splitAmount);

        // approve tokens to be spent
        AmusedToken.approve(address(uniswapV2Router), _tokenAmount);
        // Swap token for ETH
        uniswapV2Router.swapExactTokensForETH(_splitAmount, 0, path, address(this), block.timestamp);
        // add Liquidity
        uniswapV2Router.addLiquidityETH{ value: amounts[1] }(
            address(AmusedToken),
            _splitAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function _swapExactTokensForETH(uint256 _tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(AmusedToken);
        path[1] = uniswapV2Router.WETH();
        // approve tokens to be spent
        AmusedToken.approve(address(uniswapV2Router), _tokenAmount);
        // swap token => ETH
        uniswapV2Router.swapExactTokensForETH(_tokenAmount, 0, path, address(this), block.timestamp);
    }

    function getAmountsOut(address token1, address token2, uint256 _amount) public view returns(uint256[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token2;
        amounts = uniswapV2Router.getAmountsOut(_amount, path);
        return amounts;
    }
}