// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "../interfaces/IWETH.sol";
import "../interfaces/IWethGate.sol";

contract WethGate is IWethGate
{
    IWETH public weth; // wrapped native token contract

    /* ========== ERRORS ========== */

    error EthTransferFailed();

    /* ========== EVENTS ========== */

    event Withdrawal(address indexed receiver, uint wad);

    /* ========== CONSTRUCTOR  ========== */

    constructor(IWETH _weth) {
        weth = _weth;
    }

    function withdraw(address _receiver, uint _wad) external override {
        weth.withdraw(_wad);
        _safeTransferETH(_receiver, _wad);
        emit Withdrawal(_receiver, _wad);
    }

    function _safeTransferETH(address _to, uint256 _value) internal {
        (bool success, ) = _to.call{value: _value}(new bytes(0));
        if (!success) revert EthTransferFailed();
    }

    // we need to accept ETH sends to unwrap WETH
    receive() external payable {
    }

    // ============ Version Control ============
    function version() external pure returns (uint256) {
        return 101; // 1.0.1
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IWethGate {
    function withdraw(address receiver, uint wad) external;
}