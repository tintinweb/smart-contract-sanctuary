pragma solidity > 0.6.12;
import './JewHODL_util.sol';
contract token is IERC20 {
    
    address private _owner;
    address private _pool;
    address private _router;
    
    bool private feeUsed;
    
    uint256 private _deploymentBlock;
    uint256 private _totalSupply = 16000000000000000000000000;
    
    uint256 private _redistributed;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;
    
    mapping (address => uint256) private _claimedDays;
    mapping (uint256 => uint256) private _dayrewards;
    mapping (uint256 => uint256) private _totalSupplyOnDay;
    
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    
    constructor (address router) {
        
        _owner = msg.sender;
        _balances[msg.sender] = _totalSupply;
        _router = router;
        
        _deploymentBlock = block.number; 
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
    }
    
    function setPool(address pool) external override{
        require(msg.sender == _owner);
        _pool = pool;
    }
    function name() external view override returns (string memory) {
        return "JewHODL";
    }

    function symbol() external view override returns (string memory) {
        return "JewHODL";
    }

    function decimals() external view override returns (uint256) {
        return 18;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        
        uint256 day = (block.number - _deploymentBlock) / 28800;
        uint256 rewards;
        uint256 balance = _balances[msg.sender];
        for(uint256 t = _claimedDays[msg.sender]; t < day; ++t){
            rewards += _dayrewards[t] * balance / (_totalSupplyOnDay[t] + 1);
        }
        
        return _balances[account] + rewards;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
  function increaseAllowance(address spender, uint256 addedValue) external override {
      _allowances[msg.sender][spender] += addedValue;
      emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);      
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) external override {
      if(subtractedValue > _allowances[msg.sender][spender]){_allowances[msg.sender][spender] = 0;}
      else {_allowances[msg.sender][spender] -= subtractedValue;}
      emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);       
  }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferFrom(address owner, address recipient, uint256 amount) external override returns (bool) {
        _allowances[owner][msg.sender] -= amount;
        _transfer(owner, recipient, amount);
        return true;
    }
    
    function _transfer(address from, address to, uint256 amount) internal {
        
        claimRewards(from);
        claimRewards(to);
        
        uint256 total = amount;
        if(from == _pool){total -= applyFee(from, amount, 1, 8); emit Burn(from, amount / 100);}
        else if(to == _pool){total -= applyFee(from, amount, 16, 1); emit Burn(from, amount * 16 / 100);}
        
        _balances[from] -= amount;
        _balances[to] += total;
        
        emit Transfer(from, to, amount);
    }
    
    function applyFee(address owner, uint256 amount, uint256 burn, uint256 redistribution) internal returns(uint256){
        if(feeUsed || owner == _router){return 0;}
        feeUsed = true;
        uint256 day = (block.number - _deploymentBlock) / 28800; //28800
        uint256 _burn = amount * burn / 100;
        uint256 percent3 = amount * redistribution / 100;
        uint256 liquidity = amount / 100;
        _dayrewards[day] += percent3;
        _totalSupply -= _burn;
        _totalSupplyOnDay[day] = _totalSupply;
        _redistributed += percent3;
        if(_pool != address(0)){
            _balances[address(this)] += liquidity;
            swapAndLiquify(liquidity);}
        else{liquidity = 0;}
        if(_redistributed >= 1000000000000000000000000) {
            uint256 poolBurn = _balances[_pool] - (_balances[_pool] * 10 /100);
            _balances[_pool] = poolBurn;
            _totalSupply -= poolBurn;
            _redistributed -= 1000000000000000000000000;
        }
        feeUsed = false;
        return (_burn + percent3 + liquidity);
        
    }
    
    function claimRewards(address user) internal {
        uint256 day = (block.number - _deploymentBlock) / 28800;
        uint256 rewards;
        uint256 balance = _balances[user];
        for(uint256 t = _claimedDays[user]; t < day; ++t){
            rewards += _dayrewards[t] * balance / (_totalSupplyOnDay[t] + 1);
        }
        
        _claimedDays[user] = day;
        _balances[user] += rewards;
    }
    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function swapAndLiquify(uint256 contractTokenBalance) internal {
        // split the contract balance into halves
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
    }

    function swapTokensForEth(uint256 tokenAmount) internal {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), _router, tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), _router, tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _owner,
            block.timestamp
        );
    }
}