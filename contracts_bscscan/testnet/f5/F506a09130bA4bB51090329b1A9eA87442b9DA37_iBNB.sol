pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "@openzeppelin/contracts/utils/Address.sol";

/**
 * $iBNB Token
 *
 * Every tx is subject to:
 * - a sell tax, at fixed tranches (see selling_taxes_tranches and selling_taxes_rates - above the last threshold the highest selling rate will be applied).
      the sell tax is applicable on tx to an AMM pair. This tax goes to the reward pool.
 * - 5% dev tax in BNB
 * - 10% to the balancer (which, in turn, fill 2 internal "pools" via the pro_balances struct: reward and liquidity).
 * - a "check and trigger" on both liquidity, dev and reward internal pools -> if they have more token than the threshold, swap is triggered
 *   and BNB are stored in the contract (for the reward subpool) or liquidity is added to the uni pool or bnb is sent to dev wallet.
 *   The thresholds are adapted to market conditions (via a nodeJS bot)
 *
 * Reward is claimable daily, and is based on the % of the circulating supply (defined as total_supply-dead address balance-pool balance)
 *  owned by the claimer; the balance of the claimer taken into consideration is the lowest the user has had in the claim cycle
 *  after 24h since the start of the claim cycle the claimable bnb will linearly decrease, reaching 0 and entering in a new claim cycle after 48h
 *  (users have 24h to claim)
 * to keep dividends constant a portion of the bnbs stored inside the contract will be used as a reserve pool.
 * the dividends will move with a step of 20 bnb and the dividend pool's amount is computed as:
 * DP=TP/RATIO- ((TP/RATIO) % STEP)
 * 
 * where TP is the total amount of bnb in the contract,
 * RATIO is initially set at 25%
 * STEP is initially set at 20 BNB
 * 
 *                    -- Godspeed --
 */

contract iBNB is Ownable, ERC20 {
    using Address for address payable;

    struct past_tx {
      uint256 cum_transfer; //this is not what you think, you perv
      uint256 last_timestamp;
      uint256 last_claim;
      uint256 claimable_amount;
    }

    struct prop_balances {
      uint256 reward_pool;
      uint256 liquidity_pool;
      uint256 dev_pool;
    }

    struct swap_thresholds {
      uint256 reward_pool;
      uint256 liquidity_pool;
      uint256 dev_pool;
    }

    mapping (address => past_tx) private _last_tx;
    mapping (address => bool) public isExcludedFromTxFees;

    //will be used only for ibnb pairs, burn address and other addresses who wouldn't be able to claim in any case
    mapping (address => bool) public isExcludedFromDividends;
    address[] public excludedFromDividends;

    mapping(address => bool) public isBadActor;
    
    uint256 private _totalSupply = 10**15 * 10**9;

    mapping (address => bool) public isAutomatedMarketMakerPair;

    uint8 public pcs_pool_to_circ_ratio = 5;

    uint32 public reward_rate = 1 days; //I need to wait this much to be able to claim
    uint32 public claimResetInterval=2 days; //If I don't claim for this time interval I automatically enter a new claim cycle

    //antiwhale mechanism
    mapping(address => uint256) private _firstSell; //in a 24h timeframe
    mapping(address => uint256) private _totSells; //for the 24h timeframe
    uint256 public maxSellPerDay = _totalSupply/1000;

    uint8[4] public selling_taxes_rates = [2, 5, 10, 20]; //additional percentage on sell tax
    uint16[3] public selling_taxes_tranches = [100, 300, 750]; // % and div by 10**4 0.0125% -0.025% -(...)

    uint256[6] public claiming_taxes_tranches = [0.01 ether, 0.05 ether, 0.1 ether, 0.5 ether, 1 ether, 1.5 ether];
    uint8[6] public claiming_taxes_rates = [1, 2, 5, 10, 15, 25];

    address public LP_recipient;
    address public devWallet;
    address public advWallet;

    swap_thresholds public thresholds = swap_thresholds(
    { reward_pool: 10**13 * 10**9, //1%
      liquidity_pool: 10**13 * 10**9, //1%
      dev_pool: 10**13 * 10**9 //1%
    });
    
    IUniswapV2Pair public pair;
    IUniswapV2Router02 public router;

    prop_balances public balancer_balances;

    event TaxRatesChanged();
    event SwapForBNB(string);
    event BalancerPools(uint256,uint256);
    event RewardTaxChanged();
    event AddLiq(string);
    event balancerReset(uint256 reward_pool, uint256 liquidity_pool, uint256 dev_pool);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    //values are *10 %
    struct feeRatesStruct {
      uint256 devFeeBNB;
      uint256 dynamicFee;
      uint256 devFeeiBNB;
      uint256 advisoryFeeiBNB;

    }
    struct dp_config_data {
    uint256 ratio;
    uint256 step;
    }

    dp_config_data public dividendPoolSettings = dp_config_data(
    { ratio: 25, // % of how much of the balance has to be used for paying dividends (unused balance is kept as reserve)
      step: 20 ether // step at which the dp will increase/decrease 
    });

    feeRatesStruct public buyFees = feeRatesStruct(
    { devFeeBNB: 50, //5%
      dynamicFee: 100, //10%
      devFeeiBNB: 1, //0.1%
      advisoryFeeiBNB: 1 //0.1%
    });

    feeRatesStruct public sellFees = feeRatesStruct(
    { devFeeBNB: 50,
      dynamicFee: 100,
      devFeeiBNB: 1,
      advisoryFeeiBNB: 1
    });

    feeRatesStruct public transferFees = feeRatesStruct(
    { devFeeBNB: 50,
      dynamicFee: 100,
      devFeeiBNB: 1,
      advisoryFeeiBNB: 1
    });

    constructor (address _router)  ERC20("iBNB", "iBNB") {
         //create pair to get the pair address
         router = IUniswapV2Router02(_router);
         IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
         pair = IUniswapV2Pair(factory.createPair(address(this), router.WETH()));
         LP_recipient = address(msg.sender);
         devWallet = address(msg.sender);
         advWallet = address(msg.sender);


         isExcludedFromTxFees[msg.sender] = true;
         isExcludedFromTxFees[address(this)] = true;
         isExcludedFromTxFees[devWallet] = true;
         isExcludedFromTxFees[advWallet] = true;

        
        isExcludedFromDividends[0x000000000000000000000000000000000000dEaD] = true;
        excludedFromDividends.push(0x000000000000000000000000000000000000dEaD);
        isExcludedFromDividends[address(this)] = true;
        excludedFromDividends.push(address(this));
         isExcludedFromDividends[address(pair)] = true;
        excludedFromDividends.push(address(pair));  
        
        _setAutomatedMarketMakerPair(address(pair), true);
        
        _last_tx[msg.sender].last_claim = block.timestamp;
        _last_tx[msg.sender].claimable_amount = _totalSupply;

         _mint(msg.sender, _totalSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function setAutomatedMarketMakerPair(address _pair, bool value) public onlyOwner {
        require(_pair != address(pair), "The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(_pair, value);
    }

    function _setAutomatedMarketMakerPair(address _pair, bool value) private {
        require(isAutomatedMarketMakerPair[_pair] != value, "Automated market maker pair is already set to that value");
        isAutomatedMarketMakerPair[_pair] = value;

        emit SetAutomatedMarketMakerPair(_pair, value);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(!isBadActor[sender] && !isBadActor[recipient], "Bots are not allowed");

        require(balanceOf(sender) >= amount, "ERC20: transfer amount exceeds balance");

        uint256 sell_tax;
        uint256 dev_taxBNB;
        uint256 dev_tax_iBNB;
        uint256 adv_tax_iBNB;

        uint256 balancer_amount;
        uint256 txfee;
        
        //>1 day since last tx
        if(block.timestamp > _last_tx[sender].last_timestamp + 1 days) {
          _last_tx[sender].cum_transfer = 0; // a.k.a The Virgin
        }

        if(!isExcludedFromDividends[sender] && block.timestamp > claimResetInterval+_last_tx[sender].last_claim) {
          _last_tx[sender].last_claim = block.timestamp - (block.timestamp - _last_tx[sender].last_claim) % claimResetInterval;
          _last_tx[sender].claimable_amount=balanceOf(sender);
        }
        if(!isExcludedFromDividends[recipient] && block.timestamp > claimResetInterval+_last_tx[recipient].last_claim) {
          _last_tx[recipient].last_claim = block.timestamp - (block.timestamp - _last_tx[recipient].last_claim) % claimResetInterval;
          _last_tx[recipient].claimable_amount=balanceOf(recipient);
          
        }

        if(!isExcludedFromTxFees[sender] && !isExcludedFromTxFees[recipient]) {
        
          (uint112 _reserve0, uint112 _reserve1,) = pair.getReserves(); // returns reserve0, reserve1, timestamp last tx
          if(address(this) != pair.token0()) { // 0 := iBNB
            (_reserve0, _reserve1) = (_reserve1, _reserve0);
          }
          feeRatesStruct memory appliedFee;
          if(isAutomatedMarketMakerPair[sender])
            {
                appliedFee = buyFees;
            }
            else if(isAutomatedMarketMakerPair[recipient])
            {   
                if(block.timestamp < _firstSell[sender]+ 1 days){
                require(_totSells[sender]+amount <= maxSellPerDay, "You can't sell more than maxSellPerDay");
                _totSells[sender] += amount;
                }
            else{
                require(amount <= maxSellPerDay, "You can't sell more than maxSellPerDay");
                _firstSell[sender] = block.timestamp;
                _totSells[sender] = amount;
            }
                appliedFee = sellFees;
                sell_tax = sellingTax(sender, amount, _reserve0); //will update the balancer ledger too
            }
            else
            {
                appliedFee = transferFees;
            }

          dev_taxBNB = amount*appliedFee.devFeeBNB/1000;
          balancer_balances.dev_pool += dev_taxBNB;
          dev_tax_iBNB = amount*appliedFee.devFeeiBNB/1000;
          adv_tax_iBNB = amount*appliedFee.advisoryFeeiBNB/1000;

          // ------ balancer tax 10% ------
          balancer_amount = amount*appliedFee.dynamicFee/1000;

          txfee= sell_tax+balancer_amount+dev_taxBNB;

          super._transfer(sender, address(this),txfee);

          _transfer(sender, devWallet, dev_tax_iBNB);
          _transfer(sender, advWallet, adv_tax_iBNB);
          txfee+=dev_tax_iBNB+adv_tax_iBNB;
          balancer(balancer_amount, _reserve0);
          _last_tx[recipient].last_timestamp = block.timestamp;

        }
        uint256 sentToRecipient = amount-txfee;

        if(balanceOf(recipient)==0 && !isExcludedFromDividends[recipient])
        {
         _last_tx[recipient].last_claim = block.timestamp;
         _last_tx[recipient].claimable_amount = sentToRecipient;
        }

        super._transfer(sender, recipient, sentToRecipient);
        
        if(!isExcludedFromDividends[sender])
        {
          uint256 bal_sender=balanceOf(sender);

          if(bal_sender<_last_tx[sender].claimable_amount)
          {
           _last_tx[sender].claimable_amount = bal_sender;
          }
        }

    }

    //@dev take a selling tax if transfer from a non-excluded address or from the pair contract exceed
    //the thresholds defined in selling_taxes_thresholds on 24h floating window
    function sellingTax(address sender, uint256 amount, uint256 pool_balance) internal returns(uint256 sell_tax) {
        uint16[3] memory _tax_tranches = selling_taxes_tranches;
        past_tx memory sender_last_tx = _last_tx[sender];

        uint256 new_cum_sum = amount+_last_tx[sender].cum_transfer;

        if(new_cum_sum > pool_balance*_tax_tranches[2]/10**4) {
          sell_tax = amount*selling_taxes_rates[3]/100;
        }
        else if(new_cum_sum > pool_balance*_tax_tranches[1]/10**4) {
          sell_tax = amount*selling_taxes_rates[2]/100;
        }
        else if(new_cum_sum > pool_balance*_tax_tranches[0]/10**4) {
          sell_tax = amount*selling_taxes_rates[1]/100;
        }
        else { sell_tax = amount*selling_taxes_rates[0]/100; }

        _last_tx[sender].cum_transfer = sender_last_tx.cum_transfer+amount;

        balancer_balances.reward_pool += sell_tax; //sell tax is for reward:)

        return sell_tax;
    }

    //@dev take the dynamicFee taxes as input, split it between reward and liq subpools
    //    according to pool condition -> circ-pool/circ supply closer to one implies
    //    priority to the reward pool
    //    will handle all the swaps for the various taxes
    function balancer(uint256 amount, uint256 pool_balance) internal {

        address DEAD = address(0x000000000000000000000000000000000000dEaD);
        uint256 unwght_circ_supply = totalSupply()-balanceOf(DEAD);

        // we aim at a set % of liquidity pool (defaut 5% of circ supply), 100% in pancake swap is NOT a good news
        uint256 circ_supply = (pool_balance < unwght_circ_supply * pcs_pool_to_circ_ratio / 100) ? unwght_circ_supply * pcs_pool_to_circ_ratio / 100 : pool_balance;
        uint256 liquidity_amount = (amount*(circ_supply-pool_balance)*10**9)/circ_supply/10**9;
        balancer_balances.liquidity_pool += liquidity_amount ;
        balancer_balances.reward_pool += amount-liquidity_amount;

        prop_balances memory _balancer_balances = balancer_balances;
        
        if(_balancer_balances.reward_pool >= thresholds.reward_pool) {
            uint256 token_out = swapForBNB(_balancer_balances.reward_pool, address(this));
            balancer_balances.reward_pool -= token_out;
        }

        if(_balancer_balances.liquidity_pool >= thresholds.liquidity_pool) {
            uint256 token_out = addLiquidity(_balancer_balances.liquidity_pool);
            balancer_balances.liquidity_pool -= token_out; //not balanceOf, in case addLiq revert
        }

        if(_balancer_balances.dev_pool >= thresholds.dev_pool) {
            uint256 token_out = swapForBNB(_balancer_balances.dev_pool, devWallet);
            balancer_balances.dev_pool -= token_out;
        }

        emit BalancerPools(_balancer_balances.liquidity_pool, _balancer_balances.reward_pool);
    }

    //@dev when triggered, will swap and provide liquidity
    //    BNBfromSwap being the difference between and after the swap, slippage
    //    will result in extra-BNB for the reward pool (free money for the guys:)
    function addLiquidity(uint256 token_amount) internal returns (uint256) {
      uint256 BNBfromReward = address(this).balance;

      address[] memory route = new address[](2);
      route[0] = address(this);
      route[1] = router.WETH();

      if(allowance(address(this), address(router)) < token_amount) {
        _approve(address(this),address(router), type(uint256).max);
      }
      
      //odd numbers management
      uint256 half = token_amount/2;
      uint256 half_2 = token_amount-half;
      if (swapForBNB(half,address(this)) ==0)//swapForBNB failed
      {
        emit AddLiq("addLiq: fail");
        return 0; 
      }

      uint256 BNBfromSwap = address(this).balance-BNBfromReward;
      try router.addLiquidityETH{value: BNBfromSwap}(address(this), half_2, 0, 0, LP_recipient, block.timestamp){ //will not be catched
        emit AddLiq("addLiq: ok");
        return token_amount;
      }
      catch {
        emit AddLiq("addLiq: fail");
        return 0;
      }
    }

    //@dev individual reward is possible after 24h, and is the portion of the reward pool
    //     weighted by the "free" (ie non-pool non-death) supply owned.
    //     reward = (balance/free supply) * [(now - lastClaim) / 1d] * BNB_balance
    //     If an extra-buy occurs in the user's current claim cycle, the bought tokens will be taken into account in the next claim cycle
    //     user's balance used for rewards is the lowest balance of the user over the claim cycle 
    //     returns net reward, tax on the reward and the Amount of tokens for which the user is claiming
    function computeReward() public view returns(uint256 net_reward_in_BNB, uint256 tax_to_pay,uint256 claimable_amountTokens) {

      past_tx memory sender_last_tx = _last_tx[msg.sender];

      if((block.timestamp - sender_last_tx.last_claim) > claimResetInterval)
      {
        sender_last_tx.claimable_amount=balanceOf(msg.sender); //updates the claimable amount adding tokens bought in the past claim cycle
      }
      uint256 time_factor = (block.timestamp - sender_last_tx.last_claim) % claimResetInterval;

      if(time_factor < reward_rate) { // 1 claim every 24h max
        return (0, 0,sender_last_tx.claimable_amount);//too soon (that's what she said)
      }
      else
      {
        time_factor=claimResetInterval-time_factor;
      }

      uint256 claimable_supply = getClaimableSupply();
      
      uint256 tp_times_ratio = address(this).balance*dividendPoolSettings.ratio/100;
      uint256 dp =tp_times_ratio- (tp_times_ratio%dividendPoolSettings.step);
      uint256 _nom = sender_last_tx.claimable_amount*time_factor*dp;
      uint256 _denom = claimable_supply*(claimResetInterval-reward_rate);
      uint256 gross_reward_in_BNB = _nom/_denom;
      tax_to_pay = taxOnClaim(gross_reward_in_BNB);
      return (gross_reward_in_BNB-tax_to_pay, tax_to_pay, sender_last_tx.claimable_amount);
    }

    //@dev Compute the tax on claimed reward - labelled in BNB (as per team agreement)
    function taxOnClaim(uint256 amount) internal view returns(uint256 tax){

      if(amount >= claiming_taxes_tranches[5] ) { return amount*claiming_taxes_rates[5]/100; }
      else if(amount >= claiming_taxes_tranches[4] ) { return amount*claiming_taxes_rates[4]/100; }
      else if(amount >= claiming_taxes_tranches[3] ) { return amount*claiming_taxes_rates[3]/100; }
      else if(amount >= claiming_taxes_tranches[2] ) { return amount*claiming_taxes_rates[2]/100; }
      else if(amount >= claiming_taxes_tranches[1] ) { return amount*claiming_taxes_rates[1]/100; }
      else if(amount >= claiming_taxes_tranches[0] ) { return amount*claiming_taxes_rates[0]/100; }
      else { return 0; }

    }

    //@dev frontend integration
    function claimPossibleStartingAt() external view returns (uint256) {
      return block.timestamp - (block.timestamp - _last_tx[msg.sender].last_claim) % claimResetInterval + reward_rate;
    }

    function claimCycleResetAt() external view returns (uint256) {
      return block.timestamp - (block.timestamp - _last_tx[msg.sender].last_claim) % claimResetInterval + claimResetInterval;
    }

    //@dev computeReward check if last claim is less than 1d ago
    function claimReward() external {
      require(!isExcludedFromDividends[msg.sender], "user is excluded from dividends");
      (uint256 claimableBNB,,uint256 claimableTokens ) = computeReward();
      require(claimableBNB > 0, "Claim: 0");
      _last_tx[msg.sender].last_claim = block.timestamp;
      _last_tx[msg.sender].claimable_amount = claimableTokens;
      payable(msg.sender).sendValue( claimableBNB);
    }

    function swapForBNB(uint256 token_amount, address receiver) internal returns (uint256) {
      address[] memory route = new address[](2);
      route[0] = address(this);
      route[1] = router.WETH();

      if(allowance(address(this), address(router)) < token_amount) {
        _approve(address(this),address(router), type(uint256).max);
      }

      try router.swapExactTokensForETHSupportingFeeOnTransferTokens(token_amount, 0, route, receiver, block.timestamp) {
        emit SwapForBNB("Swap success");
        return token_amount;
      }
      catch Error(string memory _err) {
        emit SwapForBNB(_err);
        return 0;
      }
    }

    function excludeFromTaxes(address adr) external onlyOwner {
      require(!isExcludedFromTxFees[adr], "already excluded");
      isExcludedFromTxFees[adr] = true;
    }

    function includeInTaxes(address adr) external onlyOwner {
      require(isExcludedFromTxFees[adr], "already taxed");
      isExcludedFromTxFees[adr] = false;
    }

    function excludeFromDividends(address account) external onlyOwner() {
      require(!isExcludedFromDividends[account], "Account is already excluded");
      isExcludedFromDividends[account] = true;
      excludedFromDividends.push(account);
      _last_tx[account].claimable_amount=0;
    }

    function includeInDividends(address account) external onlyOwner() {
        require(isExcludedFromDividends[account], "Account is already excluded");
        for (uint256 i = 0; i < excludedFromDividends.length; i++) {
            if (excludedFromDividends[i] == account) {
                excludedFromDividends[i] = excludedFromDividends[excludedFromDividends.length - 1];
                _last_tx[account].claimable_amount= balanceOf(account);
                _last_tx[account].last_claim = block.timestamp;
                isExcludedFromDividends[account] = false;
                excludedFromDividends.pop();
                break;
            }
        }
    }

    function getClaimableSupply() public view returns (uint256) {
      uint256 sumOfTokens;
      for (uint256 i = 0; i < excludedFromDividends.length; i++) {
              sumOfTokens+=balanceOf(excludedFromDividends[i]);
          }
      return totalSupply()-sumOfTokens;
    }
  

    function resetBalancer() external onlyOwner {
      uint256 _contract_balance = balanceOf(address(this));
      balancer_balances.reward_pool = _contract_balance/3;
      uint256 twoThirds = _contract_balance - balancer_balances.reward_pool;
      balancer_balances.liquidity_pool = twoThirds/2;
      balancer_balances.dev_pool = twoThirds - balancer_balances.liquidity_pool;
      emit balancerReset(balancer_balances.reward_pool, balancer_balances.liquidity_pool, balancer_balances.dev_pool);
    }

    function setLPRecipient(address _LP_recipient) external onlyOwner {
      LP_recipient = _LP_recipient;
    }

    function setDevWallet(address _devWallet) external onlyOwner {
      devWallet = _devWallet;
      isExcludedFromTxFees[_devWallet] = true;
    }

    function setAdvWallet(address _advWallet) external onlyOwner {
      advWallet = _advWallet;
      isExcludedFromTxFees[_advWallet] = true;

    }

    function setSwapThresholds(uint256 lp_threshold_in_token,uint256 rp_threshold_in_token,uint256 dp_threshold_in_token) external onlyOwner {
      thresholds.liquidity_pool = lp_threshold_in_token * 10**9;
      thresholds.reward_pool = rp_threshold_in_token * 10**9;
      thresholds.dev_pool = dp_threshold_in_token * 10**9;

    }

    function setSellingTaxesTranches(uint16[3] memory new_tranches) external onlyOwner {
      selling_taxes_tranches = new_tranches;
      emit TaxRatesChanged();
    }

    function setSellingTaxesrates(uint8[4] memory new_amounts) external onlyOwner {
      selling_taxes_rates = new_amounts;
      emit TaxRatesChanged();
    }

    function setRewardTaxesTranches(uint8[6] memory new_tranches) external onlyOwner {
      claiming_taxes_tranches = new_tranches;
      emit RewardTaxChanged();
    }

    function setRewardTaxesRates(uint8[6] memory new_rates) external onlyOwner {
      claiming_taxes_rates = new_rates;
      emit RewardTaxChanged();
    }

    function setRewardRate(uint32 new_periodicity) external onlyOwner {
      require(new_periodicity< claimResetInterval, "new_periodicity > claimResetInterval");

      reward_rate = new_periodicity;
    }

    function setClaimResetInterval(uint32 new_claimResetInterval) external onlyOwner {
      require(new_claimResetInterval>reward_rate, "new_claimResetInterval <= reward_rate");
      claimResetInterval = new_claimResetInterval;
    }

    function setDividendPoolSettings(uint256 _step, uint256 _ratio) external onlyOwner {
      require(_ratio>0 && _ratio<=100,"ratio must be >0 and <=100");
      require(_step>0,"step must be >0");
      dividendPoolSettings.ratio = _ratio;
      dividendPoolSettings.step = _step;
    }

        // To be used for snipe-bots and bad actors communicated on with the community.
    function badActorDefenseMechanism(address account, bool _isBadActor) external onlyOwner{
        isBadActor[account] = _isBadActor;
    }

    function setMaxSellAmountPerDay(uint256 amount) external onlyOwner{
        maxSellPerDay = amount * 10**9;
    }

    function setSellFees(uint256 devFeeBNB, uint256 dynamicFee, uint256 advisoryFeeiBNB, uint256 devFeeiBNB) external onlyOwner{
        sellFees.devFeeBNB = devFeeBNB;
        sellFees.dynamicFee = dynamicFee;
        sellFees.advisoryFeeiBNB = advisoryFeeiBNB;
        sellFees.devFeeiBNB = devFeeiBNB;
        
    }
    function setBuyFees(uint256 devFeeBNB, uint256 dynamicFee, uint256 advisoryFeeiBNB, uint256 devFeeiBNB) external onlyOwner{
        buyFees.devFeeBNB = devFeeBNB;
        buyFees.dynamicFee = dynamicFee;
        buyFees.advisoryFeeiBNB = advisoryFeeiBNB;
        buyFees.devFeeiBNB = devFeeiBNB;
    }
    function setTransferFees(uint256 devFeeBNB, uint256 dynamicFee, uint256 advisoryFeeiBNB, uint256 devFeeiBNB) external onlyOwner{
        transferFees.devFeeBNB = devFeeBNB;
        transferFees.dynamicFee = dynamicFee;
        transferFees.advisoryFeeiBNB = advisoryFeeiBNB;
        transferFees.devFeeiBNB = devFeeiBNB;
    }

    function getReserves() external view returns (uint256 dp, uint256 rp)
    {
      uint256 tp_times_ratio = address(this).balance*dividendPoolSettings.ratio/100;
      dp= tp_times_ratio- (tp_times_ratio%dividendPoolSettings.step);
      rp = address(this).balance - dp;

    }
    
    //@dev fallback in order to receive BNB from swapToBNB
    receive () external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

