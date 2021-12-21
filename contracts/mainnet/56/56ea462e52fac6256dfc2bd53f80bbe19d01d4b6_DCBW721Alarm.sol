/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

/** 
 *  SourceUnit: c:\Users\Jad\Documents\code\Cryptoware\dcb-lottery\blockend\contracts\DCBW721Alarm.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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




/** 
 *  SourceUnit: c:\Users\Jad\Documents\code\Cryptoware\dcb-lottery\blockend\contracts\DCBW721Alarm.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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




/** 
 *  SourceUnit: c:\Users\Jad\Documents\code\Cryptoware\dcb-lottery\blockend\contracts\DCBW721Alarm.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}


/** 
 *  SourceUnit: c:\Users\Jad\Documents\code\Cryptoware\dcb-lottery\blockend\contracts\DCBW721Alarm.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

/// @notice Chain Link Keeper interface
////import "../node_modules/@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

/// @notice Access Control
////import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/// @notice draw contract interface
interface IDRAW {
    function drawNumber() external returns (bool);
}

/**
 * @title DCBW721 Alarm
 * @notice ChainLink Keeper-compatible DCBW721 trigger contract
 * @author cryptoware.eth | DCB.world
**/
contract DCBW721Alarm is
    Ownable,
    KeeperCompatibleInterface
{
    /// @notice Requested contract address
    address private requested;

    /// @notice alarm interval in seconds
    uint256 private interval;

    /// @notice last alarm timestamp
    uint256 private lastTimeStamp;

    /**
     * @notice constructor
     * @param _requested The ERC721 contract that should be requested on trigger
     * @param _interval alarm interval in seconds
    **/
    constructor(
        address _requested,
        uint256 _interval
    ) {
        interval = _interval;
        requested = _requested;
        lastTimeStamp = block.timestamp; /* solium-disable-line */
    }

    /**
     * @notice Checks if the contract requires work to be done
     * @return returns true whenever timestamp difference is greater than interval set
    **/
    function checkUpkeep(bytes calldata data) external override view returns (bool, bytes memory){
        return (checkTimestampInterval(), data);
    }

    /**
     * @notice performUpkeep should change state
    **/
    function performUpkeep(bytes calldata) external override{
        require (checkTimestampInterval(), "DCBW721 Alarm: Malicious Call Attempt");
        lastTimeStamp = block.timestamp; /* solium-disable-line */
        bool success = IDRAW(payable(requested)).drawNumber();
        require(success, "DCBW721 Alarm: drawNumber failed");
    }

    /**
     * @notice checks timestamp difference against interval
     */
    function checkTimestampInterval() internal view returns (bool) {
        return interval > 0 && (block.timestamp - lastTimeStamp) > interval; /* solium-disable-line */
    }

    /**
     * @notice updates the automated DCBW721 contract address
     * @param _requested address of the DCBW721 contract
    **/
    function setRequestedAddress(address _requested) external onlyOwner{
        require(_requested != address(0), "DCBW721 Alarm: Address cannot be 0");
        require(
            requested != _requested,
            "DCBW721: requested address cannot be same as before"
        );
        requested = _requested;
    }

    /**
     * @notice updates the time interval between Draws
     * @param _interval time for next Draw
    **/
    function updateInterval(uint256 _interval) external onlyOwner{
        interval = _interval;
    }
}