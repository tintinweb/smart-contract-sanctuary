/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

/**
 *META VERSE MetaVerseGirl
 * 
 * New BUSD reward token with reflections
 * 
 * Https://t.me/MetaVerseGirl
*/
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;


library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * C U ON THE MOON
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

contract MetaVerseGirl is IERC20, Ownable {
    using Address for address;
    
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "MetaVerseGirl";
    string constant _symbol = "METAVGIRL";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 100_000_000_000 * (10 ** _decimals);
    uint256 _maxBuyTxAmount = (_totalSupply * 1) / 20;
    uint256 _maxSellTxAmount = (_totalSupply * 1) / 200;
    uint256 _maxWalletSize = (_totalSupply * 2) / 100;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => uint256) public lastSell;
    mapping (address => uint256) public lastBuy;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) liquidityCreator;

    uint256 developerFee = 0;
    uint256 marketingFee = 800;
    uint256 liquidityFee = 300;
    uint256 buybackFee = 0;
    uint256 totalFee = marketingFee + buybackFee + liquidityFee + developerFee;
    uint256 sellBias = 0;
    uint256 feeDenominator = 10000;

    address payable public liquidityFeeReceiver = payable(0xA383503c9D2c1d32AEc5e6C5f141F39F42418da3);
    address payable public marketingFeeReceiver = payable(0x9c01c1407284007Bb234190E0da4CA83F903C6F5);
    address payable public developer;

    IDEXRouter public router;
    //address routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    //address routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    mapping (address => bool) liquidityPools;
    mapping (address => uint256) public protected;
    bool protectionEnabled = true;
    bool protectionDisabled = false;
    uint256 protectionLimit;
    uint256 public protectionCount;
    uint256 protectionTimer;

    address public pair;

    uint256 public launchedAt;
    uint256 public launchedTime;
    uint256 public deadBlocks;
    bool startBullRun = false;
    bool pauseDisabled = false;
    uint256 public rateLimit = 2;
    bool protectionEnded = false;

    bool public swapEnabled = true;
    bool processEnabled = true;
    uint256 public swapThreshold = _totalSupply / 1000;
    uint256 public swapMinimum = _totalSupply / 10000;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    
    mapping (address => bool) teamMember;
    
    modifier onlyTeam() {
        require(teamMember[_msgSender()] || msg.sender == owner(), "Caller is not a team member");
        _;
    }
    
    event ProtectedWallet(address, address, uint256, uint8);

    constructor () {
        router = IDEXRouter(routerAddress);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        liquidityPools[pair] = true;
        _allowances[owner()][routerAddress] = type(uint256).max;
        _allowances[address(this)][routerAddress] = type(uint256).max;

        isFeeExempt[owner()] = true;
        liquidityCreator[owner()] = true;

        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[routerAddress] = true;
        isTxLimitExempt[DEAD] = true;

        _balances[owner()] = _totalSupply;
        developer = payable(msg.sender);
        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner(); }
    function maxBuyTxTokens() external view returns (uint256) { return _maxBuyTxAmount / (10 ** _decimals); }
    function maxSellTxTokens() external view returns (uint256) { return _maxSellTxAmount / (10 ** _decimals); }
    function maxWalletTokens() external view returns (uint256) { return _maxWalletSize / (10 ** _decimals); }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }
    
    function setTeamMember(address _team, bool _enabled) external onlyOwner {
        teamMember[_team] = _enabled;
    }
    
    function airdrop(address[] calldata addresses, uint256[] calldata amounts) external onlyOwner {
        require(addresses.length > 0 && amounts.length == addresses.length);
        address from = msg.sender;

        for (uint i = 0; i < addresses.length; i++) {
            if(!liquidityPools[addresses[i]] && !liquidityCreator[addresses[i]]) {
                _basicTransfer(from, addresses[i], amounts[i] * (10 ** _decimals));
            }
        }
    }
    
    function buyBack(address token, uint256 amountPercentage) external onlyTeam {
        uint256 amountETH = (address(this).balance * amountPercentage) / 100;
        
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = token;

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountETH}(
            0,
            path,
            msg.sender,
            block.timestamp
        );
    }
    
    function rescueToken(address tokenAddress, uint256 tokens) external onlyTeam
        returns (bool success)
    {
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }
    
    function clearStuckBalance(uint256 amountPercentage, address adr) external onlyTeam {
        uint256 amountETH = address(this).balance;
        payable(adr).transfer((amountETH * amountPercentage) / 100);
    }
    
    function openTrading(uint256 _deadBlocks, uint256 _protection, uint256 _limit) external onlyTeam {
        require(!startBullRun && _deadBlocks < 10);
        deadBlocks = _deadBlocks;
        startBullRun = true;
        launchedAt = block.number;
        protectionTimer = block.timestamp + _protection;
        protectionLimit = _limit * (10 ** _decimals);
    }
    
    function pauseTrading() external onlyTeam {
        require(!pauseDisabled);
        startBullRun = false;
    }
    
    function disablePause() external onlyTeam {
        pauseDisabled = true;
        startBullRun = true;
    }
    
    function setProtection(bool _protect, uint256 _addTime) external onlyTeam {
        require(!protectionDisabled);
        protectionEnabled = _protect;
        require(_addTime < 1 days);
        protectionTimer += _addTime;
    }
    
    function disableProtection() external onlyTeam {
        protectionDisabled = true;
        protectionEnabled = false;
    }
    
    function protectWallet(address[] calldata _wallets, bool _protect) external onlyTeam {
        if (_protect) {
            require(protectionEnabled);
        }
        
        for (uint i = 0; i < _wallets.length; i++) {
            
            if (_protect) {
                protectionCount++;
                emit ProtectedWallet(tx.origin, _wallets[i], block.number, 2);
            }
            else {
                if (protected[_wallets[i]] != 0)
                    protectionCount--;      
            }
            protected[_wallets[i]] = _protect ? block.number : 0;
        }
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "BEP20: transfer from 0x0");
        require(recipient != address(0), "BEP20: transfer to 0x0");
        require(amount > 0, "Amount must be > zero");
        require(_balances[sender] >= amount, "Insufficient balance");
        if(!launched() && liquidityPools[recipient]){ require(liquidityCreator[sender], "Liquidity not added yet."); launch(); }
        if(!startBullRun){ require(liquidityCreator[sender] || liquidityCreator[recipient], "Trading not open yet."); }

        if (!protectionEnded && protectionTimer <= block.timestamp) {
            protectionEnded = true;
            rateLimit = 0;
            _maxWalletSize = _totalSupply;
            _maxBuyTxAmount = _totalSupply;
            _maxSellTxAmount = _totalSupply;
        }

        checkTxLimit(sender, recipient, amount);
        
        if (!liquidityPools[recipient] && recipient != DEAD) {
            if (!isTxLimitExempt[recipient]) {
                checkWalletLimit(recipient, amount);
            }
        }
        
        if(protectionEnabled && protectionTimer > block.timestamp) {
            if(liquidityPools[sender] && tx.origin != recipient && protected[recipient] == 0) {
                protected[recipient] = block.number;
                protectionCount++;
                emit ProtectedWallet(tx.origin, recipient, block.number, 0);
            }
        }
        
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(recipient, amount) : amount;
        
        if(shouldSwapBack(recipient)){ if (amount > 0) swapBack(amount); }
        
        _balances[recipient] = _balances[recipient] + amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
        launchedTime = block.timestamp;
        swapEnabled = true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function checkWalletLimit(address recipient, uint256 amount) internal view {
        uint256 walletLimit = _maxWalletSize;
        require(_balances[recipient] + amount <= walletLimit, "Transfer amount exceeds the bag size.");
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal {
        require(isTxLimitExempt[sender] || amount <= (liquidityPools[sender] ? _maxBuyTxAmount : _maxSellTxAmount), "TX Limit Exceeded");
        require(isTxLimitExempt[sender] || lastBuy[recipient] + rateLimit <= block.number, "Transfer rate limit exceeded.");
        
        if (protected[sender] != 0){
            require(amount <= protectionLimit * (10 ** _decimals) && lastSell[sender] == 0 && protectionTimer > block.timestamp, "Wallet protected, please contact support.");
            lastSell[sender] = block.number;
        }
        
        if (liquidityPools[recipient]) {
            lastSell[sender] = block.number;
        } else if (shouldTakeFee(sender)) {
            if (protectionEnabled && protectionTimer > block.timestamp && lastBuy[tx.origin] == block.number && protected[recipient] == 0) {
                protected[recipient] = block.number;
                emit ProtectedWallet(tx.origin, recipient, block.number, 1);
            }
            lastBuy[recipient] = block.number;
            if (tx.origin != recipient)
                lastBuy[tx.origin] = block.number;
        }
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if(launchedAt + deadBlocks >= block.number){ return feeDenominator - 1; }
        if (selling) return totalFee + sellBias;
        return totalFee - sellBias;
    }

    function takeFee(address recipient, uint256 amount) internal returns (uint256) {
        bool selling = liquidityPools[recipient];
        uint256 feeAmount = (amount * getTotalFee(selling)) / feeDenominator;
        
        _balances[address(this)] += feeAmount;
    
        return amount - feeAmount;
    }

    function shouldSwapBack(address recipient) internal view returns (bool) {
        return !liquidityPools[msg.sender]
        && !inSwap
        && swapEnabled
        && liquidityPools[recipient]
        && _balances[address(this)] >= swapMinimum;
    }

    function swapBack(uint256 amount) internal swapping {
        uint256 amountToSwap = amount < swapThreshold ? amount : swapThreshold;
        if (_balances[address(this)] < amountToSwap) amountToSwap = _balances[address(this)];
        
        uint256 amountToLiquify = (amountToSwap * liquidityFee / 2) / totalFee;
        amountToSwap -= amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        
        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance - balanceBefore;
        uint256 totalBNBFee = totalFee - (liquidityFee / 2);

        uint256 amountBNBLiquidity = (amountBNB * liquidityFee / 2) / totalBNBFee;
        uint256 amountBNBMarketing = (amountBNB * marketingFee) / totalBNBFee;
        uint256 amountBNBDeveloper = (amountBNB * developerFee) / totalBNBFee;
        
        if (amountBNBMarketing > 0)
            marketingFeeReceiver.transfer(amountBNBMarketing);
        if (amountBNBDeveloper > 0)
            developer.transfer(amountBNBDeveloper);
        
        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                liquidityFeeReceiver,
                block.timestamp
            );
        }

        emit FundsDistributed(amountBNBLiquidity, amountBNBMarketing, amountBNBDeveloper);
    }
    
    function addLiquidityPool(address lp, bool isPool) external onlyOwner {
        require(lp != pair, "Can't alter current liquidity pair");
        liquidityPools[lp] = isPool;
        emit UpdatedSettings(isPool ? 'Liquidity Pool Enabled' : 'Liquidity Pool Disabled', [Log(toString(abi.encodePacked(lp)), 1), Log('', 0), Log('', 0)]);
    }
    
    function switchRouter(address newRouter) external onlyOwner {
        router = IDEXRouter(newRouter);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        liquidityPools[pair] = true;
        isTxLimitExempt[newRouter] = true;
        emit UpdatedSettings('Exchange Router Updated', [Log(concatenate('New Router: ',toString(abi.encodePacked(newRouter))), 1),Log(concatenate('New Liquidity Pair: ',toString(abi.encodePacked(pair))), 1), Log('', 0)]);
    }
    
    function excludePresaleAddresses(address preSaleRouter, address presaleAddress) external onlyOwner {
        liquidityCreator[preSaleRouter] = true;
        liquidityCreator[presaleAddress] = true;
        isTxLimitExempt[preSaleRouter] = true;
        isTxLimitExempt[presaleAddress] = true;
        isFeeExempt[preSaleRouter] = true;
        isFeeExempt[presaleAddress] = true;
        emit UpdatedSettings('Presale Setup', [Log(concatenate('Presale Router: ',toString(abi.encodePacked(preSaleRouter))), 1),Log(concatenate('Presale Address: ',toString(abi.encodePacked(presaleAddress))), 1), Log('', 0)]);
    }

    function setRateLimit(uint256 rate) external onlyOwner {
        require(rate <= 30);
        rateLimit = rate;
        emit UpdatedSettings('Purchase Rate Limit', [Log('Blocks', rate), Log('', 0), Log('', 0)]);
    }

    function setTxLimit(uint256 buyNumerator, uint256 sellNumerator, uint256 divisor) external onlyOwner {
        require(buyNumerator > 0 && sellNumerator > 0 && divisor > 0 && divisor <= 10000);
        _maxBuyTxAmount = (_totalSupply * buyNumerator) / divisor;
        _maxSellTxAmount = (_totalSupply * sellNumerator) / divisor;
        emit UpdatedSettings('Maximum Transaction Size', [Log('Max Buy Tokens', _maxBuyTxAmount / (10 ** _decimals)), Log('Max Sell Tokens', _maxSellTxAmount / (10 ** _decimals)), Log('', 0)]);
    }
    
    function setMaxWallet(uint256 numerator, uint256 divisor) external onlyOwner() {
        require(numerator > 0 && divisor > 0 && divisor <= 10000);
        _maxWalletSize = (_totalSupply * numerator) / divisor;
        emit UpdatedSettings('Maximum Wallet Size', [Log('Tokens', _maxWalletSize / (10 ** _decimals)), Log('', 0), Log('', 0)]);
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
        emit UpdatedSettings(exempt ? 'Fees Removed' : 'Fees Enforced', [Log(toString(abi.encodePacked(holder)), 1), Log('', 0), Log('', 0)]);
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
        emit UpdatedSettings(exempt ? 'Transaction Limit Removed' : 'Transaction Limit Enforced', [Log(toString(abi.encodePacked(holder)), 1), Log('', 0), Log('', 0)]);
    }

    function setFees(uint256 _buybackFee, uint256 _liquidityFee, uint256 _marketingFee, uint256 _developerFee, uint256 _sellBias, uint256 _feeDenominator) external onlyOwner {
        buybackFee = _buybackFee;
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        developerFee = _developerFee;
        totalFee = _buybackFee + _marketingFee + _liquidityFee + _developerFee;
        sellBias = _sellBias;
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator / 2);
        emit UpdatedSettings('Fees', [Log('Total Fee Percent', totalFee * 100 / feeDenominator), Log('Marketing Percent', _marketingFee * 100 / feeDenominator), Log('Liquidity Percent', _liquidityFee * 100 / feeDenominator)]);
    }

    function setFeeReceivers(address _liquidityFeeReceiver, address _marketingFeeReceiver, address _developer) external onlyOwner {
        liquidityFeeReceiver = payable(_liquidityFeeReceiver);
        marketingFeeReceiver = payable(_marketingFeeReceiver);
        developer = payable(_developer);
        emit UpdatedSettings('Fee Receivers', [Log(concatenate('Liquidity Receiver: ',toString(abi.encodePacked(_liquidityFeeReceiver))), 1),Log(concatenate('Marketing Receiver: ',toString(abi.encodePacked(_marketingFeeReceiver))), 1), Log(concatenate('Dev Receiver: ',toString(abi.encodePacked(_developer))), 1)]);
    }

    function setSwapBackSettings(bool _enabled, bool _processEnabled, uint256 _denominator, uint256 _swapMinimum) external onlyOwner {
        require(_denominator > 0);
        swapEnabled = _enabled;
        processEnabled = _processEnabled;
        swapThreshold = _totalSupply / _denominator;
        swapMinimum = _swapMinimum * (10 ** _decimals);
        emit UpdatedSettings('Swap Settings', [Log('Enabled', _enabled ? 1 : 0),Log('Swap Maximum', swapThreshold), Log('Auto-processing', _processEnabled ? 1 : 0)]);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - (balanceOf(DEAD) + balanceOf(ZERO));
    }
	
	function toString(bytes memory data) internal pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";
    
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
    
    function concatenate(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

	struct Log {
	    string name;
	    uint256 value;
	}

    event FundsDistributed(uint256 charityBNB, uint256 marketingBNB, uint256 devBNB);
    event UpdatedSettings(string name, Log[3] values);
    //C U ON THE MOON
}