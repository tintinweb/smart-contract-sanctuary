// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ref/UniswapRouter.sol";
import "./ref/ITokenVesting.sol";

contract LockedTokenSale is Ownable {

    ITokenVesting public tokenVesting;
    IUniswapV2Router01 public router;
    AggregatorInterface public ref;
    address public token;

    uint constant plan1_price_limit = 97 * 1e16; // ie18
    uint constant plan2_price_limit = 87 * 1e16; // ie18

    uint[] lockedTokenPrice;

    uint public referral_ratio = 1e7; //1e8

    uint public eth_collected;

    struct AccountantInfo {
        address accountant;
        address withdrawal_address;
    }

    AccountantInfo[] accountantInfo;
    mapping(address => address) withdrawalAddress;

    uint min_withdrawal_amount;

    event Set_Accountant(AccountantInfo[] info);
    event Set_Min_Withdrawal_Amount(uint amount);
    event Set_Referral_Ratio(uint ratio);

    modifier onlyAccountant() {
        address withdraw_address = withdrawalAddress[msg.sender];
        require(withdraw_address != address(0x0), "Only Accountant can perform this operation");
        _;
    }

    constructor(address _router, address _tokenVesting, address _ref, address _token) {
        router = IUniswapV2Router01(_router); // 0x9ac64cc6e4415144c455bd8e4837fea55603e5c3
        tokenVesting = ITokenVesting(_tokenVesting); // 0x63570e161Cb15Bb1A0a392c768D77096Bb6fF88C 0xDB83E3dDB0Fa0cA26e7D8730EE2EbBCB3438527E
        ref = AggregatorInterface(_ref); // 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526 bscTestnet
        token = _token; //0x5Ca372019D65f49cBe7cfaad0bAA451DF613ab96
        lockedTokenPrice.push(0);
        lockedTokenPrice.push(plan1_price_limit); // plan1
        lockedTokenPrice.push(plan2_price_limit); // plan2
        IERC20(_token).approve(_tokenVesting, 1e25);
    }

    function balanceOfToken() public view returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }

    function getUnlockedTokenPrice() public view returns (uint) {
        address pair = IUniswapV2Factory(router.factory()).getPair(token, router.WETH());
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pair).getReserves();
        uint pancake_price;
        if( IUniswapV2Pair(pair).token0() == token ){
            pancake_price = reserve1 * (10 ** IERC20(token).decimals()) / reserve0;
        }
        else {
            pancake_price = reserve0 * (10 ** IERC20(token).decimals()) / reserve1;
        }
        return pancake_price;
    }

    function setLockedTokenPrice(uint plan, uint price) public onlyOwner{
        if(plan == 1)
            require(plan1_price_limit <= price, "Price should not below the limit");
        if(plan == 2)
            require(plan2_price_limit <= price, "Price should not below the limit");
        lockedTokenPrice[plan] = price;
    }

    function getLockedTokenPrice(uint plan) public view returns (uint){
        return lockedTokenPrice[plan] * 1e8 / ref.latestAnswer();
    }

    function buyLockedTokens(uint plan, uint amount, address referrer) public payable{

        require(amount > 0, "You should buy at least 1 locked token");

        uint price = getLockedTokenPrice(plan);
        
        uint amount_eth = amount * price;
        uint referral_value = amount_eth * referral_ratio / 1e8;

        require(amount_eth <= msg.value, 'EXCESSIVE_INPUT_AMOUNT');
        if(referrer != address(0x0) && referrer != msg.sender) {
            payable(referrer).transfer(referral_value);
        }
        
        require(amount <= IERC20(token).balanceOf(address(this)), "Insufficient fund");
        uint256 lockdays;
        if(plan == 1)
        {
            lockdays = 465;
        } else {
            lockdays = 730;
        }
        uint256 endEmission = block.timestamp + 60 * 60 * 24 * lockdays;
        ITokenVesting.LockParams[] memory lockParams = new ITokenVesting.LockParams[](1);
        ITokenVesting.LockParams memory lockParam;
        lockParam.owner = payable(msg.sender);
        lockParam.amount = amount;
        lockParam.startEmission = 0;
        lockParam.endEmission = endEmission;
        lockParam.condition = address(0);
        lockParams[0] = lockParam;

        tokenVesting.lock(token, lockParams);

        if(amount_eth < msg.value) {
            payable(msg.sender).transfer(msg.value - amount_eth);
        }

        eth_collected += amount_eth;
    }

    function setReferralRatio(uint ratio) external onlyOwner {
        require(ratio >= 1e7 && ratio <= 5e7, "Referral ratio should be 10% ~ 50%");
        referral_ratio = ratio;
        emit Set_Referral_Ratio(ratio);
    }

    function setMinWithdrawalAmount(uint amount) external onlyOwner {
        min_withdrawal_amount = amount;
        emit Set_Min_Withdrawal_Amount(amount);
    }

    function withdrawToken(uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    function withdraw(uint256 amount) external onlyAccountant {
        require(amount >= min_withdrawal_amount, "Below minimum withdrawal amount");
        payable(withdrawalAddress[msg.sender]).transfer(amount);
    }

    function setAccountant(AccountantInfo[] calldata _accountantInfo) external onlyOwner {
        uint length = accountantInfo.length;
        for(uint i; i < length; i++) {
            withdrawalAddress[accountantInfo[i].accountant] = address(0x0);
        }
        delete accountantInfo;
        length = _accountantInfo.length;
        for(uint i; i < length; i++) {
            accountantInfo.push(_accountantInfo[i]);
            withdrawalAddress[_accountantInfo[i].accountant] = _accountantInfo[i].withdrawal_address;
        }
        emit Set_Accountant(_accountantInfo);
    }
}

interface AggregatorInterface{
    function latestAnswer() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT


pragma solidity 0.8.9;

interface IUniswapV2Factory {
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

interface IUniswapV2Pair {
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

interface IUniswapV2Router01 {
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

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ITokenVesting {

   struct LockParams {
        address payable owner; // the user who can withdraw tokens once the lock expires.
        uint256 amount; // amount of tokens to lock
        uint256 startEmission; // 0 if lock type 1, else a unix timestamp
        uint256 endEmission; // the unlock date as a unix timestamp (in seconds)
        address condition; // address(0) = no condition, otherwise the condition must implement IUnlockCondition
    }
  /**
   * @notice Creates one or multiple locks for the specified token
   * @param _token the erc20 token address
   * @param _lock_params an array of locks with format: [LockParams[owner, amount, startEmission, endEmission, condition]]
   * owner: user or contract who can withdraw the tokens
   * amount: must be >= 100 units
   * startEmission = 0 : LockType 1
   * startEmission != 0 : LockType 2 (linear scaling lock)
   * use address(0) for no premature unlocking condition
   * Fails if startEmission is not less than EndEmission
   * Fails is amount < 100
   */
  function lock (address _token, LockParams[] calldata _lock_params) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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