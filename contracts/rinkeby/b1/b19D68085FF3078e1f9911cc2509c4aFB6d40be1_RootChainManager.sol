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

// File: contracts/ContextMixin.sol

pragma solidity 0.6.6;

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}
// File: contracts/RootChainManager.sol

pragma solidity 0.6.6;



contract RootChainManager is ContextMixin {
    address public predicateAddress;
    address public ethPredicateAddress;

    function setPredicateAddress(address addr, address eth) external {
        predicateAddress = addr;
        ethPredicateAddress = eth;
    }

    function _msgSender()
        internal
        view
        returns (address payable sender)
    {
        return ContextMixin.msgSender();
    }

    /**
     * @notice Move ether from root to child chain, accepts ether transfer
     * Keep in mind this ether cannot be used to pay gas on child chain
     * Use Matic tokens deposited using plasma mechanism for that
     * @param user address of account that should receive WETH on child chain
     */
    function depositEtherFor(address user) external payable {
        _depositEtherFor(user);
    }

    /**
     * @notice Move tokens from root to child chain
     * @dev This mechanism supports arbitrary tokens as long as its predicate has been registered and the token is mapped
     * @param user address of account that should receive this deposit on child chain
     * @param rootToken address of token that is being deposited
     * @param depositData bytes data that is sent to predicate and child token contracts to handle deposit
     */
    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external {
        _depositFor(user, rootToken, depositData);
    }

    function _depositEtherFor(address user) private {
        bytes memory depositData = abi.encode(msg.value);
        ITokenPredicate(ethPredicateAddress).lockTokens(
            _msgSender(),
            user,
            address(0),
            depositData
        );

        // payable(typeToPredicate[tokenToType[ETHER_ADDRESS]]).transfer(msg.value);
        // transfer doesn't work as expected when receiving contract is proxified so using call
        (bool success, /* bytes memory data */) = ethPredicateAddress.call{value: msg.value}("");
        if (!success) {
            revert("RootChainManager: ETHER_TRANSFER_FAILED");
        }
    }

    function _depositFor(
        address user,
        address rootToken,
        bytes memory depositData
    ) private {
        ITokenPredicate(predicateAddress).lockTokens(
            _msgSender(),
            user,
            rootToken,
            depositData
        );
    }
}