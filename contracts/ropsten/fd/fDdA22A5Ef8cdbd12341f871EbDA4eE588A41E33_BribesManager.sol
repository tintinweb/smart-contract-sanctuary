/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

// File: contracts/curve-bribes-automator/BribesLogic.sol


pragma solidity ^0.8.9;

interface IBribeV2 {
    function active_period(address gauge, address reward_token) external view returns (uint);
    function add_reward_amount(address gauge, address reward_token, uint amount) external returns (bool);
}

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
// File: contracts/curve-bribes-automator/BribesManager.sol


pragma solidity ^0.8.9;


contract BribesManager {
    address public immutable TOKEN;
    address public immutable GAUGE;
    uint public immutable TOKENS_PER_VOTE;
    uint public lastPeriod;
    address constant CURVE_BRIBE = 0x7893bbb46613d7a4FbcC31Dab4C9b823FfeE1026;

    /// @param token Address of the reward/incentive token
    /// @param gauge address of the curve gauge
    /// @param tokens_per_vote number of tokens to add as incentives per vote
    constructor(address token, address gauge, uint tokens_per_vote) {
        TOKEN = token;
        GAUGE = gauge;
        TOKENS_PER_VOTE = tokens_per_vote;

    }

    function sendBribe() public {
        IERC20(TOKEN).approve(CURVE_BRIBE, type(uint).max);
        lastPeriod = BribesLogic.sendBribe(TOKEN, GAUGE, TOKENS_PER_VOTE, lastPeriod, CURVE_BRIBE);
    }
}