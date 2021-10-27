/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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

    function renounceOwnership() external virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
    
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    // solhint-disable-next-line
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {} // solhint-disable-line

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {} // solhint-disable-line
}

interface ISPLINK is IERC20 {

    event TaxAddressChanged(address newTaxAddress);
    event TaxedTransferAddedFor(address[] addresses);
    event TaxedTransferRemovedFor(address[] addresses);

    event TaxTaken(uint256 teamFee);
    event TaxChanged(Tax newFees);

    struct Tax {
        uint256 buyTax;
        uint256 sellTax;
    }

    function currentFees() external view returns (Tax memory);


    function taxedPair(address pair) external view returns (bool);
}

library Utils {
    /**
     * @dev Calculates the percentage of a number
     * @param number: The number to calculate the percentage of
     * @param percentage: The percentage of the number to return
     * @return The percentage of a number
     */
    function percentageOf(uint256 number, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        return (number * percentage) / 100;
    }

    /**
     * @dev Swaps an amount of tokens for ETH
     * @param uniswapV2Router: The uniswap router to trade through
     * @param amount: The amount of tokens to swap
     * @param to: The address to send the recieved tokens to
     * @return The amount of ETH recieved
     */
    function swapForETH(
        IUniswapV2Router uniswapV2Router,
        uint256 amount,
        address to
    ) internal returns (uint256) {
        uint256 startingBalance = to.balance;
        address[] memory path = new address[](2);

        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            to,
            block.timestamp
        );

        return to.balance - startingBalance;
    }

    /**
     * @dev Adds liquidity for the token in ETH
     * @param uniswapV2Router: The uniswap router to add liquidity through
     * @param amountToken: The amount of tokens to add liquidity with
     * @param amountETH: The amount of ETH to add liquidity with
     * @param to: The address to send the recieved LP tokens to
     */
    function addLiquidityETH(
        IUniswapV2Router uniswapV2Router,
        uint256 amountToken,
        uint256 amountETH,
        address to
    ) internal {
        uniswapV2Router.addLiquidityETH{value: amountETH}(
            address(this),
            amountToken,
            0,
            0,
            to,
            block.timestamp
        );
    }

    /**
     * @param token: The address of the token to transfer
     * @param from: The sender of the tokens
     * @param to: The receiver of the tokens
     * @param amount: The amount of tokens to transfer
     */
    function transferTokens(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        IERC20(token).transferFrom(from, to, amount);
    }

    /**
     * @dev Returns the token for a Uniswap V2 Pair
     */
    function tokenFor(address pair) internal view returns (address) {
        return IUniswapV2Pair(pair).token0();
    }

    /**
    * @dev Checks if transaction amount is below max
    * @param amount: The amount to be transferred
    */
    function isNotGreaterThanMaxTXLimit(uint256 amount) internal pure returns (bool) {
      uint256 MAX_TX = 10000000000000 * 10**9; 
      return amount <= MAX_TX;
    }

    /**
    * @dev Checks if wallet balance has reached max balance per wallet
    * @param balanceOfWallet: the balance of wallet to be checked
    */
    function balanceIsLessThanMax(uint256 balanceOfWallet ) internal pure returns (bool) {
      uint256 MAX_BALANCE = 15000000000000 * 10**9; 
      return balanceOfWallet <= MAX_BALANCE;
    }
}

contract SPLINK is ISPLINK, Ownable, ERC20 {
   using SafeMath for uint256;

    uint256 internal constant MAX = type(uint256).max;

    uint256 private constant SUPPLY = 1000000000000000 * 10**9; 
    string internal constant NAME = "Space Link";
    string internal constant SYMBOL = "SPLINK";
    uint8 internal constant DECIMALS = 9;

    mapping(address => address) internal _routerFor;
    mapping(address => bool) private _isWhitelisted;
    mapping(address => bool) private _isTaxExempted;
    mapping (address => bool) private bots;
    mapping (address => uint) private cooldown;

    Tax private fees;

    address payable internal _taxAddress;

    IUniswapV2Router internal uniswapV2Router;
    address internal uniswapV2Pair;

    bool public tradingOpen;
    bool public liquidityAdded;
    bool private inSwap;
    bool public swapEnabled;
    bool private whiteListActive;
    bool public cooldownEnabled;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address payable addr1) ERC20(NAME, SYMBOL) {
        _taxAddress = addr1;
        _mint(_msgSender(), SUPPLY);
        fees = Tax(8,8);
    }

    function decimals() public pure virtual override returns (uint8) {
        return DECIMALS;
    }
    
    function taxedPair(address pair)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _routerFor[pair] != address(0);
    }

    // Transfer, no events for fees
    function transferFee(address from, uint256 amount) internal {
        _balances[from] -= amount;
        _balances[address(this)] += amount;
    }

    function takeFee(
        address from,
        uint256 amount,
        uint256 teamFee
    ) internal returns (uint256) {
        if (teamFee == 0) return 0;
        uint256 tTeam = Utils.percentageOf(amount, teamFee);
        transferFee(from, tTeam);
        emit TaxTaken(tTeam);
        return tTeam;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // If no fee, 0
        uint256 _teamFee;

        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to], "SPLINK: Currrently tagged as a bot");
            
            
            if (liquidityAdded) {
                require(tradingOpen, "SPLINK: Trading is not Open");
           
            
                if (whiteListActive) {
                     require(_isWhitelisted[to],  "SPLINK: Address must be whitelisted");
                }

                if (swapEnabled && !inSwap) {
     
                     if (taxedPair(from) && !taxedPair(to)) {
                       uint256 walletBalance = balanceOf(to).add(amount);
                      // buying transfer
                        require(Utils.isNotGreaterThanMaxTXLimit(amount), "SPLINK: Max tx exceeded");
                        require(Utils.balanceIsLessThanMax(walletBalance), "SPLINK: Max holding exceeded");
    
                        if (cooldownEnabled) {
                          require(cooldown[to] < block.timestamp);
                          cooldown[to] = block.timestamp + (30 seconds);
                        }
                        
                        _teamFee = _isTaxExempted[to] ? 0 : fees.buyTax;
                    }  else if (taxedPair(to)) {
                      // selling transfer
                        swapTokensForEth(balanceOf(address(this)));
                        sendETHToFee(address(this).balance);
                        _teamFee = _isTaxExempted[from] ? 0 : fees.sellTax;
                    }
                  
                } else {
                    require(swapEnabled, "SPLINK: Swap must be enabled");
                }
            }
        }

        uint256 fee = takeFee(from, amount, _teamFee);
        super._transfer(from, to, amount - fee);
    }

    function swapTokensForEth(uint256 tokenAmount) internal lockTheSwap {
        Utils.swapForETH(uniswapV2Router, tokenAmount, address(this));
    }

    function sendETHToFee(uint256 amount) internal {
        _taxAddress.transfer(amount);
    }

    function openTrading() external virtual onlyOwner {
        require(liquidityAdded);
        tradingOpen = true;
        cooldownEnabled = true;
        swapEnabled = true;
    }
    
    function toggleWhiteList(bool onOff) external virtual onlyOwner {
       whiteListActive = onOff;
    }

    function addDEX(address pair, address router) public virtual onlyOwner {
        require(!taxedPair(pair), "DEX already exists");
        address tokenFor = Utils.tokenFor(pair);
        _routerFor[pair] = router;
        _approve(address(this), router, MAX);
        IERC20(tokenFor).approve(router, MAX);
        IERC20(pair).approve(router, MAX);
    }

    function removeDEX(address pair) external virtual onlyOwner {
        require(taxedPair(pair), "DEX does not exist");
        address tokenFor = Utils.tokenFor(pair);
        address router = _routerFor[pair];
        delete _routerFor[pair];
        _approve(address(this), router, 0);
        IERC20(tokenFor).approve(router, 0);
        IERC20(pair).approve(router, 0);
    }

    function addLiquidity() external virtual onlyOwner lockTheSwap {
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        addDEX(uniswapV2Pair, address(_uniswapV2Router));
        Utils.addLiquidityETH(
            uniswapV2Router,
            balanceOf(address(this)),
            address(this).balance,
            owner()
        );
        liquidityAdded = true;
    }

    function setBots(address[] calldata bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
    
    function delBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    function addToWhiteList(address[] calldata addresses)
        external
        virtual
        onlyOwner
    {
        for (uint256 i; i < addresses.length; i++) {
            _isWhitelisted[addresses[i]] = true;
        }
    }
    
    
    function removeFromWhiteList(address[] calldata addresses)
        external
        virtual
        onlyOwner
    {
        for (uint256 i; i < addresses.length; i++) {
            _isWhitelisted[addresses[i]] = false;
        }
    }

    function addToTaxExempted(address[] calldata addresses)
        external
        virtual
        onlyOwner
    {
        for (uint256 i; i < addresses.length; i++) {
            _isTaxExempted[addresses[i]] = true;
        }
    }
    
    function removeFromTaxExemption(address[] calldata addresses)
        external
        virtual
        onlyOwner
    {
        for (uint256 i; i < addresses.length; i++) {
            _isTaxExempted[addresses[i]] = false;
        }
    }

    
    function setTaxAddress(address payable newTaxAddress) external onlyOwner {
        _taxAddress = newTaxAddress;
        emit TaxAddressChanged(newTaxAddress);
    }

    function manualswap() external onlyOwner {
        swapTokensForEth(balanceOf(address(this)));
    }

    function manualsend() external onlyOwner {
        sendETHToFee(address(this).balance);
    }

    function setSwapRouter(IUniswapV2Router newRouter) external onlyOwner {
        require(liquidityAdded, "Add liquidity before doing this");

        address weth = uniswapV2Router.WETH();
        address newPair = IUniswapV2Factory(newRouter.factory()).getPair(
            address(this),
            weth
        );
        require(
            newPair != address(0),
            "WETH Pair does not exist for that router"
        );
        require(taxedPair(newPair), "The pair must be a taxed pair");

        (uint256 reservesOld, , ) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        (uint256 reservesNew, , ) = IUniswapV2Pair(newPair).getReserves();
        require(
            reservesNew > reservesOld,
            "New pair must have more WETH Reserves"
        );

        uniswapV2Router = newRouter;
        uniswapV2Pair = newPair;
    }

    function setBuyTax(uint256 newBuyTax) public onlyOwner {
      require(newBuyTax <= 8, "SPLINK: Buy Tax must be less than or eqaul to 8");
      fees = Tax(newBuyTax, fees.sellTax);

      emit TaxChanged(fees);
    }

    function setSellTax(uint256 newSellTax) public onlyOwner {
      require(newSellTax <= 8, "SPLINK: Sell Tax must be less than or eqaul to 8");
      fees = Tax(fees.buyTax, newSellTax);

      emit TaxChanged(fees);
    }

    function setCooldownEnabled(bool onoff) external onlyOwner() {
        cooldownEnabled = onoff;
    }

    function currentFees() external view override returns (Tax memory) {
        return fees;
    }

    // solhint-disable-next-line
    receive() external payable virtual {}
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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