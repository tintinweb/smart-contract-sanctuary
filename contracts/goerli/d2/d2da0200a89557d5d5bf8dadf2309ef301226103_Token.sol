/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

pragma solidity 0.8.6;
// SPDX-License-Identifier: Unlicensed

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


contract Token {

    // token details
    string public name;
    string public symbol;
    uint8 public decimals = 18; 
    
    
    uint256 public buyVolume;
    uint256 public sellVolume;
    uint256 public burnTax;
    uint256 public lastSnapshotBlock;
    uint256 public maxTxnDivisor;
    uint256 public constant blkInterval = 900;
    
    uint256 private totalSupply_;
    
    // standard ERC-20 events
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    
    // non-standard events
    event TaxUpdated(uint256 oldTax, uint256 newTax, address invoker);
    event Burned(uint256 amount);
    event NewPair(address indexed pairAddr);
    event NewRouter(address indexed routerAddr);
    
    // store standard ERC-20 data
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    
    // store token-specific data
    // `tradeTimes`: Stores the last trade time of an address.
    // `isDevWallet`: Stores dev wallets.
    // `isPermanentlyRenounced`: Stores if a once-dev wallet has permanently renounced their address.
    // `isKnownUniPair`: Stores known Uniswap trading pair contracts.
    // `isKnownUniAddr`: Stores known Uniswap router contracts.
    mapping(address => uint256) private tradeTimes;
    mapping(address => bool) private isDevWallet;
    mapping(address => bool) private isPermanentlyRenounced;
    mapping(address => bool) private isKnownUniPair;
    mapping(address => bool) private isKnownUniAddr;
    
    
    bool public buyingLocked;

    
    modifier onlyDevWallet() {
        // if every single dev wallet has renounced, there's no going back.
        require(isDevWallet[msg.sender], "Only dev wallets can call");
        _;
    }
    
    
    constructor(uint256 total, address mainWallet, address[3] memory wallets, uint256 mainAlloc, uint256 altAlloc, address initRouter) {
        // allocate tokens to 1 main wallet, and 3 alternative wallets
        
        // require token allocation to be equal to the supply
        require(mainAlloc+altAlloc*3 == 100, "Invalid token allocation");
        
        // define total supply
    	totalSupply_ = total;
    	
    	// allocate tokens to mainWallet
    	balances[mainWallet] += totalSupply_*mainAlloc/100;
    	emit Transfer(address(0), mainWallet, totalSupply_*mainAlloc/100);
    	// set as dev wallet
    	isDevWallet[mainWallet] = true;
    	
    	for(uint i; i<3; i++){
    	    // allocate tokens to alt wallets
    	    balances[wallets[i]] += totalSupply_*altAlloc/100;
    	    emit Transfer(address(0), wallets[i], totalSupply_*altAlloc/100);
    	    // set as dev wallets
    	    isDevWallet[wallets[i]] = true;
    	}
    	// base burn tax
    	burnTax = 800;
    	
    	// base max txn divisor is set to 1 (100%) to avoid LP adding issues.
    	// it can later be updated by dev wallets with `updateMaxTxnDivisor`.
        maxTxnDivisor = 1;
        
    	// init uniswap V2 Router to create pair
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(initRouter);
    	
        // create the pair and assign it
        isKnownUniPair[IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH())] = true;
        isKnownUniAddr[initRouter] = true;
        
        // initialize token name
        name = "_";
        symbol = "_";
        
    }  
    
    
    function totalSupply() public view returns (uint256) {
	    return totalSupply_;
    }
    
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }


    function allowance(address holder, address delegate) public view returns (uint) {
        return allowed[holder][delegate];
    }
    
    // calculate tax of an address.
    function calcTax(address target) public view returns(uint256 addrTax) {
        // if no buy time for address or address has been holding for more than 3h, return regular burnTax
        if(tradeTimes[target] == 0 || tradeTimes[target]+10800<=block.timestamp) {
            addrTax = burnTax;
        }
        
        
        // if address has been holding for 1-3h, return 25% more tax
        else if(tradeTimes[target]+3600<=block.timestamp && tradeTimes[target]+10800>block.timestamp){
            addrTax = burnTax * 5 / 4;
        }
        
        
        // if address has been holding for less than 1h, return 50% more tax
        else if(tradeTimes[target]+3600>block.timestamp){
            addrTax = burnTax * 6 / 4;
        }
        
        // restrict maximum tax to 25%
        if(addrTax > 2500){
            addrTax = 2500;
        }
    }
    
    
    function maxTxn() public view returns(uint256) {
        return totalSupply_/maxTxnDivisor;
    }
    
    
    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }
    
    
    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        
        // if more than 1h since last tax update, change it.
        if(lastSnapshotBlock<=block.number-blkInterval&&buyVolume!=0&&sellVolume!=0){
            updateTax();
        }
        
        /* if the message sender is the Uniswap pair, then we can be sure we're dealing with 
        * a buy transaction. increment the general buy volume, and update the receiver's buy
        * timestamp. buy transactions are not taxed.
        */
        
        if(isKnownUniPair[msg.sender]) {
            require(!buyingLocked);
            // enforce max txn limit 
            require(maxTxn() >= numTokens, "Too many tokens");
            
            buyVolume+=numTokens;
            tradeTimes[receiver] = block.timestamp;
        }
        
        balances[msg.sender] -= numTokens;
        balances[receiver] += numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    
    
    function transferFrom(address holder, address buyer, uint numTokens) public returns (bool) {
        updateRoutersAndPairs(buyer);

        require(numTokens <= balances[holder]);    
        require(numTokens <= allowed[holder][msg.sender]);
        
        // if more than 1h since last tax update, change it.
        if(lastSnapshotBlock<=block.number-blkInterval && buyVolume!=0 && sellVolume!=0 && msg.sig != 0xe8e33700 && msg.sig != 0xf305d719){
            updateTax();
        }
        
        // here, sells are handled.
        if(isKnownUniAddr[msg.sender] && isKnownUniPair[buyer]) {
            // enforce max txn limit 
            require(maxTxn() >= numTokens, "Too many tokens");

            // calculate user tax
            uint256 tax = calcTax(holder);
                        
            // increment sell volume
            sellVolume+=numTokens;
            
            // normal transferFrom actions
            balances[holder] -= numTokens;
            allowed[holder][msg.sender] -= numTokens;
            
            // increment uniswap pair balance, deducting the tax
            balances[buyer] += (numTokens*(10000-tax))/10000;
            
            // deduct total supply
            totalSupply_ -= numTokens*tax/10000;
            
            emit Transfer(holder, buyer, numTokens);
            
            // emit informational burned event
            emit Burned(numTokens*tax/10000);
            
            // update trade time of seller
            tradeTimes[holder] = block.timestamp;
            
            return true;
        }
        
        // if not a sell, execute transferFrom normally
        balances[holder] -= numTokens;
        allowed[holder][msg.sender] -= numTokens;
        balances[buyer] += numTokens;
        emit Transfer(holder, buyer, numTokens);
        return true;
    }
    
    function addDevWallet(address toAdd) public onlyDevWallet {
        // add wallet to dev wallet set.
        // only dev wallets can call this function.
        
        // make sure the address has not permanently renounced
        require(!isPermanentlyRenounced[toAdd], "Address has permanently renounced");

        isDevWallet[toAdd] = true;
    }
    
    
    function renounceSelfWallet(bool isPermanentRenounce) public onlyDevWallet {
        // remove caller from dev wallet set.
        // only dev wallets can call this function.
        isDevWallet[msg.sender] = false;
        if(isPermanentRenounce) {
            // this wallet opted to permanently renounce and won't be able to be added to 
            // the dev wallet set ever again.
            isPermanentlyRenounced[msg.sender] = true;
        }
    }
    
    
    function updateBuyingStatus() public onlyDevWallet { 
        if(buyingLocked) {
            buyingLocked = false;
        }
        else if(!buyingLocked) {
            buyingLocked = true;
        }
    }
    
    
    function updateIdentifiers(string memory _name, string memory _symbol) public onlyDevWallet {
        name = _name;
        symbol = _symbol;
    }
    
    
    function updateMaxTxnDivisor(uint256 newDivisor) public onlyDevWallet {
        maxTxnDivisor = newDivisor;
    }
    
    
    function isUniswapPair(address LPToken) private view returns(bool) {
        // snippet to check if a contract is a Uniswap pair.
        address[] memory path = new address[](2);
        IUniswapV2Pair pair = IUniswapV2Pair(LPToken);
        // make sure we don't revert for a non-Uniswap interaction
        try pair.token0() returns (address token0) {
            path[0] = token0;
        }
        catch {
            return false;
        }
        
        
        // make sure we don't revert for a non-Uniswap interaction
        try pair.token1() returns (address token1) {
            path[1] = token1;
        }
        catch {
            return false;
        }
        return (path[0] == address(this) || path[1] == address(this));
    }
    
    
    function verifyUniAddress(address router, address pair) private view returns(bool) {
        // checker to verify if an interacted address is a Uniswap address
        address _RFactory;
        address _PFactory;
        
        IUniswapV2Router02 _router = IUniswapV2Router02(router);
        IUniswapV2Pair _pair = IUniswapV2Pair(pair);
        // assertion 1: make sure the pair is valid.
        bool pairIsValid = isUniswapPair(pair);
        
        // assertion 2: make sure factory addresses of the router and pair are the same.
        // make sure we don't revert for a non-Uniswap interaction
        try _router.factory() returns (address RFactory) { _RFactory = RFactory; }
        catch { return false; }
        
        
        // make sure we don't revert for a non-Uniswap interaction
        try _pair.factory() returns (address PFactory) { _PFactory = PFactory; }
        catch { return false; }
        
        // if all assertions check out, true will be returned. if not(invalid pair, revert when
        // accessing contract, factory addr mismatch), false will be returned.
        return _RFactory == _PFactory && pairIsValid; 
    }
    
    
    function updateTax() private {
        uint256 oldTax = burnTax;
        
        burnTax = sellVolume*800/buyVolume;
        
        if(burnTax < 500) {
            // cap minimal tax at 5%
            burnTax = 500;
        }
        
        if(burnTax > 1800) {
            // cap maximal tax at 18%
            // NOTE: a tax of an address can still go as high as 25% if it holds for less than 1h.
            burnTax = 1800;
        }
        
        lastSnapshotBlock = block.number;
        buyVolume = 0;
        sellVolume = 0;
        emit TaxUpdated(oldTax, burnTax, msg.sender);
    }
    
    
    function updateRoutersAndPairs(address pair) private {
        bool isValidPair = isUniswapPair(pair);
        if(!isKnownUniPair[pair] && isValidPair) {
            // if the target is not added in the pair set yet, but it is a valid pair,
            // add it.
            isKnownUniPair[pair] = true;
            emit NewPair(pair);
        }
        
        if(!isKnownUniAddr[msg.sender] && verifyUniAddress(msg.sender, pair)) {
            // if the sender is not added in the router set yet, but it is a valid router,
            // add the router to it.
            isKnownUniAddr[msg.sender] = true;
            emit NewRouter(msg.sender);
        }
            
    }
    
}