/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%###%%%%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#((///(((###%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#((//*******//((###%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##(//**************//(((##%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#((//*********************//((###%%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##(///***************************//(((##%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#((//***********************************//((###%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##((//*****************************************//(((##%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#((//************************************************///((###%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@%#((//*******************************************************//(((##%%%@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@##(//**************************************************************///((###%%@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@&#((//*********************************************************************//(((##%%%@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@##(///***************************************************************************///((###%%@@@@@@@@@@@@@@
//@@@@@@@@@@@@##(//***********************************************************************************//((###%%&@@@@@@@@@@
//@@@@@@@@&%#((/*****************************************************************************************///((##%%%@@@@@@@
//@@@@@@&%%#(//**@@@@@@@@@@@********#@@@@@@@@@@@******************@@@@@@@@@@@@@@@@@@@@@@@@@@/****************//(##%%&@@@@@
//@@@@@@&%%#(//**@@@@@@@@@@@#*******@@@@@@@@@@@@******************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#************/((#%%@@@@@
//@@@@@@&%%##(//******@@@@****************@@@(**********************@@@@*******@@@@*************@@@@@@*********//(#%%@@@@@
//@@@@@@@&%%##(/*******@@@@****************@@@#********************@@@@********@@@@****************@@@@@*******/(##%@@@@@@
//@@@@@@@@&%%#((/*******@@@@****************@@@&******************@@@@*********@@@@******************@@@@*****//(#%@@@@@@@
//@@@@@@@@@&%%#((/*******@@@@****************@@@@****************@@@@**********@@@@*******************@@@@***//(#%@@@@@@@@
//@@@@@@@@@@%%##(//*******@@@@**************@@@@@@**************@@@@***********@@@@********************@@@@**/(#%%@@@@@@@@
//@@@@@@@@@@&%%##(//*******@@@@************@@@@@@@@************@@@@************@@@@********************%@@@*/(#%%@@@@@@@@@
//@@@@@@@@@@@&%%##(//*******@@@@**********@@@@**@@@@**********@@@&*************@@@@********************%@@@/(##%@@@@@@@@@@
//@@@@@@@@@@@@&%%#((/********%@@@********@@@@****@@@@********@@@%**************@@@@********************@@@@((#%@@@@@@@@@@@
//@@@@@@@@@@@@@&%%#((/********#@@@******@@@@******@@@@******@@@(***************@@@@*******************@@@@/(#%@@@@@@@@@@@@
//@@@@@@@@@@@@@@%%##((/********/@@@****@@@@********@@@@***/@@@*****************@@@@******************@@@@/(#%&@@@@@@@@@@@@
//@@@@@@@@@@@@@@&%%##(//*********@@@(*@@@@**********@@@@*(@@@******************@@@@****************@@@@&/(#%%@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@&%%##(//*********@@@@@@@************@@@@@@@*******************@@@@************@@@@@@**/(##%@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@&%%##(//*********@@@@&,,******,,,,**@@@@&,,,,****,,,,,,,**@@@@@@@&@@@@@@&&&@@@@@****/(##%@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@&%%#((/********,,(&@@@@@,...#@@@@@,./@@@@@@@*..,@@@@@@/,,#@@&#@@@@@((#@@@@@(,,,***/((#%@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

/**
Project:   @ A U T O M O B I L I A @
Telegram: https://t.me/AutomobiliaCoin
*/
//SPDX-License-Identifier: UNLICENSED

        /* FLATTENED IMPORTED CONTRACTS ***/
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


            // File contracts/Ownable.sol

            pragma solidity ^0.8.0;

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


            // File contracts/IERC20.sol

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


            // File contracts/IUniswapV2Router01.sol

            pragma solidity >=0.6.2;

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


            // File contracts/IUniswapV2Router02.sol

            pragma solidity >=0.6.2;

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


            // File contracts/IUniswapV2Factory.sol

            pragma solidity >=0.5.0;

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


            // File contracts/Address.sol

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
                    assembly {
                        size := extcodesize(account)
                    }
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

                    (bool success, ) = recipient.call{value: amount}("");
                    require(success, "Address: unable to send value, recipient may have reverted");
                }

                /**
                * @dev Performs a Solidity function call using a low level `call`. A
                * plain `call` is an unsafe replacement for a function call: use this
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
                function functionCall(
                    address target,
                    bytes memory data,
                    string memory errorMessage
                ) internal returns (bytes memory) {
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
                function functionCallWithValue(
                    address target,
                    bytes memory data,
                    uint256 value
                ) internal returns (bytes memory) {
                    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
                }

                /**
                * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
                * with `errorMessage` as a fallback revert reason when `target` reverts.
                *
                * _Available since v3.1._
                */
                function functionCallWithValue(
                    address target,
                    bytes memory data,
                    uint256 value,
                    string memory errorMessage
                ) internal returns (bytes memory) {
                    require(address(this).balance >= value, "Address: insufficient balance for call");
                    require(isContract(target), "Address: call to non-contract");

                    (bool success, bytes memory returndata) = target.call{value: value}(data);
                    return verifyCallResult(success, returndata, errorMessage);
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
                function functionStaticCall(
                    address target,
                    bytes memory data,
                    string memory errorMessage
                ) internal view returns (bytes memory) {
                    require(isContract(target), "Address: static call to non-contract");

                    (bool success, bytes memory returndata) = target.staticcall(data);
                    return verifyCallResult(success, returndata, errorMessage);
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
                function functionDelegateCall(
                    address target,
                    bytes memory data,
                    string memory errorMessage
                ) internal returns (bytes memory) {
                    require(isContract(target), "Address: delegate call to non-contract");

                    (bool success, bytes memory returndata) = target.delegatecall(data);
                    return verifyCallResult(success, returndata, errorMessage);
                }

                /**
                * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
                * revert reason using the provided one.
                *
                * _Available since v4.3._
                */
                function verifyCallResult(
                    bool success,
                    bytes memory returndata,
                    string memory errorMessage
                ) internal pure returns (bytes memory) {
                    if (success) {
                        return returndata;
                    } else {
                        // Look for revert reason and bubble it up if present
                        if (returndata.length > 0) {
                            // The easiest way to bubble the revert reason is using memory via assembly

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
        /* FLATTENED IMPORTED CONTRACTS ***/


pragma solidity ^0.8.11;
/*
    This contract is costum built for AUTOMOBILIA
    Contract copyright by WoDeep2022 ..  
    For special contracts, send me an enquiry
    https://form.jotform.com/220014798769062
*/
contract Automobilia is Context, IERC20, Ownable {
/** Variables and Parameters */    
    using Address for address payable;
    address base_address = 0xdB29C14a4e8eB56A1C7a15DC541c7f67998D3CaD;
    address marketing_address = 0x9fB72551B49e45025500b437A93094C62384d0b2;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
     /* Maps */
    mapping (address => uint256) private _rOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) public canAddLiquidityBeforeLaunch;
    mapping (address => bool) public isTxLimitExempt;
    mapping(address => uint256) private _tOwned;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isExcludedFromMaxWallet;
    mapping(address => bool) public isBot;

    address[] private _excluded;
    address payable  BaseAddress= payable(base_address);

    /* Naming */
    string private _name = "Automobilia";  //CONTRACT VERSION 2
    string private _symbol = "OAC";

    /* Decimal handling */
    uint8 private _decimals = 9;
    uint256 private _decimalFactor = 10**_decimals;
    
    /* Total supply, total reflected supply and total fees taken */
    uint256 private constant MAX = ~uint256(0); // Maximum uint256
    //100Billion. 100.000.000.000
    uint256 private _tTotal = 10**11 * _decimalFactor; // Tokens total
    uint256 private _rTotal = MAX - (MAX % _tTotal); // Reflections total
    uint256 private _tFeeTotal; // Token Fee Total (total fees gathered)
    /* Transaction restrictions */
    uint256 public maxTxAmountBuy = _tTotal / 100; // 1% of supply
    uint256 public maxTxAmountSell = _tTotal / 200; // 0.5% of supply
    uint256 public maxWalletAmount = _tTotal / 50; // 2% of supply

    //antisnipers
    uint256 public BlockNumberAtAddedLiq;
    uint256 private BlockDelayB4Trading = 0;
    //antiBot
    uint256 public launchedAt = 0;

    //contract and fee handling
    bool public tradingOpen = false;
    bool public autoLimits = false;
    bool public _takeFee = true;
    bool public FeeDistrType = true;
    uint256 public FeesSent = 0;

    /* Statistics */
     struct StatisticsStruct {
    uint256 liqCtr;
    uint256 liqTot;
    uint256 liqPerc;
    uint256 totalTx;}

        StatisticsStruct public statistics =
            StatisticsStruct({
                liqCtr: 0, 
                liqTot: 0,
                liqPerc: 0, 
                totalTx: 0
            });

    // define Marketing Address
    address payable public MarketingAddress;

    mapping(address => bool) public isAutomatedMarketMakerPair;

    // parameter to indicate SwapAndLiquify status
    bool private inSwapAndLiquify;

    //cretate Router Object
    IUniswapV2Router02 public UniswapV2Router;
    address public uniswapV2Pair;
    bool public swapAndLiquifyEna = true;
    //define number of sold tokens to be added to liq
    uint256 public numTokensSellToAddToLiquidity = _tTotal / 2000;  //0.05%

    /** FFES */
        //Struct to summarize the fees
        struct feeRatesStruct {
            uint8 reflection;
            uint8 marketing;
            uint8 base;
            uint8 lp;
            uint8 toSwap;
        }


        feeRatesStruct public buyRates =
            feeRatesStruct({
                reflection: 2, // 0 reflection rate, in %
                base: 1, // base fee in %
                marketing: 3, // marketing fee in %
                lp: 3, // lp rate in %
                toSwap: 9 // marketing + base + lp
            });

        feeRatesStruct public sellRates =
            feeRatesStruct({
                reflection: 2, // 0 reflection rate, in %
                base: 1, // base fee in %
                marketing: 3, // marketing fee in %
                lp: 3, // lp rate in %
                toSwap: 9 // marketing + base + lp
            });

        feeRatesStruct private appliedRates = buyRates;

        struct TotFeesPaidStruct {
            uint256 reflection;
            uint256 toSwap;
        }
        TotFeesPaidStruct public totFeesPaid;
    /* FEES **/

    //declare Get values variables
    struct valuesFromGetValues {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rReflection;
        uint256 rToSwap;
        uint256 tTransferAmount;
        uint256 tReflection;
        uint256 tToSwap;
    }
/* Variables and Parameters **/   

/** EVENT TRIGGERS */
    event swapAndLiquifyEnaUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ETHReceived,
        uint256 tokensIntotoSwap
    );
    event LiquidityAdded(uint256 tokenAmount, uint256 ETHAmount);
    event MarketingAndBaseFeesAdded(uint256 baseFee, uint256 marketingFee);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event BlacklistedUser(address botAddress, bool indexed value);
    event MaxWalletAmountUpdated(uint256 amount);
    event ExcludeFromMaxWallet(address account, bool indexed isExcluded);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
/* EVENT TRIGGERS **/

/** CONSTRUCTOR */
    constructor() {
        definePCSrouter(1);
        _rOwned[owner()] = _rTotal;
        MarketingAddress = payable(marketing_address);
        //Define what address is excluded from limitations
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[MarketingAddress] = true;
        _isExcludedFromFee[BaseAddress] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromMaxWallet[owner()] = true;
        _isExcludedFromMaxWallet[MarketingAddress] = true;
        _isExcludedFromMaxWallet[BaseAddress] = true;
        _isExcludedFromMaxWallet[address(this)] = true;
        _isExcludedFromMaxWallet[uniswapV2Pair] = true;
        emit Transfer(address(0), owner(), _tTotal);
    }

        function definePCSrouter(uint8 ChoosePair) public onlyOwner {
            IUniswapV2Router02 _uniswapV2Router; // add the Object
            // Choose different Network            
            if(ChoosePair==1){ _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);} // MAINNET}
            if(ChoosePair==2){ _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);} // TestNet Old}
            if(ChoosePair==3){ _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);} // TestNet PCS kiemtienonline}
            
            // Create a uniswap pair for this new token
            uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this), _uniswapV2Router.WETH());
            isAutomatedMarketMakerPair[uniswapV2Pair] = true;
            emit SetAutomatedMarketMakerPair(uniswapV2Pair, true);

            // Set router contract variable
            UniswapV2Router = _uniswapV2Router;

        }
/* CONSTRUCTOR **/

/** AUTO LIMITS */
    function checkTxLimit() internal{ 
            uint256 time_since_start = block.timestamp - launchedAt; 
            
        if (time_since_start < 4 minutes ) {
                    maxTxAmountBuy = _tTotal / (100) * (3); 
                    maxWalletAmount = _tTotal / (100) * (5);
                } 
                
        if (time_since_start < 2 minutes ) { 
                    maxTxAmountBuy = _tTotal / (1000) * (3); 
                    maxWalletAmount = _tTotal / (1000) * (5);
                } 
                
        if (time_since_start < 1 minutes ) { 
                    maxTxAmountBuy = _tTotal / (10000) * (3); 
                    maxWalletAmount = _tTotal / (10000) * (5); 
                } 
        else { 
                    maxTxAmountBuy = _tTotal / (100) * (3); 
                    maxWalletAmount = _tTotal / (100) * (5); 
                } 
    }
/* AUTO LIMITS **/

/** Get Values and Rates handling */
   
    //  @base receive ETH from UniswapV2Router when swapping
    receive() external payable {}

    function _reflectReflection(uint256 rReflection, uint256 tReflection) private {
        _rTotal -= rReflection;
        totFeesPaid.reflection += tReflection;
    }

    function _takeToSwap(uint256 rToSwap, uint256 tToSwap) private {
        _rOwned[address(this)] += rToSwap;
        if (_isExcluded[address(this)]) _tOwned[address(this)] += tToSwap;
        totFeesPaid.toSwap += tToSwap;
    }

    function _getValues(uint256 tAmount, bool takeFee)
        private
        view
        returns (valuesFromGetValues memory to_return)
    {
        to_return = _getTValues(tAmount, takeFee);
        (
            to_return.rAmount,
            to_return.rTransferAmount,
            to_return.rReflection,
            to_return.rToSwap
        ) = _getRValues(to_return, tAmount, takeFee, _getRate());
        return to_return;
    }

    function _getTValues(uint256 tAmount, bool takeFee)
        private
        view
        returns (valuesFromGetValues memory s)
    {
        if (!takeFee) {
            s.tTransferAmount = tAmount;
            return s;
        }
        s.tReflection = (tAmount * appliedRates.reflection) / 100;
        s.tToSwap = (tAmount * appliedRates.toSwap) / 100;
        s.tTransferAmount = tAmount - s.tReflection - s.tToSwap;
        return s;
    }

    function _getRValues(
        valuesFromGetValues memory s,
        uint256 tAmount,
        bool takeFee,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rReflection,
            uint256 rToSwap
        )
    {
        rAmount = tAmount * currentRate;

        if (!takeFee) {
            return (rAmount, rAmount, 0, 0);
        }

        rReflection = s.tReflection * currentRate;
        rToSwap = s.tToSwap * currentRate;
        rTransferAmount = rAmount - rReflection - rToSwap;
        return (rAmount, rTransferAmount, rReflection, rToSwap);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply -= _rOwned[_excluded[i]];
            tSupply -= _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
/* Get Values and Rates handling **/

/** APPROVE Function */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
/* APPROVE Function **/

/** MAIN TRANSFER FUNCTION */

        /*** TRANSFER DECISION */
            function _transfer(
                address from,
                address to,
                uint256 amount
            ) private {
                if (BlockNumberAtAddedLiq == 0 && isAutomatedMarketMakerPair[to]) {
                    BlockNumberAtAddedLiq = block.number;
                }

                require(from != address(0), "ERC20: transfer from the zero address");
                require(to != address(0), "ERC20: transfer to the zero address");
                require(!isBot[from], "ERC20: address blacklisted (bot)");
                require(amount > 0, "Transfer amount must be greater than zero");
                require(
                    amount <= balanceOf(from),
                    "You are trying to transfer more than your balance"
                );
                //set Take Fee
                bool takeFee = true;
                // Do not take fee if the sender should be excluded
                if (_isExcludedFromFee[from]|| _isExcludedFromFee[to]) {
                    takeFee = false;
                }

                // Don't take any fees if marketing address isn't set.
                if (MarketingAddress == address(0)) {
                    takeFee = false;
                }

                _takeFee = takeFee;
                if (takeFee) {
                    if (isAutomatedMarketMakerPair[from]) {
                        if (block.number < BlockNumberAtAddedLiq + BlockDelayB4Trading) {
                            isBot[to] = true;
                            emit BlacklistedUser(to, true);
                        }

                        appliedRates = buyRates;
                        require(
                            amount <= maxTxAmountBuy,
                            "amount must be <= maxTxAmountBuy"
                        );
                    } else {
                        appliedRates = sellRates;
                        require(
                            amount <= maxTxAmountSell,
                            "amount must be <= maxTxAmountSell"
                        );
                    }
                }

                //at launch, add auto limits to prevent Bots and large whales
                if(autoLimits){ checkTxLimit();}
                // Avoid airdropped from ADD LP before launch     
                if(!tradingOpen && to == uniswapV2Pair && from == uniswapV2Pair)
                    require(canAddLiquidityBeforeLaunch[from]);


 //SWAP AND LIQUIFY AT BUY 
                if (
                    balanceOf(address(this)) >= numTokensSellToAddToLiquidity &&
                    !inSwapAndLiquify &&
                    isAutomatedMarketMakerPair[from] &&
                    swapAndLiquifyEna
                ) {
                    //add liquidity
                    swapAndLiquify(numTokensSellToAddToLiquidity);
                }

                //SWAP AND LIQUIFY AT SELL
                if (
                    balanceOf(address(this)) >= numTokensSellToAddToLiquidity &&
                    !inSwapAndLiquify &&
                    !isAutomatedMarketMakerPair[from] &&
                    swapAndLiquifyEna
                ) {
                    //add liquidity
                    swapAndLiquify(balanceOf(address(this)));
                }

                _tokenTransfer(from, to, amount, takeFee);
            }
        /* TRANSFER DECISION ***/

        /*** TRANSFER */
            //this method is responsible for taking all fee, if takeFee is true
            function _tokenTransfer(
            address sender,
            address recipient,
            uint256 tAmount,
            bool takeFee
            ) private {
                valuesFromGetValues memory s = _getValues(tAmount, takeFee);

                if (_isExcluded[sender]) {
                    _tOwned[sender] -= tAmount;
                }
                if (_isExcluded[recipient]) {
                    _tOwned[recipient] += s.tTransferAmount;
                }

                _rOwned[sender] -= s.rAmount;
                _rOwned[recipient] += s.rTransferAmount;
                //If FeeDisp Type is false, fees will be distributed as tokens otherwise as ETH
                if (takeFee && FeeDistrType) {
                    _reflectReflection(s.rReflection, s.tReflection);
                    _takeToSwap(s.rToSwap, s.tToSwap);
                    emit Transfer(sender, address(this), s.tToSwap);
                    FeesSent = s.tToSwap;
                }
                require(
                    _isExcludedFromMaxWallet[recipient] ||
                        balanceOf(recipient) <= maxWalletAmount,
                    "Recipient cannot hold more than maxWalletAmount"
                );
                if (takeFee && !FeeDistrType) {
                    _reflectReflection(s.rReflection, s.tReflection);
                    _takeToSwap(s.rToSwap, s.tToSwap);
                    emit Transfer(sender, BaseAddress, (s.tToSwap));
                    FeesSent = s.tToSwap;
                }
                require(
                    _isExcludedFromMaxWallet[recipient] ||
                        balanceOf(recipient) <= maxWalletAmount,
                    "Recipient cannot hold more than maxWalletAmount"
                );
                emit Transfer(sender, recipient, s.tTransferAmount);
                statistics.totalTx = statistics.totalTx + 1;
            }
        /* TRANSFER ***/

/* MAIN TRANSFER FUNCTION **/


/** SUPPORTING TRANSFER FUNCTIONS */

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 denominator = appliedRates.toSwap * 2;
        uint256 tokensToAddLiquidityWith = (contractTokenBalance *
            appliedRates.lp) / denominator;
        uint256 toSwap = contractTokenBalance - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForETH(toSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 ETHToAddLiquidityWith = (deltaBalance * appliedRates.lp) /
            (denominator - appliedRates.lp);

        // add liquidity
        addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith);

        // we give the remaining tax to base & marketing wallets
        uint256 remainingBalance = address(this).balance;
        uint256 baseFee = (remainingBalance * appliedRates.base) /
            (denominator - appliedRates.base);
        uint256 marketingFee = (remainingBalance * appliedRates.marketing) /
            (denominator - appliedRates.marketing);
        BaseAddress.sendValue(baseFee);
        MarketingAddress.sendValue(marketingFee);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the pair path of token
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniswapV2Router.WETH();

        if (allowance(address(this), address(UniswapV2Router)) < tokenAmount) {
            _approve(address(this), address(UniswapV2Router), ~uint256(0));
        }

        // make the swap
        UniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        // add the liquidity
        statistics.liqTot=statistics.liqTot+ETHAmount;
        statistics.liqCtr = statistics.liqCtr+1;
        UniswapV2Router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            BaseAddress,
            block.timestamp
        );
        emit LiquidityAdded(tokenAmount, ETHAmount);
    }
/* SUPPORTING TRANSFER FUNCTIONS **/


/** SETTERS. */

    /**Contract and wallet handling*/


        function transfer(address recipient, uint256 amount)
            public
            override
            returns (bool)
        {
            _transfer(_msgSender(), recipient, amount);
            return true;
        }

        function allowance(address owner, address spender)
            public
            view
            override
            returns (uint256)
        {
            return _allowances[owner][spender];
        }

        function approve(address spender, uint256 amount)
            public
            override
            returns (bool)
        {
            _approve(_msgSender(), spender, amount);
            return true;
        }

        function transferFrom(
            address sender,
            address recipient,
            uint256 amount
        ) public override returns (bool) {
            _transfer(sender, recipient, amount);

            uint256 currentAllowance = _allowances[sender][_msgSender()];
            require(
                currentAllowance >= amount,
                "ERC20: transfer amount exceeds allowance"
            );
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }

            return true;
        }

        function increaseAllowance(address spender, uint256 addedValue)
            public
            virtual
            returns (bool)
        {
            _approve(
                _msgSender(),
                spender,
                _allowances[_msgSender()][spender] + addedValue
            );
            return true;
        }

        function decreaseAllowance(address spender, uint256 subtractedValue)
            public
            virtual
            returns (bool)
        {
            uint256 currentAllowance = _allowances[_msgSender()][spender];
            require(
                currentAllowance >= subtractedValue,
                "ERC20: decreased allowance below zero"
            );
            unchecked {
                _approve(_msgSender(), spender, currentAllowance - subtractedValue);
            }

            return true;
        }


        // this function determines the reflection amount from token
        function reflectionFromToken(uint256 tAmount, bool deductTransferReflection)
            public
            view
            returns (uint256)
        {
            require(tAmount <= _tTotal, "Amount must be less than supply");
            if (!deductTransferReflection) {
                valuesFromGetValues memory s = _getValues(tAmount, true);
                return s.rAmount;
            } else {
                valuesFromGetValues memory s = _getValues(tAmount, true);
                return s.rTransferAmount;
            }
        }

        // this function determines the amount of tokens from the reflection
        function tokenFromReflection(uint256 rAmount)
            public
            view
            returns (uint256)
        {
            require(
                rAmount <= _rTotal,
                "Amount must be less than total reflections"
            );
            uint256 currentRate = _getRate();
            return rAmount / currentRate;
        }

        



        function excludeMultipleAccountsFromMaxWallet(
            address[] calldata accounts,
            bool excluded
        ) public onlyOwner {
            for (uint256 i = 0; i < accounts.length; i++) {
                require(
                    _isExcludedFromMaxWallet[accounts[i]] != excluded,
                    "_isExcludedFromMaxWallet already set to that value for one wallet"
                );
                _isExcludedFromMaxWallet[accounts[i]] = excluded;
                emit ExcludeFromMaxWallet(accounts[i], excluded);
            }
        }


    /* Contract and wallet handling **/


    //activate / deactivate swapandliquify
     function setswapAndLiquifyEna(bool _enabled) public onlyOwner {
        swapAndLiquifyEna = _enabled;
        emit swapAndLiquifyEnaUpdated(_enabled);
    }

    //exclude from fee
    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    //include in fee
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    //No current reflection - Tiered Rewarding Feature Applied at APP Launch
    function excludeFromReward(address account) external onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }


    function setAutomatedMarketMakerPair(address _pair, bool value)
        external
        onlyOwner
    {
        require(
            isAutomatedMarketMakerPair[_pair] != value,
            "Automated market maker pair is already set to that value"
        );
        isAutomatedMarketMakerPair[_pair] = value;
        if (value) {
            _isExcludedFromMaxWallet[_pair] = true;
            emit ExcludeFromMaxWallet(_pair, value);
        }
        emit SetAutomatedMarketMakerPair(_pair, value);
    }

    function setBuyFees(
        uint8 _reflection,
        uint8 _marketing,
        uint8 _base,
        uint8 _lp
    ) external onlyOwner {
        // MAke sure, OWNERS cannot scam the holders by changing the fees too high!!
        if(_base<1){_base = 2;}
        if(_reflection>5){_reflection = 5;}
        if(_marketing>7){_marketing = 7;}
        if(_lp>10){_lp = 10;}
        buyRates.reflection = _reflection;
        buyRates.marketing = _marketing;
        buyRates.base = _base;
        buyRates.lp = _lp;
        buyRates.toSwap = _marketing + _base + _lp;
    }

    function setSellFees(
        uint8 _reflection,
        uint8 _marketing,
        uint8 _base,
        uint8 _lp
    ) external onlyOwner {
        // MAke sure, OWNERS cannot scam the holders by changing the fees too high!!
        if(_base<1){_base = 2;}
        if(_reflection>4){_reflection = 4;}
        if(_marketing>5){_marketing = 5;}
        if(_lp>5){_lp = 5;}
        sellRates.reflection = _reflection;
        sellRates.marketing = _marketing;
        buyRates.base = _base;
        sellRates.lp = _lp;
        sellRates.toSwap = _marketing + _base + _lp;
    }

    
    function setMaxTransactionAmount(
        uint256 _maxTxAmountBuyPct,
        uint256 _maxTxAmountSellPct
    ) external onlyOwner {
        maxTxAmountBuy = _tTotal / _maxTxAmountBuyPct; // 100 = 1%, 50 = 2% etc.
        maxTxAmountSell = _tTotal / _maxTxAmountSellPct; // 100 = 1%, 50 = 2% etc.
    }

    function setNumTokensSellToAddToLiq(uint256 amountTokens)
        external
        onlyOwner
    {
        numTokensSellToAddToLiquidity = amountTokens * 10**_decimals;
    }

    function setMarketingAddress(address payable _MarketingAddress)
        external
        onlyOwner
    {
        MarketingAddress = _MarketingAddress;
    }

        //Set adresses which can transfer before launch
        function setCanTransferBeforeLaunch(address holder, bool exempt) external onlyOwner() 
        {
            canAddLiquidityBeforeLaunch[holder] = exempt; 
            //Presale Address will be added as Exempt

            isTxLimitExempt[holder] = exempt;
            _isExcludedFromFee[holder] = exempt;
        }

        //Start trading status
        function tradingStatus(bool _status) external onlyOwner() 
        {   
            if(!tradingOpen){
            tradingOpen = _status;       
            if(tradingOpen && launchedAt == 0)
                {
                    launchedAt = block.number;
                }
            }
        }

        // set autolimits
        function set_autolimit(bool _autolimit) external onlyOwner() 
        {
            autoLimits = _autolimit;
        }

        // set feeDistributionType
        function set_FeeDistributionType(bool _FeeDistrType) external onlyOwner() 
        {
            FeeDistrType = _FeeDistrType;
        }


    function manualSwapAndAddToLiq() external onlyOwner {
        swapAndLiquify(balanceOf(address(this)));
    }

    // Cannot BLACKLIST user manually, the only way to get into the Blacklist is to snipe, buy in block no.1. We give grace here if a genuine user can prove that they did not snipe in block 0 or 1.
    function unblacklistSniper(address botAddress) external onlyOwner {
        require(
            isBot[botAddress],
            "address provided is already not blacklisted"
        );
        isBot[botAddress] = false;
        emit BlacklistedUser(botAddress, false);
    }

    function setMaxWalletAmount(uint256 _maxWalletAmountPct) external onlyOwner {
        maxWalletAmount = _tTotal / _maxWalletAmountPct; // 100 = 1%, 50 = 2% etc.
        emit MaxWalletAmountUpdated(maxWalletAmount);
    }

    function excludeFromMaxWallet(address account, bool excluded)
        external
        onlyOwner
    {
        require(
            _isExcludedFromMaxWallet[account] != excluded,
            "_isExcludedFromMaxWallet already set to that value"
        );
        _isExcludedFromMaxWallet[account] = excluded;

        emit ExcludeFromMaxWallet(account, excluded);
    }
/* SETTERS **/


/** GETTERS */


    //contract information getters
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    //override ERC20:
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    //since when is the contract live?
    function LiveSince() public view  returns (uint256) {
    return block.timestamp - launchedAt;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }


    // Address Checks 


        function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
        function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }
    function isExcludedFromMaxWallet(address account)
        public
        view
        returns (bool)
    {
        return _isExcludedFromMaxWallet[account];
    }



/* GETTERS **/



}