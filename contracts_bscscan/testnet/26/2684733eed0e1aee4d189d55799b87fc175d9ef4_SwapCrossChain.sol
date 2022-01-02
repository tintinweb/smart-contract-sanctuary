// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./Pausable.sol";
import "./IBEP20.sol";

/**
 * Swap Cross Chain
 * @dev Allow anyone swap bnb to specified token
 */
contract SwapCrossChain is Pausable, Ownable {
    IBEP20 immutable _tokenContract;

    event Deposit(
        address indexed user,
        string kyc,
        uint256 amount,
        uint256 timestamp
    );
    event Withdraw(address indexed owner, uint256 amount, uint256 timestamp);

    /**
     * Constructor
     * @dev Set token address
     */
    constructor(address token) {
        _tokenContract = IBEP20(token);
    }

    /**
     * Pause
     * @dev Allow owner pause swap function
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * Unpause
     * @dev Allow owner unpause swap function
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * Deposit token
     * @dev Allow user deposit token
     */
    function depositToken(string memory kyc, uint256 amount)
        external
        whenNotPaused
    {
        _tokenContract.transferFrom(_msgSender(), address(this), amount);
        emit Deposit(_msgSender(), kyc, amount, block.timestamp);
    }

    /**
     * Withdraw token
     * @dev Allow owner withdraw free token
     */
    function withdrawToken(uint256 amount) external onlyOwner {
        _tokenContract.transfer(_msgSender(), amount);
        emit Withdraw(_msgSender(), amount, block.timestamp);
    }
}