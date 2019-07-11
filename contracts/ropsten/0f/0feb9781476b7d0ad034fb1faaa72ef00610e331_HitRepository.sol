/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity 0.5.6;

/**
 * @author Tyler Chen
 * @title HitRepository
 * @dev The contract to save the repository informations, last update: 2019-06-29, version: 0.0.3.
 */
contract HitRepository {
    /**
     * @dev the event for use to find out the transaction is success or fail.
     */
    event Success(bool value);
    /**
     * @dev the contract/repository owner.
     */
    address public owner;
    /**
     * @dev repository id also as repository id.
     */
    uint256 public id;
    /**
     * @dev repository name mapping to repository id.
     */
    mapping(uint256 => uint256) public hash_id;
    /**
     * @dev repository id mapping to repository name.
     */
    mapping(uint256 => string ) public id_name;
    /**
     * @dev repository id mapping to repository url.
     */
    mapping(uint256 => string ) public id_url;
    /**
     * @dev repository id mapping to address by type, use for delegator, member and pull request member.
     */
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public id_type_address;
    /**
     * @dev repository id mapping to address count by type.
     */
    mapping(uint256 => mapping(uint256 => mapping(uint256 => address))) public id_type_count_address;
    /**
     * @dev repository id mapping to string by type, use for pull request url.
     */
    mapping(uint256 => mapping(uint256 => mapping(uint256 => string))) public id_type_count_string;
    /**
     * @dev repository id mapping to string count by type.
     */
    mapping(uint256 => mapping(uint256 => uint256)) public id_type_count;
    /**
     * @dev repository id mapping to disable by type.
     */
    mapping(uint256 => mapping(uint256 => bool)) public id_type_disable;

    /**
     * @dev how to search delegator, var count = id_type_count(id, 1), 
     * @dev var address = id_type_count_address(id, 1, count), var enable = id_type_address(id, 1, address).
     */
    uint256 public constant TYPE_DELEGATOR = uint256(1);
    /**
     * @dev how to search member, var count = id_type_count(id, 2), 
     * @dev var address = id_type_count_address(id, 2, count), var enable = id_type_address(id, 2, address).
     */
    uint256 public constant TYPE_MEMBER = uint256(2);
    /**
     * @dev how to search pr member, var count = id_type_count(id, 3), 
     * @dev var address = id_type_count_address(id, 3, count), var enable = id_type_address(id, 3, address).
     */
    uint256 public constant TYPE_PR_MEMBER = uint256(3);
    /**
     * @dev how to search authorized pr, var count = id_type_count(id, 4), 
     * @dev var string = id_type_count_string(id, 4, count).
     */
    uint256 public constant TYPE_PR_AUTH = uint256(4);
    /**
     * @dev how to search community pr, var count = id_type_count(id, 5), 
     * @dev var string = id_type_count_string(id, 5, count).
     */
    uint256 public constant TYPE_PR_COMM = uint256(5);
    //
    uint256 public constant VERSION = uint256(2019071100);

    /**
     * @dev create the contract with the contract owner.
     */
    constructor() public {
        owner = msg.sender;
        emit Success(true);
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    /**
     * @dev Throws if the repository is not exists.
     */
    modifier hasRepository(uint256 _id) {
        require(_id > 0 && bytes(id_name[_id]).length > 0);
        _;
    }
    /**
     * @dev Throws if the type is not exists.
     */
    modifier hasType(uint256 _type) {
        require(_type >= TYPE_DELEGATOR && _type <= TYPE_PR_COMM);
        _;
    }
    /**
     * @dev get repository id by name.
     * @param _name The repository name.
     */
    function repositoryId(string memory _name) public view returns (uint256) {
        bytes memory nameBytes = bytes(_name);
        if(nameBytes.length < 1) {
            return uint256(0);
        }
        uint256 hash = uint256(keccak256(nameBytes));
        return hash_id[hash];
    }
    /**
     * @dev add repository.
     * @param _name The repository name.
     */
    function addRepository(string memory _name) public onlyOwner {
        bytes memory nameBytes = bytes(_name);
        require(nameBytes.length > 0);
        uint256 hash = uint256(keccak256(nameBytes));// hash repository name.
        require(hash_id[hash] == 0); // make sure the new repository name is not exists.
        //
        id = id + 1;// repository id.
        hash_id[hash] = id;// mapping hash with id.
        id_name[id] = _name;// mapping id with repository name.
        emit Success(true);
    }
    /**
     * @dev update repository name.
     * @param _name The repository name.
     * @param _newName The new repository name.
     */
    function updateName(string memory _name, string memory _newName) public onlyOwner {
        bytes memory newNameBytes = bytes(_newName);
        require(newNameBytes.length > 0);
        uint256 idx = repositoryId(_name);
        require(idx > 0);
        //
        uint256 hash = uint256(keccak256(bytes(_name)));
        uint256 hashNew = uint256(keccak256(newNameBytes));
        delete hash_id[hash];// remove old hash
        id_name[idx] = _newName;// set new repository name.
        hash_id[hashNew] = idx;// add new hash and point to old repository id.
        emit Success(true);
    }
    /**
     * @dev update repository url.
     * @param _name The repository name.
     * @param _url The repository url.
     */
    function updateUrl(string memory _name, string memory _url) public {
        bytes memory urlBytes = bytes(_url);
        require(urlBytes.length > 0);
        uint256 idx = repositoryId(_name);
        require(idx > 0);
        // owner or delegator or repository member can update url.
        require(msg.sender == owner 
                || id_type_address[idx][TYPE_DELEGATOR][msg.sender] == true
                || id_type_address[idx][TYPE_MEMBER][msg.sender] == true);
        //
        id_url[idx] = _url;
        emit Success(true);
    }
    /**
     * @dev update repository url by repository id.
     * @param _id The repository id.
     * @param _url The repository url.
     */
    function updateUrlById(uint256 _id, string memory _url) public hasRepository(_id) {
        bytes memory urlBytes = bytes(_url);
        require(urlBytes.length > 0);
        // owner or delegator or repository member can update url.
        require(msg.sender == owner 
                || id_type_address[_id][TYPE_DELEGATOR][msg.sender] == true
                || id_type_address[_id][TYPE_MEMBER][msg.sender] == true);
        //
        id_url[_id] = _url;
        emit Success(true);
    }
    /**
     * @dev add repository delegator by repository name.
     * @param _name The repository name.
     * @param _address The repository delegator.
     */
    function addDelegator(string memory _name, address _address) public onlyOwner {
        require(_address != address(0));
        uint256 idx = repositoryId(_name);
        require(idx > 0);
        //
        addTypeAddressById(idx, _address, TYPE_DELEGATOR);
        emit Success(true);
    }
    /**
     * @dev add repository delegator by repository id.
     * @param _id The repository id.
     * @param _address The repository delegator.
     */
    function addDelegatorById(uint256 _id, address _address) public onlyOwner hasRepository(_id) {
        require(_address != address(0));
        //
        addTypeAddressById(_id, _address, TYPE_DELEGATOR);
        emit Success(true);
    }
    /**
     * @dev remove repository delegator.
     * @param _name The repository name.
     * @param _address The repository delegator.
     */
    function removeDelegator(string memory _name, address _address) public onlyOwner {
        require(_address != address(0));
        uint256 idx = repositoryId(_name);
        require(idx > 0);
        //
        removeTypeAddressById(idx, _address, TYPE_DELEGATOR);
        emit Success(true);
    }
    /**
     * @dev remove repository delegator by repository id.
     * @param _id The repository id.
     * @param _address The repository delegator.
     */
    function removeDelegatorById(uint256 _id, address _address) public onlyOwner hasRepository(_id) {
        require(_address != address(0));
        //
        removeTypeAddressById(_id, _address, TYPE_DELEGATOR);
        emit Success(true);
    }
    /**
     * @dev add repository member by repository name.
     * @param _name The repository name.
     * @param _address The repository member.
     */
    function addMember(string memory _name, address _address) public {
        require(_address != address(0));
        uint256 idx = repositoryId(_name);
        require(idx > 0);
        // owner or delegator can add/remove repository member.
        require(msg.sender == owner 
                || id_type_address[idx][TYPE_DELEGATOR][msg.sender] == true);
        //
        addTypeAddressById(idx, _address, TYPE_MEMBER);
        emit Success(true);
    }
    /**
     * @dev add repository member by repository id.
     * @param _id The repository id.
     * @param _address The repository member.
     */
    function addMemberById(uint256 _id, address _address) public hasRepository(_id) {
        require(_address != address(0));
        // owner or delegator can add/remove repository member.
        require(msg.sender == owner 
                || id_type_address[_id][TYPE_DELEGATOR][msg.sender] == true);
        //
        addTypeAddressById(_id, _address, TYPE_MEMBER);
        emit Success(true);
    }
    /**
     * @dev remove repository member by repository name.
     * @param _name The repository name.
     * @param _address The repository member.
     */
    function removeMember(string memory _name, address _address) public {
        require(_address != address(0));
        uint256 idx = repositoryId(_name);
        require(idx > 0);
        // owner or delegator can add/remove repository member.
        require(msg.sender == owner 
                || id_type_address[idx][TYPE_DELEGATOR][msg.sender] == true);
        //
        removeTypeAddressById(idx, _address, TYPE_MEMBER);
        emit Success(true);
    }
    /**
     * @dev remove repository member by repository id.
     * @param _id The repository id.
     * @param _address The repository member.
     */
    function removeMemberById(uint256 _id, address _address) public hasRepository(_id) {
        require(_address != address(0));
        // owner or delegator can add/remove repository member.
        require(msg.sender == owner 
                || id_type_address[_id][TYPE_DELEGATOR][msg.sender] == true);
        //
        removeTypeAddressById(_id, _address, TYPE_MEMBER);
        emit Success(true);
    }
    /**
     * @dev add repository pull request member by repository name.
     * @param _name The repository name.
     * @param _address The repository member.
     */
    function addPrMember(string memory _name, address _address) public {
        require(_address != address(0));
        uint256 idx = repositoryId(_name);
        require(idx > 0);
        // owner or delegator can add/remove pull request member.
        require(msg.sender == owner 
                || id_type_address[idx][TYPE_DELEGATOR][msg.sender] == true);
        //
        addTypeAddressById(idx, _address, TYPE_PR_MEMBER);
        emit Success(true);
    }
    /**
     * @dev add repository pull request member by repository id.
     * @param _id The repository id.
     * @param _address The repository member.
     */
    function addPrMemberById(uint256 _id, address _address) public hasRepository(_id) {
        require(_address != address(0));
        // owner or delegator can add/remove pull request member.
        require(msg.sender == owner 
                || id_type_address[_id][TYPE_DELEGATOR][msg.sender] == true);
        //
        addTypeAddressById(_id, _address, TYPE_PR_MEMBER);
        emit Success(true);
    }
    /**
     * @dev remove repository pull request member by repository name.
     * @param _name The repository name.
     * @param _address The repository member.
     */
    function removePrMember(string memory _name, address _address) public {
        require(_address != address(0));
        uint256 idx = repositoryId(_name);
        require(idx > 0);
        // owner or delegator can add/remove pull request member.
        require(msg.sender == owner 
                || id_type_address[idx][TYPE_DELEGATOR][msg.sender] == true);
        //
        removeTypeAddressById(idx, _address, TYPE_PR_MEMBER);
        emit Success(true);
    }
    /**
     * @dev remove repository pull request member by repository id.
     * @param _id The repository id.
     * @param _address The repository member.
     */
    function removePrMemberById(uint256 _id, address _address) public hasRepository(_id) {
        require(_address != address(0));
        // owner or delegator can add/remove pull request member.
        require(msg.sender == owner 
                || id_type_address[_id][TYPE_DELEGATOR][msg.sender] == true);
        //
        removeTypeAddressById(_id, _address, TYPE_PR_MEMBER);
        emit Success(true);
    }
    /**
     * @dev add pull request by repository name.
     * @param _name The repository name.
     * @param _url The pull request url.
     */
    function addPullRequest(string memory _name, string memory _url) public {
        uint256 idx = repositoryId(_name);
        require(idx > 0);
        require(bytes(_url).length > 0);
        // owner, delegator, repository member and pull request member is authorized.
        if(msg.sender == owner 
            || id_type_address[idx][TYPE_DELEGATOR][msg.sender] == true
            || id_type_address[idx][TYPE_MEMBER][msg.sender] == true
            || id_type_address[idx][TYPE_PR_MEMBER][msg.sender] == true) {
            addTypeStringById(idx, _url, TYPE_PR_AUTH);
        } else {
            addTypeStringById(idx, _url, TYPE_PR_COMM);
        }
        emit Success(true);
    }
    /**
     * @dev add pull request by repository id.
     * @param _id The repository id.
     * @param _url The pull request url.
     */
    function addPullRequestById(uint256 _id, string memory _url) public hasRepository(_id) {
        require(bytes(_url).length > 0);
        // owner, delegator, repository member and pull request member is authorized.
        if(msg.sender == owner 
            || id_type_address[_id][TYPE_DELEGATOR][msg.sender] == true
            || id_type_address[_id][TYPE_MEMBER][msg.sender] == true
            || id_type_address[_id][TYPE_PR_MEMBER][msg.sender] == true) {
            addTypeStringById(_id, _url, TYPE_PR_AUTH);
        } else {
            addTypeStringById(_id, _url, TYPE_PR_COMM);
        }
        emit Success(true);
    }
    /**
     * @dev disable type by repository name.
     * @param _name The repository name.
     * @param _type The data type.
     */
    function disableType(string memory _name, uint256 _type) public hasType(_type) {
        uint256 idx = repositoryId(_name);
        require(idx > 0);
        // owner or delegator can enable/disable type.
        require(msg.sender == owner 
                || id_type_address[idx][TYPE_DELEGATOR][msg.sender] == true);
        //
        id_type_disable[idx][_type] = true;
        emit Success(true);
    }
    /**
     * @dev disable type by repository id.
     * @param _id The repository id.
     * @param _type The data type.
     */
    function disableTypeById(uint256 _id, uint256 _type) public hasType(_type) hasRepository(_id) {
        // owner or delegator can enable/disable type.
        require(msg.sender == owner 
                || id_type_address[_id][TYPE_DELEGATOR][msg.sender] == true);
        //
        id_type_disable[_id][_type] = true;
        emit Success(true);
    }
    /**
     * @dev enable type by repository name.
     * @param _name The repository name.
     * @param _type The data type.
     */
    function enableType(string memory _name, uint256 _type) public hasType(_type) {
        uint256 idx = repositoryId(_name);
        require(idx > 0);
        // owner or delegator can enable/disable type.
        require(msg.sender == owner 
                || id_type_address[idx][TYPE_DELEGATOR][msg.sender] == true);
        //
        id_type_disable[idx][_type] = false;
        emit Success(true);
    }
    /**
     * @dev enable type by repository id.
     * @param _id The repository id.
     * @param _type The data type.
     */
    function enableTypeById(uint256 _id, uint256 _type) public hasType(_type) hasRepository(_id) {
        // owner or delegator can enable/disable type.
        require(msg.sender == owner 
                || id_type_address[_id][TYPE_DELEGATOR][msg.sender] == true);
        //
        id_type_disable[_id][_type] = false;
        emit Success(true);
    }
    /**
     * @dev add address to type.
     * @param _id The repository id.
     * @param _address address.
     * @param _type type.
     */
    function addTypeAddressById(uint256 _id, address _address, uint256 _type) private {
        id_type_address[_id][_type][_address] = true;
        uint256 typeCount = id_type_count[_id][_type] + 1;
        id_type_count_address[_id][_type][typeCount] = _address;
        id_type_count[_id][_type] = typeCount;
    }
    /**
     * @dev remove address from type.
     * @param _id The repository id.
     * @param _address address.
     * @param _type type.
     */
    function removeTypeAddressById(uint256 _id, address _address, uint256 _type) private {
        id_type_address[_id][_type][_address] = false;
    }
    /**
     * @dev add string to type.
     * @param _id The repository id.
     * @param _string string.
     * @param _type type.
     */
    function addTypeStringById(uint256 _id, string memory _string, uint256 _type) private {
        uint256 typeCount = id_type_count[_id][_type] + 1;
        id_type_count_string[_id][_type][typeCount] = _string;
        id_type_count[_id][_type] = typeCount;
    }
}