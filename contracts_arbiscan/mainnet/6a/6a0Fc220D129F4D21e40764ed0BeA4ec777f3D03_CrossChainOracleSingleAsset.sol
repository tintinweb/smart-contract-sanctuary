/**
 *Submitted for verification at arbiscan.io on 2021-12-25
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// Sources flattened with hardhat v2.7.0 https://hardhat.org

// File contracts/Staking/Owned.sol


// https://docs.synthetix.io/contracts/Owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor (address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


// File contracts/Oracle/CrossChainOracleSingleAsset.sol


// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// =================== CrossChainOracleSingleAsset ====================
// ====================================================================
// Price manually set by a bot for a single token
// Has some AggregatorV3Interface / Chainlink compatibility

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian

contract CrossChainOracleSingleAsset is Owned {
    
    // Core
    address public timelock_address;
    address public bot_address;
    address public tkn_address;
    
    // Prices
    uint256 public price;
    uint256 public last_updated_time;

    // AggregatorV3Interface stuff
    uint8 public decimals = 18;
    string public description;
    uint256 public version = 1;

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnGov() {
        require(msg.sender == owner || msg.sender == timelock_address, "Not owner or timelock");
        _;
    }

    modifier onlyByOwnGovBot() {
        require(msg.sender == owner || msg.sender == timelock_address || msg.sender == bot_address, "Not owner, tlck, or bot");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor (
        address _creator_address,
        address _tkn_address,
        address _timelock_address,
        address _bot_address,
        uint256 _initial_price_e6,
        string memory _description
    ) Owned(_creator_address) {
        tkn_address = _tkn_address;
        timelock_address = _timelock_address;
        bot_address = _bot_address;

        description = _description;

        price = _initial_price_e6;
        last_updated_time = block.timestamp;
    }

    /* ========== VIEWS ========== */

    function getPrice() public view returns (uint256) {
        return price;
    }

    // AggregatorV3Interface / Chainlink compatibility
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        int256 price_e18 = int256(price) * 1e12;
        return (0, price_e18, 0, last_updated_time, 0);
    }

    /* ========== RESTRICTED FUNCTIONS, BUT BOT CAN SET ========== */

    // Set the price for a token, old interface
    function setPrice(address token_address, uint256 price_e6) public onlyByOwnGovBot {
        require(token_address == tkn_address, "Invalid token");

        setPrice(price_e6);
        last_updated_time = block.timestamp;
    }

    // Set the price for a token
    function setPrice(uint256 price_e6) public onlyByOwnGovBot {
        price = price_e6;
    }

    // Batch set prices for multiple tokens, old interface
    function setMultiplePrices(address[] memory token_addresses, uint256[] memory prices_e6) public onlyByOwnGovBot {
        require(token_addresses.length == 1, "1 token only");
        require(token_addresses[0] == tkn_address, "Invalid token");

        setPrice(prices_e6[0]);
        last_updated_time = block.timestamp;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setTimelock(address _new_timelock_address) external onlyByOwnGov {
        timelock_address = _new_timelock_address;
    }

    function setBot(address _new_bot_address) external onlyByOwnGov {
        bot_address = _new_bot_address;
    }

}