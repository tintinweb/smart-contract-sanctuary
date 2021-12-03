/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

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
    function snapshotTotalShares() external returns (bool);
    function depositMid() external payable;
    function depositLong() external payable;
    function process(uint256 gas) external;
}

contract HolderRewarderDistributor is IHolderRewarderDistributor {
    using SafeMath for uint256;
    
  address _token;
  address _midAddress;
  address _longAddress;

  //TODO: CHECK ADDRESS
  // IBEP20 BUSD = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
  // address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
  IBEP20 BUSD = IBEP20(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7); // testnet
  address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; //testnet

  struct Share {
    uint256 amount;
    uint256 txDateTime;
    uint256 rewardDateTime;
  }

  address[] shareholders;
  mapping (address => uint256) shareholderIndexes;
  mapping (address => Share[]) private _shareHoldersTxShares;
  mapping (address => uint8) private _shareHoldersTxShareCount;
  
  uint256 private _snapshotLongTotalShares;
  uint256 private _snapshotMidTotalShares;

  uint256 currentIndex;
  
  IUniswapV2Router02 router;

  mapping (string => uint256) private holderRewardersTxPeriodAmounts;
  
  modifier onlyToken() {
      require(msg.sender == _token); _;
  }
  
  modifier onlyMid() {
      require(msg.sender == _midAddress); _;
  }
  
  modifier onlyLong() {
      require(msg.sender == _longAddress); _;
  }

  constructor (address _router, address midAddress, address longAddress) 
  {
      router = IUniswapV2Router02(_router);
      _token = msg.sender;
      _midAddress = midAddress;
      _longAddress = longAddress;
  }
  
  function addShare(address shareholder, uint256 amount) external onlyToken 
  {
    if(amount > 0 && _shareHoldersTxShares[shareholder].length == 0)
    {
        addShareholder(shareholder);
    }

    if (amount > 0)
    {  
      uint256 blockTimestampLast = getBlockTimestamp();
      _shareHoldersTxShares[shareholder].push(Share(amount, blockTimestampLast, blockTimestampLast));
    }
  }
  
  function removeShare(address shareholder, uint256 amount) external onlyToken returns (uint256, uint256, uint256) {
    uint256 longTerm = 0;
    uint256 midTerm = 0;
    uint256 standardTerm = 0;
    bool feesTaken = false;
    if(_shareHoldersTxShares[shareholder].length == 0)
    {
      return (longTerm, midTerm, standardTerm);
    }
    while (!feesTaken)
    { 
      uint256 tIndex = (_shareHoldersTxShares[shareholder].length - 1);
      uint256 tx_datetime = _shareHoldersTxShares[shareholder][tIndex].txDateTime;
      uint256 blockTimestampLast = getBlockTimestamp();
      if (tx_datetime + 7 days < blockTimestampLast)
      {
        if (tx_datetime + 90 days < blockTimestampLast)
        {
          longTerm += _shareHoldersTxShares[shareholder][tIndex].amount;
          if (amount < (longTerm + midTerm + standardTerm))
          {
              uint256 remaining = (longTerm + midTerm + standardTerm) - amount;
              if (remaining == 0)
              {
                removeFromShareHolders(shareholder, tIndex);
              }
              else
              {
                _shareHoldersTxShares[shareholder][tIndex].amount = (_shareHoldersTxShares[shareholder][tIndex].amount - amount);
                longTerm = longTerm - _shareHoldersTxShares[shareholder][tIndex].amount;
                feesTaken = true;
                break;
              }
          }
          else {
            removeFromShareHolders(shareholder, tIndex);
          }
        }
        else
        {
          midTerm += _shareHoldersTxShares[shareholder][tIndex].amount;
          if (amount < (longTerm + midTerm + standardTerm))
          {
              uint256 remaining = (longTerm + midTerm + standardTerm) - amount;
              if (remaining == 0){
                removeFromShareHolders(shareholder, tIndex);
              }
              else{
                _shareHoldersTxShares[shareholder][tIndex].amount = (_shareHoldersTxShares[shareholder][tIndex].amount - amount);
                midTerm = midTerm - _shareHoldersTxShares[shareholder][tIndex].amount;
                feesTaken = true;
                break;
              }
          }
          else {
            removeFromShareHolders(shareholder, tIndex);
          }
        }
      }
      else{
        standardTerm += _shareHoldersTxShares[shareholder][tIndex].amount;
        if (amount < (longTerm + midTerm + standardTerm))
        {
            uint256 remaining = (longTerm + midTerm + standardTerm) - amount;
            if (remaining == 0){
              removeFromShareHolders(shareholder, tIndex);
            }
            else{
              _shareHoldersTxShares[shareholder][tIndex].amount = (_shareHoldersTxShares[shareholder][tIndex].amount - amount);
              standardTerm = standardTerm - _shareHoldersTxShares[shareholder][tIndex].amount;
              feesTaken = true;
              break;
            }
        }
        else {
          removeFromShareHolders(shareholder, tIndex);
        }
      }
    }
    return (longTerm, midTerm, standardTerm);
  }

  function removeFromShareHolders(address shareholder, uint index) internal {
      if (index >= _shareHoldersTxShares[shareholder].length) return;

      for (uint i = index; i<_shareHoldersTxShares[shareholder].length-1; i++){
          _shareHoldersTxShares[shareholder][i] = _shareHoldersTxShares[shareholder][i+1];
      }
      delete _shareHoldersTxShares[shareholder][_shareHoldersTxShares[shareholder].length-1];
      _shareHoldersTxShareCount[shareholder] = uint8(_shareHoldersTxShares[shareholder].length);
  }

  function calculateShareOfShareHolder(address shareholderAddress, bool excludeIfRewarded) private returns (uint256, uint256) {
    uint256 longTermHolds = 0;
    uint256 midTermHolds = 0;
    uint8 count = _shareHoldersTxShareCount[shareholderAddress];
    uint8 txInteration = 0;
    while (txInteration < count)
    {
        uint8 trCount = count - txInteration;
        uint256 txDateTime = _shareHoldersTxShares[shareholderAddress][trCount].txDateTime;
        uint256 rewardDateTime = _shareHoldersTxShares[shareholderAddress][trCount].rewardDateTime;
        uint256 blockTimestampLast = getBlockTimestamp();
        if (txDateTime + 7 days < blockTimestampLast)
        {
          bool rewardCheck = excludeIfRewarded ? rewardDateTime - 7 days < txDateTime : true;
          if (txDateTime + 90 days < blockTimestampLast && rewardCheck)
          {
            longTermHolds += _shareHoldersTxShares[shareholderAddress][trCount].amount;
            _shareHoldersTxShares[shareholderAddress][trCount].rewardDateTime = blockTimestampLast;
          }
          else if (rewardCheck)
          {
            midTermHolds += _shareHoldersTxShares[shareholderAddress][trCount].amount;
            _shareHoldersTxShares[shareholderAddress][trCount].rewardDateTime = blockTimestampLast;
          }
        }
    }
    return (longTermHolds, midTermHolds);
  }

  function snapshotTotalShares() external returns (bool) {
    uint256 longTermHolds = 0;
    uint256 midTermHolds = 0;
    for (uint256 i = 0; i < shareholders.length; i++) {
        address shareholderAddress = shareholders[i];
        (uint256 shareHolderLongTermHold, uint256 shareHolderMidTermHold) = calculateShareOfShareHolder(shareholderAddress, false);
        longTermHolds += shareHolderLongTermHold;
        midTermHolds += shareHolderMidTermHold;
    }
    _snapshotLongTotalShares = longTermHolds;
    _snapshotMidTotalShares = midTermHolds;
    return true;
  }
  
  function process(uint256 gas) external {
    uint256 shareholderCount = shareholders.length;
  
    if(shareholderCount == 0) { return; }

    uint256 gasUsed = 0;
    uint256 gasLeft = gasleft();

    uint256 iterations = 0;
    
    while(gasUsed < gas && iterations < shareholderCount) 
    {
        if(currentIndex >= shareholderCount) {
            currentIndex = 0;
        }
        address shareholderAddress = shareholders[currentIndex];
        (uint256 shareHolderLongTermHold, uint256 shareHolderMidTermHold) = calculateShareOfShareHolder(shareholderAddress, true);
        if (msg.sender == _longAddress) {
          distributeLongDividend(shareholderAddress, shareHolderLongTermHold);
        }
        else if (msg.sender == _midAddress) {
          distributeMidDividend(shareholderAddress, shareHolderMidTermHold);
        }
        gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
        gasLeft = gasleft();
        currentIndex++;
        iterations++;
    }
  }

  function distributeLongDividend(address shareholder, uint256 longTermHolds) internal onlyLong
  {
      if (longTermHolds > 0) {
        uint256 perc = longTermHolds.div(_snapshotLongTotalShares);
        BUSD.transferFrom(_longAddress, shareholder, (BUSD.balanceOf(_longAddress) * perc));
      }
  }
  

  function distributeMidDividend(address shareholder, uint256 midTermHolds) internal onlyMid {
      if (midTermHolds > 0) {
        uint256 perc = midTermHolds.div(_snapshotMidTotalShares);
        BUSD.transferFrom(_midAddress, shareholder, (BUSD.balanceOf(_midAddress) * perc));
      }
  }
  
  function depositMid() external payable override onlyLong {
      address[] memory path = new address[](2);
      path[0] = WBNB;
      path[1] = address(BUSD);

      router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
          0,
          path,
          _midAddress,
          block.timestamp
      );
  }
  
  function depositLong() external payable override onlyMid {
      address[] memory path = new address[](2);
      path[0] = WBNB;
      path[1] = address(BUSD);

      router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
          0,
          path,
          _longAddress,
          block.timestamp
      );
  }
  
  function addShareholder(address shareholder) internal {
      shareholderIndexes[shareholder] = shareholders.length;
      shareholders.push(shareholder);
      _shareHoldersTxShareCount[shareholder] = 0;
  }

  function removeShareholder(address shareholder) internal {
      shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
      shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
      _shareHoldersTxShareCount[shareholders[shareholders.length-1]] = _shareHoldersTxShareCount[shareholder];
      shareholders.pop();
  }

  function getTotalShares(address shareholder) external view returns (uint256) {
    uint256 amount = 0;
    if(_shareHoldersTxShares[shareholder].length == 0)
    {
      return amount;
    }
    for (uint256 i = 0; i < _shareHoldersTxShares[shareholder].length; i++) {
        amount += _shareHoldersTxShares[shareholder][i].amount;
    }
    return amount;
  }

  function getTotalSharesCount(address shareholder) public view returns (uint256){
    return _shareHoldersTxShares[shareholder].length;
  }
  
  function getBlockTimestamp() internal view returns (uint256) {
    return block.timestamp;
  }
}

contract Zoomy is IBEP20, Authorization {
  using SafeMath for uint256;

  struct TaxFees {
    uint256 _longTermFee;
    uint256 _midTermFee;
    uint256 _operationFee;
    uint256 _philanthoryFee;
    uint256 _burnFee;
    uint256 _lottoFee;
    uint256 _liquidityFee;
  }

  struct FounderSupply {
    uint256 unlockedAmount;
    uint256 totalAmount;
  }

  mapping (address => uint256) private _balances;
  mapping (address => FounderSupply) private _lockedBalances;
  mapping (address => mapping (address => uint256)) public _allowances;
  
  mapping (address => bool) private _isExcludedFromFee;
  mapping (address => bool) private _isExcluded;
  mapping (address => bool) private _isLocked;
  
  mapping (string => TaxFees) private _taxMatrix;

  uint256 private _totalSupply;
  uint256 private _totalLocked;
  
  uint8 private _decimals = 9;
  uint256 private _initalFragmentsSupply = 5000000000 * 10**9;
  uint256 private _maxTxAmount = _totalSupply.div(800);
  uint256 private _numTokensSellToAddToLiquidity = _totalSupply.div(800);

  string private _symbol = "Zoomy"; 
  string private _name = "Zoomy";

  uint256 private _antiWhaleAmount = 125;
  
  uint256 private _creationDate;
  uint256 private _lastLockDate;
  address[] _founders;

  address private _operationsAddress = 0x2a45BcEf8f9429ea40E427f325bea33b9CE866dA;
  address private _longTermAddress = 0xF978756addF2eC2A3942D344635b99ccD05109CE;
  address private _midTermAddress = 0x6559e3c6C6b0c41717271754eA0FB5f8b37F3d73;
  address private _lottoAddress = 0x3bD80135d5EDC56B82377117f773Dfc4f8717768;

  bool private _txBurn;

  IHolderRewarderDistributor distributor;
  
  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;
  
  bool inSwapAndLiquify;
  bool public swapAndLiquifyEnabled = true;
  uint256 distributorGas = 500000;
  
  event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
  event ProcessRewards();
  event SwapAndLiquifyEnabledUpdated(bool enabled);
  event SwapAndLiquify(
      uint256 tokensSwapped,
      uint256 ethReceived,
      uint256 tokensIntoLiqudity
  );
  
  modifier lockTheSwap {
      inSwapAndLiquify = true;
      _;
      inSwapAndLiquify = false;
  }

  constructor() Authorization(msg.sender) {
    _totalSupply =_initalFragmentsSupply;
    _balances[msg.sender] = _totalSupply;
    _totalLocked = 0;
    _creationDate = getBlockTimestamp();
    _lastLockDate = _creationDate;

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());
    uniswapV2Router = _uniswapV2Router;
    
    _isExcluded[uniswapV2Pair] = true;
    distributor = new HolderRewarderDistributor(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3, _midTermAddress, _longTermAddress);

    _isExcludedFromFee[owner] = true;
    _isExcludedFromFee[address(this)] = true;
    _isExcluded[owner] = true;
    _isExcluded[address(this)] = true;
    _txBurn = true;

    //FEE SETUP
    _taxMatrix["longTerm"] = (TaxFees(300, 200, 150, 50, 200, 100, 200));
    _taxMatrix["midTerm"] = (TaxFees(200, 100, 125, 25, 100, 50, 200));
    _taxMatrix["standard"] = (TaxFees(100, 100, 25, 25, 0, 50, 0));

    emit Transfer(address(0), msg.sender, _totalSupply);
  }
  
  function getBlockTimestamp() internal view returns (uint256) {
    return block.timestamp;
  }

  function getOwner() public override view returns (address) {
    return owner;
  }

  function decimals() public override view returns (uint8) {
    return _decimals;
  }

  function symbol() public override view returns (string memory) {
    return _symbol;
  }

  function name() public override view returns (string memory) {
    return _name;
  }

  function totalSupply() public override view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public override view returns (uint256) {
    return _balances[account];
  }
  
  function rewardsOf(address account) public view returns (uint256) {
    return distributor.getTotalShares(account);
  }
  
  function isLocked(address account) public view returns(bool) {
      return _isLocked[account];
  }
  
  function isTxBurn() public view returns(bool) {
      return _txBurn;
  }

  function lockAccount(address account) public authorized {
      _isLocked[account] = true;
  }

  function unlockAccount(address account) public authorized {
      _isLocked[account] = false;
  }
  
  function numberRewardsOf(address account) public view returns (uint256) {
    return distributor.getTotalSharesCount(account);
  }

  function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
  }
  
  function getCirculatingSupply() public view returns (uint256) {
      return _totalSupply.sub(balanceOf(address(0))).sub(_totalLocked);
  }
  
  function setTxBurn(bool val) public onlyOwner {
    _txBurn = val;
  }

  function getOperationWallet() public view returns (address) {
    return _operationsAddress;
  }
  
  function getLongTermWallet() public view returns (address) {
    return _longTermAddress;
  }
  
  function getMidTermWallet() public view returns (address) {
    return _midTermAddress;
  }
  
  function isFounder(address account) public view returns (bool) {
      bool found = false;
      for (uint256 i = 0; i < _founders.length; i++)
      {
        address founder = _founders[i];
        if (founder == account) found = true;
      }
      return found;
  }

  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) external override view returns (uint256) {
    return _allowances[owner][spender];
  }
  
  function addFounder(address founder, uint256 amount) public onlyOwner {
    _founders.push(founder);
    _totalLocked = _totalLocked.add(amount);
    _lockedBalances[founder] = FounderSupply(0, amount);
  }
  
  function checkFounders() internal {
    if (_lastLockDate + 90 days < getBlockTimestamp())
    {
      for (uint256 i = 0; i < _founders.length; i++)
      {
        address founder = _founders[i];
        uint256 unlockableAmount = _lockedBalances[founder].totalAmount.mul(15).div(
            10**2
        );
        _lockedBalances[founder].unlockedAmount = _lockedBalances[founder].totalAmount - _lockedBalances[founder].unlockedAmount - unlockableAmount;
        _totalLocked = _totalLocked.add(unlockableAmount);
        _lastLockDate = getBlockTimestamp();
      }
    }
  }

  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }
  
  function depositWallets() public {
    if (msg.sender == _longTermAddress){
        try distributor.depositMid{value: _balances[_longTermAddress]}() {} catch {}
    } else if (msg.sender == _midTermAddress) {
        try distributor.depositLong{value: _balances[_midTermAddress]}() {} catch {}
    } else if (msg.sender == _operationsAddress) {
        try distributor.depositLong{value: _balances[_midTermAddress]}() {} catch {}
    }
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(!_isLocked[sender], "This address is currently locked from transacting.");
    require(!_isLocked[recipient], "This address is currently locked from transacting.");
    require(amount > 0, "Transfer amount must be greater than zero");
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");
    require(getCirculatingSupply().mul(_antiWhaleAmount).div(
          10**5
      ) > amount, "BEP20: Sell amount exceeds the antiWhaleAmount");
        
    if (isFounder(sender) && (recipient == uniswapV2Pair || (sender != uniswapV2Pair && recipient != uniswapV2Pair)))
    {
      checkFounders();
      require(amount <= _lockedBalances[sender].unlockedAmount, "Founder has lockable amount");
    }
    
    uint256 contractTokenBalance = balanceOf(address(this));
    
    if(contractTokenBalance >= _maxTxAmount)
    {
        contractTokenBalance = _maxTxAmount;
    }
    
     // is the token balance of this contract address over the min number of
    // tokens that we need to initiate a swap + liquidity lock?
    // also, don't get caught in a circular liquidity event.
    // also, don't swap & liquify if sender is uniswap pair. 
    bool overMinTokenBalance = contractTokenBalance >= _numTokensSellToAddToLiquidity;
    if (
        overMinTokenBalance &&
        !inSwapAndLiquify &&
        sender != uniswapV2Pair &&
        swapAndLiquifyEnabled
    ) {
        contractTokenBalance = _numTokensSellToAddToLiquidity;
        //add liquidity
        swapAndLiquify(contractTokenBalance);
    }
    
    //indicates if fee should be deducted from transfer
    bool takeFee = true;
    
    //if any account belongs to _isExcludedFromFee account then remove the fee
    if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){
        takeFee = false;
    }

    //transfer amount, it will take tax, burn, liquidity fee
    _tokenTransfer(sender,recipient,amount,takeFee);
  }

  function _burn(address account, uint256 amount) public authorized {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function snapshotRewards () public onlyOwner {
    distributor.snapshotTotalShares();
  }
  
  function processRewards() public onlyOwner {
    distributor.process(distributorGas);
  }
  
  //to recieve ETH from uniswapV2Router when swaping
  receive() external payable {}
  
  function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
      swapAndLiquifyEnabled = _enabled;
      emit SwapAndLiquifyEnabledUpdated(_enabled);
  }
  
  function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
      // split the contract balance into halves
      uint256 half = contractTokenBalance.div(2);
      uint256 otherHalf = contractTokenBalance.sub(half);

      // capture the contract's current ETH balance.
      // this is so that we can capture exactly the amount of ETH that the
      // swap creates, and not make the liquidity event include any ETH that
      // has been manually sent to the contract
      uint256 initialBalance = address(this).balance;

      // swap tokens for ETH
      swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

      // how much ETH did we just swap into?
      uint256 newBalance = address(this).balance.sub(initialBalance);

      // add liquidity to uniswap
      addLiquidity(otherHalf, newBalance);
      
      emit SwapAndLiquify(half, newBalance, otherHalf);
  }
  
  function swapTokensForEth(uint256 tokenAmount) private {
      // generate the uniswap pair path of token -> weth
      address[] memory path = new address[](2);
      path[0] = address(this);
      path[1] = uniswapV2Router.WETH();

      _approve(address(this), address(uniswapV2Router), tokenAmount);

      // make the swap
      uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
          tokenAmount,
          0, // accept any amount of ETH
          path,
          address(this),
          block.timestamp
      );
  }
  
  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
      // approve token transfer to cover all possible scenarios
      _approve(address(this), address(uniswapV2Router), tokenAmount);

      // add the liquidity
      uniswapV2Router.addLiquidityETH{value: ethAmount}(
          address(this),
          tokenAmount,
          0, // slippage is unavoidable
          0, // slippage is unavoidable
          owner,
          block.timestamp
      );
  }
  
  function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
      uint256 longTermFee = 0;
      uint256 midTermFee = 0;
      uint256 operationsFee = 0;
      uint256 philanthoryFee = 0;
      uint256 burnFee = 0;
      uint256 lottoFee = 0;
      uint256 liquidityFee = 0;

      if(!_isExcluded[sender])
      { 
        (uint256 longTerm, uint256 midTerm, uint256 standardTerm) = distributor.removeShare(sender, amount);
        if (longTerm > 0 && takeFee && recipient == uniswapV2Pair)
        {
          TaxFees memory longTaxFee = _taxMatrix["longTerm"];
          longTermFee += calculateFee(longTerm, longTaxFee._longTermFee);
          midTermFee += calculateFee(longTerm, longTaxFee._midTermFee);
          operationsFee += calculateFee(longTerm, longTaxFee._operationFee);
          philanthoryFee += calculateFee(longTerm, longTaxFee._philanthoryFee);
          burnFee += _txBurn ?  calculateFee(longTerm, longTaxFee._burnFee) : 0;
          lottoFee += calculateFee(longTerm, longTaxFee._lottoFee);
          liquidityFee += calculateFee(longTerm, longTaxFee._liquidityFee);
        }
        if (midTerm > 0 && takeFee && recipient == uniswapV2Pair)
        {
          TaxFees memory midTaxFee = _taxMatrix["midTerm"];
          longTermFee += calculateFee(midTerm, midTaxFee._longTermFee);
          midTermFee += calculateFee(midTerm, midTaxFee._midTermFee);
          operationsFee += calculateFee(midTerm, midTaxFee._operationFee);
          philanthoryFee += calculateFee(midTerm, midTaxFee._philanthoryFee);
          burnFee += _txBurn ? calculateFee(midTerm, midTaxFee._burnFee) : 0;
          lottoFee += calculateFee(midTerm, midTaxFee._lottoFee);
          liquidityFee += calculateFee(midTerm, midTaxFee._liquidityFee);
        }
        if (standardTerm > 0 && takeFee)
        {
          TaxFees memory standard = _taxMatrix["standard"];
          longTermFee += calculateFee(standardTerm, standard._longTermFee);
          midTermFee += calculateFee(standardTerm, standard._midTermFee);
          operationsFee += calculateFee(standardTerm, standard._operationFee);
          philanthoryFee += calculateFee(standardTerm, standard._philanthoryFee);
          lottoFee += calculateFee(standardTerm, standard._lottoFee);
        }
      }
      
      uint256 transferAmount = amount.sub(longTermFee).sub(midTermFee);
      transferAmount = transferAmount.sub(operationsFee).sub(philanthoryFee).sub(burnFee).sub(lottoFee).sub(liquidityFee);

      if(!_isExcluded[recipient])
      { 
        distributor.addShare(recipient, transferAmount); 
      }
      _balances[sender] = _balances[sender].sub(amount);
      _balances[recipient] = _balances[recipient].add(transferAmount);
      if (takeFee)
      {
        _takeLiquidity(liquidityFee);
        _takeOperations(sender, operationsFee.add(philanthoryFee));
        _takeLongTermFee(sender, longTermFee);
        _takeMidTermFee(sender, midTermFee);
        _takeLottoFee(sender, lottoFee);
        _takeBurn(sender, burnFee);
      }

      emit Transfer(sender, recipient, transferAmount);
  }

  function _takeOperations(address sender, uint256 tFee) private {
    if (tFee > 0){
      _balances[_operationsAddress] = _balances[_operationsAddress].add(tFee);
      emit Transfer(sender, _operationsAddress, tFee);
    }
  }
  
  function _takeMidTermFee(address sender, uint256 tFee) private {
    if (tFee > 0){
      _balances[_midTermAddress] = _balances[_midTermAddress].add(tFee);
      emit Transfer(sender, owner, tFee);
    }
  }
  
  function _takeLongTermFee(address sender, uint256 tFee) private {
    if (tFee > 0){
      _balances[_longTermAddress] = _balances[_longTermAddress].add(tFee);
      emit Transfer(sender, _longTermAddress, tFee);
    }
  }
  
  function _takeLottoFee(address sender, uint256 tFee) private {
    if (tFee > 0){
      _balances[_lottoAddress] = _balances[_lottoAddress].add(tFee);
      emit Transfer(sender, _lottoAddress, tFee);
    }
  }
  
  function _takeBurn(address sender, uint256 tFee) private {
    if (_txBurn) { 
      require(sender != address(0), "BEP20: burn from the zero address");
      _totalSupply = _totalSupply.sub(tFee);
      emit Transfer(sender, address(0), tFee);
    }
  }

  function _takeLiquidity(uint256 tLiquidity) private {
      _balances[address(this)] = _balances[address(this)].add(tLiquidity);
  }

  function calculateFee(uint256 amount, uint256 fee) private pure returns (uint256) {
      return amount.mul(fee).div(
          10**4
      );
  }

  function setRouterAddress(address newRouter) public onlyOwner() {
      IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(newRouter);
      uniswapV2Pair = IUniswapV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
      uniswapV2Router = _newPancakeRouter;
  }
  
  function setMidTermAddress(address _address) public onlyOwner() {
    _midTermAddress = _address;
  }
  
  function setLongTermAddress(address _address) public onlyOwner() {
    _longTermAddress = _address;
  }
}