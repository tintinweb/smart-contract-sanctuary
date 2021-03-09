/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-08
*/

// File: contracts/Errors.sol

pragma solidity 0.6.12;

contract Modifier {
    string internal constant ONLY_OWNER = "O";
    string internal constant ONLY_MANAGER = "M";
    string internal constant CIRCUIT_BREAKER = "emergency";
}

contract ManagerModifier is Modifier {
    string internal constant ONLY_HANDLER = "H";
    string internal constant ONLY_LIQUIDATION_MANAGER = "LM";
    string internal constant ONLY_BREAKER = "B";
}

contract HandlerDataStorageModifier is Modifier {
    string internal constant ONLY_BIFI_CONTRACT = "BF";
}

contract SIDataStorageModifier is Modifier {
    string internal constant ONLY_SI_HANDLER = "SI";
}

contract HandlerErrors is Modifier {
    string internal constant USE_VAULE = "use value";
    string internal constant USE_ARG = "use arg";
    string internal constant EXCEED_LIMIT = "exceed limit";
    string internal constant NO_LIQUIDATION = "no liquidation";
    string internal constant NO_LIQUIDATION_REWARD = "no enough reward";
    string internal constant NO_EFFECTIVE_BALANCE = "not enough balance";
    string internal constant TRANSFER = "err transfer";
}

contract SIErrors is Modifier { }

contract InterestErrors is Modifier { }

contract LiquidationManagerErrors is Modifier {
    string internal constant NO_DELINQUENT = "not delinquent";
}

contract ManagerErrors is ManagerModifier {
    string internal constant REWARD_TRANSFER = "RT";
    string internal constant UNSUPPORTED_TOKEN = "UT";
}

contract OracleProxyErrors is Modifier {
    string internal constant ZERO_PRICE = "price zero";
}

contract RequestProxyErrors is Modifier { }

contract ManagerDataStorageErrors is ManagerModifier {
    string internal constant NULL_ADDRESS = "err addr null";
}

// File: contracts/oracle/oracle.sol

pragma solidity 0.6.12;

/**
 * @title BiFi's mockup Contract
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract observerOracle is Modifier {
  address payable owner;
  mapping(address => bool) operators;

  int256 price;

	modifier onlyOwner {
		require(msg.sender == owner, "onlyOwner");
		_;
	}

	modifier onlyOperators {
		address sender = msg.sender;
		require(operators[sender] || sender == owner, "onlyOperators");
		_;
	}

	constructor (int256 _price) public
	{
		address payable sender = msg.sender;
		owner = sender;
		operators[sender] = true;
		price = _price;
	}

	function ownershipTransfer(address payable _owner) onlyOwner external returns (bool) {
		owner = _owner;
		return true;
	}

	function setOperator(address payable addr, bool flag) onlyOwner external returns (bool) {
		operators[addr] = flag;
		return flag;
	}
	function latestAnswer() external view returns (int256)
	{
		return price;
	}

	function setPrice(int256 _price) onlyOwner public
	{
	  price = _price;
	}
}