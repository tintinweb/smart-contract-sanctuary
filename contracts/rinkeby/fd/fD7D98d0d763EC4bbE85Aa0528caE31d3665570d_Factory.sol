/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File contracts/libraries/math/SafeMath.sol

pragma solidity ^0.6.0;

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


// File contracts/libraries/utils/Address.sol

pragma solidity ^0.6.0;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}


// File contracts/interfaces/IUniversalMarket.sol

pragma solidity ^0.6.0;

interface IUniversalMarket {
    function initialize(
        address _owner,
        string calldata _metaData,
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals,
        uint256[] calldata _conditions,
        address[] calldata _references
    ) external returns (bool);
}


// File contracts/interfaces/IRegistry.sol

pragma solidity ^0.6.0;

interface IRegistry {
    function supportMarket(address _market) external;

    function isListed(address _market) external view returns (bool);

    function getCDS(address _address) external view returns (address);
}


// File contracts/Factory.sol

/**
 * @title Factory
 * @author @kohshiba
 * @notice This contract is the functory contract that manages functions related to market creation activities.
 */

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;




contract Factory {
    using SafeMath for uint256;
    using Address for address;

    event MarketCreated(
        address indexed market,
        address indexed template,
        string _metaData,
        string _name,
        string _symbol,
        uint8 _decimals,
        uint256[] conditions,
        address[] references
    );
    event TemplateApproval(
        IUniversalMarket indexed template,
        bool indexed approval,
        bool indexed isOpen
    );
    event ReferenceApproval(
        IUniversalMarket indexed template,
        uint256 indexed slot,
        address target,
        bool approval
    );
    event ConditionApproval(
        IUniversalMarket indexed template,
        uint256 indexed slot,
        uint256 target
    );
    event CommitNewAdmin(uint256 deadline, address future_admin);
    event NewAdmin(address admin);

    address[] public markets;

    mapping(address => bool) public templates;
    mapping(address => bool) public approval;
    mapping(address => mapping(uint256 => mapping(address => bool)))
        public reflist;
    mapping(address => mapping(uint256 => uint256)) public conditionlist;

    address public registry;
    address public owner;
    address public future_owner;
    uint256 public transfer_ownership_deadline;
    uint256 public constant ADMIN_ACTIONS_DELAY = 3 * 86400;

    constructor(address _registry) public {
        owner = msg.sender;
        registry = _registry;
    }

    /**
     * @notice A function to approve or disapprove templates.
     * Only owner of the contract can operate.
     */
    function approveTemplate(
        IUniversalMarket _template,
        bool _approval,
        bool _isOpen
    ) external {
        require(msg.sender == owner, "dev: only owner");
        require(address(_template) != address(0));
        templates[address(_template)] = _approval;
        approval[address(_template)] = _isOpen;
        emit TemplateApproval(_template, _approval, _isOpen);
    }

    /**
     * @notice A function to preset reference.
     * Only owner of the contract can operate.
     */
    function approveReference(
        IUniversalMarket _template,
        uint256 _slot,
        address _target,
        bool _approval
    ) external {
        require(msg.sender == owner, "dev: only owner");
        require(templates[address(_template)] == true);
        reflist[address(_template)][_slot][_target] = _approval;
        emit ReferenceApproval(_template, _slot, _target, _approval);
    }

    /**
     * @notice A function to preset reference.
     * Only owner of the contract can operate.
     */
    function setCondition(
        IUniversalMarket _template,
        uint256 _slot,
        uint256 _target
    ) external {
        require(msg.sender == owner, "dev: only owner");
        require(templates[address(_template)] == true);
        conditionlist[address(_template)][_slot] = _target;
        emit ConditionApproval(_template, _slot, _target);
    }

    /**
     * @notice A function to create markets.
     * This function is market model agnostic.
     */
    function createMarket(
        IUniversalMarket template,
        string memory _metaData,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256[] memory _conditions,
        address[] memory _references
    ) public returns (address) {
        require(templates[address(template)] == true, "UNAUTHORIZED_TEMPLATE");
        if (approval[address(template)] == false) {
            require(owner == msg.sender, "UNAUTHORIZED_SENDER");
        }
        if (_references.length > 0) {
            for (uint256 i = 0; i < _references.length; i++) {
                require(
                    reflist[address(template)][i][_references[i]] == true ||
                        reflist[address(template)][i][address(0)] == true,
                    "UNAUTHORIZED_REFERENCE"
                );
            }
        }

        if (_conditions.length > 0) {
            for (uint256 i = 0; i < _conditions.length; i++) {
                _conditions[i] = conditionlist[address(template)][i];
            }
        }

        address _owner = owner;

        IUniversalMarket market =
            IUniversalMarket(_createClone(address(template)));

        market.initialize(
            _owner,
            _metaData,
            _name,
            _symbol,
            _decimals,
            _conditions,
            _references
        );

        emit MarketCreated(
            address(market),
            address(template),
            _metaData,
            _name,
            _symbol,
            _decimals,
            _conditions,
            _references
        );
        markets.push(address(market));
        IRegistry(registry).supportMarket(address(market));
        return address(market);
    }

    /**
     * @notice Template Code for the create clone method:
     * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1167.md
     */
    function _createClone(address target) internal returns (address result) {
        // convert address to bytes20 for assembly use
        bytes20 targetBytes = bytes20(target);
        assembly {
            // allocate clone memory
            let clone := mload(0x40)
            // store initial portion of the delegation contract code in bytes form
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            // store the provided address
            mstore(add(clone, 0x14), targetBytes)
            // store the remaining delegation contract code
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            // create the actual delegate contract reference and return its address
            result := create(0, clone, 0x37)
        }
    }

    //----- ownership -----//
    function commit_transfer_ownership(address _owner) external {
        require(msg.sender == owner, "dev: only owner");
        require(transfer_ownership_deadline == 0, "dev: active transfer");

        uint256 _deadline = block.timestamp.add(ADMIN_ACTIONS_DELAY);
        transfer_ownership_deadline = _deadline;
        future_owner = _owner;

        emit CommitNewAdmin(_deadline, _owner);
    }

    function apply_transfer_ownership() external {
        require(msg.sender == owner, "dev: only owner");
        require(
            block.timestamp >= transfer_ownership_deadline,
            "dev: insufficient time"
        );
        require(transfer_ownership_deadline != 0, "dev: no active transfer");

        transfer_ownership_deadline = 0;
        address _owner = future_owner;

        owner = _owner;

        emit NewAdmin(owner);
    }
}