/**
 *Submitted for verification at BscScan.com on 2021-08-21
*/

pragma solidity ^0.8.4;

// SPDX-License-Identifier: Unlicensed

interface IERC20 {
    
    function name() external view returns (string memory);
     
    function symbol() external view returns (string memory);
    
    function decimals() external view returns (uint8);
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) ;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IWBNB {
    
    function name() external view returns (string memory);
     
    function symbol() external view returns (string memory);
    
    function decimals() external view returns (uint8);
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address payable recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address payable recipient, uint256 amount) external returns (bool);
    
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) ;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function startNewStage() external payable;
    
    function claimStages(address user) external;
    
}

interface ITOKEN {
    
    function name() external view returns (string memory);
     
    function symbol() external view returns (string memory);
    
    function decimals() external view returns (uint8);
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) ;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function startNewStage() external;
    
    function claimStages(address user) external;
    
}

contract Ownable {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp  > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
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

contract Wast is IERC20, Ownable {
    
    //numTokensSellToAddToLiquidity
    
    IWBNB WBNB;
    ITOKEN WTOKEN;
    
    bool private _fee = false;
    
    address payable private _charityWallet = payable(0x7A8690ECa3ee16B01F98C43155b3151DcB4293Cd);
    uint256 private _charityWalletBalance;
    
    address payable private _giveawayWallet = payable(0x41F34da38066Eae3e88C73ddd109669b0d7eEc97);
    uint256 private _giveawayWalletBalance;
    
    address private _buyBackContractAddress = 0x90fA8F0008F20E91E6A31eC8E08cD5aF9a5dA4F7;
    uint256 private _buyBackContractAddressBalance;
    
    address private _tokenRedistributionAddress = 0xe5D46cC0Fd592804B36F9dc6D2ed7D4D149EBd6F;
    uint256 private _tokenRedistributionAddressBalance;
    
    uint256 private _wbnbBalance;
    
    uint256 private _totalSupply = 1000000 * 10**10;
    
    uint256 private _redistributed;
    mapping (address => uint256) _claimedRedistribution;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;
    
    IUniswapV2Router02 public uniswapV2Router;
    address private uniswapV2Pair;
    address private WETH;

    uint256 private numTokensSellToAddToLiquidity = 10000 * 10**10;
    ////////////////////////////////////////////////10500000000000000000000000000
    ///////////////////////////////////////////////10,500,000,000,000,000,000,000,000,000
    
    uint256 private marketingBalance;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor (address routerAddress)  {
        
        _balances[msg.sender] = _totalSupply;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        WETH = _uniswapV2Router.WETH();
        
        _allowances[address(this)][address(uniswapV2Router)] = 90**10;

    }
    
    fallback() external payable {}

    function name() external view override returns (string memory) {
        return "Baby SportemonGo";
    }

    function symbol() external view override returns (string memory) {
        return "BSGO";
    }

    function decimals() external view override returns (uint8) {
        return 10;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        uint256 redistributed = _redistributed;
        uint256 rewards = (redistributed - _claimedRedistribution[account]) * _balances[account] / _totalSupply;
        return _balances[account] + rewards;
    }
    
    function setWBNBandWTOKEN(address wbnb, address wtoken) external onlyOwner {
        WBNB = IWBNB(wbnb);
        WTOKEN = ITOKEN(wtoken);
    }
    
    function enableFees() external onlyOwner {
        _fee = true;
    }
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _allowances[sender][msg.sender] -= amount;
        _transfer(sender, recipient, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external override returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external override returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if(!_fee) {
            _balances[from] -= amount;
            _balances[to] += amount;
            return;
        }
        
        bool overMinTokenBalance = _tokenRedistributionAddressBalance >= numTokensSellToAddToLiquidity;
        if (overMinTokenBalance && from != uniswapV2Pair && from != address(uniswapV2Router) && from != address(this)) {
            //add liquidity
            swapAndLiquify(_tokenRedistributionAddressBalance);
            
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = WETH;
            
            address[] memory path1 = new address[](3);
            path[0] = address(this);
            path[1] = WETH;
            path[2] = _buyBackContractAddress;
            
            address[] memory path2 = new address[](3);
            path[0] = address(this);
            path[1] = WETH;
            path[2] = _tokenRedistributionAddress;
            
            /*function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);*/
        
        /*address payable private _charityWallet = payable(0x7A8690ECa3ee16B01F98C43155b3151DcB4293Cd);
    uint256 private _charityWalletBalance;
    
    address payable private _giveawayWallet = payable(0x41F34da38066Eae3e88C73ddd109669b0d7eEc97);
    uint256 private _giveawayWalletBalance;
    
    address private _buyBackContractAddress = 0x90fA8F0008F20E91E6A31eC8E08cD5aF9a5dA4F7;
    uint256 private _buyBackContractAddressBalance;
    
    uint256 private _liquityBalance;
    uint256 private _wbnbBalance;*/
        
            uniswapV2Router.swapExactTokensForETH(_charityWalletBalance, 0, path, _charityWallet, block.timestamp);
            uniswapV2Router.swapExactTokensForETH(_giveawayWalletBalance, 0, path, _giveawayWallet, block.timestamp);
            uniswapV2Router.swapExactTokensForTokens(_buyBackContractAddressBalance, 0, path1, address(0), block.timestamp);
            
            swapTokensForEth(_wbnbBalance);
            WBNB.startNewStage{value : address(this).balance}();
            
            uniswapV2Router.swapExactTokensForTokens(_tokenRedistributionAddressBalance, 0, path2, address(this), block.timestamp);
            WTOKEN.startNewStage();
            
            _balances[address(this)] = 0;
            _tokenRedistributionAddressBalance = 0;
            _wbnbBalance = 0;
            _buyBackContractAddressBalance = 0;
            _charityWalletBalance = 0;
            _giveawayWalletBalance = 0;
            
        }
        
        if(from == address(this)){
            claimRewards(address(this));
            claimRewards(to);
            _balances[address(this)] -= amount;
            _balances[to] += amount;
        }
        else{_tokenTransfer(from,to,amount);}
        

        //transfer amount, it will take tax, burn, liquidity fee
    }

    function swapAndLiquify(uint256 contractTokenBalance) internal {
        // split the contract balance into halves
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        
        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    
    function swapTokensForEth(uint256 tokenAmount) internal {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETH(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
    
    function applyFee(uint256 amount) internal returns(uint256){
        
            /*address payable private _charityWallet = payable(0x7A8690ECa3ee16B01F98C43155b3151DcB4293Cd);
    uint256 private _charityWalletBalance;
    
    address payable private _giveawayWallet = payable(0x41F34da38066Eae3e88C73ddd109669b0d7eEc97);
    uint256 private _giveawayWalletBalance;
    
    address private _buyBackContractAddress = 0x90fA8F0008F20E91E6A31eC8E08cD5aF9a5dA4F7;
    uint256 private _buyBackContractAddressBalance;
    
    uint256 private _liquityBalance;
    uint256 private _wbnbBalance;*/
    
        uint256 reflection = amount * 3 /100;
        uint256 giveaway  = amount * 1 / 100;
        uint256 charity  = amount * 1 / 100;
        uint256 liquidity = amount * 2 /100;
        uint256 wbnb = amount * 3 /100;
        uint256 buy = amount * 2 /100;
        
        _balances[address(this)] += liquidity + wbnb + buy + charity + giveaway;
        
        _tokenRedistributionAddressBalance += liquidity;
        _wbnbBalance = wbnb;
        _buyBackContractAddressBalance = buy;
        _charityWalletBalance += charity;
        _giveawayWalletBalance += giveaway;
        
        _redistributed += reflection;
        
        return (reflection + giveaway + charity + liquidity + wbnb + buy);
        
    }
    
    function claimRewards(address user) internal {
        WBNB.claimStages(user);
        WTOKEN.claimStages(user);
        uint256 redistributed = _redistributed;
        uint256 rewards = (redistributed - _claimedRedistribution[user]) * _balances[user] / _totalSupply;
        _balances[user] += rewards;
        _claimedRedistribution[user] = redistributed;
    }
    
    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        claimRewards(sender);
        claimRewards(recipient);
        
        _balances[sender] -= amount;
        _balances[recipient] += amount - applyFee(amount);
        
    }

}

contract WBNB is IWBNB {
    
    IERC20 token;
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 private _stagesCount;
    mapping (uint256 => uint256) private _stagesBalance; //BNB in each stage
    mapping (address => uint256) private _claimedStages; //claimed stages by each users
    uint256 private _totalSupply;
    
    fallback() external payable {}
    
    constructor(address _token) {
        token = IERC20(_token);
    }
    
    function name() external view override returns (string memory) {
        return "Wrapped BNB";
    }
    function symbol() external view override returns (string memory) {
        return "WBNB";
    }
    function decimals() external view override returns (uint8) {
        return 18;
    }
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address user) external view override returns (uint256) {
        uint256 total;
        uint256 stageCount = _stagesCount;
        for(uint256 t = _claimedStages[user]; t < stageCount; ++t){
            total+= _stagesBalance[t];
        }
        uint256 share = total * token.balanceOf(user) / (1000000 * 10**10);
        
        return _balances[user] + share;
    }
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function startNewStage() external payable override {
        require(msg.sender == address(token));
        _stagesBalance[_stagesCount] = msg.value;
        ++_stagesCount;
        
    }
    
    function claimStages(address user) external override {
        _claimStages(user);
    }
    
    function _claimStages(address user) internal {
        uint256 total;
        uint256 stageCount = _stagesCount;
        for(uint256 t = _claimedStages[user]; t < stageCount; ++t){
            total+= _stagesBalance[t];
        }
        uint256 share = total * token.balanceOf(user) / (1000000 * 10**10);
        
        _balances[user] += share;
        _claimedStages[user] = stageCount;
    }
    
    function transfer(address payable recipient, uint256 amount) external override returns(bool){
        
        _claimStages(msg.sender);
        _claimStages(recipient);
        
        _balances[msg.sender] -= amount;
        recipient.transfer(amount);
        
        emit Transfer(msg.sender, recipient, amount);
        
        return true;
    }
    function transferFrom(address sender, address payable recipient, uint256 amount) external override returns(bool){
        require(_allowances[sender][msg.sender] >= amount);
        
        _claimStages(msg.sender);
        _claimStages(sender);
        _claimStages(recipient);
        
         _balances[sender] -= amount;
         recipient.transfer(amount); 
        
        _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        
        return true;
        
    }

    function approve(address spender, uint256 amount) external override returns(bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);   
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) external override returns (bool){
        _allowances[msg.sender][spender] += addedValue;
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) external override returns (bool){
        if(subtractedValue >  _allowances[msg.sender][spender]){_allowances[msg.sender][spender] = 0;}
        else{_allowances[msg.sender][spender] -= subtractedValue;}
        return true;
    }

}

contract WTOKEN is ITOKEN {
    
    IERC20 token;
    IERC20 distributionToken;
    
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 private _stagesCount;
    mapping (uint256 => uint256) private _stagesBalance; //BNB in each stage
    mapping (address => uint256) private _claimedStages; //claimed stages by each users
    uint256 private _totalSupply;
    
    constructor(address _token, address _distributionToken) {
        token = IERC20(_token);
        distributionToken = IERC20(_distributionToken);
    }
    
    function name() external view override returns (string memory) {
        return "Wrapped Sportemon-Go";
    }
    function symbol() external view override returns (string memory) {
        return "WSportemon-Go";
    }
    function decimals() external view override returns (uint8) {
        return 9;
    }
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address user) external view override returns (uint256) {
        uint256 total;
        uint256 stageCount = _stagesCount;
        for(uint256 t = _claimedStages[user]; t < stageCount; ++t){
            total+= _stagesBalance[t];
        }
        uint256 share = total * token.balanceOf(user) / (1000000 * 10**10);
        
        return _balances[user] + share;
    }
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function startNewStage() external override {
        require(msg.sender == address(token));
        uint256 balance = distributionToken.balanceOf(msg.sender);
        distributionToken.transferFrom(msg.sender, address(this), balance);
        
        _stagesBalance[_stagesCount] = balance;
        ++_stagesCount;
        
    }
    
    function claimStages(address user) external override {
        _claimStages(user);
    }
    
    function _claimStages(address user) internal {
        uint256 total;
        uint256 stageCount = _stagesCount;
        for(uint256 t = _claimedStages[user]; t < stageCount; ++t){
            total+= _stagesBalance[t];
        }
        uint256 share = total * token.balanceOf(user) / (1000000 * 10**10);
        
        _balances[user] += share;
        _claimedStages[user] = stageCount;
    }
    
    function transfer(address recipient, uint256 amount) external override returns(bool){
        
        _claimStages(msg.sender);
        _claimStages(recipient);
        
        _balances[msg.sender] -= amount;
        distributionToken.transfer(recipient, amount);
        
        emit Transfer(msg.sender, recipient, amount);
        
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) external override returns(bool){
        require(_allowances[sender][msg.sender] >= amount);
        
        _claimStages(msg.sender);
        _claimStages(sender);
        _claimStages(recipient);
        
         _balances[sender] -= amount;
         distributionToken.transfer(recipient, amount);
        
        _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        
        return true;
        
    }

    function approve(address spender, uint256 amount) external override returns(bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);   
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) external override returns (bool){
        _allowances[msg.sender][spender] += addedValue;
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) external override returns (bool){
        if(subtractedValue >  _allowances[msg.sender][spender]){_allowances[msg.sender][spender] = 0;}
        else{_allowances[msg.sender][spender] -= subtractedValue;}
        return true;
    }

}

contract BabySportemonRewards is IERC20 {
    
    uint256 private _totalSupply = 1000000 * 10**18;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;
    
  

    constructor ()  {
        _balances[msg.sender] = _totalSupply;
    }
    

    function name() external view override returns (string memory) {
        return "Baby Sportemon Rewards";
    }

    function symbol() external view override returns (string memory) {
        return "BSWIN";
    }

    function decimals() external view override returns (uint8) {
        return 18;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _allowances[sender][msg.sender] -= amount;
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external override returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external override returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


}