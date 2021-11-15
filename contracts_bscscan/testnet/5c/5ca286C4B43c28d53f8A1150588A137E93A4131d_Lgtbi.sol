/*
                        ██╗      ██████╗████████╗██████╗ ██╗     ██
                        ██║     ██╔════╝╚══██╔══╝██╔══██╗██║     ██
                        ██║     ██║  ███╗  ██║   ██████╔╝██║ ██████████
                        ██║     ██║   ██║  ██║   ██╔══██╗██║     ██
                        ███████╗╚██████╔╝  ██║   ██████╔╝██║     ██
                        ╚══════╝ ╚═════╝   ╚═╝   ╚═════╝ ╚═╝
                                                            
                             ██████╗ ██████╗ ██╗███╗   ██╗  
                            ██╔════╝██╔═══██╗██║████╗  ██║  
                            ██║     ██║   ██║██║██╔██╗ ██║  
                            ██║     ██║   ██║██║██║╚██╗██║  
                            ╚██████╗╚██████╔╝██║██║ ╚████║  
                             ╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝  
Lgtbi+ Coin using & modify @OpenZeppeling and some SafeMoon functionality
Get 10% Max Fees
Initially     
1) 7% tax is collected and distributed to holders for HODLing
2) 3% -->1.5% burn & 1.5% Go to PanckakeSwap liquidity Pool 

*/                                                            
// 
// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.1;
//Imports
//interfaces
    interface IERC20 {
        function totalSupply() external view returns (uint256);
        function balanceOf(address account) external view returns (uint256);
        function transfer(address recipient, uint256 amount) external returns (bool);
        function allowance(address owner, address spender) external view returns (uint256);
        function approve(address spender, uint256 amount) external returns (bool);
        function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
    }   
    interface IAccessControl {
        event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
        event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
        event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
        function hasRole(bytes32 role, address account) external view returns (bool);
        function getRoleAdmin(bytes32 role) external view returns (bytes32);
        function grantRole(bytes32 role, address account) external;
        function revokeRole(bytes32 role, address account) external;
        function renounceRole(bytes32 role, address account) external;
    }
    interface IERC165 {
        function supportsInterface(bytes4 interfaceId) external view returns (bool);
    }
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
//libraries
    library SafeMath {
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
            uint256 c = a + b;
            require(c >= a, "SafeMath: addition overflow");

            return c;
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
            return sub(a, b, "SafeMath: subtraction overflow");
        }

        /**
        * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
        * overflow (when the result is negative).
        *
        * Counterpart to Solidity's `-` operator.
        *
        * Requirements:
        *
        * - Subtraction cannot overflow.
        */
        function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b <= a, errorMessage);
            uint256 c = a - b;

            return c;
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
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) {
                return 0;
            }

            uint256 c = a * b;
            require(c / a == b, "SafeMath: multiplication overflow");

            return c;
        }

        /**
        * @dev Returns the integer division of two unsigned integers. Reverts on
        * division by zero. The result is rounded towards zero.
        *
        * Counterpart to Solidity's `/` operator. Note: this function uses a
        * `revert` opcode (which leaves remaining gas untouched) while Solidity
        * uses an invalid opcode to revert (consuming all remaining gas).
        *
        * Requirements:
        *
        * - The divisor cannot be zero.
        */
        function div(uint256 a, uint256 b) internal pure returns (uint256) {
            return div(a, b, "SafeMath: division by zero");
        }

        /**
        * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
        * division by zero. The result is rounded towards zero.
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
            require(b > 0, errorMessage);
            uint256 c = a / b;
            // assert(a == b * c + a % b); // There is no case in which this doesn't hold

            return c;
        }

        /**
        * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
        * Reverts when dividing by zero.
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
            return mod(a, b, "SafeMath: modulo by zero");
        }

        /**
        * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
        * Reverts with custom message when dividing by zero.
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
            require(b != 0, errorMessage);
            return a % b;
        }
    }
    library Address {
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
    library Strings {
        bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

        /**
        * @dev Converts a `uint256` to its ASCII `string` decimal representation.
        */
        function toString(uint256 value) internal pure returns (string memory) {
            // Inspired by OraclizeAPI's implementation - MIT licence
            // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

            if (value == 0) {
                return "0";
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            bytes memory buffer = new bytes(digits);
            while (value != 0) {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }

        /**
        * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
        */
        function toHexString(uint256 value) internal pure returns (string memory) {
            if (value == 0) {
                return "0x00";
            }
            uint256 temp = value;
            uint256 length = 0;
            while (temp != 0) {
                length++;
                temp >>= 8;
            }
            return toHexString(value, length);
        }

        /**
        * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
        */
        function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
            bytes memory buffer = new bytes(2 * length + 2);
            buffer[0] = "0";
            buffer[1] = "x";
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = _HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
            require(value == 0, "Strings: hex length insufficient");
            return string(buffer);
    }
}
//Contracts
    abstract contract Context {
        function _msgSender() internal view virtual returns (address) {
            return msg.sender;
        }

        function _msgData() internal view virtual returns (bytes memory) {
            this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
            return msg.data;
        }
    }
    contract Ownable is Context {
        address public _owner;
        address private _previousOwner;
        uint256 private _lockTime;

        event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
        function owner() public view returns (address) {
            return _owner;
        }

        modifier onlyOwner() {
            require(_owner == _msgSender(), "Ownable: caller is not the owner");
            _;
        }

        function renounceOwnership() public virtual onlyOwner {
            emit OwnershipTransferred(_owner, address(0));
            _owner = address(0);
        }

        function transferOwnership(address newOwner) public virtual onlyOwner {
            require(newOwner != address(0), "Ownable: new owner is the zero address");
            emit OwnershipTransferred(_owner, newOwner);
            _owner = newOwner;
        }

        function geUnlockTime() public view returns (uint256) {
            return _lockTime;
        }

        //Locks the contract for owner for the amount of time provided
        function lock(uint256 time) public virtual onlyOwner {
            _previousOwner = _owner;
            _owner = address(0);
            _lockTime = block.timestamp + time;
            emit OwnershipTransferred(_owner, address(0));
        }
        
        //Unlocks the contract for owner when _lockTime is exceeds
        function unlock() public virtual {
            require(_previousOwner == msg.sender, "You don't have permission to unlock");
            require(block.timestamp > _lockTime , "Contract is locked until 7 days");
            emit OwnershipTransferred(_owner, _previousOwner);
            _owner = _previousOwner;
        }
    }
    abstract contract ERC165 is IERC165 {
        function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
            return interfaceId == type(IERC165).interfaceId;
        }

    }
// Set logic roles 
    abstract contract RMB is Ownable, IAccessControl, ERC165, IERC20 {
        struct RoleData { mapping(address => bool) members; bytes32 adminRole;   }
        enum fnames { TIMELOCK_FN, REVOKE_FN, GRANT_FN, MINBOARD_FN, MAXBOARD_FN,CLAIM_FN, 
                        ROUTERADDRESS_FN,LIQFEE_FN, SWAPLIQ_FN,MAXTX_FN,SELLLIQ_FN, TAXFEE_FN,INCINFEE_FN,
                        EXCINFEE_FN, INCREW_FN,EXCREW_FN}
        uint256 private _TIMELOCK = 1 days;
        uint256 private _minApprovers = 3;
        uint256 private _maxApprovers = 10;
        uint256 private boardRoleCount = 0;  
        bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
        bytes32 public constant BOARD_ROLE = keccak256("BOARD_ROLE");
    
        mapping (fnames => uint256) private timelock;
        mapping (fnames => uint256 ) private n_approves;
        mapping (fnames => mapping (uint256 => mapping( address => bool))) private acepted;
        mapping(bytes32 => RoleData) private _roles;

        event _Approvement_Events(string  , fnames, address addAcepted); 
        event _lockFunction_Events(string  , fnames);
        modifier onlyRole(bytes32 role) { _checkRole(role, _msgSender()); _;  }
        modifier notLocked(fnames _fn) {
            require(timelock[_fn] != 0 && timelock[_fn] > block.timestamp, "Function is Time Locked");
            _;
        }
        modifier isLocked(fnames _fn){
            require(timelock[_fn] == 0 || timelock[_fn] <= block.timestamp, "Function is Active");
            _;
        }
        modifier onlyBoard() {
            _checkRole(BOARD_ROLE, _msgSender());
            _;
        
        }    
        modifier onlyBoard_approve(fnames _fn) {
            _checkRole(BOARD_ROLE, _msgSender());
            require(n_approves[_fn]>=_minApprovers, "approval required, not approved yet..." );
            _;
        }       
        function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
            return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
        }
        function hasRole(bytes32 role, address account) public view override returns (bool) {
            return _roles[role].members[account];
        }
        function _checkRole(bytes32 role, address account) internal view {
            if (!hasRole(role, account)) {
                revert(
                    string(
                        abi.encodePacked(
                            "AccessControl: account ",
                            Strings.toHexString(uint160(account), 20),
                            " is missing role ",
                            Strings.toHexString(uint256(role), 32)
                        )
                    )
                );
            }
        }
        function boardCount() public view returns(uint256) {
            return boardRoleCount;
        }
        function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
            return _roles[role].adminRole;
        }
        function grantRole(bytes32 role, address account) public virtual override onlyBoard_approve(fnames.GRANT_FN) {
            _grantRole(role, account);
        }
        function revokeRole(bytes32 role, address account) public virtual override onlyBoard_approve(fnames.REVOKE_FN) {
            
            _revokeRole(role, account);
        }
        function renounceRole(bytes32 role, address account) public virtual override {
            require(account == _msgSender(), "AccessControl: can only renounce roles for self");
            _revokeRole(role, account);
        }
        function _setupRole(bytes32 role, address account) internal virtual {       
            _grantRole(role, account);
        }
        function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
            bytes32 previousAdminRole = getRoleAdmin(role);
            _roles[role].adminRole = adminRole;
            emit RoleAdminChanged(role, previousAdminRole, adminRole);
        }
        function _grantRole(bytes32 role, address account) private {
            //Only Use BOARD_ROLE
            if (!hasRole(role, account)) {
                require(boardRoleCount<10,"To many board...");
                boardRoleCount++;
                _roles[role].members[account] = true;
                emit RoleGranted(role, account, _msgSender());
            }
        }
        function _revokeRole(bytes32 role, address account) private {
            //Only Use BOARD_ROLE
            if (hasRole(role, account)) {
                require(boardRoleCount>3,"Prevent min board...");
                boardRoleCount--;
                _roles[role].members[account] = false;
                emit RoleRevoked(role, account, _msgSender());
            }
        }
        function ApproveFunction(fnames _fn) onlyBoard public {
            
            require(n_approves[_fn]<=_maxApprovers, "Too many approvers..." );
            require (!already_approvedBySender(_fn), "Already approved");
        
            //Unlock for Unlock Time only first time...
            if (n_approves[_fn] == 0 )
            {
                unlockFunction(_fn);
            }
            n_approves[_fn]++; 
            acepted[_fn][n_approves[_fn]][msg.sender] = true;
            emit _Approvement_Events("Acpeted execution for function",_fn,msg.sender );    
        
        }
        function already_approvedBySender(fnames _fn) private view returns (bool){
            //To prevent big for loop
            require(n_approves[_fn]<=_maxApprovers, "Too many approvers..." );
            bool res = false;
            for (uint256 i = 1; i < n_approves[_fn]+1; i++) 
            { 
                if (acepted[_fn][i][msg.sender] == true)
                {
                    
                    res = true;
                    break;
                }
            }
            return res;
        }
        function  cleanApprovement(fnames _fn) internal onlyBoard{
            
            //To prevent big for loop
            require(n_approves[_fn]<=_maxApprovers, "Too many approvers..." );
            for (uint256 i = 1; i < n_approves[_fn]+1; i++) 
            {
                acepted[_fn][i][msg.sender] = false;
                delete acepted[_fn][i][msg.sender];
            }
            n_approves[_fn] = 0;
            lockFunction(_fn); //Reset timelock to 0
            emit _Approvement_Events("Reset approvemets for function",_fn,msg.sender );
        }
        //unlock timelock
        function unlockFunction(fnames _fn) private  onlyBoard {
            timelock[_fn] = block.timestamp + _TIMELOCK;
            emit _lockFunction_Events("Unlock function",_fn);
        }
        //lock timelock
        function lockFunction(fnames _fn) private onlyBoard {
            timelock[_fn] = 0;
            emit _lockFunction_Events("lock function",_fn);
        }
        function isLockqued(fnames _fn) public view returns (bool) {
        return (timelock[_fn] == 0||timelock[_fn] < block.timestamp);
        }
        function _SetTimeLock(uint256 _timelock) public onlyBoard_approve(fnames.TIMELOCK_FN){
            require(_timelock > 1);
            cleanApprovement(fnames.TIMELOCK_FN);
            _TIMELOCK = _timelock;
        }
        function _SetMinBoard(uint256 _minBoard) public onlyBoard_approve(fnames.MINBOARD_FN){
            require(_minBoard > 3);
            cleanApprovement(fnames.MINBOARD_FN);
            _minApprovers = _minApprovers;
        }
        function _SetMaxBoard(uint256 _maxBoard) public onlyBoard_approve(fnames.MAXBOARD_FN){
            require(_maxBoard <= 10);
            cleanApprovement(fnames.MAXBOARD_FN);
            _maxApprovers = _maxBoard;
        }
    }

contract Lgtbi is RMB {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;

    address[] private _excluded;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;
    string private _name;
    string private _symbol;
    uint256 private _decimals;   
    uint256 public _taxFee;
    uint256 private _previousTaxFee;
    uint256 public _liquidityFee;
    uint256 private _previousLiquidityFee;
    address private _dedicatedburning;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    
    uint256 public _maxTxAmount;
    uint256 public numTokensSellToAddToLiquidity;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived,uint256 tokensIntoLiqudity);
    
    modifier lockTheSwap {inSwapAndLiquify = true;_;inSwapAndLiquify = false;}
    
    constructor (
    address payable CEO,address payable CMO,address payable RHH,
    address separateForControllBurns, address donationAddress, address [] memory  board)  {
        _name = 'Lgtib+ Coin9';
        _symbol = 'LGT9';
        _decimals = 18;

        _tTotal = 1000000000 * 10 ** _decimals;
        _rTotal = (MAX - (MAX % _tTotal));
        _taxFee = 7;
        _liquidityFee = 3;
        _previousTaxFee = 7;
        _previousLiquidityFee = 3;
        _maxTxAmount = 5000000 * 10 ** _decimals;
        numTokensSellToAddToLiquidity = 500000 * 10 ** _decimals;
        _owner = CEO;
        _dedicatedburning=separateForControllBurns;
        _rOwned[CEO] = _rTotal;
        //Fill board
        for (uint256 i = 0; i < board.length; ++i) {
            _setupRole(BOARD_ROLE, board[i]);
            
        }        
        //exclude CEO and this contract from fee
        _isExcludedFromFee[CEO] = true;
        _isExcludedFromFee[address(this)] = true;
    
        uint256 _tenPercent = _tTotal.mul(10).div(10**2);
        uint256 _BurnPercent = _tTotal.mul(25).div(10**2);
        uint256 _DonationPercent = _tTotal.mul(15).div(10**2);
        
        emit Transfer(address(0), CEO, _tTotal.sub(_tenPercent.mul(2)).sub(_BurnPercent).sub(_DonationPercent));
        //transfer to Board
        emit Transfer(address(0), CMO,_tenPercent );
        emit Transfer(address(0), RHH,_tenPercent);
        emit Transfer(address(0), separateForControllBurns, _BurnPercent);
        emit Transfer(address(0), donationAddress, _DonationPercent);
    }

//Standard functios
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "Decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Burn from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        _transfer(account, address(0), amount);
    }
    function burn(uint amount) public virtual{
        require(_msgSender() != address(0), "Burn from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        _burn(_msgSender(), amount);
    }
    function burningFromBurnAccount(uint amount) public virtual{
        require(_msgSender() != address(0), "Burn from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        _approve(_dedicatedburning, _msgSender(), amount);
        _burn(_dedicatedburning, amount);
    }
//Fees&rewars
    function excludeFromReward(address account) public onlyBoard_approve(fnames.EXCREW_FN) {
        require(!_isExcluded[account], "Account is already excluded");
        cleanApprovement(fnames.EXCREW_FN);
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
    function includeInReward(address account) external onlyBoard_approve(fnames.INCREW_FN) {
        require(_isExcluded[account], "Account is already excluded");
        cleanApprovement(fnames.INCREW_FN);
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
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }    
    function excludeFromFee(address account) public onlyBoard_approve(fnames.EXCINFEE_FN) {
        cleanApprovement(fnames.EXCINFEE_FN);
        _isExcludedFromFee[account] = true;
    }   
    function includeInFee(address account) public onlyBoard_approve(fnames.INCINFEE_FN)  {
        cleanApprovement(fnames.INCINFEE_FN);
        _isExcludedFromFee[account] = false;
    }  
    function setTaxFeePercent(uint256 taxFee) external onlyBoard_approve(fnames.TAXFEE_FN) {
        cleanApprovement(fnames.TAXFEE_FN);
        require(taxFee.add(_liquidityFee)<11,"Control Fees up 10%");
        _taxFee = taxFee;
    }   
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyBoard_approve(fnames.LIQFEE_FN)  {
        cleanApprovement(fnames.LIQFEE_FN);
        require(liquidityFee.add(_taxFee)<11,"Control Fees up 10%");
        _liquidityFee = liquidityFee;
    }  
    function setNumTokensSellToAddToLiquidity(uint256 swapNumber) public onlyBoard_approve(fnames.SELLLIQ_FN) {
        cleanApprovement(fnames.SELLLIQ_FN);
        numTokensSellToAddToLiquidity = swapNumber * 10 ** _decimals;
    } 
    function setMaxTxPercent(uint256 maxTxPercent) public onlyBoard_approve(fnames.MAXTX_FN) {
        cleanApprovement(fnames.MAXTX_FN);
        _maxTxAmount = maxTxPercent  * 10 ** _decimals;
    }
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyBoard_approve(fnames.SWAPLIQ_FN) {
        cleanApprovement(fnames.SWAPLIQ_FN);
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
   function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }   
    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        
        _taxFee = 0;
        _liquidityFee = 0;
    }   
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }    
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

//  Transfer&Swap  
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }  
    function claimTokens() public onlyBoard_approve(fnames.CLAIM_FN) {
            cleanApprovement(fnames.CLAIM_FN);
            payable(_owner).transfer(address(this).balance);
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(address from, address to,uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function setRouterAddress(address newRouter) external onlyBoard_approve(fnames.ROUTERADDRESS_FN) {
        setSwapAndLiquifyEnabled(false);
        IUniswapV2Router02 _newUniRouter = IUniswapV2Router02(newRouter);
        uniswapV2Pair = IUniswapV2Factory(_newUniRouter.factory()).createPair(address(this), _newUniRouter.WETH());
        uniswapV2Router = _newUniRouter;
        setSwapAndLiquifyEnabled(true);
    }

    receive() external payable {}
}

