/**
 *Submitted for verification at BscScan.com on 2021-12-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IPancakePair {
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

interface IPancakeFactory {
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

interface IPancakeRouter01 {
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


// File @openzeppelin/contracts/utils/[email protected]
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

// File @openzeppelin/contracts/access/[email protected]0
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

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) total;
        mapping(address => uint) reward;
        mapping(address => bool) status;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) internal view returns (uint, uint, bool) {
        return (map.total[key], map.reward[key], map.status[key]);
    }

    function getIndexOfKey(Map storage map, address key) internal view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) internal view returns (address) {
        return map.keys[index];
    }

    function set(Map storage map, address key, uint total, uint val, bool status) internal {
        if (map.inserted[key]) {
            map.total[key] = total;
            map.reward[key] = val;
            map.status[key] = status;
        } else {
            map.inserted[key] = true;
            map.total[key] = total;
            map.reward[key] = val;
            map.status[key] = status;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) internal {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.total[key];
        delete map.reward[key];
        delete map.status[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

// File contracts/UNIVE.sol

contract UNIVE is IERC20, Ownable {
    using IterableMapping for IterableMapping.Map;
    IterableMapping.Map private tokenHoldersMap;

    IPancakeRouter02 public pcsV2Router;
    //address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //uniswap router2 address
    //address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //uniswap router2 address for 4 main testnet
    //address public routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //pancakeswap router2 address
    address public routerAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; //pancakeswap router testnet address
    address public pcsV2Pair;

    string constant public name = "UNIVE X";
    string constant public symbol = "UNVX";
    uint8 constant public decimals = 8;

    uint256 private _totalSupply = 1000000000 * 10**8;
    uint256 public _finalSupply = 100000000 * 10**8;
    uint256 public _totalLiquidityFee = 0;

    uint8 public feePurchase = 15;
    uint8 public feePurchaseHolder = 8;
    uint8 public feePurchaseBurn = 2;
    uint8 public feePurchaseLiquidity = 5;
    uint8 public feeSale = 20;
    uint8 public feeSaleHolder = 13;
    uint8 public feeSaleBurn = 2;
    uint8 public feeSaleLiquidity = 5;
    uint256 private feeTotalAmount = 0;    
    uint256 private feeHolderAmount = 0;
    uint256 private feeBurnAmount = 0;
    uint256 private feeLiquidityAmount = 0;       

    mapping (address => bool) public isExcludedFromTax;

    uint256 public holderThreshold = 20000 * 10**8;
    uint256 public transactionThreshold = 1000 * 10**8;
    uint256 public liquidityThreshold = 10000 * 10**8;
    uint256 public rewardThreshold = 1000 * 10**8;
    bool public taxEnable = true;
    
    bool private swapping;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping (address => bool) public AllowedContract;

    event TransferFee(address sender, address recipient, uint256 amount);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor() {        
        _balances[_msgSender()] = _totalSupply;
        isExcludedFromTax[_msgSender()] = true;
        isExcludedFromTax[routerAddress] = true;
        tokenHoldersMap.set(_msgSender(), 0, 0, true);
        
        IPancakeRouter02 _pcsV2Router = IPancakeRouter02(routerAddress);
        // Create a uniswap pair for this new token
        //address _pcsV2Pair = IPancakeFactory(_pcsV2Router.factory()).createPair(address(this), _pcsV2Router.WETH());

        pcsV2Router = _pcsV2Router;
        //pcsV2Pair = _pcsV2Pair;
    }

    function setRouterAddress(address routerAddress_) external onlyOwner {
        routerAddress = routerAddress_;
        require(routerAddress != address(pcsV2Router), "UNIVE: The router already has that address");
        pcsV2Router = IPancakeRouter02(routerAddress);         
    }
    
    function setPcsV2Pair(address pcsV2Pair_) external onlyOwner {
        pcsV2Pair = pcsV2Pair_;  
    }

    function setFeePurchaseHolder(uint8 feePurchaseHolder_) external onlyOwner {
        require(feePurchaseHolder_ < 100, "UNIVE: Holder fee incorrect");
        feePurchaseHolder = feePurchaseHolder_;
        feePurchase = feePurchaseHolder + feePurchaseBurn + feePurchaseLiquidity;
    }

    function setFeePurchaseBurn(uint8 feePurchaseBurn_) external onlyOwner {
        require(feePurchaseBurn_ < 100, "UNIVE: Burn fee incorrect");
        feePurchaseBurn = feePurchaseBurn_;
        feePurchase = feePurchaseHolder + feePurchaseBurn + feePurchaseLiquidity;
    }

    function setFeePurchaseLiquidity(uint8 feePurchaseLiquidity_) external onlyOwner {
        require(feePurchaseLiquidity_ < 100, "UNIVE: liquidity fee incorrect");
        feePurchaseLiquidity = feePurchaseLiquidity_;
        feePurchase = feePurchaseHolder + feePurchaseBurn + feePurchaseLiquidity;
    }

    function setFeeSaleHolder(uint8 feeSaleHolder_) external onlyOwner {
        require(feeSaleHolder_ <= 100, "UNIVE: Holder fee incorrect");
        feeSaleHolder = feeSaleHolder_;
        feeSale = feeSaleHolder + feeSaleBurn + feeSaleLiquidity;
    }

    function setFeeSaleBurn(uint8 feeSaleBurn_) external onlyOwner {
        require(feeSaleBurn_ <= 100, "UNIVE: Burn fee incorrect");
        feeSaleBurn = feeSaleBurn_;
        feeSale = feeSaleHolder + feeSaleBurn + feeSaleLiquidity;
    }

    function setFeeSaleLiquidity(uint8 feeSaleLiquidity_) external onlyOwner {
        require(feeSaleLiquidity_ <= 100, "UNIVE: liquidity fee incorrect");
        feeSaleLiquidity = feeSaleLiquidity_;
        feeSale = feeSaleHolder + feeSaleBurn + feeSaleLiquidity;
    }

    function setHolderThreshold(uint256 holderThreshold_) external onlyOwner {
        holderThreshold = holderThreshold_;
    }

    function setTransactionThreshold(uint256 transactionThreshold_) external onlyOwner {
        transactionThreshold = transactionThreshold_;
    }

    function setLiquidityThreshold(uint256 liquidityThreshold_) external onlyOwner {
        liquidityThreshold = liquidityThreshold_;
    }

    function setRewardThreshold(uint256 rewardThreshold_) external onlyOwner {
        rewardThreshold = rewardThreshold_;
    }

    function setTaxEnable(bool enable) external onlyOwner {
        taxEnable = enable;
    }

    function setExcludeFromTax(address address_, bool isExcluded) external onlyOwner {
        isExcludedFromTax[address_] = isExcluded;
    }

    function setRewardStatus(address address_, bool isStatus) external onlyOwner {   
        (uint total, uint reward, bool status) = tokenHoldersMap.get(address_);
        require(status != isStatus, "You have already done");
        tokenHoldersMap.set(address_, total, reward, isStatus);
    }

    function getHolderStatus(address address_) external view returns (uint, uint, bool) {
        (uint total, uint reward, bool status) = tokenHoldersMap.get(address_);
        return (total, reward, status);
    }

    function getNumberOfHolders() external view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    //to recieve ETH(BNB) from uniswapV2Router when swaping
    receive() external payable {}

    /**
     * @notice claim rewards (direct use)
     *
     */
    function claim(address receiver, address token) external {
        (uint256 total, uint256 reward, bool status) = tokenHoldersMap.get(_msgSender());

        require(status, "The reward is not allowed");
        require(reward > rewardThreshold, "Reward insufficient to withdraw");

        // get ETH from reward(UNIVE token) of the holder
        uint256 initialBalance = address(this).balance;
        
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pcsV2Router.WETH();
        _approve(address(this), address(pcsV2Router), reward);

        //make the swap to get ETH from the token
        pcsV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            reward,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        uint256 newBalance = address(this).balance - initialBalance;

        if (token == pcsV2Router.WETH()) {
            // send the reward as "ETH"
            if (newBalance > 0){
                _approve(address(this), receiver, newBalance);
                payable(receiver).transfer(newBalance);
                emit Transfer(address(this), receiver, reward); 
            } 
        } else {
            address[] memory path1 = new address[](2);
            path1[0] = pcsV2Router.WETH();
            path1[1] = token;
            IERC20(pcsV2Router.WETH()).approve(address(pcsV2Router), newBalance);
            _approve(address(this), address(pcsV2Router), newBalance);
            //make the swap to get the token required from ETH
            pcsV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value:newBalance}(
                0, // accept any amount of ETH
                path1,
                receiver,
                block.timestamp
            );   
        }        
        tokenHoldersMap.set(_msgSender(), total, 0, true);            
    } 
    
    function burn(uint256 amount) external onlyOwner{
        uint256 accountBalance = _balances[_msgSender()];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        _totalSupply -= amount;
        require(_totalSupply >= _finalSupply, "ERC20:  can not burn anymore");
        unchecked {
            _balances[_msgSender()] = accountBalance - amount;
        }        
        emit Transfer(_msgSender(), address(0), amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    
    function AllowContractTransfer(address address_, bool isAllowed) external onlyOwner {
        AllowedContract[address_] = isAllowed;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool)  {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom( address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        
        if (sender == _msgSender() || AllowedContract[_msgSender()]) {
            require(_allowances[_msgSender()][sender] >= amount, "ERC20: transfer amount(custom) exceeds allowance");
            unchecked {
                _approve(_msgSender(), sender, _allowances[_msgSender()][sender]- amount);
            }
        } else {
            require(_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), _allowances[sender][_msgSender()]- amount);
            }
        }

        return true;
    }

    function _transfer( address sender, address recipient, uint256 amount ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        
        //uint256 receiveAmount = amount;
        if (taxEnable){
            //when purchase this token
            if (sender == pcsV2Pair) {            
                if (!isExcludedFromTax[recipient]){
                    feeHolderAmount = amount * feePurchaseHolder / 100;
                    feeBurnAmount = amount * feePurchaseBurn / 100;
                    feeLiquidityAmount = amount * feePurchaseLiquidity / 100;
                    feeTotalAmount = feeHolderAmount + feeBurnAmount + feeLiquidityAmount;
                    //receiveAmount = amount - feeTotalAmount;  
                }            
            }
            //when sell this token
            if (recipient == pcsV2Pair) {
                if (!isExcludedFromTax[sender]){
                    feeHolderAmount = amount * feeSaleHolder / 100;
                    feeBurnAmount = amount * feeSaleBurn / 100;
                    feeLiquidityAmount = amount * feeSaleLiquidity / 100;
                    feeTotalAmount = feeHolderAmount + feeBurnAmount + feeLiquidityAmount;
                    //receiveAmount = amount - feeTotalAmount;
                }            
            }  
        }
        		
		_balances[recipient] += amount;
        // When this token is transferred, add or remove the sender(recipient) into the holder list by the holderThreshold
        if (_balances[recipient] > holderThreshold){
            int userExist = tokenHoldersMap.getIndexOfKey(recipient);
            if (userExist == -1) {
                tokenHoldersMap.set(recipient, 0, 0, true);
            }
        }

        if (_balances[sender] < holderThreshold){
            (uint total, uint256 reward, bool status) = tokenHoldersMap.get(sender);
            status = false;
            tokenHoldersMap.set(sender, total, reward, false);
        }        
        
        // process the tax
        if ( taxEnable && (amount > transactionThreshold) && ((sender == pcsV2Pair&&!isExcludedFromTax[recipient]) || (recipient == pcsV2Pair&&!isExcludedFromTax[sender])) ) {   
            //Each holder must receive a number of rewards(BNB or ETH) in proportion to the number of tokens he owns.     
            if (feeHolderAmount > 0){
                uint256 iterations = 0;

                while(iterations < tokenHoldersMap.keys.length) {
                    address account = tokenHoldersMap.keys[iterations];
                   (uint total, uint256 reward, bool status) = tokenHoldersMap.get(account);
                    if (status){
                        uint256 reward_add = feeHolderAmount *_balances[account] / _totalSupply;
                        tokenHoldersMap.set(account, total + reward_add, reward + reward_add, true);
                    }     
                    iterations++;
                }
            }
            
            // 2% of each transaction burned            
            if ((_totalSupply - feeBurnAmount) > _finalSupply) {
                _totalSupply -= feeBurnAmount;   
            }
            
            //5% automatically injected into liquidity
            if (feeLiquidityAmount>0) {
                _totalLiquidityFee += feeLiquidityAmount;
            }
        }   

        emit Transfer(sender, recipient, amount);
    }      
 
    function _approve( address owner,  address spender, uint256 amount ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}