// SPDX-License-Identifier: MIT

pragma solidity >0.7.0;

import "./IERC20.sol";

contract RockPaperScissors {
    uint256 public placedNumber = 0;
    uint256 public revealedNumber = 0;
    mapping(uint256 => address) public playerAddress;
    struct PlayerInfo {
        int256 guess;
        bytes32 hashedGuess;
    }
    mapping(address => PlayerInfo) public playerMapping;
    address tokenAddress = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709; // LINK token

    function placeGuess(bytes32 _hashedGuess) public {
        playerMapping[msg.sender].hashedGuess = _hashedGuess;
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), 1000000000000000000);
        placedNumber = placedNumber + 1;
        playerAddress[placedNumber] = msg.sender;
    }

    function revealGuess(string memory _guess, string memory _randomNumber) public {
        require(placedNumber == 2, "there can only be 2 players");
        require(keccak256(abi.encodePacked(_guess, _randomNumber)) == playerMapping[msg.sender].hashedGuess, "Invalid input");
        if (keccak256(abi.encodePacked(_guess)) == keccak256(abi.encodePacked("rock"))) {
            playerMapping[msg.sender].guess = 2;
        } else if (keccak256(abi.encodePacked(_guess)) == keccak256(abi.encodePacked("scissors"))) {
            playerMapping[msg.sender].guess = 1;
        } else if (keccak256(abi.encodePacked(_guess)) == keccak256(abi.encodePacked("paper"))) {
            playerMapping[msg.sender].guess = 0;
        }
        revealedNumber = revealedNumber + 1;
        if (revealedNumber == 2) {
            payout();
            revealedNumber = 0;
            placedNumber = 0;
        }
    }

    function payout() internal {
        int256 guessDifference = playerMapping[playerAddress[1]].guess - playerMapping[playerAddress[2]].guess;

        if ( guessDifference == 1 || guessDifference == -2) {
            IERC20(tokenAddress).transfer(playerAddress[1], 2000000000000000000);
        } else if (guessDifference == -1 || guessDifference == 2 ) {
            IERC20(tokenAddress).transfer(playerAddress[2], 2000000000000000000);
        } else if (guessDifference == 0) {
            IERC20(tokenAddress).transfer(playerAddress[1], 1000000000000000000);
            IERC20(tokenAddress).transfer(playerAddress[2], 1000000000000000000);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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