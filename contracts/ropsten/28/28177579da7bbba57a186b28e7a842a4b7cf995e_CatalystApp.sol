/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

pragma solidity 0.4.24;

contract CatalystApp {
    /// ACL
    bytes32 public constant MODIFY_ROLE = keccak256("MODIFY_ROLE");

    /// Errors
    string constant ERROR_OWNER_IN_USE = "ERROR_OWNER_IN_USE";
    string constant ERROR_DOMAIN_IN_USE = "ERROR_DOMAIN_IN_USE";
    string constant ERROR_ID_IN_USE = "ERROR_ID_IN_USE";
    string constant ERROR_CATALYST_NOT_FOUND = "ERROR_CATALYST_NOT_FOUND";
    string constant ERROR_OWNER_EMPTY = "ERROR_OWNER_EMPTY";
    string constant ERROR_DOMAIN_EMPTY = "ERROR_DOMAIN_EMPTY";
    string constant ERROR_CATALYST_ALREADY_REMOVED =
        "ERROR_CATALYST_ALREADY_REMOVED";

    struct Catalyst {
        bytes32 id;
        address owner;
        string domain;
        uint256 startTime;
        uint256 endTime;
    }

    // Catalyst by id
    mapping(bytes32 => Catalyst) public catalystById;
    // Domains used
    mapping(bytes32 => bool) public domains;
    // Owners used
    mapping(address => bool) public owners;
    // Catalyst indexes by id
    mapping(bytes32 => uint256) public catalystIndexById;
    // Catalyst ids
    bytes32[] public catalystIds;

    event AddCatalyst(
        bytes32 indexed _id,
        address indexed _owner,
        string _domain
    );
    event RemoveCatalyst(
        bytes32 indexed _id,
        address indexed _owner,
        string _domain
    );

    /**
     * @dev Add a new catalyst
     * @notice Add catalyst with owner `_owner` and domain `_domain`
     * @param _owner - owner of the catalyst
     * @param _domain - domain of the catalyst
     */
    function addCatalyst(address _owner, string _domain) external {
        require(_owner != address(0), ERROR_OWNER_EMPTY);

        bytes memory domain = abi.encodePacked(_domain);
        require(domain.length > 0, ERROR_DOMAIN_EMPTY);

        bytes32 domainHash = keccak256(domain);

        // Check if the owner and the domain are free
        require(!owners[_owner], ERROR_OWNER_IN_USE);
        require(!domains[domainHash], ERROR_DOMAIN_IN_USE);

        uint256 startTime = block.timestamp;

        // Calculate a catalyst id
        bytes32 id = keccak256(abi.encodePacked(startTime, _owner, _domain));

        // Check for collisions. Shouldn't happen
        require(catalystById[id].owner == address(0), ERROR_ID_IN_USE);

        // Store catalyst by its id
        catalystById[id] = Catalyst({
            id: id,
            owner: _owner,
            domain: _domain,
            startTime: startTime,
            endTime: 0
        });

        // Set owner and domain as used
        owners[_owner] = true;
        domains[domainHash] = true;

        // Store the catalyst id to be looped
        uint256 index = catalystIds.push(id);

        // Save mapping of the catalyst id within its position in the array
        catalystIndexById[id] = index - 1;

        // Log
        emit AddCatalyst(id, _owner, _domain);
    }

    /**
     * @dev Remove a catalyst
     * @notice Remove catalyst `_id` with owner `self.catalystOwner(_id): address` and domain `self.catalystDomain(_id): string`
     * @param _id - id of the catalyst
     */
    function removeCatalyst(bytes32 _id) external {
        Catalyst storage catalyst = catalystById[_id];
        bytes32 domainHash = keccak256(abi.encodePacked(catalyst.domain));

        require(catalyst.id == _id, ERROR_CATALYST_NOT_FOUND);
        require(owners[catalyst.owner], ERROR_CATALYST_ALREADY_REMOVED);
        require(domains[domainHash], ERROR_CATALYST_ALREADY_REMOVED);
        require(catalyst.endTime == 0, ERROR_CATALYST_ALREADY_REMOVED);

        // Catalyst length
        uint256 lastCatalystIndex = catalystCount() - 1;

        // Index of the catalyst to remove in the array
        uint256 removedIndex = catalystIndexById[_id];

        // Last catalyst id
        bytes32 lastCatalystId = catalystIds[lastCatalystIndex];

        // Override index of the removed catalyst with the last one
        catalystIds[removedIndex] = lastCatalystId;
        catalystIndexById[lastCatalystId] = removedIndex;

        // Update end time
        catalyst.endTime = block.timestamp;

        emit RemoveCatalyst(_id, catalyst.owner, catalyst.domain);

        // Clean storage
        catalystIds.length--;
        delete catalystIndexById[_id];
        owners[catalyst.owner] = false;
        domains[domainHash] = false;
    }

    /**
     * @dev Get catalyst count
     * @return count of catalyst
     */
    function catalystCount() public view returns (uint256) {
        return catalystIds.length;
    }

    /**
     * @dev Get catalyst owner
     * @param _id - id of the catalyst
     * @return catalyst owner
     */
    function catalystOwner(bytes32 _id) external view returns (address) {
        return catalystById[_id].owner;
    }

    /**
     * @dev Get catalyst domain
     * @param _id - id of the catalyst
     * @return catalyst domain
     */
    function catalystDomain(bytes32 _id) external view returns (string memory) {
        return catalystById[_id].domain;
    }
}