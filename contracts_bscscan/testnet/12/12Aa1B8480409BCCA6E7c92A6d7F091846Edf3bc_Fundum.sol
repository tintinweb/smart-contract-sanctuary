// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./Address.sol";
import "./IBEP20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Uniswap.sol";

contract Fundum is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  mapping (address => bool) private _isExcludedFromFee;

  uint256 private _totalSupply = 250 * 10**6 * 10**9; // 250, 000, 000 token

  string private _name = "FUNDUM";
  string private _symbol = "FNDM";
  uint8 private _decimals = 9;
  
  address public deployerWallet = 0x38Af5Fb037ecD3F0589682b32cE30A9Db183c887;
  //address public release2Wallet = 0xb8BFE1537003Ec28886E7815825aDb728f763D95;
  address public release2Wallet = 0x0b9c01C47Cd64F0E3F0418d5b11ee74E9067B65d;
  address public teamWallet = 0xaDe9a25c271a9d804968f1a843591a3C8Ff42a5D;
  address public marketingWallet = 0x9D0F1e9C087cEA08fFEF6afdACdFa2A07c001F8c;
  address public buybackWallet = 0xCCB24e0bb00064e465b916533950870CeD737476;
  address public lp2Wallet = 0xf46F57debA545b281c515D064ECD9Da598EF7cf0;

  uint8 public taxFee = 10; // total tax fee 10%
  uint256 public totalTax = 0; // total tax amount;

  uint256 public remainTax = 0; // remain tax amount in contract
  uint256 public minSwapBalance = 100 * 10**9; // require minimum 100 tokens for swap

  bool public inSwapAndLiquify = false;
  bool public swapAndLiquifyEnabled = false;
  bool public openTrading = false; 

  //address public busdAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // mainnet BUSD address
  address public busdAddress = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; // testnet BUSD address
  address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD; // burn address

  IUniswapV2Router02 public immutable uniswapV2Router;  // In BSC network uniswapV2Router is pancakeRouter.
  address public uniswapV2Pair;   // Pancake Pair

  // Lp1 tokens to deployer wallet address
  uint256 public lp1Tokens = 666666666667; // 666.666666667 token
  uint256 public lp2Tokens = 199333333333333; // 199333.333333333 token
  uint256 public reserveTokens; // reserve tokens
  uint256 public tradeTokens; // trade tokens

  event OpenTradingEnabledUpdated(bool enabled);
  event SwapAndLiquifyEnabledUpdated(bool enabled);
  event SwapTokensForBUSD(
      uint256 amountIn,
      address[] path
  );
  
  modifier lockTheSwap {
      inSwapAndLiquify = true;
      _;
      inSwapAndLiquify = false;
  }

  constructor() {
    reserveTokens = _totalSupply.mul(40).div(100); // 100M token to release wallet.
    tradeTokens = _totalSupply.sub(lp1Tokens).sub(lp2Tokens).sub(reserveTokens); // trade tokens amount: 150M - 200K

    //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // Mainnet Pancake Router 
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // Testnet Pancake Router
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), busdAddress);
    uniswapV2Router = _uniswapV2Router;

    _isExcludedFromFee[deployerWallet] = true;
    _isExcludedFromFee[release2Wallet] = true;
    _isExcludedFromFee[teamWallet] = true;
    _isExcludedFromFee[marketingWallet] = true;
    _isExcludedFromFee[buybackWallet] = true;
    _isExcludedFromFee[lp2Wallet] = true;
    _isExcludedFromFee[_msgSender()] = true;
    _isExcludedFromFee[address(this)] = true;

    _balances[deployerWallet] = lp1Tokens;

    _balances[lp2Wallet] = lp2Tokens;

    _balances[release2Wallet] = reserveTokens;

    //_balances[_msgSender()] = tradeTokens;
    _balances[address(this)] = tradeTokens;

    emit Transfer(address(0), deployerWallet, lp1Tokens);
    emit Transfer(address(0), lp2Wallet, lp2Tokens);
    emit Transfer(address(0), release2Wallet, reserveTokens);
    emit Transfer(address(0), address(this), tradeTokens);
  }

  /**
   * @dev Returns the bep20 token owner.
   */
  function getOwner() external override view returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external override view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external override view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external override view returns (string memory) {
    return _name;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() external override view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) external override view returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender) external override view returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }


  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    bool takeFee = true;
        
    //if any account belongs to _isExcludedFromFee account then remove the fee
    if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){
        takeFee = false;
    }

    if(takeFee){
      if(!openTrading){
        require(_msgSender() != address(uniswapV2Router) && _msgSender() != uniswapV2Pair, "ERR: disable adding liquidity");
      }
    }
    
    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");

    if (!inSwapAndLiquify && swapAndLiquifyEnabled && recipient == uniswapV2Pair) {
      remainTax = _balances[address(this)].sub(tradeTokens);
      if(remainTax >= minSwapBalance)
        remainTax = minSwapBalance;
        _distributeTaxFees(remainTax);
    }

    if(takeFee){
      uint256 fee = amount.mul(taxFee).div(100); // 10 % total tax from transfer
      uint256 transAmount = amount.sub(fee);

      totalTax = totalTax.add(fee);

      _balances[recipient] = _balances[recipient].add(transAmount);
      _balances[address(this)] = _balances[address(this)].add(fee);
    
      emit Transfer(sender, recipient, transAmount);
      emit Transfer(sender, address(this), fee);
    }else{
        if(recipient == buybackWallet){
          _balances[deadAddress] = _balances[deadAddress].add(amount);

          emit Transfer(sender, deadAddress, amount);
        }else{
          _balances[recipient] = _balances[recipient].add(amount);

          emit Transfer(sender, recipient, amount);
        }
    }
  }
 
  
  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }


  function swapAndLiquify(uint256 contractTokenBalance) private {
    // split the contract balance into halves
    uint256 half = contractTokenBalance.div(2);

    // swap tokens for BUSD
    swapTokensForBUSD(uniswapV2Pair, half);

    _balances[address(this)] = _balances[address(this)].sub(half);
    _balances[uniswapV2Pair] = _balances[uniswapV2Pair].add(half);
  }

  function addLiquidity(uint256 tokenAmount, uint256 busdAmount) private {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    IBEP20(busdAddress).approve(address(uniswapV2Router), busdAmount);

    uniswapV2Router.addLiquidity(
        address(this), 
        busdAddress, 
        tokenAmount, 
        busdAmount, 
        0, 
        0, 
        owner(), 
        block.timestamp
    );
  }

  function swapTokensForBUSD(address toAddress, uint256 tokenAmount) private lockTheSwap {
      address[] memory path = new address[](2);
      path[0] = address(this);
      path[1] = busdAddress;

      _approve(address(this), address(uniswapV2Router), tokenAmount);

      uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
          tokenAmount,
          0,
          path,
          toAddress,
          block.timestamp.add(120)
      );

      emit SwapTokensForBUSD(tokenAmount, path);
  }

  function _distributeTaxFees(uint256 taxBalance) private {
    swapAndLiquify(taxBalance.mul(5).div(10)); // 5% of fee to add liquidity

    swapTokensForBUSD(teamWallet, taxBalance.mul(1).div(10)); // 1% of fee convert to BUSD and send to teamWallet

    swapTokensForBUSD(marketingWallet, taxBalance.mul(2).div(10)); // 2% of fee convert to BUSD and send to marketing wallet

    swapTokensForBUSD(buybackWallet, taxBalance.mul(2).div(10)); // 2% of fee convert to BUSD and send to buyback wallet

    if(1000 * 10**9 < _balances[uniswapV2Pair] && _balances[uniswapV2Pair] < 2 * 10**5 * 10**9){
      uint256 lessAmount = 2 * 10**5 * 10**9 - _balances[uniswapV2Pair];

      if(lessAmount > 0 && _balances[address(this)] > lessAmount ){
        tradeTokens = tradeTokens.sub(lessAmount);
        _balances[address(this)] = _balances[address(this)].sub(lessAmount);
        _balances[uniswapV2Pair] = _balances[uniswapV2Pair].add(lessAmount);
        emit Transfer(address(this), uniswapV2Pair, lessAmount);
      }
    }
  }

  function manualSwapTokens() public onlyOwner {
      //uint256 contractTokenBalance = _balances[address(this)];
      swapTokensForBUSD(release2Wallet, 100 * 10**9);
  }

  function updateMinSwapBalance(uint256 _minBalance) public onlyOwner {
    minSwapBalance = _minBalance * 10**9;
  }

  function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
    swapAndLiquifyEnabled = _enabled;
    emit SwapAndLiquifyEnabledUpdated(_enabled);
  }

  function setOpenTrading(bool _enabled) public onlyOwner {
    openTrading = _enabled;
    emit OpenTradingEnabledUpdated(_enabled);
  }

  function prepareForPreSale() public onlyOwner {
    setSwapAndLiquifyEnabled(false);
    setOpenTrading(false);
    taxFee = 0;
  }
    
  function afterPreSale() public onlyOwner {
    setSwapAndLiquifyEnabled(true);
    setOpenTrading(true);
    taxFee = 10;
  }

  // to recieve ETH from uniswapV2Router when swaping
  receive() external payable {}
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.0;


library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.0;

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
   * @dev Returns the mrc token owner.
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

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.0;

import "./Context.sol";

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.0;

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