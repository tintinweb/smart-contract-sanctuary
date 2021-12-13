// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "IBribeV2.sol";
import "IERC20.sol";

library BribesLogic {
    /// @dev sends the token incentives to curve gauge votes for the next vote cycle/period
    function sendBribe(address TOKEN, address GAUGE, uint TOKENS_PER_VOTE, uint lastPeriod, address CURVE_BRIBE) public returns (uint) {
        uint balance = IERC20(TOKEN).balanceOf(address(this));
        require(balance > 0, "No tokens");

        if (TOKENS_PER_VOTE > balance) {
            TOKENS_PER_VOTE = balance;
        }

        // this makes sure that the token incentives can be sent only once per vote 
        require (block.timestamp > lastPeriod + 604800, "Bribe already sent"); // 604800 seconds in 1 week

        IBribeV2(CURVE_BRIBE).add_reward_amount(GAUGE, TOKEN, TOKENS_PER_VOTE);
        return IBribeV2(CURVE_BRIBE).active_period(GAUGE, TOKEN);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBribeV2 {
    function active_period(address gauge, address reward_token) external view returns (uint);
    function add_reward_amount(address gauge, address reward_token, uint amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(
        address to,
        uint256 amount
    ) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}