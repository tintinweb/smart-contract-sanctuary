/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// File contracts/interfaces/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function burn(uint256 value) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}


// File contracts/interfaces/IFlashReceiver.sol


pragma solidity 0.7.4;

interface IFlashReceiver {
    function receiveFlash(
        bytes32 _id,
        uint256 _amountIn,
        uint256 _expireAfter,
        uint256 _mintedAmount,
        address _staker,
        bytes calldata _data
    ) external returns (uint256);
}


// File contracts/interfaces/IFlashProtocol.sol


pragma solidity 0.7.4;

interface IFlashProtocol {
    function stake(
        uint256 _amountIn,
        uint256 _days,
        address _receiver,
        bytes calldata _data
    )
        external
        returns (
            uint256 mintedAmount,
            uint256 matchedAmount,
            bytes32 id
        );

    function unstake(bytes32 _id) external returns (uint256 withdrawAmount);

    function getFPY(uint256 _amountIn) external view returns (uint256);
}


// File contracts/libraries/SafeMath.sol


pragma solidity 0.7.4;

// A library for performing overflow-safe math, courtesy of DappHub: https://github.com/dapphub/ds-math/blob/d0ef6d6a5f/src/math.sol
// Modified to include only the essentials
library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "MATH:: ADD_OVERFLOW");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "MATH:: SUB_UNDERFLOW");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MATH:: MUL_OVERFLOW");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "MATH:: DIVISION_BY_ZERO");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


// File contracts/libraries/Address.sol


pragma solidity 0.7.4;

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
        // solhint-disable-next-line no-inline-assembly
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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


// File contracts/libraries/Create2.sol


pragma solidity 0.7.4;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint256(_data));
    }
}


// File contracts/libraries/SafeERC20.sol


pragma solidity 0.7.4;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/pool/interfaces/IPool.sol


pragma solidity 0.7.4;

interface IPool {
    function initialize(address _token) external;

    function stakeWithFeeRewardDistribution(
        uint256 _amountIn,
        address _staker,
        uint256 _expectedOutput
    ) external returns (uint256 result);

    function addLiquidity(
        uint256 _amountFLASH,
        uint256 _amountALT,
        uint256 _amountFLASHMin,
        uint256 _amountALTMin,
        address _maker
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function removeLiquidity(address _maker) external returns (uint256, uint256);

    function swapWithFeeRewardDistribution(
        uint256 _amountIn,
        address _staker,
        uint256 _expectedOutput
    ) external returns (uint256 result);
}


// File contracts/pool/contracts/PoolERC20.sol


pragma solidity 0.7.4;


// Lightweight token modelled after UNI-LP:
// https://github.com/Uniswap/uniswap-v2-core/blob/v1.0.1/contracts/UniswapV2ERC20.sol
// Adds:
//   - An exposed `mint()` with minting role
//   - An exposed `burn()`
//   - ERC-3009 (`transferWithAuthorization()`)
//   - flashMint() - allows to flashMint an arbitrary amount of FLASH, with the
//     condition that it is burned before the end of the transaction.
contract PoolERC20 is IERC20 {
    using SafeMath for uint256;

    // bytes32 private constant EIP712DOMAIN_HASH =
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 private constant EIP712DOMAIN_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    // bytes32 private constant NAME_HASH = keccak256("FLASH-ALT-LP Token")
    bytes32 private constant NAME_HASH = 0xfdde3a7807889787f51ab17062704a0d81341ba7debe5a9773b58a1b5e5f422c;

    // bytes32 private constant VERSION_HASH = keccak256("2")
    bytes32 private constant VERSION_HASH = 0xad7c5bef027816a800da1736444fb58a807ef4c9603b7848673f7e3a68eb14a5;

    // bytes32 public constant PERMIT_TYPEHASH =
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    // bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
    // keccak256("TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)");
    bytes32
        public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH = 0x7c7c6cdb67a18743f49ec6fa9b35f50d52ed05cbed4cc592e13b44501c1a2267;

    string public constant name = "FLASH-ALT-LP Token";
    string public constant symbol = "FLASH-ALT-LP";
    uint8 public constant decimals = 18;

    uint256 public override totalSupply;

    address public minter;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    // ERC-2612, ERC-3009 state
    mapping(address => uint256) public nonces;
    mapping(address => mapping(bytes32 => bool)) public authorizationState;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);

    function _validateSignedData(
        address signer,
        bytes32 encodeData,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), encodeData));
        address recoveredAddress = ecrecover(digest, v, r, s);
        // Explicitly disallow authorizations for address(0) as ecrecover returns address(0) on malformed messages
        require(recoveredAddress != address(0) && recoveredAddress == signer, "FLASH-ALT-LP Token:: INVALID_SIGNATURE");
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        // Balance is implicitly checked with SafeMath's underflow protection
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        require(to != address(0), "FLASH-ALT-LP Token:: RECEIVER_IS_TOKEN_OR_ZERO");
        // Balance is implicitly checked with SafeMath's underflow protection
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function getChainId() public pure returns (uint256 chainId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }

    function getDomainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(EIP712DOMAIN_HASH, NAME_HASH, VERSION_HASH, getChainId(), address(this)));
    }

    function burn(uint256 value) external override returns (bool) {
        _burn(msg.sender, value);
        return true;
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        uint256 fromAllowance = allowance[from][msg.sender];
        if (fromAllowance != uint256(-1)) {
            // Allowance is implicitly checked with SafeMath's underflow protection
            allowance[from][msg.sender] = fromAllowance.sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(deadline >= block.timestamp, "FLASH-ALT-LP Token:: AUTH_EXPIRED");

        bytes32 encodeData = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner], deadline));
        nonces[owner] = nonces[owner].add(1);
        _validateSignedData(owner, encodeData, v, r, s);

        _approve(owner, spender, value);
    }

    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp > validAfter, "FLASH-ALT-LP Token:: AUTH_NOT_YET_VALID");
        require(block.timestamp < validBefore, "FLASH-ALT-LP Token:: AUTH_EXPIRED");
        require(!authorizationState[from][nonce], "FLASH-ALT-LP Token:: AUTH_ALREADY_USED");

        bytes32 encodeData = keccak256(
            abi.encode(TRANSFER_WITH_AUTHORIZATION_TYPEHASH, from, to, value, validAfter, validBefore, nonce)
        );
        _validateSignedData(from, encodeData, v, r, s);

        authorizationState[from][nonce] = true;
        emit AuthorizationUsed(from, nonce);

        _transfer(from, to, value);
    }
}


// File contracts/pool/contracts/Pool.sol


pragma solidity 0.7.4;




contract Pool is PoolERC20, IPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;

    address public constant FLASH_TOKEN = 0x20398aD62bb2D930646d45a6D4292baa0b860C1f;
    address public constant FLASH_PROTOCOL = 0x15EB0c763581329C921C8398556EcFf85Cc48275;

    uint256 public reserveFlashAmount;
    uint256 public reserveAltAmount;
    uint256 private unlocked = 1;

    address public token;
    address public factory;

    modifier lock() {
        require(unlocked == 1, "Pool: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "Pool:: ONLY_FACTORY");
        _;
    }

    constructor() {
        factory = msg.sender;
    }

    function initialize(address _token) public override onlyFactory {
        token = _token;
    }

    function swapWithFeeRewardDistribution(
        uint256 _amountIn,
        address _staker,
        uint256 _expectedOutput
    ) public override lock onlyFactory returns (uint256 result) {
        result = getAPYSwap(_amountIn);
        require(_expectedOutput <= result, "Pool:: EXPECTED_IS_GREATER");
        calcNewReserveSwap(_amountIn, result);
        IERC20(FLASH_TOKEN).safeTransfer(_staker, result);
    }

    function stakeWithFeeRewardDistribution(
        uint256 _amountIn,
        address _staker,
        uint256 _expectedOutput
    ) public override lock onlyFactory returns (uint256 result) {
        result = getAPYStake(_amountIn);
        require(_expectedOutput <= result, "Pool:: EXPECTED_IS_GREATER");
        calcNewReserveStake(_amountIn, result);
        IERC20(token).safeTransfer(_staker, result);
    }

    function addLiquidity(
        uint256 _amountFLASH,
        uint256 _amountALT,
        uint256 _amountFLASHMin,
        uint256 _amountALTMin,
        address _maker
    )
        public
        override
        onlyFactory
        returns (
            uint256 amountFLASH,
            uint256 amountALT,
            uint256 liquidity
        )
    {
        (amountFLASH, amountALT) = _addLiquidity(_amountFLASH, _amountALT, _amountFLASHMin, _amountALTMin);
        liquidity = mintLiquidityTokens(_maker, amountFLASH, amountALT);
        calcNewReserveAddLiquidity(amountFLASH, amountALT);
    }

    function removeLiquidity(address _maker)
        public
        override
        onlyFactory
        returns (uint256 amountFLASH, uint256 amountALT)
    {
        (amountFLASH, amountALT) = burn(_maker);
    }

    function getAPYStake(uint256 _amountIn) public view returns (uint256 result) {
        uint256 amountInWithFee = _amountIn.mul(getLPFee());
        uint256 num = amountInWithFee.mul(reserveAltAmount);
        uint256 den = (reserveFlashAmount.mul(1000)).add(amountInWithFee);
        result = num.div(den);
    }

    function getAPYSwap(uint256 _amountIn) public view returns (uint256 result) {
        uint256 amountInWithFee = _amountIn.mul(getLPFee());
        uint256 num = amountInWithFee.mul(reserveFlashAmount);
        uint256 den = (reserveAltAmount.mul(1000)).add(amountInWithFee);
        result = num.div(den);
    }

    function getLPFee() public view returns (uint256) {
        uint256 fpy = IFlashProtocol(FLASH_PROTOCOL).getFPY(0);
        return uint256(1000).sub(fpy.div(5e15));
    }

    function quote(
        uint256 _amountA,
        uint256 _reserveA,
        uint256 _reserveB
    ) public pure returns (uint256 amountB) {
        require(_amountA > 0, "Pool:: INSUFFICIENT_AMOUNT");
        require(_reserveA > 0 && _reserveB > 0, "Pool:: INSUFFICIENT_LIQUIDITY");
        amountB = _amountA.mul(_reserveB).div(_reserveA);
    }

    function burn(address to) private lock returns (uint256 amountFLASH, uint256 amountALT) {
        uint256 balanceFLASH = IERC20(FLASH_TOKEN).balanceOf(address(this));
        uint256 balanceALT = IERC20(token).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];

        amountFLASH = liquidity.mul(balanceFLASH) / totalSupply;
        amountALT = liquidity.mul(balanceALT) / totalSupply;

        require(amountFLASH > 0 && amountALT > 0, "Pool:: INSUFFICIENT_LIQUIDITY_BURNED");

        _burn(address(this), liquidity);

        IERC20(FLASH_TOKEN).safeTransfer(to, amountFLASH);
        IERC20(token).safeTransfer(to, amountALT);

        balanceFLASH = balanceFLASH.sub(IERC20(FLASH_TOKEN).balanceOf(address(this)));
        balanceALT = balanceALT.sub(IERC20(token).balanceOf(address(this)));

        calcNewReserveRemoveLiquidity(balanceFLASH, balanceALT);
    }

    function _addLiquidity(
        uint256 _amountFLASH,
        uint256 _amountALT,
        uint256 _amountFLASHMin,
        uint256 _amountALTMin
    ) private view returns (uint256 amountFLASH, uint256 amountALT) {
        if (reserveAltAmount == 0 && reserveFlashAmount == 0) {
            (amountFLASH, amountALT) = (_amountFLASH, _amountALT);
        } else {
            uint256 amountALTQuote = quote(_amountFLASH, reserveFlashAmount, reserveAltAmount);
            if (amountALTQuote <= _amountALT) {
                require(amountALTQuote >= _amountALTMin, "Pool:: INSUFFICIENT_B_AMOUNT");
                (amountFLASH, amountALT) = (_amountFLASH, amountALTQuote);
            } else {
                uint256 amountFLASHQuote = quote(_amountALT, reserveAltAmount, reserveFlashAmount);
                require(
                    (amountFLASHQuote <= _amountFLASH) && (amountFLASHQuote >= _amountFLASHMin),
                    "Pool:: INSUFFICIENT_A_AMOUNT"
                );
                (amountFLASH, amountALT) = (amountFLASHQuote, _amountALT);
            }
        }
    }

    function mintLiquidityTokens(
        address _to,
        uint256 _flashAmount,
        uint256 _altAmount
    ) private returns (uint256 liquidity) {
        if (totalSupply == 0) {
            liquidity = SafeMath.sqrt(_flashAmount.mul(_altAmount)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = SafeMath.min(
                _flashAmount.mul(totalSupply) / reserveFlashAmount,
                _altAmount.mul(totalSupply) / reserveAltAmount
            );
        }
        require(liquidity > 0, "Pool:: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(_to, liquidity);
    }

    function calcNewReserveStake(uint256 _amountIn, uint256 _amountOut) private {
        reserveFlashAmount = reserveFlashAmount.add(_amountIn);
        reserveAltAmount = reserveAltAmount.sub(_amountOut);
    }

    function calcNewReserveSwap(uint256 _amountIn, uint256 _amountOut) private {
        reserveFlashAmount = reserveFlashAmount.sub(_amountOut);
        reserveAltAmount = reserveAltAmount.add(_amountIn);
    }

    function calcNewReserveAddLiquidity(uint256 _amountFLASH, uint256 _amountALT) private {
        reserveFlashAmount = reserveFlashAmount.add(_amountFLASH);
        reserveAltAmount = reserveAltAmount.add(_amountALT);
    }

    function calcNewReserveRemoveLiquidity(uint256 _amountFLASH, uint256 _amountALT) private {
        reserveFlashAmount = reserveFlashAmount.sub(_amountFLASH);
        reserveAltAmount = reserveAltAmount.sub(_amountALT);
    }
}


// File contracts/FlashApp.sol


pragma solidity 0.7.4;







contract FlashApp is IFlashReceiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public constant FLASH_TOKEN = 0x20398aD62bb2D930646d45a6D4292baa0b860C1f;
    address public constant FLASH_PROTOCOL = 0x15EB0c763581329C921C8398556EcFf85Cc48275;

    mapping(bytes32 => uint256) public stakerReward;
    mapping(address => address) public pools; // token -> pools

    event PoolCreated(address _pool, address _token);

    event Staked(bytes32 _id, uint256 _rewardAmount, address _pool);

    event LiquidityAdded(address _pool, uint256 _amountFLASH, uint256 _amountALT, uint256 _liquidity, address _sender);

    event LiquidityRemoved(
        address _pool,
        uint256 _amountFLASH,
        uint256 _amountALT,
        uint256 _liquidity,
        address _sender
    );

    event Swapped(address _sender, uint256 _swapAmount, uint256 _flashReceived, address _pool);

    modifier onlyProtocol() {
        require(msg.sender == FLASH_PROTOCOL, "FlashApp:: ONLY_PROTOCOL");
        _;
    }

    function createPool(address _token) external returns (address poolAddress) {
        require(_token != address(0), "FlashApp:: INVALID_TOKEN_ADDRESS");
        require(pools[_token] == address(0), "FlashApp:: POOL_ALREADY_EXISTS");
        bytes memory bytecode = type(Pool).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(block.timestamp, msg.sender));
        poolAddress = Create2.deploy(0, salt, bytecode);
        pools[_token] = poolAddress;
        IPool(poolAddress).initialize(_token);
        emit PoolCreated(poolAddress, _token);
    }

    function receiveFlash(
        bytes32 _id,
        uint256 _amountIn, //unused
        uint256 _expireAfter, //unused
        uint256 _mintedAmount,
        address _staker,
        bytes calldata _data
    ) external override onlyProtocol returns (uint256) {
        (address token, uint256 expectedOutput) = abi.decode(_data, (address, uint256));
        address pool = pools[token];
        IERC20(FLASH_TOKEN).safeTransfer(pool, _mintedAmount);
        uint256 reward = IPool(pool).stakeWithFeeRewardDistribution(_mintedAmount, _staker, expectedOutput);
        stakerReward[_id] = reward;
        emit Staked(_id, reward, pool);
    }

    function unstake(bytes32[] memory _expiredIds) public {
        for (uint256 i = 0; i < _expiredIds.length; i = i.add(1)) {
            IFlashProtocol(FLASH_PROTOCOL).unstake(_expiredIds[i]);
        }
    }

    function swap(
        uint256 _altQuantity,
        address _token,
        uint256 _expectedOutput
    ) public returns (uint256 result) {
        address user = msg.sender;
        address pool = pools[_token];

        require(pool != address(0), "FlashApp:: POOL_DOESNT_EXIST");
        require(_altQuantity > 0, "FlashApp:: INVALID_AMOUNT");

        IERC20(_token).safeTransferFrom(user, address(this), _altQuantity);
        IERC20(_token).safeTransfer(pool, _altQuantity);

        result = IPool(pool).swapWithFeeRewardDistribution(_altQuantity, user, _expectedOutput);

        emit Swapped(user, _altQuantity, result, pool);
    }

    function addLiquidityInPool(
        uint256 _amountFLASH,
        uint256 _amountALT,
        uint256 _amountFLASHMin,
        uint256 _amountALTMin,
        address _token
    ) public {
        address maker = msg.sender;
        address pool = pools[_token];

        require(pool != address(0), "FlashApp:: POOL_DOESNT_EXIST");
        require(_amountFLASH > 0 && _amountALT > 0, "FlashApp:: INVALID_AMOUNT");

        (uint256 amountFLASH, uint256 amountALT, uint256 liquidity) = IPool(pool).addLiquidity(
            _amountFLASH,
            _amountALT,
            _amountFLASHMin,
            _amountALTMin,
            maker
        );

        IERC20(FLASH_TOKEN).safeTransferFrom(maker, address(this), amountFLASH);
        IERC20(FLASH_TOKEN).safeTransfer(pool, amountFLASH);

        IERC20(_token).safeTransferFrom(maker, address(this), amountALT);
        IERC20(_token).safeTransfer(pool, amountALT);

        emit LiquidityAdded(pool, amountFLASH, amountALT, liquidity, maker);
    }

    function removeLiquidityInPool(uint256 _liquidity, address _token) public {
        address maker = msg.sender;

        address pool = pools[_token];

        require(pool != address(0), "FlashApp:: POOL_DOESNT_EXIST");

        IERC20(pool).safeTransferFrom(maker, address(this), _liquidity);
        IERC20(pool).safeTransfer(pool, _liquidity);

        (uint256 amountFLASH, uint256 amountALT) = IPool(pool).removeLiquidity(maker);

        emit LiquidityRemoved(pool, amountFLASH, amountALT, _liquidity, maker);
    }

    function removeLiquidityInPoolWithPermit(
        uint256 _liquidity,
        address _token,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public {
        address maker = msg.sender;

        address pool = pools[_token];

        require(pool != address(0), "FlashApp:: POOL_DOESNT_EXIST");

        IERC20(pool).permit(maker, pool, type(uint256).max, _deadline, _v, _r, _s);

        IERC20(pool).safeTransferFrom(maker, pool, _liquidity);

        (uint256 amountFLASH, uint256 amountALT) = IPool(pool).removeLiquidity(maker);

        emit LiquidityRemoved(pool, amountFLASH, amountALT, _liquidity, maker);
    }
}