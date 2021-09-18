// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./Ownable.sol";

contract SolyunDigitalBank is ERC20, Ownable {
    using SafeMath for uint256;

    /**
     * The time interval from each 'mint' to the 'Solyun mining pool' is not less than 365 days
     */
    uint256 public constant  MINT_INTERVAL = 365 days;

    /**
     * All of the minted 'SLY' will be moved to the mainPool.
     */
    address public mainPool;

    /**
     * The unixtimestamp for the last mint.
     */
    uint256 public lastestMinting;

    /**
     * All of the minted 'SLY' burned in the corresponding mining pool if the released amount is not used up in the current year 
     * 
     */
    uint256[6] public maxMintOfYears;

    /**
     * The number of times 'SLY' has been executed
     */
    uint256 public yearMint = 1;

    constructor() 
        public 
        ERC20("SolyunDigitalBank", "SLY", 9) 
    {
        uint256 decimal = 10 ** uint256(decimals);
        /**
        * There will distribute 400,000,000 SLY in year 1
        *                       225,000,000 SLY in year 2
        *                       175,000,000 SLY in year 3
        *                       125,000,000 SLY in year 4
        *                       75,000,000  SLY in year 5
        *  In the future, up to 50,000,000 SLY can be released each year
        */
        maxMintOfYears[0] = 400000000 * decimal;
        maxMintOfYears[1] = 225000000 * decimal;
        maxMintOfYears[2] = 175000000 * decimal;
        maxMintOfYears[3] = 125000000 * decimal;
        maxMintOfYears[4] = 75000000 * decimal;
        maxMintOfYears[5] = 50000000 * decimal;
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
     * Distribute SLY to the main mining pool according to the SLY limit that can be released every year
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

    function burnFrom(address from_, uint256 amount_) external {
        require(from_ != address(0), "burn from zero");
        
        _approve(from_, msg.sender, _allowances[from_][msg.sender].sub(amount_));
        _burn(from_, amount_);
    }
}