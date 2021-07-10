pragma solidity >=0.6.6;

import './interfaces/ITomiConfig.sol';
import './interfaces/ITomiBallotFactory.sol';
import './interfaces/ITomiBallot.sol';
import './interfaces/ITgas.sol';
import './interfaces/ITokenRegistry.sol';
import './libraries/ConfigNames.sol';
import './libraries/TransferHelper.sol';
import './modules/TgasStaking.sol';
import './modules/Ownable.sol';

contract TomiGovernance is TgasStaking, Ownable {
    uint public version = 1;
    address public configAddr;
    address public ballotFactoryAddr;
    address public rewardAddr;

    uint public T_CONFIG = 1;
    uint public T_LIST_TOKEN = 2;
    uint public T_TOKEN = 3;
    mapping(address => uint) public ballotTypes;
    mapping(address => bytes32) public configBallots;
    mapping(address => address) public tokenBallots;
    mapping(address => uint) public rewardOf;
    mapping(address => uint) public ballotOf;
    mapping(address => mapping(address => uint)) public applyTokenOf;
    mapping(address => mapping(address => bool)) public collectUsers;
    mapping(address => address) public tokenUsers;

    address[] public ballots;

    event ConfigAudited(bytes32 name, address indexed ballot, uint proposal);
    event ConfigBallotCreated(address indexed proposer, bytes32 name, uint value, address indexed ballotAddr, uint reward);
    event TokenBallotCreated(address indexed proposer, address indexed token, uint value, address indexed ballotAddr, uint reward);
    event ProposalerRewardRateUpdated(uint oldVaue, uint newValue);
    event RewardTransfered(address indexed from, address indexed to, uint value);
    event TokenListed(address user, address token, uint amount);
    event ListTokenAudited(address user, address token, uint status, uint burn, uint reward, uint refund);
    event TokenAudited(address user, address token, uint status, bool result);
    event RewardCollected(address indexed user, address indexed ballot, uint value);
    event RewardReceived(address indexed user, uint value);

    modifier onlyRewarder() {
        require(msg.sender == rewardAddr, 'TomiGovernance: ONLY_REWARDER');
        _;
    }

    constructor (address _tgas) TgasStaking(_tgas) public {
    }

    // called after deployment
    function initialize(address _rewardAddr, address _configContractAddr, address _ballotFactoryAddr) external onlyOwner {
        require(_rewardAddr != address(0) && _configContractAddr != address(0) && _ballotFactoryAddr != address(0), 'TomiGovernance: INPUT_ADDRESS_IS_ZERO');

        rewardAddr = _rewardAddr;
        configAddr = _configContractAddr;
        ballotFactoryAddr = _ballotFactoryAddr;
        lockTime = getConfigValue(ConfigNames.UNSTAKE_DURATION);
    }

    function audit(address _ballot) external returns (bool) {
        if(ballotTypes[_ballot] == T_CONFIG) {
            return auditConfig(_ballot);
        } else if (ballotTypes[_ballot] == T_LIST_TOKEN) {
            return auditListToken(_ballot);
        } else if (ballotTypes[_ballot] == T_TOKEN) {
            return auditToken(_ballot);
        } else {
            revert('TomiGovernance: UNKNOWN_TYPE');
        }
    }

    function auditConfig(address _ballot) public returns (bool) {
        bool result = ITomiBallot(_ballot).end();
        require(result, 'TomiGovernance: NO_PASS');
        uint value = ITomiBallot(_ballot).value();
        bytes32 name = configBallots[_ballot];
        result = ITomiConfig(configAddr).changeConfigValue(name, value);
        if (name == ConfigNames.UNSTAKE_DURATION) {
            lockTime = value;
        } else if (name == ConfigNames.PRODUCE_TGAS_RATE) {
            _changeAmountPerBlock(value);
        }
        emit ConfigAudited(name, _ballot, value);
        return result;
    }

    function auditListToken(address _ballot) public returns (bool) {
        bool result = ITomiBallot(_ballot).end();
        address token = tokenBallots[_ballot];
        address user = tokenUsers[token];
        require(ITokenRegistry(configAddr).tokenStatus(token) == ITokenRegistry(configAddr).REGISTERED(), 'TomiGovernance: AUDITED');
        uint status = result ? ITokenRegistry(configAddr).PENDING() : ITokenRegistry(configAddr).CLOSED();
	    uint amount = applyTokenOf[user][token];
        (uint burnAmount, uint rewardAmount, uint refundAmount) = (0, 0, 0);
        if (result) {
            burnAmount = amount * getConfigValue(ConfigNames.LIST_TOKEN_SUCCESS_BURN_PRECENT) / ITomiConfig(configAddr).PERCENT_DENOMINATOR();
            rewardAmount = amount - burnAmount;
            if (burnAmount > 0) {
                TransferHelper.safeTransfer(baseToken, address(0), burnAmount);
                totalSupply = totalSupply.sub(burnAmount);
            }
            if (rewardAmount > 0) {
                rewardOf[rewardAddr] = rewardOf[rewardAddr].add(rewardAmount);
                ballotOf[_ballot] = ballotOf[_ballot].add(rewardAmount);
                _rewardTransfer(rewardAddr, _ballot, rewardAmount);
            }
            ITokenRegistry(configAddr).publishToken(token);
        } else {
            burnAmount = amount * getConfigValue(ConfigNames.LIST_TOKEN_FAILURE_BURN_PRECENT) / ITomiConfig(configAddr).PERCENT_DENOMINATOR();
            refundAmount = amount - burnAmount;
            if (burnAmount > 0) TransferHelper.safeTransfer(baseToken, address(0), burnAmount);
            if (refundAmount > 0) TransferHelper.safeTransfer(baseToken, user, refundAmount);
            totalSupply = totalSupply.sub(amount);
            ITokenRegistry(configAddr).updateToken(token, status);
        }
	    emit ListTokenAudited(user, token, status, burnAmount, rewardAmount, refundAmount);
        return result;
    }

    function auditToken(address _ballot) public returns (bool) {
        bool result = ITomiBallot(_ballot).end();
        uint status = ITomiBallot(_ballot).value();
        address token = tokenBallots[_ballot];
        address user = tokenUsers[token];
        require(ITokenRegistry(configAddr).tokenStatus(token) != status, 'TomiGovernance: TOKEN_STATUS_NO_CHANGE');
        if (result) {
            ITokenRegistry(configAddr).updateToken(token, status);
        } else {
            status = ITokenRegistry(configAddr).tokenStatus(token);
        }
	    emit TokenAudited(user, token, status, result);
        return result;
    }

    function getConfigValue(bytes32 _name) public view returns (uint) {
        return ITomiConfig(configAddr).getConfigValue(_name);
    }

    function createConfigBallot(bytes32 _name, uint _value, uint _amount, bool _wallet, string calldata _subject, string calldata _content) external returns (address) {
        require(_value >= 0, 'TomiGovernance: INVALID_PARAMTERS');
        { // avoids stack too deep errors
        (uint minValue, uint maxValue, uint maxSpan, uint value, uint enable) = ITomiConfig(configAddr).getConfig(_name);
        require(enable == 1, "TomiGovernance: CONFIG_DISABLE");
        require(_value >= minValue && _value <= maxValue, "TomiGovernance: OUTSIDE");
        uint span = _value >= value? (_value - value) : (value - _value);
        require(maxSpan >= span, "TomiGovernance: OVERSTEP");
        }
        require(_amount >= getConfigValue(ConfigNames.PROPOSAL_TGAS_AMOUNT), "TomiGovernance: NOT_ENOUGH_AMOUNT_TO_PROPOSAL");
        if(_amount > 0) {
            _amount = _transferForBallot(_amount, _wallet);
            rewardOf[rewardAddr] = rewardOf[rewardAddr].add(_amount);
        }
        uint endBlockNumber = block.number + getConfigValue(ConfigNames.VOTE_DURATION);
        address ballotAddr = ITomiBallotFactory(ballotFactoryAddr).create(msg.sender, _value, endBlockNumber, _subject, _content);
        configBallots[ballotAddr] = _name;
        uint reward = _createdBallot(ballotAddr, T_CONFIG);
        emit ConfigBallotCreated(msg.sender, _name, _value, ballotAddr, reward);
        return ballotAddr;
    }

    function createTokenBallot(address _token, uint _value, uint _amount, bool _wallet, string calldata _subject, string calldata _content) external returns (address) {
        require(!_isDefaultToken(_token), 'TomiGovernance: DEFAULT_LIST_TOKENS_PROPOSAL_DENY');
        uint status = ITokenRegistry(configAddr).tokenStatus(_token);
        require(status == ITokenRegistry(configAddr).PENDING(), 'TomiGovernance: ONLY_ALLOW_PENDING');
        require(_value == ITokenRegistry(configAddr).OPENED() || _value == ITokenRegistry(configAddr).CLOSED(), 'TomiGovernance: INVALID_STATUS');
        require(status != _value, 'TomiGovernance: STATUS_NO_CHANGE');
        require(_amount >= getConfigValue(ConfigNames.PROPOSAL_TGAS_AMOUNT), "TomiGovernance: NOT_ENOUGH_AMOUNT_TO_PROPOSAL");
        if(_amount > 0) {
            _amount = _transferForBallot(_amount, _wallet);
            rewardOf[rewardAddr] = rewardOf[rewardAddr].add(_amount);
        }
        address ballotAddr = _createTokenBallot(T_TOKEN, _token, _value, _subject, _content);
        return ballotAddr;
    }

	function listToken(address _token, uint _amount, bool _wallet, string calldata _subject, string calldata _content) external returns (address) {
        uint status = ITokenRegistry(configAddr).tokenStatus(_token);
        require(status == ITokenRegistry(configAddr).NONE() || status == ITokenRegistry(configAddr).CLOSED(), 'TomiGovernance: LISTED');
	    require(_amount >= getConfigValue(ConfigNames.LIST_TGAS_AMOUNT), "TomiGovernance: NOT_ENOUGH_AMOUNT_TO_LIST");
	    tokenUsers[_token] = msg.sender;
        if(_amount > 0) {
            applyTokenOf[msg.sender][_token] = _transferForBallot(_amount, _wallet);
        }
	    ITokenRegistry(configAddr).registryToken(_token);
        address ballotAddr = _createTokenBallot(T_LIST_TOKEN, _token, ITokenRegistry(configAddr).PENDING(), _subject, _content);
	    emit TokenListed(msg.sender, _token, _amount);
        return ballotAddr;
	}

    function _createTokenBallot(uint _type, address _token, uint _value, string memory _subject, string memory _content) private returns (address) {
        uint endBlockNumber = block.number + getConfigValue(ConfigNames.VOTE_DURATION);
        address ballotAddr = ITomiBallotFactory(ballotFactoryAddr).create(msg.sender, _value, endBlockNumber, _subject, _content);
        uint reward = _createdBallot(ballotAddr, _type);
        ballotOf[ballotAddr] = reward;
        tokenBallots[ballotAddr] = _token;
        emit TokenBallotCreated(msg.sender, _token, _value, ballotAddr, reward);
        return ballotAddr;
    }

    function collectReward(address _ballot) external returns (uint) {
        require(block.number >= ITomiBallot(_ballot).endBlockNumber(), "TomiGovernance: NOT_YET_ENDED");
        require(!collectUsers[_ballot][msg.sender], 'TomiGovernance: REWARD_COLLECTED');
        uint amount = getReward(_ballot);
        _rewardTransfer(_ballot, msg.sender, amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        stakingSupply = stakingSupply.add(amount);
        rewardOf[msg.sender] = rewardOf[msg.sender].sub(amount);
        collectUsers[_ballot][msg.sender] = true;
        emit RewardCollected(msg.sender, _ballot, amount);
    }

    function getReward(address _ballot) public view returns (uint) {
        if (block.number < ITomiBallot(_ballot).endBlockNumber() || collectUsers[_ballot][msg.sender]) {
            return 0;
        }
        uint amount;
        uint shares = ballotOf[_ballot];
        if (ITomiBallot(_ballot).result()) {
            uint extra;
            uint rewardRate = getConfigValue(ConfigNames.VOTE_REWARD_PERCENT);
            if ( rewardRate > 0) {
               extra = shares * rewardRate / ITomiConfig(configAddr).PERCENT_DENOMINATOR();
               shares -= extra;
            }
            if (msg.sender == ITomiBallot(_ballot).proposer()) {
                amount = extra;
            }
        }

        if (ITomiBallot(_ballot).total() > 0) {
            amount += shares * ITomiBallot(_ballot).weight(msg.sender) / ITomiBallot(_ballot).total();
        }
        return amount;
    }

    function addReward(uint _value) external onlyRewarder returns (bool) {
        require(_value > 0, 'TomiGovernance: ADD_REWARD_VALUE_IS_ZERO');
        uint total = IERC20(baseToken).balanceOf(address(this));
        uint diff = total.sub(totalSupply);
        require(_value <= diff, 'TomiGovernance: ADD_REWARD_EXCEED');
        rewardOf[rewardAddr] = rewardOf[rewardAddr].add(_value);
        totalSupply = total;
        emit RewardReceived(rewardAddr, _value);
    }

    function _rewardTransfer(address _from, address _to, uint _value) private returns (bool) {
        require(_value >= 0 && rewardOf[_from] >= _value, 'TomiGovernance: INSUFFICIENT_BALANCE');
        rewardOf[_from] = rewardOf[_from].sub(_value);
        rewardOf[_to] = rewardOf[_to].add(_value);
        emit RewardTransfered(_from, _to, _value);
    }

    function _isDefaultToken(address _token) internal returns (bool) {
        address[] memory tokens = ITomiConfig(configAddr).getDefaultListTokens();
        for(uint i = 0 ; i < tokens.length; i++){
            if (tokens[i] == _token) {
                return true;
            }
        }
        return false;
    }

    function _transferForBallot(uint _amount, bool _wallet) internal returns (uint) {
        if (_wallet) {
            TransferHelper.safeTransferFrom(baseToken, msg.sender, address(this), _amount);
            totalSupply += _amount;
        } else {
            _reduce(msg.sender, _amount);
        }
        return _amount;
    }

    function _createdBallot(address _ballot, uint _type) internal returns (uint) {
        uint reward = rewardOf[rewardAddr];
        ballotOf[_ballot] = reward;
        _rewardTransfer(rewardAddr, _ballot, reward);
        ballots.push(_ballot);
        ballotTypes[_ballot] = _type;
        return reward;
    }

    function ballotCount() external view returns (uint) {
        return ballots.length;
    }

    function _changeAmountPerBlock(uint _value) internal returns (bool) {
        return ITgas(baseToken).changeInterestRatePerBlock(_value);
    }

    function updateTgasGovernor(address _new) external onlyOwner {
        ITgas(baseToken).upgradeGovernance(_new);
    }

    function upgradeApproveReward() external returns (uint) {
        require(rewardOf[rewardAddr] > 0, 'TomiGovernance: UPGRADE_NO_REWARD');
        require(ITomiConfig(configAddr).governor() != address(this), 'TomiGovernance: UPGRADE_NO_CHANGE');
        TransferHelper.safeApprove(baseToken, ITomiConfig(configAddr).governor(), rewardOf[rewardAddr]);
        return rewardOf[rewardAddr]; 
    }

    function receiveReward(address _from, uint _value) external returns (bool) {
        require(_value > 0, 'TomiGovernance: RECEIVE_REWARD_VALUE_IS_ZERO');
        TransferHelper.safeTransferFrom(baseToken, _from, address(this), _value);
        rewardOf[rewardAddr] += _value;
        totalSupply += _value;
        emit RewardReceived(_from, _value);
        return true;
    }

}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity >=0.5.0;

interface ITgas {
    function amountPerBlock() external view returns (uint);
    function changeInterestRatePerBlock(uint value) external returns (bool);
    function getProductivity(address user) external view returns (uint, uint);
    function increaseProductivity(address user, uint value) external returns (bool);
    function decreaseProductivity(address user, uint value) external returns (bool);
    function take() external view returns (uint);
    function takeWithBlock() external view returns (uint, uint);
    function mint() external returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function upgradeImpl(address _newImpl) external;
    function upgradeGovernance(address _newGovernor) external;
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

pragma solidity >=0.5.16;

interface ITokenRegistry {
    function tokenStatus(address _token) external view returns(uint);
    function pairStatus(address tokenA, address tokenB) external view returns (uint);
    function NONE() external view returns(uint);
    function REGISTERED() external view returns(uint);
    function PENDING() external view returns(uint);
    function OPENED() external view returns(uint);
    function CLOSED() external view returns(uint);
    function registryToken(address _token) external returns (bool);
    function publishToken(address _token) external returns (bool);
    function updateToken(address _token, uint _status) external returns (bool);
    function updatePair(address tokenA, address tokenB, uint _status) external returns (bool);
    function tokenCount() external view returns(uint);
    function validTokens() external view returns(address[] memory);
    function iterateValidTokens(uint32 _start, uint32 _end) external view returns (address[] memory);
}

pragma solidity >=0.5.0;

interface ITomiBallot {
    function proposer() external view returns(address);
    function endBlockNumber() external view returns(uint);
    function value() external view returns(uint);
    function result() external view returns(bool);
    function end() external returns (bool);
    function total() external view returns(uint);
    function weight(address user) external view returns (uint);
}

pragma solidity >=0.5.0;

interface ITomiBallotFactory {
    function create(
        address _proposer,
        uint _value,
        uint _endBlockNumber,
        string calldata _subject,
        string calldata _content
    ) external returns (address);
}

pragma solidity >=0.5.0;

interface ITomiConfig {
    function governor() external view returns (address);
    function dev() external view returns (address);
    function PERCENT_DENOMINATOR() external view returns (uint);
    function getConfig(bytes32 _name) external view returns (uint minValue, uint maxValue, uint maxSpan, uint value, uint enable);
    function getConfigValue(bytes32 _name) external view returns (uint);
    function changeConfigValue(bytes32 _name, uint _value) external returns (bool);
    function checkToken(address _token) external view returns(bool);
    function checkPair(address tokenA, address tokenB) external view returns (bool);
    function listToken(address _token) external returns (bool);
    function getDefaultListTokens() external returns (address[] memory);
    function platform() external view returns  (address);
    function addToken(address _token) external returns (bool);
}

pragma solidity >=0.5.16;

library ConfigNames {
    bytes32 public constant PRODUCE_TGAS_RATE = bytes32('PRODUCE_TGAS_RATE');
    bytes32 public constant SWAP_FEE_PERCENT = bytes32('SWAP_FEE_PERCENT');
    bytes32 public constant LIST_TGAS_AMOUNT = bytes32('LIST_TGAS_AMOUNT');
    bytes32 public constant UNSTAKE_DURATION = bytes32('UNSTAKE_DURATION');
    bytes32 public constant REMOVE_LIQUIDITY_DURATION = bytes32('REMOVE_LIQUIDITY_DURATION');
    bytes32 public constant TOKEN_TO_TGAS_PAIR_MIN_PERCENT = bytes32('TOKEN_TO_TGAS_PAIR_MIN_PERCENT');
    bytes32 public constant LIST_TOKEN_FAILURE_BURN_PRECENT = bytes32('LIST_TOKEN_FAILURE_BURN_PRECENT');
    bytes32 public constant LIST_TOKEN_SUCCESS_BURN_PRECENT = bytes32('LIST_TOKEN_SUCCESS_BURN_PRECENT');
    bytes32 public constant PROPOSAL_TGAS_AMOUNT = bytes32('PROPOSAL_TGAS_AMOUNT');
    bytes32 public constant VOTE_DURATION = bytes32('VOTE_DURATION');
    bytes32 public constant VOTE_REWARD_PERCENT = bytes32('VOTE_REWARD_PERCENT');
    bytes32 public constant TOKEN_PENGDING_SWITCH = bytes32('TOKEN_PENGDING_SWITCH');
    bytes32 public constant TOKEN_PENGDING_TIME = bytes32('TOKEN_PENGDING_TIME');
    bytes32 public constant LIST_TOKEN_SWITCH = bytes32('LIST_TOKEN_SWITCH');
    bytes32 public constant DEV_PRECENT = bytes32('DEV_PRECENT');
    bytes32 public constant FEE_GOVERNANCE_REWARD_PERCENT = bytes32('FEE_GOVERNANCE_REWARD_PERCENT');
    bytes32 public constant FEE_LP_REWARD_PERCENT = bytes32('FEE_LP_REWARD_PERCENT');
    bytes32 public constant FEE_FUNDME_REWARD_PERCENT = bytes32('FEE_FUNDME_REWARD_PERCENT');
    bytes32 public constant FEE_LOTTERY_REWARD_PERCENT = bytes32('FEE_LOTTERY_REWARD_PERCENT');
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
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

pragma solidity >=0.5.16;

contract BaseToken {
    address public baseToken;

    // called after deployment
    function initBaseToken(address _baseToken) internal {
        require(baseToken == address(0), 'INITIALIZED');
        require(_baseToken != address(0), 'ADDRESS_IS_ZERO');
        baseToken = _baseToken;  // it should be tgas token address
    }
}

pragma solidity >=0.5.16;

contract Ownable {
    address public owner;

    event OwnerChanged(address indexed _oldOwner, address indexed _newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Ownable: FORBIDDEN');
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), 'Ownable: INVALID_ADDRESS');
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }

}

pragma solidity >=0.5.16;

import '../libraries/TransferHelper.sol';
import '../libraries/SafeMath.sol';
import '../interfaces/IERC20.sol';
import '../interfaces/ITomiConfig.sol';
import '../modules/BaseToken.sol';


contract TgasStaking is BaseToken {
    using SafeMath for uint;

    uint public lockTime;
    uint public totalSupply;
    uint public stakingSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => uint) public allowance;


    constructor (address _baseToken) public {
        initBaseToken(_baseToken);
    }

    function _add(address user, uint value) internal {
        require(value > 0, 'ZERO');
        balanceOf[user] = balanceOf[user].add(value);
        stakingSupply = stakingSupply.add(value);
        allowance[user] = block.number;
    }

    function _reduce(address user, uint value) internal {
        require(balanceOf[user] >= value && value > 0, 'TgasStaking: INSUFFICIENT_BALANCE');
        balanceOf[user] = balanceOf[user].sub(value);
        stakingSupply = stakingSupply.sub(value);
    }

    function deposit(uint _amount) external returns (bool) {
        TransferHelper.safeTransferFrom(baseToken, msg.sender, address(this), _amount);
        _add(msg.sender, _amount);
        totalSupply = IERC20(baseToken).balanceOf(address(this));
        return true;
    }

    function withdraw(uint _amount) external returns (bool) {
        require(block.number > allowance[msg.sender] + lockTime, 'TgasStaking: NOT_DUE');
        TransferHelper.safeTransfer(baseToken, msg.sender, _amount);
        _reduce(msg.sender, _amount);
        totalSupply = IERC20(baseToken).balanceOf(address(this));
        return true;
    }

}