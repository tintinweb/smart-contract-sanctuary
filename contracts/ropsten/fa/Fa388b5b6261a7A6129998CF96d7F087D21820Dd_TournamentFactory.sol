/// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interface/ITournament.sol";
import "./interface/IRegistry.sol";


contract TournamentFactory {

    /***************
    GLOBAL VARIABLES
    ***************/
    IRegistry public registry;

    address private _owner;

    uint16 constant public MIN_VOTING_PERIOD = 3600; // 1 hour

    /***************
    EVENTS
    ***************/
    event BalanceWithdrawn(uint256 indexed amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TournamentCreated(address indexed creator, address indexed tournamentAddr);

    /***************
    MODIFIERS
    ***************/
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /***************
    FUNCTIONS
    ***************/

    /// @dev Contructor sets the Pool implementation contract's address
    /// @param _registry The address for the Registry contract
    /// @param _implementation The address for the Tournament implementation contract
    constructor(address _registry, address _implementation) {
        registry = IRegistry(_registry);
        registry.setTournamentFactoryAddress(address(this));
        registry.setTournamentAddress(_implementation);
        _owner = msg.sender;
    }

    /** @dev Creates a Tournament with custom parameters
     * Creator must pay tournament creation fee of 0.005 ETH
     * @param startTime Start time of the tournament (NFT submission deadline)
     * @param bracketSize Maximum size of the bracket. Reverts if invalid (not a sq. num)
     * @param votingPeriod How much time users have to vote in each round (seconds)
     * @param whitelistedNFT (Optional) Allows Tournament creators to limit the Tournament to one type of NFT
     * @return Address of the new Tournament
    */
    function createTournament(
        uint256 startTime,
        uint256 votingPeriod,
        uint8 bracketSize,
        address whitelistedNFT
    )
        external
        payable
        returns (address)

    {
        require(startTime > block.timestamp, "startTime must be greater than now");
        require(votingPeriod >= MIN_VOTING_PERIOD, "votingPeriod must be at least 1 hour");
        require(msg.value == 0.005 ether, "tournament creation fee is 0.005 ETH");

        uint8[7] memory validBracketSizes = [2, 4, 8, 16, 32, 64, 128];

        // check bracketSize validity
        for (uint256 i = 0; i < 7; i++) {
            if (validBracketSizes[i] == bracketSize) {
                break;
            } else if (i == 6) {
                revert("bracketSize must be a square num <= 128");
            }
        }

        address tournament = Clones.clone(registry.tournament());
        ITournament(tournament).initialize(startTime, votingPeriod, bracketSize, whitelistedNFT, address(registry), msg.sender);

        emit TournamentCreated(msg.sender, tournament);
        
        return tournament;

    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     * @param newOwner address to transfer ownership privileges to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Transfers contract balance (from tournament creation fees) to owner
     * Can only be called by the current owner.
     */
    function withdrawBalance() external onlyOwner {
        uint256 amount = address(this).balance;
        
        emit BalanceWithdrawn(amount);
        
        payable(msg.sender).transfer(amount);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
        return _owner;
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

/// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.0;

/**
 * @title Interface for Tournament implementation contract
 */

interface ITournament {
    
    function initialize(
        uint256 _startTime,
        uint256 _votingPeriod,
        uint8 _bracketSize,
        address _whitelistedNFT,
        address _registry,
        address _owner    
    ) external;
    function transferOwnership(address newOwner) external;
    function startTournament() external;
    function endTournament() external;
    function submitNFT(address _addr, uint256 _tokenId) external;
    function castVote(uint8 submissionId, uint8 matchId, uint256 numVotes) external;
    function withdrawNFT(uint8 submissionId) external;
    function claimAuctionNFT(uint8 submissionId) external;
    function claimMatchNFT(uint8 submissionId, uint8 matchId) external;
    function claimWinningsMultiple(uint8[] calldata matchIds) external;
    function claimAndVote(
        uint8[] calldata claimMatchIds,
        uint8 voteSubmissionId,
        uint8 voteMatchId)
        external;
    function startAuction(uint8 submissionId, uint8 matchId) external;
    function determineMatchPair(uint8 matchId) external;
    function bid(uint8 submissionId) external payable;
    function withdrawBid(uint8 submissionId) external;
    function withdrawWinnings(uint8 submissionId) external;
    function withdrawAdminFee() external;
    function owner() external view;
    function winner() external view returns (uint8, address, address, uint256);
    function totalSubmissions() external view returns (uint8);
    function minBid() external view returns (uint256);
    function getTournamentInfo() external view returns (uint256, uint256, uint8, address);
    function getAuctionInfo(uint8 submissionId) external view returns (address, uint256, uint256);
    function getWithdrawableRefund(address bidder, uint8 submissionId) external view returns (uint256);
    function getMatchInfo(uint8 id) external view returns (uint8, uint8, uint256, uint256);

}

/// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.0;

/**
 * @title Interface for Registry
 */

interface IRegistry {
    function setTournamentAddress(address _addr) external;
    function setTournamentFactoryAddress(address _addr) external;
    function setTribeTokenAddress(address _addr) external;

    function tournament() external view returns (address);
    function tournamentFactory() external view returns (address);
    function tribeToken() external view returns (address);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 800
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}