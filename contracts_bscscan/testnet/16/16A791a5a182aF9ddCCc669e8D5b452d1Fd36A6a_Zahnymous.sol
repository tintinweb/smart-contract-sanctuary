// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IERC20.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

/*
    ReflectFeeCoin template token tokenomics:
        - Max Supply: 100,000,000
        - Max TX: 2,000,000 (2%)
        - Min TX: 100 (0.0001%)
        - 3% of all sells are automatically redistributed to all holders
        - 3% fee is automatically added to the liquidity pool
        - 2% fee goes to a "marketing address"
        - 1% fee goes to a "developer address"
*/

contract Zahnymous is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    

    /* Maps */  
    mapping (address => uint256) private _rOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;

    /* Naming */
    string private _name = "Zahnymous";
    string private _symbol = "ZAH";

    /* Decimal handling */
    uint8 private _decimals = 18;
    uint256 private _decimalFactor = 10**_decimals;

    /* Total supply, total reflected supply and total fees taken */
    uint256 private constant MAX = ~uint256(0); // Maximum uint256
    uint256 private _tTotal = 10**8 * _decimalFactor; // Tokens total
    uint256 private _rTotal = MAX - (MAX % _tTotal); // Reflections total
    uint256 private _tFeeTotal; // Token Fee Total (total fees gathered)

    /* Transaction restrictions */
    uint256 public _maxTxAmount = 2 * 10**6 * _decimalFactor;
    uint256 public _minTxAmount = 10**2 * _decimalFactor;

    /* Fees */
    /* Redistributions to holders */
    uint256 public _taxFee = 0;
    uint256 public _previousTaxFee = _taxFee;

    /* Liquidity Pool */
    uint256 public _liqFee = 7;
    uint256 public _previousLiqFee = _liqFee;

    /* Marketing Wallet */
    uint256 public _marketingFee = 3;
    uint256 public _previousMarketingFee = _marketingFee;

    /* Developer Wallet */
    uint256 public _developerFee = 0;
    uint256 public _previousDeveloperFee = _developerFee;

    /* Payable fee wallets */
    address payable _developerAddress;
    address payable _marketingAddress;

    /* PancakeSwap */
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    /* Security utils */
    // Mutex lock for taking fees (calls untrusted external contracts)
    bool takeFeesMutexLock;
    modifier lockTakeFees {
        takeFeesMutexLock = true;
        _;
        takeFeesMutexLock = false;
    }

    constructor() {
        _rOwned[_msgSender()] = _rTotal;

        createPancakeSwapPair();

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    // -------> PancakeSwap functions
    receive() external payable {} // to recieve ETH from uniswapV2Router when swaping

    function createPancakeSwapPair() public onlyOwner {
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // MAINNET
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // TESTNET

         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // Set router contract variable
        uniswapV2Router = _uniswapV2Router;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // Generate the uniswap pair path of token -> WETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount, address partner) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            partner,
            block.timestamp
        );
    }
    // <------- PancakeSwap functions

    /* BEP20 functions */
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    /* BEP20 functions */


    /* Reflection utilities ---> */
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getRate() private view returns(uint256) {
        return _rTotal.div(_tTotal);
    }
    /* <--- Reflection utilities */


    /* Private internal contract functions */
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
        if (from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        if (from != owner() && to != owner())
            require(amount >= _minTxAmount, "Transfer amount cannot be smaller than minTxAmount.");

        bool takeFee = true;

        // Do not take fee if the sender should be excluded
        if (_isExcludedFromFee[from]) {
            takeFee = false;
        }

        // Don't take any fees if marketing address or developer addresses aren't set.
        if (_marketingAddress == address(0) || _developerAddress == address(0)) {
            takeFee = false;
        }

        if (
            takeFee &&
            from != uniswapV2Pair &&
            !takeFeesMutexLock
        ) {
            // Subtract the transfer amount left after fees
            uint256 totalFee = _developerFee.add(_marketingFee).add(_liqFee);
            uint256 totalFeeAmount = amount.mul(totalFee).div(100);
            uint256 oldAmount = amount;
            amount = amount.sub(totalFeeAmount);

            // Take fees
            _takeFees(oldAmount, from);
        }

        // Transfer the amount left of the transfer (and also take reflection tax fee here)
        _tokenTransfer(from, to, amount, takeFee);
    }

    function _takeFees(uint256 amount, address from) private lockTakeFees {
        // Calculate the wallet fees to take (partnership and marketing) - don't
        // take reflect tax or liquidity here
        uint256 walletFee = _developerFee.add(_marketingFee);
        uint256 walletFeeAmount = amount.mul(walletFee).div(100);

        // Calculate liquidity fee amount, and split it into two halves, one for
        // the amount of tokens, and the other half will represent the amount of
        // tokens to be swapped into ETH
        uint256 totalLiqFeeAmount = amount.mul(_liqFee).div(100);
        uint256 liqFeeAmount = totalLiqFeeAmount.div(2);
        uint256 liqFeeToBeSwappedToETHAmount = totalLiqFeeAmount.sub(liqFeeAmount);

        // Total fees that will have been taken away from the amount of tokens
        uint256 totalFeeAmount = walletFeeAmount.add(totalLiqFeeAmount);
        uint256 totalFeeAmountToBeSwappedForETH = walletFeeAmount.add(liqFeeToBeSwappedToETHAmount);
         

        // Capture the contract's current ETH balance
        uint256 initialBalance = address(this).balance;

        // Send the tokens taken as fee to the contract to be able to swap
        // them for ETH (the contract address needs the token balance)
        _tokenTransfer(from, address(this), totalFeeAmount, false);

        require(
            balanceOf(address(this)) >= totalFeeAmountToBeSwappedForETH,
            "Contract address does not have the available token balance to perform swap"
        );

        // Swap the required amount of tokens for ETH
        swapTokensForEth(totalFeeAmountToBeSwappedForETH);

        // How much ETH did we just swap into?
        uint256 swappedETH = address(this).balance.sub(initialBalance);

        // This multiplies the liquidity fee by 10 to avoid halving imprecisions on odd integers
        uint256 totalFeeToBeSwappedForETHMul10 = _liqFee.mul(10).div(2).add(walletFee.mul(10));
        // Calculate developer and marketing portions of the swapped ETH (also remember to multiply this factor by 10)
        uint256 developerETHPortion = swappedETH.div(totalFeeToBeSwappedForETHMul10).mul(_developerFee.mul(10));
        uint256 marketingETHPortion = swappedETH.div(totalFeeToBeSwappedForETHMul10).mul(_marketingFee.mul(10));
        // To avoid annoying halving errors, the rest of the ETH portion
        // should be exactly what was supposed to be added to the liquidity
        // pool. Thus we can just subtract from the remaining swappedETH
        // instead of calculating the exact fee percentage.
        uint256 totalETHPortionForWallets = developerETHPortion.add(marketingETHPortion);
        uint256 liquidityPoolETHPortion = swappedETH.sub(totalETHPortionForWallets);

        // Transfer ETH to fee wallets
        (bool sent, bytes memory data) = _developerAddress.call{value: developerETHPortion}("");
        require(sent, 'ETH was not sent to developer');
        (sent, data) = _marketingAddress.call{value: marketingETHPortion}("");
        require(sent, 'ETH was not sent to marketing');

        // Liquidity pool ETH was calculated from the swappedETH, and the
        // liqFeeAmount was the tokens calculated earlier representing the
        // other half of the liquidity fee.
        addLiquidity(liqFeeAmount, liquidityPoolETHPortion, owner());
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) {
            removeAllFees();
        }

        _transferStandard(sender, recipient, amount);

        if (!takeFee) {
            restoreAllFees();
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(100);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liqFee).div(100);
    }

    function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketingFee).div(100);
    }

    function calculateDeveloperFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_developerFee).div(100);
    }

    function removeAllFees() private {
        if(_taxFee == 0 && _marketingFee == 0 && _developerFee == 0 && _liqFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousDeveloperFee = _developerFee;
        _previousMarketingFee = _marketingFee;
        _previousLiqFee = _liqFee;
        
        _taxFee = 0;
        _liqFee = 0;
        _developerFee = 0;
        _marketingFee = 0;
    }
    
    function restoreAllFees() private {
        _taxFee = _previousTaxFee;
        _developerFee = _previousDeveloperFee;
        _marketingFee = _previousMarketingFee;
        _liqFee = _previousLiqFee;
    }
    /* Private internal contract functions */


    /* Public setters */
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        _previousTaxFee = _taxFee;
        _taxFee = taxFee;
    }

    function setLiqFeePercent(uint256 liqFee) external onlyOwner {
        _previousLiqFee = _liqFee;
        _liqFee = liqFee;
    }

    function setDeveloperFeePercent(uint256 developerFee) external onlyOwner {
        _previousDeveloperFee = _developerFee;
        _developerFee = developerFee;
    }

    function setMarketingFeePercent(uint256 marketingFee) external onlyOwner {
        _previousMarketingFee = _marketingFee;
        _marketingFee = marketingFee;
    }

    function setDeveloperAddress(address payable developer) public onlyOwner {
        _developerAddress = developer;
    }
    
    function setMarketingAddress(address payable marketing) public onlyOwner {
        _marketingAddress = marketing;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    /* Public setters */


    /* Public getters */
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function showDeveloperAddress() public view returns(address payable) {
        return _developerAddress;
    }
    
    function showMarketingAddress() public view returns(address payable) {
        return _marketingAddress;
    }

    function getPairAddress() public view returns (address) {
        return uniswapV2Pair;
    }
    /* Public getters */
}