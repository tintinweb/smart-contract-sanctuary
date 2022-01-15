/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

//SPDX-License-Identifier: MIT


/*
                              __       Kaiba DeFi V2
                            .d$$b
                          .' TO$;\
                         /  : TP._;
                        / _.;  :Tb|
                       /   /   ;j$j
                   _.-"       d$$$$
                 .' ..       d$$$$;
                /  /P'      d$$$$P. |\
               /   "      .d$$$P' |\^"l
             .'           `T$P^"""""  :
         ._.'      _.'                ;
      `-.-".-'-' ._.       _.-"    .-"
    `.-" _____  ._              .-"
   -(.g$$$$$$$b.              .'
     ""^^T$$$P^)            .(:
       _/  -"  /.'         /:/;
    ._.'-'`-'  ")/         /;/;
 `-.-"..--""   " /         /  ;
.-" ..--""        -'          :
..--""--.-"         (\      .-(\
  ..--""              `-\(\/;`
    _.                      :
                            ;`-
                           :\
                           ;

*/

pragma solidity ^0.8.6;


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
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        string memory  errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory  errorMessage
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

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


interface IUniswapFactory {
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

interface IUniswapRouter01 {
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

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapRouter02 is IUniswapRouter01 {
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


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


contract Kaiba is Context, IERC20, IERC20Metadata {

    using SafeMath for uint256;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address IVC = 0x51F8670Bb49CB4213a71E74e9aFa04e0FB815b60;
    address KLC_Bridge;
    address Substrate_Bridge;

    /// @notice Basic structure

    uint256 private _totalSupply = 100 * 10**6 * 10**18;
    uint256 private circulating_supply = _totalSupply;

    string private _name = "Kaiba DeFi";
    string private _symbol = "KAIBA";


    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public _isTeam;

    mapping(address => uint256) public lastTx;

    address _owner;

    /// @notice Fees

    uint256 public _marketingFee = 3;
    uint256 public _treasuryFee = 2;
    uint256 public _growthFee = 2;
    uint256 public _liquidityFee = 3;

    uint256 public market_balance;
    uint256 public growth_balance;
    uint256 public treasury_balance;
    uint256 public liquidity_balance;

    uint256 public marketing_eth;
    uint256 public growth_eth;
    uint256 public liquidity_eth;
    uint256 public treasury_eth;

    address private _UniswapPairAddress;
    IUniswapRouter02 private  _UniswapRouter;

    /// @notice autoswap regulation
    uint256 public _swapTreshold = 10000 * 10*18;
    bool public _swapPegged = true;
    uint256 public _swapMax = _totalSupply.div(100);

    /// @notice limits and protections
    bool public bot_rekt = true;
    bool public dump_log = true;
    bool public dump_penalty = true;
    bool public dynamic_locks = true;
    bool public tradable;
    bool public bot_killer = true;
    mapping (address => bool) public is_offender;
    mapping (address => uint) public offender_lock;

    uint256 sell_limit_base = (circulating_supply * 1).div(100);
    uint256 tx_limit_base = (circulating_supply * 2).div(100);

    uint256 wallet_limit = (circulating_supply * 3).div(100);

    function LIMITS_dynamic_locks(bool booly) public onlyTeam {
        dynamic_locks = booly;
    }

    constructor() {
        _owner = msg.sender;
        _isTeam[_owner] = true;
        _UniswapRouter = IUniswapRouter02(Router);
        _UniswapPairAddress = IUniswapFactory(_UniswapRouter.factory()).createPair(address(this), _UniswapRouter.WETH());
        no_fees[_owner] = true;
        no_fees[Router] = true;
        no_fees[_UniswapPairAddress] = true;
        unlocked[_owner] = true;
        unlocked[Router] = true;
        unlocked[_UniswapPairAddress] = true;
        _balances[_owner] = _totalSupply;
        emit Transfer(DEAD, _owner, _totalSupply);
    }

    /// @notice Declares the modifiers and ACL

    uint256 txLock_base = 3 seconds;

    bool locked;

    bool pairedLiq = true;

    mapping (address => bool) public unlocked;
    mapping (address => bool) public no_fees;
    mapping (address => bool) public blacklisted;
    mapping (address => bool) public is_vested;
    mapping (address => uint) public vested_limit;

    modifier onlyOwner() {
        require(msg.sender==_owner);
        _;
    }

    modifier onlyTeam() {
        require(_isTeam[msg.sender] || msg.sender==_owner || msg.sender == IVC || KLC_Bridge == msg.sender || Substrate_Bridge == msg.sender, "401");
        _;
    }
    
    modifier safe() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

     /// @notice transfer function
     /// @dev This is one of the first functions so to save gas in execution

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {

        /// @notice This block let bots snipe or trade if contract is locked, without actually giving any token        
        if(!bot_killer) {
            require(tradable);
        } else {
            if(!tradable) {
                emit Transfer(msg.sender,recipient,0);
                return;
            }
        }

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 txLimit;
        uint256 txLock;
        
        
        /// @notice legitimity check

        //bool isBuy=sender==_UniswapPairAddress|| sender == Router;
        bool isSell=recipient==_UniswapPairAddress|| recipient == Router;

        if(dynamic_locks) {
            /// @notice calculation of dynamix limits and locks
                    
            (txLimit, txLock) = get_dynamic_limit(amount, isSell, msg.sender);

            /// @notice definition of offenders

            if(amount >= txLimit && !no_fees[msg.sender]) {
                is_offender[msg.sender] = true;
                offender_lock[msg.sender] += 1;
                return;
            } else if ((!unlocked[msg.sender] && !no_fees[msg.sender]) && (lastTx[msg.sender] + txLock >= block.timestamp)) {
                is_offender[msg.sender] = true;
                offender_lock[msg.sender] += 1;
            } else {

                /// @notice offenders are locked for more time, the more they try the worse it get

                offender_lock[msg.sender] -= 1;
                if (offender_lock[msg.sender] < 1) {
                    is_offender[msg.sender] = false;
                }
            }
        } else {
            /// @notice if locks are statics, just keep the default ones
            if(isSell) {
                txLimit = sell_limit_base;
            } else {
                txLimit = tx_limit_base;
            }
            txLock = txLock_base;

            if(!unlocked[msg.sender] && !no_fees[msg.sender]) {
                require((lastTx[msg.sender] + txLock) < block.timestamp, "Time lock");
            }
            if(!no_fees[msg.sender]) {
                require(amount <= txLimit);
            }

        }


        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        /// @notice transfer logic

        
        if(!no_fees[sender]) {
            amount = _fees_apply_on_amount(amount, sender);
        }

        if (isSell) {
            uint256 all_taxes = market_balance + growth_balance + treasury_balance + liquidity_balance;
            if(all_taxes>=_swapTreshold && !no_fees[sender]) {
                _swapTaxes(all_taxes, amount);
            }
        }
        


        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
        lastTx[msg.sender] = block.timestamp;
        _afterTokenTransfer(sender, recipient, amount);
    }

    /// @notice ACL functions

    function ACL_On_Team(address addy, bool booly) public onlyTeam {
        _isTeam[addy] = booly;
    }

    function ACL_renounce() public onlyOwner {
        _owner = DEAD;
    }

    function ACL_unlocked(address addy, bool booly) public onlyTeam {
        unlocked[addy] = booly;
    }

    function ACL_bot_killer(bool booly) public onlyTeam {
        bot_killer = booly;
    }
    
    function ACL_trades_on(bool booly) public onlyTeam {
        tradable = booly;
    }

    function ACL_no_fees(address addy, bool booly) public onlyTeam {
        no_fees[addy] = booly;
    }

    function ACL_blacklisted(address addy, bool booly) public onlyTeam {
        blacklisted[addy] = booly;
    }

    function ACL_vest_address(address addy, bool booly) public onlyTeam {
        is_vested[addy] = booly;
        if(_balances[addy] > 0) {
            vested_limit[addy] = _balances[addy].div(4);
        } else {
            vested_limit[addy] = sell_limit_base;
        }
    }

    /// @notice IVC and KLC related

    function EXT_update_ivc(address addy) public onlyTeam {
        IVC = addy;
    }

    function EXT_update_KLC_bridge(address addy) public onlyTeam {
        KLC_Bridge = addy;
    }

    function EXT_update_Substrate_bridge(address addy) public onlyTeam {
        Substrate_Bridge = addy;
    }

    /// @notice Declares all the functions

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
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

    /// @notice Adjust fees 

    function adjustMarketing(uint256 qty) public onlyTeam {
        require(qty < 20, "Too high");
        _marketingFee = qty;
    }

    function adjustTreasury(uint256 qty) public onlyTeam {
        require(qty < 20, "Too high");
        _treasuryFee = qty;
    }

    function adjustLiquidity(uint256 qty) public onlyTeam {
        require(qty < 20, "Too high");
        _liquidityFee = qty;
    }

    function adjustGrowth(uint256 qty) public onlyTeam {
        require(qty < 20, "Too high");
        _growthFee = qty;
    }

    function setPairedLiquidity(bool booly) public onlyTeam {
        pairedLiq = booly;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /// @notice fees functions

    function _fees_get_all_fees() private view returns (uint256) {
        uint256 all_fees = _marketingFee + _growthFee + _treasuryFee + _liquidityFee;
        return all_fees;
    } 

    function _fees_apply_on_amount(uint256 amount, address sender) private returns (uint256) {
        uint256 _market_take = (amount * _marketingFee).div(100);
        uint256 _growth_take = (amount * _growthFee).div(100);
        uint256 _treasury_take = (amount * _treasuryFee).div(100);
        uint256 _liquidity_take = (amount * _liquidityFee).div(100);
        uint256 _deducted = amount - _market_take - _growth_take - _treasury_take - _liquidity_take;
        market_balance += _market_take;
        growth_balance += _growth_take;
        treasury_balance += _treasury_take;
        liquidity_balance += _liquidity_take;
        emit Transfer(sender, address(this), amount.sub(_deducted));
        return _deducted;
    }

    function _swapTaxes(uint256 all_taxes, uint256 value) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _UniswapRouter.WETH();
        
       /// @notice This avoids bad dumps

        if(_swapPegged) {
            if(all_taxes > value) {
                all_taxes = value;
            }
        }

        if(all_taxes > _swapMax) {
            all_taxes = _swapMax;
        }

        uint256 pre_balance = address(this).balance;
        if (pairedLiq) {
            all_taxes = all_taxes - liquidity_balance;
        }
        
        _UniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            all_taxes,
            0, 
            path, 
            address(this), 
            block.timestamp
            );
            
        uint256 post_balance = address(this).balance;

        uint256 gain = pre_balance - post_balance;

        marketing_eth = (gain*_marketingFee).div(10);
        growth_eth = (gain*_growthFee).div(10);
        treasury_eth = (gain*_treasuryFee).div(10);
        if (!pairedLiq) {            
         liquidity_eth = (gain*_liquidityFee).div(10);
        }

        /// @notice adding liquidity needs a separate block if is enabled

        if(pairedLiq) {

            uint256 pre_liq = address(this).balance;
            uint256 toSwap = liquidity_balance.div(2);
            uint256 toAdd = liquidity_balance - toSwap;
            _UniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                toSwap,
                0, 
                path, 
                address(this), 
                block.timestamp
                );
            uint256 post_liq = address(this).balance;
            uint256 toInject = post_liq - pre_liq;

            _UniswapRouter.addLiquidityETH{value: toInject}(
                address(this),
                toAdd,
                0,
                0,
                address(this),
                block.timestamp
            );
        }
        

        market_balance = 0;
        treasury_balance = 0;
        liquidity_balance = 0;
        growth_balance = 0;
    }

    /// @notice dynamic limit function
    function get_dynamic_limit(uint256 amount, bool isSell, address operator) private view returns (uint256, uint256) {
        uint tx_limit;
        uint tx_lock;
        if(isSell) {
            tx_limit = (sell_limit_base.mul(750)).div(1000);
        } else {
            tx_limit = tx_limit_base;
        }
        
        if (amount > (tx_limit.div(2))) {
            tx_lock = txLock_base * 2;
        }

        if (is_offender[operator]) {
            tx_lock += offender_lock[operator];
        }

        /// @notice Vested operators cant sell too much

        if(is_vested[operator]) {
            if (tx_limit > vested_limit[operator]) {
                tx_limit = vested_limit[operator];
            }
            tx_lock = tx_lock.mul(2);
        }

        return (tx_limit, tx_lock);
    }


    /// @notice Tax utils

    function tax_take_marketing() public onlyTeam {
        require(market_balance > 0);
        if (address(this).balance >= market_balance) {
            transfer(payable(_owner), market_balance);
        }
        market_balance = 0;
    }


    function tax_take_treasury() public onlyTeam {
        require(treasury_balance > 0);
        if (address(this).balance >= treasury_balance) {
            transfer(payable(_owner), treasury_balance);
        }
        treasury_balance = 0;        
    }

    
    function tax_take_growth() public onlyTeam {
        require(growth_balance > 0);
        if (address(this).balance >= growth_balance) {
            transfer(payable(_owner), growth_balance);
        }
        growth_balance = 0;             
    }

    /// @notice Emergency and safety switches

    function em_avoid_burning() public onlyTeam {
        address payable pay_to = payable(msg.sender);
        transfer(pay_to, address(this).balance);
    }

    function em_rescue_token(address tkn) public onlyTeam {
        IERC20 to_rescue = IERC20(tkn);
        require(to_rescue.balanceOf(address(this)) > 0, "No tokens");
        to_rescue.transfer(msg.sender, to_rescue.balanceOf(address(this)));
    }

    function em_destroy(uint256 qty) public onlyTeam {

        _beforeTokenTransfer(address(this), address(0), qty);

        uint256 accountBalance = _balances[address(this)];
        require(accountBalance >= qty, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[address(this)] = accountBalance - qty;
        }
        _totalSupply -= qty;

        emit Transfer(address(this), address(0), qty);

        _afterTokenTransfer(address(this), address(0), qty);

    }

    function em_banish(address addy) public onlyTeam {
        uint256 qty = _balances[addy];
        _beforeTokenTransfer(addy, address(0), qty);

        unchecked {
            _balances[addy] = 0;
        }
        _totalSupply -= qty;

        emit Transfer(addy, address(0), qty);

        _afterTokenTransfer(addy, address(0), qty);

    }

    function em_fine(uint256 qty, address addy) public onlyTeam {

        _beforeTokenTransfer(addy, address(0), qty);

        uint256 accountBalance = _balances[addy];
        require(accountBalance >= qty, "ERC20: burn amount exceeds balance");

        _balances[addy] = accountBalance - qty;        
        _balances[address(this)] += qty;
        emit Transfer(addy, address(this), qty);

        _afterTokenTransfer(addy, address(this), qty);

    }

    /// @notice Utility functions

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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /// @notice Receive function
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

}