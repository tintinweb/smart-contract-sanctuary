// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IDexRouter.sol";
import "./IBEP20.sol";
import "./SafeMath.sol";

contract AIRouter {
  using SafeMath for uint256;

  address private _aiTokenAddress;
  address private _routerAddress = 0x3380aE82e39E42Ca34EbEd69aF67fAa0683Bb5c1;
  address private _lpLockAddress = address(this);
  address private contractOwner;
  address private pair;

  bool private inSwap;
  bool private swapEnabled = true;

  uint256 private accuracy = 100;
  uint256 private target = 30;
  uint256 public swapThreshold = 50 * (10 ** 18); // 50 TOKENS
  
  uint256 public liqTaxShare = 50;
  uint256 public treasuryTaxShare = 20;
  uint256 public rewardTaxShare = 20;
  uint256 public devTaxShare = 10;

  uint256 public liqRoyaltyShare = 20;
  uint256 public treasuryRoyaltyShare = 30;
  uint256 public rewardRoyaltyShare = 40;
  uint256 public devRoyaltyShare = 10;

  uint256 public liqBalance = 0;
  uint256 public rewardBalance = 0;
  uint256 public devBalance = 0;
  uint256 public treasuryBalance = 0;

  address public rewardsBNBPool = 0x9423BbAb02a50541C3ecF9F4c659ED6EA332AF42;
  address public devBNBPool = 0x9423BbAb02a50541C3ecF9F4c659ED6EA332AF42;
  address public treasuryAddress = 0x5F55507507c8754b80c08A9791C46FfC15482F99;

  IBEP20 private aiContract;
  IDexRouter private router = IDexRouter(_routerAddress);

  mapping (address => bool) internal authorizations;

  constructor(address ai) {
    contractOwner = msg.sender;
    authorize(contractOwner);
    changeAiAddress(ai);

    aiContract.approve(address(router), type(uint256).max);
  }

  receive() external payable {
    if (!inSwap) {
      _distributeRoyalties(); 
    }
  }
  
  /**
  * Function modifier to require caller to be authorized
  */
  modifier authorized() {
    require(authorizations[msg.sender], "!AUTHORIZED"); _;
  }

  /**
  * Function modifier to require caller to be contract owner
  */
  modifier onlyOwner() {
    require(msg.sender == contractOwner, "!OWNER"); _;
  }

  /**
  * Function modifier to require caller to be AI contract
  */
  modifier onlyAi() {
    require(msg.sender == _aiTokenAddress, "!AI"); _;
  }

  /**
  * Function modifier to set inSwap to true while swapping
  */
  modifier swapping() {
		inSwap = true;
		_;
	  inSwap = false;
	}

  /**
    * Checks whether the contract is swapping coins on dex ATM
  */
  function isInSwap() external view returns (bool) {
    return inSwap;
  }

  function supportsDistribureFunction() external pure returns (bool) {
    return true;
  }

  function _shouldSwapBack() private view returns (bool) {
    return liqBalance >= swapThreshold
      && swapEnabled
      && msg.sender != pair
      && !inSwap;
  }

  /**
    * Adds liquidity to the exchange
  */
  function addLiquidity(uint256 AI, uint256 BNB) private {
    router.addLiquidityETH{value: BNB}(
			_aiTokenAddress,
			AI,
			0,
			0,
			_lpLockAddress,
			block.timestamp
		);
  }

  /**
    * Swaps AI to BNB on DEX and returns received amount
  */
  function _swapAI(uint256 swapAmount) private returns (uint256) {
    uint256 balanceBeforeSwap = address(this).balance;
    
    address[] memory path = new address[](2);
    path[0] = _aiTokenAddress;
    path[1] = router.WETH();
    
    router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        swapAmount,
        0,
        path,
        address(this),
        block.timestamp
    );

    uint256 bnbReceived = address(this).balance.sub(balanceBeforeSwap);
    return bnbReceived;
  }

  /**
    * Swaps BNB to AI on DEX and returns received amount
  */
  function _swapBNB(uint256 swapAmount) private returns (uint256) {
    uint256 balanceBeforeSwap = aiContract.balanceOf(address(this));
    
    address[] memory path = new address[](2);
    path[0] = router.WETH();
    path[1] = _aiTokenAddress;
    router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: swapAmount}(0, path, address(this), block.timestamp);

    uint256 aiReceived = aiContract.balanceOf(address(this)).sub(balanceBeforeSwap);
    return aiReceived;
  }

  /**
    * Handles transfer to reward and dev pools
  */
  function _distributeFees(uint256 shareA, uint256 shareB) internal {
    if (shareA > 0) { 
      (bool sent, bytes memory data) = rewardsBNBPool.call{value: shareA}("");
      require(sent, "Failed to send BNB");
    }
    if (shareB > 0) { 
      (bool sent, bytes memory data) = devBNBPool.call{value: shareB}("");
      require(sent, "Failed to send BNB");
    }
  }

  /**
    * Handles auto-liquidity logic
  */
  function liquify() internal swapping {
    uint256 aiForLiqToSwap = isOverLiquified() ? swapThreshold : swapThreshold.div(2);
    uint256 rewardToSwap = rewardBalance.mul(swapThreshold).div(liqBalance);
    uint256 devToSwap = devBalance.mul(swapThreshold).div(liqBalance);
    uint256 aiToSwap = aiForLiqToSwap.add(rewardToSwap).add(devToSwap);

    uint256 bnbReceived = _swapAI(aiToSwap);
    uint256 bnbForLiq = bnbReceived.mul(aiForLiqToSwap).div(aiToSwap);
    uint256 bnbForRewards = bnbReceived.mul(rewardToSwap).div(aiToSwap);
    uint256 bnbForDev = bnbReceived.mul(devToSwap).div(aiToSwap);

    if (isOverLiquified()) {
      (bool sent, bytes memory data) = rewardsBNBPool.call{value: bnbForLiq}("");
      require(sent, "Failed to send Ether");
    } else {
      addLiquidity(aiForLiqToSwap, bnbForLiq);
    }

    _distributeFees(
      bnbForRewards,
      bnbForDev
    );
    
    liqBalance = liqBalance.sub(swapThreshold);
    rewardBalance = rewardBalance.sub(rewardToSwap);
    devBalance = devBalance.sub(devToSwap);
  }

  /**
    * The function is triggered upon BNB received to the contract, and it routes BNB to different wallets (or just adds AI to the balance)
  */
  function _distributeRoyalties() internal {
    uint256 receivedAmount = msg.value;
    uint256 aiReceived = _swapBNB(receivedAmount.div(2));

    uint256 aiForLiq = _calculateShare(aiReceived.mul(2), liqRoyaltyShare);
    uint256 toAiTreasury = _calculateShare(aiReceived.mul(2), treasuryRoyaltyShare);
    uint256 bnbToReward = _calculateShare(receivedAmount, rewardRoyaltyShare);
    uint256 bnbToDev = _calculateShare(receivedAmount, devRoyaltyShare);

    liqBalance += aiForLiq;
    aiContract.transfer(treasuryAddress, toAiTreasury);

    _distributeFees(bnbToReward, bnbToDev);

    if (_shouldSwapBack()) { liquify(); }
  }
  
  /**
    * The function is called by AI contract upon AI tax is transfered to this contract. It routes AI to different wallets (or just adds AI to the balance), might trigger auto-liquidity as well.
  */
  function distributeTax(uint256 amount) external onlyAi {
    if (amount > 0) {
      uint256 aiForLiq = _calculateShare(amount, liqTaxShare);
      uint256 aiForRewards = _calculateShare(amount, rewardTaxShare);
      uint256 aiForDev = _calculateShare(amount, devTaxShare);
      uint256 toAiTreasury = _calculateShare(amount, treasuryTaxShare);

      liqBalance += aiForLiq;
      rewardBalance += aiForRewards;
      devBalance += aiForDev;
      treasuryBalance += toAiTreasury;
    }
  }
  
  function liquifyBack() external onlyAi {
    aiContract.transfer(treasuryAddress, treasuryBalance);
    treasuryBalance = 0;
      
    if (_shouldSwapBack()) { liquify(); }
  }

  /**
    * Checks the pair AI balance share compeared to the total supply.
  */
  function getLiquidityBacking() private view returns (uint256) {
    return accuracy.mul(aiContract.balanceOf(pair).mul(2)).div(aiContract.totalSupply());
  }
  function isOverLiquified() private view returns (bool) {
    return getLiquidityBacking() > target;
  }
  
  function _calculateShare(uint256 amount, uint256 share) private pure returns (uint256) {
    return amount.mul(share).div(100);
  }

  function _validateShares(uint256[] memory shares) private pure returns (bool) {
    uint256 shareSum = 0;
    for (uint256 i = 0; i < shares.length; i++) {
      shareSum += shares[i];
    }

    if (shareSum == 100) { return true; }
    return false;
  }

  function changeTaxShares(uint256[] memory shares) public onlyOwner {
    require(shares.length != 4, 'wrong number of shares provided');
    require(_validateShares(shares), 'sum is not 100');

    liqTaxShare = shares[0];
    treasuryTaxShare = shares[1];
    rewardTaxShare = shares[2];
    devTaxShare = shares[3];
  }

  function changeRoyaltyShares(uint256[] memory shares) public onlyOwner {
    require(shares.length != 4, 'wrong number of shares provided');
    require(_validateShares(shares), 'sum is not 100');

    liqRoyaltyShare = shares[0];
    treasuryRoyaltyShare = shares[1];
    rewardRoyaltyShare = shares[2];
    devRoyaltyShare = shares[3];
  }

  function changeRewardAddress(address addr) public onlyOwner {
    rewardsBNBPool = addr;
  }

  function changeDevAddress(address addr) public onlyOwner {
    devBNBPool = addr;
  }

  function changeTreasuryAddress(address addr) public onlyOwner {
    treasuryAddress = addr;
  }

  function changeSwapThresholdAmount(uint256 newValue) public onlyOwner {
    require(newValue >= 1 * 10**18, 'swapThreshold cannot be less then 1 token');
    swapThreshold = newValue;
  }

  function changeRouterAddress(address newRouterAddress) public onlyOwner {
    require(IDexRouter(newRouterAddress).WETH() != address(0), 'provide valid router address');
    _routerAddress = newRouterAddress;
    router = IDexRouter(_routerAddress);
  }

  function changeLpLockAddress(address newLpAddress) public onlyOwner {
    require(newLpAddress != address(0), 'should not be 0 address');
    _lpLockAddress = newLpAddress;
  }

  function changePairAddress(address newPairAddress) public onlyOwner {
    require(newPairAddress != address(0), 'should not be 0 address');
    pair = newPairAddress;
  }

  /**
  * @dev Only owner can call this function. Activates tax collection.
  */
  function changeAiAddress(address ai) public onlyOwner {
    require(ai != address(0), 'Should not be a 0 address');
    require(IBEP20(ai).balanceOf(address(0)) == 0, 'Not valid router'); // check the balanceOf method

    _aiTokenAddress = ai;
    aiContract = IBEP20(_aiTokenAddress);
    authorize(_aiTokenAddress);
  }

  /**
  * @dev Only owner can call this function. Transfer ownership to new address. Caller must be owner.
  */
  function transferOwnership(address payable adr) public onlyOwner {
      require(adr != address(0), 'Should not be a 0 address');
      contractOwner = adr;
      authorizations[contractOwner] = true;
  }
  /**
    * Authorize address. Owner only
  */
  function authorize(address adr) public onlyOwner {
      authorizations[adr] = true;
  }
  
  /**
    * Remove address' authorization. Owner only
    */
  function unauthorize(address adr) public onlyOwner {
      authorizations[adr] = false;
  }

	// Recover any BNB and AI sent to the contract is case of migration.
	function rescue() external onlyOwner {
    liqBalance = 0;
    rewardBalance = 0;
    devBalance = 0;
    treasuryBalance = 0;

    uint256 aiBalance = aiContract.balanceOf(address(this));
    aiContract.transfer(contractOwner, aiBalance);

    (bool sent, bytes memory data) = contractOwner.call{value: address(this).balance}("");
    require(sent, "Failed to send BNB");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IDexRouter {
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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

  function burn(uint256 burnQuantity) external returns (bool);

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


  function claim(uint256[] memory tokenIndices) external returns (uint256);

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