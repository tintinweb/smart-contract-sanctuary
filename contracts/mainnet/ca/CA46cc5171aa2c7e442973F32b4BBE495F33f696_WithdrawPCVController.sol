// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title a PCV Deposit interface
/// @author Ring Protocol
interface IPCVDeposit {
    // ----------- Events -----------
    event Deposit(address indexed _from, uint256 _amount);
    event Collect(address indexed _from, uint256 _amount0, uint256 _amount1);

    event Withdrawal(
        address indexed _caller,
        address indexed _to,
        uint256 _amount
    );

    // ----------- State changing api -----------

    function deposit() external payable;

    function collect() external returns (uint256 amount0, uint256 amount1);

    // ----------- PCV Controller only state changing api -----------

    function withdraw(address to, uint256 amount) external;

    function burnAndReset(uint24 _fee, int24 _tickLower, int24 _tickUpper) external;

    // ----------- Getters -----------

    function fee() external view returns (uint24);

    function tickLower() external view returns (int24);

    function tickUpper() external view returns (int24);

    function totalLiquidity() external view returns (uint128);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "./IPCVDeposit.sol";

/// @author Ring Protocol
contract WithdrawPCVController {
    address public receiver;

    /// @notice WithdrawPCVController constructor
    /// @param _receiver receiver
    constructor(address _receiver) {
        receiver = _receiver;
    }

    function withdrawLiquidity(address _pcvDeposit) external {
        require(msg.sender == receiver, "RING: FORBIDDEN");
        IPCVDeposit pcvDeposit = IPCVDeposit(_pcvDeposit);
        uint256 value = pcvDeposit.totalLiquidity();
        require(value > 0, "ERC20UniswapPCVController: No liquidity to withdraw");
        pcvDeposit.withdraw(receiver, value);
    }
}

