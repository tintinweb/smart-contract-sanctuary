// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Router02.sol';
import './Presale.sol';
import './Locker.sol';

// Factory contract to create and manage presales
contract PresaleFactory is Ownable {
    struct PresaleArgs {
        IERC20 token;
        uint256 softcap;
        uint256 hardcap;
        uint256 minContributionAmount;
        uint256 maxContributionAmount;
        uint256 presaleStart;
        uint256 presaleEnd;
        address lpRouter;
        uint256 lpRouterRate;
        uint256 swapRate;
        uint256 unlockAt;
    }

    // TODO: multiple presales per token?
    mapping(IERC20 => Presale) public presalesByToken;
    // TODO: multiple presales per owner?
    mapping(address => Presale) public presalesByOwner;

    // list of presales
    address[] public presales;
    // list of allowed uniswap v2 routers
    mapping(IUniswapV2Router02 => bool) public isAllowedRouter;

    // fee that will be charged for creating presale
    uint256 public creationFee;
    // fee that will be charged after a successful presale in percentage
    uint256 public feeFromETH;
    // fee that will be charged in tokens after a successful presale in percentage
    uint256 public feeFromTokens;

    // TODO: indexing?
    event PresaleCreated(IERC20 indexed token, address owner);
    event PresaleFeeUpdated(uint256 previousFee, uint256 newFee);
    event FeeFromETHUpdated(uint256 previousPercentage, uint256 newPercentage);
    event FeeFromTokensUpdated(uint256 previousPercentage, uint256 newPercentage);
    event IsAllowedRouterUpdated(IUniswapV2Router02 _router, bool _isAllowed);

    constructor(
        uint256 _creationFee,
        uint256 _feeFromETH,
        uint256 _feeFromTokens,
        IUniswapV2Router02[] memory _allowedRouters
    ) {
        creationFee = _creationFee;
        feeFromETH = _feeFromETH;
        feeFromTokens = _feeFromTokens;

        // set initial allowed routers
        for (uint256 i = 0; i < _allowedRouters.length; i++) {
            isAllowedRouter[_allowedRouters[i]] = true;
        }
    }

    // create a presale
    // TODO: transfer the presale token to contract
    function createPresale(PresaleArgs calldata _presale) external payable returns (address) {
        require(msg.value == creationFee, 'INVALID_CREATION_FEE');
        require(address(_presale.token) != address(0), 'TOKEN_IS_ZERO_ADDRESS');
        require(address(presalesByToken[_presale.token]) == address(0), 'PRESALE_EXISTS');
        // check if router is allowed
        require(isAllowedRouter[IUniswapV2Router02(_presale.lpRouter)] == true, 'LP_ROUTER_NOT_ALLOWED');
        // create lp locker
        // TODO: change to LP pair
        Locker locker = new Locker(_presale.token, _presale.unlockAt, msg.sender);

        // create presale
        Presale ps = new Presale(
            _presale.token,
            _presale.softcap,
            _presale.hardcap,
            _presale.minContributionAmount,
            _presale.maxContributionAmount,
            _presale.presaleStart,
            _presale.presaleEnd,
            _presale.lpRouter,
            _presale.lpRouterRate,
            _presale.swapRate,
            address(locker)
        );

        presalesByToken[_presale.token] = ps;
        presalesByOwner[msg.sender] = ps;
        presales.push(address(ps));
        // TODO: calculate amount to send to presale contract
        // TODO: send amount to presale contract
        // TODO: send remaining (fee) to owner?

        emit PresaleCreated(_presale.token, msg.sender);

        return address(ps);
    }

    // update presale creation fee
    function updateCreationFee(uint256 _amount) external onlyOwner {
        uint256 previousCreationFee = creationFee;
        creationFee = _amount;
        emit PresaleFeeUpdated(previousCreationFee, _amount);
    }

    // update presale fee from ETH raised
    function updateFeeFromETH(uint256 _percentage) external onlyOwner {
        uint256 previousFeeFromETH = feeFromETH;
        feeFromETH = _percentage;
        emit FeeFromETHUpdated(previousFeeFromETH, _percentage);
    }

    // update presale fee from tokens
    function updateFeeFromTokens(uint256 _percentage) external onlyOwner {
        uint256 previousFeeFromTokens = feeFromTokens;
        feeFromTokens = _percentage;
        emit FeeFromTokensUpdated(previousFeeFromTokens, _percentage);
    }

    // updates if router is allowed
    function updateIsAllowedRouter(IUniswapV2Router02 _router, bool _isAllowed) external onlyOwner {
        require(isAllowedRouter[_router] != _isAllowed, 'IS_ALLOWED_ROUTER_ALREADY_SET');
        isAllowedRouter[_router] = _isAllowed;

        emit IsAllowedRouterUpdated(_router, _isAllowed);
    }

    function getPresale(uint256 _index) external view returns (address presale) {
        return presales[_index];
    }

    function allPresalesLength() external view returns (uint256) {
        return presales.length;
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Presale is Ownable {
    // the token that is being offered for presale
    IERC20 public immutable token;
    // softcap of the presale
    uint256 public immutable softcap;
    // hardcap of the presale
    uint256 public immutable hardcap;

    uint256 public immutable minContributionAmount;
    uint256 public immutable maxContributionAmount;

    // presale start timestamp
    uint256 public immutable presaleStart;
    // presale end timestamp
    uint256 public immutable presaleEnd;

    // router that will be used to put the lp
    address public immutable lpRouter;

    // percentage of funds raised that will go to lp
    uint256 public immutable lpRouterRate;

    // rate at which the token will be sold on DEX
    uint256 public immutable swapRate;

    // where the locker is located
    address public immutable locker;

    mapping(address => uint256) public depositByAddr;

    // total contribution amount at the moment
    uint256 public totalContribution;

    event Deposited(address addr, uint256 amount);
    event Claimed(address addr, uint256 amount);

    constructor(
        IERC20 _token,
        uint256 _softcap,
        uint256 _hardcap,
        uint256 _minContributionAmount,
        uint256 _maxContributionAmount,
        uint256 _presaleStart,
        uint256 _presaleEnd,
        address _lpRouter,
        uint256 _lpRouterRate,
        uint256 _swapRate,
        address _locker
    ) {
        require(address(_token) != address(0), 'TOKEN_IS_ZERO_ADDRESS');
        // TODO: require token to be ERC20
        require(_softcap > 0, 'SOFTCAP_IS_ZERO');
        require(_hardcap > 0, 'HARDCAP_IS_ZERO');
        require(_hardcap > _softcap, 'HARDCAP_IS_LOWER_THAN_SOFTCAP');
        require(_minContributionAmount > 0, 'MIN_CONTRIBUTION_IS_ZERO');
        require(_maxContributionAmount > 0, 'MAX_CONTRIBUTION_IS_ZERO');
        require(_maxContributionAmount > _minContributionAmount, 'MAX_CONTRIBUTION_IS_LOWER_THAN_MIN_CONTRIBUTION');
        require(_presaleStart > block.timestamp, 'INVALID_PRESALE_START');
        require(_presaleEnd > block.timestamp, 'INVALID_PRESALE_END');
        require(_presaleEnd > _presaleStart, 'PRESALE_END_BEFORE_START');
        require(_lpRouter != address(0), 'LP_ROUTER_IS_ZERO_ADDRESS');
        // TODO: lp router must be uniswap interface
        require(_lpRouterRate > 0, 'lp router rate cannot be zero');
        require(_lpRouterRate < 100, 'lp router rate must be less than 100');
        // TODO: create lpRouter requirement and add validation

        require(_swapRate > 0, 'swapRate cannot be zero');
        // TODO: validate swap rate

        require(_token.balanceOf(address(this)) == calculateRequiredTokenAmount(), 'INSUFFICIENT_TOKENS_FOR_PRESALE');
        token = _token;
        softcap = _softcap;
        hardcap = _hardcap;
        minContributionAmount = _minContributionAmount;
        maxContributionAmount = _maxContributionAmount;
        presaleStart = _presaleStart;
        presaleEnd = _presaleEnd;
        lpRouter = _lpRouter;
        lpRouterRate = _lpRouterRate;
        swapRate = _swapRate;
        locker = _locker;
    }

    // deposit BNB to participate in the presale
    function deposit() external payable {
        require(block.timestamp > presaleStart, 'PRESALE_NOT_STARTED');
        require(block.timestamp < presaleEnd, 'PRESALE_ALREADY_ENDED');
        require(msg.value >= minContributionAmount, 'CONTRIBUTION_AMOUNT_TOO_LOW');
        require(depositByAddr[msg.sender] + msg.value <= maxContributionAmount, 'CONTRIBUTION_AMOUNT_TOO_HIGH');
        require(totalContribution + msg.value < hardcap, 'CONTRIBUTION_OVER_HARDCAP');

        depositByAddr[msg.sender] += msg.value;
        totalContribution += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    // finalizes the presale
    function finalize() external onlyOwner {
        // validate the presale has hit at least softcap
        require(totalContribution >= softcap, 'SOFTCAP_NOT_REACHED');
        // if hardcap has not been reached, validate presale has ended.

        if (totalContribution <= hardcap - minContributionAmount) {
            require(block.timestamp > presaleEnd, 'PRESALE_NOT_ENDED');
        }

        // TODO: set presale status to FINALIZED
        // TODO: convert % of the presale to LP
        // TODO: send LP to locker
        // TODO: calculate BNB fee and transfer to xxx
        // TODO: send remaining BNB to presale creator (NOT OWNER)
        // TODO: emit event
    }

    // claim function to claim tokens after presale time ends
    function claim() external {
        require(depositByAddr[msg.sender] > 0, 'NO_TOKENS_TO_CLAIM');
        uint256 depositedAmount = depositByAddr[msg.sender];

        // TODO: calculate the amount that will be sent
        // TODO: transfer the tokens to msg.sender
        emit Claimed(msg.sender, depositedAmount);
    }

    function calculateRequiredTokenAmount() public view returns (uint256) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Locker is Ownable {
    // the token that is being locked
    IERC20 public immutable token;

    uint256 public immutable unlockAt;
    address public immutable receiver;

    constructor(
        IERC20 _token,
        uint256 _unlockAt,
        address _receiver
    ) {
        require(address(_token) != address(0), 'TOKEN_ZERO_ADDRESS');
        require(_receiver != address(0), 'RECEIVER_ZERO_ADDRESS');
        require(_unlockAt > block.timestamp, 'UNLOCK_AT_BEFORE_NOW');
        token = _token;
        receiver = _receiver;
        unlockAt = _unlockAt;
    }

    function unlock() public {
        require(block.timestamp > unlockAt, 'NOT_UNLOCKED_YET');
        token.transfer(receiver, token.balanceOf(address(this)));
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
        return msg.data;
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

