// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Station.sol";
import "../interfaces/IStation.sol";

contract Headquarter is Ownable {
    event RegisteredStationLog(address indexed protocol);
    event StationCreated(address indexed stationContract, bool approved);

    IStation[] public stations;
    mapping (IStation => bool) approvedStations;

    function registerStation() public {
        stations.push(IStation(msg.sender));
        emit RegisteredStationLog(msg.sender);
    }

    function approveStation(uint index, bool approve) external onlyOwner {
        approvedStations[stations[index]] = approve;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IStation.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IStrategy.sol";
import "./Campaign.sol";
import "./governance/Headquarter.sol";

contract Station is Ownable, IStation {
    string metadata_uri;
    Headquarter public immutable headquarter;
    address payable treasury;

    mapping(uint => Campaign) campaigns;

    IFactory[] public campaignFactories;

    uint listedCampaignCount;

    constructor(string memory _metadata, address payable _treasury, Headquarter hq){
        hq.registerStation();
        headquarter = hq;
        metadata_uri = _metadata;
        treasury = _treasury;
    }

    function addSupportedFactory(IFactory factory) external override onlyOwner {
        campaignFactories.push(factory);
    }

     function listCampaign(Campaign campaign) external override {
         campaigns[listedCampaignCount] = campaign;
         listedCampaignCount += 1;
     }

    function getStationMeta() external override view returns(string memory meta){
        return metadata_uri;
    }

    // function getAllCampaigns() external view returns(IFactory.Campaign[] memory){
    //     return campaigns;
    // }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IFactory.sol";
import "../Campaign.sol";

interface IStation {
    event CampaignRegistered(address newAddress);

    function getStationMeta() external view returns (string memory meta);

    function listCampaign(Campaign campaign) external;

     function addSupportedFactory(IFactory factory) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IStrategy.sol";
interface IFactory {
    event CampaignCreated(address newAddress);

    function deployCampaign(
        string memory metadata,
         address payable _treasury,
        uint256 _fundingEndTime,
        uint256 _fundTarget,
        uint256 _fundingStartTime)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IStrategy {
    /// @notice Balance per ERC-20 token per account in shares.
    function balanceOf(address user, address erc20) external view returns (uint256);

    function pledge(uint256 amount, address token) external;

    function payOut(uint256 amount) external returns (uint256);

    function changeTreasuryAddress(address payable newTreasury) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IStrategy.sol";

contract Campaign is Ownable {
    string metadata_uri;
    IStrategy strategy;

    constructor(string memory metadata, IStrategy strat) {
        metadata_uri = metadata;
        strategy = strat;
    }

    function changeMetadata(string memory newMetadata) external {
       metadata_uri = newMetadata;
    }
}