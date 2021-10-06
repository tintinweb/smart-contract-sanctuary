/**
 *Submitted for verification at polygonscan.com on 2021-10-06
*/

// SPDX-License-Identifier: GPL-3.0-or-later


pragma solidity 0.8.9;

contract TokenFinder {
    address public smartController;
    
    mapping(string => address) public tokens;

    modifier onlySmartController {
        require(msg.sender == smartController, "not SmartController");
        _;
    }

    constructor() {
        smartController = tx.origin;
    }

    function addToken(string calldata symbol_, address tokenAddress_) external onlySmartController {
        tokens[symbol_] = tokenAddress_; /// @dev Immutable, no way to change address or delete token once added
    }

    function getToken(string calldata symbol_) external view returns (address tokenAddress) {
        require(tokens[symbol_] != address(0), "this token does not exist, try entering in all lowercase");
        tokenAddress = tokens[symbol_];
    }
    
    /// @notice Protocol for SmartController to assign role.
    /// @param _smartController Account to assign role to.
    function updateSmartController(address _smartController) external onlySmartController {
        smartController = _smartController;
    }
}