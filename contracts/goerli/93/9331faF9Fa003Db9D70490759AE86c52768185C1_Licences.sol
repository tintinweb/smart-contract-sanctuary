/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/IEIP1753.sol

pragma solidity ^0.6.2;

interface EIP1753 {
    function grantAuthority(address who) external;

    function revokeAuthority(address who) external;

    function hasAuthority(address who) external pure returns (bool);

    function issue(
        address who,
        uint256 from,
        uint256 to
    ) external;

    function revoke(address who) external;

    function hasValid(address who) external view returns (bool);

    function purchase(uint256 validFrom, uint256 validTo) external payable;
}

// File: contracts/Licences.sol

pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;



contract Licences is Ownable {
    string public name = "Kakadu National Park Camping Permit";
    uint256 public totalSupply;

    mapping(address => bool) private _authorities;

    struct Licence {
        bool licenceExists;
        address ethAccount;
        uint256 validFrom;
        uint256 validTo;
        bytes32[] waterAccountIds;
        mapping(bytes32 => WaterAccount) waterAccounts;
    }

    struct WaterAccount {
        bytes32 waterAccountId;
        uint8 zoneIndex;
    }

    Licence[] public _licences;
    mapping(address => uint256) public _addressToLicenceIndex;
    mapping(bytes32 => uint256) public _waterAccountIdToLicenceIndex;
    mapping(address => mapping(uint8 => bytes32)) public _addressToZoneIndexToWaterAccountId;

    constructor() public Ownable() {
        _authorities[msg.sender] = true;
    }

    function grantAuthority(address who) public onlyOwner() {
        _authorities[who] = true;
    }

    function revokeAuthority(address who) public onlyOwner() {
        _authorities[who] = false;
    }

    function hasAuthority(address who) public view returns (bool) {
        return _authorities[who];
    }

    function issue(
        address who,
        uint256 start,
        uint256 end
    ) public onlyAuthority {
        _licences.push(Licence(true, who, start, end, new bytes32[](0)));
        _addressToLicenceIndex[who] = _licences.length - 1;
        emit LicenceAdded(_licences.length - 1, who);
    }

    function issueCompleted(uint256 licenceIndex) public onlyAuthority {
        emit LicenceCompleted(licenceIndex, _licences[licenceIndex].ethAccount);
    }

    function revoke(address who) public onlyAuthority() {
        delete _licences[_addressToLicenceIndex[who]];
    }

    function getLicence(uint256 licenceIndex) public view returns (address, bytes32[] memory) {
        return (_licences[licenceIndex].ethAccount, _licences[licenceIndex].waterAccountIds);
    }

    function licencesLength() public view returns (uint256) {
        return _licences.length;
    }

    function hasValid(address who) public view returns (bool) {
        return _licences[_addressToLicenceIndex[who]].licenceExists;
    }

    function addLicenceWaterAccount(
        uint256 licenceIndex,
        bytes32 waterAccountId,
        uint8 zoneIndex
    ) public onlyOwner {
        _licences[licenceIndex].waterAccounts[waterAccountId] = WaterAccount(waterAccountId, zoneIndex);
        _licences[licenceIndex].waterAccountIds.push(waterAccountId);
        _waterAccountIdToLicenceIndex[waterAccountId] = licenceIndex;
        _addressToZoneIndexToWaterAccountId[_licences[licenceIndex].ethAccount][zoneIndex] = waterAccountId;
        emit WaterAccountAdded(_licences[licenceIndex].ethAccount);
    }

    function addAllLicenceWaterAccounts(
        uint256 licenceIndex,
        bytes32[] memory waterAccountIds
    ) public onlyOwner {
        for (uint8 i = 0; i < waterAccountIds.length; i++) {
            if(waterAccountIds[i] != "") {
                _licences[licenceIndex].waterAccounts[waterAccountIds[i]] = WaterAccount(waterAccountIds[i], i);
                _licences[licenceIndex].waterAccountIds.push(waterAccountIds[i]);
                _waterAccountIdToLicenceIndex[waterAccountIds[i]] = licenceIndex;
                _addressToZoneIndexToWaterAccountId[_licences[licenceIndex].ethAccount][i] = waterAccountIds[i];
                emit WaterAccountAdded(_licences[licenceIndex].ethAccount);
            }
        }
        emit LicenceCompleted(licenceIndex, _licences[licenceIndex].ethAccount);
    }

    function purchase() public payable {
        revert("Licence purchase is not supported");
    }

    function getWaterAccountIds(uint256 licenceIndex) public view returns (bytes32[] memory) {
        return _licences[licenceIndex].waterAccountIds;
    }

    function getLicenceIndexForWaterAccountId(bytes32 waterAccountId) public view returns (uint256) {
        require(_licences[_waterAccountIdToLicenceIndex[waterAccountId]].licenceExists, "There is no matching water account id");
        return _waterAccountIdToLicenceIndex[waterAccountId];
    }

    function getWaterAccountForWaterAccountId(bytes32 waterAccountId) public view returns (WaterAccount memory) {
        return _licences[_waterAccountIdToLicenceIndex[waterAccountId]].waterAccounts[waterAccountId];
    }

    function getWaterAccountsForLicence(uint256 licenceIndex) public view returns (WaterAccount[] memory) {
        uint256 waterAccountsLength = _licences[licenceIndex].waterAccountIds.length;
        require(waterAccountsLength > 0, "There are no water accounts for this licence");

        WaterAccount[] memory waterAccountArray = new WaterAccount[](waterAccountsLength);

        for (uint256 i = 0; i < waterAccountsLength; i++) {
            waterAccountArray[i] = _licences[licenceIndex].waterAccounts[_licences[licenceIndex].waterAccountIds[i]];
        }

        return waterAccountArray;
    }

    function getWaterAccountIdByAddressAndZone(address ethAccount, uint8 zoneIndex) public view returns (bytes32) {
        return _addressToZoneIndexToWaterAccountId[ethAccount][zoneIndex];
    }

    modifier onlyAuthority() {
        require(hasAuthority(msg.sender), "Only an authority can perform this function");
        _;
    }

    event LicenceAdded(uint256 index, address ethAccount);
    event WaterAccountAdded(address ethAccount);
    event LicenceCompleted(uint256 index, address ethAccount);
}