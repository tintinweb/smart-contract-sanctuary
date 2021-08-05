// SPDX-License-Identifier: MIT
pragma solidity ^0.6.11;

interface PoolInterface {
    function swapExactAmountIn(address, uint, address, uint, uint) external returns (uint, uint);
    function swapExactAmountOut(address, uint, address, uint, uint) external returns (uint, uint);
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

contract CreamETH2Proxy {

    TokenInterface public WETH;
    TokenInterface public CRETH2;
    PoolInterface public POOL;

    constructor(address _WETH, address _CRETH2, address _POOL) public {
        WETH = TokenInterface(_WETH);
        CRETH2 = TokenInterface(_CRETH2);
        POOL = PoolInterface(_POOL);
    }

    function swapExactAmountIn(
        uint minAmountOut,
        uint maxPrice
    ) external payable returns (uint tokenAmountOut, uint spotPriceAfter) {
        WETH.deposit{value: msg.value}();
        if (WETH.allowance(address(this), address(POOL)) > 0) {
            WETH.approve(address(POOL), 0);
        }
        WETH.approve(address(POOL), msg.value);

        (tokenAmountOut, spotPriceAfter) = POOL.swapExactAmountIn(
                                    address(WETH),
                                    msg.value,
                                    address(CRETH2),
                                    minAmountOut,
                                    maxPrice
                                );

        transferAll(CRETH2, tokenAmountOut);
        transferAll(WETH, WETH.balanceOf(address(this)));
        return (tokenAmountOut, spotPriceAfter);
    }

    function swapExactAmountOut(
        uint tokenAmountOut,
        uint maxPrice
    ) external payable returns (uint tokenAmountIn, uint spotPriceAfter) {
        WETH.deposit{value: msg.value}();
        if (WETH.allowance(address(this), address(POOL)) > 0) {
            WETH.approve(address(POOL), 0);
        }
        WETH.approve(address(POOL), msg.value);

        (tokenAmountIn, spotPriceAfter) = POOL.swapExactAmountOut(
                                            address(WETH),
                                            msg.value,
                                            address(CRETH2),
                                            tokenAmountOut,
                                            maxPrice
                                        );

        transferAll(CRETH2, tokenAmountOut);
        transferAll(WETH, WETH.balanceOf(address(this)));
        return (tokenAmountIn, spotPriceAfter);
    }

    function transferAll(TokenInterface token, uint amount) internal returns(bool) {
        if (amount == 0) {
            return true;
        }

        if (address(token) == address(WETH)) {
            WETH.withdraw(amount);
            (bool xfer,) = msg.sender.call{value: amount}("");
            require(xfer, "ERR_ETH_FAILED");
        } else {
            require(token.transfer(msg.sender, amount), "ERR_TRANSFER_FAILED");
        }
    }

    receive() external payable {
        assert(msg.sender == address(WETH)); // only accept ETH via fallback from the WETH contract
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}