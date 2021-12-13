//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma abicoder v2;
import "./utils/@opengsn/contracts/src/BaseRelayRecipient.sol";
import "./libraries/UniswapV2Library.sol";
import "./interface/IUniswapV2Router02.sol";
import "./interface/IUniswapV2Factory.sol";
import "./interface/IERC20.sol";

contract UniProxyGSN is BaseRelayRecipient {
    address owner;
    address uniswapV2Router02;
    address uniswapV2Factory;
    address WETH;

    struct PermitForPair {
        bool approveMax;
        uint8[2] v;
        bytes32[2] r;
        bytes32[2] s;
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event AddLiquidity(
        address indexed sender,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    event RemoveLiquidity(
        address indexed sender,
        uint256 amountA,
        uint256 amountB
    );

    event RemoveLiquidityETH(
        address indexed sender,
        uint256 amountToken,
        uint256 amountETH
    );

    event SwapExactTokensForTokens(address indexed sender, uint256[] amounts);

    event SwapTokensForExactTokens(address indexed sender, uint256[] amounts);

    event SwapTokensForExactETH(address indexed sender, uint256[] amounts);

    event SwapExactTokensForETH(address indexed sender, uint256[] amounts);

    event RemoveLiquidityETHSupportingFeeOnTransferTokens(
        address indexed sender,
        uint256 amountETH
    );

    constructor(
        address _forwarder,
        address _router
    ) {
        trustedForwarder[_forwarder] = true;
        setUniswapV2(_router);
    }

    modifier onlyOwner() {
        require(owner == _msgSender(), "Caller is not the owner");
        _;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function setTrustedForwarder(address _forwarder) public /**onlyOwner*/ {
        trustedForwarder[_forwarder] = true;
    }

    function setUniswapV2(address _router) public /**onlyOwner */{
        uniswapV2Factory = IUniswapV2Router02(_router).factory();
        WETH = IUniswapV2Router02(_router).WETH();
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        IERC20(tokenA).transferFrom(
            _msgSender(),
            address(this),
            amountADesired
        );
        IERC20(tokenB).transferFrom(
            _msgSender(),
            address(this),
            amountBDesired
        );
        IERC20(tokenA).approve(address(uniswapV2Router02), amountADesired);
        IERC20(tokenB).approve(address(uniswapV2Router02), amountBDesired);
        (amountA, amountB, liquidity) = IUniswapV2Router02(uniswapV2Router02)
            .addLiquidity(
                tokenA,
                tokenB,
                amountADesired,
                amountBDesired,
                amountAMin,
                amountBMin,
                to,
                deadline
            );
        emit AddLiquidity(_msgSender(), amountA, amountB, liquidity);
    }

    function addLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        PermitForPair memory permitData
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        {
            if (permitData.v[0] != 0) {
                uint256 valueA = permitData.approveMax
                    ? uint256(-1)
                    : amountADesired;

                IUniswapV2Pair(tokenA).permit(
                    _msgSender(),
                    address(this),
                    valueA,
                    deadline,
                    permitData.v[0],
                    permitData.r[0],
                    permitData.s[0]
                );
            }

            if (permitData.v[1] != 0) {
                uint256 valueB = permitData.approveMax
                    ? uint256(-1)
                    : amountBDesired;

                IUniswapV2Pair(tokenB).permit(
                    _msgSender(),
                    address(this),
                    valueB,
                    deadline,
                    permitData.v[1],
                    permitData.r[1],
                    permitData.s[1]
                );
            }
        }

        IERC20(tokenA).transferFrom(
            _msgSender(),
            address(this),
            amountADesired
        );
        IERC20(tokenB).transferFrom(
            _msgSender(),
            address(this),
            amountBDesired
        );
        IERC20(tokenA).approve(address(uniswapV2Router02), amountADesired);
        IERC20(tokenB).approve(address(uniswapV2Router02), amountBDesired);
        (amountA, amountB, liquidity) = IUniswapV2Router02(uniswapV2Router02)
            .addLiquidity(
                tokenA,
                tokenB,
                amountADesired,
                amountBDesired,
                amountAMin,
                amountBMin,
                to,
                deadline
            );
        emit AddLiquidity(_msgSender(), amountA, amountB, liquidity);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB) {
        address pair = UniswapV2Library.pairFor(
            uniswapV2Factory,
            tokenA,
            tokenB
        );
        IUniswapV2Pair(pair).transferFrom(
            _msgSender(),
            address(this),
            liquidity
        );
        IUniswapV2Pair(pair).approve(uniswapV2Router02, liquidity);
        (amountA, amountB) = IUniswapV2Router02(uniswapV2Router02)
            .removeLiquidity(
                tokenA,
                tokenB,
                liquidity,
                amountAMin,
                amountBMin,
                to,
                deadline
            );
        emit RemoveLiquidity(_msgSender(), amountA, amountB);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB) {
        address pair = UniswapV2Library.pairFor(
            uniswapV2Factory,
            tokenA,
            tokenB
        );
        {
            uint256 value = approveMax ? uint256(-1) : liquidity;
            IUniswapV2Pair(pair).permit(
                _msgSender(),
                address(this),
                value,
                deadline,
                v,
                r,
                s
            );
        }
        IUniswapV2Pair(pair).transferFrom(
            _msgSender(),
            address(this),
            liquidity
        );

        IUniswapV2Pair(pair).approve(uniswapV2Router02, liquidity);
        IUniswapV2Router02(uniswapV2Router02).removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
        emit RemoveLiquidity(_msgSender(), amountA, amountB);
    }

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH) {
        address pair = UniswapV2Library.pairFor(uniswapV2Factory, token, WETH);
        IUniswapV2Pair(pair).transferFrom(
            _msgSender(),
            address(this),
            liquidity
        );
        IUniswapV2Pair(pair).approve(uniswapV2Router02, liquidity);
        (amountToken, amountETH) = IUniswapV2Router02(uniswapV2Router02)
            .removeLiquidityETH(
                token,
                liquidity,
                amountTokenMin,
                amountETHMin,
                to,
                deadline
            );
        emit RemoveLiquidityETH(_msgSender(), amountToken, amountETH);
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH) {
        address pair = UniswapV2Library.pairFor(uniswapV2Factory, token, WETH);
        {
            uint256 value = approveMax ? uint256(-1) : liquidity;
            IUniswapV2Pair(pair).permit(
                _msgSender(),
                address(this),
                value,
                deadline,
                v,
                r,
                s
            );
        }
        IUniswapV2Pair(pair).transferFrom(
            _msgSender(),
            address(this),
            liquidity
        );
        IUniswapV2Pair(pair).approve(uniswapV2Router02, liquidity);
        (amountToken, amountETH) = IUniswapV2Router02(uniswapV2Router02)
            .removeLiquidityETH(
                token,
                liquidity,
                amountTokenMin,
                amountETHMin,
                to,
                deadline
            );
        emit RemoveLiquidityETH(_msgSender(), amountToken, amountETH);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        IERC20(path[0]).transferFrom(_msgSender(), address(this), amountIn);
        IERC20(path[0]).approve(address(uniswapV2Router02), amountIn);
        (amounts) = IUniswapV2Router02(uniswapV2Router02)
            .swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            );
        emit SwapExactTokensForTokens(_msgSender(), amounts);
    }

    function swapExactTokensForTokensWithPermit(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256[] memory amounts) {
        {
            uint256 value = approveMax ? uint256(-1) : amountIn;
            IUniswapV2Pair(path[0]).permit(
                _msgSender(),
                address(this),
                value,
                deadline,
                v,
                r,
                s
            );
        }
        IERC20(path[0]).transferFrom(_msgSender(), address(this), amountIn);
        IERC20(path[0]).approve(address(uniswapV2Router02), amountIn);
        (amounts) = IUniswapV2Router02(uniswapV2Router02)
            .swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            );
        emit SwapExactTokensForTokens(_msgSender(), amounts);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        IERC20(path[0]).transferFrom(_msgSender(), address(this), amountInMax);
        IERC20(path[0]).approve(address(uniswapV2Router02), amountInMax);
        (amounts) = IUniswapV2Router02(uniswapV2Router02)
            .swapTokensForExactTokens(
                amountOut,
                amountInMax,
                path,
                to,
                deadline
            );
        emit SwapTokensForExactTokens(_msgSender(), amounts);
    }

    function swapTokensForExactTokensWithPermit(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256[] memory amounts) {
        {
            uint256 value = approveMax ? uint256(-1) : amountInMax;
            IUniswapV2Pair(path[0]).permit(
                _msgSender(),
                address(this),
                value,
                deadline,
                v,
                r,
                s
            );
        }
        IERC20(path[0]).transferFrom(_msgSender(), address(this), amountInMax);
        IERC20(path[0]).approve(address(uniswapV2Router02), amountInMax);
        (amounts) = IUniswapV2Router02(uniswapV2Router02)
            .swapTokensForExactTokens(
                amountOut,
                amountInMax,
                path,
                to,
                deadline
            );
        emit SwapTokensForExactTokens(_msgSender(), amounts);
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        IERC20(path[0]).transferFrom(_msgSender(), address(this), amountInMax);
        IERC20(path[0]).approve(address(uniswapV2Router02), amountInMax);
        (amounts) = IUniswapV2Router02(uniswapV2Router02).swapTokensForExactETH(
            amountOut,
            amountInMax,
            path,
            to,
            deadline
        );
        emit SwapTokensForExactETH(_msgSender(), amounts);
    }

    function swapTokensForExactETHWithPermit(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256[] memory amounts) {
        {
            uint256 value = approveMax ? uint256(-1) : amountInMax;
            IUniswapV2Pair(path[0]).permit(
                _msgSender(),
                address(this),
                value,
                deadline,
                v,
                r,
                s
            );
        }
        IERC20(path[0]).transferFrom(_msgSender(), address(this), amountInMax);
        IERC20(path[0]).approve(address(uniswapV2Router02), amountInMax);
        (amounts) = IUniswapV2Router02(uniswapV2Router02).swapTokensForExactETH(
            amountOut,
            amountInMax,
            path,
            to,
            deadline
        );
        emit SwapTokensForExactETH(_msgSender(), amounts);
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        IERC20(path[0]).transferFrom(_msgSender(), address(this), amountIn);
        IERC20(path[0]).approve(address(uniswapV2Router02), amountIn);
        (amounts) = IUniswapV2Router02(uniswapV2Router02).swapExactTokensForETH(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
        emit SwapExactTokensForETH(_msgSender(), amounts);
    }

    function swapExactTokensForETHWithPermit(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256[] memory amounts) {
        {
            uint256 value = approveMax ? uint256(-1) : amountIn;
            IUniswapV2Pair(path[0]).permit(
                _msgSender(),
                address(this),
                value,
                deadline,
                v,
                r,
                s
            );
        }
        IERC20(path[0]).transferFrom(_msgSender(), address(this), amountIn);
        IERC20(path[0]).approve(address(uniswapV2Router02), amountIn);
        (amounts) = IUniswapV2Router02(uniswapV2Router02).swapExactTokensForETH(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
        emit SwapExactTokensForETH(_msgSender(), amounts);
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        IERC20(path[0]).transferFrom(_msgSender(), address(this), amountIn);
        IERC20(path[0]).approve(address(uniswapV2Router02), amountIn);
        IUniswapV2Router02(uniswapV2Router02)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            );
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokensWithPermit(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        {
            uint256 value = approveMax ? uint256(-1) : amountIn;
            IUniswapV2Pair(path[0]).permit(
                _msgSender(),
                address(this),
                value,
                deadline,
                v,
                r,
                s
            );
        }
        IERC20(path[0]).transferFrom(_msgSender(), address(this), amountIn);
        IERC20(path[0]).approve(address(uniswapV2Router02), amountIn);
        IUniswapV2Router02(uniswapV2Router02)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            );
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        IERC20(path[0]).transferFrom(_msgSender(), address(this), amountIn);
        IERC20(path[0]).approve(address(uniswapV2Router02), amountIn);
        IUniswapV2Router02(uniswapV2Router02)
            .swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            );
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokensWithPermit(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        {
            uint256 value = approveMax ? uint256(-1) : amountIn;
            IUniswapV2Pair(path[0]).permit(
                _msgSender(),
                address(this),
                value,
                deadline,
                v,
                r,
                s
            );
        }
        IERC20(path[0]).transferFrom(_msgSender(), address(this), amountIn);
        IERC20(path[0]).approve(address(uniswapV2Router02), amountIn);
        IUniswapV2Router02(uniswapV2Router02)
            .swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            );
    }

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public returns (uint256 amountETH) {
        address pair = UniswapV2Library.pairFor(uniswapV2Factory, token, WETH);
        IUniswapV2Pair(pair).transferFrom(
            _msgSender(),
            address(this),
            liquidity
        );
        IUniswapV2Pair(pair).approve(uniswapV2Router02, liquidity);
        (amountETH) = IUniswapV2Router02(uniswapV2Router02)
            .removeLiquidityETHSupportingFeeOnTransferTokens(
                token,
                liquidity,
                amountTokenMin,
                amountETHMin,
                to,
                deadline
            );
        emit RemoveLiquidityETHSupportingFeeOnTransferTokens(
            _msgSender(),
            amountETH
        );
    }

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public returns (uint256 amountETH) {
        address pair = UniswapV2Library.pairFor(uniswapV2Factory, token, WETH);
        uint256 value = approveMax ? uint256(-1) : liquidity;
        IUniswapV2Pair(pair).permit(
            _msgSender(),
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        IUniswapV2Pair(pair).transferFrom(
            _msgSender(),
            address(this),
            liquidity
        );
        IUniswapV2Pair(pair).approve(uniswapV2Router02, liquidity);
        (amountETH) = IUniswapV2Router02(uniswapV2Router02)
            .removeLiquidityETHSupportingFeeOnTransferTokens(
                token,
                liquidity,
                amountTokenMin,
                amountETHMin,
                to,
                deadline
            );
        emit RemoveLiquidityETHSupportingFeeOnTransferTokens(
            _msgSender(),
            amountETH
        );
    }

    string public override versionRecipient = "2.2.3";
}

// Forked from @opengsn/contracts/src/BaseRelayRecipient.sol to fix solc 0.8.

// SPDX-License-Identifier: GPL-3.0-only
// solhint-disable no-inline-assembly
pragma solidity >=0.7.6;

import "./IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    mapping(address => bool) trustedForwarder;

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return trustedForwarder[forwarder];
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address payable ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return payable(msg.sender);
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise, return `msg.data`
     * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
     * signing or hashing the
     */
    function _msgData() internal override virtual view returns (bytes memory ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

pragma solidity >=0.5.0;

import "../interface/IUniswapV2Pair.sol";

import "./SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
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
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

pragma solidity >=0.6.2;
import "./IUniswapV2Router01.sol";

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
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address payable);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes memory);

    function versionRecipient() external virtual view returns (string memory);
}

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

pragma solidity >=0.5.16;

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