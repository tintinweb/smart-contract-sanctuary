// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ILLTH.sol";

contract LlthBridge is Ownable {
    using SafeMath for uint256;
    using Address for address;

    // instance of L2 LLTH token
    ILLTH internal _LLTH;

    // sending bridging details to the Node.js server
    event BridgeRequest(string requestId, uint256 amount, address user);

    constructor(address LLTH_) {
        _LLTH = ILLTH(LLTH_);
    }

    function setLLTH(address LLTH_) external onlyOwner {
        _LLTH = ILLTH(LLTH_);
    }

    function bridge(string memory requestId, uint256 amount) external {
        require(msg.sender != address(0), "Sender cant be null address.");
        require(
            _LLTH.balanceOf(msg.sender) >= amount,
            "Not enough $LLTH token in your wallet."
        );

        emit BridgeRequest(requestId, amount, msg.sender);
        _LLTH.burn(msg.sender, amount);
    }
}