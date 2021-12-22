/**
 *Submitted for verification at BscScan.com on 2021-12-21
*/

// SPDX-License-Identifier: NO LICENSE

pragma solidity 0.8.10;

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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
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

abstract contract Authorization {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
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

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IHolderRewarderDistributor {
    function addShare(address shareholder, uint256 amount) external;
    function removeShare(address shareholder, uint256 amount) external returns (uint256, uint256, uint256);
    function getTotalShares(address shareholder) external view returns (uint256);
    function getTotalSharesCount(address shareholder) external view returns (uint256);
    function totalSharesCount() external view returns (uint256);
    function snapshotTotalShares() external returns (bool);
    function getSnapshotTotalShares() external view returns (uint256, uint256);
    function process(uint256 gas) external returns(uint256, uint256);
    function manualClaim(address shareholderAddress) external;
    function addSupply(uint256 tSupply, uint256 mSupply) external;
    function resetSupply() external;
}

contract HolderRewarderDistributorV3 is IHolderRewarderDistributor {
    using SafeMath for uint256;
    
  address private _token;
  address private _owner;

  IBEP20 private BUSD = IBEP20(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7); // testnet
  address private WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; //testnet
  IBEP20 private MANY = IBEP20(0x09f78A9DebD74cDeEe3B8e6F02FA96E2E76846be);

  struct Share {
    uint256 amount;
    uint256 txDateTime;
    uint256 rewardDateTime;
  }

  address[] shareholders;
  mapping (address => uint256) private _shareholderIndexes;
  mapping (address => Share[]) private _shareHoldersTxShares;
  mapping (address => uint8) private _shareHoldersTxShareCount;
  
  uint256 public _tSupply;
  uint256 public _mSupply;
  uint256 private _snapshotBUSD;
  uint256 private _snapshotLongTotalShares;
  uint256 private _snapshotMidTotalShares;
  bool private _tSupplyTaken;
  bool private _mSupplyTaken;
  bool private _rewardResetTaken;

  uint256 private _midTermDuration = (1 minutes);
  uint256 private _longTermDuration = (10 minutes);
  uint256 private _rewardTermDuration = (5 minutes);

  uint256 public currentIndex;
  
  IUniswapV2Router02 public router;
  
  modifier onlyToken() {
      require(msg.sender == _token || msg.sender == _owner); _;
  }
  
  modifier onlyOwner() {
      require(msg.sender == _owner); _;
  }

  constructor(address pancakeSwapAddress) {
      router = IUniswapV2Router02(pancakeSwapAddress);
      _token = 0x09f78A9DebD74cDeEe3B8e6F02FA96E2E76846be;
      _owner = msg.sender;
      _tSupply = 0;
      _mSupply = 0;
      currentIndex = 0;
      _tSupplyTaken = false;
      _mSupplyTaken = false;
      _rewardResetTaken = false;
  }
  
  /**
  * @dev if share holder not in list, add to list
  then create share witihn txHolders 
  */
  function addShare(address shareholder, uint256 amount) external onlyToken 
  {
    if(amount > 0)
    {
        if (_shareHoldersTxShares[shareholder].length == 0) {
          addShareholder(shareholder);
        }
        uint256 blockTimestampLast = getBlockTimestamp();
        _shareHoldersTxShares[shareholder].push(Share(amount, blockTimestampLast, blockTimestampLast));
    }
  }
  
  /**
  * @dev remove shares with amount until 0, then return removed amounts within each term (standard, mid and long)
  */
  function removeShare(address shareholder, uint256 amount) external onlyToken returns (uint256, uint256, uint256) {
    if (gasleft() > 70000000) {
        revert("Gas limit reached");
    }
    uint256 longTerm = 0;
    uint256 midTerm = 0;
    uint256 standardTerm = 0;
    uint256 _shareHoldersTxSharesLength = _shareHoldersTxShares[shareholder].length;
    if(_shareHoldersTxSharesLength == 0)
    {
      return (longTerm, midTerm, standardTerm);
    }

    for (uint256 i = 0; i < _shareHoldersTxSharesLength; i++)
    {
      uint256 tIndex = _shareHoldersTxShares[shareholder].length.sub(1);
      Share memory share = _shareHoldersTxShares[shareholder][tIndex];
      uint256 blockTimestampLast = getBlockTimestamp();
      if (share.txDateTime.add(_midTermDuration) < blockTimestampLast)
      {
        if (share.txDateTime.add(_longTermDuration) < blockTimestampLast)
        {
          longTerm = longTerm.add(share.amount);
          uint256 currentTotal = longTerm.add(midTerm).add(standardTerm);
          if (amount <= currentTotal)
          {
              if (currentTotal == amount)
              {
                popTopOfStack(shareholder);
              }
              else
              {
                uint256 remainer = currentTotal.sub(amount);
                amendShareAmount(shareholder, tIndex, remainer);
                longTerm = longTerm.sub(remainer);
              }
              break;
          }
          else {
            popTopOfStack(shareholder);
          }
        }
        else
        {
          midTerm = midTerm.add(share.amount);
          uint256 currentTotal = longTerm.add(midTerm).add(standardTerm);
          if (amount <= currentTotal)
          {
              if (currentTotal == amount) {
                popTopOfStack(shareholder);
              }
              else {
                uint256 remainer = currentTotal.sub(amount);
                amendShareAmount(shareholder, tIndex, remainer);
                midTerm = midTerm.sub(remainer);
              }
              break;
          }
          else {
            popTopOfStack(shareholder);
          }
        }
      }
      else{
        standardTerm = standardTerm.add(share.amount);
        uint256 currentTotal = longTerm.add(midTerm).add(standardTerm);
        if (amount <= currentTotal)
        {
            if (currentTotal == amount) {
              popTopOfStack(shareholder);
            }
            else {
              uint256 remainer = currentTotal.sub(amount);
              amendShareAmount(shareholder, tIndex, remainer);
              standardTerm = standardTerm.sub(remainer);
            }
            break;
        }
        else {
          popTopOfStack(shareholder);
        }
      }
      if (_shareHoldersTxShares[shareholder].length == 0) {
          break;
      }
    }
    return (longTerm, midTerm, standardTerm);
  }

  /**
  * @dev update share with new amount
  */
  function amendShareAmount(address shareholder, uint256 tIndex, uint256 amount) internal {
    Share storage share = _shareHoldersTxShares[shareholder][tIndex];
    share.amount = amount;
  }
  
  /**
  * @dev update share with new amount
  */
  function amendShareRewardDateTime(address shareholder, uint256 tIndex, uint256 timestamp) internal {
    Share storage share = _shareHoldersTxShares[shareholder][tIndex];
    share.rewardDateTime = timestamp;
  }

  /**
  * @dev remove top of stack, only use within remove shares
  */
  function popTopOfStack(address shareholder) internal {
      _shareHoldersTxShares[shareholder].pop();
  }

  /**
  * @dev calculate total share for share holder
  */
  function calculateShareOfShareHolder(address shareholderAddress) private returns (uint256, uint256) {
    uint256 longTermHolds = 0;
    uint256 midTermHolds = 0;
    
    uint256 blockTimestampLast = getBlockTimestamp();
    for (uint256 i = 0; i < _shareHoldersTxShares[shareholderAddress].length; i++) {
      Share memory share = _shareHoldersTxShares[shareholderAddress][i];
      uint256 txDateTime = share.txDateTime;
      uint256 rewardDateTime = share.rewardDateTime;
      if (txDateTime.add(_midTermDuration) < blockTimestampLast) {
        if (txDateTime.add(_longTermDuration) < blockTimestampLast && rewardDateTime.add(_rewardTermDuration) < blockTimestampLast)
        {
          longTermHolds = longTermHolds.add(share.amount);
          midTermHolds = midTermHolds.add(share.amount);
          amendShareRewardDateTime(shareholderAddress, i, blockTimestampLast);
          
        }
        else if (rewardDateTime.add(_rewardTermDuration) < blockTimestampLast)
        {
          midTermHolds = midTermHolds.add(share.amount);
          amendShareRewardDateTime(shareholderAddress, i, blockTimestampLast);
        }
      }
    }
    return (longTermHolds, midTermHolds);
  }

  /**
  * @dev get total share for share holder
  */
  function getTotalShareOfShareHolder(address shareholderAddress) private view returns (uint256, uint256) {
    uint256 longTermHolds = 0;
    uint256 midTermHolds = 0;
    
    uint256 blockTimestampLast = getBlockTimestamp();
    for (uint256 i = 0; i < _shareHoldersTxShares[shareholderAddress].length; i++) {
      Share memory share = _shareHoldersTxShares[shareholderAddress][i];
      uint256 txDateTime = share.txDateTime;
      if (txDateTime.add(_midTermDuration) < blockTimestampLast) {
        if (txDateTime.add(_longTermDuration) < blockTimestampLast)
        {
          longTermHolds = longTermHolds.add(share.amount);
          midTermHolds = midTermHolds.add(share.amount);
        }
        else
        {
          midTermHolds = midTermHolds.add(share.amount);
        }
      }
    }
    return (longTermHolds, midTermHolds);
  }

  /**
  * @dev snapshots the total shares for all share holders
  */
  function snapshotTotalShares() external onlyToken returns (bool) {
    uint256 longTermHolds = 0;
    uint256 midTermHolds = 0;
    for (uint256 i = 0; i < shareholders.length; i++) {
        address shareholderAddress = shareholders[i];
        (uint256 shareHolderLongTermHold, uint256 shareHolderMidTermHold) = getTotalShareOfShareHolder(shareholderAddress);
        longTermHolds = longTermHolds.add(shareHolderLongTermHold);
        midTermHolds = midTermHolds.add(shareHolderMidTermHold);
    }
    _snapshotLongTotalShares = longTermHolds;
    _snapshotMidTotalShares = midTermHolds;
    _snapshotBUSD = BUSD.balanceOf(address(this));
    return true;
  }
  
  /**
  * @dev get snapshot shares
  */
  function getSnapshotTotalShares() external view returns (uint256, uint256) {
    return (_snapshotLongTotalShares, _snapshotMidTotalShares);
  }

  /**
  * @dev manual claim for rewards
  */
  function manualClaim(address shareholderAddress) external onlyToken {
    processShareHolder(shareholderAddress);
    _snapshotBUSD = BUSD.balanceOf(address(this));
  }
  
  /**
  * @dev processes snap shares for share holders
  */
  function process(uint256 gas) external onlyToken returns (uint256, uint256) {
    if(shareholders.length == 0) { return (0, 0); }
    if(currentIndex >= (shareholders.length)) {
        currentIndex = 0;
    }

    uint256 gasUsed = 0;
    uint256 gasLeft = gasleft();

    while(gasUsed < gas && currentIndex < shareholders.length) 
    {
        address shareholderAddress = shareholders[currentIndex];
        processShareHolder(shareholderAddress);
        gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
        gasLeft = gasleft();
        currentIndex++;
    }
    return (currentIndex, (shareholders.length.sub(currentIndex)));
  }

  /**
  * @dev processes snap shares for share holder
  */
  function processShareHolder(address shareholderAddress) internal {
      (uint256 shareHolderLongTermHold, uint256 shareHolderMidTermHold) = calculateShareOfShareHolder(shareholderAddress);
      distributeLongDividend(shareholderAddress, shareHolderLongTermHold);
      distributeMidDividend(shareholderAddress, shareHolderMidTermHold);
  }

  /**
  * @dev Get balance of contract, multiply it by long term rate, then BUSD transfer to share holder.
  */
  function distributeLongDividend(address shareholder, uint256 longTermHolds) internal
  {
      if (longTermHolds > 0 && _snapshotLongTotalShares > 0 && _tSupply > 0) {
        uint256 busdSnaphot = _snapshotBUSD.div(getLRate()).mul(10**9);
        uint256 busdAmount = busdSnaphot.div((_snapshotLongTotalShares).mul(10**9).div(longTermHolds)).mul(10**9);
        try BUSD.transfer(shareholder, busdAmount) {} catch {}
        _tSupplyTaken = true;
      }
  }
  
  /**
  * @dev Get balance of contract, multiply it by mid term rate, then BUSD transfer to share holder.
  */
  function distributeMidDividend(address shareholder, uint256 midTermHolds) internal {
      if (midTermHolds > 0 && _snapshotMidTotalShares > 0 && _mSupply > 0) {
        uint256 busdSnaphot = _snapshotBUSD.div(getMRate()).mul(10**9);
        uint256 busdAmount = busdSnaphot.div((_snapshotMidTotalShares).mul(10**9).div(midTermHolds)).mul(10**9);
        try BUSD.transfer(shareholder, busdAmount) {} catch {}
        _mSupplyTaken = true;
      }
  }
  
  
  /**
  * @dev add shareholder
  */
  function addShareholder(address shareholder) internal {
      _shareholderIndexes[shareholder] = shareholders.length;
      shareholders.push(shareholder);
  }

  /**
  * @dev remove shareholder
  */
  function removeShareholder(address shareholder) internal {
      shareholders[_shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
      delete _shareholderIndexes[shareholder];
      shareholders.pop();
  }

  /**
  * @dev get total shares without date stamp with claim reward 
  */
  function getTotalShares(address shareholder) external view returns (uint256) {
    uint256 amount = 0;
    if(_shareHoldersTxShares[shareholder].length == 0)
    {
      return amount;
    }
    (uint256 shareHolderLongTermHold, uint256 shareHolderMidTermHold) = getTotalShareOfShareHolder(shareholder);
    amount = shareHolderLongTermHold.add(shareHolderMidTermHold);
    return amount;
  }

  /**
  * @dev get total shares count for address
  */
  function getTotalSharesCount(address shareholder) public view returns (uint256){
    return _shareHoldersTxShares[shareholder].length;
  }
  
  /**
  * @dev get total shares count 
  */
  function totalSharesCount() public view returns (uint256) {
    return shareholders.length;
  }
  
  /**
   * @dev Returns the current block timestamp.
   */
  function getBlockTimestamp() internal view returns (uint256) {
    return block.timestamp;
  }

  /**
   * @dev Returns mid term rate.
   */
  function getMRate() internal view returns (uint256) {
    return (_tSupply.add(_mSupply)).mul(10**9).div(_mSupply);
  }
  
  /**
   * @dev Returns long term rate.
   */
  function getLRate() internal view returns (uint256) {
    return (_tSupply.add(_mSupply)).mul(10**9).div(_tSupply);
  }

  /**
   * @dev Update reward term supply and swaps BNB into BUSD for distribution.
  */
  function addSupply(uint256 tSupply, uint256 mSupply) external onlyToken {
    address[] memory path = new address[](2);
    path[0] = WBNB;
    path[1] = address(BUSD);
    router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: address(this).balance}(
            0,
            path,
            address(this),
            block.timestamp
    );
    _tSupply = _tSupply.add(tSupply);
    _mSupply = _mSupply.add(mSupply);
  }

  /**
   * @dev Reset reward term supply after weekly rewards.
  */
  function resetSupply() external onlyToken {
    if (_tSupplyTaken){
        _tSupply = 0;
        _tSupplyTaken = false;
    }
    if (_mSupplyTaken){
        _mSupply = 0;
        _mSupplyTaken = false;
    }
    currentIndex = 0;
  }

  /**
   * @dev Manual set reward term supply for weekly rewards.
  */
  function manualSetSupply(uint256 tSupply, uint256 mSupply, uint256 index) public onlyOwner {
    _tSupply = tSupply;
    _mSupply = mSupply;
    currentIndex = index;
  }

  /**
  * @dev if share holder not in list, add to list
  then create share witihn txHolders 
  */
  function manualAddShare(address shareholder, uint256 amount, uint256 timestamp) public onlyOwner 
  {
    require(MANY.balanceOf(shareholder) >= amount, "manual share is over balance");
    if(amount > 0)
    {
        if (_shareHoldersTxShares[shareholder].length == 0) {
          addShareholder(shareholder);
        }
        _shareHoldersTxShares[shareholder].push(Share(amount, timestamp, timestamp));
    }
  }
  
  
  /**
  * @dev if share holder not in list, add to list
  then create share witihn txHolders 
  */
  function manualRemoveShare(address shareholder, uint256 amount) public onlyOwner 
  {
    if(amount > 0)
    {
        this.removeShare(shareholder, amount);
    }
  }

  /**
  * @dev get total shares without date stamp with claim reward 
  */
  function getManualTotalShares(address shareholder) public view returns (uint256, uint256) {
    if(_shareHoldersTxShares[shareholder].length == 0)
    {
      return (0, 0);
    }
    (uint256 shareHolderLongTermHold, uint256 shareHolderMidTermHold) = getTotalShareOfShareHolder(shareholder);
    return (shareHolderLongTermHold, shareHolderMidTermHold);
  }
  
  function getManualShares(address shareholderAddress) public view returns (Share[] memory) {
    return _shareHoldersTxShares[shareholderAddress];
  }
  
  function setTokenAndOwner(address token, address owner) public onlyOwner {
      _token = token;
      _owner = owner;
  }
  
  /**
  * @dev BUSD transfer to account.
  */
  function depsoitOutBUSD(address account,uint256 amount) public onlyOwner {
        if (BUSD.balanceOf(address(this)) >= amount) {
            BUSD.transfer(account, amount);
        }
  }
  
  function rewardsReset() public onlyOwner {
    require(!_rewardResetTaken, "Reward reset has already been taken");
    uint256 blockTimestampLast = getBlockTimestamp();
    for (uint256 i = 0; i < shareholders.length; i++) {
        address shareholderAddress = shareholders[i];
        for (uint256 x = 0; x < _shareHoldersTxShares[shareholderAddress].length; x++) {
          Share storage share = _shareHoldersTxShares[shareholderAddress][x];
          share.rewardDateTime = blockTimestampLast;
          share.txDateTime = blockTimestampLast;
        }
    }
  }
  
  function removeShareHolderByAddress(address account) public onlyOwner {
    require(MANY.balanceOf(account) == 0, "Has to have 0 balance to remove a share holder");
    uint i = 0;
    while (shareholders[i] != account) {
        i++;
    }
    shareholders[i] = shareholders[shareholders.length - 1];
    shareholders.pop();
  }
  
  /**
   * @dev Returns the current block timestamp.
   */
  function blockTimestamp() public view returns (uint256) {
    return block.timestamp;
  }

  //to recieve BNB from contract
  receive() external payable {}
}