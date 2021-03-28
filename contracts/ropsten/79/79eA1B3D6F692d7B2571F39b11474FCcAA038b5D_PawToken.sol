// SPDX-License-Identifier: Unlicensed
// Note - The original code was licensed as Unlicensed, however in the contract i was specifically said
// "I make this #PAW to hand over it to the community." - I interpret this as being able to use the code as I see fit.
// refer to the original PAW at https://bscscan.com/address/0x1caa1e68802594ef24111ff0d10eca592a2b5c58#code

// TODO - Comment out this when not debugging
//import "hardhat/console.sol"; // debugging
import "./SafeMath.sol";
import "./Address.sol";
import "./IBEP20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IPancakeFactory.sol";
import "./IPancakeRouter01.sol";
import "./IPancakeRouter02.sol";

/**


// 1 Billion Max Supply
// 1,000,000,000



// join on discord - https://discord.gg/YTTqYSkVGE




This would be my suggestion.

85% community liquidity

10% Public marketing

5% to immediate startup payment needs (Nikolai94's friends ect., Not for us devs)

4% fee on each tx
--1% Reflect
--2% add liquidity to pool and burn LP tokens
--1% add liquidity to pool and distribute LP tokens to devs and managers (this is for us, maybe lock these tokens for a time)

The actual percentages can change, but I think we should use this method for the payment to the devs. The advantage of using LP tokens is that when they are removed and split, they don't crash the price as long as the user holds the Paw token. But the other half of the pair (BNB or whatever) is free for them to use.







   #PAW  ฅ^•ﻌ•^ฅ
   
   #LIQ+#RFI+#SHIB+#DOGE, combine together to #PAW  


   Great features:
   3% fee auto add to the liquidity pool to locked forever when selling
   2% fee auto distribute to all holders

   3% fee for liquidity will go to an address that the contract creates, 
   and the contract will sell it and add to liquidity automatically, 
   it's the best part of the #PAW idea, increasing the liquidity pool automatically, 
   help the pool grow from the small init pool.

 */



// TODO: build up functionality to recover tokens sent directly to a contract's address
pragma solidity ^0.8.3;







contract PawToken is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint256 private totalSupplyOfToken = 1 * 10**9 * 10**9;     // the 10^9 is to get us past the decimal amount and the 2nd one gets us to 1 billion
    uint8 private totalDecimalsOfToken = 9;
    string private tokenSymbol = "PAW";
    string private tokenName = "Paw Token";

    mapping(address => bool) private isAccountExcludedFromReward;
    mapping(address => bool) private isAccountExcludedFromFee;

    mapping(address => mapping(address => uint256)) private allowanceAmount;








    // variables to go through
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);

    uint256 private _rTotal = (MAX - (MAX % totalSupplyOfToken));
    uint256 private totalFeeAmount;

    uint256 public taxFeePercent = 2;
    uint256 private previousTaxFeePercent = taxFeePercent;

    uint256 public _liquidityFee = 3;
    uint256 private _previousLiquidityFee = _liquidityFee;

    IPancakeRouter02 public immutable pancakeswapRouter;
    address public immutable pancakeswapPair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public _maxTxAmount = 5000000 * 10**6 * 10**9;
    uint256 private numTokensSellToAddToLiquidity = 500000 * 10**6 * 10**9;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);








    constructor() {

        // TODO - rename variables after understanding them
        _rOwned[_msgSender()] = _rTotal;

        // 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F = LIVE PancakeSwap
        // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D = TESTNET Uniswap Ropsten

        // TODO - Change this when ready for live
        //IPancakeRouter02 pancakeswapRouterLocal = IPancakeRouter02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
        IPancakeRouter02 pancakeswapRouterLocal = IPancakeRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);      // gets the router
        pancakeswapPair = IPancakeFactory(pancakeswapRouterLocal.factory()).createPair(address(this), pancakeswapRouterLocal.WETH());     // Creates the pancakeswap pair
        pancakeswapRouter = pancakeswapRouterLocal; // set the rest of the contract variables in the global router variable from the local one

        isAccountExcludedFromFee[owner()] = true;  // exclude owner from Fee
        isAccountExcludedFromFee[address(this)] = true;  // exclude contract from Fee

        emit Transfer(address(0), _msgSender(), totalSupplyOfToken);    // emits event of the transfer of the supply from dead to owner
    }

    // TODO - remove this function, just used for testing
    function whatismax() public view{
        // console.log("MAX:", MAX);
        // console.log("totalSupplyOfToken:", totalSupplyOfToken);
        // console.log("(MAX % totalSupplyOfToken):", (MAX % totalSupplyOfToken));
        // console.log("(MAX - (MAX % totalSupplyOfToken)):", (MAX - (MAX % totalSupplyOfToken)));
        // console.log("_rTotal:", _rTotal);

        

    }



    function getOwner() external view override returns (address){
        return owner();     // gets current owner address
    }

    function decimals() public view override returns (uint8) {
        return totalDecimalsOfToken;    // gets total decimals  
    }

    function symbol() public view override returns (string memory) {
        return tokenSymbol;     // gets token symbol
    }

    function name() public view override returns (string memory) {
        return tokenName;       // gets token name
    }

    function totalSupply() external view override returns (uint256){
        return totalSupplyOfToken;      // gets total supply
    }

    

    
    function balanceOf(address account) public view override returns (uint256) {
        if (isAccountExcludedFromReward[account]) {     // TODO - figure out what this does exactly, it's RFI code
            return _tOwned[account];
        }
        return tokenFromReflection(_rOwned[account]);
    }

    

    

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        transferInternal(_msgSender(), recipient, amount); // basic transfer from submitter address to another
        return true;
    }

    

    function allowance(address owner, address spender) external view override returns (uint256) {
        return allowanceAmount[owner][spender];     // ollownace of tokens that an address can spend on behalf of the owner, set to zero by default, this is during {approve} or {transferFrom} 
    }



    

    

    function approveInternal(address owner, address spender, uint256 amount) internal { // This is internal function is equivalent to `approve`, and can be used to e.g. set automatic allowances for certain subsystems, etc.
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        allowanceAmount[owner][spender] = amount;       // approves the amount to spend by the owner
        emit Approval(owner, spender, amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool){
        approveInternal(_msgSender(), spender, amount);     
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        transferInternal(sender, recipient, amount);       // TODO - change name of the transferInternal to something more appropriate transferAmount
        approveInternal(sender, _msgSender(), allowanceAmount[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }



    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        approveInternal(
            _msgSender(),
            spender,
            allowanceAmount[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        approveInternal(
            _msgSender(),
            spender,
            allowanceAmount[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return isAccountExcludedFromReward[account];
    }

    function totalFees() public view returns (uint256) {
        return totalFeeAmount;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !isAccountExcludedFromReward[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        totalFeeAmount = totalFeeAmount.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= totalSupplyOfToken, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!isAccountExcludedFromReward[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        isAccountExcludedFromReward[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(isAccountExcludedFromReward[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                isAccountExcludedFromReward[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) 
        private {(
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function excludeFromFee(address account) public onlyOwner {
        isAccountExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        isAccountExcludedFromFee[account] = false;
    }

    function setTaxFeePercent(uint256 newTaxFeePercent) external onlyOwner() {
        taxFeePercent = newTaxFeePercent;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = totalSupplyOfToken.mul(maxTxPercent).div(10**2);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    receive() external payable {}       // receive BNB when swapping from the pancakeswap Router

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        totalFeeAmount = totalFeeAmount.add(tFee);
    }

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
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) =
            _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity
        );
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = totalSupplyOfToken;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                (_rOwned[_excluded[i]] > rSupply) || (_tOwned[_excluded[i]] > tSupply)
            ) return (_rTotal, totalSupplyOfToken);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(totalSupplyOfToken)) return (_rTotal, totalSupplyOfToken);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (isAccountExcludedFromReward[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(taxFeePercent).div(10**2);
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(_liquidityFee).div(10**2);
    }

    function removeAllFee() private {
        if (taxFeePercent == 0 && _liquidityFee == 0) return;

        previousTaxFeePercent = taxFeePercent;
        _previousLiquidityFee = _liquidityFee;

        taxFeePercent = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        taxFeePercent = previousTaxFeePercent;
        _liquidityFee = _previousLiquidityFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return isAccountExcludedFromFee[account];
    }



    









    
    function transferInternal(address senderAddr, address receiverAddr, uint256 amount) private {   // internal function is equivalent to {transfer}, and can be used to e.g. implement automatic token fees, slashing mechanisms, etc.

        require(senderAddr != address(0), "BEP20: transfer from the zero address");
        require(receiverAddr != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");    // TODO - rename maxTxAmount
 
        // is the token balance of this contract address over the min number of tokens that we need to initiate a swap + liquidity lock?
        // don't get caught in the a circular liquidity event, don't swap and liquify if sender is the uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            // TODO- still not exactly sure on what this is
            contractTokenBalance = _maxTxAmount;        // sets the contract's token balance to the maxtxamount if it's over the max tx amount. used in calculations, doesn't actually change the balance
        }

        bool overMinTokenBalance = false; 
        if(contractTokenBalance >= numTokensSellToAddToLiquidity){
            overMinTokenBalance = true;     // check to see if we are going to swap and liquify some of their tokens as they have enough to give.
        }

        if (overMinTokenBalance && !inSwapAndLiquify && senderAddr != pancakeswapPair && swapAndLiquifyEnabled) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);   //add liquidity
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to isAccountExcludedFromFee account then remove the fee
        if (isAccountExcludedFromFee[senderAddr] || isAccountExcludedFromFee[receiverAddr]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(senderAddr, receiverAddr, amount, takeFee);
    }






    function swapAndLiquify(uint256 contractTokenBalance) private {

        inSwapAndLiquify = true;

        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialBalance = address(this).balance;     // gets initial balance, get exact amount of eth that swap creates, and make sure the liquidity event doesn't include eth manually sent to the contract.

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);

        inSwapAndLiquify = false;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapRouter.WETH();

        approveInternal(address(this), address(pancakeswapRouter), tokenAmount);

        // make the swap
        pancakeswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        approveInternal(address(this), address(pancakeswapRouter), tokenAmount);

        // add the liquidity
        pancakeswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        if (isAccountExcludedFromReward[sender] && !isAccountExcludedFromReward[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!isAccountExcludedFromReward[sender] && isAccountExcludedFromReward[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!isAccountExcludedFromReward[sender] && !isAccountExcludedFromReward[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (isAccountExcludedFromReward[sender] && isAccountExcludedFromReward[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

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
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
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
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
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
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}