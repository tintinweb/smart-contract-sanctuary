// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";


contract MOCHA is Ownable, IERC20 {
    using SafeMath for uint256;

    struct past_tx {
      uint256 cum_transfer;
      uint256 last_timestamp;
      uint256 last_claim;
    }

    struct prop_balances {
      uint256 reward_pool;
      uint256 liquidity_pool;
    }

    mapping (address => uint256) private _balances;
    mapping (address => past_tx) private _last_tx;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private excluded;

    uint8 private _decimals = 9;
    uint8 public pcs_pool_to_circ_ratio = 10;

    uint32 public reward_rate = 1 days;

    uint256 private _totalSupply = 10**15 * 10**_decimals;
    uint256 public swap_for_liquidity_threshold = 10**13 * 10**_decimals; //1%
    uint256 public swap_for_reward_threshold = 10**13 * 10**_decimals;

    uint8[4] public selling_taxes_rates = [2, 4, 6, 8];
    uint8[5] public claiming_taxes_rates = [2, 4, 6, 8, 15];
    uint16[5] public selling_taxes_tranches = [125, 250, 500, 750, 1000]; // % and div by 10**4 0.0125% -0.025% -(...)

    bool public circuit_breaker;
    bool private liq_swap_reentrancy_guard;
    bool private reward_swap_reentrancy_guard;

    string private _name = "MOCHA";
    string private _symbol = "MOCHA";

    address public LP_recipient;
    address public devWallet;

    IUniswapV2Pair public pair;
    IUniswapV2Router02 public router;

    prop_balances private balancer_balances;

    event TaxRatesChanged();
    event SwapForBNB(string);
    event BalancerPools(uint256,uint256);
    event RewardTaxChanged();
    event AddLiq(string);
    event balancerReset(uint256, uint256);

    constructor (address _router) {
         //create pair to get the pair address
         router = IUniswapV2Router02(_router);
         IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
         pair = IUniswapV2Pair(factory.createPair(address(this), router.WETH()));

         LP_recipient = address(0x000000000000000000000000000000000000dEaD); //LP token: burn
         devWallet = address(0x000000000000000000000000000000000000dEaD); //0.1%: burn

         excluded[msg.sender] = true;
         excluded[address(this)] = true;
         excluded[devWallet] = true; //exclude burn address from max_tx

         circuit_breaker = true; //ERC20 behavior by default/presale
         
         _balances[msg.sender] = _totalSupply;
         emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function decimals() public view returns (uint256) {
         return _decimals;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        uint256 sell_tax;
        uint256 dev_tax;
        uint256 balancer_amount;
        
        //>1 day since last tx
        if(block.timestamp > _last_tx[sender].last_timestamp + 1 days) {
          _last_tx[sender].cum_transfer = 0; // a.k.a The Virgin
        }


        if(excluded[sender] == false && excluded[recipient] == false && circuit_breaker == false) {
        
          (uint112 _reserve0, uint112 _reserve1,) = pair.getReserves(); // returns reserve0, reserve1, timestamp last tx
          if(address(this) != pair.token0()) { // 0 := MOCHA
            (_reserve0, _reserve1) = (_reserve1, _reserve0);
          }
          
        // ----  Sell tax  ----
          if(recipient == address(pair)) {
            sell_tax = sellingTax(sender, amount, _reserve0); //will update the balancer ledger too
          }
          
        // ------ "flexible"/dev tax 0.1% -------
          dev_tax = amount.div(1000);

        // ------ balancer tax 9.9% ------
          balancer_amount = amount.mul(99).div(1000);
          balancer(balancer_amount, _reserve0);

          //@dev every extra token are collected into address(this), it's the balancer job to then split them
          //between pool and reward, using the dedicated struct
          _balances[address(this)] += sell_tax.add(balancer_amount);
          _balances[devWallet] += dev_tax;
        }
        //else, by default:
        //  sell_tax = 0;
        //  dev_tax = 0;
        //  balancer_amount = 0;


        //reward reinit
        _last_tx[recipient].last_timestamp = block.timestamp;

        _balances[sender] = senderBalance.sub(amount);
        _balances[recipient] += amount.sub(sell_tax).sub(dev_tax).sub(balancer_amount);

        emit Transfer(sender, recipient, amount);
        emit Transfer(sender, address(this), sell_tax);
        emit Transfer(sender, address(this), balancer_amount);
        emit Transfer(sender, devWallet, dev_tax);
    }

    //@dev take a selling tax if transfer from a non-excluded address or from the pair contract exceed
    //the thresholds defined in selling_taxes_thresholds on 24h floating window
    function sellingTax(address sender, uint256 amount, uint256 pool_balance) internal returns(uint256 sell_tax) {
        uint16[5] memory _tax_tranches = selling_taxes_tranches;
        past_tx memory sender_last_tx = _last_tx[sender];

        uint256 new_cum_sum = amount.add(_last_tx[sender].cum_transfer);

        if(new_cum_sum > pool_balance.mul(_tax_tranches[4]).div(10**4)) {
          revert("Selling tax: above max amount");
        }
        else if(new_cum_sum > pool_balance.mul(_tax_tranches[3]).div(10**4)) {
          sell_tax = amount.mul(selling_taxes_rates[3]).div(100);
        }
        else if(new_cum_sum > pool_balance.mul(_tax_tranches[2]).div(10**4)) {
          sell_tax = amount.mul(selling_taxes_rates[2]).div(100);
        }
        else if(new_cum_sum > pool_balance.mul(_tax_tranches[1]).div(10**4)) {
          sell_tax = amount.mul(selling_taxes_rates[1]).div(100);
        }
        else if(new_cum_sum > pool_balance.mul(_tax_tranches[0]).div(10**4)) {
          sell_tax = amount.mul(selling_taxes_rates[0]).div(100);
        }
        else { sell_tax = 0; }

        _last_tx[sender].cum_transfer = sender_last_tx.cum_transfer.add(amount);

        balancer_balances.reward_pool += sell_tax; //sell tax is for reward:)

        return sell_tax;
    }

    //@dev take the 9.9% taxes as input, split it between reward and liq subpools
    //    according to pool condition -> circ-pool/circ supply closer to one implies
    //    priority to the reward pool
    function balancer(uint256 amount, uint256 pool_balance) internal {

        address DEAD = address(0x000000000000000000000000000000000000dEaD);
        uint256 unwght_circ_supply = totalSupply().sub(_balances[DEAD]);

        // we aim at a set % of liquidity pool (defaut 10% of circ supply), 100% in pancake swap is NOT a good news
        uint256 circ_supply = (pool_balance < unwght_circ_supply * pcs_pool_to_circ_ratio / 100) ? unwght_circ_supply * pcs_pool_to_circ_ratio / 100 : pool_balance;



        balancer_balances.liquidity_pool += (amount.mul(circ_supply.sub(pool_balance)).mul(10**9).div(circ_supply)).div(10**9);
        balancer_balances.reward_pool += (amount.mul(circ_supply.sub((circ_supply.sub(pool_balance)))).mul(10**9).div(circ_supply)).div(10**9);

        prop_balances memory _balancer_balances = balancer_balances;

        if(_balancer_balances.liquidity_pool >= swap_for_liquidity_threshold && !liq_swap_reentrancy_guard) {
            liq_swap_reentrancy_guard = true;
            uint256 token_out = addLiquidity(_balancer_balances.liquidity_pool);
            balancer_balances.liquidity_pool -= token_out; //not balanceOf, in case addLiq revert
            liq_swap_reentrancy_guard = false;
        }

        if(_balancer_balances.reward_pool >= swap_for_reward_threshold && !reward_swap_reentrancy_guard) {
            reward_swap_reentrancy_guard = true;
            uint256 token_out = swapForBNB(_balancer_balances.reward_pool, address(this));
            balancer_balances.reward_pool -= token_out;
            reward_swap_reentrancy_guard = false;
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
        _allowances[address(this)][address(router)] = ~uint256(0);
        emit Approval(address(this), address(router), ~uint256(0));
      }
      
      //odd numbers management
      uint256 half = token_amount.div(2);
      uint256 half_2 = token_amount.sub(half);
      
      try router.swapExactTokensForETHSupportingFeeOnTransferTokens(half, 0, route, address(this), block.timestamp) {
        uint256 BNBfromSwap = address(this).balance.sub(BNBfromReward);
        router.addLiquidityETH{value: BNBfromSwap}(address(this), half_2, 0, 0, LP_recipient, block.timestamp); //will not be catched
        emit AddLiq("addLiq: ok");
        return token_amount;
      }
      catch {
        emit AddLiq("addLiq: fail");
        return 0;
      }
    }

    //@dev individual reward is growing linearly througout 24h, and is the portion of the reward pool
    //     weighted by the "free" (ie non-pool non-death) supply owned.
    //     reward = (balance/free supply) * [(now - lastClaim) / 1d] * BNB_balance
    //     If an extra-buy occurs in the last 24h, reset 24h timer (in sell tax)
    //     (frontend will automatize claim then buy)
    //     returns net reward and tax on the reward
    function computeReward() public view returns(uint256, uint256 tax_to_pay) {

      past_tx memory sender_last_tx = _last_tx[msg.sender];

      if(sender_last_tx.last_claim + reward_rate > block.timestamp) { // 1 claim every 24h max
        return (0, 0);//too soon (that's what she said)
      }

      address DEAD = address(0x000000000000000000000000000000000000dEaD);

      uint256 claimable_supply = totalSupply().sub(_balances[DEAD]).sub(_balances[address(pair)]);
      uint256 time_factor = (block.timestamp - sender_last_tx.last_timestamp) % reward_rate;

      uint256 _nom = _balances[msg.sender].mul(time_factor).mul(address(this).balance);
      uint256 _denom = claimable_supply.mul(1 days);
      uint256 gross_reward_in_BNB = _nom.div(_denom);
      tax_to_pay = taxOnClaim(gross_reward_in_BNB);
      return (gross_reward_in_BNB.sub(tax_to_pay), tax_to_pay);
    }

    //@dev Compute the tax on claimed reward - labelled in BNB (as per team agreement)
    function taxOnClaim(uint256 amount) internal view returns(uint256 tax){

      if(amount > 2 ether) { return amount.mul(claiming_taxes_rates[4]).div(100); }
      else if(amount > 1.50 ether) { return amount.mul(claiming_taxes_rates[3]).div(100); }
      else if(amount > 1 ether) { return amount.mul(claiming_taxes_rates[2]).div(100); }
      else if(amount > 0.5 ether) { return amount.mul(claiming_taxes_rates[1]).div(100); }
      else if(amount > 0.25 ether) { return amount.mul(claiming_taxes_rates[0]).div(100); }
      else { return 0; }

    }

    //@dev frontend integration
    function endOfPeriod() external view returns (uint256) {
      return _last_tx[msg.sender].last_claim + reward_rate;
    }

    //@dev computeReward check if last claim is less than 1d ago
    function claimReward() external {
      (uint256 claimable, uint256 tax) = computeReward();
      require(claimable > 0, "Claim: 0");
      _last_tx[msg.sender].last_claim = block.timestamp;
      emit Transfer(msg.sender, address(this), tax);
      safeTransferETH(msg.sender, claimable);
    }

    function swapForBNB(uint256 token_amount, address receiver) internal returns (uint256) {
      address[] memory route = new address[](2);
      route[0] = address(this);
      route[1] = router.WETH();

      if(allowance(address(this), address(router)) < token_amount) {
        _allowances[address(this)][address(router)] = ~uint256(0);
        emit Approval(address(this), address(router), ~uint256(0));
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

    //@dev taken from uniswapV2 TransferHelper lib
    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    function excludeFromTaxes(address adr) external onlyOwner {
      require(!excluded[adr], "already excluded");
      excluded[adr] = true;
    }

    function includeInTaxes(address adr) external onlyOwner {
      require(excluded[adr], "already taxed");
      excluded[adr] = false;
    }

    function isExcluded(address adr) external view returns (bool){
      return excluded[adr];
    }

    function resetBalancer() external onlyOwner {
      uint256 _contract_balance = _balances[address(this)];
      balancer_balances.reward_pool = _contract_balance.div(2);
      balancer_balances.liquidity_pool = _contract_balance.div(2);
      emit balancerReset(balancer_balances.reward_pool, balancer_balances.liquidity_pool);
    }

    //@dev will bypass all the taxes and act as erc20.
    //     pools & balancer balances will remain untouched
    function setCircuitBreaker(bool status) external onlyOwner {
      circuit_breaker = status;
    }

    //@dev default = burn
    function setLPRecipient(address _LP_recipient) external onlyOwner {
      LP_recipient = _LP_recipient;
    }

    function setDevWallet(address _devWallet) external onlyOwner {
      devWallet = _devWallet;
    }

    function setSwapFor_Liq_Threshold(uint128 threshold_in_token) external onlyOwner {
      swap_for_liquidity_threshold = threshold_in_token * 10**_decimals;
    }

    function setSwapFor_Reward_Threshold(uint128 threshold_in_token) external onlyOwner {
      swap_for_reward_threshold = threshold_in_token * 10**_decimals;
    }

    function setSellingTaxesTranches(uint16[5] memory new_tranches) external onlyOwner {
      selling_taxes_tranches = new_tranches;
      emit TaxRatesChanged();
    }

    function setSellingTaxesrates(uint8[4] memory new_amounts) external onlyOwner {
      selling_taxes_rates = new_amounts;
      emit TaxRatesChanged();
    }

    function setRewardTaxesTranches(uint8[5] memory new_tranches) external onlyOwner {
      claiming_taxes_rates = new_tranches;
      emit RewardTaxChanged();
    }

    function setRewardRate(uint32 new_periodicity) external onlyOwner {
      reward_rate = new_periodicity;
    }

    //@dev fallback in order to receive BNB from swapToBNB
    receive () external payable {}
}