/*
https://t.me/apestax

APE SAFE
https://apesafe.web.app/

APE STAX
https://apestax.com
https://twitter.com/ape_stax
https://www.reddit.com/r/APESTAX
https://www.instagram.com/apestax

Welcome to the jungle. 
APE SAFE is a utility token for the APE ecosystem.

10% buy tax: 3.3% buyback, 3.4% marketing, 3.3% USDC redistribution
12.5% sell tax: 3.5% buyback, 4% marketing, 5% USDC redistribution

1 trillion token supply
10 second cooldown between transfers for buys. 
30 second cooldown between transfers for sells and wallet to wallet.

First 10 minutes buy limit of 1% total supply (10000000000 tokens)
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/utils/Context.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/utils/Address.sol";

contract APESAFE is Context, IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    // ERC20 
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private constant _totalSupply = 10**12 * 10**_decimals;
    string private constant _name = 'APE SAFE';
    string private constant _symbol = 'APESAFE \xF0\x9F\xA6\x8D';
    uint8 private constant _decimals = 9;
    
    // uniswap
    address public constant uniswapV2RouterAddr = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAddr);
    address public constant uniswapV2FactoryAddr = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address public liquidityPoolAddr = UniswapV2Library.pairFor(uniswapV2FactoryAddr, uniswapV2Router.WETH(), address(this));
    // USDC Redis
    uint256 USDCPoolBalance;
    struct Holder {
        uint256 allocInLastPos;
        uint256 redisPoolInLastPos;
        uint256 withdrawnAlloc;
        uint256 timeTransfer;
        bool hasPos;
    }
    // first 10 minutes there is a buy limit of 10 bn
    uint256 private constant _buyLimit = 10000000000 * 10**_decimals;
    uint256 private constant _buyLimitTime = 10 minutes;
    uint256 private _buyCooldown = 10 seconds;
    uint256 private _sellCooldown = 30 seconds;
    uint256 private _w2wCooldown = 30 seconds;
    bool public w2wCooldownEnabled; 
    bool public sellCooldownEnabled; 
    bool public buyCooldownEnabled; 
    bool public swapEnabled; 
    bool public lfg;
    uint256 public lfgTime;
    mapping (address => Holder) public holders;
    mapping (address => bool) private excludedFromRewards;
    mapping (address => bool) private excludedFromTaxes;
    uint256 public fundsUnlockTime;
    address public USDCAddr = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 USDC = IERC20(USDCAddr);
    
    // taxes
    struct Taxes {
        uint256 redistribution;
        uint256 marketing;
        uint256 buyback;
    }
    address payable public marketingAddr = payable(0x8c45c344de8A19cAfD0cCCE300AB9DE397b7D886);
    address payable public buybackAddr = payable(0x02a051380adF7DA7A44706AA0Ba0880c3C4568a0);
    Taxes private _buyTaxrates = Taxes(33, 34, 33);
    Taxes private _sellTaxrates = Taxes(50, 40, 35);
    Taxes private _w2wTaxrates = Taxes(50, 40, 35);
    uint256 public pendingRedisTokens;
    uint256 public pendingBuybackTokens;
    
    // whitelist for making special transfers, untaxed, "unswapped" and unrewarded
    mapping (address => bool) public whitelist;
    // blacklist to block transfers
    mapping (address => bool) public blacklist;

// -------- CONSTRUCTOR

    constructor() {
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
        
        whitelist[_msgSender()] = true;
        whitelist[address(this)] = true;
        fundsUnlockTime = block.timestamp.add(61 days);
        w2wCooldownEnabled = true; 
        sellCooldownEnabled = true; 
        buyCooldownEnabled = true; 
        swapEnabled = true; 
    }    
    
    receive() external payable {}

    
// -------- IERC20METADATA

    function name() public view virtual override returns (string memory) {
        return _name;
    }
     
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
   
// -------- IERC20

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
   
// -------- INTERNAL & PRIVATE

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!blacklist[sender] && !blacklist[recipient], "APESAFE: Address is blacklisted. ");
        require(lfg || whitelist[sender] || whitelist[recipient], "APESAFE: Trading is not live yet. ");

        // for providing initial liquidity and swaps
        // careful, need to whitelist owner later also for removing liquidity
        if (inSwap || whitelist[sender] || whitelist[recipient]) {
            _standardTokenTransfer(sender, recipient, amount);
            return;
        }
        
        Taxes memory taxrates = Taxes(0, 0, 0);
        
        // buys
        if (sender == liquidityPoolAddr && recipient != uniswapV2RouterAddr) {
            
            if (lfgTime.add(_buyLimitTime) >= block.timestamp) {
                require(
                    amount <= _buyLimit,
                    "APESAFE: No buy greater than 10 billion can be made for the first 10 minutes. "
                );
            }

            if (sellCooldownEnabled) {
                _checkCooldown(recipient, _buyCooldown);
            }
            
            if (!excludedFromRewards[recipient]) {
                _positionChange(recipient);
            }
            taxrates = _buyTaxrates;
        }
        
        // sells
        if (recipient == liquidityPoolAddr && sender != uniswapV2RouterAddr) {
            
            if (sellCooldownEnabled) {
                _checkCooldown(sender, _sellCooldown);
            }
            
            if (!excludedFromRewards[sender]) {
                _positionChange(sender);
            }
                    
            if (swapEnabled) {
                _doTheSwap();
            }
            taxrates = _sellTaxrates;
        } 
        
        // wallet to wallet
        if (recipient != liquidityPoolAddr && sender != liquidityPoolAddr) {
            
            if (w2wCooldownEnabled) {
                _checkCooldown(sender, _w2wCooldown);
            }
            
            if (!excludedFromRewards[sender]) {
                _positionChange(sender);
            }
            
            if (!excludedFromRewards[recipient]) {
                _positionChange(recipient);
            }
            
            if (swapEnabled) {
                _doTheSwap();
            }
            taxrates = _w2wTaxrates;
        }
        
        // transfer    
        if (excludedFromTaxes[sender] || excludedFromTaxes[recipient]) {
            _standardTokenTransfer(sender, recipient, amount);
        } else {
            address contractAddr = address(this);
            uint256 taxAmount;
            (amount,taxAmount) = _taxTo(amount, taxrates.buyback, contractAddr);
            pendingBuybackTokens += taxAmount;
            (amount,taxAmount) = _taxTo(amount, taxrates.redistribution, contractAddr);
            pendingRedisTokens += taxAmount;
            (amount,) = _taxTo(amount, taxrates.marketing, contractAddr);
            
            _standardTokenTransfer(sender, recipient, amount);
        }
    }
    
    function _checkCooldown(address addr, uint256 cooldown) private {
        // enforce cooldown and note down time
        require(
            holders[addr].timeTransfer.add(cooldown) < block.timestamp,
            "APESAFE: Need to wait until next transfer. "
        );
        holders[addr].timeTransfer = block.timestamp;
    }

    function _standardTokenTransfer(address sender, address recipient, uint256 amount) private {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _taxTo(uint256 amount, uint256 taxrate, address recipient) private returns (uint256,uint256) {
        
        uint256 taxAmount = amount.mul(taxrate).div(1000);
        _balances[recipient] = _balances[recipient].add(taxAmount);
        
        amount = amount.sub(taxAmount);
        return (amount, taxAmount);
    }
    
    
// -------- SWAP

    bool public inSwap = false;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
        
    function _doTheSwap() private {
        if (balanceOf(address(this)) == 0) {
            return;
        }
    
        uint256 redisTokensToSwap = _getTokensToSwap(pendingRedisTokens);
        uint256 buybackTokensToSwap = _getTokensToSwap(pendingBuybackTokens);
        uint256 marketingTokensToSwap = _getTokensToSwap(balanceOf(address(this)).sub(pendingRedisTokens).sub(pendingBuybackTokens));
        pendingRedisTokens = pendingRedisTokens.sub(redisTokensToSwap);
        pendingBuybackTokens = pendingBuybackTokens.sub(buybackTokensToSwap);
        uint256 totalTokensToSwap = redisTokensToSwap.add(buybackTokensToSwap).add(marketingTokensToSwap); 

        _swapTokensForETH(totalTokensToSwap);
        
        uint256 redisRatio = redisTokensToSwap.mul(10000).div(totalTokensToSwap);
        uint256 buybackRatio = buybackTokensToSwap.mul(10000).div(totalTokensToSwap);
        
        uint256 ethForRedis = address(this).balance.mul(redisRatio).div(10000);
        uint256 ethForBuyback = address(this).balance.mul(buybackRatio).div(10000);
        uint256 ethForMarketing = address(this).balance.sub(ethForRedis).sub(ethForBuyback);
        
        _swapETHForUSDC(ethForRedis);
        
        if (ethForBuyback != 0) {
            buybackAddr.transfer(ethForBuyback);
        }
        if (ethForMarketing != 0) {
            marketingAddr.transfer(ethForMarketing);
        }
    }

    function _getTokensToSwap(uint256 tokenAmount) public view returns (uint256) {
        // no more than 4% price impact
        if (tokenAmount.mul(1000).div(balanceOf(liquidityPoolAddr)) <= 40) {
            return tokenAmount;
        } 
        return balanceOf(liquidityPoolAddr).mul(4).div(100);
    }
    
    function _swapETHForUSDC(uint256 weiAmount) private lockTheSwap() {
        if (weiAmount == 0) {
            return;
        }
        
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = USDCAddr;
        
        uint256 prevBalance = USDC.balanceOf(address(this));

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: weiAmount}(
            0,
            path,
            address(this),
            block.timestamp.add(300)
        );
        
        uint256 postBalance = USDC.balanceOf(address(this));
        USDCPoolBalance += postBalance.sub(prevBalance);
    }   

    function _swapUSDCToTokensTo(uint256 tokenAmount, address payable addr) private lockTheSwap() {
        if (tokenAmount == 0) {
            return;
        }
        
        address[] memory path = new address[](3);
        path[0] = USDCAddr;
        path[1] = uniswapV2Router.WETH();
        path[2] = address(this);
        
        USDC.approve(uniswapV2RouterAddr, tokenAmount);
        
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            addr,
            block.timestamp.add(300)
        );
    }

    function _swapTokensForETH(uint256 tokenAmount) private lockTheSwap() {
        if (tokenAmount == 0) {
            return;
        }
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), uniswapV2RouterAddr, tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            payable(this),
            block.timestamp.add(300)
        );
    }

// -------- ADMIN
    
    function divideAndConquer() external onlyOwner() {
        _lfg();
    }

    function _lfg() private {
        require(!lfg, "APESAFE: Wen moon ser. ");
        lfg = true;
        lfgTime = block.timestamp;
    }

    function setAutoSwap(bool onoff) external onlyOwner() {
        swapEnabled = onoff;
    }
    
    function manualSwap() external onlyOwner() {
        _doTheSwap();
    }

    function setWhitelist(address addr, bool onoff) external onlyOwner() {
        whitelist[addr] = onoff;
    }

    function setBlacklist(address addr, bool onoff) external onlyOwner() {
        blacklist[addr] = onoff;
    }
    
    function setTaxrates(uint256 i, Taxes calldata taxrates) external onlyOwner() {
        if (i == 0) {
            _buyTaxrates = taxrates;
        } else if (i == 1){
            _sellTaxrates = taxrates;
        } else {
            _w2wTaxrates = taxrates;
        } 
    }    

    // not pretty, yes
    function setCooldown(uint256 i, uint256 cooldown) external onlyOwner() {
        require(cooldown <= 60 seconds, "APESAFE: Cooldown value too large. ");
        if (i == 0) {
            _buyCooldown = cooldown;
            if (cooldown == 0) {
                buyCooldownEnabled = false;
            } else {
                buyCooldownEnabled = true;
            }
        } else if (i == 1) {
            _sellCooldown = cooldown;
            if (cooldown == 0) {
                sellCooldownEnabled = false;
            } else {
                sellCooldownEnabled = true;
            }
        } else {
            _w2wCooldown = cooldown;
            if (cooldown == 0) {
                w2wCooldownEnabled = false;
            } else {
                w2wCooldownEnabled = true;
            }
        }//no, sniper!
        if (!lfg) {
            _lfg();
        }
    }
    
    function setMarketingWallet(address payable addr) external onlyOwner() {
        marketingAddr = addr;
    }

    function setBuybackLottery(address payable addr) external onlyOwner() {
        buybackAddr = addr;
    }

// -------- USDCREDIS

// public
        
    function withdrawAlloc() public {
        address addr = _msgSender();
        _withdraw(addr);
    }

    function getAlloc(address addr) public view returns (uint256) {
        uint256 allocSinceLastPos = _getAllocSinceLastPos(addr);
        return holders[addr].allocInLastPos.add(allocSinceLastPos).sub(holders[addr].withdrawnAlloc);
    }
    
    function convertUSDCToTokens() public {
        address payable addr = payable(_msgSender());
        uint256 amount = getAlloc(addr);
        holders[addr].withdrawnAlloc = holders[addr].withdrawnAlloc.add(amount);
        _positionChange(addr);
        _swapUSDCToTokensTo(amount, addr);
    }

// owner

    function withdrawAllocFor(address payable addr) external onlyOwner() {
        _withdraw(addr);
    }  
    
    // similar to locking liquiditypools in uniswap this locks the usdc pool
    function lockRedisPool(uint256 time) external onlyOwner() {
        require(fundsUnlockTime <= time, "APESAFE: Too early.");
        fundsUnlockTime = time;
    }
    
    function drainRedisPool() external onlyOwner() {
        require(fundsUnlockTime <= block.timestamp, "APESAFE: Too early.");
        USDC.transfer(_msgSender(), USDC.balanceOf(address(this)));
    }
    
    function disperseTokens(address[] calldata recipients, uint256[] calldata values) external onlyOwner() {
        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(owner(), recipients[i], values[i]);
            holders[recipients[i]].hasPos = true;
        }
    }
    
    function updatePosition(address addr) external onlyOwner() {
        _positionChange(addr);
    }
    
    // emergency function, hopefully never used...
    function fixPosition(address addr, Holder calldata holder) external onlyOwner() {
        holders[addr] = holder;
    }

// private

    function _positionChange(address addr) private {
        Holder memory holder = holders[addr];
        
        if (excludedFromRewards[addr]) {
            if (holder.hasPos) {
                holder.allocInLastPos = 0; 
                holder.redisPoolInLastPos = 0;
                holder.withdrawnAlloc = 0;
                holder.hasPos = false;
                holders[addr] = holder;
            }
            return;
        }
        if (!holder.hasPos) {
            holder.hasPos = true;
        }
        
        uint256 allocSinceLastPos = _getAllocSinceLastPos(addr);
        holder.allocInLastPos = holder.allocInLastPos.add(allocSinceLastPos);
        holder.redisPoolInLastPos = USDCPoolBalance;

        holders[addr] = holder;
    }
    
    function _getAllocSinceLastPos(address addr) private view returns (uint256) {
        uint256 redisPoolSinceLastPos = USDCPoolBalance.sub(holders[addr].redisPoolInLastPos);
        uint256 allocPerc = balanceOf(addr).mul(100000).div(_totalSupply);
        return redisPoolSinceLastPos.mul(allocPerc).div(100000); 
    }
    
    function _withdraw(address addr) private {
        require(holders[addr].hasPos, "APESAFE: No position found for this address.");
        uint256 amount = getAlloc(addr);
        holders[addr].withdrawnAlloc = holders[addr].withdrawnAlloc.add(amount);
        USDC.transfer(addr, amount);
    }
}

// -------- LIBRARIES & INTERFACES

library UniswapV2Library {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            )))));
    }
}

interface IUniswapV2Router02  {
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
    function WETH() external pure returns (address);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
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

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

