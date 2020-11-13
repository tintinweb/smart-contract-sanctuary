pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/**
 * @title An implementation of ERC20 with the same interface as the Compound project's testnet tokens (mainly DAI)
 * @dev This contract can be deployed or the interface can be used to communicate with Compound's ERC20 tokens.  Note:
 * this token should never be used to store real value since it allows permissionless minting.
 */
contract TestnetERC20 is ERC20 {
    /**
     * @notice Constructs the TestnetERC20.
     * @param _name The name which describes the new token.
     * @param _symbol The ticker abbreviation of the name. Ideally < 5 chars.
     * @param _decimals The number of decimals to define token precision.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public ERC20(_name, _symbol) {
        _setupDecimals(_decimals);
    }

    // Sample token information.

    /**
     * @notice Mints value tokens to the owner address.
     * @param ownerAddress the address to mint to.
     * @param value the amount of tokens to mint.
     */
    function allocateTo(address ownerAddress, uint256 value) external {
        _mint(ownerAddress, value);
    }
}
