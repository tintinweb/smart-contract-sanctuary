/**
 *Submitted for verification at Etherscan.io on 2020-11-27
*/

// Dependency file: contracts/libraries/SafeMath.sol

// SPDX-License-Identifier: MIT

// pragma solidity >=0.6.0;

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

// Dependency file: contracts/libraries/TransferHelper.sol


// pragma solidity >=0.6.0;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// Dependency file: contracts/modules/Configable.sol

// pragma solidity >=0.5.16;
pragma experimental ABIEncoderV2;

interface IConfig {
    function developer() external view returns (address);
    function platform() external view returns (address);
    function factory() external view returns (address);
    function mint() external view returns (address);
    function token() external view returns (address);
    function developPercent() external view returns (uint);
    function share() external view returns (address);
    function base() external view returns (address); 
    function governor() external view returns (address);
    function getPoolValue(address pool, bytes32 key) external view returns (uint);
    function getValue(bytes32 key) external view returns(uint);
    function getParams(bytes32 key) external view returns(uint, uint, uint, uint); 
    function getPoolParams(address pool, bytes32 key) external view returns(uint, uint, uint, uint); 
    function wallets(bytes32 key) external view returns(address);
    function setValue(bytes32 key, uint value) external;
    function setPoolValue(address pool, bytes32 key, uint value) external;
    function setParams(bytes32 _key, uint _min, uint _max, uint _span, uint _value) external;
    function setPoolParams(bytes32 _key, uint _min, uint _max, uint _span, uint _value) external;
    function initPoolParams(address _pool) external;
    function isMintToken(address _token) external returns (bool);
    function prices(address _token) external returns (uint);
    function convertTokenAmount(address _fromToken, address _toToken, uint _fromAmount) external view returns (uint);
    function DAY() external view returns (uint);
    function WETH() external view returns (address);
}

contract Configable {
    address public config;
    address public owner;

    event OwnerChanged(address indexed _oldOwner, address indexed _newOwner);

    constructor() public {
        owner = msg.sender;
    }
    
    function setupConfig(address _config) external onlyOwner {
        config = _config;
        owner = IConfig(config).developer();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'OWNER FORBIDDEN');
        _;
    }
    
    modifier onlyDeveloper() {
        require(msg.sender == IConfig(config).developer(), 'DEVELOPER FORBIDDEN');
        _;
    }
    
    modifier onlyPlatform() {
        require(msg.sender == IConfig(config).platform(), 'PLATFORM FORBIDDEN');
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == IConfig(config).factory(), 'FACTORY FORBIDDEN');
        _;
    }

    modifier onlyGovernor() {
        require(msg.sender == IConfig(config).governor(), 'Governor FORBIDDEN');
        _;
    }
}

// Dependency file: contracts/modules/ConfigNames.sol

// pragma solidity >=0.5.16;

library ConfigNames {
    //GOVERNANCE
    bytes32 public constant PROPOSAL_VOTE_DURATION = bytes32('PROPOSAL_VOTE_DURATION');
    bytes32 public constant PROPOSAL_EXECUTE_DURATION = bytes32('PROPOSAL_EXECUTE_DURATION');
    bytes32 public constant PROPOSAL_CREATE_COST = bytes32('PROPOSAL_CREATE_COST');
    bytes32 public constant STAKE_LOCK_TIME = bytes32('STAKE_LOCK_TIME');
    bytes32 public constant MINT_AMOUNT_PER_BLOCK =  bytes32('MINT_AMOUNT_PER_BLOCK');
    bytes32 public constant INTEREST_PLATFORM_SHARE =  bytes32('INTEREST_PLATFORM_SHARE');
    bytes32 public constant CHANGE_PRICE_DURATION =  bytes32('CHANGE_PRICE_DURATION');
    bytes32 public constant CHANGE_PRICE_PERCENT =  bytes32('CHANGE_PRICE_PERCENT');

    // POOL
    bytes32 public constant POOL_BASE_INTERESTS = bytes32('POOL_BASE_INTERESTS');
    bytes32 public constant POOL_MARKET_FRENZY = bytes32('POOL_MARKET_FRENZY');
    bytes32 public constant POOL_PLEDGE_RATE = bytes32('POOL_PLEDGE_RATE');
    bytes32 public constant POOL_LIQUIDATION_RATE = bytes32('POOL_LIQUIDATION_RATE');
    bytes32 public constant POOL_MINT_BORROW_PERCENT = bytes32('POOL_MINT_BORROW_PERCENT');
    bytes32 public constant POOL_MINT_POWER = bytes32('POOL_MINT_POWER');
    
    //NOT GOVERNANCE
    bytes32 public constant AAAA_USER_MINT = bytes32('AAAA_USER_MINT');
    bytes32 public constant AAAA_TEAM_MINT = bytes32('AAAA_TEAM_MINT');
    bytes32 public constant AAAA_REWAED_MINT = bytes32('AAAA_REWAED_MINT');
    bytes32 public constant DEPOSIT_ENABLE = bytes32('DEPOSIT_ENABLE');
    bytes32 public constant WITHDRAW_ENABLE = bytes32('WITHDRAW_ENABLE');
    bytes32 public constant BORROW_ENABLE = bytes32('BORROW_ENABLE');
    bytes32 public constant REPAY_ENABLE = bytes32('REPAY_ENABLE');
    bytes32 public constant LIQUIDATION_ENABLE = bytes32('LIQUIDATION_ENABLE');
    bytes32 public constant REINVEST_ENABLE = bytes32('REINVEST_ENABLE');
    bytes32 public constant INTEREST_BUYBACK_SHARE =  bytes32('INTEREST_BUYBACK_SHARE');

    //POOL
    bytes32 public constant POOL_PRICE = bytes32('POOL_PRICE');

    //wallet
    bytes32 public constant TEAM = bytes32('team'); 
    bytes32 public constant SPARE = bytes32('spare');
    bytes32 public constant REWARD = bytes32('reward');
}

// Root file: contracts/AAAAGovernance.sol

pragma solidity >=0.5.16;
// import 'contracts/libraries/SafeMath.sol';
// import 'contracts/libraries/TransferHelper.sol';
// import 'contracts/modules/Configable.sol';
// import 'contracts/modules/ConfigNames.sol';

interface IAAAAFactory {
    function createBallot(address _creator, address _pool, 
        bytes32 _name, uint _value, uint _reward, string calldata _subject, string calldata _content, bytes calldata _bytecode) external returns (address ballot);
}

interface IAAAABallot {
    function vote(address _user, uint _index) external;
    function execute(address _user) external;
    function executed() external returns (bool);
    function end() external returns (bool);
    function pass() external returns (bool);
    function expire() external returns (bool);
    function value() external returns (uint);
    function name() external returns (bytes32);
    function pool() external returns (address);
}

interface IAAAAMint {
    function changeInterestRatePerBlock(uint value) external returns (bool);
    function sync() external;
}

interface IAAAAShare {
    function lockStake(address _user) external;
}

contract AAAAGovernance is Configable {
    function createProposal(address _pool, bytes32 _key, uint _value, string calldata _subject, string calldata _content, bytes calldata _bytecode) external {
        _checkValid(_pool, _key, _value);
        uint cost = IConfig(config).getValue(ConfigNames.PROPOSAL_CREATE_COST);
        address token = IConfig(config).token();
        address ballot = IAAAAFactory(IConfig(config).factory()).createBallot(msg.sender, _pool, _key, _value, cost, _subject, _content, _bytecode);
        if(cost > 0) {
            TransferHelper.safeTransferFrom(token, msg.sender, address(this), cost);
            TransferHelper.safeTransfer(token, ballot, cost);
        }
    }

    function voteProposal(address _ballot, uint _index) external {
        IAAAABallot(_ballot).vote(msg.sender, _index);
        IAAAAShare(IConfig(config).share()).lockStake(msg.sender);
    }
    
    function executeProposal(address _ballot) external {
        require(IAAAABallot(_ballot).end(), "Vote not end");
        require(!IAAAABallot(_ballot).expire(), "Vote expire");
        require(IAAAABallot(_ballot).pass(), "Vote not pass");
        require(!IAAAABallot(_ballot).executed(), "Vote executed");
        
        bytes32 key = IAAAABallot(_ballot).name();
        uint value = IAAAABallot(_ballot).value();
        address pool = IAAAABallot(_ballot).pool();
        _checkValid(pool, key, value);
        
        if(key == ConfigNames.MINT_AMOUNT_PER_BLOCK) {
            IConfig(config).setValue(key, value);
            IAAAAMint(IConfig(config).mint()).sync();
        } else if(pool == address(0)) {
            IConfig(config).setValue(key, value);
        } else {
            IConfig(config).setPoolValue(pool, key, value);
        }
        IAAAABallot(_ballot).execute(msg.sender);
    }
    
    function _checkValid(address _pool, bytes32 _key, uint _value) view internal {
        (uint min, uint max, uint span, uint value) = _pool == address(0) ? IConfig(config).getParams(_key): IConfig(config).getPoolParams(_pool, _key);
        
        require(_value <= max && _value >= min, "INVALID VALUE");
        require(_value != value, "Same VALUE");
        require(value + span >= _value && _value + span >= value, "INVALID SPAN");
    }
}