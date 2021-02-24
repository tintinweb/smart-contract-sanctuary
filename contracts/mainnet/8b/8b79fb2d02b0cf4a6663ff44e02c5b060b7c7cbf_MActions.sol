/**
 *Submitted for verification at Etherscan.io on 2021-02-24
*/

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.5.12;

interface IERC20 {
    function balanceOf(address whom) external view returns (uint);
    function allowance(address, address) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transfer(address dst, uint amt) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

interface IMPool {
    function controller() external returns (address);
    function totalSupply() external view returns (uint);
    function isBound(address t) external view returns (bool);
    function getFinalTokens() external view returns(address[] memory);
    function getBalance(address token) external view returns (uint);
    function getDenormalizedWeight(address token) external view returns (uint);
    function setSwapFee(uint swapFee) external;
    function setController(address controller) external;
    function setPair(address pair) external;
    function bind(address token, uint balance, uint denorm) external;
    function finalize(address beneficiary, uint256 initAmount) external;
    function updatePairGPInfo(address[] calldata gps, uint[] calldata shares) external;
    function joinPool(address beneficiary, uint poolAmountOut) external;
    function rebind(address token, uint balance, uint denorm) external;
}

interface TokenInterface {
    function balanceOf(address) external view returns (uint);
    function allowance(address, address) external view returns (uint);
    function approve(address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function deposit() external payable;
    function withdraw(uint) external;
}

interface IPairToken {
    function setController(address _controller) external ;
}

interface IMFactory {
    function newMPool() external returns (IMPool);
}

interface IPairFactory {
    function newPair(address pool, uint256 perBlock, uint256 rate) external returns (IPairToken);
    function getPairToken(address pool) external view returns (address);
}



/********************************** WARNING **********************************/
//                                                                           //
// This contract is only meant to be used in conjunction with ds-proxy.      //
// Calling this contract directly will lead to loss of funds.                //
//                                                                           //
/********************************** WARNING **********************************/

contract MActions {

    function createWithPair(
        IMFactory factory,
        IPairFactory pairFactory,
        address[] calldata tokens,
        uint[] calldata balances,
        uint[] calldata denorms,
        address[] calldata gps,
        uint[] calldata shares,
        uint swapFee,
        uint gpRate
    ) external payable returns (IMPool pool) {
        pool = create(factory, tokens, balances, denorms, swapFee, 0, false);

        IPairToken pair = pairFactory.newPair(address(pool), 4 * 10 ** 18, gpRate);

        pool.setPair(address(pair));
        if (gpRate > 0 && gpRate <= 15 && gps.length != 0 && gps.length == shares.length) {
            pool.updatePairGPInfo(gps, shares);
        }
        pool.finalize(msg.sender, 0);
        pool.setController(msg.sender);
        pair.setController(msg.sender);
    }

    function create(
        IMFactory factory,
        address[] memory tokens,
        uint[] memory balances,
        uint[] memory denorms,
        uint swapFee,
        uint initLpSupply,
        bool finalize
    ) public payable returns (IMPool pool) {
        require(tokens.length == balances.length, "ERR_LENGTH_MISMATCH");
        require(tokens.length == denorms.length, "ERR_LENGTH_MISMATCH");

        pool = factory.newMPool();
        pool.setSwapFee(swapFee);

        address ETH = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
        address weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        for (uint i = 0; i < tokens.length; i++) {
            address inToken = tokens[i];
            if (inToken == ETH) {
                require(msg.value == balances[i], "ERR_LIMIT_IN");
                TokenInterface(weth).deposit.value(msg.value)();
                inToken = weth;
            } else {
                safeTransferFrom(inToken, msg.sender, address(this), balances[i]);
            }
            IERC20 token = IERC20(inToken);
            if (token.allowance(address(this), address(pool)) > 0) {
                safeApprove(inToken, address(pool), 0);
            }
            safeApprove(inToken, address(pool), balances[i]);
            pool.bind(inToken, balances[i], denorms[i]);
        }
        if (finalize) {
            pool.finalize(msg.sender, initLpSupply);
            pool.setController(msg.sender);
        }

    }

    function joinPool(
        IMPool pool,
        uint poolAmountOut,
        uint[] calldata maxAmountsIn
    ) external payable {
        address[] memory tokens = pool.getFinalTokens();
        require(maxAmountsIn.length == tokens.length, "ERR_LENGTH_MISMATCH");
        uint poolTotal = pool.totalSupply();
        uint ratio = bdiv(poolAmountOut, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");
        address _weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        for (uint i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint bal = pool.getBalance(t);
            uint tokenAmountIn = bmul(ratio, bal);
            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");
            address from = msg.sender;
            if (msg.value > 0 && t == _weth) {
                require(msg.value <= maxAmountsIn[i], "ERR_ETH_IN");
                TokenInterface weth = TokenInterface(_weth);
                weth.deposit.value(tokenAmountIn)();
                t = address(weth);
                from = address(this);
                if (msg.value > tokenAmountIn) {
                    safeTransferETH(msg.sender, bsub(msg.value, tokenAmountIn));
                }
            }
            safeTransferFrom(t, from, address(pool), tokenAmountIn);
        }
        pool.joinPool(msg.sender, poolAmountOut);
    }

    function rebind(
        IMPool pool,
        uint[] memory balances,
        uint initLpSupply
    ) public payable {
        require(address(pool) != address(0), "ERR_POOL_INVALID");
        address[] memory tokens = pool.getFinalTokens();
        require(tokens.length == balances.length, "ERR_LENGTH_MISMATCH");
        TokenInterface weth = TokenInterface(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        bool costETH = false;
        for (uint i = 0; i < tokens.length; i++) {
            address inToken = tokens[i];
            if (inToken == address(weth) && msg.value > 0) {
                require(msg.value == balances[i], "ERR_LIMIT_IN");
                weth.deposit.value(msg.value)();
                costETH = true;
            } else {
                safeTransferFrom(inToken, msg.sender, address(this), balances[i]);
            }
            IERC20 token = IERC20(inToken);
            if (token.allowance(address(this), address(pool)) > 0) {
                safeApprove(inToken, address(pool), 0);
            }
            safeApprove(inToken, address(pool), balances[i]);
            pool.rebind(inToken, balances[i], pool.getDenormalizedWeight(inToken));
        }
        if(msg.value > 0 && !costETH){
            safeTransferETH(msg.sender, msg.value);
        }
        pool.finalize(msg.sender, initLpSupply);
        pool.setController(msg.sender);
    }

    // when sender transfer controller to dproxy, dproxy could transfer controller back to msg.sender;
    // note: mustn't transfer pool's controller to MActions.
    function transferController(IMPool pool) external {
        require(pool.controller() == address(this), "ERR_POOL_CONTROOLER");
        pool.setController(msg.sender);
    }

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

    function safeTransferETH(
        address to,
        uint256 value
    ) internal {
        (bool success, ) = to.call.value(value)("");
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }

    function setController(IMPool pool, address newController) external {
        pool.setController(newController);
    }


    function bdiv(uint a, uint b)
    internal pure
    returns (uint)
    {
        require(b != 0, "ERR_DIV_ZERO");
        uint c0 = a * 10 ** 18;
        require(a == 0 || c0 / a == 1 * 10 ** 18, "ERR_DIV_INTERNAL"); // bmul overflow
        uint c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint c2 = c1 / b;
        return c2;
    }

    function bmul(uint a, uint b)
    internal pure
    returns (uint)
    {
        uint c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint c1 = c0 + (1 * 10 ** 18) / 2;
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint c2 = c1 / (1 * 10 ** 18);
        return c2;
    }

    function bsub(uint a, uint b)
    internal pure
    returns (uint)
    {
        (uint c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    function bsubSign(uint a, uint b)
    internal pure
    returns (uint, bool)
    {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

}