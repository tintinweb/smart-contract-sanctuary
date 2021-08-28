/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


interface IERC20 {
    
    function totalSupply() external view returns (uint256);
   
    function balanceOf(address account) external view returns (uint256);
   
    function transfer(address recipient, uint256 amount) external returns (bool);
   
    function allowance(address owner, address spender) external view returns (uint256);
 
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool); 
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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




contract MemeCoinFactoryToken is Context,IERC20, Ownable{
    using Address for address;

    mapping (address => uint256) private _balances;
    mapping (address => bool) private _excludedFromFees;
    mapping (address => mapping (address => uint256)) private _allowances;
    address _owner;
    address payable public marketingAddress = payable(0x910Ad70E105224f503067DAe10b518F73B07b5cD);
    address payable public prizePoolAddress = payable(0x0d5cC40d34243ae68519f6d10D0e0B61Cd297DFE);
   
    //7% Transaction Fee - 3% Liquidity 3% Marketing 1% Prize Pool

    uint256 private liqFee = 0;
    uint256 private prevLiqFee = 3;
    uint256 private mktFee = 0;
    uint256 private PrevmktFee = 3;
    uint256 private prizePool = 0;
    uint256 private prevPrizePool = 1;
    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    address payable public casinoDefaultAddress;
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 private mktTokens = 0;
    uint256 private prizepoolTokens = 0;
    uint256 liqTokens = liqTokens = 0;

    string private _name = "TEST";
    string private _symbol = "MCF";
    uint8 private _decimals = 9;

    uint256 private currentTreshold = 10; //Once the token value goes up this number can be decreased (To reduce price impact on asset)
    uint256 private _totalSupply = 50000 * 10**6 * 10**9; //50B supply
    uint256 public requiredTokensToSwap = currentTreshold * 10 ** 6 * 10 ** 9; //sells around 10000000 tokens 
    event SwapAndLiquify(uint256 tokensSwapped,
		uint256 bnbReceived,
		uint256 tokensIntoLiquidity
	);
    event tokensSwappedDuringTokenomics(uint256 amount);
    
    // mainnet: 0x10ED43C718714eb63d5aA57B78B54704E256024E
    //0xD99D1c33F9fC3444f8101754aBC46c52416550D1
    IPancakeRouter02 _router;
    address public immutable pcsPair;

    //Balances tracker

    modifier lockTheSwap{
		inSwapAndLiquify = true;
		_;
		inSwapAndLiquify = false;
	}
    

    constructor(){
        _balances[_msgSender()] = _totalSupply;
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        
        pcsPair = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        
        _excludedFromFees[owner()] = true;         
        _excludedFromFees[address(this)] = true;// exclude owner and contract instance from fees
        _router = _pancakeRouter;
        emit Transfer(address(0),_msgSender(),_totalSupply);




    }
    receive() external payable{}


    //general token data
    function getOwner()external view returns(address){
            return owner();
    }
    function currentmktTokens() external view returns (uint256){
            return mktTokens;
     }
     function currentPZTokens() external view returns (uint256){
            return prizepoolTokens;
     }
     function currentLiqTokens() external view returns (uint256){
            return liqTokens;
     }

     function totalSupply() external view override returns (uint256){
            return _totalSupply;
     }
   
    function balanceOf(address account) public view override returns (uint256){
        return _balances[account];
    }
   
    function transfer(address recipient, uint256 amount) external override returns (bool){
                _transfer(_msgSender(),recipient,amount);
                return true;

    }
   
    function allowance(address owner, address spender) external view override returns (uint256){
            return _allowances[owner][spender];
    }
 
    function approve(address spender, uint256 amount) external override returns (bool){
            _approve(_msgSender(),spender,amount);
            return true;
    }

    function decimals()external view returns(uint256){
        return _decimals;
    }
    function name() external view returns (string memory) {
		return _name;
	}
    function symbol() external view returns (string memory){
        return _symbol;
    }
    

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool){
        require(amount <= _allowances[sender][_msgSender()], "BEP20: transfer amount exceeds allowance");
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
		return true;
    }



    //Tokenomics related functions
    

    function _transfer(address from, address to, uint256 amount) internal{
        require(from != address(0), "BEP20: transfer from the zero address");
		require(to != address(0), "BEP20: transfer to the zero address");
        require(amount >0,"BEP20: transfered amount must be greater than zero");

        uint256 senderBalance = _balances[from];



        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        uint256 inContractBalance = balanceOf(address(this));

        if(inContractBalance >=requiredTokensToSwap && 
			!inSwapAndLiquify && 
			from != pcsPair && 
			swapAndLiquifyEnabled){
                if(inContractBalance >= requiredTokensToSwap ){
                    inContractBalance = requiredTokensToSwap;
                    swapForTokenomics(inContractBalance);

                }



            }

            bool takeFees = true;

            if(_excludedFromFees[from] || _excludedFromFees[to]) {
                takeFees = false;

            }
            uint256 mktAmount = 0;
            uint256 prizePoolAmount = 0; // Amount to be burned.
		    uint256 liqAmount = 0;  // Amount to be added to liquidity.

            if(takeFees){
                mktAmount = amount * mktFee/100;
			    liqAmount = amount * liqFee/100;
                prizePoolAmount = amount * prizePool/100;
            }

            _balances[from] = senderBalance - amount;
            _balances[to] += amount - mktAmount - prizePoolAmount - liqAmount;

          if(liqAmount != 0) {
			_balances[address(this)] += liqAmount;
			//tLiqTotal += liqAmount;
            liqTokens += liqAmount;
            prizepoolTokens += prizePoolAmount;
            mktTokens += mktAmount;
			emit Transfer(from, address(this), liqAmount);
            
		    }
        
    }
    function swapForTokenomics(uint256 balanceToswap) internal{
        swapAndLiquify(liqTokens);
        swapTokensForBNBmkt(mktTokens);
        swapTokensForBNBprizePool(prizepoolTokens);
        emit tokensSwappedDuringTokenomics(balanceToswap);

            

    }
    function swapTokensForBNBmkt(uint256 amount)private {
        address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _router.WETH();
		_approve(address(this), address(_router), amount);

		
		_router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			amount,
			0, // Accept any amount of BNB.
			path,
			marketingAddress,
			block.timestamp
		);

    }
      function swapTokensForBNBprizePool(uint256 amount)private {
        address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _router.WETH();
		_approve(address(this), address(_router), amount);

		
		_router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			amount,
			0, // Accept any amount of BNB.
			path,
			prizePoolAddress,
			block.timestamp
		);

    }
    function swapAndLiquify(uint256 liqTokensPassed) private lockTheSwap {
		uint256 half = liqTokensPassed / 2;
		uint256 otherHalf = liqTokensPassed - half;
		uint256 initialBalance = address(this).balance;

		swapTokensForBNB(half);
		uint256 newBalance = address(this).balance - (initialBalance); 

		addLiquidity(otherHalf, newBalance);
		emit SwapAndLiquify(half,newBalance,otherHalf);
	}

    function swapTokensForBNB(uint256 tokenAmount) private{
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _router.WETH();
		_approve(address(this), address(_router), tokenAmount);

		
		_router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0, // Accept any amount of BNB.
			path,
			address(this),
			block.timestamp
		);
	}
    
    function addLiquidity(uint256 tokenAmount,uint256 bnbAmount) private{
		_approve(address(this), address(_router), tokenAmount);

		_router.addLiquidityETH{value:bnbAmount}(
			address(this),
			tokenAmount,
			0,
			0,
			owner(),
			block.timestamp
		);
	}

    function _approve(address owner,address spender, uint256 amount) internal{
        require(owner != address(0), "BEP20: approve from the zero address");
		require(spender != address(0), "BEP20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);


    }



    //Fees related functions

    function addToExcluded(address toExclude) public onlyOwner{  
        _excludedFromFees[toExclude] = true;
    }
    

    function startPresaleStatus()public onlyOwner{
        PrevmktFee = mktFee;
        mktFee = 0;
        prevLiqFee = liqFee;
        liqFee =0;
        prevPrizePool = prizePool;
        prizePool =0;
        setSwapAndLiquify(false);

    }
    function endPresaleStatus() public onlyOwner{
        mktFee = 3;
        liqFee =3;
        prizePool =1;
        setSwapAndLiquify(true);
    }

    function updateTreshold(uint newThreshold) public onlyOwner{
        currentTreshold = newThreshold;

    }

    function setSwapAndLiquify(bool _enabled) public onlyOwner{
            swapAndLiquifyEnabled = _enabled;
    }


    //Marketing related 

    function setMktAddress(address newAddress) external onlyOwner{
        marketingAddress = payable(newAddress);
    }
    function transferAssetsBNB(address payable to, uint256 amount) internal{
                    to.transfer(amount);
    }

    function setCasinoAddress(address newAddress) external onlyOwner{
        casinoDefaultAddress = payable(newAddress);
    }
    function setPrizePoolAddress(address newAddress) external onlyOwner{
        prizePoolAddress = payable(newAddress);
    }









}


interface IPancakeFactory{
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


interface IPancakePair{
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

interface IPancakeRouter01 {
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

interface IPancakeRouter02 is IPancakeRouter01 {  //The functions calling for ETH actually call for BNB so i could technically change the "ETH" for BNB.
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