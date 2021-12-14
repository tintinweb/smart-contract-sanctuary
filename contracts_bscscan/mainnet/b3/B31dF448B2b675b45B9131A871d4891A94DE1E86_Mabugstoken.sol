// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./Ownable.sol";

contract Mabugstoken is ERC20, Ownable {
    using SafeMath for uint256;
    uint256 public constant  MINT_INTERVAL = 365 days;
    address public mainPool;
    uint256 public lastestMinting;
    uint256[6] public maxMintOfYears;
    uint256 public yearMint = 0;

    constructor() 
        public 
        ERC20("MABUGS", "MBG", 18) 
    {
        uint256 decimal = 10 ** uint256(decimals);
        maxMintOfYears[0] = 400000000 * decimal;
        maxMintOfYears[1] = 225000000 * decimal;
        maxMintOfYears[2] = 175000000 * decimal;
        maxMintOfYears[3] = 125000000 * decimal;
        maxMintOfYears[4] = 75000000 * decimal;
        maxMintOfYears[5] = 50000000 * decimal;
    }

    function nextMinting() public view returns(uint256) {
        return lastestMinting + MINT_INTERVAL;
    }

    function setMainPool(address pool_) external onlyOwner {
        require(pool_ != address(0));
        mainPool = pool_;
    }


    function mint(address dest_) external {
        require(msg.sender == mainPool, "invalid minter");
        require(lastestMinting.add(MINT_INTERVAL) < block.timestamp, "minting not allowed yet");

        uint256 amountThisYear = yearMint < 5 ? maxMintOfYears[yearMint] : maxMintOfYears[5];
        yearMint += 1;
        lastestMinting = block.timestamp;

        _mint(dest_, amountThisYear); 
    }

    function burn(uint256 amount_) external { 
        _burn(msg.sender, amount_);
    }

    function burnFrom(address from_, uint256 amount_) external {
        require(from_ != address(0), "burn from zero");
        
        _approve(from_, msg.sender, _allowances[from_][msg.sender].sub(amount_));
        _burn(from_, amount_);
    }
}