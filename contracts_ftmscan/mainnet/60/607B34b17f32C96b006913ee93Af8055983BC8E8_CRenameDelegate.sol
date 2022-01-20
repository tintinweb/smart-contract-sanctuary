pragma solidity ^0.5.16;

import "./CTokenInterfaces.sol";

/**
 * @title Cream's CCollateralCapErc20Delegate Contract
 * @notice CTokens which wrap an EIP-20 underlying and are delegated to
 * @author Cream
 */
contract CRenameDelegate is CTokenStorage, CErc20Storage, CDelegateInterface {
    /**
     * @notice Construct an empty delegate
     */
    constructor() public {}

    /**
     * @notice Event emitted when the name is updated
     */
    event NewTokenName(string oldTokenName, string newTokenName);

    /**
     * @notice Event emitted when the symbol is updated
     */
    event NewTokenSymbol(string oldTokenSymbol, string newTokenSymbol);

    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) public {
        require(msg.sender == admin, "admin only");

        (string memory name_, string memory symbol_) = abi.decode(data, (string, string));

        emit NewTokenName(name, name_);
        emit NewTokenSymbol(symbol, symbol_);

        name = name_;
        symbol = symbol_;
    }

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() public {
        // Shh -- we don't ever want this hook to be marked pure
        if (false) {
            implementation = address(0);
        }

        require(msg.sender == admin, "admin only");
    }
}