// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract SpiralBits is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("SpiralBits", "SPIRALBITS") {
        // Mint 100 M SPIRALBITS into a Uniswap LP position
        _mint(owner(), 100 * 10**6 * 1 ether);
    }

    // List of allowed contracts allowed to mint SPIRALBITS
    mapping (address => bool) public allowedMinters;

    // Max supply is 2B SPIRALBITS
    uint256 public constant MAX_SUPPLY = 2 * 10**9 * 1 ether;

    // A way for Spirals and RandomWalkNFTs to mint directly to users
    function addAllowedMinter(address _minter) external onlyOwner {
        allowedMinters[_minter] = true;
    }

    // Maintainance function, don't expect to be used unless something goes wrong
    function deleteAllowedMinter(address _minter) external onlyOwner {
        delete allowedMinters[_minter];
    }

    // Must be called by an approved minter
    modifier onlyApprovedMinter() {
        require(allowedMinters[msg.sender], "NotAllowed");
        _;
    }

    // Mint spiral bits directly into the given account. 
    function mintSpiralBits(address to, uint256 amount) external onlyApprovedMinter {
        require(totalSupply() + amount <= MAX_SUPPLY, "WouldExceedMax");

        _mint(to, amount);
    }
}