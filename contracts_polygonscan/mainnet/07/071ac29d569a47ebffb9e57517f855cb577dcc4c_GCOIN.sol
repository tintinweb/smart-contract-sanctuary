// SPDX-License-Identifier: MIT
   
pragma solidity 0.8.11;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./MintOwnable.sol";

contract GCOIN is MintOwnable, Ownable, ERC20Burnable {

    uint256 public constant TOKEN_MAX_CAP = 150_000_000*1e18; // 150 million * 10^18

    constructor() ERC20('GCOIN', 'GFC') {
        _mint(msg.sender, TOKEN_MAX_CAP);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyMinter {
        require(totalSupply() + amount <= TOKEN_MAX_CAP, "Exceeded TOKEN_MAX_CAP");
        _mint(to, amount);
    }
}