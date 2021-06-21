/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amount_in,
        uint amount_out_min,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amount_token_desired,
        uint amount_token_min,
        uint amount_eth_min,
        address to,
        uint deadline
    ) external payable returns (uint amount_token, uint amount_eth, uint liquidity);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TesterWester is IERC20, Ownable {
    //since you're burning tokens you have to implement reward exclusions

    using SafeMath for uint256;
    string public constant name = "testertester";
    string public constant symbol = "ZXDEW";
    uint8 public constant decimals = 9;
    uint256 uint256_max = ~uint256(0);
    uint256 private token_total = 1 * 10**12 * 10**9;
    uint256 private reserve_total = (uint256_max - (uint256_max.mod(token_total))); //maximum divisor

    uint256 public tokens_burned = 0;
    address public burn_address = address(0);

    mapping(address => uint256) private reserves_owned;
    mapping(address => uint256) private tokens_owned;
    mapping(address => bool) private excluded_from_fees;
    mapping(address => mapping (address => uint256)) private allowances;
    mapping(address => bool) private bots;
    mapping(address => uint) private cooldowns;
    //NOTE: max fee does not include team fee
    //and initially, non-team fees will be 8% 
    //this means a potential max fee of 23%
    uint256 private max_fee = 15; 
    uint256 private liquidity_fee = 5;
    uint256 private reflection_fee = 3;
    uint256 private burn_fee = 0;
    uint256 private team_fee = 8;

    uint256 private prev_liq_fee;
    uint256 private prev_refl_fee;
    uint256 private prev_burn_fee;
    uint256 private prev_team_fee;

    uint256 private max_tx_amount = token_total;
    uint256 private liquify_threshold = 100000 * 10**9;
    uint256 private burn_threshold = 10000000 * 10**9;

    uint256 private liquidity_tokens = 0;
    uint256 private fee_tokens = 0;
    uint256 private burn_tokens = 0;

    bool private swap_locked = false;
    bool private trading_open = false;
    bool private cooldown_enabled = false;
    bool private exclude_burn_address = false;

    address private fee_tweaker;
    address payable private fee_addr;

    address private uniswapV2_pair;
    IUniswapV2Router02 private uniswapv2_router;

    event FeesTweaked(
        uint256 liquidity_fee, 
        uint256 reflection_fee, 
        uint256 burn_fee
    );

    event TokensBurned(uint256 num_burned, uint256 threshold, address burn_address);
    event NewBurnThreshold(uint256 old_threshold, uint256 new_threshold);

    constructor(address fee_tweaker_, address payable fee_addr_) {
        fee_addr = fee_addr_;
        reserves_owned[msg.sender] = reserve_total;
        fee_tweaker = fee_tweaker_;
        excluded_from_fees[msg.sender] = true;
        excluded_from_fees[address(this)] = true;
        excluded_from_fees[fee_addr] = true;
    }
    
    modifier onlyFeeTweaker() {
        require(fee_tweaker == _msgSender(), "You are not the fee tweaker");
        _;
    }

    function setBurnThreshold(uint256 new_threshold) public onlyFeeTweaker() {
        require(new_threshold <= 1000000000, "Cannot set burn threshold above 1 trillion tokens");
        uint256 prev_threshold = burn_threshold;
        burn_threshold = new_threshold;
        emit NewBurnThreshold(prev_threshold, new_threshold);
    }

    function tweakFees(uint256 new_liquidity_fee, 
                       uint256 new_reflection_fee, 
                       uint256 new_burn_fee) public onlyFeeTweaker() {
        //The max fee (15%) cannot be changed
        //This is so the community doesn't have to trust the fee tweaker that much
        //Malicious behaviour is thus limited
        uint256 fee_sum = new_liquidity_fee + new_reflection_fee + new_burn_fee;
        require(fee_sum <= max_fee);
        liquidity_fee = new_liquidity_fee;
        reflection_fee = new_reflection_fee;
        burn_fee = new_burn_fee;
        emit FeesTweaked(new_liquidity_fee, new_reflection_fee, new_burn_fee);
    }

    function banBots(address[] memory bots_to_ban) public onlyOwner {
        for (uint i = 0; i < bots_to_ban.length; ++i) {
            bots[bots_to_ban[i]] = true;
        }
    }

    function unbanBot(address unban_me) public onlyOwner {
        bots[unban_me] = false;
    }

    function totalSupply() public override view returns (uint256) {
        return token_total;
    }

    function balanceOf(address token_owner) public override view returns (uint256) {
        if (token_owner == burn_address) 
            return tokens_owned[burn_address];
        return tokenFromReflection(reserves_owned[token_owner]);
    }

    function transfer(address receiver, uint256 num_tokens) public override returns (bool) {
        transferStageInitialChecks(msg.sender, receiver, num_tokens);
        return true;
    }

    function approve(address delegate, uint256 num_tokens) public override returns (bool) {
        require(msg.sender != address(0), "Cannot allow approval from zero address");
        require(delegate != address(0), "Cannot approve the zero address for spending");
        allowances[msg.sender][delegate] = num_tokens;
        emit Approval(msg.sender, delegate, num_tokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowances[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 num_tokens) public override returns (bool) {
        transferStageInitialChecks(owner, buyer, num_tokens);
        approve(owner, allowances[owner][msg.sender].sub(num_tokens, 
            "ERC20: transfer amount exceeds allowance"));
        emit Transfer(owner, buyer, num_tokens);
        return true;
    }

    function approveOthers(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function listAndProvideLiquidity() external onlyOwner() { //we're doing a presale so we need to create the pair later
        require(!trading_open, "Trading has already been opened");
        IUniswapV2Router02 uniswap_router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapv2_router = uniswap_router;
        approveOthers(address(this), address(uniswapv2_router), token_total);
        uniswapV2_pair = IUniswapV2Factory(
            uniswapv2_router.factory()).createPair(
                address(this), uniswapv2_router.WETH()
            );
        uniswapv2_router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        cooldown_enabled = true;
        max_tx_amount = 1 * 10**10 * 10**9;
        //TODO: add cooldown and max tx
        trading_open = true;
        IERC20(uniswapV2_pair).approve(address(uniswapv2_router), type(uint).max);
    }   

    modifier swapLock {
        swap_locked = true;
        _;
        swap_locked = false;
    }

    function setMaxTXPercentage(uint256 new_max_tx) public onlyOwner {
        require(new_max_tx > 0);
        max_tx_amount = token_total.mul(new_max_tx).div(100);

    }

    function transferStageInitialChecks(address from, address to, uint256 amount) private {
        require(from != address(0), "Can't transfer from 0 address");
        require(to != address(0), "Can't transfer to 0 address");
        require(to != burn_address, "Can't transfer to burn address manually");
        require(amount > 0, "Must transfer more than 0 tokens");
        require(!bots[from] && !bots[to], "Not on my watch");
        if (from != owner() && to != owner()) {
            if (from == uniswapV2_pair && to != address(uniswapv2_router) && cooldown_enabled && !excluded_from_fees[to]) {
                require(amount <= max_tx_amount, "Transfer amount exceeds maximum amount");
                require(cooldowns[to] < block.timestamp);
                cooldowns[to] = block.timestamp + (30 seconds);
            }
            if (!swap_locked && from != uniswapV2_pair && trading_open) {
                swapAndLiquify();
            }
        }
        
        transferStageToken(from, to, amount);
    }

    /*function transferStageLiquidity(address from, address to, uint256 amount) private {
        //uint256 contract_token_balance = balanceOf(address(this));
        //consider this:
        //liquidity_tokens or burn_tokens or fee_tokens > maxTX
        //then set them = maxTX ... to preserve maxTX. (cant directly set them
        //to maxTX as this would wipe out tracking & fuck it up)
        if (!swap_locked && from != uniswapV2_pair && trading_open) {
            swapAndLiquify();
        }
        transferStageToken(from, to, amount);
    }*/
    
    //Need to add up all tokens that will be swapped for ETH
    //forget about maxTX for now

    //LOCK THE SWAP SO WE DONT ENTER THIS AGAIN ON THE 
    //ROUTER TRANSACTION CALLS!!

    function getRatio(uint256 numerator, uint256 denominator, uint256 precision) private pure returns (uint256) {
        uint256 _numerator = numerator * 10 **(precision + 1);
        uint256 _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

    function swapAndLiquify() private swapLock {
        uint256 current_rate = getRate();
        uint256 fee_balance = (balanceOf(address(this)));
        fee_balance = fee_balance.sub(burn_tokens).sub(liquidity_tokens);   

        uint256 liq_balance = liquidity_tokens.div(current_rate);
        bool over_liquify_threshold = (liq_balance >= liquify_threshold);
        if (liquidity_fee != 0 && over_liquify_threshold) {
            uint256 half = liq_balance.div(2);
            uint256 other_half = liq_balance.sub(half);
            uint256 initial_balance = address(this).balance;
            uint256 swap_this = half + fee_balance;
            swapTokensForETH(swap_this);
            uint256 new_balance = address(this).balance.sub(initial_balance);
            uint256 liq_share = getRatio(half, swap_this, 4);
            new_balance = new_balance.mul(liq_share).div(10000);
            addLiquidity(other_half, new_balance);
            liquidity_tokens = 0;
        }
        if (fee_tokens > 0) { 
            if (!over_liquify_threshold) {
                swapTokensForETH(fee_balance);
            }
            fee_tokens = 0;
            uint256 balance = address(this).balance;
            if (balance > 0)
                fee_addr.transfer(balance);
        }
        uint256 burn_balance = 0;
        if (burn_balance >= burn_threshold) {
            transferToBurn(burn_balance);
            burn_tokens = 0;
        }
    }
    
    function transferToBurn(uint256 num_burn_tokens) private {
        //The burn address is the only address that will / won't be excluded.
        //included: becomes a 'black-hole', where it grows from reflections, passively decreasing circ. supply
        //excluded: excluding burned address from rewards causes more reflections to holders
        reserves_owned[address(this)] = reserves_owned[address(this)].sub(burn_tokens);
        tokens_owned[burn_address] = tokens_owned[burn_address].add(num_burn_tokens);
        reserves_owned[burn_address] = reserves_owned[burn_address].add(burn_tokens);
        tokens_burned = tokens_burned.add(num_burn_tokens);
        emit TokensBurned(num_burn_tokens, burn_threshold, burn_address);
    }

    function swapTokensForETH(uint256 token_amount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapv2_router.WETH();
        approveOthers(address(this), address(uniswapv2_router), token_amount);
        uniswapv2_router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            token_amount, 
            0, 
            path, 
            address(this), 
            block.timestamp
        );
    }

    function addLiquidity(uint256 token_amount, uint256 eth_amount) private {
        approveOthers(address(this), address(uniswapv2_router), token_amount);
        uniswapv2_router.addLiquidityETH{value: eth_amount}(
            address(this), 
            token_amount, 
            0, 
            0, 
            owner(), 
            block.timestamp
        );
    }

    function disableFees() private {
        if (burn_fee == 0 && liquidity_fee == 0
            && reflection_fee == 0 && team_fee == 0) 
            return;
        prev_burn_fee = burn_fee;
        prev_liq_fee = liquidity_fee;
        prev_refl_fee = reflection_fee;
        prev_team_fee = team_fee;
        burn_fee = 0;
        liquidity_fee = 0;
        reflection_fee = 0;
        team_fee = 0;
    }

    function enableFees() private {
        burn_fee = prev_burn_fee;
        liquidity_fee = prev_liq_fee;
        reflection_fee = prev_refl_fee;
        team_fee = prev_team_fee;
    }

    function transferStageToken(address from, address to, uint256 amount) private {
        bool cancel_fees = false;
        if (excluded_from_fees[from] || excluded_from_fees[to]) {
            cancel_fees = true;
        }

        if (cancel_fees) {
            disableFees();
            transferStageStandard(from, to, amount);
            enableFees();
        }
        else {
            transferStageStandard(from, to, amount);
        }
    }

    function transferStageStandard(address from, address to, uint256 t_initial) private {
        uint256 current_rate = getRate();
        uint256 rteam_fee = calcRValue(current_rate, t_initial, team_fee);
        fee_tokens.add(rteam_fee);
        uint256 rliq_fee = 0;
        if (liquidity_fee != 0) {
            rliq_fee = calcRValue(current_rate, t_initial, liquidity_fee);
            liquidity_tokens.add(rliq_fee);
        }
        uint256 rburn_fee = 0;
        if (burn_fee != 0) {
            rburn_fee = calcRValue(current_rate, t_initial, burn_fee);
            burn_tokens.add(rburn_fee);
        }
        uint256 rrefl_fee = 0;
        if (reflection_fee != 0) {
            rrefl_fee = (t_initial.mul(reflection_fee).div(100)).mul(current_rate);
            reserve_total.sub(rrefl_fee);
        }
        uint256 r_amount = t_initial.mul(current_rate);
        uint256 r_xfer_amount = r_amount.sub(rteam_fee).sub(rburn_fee).sub(rrefl_fee).sub(rliq_fee);
        reserves_owned[from] = reserves_owned[from].sub(r_amount);
        reserves_owned[to] = reserves_owned[to].add(r_xfer_amount);
        emit Transfer(from, to, (r_xfer_amount.div(current_rate)));
    }

    function calcRValue(uint256 current_rate, uint256 t_initial, uint256 fee) private returns (uint256) {
        uint256 rfee = (t_initial.mul(fee).div(100)).mul(current_rate);
        reserves_owned[address(this)] = reserves_owned[address(this)].add(rfee);
        return rfee;
    }

    function tokenFromReflection(uint256 reserve_amount) private view returns (uint256) {
        require (reserve_amount <= reserve_total, "Amount must be less than reserve total");
        uint256 current_rate = getRate();
        return reserve_amount.div(current_rate);
    }

    function getRate() private view returns (uint256) {
        (uint256 reserve_supply, uint256 token_supply) = getSupply();
        return reserve_supply.div(token_supply);
    }

    function getSupply() private view returns(uint256, uint256) {
        uint256 r_supply = reserve_total;
        uint256 t_supply = token_total;
        if (exclude_burn_address) {
            if (reserves_owned[burn_address] > r_supply || tokens_owned[burn_address] > t_supply)
                return (reserve_total, token_total);
            r_supply = r_supply.sub(reserves_owned[burn_address]);
            t_supply = t_supply.sub(tokens_owned[burn_address]);
        }
        if (r_supply < reserve_total.div(token_total)) 
            return (reserve_total, token_total);
        return (r_supply, t_supply);
    }

    receive() external payable {}

    function excludeBurnAddress() public onlyFeeTweaker {
        require(!exclude_burn_address, "Already excluded");
        if (reserves_owned[burn_address] > 0)
            tokens_owned[burn_address] = tokenFromReflection(reserves_owned[burn_address]);
        exclude_burn_address = true;
    }

    function includeBurnAddress() public onlyFeeTweaker {
        require(exclude_burn_address, "Already included");
        tokens_owned[burn_address] = 0;
        exclude_burn_address = false;
    }
}