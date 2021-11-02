pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;
//SPDX-License-Identifier: MIT

// import our contracts
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./entities/Pharo.sol";
import "./utility/Conversions.sol";

interface PharoNFT {
	function mintPharoNFT(address pharoHolder, string memory _ipfsHash) external returns (uint256);
}

interface ObeliskNFT {
	function mint(address user) external returns (uint256 id);
}

/**
* @title Pharo Phactory Contract
* @author jaxcoder
* @notice main pharo phactory contract
* @dev additional comments
*/
contract PharoPhactory is Pharo, Ownable, Conversions {
    using Counters for Counters.Counter;

    Counters.Counter private _pharoIds;
	Counters.Counter private _buyerIds;
	Counters.Counter private _lpIds;

    mapping(bytes32 => mapping(uint256 => Pharo)) public eventHashToPharoIdToPharo;
    
	PharoNFT public pharoNft;
	ObeliskNFT public obeliskNft;

    constructor(address pharoNFTAddress, address obeliskNFTAddress)
      public   
    {
		pharoNft = PharoNFT(pharoNFTAddress);
		obeliskNft = ObeliskNFT(obeliskNFTAddress);
    }

    /// @dev createPharo function to be called from the UI by the Market Maker
    function createPharo
    (
        uint256 amtPhroToken,
        bytes32 eventHash,
        string memory name,
        string memory description,
        uint256 lifetime
    )   public
        returns(uint256) 
    {
      	// 1. increment the id
      	_pharoIds.increment();

		// 2. set the new id 
		uint256 newPharoId = _pharoIds.current();

		// 3. create a new Pharo and update the dictionary
		Pharo storage newPharo = pharoDict[eventHash];
		newPharo.id = _pharoIds.current();
		newPharo.nftId = _pharoIds.current();
		newPharo.eventHash = eventHash;
		newPharo.name = name;
		newPharo.description = description;
		newPharo.lifetime = lifetime;
		newPharo.birthday = block.timestamp;
		newPharo.state = PharoState.MUMMY;

		// 4. 

		// 5. 
    }

	function createCoverBuyer(address buyer)
		public
	{
		_buyerIds.increment();
		Buyer storage newBuyer = buyers[_buyerIds.current()];
		newBuyer.buyerAddress = buyer;
		newBuyer.buyerPhroBalance = 0;
		newBuyer.rewardDebt = 0;
	}


	function  createLiquidityProvider
	(
		address provider,
		address asset,
		uint256 amount,
		uint256 odds
	)
		public
	{
		_lpIds.increment();
		Provider storage newProvider = providers[_lpIds.current()];
		newProvider.asset = asset;
		newProvider.providerAddress = provider;
		newProvider.staked = amount;
		newProvider.odds = odds;


	}


	function deposit()
		public
	{

	}


	function withdraw()
		public
	{
		
	}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity 0.8.4;

import "./Provider.sol";
import "./Buyer.sol";
import "./BuyIn.sol";


contract Pharo is Provider, Buyer, BuyIn {
    mapping(address => Pharo) public buyerToPharo;
    mapping(address => Pharo) public providerToPharo;
    mapping(string => Pharo) public eventHashToPharo;


    enum PharoState{ MUMMY, PHARO, IMHOTEP, ANUBIS, OBELISK }

     struct Pharo {
        uint256 id; // the id of the Pharo
        uint256 nftId; // id of the NFT representing the Pharo
        bytes32 eventHash; // hash of the event
        string name; // the name of the Pharo
        string description; // a description for the Pharo
        uint256 lifetime; // Pharo lifetime in seconds
        uint256 birthday; // epch date the Pharo was created
        PharoState state; // the state of the Pharo
        Provider[] providerList; // Array of Providers
        mapping(bytes32 => Provider) providerDict; // event id => Provider
        BuyIn[] buyInList; // Array of BuyIns
        mapping(bytes32 => BuyIn) buyIns; // event id to BuyIn
        Buyer[] buyerList; // Array of Buyers
        mapping(bytes32 => Buyer) buyers; // event id to Buyer
        uint256 liqBalance; // the balance of the Pharo's liquidity
    }

    // Require Pharo to be in a certain state to call function
    modifier inPharoStateObelisk(PharoState _state) {
      require(_state == PharoState.OBELISK);
      _;
    }

    // Require Pharo to be in a certain state to call function
    modifier inPharoStateAnubis(PharoState _state) {
      require(_state == PharoState.ANUBIS);
      _;
    }

    // Require Pharo to be in a certain state to call function
    modifier inPharoStatePharo(PharoState _state) {
      require(_state == PharoState.PHARO);
      _;
    }

    // Require Pharo to be in a certain state to call function
    modifier inPharoStateImhotep(PharoState _state) {
      require(_state == PharoState.IMHOTEP);
      _;
    }

    // Require Pharo to be in a certain state to call function
    modifier inPharoStateMummy(PharoState _state) {
      require(_state == PharoState.MUMMY);
      _;
    }

    mapping(bytes32 => Pharo) public pharoDict;


    constructor () public {}

    // Pharo Logic here...

   
   
}

pragma solidity ^0.8.0;

contract Conversions {
    constructor ( ) public {

    }
    
    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity 0.8.4;


/// @title Provider Contract
/// @author jaxcoder, seanmgonzales
/// @notice Provider objects and mappings
/// @dev it's coming..
contract Provider {

    struct Provider {
        address providerAddress;
        uint256 odds;
        uint256 staked;
        address asset;
    }

    // maps event hash to a provider
    mapping(string => Provider) public eventHashToProvider;
    // stores a Provider struct for each possible address
    mapping(address => Provider) public addressToProvider;

    // dynamic array of Providers
    Provider[] public providers;

    constructor () public {}


    /// @dev Add the over/under lp odds to the pool
    /// @param _lpAddress liquidity providers address
    /// @param _over numerator
    /// @param _under denominator
    function addProviderodds(address _lpAddress, uint256 _over, uint256 _under)
        public
    {
        // 1. update the LP's data struct

        // 2. trigger the state balancing
        //balancePharo(_pharoAddress);
    }

    // internal provider logic and functions here...
}

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

/// @title Cover Buyer Contract
/// @author jaxcoder
/// @notice buyer objects and mappings
/// @dev working on it...
contract Buyer {
    // will represent a single
    struct Buyer {
        address buyerAddress;
        uint256 buyerPhroBalance; // PHRO balance
        uint256 rewardDebt; // what we owe the user
        // reason we want this is so if we see that they are 
        // holding PHRO we can reward them somehow.
    }

    // maps the event hash to the Buyer struct
    mapping(bytes32 => Buyer) eventHashToBuyer;

    // dynamically sized array of Buyers
    Buyer[] public buyers;

    constructor () public {}

    /// @notice Get a list of all the buyers... not sure we will even want to do this?
    /// @dev this has no sort function yet
    function getAllBuyers()
        public
        //returns(Buyer[] memory)
    {

    }

    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @param _buyerId a parameter just like in doxygen (must be followed by parameter name)
    /// @return the buyers address
    function getBuyerAddress(uint256 _buyerId)
        public
        view
        returns(address)
    {
        Buyer memory buyer = buyers[_buyerId];

        return buyer.buyerAddress;
    }

    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @param _buyerId a parameter just like in doxygen (must be followed by parameter name)
    /// @return the buyers balance
    function getBuyerPhroBalance(uint256 _buyerId)
        public
        view
        returns(uint256)
    {
        Buyer memory buyer = buyers[_buyerId];

        return buyer.buyerPhroBalance;
    }



    // Internal buyer logic and funcitons...

  
}

pragma solidity 0.8.4;


/// @title BuyIn Contract
/// @author jaxcoder
/// @notice handles all buy in's for buyers and providers
/// @dev working on it...
contract BuyIn {

    struct BuyIn {
        address buyerAddress;
        uint staked;
        uint[] tranches;
    }

    // maps the event hash to a buy in -
    // buyers can have multiple buy ins associated
    // with their address, so we use an event hash
    // to associate it with the event/pharo itself.
    mapping(string => BuyIn) eventHashToBuyIn;

    // dyanamic array of buy ins
    BuyIn[] public buyins;

    constructor () public {}

    /// @notice Get a list of all the buy ins
    /// @dev this has no sort function yet
    function getAllBuyIns()
        public
        //returns(BuyIn[] memory)
    {

    }

    // Internal buy in logic and functions here..
    
}