// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./StarlinkComponent.sol";
import "./ShopItemFulfilment.sol";
import "./ILeveling.sol";
import "./base/token/BEP20/PancakeSwapHelper.sol";

contract Lottery is StarlinkComponent, ShopItemFulfilment, PancakeSwapHelper {
    struct Ticket {
        uint256 id;
        uint256 lotteryId;
        uint24 numbers;
        address owner;
        uint256 winnings;
    }

    struct Draw {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        uint256 pool;
        uint24 numbers;
        uint256[] allocationPerBracket;
        uint256 amountBurn;
    }

    address internal constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    mapping(uint256 => Ticket) public tickets;
    mapping(uint256 => Draw) public draws;
    mapping(uint256 => mapping(uint24 => mapping(uint24 => uint256))) entriesCountByBracket; //[drawId][bracket index][bracket numbers] => count
    mapping(uint256 => mapping(address => uint256[])) ticketIdsByUser;

    uint16[] public allocations;
    uint16 public burnAllocation;

    uint256 public nextDrawId;
    uint256 private nextTicketId;
    

    event TicketGiven(uint256 id);
    event DrawEnded(uint256 id);
    event DrawCreated(uint256 id);
    event WinningsClaimed(address from, uint256 amount);
    event Burned(uint256 amount);

    constructor(IXLD xld, IStarlinkEngine engine, IShop shop, address routerAddress) StarlinkComponent(xld, engine) ShopItemFulfilment(shop) PancakeSwapHelper(routerAddress) {
        pushDraw(block.timestamp + 5 minutes);
    }

    function fulfill(uint256, uint256 price, bool xldPayment, address from, uint256 quantity, uint256[] calldata params) external override onlyShop notPaused {
        uint256 xldReceived;
        if (xldPayment) {
            xldReceived = price;
        } else {
            xldReceived = buy(price);
        }

        for(uint i = 0; i < quantity; i++) {
            giveTicket(from, uint16(params[i]));
        }

        onDeposit(xldReceived);
    }

    function claim(uint256 ticketId) external notUnauthorizedContract nonReentrant process {
        Ticket memory ticket = tickets[ticketId];
        require(ticket.owner == msg.sender, "Lottery: Invalid ticket id");
        require(ticket.winnings == 0, "Lottery: Ticket already used");

        Draw memory draw = draws[ticket.lotteryId];
        require(draw.endTime != 0 && draw.endTime < block.timestamp, "Lottery: Not finished");

        uint256 winnings = calculateWinnings(draw, ticket.numbers);
        require(winnings > 0, "Lottery: Nothing to claim");
        
        ticket.winnings = winnings;
        xld.transfer(ticket.owner, winnings);

        emit WinningsClaimed(ticket.owner, winnings);
    }

    function end(uint256 seedKey) external onlyAdmins {
        Draw storage draw = draws[nextDrawId];
        draw.endTime = block.timestamp;
        draw.numbers = randomNumbers(seedKey);
        burn(draw.amountBurn);

        emit DrawEnded(nextDrawId);

        pushDraw(block.timestamp + 5 minutes);
    }

    function setAllocations(uint16[] calldata _allocations) public onlyAdmins {
        require(_allocations.length == 5, "Lottery: Invalid length");

        uint256 allocationSum = _allocations[0] + _allocations[1] + _allocations[2] + _allocations[3] + _allocations[4];
        require(allocationSum <= 1000, "Lottery: Invalid allocations");

        burnAllocation = uint16(1000 - allocationSum);
        allocations = _allocations;
    }

    function calculateWinnings(Draw memory draw, uint24 ticketNumbers) public view returns(uint256) {
        for(uint8 i = 0; i < 5; i++) {
            uint24 winBracket = bracket(draw.numbers, i);
            uint24 playedBracket = bracket(ticketNumbers, i);

            if (winBracket == playedBracket) {
                uint256 winnersCount = entriesCountByBracket[draw.id][i][winBracket];
                return draw.allocationPerBracket[i] / winnersCount;
            }
        }

        return 0;
    }


    function bracket(uint24 number, uint8 bracketIndex) public pure returns(uint24) {
        return uint24(number / 10**bracketIndex);
    }

    function ticketsOf(uint256 lotteryId, address user) public view returns(uint256[] memory) {
        return ticketIdsByUser[lotteryId][user];
    }

    function randomNumbers(uint256 seedKey) public view returns(uint24) {
        uint256 xldQueueIndex = xld.rewardClaimQueueIndex();

        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) + block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) + block.number +
            ((uint256(keccak256(abi.encodePacked(seedKey)))) / (block.timestamp)) + seedKey +
            ((uint256(keccak256(abi.encodePacked(xldQueueIndex)))) / (block.timestamp)) + xldQueueIndex +
            ((uint256(keccak256(abi.encodePacked(nextTicketId)))) / (block.timestamp)) + nextTicketId
        )));

        return uint24((seed - ((seed / 100000) * 100000)) - 1);
    }

    function pushDraw(uint256 startTime) private {
        require(draws[nextDrawId].endTime <= block.timestamp, "Lottery: Previous draw not over yet");

        nextDrawId++;

        uint256[] memory allocation;
        Draw memory draw = Draw(nextDrawId, startTime, 0, 0, 0, allocation, 0);
        draws[nextDrawId] = draw;

        emit DrawCreated(nextDrawId);
    }

    function giveTicket(address to, uint16 numbers) private {
        require(numbers <= 99999, "Lottery: Invalid numbers");
        require(draws[nextDrawId].startTime <= block.timestamp, "Lottery: Not started yet");

        Ticket memory ticket = Ticket(nextTicketId, nextDrawId, numbers, to, 0);
        tickets[nextTicketId] = ticket;

        for(uint8 i = 0; i < 5; i++) {
            uint24 bracketNumber = bracket(numbers, i);
            entriesCountByBracket[nextDrawId][i][bracketNumber]++;
        }

        ticketIdsByUser[nextDrawId][to].push(nextTicketId);
        
        emit TicketGiven(nextTicketId);
        nextTicketId++;
    }

    function onDeposit(uint256 amount) private {
        Draw storage draw = draws[nextDrawId];

        uint256 fundsToAllocate = amount;
        for(uint i = 0; i < 5; i++) {
            uint256 allocation = allocations[i] * amount / 1000;
            draw.allocationPerBracket[i] += allocation;
            fundsToAllocate -= allocation;
        }

        draw.amountBurn += fundsToAllocate;
    }

    function buy(uint256 bnbAmount) private returns(uint256) {
        if (bnbAmount > 0) {
            return swapBNBForTokens(bnbAmount, xld, address(this));
        }

        return 0;
    }

    function burn(uint256 amount) private {
        xld.transfer(BURN_ADDRESS, amount);
        emit Burned(amount);
    }
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
    uint256 processGas = 500000;

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

interface ILeveling {

    function grantStarlinkPoints(address userAddress, uint256 amount) external;

    function spendStarlinkPoints(address userAddress, uint256 amount) external;

    function levelUp(address userAddress) external;

    function changeName(address userAddress, bytes32 newName) external;

    function grantXp(address userAddress, uint256 amount, uint256 reasonId) external;
    
    function activateXpBoost(address userAddress, uint8 rate, uint256 duration) external;

    function deactivateXpBoost(address userAddress) external;

    function grantRestXp(address userAddress, uint256 amount) external;

    function spendRestXp(address userAddress, uint256 amount) external;

    function currentXpOf(address userAddress) external view returns(uint256); 

    function xpOfLevel(uint256 level) external pure returns (uint256);

    function levelOf(address userAddress) external view returns(uint256);

    function starlinkPointsPrecision() external pure returns(uint256);

    function setNameChangeVouchers(address userAddress, uint8 amount) external;

    function increaseNameChangeVouchers(address userAddress, uint8 amount) external;

    function decreaseNameChangeVouchers(address userAddress, uint8 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "../../../base/access/AccessControlled.sol";
import "./PancakeSwap/IPancakeRouter02.sol";
import "./PancakeSwap/IPancakeFactory.sol";
import "./PancakeSwap/IPancakePair.sol";
import "./IBEP20.sol";

abstract contract PancakeSwapHelper is AccessControlled {

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

	function calculateSwapAmount(uint256 bnbAmount, address token) public view returns (uint256) {
		IPancakePair pair = IPancakePair(IPancakeFactory(_pancakeswapV2Router.factory()).getPair(_pancakeswapV2Router.WETH(), address(token)));

		(uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

		return bnbAmount * reserve1 / reserve0;
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

interface IStarlink {
   	function processFunds(uint256 gas) external;

	function xldAddress() external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IStarlinkEngine {
    function addGas(uint256 amount) external;

    function donate() external payable;
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

interface IShopItemFulfilment {
    function fulfill(uint256 id, uint256 price, bool xldPayment, address from, uint256 quantity, uint256[] calldata params) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;


interface IShop {
    function addItem(uint8 typeId, uint256 val1, uint256 val2, uint112 req1, uint112 req2, uint256 price, uint8 discountRate, bool allowXldPayment, bool allowBnbPayment, bool bulkAllowed, address fulfilment, address fundsReceiver) external;

    function editItem(uint256 id, uint8 typeId, uint256 val1, uint256 val2, uint112 req1, uint112 req2, uint256 price, uint8 discountRate, bool allowXldPayment, bool allowBnbPayment, bool bulkAllowed) external;

    function setFulfilmentSystem(uint256 id, address fulfilment) external;

    function setFundsReceiver(uint256 id, address receiver) external;

    function itemInfo(uint256 id) external view returns(uint256, uint256, uint256, uint256, uint256);
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

