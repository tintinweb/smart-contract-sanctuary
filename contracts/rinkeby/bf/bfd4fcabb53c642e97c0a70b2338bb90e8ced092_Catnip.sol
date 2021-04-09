// SPDX-License-Identifier: Unlicensed

// FIXME - Comment out this when not debugging
// import "hardhat/console.sol"; // debugging

// Imports
import "./SafeMath.sol";
// import "./Address.sol";  // commented out because Initializeable.sol will import this for us
import "./IBEP20.sol";
import "./Context.sol";
// import "./Ownable.sol";  // commented out because We can't use the inheretance from OWnable as it has a constructor, we are using proxy.
import "./IPancakeFactory.sol";
import "./IPancakeRouter01.sol";
import "./IPancakeRouter02.sol";


import "./SafeBEP20.sol";


// import "./AirdropAddresses.sol";

// get the Initializable contract going for upgradable contracts
// import "../node_modules/openzeppelin-solidity/contracts/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts/proxy/utils/Initializable.sol";      // comment this out to try and get a direct reference
import "./Initializable.sol";  


// TODO - turn version 1 over to the multisig safe when ready
// TODO - Implement transfer timer

/**
Catnip - NIP
NIP Discord - https://discord.gg/MNDkzjt3DZ

\\\\\\\\\\\\\\\\\\\\\\\\\\\\ SUMMARY \\\\\\\\\\\\\\\\\\\\\\\\\\\\
Permanent Supply, no burning, no minting
This is a combination of LIQ, RFI, SHIB, DOGE, HOGE, and all the other frictionless yield tokens you know.


\\\\\\\\\\\\\\\\\\\\\\\\\\\\ DETAILS \\\\\\\\\\\\\\\\\\\\\\\\\\\\

Total supply 1,000,000,000 (1bil) tokens
      Airdrop 20% - 200,000,000 tokens - Deatils Below *$
      Developer wallet 15% - 150,000,000 tokens - Details below*%
      Public Supply 65% - 650,000,000 tokens
            Pancake swap 53.5% - 350,000,000 tokens
            Pre-sale 46.5% - 300,000,000 tokens

There will be a 5% fee on transactions:
 2% of every transaction is taken and sent to the Liquidity Pool on PancakeSwap permanently, that cannot be interacted with other than through Pancake Swap. 
 2% of every transaction is taken as a Reflect Fee, which is given to all holders.
 1% of the transaction is sent to the Team wallet. 
    Withdrawing tokens from the Team Wallet is timelocked by 2 days. 

The max transfer amount for any 1 trade is 10,000,000 (1% of total supply). This will act as a way to prevent mass dumps. This also applies to team wallet. 

\\\\\\\\\\\\\\\\\\\\\\\DEV WALLET\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
        
*% Developer wallet is only used to centralize developer fee payout, such as 
    essential expenses like webhosting, domain etc. and upfront costs of ads, extra work force payments etc. 
Initial developer payment will be 1,000,000 (1mil) NIPs which is 0.1% of total supply. 
Afterwards the amount will be however much based on how much the 1% team tx fee generates.

\\\\\\\\\\\\\\\\\\\\\\\\AIR DROP\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

*$ Airdrop is only available to people who had PAW in their wallet on March 20th 2021!
You will receive a ratio'd amount as the max supply is being reduced from 1 Quadrillion to 1 Billion. 
So you will have less new Token, but it will be equal in proportion to the amount of PAW you originally had.
Airdrop will be 10% a week so full airdropped amount will be available in 10 weeks. 
You can claim the 10% weekly or wait 10 weeks and claim the full amount then. 
We recommend waiting till the end of the last week to claim all of the NIP tokens to save on gas fee.
Airdrop system will be open for an additional 2 months after the 10th week drop, 
after the 2 months period the sytem will be closed and the unclaimed tokens will be put into public supply.

Airdrop receivers can choose between:
    1. 100% amount over 10 weeks airdrop
    2. 50% amount over 10weeks with an additional limited supply NFT airdrop
The limited supply NFT will be minted only when the receiver submits to the 2nd option. 
So it will be a VERY limited NFT as it can only be acquired through this airdrop system and never again in anyway.

\\\\\\\\\\\\\\\\\\\\\\\\\\ROAD MAP\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

Everything written here is up for changes.

Catnip game should get a public beta by the end of April, and official release in early Q3 this year.

We plan on getting an audit from War on Rugs ASAP when we go live with Pre-sale. 
Later on around 2021 Q4/2022 Q1 we plan on getting another reputable name audit assuming the developer wallet has the funds to afford it!


Possible trasnfer time out = Normal Transfers are timed out for 24 hours. Meaning you get 1 time to buy or sell per day.

The token will have a proxy contract which is timelocked by 2 days. 
Proposals are made by the Team and voted on by the community. 
Once a proposal is decided it will be updated in the contract.

NIP is used to purchase NFTs from the Marketplace. 
When you purchase NFTs, 50% goes to the Liquidity Pool on Pancake Swap.
40% goes to all other holders of NIP.
10% goes to the Team Wallet.
Once you have your NFT, it can be sold or traded. It can also be used in upcoming games.

\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\





// TODO: build up functionality to recover tokens sent directly to a contract's address


*/



pragma solidity ^0.8.3;



// working on contract proxy
// import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
// contract BEP20UpgradeableProxy is TransparentUpgradeableProxy {
//     constructor(address logic, address admin, bytes memory data) TransparentUpgradeableProxy(logic, admin, data) public {
//     }
// }


    

contract Catnip is Context, IBEP20, Initializable {

    address private ownerOfToken;
    address private previousOwnerOfToken;

    using SafeMath for uint256;
    // using Address for address; // commented out as I don't think this is needed for the proxy, it was throwing an issue with the delegate call

    uint256 private totalSupplyOfToken;
    uint8 private totalDecimalsOfToken;
    string private tokenSymbol;
    string private tokenName;

    mapping(address => bool) private isAccountExcludedFromReward;
    address[] private excludedFromRewardAddresses;      // holds the address of the account that is excluded from reward

    mapping(address => bool) private isAccountExcludedFromFee;

    mapping(address => mapping(address => uint256)) private allowanceAmount;

    mapping(address => uint256) private reflectTokensOwned;
    mapping(address => uint256) private totalTokensOwned;








    // I have no idea what these variables actually do lol
    uint256 private MAXintNum;
    uint256 private _rTotal;
    uint256 private totalFeeAmount;





    uint256 public taxFeePercent;
    uint256 private previousTaxFeePercent;

    uint256 public liquidityFeePercent;
    uint256 private previousLiquidityFeePercent;

    uint256 public teamFeePercent;      // TODO - build in team fee taking functionality
    uint256 private previousTeamFeePercent;

    IPancakeRouter02 public pancakeswapRouter;
    address public pancakeswapPair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled;

    uint256 public maxTransferAmount;        // 10^6 gets to 1 million, 10^9 gets past decimals


    
    uint256 private numTokensSellToAddToLiquidity;

    uint public releaseUnixTimeStampV1;     // version 1 release date and time





    // airdrop vars
    mapping(address => uint256) public airDropTokensTotal;
    mapping(address => uint256) public airDropTokensLeftToClaim;
    mapping(address => bool) public airDropTokensPartialClaimed;
    mapping(address => bool) public airDropTokensAllClaimed;

    




    // Events
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AirDropClaimed(address claimer, uint256 amountClaimed);




    function initialize() public {

        // Have to use this instead of a constructor
        // I also need to give variables values here, instead of having them outside this function, otherwise it will not be contract safe.
        // this will be the constructor

        // moved from the Ownable constructor
        address msgSender = _msgSender();
        ownerOfToken = msgSender;
        //console.log("ownerOfToken", ownerOfToken);
        emit OwnershipTransferred(address(0), msgSender);



        totalSupplyOfToken = 1 * 10**9 * 10**9; // the 10^9 is to get us past the decimal amount and the 2nd one gets us to 1 billion
        totalDecimalsOfToken = 9;
        tokenSymbol = "NIP";
        tokenName = "Catnip";
        MAXintNum = ~uint256(0);
        _rTotal = (MAXintNum - (MAXintNum % totalSupplyOfToken));       // might stand for reflection totals, meaning the total number of possible reflections?


        taxFeePercent = 2;
        previousTaxFeePercent = taxFeePercent;

        liquidityFeePercent = 2;
        previousLiquidityFeePercent = liquidityFeePercent;

        teamFeePercent = 1;      // TODO - build in team fee taking functionality
        previousTeamFeePercent = teamFeePercent;

        swapAndLiquifyEnabled = true;

        maxTransferAmount = 1 * 10**7 * 10**9;        // 10^6 gets to 1 million, 10^9 gets past decimals




        // num of tokens stored by fees, it is related to the minimum needed in order to do the liquification of the stored fees, otherwise it would take too much gas.
        numTokensSellToAddToLiquidity = 300000 * 10**6 * 10**9;   

        reflectTokensOwned[_msgSender()] = _rTotal;     // I have no idea what this does exactly

        // 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F = LIVE PancakeSwap
        // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D = TESTNET Uniswap Ropsten and Rinkeby

        // TODO - Change this when ready for live
        //IPancakeRouter02 pancakeswapRouterLocal = IPancakeRouter02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
        IPancakeRouter02 pancakeswapRouterLocal = IPancakeRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);      // gets the router
        pancakeswapPair = IPancakeFactory(pancakeswapRouterLocal.factory()).createPair(address(this), pancakeswapRouterLocal.WETH());     // Creates the pancakeswap pair
        pancakeswapRouter = pancakeswapRouterLocal; // set the rest of the contract variables in the global router variable from the local one

        isAccountExcludedFromFee[owner()] = true;  // exclude owner from Fee
        isAccountExcludedFromFee[address(this)] = true;  // exclude contract from Fee

        emit Transfer(address(0), _msgSender(), totalSupplyOfToken);    // emits event of the transfer of the supply from dead to owner


        releaseUnixTimeStampV1 = block.timestamp;     // gets the block timestamp so we can know when it was deployed


        // FIXME - You will want to remove this so we don't airdrop the wrong people
        // Airdrop Initialization
        initializeAirdropMapping();

    }

    // FIXME - remove this function, just used for testing
    function testingFunction() public view{
        // console.log("MAX:", MAX);
        // console.log("totalSupplyOfToken:", totalSupplyOfToken);
        // console.log("(MAX % totalSupplyOfToken):", (MAX % totalSupplyOfToken));
        // console.log("(MAX - (MAX % totalSupplyOfToken)):", (MAX - (MAX % totalSupplyOfToken)));
        // console.log("_rTotal:", _rTotal);
    }


    function owner() public view returns (address) {
        return ownerOfToken;        // Returns the address of the current owner.
    }

    modifier onlyOwner() {
        require(ownerOfToken == _msgSender(), "Ownable: caller is not the owner");  // Throws if called by any account other than the owner.
        _;      // when using a modifier, the code from the function is inserted here. // if multiple modifiers then the previous one inherits the next one's modifier code
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
        if (isAccountExcludedFromReward[account]) {     // I have no idea what this does exactly
            return totalTokensOwned[account];
        }
        return tokenFromReflection(reflectTokensOwned[account]);
    }

    

    

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        transferInternal(_msgSender(), recipient, amount, false); // transfers with fees applied
        return true;
    }

    function allowance(address ownerAddr, address spender) external view override returns (uint256) { 
        return allowanceAmount[ownerAddr][spender];    // Returns remaining tokens that spender is allowed during {approve} or {transferFrom} 
    }

    function approveInternal(address ownerAddr, address spender, uint256 amount) internal { 
        // This is internal function is equivalent to `approve`, and can be used to e.g. set automatic allowances for certain subsystems, etc.
        require(ownerAddr != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        allowanceAmount[ownerAddr][spender] = amount;       // approves the amount to spend by the ownerAddr
        emit Approval(ownerAddr, spender, amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool){
        approveInternal(_msgSender(), spender, amount);     
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        transferInternal(sender, recipient, amount, false); 
        approveInternal(sender, _msgSender(), allowanceAmount[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    // TODO - figure out if setting this to Internal breaks anything
    function transferFromIgnoreMaxLimit(address sender, address recipient, uint256 amount) internal returns (bool) {
        transferInternal(sender, recipient, amount, true); 
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


    // TODO - Ask Shanghai Bill about this, the LIQ Dev, perhaps this is a manaul call?
    function deliverReflectTokens(uint256 tAmount) public {   
        address sender = _msgSender();          
        require(!isAccountExcludedFromReward[sender],"Excluded addresses cannot call this function");
        (uint256 rAmount, , , , , ) = getTaxAndReflectionValues(tAmount);
        reflectTokensOwned[sender] = reflectTokensOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        totalFeeAmount = totalFeeAmount.add(tAmount);
    }


    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= totalSupplyOfToken, "Amount must be less than supply");          // not too sure how this works exactly

        (uint256 rAmount, uint256 rTransferAmount, , , , ) = getTaxAndReflectionValues(tAmount);

        if(deductTransferFee){
            return rTransferAmount;     // if we are deducting the transfer fee, then use this amount, otherwise return the regular Amount
        }
        else{
            return rAmount;
        }
    }

    
    function tokenFromReflection(uint256 rAmount) public view returns (uint256){        // no idea what this does
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = getReflectRate();
        return rAmount.div(currentRate);        // gets the amount of the reflection
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return isAccountExcludedFromReward[account];
    }

    function excludeFromReward(address account) public onlyOwner() {
        // XXX - if there is ever cross change compatability, then in the future you will need to include Uniswap Addresses, but for now Pancake Swap works.
        require(account != 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F, "Account must not be PancakeSwap Router");    // don't ever exclude the Uniswap or Pancake Swap router
        require(!isAccountExcludedFromReward[account], "Account is already excluded");
        if (reflectTokensOwned[account] > 0) {
            totalTokensOwned[account] = tokenFromReflection(reflectTokensOwned[account]);   // gets the reflect tokens and gives them to the address before excluding it
        }
        isAccountExcludedFromReward[account] = true;
        excludedFromRewardAddresses.push(account);
    }


    function includeInReward(address account) external onlyOwner() {
        require(isAccountExcludedFromReward[account], "Account is already included");
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

    function getReflectRate() private view returns (uint256) {
        (uint256 reflectSupply, uint256 tokenSupply) = getCurrentSupplyTotals();       // gets the current reflect supply, and the total token supply.
        return reflectSupply.div(tokenSupply);        // to get the rate, we will divide the reflect supply by the total token supply.
    }


    
    function getCurrentSupplyTotals() private view returns (uint256, uint256) { // No idea what this does

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
        // no idea what this does - I think it's taking some of the liquidity and giving it to reflect holders who have LPs, if they are excluded then they get it in their tOwned balance?
        uint256 currentRate = getReflectRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        reflectTokensOwned[address(this)] = reflectTokensOwned[address(this)].add(rLiquidity);  // if included gives the reward to their reflect tokens owned part
        if (isAccountExcludedFromReward[address(this)]){
            totalTokensOwned[address(this)] = totalTokensOwned[address(this)].add(tLiquidity);  // if excluded from reward gives it to their tokens, 
        }
    }

    



    


    
    function transferInternal(address senderAddr, address receiverAddr, uint256 amount, bool ignoreMaxTxAmt) private {   
        // internal function is equivalent to {transfer}, and can be used to e.g. implement automatic token fees, slashing mechanisms, etc.

        require(senderAddr != address(0), "BEP20: transfer from the zero address");
        require(receiverAddr != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(!ignoreMaxTxAmt){
            require(amount <= maxTransferAmount, "Transfer amount exceeds the maxTxAmount."); 
        }
        
 
        // is the token balance of this contract address over the min number of tokens that we need to initiate a swap + liquidity lock?
        // don't get caught in the a circular liquidity event, don't swap and liquify if sender is the uniswap pair.
        uint256 contractStoredFeeTokenBalance = balanceOf(address(this));

        if (contractStoredFeeTokenBalance >= maxTransferAmount) {
            // why would we do this? we should store all the amounts at once, not just the max. doesn't make a lot of sense
            // still not exactly sure on what this is
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
        approveInternal(address(this), address(pancakeswapRouter), tokenAmount);        // Why two approvals? Have to approve both halfs
        pancakeswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);     // make the swap
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        approveInternal(address(this), address(pancakeswapRouter), tokenAmount);        // Why two approvals? Have to approve both halfs
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




    function getNowBlockTime() public view returns (uint) {
        return block.timestamp;     // gets the current time and date in Unix timestamp
    }


    // Air Drop Functions
    function airDropClaim() public {

        address claimer = _msgSender();

        // this address is not valid to claim so return it. Needs to have an amount over 0 to claim
        require(airDropTokensTotal[claimer] > 0,"You have no airdrop to claim.");

        require(!airDropTokensAllClaimed[claimer],"You have claimed all your AirDrop tokens");      // this address has claimed all possible airdrop tokens so return

        if(!airDropTokensPartialClaimed[claimer]){      // if it hasn't been partially claimed then it's their first time claiming it
            airDropTokensLeftToClaim[claimer] = airDropTokensTotal[claimer];        // since no tokens have attempted to be claimed yet, set up the LeftToClaim Mapping.
            airDropTokensPartialClaimed[claimer] = true;
        }

        uint256 amountOfNIPClaimedSoFar = airDropTokensTotal[claimer].sub(airDropTokensLeftToClaim[claimer]);

        uint256 percentClaimedSoFar = 0; 
        if(amountOfNIPClaimedSoFar > 0){
            percentClaimedSoFar = airDropTokensLeftToClaim[claimer].mul(100).div(airDropTokensTotal[claimer]); 
            percentClaimedSoFar = 100 - percentClaimedSoFar;
        }

        uint currentTime = getNowBlockTime();       // find the number of weeks it's been so far

        uint timeElapsedFromReleaseDate = currentTime.sub(releaseUnixTimeStampV1);

        uint numberOfWeeksSinceRelease = timeElapsedFromReleaseDate.div(604800);
        if(numberOfWeeksSinceRelease > 10){
            numberOfWeeksSinceRelease = 10;   // max number of weeks is 10
        }

        uint percentToGiveOut = numberOfWeeksSinceRelease.mul(10);  

        require(percentToGiveOut > percentClaimedSoFar, "0x01 - You have claimed all the airdrop available so far, check back later weeks for more.");

        uint amountToGiveClaimer = airDropTokensTotal[claimer].mul(percentToGiveOut).div(100);

        if(amountToGiveClaimer >= amountOfNIPClaimedSoFar){
            amountToGiveClaimer = amountToGiveClaimer.sub(amountOfNIPClaimedSoFar);
        }
        else{
            amountToGiveClaimer = amountOfNIPClaimedSoFar.sub(amountToGiveClaimer);
        }

        require(amountToGiveClaimer > 0, "0x02 - You have claimed all the airdrop available so far, check back later weeks for more.");

        approveInternal(ownerOfToken, claimer, amountToGiveClaimer.mul(10**9));        // approves amount to claim from owner address
        transferFromIgnoreMaxLimit(ownerOfToken, claimer, amountToGiveClaimer.mul(10**9));       // transfers the airdrop amount from the owner address to the claimer
        approveInternal(ownerOfToken, claimer, 0);        // sets the approved amount back to zero

        airDropTokensLeftToClaim[claimer] -= amountToGiveClaimer;   // reduces the amount left to claim

        if(airDropTokensLeftToClaim[claimer] == 0){
            airDropTokensAllClaimed[claimer] = true;
        }

        emit AirDropClaimed(claimer, amountToGiveClaimer);
    }



    // FIXME - Remove Function In Production
    function airDropClaimWeekSimulation(uint256 NumberOfWeeksToTest) public {

        address claimer = _msgSender();

        // console.log("claimer", claimer);
        // console.log("ownerOfToken", ownerOfToken);
        
        // console.log("airDropTokensTotal[claimer]", airDropTokensTotal[claimer]);
        // console.log("airDropTokensLeftToClaim[claimer]", airDropTokensLeftToClaim[claimer]);
        // console.log("airDropTokensPartialClaimed[claimer]", airDropTokensPartialClaimed[claimer]);
        // console.log("airDropTokensAllClaimed[claimer]", airDropTokensAllClaimed[claimer]);

        // this address is not valid to claim so return it. Needs to have an amount over 0 to claim
        require(airDropTokensTotal[claimer] > 0,"You have no airdrop to claim.");

        require(!airDropTokensAllClaimed[claimer],"You have claimed all your AirDrop tokens");      // this address has claimed all possible airdrop tokens so return

        if(!airDropTokensPartialClaimed[claimer]){      // if it hasn't been partially claimed then it's their first time claiming it
            airDropTokensLeftToClaim[claimer] = airDropTokensTotal[claimer];        // since no tokens have attempted to be claimed yet, set up the LeftToClaim Mapping.
            airDropTokensPartialClaimed[claimer] = true;
        }

        uint256 amountOfNIPClaimedSoFar = airDropTokensTotal[claimer].sub(airDropTokensLeftToClaim[claimer]);
        // console.log("amountOfNIPClaimedSoFar", amountOfNIPClaimedSoFar);


        uint256 percentClaimedSoFar = 0; 
        if(amountOfNIPClaimedSoFar > 0){
            percentClaimedSoFar = airDropTokensLeftToClaim[claimer].mul(100).div(airDropTokensTotal[claimer]); 
            percentClaimedSoFar = 100 - percentClaimedSoFar;
        }
        
        // console.log("percentClaimedSoFar", percentClaimedSoFar); 



        // find the number of weeks it's been so far
        uint currentTime = getNowBlockTime();

        // console.log("currentTime", currentTime);
        // console.log("releaseUnixTimeStampV1", releaseUnixTimeStampV1);

        uint timeElapsedFromReleaseDate = currentTime.sub(releaseUnixTimeStampV1);

        uint256 oneWeekInUnixTime = 604800;
        uint256 weeksInUnixTime = oneWeekInUnixTime.mul(NumberOfWeeksToTest);
        timeElapsedFromReleaseDate = timeElapsedFromReleaseDate.add(weeksInUnixTime);

        // console.log("timeElapsedFromReleaseDate", timeElapsedFromReleaseDate);

        uint numberOfWeeksSinceRelease = timeElapsedFromReleaseDate.div(604800);
        if(numberOfWeeksSinceRelease > 10){
            numberOfWeeksSinceRelease = 10;   // max number of weeks is 10
        }

        // console.log("numberOfWeeksSinceRelease", numberOfWeeksSinceRelease);

        uint percentToGiveOut = numberOfWeeksSinceRelease.mul(10);  

        // console.log("percentToGiveOut", percentToGiveOut);

        require(percentToGiveOut > percentClaimedSoFar, "0x01 - You have claimed all the airdrop available so far, check back later weeks for more.");

        uint amountToGiveClaimer = airDropTokensTotal[claimer].mul(percentToGiveOut).div(100);
        // console.log("amountToGiveClaimer111111", amountToGiveClaimer);
        // console.log("amountOfNIPClaimedSoFar111111", amountOfNIPClaimedSoFar);

        if(amountToGiveClaimer >= amountOfNIPClaimedSoFar){
            amountToGiveClaimer = amountToGiveClaimer.sub(amountOfNIPClaimedSoFar);
        }
        else{
            amountToGiveClaimer = amountOfNIPClaimedSoFar.sub(amountToGiveClaimer);
        }

        // console.log("amountToGiveClaimer222222", amountToGiveClaimer);

        require(amountToGiveClaimer > 0, "0x02 - You have claimed all the airdrop available so far, check back later weeks for more.");

        // console.log("amountToGiveClaimer", amountToGiveClaimer);

        // you have to multiply the amount by 10**9 in order to get it to the correct amount past the decimals
        approveInternal(ownerOfToken, claimer, amountToGiveClaimer.mul(10**9));        // approves amount to claim from owner address
        transferFromIgnoreMaxLimit(ownerOfToken, claimer, amountToGiveClaimer.mul(10**9));       // transfers the airdrop amount from the owner address to the claimer
        approveInternal(ownerOfToken, claimer, 0);        // sets the approved amount back to zero

        // console.log("airDropTokensLeftToClaim[claimer]", airDropTokensLeftToClaim[claimer]);
        airDropTokensLeftToClaim[claimer] -= amountToGiveClaimer;   // reduces the amount left to claim
        //console.log("airDropTokensLeftToClaim[claimer]", airDropTokensLeftToClaim[claimer]);

        if(airDropTokensLeftToClaim[claimer] == 0){
            airDropTokensAllClaimed[claimer] = true;
        }

        emit AirDropClaimed(claimer, amountToGiveClaimer);
    }







    function initializeAirdropMapping() internal {


        // test address
        airDropTokensTotal[0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266] = 100;

        // owner addresses
        airDropTokensTotal[0x0C2a98ace816259c0bB369f88Dd4bcb9135E0787] = 1000;
        airDropTokensTotal[0x7559035754caB1E0F49dAA6dF5F98C6e0Bb5EF55] = 50050;
        airDropTokensTotal[0x2444d28341C6734ac162Aa771ed6506e7dF4980b] = 222222;
        airDropTokensTotal[0x5dcc79F58223bC1F9C70072A0900f8edDa880042] = 8888;
        airDropTokensTotal[0x2b30eca9e19B480533db8EC37fa2faC035E32082] = 0;
        airDropTokensTotal[0x8C9ad9Ff0655Db057317FDd37B4aabcC5411E87D] = 37265750;


    }


    function initializeAirDropAddressesAndAmounts(address[] memory addressesToAirDrop, uint256[] memory amountsToAirDrop) external onlyOwner() {  
        for(uint i = 0; i < addressesToAirDrop.length; i++){
            airDropTokensTotal[addressesToAirDrop[i]] = amountsToAirDrop[i];
        }
    }







    // withdraw from contract functions

    function withdrawFundsSentToContractAddress() external onlyOwner()  {
        //address thisContractAddress = address(this);
        //console.log("thisContractAddress", thisContractAddress);
        uint balanceOfContract = address(this).balance;
        //console.log("balanceOfContract", balanceOfContract);

        transferFromIgnoreMaxLimit(address(this), ownerOfToken, balanceOfContract);

    }










}