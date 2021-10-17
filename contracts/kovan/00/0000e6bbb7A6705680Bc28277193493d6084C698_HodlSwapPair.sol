// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import './interfaces/IHodlSwapPair.sol';
import './HodlSwapERC20.sol';
import './libraries/Math.sol';
import './interfaces/IERC20.sol';
import './interfaces/IHodlSwapCallee.sol';

contract HodlSwapPair is IHodlSwapPair, HodlSwapERC20 {

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    uint private constant FEE_SWAP_PRECISION = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;
    // pair swap fee as parts per FEE_SWAP_PRECISION
    uint public feeSwap;

    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint private locked; // reenterance lock
    struct Slot0 {
        uint104 reserve0;
        uint104 reserve1;
        // pair protocol fee as a percentage of the swap fee in form simple fracton:
        // negative - fees turned off, 0 - 1, 1 - 1/2, 2 - 1/3, 3 - 1/4 etc
        int8 feeProtocol;
    }
    Slot0 private slot0; // uses single storage slot

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
    event Sync(uint reserve0, uint reserve1);
    event SetFeeProtocol(int8 feeProtocol);

    modifier lock() {
        require(locked == 0, 'HodlSwap: LOCKED');
        locked = 1;
        _;
        locked = 0;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, 'HodlSwap: FORBIDDEN');
        _;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1, uint _feeSwap, int8 _feeProtocol)
        external
    {
        require(factory == address(0), "HodlSwap: FORBIDDEN");
        factory = msg.sender;
        token0 = _token0;
        token1 = _token1;
        feeSwap = _feeSwap;
        slot0.feeProtocol = _feeProtocol;
        emit SetFeeProtocol(_feeProtocol);
    }

    function setFeeProtocol(int8 _feeProtocol)
        external onlyFactory
    {
        require(slot0.feeProtocol != _feeProtocol);
        slot0.feeProtocol = _feeProtocol;
        emit SetFeeProtocol(_feeProtocol);
    }


    function _safeTransfer(address token, address to, uint value)
        private
    {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'HodlSwap: TRANSFER_FAILED');
    }

    function _getReserves()
        private view returns (Reserves memory _reserves)
    {
        (_reserves.reserve0, _reserves.reserve1) = (slot0.reserve0, slot0.reserve1); //gas savings
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1)
        private
    {
        require(balance0 <= type(uint104).max && balance1 <= type(uint104).max, 'HodlSwap: OVERFLOW');
        (slot0.reserve0, slot0.reserve1) = (uint104(balance0), uint104(balance1)); //gas savings
    }

    // if fee is on, mint liquidity equivalent to 1/(feeProtocol+1)th of the growth in sqrt(k) to factory address
    function _mintFee(uint _reserve0, uint _reserve1, uint _kLast, int8 _feeProtocol)
        private
    {
        uint rootK = Math.sqrt(_reserve0 * _reserve1);
        uint rootKLast = Math.sqrt(_kLast);
        if (rootK > rootKLast) {
            uint numerator = totalSupply * (rootK - rootKLast);
            uint denominator = rootK * uint8(_feeProtocol) + rootKLast;
            uint liquidity = numerator / denominator;
            if (liquidity > 0) {
                _mint(factory, liquidity);
            }
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to)
        external lock returns (uint liquidity)
    {
        Reserves memory _reserves = _getReserves(); // gas savings
        (uint balance0, uint balance1) = (
            IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this))
        ); // gas savings
        uint amount0 = balance0 - _reserves.reserve0;
        uint amount1 = balance1 - _reserves.reserve1;

        uint _kLast = kLast; // gas savings
        int8 _feeProtocol = slot0.feeProtocol; // gas savings
        if (_kLast != 0) {
            if (_feeProtocol >= 0) _mintFee(_reserves.reserve0, _reserves.reserve1, _kLast, _feeProtocol);
            else kLast = 0;
        }
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0 * _totalSupply / _reserves.reserve0, amount1 * _totalSupply / _reserves.reserve1);
        }
        require(liquidity > 0, 'HodlSwap: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1);
        if (_feeProtocol >= 0) kLast = balance0 * balance1;
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to)
        external lock returns (uint amount0, uint amount1)
    {
        Reserves memory _reserves = _getReserves(); // gas savings
        uint liquidity = balanceOf[address(this)];

        uint _kLast = kLast; // gas savings
        int8 _feeProtocol = slot0.feeProtocol; // gas savings
        if (_kLast != 0) {
            if (_feeProtocol >= 0) _mintFee(_reserves.reserve0, _reserves.reserve1, _kLast, _feeProtocol);
            else kLast = 0;
        }
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity * _reserves.reserve0 / _totalSupply; 
        amount1 = liquidity * _reserves.reserve1 / _totalSupply; 
        require(amount0 > 0 && amount1 > 0, 'HodlSwap: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(token0, to, amount0);
        _safeTransfer(token1, to, amount1);
        _reserves.reserve0 -= amount0;
        _reserves.reserve1 -= amount1;

        (slot0.reserve0, slot0.reserve1) = (uint104(_reserves.reserve0), uint104(_reserves.reserve1));
        if (_feeProtocol >= 0) kLast = _reserves.reserve0 * _reserves.reserve1;
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data)
        external lock
    {
        require(amount0Out > 0 || amount1Out > 0, 'HodlSwap: INSUFFICIENT_OUTPUT_AMOUNT');
        Reserves memory _reserves = _getReserves(); // gas savings
        require(amount0Out < _reserves.reserve0 && amount1Out < _reserves.reserve1, 'HodlSwap: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        require(to != token0 && to != token1, 'HodlSwap: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(token1, to, amount1Out); // optimistically transfer tokens
        if (data.length > 0) IHodlSwapCallee(to).hodlswapCall(msg.sender, amount0Out, amount1Out, data);
        (balance0, balance1) = (
            IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this))
        ); // gas savings
        uint amount0In = balance0 > _reserves.reserve0 - amount0Out ? balance0 - (_reserves.reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserves.reserve1 - amount1Out ? balance1 - (_reserves.reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'HodlSwap: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = balance0 * FEE_SWAP_PRECISION - amount0In * feeSwap;
        uint balance1Adjusted = balance1 * FEE_SWAP_PRECISION - amount1In * feeSwap;
        require(balance0Adjusted * balance1Adjusted >= _reserves.reserve0 * _reserves.reserve1 * FEE_SWAP_PRECISION**2, 'HodlSwap: K');
        }
        _update(balance0, balance1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to)
        external lock
    {
        Reserves memory _reserves = _getReserves(); // gas savings
        _safeTransfer(token0, to, IERC20(token0).balanceOf(address(this)) - _reserves.reserve0);
        _safeTransfer(token1, to, IERC20(token1).balanceOf(address(this)) - _reserves.reserve1);
    }

    // force reserves to match balances
    function sync()
        external lock
    {
        (uint balance0, uint balance1) = (
            IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this))
        ); // gas savings
        _update(balance0, balance1);
        emit Sync(balance0, balance1);
    }

    function getReserves()
        external view returns (Reserves memory _reserves)
    {
        return _getReserves();
    }    

    function feeProtocol() 
        external view returns (int8)
    {
        return slot0.feeProtocol;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

interface IHodlSwapCallee {
    function hodlswapCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

interface IERC20 {
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import './interfaces/IHodlSwapERC20.sol';

contract HodlSwapERC20 is IHodlSwapERC20 {

    string public constant name = 'HodlSwapLp';
    string public constant symbol = 'hslp';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() {
        uint chainId;
        assembly {
            chainId := chainid()
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
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] -= value;
        totalSupply -= value;
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] -= value;
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'HodlSwap: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'HodlSwap: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;
import './IHodlSwapERC20.sol';

interface IHodlSwapPair is IHodlSwapERC20 {
    struct Reserves {
        uint reserve0;
        uint reserve1;
    }

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (Reserves memory _reserves);
    function kLast() external view returns (uint);
    function feeSwap() external view returns (uint);
    function feeProtocol() external view returns (int8);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address _token0, address _token1, uint _feeSwap, int8 _feeProtocol) external;
    function setFeeProtocol(int8 _feeProtocol) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

interface IHodlSwapERC20 {
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