// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./ERC20.sol";

contract MockBUSD is ERC20 {

    constructor() ERC20("TestBUSD", "TBUSD") {}

    /**
     * @notice Mints desired amount of tokens for the recipient
     * @param _receiver Receiver of the tokens.
     * @param _amount Amount (in wei - smallest decimals)
     */
    function mintFor(address _receiver, uint256 _amount) external {
        require(_receiver != address(0), "Zero address");
        require(_receiver != address(this), "Incorrect address");
        require(_amount > 0, "Incorrect amount");
        _mint(_receiver, _amount);
    }

    function mint(uint256 _amount) external {
        require(_amount > 0, "Incorrect amount");
        _mint(_msgSender(), _amount);
    }
}