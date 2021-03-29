// SPDX-License-Identifier: Unlicensed

// FIXME - Comment out this when not debugging
//import "hardhat/console.sol"; // debugging
import "./SafeMath.sol";
import "./Address.sol";
import "./IBEP20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IPancakeFactory.sol";
import "./IPancakeRouter01.sol";
import "./IPancakeRouter02.sol";


// TODO - build in proxy contract

/**


Catnip - NIP


1 Billion Permanent Supply
1,000,000,000
2% of every transaction is taken and sent to the Liquidity Pool on PancakeSwap permanently, that cannot be interacted with other than through Pancake Swap. 
2% of every transaction is taken as a Reflect Fee, which is given to all holders.
1% of the transaction is sent to the Team wallet. 
This computes to a 5% total fee on each transaction.
Withdrawing tokens from the Team Wallet is timelocked by 2 days. 

The max transfer amount for any 1 trade is 1 Million, or 0.1% of total supply. 
This will stop dumps. This also applies to team wallet. 
Normal Transfers are timed out for 24 hours. Meaning you get 1 time to buy or sell per day.

The token will have a proxy contract which is timelocked by 2 days. 
Proposals are made by the Team and voted on by the community. 
Once a proposal is decided it will be updated in the contract.

NIP is used to purchase NFTs from the Marketplace. 
When you purchase NFTs, 50% goes to the Liquidity Pool on Pancake Swap.
40% goes to all other holders of NIP.
10% goes to the Team Wallet.
Once you have your NFT, it can be sold or traded. It can also be used in upcoming games.

An Airdrop will happen for all PAW holders. You will receive a ratio'd amount as the max supply is being reduced 
from 1 Quadrillion to 1 Billion. So you will have less NIP, but it will be equal in proportion to the amount of PAW you originally had.

The airdrop can be claimed 10% a week, so full airdropped amount is available in 10 weeks upon release. 
We recommend waiting till the end of the last week to claim all of the NIP tokens to save on gas fee.




// join on discord - https://discord.gg/YTTqYSkVGE

// Features
// Permanent Supply, no burning, no minting
// TODO - add in the number of BNB here
// 85% of Total Supply (850 Million NIP) was initially put into the LP with X BNB
// 10% of Total Supply (100 Million NIP) is for Public Marketing fees, this is for payment of Adverts, Shilling, etc. This will be sold slowly to not cause a dump in price.
// 5%  of Total Supply (50 Million NIP) startup payments to Devs, Artists, and Team Members. Will not be dumped all at once.




The actual percentages can change, but I think we should use this method for the payment to the devs. 
The advantage of using LP tokens is that when they are removed and split, they don't crash the price as long as the user holds the Paw token. 
But the other half of the pair (BNB or whatever) is free for them to use.


This is a combination of LIQ, RFI, SHIB, DOGE, HOGE, and all the other frictionless yield tokens you know.


// TODO: build up functionality to recover tokens sent directly to a contract's address
// TODO - Build in an actual check Max Transfer function to stop whale dumps


*/



pragma solidity ^0.8.3;







contract Catnip is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint256 private totalSupplyOfToken = 1 * 10**9 * 10**9;     // the 10^9 is to get us past the decimal amount and the 2nd one gets us to 1 billion
    uint8 private totalDecimalsOfToken = 9;
    string private tokenSymbol = "NIP";
    string private tokenName = "Catnip";

    mapping(address => bool) private isAccountExcludedFromReward;
    address[] private excludedFromRewardAddresses;      // holds the address of the account that is excluded from reward

    mapping(address => bool) private isAccountExcludedFromFee;

    mapping(address => mapping(address => uint256)) private allowanceAmount;

    mapping(address => uint256) private reflectTokensOwned;
    mapping(address => uint256) private totalTokensOwned;








    // // TODO - below 3 variables to go through
    uint256 private constant MAX = ~uint256(0);
    uint256 private _rTotal = (MAX - (MAX % totalSupplyOfToken));       // might stand for reflection totals, meaning the total number of possible reflections?
    uint256 private totalFeeAmount;





    uint256 public taxFeePercent = 2;
    uint256 private previousTaxFeePercent = taxFeePercent;

    uint256 public liquidityFeePercent = 2;
    uint256 private previousLiquidityFeePercent = liquidityFeePercent;

    uint256 public teamFeePercent = 1;      // TODO - build in team fee taking functionality
    uint256 private previousTeamFeePercent = teamFeePercent;

    IPancakeRouter02 public immutable pancakeswapRouter;
    address public immutable pancakeswapPair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public maxTransferAmount = 1 * 10**6 * 10**9;        // 10^6 gets to 1 million, 10^9 gets past decimals
    // TODO - Implement transfer timer
    // TODO - implement multisig

    // num of tokens stored by fees, it is related to the minimum needed in order to do the liquification of the stored fees, otherwise it would take too much gas.
    uint256 private numTokensSellToAddToLiquidity = 300000 * 10**6 * 10**9;   
    

    // Events
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);








    constructor() {

        // TODO - rename variables after understanding them
        reflectTokensOwned[_msgSender()] = _rTotal;

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

    // FIXME - remove this function, just used for testing
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

    

    // TODO - figure out
    function balanceOf(address account) public view override returns (uint256) {
        if (isAccountExcludedFromReward[account]) {     // TODO - figure out what this does exactly, it's RFI code
            return totalTokensOwned[account];
        }
        return tokenFromReflection(reflectTokensOwned[account]);
    }

    

    

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        transferInternal(_msgSender(), recipient, amount); // transfers with fees applied
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) { 
        return allowanceAmount[owner][spender];    // Returns remaining tokens that spender is allowed during {approve} or {transferFrom} 
    }

    function approveInternal(address owner, address spender, uint256 amount) internal { 
        // This is internal function is equivalent to `approve`, and can be used to e.g. set automatic allowances for certain subsystems, etc.
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
        transferInternal(sender, recipient, amount); 
        approveInternal(sender, _msgSender(), allowanceAmount[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool){
        approveInternal(_msgSender(), spender, allowanceAmount[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool){
        approveInternal(_msgSender(),spender,allowanceAmount[_msgSender()][spender].sub(subtractedValue,"BEP20: decreased allowance below zero"));
        return true;
    }

    function totalFees() public view returns (uint256) {
        return totalFeeAmount;
    }


    // TODO - figure this out
    function deliverReflectTokens(uint256 tAmount) public {
        address sender = _msgSender();
        require(!isAccountExcludedFromReward[sender],"Excluded addresses cannot call this function");
        (uint256 rAmount, , , , , ) = getTaxAndReflectionValues(tAmount);
        reflectTokensOwned[sender] = reflectTokensOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        totalFeeAmount = totalFeeAmount.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= totalSupplyOfToken, "Amount must be less than supply");

        (uint256 rAmount, uint256 rTransferAmount, , , , ) = getTaxAndReflectionValues(tAmount);

        if(deductTransferFee){
            return rTransferAmount;     // if we are deducting the transfer fee, then use this amount, otherwise return the regular Amount
        }
        else{
            return rAmount;
        }
    }

    // TODO - figure this out
    function tokenFromReflection(uint256 rAmount) public view returns (uint256){
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = getReflectRate();
        return rAmount.div(currentRate);        // gets the amount of the reflection
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return isAccountExcludedFromReward[account];
    }

    function excludeFromReward(address account) public onlyOwner() {
        // TODO - if there is ever cross change compatability, then in the future you will need to include Uniswap Addresses, but for now Pancake Swap works.
        require(account != 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F, "Account must not be PancakeSwap Router");    // don't ever exclude the Uniswap or Pancake Swap router
        require(!isAccountExcludedFromReward[account], "Account is already excluded");
        if (reflectTokensOwned[account] > 0) {
            totalTokensOwned[account] = tokenFromReflection(reflectTokensOwned[account]);   // gets the reflect tokens and gives them to the address before excluding it
        }
        isAccountExcludedFromReward[account] = true;
        excludedFromRewardAddresses.push(account);
    }


    function includeInReward(address account) external onlyOwner() {
        require(isAccountExcludedFromReward[account], "Account is already excluded");
        for (uint256 i = 0; i < excludedFromRewardAddresses.length; i++) {
            if (excludedFromRewardAddresses[i] == account) {
                excludedFromRewardAddresses[i] = excludedFromRewardAddresses[excludedFromRewardAddresses.length - 1];   // finds and removes the address from the excluded addresses

                // Perhaps rename the variable, could be a bug?
                totalTokensOwned[account] = 0;  // sets the reward tokens to 0 // TODO - test this to make sure we aren't setting the total actual tokens to zero, could be a bug?. 
                // maybe this is totalRewardTokensOwned?


                isAccountExcludedFromReward[account] = false;
                excludedFromRewardAddresses.pop();
                break;
            }
        }
    }

    

    function excludeFromFee(address account) public onlyOwner {
        isAccountExcludedFromFee[account] = true;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return isAccountExcludedFromFee[account];
    }

    function includeInFee(address account) public onlyOwner {
        isAccountExcludedFromFee[account] = false;
    }

    function setTaxFeePercent(uint256 newTaxFeePercent) external onlyOwner() {
        taxFeePercent = newTaxFeePercent;
    }

    function setLiquidityFeePercent(uint256 newLiquidityFeePercent) external onlyOwner() {
        liquidityFeePercent = newLiquidityFeePercent;
    }

    function setTeamFeePercent(uint256 newTeamFeePercent) external onlyOwner() {
        teamFeePercent = newTeamFeePercent;
    }

    function setMaxTransferPercent(uint256 maxTransferPercent) external onlyOwner() {
        maxTransferAmount = totalSupplyOfToken.mul(maxTransferPercent).div(10**2);  // the math is ((Total Supply * %) / 100)
    }

    function setSwapAndLiquifyEnabled(bool enableSwapAndLiquify) public onlyOwner {     
        swapAndLiquifyEnabled = enableSwapAndLiquify;   // allows owner to turn off the liquification fee
        emit SwapAndLiquifyEnabledUpdated(enableSwapAndLiquify);
    }

    receive() external payable {}       // used as a fallback function that is only able to receive BNB.

    function takeReflectFee(uint256 reflectFee, uint256 taxFee) private {
        _rTotal = _rTotal.sub(reflectFee);      // subtracts the fee from the reflect totals
        totalFeeAmount = totalFeeAmount.add(taxFee);    // adds to the toal fee amount
    }



    // FIXME - remove in production
    function getReflectRateTest() public view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = getCurrentSupplyTotals();
        // console.log("rSupply", rSupply);
        // console.log("tSupply", tSupply);
        // console.log("rSupply.div(tSupply)", rSupply.div(tSupply));
        return rSupply.div(tSupply);
    }

    function getReflectRate() private view returns (uint256) {
        (uint256 reflectSupply, uint256 tokenSupply) = getCurrentSupplyTotals();       // gets the current reflect supply, and the total token supply.
        return reflectSupply.div(tokenSupply);        // to get the rate, we will divide the reflect supply by the total token supply.
    }


    // TODO - figure out
    function getCurrentSupplyTotals() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;      // total reflections
        uint256 tSupply = totalSupplyOfToken;       // total supply

        for (uint256 i = 0; i < excludedFromRewardAddresses.length; i++) {
            if ((reflectTokensOwned[excludedFromRewardAddresses[i]] > rSupply) || (totalTokensOwned[excludedFromRewardAddresses[i]] > tSupply)){
                return (_rTotal, totalSupplyOfToken);       // if any address that is excluded has a greater reflection supply or great than the total supply then we just return that
            } 
            rSupply = rSupply.sub(reflectTokensOwned[excludedFromRewardAddresses[i]]);  // calculates the reflection supply by subtracting the reflect tokens owned from every address
            tSupply = tSupply.sub(totalTokensOwned[excludedFromRewardAddresses[i]]);    // calculates the total token supply by subtracting the total tokens owned from every address
            // I think this will eventually leave the supplies with what's left in the PancakeSwap router
        }

        if (rSupply < _rTotal.div(totalSupplyOfToken)){     // checks to see if the reflection total rate is greater than the reflection supply after subtractions
            return (_rTotal, totalSupplyOfToken);
        } 

        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        // TODO - figure out this, I think it's taking some of the liquidity and giving it to reflect holders who have LPs, if they are excluded then they get it in their tOwned balance?
        uint256 currentRate = getReflectRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        reflectTokensOwned[address(this)] = reflectTokensOwned[address(this)].add(rLiquidity);  // if included gives the reward to their reflect tokens owned part
        if (isAccountExcludedFromReward[address(this)]){
            totalTokensOwned[address(this)] = totalTokensOwned[address(this)].add(tLiquidity);  // if excluded from reward gives it to their tokens, 
        }
    }

    



    


    
    function transferInternal(address senderAddr, address receiverAddr, uint256 amount) private {   
        // internal function is equivalent to {transfer}, and can be used to e.g. implement automatic token fees, slashing mechanisms, etc.

        require(senderAddr != address(0), "BEP20: transfer from the zero address");
        require(receiverAddr != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= maxTransferAmount, "Transfer amount exceeds the maxTxAmount."); 
 
        // is the token balance of this contract address over the min number of tokens that we need to initiate a swap + liquidity lock?
        // don't get caught in the a circular liquidity event, don't swap and liquify if sender is the uniswap pair.
        uint256 contractStoredFeeTokenBalance = balanceOf(address(this));

        if (contractStoredFeeTokenBalance >= maxTransferAmount) {
            // why would we do this? we should store all the amounts at once, not just the max. doesn't make a lot of sense
            // TODO- still not exactly sure on what this is
            contractStoredFeeTokenBalance = maxTransferAmount;        // sets the storedFeeTokenBalance to the MaxtxAmount, this will leave some of the tokens in the pool behind maybe?
        }

        bool overMinContractStoredFeeTokenBalance = false; 
        if(contractStoredFeeTokenBalance >= numTokensSellToAddToLiquidity){  // check to see if there are enough tokens stored from fees in the Contract to justify the Swap
            overMinContractStoredFeeTokenBalance = true;                        // if we did not have a minimum, the gas would eat into the profits generated from the fees.
        }

        if (overMinContractStoredFeeTokenBalance && !inSwapAndLiquify && senderAddr != pancakeswapPair && swapAndLiquifyEnabled) {
            contractStoredFeeTokenBalance = numTokensSellToAddToLiquidity;     // TODO - perhaps this should be changed back to just it's normal balance, instead of setting it to a direct amount?       

            swapAndLiquify(contractStoredFeeTokenBalance);   //add liquidity
        }

        bool takeFee = true;    // should fee be taken?
        if (isAccountExcludedFromFee[senderAddr] || isAccountExcludedFromFee[receiverAddr]) {   // if either address is excluded from fee, then set takeFee to false.
            takeFee = false;    
        }

        //transfer amount, it will take tax, burn, liquidity fee
        transferTokens(senderAddr, receiverAddr, amount, takeFee);  // transfer the tokens, take the fee, burn, and liquidity fee
    }






    function swapAndLiquify(uint256 contractStoredFeeTokenBalance) private {

        inSwapAndLiquify = true;

        // gets two halves to be used in liquification
        uint256 half1 = contractStoredFeeTokenBalance.div(2);
        uint256 half2 = contractStoredFeeTokenBalance.sub(half1);

        uint256 initialBalance = address(this).balance;     
        // gets initial balance, get exact amount of BNB that swap creates, and make sure the liquidity event doesn't include BNB manually sent to the contract.

        swapTokensForEth(half1); // swaps tokens into BNB to add back into liquidity. Uses half 1

        uint256 newBalance = address(this).balance.sub(initialBalance);     // new Balance calculated after that swap

        addLiquidity(half2, newBalance);     // Adds liquidity to PancakeSwap using Half 2

        emit SwapAndLiquify(half1, newBalance, half2);

        inSwapAndLiquify = false;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);       // Contract Token Address
        path[1] = pancakeswapRouter.WETH();     // Router Address
        approveInternal(address(this), address(pancakeswapRouter), tokenAmount);        // TODO - Why two approvals?
        pancakeswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);     // make the swap
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        approveInternal(address(this), address(pancakeswapRouter), tokenAmount);        // TODO - Why two approvals?
        pancakeswapRouter.addLiquidityETH{value: ethAmount}(address(this),tokenAmount, 0, 0, owner(), block.timestamp);     // adds the liquidity
    }



    function removeAllFee() private {
        if (taxFeePercent == 0 && liquidityFeePercent == 0){
            return;     // if it's already zero for both just return, probably to not mess up the previous fee rates
        } 

        previousTaxFeePercent = taxFeePercent;
        previousLiquidityFeePercent = liquidityFeePercent;
        previousTeamFeePercent = teamFeePercent;

        taxFeePercent = 0;
        liquidityFeePercent = 0;
        teamFeePercent = 0;
    }

    function restoreAllFee() private {
        taxFeePercent = previousTaxFeePercent;
        liquidityFeePercent = previousLiquidityFeePercent;
        teamFeePercent = previousTeamFeePercent;
    }

    function getTaxValues(uint256 transferAmount) private view returns (uint256, uint256, uint256) {
        uint256 taxFee = transferAmount.mul(taxFeePercent).div(10**2);    // calculate Tax Fee
        uint256 taxLiquidity = transferAmount.mul(liquidityFeePercent).div(10**2);   // calculate Liquidity Fee
        uint256 taxTransferAmount = transferAmount.sub(taxFee).sub(taxLiquidity);
        return (taxTransferAmount, taxFee, taxLiquidity);
    }

    function getReflectionValues(uint256 transferAmount, uint256 taxFee, uint256 taxLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256){
        uint256 reflectionAmount = transferAmount.mul(currentRate);
        uint256 reflectionFee = taxFee.mul(currentRate);
        uint256 reflectionLiquidity = taxLiquidity.mul(currentRate);
        uint256 reflectionTransferAmount = reflectionAmount.sub(reflectionFee).sub(reflectionLiquidity);
        return (reflectionAmount, reflectionTransferAmount, reflectionFee);
    }

    function getTaxAndReflectionValues(uint256 tAmount) private view returns (uint256,uint256,uint256,uint256,uint256,uint256) {
        (uint256 taxTransferAmount, uint256 taxFee, uint256 taxLiquidity) = getTaxValues(tAmount);
        (uint256 reflectAmount, uint256 reflectTransferAmount, uint256 reflectFee) = getReflectionValues(tAmount, taxFee, taxLiquidity, getReflectRate());
        return (reflectAmount, reflectTransferAmount, reflectFee, taxTransferAmount, taxFee, taxLiquidity);
    }

    

    

    function transferTokens(address sender, address recipient, uint256 transferAmount, bool takeFee) private {
        if (!takeFee) {
            removeAllFee();
        }
        
        (uint256 reflectAmount, uint256 reflectTransferAmount,uint256 reflectFee,uint256 taxTransferAmount,uint256 taxFee,uint256 taxLiquidity) = getTaxAndReflectionValues(transferAmount);
        
        if(isAccountExcludedFromReward[sender]){    // is the sender address excluded from Reward?
            totalTokensOwned[sender] = totalTokensOwned[sender].sub(transferAmount);
        }

        reflectTokensOwned[sender] = reflectTokensOwned[sender].sub(reflectAmount);

        if(isAccountExcludedFromReward[recipient]){    // is the sender address excluded from Reward?
            totalTokensOwned[recipient] = totalTokensOwned[recipient].add(taxTransferAmount);
        }

        reflectTokensOwned[recipient] = reflectTokensOwned[recipient].add(reflectTransferAmount);

        _takeLiquidity(taxLiquidity);

        takeReflectFee(reflectFee, taxFee);
        emit Transfer(sender, recipient, taxTransferAmount);

        if (!takeFee){
            restoreAllFee();
        } 
    }

    

    
}