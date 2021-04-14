/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

pragma solidity ^0.5.17;

/**
 * @author Mustafa Refaey
 * @dev Implementation of PrivateStamp contract.
 */
contract PrivateStamp {
    /// the owner of the contract
    address public owner;

    /// frontend app version
    uint256 appVersion;

    /// a mapping of the hash uploaders and their hashes, stamped by the block number
    mapping(address => mapping(string => uint256)) private hashes;

    /// an event to be emitted when a new hash has been added
    event LogAdditionEvent(
        address indexed stampper,
        uint256 blockNumber,
        string hash
    );

    /// an event to be emitted when a new hash has been added
    event LogAppVersionUpdated(uint256 appVersion);

    /// checks if the msg.sender is the owner of the contract
    modifier ownerOnly() {
        require(msg.sender == owner, "You must be the owner!");
        _;
    }

    constructor() public {
        /// set the owner as the contract deployer
        owner = msg.sender;

        appVersion = 1;
    }

    /// @notice Stores the hash in the contract's state
    /// @param hash The hash to be stored
    function storeHash(string memory hash) public {
        require(
            hashes[msg.sender][hash] == 0,
            "This hash has been stored previously!"
        );

        hashes[msg.sender][hash] = block.number;

        emit LogAdditionEvent(msg.sender, block.number, hash);
    }

    /// @notice Verifies if the hash exists
    /// @param stampper The address of the stampper
    /// @param hash The hash to be stored
    /// @return the block number of a hash if it exists in the contract's state
    /// or returns 0
    function verifyHash(address stampper, string memory hash)
        public
        view
        returns (uint256)
    {
        return hashes[stampper][hash];
    }

    /// @notice Updates the frontend app version
    /// @param _appVersion The new frontend app version
    function updateAppVersion(uint256 _appVersion) public ownerOnly {
        appVersion = _appVersion;

        emit LogAppVersionUpdated(_appVersion);
    }

    /// @notice Retrieves the frontend app version
    /// @return the frontend app version
    function getAppVersion() public view returns (uint256) {
        return appVersion;
    }
}