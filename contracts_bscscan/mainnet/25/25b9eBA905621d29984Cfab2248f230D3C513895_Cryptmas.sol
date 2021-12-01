/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

/**
 Telegram: https://t.me/Cryptmasss
 Website:  https://cryptmas.site
 Twitter:  https://twitter.com/cryptmas4u

                                                                --------------                                              ////////////////
  ------------       ----------     \           /     -------    ------------     //\\      //\\        //////////       //////////////////////
 /                  /          /     \         /     //     //        //          // \\    // \\        //      //       //////////////////////
 /                  /         /       \       /      //     //        //          //  \\  //  \\        //      //       ///////
 /                  /        /         \     /       //     //        //          //   \\//   \\        //////////         ///////
 /                  /--------           \   /        ////////         //          //          \\        //      //           ////////
 /                  /      \             \ /         //               //          //          \\        //      //              ///////
 /                  /       \             /          //               //          //          \\        //      //                 ////////
 /                  /        \           /           //               //          //          \\        //      //                    ///////
 /                  /         \         /            //               //          //          \\        //      //                      //////
   -----------      /          \       /             //               //          //          \\        //      //                    /////////
                                                                                                                                  ////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Merry Cryptmas xox 

  Total Tokens: 1,000,000,000
  Max Wallet:   2% 20,000,000
  Tax: 12% 
*/

/** 
 * The contracts crafted by Ultraman Contracts are not liable for the actions of the acting dev (client).
 * PLEASE MAKE SURE LIQUIDITY IS LOCKED BEFORE BUYING
 * The contract created below is safu as the following is true:
 * There is not a pause contract button.
 * You cannot disable sells.
 * If the dev chooses to renounce, there is no backdoor.
 * Sell taxes cannot be raised higher than 15%
 * All info pertaining to the contract will be listed above the disclaimer message. 
 * For further inquiry contact t.me/UltramanContracts
*/

// SPDX-License-Identifier: Unlicensed


pragma solidity ^0.8.4;

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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
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
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

contract Cryptmas is Context, IERC20, Ownable {
    
    using SafeMath for uint256;

    string private constant _name = "Cryptmas";
    string private constant _symbol = "CRYPTMAS";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000 * 1e6 * 1e9; //1,000,000,000
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    uint256 public tradingActiveBlock = 0; // 0 means trading is not active
    mapping(address => bool) public boughtEarly; // mapping to track addresses that buy within the first 2 blocks pay a 3x tax for 24 hours to sell
    uint256 public earlyBuyPenaltyEnd; // determines when snipers/bots can sell without extra penalty    
    
    //Buy Fee
    uint256 public _reflectionFeeOnBuy = 0;
    uint256 public _taxFeeOnBuy = 12;

    //Sell Fee
    uint256 public _reflectionFeeOnSell = 1;
    uint256 public _taxFeeOnSell = 11;
    
    //Original Fee
    uint256 private _previousReflectionFee = _reflectionFee;
    uint256 private _previousTaxFee = _taxFee;
    uint256 private _reflectionFee = _reflectionFeeOnSell;
    uint256 private _taxFee = _taxFeeOnSell;
    
    address payable public _devAddress = payable(0xEC3f9069cB7820592535B3eb8381EDCeee80F0EB); //dev
    address payable public _mktgAddress = payable(0xa5E9c574661519654C270D899836302116F48258); //Marketing
    address payable private _umAddress = payable(0xd124cAc27C54f65551172FcebEAEdD3f9722FE1F); //Ultraman Contracts
    address payable private _rewardsAddress = payable(0xbef58473097f0458CFc50574FF048569D00175A7); //Rewards
    
    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = true;
    
    uint256 public _maxTxAmount = 1000 * 1e6 * 1e9; //max transaction set to 100%
    uint256 public _maxWalletSize = 2100 * 1e4 * 1e9; //max wallet set to 2.1% 21,000,000
    uint256 public _swapTokensAtAmount = 1000 * 1e3 * 1e9; //amount of tokens to swap for bnb 0.1%

    //anit-sniper
    event BoughtEarly(address indexed sniper);
    event RemovedSniper(address indexed notsnipersupposedly);
    
    event ExcludeFromReflection(address excludedFromReflection);
    event IncludeInReflection(address includedFromReflection);

    event ExcludeFromFee(address excludedFromFee);
    event IncludeInFee(address includedFromFee);

    event UpdatedMktgAddress(address mktgAddress);
    event UpdatedDevAddress(address devAddress);
    event UpdatedRewardsAddress(address rewardsAddress);

    event SetFee(uint256 reflectionFeeOnBuy, uint256 reflectionFeeOnSell, uint256 taxFeeOnBuy, uint256 taxFeeOnSell);
    
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    constructor() {
        
        _rOwned[_msgSender()] = _rTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); //0x10ED43C718714eb63d5aA57B78B54704E256024E (BSC)
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_devAddress] = true;
        _isExcludedFromFee[_rewardsAddress] = true;
        _isExcludedFromFee[_mktgAddress] = true;
        _isExcludedFromFee[_umAddress] = true;
        
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

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function excludeFromFee(address account) internal {
        _isExcludedFromFee[account] = true;
        emit ExcludeFromFee(account);
    }

    function includeInFee(address account) internal {
        _isExcludedFromFee[account] = false;
        emit IncludeInFee(account);
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
    
    function removeAllFee() private {
        if (_reflectionFee == 0 && _taxFee == 0) return;
    
        _previousReflectionFee = _reflectionFee;
        _previousTaxFee = _taxFee;
        
        _reflectionFee = 0;
        _taxFee = 0;
    }

    function restoreAllFee() private {
        _reflectionFee = _previousReflectionFee;
        _taxFee = _previousTaxFee;
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

        if (from != owner() && to != owner()) {
            
            if (!tradingOpen) 
              
            if(to != uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(balanceOf(to) + amount < _maxWalletSize, "TOKEN: Balance exceeds wallet size!");
                require(amount <= _maxTxAmount, "TOKEN: Max Transaction Limit");
                
            }
            
            //anti-sniper
            if(from != owner() && to != uniswapV2Pair && block.number == tradingActiveBlock){
                    boughtEarly[to] = true;
                    emit BoughtEarly(to);
                }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= _swapTokensAtAmount;

            if(contractTokenBalance >= _maxTxAmount)
            {
                contractTokenBalance = _maxTxAmount;
            }
            
            if (canSwap && !inSwap && from != uniswapV2Pair && swapEnabled) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
        
        bool takeFee = true;

        //Transfer Tokens
        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (from != uniswapV2Pair && to != uniswapV2Pair)) {
            takeFee = false;
        } else {
            
            //Set Fee for Buys
            if(from == uniswapV2Pair && to != address(uniswapV2Router)) {
                _reflectionFee = _reflectionFeeOnBuy;
                _taxFee = _taxFeeOnBuy;
                
            }
    
            //Set Fee for Sells
            if (!_isExcludedFromFee[from]) {
                        require(amount <= _maxTxAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                }

            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _reflectionFee = _reflectionFeeOnSell;
                _taxFee = _taxFeeOnSell;
            // higher tax if bought in the same block as trading active for 72 hours (sniper protect)
            if(boughtEarly[from] && earlyBuyPenaltyEnd > block.timestamp){
                _taxFee = _taxFee * 3;
                }
            }
            
        }

        _tokenTransfer(from, to, amount, takeFee);
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

    function sendETHToFee(uint256 amount) private {
        _devAddress.transfer(amount.div(4));
        _mktgAddress.transfer(amount.div(4).mul(3));
    }

    function setTrading(bool _tradingOpen) private onlyOwner {
        tradingOpen = _tradingOpen;
        tradingActiveBlock = block.number;
        earlyBuyPenaltyEnd = block.timestamp + 72 hours;
    }

    function manualswap() external {
        require(_msgSender() == _devAddress || _msgSender() == _mktgAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        require(_msgSender() == _devAddress || _msgSender() == _mktgAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }  

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
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

    receive() external payable {}

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) =
            _getTValues(tAmount, _reflectionFee, _taxFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRValues(tAmount, tFee, tTeam, currentRate);
        
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 reflectionFee, uint256 taxFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(reflectionFee).div(100);
        uint256 tTeam = tAmount.mul(taxFee).div(100);
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
    
    function setFee(uint256 reflectionFeeOnBuy, uint256 reflectionFeeOnSell, uint256 taxFeeOnBuy, uint256 taxFeeOnSell) public onlyOwner() {
        _reflectionFeeOnBuy = reflectionFeeOnBuy;
        _taxFeeOnBuy = taxFeeOnBuy;
        
        _reflectionFeeOnSell = reflectionFeeOnSell;
        _taxFeeOnSell = taxFeeOnSell;
        
        require(_reflectionFeeOnBuy + _taxFeeOnBuy <= 15, "Must keep buy taxes below 15%"); //wont allow taxes to go above 15%
        require(_reflectionFeeOnSell + _taxFeeOnSell <= 15, "Must keep buy taxes below 15%"); //wont allow taxes to go above 15%
    }

    //Set minimum tokens required to swap.
    function setMinSwapTokensThreshold(uint256 swapTokensAtAmount) public onlyOwner {
        _swapTokensAtAmount = swapTokensAtAmount;
    }
    
    //Set max transaction
    function setMaxTxnAmount(uint256 maxTxAmount) public onlyOwner {
        _maxTxAmount = maxTxAmount;
    }
    
    //set max wallet
    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        _maxWalletSize = maxWalletSize;
    }
    
    //set exclude wallet from fees
    function setExcludedFromFee(address account, bool excluded) public onlyOwner {
            _isExcludedFromFee[account] = excluded;
    }
 
}