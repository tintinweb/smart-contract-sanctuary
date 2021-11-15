// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./base/token/BEP20/EmergencyWithdrawable.sol";
import "./base/token/BEP20/PancakeSwapHelper.sol";
import "./base/token/BEP20/IXLD.sol";
import "./IShopItemFulfilment.sol";
import "./IDepositable.sol";
import "./IShop.sol";

contract Shop is IShop, PancakeSwapHelper, EmergencyWithdrawable {
    struct ShopItem {
        uint256 price; // Price is always in BNB
        uint256 id;
        uint256 val1;
        uint256 val2;
        uint8 typeId;
        uint8 discountRate;
        uint8 bulkDiscountRate;
        address fulfilment;
        address fundsReceiver;
    }

    mapping(uint256 => ShopItem) public items;
    mapping(address => uint256) public fundsReceivedBNB;
    mapping(address => uint256) public fundsReceivedXLD;

    IXLD public xld;
    uint256 public nextId;
    uint8 public globalDiscountRate;
    uint8 public slippage = 70;

    event ItemBought(uint256 id, uint256 price, bool xldPayment, address from);

    constructor(IXLD _xld, address routerAddress) PancakeSwapHelper(routerAddress) {
        xld = _xld;
        nextId = 1; 
	}

    function upsertItem(uint256 id, uint8 typeId, uint256 price, uint8 discountRate, uint8 bulkDiscountRate, uint256 val1, uint256 val2, address fulfilment, address fundsReceiver) external override onlyAdmins {
        ShopItem storage item;

        if (id == 0) {
            // Adding item
            item = items[nextId];
            item.id = nextId;
            nextId++;
        } else {
            item = items[id];
            require(item.id == id, "Shop: Item does not exist");
        }

        require(fundsReceiver != address(0), "Shop: Cannot deposit funds to zero address");
        require(fulfilment != address(0), "Shop: Cannot fulfill from zero address");
        
        item.typeId = typeId;
        item.price = price;
        item.discountRate = discountRate;
        item.bulkDiscountRate = bulkDiscountRate;
        item.val1 = val1;
        item.val2 = val2;
        item.fulfilment = fulfilment;
        item.fundsReceiver = fundsReceiver;
    }

    function itemInfo(uint256 id) external override view returns(uint256, uint256, uint256) {
        ShopItem storage item = items[id];
        return (item.typeId, item.val1, item.val2);
    }

    function deleteItem(uint256 id) public onlyOwner {
        delete items[id];
    }

    function setGlobalDiscountRate(uint8 rate) public onlyOwner {
        require(rate <= 100, "Shop: Invalid value");
        globalDiscountRate = rate;
    }

    function setSlippage(uint8 _slippage) public onlyOwner {
        require(_slippage <= 1000, "Shop: Invalid value");
        slippage = _slippage;
    }

    function priceOf(uint256 itemId, uint256 quantity) public view returns (uint256) {
        return priceOf(items[itemId], quantity);
    }

    function xldPriceOf(uint256 itemId, uint256 quantity) public view returns (uint256) {
        return xldPriceOf(items[itemId], quantity);
    }

    function discountRateOf(uint256 itemId) public view returns(uint256) {
        return discountRateOf(items[itemId]);
    }

    function buyItem(uint256 id, uint256 quantity, uint256[] calldata params) external payable notUnauthorizedContract nonReentrant notPaused {
        ShopItem storage item = items[id];
        require(id > 0 && item.id == id, "Shop: Item does not exist");

        uint256 price = priceOf(item, quantity);

        require(msg.value == price, "Shop: Incorrect pay amount");
        require(quantity >= 1, "Shop: Invalid quantity");
        require(params.length == quantity, "Shop: Invalid params");

        IDepositable(item.fundsReceiver).deposit{value: msg.value}(address(0), msg.value);
        fundsReceivedBNB[item.fundsReceiver] += msg.value;

        IShopItemFulfilment(item.fulfilment).fulfill(id, msg.value, false, msg.sender, quantity, params);

        emit ItemBought(id, msg.value, false, msg.sender);
    }

    function buyItemWithXLD(uint256 id, uint256 quantity, uint256 amount, uint256[] calldata params) external notUnauthorizedContract nonReentrant notPaused {
        ShopItem storage item = items[id];
        require(id > 0 && item.id == id, "Shop: Item does not exist");

        uint256 price = xldPriceOf(item, quantity);
        uint256 minPriceAllowedBySlippage = price - price * slippage / 1000;

        require(amount >= minPriceAllowedBySlippage, "Shop: Insufficient amount");
        require(quantity >= 1, "Shop: Invalid quantity");
        require(params.length == quantity, "Shop: Invalid params");

        IDepositable receiver = IDepositable(item.fundsReceiver);
        xld.transferFrom(msg.sender, address(this), amount);
        xld.increaseAllowance(address(receiver), amount);
        receiver.deposit(address(xld), amount);
        fundsReceivedXLD[address(receiver)] += amount;

        IShopItemFulfilment(item.fulfilment).fulfill(id, amount, true, msg.sender, quantity, params);

        emit ItemBought(id, amount, false, msg.sender);
    }

    function priceOf(ShopItem storage item, uint256 quantity) internal view returns (uint256) {
        return applyDiscount(item.price, quantity, discountRateOf(item), item.bulkDiscountRate);
    }

    function xldPriceOf(ShopItem storage item, uint256 quantity) internal view returns (uint256) {
        uint256 xldPrice = calculateSwapAmountFromBNBToToken(address(xld), item.price);
        return applyDiscount(xldPrice, quantity, discountRateOf(item), item.bulkDiscountRate);
    }

    function applyDiscount(uint256 price, uint256 quantity, uint256 discountRate, uint256 bulkDiscountRate) internal pure returns(uint256) {
        uint256 discount = price * discountRate / 100;
        if (discount > price) {
            return 0;
        }

        uint256 total = (price - discount) * quantity;
        if (bulkDiscountRate == 0) {
            return total;
        }

        uint256 bulkDiscountDivisor = bulkDiscountRate;
        if (quantity > bulkDiscountDivisor) {
            bulkDiscountDivisor = quantity;
        }

        return (total * (bulkDiscountDivisor + 1 - quantity)) / bulkDiscountDivisor;
    }

    
    function discountRateOf(ShopItem storage item) internal view returns (uint256) {
        return globalDiscountRate + item.discountRate;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "../../../base/access/AccessControlled.sol";
import "./IBEP20.sol";

abstract contract EmergencyWithdrawable is AccessControlled {
    /**
     * @notice Withdraw unexpected tokens sent to the contract
     */
    function withdrawStuckTokens(address token) external onlyOwner {
        uint256 amount = IBEP20(token).balanceOf(address(this));
        IBEP20(token).transfer(msg.sender, amount);
    }
    
    /**
     * @notice Withdraws funds of the contract - only for emergencies
     */
    function emergencyWithdrawFunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "../../../base/access/AccessControlled.sol";
import "./PancakeSwap/IPancakeRouter02.sol";
import "./PancakeSwap/IPancakeFactory.sol";
import "./PancakeSwap/IPancakePair.sol";
import "./IBEP20.sol";

contract PancakeSwapHelper is AccessControlled {

	address internal _pancakeSwapRouterAddress;
	IPancakeRouter02 internal _pancakeswapV2Router;

	constructor(address routerAddress) {
		//0x10ED43C718714eb63d5aA57B78B54704E256024E for main net
		setPancakeSwapRouter(routerAddress);
	}

    function setPancakeSwapRouter(address routerAddress) public onlyOwner {
		require(routerAddress != address(0), "Cannot use the zero address as router address");

		_pancakeSwapRouterAddress = routerAddress; 
		_pancakeswapV2Router = IPancakeRouter02(_pancakeSwapRouterAddress);
		
		onPancakeSwapRouterUpdated();
	}


	// Returns how many tokens can be bought with the given amount of BNB in PCS
	function calculateSwapAmountFromBNBToToken(address token, uint256 amountBNB) public view returns (uint256) {
		if (token == _pancakeswapV2Router.WETH()) {
			return amountBNB;
		}

		IPancakePair pair = IPancakePair(IPancakeFactory(_pancakeswapV2Router.factory()).getPair(_pancakeswapV2Router.WETH(), token));
		(uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

		// Ensure reserve0 is WETH
		(uint112 _reserve0, uint112 _reserve1) = pair.token0() == _pancakeswapV2Router.WETH() ? (reserve0, reserve1) : (reserve1, reserve0);
		if (_reserve0 == 0) {
			return _reserve1;
		}
		
		return amountBNB * _reserve1 / _reserve0;
	}

	function calculateSwapAmountFromTokenToBNB(address token, uint256 amountTokens) public view returns (uint256) {
		if (token == _pancakeswapV2Router.WETH()) {
			return amountTokens;
		}

		IPancakePair pair = IPancakePair(IPancakeFactory(_pancakeswapV2Router.factory()).getPair(_pancakeswapV2Router.WETH(), token));
		(uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

		// Ensure reserve0 is WETH
		(uint112 _reserve0, uint112 _reserve1) = pair.token0() == _pancakeswapV2Router.WETH() ? (reserve0, reserve1) : (reserve1, reserve0);
		if (_reserve1 == 0) {
			return _reserve0;
		}

		return amountTokens * _reserve0 / _reserve1;
	}

	function swapBNBForTokens(uint256 bnbAmount, IBEP20 token, address to) internal returns(uint256) { 
		// Generate pair for WBNB -> Token
		address[] memory path = new address[](2);
		path[0] = _pancakeswapV2Router.WETH();
		path[1] = address(token);

		// Swap and send the tokens to the 'to' address
		uint256 previousBalance = token.balanceOf(to);
		_pancakeswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: bnbAmount }(0, path, to, block.timestamp + 360);
		return token.balanceOf(to) - previousBalance;
	}

	function swapTokensForBNB(uint256 tokenAmount, IBEP20 token, address to) internal returns(uint256) {
		uint256 initialBalance = to.balance;
		
		// Generate pair for Token -> WBNB
		address[] memory path = new address[](2);
		path[0] = address(token);
		path[1] = _pancakeswapV2Router.WETH();

		// Swap
		_pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp + 360);
		
		// Return the amount received
		return to.balance - initialBalance;
	}


	function onPancakeSwapRouterUpdated() internal virtual {

	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IBEP20.sol";

interface IXLD is IBEP20 {
   	function processRewardClaimQueue(uint256 gas) external;

    function calculateRewardCycleExtension(uint256 balance, uint256 amount) external view returns (uint256);

    function claimReward() external;

    function claimReward(address addr) external;

    function isRewardReady(address user) external view returns (bool);

    function isExcludedFromFees(address addr) external view returns(bool);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function rewardClaimQueueIndex() external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IShopItemFulfilment {
    function fulfill(uint256 id, uint256 price, bool xldPayment, address from, uint256 quantity, uint256[] calldata params) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IDepositable {
    function deposit(address token, uint256 amount) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;


interface IShop {
    function upsertItem(uint256 id, uint8 typeId, uint256 price, uint8 discountRate, uint8 bulkDiscountRate, uint256 val1, uint256 val2, address fulfilment, address fundsReceiver) external;

    function itemInfo(uint256 id) external view returns(uint256, uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

/**
 * @dev Contract module that helps prevent calls to a function.
 */
abstract contract AccessControlled {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    address private _owner;
    bool private _isPaused;
    mapping(address => bool) private _admins;
    mapping(address => bool) private _authorizedContracts;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _status = _NOT_ENTERED;
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

        setAdmin(_owner, true);
        setAdmin(address(this), true);
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "AccessControlled: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "AccessControlled: contract not allowed");
        require(msg.sender == tx.origin, "AccessControlled: proxy contract not allowed");
        _;
    }

    modifier notUnauthorizedContract() {
        if (!_authorizedContracts[msg.sender]) {
            require(!_isContract(msg.sender), "AccessControlled: contract not allowed");
            require(msg.sender == tx.origin, "AccessControlled: proxy contract not allowed");
        }
        _;
    }

    modifier isNotUnauthorizedContract(address addr) {
        if (!_authorizedContracts[addr]) {
            require(!_isContract(addr), "AccessControlled: contract not allowed");
        }
        
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "AccessControlled: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by a non-admin account
     */
    modifier onlyAdmins() {
        require(_admins[msg.sender], "AccessControlled: caller does not have permission");
        _;
    }

    modifier notPaused() {
        require(!_isPaused, "AccessControlled: paused");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function setAdmin(address addr, bool _isAdmin) public onlyOwner {
        _admins[addr] = _isAdmin;
    }

    function isAdmin(address addr) public view returns(bool) {
        return _admins[addr];
    }

    function setAuthorizedContract(address addr, bool isAuthorized) public onlyOwner {
        _authorizedContracts[addr] = isAuthorized;
    }

    function pause() public onlyOwner {
        _isPaused = true;
    }

    function unpause() public onlyOwner {
        _isPaused = false;
    }

    /**
     * @notice Checks if address is a contract
     * @dev It prevents contract from being targetted
     */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IPancakeRouter01.sol";

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

//SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.6;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

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

