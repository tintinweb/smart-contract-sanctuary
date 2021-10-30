pragma solidity >=0.6.0 <0.9.0;

import './libraries/TransferHelper.sol';
import './interfaces/IRainbowFactory.sol';
import './interfaces/IUniFaucet.sol';
import './interfaces/IRainbowStake.sol';
import './RainbowStake.sol';
import './interfaces/IRainbowERC20.sol';
import './interfaces/IERC20.sol';
import './libraries/SafeMath.sol';

contract UniFaucet is IUniFaucet {
    using SafeMath for uint;

    address public immutable override factory;
    address public immutable feeTo; // Where to send the fees
    uint public immutable feeAmount;

    constructor(address _factory, address _feeTo, uint _feeAmount) {
        factory = _factory;
        feeTo   = _feeTo;
        feeAmount = _feeAmount;
    }

    function createLiquidityStake(address tokenA) public returns (address) {
        address stake = IRainbowFactory(factory).getStake(tokenA);
        require(stake == address(0), "UniFaucet: STAKE ALREADY EXISTS");
        stake = IRainbowFactory(factory).createStake(tokenA);
        return stake;
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(address tokenA, uint liquidity, address to) public override returns (uint amountA) {
        address stake = IRainbowFactory(factory).getStake(tokenA);

        RainbowStake(stake).transferFrom(msg.sender, stake, liquidity); // send liquidity to pair for burning
        amountA = RainbowStake(stake).burn(to);
    }

    // Require fee on use
    function drip(address token, address to) public payable override returns (uint amount) {
        require(msg.value >= feeAmount, "Must send Wei");

        address stake = IRainbowFactory(factory).getStake(token);
        IRainbowStake(stake).drip(to, amount);
        TransferHelper.safeTransferETH(feeTo, msg.value);
    }

    function getAvailableSpend(address token) public view override returns (uint spend) {
        address stake = IRainbowFactory(factory).getStake(token);
        require(stake != address(0), "UniFaucet: STAKE_DOES_NOT_EXIST");

        uint _totalSupply = IERC20(token).balanceOf(stake);
        uint _reserves = IRainbowStake(stake).getReserve();
        spend = _totalSupply.sub(_reserves);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

pragma solidity>=0.5.16;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "ds-math-div-overflow");
        uint256 c = a / b;
        return c;
    }
}

pragma solidity>=0.5.16;

// a library for performing various math operations

library Math {
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

pragma solidity >=0.6.2;

interface IUniFaucet {
    function factory() external view returns (address);
    function removeLiquidity(address tokenA, uint liquidity, address to) external returns (uint amountA);
    function drip(address token, address to) payable external returns (uint amount);
    function getAvailableSpend(address token) view external returns (uint spend);
}

pragma solidity >=0.5.0;

interface IRainbowStake {
    event Mint(address indexed sender, uint amount0);
    event Burn(address indexed sender, uint amount0, address indexed to);
    event Drip(address indexed to, uint amount);
    event Sync(uint reserve0);

    function factory() external view returns (address);
    function token0() external view returns (address);
    function getReserve() external view returns (uint reserve0);
    function addLiquidity(address tokenA, uint amountA, address to) external;
    function burn(address to) external returns (uint amount0);
    function drip(address to, uint amount) external;
    function initialize(address) external;
}

pragma solidity >=0.5.0;

interface IRainbowFactory {
    event StakeCreated(address indexed token0, address stake, uint);

    function getStake(address tokenA) external view returns (address stake);
    function allStakes(uint) external view returns (address stake);
    function allStakesLength() external view returns (uint);

    function createStake(address tokenA) external returns (address stake);
}

pragma solidity >=0.5.0;

interface IRainbowERC20 {
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

pragma solidity >=0.5.0;

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
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

pragma solidity >=0.6.0 <0.9.0;

import './interfaces/IRainbowStake.sol';
import './RainbowERC20.sol';
import './libraries/Math.sol';
import './interfaces/IERC20.sol';
import './interfaces/IRainbowFactory.sol';
import './libraries/TransferHelper.sol';

contract RainbowStake is IRainbowStake, RainbowERC20 {
    using SafeMath for uint;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public override factory;
    address public override token0;

    uint    private reserve0;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'RainbowFaucet: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0) external override {
        require(msg.sender == factory, 'RainbowFaucet: FORBIDDEN'); // sufficient check
        token0 = _token0;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'RainbowFaucet: TRANSFER_FAILED');
    }

    function getReserve() public view override returns (uint _reserve0) {
        _reserve0 = reserve0;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0) private {
        require(balance0 <= 2**256 - 1, "RainbowStake: OVERFLOW");
        reserve0 = balance0;
        emit Sync(reserve0);
    }

    function addLiquidity(address tokenA, uint amountA, address to) external override lock {
        // See Optimiziation:  https://github.com/Uniswap/v2-periphery/blob/dda62473e2da448bc9cb8f4514dadda4aeede5f4/contracts/libraries/UniswapV2Library.sol#L18
        uint _balanceBeforeTransfer = IERC20(token0).balanceOf(address(this));
        TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), amountA);
        uint _balanceAfterTransfer = IERC20(token0).balanceOf(address(this));

        uint _liquidity = _balanceAfterTransfer.sub(_balanceBeforeTransfer);
        require(_liquidity > 0, 'RainbowStake: INSUFFICIENT_LIQUIDITY_MINTED');

        mint(to, _liquidity);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to, uint _liquidity) private {
        uint _reserve = getReserve();
        _mint(to, _liquidity);
        _update(_reserve.add(_liquidity)); // Update reserve only by minted amount

        emit Mint(msg.sender, _liquidity);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock override returns (uint) {
        require(getReserve() > 0, 'UniFaucet: CANNOT_BURN_NO_LIQUIDITY');
        address _token = token0;
        uint liquidity = balanceOf[address(this)]; // Num LP Tokens
        require(liquidity > 0, 'UniFaucet: INSUFFICIENT_LIQUIDITY_BURNED');

        _burn(address(this), liquidity);
        _safeTransfer(_token, to, liquidity);

        uint _reserve = getReserve();
        _update(_reserve.sub(liquidity));
        emit Burn(msg.sender, liquidity, to);
        return liquidity;
    }

    function drip(address to, uint amount) external override {
        uint _balance = IERC20(token0).balanceOf(address(this)); // Should be more than staked amount
        uint reflection = _balance.sub(getReserve());
        require(reflection > 0, "UniFaucet: NO REFLECTION AVAILABLE");
        amount = reflection.mul(1) / 100;

        IERC20(token0).transfer(to, amount);
        emit Drip(to, amount);
    }
}

pragma solidity>=0.5.16;

import './interfaces/IRainbowERC20.sol';
import './libraries/SafeMath.sol';

contract RainbowERC20 is IRainbowERC20 {
    using SafeMath for uint;

    string public constant override name = 'RainbowStake';
    string public constant override symbol = 'RNBW';
    uint8 public constant override decimals = 18;
    uint  public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public override nonces;

    constructor() {
        uint chainId;
        assembly {
            chainId := chainid() // Added parens??
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        if (allowance[from][msg.sender] != uint(2**256 - 1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external override {
        require(deadline >= block.timestamp, 'RainbowERC: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'RainbowERC: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}