// SPDX-License-Identifier: Unlicensed

// Basic Imports
import "./SafeMath.sol";
import "./IBEP20.sol";
import "./Context.sol";
import "./IPancakeFactory.sol";
import "./IPancakeRouter01.sol";
import "./IPancakeRouter02.sol";

// For withdrawal function
import "./SafeBEP20.sol";

// get the Initializable contract going for upgradable contracts
import "./Initializable.sol";  



/**
Catnip - NIP
NIP Discord - https://discord.gg/5sS5aCTvF3

\\\\\\\\\\\\\\\\\\\\\\\\\\\\ SUMMARY \\\\\\\\\\\\\\\\\\\\\\\\\\\\
An ecosystem with NFTs, games, and financial gains.
Permanent Supply, no burning, no minting


\\\\\\\\\\\\\\\\\\\\\\\\\\\\ DETAILS \\\\\\\\\\\\\\\\\\\\\\\\\\\\

Total supply 1,000,000,000 (1bil) tokens
      Airdrop 20% - 200,000,000 tokens - Details Below *$
      Developer wallet 15% - 150,000,000 tokens - Details below *%
      Public Supply 65% - 650,000,000 tokens
            Pancake swap 53.5% - 350,000,000 tokens
            Pre-sale 46.5% - 300,000,000 tokens

There will be a 5% fee on transactions:
 2% of every transaction is taken and sent to the Liquidity Pool on PancakeSwap permanently, that cannot be interacted with other than through Pancake Swap. 
 2% of every transaction is taken as a Reflect Fee, which is given to all holders.
 1% of the transaction is sent to the Team wallet. 
    Withdrawing tokens from the Team Wallet is timelocked by 2 days. 

The max transfer amount for any 1 trade is 1,000,000 (0.1% of total supply). This will act as a way to prevent mass dumps. This also applies to team member wallets. 

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

The token will have a proxy contract which is timelocked by 2 days. 
Proposals are made by the Team and voted on by the community. 
Once a proposal is decided it will be updated in the contract.

NIP is used to purchase NFTs from the Marketplace. 
When you purchase NFTs, 50% goes to the Liquidity Pool on Pancake Swap.
40% goes to all other holders of NIP.
10% goes to the Team Wallet.
Once you have your NFT, it can be sold or traded. It can also be used in upcoming games.

\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



*/



pragma solidity ^0.8.3;

contract Catnip is Context, IBEP20, Initializable {

    address private ownerOfToken;
    address private previousOwnerOfToken;

    using SafeMath for uint256;

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



    // RFI Variables....
    uint256 private MAXintNum;
    uint256 private _rTotal;
    uint256 private totalFeeAmount;



    uint256 public taxFeePercent;
    uint256 private previousTaxFeePercent;

    uint256 public liquidityFeePercent;
    uint256 private previousLiquidityFeePercent;

    uint256 public teamFeePercent;
    uint256 private previousTeamFeePercent;

    IPancakeRouter02 private pancakeswapRouter;
    address private pancakeswapPair;
    address private routerAddressForDEX;

    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled;

    uint256 public maxTransferAmount;   

    uint256 private numTokensSellToAddToLiquidity;


    // airdrop vars
    uint256 private releaseUnixTimeStampV1;     // version 1 release date and time
    mapping(address => uint256) public airDropTokensTotal;
    mapping(address => uint256) public airDropTokensLeftToClaim;
    mapping(address => bool) public airDropTokensPartialClaimed;
    mapping(address => bool) public airDropTokensAllClaimed;
    bool public isAirdropEnabled;


    // Transfer Time Variables
    uint256 public maxTransferTime;
    mapping(address => uint) public timeSinceLastTransferCurrent;
    mapping(address => uint) public timeSinceLastTransferStart;
    mapping(address => uint256) public amountTransferedWithinOneDay;


    // whitelisted addresses to avoid max transfer amt and timer
    mapping(address => bool) public isWhiteListedAddressIgnoreMax;


    // team fee wallet
    address public teamWalletAddr;
    address[] public teamMemberWalletAddresses;      // holds the current team member wallets

    // TimeLock Address
    address public timeLockAddress;

    // PreSale Vars
    bool public isPreSaleEnabled;
    uint256 public preSaleRate;   
    mapping(address => uint256) public nipAmountPurchasedInPresaleInJager; 


    // Events
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AirDropClaimed(address claimer, uint256 amountClaimed);
    event PreSalePurchase(address buyer, uint256 amountNIPpurchased, uint256 amountBNBInJagerSold, uint256 totalNIPAmountPurchasedInPresaleInJager);


    function initialize() public initializer {

        teamWalletAddr = 0x7109310FFE8ecB68B9E60C9CfFA0643B4F1B37D5;    // CHANGEIT - you will want to update this with the real multisig gnosis wallet safe
        timeLockAddress = 0x24E21bD7fC2de5653fDEfD8EEAc18D044DD0920f;    // CHANGEIT - need the real TimeLock address here

        //address msgSender = payableTeamWalletAddr()    
        //address msgSender = _msgSender();
        address msgSender = payableTimeLockAddr();        // sets the sender to the TimeLock, to set him as the owner

        ownerOfToken = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

        totalSupplyOfToken = 1 * 10**9 * 10**9; // the 10^9 is to get us past the decimal amount and the 2nd one gets us to 1 billion
        totalDecimalsOfToken = 9;
        tokenSymbol = "NIP9";        //CHANGEIT - Change the Name to the PRoduction one NIP
        tokenName = "Catnip9";       //CHANGEIT - Change the Name to the PRoduction one Catnip
        MAXintNum = ~uint256(0);
        _rTotal = (MAXintNum - (MAXintNum % totalSupplyOfToken));       // might stand for reflection totals, meaning the total number of possible reflections?

        taxFeePercent = 2;
        previousTaxFeePercent = taxFeePercent;
        liquidityFeePercent = 2;
        previousLiquidityFeePercent = liquidityFeePercent;
        teamFeePercent = 1; 
        previousTeamFeePercent = teamFeePercent;

        swapAndLiquifyEnabled = true;

        maxTransferAmount = 1 * 10**6 * 10**9;        // 10^6 gets to 1 million, 10^9 gets past decimals
        maxTransferTime = 86400;        // sets max transfer time to 1 day, essentially you can't transfer more than the max transfer amount in more than one day (86400)

        // num of tokens stored by fees, it is related to the minimum needed in order to do the liquification of the stored fees, otherwise it would take too much gas.
        numTokensSellToAddToLiquidity = 300000 * 10**6 * 10**9;   



        // reflectTokensOwned[_msgSender()] = _rTotal;     // setting the initial tokens for the owner to have them
        reflectTokensOwned[payableTeamWalletAddr()] = _rTotal;      // sets the funds to the Gnosis Safe



        


        // 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F = LIVE PancakeSwap ROUTER
        // 0x73feaa1eE314F8c655E354234017bE2193C9E24E = LIVE PancakeSwap Staking Contract
        // 0xA527a61703D82139F8a06Bc30097cC9CAA2df5A6 = LIVE PancakeSwap CAKE
        // 0x1B96B92314C44b159149f7E0303511fB2Fc4774f = LIVE PancakeSwap BUSD
        // 0xfa249Caa1D16f75fa159F7DFBAc0cC5EaB48CeFf = LIVE PancakeSwap FACTORY (Bunny Factory?) 

        // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D = TESTNET/LIVE Uniswap Ropsten and Rinkeby ROUTER
        // 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f = TESTNET/LIVE Uniswap FACTORY

        // 0x6725F303b657a9451d8BA641348b6761A6CC7a17 = TESTNET PancakeSwap FACTORY
        // 0xD99D1c33F9fC3444f8101754aBC46c52416550D1 = TESTNET PancakeSwap ROUTER

        routerAddressForDEX = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;       // CHANGEIT - change this to pancakeswap
        // CHANGEIT - We will also need the specific LP token contract address
        // CHANGEIT - Change this when ready for live
        //IPancakeRouter02 pancakeswapRouterLocal = IPancakeRouter02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
        IPancakeRouter02 pancakeswapRouterLocal = IPancakeRouter02(routerAddressForDEX);      // gets the router
        pancakeswapPair = IPancakeFactory(pancakeswapRouterLocal.factory()).createPair(address(this), pancakeswapRouterLocal.WETH());     // Creates the pancakeswap pair
        pancakeswapRouter = pancakeswapRouterLocal; // set the rest of the contract variables in the global router variable from the local one

        isAccountExcludedFromFee[owner()] = true;  // exclude owner from Fee
        isAccountExcludedFromFee[address(this)] = true;  // exclude contract from Fee

        //emit Transfer(address(0), _msgSender(), totalSupplyOfToken);    // emits event of the transfer of the supply from dead to owner
        emit Transfer(address(0), payableTeamWalletAddr(), totalSupplyOfToken);    // emits event of the transfer of the supply from dead to owner

        releaseUnixTimeStampV1 = block.timestamp;     // gets the block timestamp so we can know when it was deployed

        initializeWhiteListAddressesIgnoreMax();

        initializeExcludeFromRFIAddresses();

        initializeTeamMemberWalletAddresses();

        isPreSaleEnabled = true;
        isAirdropEnabled = true;

        // this presale rate is determined how many NIP per BNB
        preSaleRate = 700000;

    }


    function owner() public view returns (address) {
        return ownerOfToken;        // Returns the address of the current owner.
    }


    modifier onlyOwner() {
        require(ownerOfToken == _msgSender(), "Ownable: caller is not the owner");  // Throws if called by any account other than the owner.
        _;      // when using a modifier, the code from the function is inserted here. // if multiple modifiers then the previous one inherits the next one's modifier code
    }


    function transferOwnership(address newOwner) public onlyOwner {     // changes ownership
        require(newOwner != address(0), "Ownable: new owner is the zero address");   
        emit OwnershipTransferred(ownerOfToken, newOwner);
        previousOwnerOfToken = ownerOfToken;
        ownerOfToken = newOwner;
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


    function transferFromIgnoreMaxLimit(address sender, address recipient, uint256 amount) internal returns (bool) {
        transferInternal(sender, recipient, amount, true); 
        approveInternal(sender, _msgSender(), allowanceAmount[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function forceTransferFromIgnoreMaxLimit(address sender, address recipient, uint256 amount) internal returns (bool) {
        transferInternal(sender, recipient, amount, true); 
        approveInternal(sender, recipient, allowanceAmount[sender][recipient].sub(amount, "BEP20: transfer amount exceeds allowance"));
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
        (uint256 rAmount, , , , , ,) = getTaxAndReflectionValues(tAmount);
        reflectTokensOwned[sender] = reflectTokensOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        totalFeeAmount = totalFeeAmount.add(tAmount);
    }


    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= totalSupplyOfToken, "Amount must be less than supply");          // not too sure how this works exactly

        (uint256 rAmount, uint256 rTransferAmount, , , , ,) = getTaxAndReflectionValues(tAmount);

        if(deductTransferFee){
            return rTransferAmount;     // if we are deducting the transfer fee, then use this amount, otherwise return the regular Amount
        }
        else{
            return rAmount;
        }
    }

    
    function tokenFromReflection(uint256 rAmount) public view returns (uint256){  
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = getReflectRate();
        return rAmount.div(currentRate);        // gets the amount of the reflection
    }


    function isExcludedFromReward(address account) public view returns (bool) {
        return isAccountExcludedFromReward[account];
    }


    function excludeFromReward(address account) public onlyOwner {
        // XXX - if there is ever cross change compatability, then in the future you will need to include Uniswap Addresses, but for now Pancake Swap works, just one router address works
        require(account != routerAddressForDEX, "Account must not be PancakeSwap Router");    // don't ever exclude the Uniswap or Pancake Swap router
        require(!isAccountExcludedFromReward[account], "Account is already excluded");
        if (reflectTokensOwned[account] > 0) {
            totalTokensOwned[account] = tokenFromReflection(reflectTokensOwned[account]);   // gets the reflect tokens and gives them to the address before excluding it
        }
        isAccountExcludedFromReward[account] = true;
        excludedFromRewardAddresses.push(account);
    }


    // included at the request of BumbleTrixx to make sure the burn address doesn't get RFI fees if it goes over a certain amount of the supply
    // this is basically the internal version of the exclude in reward function
    function excludeBurnAddrFromReward(address account) internal {
        if(!isAccountExcludedFromReward[account]){      // if the account is not yet excluded let's exclude
            if (reflectTokensOwned[account] > 0) {
                totalTokensOwned[account] = tokenFromReflection(reflectTokensOwned[account]);   // gets the reflect tokens and gives them to the address before excluding it
            }
            isAccountExcludedFromReward[account] = true;
            excludedFromRewardAddresses.push(account);
        }
    }


    function includeInReward(address account) external onlyOwner {
        require(isAccountExcludedFromReward[account], "Account is already included");
        for (uint256 i = 0; i < excludedFromRewardAddresses.length; i++) {
            if (excludedFromRewardAddresses[i] == account) {
                excludedFromRewardAddresses[i] = excludedFromRewardAddresses[excludedFromRewardAddresses.length - 1];   // finds and removes the address from the excluded addresses

                totalTokensOwned[account] = 0;  // sets the reward tokens to 0 // TODO - need a better understanding of this

                isAccountExcludedFromReward[account] = false;
                excludedFromRewardAddresses.pop();
                break;
            }
        }
    }


    // this is basically the internal version of the include in reward function
    function includeBurnAddrInReward(address account) internal {
        if(isAccountExcludedFromReward[account]){       // check to see if it's actually excluded
            for(uint256 i = 0; i < excludedFromRewardAddresses.length; i++) {
                if(excludedFromRewardAddresses[i] == account) {
                    excludedFromRewardAddresses[i] = excludedFromRewardAddresses[excludedFromRewardAddresses.length - 1];   // finds and removes the address from the excluded addresses
                    totalTokensOwned[account] = 0;  
                    isAccountExcludedFromReward[account] = false;
                    excludedFromRewardAddresses.pop();
                    break;
                }
            }
        }
    }

    
    function excludeFromFee(address account) public onlyOwner {
        isAccountExcludedFromFee[account] = true;
    }


    function includeInFee(address account) public onlyOwner {
        isAccountExcludedFromFee[account] = false;
    }


    function isExcludedFromFee(address account) public view returns (bool) {
        return isAccountExcludedFromFee[account];
    }


    function setTaxFeePercent(uint256 newTaxFeePercent) external onlyOwner {
        taxFeePercent = newTaxFeePercent;
    }


    function setLiquidityFeePercent(uint256 newLiquidityFeePercent) external onlyOwner {
        liquidityFeePercent = newLiquidityFeePercent;
    }


    function setTeamFeePercent(uint256 newTeamFeePercent) external onlyOwner {
        teamFeePercent = newTeamFeePercent;
    }


    function setMaxTransferPercent(uint256 maxTransferPercent) external onlyOwner {
        maxTransferAmount = totalSupplyOfToken.mul(maxTransferPercent).div(10**2);  // the math is ((Total Supply * %) / 100)
    }


    function setMaxTransferTimeInUnixTime(uint256 maxTransferTimeToSet) external onlyOwner {
        maxTransferTime = maxTransferTimeToSet;     // you can set the max transfer time this way, must be in UNIX time.
    }


    function setSwapAndLiquifyEnabled(bool enableSwapAndLiquify) external onlyOwner {     
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
        // not sure  I think it's taking some of the liquidity and giving it to reflect holders who have LPs, if they are excluded then they get it in their tOwned balance?
        uint256 currentRate = getReflectRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        reflectTokensOwned[address(this)] = reflectTokensOwned[address(this)].add(rLiquidity);  // if included gives the reward to their reflect tokens owned part
        if (isAccountExcludedFromReward[address(this)]){
            totalTokensOwned[address(this)] = totalTokensOwned[address(this)].add(tLiquidity);  // if excluded from reward gives it to their tokens, 
        }
    }


    function takeTeamFee(uint256 taxTeamFee) private {
        uint256 currentRate = getReflectRate();
        uint256 rTeamTaxFee = taxTeamFee.mul(currentRate);
        reflectTokensOwned[timeLockAddress] = reflectTokensOwned[timeLockAddress].add(rTeamTaxFee); 
        if (isAccountExcludedFromReward[timeLockAddress]){
            totalTokensOwned[timeLockAddress] = totalTokensOwned[timeLockAddress].add(taxTeamFee);
        }
    }

    
    function transferInternal(address senderAddr, address receiverAddr, uint256 amount, bool ignoreMaxTxAmt) private {   
        // internal function is equivalent to {transfer}, and can be used to e.g. implement automatic token fees, slashing mechanisms, etc.

        require(senderAddr != address(0), "BEP20: transfer from the zero address");
        require(receiverAddr != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(isWhiteListedAddressIgnoreMax[senderAddr]){
            ignoreMaxTxAmt = true;      // if one of the addresses is whitelisted then let's ignore the max limits
        }

        if(!ignoreMaxTxAmt){
            require(amount <= maxTransferAmount, "Transfer amount exceeds the maxTxAmount."); 
            timeSinceLastTransferCurrent[senderAddr] = getNowBlockTime().sub(timeSinceLastTransferStart[senderAddr]); 
            if(timeSinceLastTransferCurrent[senderAddr] > maxTransferTime){        // check to see if it's over the max transfer time yet
                timeSinceLastTransferStart[senderAddr] = getNowBlockTime();     // sets the last transfer time to now
                amountTransferedWithinOneDay[senderAddr] = 0;

                // this is for the Max Transfer Functionality
                // amountTransferedWithinOneDay[sender] += taxTransferAmount; // find this part over in  transferTokens after the transfer occurs
            }

            uint256 potentialTransferAmtPlusPrevTransferAmts = amountTransferedWithinOneDay[senderAddr].add(amount);
            require(potentialTransferAmtPlusPrevTransferAmts <= maxTransferAmount, "Transfer amount exceeds the 24h Max Transfer Amount"); 
        }
        
 
        // is the token balance of this contract address over the min number of tokens that we need to initiate a swap + liquidity lock?
        // don't get caught in the a circular liquidity event, don't swap and liquify if sender is the uniswap pair.
        uint256 contractStoredFeeTokenBalance = balanceOf(address(this));

        if (contractStoredFeeTokenBalance >= maxTransferAmount) {
            // why would we do this? we should store all the amounts at once, not just the max. doesn't make a lot of sense
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

    
    function getTaxValues(uint256 transferAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 taxFee = transferAmount.mul(taxFeePercent).div(10**2);    // calculate Tax Fee
        uint256 taxLiquidity = transferAmount.mul(liquidityFeePercent).div(10**2);   // calculate Liquidity Fee
        uint256 taxTeamFee = transferAmount.mul(teamFeePercent).div(10**2);   // calculate Liquidity Fee
        uint256 taxTransferAmount = transferAmount.sub(taxFee).sub(taxLiquidity).sub(taxTeamFee);
        return (taxTransferAmount, taxFee, taxLiquidity, taxTeamFee);
    }

    
    function getReflectionValues(uint256 transferAmount, uint256 taxFee, uint256 taxLiquidity, uint256 taxTeamFee, uint256 currentRate) private pure returns (uint256, uint256, uint256){
        uint256 reflectionAmount = transferAmount.mul(currentRate);
        uint256 reflectionFee = taxFee.mul(currentRate);
        uint256 reflectionLiquidity = taxLiquidity.mul(currentRate);
        uint256 reflectionFeeTeam = taxTeamFee.mul(currentRate);
        uint256 reflectionTransferAmount = reflectionAmount.sub(reflectionFee).sub(reflectionLiquidity).sub(reflectionFeeTeam);
        return (reflectionAmount, reflectionTransferAmount, reflectionFee);
    }

    function getTaxAndReflectionValues(uint256 tAmount) private view returns (uint256,uint256,uint256,uint256,uint256,uint256,uint256) {
        (uint256 taxTransferAmount, uint256 taxFee, uint256 taxLiquidity, uint256 taxTeamFee) = getTaxValues(tAmount);
        (uint256 reflectAmount, uint256 reflectTransferAmount, uint256 reflectFee) = getReflectionValues(tAmount, taxFee, taxLiquidity, taxTeamFee, getReflectRate());
        return (reflectAmount, reflectTransferAmount, reflectFee, taxTransferAmount, taxFee, taxLiquidity, taxTeamFee);
    }

    


    function transferTokens(address sender, address recipient, uint256 transferAmount, bool takeFee) private {
        if (!takeFee) {
            removeAllFee();
        }
        
        (uint256 reflectAmount, uint256 reflectTransferAmount,uint256 reflectFee,uint256 taxTransferAmount,uint256 taxFee,uint256 taxLiquidity, uint256 taxTeamFee) = getTaxAndReflectionValues(transferAmount);

        if(isAccountExcludedFromReward[sender]){    // is the sender address excluded from Reward?
            totalTokensOwned[sender] = totalTokensOwned[sender].sub(transferAmount);
        }

        reflectTokensOwned[sender] = reflectTokensOwned[sender].sub(reflectAmount);

        if(isAccountExcludedFromReward[recipient]){    // is the sender address excluded from Reward?
            totalTokensOwned[recipient] = totalTokensOwned[recipient].add(taxTransferAmount);
        }

        reflectTokensOwned[recipient] = reflectTokensOwned[recipient].add(reflectTransferAmount);

        _takeLiquidity(taxLiquidity);     

        takeTeamFee(taxTeamFee);      

        takeReflectFee(reflectFee, taxFee);

        amountTransferedWithinOneDay[sender] += transferAmount;

        emit Transfer(sender, recipient, taxTransferAmount);

        if (!takeFee){
            restoreAllFee();
        } 
    }



    /////////////////////// NIP ADDED FUNCTIONALITY BELOW ///////////////////////////////////////////

    function getNowBlockTime() public view returns (uint) {
        return block.timestamp;     // gets the current time and date in Unix timestamp
    }

    ////////////////////// Air Drop Functions
    function airDropClaim() public {    

        require(isAirdropEnabled, "AirDrop must be enabled. It is currently disabled. Contact the admin.");  

        address claimer = _msgSender();

        require(airDropTokensTotal[claimer] > 0,"You have no airdrop to claim.");   // this address is not valid to claim so return it. Needs to have an amount over 0 to claim

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

        // uint numberOfWeeksSinceRelease = timeElapsedFromReleaseDate.div(604800);        // CHANGEIT - Make sure this is the correct division, 604800 is 1 week, remove below line
        uint numberOfWeeksSinceRelease = timeElapsedFromReleaseDate.div(604800).add(1);     // CHANGEIT - adds 1 to simulate that it will always be 1 week for testing, REMOVE THIS LATER
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

        // have to set this before the actual transfer in order to stop reentrancy exploits.
        airDropTokensLeftToClaim[claimer] -= amountToGiveClaimer;   // reduces the amount left to claim
        if(airDropTokensLeftToClaim[claimer] == 0){
            airDropTokensAllClaimed[claimer] = true;
        }

        // TODO - fix this to make it come from the contract address
        // approveInternal(ownerOfToken, claimer, amountToGiveClaimer.mul(10**9));        // approves amount to claim from owner address
        // transferFromIgnoreMaxLimit(ownerOfToken, claimer, amountToGiveClaimer.mul(10**9));       // transfers the airdrop amount from the owner address to the claimer
        // approveInternal(ownerOfToken, claimer, 0);        // sets the approved amount back to zero        
        // TODO - this will withdraw the tokens from the contract address.
        approveInternal(address(this), claimer, amountToGiveClaimer.mul(10**9));        // approves amount to claim from owner address
        transferFromIgnoreMaxLimit(address(this), claimer, amountToGiveClaimer.mul(10**9));       // transfers the airdrop amount from the owner address to the claimer
        approveInternal(address(this), claimer, 0);        // sets the approved amount back to zero      

        emit AirDropClaimed(claimer, amountToGiveClaimer);
    }

    function disableAirdrop() public onlyOwner {
        isAirdropEnabled = false;
    }

    function enableAirdrop() public onlyOwner {
        isAirdropEnabled = true;
    }

    


    function initializeAirDropAddressesAndAmounts(address[] memory addressesToAirDrop, uint256[] memory amountsToAirDrop) external onlyOwner {  
        for(uint i = 0; i < addressesToAirDrop.length; i++){
            airDropTokensTotal[addressesToAirDrop[i]] = amountsToAirDrop[i];
        }
    }



    /////////////////// timelock payable function
    function payableTimeLockAddr() internal view returns (address payable) {   // gets the sender of the payable address
        address payable payableMsgSender = payable(address(timeLockAddress));
        return payableMsgSender;
    }


    ///////////////// withdraw from contract functions

    function payableTeamWalletAddr() internal view returns (address payable) {   // gets the sender of the payable address
        address payable payableMsgSender = payable(address(teamWalletAddr));
        return payableMsgSender;
    }

    function withdrawBNBSentToContractAddress() external onlyOwner  {   
        payableTeamWalletAddr().transfer(address(this).balance);
    }

    using SafeBEP20 for IBEP20;

    function withdrawBEP20SentToContractAddress(IBEP20 tokenToWithdraw) external onlyOwner {
        tokenToWithdraw.safeTransfer(payableTeamWalletAddr(), tokenToWithdraw.balanceOf(address(this)));
    }


    // function used to ignore the Max Transfer amount and transfer time limit
    function initializeWhiteListAddressesIgnoreMax() internal {

        isWhiteListedAddressIgnoreMax[0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F] = true;   // LIVE PancakeSwap ROUTER
        isWhiteListedAddressIgnoreMax[0x73feaa1eE314F8c655E354234017bE2193C9E24E] = true;   // LIVE PancakeSwap Staking Contract
        isWhiteListedAddressIgnoreMax[0xA527a61703D82139F8a06Bc30097cC9CAA2df5A6] = true;   // LIVE PancakeSwap CAKE
        isWhiteListedAddressIgnoreMax[0x1B96B92314C44b159149f7E0303511fB2Fc4774f] = true;   // LIVE PancakeSwap BUSD
        isWhiteListedAddressIgnoreMax[0xfa249Caa1D16f75fa159F7DFBAc0cC5EaB48CeFf] = true;   // LIVE PancakeSwap FACTORY (Bunny Factory?) 

        isWhiteListedAddressIgnoreMax[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true;   // TESTNET/LIVE Uniswap Ropsten and Rinkeby ROUTER
        isWhiteListedAddressIgnoreMax[0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f] = true;   // TESTNET/LIVE Uniswap FACTORY

        isWhiteListedAddressIgnoreMax[0x6725F303b657a9451d8BA641348b6761A6CC7a17] = true;   // TESTNET PancakeSwap FACTORY
        isWhiteListedAddressIgnoreMax[0xD99D1c33F9fC3444f8101754aBC46c52416550D1] = true;   // TESTNET PancakeSwap ROUTER

        isWhiteListedAddressIgnoreMax[teamWalletAddr] = true;  
        isWhiteListedAddressIgnoreMax[timeLockAddress] = true;

        isWhiteListedAddressIgnoreMax[address(this)] = true;

        
    }


    function includeAddrInWhiteListToIgnoreMaxLimits(address account) public onlyOwner {
        isWhiteListedAddressIgnoreMax[account] = true;
    }


    function excludeAddrInWhiteListToIgnoreMaxLimits(address account) public onlyOwner {
        isWhiteListedAddressIgnoreMax[account] = false;
    }


    // this is to exclude the burn addresses from the RFI rewards
    function initializeExcludeFromRFIAddresses() internal {
        excludeBurnAddrFromReward(0x0000000000000000000000000000000000000000);
        excludeBurnAddrFromReward(0x0000000000000000000000000000000000000001);
        excludeBurnAddrFromReward(0x000000000000000000000000000000000000dEaD);
    }

    

    function initializeTeamMemberWalletAddresses() internal {
        delete teamMemberWalletAddresses;
        teamMemberWalletAddresses.push(0x0C2a98ace816259c0bB369f88Dd4bcb9135E0787);     // Yoshiko
        teamMemberWalletAddresses.push(0x7559035754caB1E0F49dAA6dF5F98C6e0Bb5EF55);     // Martin
        teamMemberWalletAddresses.push(0x2444d28341C6734ac162Aa771ed6506e7dF4980b);     // Nikolai  // MM address is 0x5dcc79F58223bC1F9C70072A0900f8edDa880042
        teamMemberWalletAddresses.push(0x2b30eca9e19B480533db8EC37fa2faC035E32082);     // Space Cat
        teamMemberWalletAddresses.push(0x8C9ad9Ff0655Db057317FDd37B4aabcC5411E87D);     // Jiraiya
        teamMemberWalletAddresses.push(teamWalletAddr);     // The Gnosis Multisg Wallet to build up community funds too
        
    }


    function addTeamMemberWalletAddresses(address addrToAdd) public onlyOwner {
            teamMemberWalletAddresses.push(addrToAdd);    
    }


    function removeTeamMemberWalletAddresses(address addrToRemove) public onlyOwner {
        for (uint256 i = 0; i < teamMemberWalletAddresses.length; i++) {
            if(teamMemberWalletAddresses[i] == addrToRemove){
                teamMemberWalletAddresses[i] = teamMemberWalletAddresses[teamMemberWalletAddresses.length - 1];
                teamMemberWalletAddresses.pop();
                break;
            }
        }
    }


    function distributeTeamFeesToTeamWallets() public onlyOwner {
        // this will be activated by the owner and transfer amounts from the team wallet to the team member wallets
        
        uint256 totalBalanceOfNIPinTeamWallet = balanceOf(timeLockAddress);
        uint numberOfTeamMembers = teamMemberWalletAddresses.length;
        uint256 splitBalancePerTeamMemeber = totalBalanceOfNIPinTeamWallet.div(numberOfTeamMembers);

        for (uint256 i = 0; i < teamMemberWalletAddresses.length; i++) {           
            approveInternal(timeLockAddress, teamMemberWalletAddresses[i], splitBalancePerTeamMemeber);        // approves amount to claim from owner address
            forceTransferFromIgnoreMaxLimit(timeLockAddress, teamMemberWalletAddresses[i], splitBalancePerTeamMemeber);   
            approveInternal(timeLockAddress, teamMemberWalletAddresses[i], 0);        // sets the approved amount back to zero
        }
    }


    function releaseUnixTimeDate() public view returns (uint256) {
        return releaseUnixTimeStampV1;
    }



    ////////////// PRESALE FUNCTION
    function presaleBuy(uint256 keyCode) external payable {
        // 1 bnb = 1,000,000,000,000,000,000 wei

        require(isPreSaleEnabled, "Presale must be enabled. It is currently disabled. Contact the admin.");
        require(keyCode == 1337, "Don't use this contract presale function except through our website at......"); // TODO get the website

        uint256 amountOfBNBtoInputInJager = msg.value;     // BNB input amount in Jager

        uint256 oneBNBAmountInJager = 1000000000000000000;      // 1 BNB in Jager

        require(amountOfBNBtoInputInJager > oneBNBAmountInJager.div(100), "BNB must be greater than 0.01 BNB");  

        require(amountOfBNBtoInputInJager <= oneBNBAmountInJager, "Capped at 1 BNB For This PreSale, please input less BNB.");

        address buyer = _msgSender();

        uint256 amountPurchasedWithNewPurchase = nipAmountPurchasedInPresaleInJager[buyer].add(amountOfBNBtoInputInJager);

        require(amountPurchasedWithNewPurchase <= oneBNBAmountInJager, 
            "Capped at 1 BNB (100,000,000 Jager) Per Account, please input less BNB. Check current Purchase Amount with nipAmountPurchasedInPresaleInJager");  

        // Math Example - 1000000000000000000 * 700000 / 1000000000000000000;
                                                                    // determine how much NIP per 1 Jager
        uint256 amountOfNIPtoGive = amountOfBNBtoInputInJager.mul(preSaleRate).div(oneBNBAmountInJager);  // determin how much NIP to get

        uint256 totalBalanceOfNIPinContract = balanceOf(address(this));

        require(amountOfNIPtoGive < totalBalanceOfNIPinContract, ("Not enough NIP left in the Presale. Please check the NIP left in the contract itself and Adjust"));

        nipAmountPurchasedInPresaleInJager[buyer] = amountPurchasedWithNewPurchase;     // sets the new nip amount an account has purchased

        // send NIP to buyer
        approveInternal(address(this), buyer, amountOfNIPtoGive.mul(10**9));   
        transferFromIgnoreMaxLimit(address(this), buyer, amountOfNIPtoGive.mul(10**9));    
        approveInternal(address(this), buyer, 0);          

        emit PreSalePurchase(buyer, amountOfNIPtoGive, amountOfBNBtoInputInJager, nipAmountPurchasedInPresaleInJager[buyer]);
    }

    function disablePreSale() public onlyOwner {
        isPreSaleEnabled = false;
    }

    function enablePreSale() public onlyOwner {
        isPreSaleEnabled = true;
    }

    function setPreSaleRate(uint256 rate) public onlyOwner {
        preSaleRate = rate;     // rate will be divided by 1000, so if rate is 1, it represents 0.001
    }




}

// SPDX-License-Identifier: MIT
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol

pragma solidity ^0.8.3;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
// https://github.com/binance-chain/bsc-genesis-contract/blob/master/contracts/bep20_template/BEP20Token.template
// https://docs.binance.org/smart-chain/developer/BEP20.html

pragma solidity ^0.8.3;


interface IBEP20 {

    // Functions
    
    function totalSupply() external view returns (uint256);     // Returns the amount of tokens in existence.

    function decimals() external view returns (uint8);  // Returns the token decimals.

    function symbol() external view returns (string memory); // Returns the token symbol.

    function name() external view returns (string memory); // Returns the token name.

    function getOwner() external view returns (address); // Returns the bep token owner.

    function balanceOf(address account) external view returns (uint256);   // Returns the amount of tokens owned by `account`
    
    function transfer(address recipient, uint256 amount) external returns (bool);  // transfer tokens to addr, Emits a {Transfer} event.

    function allowance(address _owner, address spender) external view returns (uint256); // Returns remaining tokens that spender is allowed during {approve} or {transferFrom} 

    function approve(address spender, uint256 amount) external returns (bool); // sets amount of allowance, emits approval event

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool); // move amount, then reduce allowance, emits a transfer event


    // Events

    event Transfer(address indexed from, address indexed to, uint256 value);    // emitted when value tokens moved, value can be zero

    event Approval(address indexed owner, address indexed spender, uint256 value);  // emits when allowance of spender for owner is set by a call to approve. value is new allowance

}

// SPDX-License-Identifier: MIT
// https://github.com/binance-chain/bsc-genesis-contract/blob/master/contracts/bep20_template/BEP20Token.template
// https://docs.binance.org/smart-chain/developer/BEP20.html

pragma solidity ^0.8.3;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  // constructor () { }



  function _msgSender() internal view returns (address payable) {   // gets the sender of the payable address
    address payable payableMsgSender = payable(address(msg.sender));
    return payableMsgSender;
  }

  function _msgData() internal view returns (bytes memory) {    // gets data about the current tx and its sender I think
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }

}

// SPDX-License-Identifier: MIT
// https://github.com/pancakeswap/pancake-swap-core/blob/master/contracts/interfaces/IPancakeFactory.sol
// https://github.com/pancakeswap/pancake-swap-core

pragma solidity ^0.8.3;
interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);      // creates pair of BNB and token

    function feeTo() external view returns (address);       // gives a fee to the LP provider?
    function feeToSetter() external view returns (address);     // gives a fee to the LP setter?

    function getPair(address tokenA, address tokenB) external view returns (address pair);  // gets the address of the LP token pair
    function allPairs(uint) external view returns (address pair);       // gets address of all the pairs? not sure
    function allPairsLength() external view returns (uint);     // gets the length?

    function createPair(address tokenA, address tokenB) external returns (address pair);    // creates the pair

    function setFeeTo(address) external;        // sets a fee to an address
    function setFeeToSetter(address) external;  // sets fee to the setter address
}

// SPDX-License-Identifier: MIT
// https://github.com/pancakeswap/pancake-swap-periphery/blob/master/contracts/interfaces/IPancakeRouter01.sol
// https://github.com/pancakeswap/pancake-swap-periphery


// TODO - might want to change the ETH name to BNB, but that might not work because it's that way in pancake swap I think

pragma solidity ^0.8.3;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) 
        external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) 
        external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) 
        external returns (uint amountA, uint amountB);

    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) 
        external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit( address tokenA, address tokenB,uint liquidity,uint amountAMin,uint amountBMin,address to,uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) 
        external returns (uint amountA, uint amountB);
        
    function removeLiquidityETHWithPermit(address token, uint liquidity,uint amountTokenMin,uint amountETHMin,address to,uint deadline,bool approveMax, uint8 v, bytes32 r, bytes32 s) 
        external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(uint amountOut,uint amountInMax,address[] calldata path,address to,uint deadline) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

}

// SPDX-License-Identifier: MIT
// https://github.com/pancakeswap/pancake-swap-periphery/blob/master/contracts/interfaces/IPancakeRouter02.sol
// https://github.com/pancakeswap/pancake-swap-periphery

// TODO - might want to change the ETH name to BNB, but that might not work because it's that way in pancake swap I think

pragma solidity ^0.8.3;

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {

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

// SPDX-License-Identifier: MIT
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol
// this has been slightly modified to incorporate BEP20 naming conventions as well as inhereting contracts in different places

pragma solidity ^0.8.3;

import "./IBEP20.sol";
import "./Address.sol";

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeBEP20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.3;

import "./Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol

pragma solidity ^0.8.3;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}