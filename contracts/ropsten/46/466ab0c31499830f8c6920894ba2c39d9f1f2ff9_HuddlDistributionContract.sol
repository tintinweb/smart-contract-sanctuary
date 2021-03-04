/**
 *Submitted for verification at Etherscan.io on 2021-03-04
*/

/*
                                              dHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHb   
                                              HHP%%#%%%%%%%%%%%%%%%%#%%%%%%%#%%VHH
                                              HH%%%%%%%%%%#%v~~~~~~\%%%#%%%%%%%%HH
                                              HH%%%%%#%%%%v'        ~~~~\%%%%%#%HH
                                              HH%%#%%%%%%v'dHHb      a%%%#%%%%%%HH
                                              HH%%%%%#%%v'dHHHA     :%%%%%%#%%%%HH
                                              HH%%%#%%%v' VHHHHaadHHb:%#%%%%%%%%HH
                                              HH%%%%%#v'   `VHHHHHHHHb:%%%%%#%%%HH
                                              HH%#%%%v'      `VHHHHHHH:%%%#%%#%%HH
                                              HH%%%%%'        dHHHHHHH:%%#%%%%%%HH
                                              HH%%#%%        dHHHHHHHH:%%%%%%#%%HH
                                              HH%%%%%       dHHHHHHHHH:%%#%%%%%%HH
                                              HH#%%%%       VHHHHHHHHH:%%%%%#%%%HH
                                              HH%%%%#   b    HHHHHHHHV:%%%#%%%%#HH
                                              HH%%%%%   Hb   HHHHHHHV'%%%%%%%%%%HH
                                              HH%%#%%   HH  dHHHHHHV'%%%#%%%%%%%HH
                                              HH%#%%%   VHbdHHHHHHV'#%%%%%%%%#%%HH
                                              HHb%%#%    VHHHHHHHV'%%%%%#%%#%%%%HH
                                              HHHHHHHb    VHHHHHHH:%odHHHHHHbo%dHH
                                              HHHHHHHHboodboooooodHHHHHHHHHHHHHHHH
                                              HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
                                              HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
                                              VHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHGGN94
 ___  ___  ___  ___  ________  ________  ___       _______       ________ ___  ________   ________  ________   ________  _______      
|\  \|\  \|\  \|\  \|\   ___ \|\   ___ \|\  \     |\  ___ \     |\  _____|\  \|\   ___  \|\   __  \|\   ___  \|\   ____\|\  ___ \     
\ \  \\\  \ \  \\\  \ \  \_|\ \ \  \_|\ \ \  \    \ \   __/|    \ \  \__/\ \  \ \  \\ \  \ \  \|\  \ \  \\ \  \ \  \___|\ \   __/|    
 \ \   __  \ \  \\\  \ \  \ \\ \ \  \ \\ \ \  \    \ \  \_|/__   \ \   __\\ \  \ \  \\ \  \ \   __  \ \  \\ \  \ \  \    \ \  \_|/__  
  \ \  \ \  \ \  \\\  \ \  \_\\ \ \  \_\\ \ \  \____\ \  \_|\ \ __\ \  \_| \ \  \ \  \\ \  \ \  \ \  \ \  \\ \  \ \  \____\ \  \_|\ \ 
   \ \__\ \__\ \_______\ \_______\ \_______\ \_______\ \_______|\__\ \__\   \ \__\ \__\\ \__\ \__\ \__\ \__\\ \__\ \_______\ \_______\
    \|__|\|__|\|_______|\|_______|\|_______|\|_______|\|_______\|__|\|__|    \|__|\|__| \|__|\|__|\|__|\|__| \|__|\|_______|\|_______|
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// File: contracts/interfaces/IUniswapV2Router01.sol

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
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity, address returnPair);
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

// File: contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.6;


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

// File: contracts/HuddlDistributionContract.sol

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.6;

//import "hardhat/console.sol";


contract HuddlDistributionContract is Ownable{
  /*
  //string greeting;
  /* Total amount of deposited ETH in contract */
  uint256 totalETH;
  /* Total amount of HUDL in contract */
  uint256 totalHUDL = 2000000 * 10**18;
  /* Total supply of initial LP in contract */
  uint256 initTotalLP;
  /* Total of locked vesting LP in contract */
  uint256 lockedTokens;
    /* Total unlocked vesting LP in contract */
  uint256 unlockedTokens;
  /* Start date of despositing into the distributor */
  uint256 startDate;
  /* Deposit end date of despositing into the distributor */
  uint256 depositEndDate;                                             
  /* Date for deployment of the distributor */
  uint256 deployDate;
  /* Checks whether the deployer is active to take deposits */
  bool active;
  /* If by chance the contract should fail in provisioning liquidity we will enable huddlers to withdraw their ETH */
  bool emergency;
  /* Enables users to collect their newly provisioned LP tokens */
  bool claimable;
  /* When the distributor will be able to start releasing vested tokens */
  uint256 vestingLockedDate;
  /* Minimum buy in */
  uint256 minBuy;
  /* Maximum buy in */
  uint256 maxBuy;
  /* The maximum amount of ETH possible for the buy in */
  uint256 maxAmount;
  /* HUDL token address */
  address hudlTokenAddress;
  /* HUDL LP token address */
  address hudlLPAddress;
  /* HUDL LP token address */
  IERC20 hudlLPToken;
  /* Tracks each users deposit */
  mapping(address=>uint256) huddlerETHDeposit;
  /* Tracks each users claimed vesting */
  mapping(address=>uint256) huddlerLPClaimed;
  /* Uniswapv2 router object */
  IUniswapV2Router02 private univ2Router;
  

  constructor(
  address _hudlToken, 
  address _hudlLPToken,
  uint256 _maxAmount,
  uint256 _startDate,
  uint256 _minBuy,
  uint256 _maxBuy) public{
    hudlTokenAddress = _hudlToken;
    hudlLPAddress = _hudlLPToken;
    maxAmount = _maxAmount;
    startDate = _startDate;
    depositEndDate = startDate + 30 days;
    deployDate = startDate + 60 days;
    minBuy = _minBuy;
    maxBuy = _maxBuy;
    active = true;

    univ2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  }

  /*** GETTER FUNCTIONS ***/
  function totalETHSupply() external view returns (uint256){
    return totalETH;
  }
  
  function totalHUDLSupply() external view returns (uint256){
    return totalHUDL;
  }
  
  function totalLPSupply() external view returns (uint256){
    return initTotalLP;
  }

  function totalUnlockedLP() external view returns (uint256){
    return unlockedTokens;
  }

  function getMaxAmount() external view returns (uint256){
    return maxAmount;
  }

  function getMinBuyIn() external view returns (uint256){
    return minBuy;
  }

  function getMaxBuyIn() external view returns (uint256){
    return maxBuy;
  }

  function getDeployDate() external view returns (uint256){
    return deployDate;
  }

  function getDepositEndDate() external view returns (uint256){
    return depositEndDate;
  }

  function getStartDate() external view returns (uint256){
    return startDate;
  }

  function getHUDLAddress() external view returns (address){
    return hudlTokenAddress;
  }

  function getHUDLLPAddress() external view returns (address){
    return hudlLPAddress;
  }

  /*** SETTER FUNCTIONS ***/
  function setEmergency(bool _emergency) public onlyOwner{
    emergency = _emergency;
  }

  function pushLaunchDate() public onlyOwner{
    deployDate = deployDate + 1 days;
  }

  function setActive(bool _active) public onlyOwner{
    active = _active;
  }

  function setMaxAmount(uint256 _maxAmount) public onlyOwner{
    require(_maxAmount > maxAmount, "10x");
    maxAmount = _maxAmount;
  }


  /*** MUTATIVE FUNCTIONS ***/

  /* Allows huddlers to claim their provisioned LP tokens */
  function claim() public {
    _claim();
  }

  function _claim() internal{
    require(claimable, "10x");
    
    unlockLPTokens();

    uint256 amount = (((unlockedTokens + initTotalLP) * huddlerETHDeposit[msg.sender]) / totalETH) - huddlerLPClaimed[msg.sender];

    hudlLPToken.transfer(msg.sender, amount);

    huddlerLPClaimed[msg.sender] += amount;
  }

  /* Users desposit their tokens  */
  function deposit() public payable{    
    _deposit(msg.value);
  }

  function _deposit(uint256 amount) internal{
    require(!emergency, "10x");
    require(active, "10x");
    require(depositEndDate >= block.timestamp, "10x");
    require(amount >= minBuy && (huddlerETHDeposit[msg.sender] + amount) <= maxBuy, "10x");

    huddlerETHDeposit[msg.sender] += amount;
    totalETH += msg.value;
  }


  /* Allows either the huddlers or the owners to call the provisioning to UniSwap */
  function provisionLiquidity() public {
    _provisionLiquidity();
  }

  function _provisionLiquidity() private{
    require(deployDate <= block.timestamp, "10x");
    require(!claimable, "10x");

    uint trash;
  
    (trash, trash, initTotalLP, hudlLPAddress) = univ2Router.addLiquidityETH(hudlTokenAddress, totalHUDL, totalHUDL, totalETH, address(this), block.timestamp + 15 minutes);

    hudlLPToken = IERC20(hudlLPAddress);
    initTotalLP = initTotalLP / 2;
    lockedTokens = initTotalLP;

    vestingLockedDate = block.timestamp + 365 days;
    claimable = true;
  }

  /* Users withdraw their desposits  */
  function withdraw() public payable{    
    _withdraw();
  }

  function _withdraw() internal{
    require(emergency, "10x");
    
    address payable receiver = msg.sender;
    receiver.transfer(huddlerETHDeposit[msg.sender]);
  }


    /*** UTILITY FUNCTIONS ***/
    function unlockLPTokens() internal{
      if(block.timestamp >= vestingLockedDate){
        uint256 secondsSinceStart = (block.timestamp - vestingLockedDate);
        uint256 secondsYear = 31536000;

        if(secondsSinceStart >= 1){
          unlockedTokens = (lockedTokens * secondsSinceStart) / secondsYear;
        }
      }
    }

}