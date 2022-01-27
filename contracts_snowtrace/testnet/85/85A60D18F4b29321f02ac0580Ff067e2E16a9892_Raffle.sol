// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/IRarity.sol";
import "../interfaces/IrERC20.sol";
import "../interfaces/IRandomCodex.sol";
import "../interfaces/onlyExtended.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Raffle is OnlyExtended, IERC721Receiver {

    uint private globalSeed = 0; //Used in `_get_random()`
    uint public endTime;
    uint public rewardForSacrifice = 150;
    IrERC20 private candies;
    IRandomCodex private randomCodex;
    IRarity private rm;
    IERC721 private Skins;

    uint[] public participants;
    address[] public winners;
    uint[] public skinsIds;
    mapping(uint => uint) ticketsPerSummoner;

    bool public rewarded = false;
    bool public prizesLoaded = false;

    constructor(address _rm, address _candies, address _randomCodex, address _skins) {
        candies = IrERC20(_candies);
        randomCodex = IRandomCodex(_randomCodex);
        rm = IRarity(_rm);
        Skins = IERC721(_skins);

        endTime = block.timestamp + 7 days; //Raffle end in 7 days
    }

    function _isApprovedOrOwner(uint _adventurer, address _operator) internal view returns (bool) {
        return (rm.getApproved(_adventurer) == _operator || rm.ownerOf(_adventurer) == _operator || rm.isApprovedForAll(rm.ownerOf(_adventurer), _operator));
    }

    function _get_random(uint limit, bool withZero) internal view returns (uint) {
        //pseudo random fn
        uint _globalSeed = globalSeed;
        _globalSeed += gasleft();
        uint result = 0;
        if (withZero) {
            result = randomCodex.dn(_globalSeed, limit);
        }else{
            if (limit == 1) {
                return 1;
            }
            result = randomCodex.dn(_globalSeed, limit);
            result += 1;
        }
        return result;
    }

    function _update_global_seed() internal {
        string memory _string = string(
            abi.encodePacked(
                abi.encodePacked(msg.sender), 
                abi.encodePacked(block.timestamp), 
                abi.encodePacked(globalSeed), 
                abi.encodePacked(block.difficulty), 
                abi.encodePacked(gasleft())
            )
        );
        globalSeed = uint256(keccak256(abi.encodePacked(_string)));
    }

    function _check_if_already_won(address[] memory currentWinners, address target) internal pure returns (bool) {
        //Return TRUE if target already won
        for (uint256 k = 0; k < currentWinners.length; k++) {
            address winner = currentWinners[k];
            if (winner == target){
                return true;
            }
        }
        return false;
    }

    function loadPrizes(uint[] memory _skinsIds) external onlyExtended {
        //Load NFTs in this contract
        skinsIds = _skinsIds;

        for (uint256 h = 0; h < _skinsIds.length; h++) {
            Skins.safeTransferFrom(msg.sender, address(this), _skinsIds[h]);
        }

        prizesLoaded = true;
    }

    function enterRaffle(uint summoner, uint amount) external {
        //Enter raffle, burn amount
        require(block.timestamp <= endTime, "!endTime");
        require(amount != 0, "zero amount");
        require(amount % 25 == 0, "!amount"); //Can only enter raffle with multiples of 25
        require(_isApprovedOrOwner(summoner, msg.sender), "!owner");
        candies.burn(summoner, amount);
        uint tickets = amount / 25;
        for (uint256 i = 0; i < tickets; i++) {
            participants.push(summoner);
        }
        ticketsPerSummoner[summoner] += tickets;
        _update_global_seed();
    }

    function sacrifice(uint summonerToSacrifice, uint summonerToReceive) external {
        //Sacrifice a summoner for candies
        require(block.timestamp <= endTime, "!endTime");
        require(rm.level(summonerToSacrifice) >= 4, "!level");
        rm.safeTransferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), summonerToSacrifice, "");
        candies.mint(summonerToReceive, rewardForSacrifice);
    }

    function reward() external onlyExtended {
        //Admin execute the raffle
        require(block.timestamp >= endTime, "!endTime");
        require(!rewarded, "rewarded");
        require(prizesLoaded, "!prizes");
        uint[] memory _participants = participants;
        require(skinsIds.length < _participants.length, "!participantsLength");

        for (uint256 e = 0; e < skinsIds.length; e++) {
            uint num = _get_random(participants.length, true);
            address candidate = rm.ownerOf(_participants[num]);

            if(!_check_if_already_won(winners, candidate)){ //check if already won
                winners.push(candidate);
            }else{
                e--;
            }
        }

        rewarded = true;

        //Airdrop
        for (uint256 gm = 0; gm < winners.length; gm++) {
            Skins.safeTransferFrom(address(this), winners[gm], skinsIds[gm]);
        }
    }

    function getTicketsPerSummoner(uint summoner) external view returns (uint) {
        return ticketsPerSummoner[summoner];
    }

    function getWinners() external view returns (address[] memory) {
        return winners;
    }

    function getParticipants() external view returns (uint[] memory) {
        return participants;
    }

    function getWinningOdds(uint summoner, uint plusTickets) external view returns (uint, uint) {
        uint tickets = ticketsPerSummoner[summoner] + plusTickets;
        uint totalParticipants = participants.length + plusTickets;
        uint prizesCount = skinsIds.length;
        
        uint numerator = 0;
        uint denominator = 0;

        if(prizesCount <= totalParticipants && totalParticipants > 0){
            numerator = tickets;
            denominator = totalParticipants;
        }else{
            return (100, 100);
        }

        // Return odds in numerator/denominator
        return (numerator, denominator);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IRarity {
    function adventure(uint _summoner) external;
    function xp(uint _summoner) external view returns (uint);
    function level_up(uint _summoner) external;
    function adventurers_log(uint adventurer) external view returns (uint);
    function approve(address to, uint256 tokenId) external;
    function level(uint) external view returns (uint);
    function class(uint) external view returns (uint);
    function getApproved(uint) external view returns (address);
    function ownerOf(uint) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function classes(uint id) external pure returns (string memory);
    function summoner(uint _summoner) external view returns (uint _xp, uint _log, uint _class, uint _level);
    function spend_xp(uint _summoner, uint _xp) external;
    function next_summoner() external view returns (uint);
    function summon(uint _class) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IrERC20 {
    function burn(uint from, uint amount) external;
    function mint(uint to, uint amount) external;
    function approve(uint from, uint spender, uint amount) external returns (bool);
    function transfer(uint from, uint to, uint amount) external returns (bool);
    function transferFrom(uint executor, uint from, uint to, uint amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IRandomCodex {
    function dn(uint _summoner, uint _number) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

abstract contract OnlyExtended {
    address public extended;
    address public pendingExtended;

    constructor() {
        extended = msg.sender;
    }

    modifier onlyExtended() {
        require(msg.sender == extended, "!owner");
        _;
    }
    modifier onlyPendingExtended() {
		require(msg.sender == pendingExtended, "!authorized");
		_;
	}

    /*******************************************************************************
	**	@notice
	**		Nominate a new address to use as Extended.
	**		The change does not go into effect immediately. This function sets a
	**		pending change, and the management address is not updated until
	**		the proposed Extended address has accepted the responsibility.
	**		This may only be called by the current Extended address.
	**	@param _extended The address requested to take over the role.
	*******************************************************************************/
    function setExtended(address _extended) public onlyExtended() {
		pendingExtended = _extended;
	}


	/*******************************************************************************
	**	@notice
	**		Once a new extended address has been proposed using setExtended(),
	**		this function may be called by the proposed address to accept the
	**		responsibility of taking over the role for this contract.
	**		This may only be called by the proposed Extended address.
	**	@dev
	**		setExtended() should be called by the existing extended address,
	**		prior to calling this function.
	*******************************************************************************/
    function acceptExtended() public onlyPendingExtended() {
		extended = msg.sender;
	}
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}