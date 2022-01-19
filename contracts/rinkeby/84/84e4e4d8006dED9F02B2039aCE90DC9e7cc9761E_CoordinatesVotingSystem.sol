// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CoordinatesVotingSystem is ReentrancyGuard {
    // Info of point
    struct Point {
        uint256 x;
        uint256 y;
    }

    // Info of terrain
    struct Terrain {
        Point point1;
        Point point2;
        address owner;
    }

    // Info of proposal
    struct Proposal {
        uint256 voteCnt;
        address creator;
        Terrain terrain;
    }

    uint256 public totalOwnerCnt;
    uint8 public immutable MAXIMUM_TERRAIN_SIZE;
    Terrain[] public maps;

    // x value => y value => owner address
    mapping(uint256 => mapping(uint256 => address)) public terrainOwners;
    // owner address => status
    mapping(address => bool) public owners;
    // proposal name => proposal
    mapping(string => Proposal) public buyProposals;
    // proposal name => proposal
    mapping(string => Proposal) public extendProposals;
    // user => proposal name => status
    mapping(address => mapping(string => bool)) public hasBuyProposaled;
    // user => proposal name => status
    mapping(address => mapping(string => bool)) public hasExtendProposaled;
    // user => proposal name => status
    mapping(address => mapping(string => bool)) public terrainVoters;
    // user => proposal name => status
    mapping(address => mapping(string => bool)) public mapVoters;

    /**
     * @dev Emitted when a new terrain is added
     */
    event TerrianAdded(
        address indexed user,
        Terrain terrain,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a new map is added
     */
    event MapAdded(address indexed user, Terrain terrain, uint256 timestamp);

    /**
     * @dev Emitted when owner of terrain is changed
     */
    event TerrianOwnerChanged(
        address indexed user,
        Terrain terrain,
        uint256 timestamp
    );

    /**
     * @dev Emitted when buy proposal is created
     */
    event BuyProposalCrated(
        address indexed user,
        string proposalName,
        uint256 timestamp
    );

    /**
     * @dev Emitted when extend proposal is created
     */
    event ExtendProposalCrated(
        address indexed user,
        string proposalName,
        uint256 timestamp
    );

    /**
     * @dev Emitted when buy proposal is voted
     */
    event BuyProposalVoted(
        address indexed owner,
        string proposalName,
        uint256 timestamp
    );

    /**
     * @dev Emitted when extend proposal is voted
     */
    event ExtendProposalVoted(
        address indexed owner,
        string proposalName,
        uint256 timestamp
    );

    modifier onlyOwner(address _user) {
        require(owners[msg.sender], "Not owner");
        _;
    }

    /**
     * @notice Initialize contract
     * @param _x1     x value of left
     * @param _x2     x value of right
     * @param _y1     y value of top
     * @param _y2     y value of bottom
     */
    constructor(
        uint256 _x1,
        uint256 _x2,
        uint256 _y1,
        uint256 _y2
    ) {
        require(_x2 > _x1, "Incorrect x order");
        require(_y2 > _y1, "Incorrect y order");
        (
            uint256 x1,
            uint256 x2,
            uint256 y1,
            uint256 y2
        ) = _sortCoordinatePoints(_x1, _x2, _y1, _y2);

        Terrain memory _terrain = Terrain(
            Point(x1, y1),
            Point(x2, y2),
            msg.sender
        );

        maps.push(_terrain);
        owners[msg.sender] = true;
        totalOwnerCnt += 1;
        MAXIMUM_TERRAIN_SIZE = 3;

        emit TerrianAdded(msg.sender, _terrain, block.timestamp);
    }

    /**
     * @notice Sort coordinate points
     * @param _x1     x value of bottom left point
     * @param _x2     x value of bottom right point
     * @param _y1     y value of top left point
     * @param _y2     y value of top right point
     * @return x1     x value of bottom left point
     * @return x2     x value of bottom right point
     * @return y1     y value of top left point
     * @return y2     y value of top right point
     */
    function _sortCoordinatePoints(
        uint256 _x1,
        uint256 _x2,
        uint256 _y1,
        uint256 _y2
    )
        internal
        pure
        returns (
            uint256 x1,
            uint256 x2,
            uint256 y1,
            uint256 y2
        )
    {
        x1 = _x1;
        x2 = _x2;
        y1 = _y1;
        y2 = _y2;
        if (_x1 > _x2) {
            x1 = _x2;
            x2 = _x1;
        }
        if (_y1 > _y2) {
            y1 = _y2;
            y2 = _y1;
        }
    }

    /**
     * @notice Check if terrain can be sold
     * @param _x1     x value of left
     * @param _x2     x value of right
     * @param _y1     y value of top
     * @param _y2     y value of bottom
     * @return isValid     valid status of terrain
     */
    function _isValidTerrain(
        uint256 _x1,
        uint256 _x2,
        uint256 _y1,
        uint256 _y2
    ) internal view returns (bool isValid) {
        isValid = true;

        if (
            _x2 > _x1 + MAXIMUM_TERRAIN_SIZE || _y2 > _y1 + MAXIMUM_TERRAIN_SIZE
        ) {
            isValid = false;
            revert("Out of terrain size");
        }
        for (uint256 x = _x1; x < _x2; x++) {
            for (uint256 y = _y1; y < _y2; y++) {
                if (terrainOwners[x][y] != address(0)) {
                    isValid = false;
                    break;
                }
            }
        }
    }

    /**
     * @notice Check if terrain or map is inside map array
     * @param _x1     x value of left
     * @param _x2     x value of right
     * @param _y1     y value of top
     * @param _y2     y value of bottom
     * @return isInside     valid status of terrain
     */
    function _isInsideMap(
        uint256 _x1,
        uint256 _x2,
        uint256 _y1,
        uint256 _y2
    ) internal view returns (bool isInside) {
        isInside = true;
        for (uint256 i = 0; i < maps.length; i++) {
            Terrain memory map = maps[i];
            if (
                _x1 < map.point1.x ||
                _x2 > map.point2.x ||
                _y1 < map.point1.y ||
                _y2 > map.point2.y
            ) {
                isInside = false;
                break;
            }
        }
    }

    /**
     * @notice Set terrain owner
     * @param _x1     x value of left
     * @param _x2     x value of right
     * @param _y1     y value of top
     * @param _y2     y value of bottom
     */
    function _setTerrainOwner(
        uint256 _x1,
        uint256 _x2,
        uint256 _y1,
        uint256 _y2,
        address _owner
    ) internal {
        for (uint256 x = _x1; x < _x2; x++) {
            for (uint256 y = _y1; y < _y2; y++) {
                if (terrainOwners[x][y] == address(0)) {
                    terrainOwners[x][y] = _owner;
                } else {
                    revert("Set terrain owner failed");
                }
            }
        }
    }

    /**
     * @notice Get buy proposal
     * @param _name     proposal name
     * @return      proposal info
     */
    function getBuyProposal(string memory _name)
        public
        view
        returns (Proposal memory)
    {
        return buyProposals[_name];
    }

    /**
     * @notice Get extend proposal
     * @param _name     proposal name
     * @return      proposal info
     */
    function getExtendProposal(string memory _name)
        public
        view
        returns (Proposal memory)
    {
        return extendProposals[_name];
    }

    /**
     * @notice Get buy proposal status
     * @param _user     user address
     * @param _name     proposal name
     * @return    proposal status
     */
    function getBuyProposalStatus(address _user, string memory _name)
        public
        view
        returns (bool)
    {
        return hasBuyProposaled[_user][_name];
    }

    /**
     * @notice Get extend proposal status
     * @param _user     user address
     * @param _name     proposal name
     * @return    proposal status
     */
    function getExtendProposalStatus(address _user, string memory _name)
        public
        view
        returns (bool)
    {
        return hasExtendProposaled[_user][_name];
    }

    /**
     * @notice Get terrain voter status
     * @param _user     user address
     * @param _name     proposal name
     * @return    voter status
     */
    function getTerrainVoterStatus(address _user, string memory _name)
        public
        view
        returns (bool)
    {
        return terrainVoters[_user][_name];
    }

    /**
     * @notice Get map voter status
     * @param _user     user address
     * @param _name     proposal name
     * @return    voter status
     */
    function getMapVoterStatus(address _user, string memory _name)
        public
        view
        returns (bool)
    {
        return mapVoters[_user][_name];
    }

    /**
     * @notice Create a proposal to buy terrain
     * @param _name     name of proposal
     * @param _x1     x value of bottom left point
     * @param _x2     x value of bottom right point
     * @param _y1     y value of top left point
     * @param _y2     y value of top right point
     */
    function makeBuyProposal(
        string memory _name,
        uint256 _x1,
        uint256 _x2,
        uint256 _y1,
        uint256 _y2
    ) external {
        require(
            buyProposals[_name].creator == address(0),
            "Proposal name was already used"
        );

        (
            uint256 x1,
            uint256 x2,
            uint256 y1,
            uint256 y2
        ) = _sortCoordinatePoints(_x1, _x2, _y1, _y2);

        require(_isInsideMap(x1, x2, y1, y2), "Terrain is not in map");
        require(_isValidTerrain(x1, x2, y1, y2), "Terrain was already sold");

        Proposal memory _proposal = Proposal(
            0,
            msg.sender,
            Terrain(Point(x1, y1), Point(x2, y2), msg.sender)
        );
        buyProposals[_name] = _proposal;
        hasBuyProposaled[msg.sender][_name] = true;

        emit BuyProposalCrated(msg.sender, _name, block.timestamp);
    }

    /**
     * @notice Vote on a proposal to buy terrain
     * @param _name     name of proposal
     */
    function voteTerrainProposal(string memory _name)
        external
        onlyOwner(msg.sender)
    {
        Proposal memory _proposal = buyProposals[_name];
        require(
            buyProposals[_name].creator != msg.sender,
            "Proposal can't be voted by proposal creator"
        );
        require(
            buyProposals[_name].creator != address(0),
            "Proposal was not made with this name"
        );
        require(!terrainVoters[msg.sender][_name], "Already voted");

        terrainVoters[msg.sender][_name] = true;
        buyProposals[_name].voteCnt += 1;
        if (totalOwnerCnt == buyProposals[_name].voteCnt) {
            totalOwnerCnt += 1;
            owners[_proposal.creator] = true;
            _setTerrainOwner(
                _proposal.terrain.point1.x,
                _proposal.terrain.point2.x,
                _proposal.terrain.point1.y,
                _proposal.terrain.point2.y,
                _proposal.creator
            );

            emit TerrianOwnerChanged(
                msg.sender,
                _proposal.terrain,
                block.timestamp
            );
        }
        emit BuyProposalVoted(msg.sender, _name, block.timestamp);
    }

    /**
     * @notice Create a proposal to extend terrain
     * @param _name     name of proposal
     * @param _x1     x value of bottom left point
     * @param _x2     x value of bottom right point
     * @param _y1     y value of top left point
     * @param _y2     y value of top right point
     */
    function makeExtendProposal(
        string memory _name,
        uint256 _x1,
        uint256 _x2,
        uint256 _y1,
        uint256 _y2
    ) external {
        require(
            extendProposals[_name].creator == address(0),
            "Extend Proposal name was already used"
        );

        (
            uint256 x1,
            uint256 x2,
            uint256 y1,
            uint256 y2
        ) = _sortCoordinatePoints(_x1, _x2, _y1, _y2);

        require(
            !_isInsideMap(x1, x2, y1, y2),
            "Map is overlapped with existing maps"
        );

        Proposal memory _proposal = Proposal(
            0,
            msg.sender,
            Terrain(Point(x1, y1), Point(x2, y2), msg.sender)
        );
        extendProposals[_name] = _proposal;
        hasExtendProposaled[msg.sender][_name] = true;

        emit ExtendProposalCrated(msg.sender, _name, block.timestamp);
    }

    /**
     * @notice Vote on a proposal to extend map
     * @param _name     name of proposal
     */
    function voteMapProposal(string memory _name)
        external
        onlyOwner(msg.sender)
    {
        Proposal memory _proposal = extendProposals[_name];
        require(
            extendProposals[_name].creator != msg.sender,
            "Proposal can't be voted by proposal creator"
        );
        require(
            extendProposals[_name].creator != address(0),
            "Proposal was not made with this name"
        );
        require(!mapVoters[msg.sender][_name], "Already voted");

        mapVoters[msg.sender][_name] = true;
        extendProposals[_name].voteCnt += 1;
        if (totalOwnerCnt == extendProposals[_name].voteCnt) {
            maps.push(_proposal.terrain);
            emit MapAdded(msg.sender, _proposal.terrain, block.timestamp);
        }
        emit ExtendProposalVoted(msg.sender, _name, block.timestamp);
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}