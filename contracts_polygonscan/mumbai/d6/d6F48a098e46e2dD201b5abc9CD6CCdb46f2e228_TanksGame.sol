/**
 *Submitted for verification at polygonscan.com on 2021-12-01
*/

// Sources flattened with hardhat v2.6.7 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


pragma solidity ^0.8.0;

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


// File contracts/util/StringUtils.sol

pragma solidity ^0.8.7;

library StringUtils {
    function compare(string memory self, string memory other)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((self))) ==
            keccak256(abi.encodePacked((other))));
    }

    /// overloaded once
    function append(string memory self, string memory b)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(self, b));
    }

    function append(
        string memory self,
        string memory b,
        string memory c
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(self, b, c));
    }
}


// File contracts/util/MathUtils.sol

pragma solidity ^0.8.7;

library MathUtils {
    function abs(int256 x) internal pure returns (int256) {
        return x >= 0 ? x : -x;
    }

    /// have not had need to do ints yet
    function toString(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return '0';
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}


// File contracts/util/Types.sol

pragma solidity ^0.8.7;

struct MapSpec {
    string mapName;
    uint256 width;
    uint256 height;
}

struct TerrainTraits {
    string modelId; /* the 3d model to serve */
    bool blocksMovement;
    bool blocksLOS;
}

struct BoundaryTraits {
    string modelId; /* the 3d model to serve */
    bool blocksMovement;
    bool blocksLOS;
}

struct LocationSpec {
    string terrainName;
    // hexagons have 6 sides but they also have neighbors, hence we only care about 3 sides

    /*
         6/\1
        5|  |2
         4\/3
     */
    string[3] boundaryNames; /* empty -> no boundary */
}

struct Vector2 {
    int256 axis1;
    int256 axis2;
}

struct PlayerStats {
    address playerAddress;
    Vector2 location;
    string locationId;
    uint256 hearts;
    uint256 range;
    int256 spentEnergy;
    uint256 nPurchases;
}

struct NewGameSpec {
    // map reference
    bytes32 mapId;
    address mapContractAddress;
    // general config
    uint256 energyFrequency;
}

struct GameSpec {
    // --- from instantiation ---
    address mapContractAddress; /* map reference */
    bytes32 mapId; /* map reference */
    uint256 energyFrequency;
    address[] playerAddresses;
    // --- dynamic ---
    mapping(address => PlayerStats) playerMap;
    uint256 gameStart; /* should never == 0 */
    uint256 gameEnd; /* if this != 0 --> game is in progress, otherwise game over */
    address winner; /* if != address(0) --> game in progress */
    // --- useful memos ---
    uint256 playerCount;
    uint256 destroyedCount;
    mapping(string => address) occupancyMap; /* memo: save us iterating through players */
}


// File contracts/TanksMap.sol

pragma solidity ^0.8.7;




struct StartingPositionSpec {
    Vector2 location;
    string locationId;
}

// https://www.redblobgames.com/grids/hexagons/#map-storage --> rectangle
contract TanksMap is Ownable {
    using StringUtils for string;
    using MathUtils for uint256;
    using MathUtils for int256;

    event MapCreated(bytes32 mapId, MapSpec mapSpec);
    event TerrainAdded(string terrainName, TerrainTraits terrainTraits);
    event BoundaryAdded(string boundaryName, BoundaryTraits boundaryTraits);

    mapping(bytes32 => MapSpec) public allMapSpecs;
    /* maps each mapId to a mapping between locationId and locationSpec */
    mapping(bytes32 => mapping(string => LocationSpec)) public allLocationSpecs;
    mapping(bytes32 => string[]) public allLocationIds;
    mapping(bytes32 => StartingPositionSpec[]) public allStartingPositions;

    bytes32[] private knownMaps;

    /* terrain / boundary metadata (common for all maps) */
    mapping(string => TerrainTraits) public allTerrains;
    mapping(string => BoundaryTraits) public allBoundaries;
    string[] private knownTerrainNames;
    string[] private knownBoundaryNames;

    // for each game, maps locationId to whether it is a starting position
    // only used for validation (detecting dupes)
    // values are set to false upon successful assignment
    mapping(bytes32 => mapping(string => bool)) private startingLocationsMap;

    constructor() Ownable() {}

    // CREATE

    // TODO: make ownable later
    function createMap(
        MapSpec memory mapSpec,
        string[] memory locationIds,
        string[] memory terrainNames,
        string[] memory boundaryNames
    ) public onlyOwner returns (bytes32) {
        bytes32 mapId = keccak256(abi.encodePacked(mapSpec.mapName));

        require(
            locationIds.length == terrainNames.length,
            'Number of locationIds does not match number of terrainNames'
        );

        require(
            locationIds.length * 3 == boundaryNames.length,
            'Number of locationIds does not match number of boundaries (x3)'
        );

        require(
            bytes(allMapSpecs[mapId].mapName).length == 0,
            'Map with that name already exists'
        );

        allMapSpecs[mapId] = mapSpec;

        for (uint256 i = 0; i < locationIds.length; i++) {
            string memory terrainName = terrainNames[i];
            string[3] memory boundaries = [
                boundaryNames[i * 3],
                boundaryNames[i * 3 + 1],
                boundaryNames[i * 3 + 2]
            ];

            require(
                bytes(allTerrains[terrainName].modelId).length > 0,
                'Unsupported terrain provided'
            );

            for (uint256 j = 0; j < 3; j++) {
                // if boundary name is not empty, check to see if it is valid
                // (boundaries are not required but terrain is)
                if (bytes(boundaries[j]).length > 0) {
                    require(
                        bytes(allBoundaries[boundaries[j]].modelId).length > 0,
                        'Unsupported boundary provided'
                    );
                }
            }

            string memory locationId = locationIds[i];

            LocationSpec memory locationSpec = LocationSpec({
                terrainName: terrainName,
                boundaryNames: boundaries
            });

            allLocationSpecs[mapId][locationId] = locationSpec;
        }

        emit MapCreated(mapId, mapSpec);

        knownMaps.push(mapId);
        allLocationIds[mapId] = locationIds;

        return mapId;
    }

    function addTerrain(string memory terrainName, TerrainTraits memory traits)
        public
        onlyOwner
    {
        require(
            bytes(allTerrains[terrainName].modelId).length == 0,
            'Terrain with that name already exists'
        );
        allTerrains[terrainName] = traits;
        knownTerrainNames.push(terrainName);

        emit TerrainAdded(terrainName, traits);
    }

    function addBoundary(
        string memory boundaryName,
        BoundaryTraits memory traits
    ) public onlyOwner {
        require(
            bytes(allBoundaries[boundaryName].modelId).length == 0,
            'Boundary with that name already exists'
        );
        allBoundaries[boundaryName] = traits;
        knownBoundaryNames.push(boundaryName);

        emit BoundaryAdded(boundaryName, traits);
    }

    function setStartingPositions(
        bytes32 mapId,
        Vector2[] memory startingLocations
    ) public onlyOwner {
        string[] memory locationIds = new string[](startingLocations.length);

        delete allStartingPositions[mapId];

        // build list of location ids for the sake of validation
        for (uint256 i = 0; i < startingLocations.length; i++) {
            Vector2 memory pos = startingLocations[i];
            string memory locationId = coordinateToId(pos);

            locationIds[i] = locationId;
        }

        // perform the assignment; make sure no duplicates
        for (uint256 i = 0; i < startingLocations.length; i++) {
            Vector2 memory location = startingLocations[i];
            string memory locationId = locationIds[i];

            require(
                !startingLocationsMap[mapId][locationId],
                'Location has been assigned starting position more than once'
            );

            require(
                !getTerrainTraitsForLocation(mapId, locationId).blocksMovement,
                'Cannot assign players to obstacles'
            );

            startingLocationsMap[mapId][locationId] = true;

            allStartingPositions[mapId].push(
                StartingPositionSpec({
                    location: location,
                    locationId: locationId
                })
            );
        }

        // validation logic
        for (uint256 i = 0; i < startingLocations.length; i++) {
            string memory locationId = locationIds[i];

            startingLocationsMap[mapId][locationId] = false;
        }
    }

    // VIEWS

    function getMaxNumberOfPlayers(bytes32 mapId)
        public
        view
        returns (uint256 maxPlayers)
    {
        maxPlayers = allStartingPositions[mapId].length;
    }

    function getMapLocations(bytes32 mapId)
        public
        view
        returns (
            string[] memory locationIds,
            string[] memory terrainNames,
            string[] memory boundaryNames
        )
    {
        locationIds = new string[](allLocationIds[mapId].length);
        terrainNames = new string[](allLocationIds[mapId].length);
        boundaryNames = new string[](allLocationIds[mapId].length * 3);

        for (uint256 i = 0; i < allLocationIds[mapId].length; i++) {
            string memory locationId = allLocationIds[mapId][i];
            locationIds[i] = locationId;
            LocationSpec memory locationSpec = allLocationSpecs[mapId][
                locationId
            ];
            terrainNames[i] = locationSpec.terrainName;

            for (uint256 j = 0; j < 3; j++) {
                boundaryNames[i * 3 + j] = locationSpec.boundaryNames[j];
            }
        }
    }

    function getTerrainTraits(string memory terrainName)
        public
        view
        returns (TerrainTraits memory terrainTraits)
    {
        terrainTraits = allTerrains[terrainName];
    }

    function getBoundaryTraits(string memory boundaryName)
        public
        view
        returns (BoundaryTraits memory boundaryTraits)
    {
        boundaryTraits = allBoundaries[boundaryName];
    }

    function getKnownTerrains()
        public
        view
        returns (
            string[] memory terrainNames,
            string[] memory modelIdArr,
            bool[] memory blocksMovementArr,
            bool[] memory blocksLOSArr
        )
    {
        terrainNames = new string[](knownTerrainNames.length);
        modelIdArr = new string[](knownTerrainNames.length);
        blocksMovementArr = new bool[](knownTerrainNames.length);
        blocksLOSArr = new bool[](knownTerrainNames.length);

        for (uint256 i = 0; i < knownTerrainNames.length; i++) {
            terrainNames[i] = knownTerrainNames[i];
            TerrainTraits memory traits = allTerrains[terrainNames[i]];

            modelIdArr[i] = traits.modelId;
            blocksMovementArr[i] = traits.blocksMovement;
            blocksLOSArr[i] = traits.blocksLOS;
        }
    }

    function getKnownBoundaries()
        public
        view
        returns (
            string[] memory boundaryNames,
            string[] memory modelIdArr,
            bool[] memory blocksMovementArr,
            bool[] memory blocksLOSArr
        )
    {
        boundaryNames = new string[](knownBoundaryNames.length);
        modelIdArr = new string[](knownBoundaryNames.length);
        blocksMovementArr = new bool[](knownBoundaryNames.length);
        blocksLOSArr = new bool[](knownBoundaryNames.length);

        for (uint256 i = 0; i < knownBoundaryNames.length; i++) {
            boundaryNames[i] = knownBoundaryNames[i];
            BoundaryTraits memory traits = allBoundaries[boundaryNames[i]];

            modelIdArr[i] = traits.modelId;
            blocksMovementArr[i] = traits.blocksMovement;
            blocksLOSArr[i] = traits.blocksLOS;
        }
    }

    function getKnownMaps() public view returns (bytes32[] memory mapIds) {
        mapIds = new bytes32[](knownMaps.length);

        for (uint256 i = 0; i < knownMaps.length; i++) {
            mapIds[i] = knownMaps[i];
        }
    }

    // SPATIAL LOGIC (map independent)

    function distance(Vector2 memory pos1, Vector2 memory pos2)
        public
        pure
        returns (uint256)
    {
        return
            uint256(
                MathUtils.abs(int256(pos1.axis1 - pos2.axis1)) +
                    MathUtils.abs(
                        int256(
                            pos1.axis1 + pos1.axis2 - pos2.axis1 - pos2.axis2
                        )
                    ) +
                    MathUtils.abs(int256(pos1.axis2 - pos2.axis2))
            ) / 2;
    }

    function neighbors(Vector2 memory pos1, Vector2 memory pos2)
        public
        pure
        returns (bool)
    {
        return distance(pos1, pos2) == 1;
    }

    // note: we have no need for idToCoordinate because contract calls include axial coordinates
    //  rather than ids for anything mathematical
    function coordinateToId(Vector2 memory pos)
        public
        pure
        returns (string memory)
    {
        // this is fine because (v,w) position vectors are always positive
        uint256 r = uint256(pos.axis2);
        uint256 q = uint256(pos.axis1 + pos.axis2 / 2); /* solidity rounds down to zero */

        return q.toString().append('_', r.toString());
    }

    function vectorAdd(Vector2 memory pos1, Vector2 memory pos2)
        public
        pure
        returns (Vector2 memory)
    {
        return Vector2(pos1.axis1 + pos2.axis1, pos1.axis2 + pos2.axis2);
    }

    function scaleVector(Vector2 memory pos, int256 scale)
        public
        pure
        returns (Vector2 memory)
    {
        return Vector2(pos.axis1 * scale, pos.axis2 * scale);
    }

    function getAxialDirections() private pure returns (Vector2[6] memory) {
        Vector2[6] memory axialDirections;

        axialDirections[0] = Vector2(1, 0);
        axialDirections[1] = Vector2(1, -1);
        axialDirections[2] = Vector2(0, -1);
        axialDirections[3] = Vector2(-1, 0);
        axialDirections[4] = Vector2(-1, 1);
        axialDirections[5] = Vector2(0, 1);

        return axialDirections;
    }

    // SPATIAL LOGIC (map dependent)

    function getLocation(bytes32 mapId, string memory locationId)
        public
        view
        returns (LocationSpec memory locationSpec)
    {
        locationSpec = allLocationSpecs[mapId][locationId];
    }

    function getTerrainTraitsForLocation(
        bytes32 mapId,
        string memory locationId
    ) public view returns (TerrainTraits memory) {
        return allTerrains[allLocationSpecs[mapId][locationId].terrainName];
    }

    function moveIsValid(
        bytes32 mapId,
        // string memory locationIdOrigin,
        // Vector2 memory positionOrigin,
        string memory locationIdDest,
        Vector2 memory positionDest
    ) public view returns (bool valid) {
        LocationSpec memory destinationLocation = allLocationSpecs[mapId][
            locationIdDest
        ];

        bool destinationIsObstacle = allTerrains[
            destinationLocation.terrainName
        ].blocksMovement;

        bool isWithinBounds = withinBounds(mapId, positionDest);

        // TODO: boundaries logic here (requires vectors)

        valid = isWithinBounds && !destinationIsObstacle;
    }

    // Given a map spec, is a position expressed as vector2 within the bounds of the map?
    function withinBounds(bytes32 mapId, Vector2 memory pos)
        public
        view
        returns (bool isWithinBounds)
    {
        Vector2 memory topLeft = Vector2(0, 0);

        uint256 offsetX = distance(topLeft, Vector2(pos.axis1, 0));
        uint256 offsetY = distance(topLeft, Vector2(0, pos.axis2));

        bool satisfiesMin = offsetX >= 0 && offsetY >= 0;
        bool satisfiesMax = offsetX < allMapSpecs[mapId].width &&
            offsetY < allMapSpecs[mapId].height;

        isWithinBounds = satisfiesMin && satisfiesMax;
    }

    function getStartingPosition(bytes32 mapId, uint256 playerIdx)
        public
        view
        returns (string memory locationId, Vector2 memory location)
    {
        require(playerIdx < getMaxNumberOfPlayers(mapId), 'Map is full');

        StartingPositionSpec memory slp = allStartingPositions[mapId][
            playerIdx
        ];

        locationId = slp.locationId;
        location = slp.location;
    }

    function getStartingPositions(bytes32 mapId)
        public
        view
        returns (string[] memory locationIds)
    {
        locationIds = new string[](allStartingPositions[mapId].length);

        for (uint256 i = 0; i < allStartingPositions[mapId].length; i++) {
            locationIds[i] = allStartingPositions[mapId][i].locationId;
        }
    }
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File contracts/EnergyPurchases.sol

pragma solidity ^0.8.7;

abstract contract EnergyPurchases {
    function getEnergyPriceInTanks(uint256 nPurchases)
        public
        virtual
        returns (uint256);
}


// File contracts/TanksGame.sol

pragma solidity ^0.8.7;







contract TanksGame is Ownable {
    using MathUtils for uint256;
    using MathUtils for int256;
    using StringUtils for string;

    struct PlayerOnLocationInfo {
        Vector2 location;
        string locationId;
        address playerAddress;
    }

    ERC20 tanksToken;
    EnergyPurchases energyPurchases;

    event GameSpawned(
        bytes32 gameId,
        NewGameSpec newGameSpec,
        uint256 gameStart
    );

    event SpendEnergy(
        bytes32 gameId,
        address playerAddress,
        int256 amount,
        int256 totalSpentEnergy
    );
    event MoveTank(
        bytes32 gameId,
        address playerAddress,
        Vector2 origin,
        Vector2 destination
    );
    event AttackSuccess(
        bytes32 gameId,
        address senderPlayerAddress,
        address targetPlayerAddress,
        int256 heartsDelta,
        uint256 remainingHearts,
        bool didDestroy
    );
    event GiftEnergySuccess(
        bytes32 gameId,
        address senderPlayerAddress,
        address targetPlayerAddress,
        int256 spentEnergyDelta,
        int256 totalSpentEnergy
    );
    event GiftHeartsSuccess(
        bytes32 gameId,
        address senderPlayerAddress,
        address targetPlayerAddress,
        uint256 remainingHeartsSender,
        uint256 remainingHeartsTarget
    );
    event PurchaseHeartsSuccess(
        bytes32 gameId,
        address playerAddress,
        uint256 remainingHearts
    );
    event PurchaseRangeSuccess(
        bytes32 gameId,
        address playerAddress,
        uint256 playerRange
    );
    event TanksPurchaseSuccess(
        bytes32 gameId,
        address playerAddresses,
        uint256 purchaseEnergyCost,
        uint256 nPurchasesTotal
    );
    event GameEnd(bytes32 gameId, uint256 gameEnd, address winner);

    address public tokenAddress;
    address public lobbyAddress;

    mapping(bytes32 => GameSpec) public gamesMap;

    constructor(address tokenAddress_, address energyPurchasesAddress_)
        Ownable()
    {
        tanksToken = ERC20(tokenAddress_);
        energyPurchases = EnergyPurchases(energyPurchasesAddress_);
    }

    // --- modifiers ---

    modifier mustBeLobbyContract() {
        require(_msgSender() == lobbyAddress, 'Caller is not lobby contract');

        _;
    }

    modifier onlyCallableByPlayer(bytes32 gameId) {
        require(gamesMap[gameId].gameEnd == 0, 'Game has finished');

        require(
            gamesMap[gameId].playerMap[_msgSender()].playerAddress !=
                address(0),
            'Only callable by players'
        );
        require(
            gamesMap[gameId].playerMap[_msgSender()].hearts > 0,
            'Player has already been destroyed'
        );
        _;
    }

    modifier costsEnergy(bytes32 gameId, uint256 amount) {
        require(
            getEnergyForPlayer(gameId, _msgSender()) >= amount,
            'Player does not have enough energy to perform action'
        );

        PlayerStats storage player = gamesMap[gameId].playerMap[_msgSender()];
        player.spentEnergy += int256(amount);

        _;

        emit SpendEnergy(
            gameId,
            _msgSender(),
            int256(amount),
            player.spentEnergy
        );
    }

    modifier validTarget(bytes32 gameId, Vector2 memory target) {
        TanksMap map = TanksMap(gamesMap[gameId].mapContractAddress);

        uint256 distance = map.distance(
            gamesMap[gameId].playerMap[_msgSender()].location,
            target
        );

        require(distance > 0, 'Cannot target self');

        // TODO: obstacle check with ray tracing

        require(
            distance <= gamesMap[gameId].playerMap[_msgSender()].range,
            'Out of range'
        );

        require(
            gamesMap[gameId].occupancyMap[map.coordinateToId(target)] !=
                address(0),
            'Target must be occupied by a player'
        );

        _;
    }

    // --- public views ---

    /// Turns player info into a 2D matrix.
    function getPlayers(bytes32 gameId)
        external
        view
        returns (
            address[] memory playersAddresses,
            Vector2[] memory playersLocations,
            string[] memory playersLocationIds,
            uint256[] memory playersHearts,
            uint256[] memory playersRanges,
            int256[] memory playersSpentEnergies,
            uint256[] memory playersNPurchases
        )
    {
        GameSpec storage gameSpec = gamesMap[gameId];

        uint256 playerCount = gameSpec.playerCount;

        playersAddresses = new address[](playerCount);
        playersLocations = new Vector2[](playerCount);
        playersLocationIds = new string[](playerCount);
        playersHearts = new uint256[](playerCount);
        playersRanges = new uint256[](playerCount);
        playersSpentEnergies = new int256[](playerCount);
        playersNPurchases = new uint256[](playerCount);

        for (uint256 i = 0; i < playerCount; i++) {
            address playerAddress = gameSpec.playerAddresses[i];

            PlayerStats memory player = gameSpec.playerMap[playerAddress];

            playersAddresses[i] = player.playerAddress;
            playersLocations[i] = player.location;
            playersLocationIds[i] = player.locationId;
            playersHearts[i] = player.hearts;
            playersRanges[i] = player.range;
            playersSpentEnergies[i] = player.spentEnergy;
            playersNPurchases[i] = player.nPurchases;
        }
    }

    function getActiveGame(bytes32 gameId)
        external
        view
        returns (
            bytes32 mapId,
            address mapContractAddress,
            uint256 gameStart,
            uint256 gameEnd,
            address winner
        )
    {
        GameSpec storage gameSpec = gamesMap[gameId];

        return (
            gameSpec.mapId,
            gameSpec.mapContractAddress,
            gameSpec.gameStart,
            gameSpec.gameEnd,
            gameSpec.winner
        );
    }

    // --- game logic ---

    function move(bytes32 gameId, Vector2 memory destination)
        public
        onlyCallableByPlayer(gameId)
        costsEnergy(gameId, 1)
    {
        GameSpec storage game = gamesMap[gameId];

        TanksMap map = TanksMap(game.mapContractAddress);

        string memory locationIdDest = map.coordinateToId(destination);
        require(
            game.occupancyMap[locationIdDest] == address(0),
            'Destination is occupied'
        );

        require(
            map.moveIsValid(game.mapId, locationIdDest, destination),
            'Map: move is not valid'
        );

        PlayerStats storage player = game.playerMap[_msgSender()];

        Vector2 memory origin = player.location;
        string memory locationIdOrigin = player.locationId;

        require(
            map.neighbors(origin, destination),
            'Can only move between neighboring locations'
        );

        // --- mutations ---
        player.location = destination;
        player.locationId = locationIdDest;

        // update the occupancy map
        game.occupancyMap[locationIdOrigin] = address(0);
        game.occupancyMap[locationIdDest] = _msgSender();

        // --- events ---
        emit MoveTank(gameId, _msgSender(), origin, destination);
    }

    function attack(bytes32 gameId, Vector2 memory target)
        public
        onlyCallableByPlayer(gameId)
        costsEnergy(gameId, 1)
        validTarget(gameId, target)
    {
        (
            PlayerOnLocationInfo memory playerLocationInfo,
            PlayerStats storage targetPlayer
        ) = getTargetInfo(gameId, target);

        require(targetPlayer.hearts > 0, 'Target is already destroyed');

        targetPlayer.hearts -= 1;

        if (targetPlayer.hearts == 0) {
            // destroy the tank
            gamesMap[gameId].occupancyMap[
                playerLocationInfo.locationId
            ] = address(0);
            gamesMap[gameId].destroyedCount++;
            targetPlayer.locationId = '';
        }

        emit AttackSuccess(
            gameId,
            _msgSender(),
            playerLocationInfo.playerAddress,
            -1,
            targetPlayer.hearts,
            targetPlayer.hearts == 0
        );

        if (
            gamesMap[gameId].playerCount - gamesMap[gameId].destroyedCount == 1
        ) {
            gamesMap[gameId].gameEnd = block.timestamp;

            gamesMap[gameId].winner = _msgSender();
            emit GameEnd(gameId, gamesMap[gameId].gameEnd, _msgSender()); /* killing blow --> msgSender is the winner */
        }
    }

    function giftEnergy(bytes32 gameId, Vector2 memory target)
        public
        onlyCallableByPlayer(gameId)
        costsEnergy(gameId, 1)
        validTarget(gameId, target)
    {
        (
            PlayerOnLocationInfo memory playerLocationInfo,
            PlayerStats storage targetPlayer
        ) = getTargetInfo(gameId, target);

        targetPlayer.spentEnergy += -1;

        emit GiftEnergySuccess(
            gameId,
            _msgSender(),
            playerLocationInfo.playerAddress,
            -1,
            targetPlayer.spentEnergy
        );
    }

    function giftHearts(bytes32 gameId, Vector2 memory target)
        public
        onlyCallableByPlayer(gameId)
        validTarget(gameId, target)
    {
        GameSpec storage game = gamesMap[gameId];

        require(
            game.playerMap[_msgSender()].hearts > 1,
            'Cannot gift last heart'
        );

        (
            PlayerOnLocationInfo memory playerLocationInfo,
            PlayerStats storage targetPlayer
        ) = getTargetInfo(gameId, target);

        game.playerMap[_msgSender()].hearts -= 1;
        targetPlayer.hearts += 1;

        emit GiftHeartsSuccess(
            gameId,
            _msgSender(),
            game.occupancyMap[playerLocationInfo.locationId],
            game.playerMap[_msgSender()].hearts,
            targetPlayer.hearts
        );
    }

    function purchaseHearts(bytes32 gameId)
        public
        onlyCallableByPlayer(gameId)
        costsEnergy(gameId, 3)
    {
        GameSpec storage game = gamesMap[gameId];

        PlayerStats storage player = game.playerMap[_msgSender()];

        player.hearts += 1;

        emit PurchaseHeartsSuccess(gameId, _msgSender(), player.hearts);
    }

    function purchaseRange(bytes32 gameId)
        public
        onlyCallableByPlayer(gameId)
        costsEnergy(gameId, 3)
    {
        GameSpec storage game = gamesMap[gameId];

        PlayerStats storage player = game.playerMap[_msgSender()];

        player.range += 1;

        emit PurchaseRangeSuccess(gameId, _msgSender(), player.range);
    }

    function purchaseEnergy(bytes32 gameId)
        public
        onlyCallableByPlayer(gameId)
    {
        GameSpec storage game = gamesMap[gameId];

        uint256 tokenBalance = tanksToken.balanceOf(_msgSender());
        uint256 approvedAmount = tanksToken.allowance(
            _msgSender(),
            address(this)
        );

        PlayerStats storage player = game.playerMap[_msgSender()];

        uint256 purchaseEnergyCost = energyPurchases.getEnergyPriceInTanks(
            player.nPurchases
        );

        require(
            tokenBalance > purchaseEnergyCost &&
                approvedAmount > purchaseEnergyCost,
            'Purchase energy cost in TANKS exceeds approved amount'
        );

        // mutations

        player.spentEnergy -= 3;
        player.nPurchases += 1;

        tanksToken.transferFrom(
            _msgSender(),
            address(this),
            purchaseEnergyCost
        );

        emit SpendEnergy(gameId, _msgSender(), -3, player.spentEnergy);
        emit TanksPurchaseSuccess(
            gameId,
            _msgSender(),
            purchaseEnergyCost,
            player.nPurchases
        );
    }

    // --- admin ---

    function spawnGame(
        bytes32 gameId,
        NewGameSpec memory newGameSpec,
        address[] memory players
    ) public mustBeLobbyContract returns (bool) {
        GameSpec storage gameSpec = gamesMap[gameId];

        gameSpec.mapId = newGameSpec.mapId;
        gameSpec.mapContractAddress = newGameSpec.mapContractAddress;
        gameSpec.playerCount = players.length;
        gameSpec.energyFrequency = newGameSpec.energyFrequency;

        gameSpec.gameStart = block.timestamp;
        gameSpec.playerAddresses = players;

        TanksMap mapContract = TanksMap(gameSpec.mapContractAddress);

        for (uint256 i = 0; i < players.length; i++) {
            PlayerStats memory newPlayerStats;

            address playerAddress = players[i];

            newPlayerStats.playerAddress = playerAddress;

            (string memory locationId, Vector2 memory location) = mapContract
                .getStartingPosition(gameSpec.mapId, i);

            newPlayerStats.locationId = locationId;
            newPlayerStats.location = location;
            newPlayerStats.hearts = 2;
            newPlayerStats.range = 2;
            newPlayerStats.spentEnergy = 0;
            newPlayerStats.nPurchases = 0;

            gameSpec.playerMap[playerAddress] = newPlayerStats;
            gameSpec.occupancyMap[locationId] = playerAddress;
        }

        emit GameSpawned(gameId, newGameSpec, gameSpec.gameStart);

        return true;
    }

    function advanceFog(bytes32 gameId) public {
        // TODO: logically change position of the fog
    }

    function setLobbyContract(address lobbyAddress_) public onlyOwner {
        lobbyAddress = lobbyAddress_;
    }

    // --- private / helpers ---

    // given a target (i.e. location on map as vector2), provides data for player on the location
    function getTargetInfo(bytes32 gameId, Vector2 memory target)
        private
        view
        returns (PlayerOnLocationInfo memory, PlayerStats storage)
    {
        GameSpec storage gameSpec = gamesMap[gameId];
        TanksMap map = TanksMap(gameSpec.mapContractAddress);

        string memory targetLocationId = map.coordinateToId(target);

        address targetPlayerAddress = gamesMap[gameId].occupancyMap[
            targetLocationId
        ];

        PlayerStats storage targetPlayer = gamesMap[gameId].playerMap[
            targetPlayerAddress
        ];

        return (
            PlayerOnLocationInfo({
                location: target,
                locationId: targetLocationId,
                playerAddress: targetPlayerAddress
            }),
            targetPlayer
        );
    }

    function accumulatedEnergy(bytes32 gameId) private view returns (uint256) {
        uint256 BASE_ENERGY = 3; /* TODO: make configable */

        uint256 energyFrequency = gamesMap[gameId].energyFrequency;
        uint256 gameStart = gamesMap[gameId].gameStart;

        // solidity uses floor division so this works well
        uint256 accumedOnly = (block.timestamp - gameStart) / (energyFrequency); /* value is supplied in millis; calcs done in seconds */

        return BASE_ENERGY + accumedOnly;
    }

    function getEnergyForPlayer(bytes32 gameId, address playerAddress)
        private
        view
        returns (uint256)
    {
        return
            uint256(
                int256(accumulatedEnergy(gameId)) -
                    gamesMap[gameId].playerMap[playerAddress].spentEnergy
            );
    }
}