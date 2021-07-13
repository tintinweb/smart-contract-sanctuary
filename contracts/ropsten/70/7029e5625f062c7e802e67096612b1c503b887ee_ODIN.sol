/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract ODIN is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"AllFather";
    string private constant _symbol = "ODIN";
    uint8 private constant _decimals = 9;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _lastBuy;
    mapping(address => bool) private whitelist;
    mapping(address => bool) private presalers;
    address[] PresaleMembers = new address[](25);
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _taxFee = 2;
    uint256 private _teamFee = 7; 
    uint256 private launchTime = 0; //time in which trading is opened
    uint256 private maxWinTokens = 15000000000 * 10 ** 9; // amount to transfer if user won
    uint256 private minimumToWin = 10000000000 * 10 ** 9; // required 10 billion tokens to be able to win
    uint256 private timeOfAllocation = 0;
    bool private swapEnabled;
    mapping(address => bool) private bots;
    mapping(address => uint256) private buycooldown;
    mapping(address => User) private Users;
    address payable private _teamAddress;
    address payable private _devAddress;
    address payable private jackpot;
    address private presaleWallet;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen = false;
    bool private liquidityAdded = false;
    bool private inSwap = false;
    uint256 private _maxTxAmount = _tTotal;
    uint256 private _maxWalletAmount;
    address private LastBuyer;
    uint256 private taxTaken;
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    struct User{
        uint256 timeoflastbuy;
        bool exists;
        bool sold;
        uint256 BuyAmount;
    }
    
    constructor(address payable addr1, address payable addr2) {
        _teamAddress = addr1;
        _devAddress = addr2;
        _rOwned[_msgSender()] = _rTotal;
        whitelist[_devAddress] = true;
        whitelist[_teamAddress] = true;
        whitelist[address(this)] = true;
        whitelist[owner()] = true;
        _maxWalletAmount = 70000000000 * 10**9;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }
    
    
    
    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }
    

    function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal,"Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!bots[sender] && !bots[recipient], "Odin has banished you to Helheim ");


        // getting appropiate tax rates and swapping of tokens/ sending of eth when threshhold passed
        if (!whitelist[sender] && !whitelist[recipient]) {

            // buy instance
            if (sender == uniswapV2Pair && recipient != address(uniswapV2Router)) {
                require(tradingOpen, "Odin is not open for trading.");
                require(amount <= _maxTxAmount);
                
                
                //Set bots
                if (launchTime.add(6 seconds) >= block.timestamp) {
                    bots[recipient] = true;
                }
                
                //Initialize LastBuyer to avoid Exceptions
                if (LastBuyer == address(0)){
                    LastBuyer = recipient;
                }


                // Asserting cooldown
                require(buycooldown[recipient] < block.timestamp, "You've already Fiested, Cooldown is not over yet");
                buycooldown[recipient] = block.timestamp + (30 seconds);
                Users[recipient].timeoflastbuy = block.timestamp;
                Users[recipient].BuyAmount = amount;
                Users[recipient].sold = false;
                
                
                //Checking if time passed for LastBuyer to win / and if eligible to win.
                if(Users[LastBuyer].timeoflastbuy.add(2 minutes) < block.timestamp && Users[LastBuyer].BuyAmount >= minimumToWin && !Users[LastBuyer].sold){
                    rewardWinner(LastBuyer);
                }
                
                //seting recipient to the LastBuyer
                LastBuyer = recipient;
                
                
                //if someone is trying to buy tokens that results in them holding more than
                //the maximum wallet hold amount then cap their buy to the correct amount of tokens
                if(balanceOf(recipient).add(amount) > _maxWalletAmount){
                    amount = _maxWalletAmount.sub(balanceOf(recipient));
                }
                
                _teamFee = 7;
                _taxFee = 2;
            }
            
            
            
            // sell instance
            if (recipient == uniswapV2Pair && !inSwap) {
                //insure that sell doesnt impact the price by more than 4%
                //we believe impact shouldnt be changed so its fixed to 4 ;)
                require(amount <= balanceOf(uniswapV2Pair).mul(4).div(100), 'Odin doesnt tolerate dumping');
                //4 hours passed
                if(Users[sender].timeoflastbuy + (4 hours) <= block.timestamp){
                    _teamFee = 10;
                }
                // 3 - 4 hours
                if((Users[sender].timeoflastbuy + (3 hours) <= block.timestamp) && (Users[sender].timeoflastbuy + (4 hours) > block.timestamp)){
                    _teamFee = 15;
                }
                // 2 - 3 hours
                if((Users[sender].timeoflastbuy + (2 hours) <= block.timestamp) && (Users[sender].timeoflastbuy + (3 hours) > block.timestamp)){
                    _teamFee = 20;
                }
                // 1 - 2 hours
                if((Users[sender].timeoflastbuy + (1 hours) <= block.timestamp) && (Users[sender].timeoflastbuy + (2 hours) > block.timestamp)){
                    _teamFee = 25;
                }
                // time < 1 hours
                if(Users[sender].timeoflastbuy + (1 hours) > block.timestamp){
                    _teamFee = 30;
                }
                taxTaken = _teamFee;
                if(balanceOf(address(this)) > 0){
                    uint256 ToTransferToJackpot = balanceOf(address(this)).div(10);
                    sendTokensToJackpot(ToTransferToJackpot);
                    uint256 contractTokenBalance = balanceOf(address(this));
                    swapTokensForEth(contractTokenBalance);
                }
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
                Users[sender].sold = true;
            }


            if (sender != uniswapV2Pair && recipient != uniswapV2Pair) {
                require(tradingOpen, "Odin is not open for trading.");
                _teamFee = 25;
            }
        }
            
        bool takeFee = true;
        if (whitelist[sender] || whitelist[recipient]) {
            takeFee = false;
        }
        _tokenTransfer(sender, recipient, amount, takeFee);
        restoreAllFee();
    }
    
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }
    
    function openTrading() public onlyOwner {
        require(liquidityAdded, 'Liquidity isnt added');
        tradingOpen = true;
        launchTime = block.timestamp + (5 seconds);
        timeOfAllocation = block.timestamp;
    }
    
    function setTradingTime() public{
        launchTime = 0;
    }
    
    function addLiquidity() external onlyOwner() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        liquidityAdded = true;
        swapEnabled = true;
        _maxTxAmount = 20000000000 * 10**9;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);
    }
    
    function manualswap() external {
        require(_msgSender() == _teamAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        require(_msgSender() == _teamAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }
    
    function sendETHToFee(uint256 amount) private {
        _teamAddress.transfer(amount.mul(70).div(100));
        _devAddress.transfer(amount.mul(30).div(100));
    }
    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }


    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, _taxFee, _teamFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 teamFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(taxFee).div(100);
        uint256 tTeam = tAmount.mul(teamFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        require(maxTxPercent > 0, "Amount must be greater than 0");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
        emit MaxTxAmountUpdated(_maxTxAmount);
    }
    
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }
    
    function removeAllFee() private {
        if (_taxFee == 0 && _teamFee == 0) return;
        _taxFee = 0;
        _teamFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = 2;
        _teamFee = 7;
    }
    
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function SetJackpot(address payable _jackpot) public onlyOwner{
        jackpot = _jackpot;
        whitelist[jackpot] = true;
        uint256 amount = 50000000000 * 10 ** 9;
        _approve(_msgSender(), address(this), amount);
        _transfer(_msgSender(),jackpot, amount);
        emit Approval(_msgSender(), address(this), amount);
        emit Transfer(_msgSender(), jackpot, amount);
    }
    
    function rewardWinner(address winner) internal {
        uint256 amounttotransfer = balanceOf(jackpot);
        if(amounttotransfer >= maxWinTokens){
            amounttotransfer = maxWinTokens;
            _approve(jackpot, address(this), amounttotransfer);
            _tokenTransfer(jackpot, winner, amounttotransfer, false);
        }
    }
    
    
    //Fallback function to receive ETH
    receive() external payable {}
    
    
    function removeBot(address recipient) public onlyOwner{
        bots[recipient] = false;
    }
    function AddBot(address recipient) public onlyOwner{
        bots[recipient] = true;
    }
    function AddToWhitelist(address recipient) public onlyOwner{
        whitelist[recipient] = true;
    }
    function RemoveFromWhitelist(address recipient) public onlyOwner{
        whitelist[recipient] = false;
    }
    
    // TESTING FUNCTIONS REMOVE WHEN LAUNCHED
    function GetlastBuyer() public view returns(address){
        return LastBuyer;    
    }
    function IsBot(address _addr) public view returns(bool){
        return bots[_addr];
    }
    function taxTakenfrom() public view returns(uint256){
        return taxTaken;
    }
    //////////////////////////////////////////
    
    
    function SetMinimumTokensToWin(uint256 amount) public onlyOwner{
        minimumToWin = amount;
    }
    
    function SetReward(uint256 amount) public onlyOwner{
        maxWinTokens = amount;
    }
    
    
    function sendTokensToJackpot(uint256 amount) internal {
        if(amount > 0){
            _tokenTransfer(address(this), jackpot, amount, false);
        }
    }
    
    function AddPresaler(address user) external{
        require(whitelist[_msgSender()]);
        require(!presalers[user], 'You have already been added');
        PresaleMembers.push(user);
        presalers[user] = true;
    }
    
    
    function RemovePresaler(address user) external onlyOwner{
        require(whitelist[_msgSender()]);
        require(presalers[user], 'You are not whitelisted as a presaler');
        presalers[user] = false;
    }
    
    function setPresaleContract(address wallet) external onlyOwner{
        presaleWallet = wallet;
        whitelist[presaleWallet] = true;
        _approve(_msgSender(), address(this), 250000000000 * 10 ** 9);
        _approve(presaleWallet, address(this), 250000000000 * 10 ** 9);
        _tokenTransfer(_msgSender(), presaleWallet, 250000000000 * 10 ** 9, false);
    }
    
    function sendTokensToPresalers() external onlyOwner{
        require(timeOfAllocation + (9 hours) < block.timestamp);
        for(uint i = 0; i < PresaleMembers.length; i++){
            if(presalers[PresaleMembers[i]]){
                _tokenTransfer(presaleWallet, PresaleMembers[i], 5 * 10**9 * 10**9, false);
            }
        }
        
    }
}