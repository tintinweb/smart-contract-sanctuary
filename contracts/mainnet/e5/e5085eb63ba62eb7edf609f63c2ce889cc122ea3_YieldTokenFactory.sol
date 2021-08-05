/**
 *Submitted for verification at Etherscan.io on 2021-01-18
*/

// Sources flattened with hardhat v2.0.6 https://hardhat.org

// File contracts/uniswapv2/libraries/TransferHelper.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// File contracts/interfaces/IERC20.sol


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // EIP 2612
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}


// File contracts/uniswapv2/libraries/SafeMath.sol



// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUniswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}


// File contracts/uniswapv2/interfaces/IUniswapV2Pair.sol



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


// File contracts/uniswapv2/interfaces/IUniswapV2ERC20.sol



interface IUniswapV2ERC20 {
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
}


// File contracts/SushiYieldToken.sol






contract SushiYieldToken {
    using SafeMathUniswap for uint256;
    using TransferHelper for address;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed sender, uint256 amount);
    event Burn(address indexed sender, uint256 amount, address indexed to);

    /**
     * @return address of YieldTokenFactory
     */
    address public factory;
    /**
     * @return address of lp token
     */
    address public lpToken;
    /**
     * @return data to be used when `mint`ing/`burn`ing
     */
    bytes public data;

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "locked");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() public {
        factory = msg.sender;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function initialize(address _lpToken, bytes memory _data) external {
        require(msg.sender == factory, "forbidden");
        lpToken = _lpToken;
        data = _data;

        IUniswapV2Pair pair = IUniswapV2Pair(lpToken);
        string memory symbol0 = IUniswapV2ERC20(pair.token0()).symbol();
        string memory symbol1 = IUniswapV2ERC20(pair.token1()).symbol();
        name = string(abi.encodePacked(symbol0, "-", symbol1, " SushiSwap Yield Token"));
        symbol = string(abi.encodePacked(symbol0, "-", symbol1, " SYD"));
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint256 value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
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
        require(deadline >= block.timestamp, "expired");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "invalid-signature");
        _approve(owner, spender, value);
    }

    function mint(address to) external lock returns (uint256 amount) {
        amount = IUniswapV2ERC20(lpToken).balanceOf(address(this));
        require(amount > 0, "insufficient-balance");

        (bool success,) = factory.delegatecall(abi.encodeWithSignature("deposit(bytes,uint256,address)", data, amount, to));
        require(success, "failed-to-deposit");

        _mint(to, amount);

        emit Mint(msg.sender, amount);
    }

    function burn(address to) external lock returns (uint256 amount) {
        amount = balanceOf[address(this)];
        require(amount > 0, "insufficient-balance");

        (bool success,) = factory.delegatecall(abi.encodeWithSignature("withdraw(bytes,uint256,address)", data, amount, to));
        require(success, "failed-to-withdraw");

        _burn(address(this), amount);

        emit Burn(msg.sender, amount, to);
    }
}


// File contracts/YieldTokenFactory.sol





interface IMasterChef {
    struct PoolInfo {
        address lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accSushiPerShare;
    }

    function sushi() external view returns (address);

    function poolInfo(uint256 index) external view returns (
        address lpToken,
        uint256 allocPoint,
        uint256 lastRewardBlock,
        uint256 accSushiPerShare
    );

    function deposit(uint256 pid, uint256 amount) external;

    function withdraw(uint256 pid, uint256 amount) external;
}

contract YieldTokenFactory {
    using TransferHelper for address;

    event YieldTokenCreated(uint256 pid, address token);

    /**
     * @return address of `MasterChef`
     */
    address public masterChef;

    /**
     * @return address of `SushiToken`
     */
    address public sushi;

    /**
     * @return address of `SushiYieldToken` for `pid`
     */
    mapping(uint256 => address) public getYieldToken;

    constructor(address _masterChef) public {
        masterChef = _masterChef;
        sushi = IMasterChef(_masterChef).sushi();
    }

    /**
     * @return init hash of `SushiYieldToken`
     */
    function yieldTokenCodeHash() external pure returns (bytes32) {
        return keccak256(type(SushiYieldToken).creationCode);
    }

    /**
     * @notice create a new `SushiYieldToken` for `pid`
     *
     * @return token created token's address
     */
    function createYieldToken(uint256 pid) external returns (address token) {
        require(getYieldToken[pid] == address(0), "already-created");

        bytes memory bytecode = type(SushiYieldToken).creationCode;
        bytes memory data = abi.encode(masterChef, pid);
        bytes32 salt = keccak256(data);
        assembly {
            token := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        (address lpToken,,,) = IMasterChef(masterChef).poolInfo(pid);
        SushiYieldToken(token).initialize(lpToken, data);
        getYieldToken[pid] = token;

        emit YieldTokenCreated(pid, token);
    }

    /**
     * @notice deposit lp token (meant to be `delegatecall`ed by `SushiYieldToken`)
     *
     * @param data encoded `pid`
     * @param amount amount of lp tokens
     * @param to receiver of sushi rewards
     */
    function deposit(bytes memory data, uint256 amount, address to) external {
        (address _masterChef, uint256 pid) = abi.decode(data, (address, uint256));
        (address lpToken,,,) = IMasterChef(_masterChef).poolInfo(pid);
        lpToken.safeApprove(_masterChef, amount);
        IMasterChef(_masterChef).deposit(pid, amount);
        _transferBalance(sushi, to);
    }

    /**
     * @notice withdraw lp tokens (meant to be `delegatecall`ed by `SushiYieldToken`)
     *
     * @param data encoded `pid`
     * @param amount amount of lp tokens
     * @param to receiver of lp tokens
     */
    function withdraw(bytes memory data, uint256 amount, address to) external {
        (address _masterChef, uint256 pid) = abi.decode(data, (address, uint256));
        (address lpToken,,,) = IMasterChef(_masterChef).poolInfo(pid);
        IMasterChef(_masterChef).withdraw(pid, amount);
        _transferBalance(lpToken, to);
        _transferBalance(sushi, to);
    }

    function _transferBalance(address token, address to) internal {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            token.safeTransfer(to, balance);
        }
    }
}