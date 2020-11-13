/*
https://powerpool.finance/

          wrrrw r wrr
         ppwr rrr wppr0       prwwwrp                                 prwwwrp                   wr0
        rr 0rrrwrrprpwp0      pp   pr  prrrr0 pp   0r  prrrr0  0rwrrr pp   pr  prrrr0  prrrr0    r0
        rrp pr   wr00rrp      prwww0  pp   wr pp w00r prwwwpr  0rw    prwww0  pp   wr pp   wr    r0
        r0rprprwrrrp pr0      pp      wr   pr pp rwwr wr       0r     pp      wr   pr wr   pr    r0
         prwr wrr0wpwr        00        www0   0w0ww    www0   0w     00        www0    www0   0www0
          wrr ww0rrrr

*/

// File: contracts/bactions-proxy/BActions.sol

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

pragma solidity 0.6.12;

abstract contract ERC20 {
    function balanceOf(address whom) external view virtual returns (uint);
    function allowance(address, address) external view virtual returns (uint);
    function approve(address spender, uint amount) external virtual returns (bool);
    function transfer(address dst, uint amt) external virtual returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external virtual returns (bool);
}

abstract contract BPool is ERC20 {
    function isBound(address t) external view virtual returns (bool);
    function getFinalTokens() external view virtual returns(address[] memory);
    function getBalance(address token) external view virtual returns (uint);
    function setSwapFee(uint swapFee) external virtual;
    function setCommunityFeeAndReceiver(uint swapFee, uint joinFee, uint exitFee, address swapFeeReceiver) external virtual;
    function setController(address controller) external virtual;
    function setPublicSwap(bool public_) external virtual;
    function finalize() external virtual;
    function bind(address token, uint balance, uint denorm) external virtual;
    function rebind(address token, uint balance, uint denorm) external virtual;
    function unbind(address token) external virtual;
    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external virtual;
    function joinswapExternAmountIn(
        address tokenIn, uint tokenAmountIn, uint minPoolAmountOut
    ) external virtual returns (uint poolAmountOut);
}

abstract contract BFactory {
    function newBPool(string calldata name, string calldata symbol) external virtual returns (BPool);
}

/********************************** WARNING **********************************/
//                                                                           //
// This contract is only meant to be used in conjunction with ds-proxy.      //
// Calling this contract directly will lead to loss of funds.                //
//                                                                           //
/********************************** WARNING **********************************/

contract BActions {

    function create(
        BFactory factory,
        string calldata name,
        string calldata symbol,
        address[] calldata tokens,
        uint[] calldata balances,
        uint[] calldata denorms,
        uint[4] calldata fees,
        address communityFeeReceiver,
        bool finalize
    ) external returns (BPool pool) {
        require(tokens.length == balances.length, "ERR_LENGTH_MISMATCH");
        require(tokens.length == denorms.length, "ERR_LENGTH_MISMATCH");

        pool = factory.newBPool(name, symbol);
        pool.setSwapFee(fees[0]);
        pool.setCommunityFeeAndReceiver(fees[1], fees[2], fees[3], communityFeeReceiver);

        for (uint i = 0; i < tokens.length; i++) {
            ERC20 token = ERC20(tokens[i]);
            require(token.transferFrom(msg.sender, address(this), balances[i]), "ERR_TRANSFER_FAILED");
            if (token.allowance(address(this), address(pool)) > 0) {
                token.approve(address(pool), 0);
            }
            token.approve(address(pool), balances[i]);
            pool.bind(tokens[i], balances[i], denorms[i]);
        }

        if (finalize) {
            pool.finalize();
            require(pool.transfer(msg.sender, pool.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
        } else {
            pool.setPublicSwap(true);
        }

        pool.setController(msg.sender);
    }

    function setTokens(
        BPool pool,
        address[] calldata tokens,
        uint[] calldata balances,
        uint[] calldata denorms
    ) external {
        require(tokens.length == balances.length, "ERR_LENGTH_MISMATCH");
        require(tokens.length == denorms.length, "ERR_LENGTH_MISMATCH");

        for (uint i = 0; i < tokens.length; i++) {
            ERC20 token = ERC20(tokens[i]);
            if (pool.isBound(tokens[i])) {
                if (balances[i] > pool.getBalance(tokens[i])) {
                    require(
                        token.transferFrom(msg.sender, address(this), balances[i] - pool.getBalance(tokens[i])),
                        "ERR_TRANSFER_FAILED"
                    );
                    if (token.allowance(address(this), address(pool)) > 0) {
                        token.approve(address(pool), 0);
                    }
                    token.approve(address(pool), balances[i] - pool.getBalance(tokens[i]));
                }
                if (balances[i] > 10**6) {
                    pool.rebind(tokens[i], balances[i], denorms[i]);
                } else {
                    pool.unbind(tokens[i]);
                }

            } else {
                require(token.transferFrom(msg.sender, address(this), balances[i]), "ERR_TRANSFER_FAILED");
                if (token.allowance(address(this), address(pool)) > 0) {
                    token.approve(address(pool), 0);
                }
                token.approve(address(pool), balances[i]);
                pool.bind(tokens[i], balances[i], denorms[i]);
            }

            if (token.balanceOf(address(this)) > 0) {
                require(token.transfer(msg.sender, token.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
            }

        }
    }

    function setPublicSwap(BPool pool, bool publicSwap) external {
        pool.setPublicSwap(publicSwap);
    }

    function setSwapFee(BPool pool, uint newFee) external {
        pool.setSwapFee(newFee);
    }

    function setController(BPool pool, address newController) external {
        pool.setController(newController);
    }

    function finalize(BPool pool) external {
        pool.finalize();
        require(pool.transfer(msg.sender, pool.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
    }

    function joinPool(
        BPool pool,
        uint poolAmountOut,
        uint[] calldata maxAmountsIn
    ) external {
        address[] memory tokens = pool.getFinalTokens();
        require(maxAmountsIn.length == tokens.length, "ERR_LENGTH_MISMATCH");

        for (uint i = 0; i < tokens.length; i++) {
            ERC20 token = ERC20(tokens[i]);
            require(token.transferFrom(msg.sender, address(this), maxAmountsIn[i]), "ERR_TRANSFER_FAILED");
            if (token.allowance(address(this), address(pool)) > 0) {
                token.approve(address(pool), 0);
            }
            token.approve(address(pool), maxAmountsIn[i]);
        }
        pool.joinPool(poolAmountOut, maxAmountsIn);
        for (uint i = 0; i < tokens.length; i++) {
            ERC20 token = ERC20(tokens[i]);
            if (token.balanceOf(address(this)) > 0) {
                require(token.transfer(msg.sender, token.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
            }
        }
        require(pool.transfer(msg.sender, pool.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
    }

    function joinswapExternAmountIn(
        BPool pool,
        address tokenIn,
        uint tokenAmountIn,
        uint minPoolAmountOut
    ) external {
        ERC20 token = ERC20(tokenIn);
        require(token.transferFrom(msg.sender, address(this), tokenAmountIn), "ERR_TRANSFER_FAILED");
        if (token.allowance(address(this), address(pool)) > 0) {
            token.approve(address(pool), 0);
        }
        token.approve(address(pool), tokenAmountIn);
        uint poolAmountOut = pool.joinswapExternAmountIn(tokenIn, tokenAmountIn, minPoolAmountOut);
        require(pool.transfer(msg.sender, poolAmountOut), "ERR_TRANSFER_FAILED");
    }
}