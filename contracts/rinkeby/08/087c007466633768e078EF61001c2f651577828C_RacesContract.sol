// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import '../openzeppelin/access/Ownable.sol';
import '../libraries/race/Race.sol';
import '../libraries/caller/Caller.sol';
import '../libraries/terrain/Terrain.sol';
import '../libraries/wrappedHound/WrappedHound.sol';
import '../libraries/hound/Hound.sol';
import '../libraries/terrainsConstructorParams/TerrainsConstructorParams.sol';
import '../libraries/houndsConstructorParamsRaces/HoundsConstructorParamsRaces.sol';
import '../libraries/randomNumberGenerator/RandomNumberGenerator.sol';
import '../libraries/generatorConstructorParams/GeneratorConstructorParams.sol';
import '../libraries/queue/Queue.sol';
import '../plugins/payments/Payments.sol';
import '../libraries/finishedRace/FinishedRace.sol';


interface IHounds {
    function hound(uint256 theHoundId) external view returns(Hound.Default memory);
}


contract RacesContract is Ownable, Payments {
    
    event NewRace(Race.Default queue);
    uint256 public queueId = 1;
    uint256 public raceId = 1;
    TerrainsConstructorParams.Default terrains;
    HoundsConstructorParamsRaces.Default hounds;
    RandomNumberGenerator.Default randomness;
    GeneratorConstructorParams.Default generator;
    mapping(uint256 => Race.Default) public queues;

    /**
     * DIIMIIM:
     * We'll save the races structure as bytes and we'll decode them into their specific tuple using their specific generator contract
     */
    mapping(uint256 => FinishedRace.Default) public races;    
    
    constructor(
        TerrainsConstructorParams.Default memory theTerrains, 
        HoundsConstructorParamsRaces.Default memory theHounds,
        RandomNumberGenerator.Default memory theRandomness,
        GeneratorConstructorParams.Default memory theGenerator
    ) {
        terrains = theTerrains;
        hounds = theHounds;
        randomness = theRandomness;
        generator = theGenerator;
    }

    function setGlobalParameters(
        TerrainsConstructorParams.Default memory theTerrains, 
        HoundsConstructorParamsRaces.Default memory theHounds,
        RandomNumberGenerator.Default memory theRandomness,
        GeneratorConstructorParams.Default memory theGenerator
    ) external onlyOwner {
        terrains = theTerrains;
        hounds = theHounds;
        randomness = theRandomness;
        generator = theGenerator;
    }

    function createQueues(Queue.Default[] memory theQueues) external onlyOwner {
        for ( uint256 i = 0 ; i < theQueues.length ; ++i ) {
            queues[queueId].terrain = theQueues[i].terrain;
            queues[queueId].price = theQueues[i].price;
            queues[queueId].stamina = theQueues[i].stamina;
            queues[queueId].currency = theQueues[i].currency;
            queues[queueId].totalParticipants = theQueues[i].totalParticipants;
            ++queueId;
        }
    }

    function uploadRace(FinishedRace.Default memory race) external onlyOwner {
        races[raceId] = race;
        ++raceId;
    }

    function enqueue(uint256 theQueueId, uint256 theHoundId) external payable {
    
        // Queue verifications
        require(theQueueId < queueId, Errors.QUEUE_ID_NOT_VALID);
        
        // Hound verifications
        Hound.Default memory hound = IHounds(hounds.provider).hound(theHoundId);
        require(!hound.running, Errors.ONE_RUN_PER_HOUND);
        require(hound.identity.geneticSequence[0] > 0, Errors.HOUND_DOES_NOT_EXIST);
        require(hound.stamina.stamina >= queues[theQueueId].stamina, Errors.NOT_ENOUGH_STAMINA);

        // Adds the participant in the queue
        queues[theQueueId].participants.push(hound);
        
        Caller.call(
            hounds.provider,
            hounds.staminaSetter,
            abi.encode(theHoundId,queues[theQueueId].stamina)
        );

        // If last participant in the queue is calling this
        if ( queues[theQueueId].participants.length == queues[theQueueId].totalParticipants ) {

            if ( generator.callable ) {
                races[raceId].generatorContract = generator.provider;
                races[raceId].race = Caller.call(
                    generator.provider,
                    generator.generator,
                    abi.encode(queues[theQueueId]),
                    queues[theQueueId].price * queues[theQueueId].totalParticipants
                );
                ++raceId;
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
import '../wrappedHound/WrappedHound.sol';
import '../hound/Hound.sol';


library Race {
    
    /**
     * DIIMIIM:
     * Participants can pay with multiple currencies, ETH included
     */
    struct Default {

        // Terrain of the race
        uint256 terrain;

        // Participants
        // totalParticipants will be the array length here
        Hound.Default[] participants;

        // address(0) for ETH
        address currency;

        // ETH based
        uint256 price;

        // Required stamina
        uint32 stamina;

        // Total number of participants
        uint32 totalParticipants;

    }

    struct Finished {

        // Terrain of the race
        uint256 terrain;

        // Race seed
        bytes seed;

        // address(0) for ETH
        address currency;

        // ETH based
        uint256 price;

        // Race randomness
        uint256 randomness;

        // Required stamina
        uint32 stamina;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;
import '../errors/Errors.sol';


library Caller {

    function call(address provider, string memory method, bytes calldata parameters) public returns(bytes memory) {

        (bool success, bytes memory data) = provider.call(
            abi.encodeWithSignature(method, parameters)
        );
        
        require(success, Errors.CALL_FAILED);
        
        return data;
    }

    function call(address provider, string memory method, bytes calldata parameters, uint256 value) public returns(bytes memory) {

        (bool success, bytes memory data) = provider.call{ value: value }(
            abi.encodeWithSignature(method, parameters)
        );
        
        require(success, Errors.CALL_FAILED);
        
        return data;
    }

    function delegatecall(address provider, string memory method, bytes calldata parameters) public returns(bytes memory) {

        (bool success, bytes memory data) = provider.delegatecall(
            abi.encodeWithSignature(method, parameters)
        );
        
        require(success, Errors.DELEGATECALL_FAILED);
        
        return data;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library Terrain {
    
    struct Default {
        uint32 surface;
        uint32 distance;
        uint32 weather;
    }

    struct Wrapped {
        uint256 id;
        Default terrain;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;
import '../hound/Hound.sol';


library WrappedHound {
    
    struct Default {
        uint256 id;
        Hound.Default hound;
    }
    
}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;
import '../rarity/Rarity.sol';
import '../dashboard/Dashboard.sol';
import '../houndStatistics/HoundStatistics.sol';
import '../stamina/Stamina.sol';
import '../breeding/Breeding.sol';
import '../identity/Identity.sol';


library Hound {
    
    struct Default {
        Dashboard.Default dashboard;
        HoundStatistics.Default statistics;
        Stamina.Default stamina;
        Breeding.Default breeding;
        Identity.Default identity;
        string title;
        string token_url;
        uint256[] achievements;
        bool custom;
        bool running;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library TerrainsConstructorParams {
    
    struct Default {
        address provider;
        string getter;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library HoundsConstructorParamsRaces {
    
    struct Default {
        address provider;
        string getter;
        string staminaSetter;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library RandomNumberGenerator {
    
    struct Default {
        address provider;
        string generator;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library GeneratorConstructorParams {
    
    struct Default {
        address provider;
        string generator;
        bool callable;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library Queue {
    
    /**
     * DIIMIIM:
     * Params used to create a race
     */
    struct Default {

        // Terrain of the race
        uint256 terrain;

        // address(0) for ETH
        address currency;

        // Price of the race
        uint256 price;

        // Required stamina
        uint32 stamina;

        // Total number of participants
        uint32 totalParticipants;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import '../../openzeppelin/access/Ownable.sol';
import '../../openzeppelin/token/ERC20/IERC20.sol';
import '../../libraries/errors/Errors.sol';


contract Payments is Ownable {

    event CurrencyWithdrawal(address indexed currency, uint256 quantity);

	/*
	 * @DIIMIIM: This will be used to withdraw from contract funds
	 * ! Owner only
	 */
	function withdrawFunds(address currency, uint256 quantity) internal {
		if ( currency == address(0) ) {
		    require(payable(msg.sender).send(quantity), Errors.ETH_TRANSFER_FAILED);
		} else {
		    require(IERC20(currency).transferFrom(address(this),msg.sender,quantity),Errors.CURRENCY_TRANSFER_FAILED);
		}
		emit CurrencyWithdrawal(currency,quantity);
	}

	function transferCurrency(
        address from,
        address payable to,
        address currency,
        uint256 qty
	) public {
		if ( currency != address(0) )
			require(IERC20(currency).transferFrom(
				from,
				to, 
				qty
			), Errors.CURRENCY_TRANSFER_FAILED);
		else
			require(to.send(qty), Errors.ETH_TRANSFER_FAILED);
	}

}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library FinishedRace {
    
    struct Default {
        address generatorContract;
        bytes race;
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

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;

library Rarity {

    enum Default {
        UNCOMMON,
        COMMON,
        RARE,
        EPIC,
        LEGENDARY,
        MYTICAL
    }
    
}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;

library Dashboard {
    
    struct Default {
        address genesController;
        address rngProvider;
        address incubator;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library HoundStatistics {
    
    struct Default {
        uint64 totalRuns;
        uint64 firstPlace;
        uint64 secondPlace;
        uint64 thirdPlace;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;

library Stamina {
    
    struct Default {
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
    
    struct Default {
        uint256 breedCooldown;
        uint256 breedingFee;
        uint256 lastUpdate;
        bool availableToBreed;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library Identity {
    
    struct Default {
        address[] previousOwners;
        address owner;
        uint32[13] geneticSequence;
        uint256 generation;
        uint256 maleParent;
        uint256 femaleParent;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;

library Errors {

    string public constant NO_OWNER_ON_HOUND_CREATION = '1';
    string public constant NOT_ENOUGH_PAID_TO_MINT = '2';
    string public constant NOT_ENOUGH_PAID_TO_BREED = '3';
    string public constant CONSTRUCTOR_PARAMETER_MISSING = '4';
    string public constant SYNCED_ARRAY_LENGTH_INVALID = '5';
    
    /* @DIIMIIM: Used for almost every .call() code snippet */
    string public constant CALL_FAILED = '6';
    
    /* @DIIMIIM: Used for almost every .delegatecall() code snippet */
    string public constant DELEGATECALL_FAILED = '7';
    
    string public constant RNG_PROVIDER_NOT_ALLOWED = '8';
    string public constant INCOMPLETE_INCUBATOR_IMPLEMENTATION = '9';
    
    string public constant NOT_ENOUGH_LINK = '10';
    
    string public constant NOT_OWNER_OF_CONTRACT = '11';
    string public constant QUEUE_ID_NOT_VALID = '12';
    string public constant ONE_RUN_PER_HOUND = '13';
    string public constant ETH_TRANSFER_FAILED = '14';
    string public constant CURRENCY_TRANSFER_FAILED = '15';
    string public constant BIOLOGICAL_REQUIREMENTS_NOT_MET = '16';
    string public constant NOT_ENOUGH_PAID_TO_PLAY = '17';
    string public constant CLASSIC_RACE_PARTICIPANTS_RANGE_NOT_MATCHED = '18';
    string public constant RACE_HAS_FINISHED_ALREADY = '19';
    string public constant NOT_THE_OWNER_OF_HOUND = '20';
    string public constant HOUND_BREEDING_STILL_ON_COOLDOWN = '21';
    string public constant HOUND_NOT_AVAILABLE_TO_BREED = '22';
    string public constant CALLER_NOT_ALLOWED = '23';
    string public constant HOUND_DOES_NOT_EXIST = '23';
    string public constant NOT_ENOUGH_STAMINA = '24';
    string public constant NOT_VALID_GAME_MODE = '25';
    string public constant NOT_ENOUGH_PAID_TO_REFILL = '26';
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