/**
 *Submitted for verification at Etherscan.io on 2021-01-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
}


pragma solidity 0.6.12;

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


pragma solidity 0.6.12;

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

    function unstake(bytes32 _id)
        external
        returns (uint256 withdrawAmount);

    function getFPY(uint256 _amountIn) external view returns (uint256);
}


pragma solidity 0.6.12;

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

    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


pragma solidity 0.6.12;

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
}



pragma solidity ^0.6.0;

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
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address) {
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
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint256(_data));
    }
}


pragma solidity 0.6.12;

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


pragma solidity 0.6.12;



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

    // bytes32 private constant VERSION_HASH = keccak256("1")
    bytes32 private constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

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
    ) external {
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

// File: ../../../../media/shakeib98/xio-flashapp-contracts/contracts/pool/contracts/Pool.sol

pragma solidity 0.6.12;






contract Pool is PoolERC20, IPool {
    using SafeMath for uint256;

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant TRANSFER_SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    address public constant FLASH_TOKEN = 0xB4467E8D621105312a914F1D42f10770C0Ffe3c8;
    address public constant FLASH_PROTOCOL = 0xEc02f813404656E2A2AEd5BaeEd41D785324E8D0;

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

    constructor() public {
        factory = msg.sender;
    }

    function _safeTransfer(
        address _token,
        address _to,
        uint256 _value
    ) private {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(TRANSFER_SELECTOR, _to, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Pool:: TRANSFER_FAILED");
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
        _safeTransfer(FLASH_TOKEN, _staker, result);
    }

    function stakeWithFeeRewardDistribution(
        uint256 _amountIn,
        address _staker,
        uint256 _expectedOutput
    ) public override lock onlyFactory returns (uint256 result) {
        result = getAPYStake(_amountIn);
        require(_expectedOutput <= result, "Pool:: EXPECTED_IS_GREATER");
        calcNewReserveStake(_amountIn, result);
        _safeTransfer(token, _staker, result);
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

        _safeTransfer(FLASH_TOKEN, to, amountFLASH);
        _safeTransfer(token, to, amountALT);

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


pragma solidity 0.6.12;









contract FlashApp is IFlashReceiver {
    using SafeMath for uint256;

    address public constant FLASH_TOKEN = 0xB4467E8D621105312a914F1D42f10770C0Ffe3c8;
    address public constant FLASH_PROTOCOL = 0xEc02f813404656E2A2AEd5BaeEd41D785324E8D0;

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
        IERC20(FLASH_TOKEN).transfer(pool, _mintedAmount);
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

        IERC20(_token).transferFrom(user, address(this), _altQuantity);
        IERC20(_token).transfer(pool, _altQuantity);

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

        IERC20(FLASH_TOKEN).transferFrom(maker, address(this), amountFLASH);
        IERC20(FLASH_TOKEN).transfer(pool, amountFLASH);
        IERC20(_token).transferFrom(maker, address(this), amountALT);
        IERC20(_token).transfer(pool, amountALT);

        emit LiquidityAdded(pool, amountFLASH, amountALT, liquidity, maker);
    }

    function removeLiquidityInPool(uint256 _liquidity, address _token) public {
        address maker = msg.sender;

        address pool = pools[_token];

        require(pool != address(0), "FlashApp:: POOL_DOESNT_EXIST");

        IERC20(pool).transferFrom(maker, address(this), _liquidity);
        IERC20(pool).transfer(pool, _liquidity);

        (uint256 amountFLASH, uint256 amountALT) = IPool(pool).removeLiquidity(maker);

        emit LiquidityRemoved(pool, amountFLASH, amountALT, _liquidity, maker);
    }
}