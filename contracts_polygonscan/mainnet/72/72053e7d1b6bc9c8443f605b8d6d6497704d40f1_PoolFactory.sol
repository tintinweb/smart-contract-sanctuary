// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./PoolFactory.sol";

contract Pool is ReentrancyGuard {
	using Counters for Counters.Counter;

	enum RISK_LEVEL {
		LOW,
		MODERATE,
		HIGH
	} // 20%, 50%, 100%
	enum STATUS {
		ACTIVE,
		COMPLETED,
		CANCELLED
	}
	enum SELECTION {
		UNDEFINED,
		HOME,
		AWAY,
		DRAW
	}

	Counters.Counter public _betIds;
	Counters.Counter public _resultIds;
	Counters.Counter public _homeCounter;
	Counters.Counter public _awayCounter;
	Counters.Counter public _drawCounter;

	uint256 public MAX_BET_AMOUNT = 100 ether;
	uint256 public MIN_BET_AMOUNT = 0.01 ether;

	address payable public creator;
	string public name;
	string public url;
	address payable factoryAddress;
	uint256 public category;
	uint256 public group;
	bool public acceptDraw;
	RISK_LEVEL public riskLevel;
	uint256 public startTimestamp;
	uint256 public endTimestamp;
	SELECTION public result;
	STATUS public status;

	struct Bet {
		address payable owner;
		SELECTION selection;
		uint256 amount;
		STATUS status;
		uint256 timestamp;
	}

	struct Result {
		address payable validator;
		SELECTION res;
		uint256 homeScore;
		uint256 awayScore;
		STATUS status;
	}

	Counters.Counter homeValidators;
	Counters.Counter awayValidators;
	Counters.Counter drawValidators;
	SELECTION tempResult = SELECTION.UNDEFINED;
	mapping(address => SELECTION[]) public userBetSelections;
	mapping(uint256 => Bet) public bets;
	mapping(uint256 => Result) public results;
	address[] public validators;
	uint256[] myBets;

	uint256 private accumulatedAmount;
	uint256 private factoryAmount;
	uint256 private creatorAmount;
	uint256 private validatorsAmount;
	uint256 private gamblersAmount;
	uint256 private withdrawAmount;
	uint256 private winnersAmount;

	modifier isCreator() {
		require(msg.sender == creator, "caller_not_creator");
		_;
	}

	modifier isFactory() {
		require(msg.sender == factoryAddress, "caller_not_factory");
		_;
	}

	event BetPlaced(uint256 id, address user, uint256 amount);
	event PoolResultAdded(
		uint256 id,
		address user,
		SELECTION result,
		uint256 homeScore,
		uint256 awayScore
	);

	constructor(
		string memory _name,
		string memory _url,
		uint256 _categoryId,
		uint256 _groupId,
		bool _acceptDraw,
		RISK_LEVEL _riskLevel,
		uint256 _startTimestamp,
		uint256 _endTimestamp,
		address _creator,
		address _factoryAddress
	) {
		name = _name;
		url = _url;
		category = _categoryId;
		group = _groupId;
		acceptDraw = _acceptDraw;
		riskLevel = _riskLevel;
		startTimestamp = _startTimestamp;
		endTimestamp = _endTimestamp;
		creator = payable(_creator);
		factoryAddress = payable(_factoryAddress);
		status = STATUS.ACTIVE;
		result = SELECTION.UNDEFINED;
	}

	function hasMultiSelections() private view returns (bool) {
		uint256 hasHome = _homeCounter.current() > 0 ? 1 : 0;
		uint256 hasAway = _awayCounter.current() > 0 ? 1 : 0;
		uint256 hasDraw = _drawCounter.current() > 0 ? 1 : 0;

		return (hasHome + hasAway + hasDraw) >= 2;
	}

	function changeName(string memory _newValue) public isCreator {
		name = _newValue;
	}

	function changeUrl(string memory _newValue) public isCreator {
		url = _newValue;
	}

	function changeCreator(address _newCreator) public isCreator {
		creator = payable(_newCreator);
	}

	function getCreator() public view returns (address) {
		return creator;
	}

	function cancelPool() public isCreator {
		require(result == SELECTION.UNDEFINED, "pool_must_not_have_result");
		require(tempResult == SELECTION.UNDEFINED, "pool_must_not_have_temp_result");

		status = STATUS.CANCELLED;
		// PoolFactory(factoryAddress).updatePools(
		// 	address(this),
		// 	status,
		// 	category,
		// 	group
		// );
	}

	function forceCancelPool() external isFactory nonReentrant {
		require(result == SELECTION.UNDEFINED, "pool_must_not_have_result");

		status = STATUS.CANCELLED;
		tempResult = SELECTION.UNDEFINED;
		_resultIds.reset();
		for (uint256 i = 0; i < _resultIds.current(); i++) {
			delete results[i + 1];
		}
		homeValidators.reset();
		awayValidators.reset();
		drawValidators.reset();
		delete validators;
	}

	function placeBet(SELECTION _selection) public payable nonReentrant {
		require(msg.sender != creator, "sender_must_not_be_creator");
		require(status == STATUS.ACTIVE, "pool_must_bet_active");
		require(block.timestamp < startTimestamp, "pool_already_started");
		require(_selection != SELECTION.UNDEFINED, "invalid_selection");
		if (_selection == SELECTION.DRAW) {
			require(acceptDraw, "pool_not_accept_draw");
		}
		require(
			msg.value >= MIN_BET_AMOUNT && msg.value <= MAX_BET_AMOUNT,
			"invalid_bet_amount"
		);

		_betIds.increment();
		uint256 betId = _betIds.current();

		bets[betId] = Bet(
			payable(msg.sender),
			_selection,
			msg.value,
			STATUS.ACTIVE,
			block.timestamp
		);
		userBetSelections[msg.sender].push(_selection);

		if (_selection == SELECTION.HOME) {
			_homeCounter.increment();
		} else if (_selection == SELECTION.AWAY) {
			_awayCounter.increment();
		} else if (_selection == SELECTION.DRAW) {
			_drawCounter.increment();
		}

		emit BetPlaced(betId, msg.sender, msg.value);
	}

	function removeBet(uint256 betId) public nonReentrant {
		Bet memory currBet = bets[betId];

		require(currBet.owner == msg.sender, "bet_owner_only");
		require(
			block.timestamp < startTimestamp,
			"bet_must_not_have_started"
		);
		uint256 amountToTransfer = currBet.amount;
		bets[betId].status = STATUS.CANCELLED;

		address payable gambler = payable(address(msg.sender));
		gambler.transfer(amountToTransfer);
	}

	function getBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function listBets() public view returns (Bet[] memory) {
		uint256 totalItemCount = _betIds.current();
		uint256 currentIndex = 0;

		Bet[] memory items = new Bet[](totalItemCount);

		for (uint256 i = 0; i < totalItemCount; i++) {
			uint256 currentId = i + 1;
			Bet storage currentItem = bets[currentId];
			items[i] = currentItem;
			currentIndex += 1;
		}
		return items;
	}

	function listResults() public view returns (Result[] memory) {
		uint256 totalItemCount = _resultIds.current();
		uint256 currentIndex = 0;

		Result[] memory items = new Result[](totalItemCount);

		for (uint256 i = 0; i < totalItemCount; i++) {
			uint256 currentId = i + 1;
			Result storage currentItem = results[currentId];
			items[i] = currentItem;
			currentIndex += 1;
		}
		return items;
	}

	function setResult(
		SELECTION _result,
		uint256 _homeScore,
		uint256 _awayScore
	) public {
		require(status == STATUS.ACTIVE, "pool_status_must_be_active");
		require(result == SELECTION.UNDEFINED, "pool_must_not_have_result");
		require(
			block.timestamp > (endTimestamp + (15 * 60)),
			"pool_set_result_not_allowed"
		);
		require(hasMultiSelections(), "pool_must_have_multiple_selections");

		int256 findIdx = -1;
		for (uint256 i = 0; i < validators.length; i++) {
			if (validators[i] == msg.sender) {
				findIdx = int256(i);
			}
		}
		require(findIdx < 0, "address_already_add_result");

		if (tempResult == SELECTION.UNDEFINED || tempResult == _result) {
			tempResult = _result;
			_resultIds.increment();
			uint256 resultId = _resultIds.current();

			results[resultId] = Result(
				payable(msg.sender),
				_result,
				_homeScore,
				_awayScore,
				STATUS.ACTIVE
			);
			validators.push(payable(msg.sender));

			// buscar si el validador aposto en esta pool y cual fue su seleccion
			// incrementar el contador de validadores que apostaron en la pool
			SELECTION[] memory userSelections = userBetSelections[msg.sender];
			if (userSelections.length > 0) {
				if (userSelections[0] != SELECTION.UNDEFINED) {
					if (userSelections[0] == SELECTION.HOME) {
						homeValidators.increment();
					} else if (userSelections[0] == SELECTION.AWAY) {
						awayValidators.increment();
					} else {
						drawValidators.increment();
					}
				}
			}
			// si ya son 5 validaciones y hay al menos 1 vadacion de 2 SELECTION diferentes,
			// setear resultado en la bet
			uint256 validatorSum = homeValidators.current() +
				awayValidators.current() +
				drawValidators.current();

			if (
				validators.length >= 5 &&
				(validatorSum >= 2 &&
					(homeValidators.current() > 0 ||
						awayValidators.current() > 0 ||
						drawValidators.current() > 0))
			) {
				result = tempResult;
				status = STATUS.COMPLETED;
				// calcular montos a repartir segun el balance de la pool y el riskLevel
				// montos para validators, creator y gamblers
				accumulatedAmount = address(this).balance;
				uint256 communityAmount = 0;

				if (riskLevel == RISK_LEVEL.LOW) {
					communityAmount = (accumulatedAmount * 55) / 1000; // 5.5%
					withdrawAmount = (accumulatedAmount * 80) / 100; // 80%
				} else if (riskLevel == RISK_LEVEL.MODERATE) {
					communityAmount = (accumulatedAmount * 125) / 1000; // 12.5%
					withdrawAmount = (accumulatedAmount * 50) / 100; // 50%
				} else {
					communityAmount = (accumulatedAmount * 175) / 1000; // 17%
					withdrawAmount = (accumulatedAmount * 0) / 100; // 0%
				}
				factoryAmount = (accumulatedAmount * 25) / 1000; // 2.5%

				// community ammount
				creatorAmount = (communityAmount * 30) / 100; // 30%
				validatorsAmount = (communityAmount * 70) / 100; // 70%

				gamblersAmount =
					accumulatedAmount -
					communityAmount -
					factoryAmount -
					withdrawAmount;

				uint256 totalItemCount = _betIds.current();
				uint256 currentIndex = 0;
				for (uint256 i = 0; i < totalItemCount; i++) {
					uint256 currentId = i + 1;
					Bet storage currentItem = bets[currentId];
					if (
						currentItem.selection == result &&
						currentItem.status == STATUS.ACTIVE
					) {
						winnersAmount += currentItem.amount;
					}
					currentIndex += 1;
				}

				payable(factoryAddress).transfer(factoryAmount);
				factoryAmount = 0;
			}

			emit PoolResultAdded(
				resultId,
				msg.sender,
				_result,
				_homeScore,
				_awayScore
			);
		} else {
			// se ingreso un resultado que difiere, se limpia el estado y reinicia la validacion
			tempResult = SELECTION.UNDEFINED;
			_resultIds.reset();
			uint256 resultId = _resultIds.current();
			for (uint256 i = 0; i < _resultIds.current(); i++) {
				delete results[i + 1];
			}
			homeValidators.reset();
			awayValidators.reset();
			drawValidators.reset();
			delete validators;
			emit PoolResultAdded(
				resultId,
				msg.sender,
				_result,
				_homeScore,
				_awayScore
			);
		}
	}

	// forzar el resultado en caso de que despues de 24 horas de terminado
	// no se haya validado la pool, se dejan los validadores que hayan ingresado resultado y se libera la pool 
	function forceResult(SELECTION _result, uint256 _homeScore, uint256 _awayScore) external isFactory nonReentrant {
		require(status == STATUS.ACTIVE, "pool_status_must_be_active");
		require(result == SELECTION.UNDEFINED, "pool_must_not_have_result");
		require(
			block.timestamp > (endTimestamp + (60 * 60 * 24)),
			"pool_set_result_not_allowed"
		);

		if (tempResult == _result) {
			tempResult = _result;
			_resultIds.increment();
			uint256 resultId = _resultIds.current();

			results[resultId] = Result(
				payable(msg.sender),
				_result,
				_homeScore,
				_awayScore,
				STATUS.ACTIVE
			);
			validators.push(payable(msg.sender));

			// buscar si el validador aposto en esta pool y cual fue su seleccion
			// incrementar el contador de validadores que apostaron en la pool
			SELECTION[] memory userSelections = userBetSelections[msg.sender];
			if (userSelections.length > 0) {
				if (userSelections[0] != SELECTION.UNDEFINED) {
					if (userSelections[0] == SELECTION.HOME) {
						homeValidators.increment();
					} else if (userSelections[0] == SELECTION.AWAY) {
						awayValidators.increment();
					} else {
						drawValidators.increment();
					}
				}
			}

			// calcular montos a repartir segun el balance de la pool y el riskLevel
			// montos para validators, creator y gamblers
			accumulatedAmount = address(this).balance;
			uint256 communityAmount = 0;

			if (riskLevel == RISK_LEVEL.LOW) {
				communityAmount = (accumulatedAmount * 55) / 1000; // 5.5%
				withdrawAmount = (accumulatedAmount * 80) / 100; // 80%
			} else if (riskLevel == RISK_LEVEL.MODERATE) {
				communityAmount = (accumulatedAmount * 125) / 1000; // 12.5%
				withdrawAmount = (accumulatedAmount * 50) / 100; // 50%
			} else {
				communityAmount = (accumulatedAmount * 175) / 1000; // 17%
				withdrawAmount = (accumulatedAmount * 0) / 100; // 0%
			}
			factoryAmount = (accumulatedAmount * 25) / 1000; // 2.5%

			// community ammount
			creatorAmount = (communityAmount * 30) / 100; // 30%
			validatorsAmount = (communityAmount * 70) / 100; // 70%

			gamblersAmount =
				accumulatedAmount -
				communityAmount -
				factoryAmount -
				withdrawAmount;

			uint256 totalItemCount = _betIds.current();
			uint256 currentIndex = 0;
			for (uint256 i = 0; i < totalItemCount; i++) {
				uint256 currentId = i + 1;
				Bet storage currentItem = bets[currentId];
				if (
					currentItem.selection == result &&
					currentItem.status == STATUS.ACTIVE
				) {
					winnersAmount += currentItem.amount;
				}
				currentIndex += 1;
			}

			payable(factoryAddress).transfer(factoryAmount);
			factoryAmount = 0;
		

			emit PoolResultAdded(
				resultId,
				msg.sender,
				_result,
				_homeScore,
				_awayScore
			);
		} else {
			// se ingreso un resultado que difiere, se limpia el estado y reinicia la validacion
			tempResult = SELECTION.UNDEFINED;
			_resultIds.reset();
			for (uint256 i = 0; i < _resultIds.current(); i++) {
				delete results[i + 1];
			}
			homeValidators.reset();
			awayValidators.reset();
			drawValidators.reset();
			delete validators;

			_resultIds.increment();
			uint256 resultId = _resultIds.current();
			results[resultId] = Result(
				payable(msg.sender),
				_result,
				_homeScore,
				_awayScore,
				STATUS.ACTIVE
			);
			validators.push(payable(msg.sender));


			emit PoolResultAdded(
				resultId,
				msg.sender,
				_result,
				_homeScore,
				_awayScore
			);
		}

		result = _result;
		status = STATUS.COMPLETED;
	}

	function claimPayment() public nonReentrant returns(uint256) {
		uint256 amountToTransfer = 0;

		if (hasMultiSelections()) {
			require(result != SELECTION.UNDEFINED, "pool_must_have_result");

			// si es owner (30%)
			if (msg.sender == creator) {
				require(status != STATUS.CANCELLED, "pool_must_not_be_cancelled");
				amountToTransfer += creatorAmount;
				creatorAmount = 0;
			}

			int256 findIdx = -1;
			for (uint256 i = 0; i < validators.length; i++) {
				if (validators[i] == msg.sender) {
					findIdx = int256(i);
				}
			}

			// si es validador (70%)
			if (findIdx >= 0 && status != STATUS.CANCELLED) {
				Result memory findedResult = results[uint256(findIdx + 1)];
				if (findedResult.status == STATUS.ACTIVE) {
					results[uint256(findIdx + 1)].status = STATUS.COMPLETED;
					amountToTransfer += (validatorsAmount / validators.length);
				}
			}
		}

		for (uint256 i = 0; i < _betIds.current(); i++) {
			uint256 currentId = i + 1;
			Bet memory currBet = bets[currentId];
			if (
				currBet.status == STATUS.ACTIVE && currBet.owner == msg.sender
			) {
				myBets.push(currentId);
			}
		}

		for (uint256 i = 0; i < myBets.length; i++) {
			uint256 myBetId = myBets[i];

			if (
				bets[myBetId].status == STATUS.ACTIVE &&
				bets[myBetId].owner == msg.sender
			) {
				bets[myBetId].status = STATUS.COMPLETED;
				// si hubo apuestas de diferentes selections o si se completo
				// checar si esta activa o cancelada la pool
				// si hubo apuestas de diferentes selections o si se completo
				if (status == STATUS.CANCELLED || !hasMultiSelections()) {
					amountToTransfer += bets[myBetId].amount;
				} else {
					if (riskLevel == RISK_LEVEL.LOW) {
						amountToTransfer += (bets[myBetId].amount * 80) / 100; // 80%
					} else if (riskLevel == RISK_LEVEL.MODERATE) {
						amountToTransfer += (bets[myBetId].amount * 50) / 100; // 50%
					} else {
						amountToTransfer += (bets[myBetId].amount * 0) / 100; // 0%
					}

					// checar si gano y que porcentaje de la bolsa le corresponde
					if (bets[myBetId].selection == result) {
						amountToTransfer += ((bets[myBetId].amount /
							winnersAmount) * gamblersAmount);
					}
				}
			}
		}
		delete myBets;

		if ((address(this).balance - amountToTransfer) <= 0) {
			status = STATUS.COMPLETED;
			PoolFactory(factoryAddress).updatePools(
				address(this),
				status,
				category,
				group
			);
		}

		if (amountToTransfer > 0) {
			address payable gambler = payable(address(msg.sender));
			gambler.transfer(amountToTransfer);
		}
		return amountToTransfer;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Pool.sol";

contract PoolFactory is ReentrancyGuard {
	using Counters for Counters.Counter;

	enum CATEGORY_STATUS {
		ACTIVE,
		INACTIVE
	}

	struct Category {
		uint256 id;
		string name;
		uint256 poolsCount;
		CATEGORY_STATUS status;
	}
	struct Group {
		uint256 id;
		uint256 category;
		string name;
		string country;
		uint256 poolsCount;
		CATEGORY_STATUS status;
	}
	struct PoolInput {
		string name;
		string url;
		uint256 category;
		uint256 group;
		bool acceptDraw;
		Pool.RISK_LEVEL riskLevel;
		uint256 startTimestamp;
		uint256 endTimestamp;
	}

	Counters.Counter public _categoryIds;
	Counters.Counter public _groupIds;
	Counters.Counter public _poolIds;

	address payable owner;

	mapping(uint256 => Category) public categories;
	mapping(uint256 => Group) public groups;
	address[] public deployedPools;
	address[] public activePools;

	modifier isOwner() {
		require(msg.sender == owner, "caller_not_owner");
		_;
	}

	// events
	event PoolCreated(address _address, string name);
	event PoolUpdated(address _address, Pool.STATUS status);

	constructor() {
		owner = payable(msg.sender);
	}

	function listCategories() public view returns (Category[] memory) {
		uint256 totalItemCount = _categoryIds.current();
		uint256 itemCount = 0;
		uint256 currentIndex = 0;

		for (uint256 i = 0; i < totalItemCount; i++) {
			if (categories[i + 1].status == CATEGORY_STATUS.ACTIVE) {
				itemCount += 1;
			}
		}

		Category[] memory items = new Category[](itemCount);

		for (uint256 i = 0; i < totalItemCount; i++) {
			if (categories[i + 1].status == CATEGORY_STATUS.ACTIVE) {
				uint256 currentId = i + 1;
				Category storage currentItem = categories[currentId];
				items[i] = currentItem;
				currentIndex += 1;
			}
		}
		return items;
	}

	function listGroups() public view returns (Group[] memory) {
		uint256 totalItemCount = _groupIds.current();
		uint256 itemCount = 0;
		uint256 currentIndex = 0;

		for (uint256 i = 0; i < totalItemCount; i++) {
			if (groups[i + 1].status == CATEGORY_STATUS.ACTIVE) {
				itemCount += 1;
			}
		}

		Group[] memory items = new Group[](itemCount);

		for (uint256 i = 0; i < totalItemCount; i++) {
			if (groups[i + 1].status == CATEGORY_STATUS.ACTIVE) {
				uint256 currentId = i + 1;
				Group storage currentItem = groups[currentId];
				items[i] = currentItem;
				currentIndex += 1;
			}
		}
		return items;
	}

	function createPool(
		PoolInput memory input,
		string memory newCategoryName,
		string memory newGroupName,
		string memory newGroupCountry
	) public {
		uint256 categoryId;
		uint256 groupId;

		if (input.category > 0) {
			categoryId = input.category;
			categories[categoryId].poolsCount++;
		} else {
			_categoryIds.increment();
			categoryId = _categoryIds.current();

			categories[categoryId] = Category(
				categoryId,
				newCategoryName,
				1,
				CATEGORY_STATUS.ACTIVE
			);
		}

		if (input.group > 0) {
			groupId = input.group;
			groups[groupId].poolsCount++;
		} else {
			_groupIds.increment();
			groupId = _groupIds.current();

			groups[groupId] = Group(
				groupId,
				categoryId,
				newGroupName,
				newGroupCountry,
				1,
				CATEGORY_STATUS.ACTIVE
			);
		}

		_poolIds.increment();
		address newPool = address(
			new Pool(
				input.name,
				input.url,
				categoryId,
				groupId,
				input.acceptDraw,
				input.riskLevel,
				input.startTimestamp,
				input.endTimestamp,
				msg.sender,
				address(this)
			)
		);
		deployedPools.push(newPool);
		activePools.push(newPool);
		emit PoolCreated(newPool, input.name);
	}

	function updatePools(
		address _address,
		Pool.STATUS _status,
		uint256 _categoryId,
		uint256 _groupId
	) external {
		require(_address == msg.sender, "must_call_from_pool");

		if (_status != Pool.STATUS.ACTIVE) {
			int256 findIdx = -1;
			for (uint256 i = 0; i < activePools.length; i++) {
				if (activePools[i] == _address) {
					findIdx = int256(i);
				}
			}

			if (findIdx >= 0 && findIdx < int256(activePools.length)) {
				categories[_categoryId].poolsCount--;
				groups[_groupId].poolsCount--;

				for (
					int256 i = findIdx;
					i < int256(activePools.length) - 1;
					i++
				) {
					activePools[uint256(i)] = activePools[uint256(i + 1)];
				}
				activePools.pop();
			}
		}

		emit PoolUpdated(_address, _status);
	}

	function cancelPool(address _address) public isOwner {
		Pool(_address).forceCancelPool();
	}

	function setPoolResult(address _address, Pool.SELECTION _result, uint256 _homeScore, uint256 _awayScore) public isOwner {
		Pool(_address).forceResult(_result, _homeScore, _awayScore);
	}

	function getDeployedPools() public view returns (address[] memory) {
		return deployedPools;
	}

	function getActivePools() public view returns (address[] memory) {
		return activePools;
	}

	function getBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function withdraw() public isOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(address(msg.sender)).transfer(balance);
    }

	fallback() external payable {}

	receive() external payable {}
}

