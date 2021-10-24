// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Pausable.sol";
import "./ERC20.sol";
import "./Ownable.sol";

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.1/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.1/contracts/token/ERC20//ERC20.sol";
//import https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol"

/**
 * @title DetailedERC20 token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract IXLToken is ERC20, Pausable, Ownable {
    uint256 private immutable _cap;
    /**
    * @dev Pausable
    */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
    /**
     * @dev Total Supply
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply
    ) ERC20(name, symbol) public {
        require(totalSupply > 0, "ERC20Capped: cap is 0");
        _cap = totalSupply;
        _mint(msg.sender,totalSupply);
    }
    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }
    
    function pause() public onlyOwner () {
        _pause();
    }
    
    function unpause() public onlyOwner () {
        _unpause();
    }
    
}