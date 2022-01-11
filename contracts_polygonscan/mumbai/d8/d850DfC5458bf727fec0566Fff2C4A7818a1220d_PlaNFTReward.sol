/**
 *Submitted for verification at polygonscan.com on 2022-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract PlaNFTReward is Ownable {
    event withdrawETH(address owner, uint256 value);
    event withdrawToken(address token, address to, uint256 value);

    constructor() {}

    function withdrawForETH(uint256 value) public onlyOwner {
        require(address(this).balance >= value, "balances not enough!");
        payable(msg.sender).transfer(value);
        emit withdrawETH(msg.sender, value);
    }

    function withdrawForToken(
        address tokenAddr,
        address to,
        uint256 value
    ) public onlyOwner {
        require(
            IERC20(tokenAddr).balanceOf(address(this)) >= value,
            "balances not enough!"
        );
        IERC20(tokenAddr).transfer(to, value);
        emit withdrawToken(tokenAddr, to, value);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    receive() external payable {}

    fallback() external payable {}
}