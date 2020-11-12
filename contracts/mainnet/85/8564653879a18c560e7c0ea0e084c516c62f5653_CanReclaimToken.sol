// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "./SafeERC20.sol";
import "./Ownable.sol";

// Tokens should not be sent to this contract.  If any tokens are accidentally sent to
// this contract, allow the contract owner to recover them.
// Copied from https://github.com/OpenZeppelin/openzeppelin-solidity/blob/6c4c8989b399510a66d8b98ad75a0979482436d2/contracts/ownership/CanReclaimToken.sol
contract CanReclaimToken is Ownable {
    using SafeERC20 for IERC20;

    function reclaimToken(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(owner(), balance);
    }
}
