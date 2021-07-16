//SourceUnit: Collector.sol

pragma solidity 0.6.0;

import "./Ownable.sol";
import "./Commission.sol";

contract Collector is Ownable, Commission {
	address private _collector;
	uint96 private _;
	uint private _fees;

	event Collected(uint amount);

	function collect() public onlyOwner {
		require(_fees > 0, "Nothing to collect");
		payable(_collector).transfer(_fees);
		emit Collected(_fees);
		_fees = 0;
	}

	function collected() public view returns (uint) { return _fees; }

	function setCollector(address newCollector) public onlyOwner {
		require(newCollector != address(0), "New collector is the zero address");
		_collector = newCollector;
	}

	function collector() public view returns (address) { return _collector; }	

	function _takeComission(uint256 amount) internal returns (uint256){
		uint fee = (amount*commission())/10000;
		_fees += fee;
		return fee;
	}
}

//SourceUnit: Commission.sol

pragma solidity 0.6.0;

import "./Ownable.sol";

contract Commission is Ownable {
	uint private _commission;

	event CommissionChanged(uint from, uint to);

	function setCommission(uint percentsMultipliedBy100) public onlyOwner {
		uint oldCommission = _commission;
		_commission = percentsMultipliedBy100;
		emit CommissionChanged(oldCommission, _commission);
	}

	function commission() public view returns(uint) {
		return _commission;
	}	

}

//SourceUnit: Consolation.sol

pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;
import "./Ownable.sol";
import "./ITRC20.sol";
import "./Rewards.sol";

contract Consolation is Ownable, RewardsQueue {
	address private _consolationTokenAddress;
	address private _consolationTokenHolder;  
	uint192 private _rate; // amount of token for 1,000,000 trx

	event ConsolationTokenAddressChanged(address from, address to);
	event ConsolationTokenHolderChanged(address from, address to);
	event ConsolationRateChanged(uint from, uint to);

	function setConsolationTokenAddress(address token) public onlyOwner {
		address old = _consolationTokenAddress;
		_consolationTokenAddress = token;
		emit ConsolationTokenAddressChanged(old, _consolationTokenAddress);
	}

	function setConsolationTokenHolder(address holder) public onlyOwner {
		address old = _consolationTokenHolder;
		_consolationTokenHolder = holder;
		emit ConsolationTokenHolderChanged(old, _consolationTokenHolder);
	}

	function setConsolationRate(uint rate) public onlyOwner {
		uint old = _rate;
		_rate = uint192(rate);
		emit ConsolationRateChanged(old, _rate);
	}

	function _sendTokens(address recipient, uint amount) internal {
		require(_consolationTokenAddress != address(0), 'Token contract address not set');
		require(_consolationTokenHolder != address(0), 'Token holder address not set');
		ITRC20 token = ITRC20(_consolationTokenAddress);
		token.transferFrom(_consolationTokenHolder, recipient, amount);
	}

	event Withdrawn(uint number, address player, uint prize, uint consolation);

	function _issueConsolationPrize(uint number, address player) internal {
		Reward memory r = _reward(uint128(number));
		require(player == _playerAddressById(r.playerId), "You can not withdraw the reward of another player");
		uint128 firstNumber = _findFirstRewardNumberByPlayerId(r.playerId);
		if(firstNumber > 0) {			
			if(firstNumber == number) {
				uint trxAmount = balance(player);				
				payable(player).transfer(trxAmount);
				_emptyBalanceById(r.playerId);
				require(uint256(r.amount) > trxAmount, 'Something wrong');
				uint tokens = uint256(r.amount) - trxAmount;
				_sendTokens(player, tokens);
				_deleteReward(uint128(number));
				emit Withdrawn(number, player, trxAmount, tokens);
			} else {				
				uint tokens = uint256(r.amount);
				_sendTokens(player, tokens);
				_deleteReward(uint128(number));
				emit Withdrawn(number, player, 0, tokens);
			}
		}
	}
}

//SourceUnit: Context.sol

// SPDX-License-Identifier: MIT

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


//SourceUnit: EntryBounds.sol

pragma solidity 0.6.0;

import "./Ownable.sol";

contract EntryBounds is Ownable {
	uint private _lower;
	uint private _upper;	

	event lowerEntryBoundUpdated(uint from, uint to);
	event upperEntryBoundUpdated(uint from, uint to);

	function setEntryBounds(uint newLowerBound, uint newUpperBound) public onlyOwner {
		require(newUpperBound > newLowerBound, "Upper bound should be greater than lower bound");
		uint old = _upper;
		_upper = newUpperBound;
		emit upperEntryBoundUpdated(old, _upper);
		old = _lower;
		_lower = newLowerBound;
		emit lowerEntryBoundUpdated(old, _lower);		
	}

	function setUpperEntryBound(uint newUpperBound) public onlyOwner {
		require(newUpperBound > _lower, "Upper bound should be greater than lower bound");
		uint old = _upper;
		_upper = newUpperBound;
		emit upperEntryBoundUpdated(old, _upper);
	}

	function setLowerEntryBound(uint newLowerBound) public onlyOwner {
		require(newLowerBound < _upper, "Lower bound should be less than upper bound");
		uint old = _upper;
		_lower = newLowerBound;
		emit lowerEntryBoundUpdated(old, _lower);
	}

  function _lowerBound() internal view returns(uint) {return _lower;}
  function _upperBound() internal view returns(uint) {return _upper;}

	function entryBounds() public view returns(uint, uint) {
		return (_lower, _upper);
	}

}

//SourceUnit: Gamber.sol

pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;

import "./Rewards.sol";
import "./PlayerBase.sol";
import "./Collector.sol";
import "./EntryBounds.sol";
import "./Consolation.sol";
import "./InterestRate.sol";
import "./Splitting.sol";

contract Gamber is RewardsQueue, Collector, EntryBounds, Consolation, InterestRate, Splitting {	
		
	constructor() public {
		setInterestRate(20*100); // 20%
		setCommission(10*100); // 10%
		setEntryBounds(100*10**6, 5000*10**6); // 500 trx - 5000 trx
		setCollector(msg.sender);
		setConsolationTokenHolder(msg.sender);
		setConsolationRate(10**6); // 1:1
		uint[] memory split = new uint[](5);
		split[0] = 3000;
		split[1] = 1500;
		split[2] =  500;
		split[3] =  500;
		split[4] =  500;
		setSplitting(split);
	}

	event Played(uint number, address player, uint amount);	

	function _play(uint256 amount) internal {		
		address currentPlayer = _msgSender();

		require(playerExists(currentPlayer), 'Sender is not a player');
		require(amount >= _lowerBound(), 'Amount is less than the lower bound');
		require(amount <= _upperBound(), 'Amount is greater than the upper bound');

		uint[] memory splitted = _splitted(amount);

		// address nextPlayer = _parent(currentPlayer);

		uint[] memory parentsInQueue = _parentsInQueue(currentPlayer);
		
		uint i;
		for (i = splitted.length ; i-- > 1; ) {
			if(i > parentsInQueue.length) {
				splitted[0] += splitted[i];
				splitted[i] = 0;
			} else {
				if(parentsInQueue[i-1] == 0) {
					splitted[0] += splitted[i];
					splitted[i] = 0;
				} else {
					uint remainder = _processPlayerQueue(_playerAddressById(parentsInQueue[i-1]), splitted[i]);
					if(remainder > 0) splitted[0] += remainder;
				}
			}
		}		

		splitted[0] -= _takeComission(amount);

		_processMainQueue(splitted[0]);		

		_addReward(currentPlayer, _calcReward(amount));
		emit Played(_lastNumber(), currentPlayer, amount);
	}

	function withdraw(uint number) external {
		Reward memory r = _reward(uint128(number));
		require(r.renounceAt < block.timestamp, 'Too soon');
		address currentPlayer = _msgSender();
		_issueConsolationPrize(number, currentPlayer);		
	}

	function play(address parent) external payable {
		_addPlayer(parent, _msgSender());
		_play(msg.value);
	}

	function play() external payable {
		_play(msg.value);
	}

}


//SourceUnit: ITRC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the TRC20 standard as defined in the EIP.
 */
interface ITRC20 {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


//SourceUnit: InterestRate.sol

pragma solidity 0.6.0;

import "./Ownable.sol";

contract InterestRate is Ownable {
	uint private _interestRate;

	event InterestRateChanged(uint from, uint to);

	function setInterestRate(uint percentsMultipliedBy100) public onlyOwner {
		uint old = _interestRate;
		_interestRate = percentsMultipliedBy100;
		emit InterestRateChanged(old, _interestRate);
	}

	function interestRate() public view returns(uint) {
		return _interestRate;
	}

  function _calcReward(uint256 amount) internal view returns (uint256){
		amount += (amount*_interestRate)/10000;		
		return amount;
	}
}

//SourceUnit: Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Context.sol";
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
    uint96 private _;

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


//SourceUnit: PlayerBase.sol

pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;

struct Player {
	address player;
	uint96 balance;
}

contract PlayerBase {
	mapping(address => address) private _childToParent;
	mapping(address => uint256) private _addressToId;
	Player[] _players;

	function _parent(address player) internal view returns (address) {
		return _childToParent[player];
	}	

	function parent(address player) public view returns (address) {
		return _parent(player);
	}

	function _addPlayer(address parent_, address child) internal {
		require(playerExists(parent_), "Player does not exist");
		if(playerExists(child)) return;
		_childToParent[child] = parent_;
		_players.push(Player(child, 0));
		_addressToId[child] = _players.length;
	}

	function playerExists(address player) public view returns(bool) {
		return _addressToId[player] != 0;
	}

	function players() public view returns(address[] memory) {
		address[] memory results = new address[](_players.length);
		for (uint256 i = 0; i < _players.length; i++)
			results[i] = _players[i].player;
		return results;
	}

	function balance(address player) public view returns(uint96) {
		return _players[_addressToId[player] - 1].balance;
	}

	function _increaseBalanceById(uint playerId, uint amount) internal {
		_players[playerId-1].balance += uint96(amount);
	}

	function _emptyBalanceById(uint playerId) internal {
		_players[playerId-1].balance = 0;
	}
  
  function _playerIdByAddress(address player) internal view returns (uint256) {
    return _addressToId[player];
  }

  function _playerAddressById(uint id) internal view returns (address) {
    return _players[id-1].player;
  }

  function _playerBalanceById(uint id) internal view returns (uint) {
    return _players[id-1].balance;
  }

	function _distance(address parent_, address child) internal view returns(uint) {
		uint distance = 1;
		if(parent_ == child) return 0;
		while(_childToParent[child] != address(0)) {
			if(_childToParent[child] == parent_)
				return distance;
			else {
				distance++;
				child = _childToParent[child];
			}
		}
		return 0;
	}

	function followers(address player) public view returns(address[][] memory) {
		uint levels = 0;
		uint d = 0;
		for (uint256 i = 0; i < _players.length; i++) {
			d = _distance(player, _players[i].player);
			if(d > levels) levels = d;
		}
		address[][] memory results = new address[][](levels);
		address[] memory buffer = new address[](_players.length);

		for (uint256 level = 1; level <= levels; level++) {
			uint count = 0;
			for (uint256 i = 0; i < _players.length; i++)
				if(_distance(player, _players[i].player) == level)
					buffer[count++] = _players[i].player;
			results[level-1] = new address[](count);
			for (uint256 i = 0; i < count; i++)
				results[level-1][i] = buffer[i];
		}
		
		return results;
	}

	constructor() internal {
		_childToParent[0x6e51535175fe54cFBC8609B49f4A44E3174abB92] = 0x40c1FEd422126EA27400C9Ae894FCd016f76D8E4; //TL2WkkbdKTsfdPbn3gjuE4x1SSBQ6XZMwo => TFsceNgCEvz6UWexuv3W145TvHKVjZ7fsn
		_childToParent[0xA6Bd32CBe694cDDe1ae31135366852F7449dD688] = 0x40c1FEd422126EA27400C9Ae894FCd016f76D8E4; //TRAqpe4X2fxtrgV6cUzDQQ9FZW8148whcB => TFsceNgCEvz6UWexuv3W145TvHKVjZ7fsn
		_childToParent[0x5F708E04c2B172eC6512144CF5CF8C0Eb3bB1B7A] = 0x40c1FEd422126EA27400C9Ae894FCd016f76D8E4; //TJfr2izEGa7foFZw9WWRbWXuYNWqNCFMTt => TFsceNgCEvz6UWexuv3W145TvHKVjZ7fsn
		_childToParent[0x716b5b8B12169dFe22210f7B49d4350AE8291C3C] = 0x40c1FEd422126EA27400C9Ae894FCd016f76D8E4; //TLJuy58Wx88nmd2AMmcksPFYR8GJNmdPBk => TFsceNgCEvz6UWexuv3W145TvHKVjZ7fsn
		_childToParent[0xb753Aa288F5076E7935804BFf1C3CaedC4D24f17] = 0x6e51535175fe54cFBC8609B49f4A44E3174abB92; //TSgYtHetGy9HQuwsgkenidRd7gqPGjBY1W => TL2WkkbdKTsfdPbn3gjuE4x1SSBQ6XZMwo
		_childToParent[0xD2eF80f95F15305774AcfAC68415290719E057c4] = 0x6e51535175fe54cFBC8609B49f4A44E3174abB92; //TVCXpMoczF2S6beRVpPw6u8JA6MM6CvsDr => TL2WkkbdKTsfdPbn3gjuE4x1SSBQ6XZMwo
		_childToParent[0x0d6bFE30C32CC5463D1f2F980ebB0cc1E10F0f08] = 0x6e51535175fe54cFBC8609B49f4A44E3174abB92; //TBCBA2t26KN9pGnruEtwuHvqS9dW6FFhpd => TL2WkkbdKTsfdPbn3gjuE4x1SSBQ6XZMwo
		_childToParent[0xEb61D050822Af2Ec1Be1F4157c74fd7B73e69aC6] = 0x6e51535175fe54cFBC8609B49f4A44E3174abB92; //TXRnyMcLFsh8DMHpmjsdE6yKSAX8fvUPXL => TL2WkkbdKTsfdPbn3gjuE4x1SSBQ6XZMwo
		_childToParent[0x28799942C53aadDAFc33D127B40ce97EFdADC4E1] = 0x6e51535175fe54cFBC8609B49f4A44E3174abB92; //TDfDhZDaNB4mD7Gi7rJXpronqrs4BuLitf => TL2WkkbdKTsfdPbn3gjuE4x1SSBQ6XZMwo
		_childToParent[0x4C8eCe0B58Ec878DbDa21Aa58c93f476DD31cEB1] = 0x6e51535175fe54cFBC8609B49f4A44E3174abB92; //TGx1RtnvSwWFFJTCUBv4QtVhonDbiJuSo5 => TL2WkkbdKTsfdPbn3gjuE4x1SSBQ6XZMwo
		_childToParent[0x9464191A13A7e43dC7Ee1deA6c6bDa8eEE2B167b] = 0x6e51535175fe54cFBC8609B49f4A44E3174abB92; //TPVpvPG9zKPA1TGWKLdY2i9SXN8F7yVZXu => TL2WkkbdKTsfdPbn3gjuE4x1SSBQ6XZMwo
		_childToParent[0xe3A1FBd153FFb6Ba4371763C1Bb6C7bc9B2DBe63] = 0x6e51535175fe54cFBC8609B49f4A44E3174abB92; //TWipSRhhmaA8TUnGHAgbkuMPiZTCUfb2AN => TL2WkkbdKTsfdPbn3gjuE4x1SSBQ6XZMwo
		_childToParent[0x54346bAbfcfd3295B93A84dF5b979A87f75Bb846] = 0x28799942C53aadDAFc33D127B40ce97EFdADC4E1; //THeSZRHAY34b9KYwxcmhVxZwh9L7riaWan => TDfDhZDaNB4mD7Gi7rJXpronqrs4BuLitf
		_childToParent[0xE7A87Af6b84CB5e3815393E57661b16De4041275] = 0x28799942C53aadDAFc33D127B40ce97EFdADC4E1; //TX66vbBcvTxwxQPALd3vXLUxw8DZNQvwhD => TDfDhZDaNB4mD7Gi7rJXpronqrs4BuLitf
		_childToParent[0xD53140D111b57F4C676Cc728E00Bb10F63dfC950] = 0x28799942C53aadDAFc33D127B40ce97EFdADC4E1; //TVQTw6Cn6HgQ3d5RHiH4cioSsHH8oQgruz => TDfDhZDaNB4mD7Gi7rJXpronqrs4BuLitf
		_childToParent[0x5d2E9C5b0fC970d94b41998CA99aEf7922b841bd] = 0x28799942C53aadDAFc33D127B40ce97EFdADC4E1; //TJTugUKoA4QnNUZx1VKTETo54hvgjEJa5t => TDfDhZDaNB4mD7Gi7rJXpronqrs4BuLitf
		_childToParent[0xa093C0936F100635D7aE0C15f8Cb30a66F9384Da] = 0x28799942C53aadDAFc33D127B40ce97EFdADC4E1; //TQcG7kvfUcurNnX7Ug3gP6QnvdHALX5uPG => TDfDhZDaNB4mD7Gi7rJXpronqrs4BuLitf
		_childToParent[0x8385a9DA4Eef33CC94bA00aF84F50113c9a29fB9] = 0x28799942C53aadDAFc33D127B40ce97EFdADC4E1; //TMxdeHpArwkhaw9dNj7FaQ2RphAjaLWXDc => TDfDhZDaNB4mD7Gi7rJXpronqrs4BuLitf
		_childToParent[0x51685a90eDc84e86515B44093f64b9a28A8C57d0] = 0xD53140D111b57F4C676Cc728E00Bb10F63dfC950; //THPekDymc87NtjttjPPHGFtXozFiLob9WD => TVQTw6Cn6HgQ3d5RHiH4cioSsHH8oQgruz

		_players.push(Player(0x40c1FEd422126EA27400C9Ae894FCd016f76D8E4, 0));
		_addressToId[0x40c1FEd422126EA27400C9Ae894FCd016f76D8E4] = 1;
		_players.push(Player(0x6e51535175fe54cFBC8609B49f4A44E3174abB92, 0));
		_addressToId[0x6e51535175fe54cFBC8609B49f4A44E3174abB92] = 2;
		_players.push(Player(0xA6Bd32CBe694cDDe1ae31135366852F7449dD688, 0));
		_addressToId[0xA6Bd32CBe694cDDe1ae31135366852F7449dD688] = 3;
		_players.push(Player(0x5F708E04c2B172eC6512144CF5CF8C0Eb3bB1B7A, 0));
		_addressToId[0x5F708E04c2B172eC6512144CF5CF8C0Eb3bB1B7A] = 4;
		_players.push(Player(0x716b5b8B12169dFe22210f7B49d4350AE8291C3C, 0));
		_addressToId[0x716b5b8B12169dFe22210f7B49d4350AE8291C3C] = 5;
		_players.push(Player(0xb753Aa288F5076E7935804BFf1C3CaedC4D24f17, 0));
		_addressToId[0xb753Aa288F5076E7935804BFf1C3CaedC4D24f17] = 6;
		_players.push(Player(0xD2eF80f95F15305774AcfAC68415290719E057c4, 0));
		_addressToId[0xD2eF80f95F15305774AcfAC68415290719E057c4] = 7;
		_players.push(Player(0x0d6bFE30C32CC5463D1f2F980ebB0cc1E10F0f08, 0));
		_addressToId[0x0d6bFE30C32CC5463D1f2F980ebB0cc1E10F0f08] = 8;
		_players.push(Player(0xEb61D050822Af2Ec1Be1F4157c74fd7B73e69aC6, 0));
		_addressToId[0xEb61D050822Af2Ec1Be1F4157c74fd7B73e69aC6] = 9;
		_players.push(Player(0x28799942C53aadDAFc33D127B40ce97EFdADC4E1, 0));
		_addressToId[0x28799942C53aadDAFc33D127B40ce97EFdADC4E1] = 10;
		_players.push(Player(0x4C8eCe0B58Ec878DbDa21Aa58c93f476DD31cEB1, 0));
		_addressToId[0x4C8eCe0B58Ec878DbDa21Aa58c93f476DD31cEB1] = 11;
		_players.push(Player(0x9464191A13A7e43dC7Ee1deA6c6bDa8eEE2B167b, 0));
		_addressToId[0x9464191A13A7e43dC7Ee1deA6c6bDa8eEE2B167b] = 12;
		_players.push(Player(0xe3A1FBd153FFb6Ba4371763C1Bb6C7bc9B2DBe63, 0));
		_addressToId[0xe3A1FBd153FFb6Ba4371763C1Bb6C7bc9B2DBe63] = 13;
		_players.push(Player(0x54346bAbfcfd3295B93A84dF5b979A87f75Bb846, 0));
		_addressToId[0x54346bAbfcfd3295B93A84dF5b979A87f75Bb846] = 14;
		_players.push(Player(0xE7A87Af6b84CB5e3815393E57661b16De4041275, 0));
		_addressToId[0xE7A87Af6b84CB5e3815393E57661b16De4041275] = 15;
		_players.push(Player(0xD53140D111b57F4C676Cc728E00Bb10F63dfC950, 0));
		_addressToId[0xD53140D111b57F4C676Cc728E00Bb10F63dfC950] = 16;
		_players.push(Player(0x5d2E9C5b0fC970d94b41998CA99aEf7922b841bd, 0));
		_addressToId[0x5d2E9C5b0fC970d94b41998CA99aEf7922b841bd] = 17;
		_players.push(Player(0xa093C0936F100635D7aE0C15f8Cb30a66F9384Da, 0));
		_addressToId[0xa093C0936F100635D7aE0C15f8Cb30a66F9384Da] = 18;
		_players.push(Player(0x8385a9DA4Eef33CC94bA00aF84F50113c9a29fB9, 96900000));
		_addressToId[0x8385a9DA4Eef33CC94bA00aF84F50113c9a29fB9] = 19;
		_players.push(Player(0x51685a90eDc84e86515B44093f64b9a28A8C57d0, 0));
		_addressToId[0x51685a90eDc84e86515B44093f64b9a28A8C57d0] = 20;


	}
}

//SourceUnit: Rewards.sol

pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;

import "./PlayerBase.sol";
import "./Ownable.sol";

struct Reward {
	uint32 playerId;
	uint32 renounceAt;
	uint192 amount;
}

contract RewardsQueue is Ownable, PlayerBase {

	uint private _retention;

	uint128 private _first;
  uint128 private _last;
	mapping(uint128 => Reward) private _rewards;

	function rewards() public view returns(uint[4][] memory) {
		uint count = 0;
		for (uint128 number = _first; number <= _last; number++)
			if(!_isEmpty(number)) count++;
		if(count == 0) return new uint[4][](0);
		uint[4][] memory result = new uint[4][](count);
		count = 0;
		for (uint128 number = _first; number <= _last; number++)
			if(!_isEmpty(number))
				result[count++] = [
					number,
					uint(_playerAddressById(_rewards[number].playerId)),
					_rewards[number].amount,
					_rewards[number].renounceAt
				];
		return result;
	}

	function playerRewards(address player) public view returns(uint[3][] memory) {
		if(!playerExists(player)) return new uint[3][](0);
		uint count = 0;
		for (uint128 number = _first; number <= _last; number++)
			if(_playerIdByAddress(player) == _rewards[number].playerId) count++;
		uint[3][] memory result = new uint[3][](count);
		count = 0;
		for (uint128 number = _first; number <= _last; number++)
			if(_playerIdByAddress(player) == _rewards[number].playerId)
				result[count++] = [
					uint(number),
					_rewards[number].amount,
					_rewards[number].renounceAt
				];
		return result;
	}

	function setRetentionPeriod(uint32 period) public onlyOwner {
		_retention = period;
	}

	function retentionPeriod() public view returns(uint) {
		return _retention;
	}

	function _addReward(address player, uint256 amount) internal {
		_rewards[++_last] = Reward(
			uint32(_playerIdByAddress(player)),
			uint32(block.timestamp + _retention),
			uint192(amount)
		);
	}

	function _reward(uint128 number) internal view returns (Reward memory) {
		return _rewards[number];
	}

	function _isEmpty(uint128 number) internal view returns(bool) {
		return _rewards[number].playerId == 0;
	}

	function _processMainQueue(uint amount) internal {
		uint128 n;
		uint128 shift = 0;
		for (n = _first; n <= _last; n++)
			if(_isEmpty(n))
				shift++;
			else
				break;
		if(shift > 0) _first += shift;
		for (n = _first; n <= _last; n++) {
			if(!_isEmpty(n)) {
				Reward memory r = _rewards[n];
				if(r.amount < amount + _playerBalanceById(r.playerId)) {
					_award(n, _playerAddressById(r.playerId), r.amount);
					amount -= (r.amount - _playerBalanceById(r.playerId));
					_emptyBalanceById(r.playerId);
					_deleteReward(n);
				} else {
					_increaseBalanceById(r.playerId, amount);
					break;
				}
			}
		}
	}

	function _processPlayerQueue(address player, uint amount) internal returns(uint) {
		uint playerId = _playerIdByAddress(player);
		for (uint128 n = _first; n <= _last; n++) {
			if(!_isEmpty(n) && _rewards[n].playerId == playerId) {
				Reward memory r = _rewards[n];
				if(r.amount < amount + _playerBalanceById(playerId)) {
					_award(n, player, r.amount);
					amount -= (r.amount - _playerBalanceById(playerId));
					_emptyBalanceById(playerId);
					_deleteReward(n);
				} else {
					_increaseBalanceById(playerId, amount);
					return 0;
				}
			}
		}
		return amount;
	}

	event Awarded(uint number, address player, uint prize);

	function _award(uint number, address player, uint prize) internal {
		payable(player).transfer(prize);
		emit Awarded(number, player, prize);
	}

	function _deleteReward(uint128 number) internal {
		delete _rewards[number];
		if(number == _first) _first++;
	}

	function _lastNumber() internal view returns (uint) {
		return _last;
	}

	function _findFirstRewardNumberByPlayerId(uint id) internal view returns (uint128) {
		for (uint128 n = _first; n <= _last; n++)
			if(_rewards[n].playerId == id) return n;
	}

	function _parentsInQueue(address player) internal view returns(uint[] memory) {

		uint parentsCount = 0;
		address nextPlayer = _parent(player);

		while(playerExists(nextPlayer)) {
			parentsCount++;
			nextPlayer = _parent(nextPlayer);
		}

		if(parentsCount == 0) return new uint[](0);

		uint[] memory parents = new uint[](parentsCount);
		nextPlayer = _parent(player);
		for (uint256 i = 0; i < parentsCount; i++) {
			parents[i] = _playerIdByAddress(nextPlayer);
			nextPlayer = _parent(nextPlayer);
		}

		uint[] memory parentsInQueue = new uint[](parentsCount);

		for (uint128 n = _first; n <= _last; n++) {
			for (uint256 i = 0; i < parentsCount; i++) {
				if(parentsInQueue[i] == 0)
					if(_rewards[n].playerId == parents[i]) 
						parentsInQueue[i] = parents[i];
			}
		}

		return parentsInQueue;
		
	}

	constructor() internal {
		_first = 117;
		_last = 161;
		_retention = 20 days;
		_rewards[117] = Reward(uint32(_playerIdByAddress(0x8385a9DA4Eef33CC94bA00aF84F50113c9a29fB9)), uint32(1614103239 + _retention), 2400000000);
		_rewards[118] = Reward(uint32(_playerIdByAddress(0x28799942C53aadDAFc33D127B40ce97EFdADC4E1)), uint32(1614103239 + _retention), 6000000000);
		_rewards[119] = Reward(uint32(_playerIdByAddress(0x40c1FEd422126EA27400C9Ae894FCd016f76D8E4)), uint32(1614103953 + _retention), 1200000000);
		_rewards[120] = Reward(uint32(_playerIdByAddress(0x4C8eCe0B58Ec878DbDa21Aa58c93f476DD31cEB1)), uint32(1614104358 + _retention), 5964000000);
		_rewards[121] = Reward(uint32(_playerIdByAddress(0x4C8eCe0B58Ec878DbDa21Aa58c93f476DD31cEB1)), uint32(1614104388 + _retention), 3456000000);
		_rewards[122] = Reward(uint32(_playerIdByAddress(0x40c1FEd422126EA27400C9Ae894FCd016f76D8E4)), uint32(1614104427 + _retention), 1200000000);
		_rewards[123] = Reward(uint32(_playerIdByAddress(0xD2eF80f95F15305774AcfAC68415290719E057c4)), uint32(1614104679 + _retention), 5064000000);
		_rewards[124] = Reward(uint32(_playerIdByAddress(0x5F708E04c2B172eC6512144CF5CF8C0Eb3bB1B7A)), uint32(1614104949 + _retention), 2632800000);
		_rewards[125] = Reward(uint32(_playerIdByAddress(0xb753Aa288F5076E7935804BFf1C3CaedC4D24f17)), uint32(1614108729 + _retention), 3600000000);
		_rewards[126] = Reward(uint32(_playerIdByAddress(0x28799942C53aadDAFc33D127B40ce97EFdADC4E1)), uint32(1614110781 + _retention), 1200000000);
		_rewards[127] = Reward(uint32(_playerIdByAddress(0x9464191A13A7e43dC7Ee1deA6c6bDa8eEE2B167b)), uint32(1614143805 + _retention), 120000000);
		_rewards[128] = Reward(uint32(_playerIdByAddress(0x40c1FEd422126EA27400C9Ae894FCd016f76D8E4)), uint32(1614147741 + _retention), 2160000000);
		_rewards[129] = Reward(uint32(_playerIdByAddress(0x40c1FEd422126EA27400C9Ae894FCd016f76D8E4)), uint32(1614155991 + _retention), 1680000000);
		_rewards[130] = Reward(uint32(_playerIdByAddress(0xb753Aa288F5076E7935804BFf1C3CaedC4D24f17)), uint32(1614156069 + _retention), 3600000000);
		_rewards[131] = Reward(uint32(_playerIdByAddress(0x40c1FEd422126EA27400C9Ae894FCd016f76D8E4)), uint32(1614157140 + _retention), 1080000000);
		_rewards[132] = Reward(uint32(_playerIdByAddress(0xa093C0936F100635D7aE0C15f8Cb30a66F9384Da)), uint32(1614157437 + _retention), 1200000000);
		_rewards[133] = Reward(uint32(_playerIdByAddress(0x5d2E9C5b0fC970d94b41998CA99aEf7922b841bd)), uint32(1614157512 + _retention), 3000000000);
		_rewards[134] = Reward(uint32(_playerIdByAddress(0xE7A87Af6b84CB5e3815393E57661b16De4041275)), uint32(1614165651 + _retention), 2244000000);
		_rewards[135] = Reward(uint32(_playerIdByAddress(0xb753Aa288F5076E7935804BFf1C3CaedC4D24f17)), uint32(1614165735 + _retention), 2520000000);
		_rewards[136] = Reward(uint32(_playerIdByAddress(0xE7A87Af6b84CB5e3815393E57661b16De4041275)), uint32(1614166575 + _retention), 4110000000);
		_rewards[137] = Reward(uint32(_playerIdByAddress(0x40c1FEd422126EA27400C9Ae894FCd016f76D8E4)), uint32(1614166773 + _retention), 1800000000);
		_rewards[138] = Reward(uint32(_playerIdByAddress(0x40c1FEd422126EA27400C9Ae894FCd016f76D8E4)), uint32(1614191763 + _retention), 120000000);
		_rewards[139] = Reward(uint32(_playerIdByAddress(0x40c1FEd422126EA27400C9Ae894FCd016f76D8E4)), uint32(1614191787 + _retention), 896400000);
		_rewards[140] = Reward(uint32(_playerIdByAddress(0x6e51535175fe54cFBC8609B49f4A44E3174abB92)), uint32(1614192009 + _retention), 3600000000);
		_rewards[141] = Reward(uint32(_playerIdByAddress(0xA6Bd32CBe694cDDe1ae31135366852F7449dD688)), uint32(1614192723 + _retention), 3420000000);
		_rewards[142] = Reward(uint32(_playerIdByAddress(0x0d6bFE30C32CC5463D1f2F980ebB0cc1E10F0f08)), uint32(1614193887 + _retention), 240000000);
		_rewards[143] = Reward(uint32(_playerIdByAddress(0xb753Aa288F5076E7935804BFf1C3CaedC4D24f17)), uint32(1614194157 + _retention), 2448000000);
		_rewards[144] = Reward(uint32(_playerIdByAddress(0x54346bAbfcfd3295B93A84dF5b979A87f75Bb846)), uint32(1614194502 + _retention), 120000000);
		_rewards[145] = Reward(uint32(_playerIdByAddress(0xD53140D111b57F4C676Cc728E00Bb10F63dfC950)), uint32(1614268839 + _retention), 480000000);
		_rewards[146] = Reward(uint32(_playerIdByAddress(0x51685a90eDc84e86515B44093f64b9a28A8C57d0)), uint32(1614326865 + _retention), 660000000);
		_rewards[147] = Reward(uint32(_playerIdByAddress(0xD53140D111b57F4C676Cc728E00Bb10F63dfC950)), uint32(1614342933 + _retention), 480000000);
		_rewards[148] = Reward(uint32(_playerIdByAddress(0xe3A1FBd153FFb6Ba4371763C1Bb6C7bc9B2DBe63)), uint32(1614367473 + _retention), 1200000000);
		_rewards[149] = Reward(uint32(_playerIdByAddress(0xEb61D050822Af2Ec1Be1F4157c74fd7B73e69aC6)), uint32(1614512844 + _retention), 6000000000);
		_rewards[150] = Reward(uint32(_playerIdByAddress(0x6e51535175fe54cFBC8609B49f4A44E3174abB92)), uint32(1614521439 + _retention), 3600000000);
		_rewards[151] = Reward(uint32(_playerIdByAddress(0x6e51535175fe54cFBC8609B49f4A44E3174abB92)), uint32(1614523974 + _retention), 3600000000);
		_rewards[152] = Reward(uint32(_playerIdByAddress(0x28799942C53aadDAFc33D127B40ce97EFdADC4E1)), uint32(1614524034 + _retention), 2160000000);
		_rewards[153] = Reward(uint32(_playerIdByAddress(0x6e51535175fe54cFBC8609B49f4A44E3174abB92)), uint32(1614524529 + _retention), 3600000000);
		_rewards[154] = Reward(uint32(_playerIdByAddress(0x54346bAbfcfd3295B93A84dF5b979A87f75Bb846)), uint32(1614526857 + _retention), 3600000000);
		_rewards[155] = Reward(uint32(_playerIdByAddress(0xD2eF80f95F15305774AcfAC68415290719E057c4)), uint32(1614526929 + _retention), 2352000000);
		_rewards[156] = Reward(uint32(_playerIdByAddress(0x54346bAbfcfd3295B93A84dF5b979A87f75Bb846)), uint32(1614527319 + _retention), 1440000000);
		_rewards[157] = Reward(uint32(_playerIdByAddress(0x6e51535175fe54cFBC8609B49f4A44E3174abB92)), uint32(1614528225 + _retention), 876000000);
		_rewards[158] = Reward(uint32(_playerIdByAddress(0x6e51535175fe54cFBC8609B49f4A44E3174abB92)), uint32(1614528276 + _retention), 3840000000);
		_rewards[159] = Reward(uint32(_playerIdByAddress(0x6e51535175fe54cFBC8609B49f4A44E3174abB92)), uint32(1614718818 + _retention), 4200000000);
		_rewards[160] = Reward(uint32(_playerIdByAddress(0x40c1FEd422126EA27400C9Ae894FCd016f76D8E4)), uint32(1614718872 + _retention), 1440000000);
		_rewards[161] = Reward(uint32(_playerIdByAddress(0xb753Aa288F5076E7935804BFf1C3CaedC4D24f17)), uint32(1614760851 + _retention), 2394000000);	
	}
}

//SourceUnit: Splitting.sol

pragma solidity 0.6.0;
import "./Ownable.sol";
import "./Commission.sol";

contract Splitting is Ownable, Commission {
	mapping(uint => uint) private _split;
	uint _levels;

	event SplittingUpdated(uint level, uint from, uint to);

	function setSplitting(uint[] memory split) public onlyOwner {		
		uint sum = 0;
    uint i;
		for (i = 0; i < split.length; i++) sum += split[i];
    sum += commission();
		require(sum <= 100*100, "Values including commission exceeds 100%");
		if(split.length > _levels) 
			for (i = 0; i < split.length; i++)
				if( i + 1 > _levels ) {					
					_split[i + 1] = split[i];
					emit SplittingUpdated(i + 1, 0, split[i]);
				} else {
					_split[i + 1] = split[i];
					emit SplittingUpdated(i + 1, _split[i + 1], split[i]);
				}
		else
			for (i = 0; i < _levels; i++)
				if( i > split.length ) {
					delete _split[i + 1];
					emit SplittingUpdated(i + 1, _split[i + 1], 0);
				} else {
					_split[i + 1] = split[i];
					emit SplittingUpdated(i + 1, _split[i + 1], split[i]);
				}
		_levels = split.length;		
	}

  function _splitted(uint amount) internal view returns (uint[] memory) {
    uint[] memory results = new uint[](_levels+1);
    results[0] = amount;
    for (uint256 i = 0; i < _levels; i++) {      
			results[i+1] = (amount*_split[i + 1])/10000;
      results[0] -= results[i+1];
		}
    return results;
  }

	function splitting() public view returns (uint[] memory) {
		uint[] memory results = new uint[](_levels);
		for (uint256 i = 0; i < _levels; i++) {
			results[i] = _split[i + 1];
		}
		return results;
	}

}