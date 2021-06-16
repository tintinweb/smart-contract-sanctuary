// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

/// @title OpenTherapoid
/// @notice ERC-20 implementation of OpenTherapoid token
contract OpenTherapoid is ERC20, Ownable {
    uint8 public tokenDecimals;

    /**
     * @dev Sets the values for {name = OpenTherapoidCoin}, {totalSupply = 210000} and {symbol = SCOIN}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(uint256 fixedSupply) ERC20("ScienceCoin", "SCOIN") {
        tokenDecimals = 18;
        super._mint(msg.sender, fixedSupply); // Since Total supply 210000
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     * The receive function is executed on a call to the contract with empty calldata.
     */
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev To update number of decimals for a token
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     */
    function updateDecimals(uint8 noOfDecimals) public onlyOwner {
        tokenDecimals = noOfDecimals;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Requirements:
     *
     * - invocation can be done, only by the contract owner.
     */
    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     */
    function burn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }

    /**
     * @dev To transfer all BNBs stored in the contract to the caller
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     */
    function withdrawAll() public payable onlyOwner {
        require(
            payable(msg.sender).send(address(this).balance),
            "Withdraw failed"
        );
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view override returns (uint8) {
        return tokenDecimals;
    }
}