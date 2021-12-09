/**
 *Submitted for verification at polygonscan.com on 2021-12-09
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.0;


interface IBizverseFactory {
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

interface IBizversePair {
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

interface IBizverseRouter01 {
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

interface IBIZ {
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

    function setLab(address labAddress_) external returns (bool);
    function labMint(address to, uint256 amount) external returns (bool);
}

contract LAB {
    address public biveAddress = 0x2Fbee4B84918a92097503f7336bDE49a2AAaB58F;
    address public bizAddress = 0x137bE3Af4357a607Bc4DfEDB0dfd3893AFd21E6D;
    address public vraAddress = 0xc1C2D0754A2d4a0F79F248a0e4E6E9f87e6b0D99;
    address public factory = 0xDaA275A9F170091Bfd67F4cBe9d5B4c461fF3Ea8;
    address public router = 0x76E7C4D54cFF6Dc0f18fE0A3A4f6CC4223464B7A;
    address public pair = 0x917fEEb2374515B2F8E79c605ff79011737D7081;
    address public owner;
    IERC20 internal BIVE = IERC20(biveAddress);
    IERC20 internal VRA = IERC20(vraAddress);
    IBIZ internal BIZ = IBIZ(bizAddress);

    address public devAddress = 0x4990b539D97978EF1ce44a0691f24436EBb16CaD;

    event SetDevAddress(address indexed account);
    event SwapVRAToBIZ(uint indexed amount);
    event SwapBIVEToBIZ(uint indexed amountIn, uint indexed amountOut);
    event WithdrawVRAByBIZ(uint indexed amount);

    constructor(){
        BIVE.approve(router, type(uint256).max);
        VRA.approve(router, type(uint256).max);
        owner = msg.sender;
    }

    function setDevAddress(address _devAddress) public returns (bool){
        require(msg.sender == owner);
        require(_devAddress != devAddress);
        devAddress = _devAddress;
        emit SetDevAddress(_devAddress);
        return true;
    }

    function transferOwnership(address _newOwner) public returns (bool){
        require(msg.sender == owner);
        require(owner != _newOwner);
        owner = _newOwner;
        return true;
    }

    function getReserves() internal view returns(uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast){
        (reserve0, reserve1, blockTimestampLast) = IBizversePair(pair).getReserves();
    }

    function getAmountOut(uint amountIn) public view returns (uint amountOut){
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = getReserves();
        amountOut = IBizverseRouter01(router).getAmountOut(amountIn, reserve0, reserve1);
    }

    function getAmountIn(uint amountOut) public view returns (uint amountIn){
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = getReserves();
        amountIn = IBizverseRouter01(router).getAmountIn(amountOut, reserve1, reserve0);
    }

    function swapVRA(uint amountIn) public returns (uint amountOut){
        require(VRA.transferFrom(msg.sender, address(this), amountIn), "Swap VRA to BIZ: Transfer VRA failed");
        bool minted = BIZ.labMint(msg.sender,amountIn);
        if (!minted) revert();
        emit SwapVRAToBIZ(amountIn);
        amountOut = amountIn;
    }

    function swapExactBiveToBiz(
        uint amountIn,
        uint amountOutMin,
        uint deadline
    ) public returns (bool){
        require(BIVE.transferFrom(msg.sender, address(this), amountIn), "TransferFrom VRA failed");
        address[] memory path = new address[](2);
        path[0] = biveAddress;
        path[1] = vraAddress;
        uint[] memory amounts = IBizverseRouter01(router).swapExactTokensForTokens(amountIn, amountOutMin,path, address(this), deadline);
        if (amounts.length == 0){
            revert();
        } else {
            require(IBIZ(bizAddress).labMint(msg.sender,amounts[0]), "Mint failed");
            emit SwapBIVEToBIZ(amountIn,amounts[0]);
        }
          
        return true;
    }

    function swapBiveToExactBiz(
        uint amountInMax,
        uint amountOut,
        uint deadline
    ) public returns (bool){
        address[] memory path = new address[](2);
        path[0] = biveAddress;
        path[1] = vraAddress;
        require(BIVE.transferFrom(msg.sender, address(this), amountInMax), "TransferFrom VRA failed");
        uint[] memory amounts = IBizverseRouter01(router).swapTokensForExactTokens(amountOut, amountInMax, path, address(this), deadline);

        if (amounts.length == 0){
            revert();
        } else{
            if (amounts[0] < amountInMax) require(BIVE.transfer(msg.sender, amountInMax - amounts[0]), "Transfer VRA failed");
            require(IBIZ(bizAddress).labMint(msg.sender, amountOut), "Mint failed");
            emit SwapBIVEToBIZ(amounts[0],amountOut);
        } 
        return true;
    }

    function swapBizToVRA(uint amountIn) public returns (uint amountOut){
        require(msg.sender == devAddress);
        require(BIZ.transferFrom(msg.sender, address(this), amountIn), "Swap BIZ to VRA: Transfer BIZ failed");
        bool burned = BIZ.transfer(address(0),amountIn);
        if (!burned){
            revert();
        } else {
            require(VRA.transfer(msg.sender, amountIn), "Swap BIZ to VRA: Transfer VRA failed");
            amountOut = amountIn;
            emit WithdrawVRAByBIZ(amountIn);
        }
    }

    function ownerWithdrawToken(address _tokenAddress, uint256 _amount) public returns (bool){
        require(msg.sender == owner);
        TransferHelper.safeTransfer(_tokenAddress,msg.sender, _amount);
        return true;
    }

    function ownerWithdrawNativeToken(uint256 _amount) public returns (bool){
        require(msg.sender == owner);
        TransferHelper.safeTransferETH(msg.sender, _amount);
        return true;
    }


}