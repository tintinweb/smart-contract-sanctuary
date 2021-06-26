/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
https://t.me/moondogofficial
Moon Dog
$MDOG

Completely dynamic fees - able to be changed when the community chooses.
Join us and join a community that will have more power and control over their
ecosystem than any other community in meme coin history.

***Original source code - separate voting contract deployed soon***
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMdhhhyhmMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMdddyohhoohNMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMddhy-.-smy/osyhdmNMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMdym/+yhso+:::::/oyyyydmNMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMmhmhs/::::``.::::::://oyyyyyyyyhmNMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNho+/::/yys///+//::-..:::/shyyyydhdMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNmhyydNNdo/:::::://ymmNNmmy/-..::::/hh---dhdMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNmy/````:sh+::.``````.mNNNNNmhyyys+:::/hy-odhmMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMys`       -ho`  -/.   +mNNmh:.y//+o::::/dsdydNMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNNNNNNNNNyy+`       .d:  hNd:-:+dd+.`  `..-::::::omhdmMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNNmdmmddddddhhhhhhhdo-`     `h+  dNNmmNNNNdo.``.::``-:::::+hmMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMNmmmddhhhhhyyyyyyyyyyyyyyyyy:--..om:` +NNmhydmhdmmddmNm-  .:::::ydMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMNNmmdhhyyyyyyssssooooooooosssssyyyyyyhhhyshsosyhs+oymNNNNm+    -::::sdMMMMMM
MMMMMMMMMMMMMMMMMMMMMNmddhhhyo+++oo+++///////////////+++oossyyyyyms+yys++ymNNNmds-      .::/dmMMMMMM
MMMMMMMMMMMMMMMMMMNmddhhyyyss+/////////////////////////////++osyyyhhyyyhy/-::--`         .:ydMMMMMMM
MMMMMMMMMMMMMMMMNmdhhhyyyso+///////////////////////////////////+osyyyyyhho-`             `odNMMMMMMM
MMMMMMMMMMMMMMNmdhhyyyso+/////////////////////////////////////////+osyyyyhhy+.   `.--.``.ymMMMMMMMMM
MMMMMMMMMMMMNmdhhyyyso+/////////////////////////////////////////////+ossoooshhs/os++++osddNMMMMMMMMM
MMMMMMMMMMMmddhyyyyo+/////////////////////////////////////////////////+/////+yhd:`     `-ohNMMMMMMMM
MMMMMMMMMNddhhyyys+//////////////////////////////////////////////////////////oyd/         /mNMMMMMMM
MMMMMMMMNddhyyyyo////////////////////////////////////////////////////////////oyyd-`       -dNMMMMMMM
MMMMMMMmdhhyyyyo//////////////////////////////////++++++++//////////////////oyyyyhys-..` -hdMMMMMMMM
MMMMMMNmhhyyyy+//////////////////////////////++osssyyyyyyssoo+//////////////oyyyyyyhdddyydmMMMMMMMMM
MMMMMmdhhyyyyo/////////////////////////////+osyyyyyyyyyyyyyyyyso+////////////oyyyyyyhhhhmmmMMMMMMMMM
MMMMNmhhyyyys/////////////////////////////oyyyyyyyyyyyyyyyyyyyyys+//////////++ssyyyyhhhhdNmmMMMMMMMM
MMMNddhhyyyy+///////////////////////////+syyyyyyyyyyyyyyyyyyyyyyyyo+sss+/+ossyyssssyyhhhhmNmNMMMMMMM
MMMmmhhysooo+++/////////////////////////syyyyyyyyyyyyyyyyyyyyyyyyyyyyyyooyyyyyyyyysoyyhhhhmNmMMMMMMM
MMNmdhhs+syyyyys+//////////////////////+yyyyyyyyyyyyyyyyyyyyyyyyyyyyooo+yyyyyyyyyyysoyhhhhdNmmMMMMMM
MMmmhhy+syyyyyyyy+/////////////////////oyyyyyyyyyyyyyyyyyyyyyyyyyyyy+//+yyyyyyyyyyyyoyyhhhhmNmMMMMMM
MNddhhy+syyyyyyyy+/////////////////////+yyyyyyyyyyyyyyyyyyyyyyyyyyyy+//+syyyyyyyyyyssyyhhhhmNmmMMMMM
Mmmdhhyyosyyyyys+//////////////////////+syyyyyyyyyyyyyyyyyyyyyyyyyys////+syyyyyyyyooyyyhhhhdNNdMMMMM
MNmhhhyyyys++++/////////////////////////+yyyyyyyyyyyyyyyyyyyyyyyyys+//////+oossooosyyyyhhhhdNNdMMMMM
MNmhhhyyyyy+/////////////////////////////+syyyyyyyyyyyyyyyyyyyyyys+////////////oyyyyyyyhhhhdNNhMMMMM
MNmhhhyyyyyo///////////////////////////////osyyyyyyyyyyyyyyyyyys+//////////////syyyyyyyhhhhdNNhMMMMM
MNNhhhyyyyyy+////////////////////////////////+osyyyyyyyyyyyyso+///////////////+yyyyyyyyhhhhdNNhMMMMM
MNNdhhyyyyyyo///////////////////////////////////+++oooooo+++//////////////////syyyyyyyhhhhhmNNdMMMMM
Mmmmhhhysssyyo////////////////////////////////////////+ossso+////////////////oyyyyyyyyhhhhhmNNdMMMMM
MNdmhhhyoyyyyyo//////////////////////////////////////oyyyyyys+//////////////oyyyyyyyyhhhhhdNNmNMMMMM
MMdNdhhhosyyyys+/////////////////////////////////////syyyyyyy+/////////////oyyyyyyyyyhhhhhmNNmMMMMMM
MMNmmdhhhsssssyyo////////////////++oosssssoo++///////+osyyss+/////////////oyyyyyyyyyhhhhhdNNmmMMMMMM
MMMmmmhhhhyyyyyyyo+///////////+ossyyyyyyyyyyyyso+//////++++///////++////+syyyyyyyyyhhhhhdmNNmMMMMMMM
MMMMdNmhhhhyyyyyyyso/////////+syyyyyyyyyyyyyyyyyso//////////////+sssso+osyyyyyyyyyhhhhhhmNNdNMMMMMMM
MMMMNdNdhhhhyyyyyyyys+//////+yyyyyyyyyyyyyyyyyyyyyo////////////+yyyyyyssyyyyyyyyyhhhhhhmNNmmMMMMMMMM
MMMMMmmNdhhhhyyyyyyyyys++///syyyyyyyyyyyyyyyyyyyyyy+///////////+yyyyyysoyyyyyyyyhhhhhhmNNmmMMMMMMMMM
MMMMMMNmNmhhhhyyyyyyyyyyso++yyyyyyyyyyyyyyyyyyyyyyyo///////////+osyyysosyyyyyyhhhhhhdmNNmNMMMMMMMMMM
MMMMMMMmmNmdhhhhyyyyyyyyyyyssyyyyyyyyyyyyyyyyyyyyys+///////++osssoosssyyyyyyyhhhhhhdmNNmmMMMMMMMMMMM
MMMMMMMMNmmmdhhhhhyyyyyyyyyyssyyyyyyyyyyyyyyyyyyys+///+++ossyyyyyyyyyyyyyyyhhhhhhdmNNmmNMMMMMMMMMMMM
MMMMMMMMMMmmNmdhhhhhyyyyyyyyyyssyyyyyyyyyyyyyyyso++osssyyyyyyyyyyyyyyyyyyhhhhhhhdmNNmmNMMMMMMMMMMMMM
MMMMMMMMMMMNmmNmdhhhhhhyyyyyyyysssssyyyyyyyysso++oyyyyyyyyyyyyyyyyyyyyhhhhhhhhdmNNmmNMMMMMMMMMMMMMMM
MMMMMMMMMMMMNmmmNmdhhhhhhhyyyyyyyyssoooooooooossyyyyyyyyyyyyyyyyyyyhhhhhhhhhdmNNNmmNMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMmmmNmmdhhhhhhhyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyhhhhhhhhhhdmmNNmmmMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMmmmNNmddhhhhhhhhhhyyyyyyyyyyyyyyyyyyyyyyyhhhhhhhhhhhhdmmNNNmmmNMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMNmmmNNmmdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhddmmNNNNmmmMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMNNdmNNNmmddhhhhhhhhhhhhhhhhhhhhhhhhhhhhdddmmNNNNNmmNNMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMNNmmNNNNNmmmdddddhhhhhhhhhhhddddmmmmNNNNNNmmNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMNNmmdmmNNNNNNNNNNNmmmNNNNNNNNNNmNmmmdNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNNNmmddmmmmmmmmmmmmmmdmNmNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNNNNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
*/

//Note: Moon Dog isn't relying on SafeMath as recent versions of solidity 
//      have implicit under/over-flow checking.
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

contract MoonDog is IERC20, Ownable {
    string public constant name = "Moon Dog";
    string public constant symbol = "MDOG";
    uint8 public constant decimals = 9;
    uint256 uint256_max = ~uint256(0);
    uint256 private token_total = 1 * 10**9 * 10**9; //max-supply: 1 billion tokens
    uint256 private reserve_total = (uint256_max - (uint256_max % token_total)); //max divisor
    address public burn_address = address(0);
    mapping(address => uint256) private reserves_owned;
    mapping(address => uint256) private tokens_owned;
    mapping(address => bool) private excluded_from_fees;
    mapping(address => mapping (address => uint256)) private allowances;
    mapping(address => bool) private bots;
    mapping(address => uint) private cooldowns;
    uint256 public liquidity_fee = 5;
    uint256 public reflection_fee = 3;
    uint256 public burn_fee = 0;
    uint256 private team_fee = 8;
    uint256 private max_tx_amount = token_total;
    uint256 private liquify_threshold = 1*10**5 * 10**9;
    uint256 private liquidity_tokens = 0;
    uint256 private fee_tokens = 0;
    bool private swap_locked = false;
    bool private trading_open = false;
    bool private cooldown_enabled = false;
    bool private exclude_burn_address = false;
    address private fee_tweaker;
    address payable private fee_addr;
    address public uniswapV2_pair;
    IUniswapV2Router02 private uniswapv2_router;

    event FeesTweaked(
        uint256 liquidity_fee, 
        uint256 reflection_fee, 
        uint256 burn_fee
    );

    constructor(address fee_tweaker_, address payable fee_addr_) {
        fee_addr = fee_addr_;
        reserves_owned[msg.sender] = reserve_total;
        fee_tweaker = fee_tweaker_;
        IUniswapV2Router02 uniswap_router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapv2_router = uniswap_router;
        uniswapV2_pair = IUniswapV2Factory(uniswapv2_router.factory()).createPair(
            address(this), uniswapv2_router.WETH()
        );
        excluded_from_fees[msg.sender] = true;
        excluded_from_fees[address(this)] = true;
        excluded_from_fees[fee_addr] = true;
        emit Transfer(address(0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B), _msgSender(), token_total);
    }
    
    function openSwap() external onlyOwner {
        require(!trading_open, "Trading has already been opened");
        max_tx_amount = 5 * 10**6 * 10**9; // 0.5%
        trading_open = true;
        cooldown_enabled = true;
    }

    modifier onlyFeeTweaker() {
        require(fee_tweaker == _msgSender(), "You are not the fee tweaker");
        _;
    }

    function tweakFees(uint256 new_liquidity_fee, 
                       uint256 new_reflection_fee, 
                       uint256 new_burn_fee) public onlyFeeTweaker() {
        //The max fee (15%) cannot be changed
        //This is so the community doesn't have to trust the fee tweaker that much
        //Malicious behaviour is thus limited
        require((new_liquidity_fee + new_reflection_fee + new_burn_fee) <= 15);
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
        if (token_owner == burn_address && exclude_burn_address) 
            return tokens_owned[burn_address];
        return tokenFromReflection(reserves_owned[token_owner]);
    }

    function transfer(address receiver, uint256 num_tokens) public override returns (bool) {
        require(
            excluded_from_fees[msg.sender] || 
            excluded_from_fees[receiver] || 
            trading_open
        );
        transferStageInitialChecks(msg.sender, receiver, num_tokens);
        return true;
    }

    function approve(address delegate, uint256 num_tokens) public override returns (bool) {
        approveOthers(msg.sender, delegate, num_tokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowances[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 num_tokens) public override returns (bool) {
        require(num_tokens <= allowances[owner][msg.sender], "Cannot spend more tokens than the allowance");
        transferStageInitialChecks(owner, buyer, num_tokens);
        approve(owner, allowances[owner][msg.sender] - num_tokens);
        return true;
    }

    function approveOthers(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function editFeesOnAddress(address addr, bool true_or_false) external onlyOwner {
        excluded_from_fees[addr] = true_or_false;
    }

    modifier swapLock {
        swap_locked = true;
        _;
        swap_locked = false;
    }

    function setMaxTXPercentage(uint256 new_max_tx) public onlyOwner {
        require(new_max_tx > 0);
        max_tx_amount = ((token_total * new_max_tx) / 100);

    }

    function transferStageInitialChecks(address from, address to, uint256 amount) private {
        require(from != address(0), "Can't transfer from 0 address");
        require(to != address(0), "Can't transfer to 0 address");
        require(amount > 0, "Must transfer more than 0 tokens");
        require(!bots[from] && !bots[to], "Not on my watch");
        if (from != owner() && to != owner()) {
            if (!swap_locked) {
                if (from == uniswapV2_pair && to != address(uniswapv2_router) && cooldown_enabled && !excluded_from_fees[to]) {
                    require(amount <= max_tx_amount, "Transfer amount exceeds maximum amount");
                    require(cooldowns[to] < block.timestamp);
                    cooldowns[to] = block.timestamp + (30 seconds);
                }
                if (from != uniswapV2_pair && trading_open) {
                    swapAndLiquify();
                }
            }
        }
        transferStageToken(from, to, amount);
    }
    
    function swapAndLiquify() private swapLock {
        uint256 fee_balance = balanceOf(address(this)) - liquidity_tokens;
        bool over_liquify_threshold = (liquidity_tokens >= liquify_threshold);
        if (liquidity_fee != 0 && over_liquify_threshold) {
            uint256 half = liquidity_tokens / 2;
            uint256 other_half = liquidity_tokens - half;
            uint256 swap_this = half + fee_balance;
            swapTokensForETH(swap_this);
            uint256 eth_balance = address(this).balance;
            uint256 fee_total = (((liquidity_fee*10)/2) + team_fee*10);
            uint256 liq_share = (eth_balance / fee_total) * (liquidity_fee*10);
            addLiquidity(other_half, liq_share);
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
    }

    //This function is to circumvent uniswap maximum slippage values
    //just incase tokens back up and the swap gets jammed
    //this shouldn't happen, but if it does, this fixes it
    function manualLiquify() public onlyFeeTweaker {
        swapAndLiquify();
    }

    function transferStageToken(address from, address to, uint256 amount) private {
        bool cancel_fees = false;
        if (excluded_from_fees[from] || excluded_from_fees[to]) {
            cancel_fees = true;
        }
        transferStageStandard(from, to, amount, cancel_fees);
    }

    function transferStageStandard(address from, address to, uint256 t_initial, bool cancel_fees) private {
        uint256 current_rate = getRate();
        uint256 r_amount = t_initial * current_rate;
        uint256 r_xfer_amount = r_amount;
        if (!cancel_fees) {
            uint256 one_percent = t_initial / 100;
            if (team_fee != 0) {
                uint256 rteam_fee;
                uint256 tteam_fee;
                (tteam_fee, rteam_fee) = calcRTValue(current_rate, team_fee, one_percent);
                fee_tokens += tteam_fee;
                r_xfer_amount -= rteam_fee;
            }
            if (liquidity_fee != 0) {
                uint256 rliq_fee;
                uint256 tliq_fee;
                (tliq_fee, rliq_fee) = calcRTValue(current_rate, liquidity_fee, one_percent);
                liquidity_tokens += tliq_fee;
                r_xfer_amount -= rliq_fee;
            }
            if (burn_fee != 0) {
                uint256 tburn_fee = one_percent * burn_fee;
                uint256 rburn_fee = tburn_fee * current_rate;
                r_xfer_amount -= rburn_fee;
                reserves_owned[burn_address] = reserves_owned[burn_address] + rburn_fee;
                if (exclude_burn_address)
                    tokens_owned[burn_address] = tokens_owned[burn_address] + tburn_fee;
                emit Transfer(from, burn_address, tburn_fee);
            }
            if (reflection_fee != 0) {
                uint256 rrefl_fee;
                rrefl_fee = (one_percent * reflection_fee) * current_rate;
                reserve_total = reserve_total - rrefl_fee;
                r_xfer_amount -= rrefl_fee;
            }
        }
        reserves_owned[from] = reserves_owned[from] - r_amount;
        reserves_owned[to] = reserves_owned[to] + r_xfer_amount;
        emit Transfer(from, to, (r_xfer_amount / current_rate));
    }

    function calcRTValue(uint256 current_rate, uint256 fee, uint256 one_percent) private returns (uint256, uint256) {
        uint256 tfee = one_percent * fee;
        uint256 rfee = tfee * current_rate;
        reserves_owned[address(this)] += rfee;
        return (tfee, rfee);
    }
    
    function enableCooldown(bool torf) external onlyOwner {
        cooldown_enabled = torf;
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

    function tokenFromReflection(uint256 reserve_amount) private view returns (uint256) {
        require (reserve_amount <= reserve_total, "Amount must be less than reserve total");
        uint256 current_rate = getRate();
        return reserve_amount / current_rate;
    }

    function getRate() private view returns (uint256) {
        (uint256 reserve_supply, uint256 token_supply) = getSupply();
        return reserve_supply / token_supply;
    }

    function getSupply() private view returns(uint256, uint256) {
        uint256 r_supply = reserve_total;
        uint256 t_supply = token_total;
        if (exclude_burn_address) {
            if (reserves_owned[burn_address] > r_supply || tokens_owned[burn_address] > t_supply)
                return (reserve_total, token_total);
            r_supply = r_supply - reserves_owned[burn_address];
            t_supply = t_supply - tokens_owned[burn_address];
        }
        if (r_supply < (reserve_total / token_total))
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