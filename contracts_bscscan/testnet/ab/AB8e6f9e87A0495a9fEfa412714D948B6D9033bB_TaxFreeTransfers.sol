// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./base/token/BEP20/EmergencyWithdrawable.sol";
import "./base/token/BEP20/IXLD.sol";
import "./StarlinkComponent.sol";
import "./ShopItemFulfilment.sol";
import "./IStarlinkEngine.sol";
import "./base/token/BEP20/PancakeSwap/IPancakeRouter02.sol";

contract TaxFreeTransfers is StarlinkComponent, ShopItemFulfilment {
    struct UserInfo {
        uint256 lastTaxFreeTransferTime;
        uint256 lastTaxExemptionTime;
        uint256 taxFreeTransferVouchers;
        uint256 taxExemptionTokens;
    }

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    uint256 public taxFreeTransferCooldown;
    uint256 public taxExemptCooldown;

    uint256 public taxExemptMinTax = 50;
    address internal _pancakeSwapRouterAddress;
	IPancakeRouter02 internal _pancakeswapV2Router;

    mapping(address => UserInfo) public userInfo;

    event TaxFreeVoucherRedeemed(address user, address destination, uint256 amount);
    event TaxExemptRedeemedBuy(address user, uint256 amount);
    event TaxExemptRedeemedSell(address user, uint256 amount);

	constructor(IXLD xld, IStarlinkEngine engine, IShop shop, address routerAddress) StarlinkComponent(xld, engine) ShopItemFulfilment(shop) {
        taxFreeTransferCooldown = 6 hours;

        setPancakeSwapRouter(routerAddress);
	}

    function redeemTaxFreeVoucher(address destination, uint256 amount) external notPaused notUnauthorizedContract nonReentrant isNotUnauthorizedContract(destination) process {
        UserInfo storage user = userInfo[msg.sender];
        require(user.taxFreeTransferVouchers > 0, "TaxFreeTransfers: Not enough vouchers");
        require(user.lastTaxFreeTransferTime == 0 || block.timestamp - user.lastTaxFreeTransferTime > taxFreeTransferCooldown, "TaxFreeTransfers: Wait some time");

        doTaxFreeTransfer(user, msg.sender, destination, amount);
        emit TaxFreeVoucherRedeemed(msg.sender, destination, amount);
    }

    function taxExemptBuy(uint256 amountOutMin) external payable notPaused notUnauthorizedContract nonReentrant process {
        UserInfo storage user = userInfo[msg.sender];
        require(user.taxExemptionTokens >= amountOutMin, "TaxFreeTransfers: Not enough TET");
        require(xld.isExcludedFromFees(address(this)), "TaxFreeTransfers: Not enabled");
        require(msg.value > 0, "TaxFreeTransfers: Amount must be greater than zero");
        require(user.lastTaxExemptionTime == 0 || block.timestamp - user.lastTaxExemptionTime > taxExemptCooldown, "TaxFreeTransfers: Wait some time");

        user.lastTaxExemptionTime = block.timestamp;

        // Buy XLD using received BNB
        uint256 amountTaxed = msg.value * taxExemptMinTax / 1000;
        uint256 amountBought = swapBNBForXLD(msg.value - amountTaxed, amountOutMin);
        user.taxExemptionTokens -= amountBought;

        // Send the amount bought
        xld.transfer(msg.sender, amountBought);

        // Sent taxed amount to XLD reward pool
        (bool sent,) = address(xld).call{value : amountTaxed, gas: 3000}("");
        require(sent, "TaxFreeTransfers: XLD funding reverted");

        emit TaxExemptRedeemedBuy(msg.sender, amountBought);
    }

    function taxExemptSell(uint256 xldAmount, uint256 amountOutMin) external notPaused notUnauthorizedContract nonReentrant process {
        require(xld.allowance(msg.sender, address(this)) >= xldAmount, "TaxFreeTransfers: Not approved");
        require(xldAmount > 0, "TaxFreeTransfers: Amount must be greater than zero");

        UserInfo storage user = userInfo[msg.sender];
        require(user.taxExemptionTokens >= xldAmount, "TaxFreeTransfers: Not enough TET");
        require(xld.isExcludedFromFees(address(this)), "TaxFreeTransfers: Not enabled");
        require(user.lastTaxExemptionTime == 0 || block.timestamp - user.lastTaxExemptionTime > taxExemptCooldown, "TaxFreeTransfers: Wait some time");

        user.lastTaxExemptionTime = block.timestamp;
        user.taxExemptionTokens -= xldAmount;

        // Receive XLD from sender
        xld.transferFrom(msg.sender, address(this), xldAmount);

        // Sell the XLD
        uint256 bnbReceived = swapXLDForBNB(xldAmount, amountOutMin);
        uint256 amountTaxed = bnbReceived * taxExemptMinTax / 1000;

        // Sent taxed amount to XLD reward pool
        (bool sent,) = address(xld).call{value : amountTaxed, gas: 3000}("");
        require(sent, "TaxFreeTransfers: XLD funding reverted");

        // Send the BNB received
        (sent,) = msg.sender.call{value : bnbReceived - amountTaxed, gas: 3000}("");
        require(sent, "TaxFreeTransfers: BNB transfer reverted");

        emit TaxExemptRedeemedSell(msg.sender, xldAmount);
    }

    function taxFreeTransfer(address source, address destination, uint256 amount) external onlyAdmins {
        UserInfo storage user = userInfo[source];
        doTaxFreeTransfer(user, source, destination, amount);
    }

    function increaseTaxFreeTransferVouchers(address userAddress, uint256 amount) external onlyAdmins {
        UserInfo storage user = userInfo[userAddress];
        user.taxFreeTransferVouchers += amount;
    }

    function increaseTaxExemptionTokens(address userAddress, uint256 amount) external onlyAdmins {
        userInfo[userAddress].taxExemptionTokens += amount;
    }

    function decreaseTaxExemptionTokens(address userAddress, uint256 amount) external onlyAdmins {
        userInfo[userAddress].taxExemptionTokens -= amount;
    }

    function decreaseTaxFreeTransferVouchers(address userAddress, uint256 amount) external onlyAdmins {
        UserInfo storage user = userInfo[userAddress];
        user.taxFreeTransferVouchers -= amount;
    }

    function setTaxFreeTransferCooldown(uint256 duration) external onlyOwner {  
        taxFreeTransferCooldown = duration;
    }

    function fulfill(uint256 id, address from, uint256, uint256) external override onlyShop notPaused {
        UserInfo storage user = userInfo[from];
        (, uint256 val1, ) = shop.itemInfo(id);

        user.taxFreeTransferVouchers += val1;
    }

    function doTaxFreeTransfer(UserInfo storage user, address source, address destination, uint256 amount) private {
        require(amount > 0, "TaxFreeTransfers: Invalid amount");
        require(xld.allowance(source, address(this)) >= amount, "TaxFreeTransfers: Not enabled");

        uint256 destinationBalance = xld.balanceOf(destination);
        require(destinationBalance == 0 || xld.calculateRewardCycleExtension(destinationBalance, amount) == 0, "TaxFreeTransfers: Penalty");
        require(xld.isExcludedFromFees(address(this)), "TaxFreeTransfers: Transfers disabled");
        
        user.taxFreeTransferVouchers--;
        user.lastTaxFreeTransferTime = block.timestamp;

        xld.transferFrom(source, address(this), amount);
        xld.transfer(destination, amount);
    }

	function swapBNBForXLD(uint256 bnbAmount, uint256 amountOutMin) internal returns(uint256) { 
		uint256 previousBalance = xld.balanceOf(address(this));

		address[] memory path = new address[](2);
		path[0] = _pancakeswapV2Router.WETH();
		path[1] = address(xld);

		_pancakeswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: bnbAmount }(amountOutMin, path, address(this), block.timestamp + 360);
        
		return xld.balanceOf(address(this)) - previousBalance;
	}

	function swapXLDForBNB(uint256 tokenAmount, uint256 amountOutMin) internal returns(uint256) {
		uint256 initialBalance = address(this).balance;

		address[] memory path = new address[](2);
		path[0] = address(xld);
		path[1] = _pancakeswapV2Router.WETH();

		_pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, amountOutMin, path, address(this), block.timestamp + 360);

		return address(this).balance - initialBalance;
	}

    function setPancakeSwapRouter(address routerAddress) public onlyOwner {
		require(routerAddress != address(0), "Cannot use the zero address as router address");

		_pancakeSwapRouterAddress = routerAddress; 
		_pancakeswapV2Router = IPancakeRouter02(_pancakeSwapRouterAddress);
	}

    function setMinTaxMagnitude(uint256 _taxExemptMinTax) external onlyOwner {
        require(_taxExemptMinTax <= 1000, "TaxFreeTransfers: Min tax magnitude is too high");
        taxExemptMinTax = _taxExemptMinTax;
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

import "./base/token/BEP20/IXLD.sol";
import "./IStarlink.sol";
import "./IStarlinkEngine.sol";
import "./base/access/AccessControlled.sol";
import "./base/token/BEP20/EmergencyWithdrawable.sol";

contract StarlinkComponent is AccessControlled, EmergencyWithdrawable {
    IXLD public xld;
    IStarlinkEngine public engine;
    uint256 public processGas = 300000;

    modifier process() {
        if (processGas > 0) {
            engine.addGas(processGas);
        }
        
        _;
    }

    constructor(IXLD _xld, IStarlinkEngine _engine) {
        require(address(_xld) != address(0), "StarlinkComponent: Invalid address");
       
        xld = _xld;
        setEngine(_engine);
    }

    function setProcessGas(uint256 gas) external onlyOwner {
        processGas = gas;
    }

    function setEngine(IStarlinkEngine _engine) public onlyOwner {
        require(address(_engine) != address(0), "StarlinkComponent: Invalid address");

        engine = _engine;
    }

    function setXld(IXLD _xld) public onlyOwner {
        require (address(_xld) != address(0), "StarlinkComponent: Invalid address");
        xld = _xld;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IShopItemFulfilment.sol";
import "./IShop.sol";
import "./base/access/AccessControlled.sol";

abstract contract ShopItemFulfilment is IShopItemFulfilment, AccessControlled {
    IShop public shop;

    constructor(IShop _shop) {
        setShop(_shop);
    }

    modifier onlyShop() {
        require(msg.sender == address(shop), "ShopItemFulfilment: Only shop can call this");
        _;
    }

    function setShop(IShop _shop) public onlyOwner {
         require(address(_shop) != address(0), "ShopItemFulfilment: Invalid address");
         shop = _shop;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IStarlinkEngine {
    function addGas(uint256 amount) external;
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
            require(!_isContract(msg.sender), "AccessControlled: unauthorized contract not allowed");
            require(msg.sender == tx.origin, "AccessControlled: unauthorized proxy contract not allowed");
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

interface IStarlink {
   	function processFunds(uint256 gas) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IShopItemFulfilment {
    function fulfill(uint256 id, address from, uint256 quantity, uint256 param) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;


interface IShop {
    function upsertItem(uint256 id, uint8 typeId, uint256 price, uint8 discountRate, uint8 bulkDiscountRate, uint256 val1, uint256 val2, address fulfilment, address fundsReceiver) external;

    function itemInfo(uint256 id) external view returns(uint256, uint256, uint256);
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

