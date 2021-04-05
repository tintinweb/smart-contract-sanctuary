/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

// SPDX-License-Identifier: MIT
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

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function mint(address to, uint256 value) external returns (bool);

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

interface IUSDHProtocol {
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

interface IPool {
    function initialize(address _token) external;
    
    function addLiquidity(
        uint256 _amountALT,
        address _owner
    )
        external
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function removeLiquidity(address _maker) external returns (uint256, uint256, uint256);

    function swapTokens(
        address _user,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _amountInAddress,
        address _amountOutAddress
    ) external returns (uint256 result);

    function setRatio(uint256 _ratio) external;

    function getDetails() external view returns(uint256, uint256, uint256);
    
    function getUser(address _user) external view returns(uint256, uint256);
}

contract PoolERC20 is IERC20 {
    using SafeMath for uint256;

    // bytes32 private constant EIP712DOMAIN_HASH =
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 private constant EIP712DOMAIN_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    // bytes32 private constant NAME_HASH = keccak256("USDH-ALT-LP Token")
    bytes32 private constant NAME_HASH = 0x0;

    // bytes32 private constant VERSION_HASH = keccak256("1")
    bytes32 private constant VERSION_HASH = 0x0;

    // bytes32 public constant PERMIT_TYPEHASH =
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    // bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
    // keccak256("TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)");
    bytes32
        public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH = 0x7c7c6cdb67a18743f49ec6fa9b35f50d52ed05cbed4cc592e13b44501c1a2267;

    string public constant name = "USDH-ALT-LP Token";
    string public constant symbol = "USDH-ALT-LP";
    uint8 public constant decimals = 18;

    uint256 public override totalSupply;

    // address public minter;

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
        require(recoveredAddress != address(0) && recoveredAddress == signer, "USDH-ALT-LP Token:: INVALID_SIGNATURE");
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function mint(address to, uint256 value) public override returns (bool) {
        _mint(to, value);
        return true;
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
        require(to != address(0), "USDH-ALT-LP Token:: RECEIVER_IS_TOKEN_OR_ZERO");
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
        require(deadline >= block.timestamp, "USDH-ALT-LP Token:: AUTH_EXPIRED");

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
        require(block.timestamp > validAfter, "USDH-ALT-LP Token:: AUTH_NOT_YET_VALID");
        require(block.timestamp < validBefore, "USDH-ALT-LP Token:: AUTH_EXPIRED");
        require(!authorizationState[from][nonce], "USDH-ALT-LP Token:: AUTH_ALREADY_USED");

        bytes32 encodeData = keccak256(
            abi.encode(TRANSFER_WITH_AUTHORIZATION_TYPEHASH, from, to, value, validAfter, validBefore, nonce)
        );
        _validateSignedData(from, encodeData, v, r, s);

        authorizationState[from][nonce] = true;
        emit AuthorizationUsed(from, nonce);

        _transfer(from, to, value);
    }
}

contract Pool is PoolERC20, IPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;

    struct User {
        uint256 tokenUSDH;
        uint256 LPTokensAmount;
    }

    address public constant USDH__TOKEN = 0x11840Cc5A565Eb1006faF8cF41D960c76e00A022;

    uint256 public reserveUSDHAmount;
    uint256 public reserveAltAmount;
    uint256 private unlocked = 1;

    address public token;
    address public factory;
    uint256 public initialRatio;

    mapping(address => User) public user;

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

    function addLiquidity(uint256 _amountALT, address _owner) public override onlyFactory returns(uint256 amountUSDH, uint256 amountAlt, uint256 liquidity, uint256 userLiquidityReward, uint256 stakeAmount, uint256 amountUSDHTotal) {
        (amountUSDH, amountAlt, userLiquidityReward, stakeAmount, amountUSDHTotal) = _addLiquidity(_amountALT);
        liquidity = mintLiquidityTokens(_owner, amountUSDH, amountAlt);
        user[_owner].tokenUSDH = user[_owner].tokenUSDH.add(amountUSDH);
        user[_owner].LPTokensAmount = user[_owner].LPTokensAmount.add(liquidity);
        calcNewReserveAddLiquidity(amountUSDH, amountAlt);
    }

    function _addLiquidity(uint256 _amountALT) private view returns (uint256 amountUSDH, uint256 amountALT, uint256 userLiquidityReward, uint256 stakeAmount, uint256 amountUSDHTotal) {
        if (reserveAltAmount == 0 && reserveUSDHAmount == 0) {
            uint256 _amountUSDHTotal = calculateUSDHMintAmount(_amountALT);
            // add token ratio:
            uint256 initialCalculation = _amountUSDHTotal.div(2);
            uint256 _amountUSDH = initialCalculation;
            uint256 _userLiquidityReward = (initialCalculation.mul(95)).div(100);
            uint256 _stakeAmount = (initialCalculation.mul(5)).div(100);
            
            (amountUSDH, amountALT) = (_amountUSDH, _amountALT);
            (userLiquidityReward, stakeAmount, amountUSDHTotal) = (_userLiquidityReward, _stakeAmount, _amountUSDHTotal);
        } else {
                uint256 amountUSDHQuote = quote(_amountALT, reserveAltAmount, reserveUSDHAmount);
                uint256 amountUSDHTotal_ = amountUSDHQuote.mul(2);
                
                uint256 initialCalculation = amountUSDHTotal_.div(2);
                uint256 _amountUSDH = initialCalculation;
                uint256 _userLiquidityReward = (initialCalculation.mul(95)).div(100);
                uint256 _stakeAmount = (initialCalculation.mul(5)).div(100);

                (amountUSDH, amountALT) = (_amountUSDH, _amountALT); // to avoid stack too deep error
                (userLiquidityReward, stakeAmount, amountUSDHTotal) = (_userLiquidityReward, _stakeAmount, amountUSDHTotal_);
            }
        }

    function removeLiquidity(address _maker) public override onlyFactory returns (uint256 amountUSDH, uint256 amountALT, uint256 amountUSDHUserBurn) {
        (amountUSDH, amountALT, amountUSDHUserBurn) = burn(_maker);
    }

    function getDetails() public override view returns(uint256, uint256, uint256) {
        return (initialRatio, reserveUSDHAmount, reserveAltAmount);
    }
    
    function getUser(address _user) public override view returns(uint256, uint256) {
        return (user[_user].tokenUSDH, user[_user].LPTokensAmount);
    }

    function burn(address to) private returns (uint256 amountUSDH, uint256 amountAlt, uint256 amountUSDHUserBurn) {
        uint256 balanceUSDH = IERC20(USDH__TOKEN).balanceOf(address(this));
        uint256 balanceAlt = IERC20(token).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];

        amountAlt = liquidity.mul(balanceAlt) / totalSupply;
        amountUSDH = liquidity.mul(balanceUSDH) / totalSupply;

        uint256 initialCalculation = (liquidity.mul(10000)).div(user[to].LPTokensAmount);
        amountUSDHUserBurn = (initialCalculation.mul(user[to].tokenUSDH)).div(10000);

        require(amountUSDH > 0 && amountAlt > 0, "Pool:: INSUFFICIENT_LIQUIDITY_BURNED");

        user[to].tokenUSDH = user[to].tokenUSDH.sub(amountUSDHUserBurn);
        user[to].LPTokensAmount = user[to].LPTokensAmount.sub(liquidity);

        _burn(address(this), liquidity);
        IERC20(USDH__TOKEN).burn(amountUSDH);
        IERC20(token).transfer(to, amountAlt);

        calcNewReserveRemoveLiquidity(amountUSDH, amountAlt);
    }

    function swapTokens(
        address _user,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _amountInAddress,
        address _amountOutAddress
    ) external override returns (uint256 result) {
        result = _swap(_amountIn, _amountInAddress);
        require(result >= _amountOutMin, "Swap: MINIMUM_AMOUNT_EXCEEDED");
        calcNewReserveSwap(_amountIn, result, _amountInAddress);

        IERC20(_amountOutAddress).transfer(_user, result);
    }

    function _swap(uint256 amountIn, address amountInAddress) internal view returns (uint256 amountQuote) {
        (uint256 amountInQ, uint256 reserveA, uint256 reserveB) =
            amountInAddress == USDH__TOKEN
                ? (amountIn, reserveUSDHAmount, reserveAltAmount)
                : (amountIn, reserveAltAmount, reserveUSDHAmount);

        amountQuote = quoteSwap(amountInQ, reserveA, reserveB);
    }

    function quoteSwap(uint256 _amountA, uint256 _reserveA, uint256 _reserveB) public pure returns (uint256 amountB) {
        require(_amountA > 0, "Pool:: INSUFFICIENT_AMOUNT");
        require(_reserveA > 0 && _reserveB > 0, "Pool:: INSUFFICIENT_LIQUIDITY");
        amountB = _amountA.mul(_reserveB).div(_reserveA);
        require(amountB < _reserveB, "Pool:: INSUFFICIENT_LIQUIDITY_REQUESTED");
    }

    function quote(uint256 _amountA, uint256 _reserveA, uint256 _reserveB) public pure returns (uint256 amountB) {
        require(_amountA > 0, "Pool:: INSUFFICIENT_AMOUNT");
        require(_reserveA > 0 && _reserveB > 0, "Pool:: INSUFFICIENT_LIQUIDITY");
        amountB = _amountA.mul(_reserveB).div(_reserveA);
    }

    function calculateUSDHMintAmount(uint256 amountALT) private view returns(uint256) {
        uint256 initialUSDHMintAmount = amountALT.mul(initialRatio);
        uint256 actualUSDHMintRatio = initialUSDHMintAmount.div(10**18);
        uint256 USDHMintAmount = actualUSDHMintRatio.mul(2);
        return USDHMintAmount;
    }

    function calcNewReserveAddLiquidity(uint256 amountUSDH, uint256 amountAlt) private {
        reserveUSDHAmount = reserveUSDHAmount.add(amountUSDH);
        reserveAltAmount = reserveAltAmount.add(amountAlt);
    }

    function calcNewReserveRemoveLiquidity(uint256 amountUSDH, uint256 amountAlt) private {
        reserveUSDHAmount = reserveUSDHAmount.sub(amountUSDH);
        reserveAltAmount = reserveAltAmount.sub(amountAlt);
    }

    function calcNewReserveSwap(uint256 amountIn, uint256 amountOut, address amountInAddress) private {
        if (amountInAddress == address(USDH__TOKEN)) {
            reserveUSDHAmount = reserveUSDHAmount.add(amountIn);
            reserveAltAmount = reserveAltAmount.sub(amountOut);
        } else {
            reserveUSDHAmount = reserveUSDHAmount.sub(amountOut);
            reserveAltAmount = reserveAltAmount.add(amountIn);
        }
    }

    function setRatio(uint256 _ratio) public override onlyFactory {
        initialRatio = _ratio;
    }

    function mintLiquidityTokens(
        address _to,
        uint256 _USDHAmount,
        uint256 _altAmount
    ) private returns (uint256 liquidity) {
        if (totalSupply == 0) {
            liquidity = SafeMath.sqrt(_USDHAmount.mul(_altAmount)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = SafeMath.min(
                _USDHAmount.mul(totalSupply) / reserveUSDHAmount,
                _altAmount.mul(totalSupply) / reserveAltAmount
            );
        }
        require(liquidity > 0, "Pool:: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(_to, liquidity);
    }
}

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

contract HedgeFactory is Pool, Ownable {
    using SafeMath for uint256;
    using Address for address;

    address public constant USDH_TOKEN = 0x11840Cc5A565Eb1006faF8cF41D960c76e00A022;
    address public constant STAKING_CONTRACT = 0x54D7b8dc548F4C3Eab3952C05f6d450FecEBe3a2;

    mapping(address => address) public pools;

    event PoolCreated(address pair, address token, uint256 initialRatio);
    event LiquidityAdded(address token, address pair, address indexed owner, uint256 amountALT, uint256 amountUSDH, uint256 liquidity);
    event LiquidityRemoved(address pair, address indexed owner, uint256 amountALT, uint256 amountUSDH, uint256 amountUserUSDHBurn, uint256 liquidity);
    event Swap(address sender, uint256 amountIn, uint256 amountOut, address pair, address amountInAddress, address amountOutAddress);

    function createPool(address token, uint256 ratio) external onlyOwner returns(address pair) {
        require(token != address(0), "createPool: Invalid Token address");
        require(pools[token] == address(0), "createPool: Pool already exist");
        bytes memory bytecode = type(Pool).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(block.timestamp, msg.sender));
        pair = Create2.deploy(0, salt, bytecode);
        pools[token] = pair;        
        IPool(pair).initialize(token);
        IPool(pair).setRatio(ratio);
        emit PoolCreated(pair, token, ratio);
    }

    function addLiquidityInPool(uint256 amountALT, address _token) public {
        address owner = msg.sender;
        address pair = pools[_token];

        require(pair != address(0), "addLiquidity: Pool does not exist");
        require(amountALT > 0, "addLiquidity: Please enter valid amount");

        (uint256 _amountUSDH, uint256 amountAlt, uint256 liquidity, uint256 userLiquidityReward, uint256 stakeAmount, uint256 amountUSDHTotal) = IPool(pair).addLiquidity(
            amountALT,
            owner
        );

        IERC20(USDH_TOKEN).mint(address(this), amountUSDHTotal);
        IERC20(_token).transferFrom(owner, address(this), amountAlt);

        IERC20(_token).transfer(pair, amountAlt);
        IERC20(USDH_TOKEN).transfer(pair, _amountUSDH);
        
        IERC20(USDH_TOKEN).transfer(owner, userLiquidityReward);
        IERC20(USDH_TOKEN).transfer(address(STAKING_CONTRACT), stakeAmount);

        emit LiquidityAdded(_token, pair, owner, amountAlt, _amountUSDH, liquidity);
    }

    function swap(address token, uint256 amountIn, uint256 amountOutMin, address amountInAddress, address amountOutAddress) public returns(uint256 result) {
        address user = msg.sender;
        address pair = pools[token];

        require(pair != address(0), "Swap: POOL_DOESNT_EXIST");
        require(amountIn > 0, "Swap: INVALID_AMOUNT_IN");

        IERC20(amountInAddress).transferFrom(user, address(this), amountIn);
        IERC20(amountInAddress).transfer(pair, amountIn);

        result = IPool(pair).swapTokens(user, amountIn, amountOutMin, amountInAddress, amountOutAddress);

        emit Swap(user, amountIn, result, pair, amountInAddress, amountOutAddress);
    }

    function removeLiquidityInPool(uint256 USDHAmount, uint256 liquidity, address token) public {
        address owner = msg.sender;
        address pair = pools[token];

        require(pair != address(0), "removeLiquidity: Pool does not exist");

        IERC20(pair).transferFrom(owner, address(this), liquidity);
        IERC20(USDH_TOKEN).transferFrom(owner, address(this), USDHAmount);
        IERC20(pair).transfer(pair, liquidity);

        (uint256 amountUSDH, uint256 amountAlt, uint256 amountUserUSDHBurn) = IPool(pair).removeLiquidity(owner);

        require(amountUserUSDHBurn <= USDHAmount, "removeLiquidity: INVALID_USDH_CLAIM");

        IERC20(USDH_TOKEN).burn(amountUserUSDHBurn);

        emit LiquidityRemoved(pair, owner, amountAlt, amountUSDH, amountUserUSDHBurn,liquidity);
    }

    function getDetails(address _poolAddress) external view returns(uint256, uint256, uint256) {
        return IPool(_poolAddress).getDetails();
    }

    function getUsers(address _poolAddress, address _user) external view returns(uint256, uint256) {
        return IPool(_poolAddress).getUser(_user);
    }
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IUSDHReceiver {
    function receiveUSDH(
        bytes32 _id,
        uint256 _amountIn,
        uint256 _expireAfter,
        uint256 _mintedAmount,
        address _staker,
        bytes calldata _data
    ) external returns (uint256);
}