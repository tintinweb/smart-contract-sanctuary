// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./Ownable.sol";

contract MAFIAFOOTToken is ERC20, Ownable {
    using SafeMath for uint256;

    /**
     * The time interval from each 'mint' to the 'MFF mining pool' is not less than 365 days
     */
    uint256 public constant  MINT_INTERVAL = 365 days;

    /**
     * All of the minted 'MFF' will be moved to the mainPool.
     */
    address public mainPool;

    /**
     * The unixtimestamp for the last mint.
     */
    uint256 public lastestMinting;

    /**
     * All of the minted 'MFF' burned in the corresponding mining pool if the released amount is not used up in the current year 
     * 
     */
    uint256[6] public maxMintOfYears;

    /**
     * The number of times 'mint' has been executed
     */
    uint256 public yearMint = 0;

    constructor() public 
        ERC20("Mafiafoot", "MFF", 18) 
    {
        uint256 decimal = 10 ** uint256(decimals);
        /**
        * There will distribute 50,000,000 MFF in year 1
        *                       20,000,000 MFF in year 2
        *                       10,000,000 MFF in year 3
        *                       5,000,000 MFF in year 4
        *                       5,000,000  MFF in year 5
        *  In the future, up to 5,000,000 MFF can be released each year
        */
        maxMintOfYears[0] = 50000000 * decimal;
        maxMintOfYears[1] = 20000000 * decimal;
        maxMintOfYears[2] = 10000000 * decimal;
        maxMintOfYears[3] = 5000000 * decimal;
        maxMintOfYears[4] = 5000000 * decimal;
        maxMintOfYears[5] = 5000000 * decimal;
    }

    /**
     * The unixtimestamp of 'mint' can be executed next time
     */
    function nextMinting() public view returns(uint256) {
        return lastestMinting + MINT_INTERVAL;
    }

    /** 
     * Set the target mining pool contract for minting
     */
    function setMainPool(address pool_) external onlyOwner {
        require(pool_ != address(0));
        mainPool = pool_;
    }

    /**
     * Distribute MFF to the main mining pool according to the MFF limit that can be released every year
     */
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

}