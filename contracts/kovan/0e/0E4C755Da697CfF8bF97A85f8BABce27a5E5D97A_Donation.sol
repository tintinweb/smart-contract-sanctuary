/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

// SPDX-License-Identifier: MIT

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


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

interface IAaveProvider {

    function getLendingPool() external view returns (address);

}

interface IAaveLendingPool {

      /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);



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

contract Donation is Ownable {
    

    enum campaignstate{Uninitialize, Active, Stopped}

    struct $_Campaign {
        address _owner; //The Campaign wallet which is the only one can withdraw
        uint _usdcBalance;
        uint _orgId;
        Donation.campaignstate _state;
        
    }
    //Will use as the ID of the organization
    mapping ( uint => $_Campaign) public campaigns;
    uint campaignIndex; //Set to 0 on deploy by default

    address private  AAVE_PROVIDER = 0x88757f2f99175387aB4C6a4b3067c77A695b0349;
    IERC20 private usdc  = IERC20(0xe22da380ee6B445bb8273C81944ADEB6E8450422); // Kovan
    IERC20 private aUsdc = IERC20(0xe12AFeC5aa12Cf614678f9bFeeB98cA9Bb95b5B0); // Kovan
    IERC20 private dai   = IERC20(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
    

    IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//Uniswap router address
    IAaveProvider provider   = IAaveProvider(AAVE_PROVIDER);
    IAaveLendingPool public aaveLendingPool = IAaveLendingPool(provider.getLendingPool()); // Kovan address 0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe
    
    uint256 max = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    
    uint public balanceReceived = 0;
    uint public totalUsdcBalance = 0;
    uint public activeCampaigns = 0;

    mapping(address => mapping(uint => uint)) public userDepositedUsdc;

    
    //Events
    event CampaignCreated(uint _id, address _organization);
    event DepositedToCharity(uint _amount, uint _assetId, uint _organisationId);
    event WithdrawCharityInterest(uint _amount, uint _assetId, uint _organisationId);


    constructor() {
        usdc.approve(address(aaveLendingPool), max);
        aUsdc.approve(address(aaveLendingPool), max);
        dai.approve(address(aaveLendingPool), max);
        createCampaign(0, address(0xc1f23e093c314Ea704Af2c1000f9Bf20a4d2D2B4)); // Just a demo

    }
    //Setting up new organization
    function createCampaign(uint _orgId, address _owner) public {

        campaigns[campaignIndex]._owner = _owner;
        campaigns[campaignIndex]._state = campaignstate.Active;
        campaigns[campaignIndex]._orgId = _orgId;
        emit CampaignCreated(campaignIndex, _owner);
        campaignIndex++;
        activeCampaigns++;
    
    } 
    
    /*
        Getting Dai tokens from uniswap for deposited ETH
        In Kovan uniswap Dai is not the same as AAVE Dai.
        on Mainnet these tokens will occur interest in the Aave protocol
    */
    receive() external payable {
         // Execute trade on Uniswap
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = address(dai);

        uint[] memory amounts = uniswapRouter.swapExactETHForTokens{ value: msg.value }(0, path, address(this), block.timestamp + 10);
        balanceReceived += amounts[1]; // Update Dai amount

    }
    
    /*
        User deposit _amount after approve the contract to spend this amount
        Depositing to a specific campaign
    */
    function userDepositUsdc(uint _amount, uint _campaignId) external {
        //Spending allowence done in the GUI
        require(campaigns[_campaignId]._state == campaignstate.Active, "Organization not exist");
        userDepositedUsdc[msg.sender][_campaignId] += _amount;                                  //Tarcking User deposits
        campaigns[_campaignId]._usdcBalance += _amount;
        require(usdc.transferFrom(msg.sender, address(this), _amount), "USDC Transfer failed!");

        aaveLendingPool.deposit(address(usdc), _amount, address(this), 0);
        emit DepositedToCharity(_amount, 0, _campaignId); // Assuming USDC is asset 0
        totalUsdcBalance += _amount;
     }
      /*
        Withdraw function will be implement in mainnet like a farm contract
        with shares and part of the total share for each campaign
        Since Aave on Kovan doesn't behave the same as Mainnet ( the Atokens don't occur interest)

      */
     function withdrawInterest(uint _campaignId) external {
         //For now it will work with only 1 organization since the way the yeild is bearing take from cake contract
         require(campaigns[_campaignId]._owner == msg.sender, "Only Organization adming can withdraw");

         uint aUsdcTotal = aUsdc.balanceOf(address(this));
         uint256 totalInterest = aUsdcTotal - totalUsdcBalance; 
         if (totalInterest > 0){
            uint poolInterest = totalInterest / activeCampaigns;
            campaigns[_campaignId]._usdcBalance -= poolInterest ;
            aaveLendingPool.withdraw(address(usdc), poolInterest, address(this)); 
            require(usdc.transfer(msg.sender,  poolInterest), "USDC Transfer failed!"); 
            emit WithdrawCharityInterest(poolInterest, 0, _campaignId);
         }
     }

    /*
        Hard coded withdraw from the pool by the pool owner
        Will not be use in Mainnet

    */
    function withdrawInterestTest(uint _campaignId) external {
         //For now it will work with only 1 organization since the way the yeild is bearing take from cake contract

        require(campaigns[_campaignId]._owner == msg.sender, "Only Organization adming can withdraw");
        uint poolInterest = 100;
        campaigns[_campaignId]._usdcBalance -= poolInterest ;
        aaveLendingPool.withdraw(address(usdc), poolInterest, address(this)); 
        require(usdc.transfer(msg.sender,  poolInterest), "USDC Transfer failed!"); 
        emit WithdrawCharityInterest(poolInterest, 0, _campaignId);
         
     }

    /*
        Withdraw function will be implement in mainnet like a farm contract
        with shares and part of the total share for each campaign
        Since Aave on Kovan doesn't behave the same as Mainnet ( the Atokens don't occur interest)

    */

    function withdrawAllFunds(uint _campaignId) external {
        //For now it will work with only 1 organization since the way the yeild is bearing take from cake contract
        require(campaigns[_campaignId]._owner == msg.sender, "Only Organization adming can withdraw");

        uint aUsdcTotal = aUsdc.balanceOf(address(this));
        uint totalInterest = aUsdcTotal - totalUsdcBalance; 
        uint poolInterest = totalInterest / activeCampaigns; //Use only for MVP
        activeCampaigns--; 
        totalUsdcBalance -= campaigns[_campaignId]._usdcBalance;

        uint totalToWithdraw = campaigns[_campaignId]._usdcBalance + poolInterest;
        campaigns[_campaignId]._usdcBalance = 0;
        campaigns[campaignIndex]._state = campaignstate.Stopped;


        aaveLendingPool.withdraw(address(usdc), totalToWithdraw, address(this)); 
        require(usdc.transfer(msg.sender,  totalToWithdraw), "USDC Transfer failed!"); 
        emit WithdrawCharityInterest(totalToWithdraw, 0, _campaignId);

    }

}