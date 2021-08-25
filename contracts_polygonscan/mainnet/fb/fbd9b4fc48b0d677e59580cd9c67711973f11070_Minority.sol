// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./SwapInterfaces.sol";
import "./MinorityShared.sol";
import "./MinorityLiquidityManager.sol";
import "./MinorityVestingManager.sol";
import "./MinorityPresale.sol";

/**
 * The Minority token.
 * Transfers fees to holders, a treasury wallet and a reward wallet
 * Automatically adds Minority-USDC liquidity to Quickswap
 */
contract Minority is Context, IERC20, Ownable, MinorityShared {
    using SafeMath for uint256;
    using SafeMath for uint8;
    
    MinorityLiquidityManager public minorityLiquidityManager;
    MinorityVestingManager public minorityVestingManager;
    MinorityPresale public minorityPresale;

    mapping (address => uint256) private reflectiveBalances;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;

    mapping (address => bool) private isExcludedFromFee;

    mapping (address => bool) private isExcluded;
    address[] private excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant TOTAL_SUPPLY = 2000000000 * 10**DECIMALS; // 2 billion total supply
    uint256 private reflectiveTotal = (MAX - (MAX % TOTAL_SUPPLY));
    
    uint256 private constant LIQUIDITY_TOKENS_TO_VEST = 600000000 * 10**DECIMALS;
    uint256 private constant MPA_TREASURY_TOKENS_TO_VEST = 240000000 * 10**DECIMALS;
    uint256 private constant MARKETING_TOKENS_TO_VEST = 100000000 * 10**DECIMALS;
    uint256 private constant DAPP_TOKENS_TO_VEST = 100000000 * 10**DECIMALS;
    uint256 private constant THINKTANK_TOKENS_TO_VEST = 20000000 * 10**DECIMALS;
    uint256 public tokensToVest = LIQUIDITY_TOKENS_TO_VEST.add(MPA_TREASURY_TOKENS_TO_VEST).add(MARKETING_TOKENS_TO_VEST).add(DAPP_TOKENS_TO_VEST).add(THINKTANK_TOKENS_TO_VEST);
    uint256 public constant TOKENS_FOR_PRESALE = 100000000 * 10**DECIMALS;
    uint256 public constant TOKENS_FOR_POST_PRESALE_LP = 80000000 * 10**DECIMALS;

    string private constant NAME = "MinTest2";
    string private constant SYMBOL = "MT2";
    uint8 private constant DECIMALS = 18;
    
    uint8 public reflectionFee = 2; // 2% of each transaction redistributed to all existing holders via reflection
    uint8 public liquidityFee = 2; // 2% of each transaction added to LP Pool. The LP adding is only executed when a sell occurs and the contract balance > MIN_CONTRACT_BALANCE_TO_ADD_LP
    uint8 public burnFee = 2; // 2% of each transaction sent to burn address
    uint8 public treasuryFee = 2; // 2% of each transaction sent to Treasury Wallet
    uint8 public rewardFee = 2; // 2% of each transaction sent to Reward Wallet
    uint256 public totalTxFees = reflectionFee.add(liquidityFee).add(burnFee).add(treasuryFee).add(rewardFee); // Makes some calculations easier. Capped at 25 in setFeePercentages
    
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD; // NOTE: no quotes round the address
    address public treasuryWallet = 0x3b31f5Cc5136F859c8C74eC1Bf8275A51709952B; // used MPA Treasury address from sheet
    address public rewardWallet = 0x19D3aE69b2170e9F37e3090d08a13fb2F2F2bE21; //
    address public marketingWallet = 0x7b85cC48CaE1eeaE0c533D717decAEA8d418d1d3;
    address public dappWallet = 0x8D8A151ACB9B7556497C27A13bb454299333aBb6;
    address public thinkTankWallet = 0x1b4340F1e1E19c794AE532Be142AD1327C9c4654;
    
    ISwapRouter02 public swapRouter;
    address public swapPair;
    
    bool public swapAndLiquifyEnabled = true;
    
    uint256 public maxTxAmount = TOTAL_SUPPLY.div(100); // CHANGEME - suggested 1% total supply (20,000,000 tokens)
    uint256 private constant MIN_CONTRACT_BALANCE_TO_ADD_LP = 200 * 10**DECIMALS; // CHANGEME - suggested 20,000 tokens = $200 at initial Mcap - if the tokenomics are changed to reduce this mcap then would change accordingly
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 minorityTokensAdded, uint256 usdcAdded, uint256 lpTokensCreated);
    event ExcludedFromReward(address indexed account);
    event IncludedInReward(address indexed account);
    event ExcludedFromFee(address indexed account);
    event IncludedInFee(address indexed account);
    event FeesChanged (uint256 oldReflectionFee, uint256 newReflectionFee, uint256 oldLiquidityFee, uint256 newLiquidityFee, 
                        uint256 oldTreasuryFee, uint256 newTreasuryFee, uint256 oldBurnFee, uint256 newBurnFee, uint256 oldRewardFee, uint256 newRewardFee);
    event MaxTxAmountChanged (uint256 oldMaxTxAmount, uint256 newMaxTxAmount);
    
    constructor () {
        swapRouter = ISwapRouter02 (ROUTER); 
        swapPair = ISwapFactory (swapRouter.factory()).createPair(address(this), USDC); // Create a Minority -> USDC LP pair
        minorityLiquidityManager = new MinorityLiquidityManager();
        minorityVestingManager = new MinorityVestingManager (_msgSender(), address(this));
        minorityPresale = new MinorityPresale (_msgSender());
        
        //exclude owner, this contract and fee wallets from fee - CHANGEME may need to add more wallets to this
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[address(minorityLiquidityManager)] = true;
        isExcludedFromFee[address(minorityVestingManager)] = true;
        isExcludedFromFee[address(minorityPresale)] = true;
        isExcludedFromFee[treasuryWallet] = true;
        isExcludedFromFee[rewardWallet] = true;
        isExcludedFromFee[BURN_ADDRESS] = true; // Manual burns exempt from fees
        isExcluded[swapPair] = true;
        excluded.push(swapPair); // Stop skimming
        isExcluded[address(minorityVestingManager)] = true;
        excluded.push(address(minorityVestingManager)); // Vesting manager needs immutable amounts to process, and won't process reflected amounts
        isExcluded[address(minorityPresale)] = true;
        excluded.push(address(minorityPresale)); // Presale needs immutable amounts to process, and won't process reflected amounts - unlikely there will be reflections before presale ends, but do this just in case
        
        // distribute initial tokens
        uint256 tokensToPresale = TOKENS_FOR_PRESALE.add(TOKENS_FOR_POST_PRESALE_LP);
        balances[address(minorityPresale)] = tokensToPresale;
        emit Transfer (address(0), address(minorityPresale), tokensToPresale);
        balances[address(minorityVestingManager)] = tokensToVest;
        emit Transfer (address(0), address(minorityVestingManager), tokensToVest);
        uint256 tokensToDeployer = TOTAL_SUPPLY.sub(tokensToVest).sub(TOKENS_FOR_PRESALE).sub(TOKENS_FOR_POST_PRESALE_LP);
        uint256 currentRate = reflectiveTotal.div(tokensToDeployer);
        reflectiveBalances[_msgSender()] = tokensToDeployer.mul(currentRate); // Transfer all tokens to the contract creator
        emit Transfer (address(0), _msgSender(), tokensToDeployer);
        
        // set up presale
        minorityPresale.setUpPresale (
            100,                            // rate - 100 Minority to 1 USDC. Decimals are the same therefore this is easy to calculate
            BURN_ADDRESS,                   // address who should own any funds to distribute. In the case all funds go to LP, the address that owns the LP tokens - CHANGEME
            address(this),                  // token to sell
            1000000 * 10**DECIMALS,         // hardcap in payment token (1m USDC)
            500000 * 10**DECIMALS,          // softcap in payment token (500k USDC)
            25000 * 10**DECIMALS,           // individual cap in payment token (25k USDC)
            USDC,                           // payment token (USDC)
            block.timestamp,    // opening time - set to 10 years in the future intentionally - this can be changed by the token deployer by calling changePresaleTimings, or configured here pre-deploy - CHANGEME
            block.timestamp + 3651 days,    // closing time - set to 10 years in the future intentionally - this can be changed by the token deployer by calling changePresaleTimings, or configured here pre-deploy CHANGEME
            TOKENS_FOR_POST_PRESALE_LP,     // number of tokens to pair with received funds and add to the LP post-presale
            100,                            // percent of funds to add to the LP post-presale
            false                           // don't check the presale contract owns the right number of tokens - we've calculated this above, and this will fail if done in the same transaction
        );
        
        // set vesting
        minorityVestingManager.addVestingSchedule (LIQUIDITY_TOKENS_TO_VEST, 2, 5, 0, address(minorityLiquidityManager), false); // startTime set to 0 - this should be modified once the presale has finished - CHANGEME
        minorityVestingManager.addVestingSchedule (MPA_TREASURY_TOKENS_TO_VEST, 2, 30, block.timestamp, treasuryWallet, false); // starts now, 2% every 30 days. Address may need modifying (MPA Treasury Vest) - CHANGEME
        minorityVestingManager.addVestingSchedule (MARKETING_TOKENS_TO_VEST, 4, 30, block.timestamp, marketingWallet, false); // starts now, 4% every 30 days. Address may need modifying (Marketing Vest) - CHANGEME
        minorityVestingManager.addVestingSchedule (DAPP_TOKENS_TO_VEST, 4, 30, block.timestamp, dappWallet, false); // starts now, 4% every 30 days. Address may need modifying (dApp Vest) - CHANGEME
        minorityVestingManager.addVestingSchedule (THINKTANK_TOKENS_TO_VEST, 20, 365, block.timestamp, thinkTankWallet, false); // starts now, 20% every 365 days. Address may need modifying (think Tank Vest) - CHANGEME
   }
    
    function name() public pure returns (string memory) {
        return NAME;
    }

    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    function totalSupply() public pure override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function balanceOf (address account) public view override returns (uint256) {
        if (isExcluded[account]) 
            return balances[account];
            
        return tokenFromReflection (reflectiveBalances[account]);
    }

    function transfer (address recipient, uint256 amount) public override returns (bool) {
        _transfer (_msgSender(), recipient, amount);
        return true;
    }

    function allowance (address owner, address spender) public view override returns (uint256) {
        return allowances[owner][spender];
    }

    function approve (address spender, uint256 amount) public override returns (bool) {
        _approve (_msgSender(), spender, amount);
        return true;
    }

    function transferFrom (address sender, address recipient, uint256 amount) public override returns (bool) {
        _approve (sender, _msgSender(), allowances[sender][_msgSender()].sub(amount, "MinorityToken: transfer amount exceeds allowance"));
        _transfer (sender, recipient, amount);
        return true;
    }

    function increaseAllowance (address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance (address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowances[_msgSender()][spender].sub(subtractedValue, "MinorityToken: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward (address account) public view returns (bool) {
        return isExcluded[account];
    }
    
    // Given an amount in "normal" token space, returns an amount in reflective token space, with or without the transfer fee deduction
    function reflectionFromToken (uint256 amount, bool deductTransferFee) public view returns (uint256) {
        require (amount <= TOTAL_SUPPLY, "Amount must be less than supply");
        
        if (!deductTransferFee) {
            (uint256 reflectiveAmount,,,,) = getValues (amount);
            return reflectiveAmount;
        } else {
            (,uint256 rTransferAmount,,,) = getValues (amount);
            return rTransferAmount;
        }
    }
    
    // Given an amount in reflective token space, returns an amount in "normal" token space
    function tokenFromReflection (uint256 reflectionAmount) public view returns (uint256) {
        require (reflectionAmount <= reflectiveTotal, "MinorityToken: Amount must be less than total reflections");
        uint256 currentRate =  getRate();
        return reflectionAmount.div(currentRate);
    }

    function excludeFromReward (address account) public onlyOwner {
        require (!isExcluded[account], "MinorityToken: Account is already excluded");
        
        if (reflectiveBalances[account] > 0)
            balances[account] = tokenFromReflection(reflectiveBalances[account]);
        
        isExcluded[account] = true;
        excluded.push(account);
        emit ExcludedFromReward(account);
    }

    function includeInReward (address account) external onlyOwner {
        require (isExcluded[account], "MinorityToken: Account is already included");
        
        for (uint256 i = 0; i < excluded.length; i++) {
            if (excluded[i] == account) {
                excluded[i] = excluded[excluded.length - 1];
                balances[account] = 0;
                isExcluded[account] = false;
                excluded.pop();
                break;
            }
        }
        
        emit IncludedInReward(account);
    }
    
    function excludeFromFee (address account) public onlyOwner {
        isExcludedFromFee[account] = true;
        emit ExcludedFromFee(account);
    }
    
    function includeInFee (address account) public onlyOwner {
        isExcludedFromFee[account] = false;
        emit IncludedInFee(account);
    }
    
    // Sets individual fee percentages, capping the total at 25% to protect users
    function setFeePercentages (uint8 _reflectionFee, uint8 _liquidityFee, uint8 _treasuryFee, uint8 _burnFee, uint8 _rewardFee) external onlyOwner {
        uint256 _totalTxFees = _reflectionFee.add(_liquidityFee).add(_treasuryFee).add(_burnFee).add(_rewardFee);
        require (_totalTxFees <= 25, "MinorityToken: Total fees too high"); // Set a cap to protect users - CHANGEME
        emit FeesChanged (reflectionFee, _reflectionFee, liquidityFee, _liquidityFee, treasuryFee, _treasuryFee, burnFee, _burnFee, rewardFee, _rewardFee);
        reflectionFee = _reflectionFee;
        liquidityFee = _liquidityFee;
        treasuryFee = _treasuryFee;
        burnFee = _burnFee;
        rewardFee = _rewardFee;
        totalTxFees = _totalTxFees;
    }

    function setTreasuryWallet (address _treasuryWallet) external onlyOwner {
        require (_treasuryWallet != address(0), "MinorityToken: Wallet can't be set to the zero address"); // safety check - transfers to the 0 address fail
        treasuryWallet = _treasuryWallet;
    }

    function setRewardWallet (address _rewardWallet) external onlyOwner {
        require (_rewardWallet != address(0), "MinorityToken: Wallet can't be set to the zero address");
        rewardWallet = _rewardWallet;
    }
   
    // Sets Max Tx Percentage, minimum is 1% of total supply (20,000,000 tokens)
    function setMaxTxPercent (uint256 maxTxPercent) external onlyOwner {
        require (maxTxPercent < 100, "MinorityToken: Max Tx can't be > 100%");
        uint256 _maxTxAmount = TOTAL_SUPPLY.mul(maxTxPercent).div(100);
        emit MaxTxAmountChanged (maxTxAmount, _maxTxAmount);
        maxTxAmount = _maxTxAmount;
    }

    function setSwapAndLiquifyEnabled (bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
     //to recieve ETH from swapRouter when swaping
    receive() external payable {}

    function reflectFee (uint256 rReflectionFee) private {
        reflectiveTotal = reflectiveTotal.sub(rReflectionFee);
    }

    function getValues (uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tReflectionFee, uint256 tOtherFees) = getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflectionFee) = getRValues(tAmount, tReflectionFee, tOtherFees, getRate());
        return (rAmount, rTransferAmount, rReflectionFee, tTransferAmount, tOtherFees);
    }

    function getTValues (uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tReflectionFee = tAmount.mul(reflectionFee).div(100);
        uint256 tOtherFees = tAmount.mul(totalTxFees.sub(reflectionFee)).div(100); // Calculate other fees together as we don't need to separate these out until later (see takeOtherFees)
        uint256 tTransferAmount = tAmount.sub(tReflectionFee).sub(tOtherFees);
        return (tTransferAmount, tReflectionFee, tOtherFees);
    }

    function getRValues (uint256 tAmount, uint256 tReflectionFee, uint256 tOtherFees, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rReflectionFee = tReflectionFee.mul(currentRate);
        uint256 rOtherFees = tOtherFees.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rReflectionFee).sub(rOtherFees);
        return (rAmount, rTransferAmount, rReflectionFee);
    }

    function getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = reflectiveTotal;
        uint256 tSupply = TOTAL_SUPPLY;    
        
        for (uint256 i = 0; i < excluded.length; i++) {
            if (reflectiveBalances[excluded[i]] > rSupply || balances[excluded[i]] > tSupply) 
                return (reflectiveTotal, TOTAL_SUPPLY);
                
            rSupply = rSupply.sub(reflectiveBalances[excluded[i]]);
            tSupply = tSupply.sub(balances[excluded[i]]);
        }
        
        if (rSupply < reflectiveTotal.div(TOTAL_SUPPLY)) 
            return (reflectiveTotal, TOTAL_SUPPLY);
            
        return (rSupply, tSupply);
    }
    
    function checkIfExcludedFromFee (address account) public view returns (bool) {
        return isExcludedFromFee[account];
    }

    function _approve (address owner, address spender, uint256 amount) private {
        require (owner != address(0), "MinorityToken: : can't approve from the zero address");
        require (spender != address(0), "MinorityToken: : approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer (address sender, address recipient, uint256 amount) private {
        require (sender != address(0), "MinorityToken: transfer from the zero address");
        require (recipient != address(0), "MinorityToken: transfer to the zero address");
        require (amount > 0, "MinorityToken: Transfer amount must be greater than zero");
        
        if (sender != owner() && recipient != owner())
            require(amount <= maxTxAmount, "MinorityToken: Transfer amount exceeds the _maxTxAmount.");

        uint256 contractTokenBalance = balanceOf(address(minorityLiquidityManager));
        
        if (contractTokenBalance >= maxTxAmount)
            contractTokenBalance = maxTxAmount;
        
        // Only swap if the contract balance is over the minimum specified, it is a sell, and we're not already liquifying
        // Liquification managed by the Minority Liquidity Manager contract
        if (contractTokenBalance >= MIN_CONTRACT_BALANCE_TO_ADD_LP && !minorityLiquidityManager.getInSwapAndLiquify() && sender != swapPair && swapAndLiquifyEnabled) {
            (uint256 tokensAdded, uint256 usdcAdded, uint256 lpTokensCreated) = minorityLiquidityManager.swapAndLiquify(contractTokenBalance);
            emit SwapAndLiquify (tokensAdded, usdcAdded, lpTokensCreated);
        } else {
            // Send any vested tokens to their owners. Don't use too much gas by doing this when we don't swap and liquify only
            minorityVestingManager.executePendingVests();
        }
        
        //indicates if fee should be deducted from transfer
        bool feesEnabled = true;
        
        //if any account belongs to isExcludedFromFee account then remove the fee
        if(isExcludedFromFee[sender] || isExcludedFromFee[recipient])
            feesEnabled = false;
        
        //transfer amount, it will take all fees
        tokenTransfer (sender, recipient, amount, feesEnabled);
    }
    
    // Sends fees to their destination addresses, ensuring the result will be shown correctly on blockchain viewing sites (eg polygonscan)
    function takeFee (uint256 tFeeAmount, address feeWallet, address sender) private {
        uint256 rFeeAmount = tFeeAmount.mul(getRate());
        reflectiveBalances[feeWallet] = reflectiveBalances[feeWallet].add(rFeeAmount);
        
        if(isExcluded[feeWallet])
            balances[feeWallet] = balances[feeWallet].add(tFeeAmount);
            
        emit Transfer(sender, feeWallet, tFeeAmount);
    }
    
    // Splits tOtherFees into its constiuent parts and sends each of them
    function takeOtherFees (uint256 tOtherFees, address sender) private {
        uint256 otherFeesDivisor = totalTxFees.sub(reflectionFee);
        takeFee (tOtherFees.mul(liquidityFee).div(otherFeesDivisor), address(minorityLiquidityManager), sender);
        takeFee (tOtherFees.mul(treasuryFee).div(otherFeesDivisor), treasuryWallet, sender);
        takeFee (tOtherFees.mul(rewardFee).div(otherFeesDivisor), rewardWallet, sender);
        takeFee (tOtherFees.mul(burnFee).div(otherFeesDivisor), BURN_ADDRESS, sender);
    }

    // Responsible for taking all fees, if feesEnabled is true
    function tokenTransfer (address sender, address recipient, uint256 tAmount, bool feesEnabled) private {
        uint256 rAmount = 0;
        uint256 rTransferAmount = 0;
        uint256 rReflectionFee = 0;
        uint256 tTransferAmount = 0;
        uint256 tOtherFees = 0;
        
        if (!feesEnabled) {
            (rAmount,,,,) = getValues (tAmount);
            rTransferAmount = rAmount;
            tTransferAmount = tAmount;
        } else {
            (rAmount, rTransferAmount, rReflectionFee, tTransferAmount, tOtherFees) = getValues (tAmount);
        }
        
        reflectiveBalances[sender] = reflectiveBalances[sender].sub(rAmount);
        reflectiveBalances[recipient] = reflectiveBalances[recipient].add(rTransferAmount);
        
        if (isExcluded[sender])
            balances[sender] = balances[sender].sub(tAmount);
            
        if (isExcluded[recipient])
            balances[recipient] = balances[recipient].add(tTransferAmount);
        
        if (tOtherFees > 0)
            takeOtherFees (tOtherFees, sender);
        
        if (rReflectionFee > 0)
            reflectFee (rReflectionFee);
        
        emit Transfer (sender, recipient, tTransferAmount);
    }
}