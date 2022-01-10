// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '../../arenas/Arena.sol';
import '../../hounds/Hound.sol';
import '../../payments/Payments.sol';
import '../../hounds/IData.sol';
import '../../arenas/IData.sol';
import '../../randomness/vanilla/IData.sol';
import '../../utils/FilterForWinners.sol';
import '../races/Race.sol';
import '../Constructor.sol';


/**
 * DIIMIIM:
 * This should not have any storage, except the constructor ones
 */
contract RaceGeneratorMethods is Payments {

    event NewRace(Race.Struct queue, Race.Finished race);
    Constructor.Struct public control;
    string error = "Failed to delegatecall";

    function setGlobalParameters(
        Constructor.Struct memory input
    ) external {
        control = input;
    }

    // Compute the race hounds stats
    function computeHoundsStats(uint256[] memory participants, Arena.Struct memory terrain) internal view returns(uint256[] memory) {

        uint256[] memory stats = new uint256[](participants.length);

        Hound.Struct memory hound;

        // For each hound
        for ( uint256 i = 0 ; i < participants.length ; ++i ) {

            // Hound verifications
            hound = IHoundsData(control.hounds).hound(participants[i]);

            // Compute the main stats
            stats[i] = uint256((hound.identity.geneticSequence[30] + hound.identity.geneticSequence[31] + hound.identity.geneticSequence[32] + hound.identity.geneticSequence[33]) * 99);
            uint256 tmp = stats[i];

            // Compute the environmental stats
            if ( hound.identity.geneticSequence[9] == terrain.surface )
                stats[i] += tmp / 20;
            if ( hound.identity.geneticSequence[10] == terrain.distance )
                stats[i] += tmp / 20;
            if ( hound.identity.geneticSequence[11] == terrain.weather )
                stats[i] += tmp / 20;

            // Compute the stamina stats
            if ( hound.stamina.staminaCap / 2 > hound.stamina.stamina )
                stats[i] = stats[i] * 90 / 100;

        }

        return stats;

    }

    // Simulate the classic race seed
    function simulateClassicRace(uint256[] memory participants, uint256 terrain, uint256 theRandomness) public view returns(bytes memory output) {
        
        Arena.Struct memory theTerrain = ITerrains(control.terrains).getTerrain(terrain);

        // Compute the hounds score power
        
        uint256[] memory houndsPower = computeHoundsStats(participants, theTerrain);
        
        // Variation of their power will be up to 15%, using randomness
        uint256 variation = uint256(keccak256(abi.encode(theRandomness, block.difficulty))) % 15;

        // Updating their score power
        for ( uint256 j = 0 ; j < houndsPower.length ; ++j ) 
            houndsPower[j] = houndsPower[j] + ( ( houndsPower[j] * variation ) / 100 );
        
        // Encoding it into bytes
        output =  abi.encode(
            quickSort(
                houndsPower,
                0,
                houndsPower.length-1
            )
        );

    }

    function generate(Race.Struct memory queue) external payable returns(Race.Finished memory race) {

        require(control.allowed == msg.sender, "23");
        
        require(queue.participants.length == queue.totalParticipants, "19");

        // Queue verifications
        require(queue.entryFee <= msg.value, "17");

        // Generates the randomness
        uint256 theRandomness = IRandomnessVanillaData(control.randomness).getRandomNumber(abi.encode(block.timestamp));
        bytes memory seed = simulateClassicRace(queue.participants,queue.arena,theRandomness);

        // Decode the race seed into the participants array
        uint256[] memory participants = abi.decode(seed,(uint256[]));

        // Gets the first indexes of the best participants
        uint256[3] memory winners = FilterForWinners.filterForWinners(participants);

        sendRewards(
            [
                IHoundsData(control.hounds).ownerOf(winners[0]),
                IHoundsData(control.hounds).ownerOf(winners[1]),
                IHoundsData(control.hounds).ownerOf(winners[2])
            ],
            queue.currency,
            [
                queue.entryFee * 5, 
                queue.entryFee * 3, 
                queue.entryFee * 2
            ]
        );
    
        race = Race.Finished(
            queue.currency,
            participants,
            queue.arena,
            queue.entryFee,
            theRandomness
        );

        // Emit the race event
        emit NewRace(queue,race);

    }

    function sendRewards(address[3] memory winners, address currency, uint256[3] memory amounts) public payable {
        for ( uint i = 0 ; i < 3 ; ++i ) {
            transferTokens(
                address(this),
                payable(winners[i]),
                currency,
                amounts[i]
            );
        }
    }

    function quickSort(uint256[] memory arr, uint256 left, uint256 right) internal pure returns(uint[] memory){
        uint256 i = left;
        uint256 j = right;
        if (i == j) return arr;
        uint256 pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
        return arr;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library Arena {
    
    struct Struct {
        uint32 surface;
        uint32 distance;
        uint32 weather;
    }

    struct Wrapped {
        uint256 id;
        Struct arena;
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

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;

import './Arena.sol';


interface ITerrains {
    function createTerrain(Arena.Struct memory terrain) external;
    function editTerrain(uint256 _id, Arena.Struct memory terrain) external;
    function getTerrain(uint256 _id) external view returns(Arena.Struct memory);
    function ownerOf(uint256 tokenId) external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


interface IRandomnessVanillaData {
    function getRandomNumber(bytes memory input) external view returns(uint256);
    function setGlobalParameters(address methods) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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