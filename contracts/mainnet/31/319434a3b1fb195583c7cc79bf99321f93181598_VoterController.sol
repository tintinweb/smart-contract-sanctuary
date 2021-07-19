/**
 *Submitted for verification at Etherscan.io on 2021-07-18
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface Voter {
    function setGovernance(address _gov) external;
    function execute(address to, uint value, bytes calldata data) external returns (bool, bytes memory);
    function claim_rewards(address _for) external;
}

contract VoterController {

    address public owner;
    address private mintr = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
    address private voter = address(0xdc66DBa57c6f9213c641a8a216f8C3D9d83573cd);

    constructor() public {
        owner = msg.sender;
    }

    function setKeeper(address _owner) external {
        require(msg.sender == owner, "!auth");
        owner = _owner;
    }

    function setRewards(address _owner) external {
        require(msg.sender == owner, "!auth");
        Voter(voter).setGovernance(_owner);
    }

    function kill() external {
        require(msg.sender == owner, "!auth");
        selfdestruct(msg.sender);
    }

    function mints(address[] calldata _gauges) external {
        for(uint256 i = 0; i < _gauges.length; ++i) {
            Voter(voter).execute(mintr, 0, abi.encodeWithSignature("mint(address)", _gauges[i]));
        }
    }

    function pulls(address[] calldata _tokens) external {
        for(uint256 i = 0; i < _tokens.length; ++i) {
            Voter(voter).execute(_tokens[i], 0, abi.encodeWithSignature("transfer(address,uint256)", owner, IERC20(_tokens[i]).balanceOf(voter)));
        }
    }

    function allows(address[] calldata _tokens) external {
        for(uint256 i = 0; i < _tokens.length; ++i) {
            Voter(voter).execute(_tokens[i], 0, abi.encodeWithSignature("approve(address,uint256)", owner, uint(-1)));
        }
    }

    function claims(address[] calldata _gs) external {
        for(uint256 i = 0; i < _gs.length; ++i) {
            Voter(_gs[i]).claim_rewards(voter);
        }
    }
}