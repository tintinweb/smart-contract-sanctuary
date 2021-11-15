// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./Token.sol";
import "./feeds/ChainlinkPriceConsumer.sol";
import "./Initializable.sol";

contract Betting is Ownable, Initializable {
    
  using SafeMath for uint;

	struct Game {
		address gamer1;
		address gamer2;

		address token1;
		address token2;

		uint amount1;
		uint amount2;

		uint latestBet;

		bool closed;
	}

	uint public referrerFee; //50%
	uint public adminFee; //50%
	uint public globalFee; //in %
	uint public transactionFee; //in USD (10^18 meanth $1))
	bool public acceptBets;
	
	address public eth_usd_consumer_address;
	ChainlinkPriceConsumer private eth_usd_pricer;
	uint8 private eth_usd_pricer_decimals;

	uint256 private constant PRICE_PRECISION = 1e6;

	address public manager;
	address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
	mapping(address => bool) public bots;
	mapping(address => bool) public supportBots;
	mapping(uint => Game[]) public typeGames;
	
	mapping(uint => uint) public typePrice;
	mapping(address => uint) public tokenPrice;
	mapping(address => address) public userReferrer;
	mapping(address => bool) public userRegistered;
	mapping(address => bool) public inGame;
	mapping(address => ChainlinkPriceConsumer) public chainlinkMapper;
	mapping(address => uint8) public chainlinkMapperDecimals;
	mapping(address => bool) isSupportedToken;
	mapping(address => bool) isStablecoin;


	event Registration(address indexed user, address indexed referrer, bytes32 password);
	event PriceUpdated(address indexed tokenAddress, uint price);
	event NewGamer(address indexed user, uint indexed betType, uint indexed gameIndex, address tokenAddress, uint value);
	event NewGame(uint indexed betType, uint gameIndex);
	event GameStarted(address indexed user1, address indexed user2, uint indexed betType, uint gameIndex);
	event NewGlobalFee(uint newGlobalFee);
	event NewAdminFee(uint newAdminFee);
	event NewReferrerFee(uint newReferrerFee);
	event NewTransactionFee(uint newTransactionFee);
	event GameClosed(address indexed winner, uint indexed betType, uint indexed gameIndex, uint prize1, uint prize2, uint fee);
	event NewTypePrice(uint indexed betType, uint price);

	modifier onlyManager() {
		require(msg.sender == manager, 'only manager'); 
		_; 
	}

	modifier onlyUnlocked() {
		require(acceptBets, 'Bets locked'); 
		_; 
	}

	modifier onlyRegistrated() {
		require(userRegistered[msg.sender], 'register first');
		require(!inGame[msg.sender], 'already in game'); 
		_; 
	}

	function lockBets() public onlyOwner {
		acceptBets = false;
	}

	function unlockBets() public onlyOwner {
		acceptBets = true;
	}

	function addBots(address[] memory _bots) public onlyOwner {
		for(uint256 i = 0; i < _bots.length; i++) {
			bots[_bots[i]] = true;
		}
	}

	function init(address _managerAddress, address _eth_usd_consumer_address, address[] memory supportedTokens, address[] memory chainlink_price_consumer_addresses, bool[] memory _isStablecoin) public initializer {
		require(supportedTokens.length == chainlink_price_consumer_addresses.length);
		require(supportedTokens.length == _isStablecoin.length);

		address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
		
		manager = _managerAddress;
		setETHUSDOracle(_eth_usd_consumer_address);

		for(uint i = 0; i < supportedTokens.length; i++) {
			addSupportedToken(supportedTokens[i], chainlink_price_consumer_addresses[i], _isStablecoin[i]);
		}

		referrerFee = 50;
		adminFee = 50;
		globalFee = 10;

		acceptBets = true;
	}

	function addSupportedToken(address _newToken, address _chainlink_price_consumer_address, bool _isStablecoin) public onlyOwner {
		if(!_isStablecoin) {
			chainlinkMapper[_newToken] = ChainlinkPriceConsumer(_chainlink_price_consumer_address);
			chainlinkMapperDecimals[_newToken] = chainlinkMapper[_newToken].getDecimals();
		}

		isStablecoin[_newToken] = _isStablecoin;
		isSupportedToken[_newToken] = true;
	}

	function registration(address _referrer, bytes32 _password) public {
		require(!userRegistered[msg.sender], "user already exists");
		require(_referrer != msg.sender, "refferer must not be equal to user wallet");

		userRegistered[msg.sender] = true;
		userReferrer[msg.sender] = _referrer;

		emit Registration(msg.sender, _referrer, _password);
	}

	function newManager(address _newManagerAddress) public onlyOwner {
		manager = _newManagerAddress;
	}

	function setGlobalFee(uint _newFee) public onlyManager {
		globalFee = _newFee;
		emit NewGlobalFee(_newFee);
	}

	function setAdminFee(uint _newAdminFee) public onlyManager {
		adminFee = _newAdminFee;
		emit NewAdminFee(_newAdminFee);
	}

	function setWinnerFee(uint _newReferrerFee) public onlyManager {
		referrerFee = _newReferrerFee;
		emit NewReferrerFee(_newReferrerFee);
	}

	function setTransactionFee(uint _newTransactionFee) public onlyManager {
		transactionFee = _newTransactionFee;
		emit NewTransactionFee(_newTransactionFee);
	}
	
	function bet(address tokenAddress, uint t, bool supportsBot) public payable onlyRegistrated onlyUnlocked {
		require(typePrice[t] != 0, "invalid bet type");
		require(isSupportedToken[tokenAddress], "Token is not supported");
		require(!inGame[msg.sender], "User already in game");
		supportBots[msg.sender] = supportsBot;
		//@todo add referrer program
		inGame[msg.sender] = true;
		if(msg.value > 0) {
			ethBet(msg.sender, t, msg.value, supportsBot);
			return;
		}

		tokenBet(msg.sender, t, tokenAddress, supportsBot);
	}

	function forcedCloseGame(uint t, uint gameIndex) public onlyManager {
		Game memory _game = typeGames[t][gameIndex];

		typeGames[t][gameIndex].closed = true;
		inGame[_game.gamer1] = false;

		IERC20(_game.token1).transfer(_game.gamer1, _game.amount1);
	}

	function closeGame(uint t, uint gameIndex, address payable winnerAddress) public onlyManager {
		require(!typeGames[t][gameIndex].closed, "game already closed");

		Game memory _game = typeGames[t][gameIndex];
		require(winnerAddress == _game.gamer1 || winnerAddress == _game.gamer2, "invalid winner");

		typeGames[t][gameIndex].closed = true;

		inGame[_game.gamer1] = false;
		inGame[_game.gamer2] = false;

		uint gameFee1 = _game.amount1.mul(globalFee).div(100);
		uint gameFee2 = _game.amount2.mul(globalFee).div(100);

		uint transactionFee1 = _game.token1 == ETH_ADDRESS ? (uint256(eth_usd_pricer.getLatestPrice()) * (PRICE_PRECISION) / (uint256(10) ** eth_usd_pricer_decimals)).mul(transactionFee) : isStablecoin[_game.token1] ? PRICE_PRECISION : uint256(chainlinkMapper[_game.token1].getLatestPrice()) * (PRICE_PRECISION) / (uint256(10) ** chainlinkMapperDecimals[_game.token1]);
		uint transactionFee2 = _game.token2 == ETH_ADDRESS ? (uint256(eth_usd_pricer.getLatestPrice()) * (PRICE_PRECISION) / (uint256(10) ** eth_usd_pricer_decimals)).mul(transactionFee) : isStablecoin[_game.token2] ? PRICE_PRECISION : uint256(chainlinkMapper[_game.token2].getLatestPrice()) * (PRICE_PRECISION) / (uint256(10) ** chainlinkMapperDecimals[_game.token2]);

		if(_game.token1 == _game.token2) {
			uint completedFee = gameFee1.add(gameFee2).add(transactionFee1).add(transactionFee2);
			address looserAddress = winnerAddress == _game.gamer1 ? _game.gamer2 : _game.gamer1;

			if(_game.token1 == ETH_ADDRESS) {
				if(userReferrer[winnerAddress] == address(0) && userReferrer[looserAddress] == address(0)) {
					safeEthTransfer(owner(), completedFee);
				} else if(userReferrer[winnerAddress] == address(0)) {
					safeEthTransfer(owner(), completedFee.mul(adminFee.add(referrerFee.div(2))).div(100));
					safeEthTransfer(userReferrer[looserAddress], completedFee.mul(referrerFee.div(2)).div(100));
				} else if(userReferrer[looserAddress] == address(0)) {
					safeEthTransfer(owner(), completedFee.mul(adminFee.add(referrerFee.div(2))).div(100));
					safeEthTransfer(userReferrer[winnerAddress], completedFee.mul(referrerFee.div(2)).div(100));
				} else {
					safeEthTransfer(owner(), completedFee.mul(adminFee).div(100));
					safeEthTransfer(userReferrer[winnerAddress], completedFee.mul(referrerFee.div(2)).div(100));
					safeEthTransfer(userReferrer[looserAddress], completedFee.mul(referrerFee.div(2)).div(100));
				}

				safeEthTransfer(winnerAddress, _game.amount1.add(_game.amount2).sub(completedFee));
				// address(uint160(owner())).transfer(completedFee);
				// winnerAddress.transfer(_game.amount1.add(_game.amount2).sub(completedFee));
				emit GameClosed(winnerAddress, t, gameIndex, _game.amount1.add(_game.amount2).sub(completedFee), 0, completedFee);
				return;
			}

			if(userReferrer[winnerAddress] == address(0) && userReferrer[looserAddress] == address(0)) {
				IERC20(_game.token1).transfer(address(uint160(owner())), completedFee);
			} else if(userReferrer[winnerAddress] == address(0)) {
				IERC20(_game.token1).transfer(owner(), completedFee.mul(adminFee.add(referrerFee.div(2))).div(100));
				IERC20(_game.token1).transfer(userReferrer[looserAddress], completedFee.mul(referrerFee.div(2)).div(100));
			} else if(userReferrer[looserAddress] == address(0)) {
				IERC20(_game.token1).transfer(owner(), completedFee.mul(adminFee.add(referrerFee.div(2))).div(100));
				IERC20(_game.token1).transfer(userReferrer[winnerAddress], completedFee.mul(referrerFee.div(2)).div(100));
			} else {
				IERC20(_game.token1).transfer(owner(), completedFee.mul(adminFee).div(100));
				IERC20(_game.token1).transfer(userReferrer[winnerAddress], completedFee.mul(referrerFee.div(2)).div(100));
				IERC20(_game.token1).transfer(userReferrer[looserAddress], completedFee.mul(referrerFee.div(2)).div(100));
			}

			IERC20(_game.token1).transfer(winnerAddress, _game.amount1.add(_game.amount2).sub(completedFee));
			emit GameClosed(winnerAddress, t, gameIndex, _game.amount1.add(_game.amount2).sub(completedFee), 0, completedFee);
			return;
		}

		uint totalFee1 = gameFee1.add(transactionFee1);

		internalTransfer(winnerAddress, winnerAddress == _game.gamer1 ? _game.gamer2 : _game.gamer1, _game.token1, _game.amount1, totalFee1.mul(2));
		internalTransfer(winnerAddress, winnerAddress == _game.gamer1 ? _game.gamer2 : _game.gamer1, _game.token2, _game.amount2, 0);
		
		emit GameClosed(winnerAddress, t, gameIndex, _game.amount1.sub(totalFee1), _game.amount2, totalFee1);
	}

	function internalTransfer(address payable winnerAddress, address looserAddress, address tokenAddress, uint value, uint fee) internal {
		if(tokenAddress == ETH_ADDRESS) {
			if(fee != 0) {
				if(userReferrer[winnerAddress] == address(0) && userReferrer[looserAddress] == address(0)) {
					safeEthTransfer(owner(), fee.mul(adminFee.add(referrerFee)).div(100));
				} else if(userReferrer[winnerAddress] == address(0)) {
					safeEthTransfer(owner(), fee.mul(adminFee.add(referrerFee.div(2))).div(100));
					safeEthTransfer(userReferrer[looserAddress], fee.mul(referrerFee.div(2)).div(100));
				} else if(userReferrer[looserAddress] == address(0)) {
					safeEthTransfer(owner(), fee.mul(adminFee.add(referrerFee.div(2))).div(100));
					safeEthTransfer(userReferrer[winnerAddress], fee.mul(referrerFee.div(2)).div(100));
				} else {
					safeEthTransfer(owner(), fee.mul(adminFee).div(100));
					safeEthTransfer(userReferrer[winnerAddress], fee.mul(referrerFee.div(2)).div(100));
					safeEthTransfer(userReferrer[looserAddress], fee.mul(referrerFee.div(2)).div(100));
				}
			}
			safeEthTransfer(winnerAddress, value.sub(fee));
			return;
		}

		if(fee != 0) {
			if(userReferrer[winnerAddress] == address(0) && userReferrer[looserAddress] == address(0)) {
				IERC20(tokenAddress).transfer(owner(), fee.mul(adminFee.add(referrerFee)).div(100));
			} else if(userReferrer[winnerAddress] == address(0)) {
				IERC20(tokenAddress).transfer(owner(), fee.mul(adminFee.add(referrerFee.div(2))).div(100));
				IERC20(tokenAddress).transfer(userReferrer[looserAddress], fee.mul(referrerFee.div(2)).div(100));
			} else if(userReferrer[looserAddress] == address(0)) {
				IERC20(tokenAddress).transfer(owner(), fee.mul(adminFee.add(referrerFee.div(2))).div(100));
				IERC20(tokenAddress).transfer(userReferrer[winnerAddress], fee.mul(referrerFee.div(2)).div(100));
			} else {
				IERC20(tokenAddress).transfer(owner(), fee.mul(adminFee).div(100));
				IERC20(tokenAddress).transfer(userReferrer[winnerAddress], fee.mul(referrerFee.div(2)).div(100));
				IERC20(tokenAddress).transfer(userReferrer[looserAddress], fee.mul(referrerFee.div(2)).div(100));
			}
		}
		IERC20(tokenAddress).transfer(winnerAddress, value.sub(fee));
	}

	function ethBet(address user, uint t, uint ethValue, bool _supportsBot) internal {
		uint256 eth_usd_price = uint256(eth_usd_pricer.getLatestPrice()) * (PRICE_PRECISION) / (uint256(10) ** eth_usd_pricer_decimals);
		require(uint(1e18).mul(typePrice[t]).div(eth_usd_price) >= ethValue, "invalid type or msg.value");

		if (typeGames[t].length == 0) {
			newGame(user, t, ETH_ADDRESS, ethValue);
			return;
		}

		if (typeGames[t][typeGames[t].length-1].gamer2 == address(0)) {
			if(!_supportsBot) {
				require(!bots[typeGames[t][typeGames[t].length-1].gamer1], "User doesn't support bots");
			}

			if(!supportBots[typeGames[t][typeGames[t].length-1].gamer1]) {
				require(!bots[user], "User doesn't support bots");
			}

			typeGames[t][typeGames[t].length-1].gamer2 = user;
			typeGames[t][typeGames[t].length-1].token2 = ETH_ADDRESS;
			typeGames[t][typeGames[t].length-1].amount2 = ethValue;
			typeGames[t][typeGames[t].length-1].latestBet = block.timestamp;

			emit NewGamer(user, t, typeGames[t].length-1, ETH_ADDRESS, ethValue);
			emit GameStarted(typeGames[t][typeGames[t].length-1].gamer1, typeGames[t][typeGames[t].length-1].gamer2, t, typeGames[t].length-1);
			return;
		}

		newGame(user, t, ETH_ADDRESS, ethValue);
	}

	function tokenBet(address user, uint t, address tokenAddress, bool _supportsBot) internal {
		uint256 token_usd_price;
		
		if(isStablecoin[tokenAddress]) {
			token_usd_price = PRICE_PRECISION;
		} else {	
			token_usd_price = uint256(chainlinkMapper[tokenAddress].getLatestPrice()) * (PRICE_PRECISION) / (uint256(10) ** chainlinkMapperDecimals[tokenAddress]);
		}

		uint decimals = IERC20(tokenAddress).decimals();

		uint tokenValue = (10 ** decimals).mul(typePrice[t]).div(token_usd_price);
		IERC20(tokenAddress).transferFrom(user, address(this), tokenValue);

		if (typeGames[t].length == 0) {
			newGame(user, t, tokenAddress, tokenValue);
			return;
		}

		if (typeGames[t][typeGames[t].length-1].gamer2 == address(0)) {
			if(!_supportsBot && bots[typeGames[t][typeGames[t].length-1].gamer1]) {
				if(typeGames[t][typeGames[t].length-2].gamer2 == address(0)) {
					_joinGame(t, user, tokenAddress, tokenValue, 2);
					return;
				}
				newGame(user, t, tokenAddress, tokenValue);
				return;
			}

			if(!supportBots[typeGames[t][typeGames[t].length-1].gamer1] && bots[user]) {
				newGame(user, t, tokenAddress, tokenValue);
				return;
			}

			_joinGame(t, user, tokenAddress, tokenValue, 1);
			return;
		}

		newGame(user, t, tokenAddress, tokenValue);
	}

	function _joinGame(uint t, address user, address tokenAddress, uint tokenValue, uint _sub) internal {
		require(typeGames[t][typeGames[t].length-_sub].gamer1 != user, 'double registration');
		typeGames[t][typeGames[t].length-_sub].gamer2 = user;
		typeGames[t][typeGames[t].length-_sub].token2 = tokenAddress;
		typeGames[t][typeGames[t].length-_sub].amount2 = tokenValue;
		typeGames[t][typeGames[t].length-_sub].latestBet = block.timestamp;

		emit NewGamer(user, t, typeGames[t].length-_sub, tokenAddress, tokenValue);
		emit GameStarted(typeGames[t][typeGames[t].length-_sub].gamer1, typeGames[t][typeGames[t].length-_sub].gamer2, t, typeGames[t].length-_sub);
		return;
	}

	function newGame(address user, uint t, address tokenAddress, uint value) internal {
		typeGames[t].push(Game(user, address(0), tokenAddress, address(0), value, 0, block.timestamp, false));

		emit NewGame(t, typeGames[t].length-1);
		emit NewGamer(user, t, typeGames[t].length-1, tokenAddress, value);
	}

	function updateTokenPrice(address tokenAddress, uint price) public onlyManager {
		// example for 1 USD as basic price 
		// 1 USD mean 10*18 usdt/usdc or any stablecoin with 18 decimals
		// 1 USD mean 8705 renBTC (8 decimals $11,283 price)
		// 1 USD mean 274710000000000000 UNI(18 decimals, $3.39 price)
		// etc

		tokenPrice[tokenAddress] = price;
		emit PriceUpdated(tokenAddress, price);
	}

	function setTypePrice(uint betType, uint price) public onlyManager {
		typePrice[betType] = price;
		emit NewTypePrice(betType, price);
	}

	function safeEthTransfer(address to, uint value) private {
		if(!address(uint160(to)).send(value)) {
			address(uint160(owner())).transfer(value);
		}
	}

	function setETHUSDOracle(address _eth_usd_consumer_address) public onlyOwner {
        eth_usd_consumer_address = _eth_usd_consumer_address;
        eth_usd_pricer = ChainlinkPriceConsumer(_eth_usd_consumer_address);
        eth_usd_pricer_decimals = eth_usd_pricer.getDecimals();
    }
}

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
contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.6.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

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
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Context.sol";

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
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

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

    function decimals() external view returns (uint8);

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;

        _mint(msg.sender, 1e25);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
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
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal { }
}

pragma solidity ^0.6.0;

interface ChainlinkPriceConsumer {
    function getLatestPrice() external view returns (int);
    function getDecimals() external view returns (uint8);
}

