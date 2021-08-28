/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

// SPDX-License-Identifier: UNLICENCED

pragma solidity <0.8.6;

contract OwnerContract{
    address internal owner;
    address internal mainAdmin;
    mapping(address=>bool) public admins;
    
    event ownershipTransfered(address from, address to);
    event MainAdminChanged(address changedBy, address newMainAdmin);
    event AdminAdded(address AddedBy, address newAdmin);
    event adminRemoved(address removedBy, address removedAdmin);
    
    constructor() {
        owner = msg.sender;
        mainAdmin = msg.sender;
    }
    
    modifier isOwner(){
        require(msg.sender==owner, "Access denied!");
        _;
    }
    
    modifier isMainAdmin(){
        if (msg.sender == owner || msg.sender == mainAdmin){
            _;
        }
        else revert("Access denied!");
    }
    
    modifier isAdmin(){
        if (msg.sender == owner || msg.sender == mainAdmin || admins[msg.sender]){
            _;
        }
        else revert("Access denied!");
    }
    
    function transferOwnership(address _to) public isOwner{
        owner = _to;
        emit ownershipTransfered(msg.sender, owner);
    }
    
    function changeMainAdmin(address _to) public isMainAdmin{
        mainAdmin = _to;
        emit MainAdminChanged(msg.sender, _to);
    }
    
    function addAdmin(address _admin) public isMainAdmin{
        admins[_admin] = true;
        emit AdminAdded(msg.sender, _admin);
    }
    
    function removeAmin(address _admin) public isMainAdmin{
        admins[_admin] = false;
        emit adminRemoved(msg.sender, _admin);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view virtual returns (string memory) {return _name;}
    function symbol() public view virtual returns (string memory) {return _symbol;}
    function decimals() public view virtual returns (uint8) {return _decimals;}
    function totalSupply() public view virtual override returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view virtual override returns (uint256) {return _balances[account];}

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);
  function getRoundData(uint80 _roundId) external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData() external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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

contract ColletoralsContract{
    
    AggregatorV3Interface WBTCAggregator = AggregatorV3Interface(0xECe365B379E1dD183B20fc5f022230C044d51404);
    AggregatorV3Interface WETHAggregator = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    AggregatorV3Interface LINKAggregator = AggregatorV3Interface(0x396c5E36DD0a0F5a5D33dae44368D4193f69a1F0);
    /*
    AggregatorV3Interface UNIAggregator = AggregatorV3Interface();
    AggregatorV3Interface MATICAggregator = AggregatorV3Interface();
    AggregatorV3Interface QUICKAggregator = AggregatorV3Interface();
    AggregatorV3Interface SOLAggregator = AggregatorV3Interface();
    AggregatorV3Interface PBNBAggregator = AggregatorV3Interface();
    */
    
    function getWBTCPrice() public view returns (uint){
        (, int256 answer,,,) = WBTCAggregator.latestRoundData();
        answer = answer - (answer % 1);
        return uint(answer/10**8);
    }
    
    function getWETHPrice() public view returns (uint){
        (, int256 answer,,,) = WETHAggregator.latestRoundData();
        answer = answer - (answer % 1);
        return uint(answer/10**8);
    }
    
    function getLINKPrice() public view returns (uint){
        (, int256 answer,,,) = LINKAggregator.latestRoundData();
        answer = answer - (answer % 1);
        return uint(answer/10**8);
    }
    /*
    function getUNIPrice() public view returns (uint){
        (, int256 answer,,,) = UNIAggregator.latestRoundData();
        answer = answer - (answer % 1);
        return uint(answer/10**8);
    }
    
    function getMATICPrice() public view returns (int){
        (, int256 answer,,,) = MATICAggregator.latestRoundData();
        answer = answer - (answer % 1);
        return answer/10**8;
    }
    
    function getQUICKPrice() public view returns (int){
        (, int256 answer,,,) = QUICKAggregator.latestRoundData();
        answer = answer - (answer % 1);
        return answer/10**8;
    }
    
    function getSOLPrice() public view returns (int){
        (, int256 answer,,,) = SOLAggregator.latestRoundData();
        answer = answer - (answer % 1);
        return answer/10**8;
    }
    
    function getPBNBPrice() public view returns (int){
        (, int256 answer,,,) = PBNBAggregator.latestRoundData();
        answer = answer - (answer % 1);
        return answer/10**8;
    }
    */
    
}

interface WETHERC20{
  function deposit() external payable;
  function transfer(address dst, uint wad) external returns (bool);
  function withdraw(uint wad) external;
  function allowance(address _owner, address _spender)external view returns (uint256);
  function approve(address _spender, uint256 _value) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
  event Approval(address indexed owner, address indexed spender,uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract simurgStable is ERC20, OwnerContract, ColletoralsContract{
    
    WETHERC20 WBTC = WETHERC20(0x577D296678535e4903D59A4C929B718e1D575e0A);
    WETHERC20 USDT = WETHERC20(0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02);
    WETHERC20 LINK = WETHERC20(0x01BE23585060835E02B77ef475b0Cc51aA1e0709);
    WETHERC20 WETH = WETHERC20(0xc778417E063141139Fce010982780140Aa0cD5Ab);
    WETHERC20 USDC = WETHERC20(0x577D296678535e4903D59A4C929B718e1D575e0A);
    
    /*
    WETHERC20 UNI = WETHERC20(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    WETHERC20 MATIC = WETHERC20(0x1343A33d5510e95B87166433BCDDd5DbEe8B4D8A);
    
    IUniswapV2Router02 ETHtoWETH = IUniswapV2Router02 (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    UniswapV2Factory Unifactory = UniswapV2Factory (0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    */
    
    constructor() ERC20("Simurg Stable Dollar", "SSD08"){}
    
    address[] swapPath = new address[](2);
    
    function mint(address _address, uint _amount) internal{
        _mint(_address, _amount);
    }
    
    function mintNewStableWithETH() payable public{
        if (msg.value > 1 wei){
            uint256 mintAmount = getWETHPrice() * msg.value;
            mint(payable(msg.sender), mintAmount);
            changeETHtoWETH();
        }
        else{revert("Not enough money");}
    }
    
    function mintNewStableWithWETH(uint _amount) public {
        require(_amount > 0, "You need to sell at least some tokens");
        uint256 allowance = WETH.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        uint256 price = getWETHPrice();
        WETH.transferFrom(msg.sender, address(this), _amount);
        mint(msg.sender, price*_amount);
        emit Transfer(msg.sender, address(this), _amount);
    }
    
    function mintNewStableWithWBTC(uint _amount) public {
        require(_amount > 0, "You need to sell at least some tokens");
        uint256 allowance = WBTC.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        uint256 price = getWBTCPrice();
        WBTC.transferFrom(msg.sender, address(this), _amount);
        mint(msg.sender, price*_amount);
        emit Transfer(msg.sender, address(this), _amount);
    }
    
    function mintNewStableWithUSDT(uint _amount) public {
        require(_amount > 0, "You need to sell at least some tokens");
        USDT.transferFrom(msg.sender, address(this), _amount);
        mint(msg.sender, _amount);
        emit Transfer(msg.sender, address(this), _amount);
    }
    
    function mintNewStableWithLINK(uint _amount) public {
        require(_amount > 0, "You need to sell at least some tokens");
        uint256 allowance = LINK.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        uint256 price = getLINKPrice();
        LINK.transferFrom(msg.sender, address(this), _amount);
        mint(msg.sender, price * _amount);
        emit Transfer(msg.sender, address(this), _amount);
    }
    
    function changeETHtoWETH() internal{
        WETH.deposit{value: msg.value}();
        WETH.transfer(address(this), msg.value);
    }
    
    function changeWETHtoETH(uint _amount) internal{
        WETH.withdraw(_amount);
    }
    
    function getBackETH() public isAdmin{
        payable(msg.sender).transfer(address(this).balance);
    }
}