/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

// File: contracts/ITokenPredicate.sol

pragma solidity 0.6.6;

/// @title Token predicate interface for all pos portal predicates
/// @notice Abstract interface that defines methods for custom predicates
interface ITokenPredicate {

    /**
     * @notice Deposit tokens into pos portal
     * @dev When `depositor` deposits tokens into pos portal, tokens get locked into predicate contract.
     * @param depositor Address who wants to deposit tokens
     * @param depositReceiver Address (address) who wants to receive tokens on side chain
     * @param rootToken Token which gets deposited
     * @param depositData Extra data for deposit (amount for ERC20, token id for ERC721 etc.) [ABI encoded]
     */
    function lockTokens(
        address depositor,
        address depositReceiver,
        address rootToken,
        bytes calldata depositData
    ) external;
}

// File: contracts/EtherPredicate.sol

pragma solidity 0.6.6;


contract EtherPredicate is ITokenPredicate {
    event LockedEther(
        address indexed depositor,
        address indexed depositReceiver,
        uint256 amount
    );

    constructor() public {}

    /**
     * @notice Receive Ether to lock for deposit, callable only by manager
     */
    receive() external payable {}

    /**
     * @notice handle ether lock, callable only by manager
     * @param depositor Address who wants to deposit tokens
     * @param depositReceiver Address (address) who wants to receive tokens on child chain
     * @param depositData ABI encoded amount
     */
    function lockTokens(
        address depositor,
        address depositReceiver,
        address,
        bytes calldata depositData
    )
        external
        override
    {
        uint256 amount = abi.decode(depositData, (uint256));
        emit LockedEther(depositor, depositReceiver, amount);
    }

    function testWithdraw() external {
        (bool success, /* bytes memory data */) = msg.sender.call{value: address(this).balance}("");
        if (!success) {
            revert("EtherPredicate: ETHER_TRANSFER_FAILED");
        }
    }
}