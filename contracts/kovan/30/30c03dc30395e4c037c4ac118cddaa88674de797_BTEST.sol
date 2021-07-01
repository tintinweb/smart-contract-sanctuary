/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

/*
 __      __                           ________                    __        __    __                         
|  \    /  \                         |        \                  |  \      |  \  |  \                        
 \$$\  /  $$______   __    __   ______\$$$$$$$$______    _______ | $$____  | $$\ | $$  ______   __   __   __ 
  \$$\/  $$/      \ |  \  |  \ /      \ | $$  /      \  /       \| $$    \ | $$$\| $$ /      \ |  \ |  \ |  \
   \$$  $$|  $$$$$$\| $$  | $$|  $$$$$$\| $$ |  $$$$$$\|  $$$$$$$| $$$$$$$\| $$$$\ $$|  $$$$$$\| $$ | $$ | $$
    \$$$$ | $$  | $$| $$  | $$| $$   \$$| $$ | $$    $$| $$      | $$  | $$| $$\$$ $$| $$  | $$| $$ | $$ | $$
    | $$  | $$__/ $$| $$__/ $$| $$      | $$ | $$$$$$$$| $$_____ | $$  | $$| $$ \$$$$| $$__/ $$| $$_/ $$_/ $$
    | $$   \$$    $$ \$$    $$| $$      | $$  \$$     \ \$$     \| $$  | $$| $$  \$$$ \$$    $$ \$$   $$   $$
     \$$    \$$$$$$   \$$$$$$  \$$       \$$   \$$$$$$$  \$$$$$$$ \$$   \$$ \$$   \$$  \$$$$$$   \$$$$$\$$$$ 
*//* SPDX-License-Identifier: Unlicensed */
pragma solidity ^0.8.6;

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
    event TeamMarket(address indexed from, address indexed to, uint256 value);
    event Charity(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, address indexed to, uint256 value);
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
//
contract Ownable is Context {
    address private _owner;
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
//
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
//
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
//
contract BTEST is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    string private constant _name = "BTEST";
    string private constant _symbol = "BTEST";
    uint8 private constant _decimals = 9;
    
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _isExcludedFromFee;
    mapping(address => bool) public _isExcludedFromReward;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _taxDistributeFee = 2;
    uint256 private _teamMarketFee = 2;
    // 0.5% fee will be calculated later, number 1 is set because variable cannot store floating point
    uint256 private _charityFee = 1;
    // 0.5% fee will be calculated later, number 1 is set because variable cannot store floating point
    uint256 private _burnFee = 1;
    
    mapping(address => bool) private bots;
    mapping(address => uint256) private buycooldown;
    mapping(address => uint256) private sellcooldown;
    mapping(address => uint256) private firstsell;
    mapping(address => uint256) private sellnumber;
    
// made public for transparency
    address payable public _teamMarketAddress;
    address payable public _charityAddress;
    address payable public _burnAddress = payable(0x000000000000000000000000000000000000dEaD);
    
    address public _routerAddress;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    
    
    bool private tradingOpen = false;
    bool private liquidityAdded = false;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;
    uint256 private _maxTxAmount = _tTotal;
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    constructor(address payable addr1, address payable addr2, address payable addr3) {
        _routerAddress = addr1;
        _teamMarketAddress = addr2;
        _charityAddress = addr3;
        _tOwned[_msgSender()] = _tTotal;
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromReward[owner()] = true;
        _isExcludedFromReward[address(this)] = true;
        _isExcludedFromReward[_teamMarketAddress] = true;
        _isExcludedFromReward[_charityAddress] = true;
        _isExcludedFromReward[_burnAddress] = true;
        _isExcludedFromReward[_routerAddress] = true;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_teamMarketAddress] = true;
        _isExcludedFromFee[_charityAddress] = true;
        _isExcludedFromFee[_burnAddress] = true;
        _isExcludedFromFee[_routerAddress] = true;
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
        if (_isExcludedFromReward[account]) return _tOwned[account];
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

    function setCooldownEnabled(bool onoff) external onlyOwner {
        cooldownEnabled = onoff;
    }

    // added
    function setExcludedFromFee(address account, bool isExcluded) external onlyOwner {
        _isExcludedFromFee[account] = isExcluded;
    }

    // added
    function setExcludedFromReward(address account, bool isExcluded) external onlyOwner {
        _isExcludedFromReward[account] = isExcluded;
    }


    function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal,"Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
    
    // added admin function to remove fees
    function setRemoveAllFee() onlyOwner external {
        if (_taxDistributeFee == 0 && _teamMarketFee == 0) return;
        _taxDistributeFee = 0;
        _teamMarketFee = 0;
        _charityFee = 0;
        _burnFee = 0;
    } 
    // added admin function to restore fees
    function setRestoreAllFee() onlyOwner external {
        _taxDistributeFee = 2;
        _teamMarketFee = 2;
        // 0.5% fee will be calculated later, number 1 is set because variable cannot store floating point
        _charityFee = 1;
        // 0.5% fee will be calculated later, number 1 is set because variable cannot store floating point
        _burnFee = 1;
    }
    
    function removeAllFee() private {
        if (_taxDistributeFee == 0 && _teamMarketFee == 0) return;
        _taxDistributeFee = 0;
        _teamMarketFee = 0;
        _charityFee = 0;
        _burnFee = 0;
    }

    function restoreAllFee() private {
        _taxDistributeFee = 2;
        _teamMarketFee = 2;
        // 0.5% fee will be calculated later, number 1 is set because variable cannot store floating point
        _charityFee = 1;
        // 0.5% fee will be calculated later, number 1 is set because variable cannot store floating point
        _burnFee = 1;
    }
    
    /**
    function setFee(uint256 multiplier) private {
        _taxDistributeFee = _taxDistributeFee * multiplier;
        if (multiplier > 1) {
            _teamMarketFee = 10;
        }
        
    }
    */

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
            if (cooldownEnabled) {
                if (from != address(this) && to != address(this) && from != address(uniswapV2Router) && to != address(uniswapV2Router)) {
                    require(_msgSender() == address(uniswapV2Router) || _msgSender() == uniswapV2Pair,"ERR: Uniswap only");
                }
            }
            require(!bots[from] && !bots[to]);
            // buy order
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to] && cooldownEnabled) {
                require(tradingOpen, "Trading Closed!");
                require(amount <= _maxTxAmount, "Transaction to big!");
                require(buycooldown[to] < block.timestamp, "Wait for Cool Down!");
                buycooldown[to] = block.timestamp + (30 seconds);
            }
            // sell order
            //uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && from != uniswapV2Pair && to == address(uniswapV2Router) && swapEnabled) {
                // slippage control
                require(amount <= balanceOf(uniswapV2Pair).mul(3).div(100) && amount <= _maxTxAmount, "Transaction to big!");
                require(sellcooldown[from] < block.timestamp, "Wait for Cool Down!");
                if(firstsell[from] + (1 days) < block.timestamp){
                    sellnumber[from] = 0;
                }
                // sell off control
                if (sellnumber[from] == 0) {
                    uint256 tfeeWhole = 25;
                    // get float point result of 2.5% for fee
                    _taxDistributeFee = tfeeWhole.div(10);
                    sellnumber[from]++;
                    firstsell[from] = block.timestamp;
                    sellcooldown[from] = block.timestamp + (1 hours);
                }
                else if (sellnumber[from] == 1) {
                    uint256 tfeeWhole = 55;
                    // get float point result of 5.5% for fee
                    _taxDistributeFee = tfeeWhole.div(10);
                    sellnumber[from]++;
                    sellcooldown[from] = block.timestamp + (2 hours);
                }
                else if (sellnumber[from] == 2) {
                    uint256 tfeeWhole = 165;
                    // get float point result of 16.5% for fee
                    _taxDistributeFee = tfeeWhole.div(10);
                    sellnumber[from]++;
                    sellcooldown[from] = block.timestamp + (6 hours);
                }
                else if (sellnumber[from] == 3) {
                    // get float point result of 23.5% for fee
                    uint256 tfeeWhole = 235;
                    _taxDistributeFee = tfeeWhole.div(10);
                    sellnumber[from]++;
                    sellcooldown[from] = firstsell[from] + (1 days);
                }
                /**
                //to approve & send to swap 
                swapTokensForBNB(contractTokenBalance);
                //current bal after swap
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                   sendBNBToFee(address(this).balance);
                }
                //setFee(sellnumber[from]);
                */
            }
        }
        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
        restoreAllFee();
    }
// swap contact token for BNB
    function swapTokensForBNB(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

// move BNB to TeamMarket Address & Charity Address
    function sendBNBToFee(uint256 amount) private {
        _teamMarketAddress.transfer(amount.div(2));
        _charityAddress.transfer(amount.div(2));
    }
    
    function openTrading() public onlyOwner {
        require(liquidityAdded);
        tradingOpen = true;
    }

    function addLiquidity() external onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_routerAddress);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        cooldownEnabled = true;
        liquidityAdded = true;
        _maxTxAmount = 3000000000 * 10**9;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);
    }

// swap contract tokens for bnb
    function manualswap() onlyOwner external {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForBNB(contractBalance);
    }
// send contract funds to charity, marketing, & team wallets
    function manualsend() onlyOwner external {
        uint256 contractETHBalance = address(this).balance;
        sendBNBToFee(contractETHBalance);
    }
    
// actions 
    function _reflectFee(uint256 rDistributeFee, uint256 tDistributeFee) private {
        _rTotal = _rTotal.sub(rDistributeFee);
        _tFeeTotal = _tFeeTotal.add(tDistributeFee);
    }
    
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
    
   /**
    function _getRValues(uint256 tAmount, uint256 tDistributeFee, uint256 tTeamMarket, uint256 tCharity, uint256 tBurn) private view returns (uint256, uint256, uint256) {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rDistributeFee = tDistributeFee.mul(currentRate);
        uint256 rTeamMarket = tTeamMarket.mul(currentRate);
        uint256 rCharity = tCharity.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rDistributeFee).sub(rTeamMarket).sub(rCharity).sub(rBurn);
        return (rAmount, rTransferAmount, rDistributeFee);
    }
    
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 tDistributeFee = tAmount.mul(_taxDistributeFee).div(100);
        uint256 tTeamMarket = tAmount.mul(_teamMarketFee).div(100);
        uint256 tCharity = tAmount.mul(_charityFee).div(100);
        uint256 tBurn = tAmount.mul(_burnFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tDistributeFee).sub(tTeamMarket).sub(tCharity).sub(tBurn);
        return (tTransferAmount, tDistributeFee, tTeamMarket, tCharity, tBurn);
    }
    
    
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        //(uint256 tTransferAmount, uint256 tDistributeFee, uint256 tTeamMarket, uint256 tCharity, uint256 tBurn) = _getTValues(tAmount);
        //(uint256 rAmount, uint256 rTransferAmount, uint256 rDistributeFee) = _getRValues(tAmount, tDistributeFee, tTeamMarket, tCharity, tBurn);
        // moved two functions above to reduce stack
        // _getTValues
        uint256 tDistributeFee = tAmount.mul(_taxDistributeFee).div(100);
        uint256 tTeamMarket = tAmount.mul(_teamMarketFee).div(100);
        uint256 tCharity = tAmount.mul(_charityFee).div(100);
        uint256 tBurn = tAmount.mul(_burnFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tDistributeFee).sub(tTeamMarket).sub(tCharity).sub(tBurn);
        // _getRValues
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rDistributeFee = tDistributeFee.mul(currentRate);
        uint256 rTeamMarket = tTeamMarket.mul(currentRate);
        uint256 rCharity = tCharity.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rDistributeFee).sub(rTeamMarket).sub(rCharity).sub(rBurn);
        return (rAmount, rTransferAmount, rDistributeFee, tTransferAmount, tDistributeFee, tTeamMarket, tCharity, tBurn);
    }
    */

    //set max buy amount
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        require(maxTxPercent > 0, "Amount must be greater than 0");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
        emit MaxTxAmountUpdated(_maxTxAmount);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }
    
    // added to reduce stack
    function _calculateReflectTransfer(address sender, address recipient, uint256 rAmount, uint256 rTransferAmount) private {
        
       _rOwned[sender] = _rOwned[sender].sub(rAmount);
       _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
    }
    // added to reduce stack
    function _calculateStandardTransfer(address sender, address recipient, uint256 tAmount, uint256 tTransferAmount) private {
       
       _tOwned[sender] = _tOwned[sender].sub(tAmount);
       _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    }
    
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        //(uint256 rAmount, uint256 rTransferAmount, uint256 rDistributeFee, uint256 tTransferAmount, uint256 tDistributeFee, uint256 tTeamMarket, uint256 tCharity, uint256 tBurn) = _getValues(tAmount);
        // moved fuction above to reduce stack
        // _getValues //
            // _getTValues
            uint256 tDistributeFee = tAmount.mul(_taxDistributeFee).div(100);
            uint256 tTeamMarket = tAmount.mul(_teamMarketFee).div(100);
            // 0.5% fee by dividing by 200
            uint256 tCharity = tAmount.mul(_charityFee).div(200);
            uint256 tBurn = tAmount.mul(_burnFee).div(200);
            //
            uint256 tTransferAmount = tAmount.sub(tDistributeFee).sub(tTeamMarket).sub(tCharity).sub(tBurn);
            // _getRValues
            uint256 currentRate = _getRate();
            uint256 rAmount = tAmount.mul(currentRate);
            uint256 rDistributeFee = tDistributeFee.mul(currentRate);
            uint256 rTeamMarket = tTeamMarket.mul(currentRate);
            uint256 rCharity = tCharity.mul(currentRate);
            uint256 rBurn = tBurn.mul(currentRate);
            uint256 rTransferAmount = rAmount.sub(rDistributeFee).sub(rTeamMarket).sub(rCharity).sub(rBurn);
        //
        _calculateStandardTransfer(sender, recipient, tAmount, tTransferAmount);
        _calculateReflectTransfer(sender, recipient, rAmount, rTransferAmount);
        _takeTeamMarket(tTeamMarket);
        _takeCharity(tCharity);
        _takeBurn(tBurn);
        _reflectFee(rDistributeFee, tDistributeFee);
        emit Transfer(sender, recipient, tTransferAmount);
        emit TeamMarket(sender, _teamMarketAddress, tTeamMarket);
        emit Charity(sender, _charityAddress, tCharity);
        emit Burn(sender, _burnAddress, tBurn);
    }
// marketing & dev
    function _takeTeamMarket(uint256 tTeamMarket) private {
        uint256 currentRate = _getRate();
        uint256 rTeamMarket = tTeamMarket.mul(currentRate);
        _tOwned[_teamMarketAddress] = _tOwned[_teamMarketAddress].add(tTeamMarket);
        _rOwned[_teamMarketAddress] = _rOwned[_teamMarketAddress].add(rTeamMarket);
    }
// added charity
    function _takeCharity(uint256 tCharity) private {
        uint256 currentRate = _getRate();
        uint256 rCharity = tCharity.mul(currentRate);
        _tOwned[_charityAddress] = _tOwned[_charityAddress].add(tCharity);
        _rOwned[_charityAddress] = _rOwned[_charityAddress].add(rCharity);
    }
// added burn
    function _takeBurn(uint256 tBurn) private {
        uint256 currentRate = _getRate();
        uint256 rBurn = tBurn.mul(currentRate);
        _tOwned[_burnAddress] = _tOwned[_burnAddress].add(tBurn);
        _rOwned[_burnAddress] = _rOwned[_burnAddress].add(rBurn);
    }
// allow deposit to contract
    receive() external payable {}
}