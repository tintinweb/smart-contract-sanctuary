pragma solidity ^0.6.4;

interface IERC20 {
    event Approval(address indexed _src, address indexed _dst, uint _amount);
    event Transfer(address indexed _src, address indexed _dst, uint _amount);

    function totalSupply() external view returns (uint);
    function balanceOf(address _whom) external view returns (uint);
    function allowance(address _src, address _dst) external view returns (uint);

    function approve(address _dst, uint _amount) external returns (bool);
    function transfer(address _dst, uint _amount) external returns (bool);
    function transferFrom(
        address _src, address _dst, uint _amount
    ) external returns (bool);
}
// File: localhost/contracts/interfaces/IWETH.sol

// File: @emilianobonassi/gas-saver/ChiGasSaver.sol

pragma solidity ^0.6.0;

interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns(uint256 freed);
}

contract ChiGasSaver {

    modifier saveGas(address payable sponsor) {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;

        IFreeFromUpTo chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
        chi.freeFromUpTo(sponsor, (gasSpent + 14154) / 41947);
    }
}

// File: localhost/contracts/Ownable.sol

pragma solidity 0.6.4;

// TODO move this generic contract to a seperate repo with all generic smart contracts

contract Ownable {

    bytes32 constant public oSlot = keccak256("Ownable.storage.location");

    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    // Ownable struct
    struct os {
        address owner;
    }

    modifier onlyOwner(){
        require(msg.sender == los().owner, "Ownable.onlyOwner: msg.sender not owner");
        _;
    }

    /**
        @notice Transfer ownership to a new address
        @param _newOwner Address of the new owner
    */
    function transferOwnership(address _newOwner) onlyOwner external {
        _setOwner(_newOwner);
    }

    /**
        @notice Internal method to set the owner
        @param _newOwner Address of the new owner
    */
    function _setOwner(address _newOwner) internal {
        emit OwnerChanged(los().owner, _newOwner);
        los().owner = _newOwner;
    }

    /**
        @notice Load ownable storage
        @return s Storage pointer to the Ownable storage struct
    */
    function los() internal pure returns (os storage s) {
        bytes32 loc = oSlot;
        assembly {
            s_slot := loc
        }
    }

}
// File: localhost/contracts/interfaces/ISmartPoolRegistry.sol

pragma solidity 0.6.4;

interface ISmartPoolRegistry {
    function inRegistry(address _pool) external view returns(bool);
    function entries(uint256 _index) external view returns(address);
    function addSmartPool(address _smartPool) external;
    function removeSmartPool(uint256 _index) external;
}
// File: localhost/contracts/interfaces/IUniswapV2Exchange.sol

interface IUniswapV2Exchange {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
// File: localhost/contracts/interfaces/IUniswapV2Factory.sol

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
// File: localhost/contracts/interfaces/IPSmartPool.sol

pragma solidity ^0.6.4;

interface IPSmartPool is IERC20 {
    function joinPool(uint256 _amount) external;
    function exitPool(uint256 _amount) external;
    function getController() external view returns(address);
    function getTokens() external view returns(address[] memory);
    function calcTokensForAmount(uint256 _amount) external view  returns(address[] memory tokens, uint256[] memory amounts);
}
// File: localhost/contracts/recipes/LibSafeApproval.sol



library LibSafeApprove {
    function safeApprove(IERC20 _token, address _spender, uint256 _amount) internal {
        uint256 currentAllowance = _token.allowance(address(this), _spender);

        // Do nothing if allowance is already set to this value
        if(currentAllowance == _amount) {
            return;
        }

        // If approval is not zero reset it to zero first
        if(currentAllowance != 0) {
            _token.approve(_spender, 0);
        }

        // do the actual approval
        _token.approve(_spender, _amount);
    }
}
// File: localhost/contracts/recipes/SafeMath.sol


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
}
// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

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

// File: localhost/contracts/recipes/UniLib.sol

pragma solidity >=0.5.0;



library UniLib {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniLib: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniLib: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniLib: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniLib: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniLib: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniLib: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniLib: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniLib: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniLib: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniLib: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}
// File: localhost/contracts/interfaces/IERC20.sol




interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}
// File: localhost/contracts/recipes/UniswapV2Recipe.sol

pragma solidity 0.6.4;










contract UniswapV2Recipe is Ownable, ChiGasSaver {
    using LibSafeApprove for IERC20;

    IWETH constant public WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IUniswapV2Factory constant uniswapFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    ISmartPoolRegistry constant public registry = ISmartPoolRegistry(0x412a5d5eC35fF185D6BfF32a367a985e1FB7c296);
    address payable public constant gasSponsor = 0x3bFdA5285416eB06Ebc8bc0aBf7d105813af06d0;
    bool private isPaused = false;
    
    // Pauzer
    modifier revertIfPaused {
        if (isPaused) {
            revert("[UniswapV2Recipe] is Paused");
        } else {
            _;
        }
    }
    
    function togglePause() public onlyOwner {
        isPaused = !isPaused;
    }

    constructor() public {
        _setOwner(msg.sender);
    }

    // Max eth amount enforced by msg.value
    function toPie(address _pie, uint256 _poolAmount) external payable revertIfPaused saveGas(gasSponsor) {
        require(registry.inRegistry(_pie), "Not a Pie");
        uint256 totalEth = calcToPie(_pie, _poolAmount);
        require(msg.value >= totalEth, "Amount ETH too low");

        WETH.deposit{value: totalEth}();

        _toPie(_pie, _poolAmount);

        // return excess ETH
        if(address(this).balance != 0) {
            // Send any excess ETH back
            msg.sender.transfer(address(this).balance);
        }

        // Transfer pool tokens to msg.sender
        IERC20 pie = IERC20(_pie);

        IERC20(pie).transfer(msg.sender, pie.balanceOf(address(this)));
    }

    function _toPie(address _pie, uint256 _poolAmount) internal {
        (address[] memory tokens, uint256[] memory amounts) = IPSmartPool(_pie).calcTokensForAmount(_poolAmount);

        for(uint256 i = 0; i < tokens.length; i++) {
            if(registry.inRegistry(tokens[i])) {
                _toPie(tokens[i], amounts[i]);
            } else {
                IUniswapV2Exchange pair = IUniswapV2Exchange(UniLib.pairFor(address(uniswapFactory), tokens[i], address(WETH)));

                (uint256 reserveA, uint256 reserveB) = UniLib.getReserves(address(uniswapFactory), address(WETH), tokens[i]);
                uint256 amountIn = UniLib.getAmountIn(amounts[i], reserveA, reserveB);

                // UniswapV2 does not pull the token
                WETH.transfer(address(pair), amountIn);

                if(token0Or1(address(WETH), tokens[i]) == 0) {
                    pair.swap(amounts[i], 0, address(this), new bytes(0));
                } else {
                    pair.swap(0, amounts[i], address(this), new bytes(0));
                }
            }

            IERC20(tokens[i]).safeApprove(_pie, amounts[i]);
        }

        IPSmartPool pie = IPSmartPool(_pie);
        pie.joinPool(_poolAmount);
    }

    function calcToPie(address _pie, uint256 _poolAmount) public view returns(uint256) {
        (address[] memory tokens, uint256[] memory amounts) = IPSmartPool(_pie).calcTokensForAmount(_poolAmount);

        uint256 totalEth = 0;

        for(uint256 i = 0; i < tokens.length; i++) {
            if(registry.inRegistry(tokens[i])) {
                totalEth += calcToPie(tokens[i], amounts[i]);
            } else {
                (uint256 reserveA, uint256 reserveB) = UniLib.getReserves(address(uniswapFactory), address(WETH), tokens[i]);
                totalEth += UniLib.getAmountIn(amounts[i], reserveA, reserveB);
            }
        }

        return totalEth;
    }


    // TODO recursive exit
    function toEth(address _pie, uint256 _poolAmount, uint256 _minEthAmount) external revertIfPaused saveGas(gasSponsor) {
        uint256 totalEth = calcToPie(_pie, _poolAmount);
        require(_minEthAmount <= totalEth, "Output ETH amount too low");
        IPSmartPool pie = IPSmartPool(_pie);

        (address[] memory tokens, uint256[] memory amounts) = IPSmartPool(_pie).calcTokensForAmount(_poolAmount);
        pie.transferFrom(msg.sender, address(this), _poolAmount);
        pie.exitPool(_poolAmount);

        for(uint256 i = 0; i < tokens.length; i++) {
            (uint256 reserveA, uint256 reserveB) = UniLib.getReserves(address(uniswapFactory), tokens[i], address(WETH));
            uint256 wethAmountOut = UniLib.getAmountOut(amounts[i], reserveA, reserveB);
            IUniswapV2Exchange pair = IUniswapV2Exchange(UniLib.pairFor(address(uniswapFactory), tokens[i], address(WETH)));

            // Uniswap V2 does not pull the token
            IERC20(tokens[i]).transfer(address(pair), amounts[i]);

            if(token0Or1(address(WETH), tokens[i]) == 0) {
                pair.swap(0, wethAmountOut, address(this), new bytes(0));
            } else {
                pair.swap(wethAmountOut, 0, address(this), new bytes(0));
            }
        }

        WETH.withdraw(totalEth);
        msg.sender.transfer(address(this).balance);
    }

    function calcToEth(address _pie, uint256 _poolAmountOut) external view returns(uint256) {
        (address[] memory tokens, uint256[] memory amounts) = IPSmartPool(_pie).calcTokensForAmount(_poolAmountOut);

        uint256 totalEth = 0;

        for(uint256 i = 0; i < tokens.length; i++) {
            (uint256 reserveA, uint256 reserveB) = UniLib.getReserves(address(uniswapFactory), tokens[i], address(WETH));
            totalEth += UniLib.getAmountOut(amounts[i], reserveA, reserveB);
        }

        return totalEth;
    }

    function token0Or1(address tokenA, address tokenB) internal view returns(uint256) {
        (address token0, address token1) = UniLib.sortTokens(tokenA, tokenB);

        if(token0 == tokenB) {
            return 0;
        }

        return 1;
    }
    
    function die() public onlyOwner {
        address payable _to = payable(los().owner);
        selfdestruct(_to);
    }

    function saveEth() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function saveToken(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

}