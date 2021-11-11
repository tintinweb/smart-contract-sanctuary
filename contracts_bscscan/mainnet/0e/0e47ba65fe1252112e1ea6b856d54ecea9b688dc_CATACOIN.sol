/**
 *Submitted for verification at BscScan.com on 2021-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ERC20Interface {
    
    function totalSupply() external view returns (uint);

    function balanceOf(address _account) external view returns (uint);

    function decimals() external view returns (uint8);
    
    function transfer(address _recipient, uint _amount) external returns (bool);

    function allowance(address _owner, address _spender) external view returns (uint);

    function approve(address _spender, uint _amount) external returns (bool);

    function transferFrom(
        address _sender,
        address _recipient,
        uint _amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    // function renounceOwnership() public virtual onlyOwner {
    //     emit OwnershipTransferred(_owner, address(0));
    //     _owner = address(0);
    // }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    // function geUnlockTime() public view returns (uint256) {
    //     return _lockTime;
    // }

    // //Locks the contract for owner for the amount of time provided
    // function lock(uint256 time) public virtual onlyOwner {
    //     _previousOwner = _owner;
    //     _owner = address(0);
    //     _lockTime = now + time;
    //     emit OwnershipTransferred(_owner, address(0));
    // }
    
    // //Unlocks the contract for owner when _lockTime is exceeds
    // function unlock() public virtual {
    //     require(_previousOwner == msg.sender, "You don't have permission to unlock");
    //     require(now > _lockTime , "Contract is locked until 7 days");
    //     emit OwnershipTransferred(_owner, _previousOwner);
    //     _owner = _previousOwner;
    // }
}
// pragma solidity >=0.5.0;

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


// pragma solidity >=0.5.0;

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

abstract contract Pausable is Context {

    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor() public {
        _paused = true;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract CATACOIN is ERC20Interface,Ownable,Pausable {
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint8 private _decimals = 9;
    
    
    
    mapping (address => uint256) private balances;
    
    mapping (address => mapping (address => uint256)) private allowed;
    
    
    uint private deci = 10**9;
    uint256 private numberToken = 1 * 10**11;
    uint256 private supply = numberToken * deci;
    uint256 public _maxTxAmount = (numberToken * deci).div(10);
    uint256 public swapTokensAtAmount = 2* (numberToken * deci).div(1000);

    
    //----------------------------------------------------------------------------------------------------
    bool private swapping = false;
    
    // Tax
    //----------------------------------------------------------------------------------------------------
    struct Tax {
        uint buyTax;
        uint sellTax;
    }
    
    mapping(address => bool) private _isExcludedFromFee;
    
    address private marketingTaxAddress;
    address private supplyTaxAddress;
    address private rewardTaxAddress;

    address private devWalletAddress;

    Tax public marketingTax = Tax(2,5);
    Tax public supplyTax = Tax(3,5);
    Tax public rewardTax = Tax(5,5);
    
    uint256 public totalBuyFees = marketingTax.buyTax.add(supplyTax.buyTax).add(rewardTax.buyTax);
    uint256 public totalSellFees = marketingTax.sellTax.add(supplyTax.sellTax).add(rewardTax.sellTax);
    
    event TransferTax(address sender,address _recipient, uint _amount) ;
    
    // burn mawBuy
    address address0 = 0x000000000000000000000000000000000000dEaD;
    
    uint private amountMaxBuy = 1;
    bool private maxBuyEnable = true;
    
    //routuer 
    address routerAdress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IUniswapV2Router02 public  uniswapV2Router;
    address public  uniswapV2Pair;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
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
    
    
    
    // constructor(address _burnAddress,address _marketingTaxAddress,address _rewardTaxAddress) public {
    constructor() public {

        name = "CATACOIN";
        symbol = "CATACOIN";
    
        //routeur
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAdress);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
    
        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        

        
        // marketingTaxAddress = _marketingTaxAddress;
        // rewardTaxAddress = _rewardTaxAddress;
        // burnAddress = _burnAddress;
        
        devWalletAddress = 0xd3aB9eB576E12F45E5bB93cE45b2dEa395d17D46;

        supplyTaxAddress = 0x23e9f3D5B9cC56E20Ee01E0A464A56705907B684;
        marketingTaxAddress = 0xa2Dc107A2fB2D9704EF7c9D6432Cdb75a4DE3a45;
        rewardTaxAddress = 0x4403644AB99a62F0e7fdE002EDbb2d0D6f795fb5;
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[routerAdress] = true;
        
        _isExcludedFromFee[marketingTaxAddress] = true;
        _isExcludedFromFee[rewardTaxAddress] = true;
        _isExcludedFromFee[supplyTaxAddress] = true;
        
        
        //transer
        balances[owner()] = supply;
        emit Transfer(address(0), owner(), supply);
        
        uint devAmmount  = balances[owner()].div(10);
        balances[owner()] = balances[owner()].sub(devAmmount);
        balances[devWalletAddress] = devAmmount;
        emit Transfer(owner(), devWalletAddress, devAmmount);
    }

///-------------------------------------------
//Based Function
//-------------------------------------------

 function totalSupply() external override view returns (uint256) {
    return supply;
  }

  function balanceOf(address _owner) public override view returns (uint256) {
    return balances[_owner];
  }
    
    function getOwner() public  view returns (address) {
     return owner();
  }
  
  function decimals() external override view returns (uint8) {
    return _decimals;
  }
  
  
  function transfer(address _recipient, uint _amount) external override whenNotPaused returns (bool) {
      _transfer(_msgSender(), _recipient, _amount);
      return true;
  }

    function transferFrom(
        address _sender,
        address _recipient,
        uint _amount
    ) external override returns (bool){
         _transfer(_sender, _recipient, _amount);
        allowed[_sender][_msgSender()] = allowed[_sender][_msgSender()].sub(_amount);
        return true;
    }
    
    function allowance(address _owner, address _spender) external override view returns (uint){
        return allowed[_owner][_spender];
    }

    
    
    function approve(address _spender, uint _amount) external override returns (bool){
        _approve(_msgSender(), _spender, _amount);
        return true;
    }
    
    
//-------------------------------------------
//get
//-------------------------------------------
    
    function getContractAdress() external view returns (address){
        return address(this);
    }
    
    function getPayableContractAdress() external view returns (address){
        return payable(address(this));
    }
    
    function getCurrentSupply() internal view returns (uint256){
        return supply;
    }

    
    function getLiquidityFee() public  view returns (uint256)  {
        return balances[address(this)].div(10**9);
   }
     
    function getTaxes() external view returns (uint256){
         return balances[address(this)];
    }
     

    
//-------------------------------------------
//set
//-------------------------------------------

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "CHEG: The router already has that address");
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }   

    function setMaketingTaxAddress(address _taxAddress) public onlyOwner {
        marketingTaxAddress = _taxAddress;
    }

    function setRewardTaxAddress(address _taxAddress) public onlyOwner {
        rewardTaxAddress = _taxAddress;
    }    
    
    function setSupplyTaxAddress(address _supplyTaxAddress) public onlyOwner {
        supplyTaxAddress = _supplyTaxAddress;
    }   

    function withdraw() external onlyOwner {
        address  contractAddress = address(this);
        payable(owner()).transfer(contractAddress.balance);
    }
    
    function withdrawToken() external onlyOwner {
        address  contractAddress = address(this);
        uint256 token = balances[contractAddress];
        balances[owner()] = balances[owner()].add(token);
        balances[contractAddress] = balances[contractAddress].sub(token);
    }
    ///-------------------------------------------
// change allowance
///-------------------------------------------

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal  {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        allowed[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

 function increaseAllowance(address _spender, uint256 _addedValue) public  returns (bool) {
        _approve(_msgSender(), _spender, allowed[_msgSender()][_spender].add(_addedValue));
        return true;
    }

   
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public  returns (bool) {
        uint256 currentAllowance = allowed[_msgSender()][_spender];
        require(currentAllowance >= _subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), _spender, currentAllowance.sub(_subtractedValue));
        return true;
    }

//-------------------------------------------
// Burn 
//-------------------------------------------

event Burn(address indexed burner, uint256 value);

function burn(uint _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        supply = supply.sub(_value);
        Burn(burner, _value);
        balances[address0] = balances[address0].add(_value);
        emit Transfer(burner, address0, _value);
    }
    

    
///-------------------------------------------
// Pause
///-------------------------------------------
   
   function changePause() external  onlyOwner  returns (bool ) {
     if(paused()){
         _unpause();
     }else{
         _pause();
     }
     return paused();
  }
  
  ///-------------------------------------------
// maxBuy
///-------------------------------------------
   
    modifier calculmaxBuy(uint256 _amount,address _sender , address _recipient) {
        if(maxBuyEnable){
            if(_isExcludedFromFee[_sender] || _isExcludedFromFee[_recipient]){
            
            }else{
                uint256 max = getCurrentSupply().mul(amountMaxBuy).div(100);
                require(_amount <= max, "Max buy is 1%");
            }

        }
        _;
    }
    
    function getMaxPerBuy() external view returns(uint256) {
        return amountMaxBuy;
    }
       function setMaxPerBuy(uint256 _amount) onlyOwner external  {
        amountMaxBuy = _amount;
    }
    function changeMaxBuyEnable() onlyOwner external {
       maxBuyEnable = !maxBuyEnable;
    }
       function getMaxBuyEnable() external view returns(bool) {
       return maxBuyEnable;
    }
    
    function getCurrentMaxPerBuy() external view returns(uint256) {
        return (getCurrentSupply().mul(amountMaxBuy).div(100)).div(10**9);
    } 
    
    

///-------------------------------------------
//calcul TAXE 
///-------------------------------------------

    
     function getBuyTax() private view returns (uint){
         return marketingTax.buyTax + supplyTax.buyTax + rewardTax.buyTax;
     }
          
      function getSellTax() private view returns (uint){
         return marketingTax.sellTax + supplyTax.sellTax + rewardTax.sellTax;
     }
 
    
    function calculTaxFee( uint256 _amount,address _sender) private view returns (uint256)  {
        uint256 taxFee;
        if(isABuy(_sender)){
                taxFee = _amount.mul(getBuyTax()).div(100);
          }else{
                taxFee = _amount.mul(getSellTax()).div(100);
          }
            return taxFee ;

    }
    function sendFee(address _sender,uint256 _fee) private  {
        // uint256 rewardFee;
        // uint256 otherFee;
        // // if(isABuy(_sender)){
        //       rewardFee = _fee.mul(rewardTax.buyTax).div(100);
        // }else{
        //       rewardFee = _fee.mul(rewardTax.sellTax).div(100);
        // }
            // otherFee = _fee.sub(rewardFee);
        balances[address(this)] = balances[address(this)].add(_fee);
        emit Transfer(_sender, address(this), _fee);  
            
            // balances[rewardTaxAddress] = balances[rewardTaxAddress].add(rewardFee);
            // emit Transfer(_sender, rewardTaxAddress, rewardFee);
     }
    
    function isABuy(address _sender)internal view returns(bool){
        return _sender == uniswapV2Pair;
    }
     
     
///-------------------------------------------
//transfer
///-------------------------------------------


       function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private calculmaxBuy(_amount,_sender,_recipient)  {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");
        require(_amount > 0, "Transfer amount must be greater than zero");
   
        balances[_sender] = balances[_sender].sub(_amount);

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
    bool takeFee = true;
        
      if(_isExcludedFromFee[_sender] || _isExcludedFromFee[_recipient]){
            takeFee = false;
        }else{
        
           	uint256 contractTokenBalance = balanceOf(address(this));
            
            bool overMinTokenBalance = contractTokenBalance >= swapTokensAtAmount;
            if (
                overMinTokenBalance &&
                !inSwapAndLiquify &&
                !isABuy(_sender) &&
                swapAndLiquifyEnabled
            ) {
                // contractTokenBalance = numTokensSellToAddToLiquidity;
                // swapAndLiquify(contractTokenBalance);
                uint marketingFee;
                uint liquidityFee;
                uint totalFees;
                
                if(isABuy(_sender)){
                    marketingFee = marketingTax.buyTax;
                    liquidityFee = supplyTax.buyTax;
                    totalFees = totalBuyFees;
                }else{
                    marketingFee = marketingTax.sellTax;
                    liquidityFee = supplyTax.sellTax;
                    totalFees = totalSellFees;
                }
                swapping = true;
    
                uint256 marketingTokens = contractTokenBalance.mul(marketingFee).div(totalFees);
                swapAndSendToFee(marketingTokens);
                
                uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(totalFees);
                swapLiquify(swapTokens);
    
                uint256 sellTokens = balanceOf(address(this));
                swapAndSendDividends(sellTokens);
    
                swapping = false;
            }
        }
         
        if(takeFee){
            uint256 taxFee = calculTaxFee(_amount,_sender);
            sendFee(_sender,taxFee);
            _amount = _amount.sub(taxFee);
        }
        
        balances[_recipient] = balances[_recipient].add(_amount);
        emit Transfer(_sender, _recipient, _amount);

    }
    
        function swapAndSendToFee(uint256 tokens) private  {
            swapTokensForEth(tokens,marketingTaxAddress);
        }
    
        function swapAndSendDividends(uint256 tokens) private {
            swapTokensForEth(tokens,rewardTaxAddress);
        }
        
        function swapLiquify(uint256 tokens) private {
            swapTokensForEth(tokens,supplyTaxAddress);
        }
        function swapTokensForEth(uint256 tokenAmount ,address _recipient) private {

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
            _recipient,
            block.timestamp
        );

    }
    

        
        function swapAndLiquify(uint256 tokens) private {
       // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half,address(this)); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
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
            address(0),
            block.timestamp
        );

    }


    
    function getblanceOf() public  view returns (uint256)  {
        uint256 contractTokenBalance = balanceOf(address(this));
        return contractTokenBalance;
   }
     
    function getcontractTokenBalanceOf() external view returns (uint256){
        uint marketingFee = marketingTax.sellTax;
        uint totalFees = totalSellFees;
        uint256 contractTokenBalance = balanceOf(address(this));
        return contractTokenBalance.mul(marketingFee).div(totalFees).div(_decimals);
    }

  //-------------------------------------------  
  //swap and liquidity
  //-------------------------------------------  


    
    

    //  function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
    //     // split the contract balance into halves
    //     uint256 half = contractTokenBalance.div(2);
    //     uint256 marketingFee = half;
    //     swapMarketingFee(marketingFee);
        
    //     uint256 liquidityFee = half.div(2);
    //     uint256 otherHalf = half.sub(liquidityFee);

    //     // capture the contract's current ETH balance.
    //     // this is so that we can capture exactly the amount of ETH that the
    //     // swap creates, and not make the liquidity event include any ETH that
    //     // has been manually sent to the contract
    //     uint256 initialBalance = address(this).balance;
        
    //     swapTokensForEth(liquidityFee);
    //     // swap tokens for ETH
    //     // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
    //     // how much ETH did we just swap into?
    //     uint256 newBalance = address(this).balance.sub(initialBalance);

    //     // add liquidity to uniswap
    //     addLiquidity(otherHalf, newBalance);
        
    //     emit SwapAndLiquify(half, newBalance, otherHalf);
    // }
    
    //     function swapMarketingFee(uint256 tokenAmount) private{
    //      address[] memory path = new address[](2);
    //     path[0] = address(this);
    //     path[1] = uniswapV2Router.WETH();

    //     _approve(address(this), address(uniswapV2Router), tokenAmount);

    //     // make the swap
    //     uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
    //         tokenAmount,
    //         0, // accept any amount of ETH
    //         path,
    //         marketingTaxAddress,
    //         block.timestamp
    //     );
    // }
    

    
    
    // function swapTokensForEth(uint256 tokenAmount) private {
    //     // generate the uniswap pair path of token -> weth
    //     address[] memory path = new address[](2);
    //     path[0] = address(this);
    //     path[1] = uniswapV2Router.WETH();

    //     _approve(address(this), address(uniswapV2Router), tokenAmount);

    //     // make the swap
    //     uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
    //         tokenAmount,
    //         0, // accept any amount of ETH
    //         path,
    //         address(this),
    //         block.timestamp
    //     );
    // }


    // function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    //     // approve token transfer to cover all possible scenarios
    //     _approve(address(this), address(uniswapV2Router), tokenAmount);

    //     // add the liquidity
    //     uniswapV2Router.addLiquidityETH{value: ethAmount}(
    //         address(this),
    //         tokenAmount,
    //         0, // slippage is unavoidable
    //         0, // slippage is unavoidable
    //         owner(),
    //         block.timestamp
    //     );
    // }
    
    

    
        function externalSwapTokensForEth(uint256 tokenAmount) external onlyOwner{
         address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            marketingTaxAddress,
            block.timestamp
        );
    }
}