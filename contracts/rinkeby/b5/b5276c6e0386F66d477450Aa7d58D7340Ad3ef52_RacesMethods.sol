// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '../../openzeppelin/access/Ownable.sol';
import '../../utils/FilterForWinners.sol';
import '../../hounds/Hound.sol';
import '../../hounds/IData.sol';
import '../../payments/Payments.sol';

import './Race.sol';
import './Queue.sol';
import '../Constructor.sol';


contract RacesMethods is Ownable, Payments {
    
    event NewRace(Race.Struct queue);
    uint256 public queueId = 1;
    uint256 public raceId = 1;
    Constructor.Struct public control;
    mapping(uint256 => Race.Struct) public queues;
    string error = "Failed to delegatecall";

    /**
     * DIIMIIM:
     * We'll save the races structure as bytes and we'll decode them into their specific tuple using their specific generator contract
     */
    mapping(uint256 => Race.Finished) public races;    

    function setGlobalParameters(
        Constructor.Struct memory input
    ) external {
        control = input;
    }

    function createQueues(Queue.Struct[] memory theQueues) external {
        for ( uint256 i = 0 ; i < theQueues.length ; ++i ) {
            queues[queueId].arena = theQueues[i].arena;
            queues[queueId].entryFee = theQueues[i].entryFee;
            queues[queueId].currency = theQueues[i].currency;
            queues[queueId].totalParticipants = theQueues[i].totalParticipants;
            ++queueId;
        }
    }

    function deleteQueue(uint256 theQueueId) external {
        delete queues[theQueueId];
    }

    function uploadRace(Race.Finished memory race, Payment.Struct[] memory payments) external {
        
        // Save the finished race
        races[raceId] = race;

        // Perform all race payments / rewards
        compoundTransfer(payments);

        // Increase the finished race id
        ++raceId;

    }

    /*
     * DIIMIIM:
     * Enqueue method
     */
    function enqueue(uint256 theQueueId, uint256 theHoundId) external payable {
    
        require(queues[queueId].totalParticipants > 0, "31");

        // Queue verifications
        require(msg.value >= queues[theQueueId].entryFee, "17");

        // Hound verifications
        Hound.Struct memory hound = IHoundsData(control.hounds).hound(theHoundId);

        require(!hound.running, "13");

        bool success;
        bytes memory output;

        // Adds the participant in the queue
        queues[theQueueId].participants.push(theHoundId);
        
        IHoundsData(control.hounds).updateHoundStamina(theHoundId);

        // If last participant in the queue is calling this
        if ( queues[theQueueId].participants.length == queues[theQueueId].totalParticipants ) {


            /*
             * DIIMIIM:
             * Blockchain race generator
             * No custom rewards mechanism available
             */
            if ( control.callable ) {
                
                (success, output) = control.raceGenerator.call{ value: queues[theQueueId].entryFee * queues[theQueueId].totalParticipants }(
                    abi.encodeWithSignature(
                        "generate((uint256,uint256[],address,uint256,uint32))",
                        queues[theQueueId]
                    )
                );
                require(success,error);
                
                races[raceId] = abi.decode(output,(Race.Finished));

                ++raceId;


            /*
             * DIIMIIM:
             * Back-end race generator
             * Fully customizable
             */
            } else {

                emit NewRace(queues[theQueueId]);

            }

            delete queues[theQueueId].participants;

        }

    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library FilterForWinners {

    function filterForWinners(uint256[] memory participants) internal pure returns(uint256[3] memory winners) {
        for ( uint256 i = 0 ; i < participants.length ; ++i ) {

            if (participants[i] > winners[0]) {
                winners[2] = winners[1];
                winners[1] = winners[0];
                winners[0] = i;
            } else if ( participants[i] > winners[1]) {
                winners[2] = winners[1];
                winners[1] = i;
            } else if (participants[i] > winners[2])
                winners[2] = i;

        }
    }

}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;

import './Statistics.sol';
import './Stamina.sol';
import './Breeding.sol';
import './Identity.sol';


library Hound {
    
    struct Struct {
        Statistics.Struct statistics;
        Stamina.Struct stamina;
        Breeding.Struct breeding;
        Identity.Struct identity;
        string title;
        string token_url;
        bool custom;
        bool running;
    }
    
}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;

import './GlobalVariables.sol';
import './Hound.sol';


interface IHoundsData {
    function setGlobalParameters(GlobalVariables.Struct memory input) external;
    function adminCreateHound(Hound.Struct memory theHounds) external;
    function breedHounds(uint256 hound1, uint256 hound2) external payable;
    function updateHoundStamina(uint256 theHoundId) external;
    function updateHoundBreeding(uint256 theHoundId, uint256 breedingCooldownToConsume) external;
    function putHoundForBreed(uint256 _hound, uint256 fee, bool status) external;
    function hound(uint256 theHoundId) external view returns(Hound.Struct memory);
    function ownerOf(uint256 tokenId) external view returns(address);
    function handleHoundTransfer(uint256 theHoundId, address from, address to) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function tokenURI(uint256 _tokenId) external view returns(string memory);
    function setTokenURI(uint256 _tokenId, string memory token_url) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '../openzeppelin/token/ERC20/IERC20.sol';

import './Payment.sol';


contract Payments {

	function transferTokens(
        address from,
        address payable to,
        address currency,
        uint256 qty
	) public payable {
		if ( currency != address(0) ) {
			require(IERC20(currency).transferFrom(from, to, qty), "15");
		} else {
			require(to.send(qty), "14");
		}
	}

	function compoundTransfer(Payment.Struct[] memory payments) public payable {
		uint256 l = payments.length;
		uint256 totalPaid;
		for ( uint i = 0 ; i < l ; ++i ) {
			totalPaid += payments[i].qty;
			require(msg.value >= totalPaid, "30");
			transferTokens(payments[i].from, payable(payments[i].to), payments[i].currency, payments[i].qty);
		}
	}

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library Race {
    
    /**
     * DIIMIIM:
     * Participants can pay with multiple currencies, ETH included
     */
    struct Struct {

        // address(0) for ETH
        address currency;

        // Participants
        // totalParticipants will be the array length here
        uint256[] participants;

        // arena of the race
        uint256 arena;

        // ETH based
        uint256 entryFee;

        // Start date
        uint256 startDate;

        // Total number of participants
        uint32 totalParticipants;

    }

    struct Finished {

        // address(0) for ETH
        address currency;

        // Race seed
        uint256[] participants;

        // arena of the race
        uint256 arena;

        // ETH based
        uint256 entryFee;

        // Race randomness
        uint256 seed;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library Queue {
    
    /**
     * DIIMIIM:
     * Params used to create a race
     */
    struct Struct {

        // Arena of the race
        uint256 arena;

        // address(0) for ETH
        address currency;

        // Price of the race
        uint256 entryFee;

        // Required stamina
        uint32 stamina;

        // Total number of participants
        uint32 totalParticipants;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library Constructor {
    
    struct Struct {

        address randomness;
        address terrains;
        address hounds;
        address allowed;
        address methods;
        address raceGenerator;

        /* Stater race fee */
        uint256 raceFee;

        /* False if race is uploaded by admin, true if it's blockchain generated */
        bool callable;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library Statistics {
    
    struct Struct {
        uint64 totalRuns;
        uint64 firstPlace;
        uint64 secondPlace;
        uint64 thirdPlace;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library Stamina {
    
    struct Struct {
        uint256 lastUpdate;
        uint256 staminaRefill1x;
        uint32 stamina;
        uint32 staminaPerHour;
        uint32 staminaCap;
    }
    
}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;

library Breeding {
    
    struct Struct {
        uint256 breedCooldown;
        uint256 breedingFee;
        uint256 lastUpdate;
        bool availableToBreed;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library Identity {
    
    struct Struct {
        uint32[50] geneticSequence;
        uint256 generation;
        uint32[50] maleParent;
        uint32[50] femaleParent;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library GlobalVariables {
    
    struct Struct {
        address[] allowedCallers;
        address incubator;
        address methods;
        uint256 breedCost;
        uint256 breedFee;
        uint256 refillCost;
        bool[] isAllowed;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/IERC20.sol)

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
pragma solidity <=0.8.10;


library Payment {
    
    struct Struct {
        address from;
        address to;
        address currency;
        uint256 qty;
    }

}