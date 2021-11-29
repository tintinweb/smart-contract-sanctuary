/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

/**
                                                                                                                        
                                                                                                                        
                                                                             `!'                                        
                                                                          _*YkwV*'                                      
                                                                      `!xomUIzwVcT^.                                    
                                                                   _*c55G3KUIzwVcl}Y*.                                  
                                                                !LG6OdZ5G3KUIzwVcu}Yix<'                                
                                                            -*kE$0E6OdZ5G3KUIzwVcu}Yixx*.                               
                                                         :YbQQ8g$0E6OdZ5G3KUIzwVcl}L*:`                                 
                                                     `~uEQBBQQ8g$0E6OdZ5G3KUIzwVL^_`                                    
                                                  -rXDg8QQBBQQ8g$0E6OdZ5G3mUoL;-                                        
                                               "ve9E0$g8QQBBQQ8g$0E6OdZ5G3Kx-                                           
                                           -^uHZdO9E0$g8QQBBQQ8g$0E6OdZ5G3KUjx!`                                        
                                        _*cKPGMZdO9E0$g8QQBBQQ8g$0E6OdZ5G3KUXzwV?:`                                     
                                    `!rVzIeKPGMZdO9E0$g8QQBBQQ8g$0E6OdZ5G3KUIzwVcr.                                     
                                 .!vuVVwzIeKPGMZdO9E0$g8QQBBQQ8g$0E6OdZ5G3KUIzwVx:'                                     
                             `_=|L}TuVVwzIeKPGMZdO9E0$g8QQBBQQ8g$0E6OdZ5G3KUIzwVcu}x^"'                                 
                             .!rxi}TuVVwzIeKPGMZdO9E0$g8QQBBQQ8g$0E6OdZ5G3KUIzwVcl}}v<,`                                
                                `:r}uVVwzIeKPGMZdO9E0$g8QQBBQQ8g$0E6OdZ5G3KUIzwV}*:'                                    
                                   `"r}wzIeKPGMZdO9E0$g8QQBBQQ8g$0E6OdZ5G3KUIzwV}!                                      
                                       -^}sKPGMZdO9E0$g8QQBBQQ8g$0E6OdZ5G3KUXzwVT*-                                     
                                          '~Y3MZdO9E0$g8QQBBQQ8g$0E6OdZ5G3mUXVr,                                        
                                             `:veO9E0$g8QQBBQQ8g$0E6OdZ5G3mx"                                           
                                                 _)XD$g8QQBBQQ8g$0E6OdZ5G3KI}<-                                         
                                                    `!YZQQBBQQ8g$0E6OdZ5G3KUXzwur:`                                     
                                                        _vqQQQ8g$0E6OdZ5G3KUIzwVcu}(!.                                  
                                                           '*V6g$0E6OdZ5G3KUIzwVcu}Yix)='                               
                                                               :xmR6OdZ5G3KUIzwVcu}Yix),                                
                                                                  .^}GZ5G3KUIzwVcu}Yv:                                  
                                                                      :?w3KUXzwVcuv:                                    
                                                                         -<LkzwVx"                                      
                                                                            `"*:                                        
                                                                                                                        
                                                                                                                        
                                                                                                                        
                                                                                                                        
                                                                                                                        
          .^v--?>'    `vxx`:xxxxxxr   -xxxxxxxxxx,       .xx*         vx~         ^xx:`xxxxxxx'  `\x~      rx*          
        '[email protected]@@*(@@@Z.  :#@#,[email protected]@@@@@Q   )##########}      `[email protected]@@z        @@0         [email protected]@j,@@@@@@@~  ,@@0      #@B          
        [email protected]@L   `[email protected]@M       [email protected]@~                         [email protected]@[email protected]@x       @@0             ,@@M       [email protected]@6      #@B          
        [email protected]@8Mwx^:.`       [email protected]@=       :zzzzzzzzz*      [email protected]@V`[email protected]@>      @@0             ,@@q       `[email protected]@B          
          [email protected]@@8r       [email protected]@=       ^QQQQQQQQQV     [email protected]@M  ,[email protected]#,     @@0             ,@@q       ,@@@[email protected]@B          
       `0BE`   `:[email protected]@`      [email protected]@=                      `gQb`   "#@B'    @@0             ,@@q       ,@@0      #@B          
        [email protected]@#Z::[email protected]@d       [email protected]@=       !ZZZZZZZZZZ^  [email protected]@$    @@0 5ddddj      ,@@q       ,@@0      #@B          
         .xa6=>DZy~        v0E_       =dddddddddd*  wddddddddddddd!   GZ} GZZZZz      .E0i       '5dT      mdk          
                                                                                                                        
                                                                                                                        
                                                                                                                        
 Telegram: https://t.me/StealthTokenOfficial
 Website: https://StealthToken.io
 Stealth
 The Home of Dynamic Stealth Tokenomics
 Making Crypto Great Again - As One
 Contract Creator Address: 0x68739D3CEFEb50d84838B3393535675cbf59E75A
 Multi-Sig Wallet Address for Eth: 0x852a8cb5D5e09133EDa0713C1A475A5B7dE80226
*/

pragma solidity ^0.8.6;
// SPDX-License-Identifier: UNLICENSED

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/* @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    address payable private _owner;
    address payable private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        _owner = payable(address(0));
    }

    function transferOwnership(address payable newOwner)
        public
        virtual
        onlyOwner
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = payable(address(0));
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(
            block.timestamp > _lockTime,
            "Contract is locked until defined days"
        );
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _previousOwner = payable(address(0));
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract Stealth is Context, IERC20, Ownable {
    using SafeMath for uint256;
    // If you are reading this then welcome - this is where the work happens.
    // StealthStandard Check
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _firstBuy;
    mapping (address => uint256) private _lastBuy;
    mapping (address => uint256) private _lastSell;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _hasTraded;
    mapping (address => bool) private bots;
    mapping (address => uint) private cooldown;
    uint256 private constant _tTotal = 1000000000000 * 10**18;
    uint256 private _tradingStartTimestamp;
    uint256 public sellCoolDownTime = 60 seconds;
    uint256 private minTokensToSell = _tTotal.div(100000);
    
    address payable private _stealthMultiSigWallet;
    
    string private constant _name = "Stealth Standard";
    string private constant _symbol = "$STEALTH";
    uint8 private constant _decimals = 18;
    
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    bool private tradingOpen = false;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private antiBotEnabled = false;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    constructor () {
        _stealthMultiSigWallet = payable(0x852a8cb5D5e09133EDa0713C1A475A5B7dE80226);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_stealthMultiSigWallet] = true;
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
        return _balances[account];
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(balanceOf(from) >= amount,"Not enough balance for tx");


        // Check if we are buying or selling, or simply transferring
        //if (to == uniswapV2Pair && from != address(uniswapV2Router) && from != owner() && from != address(this) && ! _isExcludedFromFee[from]) {
        if ((to == uniswapV2Pair) && ! _isExcludedFromFee[from]) {
            // Selling to uniswapV2Pair:

            // ensure trading is open
            require(tradingOpen,"trading is not yet open");

            // Block known bots from selling - If you think this was a mistake please contact the Stealth Team
            require(!bots[from], "Stealth is a Bot Free Zone");

            // anti bot code - checks for buys and sells in the same block or within the sellCoolDownTime
            if  (antiBotEnabled) {
                uint256 lastBuy = _lastBuy[from];
                require(block.timestamp > lastBuy, "Sorry - no FrontRunning allowed right now");
                require(cooldown[from] < block.timestamp);
                cooldown[from] = block.timestamp + sellCoolDownTime;
            }

            // Has Seller made a trade before? If not set to current block timestamp
            // We check this again on a sell to make sure they didn't transfer to a new wallet
            if (!_hasTraded[from]){
                _firstBuy[from] = block.timestamp;
                _hasTraded[from] = true;
            }

            if (swapEnabled) {
                // handle sell of tokens in contract for Eth
                uint256 contractTokenBalance = balanceOf(address(this));
                if (contractTokenBalance >= minTokensToSell) {
                    if (!inSwap) {
                        swapTokensForEth(contractTokenBalance);
                        uint256 contractETHBalance = address(this).balance;
                        if(contractETHBalance > 0) {
                        sendETHToWallet(address(this).balance);
                        }
                    }
                }
            }
            
            // Check to see if just taking profits or selling over 5%
            bool justTakingProfits = _justTakingProfits(amount, from);
            uint256 numHours = _getHours(_lastSell[from], block.timestamp);
            uint256 numDays = (numHours / 24);
            if (justTakingProfits) {
                // just taking profits but need to make sure its been more than 7 days since last sell if so
                if (numDays < 7) {
                    _firstBuy[from] = block.timestamp;
                    _lastBuy[from] = block.timestamp;
                }
            } else {
                if (numDays < 84) {
                // sold over 5% so we reset the last buy to be now
                _firstBuy[from] = block.timestamp;
                _lastBuy[from] = block.timestamp;
                }
            }

            // Record last sell timestamp
            _lastSell[from] = block.timestamp;

            // Transfer with taxes
            _tokenTransferTaxed(from,to,amount);

        //} else if (from == uniswapV2Pair && to != address(uniswapV2Router) && to != owner() && to != address(this)) {
        } else if ((from == uniswapV2Pair) && ! _isExcludedFromFee[to]) {
            // Buying from uniswapV2Pair:

            // ensure trading is open
            require(tradingOpen,"trading is not yet open");

            // Has buyer made a trade before? If not set to current block timestamp
            if (!_hasTraded[to]){
                _firstBuy[to] = block.timestamp;
                _hasTraded[to] = true;
            }

            // snapshot the last buy timestamp
            _lastBuy[to] = block.timestamp;

            // Simple Transfer with no taxes 
            _transferFree(from, to, amount);
        } else {
            // Other transfer

            // Block known bots from selling - If you think this was a mistake please contact the Stealth Team
            require(!bots[from] && !bots[to], "Stealth is a Bot Free Zone");

            // Handle the case of wallet to wallet transfer
            _firstBuy[to] = block.timestamp;
            _hasTraded[to] = true;

            // Simple Transfer with no taxes
            _transferFree(from, to, amount);
        }

    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    // If we are doing a tax free Transfer that happens here after _transfer:
    function _transferFree(address sender, address recipient, uint256 tAmount) private {
        _balances[sender] = _balances[sender].sub(tAmount);
        _balances[recipient] = _balances[recipient].add(tAmount); 
        emit Transfer(sender, recipient, tAmount);
    }
        
    // If we are doing a taxed Transfer that happens here after _transfer:
    function _tokenTransferTaxed(address sender, address recipient, uint256 amount) private {
        _transferTaxed(sender, recipient, amount);
    }

    function _transferTaxed(address sender, address recipient, uint256 tAmount) private {

        // Calculate the taxed token amount
        uint256 tTeam = _getTaxedValue(tAmount, sender);
        uint256 transferAmount = tAmount - tTeam;

        _balances[sender] = _balances[sender].sub(tAmount);
        _balances[recipient] = _balances[recipient].add(transferAmount); 
        _takeTeam(tTeam);
        emit Transfer(sender, recipient, transferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        _balances[address(this)] = _balances[address(this)].add(tTeam);
    }

    // Check to see if the sell amount is greater than 5% of tokens in a 7 day period
    function _justTakingProfits(uint256 sellAmount, address account) private view returns(bool) {
        // Basic cheak to see if we are selling more than 5% - if so return false
        if ((sellAmount * 20) > _balances[account]) {
            return false;
        } else {
            return true;
        }
    }

    // Calculate the number of taxed tokens for a transaction
    function _getTaxedValue(uint256 transTokens, address account) private view returns(uint256){
        uint256 taxRate = _getTaxRate(account);
        if (taxRate == 0) {
            return 0;
        } else {
            uint256 numerator = (transTokens * (10000 - (100 * taxRate)));
            return (((transTokens * 10000) - numerator) / 10000);
        }
    }

    // Calculate the current tax rate.
	function _getTaxRate(address account) private view returns(uint256) {
        uint256 numHours = _getHours(_tradingStartTimestamp, block.timestamp);

        if (numHours <= 24){
            // 20% Sell Tax first 24 Hours
            return 20;
        } else if (numHours <= 48){
            // 16% Sell Tax second 24 Hours
            return 16;
        } else {
            // 12% Sell Tax starting rate
            numHours = _getHours(_firstBuy[account], block.timestamp);
            uint256 numDays = (numHours / 24);
            if (numDays >= 84 ){
                //12 x 7 = 84 = tax free!
                return 0;
            } else {
                uint256 numWeeks = (numDays / 7);
                return (12 - numWeeks);
            }
        }
    }

    // Calculate the number of hours that have passed between endDate and startDate:
    function _getHours(uint256 startDate, uint256 endDate) private pure returns(uint256){
        return ((endDate - startDate) / 60 / 60);
    }
    
    receive() external payable {}
    
    function manualswap() external {
        require(_msgSender() == _stealthMultiSigWallet || _msgSender() == address(this) || _msgSender() == owner());
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external {
        require(_msgSender() == _stealthMultiSigWallet || _msgSender() == address(this) || _msgSender() == owner());
        uint256 contractETHBalance = address(this).balance;
        sendETHToWallet(contractETHBalance);
    }

    function airdrop(address[] memory _user, uint256[] memory _amount) external onlyOwner {
        uint256 len = _user.length;
        require(len == _amount.length);
        for (uint256 i = 0; i < len; i++) {
            _balances[_msgSender()] = _balances[_msgSender()].sub(_amount[i], "ERC20: transfer amount exceeds balance");
            _balances[_user[i]] = _balances[_user[i]].add(_amount[i]);
            emit Transfer(_msgSender(), _user[i], _amount[i]);
        }
    }
    
    function setMultipleBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function setBot(address isbot) public onlyOwner {
        bots[isbot] = true;
    }
    
    function deleteBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    function isBlacklisted(address isbot) public view returns(bool) {
        return bots[isbot];
    }

    function setAntiBotMode(bool onoff) external onlyOwner() {
        antiBotEnabled = onoff;
    }

    function isAntiBotEnabled() public view returns(bool) {
        return antiBotEnabled;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setSellCoolDownTime(uint256 _newTime) public onlyOwner {
        sellCoolDownTime = _newTime;
    }

    function updateRouter(IUniswapV2Router02 newRouter, address newPair) external onlyOwner {
        uniswapV2Router = newRouter;
        uniswapV2Pair = newPair;
    }
            
    function sendETHToWallet(uint256 amount) private {
        _stealthMultiSigWallet.transfer(amount);
    }
    
    function startTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        antiBotEnabled = true;
        swapEnabled = true;
        tradingOpen = true;
        _tradingStartTimestamp = block.timestamp;
    }

    function setSwapEnabledMode(bool swap) external onlyOwner {
        swapEnabled = swap;
    }

    function isTradingOpen() public view returns(bool) {
        return tradingOpen;
    }


}