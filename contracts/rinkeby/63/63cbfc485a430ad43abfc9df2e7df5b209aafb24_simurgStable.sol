/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

// SPDX-License-Identifier: UNLICENCED

pragma solidity <0.8.6;

abstract contract OwnerContract{
    address internal owner;
    
    address WBTCAddress = 0x577D296678535e4903D59A4C929B718e1D575e0A;
    address USDTAddress = 0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02;
    address USDCAddress = 0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b;
    address WETHAddress = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address LINKAddress = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    address UNISWAP_R_V2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address WBTCOracleAddress = 0xECe365B379E1dD183B20fc5f022230C044d51404;
    address WETHOracleAddress = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
    address LINKOracleAddress = 0xd8bD0a1cB028a31AA859A21A3758685a95dE4623;
    
    
    event ownershipTransfered(address from, address to);
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier isOwner(){
        require(msg.sender==owner, "Access denied!");
        _;
    }
    
    function transferOwnership(address _to) public isOwner{
        owner = _to;
        emit ownershipTransfered(msg.sender, owner);
    }

    function changeAddress(uint _choice, address _address) public isOwner{
        if (_choice == 0){WBTCAddress = _address;}
        else if(_choice == 1){USDTAddress = _address;}
        else if(_choice == 2){USDCAddress = _address;}
        else if(_choice == 3){WETHAddress = _address;}
        else if(_choice == 4){LINKAddress = _address;}
        else if(_choice == 5){UNISWAP_R_V2 = _address;}
        else if(_choice == 6){WBTCOracleAddress = _address;}
        else if(_choice == 7){WETHOracleAddress = _address;}
        else if(_choice == 8){LINKOracleAddress = _address;}
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

abstract contract ERC20 is Context, IERC20 {
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
  function latestRoundData() external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

interface IUniswapV2Router02 {
    
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
    
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

abstract contract ColletoralsContract is OwnerContract{
    
    AggregatorV3Interface WBTCAggregator = AggregatorV3Interface(WBTCOracleAddress);
    AggregatorV3Interface WETHAggregator = AggregatorV3Interface(WETHOracleAddress);
    AggregatorV3Interface LINKAggregator = AggregatorV3Interface(LINKOracleAddress);
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
        return uint(answer/10**6);
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

interface WETHERC20 is IERC20{
    function deposit() external payable;
    function withdraw(uint wad) external;
}

abstract contract profitContract is OwnerContract{
    
    event profitContractAddressChanged(address _by, address _to);
    
    address profitContractAddress = 0xcA1C707986c098C3dea255EDF92A0a6C8a9e7808;
    
    ShareProfitInterface ProfitSpread = ShareProfitInterface(profitContractAddress);
    
    function changeProfitReceiver(address _to) public isOwner{
        profitContractAddress = payable(_to);
        emit profitContractAddressChanged(msg.sender, _to);
    }
}

abstract contract liquidityAddContract is OwnerContract, ColletoralsContract, ERC20, profitContract{
    uint internal WETHAmount;
    uint internal WBTCAmount;
    uint internal LINKAmount;
    uint internal USDTAmount;
    uint internal USDCAmount;
    uint public result2;
    uint[] public result3;
    
    IUniswapV2Router02 Uniswap = IUniswapV2Router02 (UNISWAP_R_V2);
    
    function swapWETH() public returns (uint[] memory){
        uint _amount = WETHAmount * 7 / 10;
        require(_amount > 0, "Not enough amount of tokens");
        uint timeNow = block.timestamp;
        address[] memory swapPath = new address[](2);
        swapPath[0] = WETHAddress;
        swapPath[1] = USDTAddress;
        uint price = getWETHPrice();
        uint[] memory result = Uniswap.swapExactTokensForTokens(_amount, (_amount * price * 90 / 100), swapPath, address(this), timeNow + 120);
        WETHAmount -= result[0];
        USDTAmount += result[1];
        return result;
    }
    
    function swapWBTC() public returns(uint[] memory){
        uint _amount = WBTCAmount * 7 / 10;
        require(_amount > 0, "Not enough amount of tokens");
        uint timeNow = block.timestamp;
        address[] memory swapPath = new address[](2);
        swapPath[0] = WBTCAddress;
        swapPath[1] = USDCAddress;
        uint price = (9882);
        uint[] memory result = Uniswap.swapExactTokensForTokens(_amount, (_amount * price * 90 / 100), swapPath, address(this), timeNow + 120);
        WBTCAmount -= result[0];
        USDCAmount += result[1];
        return result;
    }
    
    function swapLINK() public returns(uint[] memory){
        uint _amount = LINKAmount * 7 / 10;
        require(_amount > 0, "Not enough amount of tokens");
        uint timeNow = block.timestamp;
        address[] memory swapPath = new address[](2);
        swapPath[0] = LINKAddress;
        swapPath[1] = USDTAddress;
        uint price = getLINKPrice();
        uint[] memory result = Uniswap.swapExactTokensForTokens(_amount, (_amount * (price / 100) * 90 / 100), swapPath, address(this), timeNow + 120);
        LINKAmount -= result[0];
        USDTAmount += result[1];
        return result;
    }
    
    function addLiquidityStable() public{
        if (USDCAmount > USDTAmount && USDCAmount > 0){
            uint _amount = USDCAmount * 7 / 10;
            uint timeNow = block.timestamp;
            _mint(address(this), _amount);
            (uint minted,,) = Uniswap.addLiquidity(address(this), USDCAddress, _amount, _amount*(10**10), _amount, _amount*(10**10), address(this), timeNow + 120);
            _burn(address(this), (_amount - minted));
            USDCAmount -= (_amount - minted);
        }
        if(USDTAmount > USDCAmount && USDTAmount > 0){
            uint _amount = USDTAmount * 7 / 10;
            uint timeNow = block.timestamp;
            _mint(address(this), _amount);
            (uint minted,,) = Uniswap.addLiquidity(address(this), USDTAddress, _amount, _amount, _amount, _amount, address(this), timeNow + 120);
            _burn(address(this), (_amount - minted));
            USDTAmount -= (_amount - minted);
        }
    }
    
    function swapWBTCandProfit(uint256 _amount) public{
        require(_amount > 0, "Not enough amount of tokens");
        uint timeNow = block.timestamp;
        address[] memory swapPath = new address[](2);
        swapPath[0] = WBTCAddress;
        swapPath[1] = USDCAddress;
        uint price = (9882);
        uint[] memory result = Uniswap.swapExactTokensForTokens(_amount, (_amount * price * 90 / 100), swapPath, address(this), timeNow + 120);
        ProfitSpread.depositUSDCProfit(result[1]);
    }
    
    function swapLINKandProfit(uint256 _amount) public{
        require(_amount > 0, "Not enough amount of tokens");
        uint timeNow = block.timestamp;
        address[] memory swapPath = new address[](2);
        swapPath[0] = LINKAddress;
        swapPath[1] = USDTAddress;
        uint price = getLINKPrice();
        uint[] memory result = Uniswap.swapExactTokensForTokens(_amount, (_amount * (price / 100) * 90 / 100), swapPath, address(this), timeNow + 120);
        ProfitSpread.depositUSDTProfit(result[1]);
    }
    
    function swapWETHandProfit(uint256 _amount) public{
        require(_amount > 0, "Not enough amount of tokens");
        uint timeNow = block.timestamp;
        address[] memory swapPath = new address[](2);
        swapPath[0] = WETHAddress;
        swapPath[1] = USDTAddress;
        uint price = getWETHPrice();
        uint[] memory result = Uniswap.swapExactTokensForTokens(_amount, (_amount * price * 90 / 100), swapPath, address(this), timeNow + 120);
        ProfitSpread.depositUSDTProfit(result[1]);
    }
}

interface ShareProfitInterface{
    function depositUSDTProfit(uint256 _amount) external;
    function depositUSDCProfit(uint256 _amount) external;
}

contract simurgStable is profitContract, liquidityAddContract{
    
    uint public profitReceiverPercentage;
    uint public redeemTax;
    uint public referralPercentage;
    
    WETHERC20 WBTC = WETHERC20(WBTCAddress);
    WETHERC20 USDT = WETHERC20(USDTAddress);
    WETHERC20 LINK = WETHERC20(LINKAddress);
    WETHERC20 WETH = WETHERC20(WETHAddress);
    WETHERC20 USDC = WETHERC20(USDCAddress);
    
    /*
    WETHERC20 UNI = WETHERC20(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    WETHERC20 MATIC = WETHERC20(0x1343A33d5510e95B87166433BCDDd5DbEe8B4D8A);
    */
    
    constructor() ERC20("Simurg Stable Dollar", "SSD12"){
        redeemTax = 50;
        referralPercentage = 20;
        profitReceiverPercentage = 15;
    }
    
    function approveThem() public {
        WBTC.approve(UNISWAP_R_V2, 9999999**11);
        WETH.approve(UNISWAP_R_V2, 9999999**11);
        USDT.approve(UNISWAP_R_V2, 9999999**11);
        USDC.approve(UNISWAP_R_V2, 9999999**11);
        this.approve(UNISWAP_R_V2, 9999999**11);
    }
     
    function mintNewStableWithWETH(uint _amount, address _referral) public {
        require(_amount > 0, "You need to sell at least some tokens");
        uint256 allowance = WETH.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        uint256 price = getWETHPrice();
        WETH.transferFrom(msg.sender, address(this), (_amount*(10000 - referralPercentage)/10000));
        WETH.transferFrom(msg.sender, _referral, _amount*(referralPercentage)/10000);
        _mint(msg.sender, price*_amount);
        WETHAmount += _amount * (redeemTax - profitReceiverPercentage - referralPercentage)/10000;
    }
    
    function mintNewStableWithWBTC(uint _amount, address _referral) public {
        require(_amount > 0, "You need to sell at least some tokens");
        uint256 allowance = WBTC.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        uint256 price = getWBTCPrice() * 10**10;
        WBTC.transferFrom(msg.sender, address(this), (_amount*(10000 - referralPercentage)/10000));
        WBTC.transferFrom(msg.sender, _referral, _amount*(referralPercentage)/10000);
        _mint(msg.sender, price*_amount);
        WBTCAmount += _amount * (redeemTax - profitReceiverPercentage - referralPercentage)/10000;
    }
    
    function mintNewStableWithUSDT(uint _amount, address _referral) public {
        require(_amount > 0, "You need to sell at least some tokens");
        USDT.transferFrom(msg.sender, address(this), (_amount*(10000 - referralPercentage)/10000));
        USDT.transferFrom(msg.sender, _referral, _amount*(referralPercentage)/10000);
        _mint(msg.sender, _amount);
        USDTAmount += _amount * (redeemTax - profitReceiverPercentage - referralPercentage)/10000;
    }
    
    function mintNewStableWithUSDC(uint _amount, address _referral) public {
        require(_amount > 0, "You need to sell at least some tokens");
        uint256 allowance = USDC.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        USDC.transferFrom(msg.sender, address(this), (_amount*(10000 - referralPercentage)/10000));
        USDC.transferFrom(msg.sender, _referral, _amount*(referralPercentage)/10000);
        _mint(msg.sender,  _amount);
        USDCAmount += _amount * (redeemTax - profitReceiverPercentage - referralPercentage)/10000;
    }
    
    function mintNewStableWithLINK(uint _amount, address _referral) public {
        require(_amount > 0, "You need to sell at least some tokens");
        uint256 allowance = LINK.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        uint256 price = getLINKPrice();
        LINK.transferFrom(msg.sender, address(this), (_amount*(10000 - referralPercentage)/10000));
        LINK.transferFrom(msg.sender, _referral, _amount*(referralPercentage)/10000);
        _mint(msg.sender, price * _amount / 100);
        LINKAmount += _amount * (redeemTax - profitReceiverPercentage - referralPercentage)/10000;
    }
    
    function redeemCollateralWETH(uint _amount) public {
        require(_amount > 0, "You need to sell at least some tokens");
        uint256 allowance = allowance(msg.sender, address(this));
        require(allowance >= _amount, "Request exceeding allowance!");
        uint256 price = getWETHPrice();
        _burn(msg.sender, _amount);
        WETH.transfer(msg.sender, (_amount / price * (10000 - redeemTax)/10000));
        swapWETHandProfit(_amount / price * (profitReceiverPercentage)/10000);
        swapWETH();
    }
    
    function redeemCollateralWBTC(uint _amount) public {
        require(_amount > 0, "You need to sell at least some tokens");
        uint256 allowance = allowance(msg.sender, address(this));
        require(allowance >= _amount, "Request exceeding allowance!");
        uint256 price = getWBTCPrice();
        _burn(msg.sender, _amount);
        WBTC.transfer(msg.sender, (_amount / price * (10000 - redeemTax)/10000 / (10**10)));
        swapWBTCandProfit(_amount / price * (profitReceiverPercentage)/10000 / (10**10));
        swapWBTC();
    }
    
    function redeemCollateralUSDT(uint _amount) public {
        require(_amount > 0, "You need to sell at least some tokens");
        uint256 allowance = allowance(msg.sender, address(this));
        require(allowance >= _amount, "Request exceeding allowance!");
        _burn(msg.sender, _amount);
        USDT.transfer(msg.sender, (_amount * (10000 - redeemTax)/10000));
        ProfitSpread.depositUSDTProfit((_amount * (profitReceiverPercentage)/10000));
        addLiquidityStable();
    }
    
    function redeemCollateralUSDC(uint _amount) public {
        require(_amount > 0, "You need to sell at least some tokens");
        uint256 allowance = allowance(msg.sender, address(this));
        require(allowance >= _amount, "Request exceeding allowance!");
        _burn(msg.sender, _amount);
        USDC.transfer(msg.sender, (_amount * (10000 - redeemTax)/10000));
        ProfitSpread.depositUSDCProfit((_amount * (profitReceiverPercentage)/10000));
        addLiquidityStable();
    }
    
    function redeemCollateralLINK(uint _amount) public {
        require(_amount > 0, "You need to sell at least some tokens");
        uint256 allowance = allowance(msg.sender, address(this));
        require(allowance >= _amount, "Request exceeding allowance!");
        uint256 price = getLINKPrice();
        _burn(msg.sender, _amount);
        LINK.transfer(msg.sender, (_amount / price * ((10000 - redeemTax)/10000) / 100));
        swapLINKandProfit((_amount / price * (profitReceiverPercentage)/10000));
        swapLINK();
    }
    
    function changePercentage(uint _choice ,uint _percentage) public isOwner{
        if (_choice == 0){
            referralPercentage = _percentage;
        }else if(_choice == 1){
            profitReceiverPercentage = _percentage;
        }else if (_choice == 2){
            redeemTax = _percentage;
        }
    }
    
}