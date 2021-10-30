/**
 *Submitted for verification at Etherscan.io on 2021-10-30
*/

pragma solidity 0.5.17;

/**
 * @title Avastar Data Types
 * @author Cliff Hall
 */
contract AvastarTypes {

    enum Generation {
        ONE,
        TWO,
        THREE,
        FOUR,
        FIVE
    }

    enum Series {
        PROMO,
        ONE,
        TWO,
        THREE,
        FOUR,
        FIVE
    }

    enum Wave {
        PRIME,
        REPLICANT
    }

    enum Gene {
        SKIN_TONE,
        HAIR_COLOR,
        EYE_COLOR,
        BG_COLOR,
        BACKDROP,
        EARS,
        FACE,
        NOSE,
        MOUTH,
        FACIAL_FEATURE,
        EYES,
        HAIR_STYLE
    }

    enum Gender {
        ANY,
        MALE,
        FEMALE
    }

    enum Rarity {
        COMMON,
        UNCOMMON,
        RARE,
        EPIC,
        LEGENDARY
    }

    struct Trait {
        uint256 id;
        Generation generation;
        Gender gender;
        Gene gene;
        Rarity rarity;
        uint8 variation;
        Series[] series;
        string name;
        string svg;

    }

    struct Prime {
        uint256 id;
        uint256 serial;
        uint256 traits;
        bool[12] replicated;
        Generation generation;
        Series series;
        Gender gender;
        uint8 ranking;
    }

    struct Replicant {
        uint256 id;
        uint256 serial;
        uint256 traits;
        Generation generation;
        Gender gender;
        uint8 ranking;
    }

    struct Avastar {
        uint256 id;
        uint256 serial;
        uint256 traits;
        Generation generation;
        Wave wave;
    }

    struct Attribution {
        Generation generation;
        string artist;
        string infoURI;
    }

}

// File: contracts/IAvastarTeleporter.sol

pragma solidity 0.5.17;


/**
 * @title AvastarTeleporter Interface
 * @author Cliff Hall
 * @notice Declared as abstract contract rather than interface as it must inherit for enum types.
 * Used by AvastarMinter contract to interact with subset of AvastarTeleporter contract functions.
 */
contract IAvastarTeleporter is AvastarTypes {

    /**
     * @notice Acknowledge contract is `AvastarTeleporter`
     * @return always true if the contract is in fact `AvastarTeleporter`
     */
    function isAvastarTeleporter() external pure returns (bool);

    /**
     * @notice Get token URI for a given Avastar Token ID.
     * Reverts if given token id is not a valid Avastar Token ID.
     * @param _tokenId the Token ID of a previously minted Avastar Prime or Replicant
     * @return uri the off-chain URI to the JSON metadata for the given Avastar
     */
    function tokenURI(uint _tokenId)
    external view
    returns (string memory uri);

    /**
     * @notice Get an Avastar's Wave by token ID.
     * @param _tokenId the token id of the given Avastar
     * @return wave the Avastar's wave (Prime/Replicant)
     */
    function getAvastarWaveByTokenId(uint256 _tokenId)
    external view
    returns (Wave wave);

    /**
     * @notice Get the Avastar Prime metadata associated with a given Token ID.
     * @param _tokenId the Token ID of the specified Prime
     * @return tokenId the Prime's token ID
     * @return serial the Prime's serial
     * @return traits the Prime's trait hash
     * @return generation the Prime's generation
     * @return series the Prime's series
     * @return gender the Prime's gender
     * @return ranking the Prime's ranking
     */
    function getPrimeByTokenId(uint256 _tokenId)
    external view
    returns (
        uint256 tokenId,
        uint256 serial,
        uint256 traits,
        Generation generation,
        Series series,
        Gender gender,
        uint8 ranking
    );

    /**
     * @notice Get the Avastar Replicant metadata associated with a given Token ID
     * @param _tokenId the token ID of the specified Replicant
     * @return tokenId the Replicant's token ID
     * @return serial the Replicant's serial
     * @return traits the Replicant's trait hash
     * @return generation the Replicant's generation
     * @return gender the Replicant's gender
     * @return ranking the Replicant's ranking
     */
    function getReplicantByTokenId(uint256 _tokenId)
    external view
    returns (
        uint256 tokenId,
        uint256 serial,
        uint256 traits,
        Generation generation,
        Gender gender,
        uint8 ranking
    );

    /**
     * @notice Retrieve a Trait's info by ID.
     * @param _traitId the ID of the Trait to retrieve
     * @return id the ID of the trait
     * @return generation generation of the trait
     * @return series list of series the trait may appear in
     * @return gender gender(s) the trait is valid for
     * @return gene gene the trait belongs to
     * @return variation variation of the gene the trait represents
     * @return rarity the rarity level of this trait
     * @return name name of the trait
     */
    function getTraitInfoById(uint256 _traitId)
    external view
    returns (
        uint256 id,
        Generation generation,
        Series[] memory series,
        Gender gender,
        Gene gene,
        Rarity rarity,
        uint8 variation,
        string memory name
    );


    /**
     * @notice Retrieve a Trait's name by ID.
     * @param _traitId the ID of the Trait to retrieve
     * @return name name of the trait
     */
    function getTraitNameById(uint256 _traitId)
    external view
    returns (string memory name);

    /**
     * @notice Get Trait ID by Generation, Gene, and Variation.
     * @param _generation the generation the trait belongs to
     * @param _gene gene the trait belongs to
     * @param _variation the variation of the gene
     * @return traitId the ID of the specified trait
     */
    function getTraitIdByGenerationGeneAndVariation(
        Generation _generation,
        Gene _gene,
        uint8 _variation
    )
    external view
    returns (uint256 traitId);

    /**
     * @notice Get the artist Attribution for a given Generation, combined into a single string.
     * @param _generation the generation to retrieve artist attribution for
     * @return attribution a single string with the artist and artist info URI
     */
    function getAttributionByGeneration(Generation _generation)
    external view
    returns (
        string memory attribution
    );

    /**
     * @notice Mint an Avastar Prime
     * Only invokable by minter role, when contract is not paused.
     * If successful, emits a `NewPrime` event.
     * @param _owner the address of the new Avastar's owner
     * @param _traits the new Prime's trait hash
     * @param _generation the new Prime's generation
     * @return _series the new Prime's series
     * @param _gender the new Prime's gender
     * @param _ranking the new Prime's rarity ranking
     * @return tokenId the newly minted Prime's token ID
     * @return serial the newly minted Prime's serial
     */
    function mintPrime(
        address _owner,
        uint256 _traits,
        Generation _generation,
        Series _series,
        Gender _gender,
        uint8 _ranking
    )
    external
    returns (uint256, uint256);

    /**
     * @notice Mint an Avastar Replicant.
     * Only invokable by minter role, when contract is not paused.
     * If successful, emits a `NewReplicant` event.
     * @param _owner the address of the new Avastar's owner
     * @param _traits the new Replicant's trait hash
     * @param _generation the new Replicant's generation
     * @param _gender the new Replicant's gender
     * @param _ranking the new Replicant's rarity ranking
     * @return tokenId the newly minted Replicant's token ID
     * @return serial the newly minted Replicant's serial
     */
    function mintReplicant(
        address _owner,
        uint256 _traits,
        Generation _generation,
        Gender _gender,
        uint8 _ranking
    )
    external
    returns (uint256, uint256);

    /**
     * Gets the owner of the specified token ID.
     * @param tokenId the token ID to search for the owner of
     * @return owner the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice Gets the total amount of tokens stored by the contract.
     * @return count total number of tokens
     */
    function totalSupply() public view returns (uint256 count);
}

// File: contracts/AvastarBase.sol

pragma solidity 0.5.17;

/**
 * @title Avastar Base
 * @author Cliff Hall
 * @notice Utilities used by descendant contracts
 */
contract AvastarBase {

    /**
     * @notice Convert a `uint` value to a `string`
     * via OraclizeAPI - MIT licence
     * https://github.com/provable-things/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol#L896
     * @param _i the `uint` value to be converted
     * @return result the `string` representation of the given `uint` value
     */
    function uintToStr(uint _i)
    internal pure
    returns (string memory result) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        result = string(bstr);
    }

    /**
     * @notice Concatenate two strings
     * @param _a the first string
     * @param _b the second string
     * @return result the concatenation of `_a` and `_b`
     */
    function strConcat(string memory _a, string memory _b)
    internal pure
    returns(string memory result) {
        result = string(abi.encodePacked(bytes(_a), bytes(_b)));
    }

}

// File: @openzeppelin/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/AccessControl.sol

pragma solidity 0.5.17;



/**
 * @title Access Control
 * @author Cliff Hall
 * @notice Role-based access control and contract upgrade functionality.
 */
contract AccessControl {

    using SafeMath for uint256;
    using SafeMath for uint16;
    using Roles for Roles.Role;

    Roles.Role private admins;
    Roles.Role private minters;
    Roles.Role private owners;

    /**
     * @notice Sets `msg.sender` as system admin by default.
     * Starts paused. System admin must unpause, and add other roles after deployment.
     */
    constructor() public {
        admins.add(msg.sender);
    }

    /**
     * @notice Emitted when contract is paused by system administrator.
     */
    event ContractPaused();

    /**
     * @notice Emitted when contract is unpaused by system administrator.
     */
    event ContractUnpaused();

    /**
     * @notice Emitted when contract is upgraded by system administrator.
     * @param newContract address of the new version of the contract.
     */
    event ContractUpgrade(address newContract);


    bool public paused = true;
    bool public upgraded = false;
    address public newContractAddress;

    /**
     * @notice Modifier to scope access to minters
     */
    modifier onlyMinter() {
        require(minters.has(msg.sender));
        _;
    }

    /**
     * @notice Modifier to scope access to owners
     */
    modifier onlyOwner() {
        require(owners.has(msg.sender));
        _;
    }

    /**
     * @notice Modifier to scope access to system administrators
     */
    modifier onlySysAdmin() {
        require(admins.has(msg.sender));
        _;
    }

    /**
     * @notice Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @notice Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @notice Modifier to make a function callable only when the contract not upgraded.
     */
    modifier whenNotUpgraded() {
        require(!upgraded);
        _;
    }

    /**
     * @notice Called by a system administrator to  mark the smart contract as upgraded,
     * in case there is a serious breaking bug. This method stores the new contract
     * address and emits an event to that effect. Clients of the contract should
     * update to the new contract address upon receiving this event. This contract will
     * remain paused indefinitely after such an upgrade.
     * @param _newAddress address of new contract
     */
    function upgradeContract(address _newAddress) external onlySysAdmin whenPaused whenNotUpgraded {
        require(_newAddress != address(0));
        upgraded = true;
        newContractAddress = _newAddress;
        emit ContractUpgrade(_newAddress);
    }

    /**
     * @notice Called by a system administrator to add a minter.
     * Reverts if `_minterAddress` already has minter role
     * @param _minterAddress approved minter
     */
    function addMinter(address _minterAddress) external onlySysAdmin {
        minters.add(_minterAddress);
        require(minters.has(_minterAddress));
    }

    /**
     * @notice Called by a system administrator to add an owner.
     * Reverts if `_ownerAddress` already has owner role
     * @param _ownerAddress approved owner
     * @return added boolean indicating whether the role was granted
     */
    function addOwner(address _ownerAddress) external onlySysAdmin {
        owners.add(_ownerAddress);
        require(owners.has(_ownerAddress));
    }

    /**
     * @notice Called by a system administrator to add another system admin.
     * Reverts if `_sysAdminAddress` already has sysAdmin role
     * @param _sysAdminAddress approved owner
     */
    function addSysAdmin(address _sysAdminAddress) external onlySysAdmin {
        admins.add(_sysAdminAddress);
        require(admins.has(_sysAdminAddress));
    }

    /**
     * @notice Called by an owner to remove all roles from an address.
     * Reverts if address had no roles to be removed.
     * @param _address address having its roles stripped
     */
    function stripRoles(address _address) external onlyOwner {
        require(msg.sender != _address);
        bool stripped = false;
        if (admins.has(_address)) {
            admins.remove(_address);
            stripped = true;
        }
        if (minters.has(_address)) {
            minters.remove(_address);
            stripped = true;
        }
        if (owners.has(_address)) {
            owners.remove(_address);
            stripped = true;
        }
        require(stripped == true);
    }

    /**
     * @notice Called by a system administrator to pause, triggers stopped state
     */
    function pause() external onlySysAdmin whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /**
     * @notice Called by a system administrator to un-pause, returns to normal state
     */
    function unpause() external onlySysAdmin whenPaused whenNotUpgraded {
        paused = false;
        emit ContractUnpaused();
    }

}

// File: contracts/AvastarMetadata.sol

pragma solidity 0.5.17;





/**
 * @title Avastar Metadata Generator
 * @author Cliff Hall
 * @notice Generate Avastar metadata from on-chain data.
 * Refers to the `AvastarTeleporter` for raw data to generate
 * the human and machine readable metadata for a given Avastar token Id.
 */
contract AvastarMetadata is AvastarBase, AvastarTypes, AccessControl {

    string public constant INVALID_TOKEN_ID = "Invalid Token ID";

    /**
     * @notice Event emitted when AvastarTeleporter contract is set
     * @param contractAddress the address of the AvastarTeleporter contract
     */
    event TeleporterContractSet(address contractAddress);

    /**
     * @notice Event emitted when TokenURI base changes
     * @param tokenUriBase the base URI for tokenURI calls
     */
    event TokenUriBaseSet(string tokenUriBase);

    /**
     * @notice Event emitted when the `mediaUriBase` is set.
     * Only emitted when the `mediaUriBase` is set after contract deployment.
     * @param mediaUriBase the new URI
     */
    event MediaUriBaseSet(string mediaUriBase);

    /**
     * @notice Event emitted when the `viewUriBase` is set.
     * Only emitted when the `viewUriBase` is set after contract deployment.
     * @param viewUriBase the new URI
     */
    event ViewUriBaseSet(string viewUriBase);

    /**
     * @notice Address of the AvastarTeleporter contract
     */
    IAvastarTeleporter private teleporterContract ;

    /**
     * @notice The base URI for an Avastar's off-chain metadata
     */
    string internal tokenUriBase;

    /**
     * @notice Base URI for an Avastar's off-chain image
     */
    string private mediaUriBase;

    /**
     * @notice Base URI to view an Avastar on the Avastars website
     */
    string private viewUriBase;

    /**
     * @notice Set the address of the `AvastarTeleporter` contract.
     * Only invokable by system admin role, when contract is paused and not upgraded.
     * To be used if the Teleporter contract has to be upgraded and a new instance deployed.
     * If successful, emits an `TeleporterContractSet` event.
     * @param _address address of `AvastarTeleporter` contract
     */
    function setTeleporterContract(address _address) external onlySysAdmin whenPaused whenNotUpgraded {

        // Cast the candidate contract to the IAvastarTeleporter interface
        IAvastarTeleporter candidateContract = IAvastarTeleporter(_address);

        // Verify that we have the appropriate address
        require(candidateContract.isAvastarTeleporter());

        // Set the contract address
        teleporterContract = IAvastarTeleporter(_address);

        // Emit the event
        emit TeleporterContractSet(_address);
    }

    /**
     * @notice Acknowledge contract is `AvastarMetadata`
     * @return always true
     */
    function isAvastarMetadata() external pure returns (bool) {return true;}

    /**
     * @notice Set the base URI for creating `tokenURI` for each Avastar.
     * Only invokable by system admin role, when contract is paused and not upgraded.
     * If successful, emits an `TokenUriBaseSet` event.
     * @param _tokenUriBase base for the ERC721 tokenURI
     */
    function setTokenUriBase(string calldata _tokenUriBase)
    external onlySysAdmin whenPaused whenNotUpgraded
    {
        // Set the base for metadata tokenURI
        tokenUriBase = _tokenUriBase;

        // Emit the event
        emit TokenUriBaseSet(_tokenUriBase);
    }

    /**
     * @notice Set the base URI for the image of each Avastar.
     * Only invokable by system admin role, when contract is paused and not upgraded.
     * If successful, emits an `MediaUriBaseSet` event.
     * @param _mediaUriBase base for the mediaURI shown in metadata for each Avastar
     */
    function setMediaUriBase(string calldata _mediaUriBase)
    external onlySysAdmin whenPaused whenNotUpgraded
    {
        // Set the base for metadata tokenURI
        mediaUriBase = _mediaUriBase;

        // Emit the event
        emit MediaUriBaseSet(_mediaUriBase);
    }

    /**
     * @notice Set the base URI for the image of each Avastar.
     * Only invokable by system admin role, when contract is paused and not upgraded.
     * If successful, emits an `MediaUriBaseSet` event.
     * @param _viewUriBase base URI for viewing an Avastar on the Avastars website
     */
    function setViewUriBase(string calldata _viewUriBase)
    external onlySysAdmin whenPaused whenNotUpgraded
    {
        // Set the base for metadata tokenURI
        viewUriBase = _viewUriBase;

        // Emit the event
        emit ViewUriBaseSet(_viewUriBase);
    }

    /**
     * @notice Get view URI for a given Avastar Token ID.
     * @param _tokenId the Token ID of a previously minted Avastar Prime or Replicant
     * @return uri the off-chain URI to view the Avastar on the Avastars website
     */
    function viewURI(uint _tokenId)
    public view
    returns (string memory uri)
    {
        require(_tokenId < teleporterContract.totalSupply(), INVALID_TOKEN_ID);
        uri = strConcat(viewUriBase, uintToStr(_tokenId));
    }

    /**
     * @notice Get media URI for a given Avastar Token ID.
     * @param _tokenId the Token ID of a previously minted Avastar Prime or Replicant
     * @return uri the off-chain URI to the Avastar image
     */
    function mediaURI(uint _tokenId)
    public view
    returns (string memory uri)
    {
        require(_tokenId < teleporterContract.totalSupply(), INVALID_TOKEN_ID);
        uri = strConcat(mediaUriBase, uintToStr(_tokenId));
    }

    /**
     * @notice Get token URI for a given Avastar Token ID.
     * @param _tokenId the Token ID of a previously minted Avastar Prime or Replicant
     * @return uri the Avastar's off-chain JSON metadata URI
     */
    function tokenURI(uint _tokenId)
    external view
    returns (string memory uri)
    {
        require(_tokenId < teleporterContract.totalSupply(), INVALID_TOKEN_ID);
        uri = strConcat(tokenUriBase, uintToStr(_tokenId));
    }

    /**
     * @notice Get human-readable metadata for a given Avastar by Token ID.
     * @param _tokenId the token id of the given Avastar
     * @return metadata the Avastar's human-readable metadata
     */
    function getAvastarMetadata(uint256 _tokenId)
    external view
    returns (string memory metadata) {

        require(_tokenId < teleporterContract.totalSupply(), INVALID_TOKEN_ID);

        uint256 id;
        uint256 serial;
        uint256 traits;
        Generation generation;
        Wave wave;
        Series series;
        Gender gender;
        uint8 ranking;
        string memory attribution;

        // Get the Avastar
        wave = teleporterContract.getAvastarWaveByTokenId(_tokenId);

        // Get Prime or Replicant info depending on Avastar's Wave
        if (wave == Wave.PRIME) {
            (id, serial, traits, generation, series, gender, ranking) = teleporterContract.getPrimeByTokenId(_tokenId);
        } else {
            (id, serial, traits, generation, gender, ranking)  = teleporterContract.getReplicantByTokenId(_tokenId);
        }

        // Get artist attribution
        attribution = teleporterContract.getAttributionByGeneration(generation);
        attribution = strConcat('Original art by: ', attribution);

        // Name
        metadata = strConcat('{\n  "name": "Avastar #', uintToStr(uint256(id)));
        metadata = strConcat(metadata, '",\n');

        // Description: Generation
        metadata = strConcat(metadata, '  "description": "Generation ');
        metadata = strConcat(metadata, uintToStr(uint8(generation) + 1));

        // Description: Series (if 1-5)
        if (wave == Wave.PRIME && series != Series.PROMO) {
            metadata = strConcat(metadata, ' Series ');
            metadata = strConcat(metadata, uintToStr(uint8(series)));
        }

        // Description: Gender
        if (gender == Gender.MALE) {
            metadata = strConcat(metadata, ' Male ');
        }
        else if (gender == Gender.FEMALE) {
            metadata = strConcat(metadata, ' Female ');
        }
        else {
            metadata = strConcat(metadata, ' Non-Binary ');
        }

        // Description: Founder, Exclusive, Prime, or Replicant
        if (wave == Wave.PRIME && series == Series.PROMO) {
            metadata = strConcat(metadata, (serial <100) ? 'Founder. ' : 'Exclusive. ');
        } else {
            metadata = strConcat(metadata, (wave == Wave.PRIME) ? 'Prime. ' : 'Replicant. ');
        }
        metadata = strConcat(metadata, attribution);
        metadata = strConcat(metadata, '",\n');

        // View URI
        metadata = strConcat(metadata, '  "external_url": "');
        metadata = strConcat(metadata, viewURI(_tokenId));
        metadata = strConcat(metadata, '",\n');

        // Media URI
        metadata = strConcat(metadata, '  "image": "');
        metadata = strConcat(metadata, mediaURI(_tokenId));
        metadata = strConcat(metadata, '",\n');

        // Attributes (ala OpenSea)
        metadata = strConcat(metadata, '  "attributes": [\n');

        // Gender
        metadata = strConcat(metadata, '    {\n');
        metadata = strConcat(metadata, '      "trait_type": "gender",\n');
        metadata = strConcat(metadata, '      "value": "');
        
        if (gender == Gender.MALE) {
            metadata = strConcat(metadata, 'male"');
        }
        else if (gender == Gender.FEMALE) {
            metadata = strConcat(metadata, 'female"');
        }
        else {
            metadata = strConcat(metadata, 'non-binary"');
        }

        metadata = strConcat(metadata, '\n    },\n');

        // Wave
        metadata = strConcat(metadata, '    {\n');
        metadata = strConcat(metadata, '      "trait_type": "wave",\n');
        metadata = strConcat(metadata, '      "value": "');
        metadata = strConcat(metadata, (wave == Wave.PRIME) ? 'prime"' : 'replicant"');
        metadata = strConcat(metadata, '\n    },\n');

        // Generation
        metadata = strConcat(metadata, '    {\n');
        metadata = strConcat(metadata, '      "display_type": "number",\n');
        metadata = strConcat(metadata, '      "trait_type": "generation",\n');
        metadata = strConcat(metadata, '      "value": ');
        metadata = strConcat(metadata, uintToStr(uint8(generation) + 1));
        metadata = strConcat(metadata, '\n    },\n');

        // Series
        if (wave == Wave.PRIME) {
            metadata = strConcat(metadata, '    {\n');
            metadata = strConcat(metadata, '      "display_type": "number",\n');
            metadata = strConcat(metadata, '      "trait_type": "series",\n');
            metadata = strConcat(metadata, '      "value": ');
            metadata = strConcat(metadata, uintToStr(uint8(series)));
            metadata = strConcat(metadata, '\n    },\n');
        }

        // Serial
        metadata = strConcat(metadata, '    {\n');
        metadata = strConcat(metadata, '      "display_type": "number",\n');
        metadata = strConcat(metadata, '      "trait_type": "serial",\n');
        metadata = strConcat(metadata, '      "value": ');
        metadata = strConcat(metadata, uintToStr(serial));
        metadata = strConcat(metadata, '\n    },\n');

        // Ranking
        metadata = strConcat(metadata, '    {\n');
        metadata = strConcat(metadata, '      "display_type": "number",\n');
        metadata = strConcat(metadata, '      "trait_type": "ranking",\n');
        metadata = strConcat(metadata, '      "value": ');
        metadata = strConcat(metadata, uintToStr(ranking));
        metadata = strConcat(metadata, '\n    },\n');

        // Level
        metadata = strConcat(metadata, '    {\n');
        metadata = strConcat(metadata, '      "trait_type": "level",\n');
        metadata = strConcat(metadata, '      "value": "');
        metadata = strConcat(metadata, getRankingLevel(ranking));
        metadata = strConcat(metadata, '"\n    },\n');

        // Traits
        metadata = strConcat(metadata, assembleTraitMetadata(generation, traits));

        // Finish JSON object
        metadata = strConcat(metadata, '  ]\n}');

    }

    /**
     * @notice Get the rarity level for a given Avastar Rank
     * @param ranking the ranking level (1-100)
     * @return level the rarity level (Common, Uncommon, Rare, Epic, Legendary)
     */
    function getRankingLevel(uint8 ranking)
    internal pure
    returns (string memory level) {
        require(ranking >0 && ranking <=100);
        uint8[4] memory breaks = [33, 41, 50, 60];
        if (ranking < breaks[0]) {level = "Common";}
        else if (ranking < breaks[1]) {level = "Uncommon";}
        else if (ranking < breaks[2]) {level = "Rare";}
        else if (ranking < breaks[3]) {level = "Epic";}
        else {level = "Legendary";}
    }

    /**
     * @notice Assemble the human-readable metadata for a given Trait hash.
     * Used internally by
     * @param _generation the generation the Avastar belongs to
     * @param _traitHash the Avastar's trait hash
     * @return metdata the JSON trait metadata for the Avastar
     */
    function assembleTraitMetadata(Generation _generation, uint256 _traitHash)
    internal view
    returns (string memory metadata)
    {
        require(_traitHash > 0);
        uint256 slotConst = 256;
        uint256 slotMask = 255;
        uint256 bitMask;
        uint256 slottedValue;
        uint256 slotMultiplier;
        uint256 variation;
        uint256 traitId;

        // Iterate trait hash by Gene and assemble trait attribute data
        for (uint8 slot = 0; slot <= uint8(Gene.HAIR_STYLE); slot++){
            slotMultiplier = uint256(slotConst**slot);  // Create slot multiplier
            bitMask = slotMask * slotMultiplier;        // Create bit mask for slot
            slottedValue = _traitHash & bitMask;        // Extract slotted value from hash
            if (slottedValue > 0) {
                variation = (slot > 0)                  // Extract variation from slotted value
                ? slottedValue / slotMultiplier
                : slottedValue;
                if (variation > 0) {
                    traitId = teleporterContract.getTraitIdByGenerationGeneAndVariation(_generation, Gene(slot), uint8(variation));
                    metadata = strConcat(metadata, '    {\n');
                    metadata = strConcat(metadata, '      "trait_type": "');
                    if (slot == uint8(Gene.SKIN_TONE)) {
                        metadata = strConcat(metadata, 'skin_tone');
                    } else if (slot == uint8(Gene.HAIR_COLOR)) {
                        metadata = strConcat(metadata, 'hair_color');
                    } else if (slot == uint8(Gene.EYE_COLOR)) {
                        metadata = strConcat(metadata, 'eye_color');
                    } else if (slot == uint8(Gene.BG_COLOR)) {
                        metadata = strConcat(metadata, 'background_color');
                    } else if (slot == uint8(Gene.BACKDROP)) {
                        metadata = strConcat(metadata, 'backdrop');
                    } else if (slot == uint8(Gene.EARS)) {
                        metadata = strConcat(metadata, 'ears');
                    } else if (slot == uint8(Gene.FACE)) {
                        metadata = strConcat(metadata, 'face');
                    } else if (slot == uint8(Gene.NOSE)) {
                        metadata = strConcat(metadata, 'nose');
                    } else if (slot == uint8(Gene.MOUTH)) {
                        metadata = strConcat(metadata, 'mouth');
                    } else if (slot == uint8(Gene.FACIAL_FEATURE)) {
                        metadata = strConcat(metadata, 'facial_feature');
                    } else if (slot == uint8(Gene.EYES)) {
                        metadata = strConcat(metadata, 'eyes');
                    } else if (slot == uint8(Gene.HAIR_STYLE)) {
                        metadata = strConcat(metadata, 'hair_style');
                    }
                    metadata = strConcat(metadata, '",\n');
                    metadata = strConcat(metadata, '      "value": "');
                    metadata = strConcat(metadata, teleporterContract.getTraitNameById(traitId));
                    metadata = strConcat(metadata, '"\n    }');
                    if (slot < uint8(Gene.HAIR_STYLE))  metadata = strConcat(metadata, ',');
                    metadata = strConcat(metadata, '\n');

                }
            }
        }
    }

}