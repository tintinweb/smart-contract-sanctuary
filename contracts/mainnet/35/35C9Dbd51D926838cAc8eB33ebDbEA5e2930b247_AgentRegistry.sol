// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/711/dependencies/IAgency.sol

pragma solidity >=0.5.0;

interface IAgency {
    function register(string calldata _input) external pure returns(bytes32);
}

// File: contracts/711/dependencies/IAgentRegistry.sol

pragma solidity >=0.5.0;

interface IAgentRegistry {
    function agents() external returns (uint256);
    function register(string calldata _nameString) external payable;
    function getAgentAddressById(uint256 _agentId) external view returns (address payable);
    function getAgentAddressByName(bytes32 _agentName) external view returns (address payable);
    function isAgent(address _agent) external view returns (bool);
}

// File: contracts/711/ADDRESSBOOK.sol

pragma solidity ^0.5.0;

contract ADDRESSBOOK {
    address constant public FEE_APPROVER = 0x6C70d504932AA318f8070De13F3c4Ab69A87953f;
    address payable constant public VAULT = 0xB1ff949285107B7b967c0d05886F2513488D0042;
    address constant public REWARDS_DISTRIBUTOR = 0xB3c39777142320F7C5329bF87287A707C77266e3;
    address constant public STAKING_CONTRACT = 0x29d44e1726e4368e5A7Abf4fbC481a874AebCf00;
    address constant public ZAP = 0x0797778B9110D03FF64fF25192e2a980Bf4523b8;
    address constant public TOKEN_ADDRESS_711 = 0x9d4709e7C38e7857636c342a37547E191125E028;
    address constant public AGENT_REGISTRY = 0x35C9Dbd51D926838cAc8eB33ebDbEA5e2930b247;
    address constant public UNISWAP_V2_PAIR_711_WETH = 0xF295b0fa1A89c8a06109fB2D2c860a96Fb39dca5;
}

// File: contracts/711/AgentRegistry.sol

pragma solidity 0.5.16;





contract AgentRegistry is IAgentRegistry, ADDRESSBOOK {
    using SafeMath for *;

    struct Player {
        uint256 id;             // agent id
        bytes32 name;           // agent name
        bool isAgent;           // referral activated
    }

    IAgency agency = IAgency(0x7Bc360ebD65eFa503FF189A0F81f61f85D310Ec3);
    address payable public vault;
    uint256 public agents;      // number of agent
    // player data
    mapping(address => Player) public player;       // player data
    mapping(uint256 => address) public agentxID_;   // return agent address by id
    mapping(bytes32 => address) public agentxName_; // return agent address by name

    //******************
    // MODIFIER
    //******************
    modifier isHuman() {
        require(msg.sender == tx.origin, "sorry humans only");
        _;
    }

    constructor() public {
        vault = VAULT;
    }

    /**
     * @dev Register
     * @notice Register a name by a human player
     */
    function register(string calldata _nameString)
        external
        payable
        isHuman()
    {
        bytes32 _name = agency.register(_nameString);
        address _agent = msg.sender;
        require(msg.value >= 0.1 ether, "insufficient amount");
        require(agentxName_[_name] == address(0), "name registered");

        if(!player[_agent].isAgent){
            agents += 1;
            player[_agent].isAgent = true;
            player[_agent].id = agents;
            agentxID_[agents] = _agent;
        }
        // set name active for the player
        player[_agent].name = _name;
        agentxName_[_name] = _agent;
        // transfer ether to vault
        vault.transfer(msg.value);
    }

    function getAgentAddressById(uint256 _agentId) external view returns (address payable) {
        return address(uint160(agentxID_[_agentId]));
    }

    function getAgentAddressByName(bytes32 _agentName) external view returns (address payable) {
        return address(uint160(agentxName_[_agentName]));
    }

    function isAgent(address _agent) external view returns (bool) {
        return player[_agent].isAgent;
    }
}