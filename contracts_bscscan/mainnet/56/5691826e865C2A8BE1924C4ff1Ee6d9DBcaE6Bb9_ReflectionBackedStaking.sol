// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IDEXRouter} from './interfaces/IDEXRouter.sol';
import {Pausable} from '@openzeppelin/contracts/security/Pausable.sol';
import "./interfaces/IBEP20.sol";
import "./interfaces/IGatewayHook.sol";
import "./interfaces/IStaking.sol";
import './Auth.sol';
import "./EarnHub.sol";



contract ReflectionBackedStaking is IGatewayHook, IStaking, Auth, Pausable {
    // * Event declarations
    event EnterStaking(address addr, uint256 amt);
    event LeaveStaking(address addr, uint256 amt);
    event Harvest(address addr, uint256 unpaidAmount);

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    struct TokenPool {
        uint256 totalShares;
        uint256 totalDividends;
        uint256 totalDistributed;
        uint256 dividendsPerShare;
        IBEP20 rewardsToken;
        IBEP20 stakingToken;
    }

    IDEXRouter public router;

    TokenPool public tokenPool;

    IAnyflect public anyflect = IAnyflect(0x8e3Ad8D73EE2439c3ce0A293e59C19563C2C56F5);

    EarnHub public earnHub;
    IBEP20 public rewardsToken;

    mapping(address => Share) public shares; // Shares by token vault

    mapping(address => bool) excludeSwapperRole;

    uint256 public launchedAt;

    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    bool public swapping = false;

    constructor(
        address _router,
        IBEP20 _rewardsToken,
        IBEP20 _stakingToken,
        EarnHub _earnHub
    ) Auth(msg.sender) {
        router = _router != address(0) ? IDEXRouter(_router) : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        rewardsToken = _rewardsToken;
        tokenPool.rewardsToken = rewardsToken;
        tokenPool.stakingToken = _stakingToken;
        earnHub = _earnHub;
        launchedAt = block.timestamp;
    }

    receive() external payable {
        require(!paused(), 'Contract has been paused');

        if (swapping)
            return;

        if (!excludeSwapperRole[msg.sender]) {
            getRewardsToken(address(this).balance);
        }
    }

    // * Lets you stake stakingToken
    function enterStaking(uint256 _amt) external whenNotPaused {
        require(tokenPool.stakingToken.allowance(msg.sender, address(this)) >= _amt, 'Not enough allowance');
        _enterStaking(msg.sender, _amt, msg.sender);
    }

    function _enterStaking(address _addr, uint256 _amt, address _transferFromAddr) internal {
        if (_amt == 0) _amt = tokenPool.stakingToken.balanceOf(_addr);

        require(_amt <= tokenPool.stakingToken.balanceOf(_transferFromAddr), 'Insufficient balance to enter staking');

        earnHub.setIsFeeExempt(_transferFromAddr, true);
        bool success = tokenPool.stakingToken.transferFrom(_transferFromAddr, address(this), _amt);
        earnHub.setIsFeeExempt(_transferFromAddr, false);

        require(success, 'Failed to fetch tokens towards the staking contract');

        // Give out rewards if already staking
        if (shares[_addr].amount > 0) {
            giveStakingReward(_addr);
        }

        addShareHolder(_addr, _amt);
        emit EnterStaking(_addr, _amt);
    }

    function leaveStaking(uint256 _amt) external {
        _leaveStaking(_amt, msg.sender);
    }

    function _leaveStaking(uint256 _amt, address _staker) internal {
        require(shares[_staker].amount > 0, 'You are not currently staking');

        // Pay native token rewards.
        if (getUnpaidEarnings(_staker) > 0) {
            giveStakingReward(_staker);
        }


        if (_amt == 0) _amt = shares[_staker].amount;
        // Update shares for address
        _removeShares(_amt, _staker);
        // Get rewards from contract
        tokenPool.stakingToken.transfer(_staker, _amt);

        emit LeaveStaking(_staker, _amt);
    }

    function reinvest() external {
        uint256 earnHubAmtObtained = _swapStakingRewards(getUnpaidEarnings(msg.sender));
        _reinvestStake(msg.sender, earnHubAmtObtained);
    }

    function _reinvestStake(address _addr, uint256 _amt) internal {
        addShareHolder(_addr, _amt);
    }

    function giveStakingReward(address _shareholder) internal {
        require(shares[_shareholder].amount > 0, 'You are not currently staking');

        uint256 amount = getUnpaidEarnings(_shareholder);

        if (amount > 0) {
            tokenPool.totalDistributed += amount;
            shares[_shareholder].totalRealised += amount;
            shares[_shareholder].totalExcluded = getCumulativeDividends(shares[_shareholder].amount);
            rewardsToken.transfer(_shareholder, amount);
        }
    }

    function _swapStakingRewards(uint256 _amt) internal returns (uint256) {
        uint256 earnHubBalanceBefore = earnHub.balanceOf(address(this));

        address[] memory path = new address[](3);
        path[0] = address(tokenPool.rewardsToken);
        path[1] = router.WETH();
        path[2] = address(tokenPool.stakingToken);

        tokenPool.rewardsToken.approve(address(router), _amt);
        swapping = true;
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amt,
            0,
            path,
            address(this),
            block.timestamp
        );
        swapping = false;

        uint256 balanceAfter = earnHub.balanceOf(address(this));

        return balanceAfter - earnHubBalanceBefore;
    }

    function harvest() external whenNotPaused {
        require(getUnpaidEarnings(msg.sender) > 0, 'No earnings yet ser');
        uint256 unpaid = getUnpaidEarnings(msg.sender);
        if (!isLiquid(getUnpaidEarnings(msg.sender))) {
            getRewardsToken(address(this).balance);
        }
        giveStakingReward(msg.sender);
        emit Harvest(msg.sender, unpaid);
    }

    function getUnpaidEarnings(address _shareholder) public view returns (uint256) {
        if (shares[_shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[_shareholder].amount);
        uint256 shareholderTotalExcluded = shares[_shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return (shareholderTotalDividends - shareholderTotalExcluded);
    }

    // * Update pool shares and user data
    function addShareHolder(address _shareholder, uint256 _amt) internal {
        tokenPool.totalShares += _amt;
        shares[_shareholder].amount += _amt;
        shares[_shareholder].totalExcluded = getCumulativeDividends(shares[_shareholder].amount);
    }

    function _removeShares(uint256 _amt, address _staker) internal {
        tokenPool.totalShares -= _amt;
        shares[_staker].amount -= _amt;
        shares[_staker].totalExcluded = getCumulativeDividends(shares[_staker].amount);
    }

    function getCumulativeDividends(uint256 _share) public view returns (uint256) {
        return _share * tokenPool.dividendsPerShare / dividendsPerShareAccuracyFactor;
    }

    function isLiquid(uint256 _amt) internal view returns (bool) {
        return rewardsToken.balanceOf(address(this)) > _amt;
    }

    function getRewardsTokenPath() internal view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(rewardsToken);
        return path;
    }

    function getRewardsToken(uint256 _amt) internal returns (uint256) {
        if (tokenPool.totalShares == 0)
            return 0;
        uint256 balanceBefore = rewardsToken.balanceOf(address(this));

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value : _amt}(
            0,
            getRewardsTokenPath(),
            address(this),
            block.timestamp
        );

        uint256 amount = (rewardsToken.balanceOf(address(this)) - balanceBefore);

        tokenPool.totalDividends += amount;
        tokenPool.dividendsPerShare += (dividendsPerShareAccuracyFactor * amount / tokenPool.totalShares);
        return amount;
    }

    // * Enables hopping between staking pools
    // ! Authorize all pools to enable hops.
    function makeHop(IStaking _newPool) external override {
        require(shares[msg.sender].amount > 0, 'Not enough in stake to hop');
        uint256 amt = shares[msg.sender].amount;
        // Pay native token rewards.
        if (getUnpaidEarnings(msg.sender) > 0) {
            giveStakingReward(msg.sender);
        }
        _removeShares(amt, msg.sender);
        tokenPool.stakingToken.approve(address(_newPool), tokenPool.stakingToken.totalSupply());
        _newPool.receiveHop(amt, msg.sender, payable(address(this)));
    }

    // * Has to be authorized due to being able to spoof a ReflctionBackedStaking contract, enabling phishing venues for scammers.
    function receiveHop(uint256 _amt, address _addr, address payable _oldPool) external override authorized {
        require(tokenPool.stakingToken.allowance(_oldPool, address(this)) >= _amt, 'Not enough allowance');
        _enterStaking(_addr, _amt, _oldPool);

        anyflect.setShares(address(0x1), _addr, 0, _amt + tokenPool.stakingToken.balanceOf(_addr)); //overwriting anyflect shares
    }

    // * [START] Setter Functions
    function pause(bool _pauseStatus) external authorized {
        if (_pauseStatus) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setSwapperExcluded(address _addr, bool _excluded) external authorized {
        excludeSwapperRole[_addr] = _excluded;
    }

    function lunch() external authorized {
        launchedAt = block.timestamp;
    }

    function setStakingToken(IBEP20 _stakingToken) external authorized {
        tokenPool.stakingToken = _stakingToken;
    }

    function setRewardToken(IBEP20 _rewardToken) external authorized {
        rewardsToken = _rewardToken;
        tokenPool.rewardsToken = _rewardToken;
    }

    function setEarnHub(EarnHub _earnHubToken) external authorized {
        earnHub = _earnHubToken;
    }

    function setAnyFlect(IAnyflect _anyflect) external authorized {
        anyflect = _anyflect;
    }
    // * [END] Setter Functions

    // * [START] IGatewayHook functions
    function process(EarnHubLib.Transfer memory transfer, uint256 gasLimit) external override(IGatewayHook) {

    }

    function depositBNB() external payable override (IGatewayHook) {
        if (!excludeSwapperRole[msg.sender]) {
            getRewardsToken(address(this).balance);
        }
    }

    function excludeFromProcess(bool val) external override (IGatewayHook) {
        excludeSwapperRole[msg.sender] = true;
    }
    // * [END] IGatewayHook functions

    // * [START] Auxiliary Functions
    // Grabs any shitcoin someone sends to our contract, converts it to rewards for our holders ♥
    function fuckShitcoins(IBEP20 _shitcoin, address[] memory _path) external authorized {

        require(
            address(_shitcoin) != address(rewardsToken) ||
            address(_shitcoin) != address(tokenPool.stakingToken),
            "Hey this is a safe space"
        );


        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _shitcoin.balanceOf(address(this)),
            0,
            _path,
            address(this),
            block.timestamp
        );
    }

    function emergencyWithdraw() external {
        tokenPool.stakingToken.transfer(msg.sender, shares[msg.sender].amount);
        _removeShares(shares[msg.sender].amount, msg.sender);
    }

    function rescueSquad(address payable _to) external authorized {
        (bool succ,) = _to.call{value : address(this).balance}("");
        require(succ, "unable to send value, recipient may have reverted");
    }

    function rescueSquadTokens(address _to) external authorized {
        rewardsToken.transfer(_to, rewardsToken.balanceOf(address(this)));
        earnHub.transfer(_to, earnHub.balanceOf(address(this)));
    }
    // * [END] Auxiliary Functions

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
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


    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "../libraries/EarnHubLib.sol";

interface IGatewayHook {
    //should be called only when depositBNB > 0
    function depositBNB() external payable;
    //should be called either case
    function process(EarnHubLib.Transfer memory transfer, uint gasLimit) external;
    function excludeFromProcess(bool val) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IStaking {
    function makeHop(IStaking _newPool) external;
    function receiveHop(uint amt, address _addr, address payable oldPool) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only. Calls internal _authorize method
     */
    function authorize(address adr) external onlyOwner {
        _authorize(adr);
    }
    
    function _authorize (address adr) internal {
        authorizations[adr] = true;
    }
    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

///$$$$       /$$$$$$$$                               /$$   /$$           /$$             /$$$$
//| $$_/      | $$_____/                              | $$  | $$          | $$            |_  $$
//| $$        | $$        /$$$$$$   /$$$$$$  /$$$$$$$ | $$  | $$ /$$   /$$| $$$$$$$         | $$
//| $$        | $$$$$    |____  $$ /$$__  $$| $$__  $$| $$$$$$$$| $$  | $$| $$__  $$        | $$
//| $$        | $$__/     /$$$$$$$| $$  \__/| $$  \ $$| $$__  $$| $$  | $$| $$  \ $$        | $$
//| $$        | $$       /$$__  $$| $$      | $$  | $$| $$  | $$| $$  | $$| $$  | $$        | $$
//| $$$$      | $$$$$$$$|  $$$$$$$| $$      | $$  | $$| $$  | $$|  $$$$$$/| $$$$$$$/       /$$$$
//|____/      |________/ \_______/|__/      |__/  |__/|__/  |__/ \______/ |_______/       |____/
//
//
//    JOIN OUR TELEGRAM GROUP > t.me/earnhubBSC
//    JOIN OUR TELEGRAM GROUP > t.me/earnhubBSC
//    JOIN OUR TELEGRAM GROUP > t.me/earnhubBSC
//    JOIN OUR TELEGRAM GROUP > t.me/earnhubBSC
//    JOIN OUR TELEGRAM GROUP > t.me/earnhubBSC
//    JOIN OUR TELEGRAM GROUP > t.me/earnhubBSC
//
//
///$$      /$$ /$$                                           /$$
//| $$  /$ | $$| $$                                          |__/
//| $$ /$$$| $$| $$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$        /$$ /$$$$$$$   /$$$$$$$  /$$$$$$  /$$$$$$/$$$$   /$$$$$$
//| $$/$$ $$ $$| $$__  $$ /$$__  $$ /$$__  $$ /$$__  $$      | $$| $$__  $$ /$$_____/ /$$__  $$| $$_  $$_  $$ /$$__  $$
//| $$$$_  $$$$| $$  \ $$| $$$$$$$$| $$  \__/| $$$$$$$$      | $$| $$  \ $$| $$      | $$  \ $$| $$ \ $$ \ $$| $$$$$$$$
//| $$$/ \  $$$| $$  | $$| $$_____/| $$      | $$_____/      | $$| $$  | $$| $$      | $$  | $$| $$ | $$ | $$| $$_____/
//| $$/   \  $$| $$  | $$|  $$$$$$$| $$      |  $$$$$$$      | $$| $$  | $$|  $$$$$$$|  $$$$$$/| $$ | $$ | $$|  $$$$$$$
//|__/     \__/|__/  |__/ \_______/|__/       \_______/      |__/|__/  |__/ \_______/ \______/ |__/ |__/ |__/ \_______/
//
//
//
///$$                   /$$     /$$                                             /$$
//|__/                  | $$    | $$                                            | $$
///$$  /$$$$$$$       /$$$$$$  | $$$$$$$   /$$$$$$         /$$$$$$  /$$   /$$ /$$$$$$    /$$$$$$$  /$$$$$$  /$$$$$$/$$$$   /$$$$$$
//| $$ /$$_____/      |_  $$_/  | $$__  $$ /$$__  $$       /$$__  $$| $$  | $$|_  $$_/   /$$_____/ /$$__  $$| $$_  $$_  $$ /$$__  $$
//| $$|  $$$$$$         | $$    | $$  \ $$| $$$$$$$$      | $$  \ $$| $$  | $$  | $$    | $$      | $$  \ $$| $$ \ $$ \ $$| $$$$$$$$
//| $$ \____  $$        | $$ /$$| $$  | $$| $$_____/      | $$  | $$| $$  | $$  | $$ /$$| $$      | $$  | $$| $$ | $$ | $$| $$_____/
//| $$ /$$$$$$$/        |  $$$$/| $$  | $$|  $$$$$$$      |  $$$$$$/|  $$$$$$/  |  $$$$/|  $$$$$$$|  $$$$$$/| $$ | $$ | $$|  $$$$$$$
//|__/|_______/          \___/  |__/  |__/ \_______/       \______/  \______/    \___/   \_______/ \______/ |__/ |__/ |__/ \_______/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Auth} from "./Auth.sol";
import {EarnHubLib} from "./libraries/EarnHubLib.sol";
import {IBEP20} from "./interfaces/IBEP20.sol";
import {IDEXRouter} from "./interfaces/IDEXRouter.sol";
import {IDEXFactory} from "./interfaces/IDEXFactory.sol";
import "./interfaces/ITransferGateway.sol";
import "./interfaces/IAnyflect.sol";
import "./interfaces/ILoyaltyTracker.sol";



contract EarnHub is IBEP20, Auth {
    // * Custom Event declarations
    event GenericErrorEvent(string reason);

    address deadAddress = 0x000000000000000000000000000000000000dEaD;

    // Fees
    uint256 public baseSellFee = 1700; //! default floor sale Fee, always taxes higher and decays to this value after N days (see getVariableFee())
    uint256 public currentSellFee = baseSellFee;
    uint256 public maxSellFee = 0;
    uint256 public transferFee = 0;
    uint256 public baseBuyFee = 1200;

    // Variable Fee timestamps
    uint256 public variableFeeStartingTimestamp;
    uint256 public variableFeeEndingTimestamp;

    // Convenience data
    address public pair;
    mapping(address => bool) liquidityPairs;

    mapping(address => bool) isPresale;

    // Token data
    string constant _name = "EarnHub Token";
    string constant _symbol = "EHB";
    uint8 constant _decimals = 9;
    uint256 public _totalSupply = 7e13 * 1e9;
    uint256 public _maxTxAmount = _totalSupply;
    uint256 public _swapThreshold = 1000 * 1e9;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping (address => bool ) isBasicTransfer;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) isTxLimitExempt;

    // User data
    mapping(address => EarnHubLib.User) public users;

    IAnyflect public anyflect;
    mapping(address => bool) public isAnyflectExempt;

    IDEXRouter public router;
    ITransferGateway public transferGateway;
    ILoyaltyTracker public loyaltyTracker;

    // Modifier used to know if our own contract executed a swap and this transfer corresponds to a swap executed by this contract. This is used to prevent circular liquidity issues.
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (address _dexRouter, ITransferGateway _transferGateway, string memory _name, string memory _symbol) Auth(msg.sender) {
        // Token Variables
        _name = _name;
        _symbol = _symbol;

        transferGateway = _transferGateway;
        _authorize(address(transferGateway));

        isFeeExempt[msg.sender] = true;
        isFeeExempt[_dexRouter] = true;
        isTxLimitExempt[msg.sender] = true;

        // Enabling Dex trading
        router = IDEXRouter(_dexRouter);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        liquidityPairs[pair] = true;
        _allowances[address(this)][address(router)] = _totalSupply;
        approve(_dexRouter, _totalSupply);
        approve(address(pair), _totalSupply);

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {

        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] -= amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (inSwap || sender == address(anyflect) || isBasicTransfer[sender]) {return _basicTransfer(sender, recipient, amount);}


        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");

        if (_shouldSwapBack()) { _swapBack(); }
        EarnHubLib.TransferType transferType = _createTransferType(sender, recipient);

        // * Getting referral data for transferType
        bool isReferral;
        uint256 referralBuyDiscount;
        uint256 referralSellDiscount;
        uint256 referralCount;
        if (address(loyaltyTracker) != address(0)) {
            (isReferral, referralBuyDiscount, referralSellDiscount, referralCount) = getReferralData(sender);
            if (referralSellDiscount > baseSellFee) {
                emit GenericErrorEvent("_transferFrom(): referralSellDiscount > baseSellFee");
            }
            if (referralBuyDiscount > baseBuyFee) {
                emit GenericErrorEvent("_transferFrom(): referralBuyDiscount > baseBuyFee");
            }
        }

        uint amountAfterFee = !isFeeExempt[sender] ? _takeFee(sender, recipient, amount, transferType, referralBuyDiscount, referralSellDiscount) : amount;
        _balances[sender] -= amount;
        _balances[recipient] += amountAfterFee;

        EarnHubLib.User memory user = _createOrUpdateUser(address(sender), block.timestamp, isReferral, referralBuyDiscount, referralSellDiscount, referralCount);

        EarnHubLib.Transfer memory transf = _createTransfer(user, amount, transferType, sender, recipient);


        if (address(anyflect) != address(0)) {
            uint256 balancesSender = _balances[sender];
            uint256 balancesRecipient = _balances[recipient];

            try anyflect.setShares(sender, recipient, balancesSender, balancesRecipient) {

            } catch Error (string memory reason) {
                emit GenericErrorEvent("_transferFrom(): anyflect.setShares() Failed");
                emit GenericErrorEvent(reason);
            }
        }


        try transferGateway.onTransfer(transf) {

        } catch Error (string memory reason) {
            emit GenericErrorEvent('_transferFrom(): transferGateway.onTransfer() Failed');
            emit GenericErrorEvent(reason);
        }

        emit Transfer(sender, recipient, amountAfterFee);
        return true;
    }

    function _createOrUpdateUser(address _addr, uint256 _lastPurchase, bool _isReferral, uint256 _referralBuyDiscount, uint256 _referralSellDiscount, uint256 _referralCount) internal returns (EarnHubLib.User memory) {
        EarnHubLib.User memory user = EarnHubLib.User(_addr, _lastPurchase, _isReferral, _referralBuyDiscount, _referralSellDiscount, _referralCount);

        users[_addr] = user;

        return user;
    }

    function _createTransferType(address _from, address _recipient) internal view returns (EarnHubLib.TransferType) {
        if (liquidityPairs[_recipient]) {
            return EarnHubLib.TransferType.Sale;
        } else if (liquidityPairs[_from] || isPresale[_from]) {
            return EarnHubLib.TransferType.Purchase;
        }
        return EarnHubLib.TransferType.Transfer;
    }

    function _createTransfer(EarnHubLib.User memory _address, uint256 _amt, EarnHubLib.TransferType _transferType, address _from, address _to) internal pure returns (EarnHubLib.Transfer memory) {
        EarnHubLib.Transfer memory _transfer = EarnHubLib.Transfer(_address, _amt, _transferType, _from, _to);
        return _transfer;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _takeFee(address _sender, address _receiver, uint256 _amount, EarnHubLib.TransferType _transferType, uint256 _referralBuyDiscount, uint256 _referralSellDiscount) internal returns (uint256) {
        // * Takes the fee and keeps remainder in contract
        uint256 feeAmount = _amount * getTotalFee(_transferType, _referralBuyDiscount, _referralSellDiscount) / 10000;

        if (feeAmount > 0) {
            _balances[address(this)] += feeAmount;
            emit Transfer(_sender, address(this), feeAmount);
        }

        return (_amount - feeAmount);
    }

    function _shouldSwapBack() internal view returns (bool) {
        return ((msg.sender != pair) && (!inSwap) && (_balances[address(this)] >= _swapThreshold));
    }

    function _swapBack() internal swapping {
        uint256 amountToSwap = _swapThreshold;

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

        try transferGateway.depositBNB{value : amountBNB}() {
        } catch Error(string memory reason) {
            emit GenericErrorEvent("_swapBack(): transferGateway.depositBNB() Failed");
            emit GenericErrorEvent(reason);
        }
    }


    // * Getter (view only) Functions
    function getCirculatingSupply() public view returns (uint256) {
        return (_totalSupply - balanceOf(deadAddress) - balanceOf(address(0)));
    }

    function getLiquidityBacking(uint256 _accuracy) public view returns (uint256) {
        return (_accuracy * (balanceOf(pair) * 2) / getCirculatingSupply());
    }

    function isOverLiquified(uint256 _target, uint256 _accuracy) public view returns (bool) {
        return (getLiquidityBacking(_accuracy) > _target);
    }

    function getTotalFee(EarnHubLib.TransferType _transferType, uint256 _referralBuyDiscount, uint256 _referralSellDiscount) public returns (uint256) {


        if (_transferType == EarnHubLib.TransferType.Sale) {
            uint256 sellFee = maxSellFee > 0 ? getVariableSellFee() : baseSellFee;
            if (_referralSellDiscount > 0) sellFee -= _referralSellDiscount;
            return sellFee;
        }
        if (_transferType == EarnHubLib.TransferType.Transfer) {
            return transferFee;
        }
        else {
            uint256 buyFee = baseBuyFee;
            if (_referralBuyDiscount > 0) buyFee -= _referralBuyDiscount;
            return buyFee;
        }
    }

    function getVariableSellFee() public returns (uint256) {
        // ! starts at maxSellFee then lineally decays to baseSellFee over variableTaxTimeframe

        // * variable sell fee timeframe ended or timeframe hasn't started
        if (variableFeeStartingTimestamp > block.timestamp || variableFeeEndingTimestamp < block.timestamp) {
            if (variableFeeEndingTimestamp < block.timestamp) maxSellFee = 0;
            currentSellFee = baseSellFee;
            return baseSellFee;
        } else if (variableFeeStartingTimestamp <= block.timestamp && block.timestamp <= variableFeeEndingTimestamp) {// * while in variable fee timeframe
            // * how long does variableFee timeframe lasts in seconds
            uint256 variableTaxTimeframe = variableFeeEndingTimestamp - variableFeeStartingTimestamp;
            uint256 sellFee = baseSellFee + ((maxSellFee - baseSellFee) * (variableTaxTimeframe - (block.timestamp - variableFeeStartingTimestamp))) / variableTaxTimeframe;
            currentSellFee = sellFee;
            return sellFee;
        }
        return baseSellFee;
    }

    function getReferralData(address _addr) public returns (bool isReferral, uint256 referralBuyDiscount, uint256 referralSellDiscount, uint256 referralCount) {

        try loyaltyTracker.getReferralData(_addr) returns (bool isReferral, uint256 referralBuyDiscount, uint256 referralSellDiscount, uint256 referralCount){
            isReferral = isReferral;
            referralBuyDiscount = referralBuyDiscount;
            referralSellDiscount = referralSellDiscount;
            referralCount = referralCount;

        } catch Error (string memory reason){
            emit GenericErrorEvent('getReferralData(): loyaltyTracker.getReferralData() Failed');
            emit GenericErrorEvent(reason);

            isReferral = false;
            referralBuyDiscount = 0;
            referralSellDiscount = 0;
            referralCount = 0;
        }

        return (isReferral, referralBuyDiscount, referralSellDiscount, referralCount);

    }


    // * Setter (write only) Functions
    function setVariableSellFeeParams(uint256 _maxSellFee, bool _useCurrentTimestampForStart, uint256 _startingTimestamp, uint256 _endingTimestamp) external authorized {
        require(_endingTimestamp >= _startingTimestamp, "_endingTimestamp should be >= _startingTimestamp");
        require(_maxSellFee >= baseSellFee, "_maxFee should be >= baseSellFee");

        maxSellFee = _maxSellFee;
        variableFeeStartingTimestamp = _useCurrentTimestampForStart ? block.timestamp : _startingTimestamp;
        variableFeeEndingTimestamp = _endingTimestamp;
    }

    function setNewBaseFees(uint256 _newBaseSellFee, uint256 _newTransferFee, uint256 _newBaseBuyFee) external authorized {
        require(_newBaseSellFee <= 10000 && _newTransferFee <= 10000 && _newBaseBuyFee <= 10000, "New fees should be less than 100%");
        baseSellFee = _newBaseSellFee;
        transferFee = _newTransferFee;
        baseBuyFee = _newBaseBuyFee;
    }

    function setTransferGateway(ITransferGateway _transferGateway) external authorized {
        transferGateway = _transferGateway;
        _authorize(address(_transferGateway));
    }

    function setAnyflect(IAnyflect _anyflect) external authorized {
        anyflect = _anyflect;
        anyflect.setExcludedFrom(pair, true);
        anyflect.setExcludedTo(pair, true);
        anyflect.setExcludedFrom(address(this), true);
        anyflect.setExcludedFrom(address(0), true);
        anyflect.setExcludedFrom(0x000000000000000000000000000000000000dEaD, true);
        _authorize(address(anyflect));
    }

    function setDexRouter(IDEXRouter _router) external authorized {
        router = _router;
    }

    function setLoyaltyTracker(ILoyaltyTracker _loyaltyTracker) external authorized {
        loyaltyTracker = _loyaltyTracker;
        _authorize(address(_loyaltyTracker));
    }

    function setTxLimit(uint256 _amount) external authorized {
        _maxTxAmount = _amount;
    }

    function setIsFeeExempt(address _addr, bool _exempt) external authorized {
        isFeeExempt[_addr] = _exempt;
    }

    function setIsTxLimitExempt(address _addr, bool _exempt) external authorized {
        isTxLimitExempt[_addr] = _exempt;
    }

    function setLiquidityPair(address _pair, bool _value) external authorized {
        liquidityPairs[_pair] = _value;
    }

    function setSwapThreshold(uint256 _amount) external authorized {

        _swapThreshold = _amount;
    }

    function setAnyflectExempt(address _addr, bool _value) external authorized {
        isAnyflectExempt[_addr] = _value;
    }

    function setPresaleContract(address _addr, bool _value) external authorized {
        isPresale[_addr] = _value;
    }

    function setBasicTransfer(address _addr, bool _value) external authorized {
        isBasicTransfer[_addr] = _value;
    }

    function rescueSquad(address payable _to) external authorized {
        (bool success,) = _to.call{value : address(this).balance}("");
        require(success, "unable to send value, recipient may have reverted");
    }

    // Grabs any shitcoin someone sends to our contract, converts it to rewards for our holders ♥
    function fuckShitcoins(IBEP20 _shitcoin, address[] memory _path, address _to) external authorized {
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _shitcoin.balanceOf(address(this)),
            0,
            _path,
            address(_to),
            block.timestamp
        );
    }

    // * Interface-compliant functions
    receive() external payable {}

    function totalSupply() external view override returns (uint256) {return _totalSupply;}

    function decimals() external pure override returns (uint8) {return _decimals;}

    function symbol() external pure override returns (string memory) {return _symbol;}

    function name() external pure override returns (string memory) {return _name;}

    function getOwner() external view override returns (address) {return owner;}

    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}

    function allowance(address holder, address spender) external view override returns (uint256) {return _allowances[holder][spender];}

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library EarnHubLib {
    struct User {
        address _address;
        uint256 lastPurchase;
        bool isReferral;
        uint256 referralBuyDiscount;
        uint256 referralSellDiscount;
        uint256 referralCount;
    }

    enum TransferType {
        Sale,
        Purchase,
        Transfer
    }

    struct Transfer {
        User user;
        uint256 amt;
        TransferType transferType;
        address from;
        address to;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "../libraries/EarnHubLib.sol";
import "./IGatewayHook.sol";

interface ITransferGateway {
    function removeHookedContract(uint256 _hookedContractId) external;
    function updateHookedContractShares(uint256 _hookedContractId, uint256 _newShares) external;
    function updateHookedContractHandicap(uint256 _hookedContractId, uint256 _newHandicap) external;
    function onTransfer(EarnHubLib.Transfer memory _transfer) external;
    function setBpScale(uint256 _newBpScale) external;
    function setMinGasThreshold(uint256 _newMinGas) external;
    function setMaxGas(uint256 _newMaxGas) external;
    function depositBNB() external payable;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IDEXRouter.sol";
import "./IBEP20.sol";

interface IAnyflect {
    function subscribeToReflection(IDEXRouter router, IBEP20 token) external;
    function excludeFromProcess(bool _val) external;
    function setShares(address from, address to, uint256 fromBalance, uint256 toBalance) external;
    function setExcludedFrom(address from, bool val) external;
    function setExcludedTo(address from, bool val) external;
    function getShareholderShares (address _shareholder) external returns (uint);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ILoyaltyTracker {
    function getReferralData(address _addr) external returns(bool, uint256, uint256, uint256); // * gets all of the data below in a single DELEGATECALL
    function getReferralStatus(address _addr) external returns (bool);
    function getBuyDiscount(address _addr) external returns (uint256);
    function getSellDiscount(address _addr) external returns (uint256);
    function getReferralCount(address _addr) external returns (uint256);
}