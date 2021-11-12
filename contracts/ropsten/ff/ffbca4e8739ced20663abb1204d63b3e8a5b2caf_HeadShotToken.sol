/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

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

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

contract HeadShotToken is Ownable, IERC20 {
    string private _name = "Headshot";
    string private _symbol = "HST";
    uint256 private _decimal = 18;
    /*
    string private _ticketCreateName = "HeadshotCreateTicket";
    string private _ticketCreateSymbol = "HST_CREATE";

    string private _ticketVoteName = "HeadshotVoteTicket";
    string private _ticketVoteSymbol = "HST_VOTE";

    string private _ticketVerifyName = "HeadshotVerifyTicket";
    string private _ticketVerifySymbol = "HST_VERIFY";
    */
    uint256 private marketingFeeBPS = 300;
    uint256 private liquidityFeeBPS = 300;
    uint256 private developmentFeeBPS = 300;
    uint256 private totalFeeBPS = 900;

    uint256 private _priceOfRegister = 10000;
    uint256 private _priceOfVerify = 20000;
    uint256 private _priceOfVote = 100;

    uint256 private _realPriceOfRegister;
    uint256 private _realPriceOfVerify;
    uint256 private _realPriceOfVote;

    uint256 public swapTokensAtAmount = 10000000 * (10 ** _decimal);
    uint256 private minimumBalanceRequired = 1 * 10 ** 9;

    uint256 public lastSwapTime;

    bool public swapEnabled = true;
    bool public taxEnabled = true;

    uint256 private _totalSupply;
    bool private swapping;

    address public marketingWallet;
    address public developmentWallet;
    address public salesWallet;

    address public uniswapV2Pair;

    uint256 public maxTxBPS = 75;
    uint256 public maxWalletBPS = 175;

    bool public maxTxEnabled = true;
    bool public maxWalletEnabled = true;
    bool public voteAirdrop = true;

    mapping(address => uint256) private _balances;

    mapping(address => uint256) private _createTicketBalances;
    mapping(address => uint256) private _voteTicketBalances;
    mapping(address => uint256) private _verifyTicketBalances;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) private _isExcludedFromMaxTx;
    mapping(address => bool) private _isExcludedFromMaxWallet;

    event SwapAndAddLiquidity(uint256 tokensSwapped, uint256 nativeReceived, uint256 tokensIntoLiquidity);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event SwapEnabled(bool enabled);
    event TaxEnabled(bool enabled);
    event SwapBNBForTokens(uint256 amountIn, address[] path);

    IUniswapV2Router02 public uniswapV2Router;

    constructor() {
        //address uniswapV2Addr = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // Mainnet
        address uniswapV2Addr = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Ropsten
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniswapV2Addr);

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);

        excludeFromMaxTx(owner(), true);
        excludeFromMaxTx(address(this), true);

        excludeFromMaxWallet(owner(), true);
        excludeFromMaxWallet(address(this), true);

        _mint(owner(), 1000000000000 * (10 ** _decimal));
    }

    receive() external payable {}

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimal;
    }

    function marketingFee() public view returns (uint256) {
        return marketingFeeBPS / 100;
    }

    function liquidityFee() public view returns (uint256) {
        return liquidityFeeBPS / 100;
    }

    function developmentFee() public view returns (uint256) {
        return developmentFeeBPS / 100;
    }

    function totalFee() public view returns (uint256) {
        return totalFeeBPS / 100;
    }

    function calcAllFee() private {
        totalFeeBPS = marketingFeeBPS + liquidityFeeBPS + developmentFeeBPS;
    }

    function setRealPrice() private {
        _realPriceOfRegister = _priceOfRegister * (10 ** _decimal);
        _realPriceOfVerify = _priceOfVerify * (10 ** _decimal);
        _realPriceOfVote = _priceOfVote * (10 ** _decimal);
    }

    function priceOfCreate() public view returns (uint256) {
        return _priceOfRegister;
    }

    function priceOfVote() public view returns (uint256) {
        return _priceOfVote;
    }

    function priceOfVerify() public view returns (uint256) {
        return _priceOfVerify;
    }

    function setCreatePrice(uint256 value) external onlyOwner {
        _priceOfRegister = value;
        setRealPrice();
    }

    function setVotePrice(uint256 value) external onlyOwner {
        _priceOfVote = value;
        setRealPrice();
    }

    function setVerifyPrice(uint256 value) external onlyOwner {
        _priceOfVerify = value;
        setRealPrice();
    }

    function setMarketingWallet(address payable wallet) external onlyOwner {
        marketingWallet = wallet;
    }

    function setDevelopmentWallet(address payable wallet) external onlyOwner {
        developmentWallet = wallet;
    }

    function setSalesWallet(address payable wallet) external onlyOwner {
        salesWallet = wallet;
    }

    function setMarketingFee(uint256 value) external onlyOwner {
        marketingFeeBPS = value;
        calcAllFee();
    }

    function setLiquidityFee(uint256 value) external onlyOwner {
        liquidityFeeBPS = value;
        calcAllFee();
    }

    function setDevelopmentFee(uint256 value) external onlyOwner {
        developmentFeeBPS = value;
        calcAllFee();
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function balanceCreateTicket(address account) public view returns (uint256) {
        return _createTicketBalances[account];
    }

    function balanceVoteTicket(address account) public view returns (uint256) {
        return _voteTicketBalances[account];
    }

    function balanceVerifyTicket(address account) public view returns (uint256) {
        return _verifyTicketBalances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "SHOT: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "SHOT: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "SHOT: transfer from the zero address");
        require(recipient != address(0), "SHOT: transfer to the zero address");

        calcAllFee();
        setRealPrice();

        if(sender == address(uniswapV2Pair) && recipient != address(uniswapV2Router)) {
            // check the max tx, unless sender or recipient excluded
            if(maxTxEnabled && !_isExcludedFromMaxTx[sender] && !_isExcludedFromMaxTx[recipient]) {
                uint256 maxTx = totalSupply() * maxTxBPS / 10000;
                require(amount <= maxTx, "anti-whale max tx enforced");
            }

            // check the max wallet size, unless sender or recipient excluded
            if(maxWalletEnabled && !_isExcludedFromMaxWallet[sender] && !_isExcludedFromMaxWallet[recipient]) {
                uint256 maxWallet = totalSupply() * maxWalletBPS / 10000;
                require((balanceOf(recipient) + amount) <= maxWallet, "anti-whale max wallet enforced");
            }
        }

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "SHOT: transfer amount exceeds balance");

        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 contractNativeBalance = address(this).balance;

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(swapEnabled &&
        canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[sender] && // no swap on remove liquidity step 1 or DEX buy
            sender != address(uniswapV2Router) && // no swap on remove liquidity step 2
            sender != owner() &&
            recipient != owner()
        ) {
            swapping = true;

            _executeSwap(contractTokenBalance, contractNativeBalance);

            lastSwapTime = block.timestamp;
            swapping = false;
        }

        bool takeFee;

        if(sender == address(uniswapV2Pair) || recipient == address(uniswapV2Pair)) {
            takeFee = true;
        }

        if(_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
            takeFee = false;
        }

        if(swapping || !taxEnabled) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 fees = amount * totalFeeBPS / 10000;
            amount -= fees;
            _executeTransfer(sender, address(this), fees);
        }

        _executeTransfer(sender, recipient, amount);
    }

    function _executeTransfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "SHOT: transfer from the zero address");
        require(recipient != address(0), "SHOT: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "SHOT: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "SHOT: zero address");
        require(spender != address(0), "SHOT: zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "SHOT: zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) private {
        require(account != address(0), "SHOT: zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "SHOT: exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function swapTokensForNative(uint256 tokens) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokens);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokens,
            0, // accept any amount of native
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokens, uint256 native) private {
        _approve(address(this), address(uniswapV2Router), tokens);
        uniswapV2Router.addLiquidityETH{value: native}(
            address(this),
            tokens,
            0, // slippage unavoidable
            0, // slippage unavoidable
            address(0), // no one gets the liquidity tokens, its locked
            block.timestamp
        );
    }

    function _executeSwap(uint256 tokens, uint256 native) private {
        if(tokens <= 0) {
            return;
        }

        uint256 swapTokensMarketing;
        if(address(marketingWallet) != address(0)) {
            swapTokensMarketing = tokens * marketingFeeBPS / totalFeeBPS;
        }

        uint256 swapTokensDevelopment = 0;
        if(address(developmentWallet) != address(0)) {
            swapTokensDevelopment = tokens * developmentFeeBPS / totalFeeBPS;
        }

        uint256 tokensForLiquidity = tokens - swapTokensMarketing - swapTokensDevelopment;
        uint256 swapTokensLiquidity = tokensForLiquidity / 2;
        uint256 addTokensLiquidity = tokensForLiquidity - swapTokensLiquidity;
        uint256 swapTokensTotal = swapTokensMarketing + swapTokensDevelopment + swapTokensLiquidity;

        uint256 initNativeBal = address(this).balance;
        swapTokensForNative(swapTokensTotal);
        uint256 nativeSwapped = (address(this).balance - initNativeBal) + native;

        uint256 nativeMarketing = nativeSwapped * swapTokensMarketing / swapTokensTotal;
        uint256 nativeDevelopment = nativeSwapped * swapTokensDevelopment / swapTokensTotal;
        uint256 nativeLiquidity = nativeSwapped - nativeMarketing - nativeDevelopment;

        if(nativeMarketing > 0) {
            payable(marketingWallet).transfer(nativeMarketing);
        }

        if(nativeDevelopment > 0) {
            payable(developmentWallet).transfer(nativeDevelopment);
        }

        addLiquidity(addTokensLiquidity, nativeLiquidity);
        emit SwapAndAddLiquidity(swapTokensLiquidity, nativeLiquidity, addTokensLiquidity);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "SHOT: account is already set to requested state");
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "SHOT: DEX pair can not be removed");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "SHOT: automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "SHOT: the router is already set to the new address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
        .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function setSwapEnabled(bool _enabled) external onlyOwner () {
        swapEnabled = _enabled;
        emit SwapEnabled(_enabled);
    }

    function setTaxEnabled(bool _enabled) external onlyOwner () {
        taxEnabled = _enabled;
        emit TaxEnabled(_enabled);
    }

    function setMaxTxEnabled(bool _enabled) external onlyOwner () {
        maxTxEnabled = _enabled;
    }

    function setMaxTxBPS(uint256 bps) external onlyOwner () {
        require(bps >= 75 && bps <= 10000, "BPS must be between 75 and 10000");
        maxTxBPS = bps;
    }

    function excludeFromMaxTx(address account, bool excluded) public onlyOwner () {
        _isExcludedFromMaxTx[account] = excluded;
    }

    function isExcludedFromMaxTx(address account) public view returns (bool) {
        return _isExcludedFromMaxTx[account];
    }

    function setMaxWalletEnabled(bool _enabled) external onlyOwner () {
        maxWalletEnabled = _enabled;
    }

    function setMaxWalletBPS(uint256 bps) external onlyOwner () {
        require(bps >= 175 && bps <= 10000, "BPS must be between 175 and 10000");
        maxWalletBPS = bps;
    }

    function excludeFromMaxWallet(address account, bool excluded) public onlyOwner () {
        _isExcludedFromMaxWallet[account] = excluded;
    }

    function isExcludedFromMaxWallet(address account) public view returns (bool) {
        return _isExcludedFromMaxWallet[account];
    }

    function buyTicket(uint256 _mode, uint256 _count) public returns (bool) {
        if (_mode == 0){
            _executeTransfer(_msgSender(), salesWallet, _count * _realPriceOfRegister);
            _createTicketBalances[_msgSender()] += _count;
        } else if (_mode == 1){
            _executeTransfer(_msgSender(), salesWallet, _count * _realPriceOfVerify);
            _verifyTicketBalances[_msgSender()] += _count;
        } else if (_mode == 2) {
            _executeTransfer(_msgSender(), salesWallet, _count * _realPriceOfVote);
            _voteTicketBalances[_msgSender()] += _count;
        }
        airdropVoteTicket(_msgSender());
        return true;
    }

    function useTicket(uint256 _mode) public returns (bool) {
        uint256 _count = 1;
        bool result = false;
        if (_mode == 0){
            uint256 currBalance = _createTicketBalances[_msgSender()];
            if (currBalance - _count > 0){
                //_executeTransfer(_msgSender(), salesWallet, _count * _realPriceOfRegister);
                _createTicketBalances[_msgSender()] -= _count;
                result = true;
            }
        } else if (_mode == 1){
            uint256 currBalance = _verifyTicketBalances[_msgSender()];
            if (currBalance - _count > 0){
                //_executeTransfer(_msgSender(), salesWallet, _count * _realPriceOfVerify);
                _verifyTicketBalances[_msgSender()] -= _count;
                result = true;
            }
        } else if (_mode == 1){
            uint256 currBalance = _voteTicketBalances[_msgSender()];
            if (currBalance - _count > 0){
                //_executeTransfer(_msgSender(), salesWallet, _count * _realPriceOfVote);
                _voteTicketBalances[_msgSender()] -= _count;
                result = true;
            }
        }
        return result;
    }

    function setVoteAirdropEnabled(bool _enabled) external onlyOwner () {
        voteAirdrop = _enabled;
    }

    function airdropVoteTicket(address _address) private {
        if (voteAirdrop)
            _voteTicketBalances[_address] += 1;
    }
}