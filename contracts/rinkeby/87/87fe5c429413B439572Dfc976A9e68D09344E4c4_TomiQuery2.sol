// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import '../interfaces/IERC20.sol';
import '../interfaces/ITomiGovernance.sol';
import '../libraries/SafeMath.sol';

/**
 * @title TomiBallot
 * @dev Implements voting process along with vote delegation
 */
contract TomiBallot {
    using SafeMath for uint;

    struct Voter {
        uint256 weight; // weight is accumulated by delegation
        bool voted; // if true, that person already voted
        address delegate; // person delegated to
        uint256 vote; // index of the voted proposal
    }

    mapping(address => Voter) public voters;
    mapping(uint256 => uint256) public proposals;

    address public TOMI;
    address public governor;
    address public proposer;
    uint256 public value;
    uint256 public endBlockNumber;
    bool public ended;
    string public subject;
    string public content;

    uint256 private constant NONE = 0;
    uint256 private constant YES = 1;
    uint256 private constant NO = 2;

    uint256 public total;
    uint256 public createTime;

    modifier onlyGovernor() {
        require(msg.sender == governor, 'TomiBallot: FORBIDDEN');
        _;
    }

    /**
     * @dev Create a new ballot.
     */
    constructor(
        address _TOMI,
        address _proposer,
        uint256 _value,
        uint256 _endBlockNumber,
        address _governor,
        string memory _subject,
        string memory _content
    ) public {
        TOMI = _TOMI;
        proposer = _proposer;
        value = _value;
        endBlockNumber = _endBlockNumber;
        governor = _governor;
        subject = _subject;
        content = _content;
        proposals[YES] = 0;
        proposals[NO] = 0;
        createTime = block.timestamp;
    }

    /**
     * @dev Give 'voter' the right to vote on this ballot.
     * @param voter address of voter
     */
    function _giveRightToVote(address voter) private returns (Voter storage) {
        require(block.number < endBlockNumber, 'Ballot is ended');
        Voter storage sender = voters[voter];
        require(!sender.voted, 'You already voted');
        sender.weight += IERC20(governor).balanceOf(voter);
        require(sender.weight != 0, 'Has no right to vote');
        return sender;
    }

    function _stakeCollateralToVote(uint256 collateral) private returns (bool) {
        uint256 collateralRemain = IERC20(governor).balanceOf(msg.sender);
        uint256 collateralMore = collateral.sub(collateralRemain);
        require(IERC20(TOMI).allowance(msg.sender, address(this)) >= collateralMore, "TomiBallot:Collateral allowance is not enough to vote!");
        IERC20(TOMI).transferFrom(msg.sender, address(this), collateralMore);
        IERC20(TOMI).approve(governor, collateralMore);
        bool success = ITomiGovernance(governor).onBehalfDeposit(msg.sender, collateralMore);
        return success;
    }

    /**
     * @dev Delegate your vote to the voter 'to'.
     * @param to address to which vote is delegated
     */
    function delegate(address to) public {
        Voter storage sender = _giveRightToVote(msg.sender);
        require(to != msg.sender, 'Self-delegation is disallowed');

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, 'Found loop in delegation');
        }
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            proposals[delegate_.vote] += sender.weight;
            total += msg.sender != proposer ? sender.weight: 0;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
            total += msg.sender != proposer ? sender.weight: 0;
        }
    }

    /**
     * @dev Give your vote (including votes delegated to you) to proposal 'proposals[proposal].name'.
     * @param proposal index of proposal in the proposals array
     */
    function vote(uint256 proposal, uint256 collateral) public {
        if (collateral > 0) {
            require(_stakeCollateralToVote(collateral), "TomiBallot:Fail due to stake TOMI as collateral!");
        }

        Voter storage sender = _giveRightToVote(msg.sender);
        require(proposal == YES || proposal == NO, 'Only vote 1 or 2');
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal] += sender.weight;
        
        if (msg.sender != proposer) {
            total += sender.weight;
        }
    }

    function voteByGovernor(address user, uint256 proposal) public onlyGovernor {
        Voter storage sender = _giveRightToVote(user);
        require(proposal == YES || proposal == NO, 'Only vote 1 or 2');
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal] += sender.weight;
        
        if (user != proposer) {
            total += sender.weight;
        }
    }

    /**
     * @dev Computes the winning proposal taking all previous votes into account.
     * @return winningProposal_ index of winning proposal in the proposals array
     */
    function winningProposal() public view returns (uint256) {
        if (proposals[YES] > proposals[NO]) {
            return YES;
        } else if (proposals[YES] < proposals[NO]) {
            return NO;
        } else {
            return NONE;
        }
    }

    function result() public view returns (bool) {
        uint256 winner = winningProposal();
        if (winner == YES) {
            return true;
        }
        return false;
    }

    function end() public onlyGovernor returns (bool) {
        require(block.number >= endBlockNumber, 'ballot not yet ended');
        require(!ended, 'end has already been called');
        ended = true;
        return result();
    }

    function weight(address user) external view returns (uint256) {
        Voter memory voter = voters[user];
        return voter.weight;
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

interface ITomiGovernance {
    function addPair(address _tokenA, address _tokenB) external returns (bool);
    function addReward(uint _value) external returns (bool);
    function deposit(uint _amount) external returns (bool);
    function onBehalfDeposit(address _user, uint _amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import "./TomiBallot.sol";
import "./TomiBallotRevenue.sol";

contract TomiBallotFactory {
    address public TOMI;

    event Created(address indexed proposer, address indexed ballotAddr, uint256 createTime);
    event RevenueCreated(address indexed proposer, address indexed ballotAddr, uint256 createTime);

    constructor(address _TOMI) public {
        TOMI = _TOMI;
    }

    function create(
        address _proposer,
        uint256 _value,
        uint256 _endBlockNumber,
        string calldata _subject,
        string calldata _content
    ) external returns (address) {
        require(_value >= 0, 'TomiBallotFactory: INVALID_PARAMTERS');
        address ballotAddr = address(
            new TomiBallot(TOMI, _proposer, _value, _endBlockNumber, msg.sender, _subject, _content)
        );
        emit Created(_proposer, ballotAddr, block.timestamp);
        return ballotAddr;
    }

    function createShareRevenue(
        address _proposer,
        uint256 _endBlockNumber,
        string calldata _subject,
        string calldata _content
    ) external returns (address) {
        address ballotAddr = address(
            new TomiBallotRevenue(TOMI, _proposer, _endBlockNumber, msg.sender, _subject, _content)
        );
        emit RevenueCreated(_proposer, ballotAddr, block.timestamp);
        return ballotAddr;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import '../interfaces/IERC20.sol';
import '../interfaces/ITomiGovernance.sol';
import '../libraries/SafeMath.sol';

/**
 * @title TomiBallot
 * @dev Implements voting process along with vote delegation
 */
contract TomiBallotRevenue {
    using SafeMath for uint;

    struct Participator {
        uint256 weight; // weight is accumulated by delegation
        bool participated; // if true, that person already voted
        address delegate; // person delegated to
    }

    mapping(address => Participator) public participators;

    address public TOMI;
    address public governor;
    address public proposer;
    uint256 public endBlockNumber;
    bool public ended;
    string public subject;
    string public content;


    uint256 public total;
    uint256 public createTime;

    modifier onlyGovernor() {
        require(msg.sender == governor, 'TomiBallot: FORBIDDEN');
        _;
    }

    /**
     * @dev Create a new ballot.
     */
    constructor(
        address _TOMI,
        address _proposer,
        uint256 _endBlockNumber,
        address _governor,
        string memory _subject,
        string memory _content
    ) public {
        TOMI = _TOMI;
        proposer = _proposer;
        endBlockNumber = _endBlockNumber;
        governor = _governor;
        subject = _subject;
        content = _content;
        createTime = block.timestamp;
    }


    /**
     * @dev Give 'participator' the right to vote on this ballot.
     * @param participator address of participator
     */
    function _giveRightToJoin(address participator) private returns (Participator storage) {
        require(block.number < endBlockNumber, 'Ballot is ended');
        Participator storage sender = participators[participator];
        require(!sender.participated, 'You already participate in');
        sender.weight += IERC20(governor).balanceOf(participator);
        require(sender.weight != 0, 'Has no right to participate in');
        return sender;
    }

    function _stakeCollateralToJoin(uint256 collateral) private returns (bool) {
        uint256 collateralRemain = IERC20(governor).balanceOf(msg.sender);
        uint256 collateralMore = collateral.sub(collateralRemain);
        require(IERC20(TOMI).allowance(msg.sender, address(this)) >= collateralMore, "TomiBallot:Collateral allowance is not enough to vote!");
        IERC20(TOMI).transferFrom(msg.sender, address(this), collateralMore);
        IERC20(TOMI).approve(governor, collateralMore);
        bool success = ITomiGovernance(governor).onBehalfDeposit(msg.sender, collateralMore);
        return success;
    }

    /**
     * @dev Delegate your vote to the voter 'to'.
     * @param to address to which vote is delegated
     */
    function delegate(address to) public {
        Participator storage sender = _giveRightToJoin(msg.sender);
        require(to != msg.sender, 'Self-delegation is disallowed');

        while (participators[to].delegate != address(0)) {
            to = participators[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, 'Found loop in delegation');
        }
        sender.participated = true;
        sender.delegate = to;
        Participator storage delegate_ = participators[to];
        if (delegate_.participated) {
            // If the delegate already voted,
            // directly add to the number of votes
            total += msg.sender != proposer ? sender.weight: 0;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
            total += msg.sender != proposer ? sender.weight: 0;
        }
    }

    /**
     * @dev Give your vote (including votes delegated to you) to proposal 'proposals[proposal].name'.
     */
    function participate(uint256 collateral) public {
        if (collateral > 0) {
            require(_stakeCollateralToJoin(collateral), "TomiBallotRevenue:Fail due to stake TOMI as collateral!");
        }

        Participator storage sender = _giveRightToJoin(msg.sender);
        sender.participated = true;

        if (msg.sender != proposer) {
            total += sender.weight;
        }
    }

    function participateByGovernor(address user) public onlyGovernor {
        Participator storage sender = _giveRightToJoin(user);
        sender.participated = true;

        if (msg.sender != proposer) {
            total += sender.weight;
        }
    }

    function end() public onlyGovernor returns (bool) {
        require(block.number >= endBlockNumber, 'ballot not yet ended');
        require(!ended, 'end has already been called');
        ended = true;
        return ended;
    }

    function weight(address user) external view returns (uint256) {
        Participator memory participator = participators[user];
        return participator.weight;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;
import './modules/Ownable.sol';
import './interfaces/ITgas.sol';
import './interfaces/ITomiFactory.sol';
import './interfaces/IERC20.sol';
import './interfaces/ITomiPair.sol';
import './libraries/TomiSwapLibrary.sol';
import './libraries/SafeMath.sol';

contract TomiTransferListener is Ownable {
    uint256 public version = 1;
    address public TGAS;
    address public PLATFORM;
    address public WETH;
    address public FACTORY;
    address public admin;

    mapping(address => uint) public pairWeights;

    event Transfer(address indexed from, address indexed to, address indexed token, uint256 amount);
    event WeightChanged(address indexed pair, uint weight);

    function initialize(
        address _TGAS,
        address _FACTORY,
        address _WETH,
        address _PLATFORM,
        address _admin
    ) external onlyOwner {
        require(
            _TGAS != address(0) && _FACTORY != address(0) && _WETH != address(0) && _PLATFORM != address(0),
            'TOMI TRANSFER LISTENER : INPUT ADDRESS IS ZERO'
        );
        TGAS = _TGAS;
        FACTORY = _FACTORY;
        WETH = _WETH;
        PLATFORM = _PLATFORM;
        admin = _admin;
    }

    function changeAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    function updateTGASImpl(address _newImpl) external onlyOwner {
        ITgas(TGAS).upgradeImpl(_newImpl);
    }

    function updatePairPowers(address[] calldata _pairs, uint[] calldata _weights) external {
        require(msg.sender == admin, 'TOMI TRANSFER LISTENER: ADMIN PERMISSION');
        require(_pairs.length == _weights.length, "TOMI TRANSFER LISTENER: INVALID PARAMS");

        for(uint i = 0;i < _weights.length;i++) {
            pairWeights[_pairs[i]] = _weights[i];
            _setProdutivity(_pairs[i]);
            emit WeightChanged(_pairs[i], _weights[i]);
        }
    }


    function _setProdutivity(address _pair) internal {
        (uint256 lastProdutivity, ) = ITgas(TGAS).getProductivity(_pair);
        address token0 = ITomiPair(_pair).token0();
        address token1 = ITomiPair(_pair).token1();
        (uint reserve0, uint reserve1, ) = ITomiPair(_pair).getReserves();
        uint currentProdutivity = 0;
        if(token0 == TGAS) {
            currentProdutivity = reserve0 * pairWeights[_pair];
        } else if(token1 == TGAS) {
            currentProdutivity = reserve1 * pairWeights[_pair];
        }

        if(lastProdutivity != currentProdutivity) {
            if(lastProdutivity > 0) {
                ITgas(TGAS).decreaseProductivity(_pair, lastProdutivity);
            } 

            if(currentProdutivity > 0) {
                ITgas(TGAS).increaseProductivity(_pair, currentProdutivity);
            }
        }
    }

    function upgradeProdutivity(address fromPair, address toPair) external {
        require(msg.sender == PLATFORM, 'TOMI TRANSFER LISTENER: PERMISSION');
        (uint256 fromPairPower, ) = ITgas(TGAS).getProductivity(fromPair);
        (uint256 toPairPower, ) = ITgas(TGAS).getProductivity(toPair);
        if(fromPairPower > 0 && toPairPower == 0) {
            ITgas(TGAS).decreaseProductivity(fromPair, fromPairPower);
            ITgas(TGAS).increaseProductivity(toPair, fromPairPower);
        }
    }

    function transferNotify(
        address from,
        address to,
        address token,
        uint256 amount
    ) external returns (bool) {
        require(msg.sender == PLATFORM, 'TOMI TRANSFER LISTENER: PERMISSION');
        if(ITomiFactory(FACTORY).isPair(from) && token == TGAS) {
            _setProdutivity(from);
        }

        if(ITomiFactory(FACTORY).isPair(to) && token == TGAS) {
            _setProdutivity(to);
        }

        emit Transfer(from, to, token, amount);
        return true;
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

pragma solidity >=0.5.0;

interface ITomiFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function contractCodeHash() external view returns (bytes32);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function isPair(address pair) external view returns (bool);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function playerPairs(address player, uint index) external view returns (address pair);
    function getPlayerPairCount(address player) external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function addPlayerPair(address player, address _pair) external returns (bool);
}

pragma solidity >=0.5.0;

interface ITomiPair {
  
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function totalSupply() external view returns (uint);
    function balanceOf(address) external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address from, address to, uint amount) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address tokenA, address tokenB, address platform, address tgas) external;
    function swapFee(uint amount, address token, address to) external ;
    function queryReward() external view returns (uint rewardAmount, uint blockNumber);
    function mintReward() external returns (uint rewardAmount);
    function getTGASReserve() external view returns (uint);
}

pragma solidity >=0.5.0;

import '../interfaces/ITomiPair.sol';
import '../interfaces/ITomiFactory.sol';
import "./SafeMath.sol";

library TomiSwapLibrary {
    using SafeMath for uint;

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'TomiSwapLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'TomiSwapLibrary: ZERO_ADDRESS');
    }

    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        bytes32 rawAddress = keccak256(
        abi.encodePacked(
            bytes1(0xff),
            factory,
            salt,
            ITomiFactory(factory).contractCodeHash()
            )
        );
        return address(bytes20(rawAddress << 96));
    }

    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = ITomiPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
    
    function quoteEnhance(address factory, address tokenA, address tokenB, uint amountA) internal view returns(uint amountB) {
        (uint reserveA, uint reserveB) = getReserves(factory, tokenA, tokenB);
        return quote(amountA, reserveA, reserveB);
    }

    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'TomiSwapLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'TomiSwapLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'TomiSwapLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'TomiSwapLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = amountIn.mul(reserveOut);
        uint denominator = reserveIn.add(amountIn);
        amountOut = numerator / denominator;
    }
    
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'TomiSwapLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'TomiSwapLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut);
        uint denominator = reserveOut.sub(amountOut);
        amountIn = (numerator / denominator).add(1);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import './libraries/ConfigNames.sol';
import './libraries/SafeMath.sol';
import './libraries/TransferHelper.sol';
import './libraries/TomiSwapLibrary.sol';
import './interfaces/IWETH.sol';
import './interfaces/ITomiGovernance.sol';
import './interfaces/ITomiConfig.sol';
import './interfaces/IERC20.sol';
import './interfaces/ITomiFactory.sol';
import './interfaces/ITomiPair.sol';
import './interfaces/ITomiPool.sol';
import './modules/Ownable.sol';
import './modules/ReentrancyGuard.sol';
import './interfaces/ITomiTransferListener.sol';
import './interfaces/ITokenRegistry.sol';

contract TomiPlatform is Ownable {
    uint256 public version = 1;
    address public TOMI;
    address public CONFIG;
    address public FACTORY;
    address public WETH;
    address public GOVERNANCE;
    address public TRANSFER_LISTENER;
    address public POOL;
    uint256 public constant PERCENT_DENOMINATOR = 10000;

    bool public isPause;

    event AddLiquidity(
        address indexed player,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB
    );
    event RemoveLiquidity(
        address indexed player,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB
    );
    event SwapToken(
        address indexed receiver,
        address indexed fromToken,
        address indexed toToken,
        uint256 inAmount,
        uint256 outAmount
    );

    receive() external payable {
        assert(msg.sender == WETH);
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'TOMI PLATFORM : EXPIRED');
        _;
    }

    modifier noneTokenCall() {
        require(ITokenRegistry(CONFIG).tokenStatus(msg.sender) == 0, 'TOMI PLATFORM : ILLEGAL CALL');
        _;
    }

    function initialize(
        address _TOMI,
        address _CONFIG,
        address _FACTORY,
        address _WETH,
        address _GOVERNANCE,
        address _TRANSFER_LISTENER,
        address _POOL
    ) external onlyOwner {
        TOMI = _TOMI;
        CONFIG = _CONFIG;
        FACTORY = _FACTORY;
        WETH = _WETH;
        GOVERNANCE = _GOVERNANCE;
        TRANSFER_LISTENER = _TRANSFER_LISTENER;
        POOL = _POOL;
    }

    function pause() external onlyOwner {
        isPause = true;
    }

    function resume() external onlyOwner {
        isPause = false;
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB) {
        if (ITomiFactory(FACTORY).getPair(tokenA, tokenB) == address(0)) {
            ITomiConfig(CONFIG).addToken(tokenA);
            ITomiConfig(CONFIG).addToken(tokenB);
            ITomiFactory(FACTORY).createPair(tokenA, tokenB);
        }
        require(
            ITomiConfig(CONFIG).checkPair(tokenA, tokenB),
            'TOMI PLATFORM : ADD LIQUIDITY PAIR CONFIG CHECK FAIL'
        );
        (uint256 reserveA, uint256 reserveB) = TomiSwapLibrary.getReserves(FACTORY, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = TomiSwapLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'TOMI PLATFORM : INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = TomiSwapLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'TOMI PLATFORM : INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
        ITomiFactory(FACTORY).addPlayerPair(msg.sender, ITomiFactory(FACTORY).getPair(tokenA, tokenB));
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    )
        external
        ensure(deadline)
        returns (
            uint256 _amountA,
            uint256 _amountB,
            uint256 _liquidity
        )
{
        require(!isPause, "TOMI PAUSED");
        (_amountA, _amountB) = _addLiquidity(tokenA, tokenB, amountA, amountB, amountAMin, amountBMin);
        address pair = TomiSwapLibrary.pairFor(FACTORY, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, _amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, _amountB);

        // notify pool
        ITomiPool(POOL).preProductivityChanged(pair, msg.sender);
        _liquidity = ITomiPair(pair).mint(msg.sender);
        ITomiPool(POOL).postProductivityChanged(pair, msg.sender);

        _transferNotify(msg.sender, pair, tokenA, _amountA);
        _transferNotify(msg.sender, pair, tokenB, _amountB);
        emit AddLiquidity(msg.sender, tokenA, tokenB, _amountA, _amountB);
    }

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
    )
        external
        payable
        ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        require(!isPause, "TOMI PAUSED");
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = TomiSwapLibrary.pairFor(FACTORY, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));

        // notify pool
        ITomiPool(POOL).preProductivityChanged(pair, msg.sender);
        liquidity = ITomiPair(pair).mint(msg.sender);
        ITomiPool(POOL).postProductivityChanged(pair, msg.sender);

        _transferNotify(msg.sender, pair, WETH, amountETH);
        _transferNotify(msg.sender, pair, token, amountToken);
        emit AddLiquidity(msg.sender, token, WETH, amountToken, amountETH);
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        require(!isPause, "TOMI PAUSED");
        address pair = TomiSwapLibrary.pairFor(FACTORY, tokenA, tokenB);
        uint256 _liquidity = liquidity;
        address _tokenA = tokenA;
        address _tokenB = tokenB;

        // notify pool
        ITomiPool(POOL).preProductivityChanged(pair, msg.sender);
        (uint256 amount0, uint256 amount1) = ITomiPair(pair).burn(msg.sender, to, _liquidity);
        ITomiPool(POOL).postProductivityChanged(pair, msg.sender);

        (address token0, ) = TomiSwapLibrary.sortTokens(_tokenA, _tokenB);
        (amountA, amountB) = _tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        _transferNotify(pair, to, _tokenA, amountA);
        _transferNotify(pair, to, _tokenB, amountB);
        require(amountA >= amountAMin, 'TOMI PLATFORM : INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'TOMI PLATFORM : INSUFFICIENT_B_AMOUNT');
        emit RemoveLiquidity(msg.sender, _tokenA, _tokenB, amountA, amountB);
    }

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
        require(!isPause, "TOMI PAUSED");
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
        _transferNotify(address(this), to, token, amountToken);
        _transferNotify(address(this), to, WETH, amountETH);
    }

    function _getAmountsOut(
        uint256 amount,
        address[] memory path,
        uint256 percent
    ) internal view returns (uint256[] memory amountOuts) {
        amountOuts = new uint256[](path.length);
        amountOuts[0] = amount;
        for (uint256 i = 0; i < path.length - 1; i++) {
            address inPath = path[i];
            address outPath = path[i + 1];
            (uint256 reserveA, uint256 reserveB) = TomiSwapLibrary.getReserves(FACTORY, inPath, outPath);
            uint256 outAmount = SafeMath.mul(amountOuts[i], SafeMath.sub(PERCENT_DENOMINATOR, percent));
            amountOuts[i + 1] = TomiSwapLibrary.getAmountOut(outAmount / PERCENT_DENOMINATOR, reserveA, reserveB);
        }
    }

    function _getAmountsIn(
        uint256 amount,
        address[] memory path,
        uint256 percent
    ) internal view returns (uint256[] memory amountIn) {
        amountIn = new uint256[](path.length);
        amountIn[path.length - 1] = amount;
        for (uint256 i = path.length - 1; i > 0; i--) {
            address inPath = path[i - 1];
            address outPath = path[i];
            (uint256 reserveA, uint256 reserveB) = TomiSwapLibrary.getReserves(FACTORY, inPath, outPath);
            uint256 inAmount = TomiSwapLibrary.getAmountIn(amountIn[i], reserveA, reserveB);
            amountIn[i - 1] = SafeMath.add(
                SafeMath.mul(inAmount, PERCENT_DENOMINATOR) / SafeMath.sub(PERCENT_DENOMINATOR, percent),
                1
            );
        }
        amountIn = _getAmountsOut(amountIn[0], path, percent);
    }

    function swapPrecondition(address token) public view returns (bool) {
        if (token == TOMI || token == WETH) return true;
        uint256 percent = ITomiConfig(CONFIG).getConfigValue(ConfigNames.TOKEN_TO_TGAS_PAIR_MIN_PERCENT);
        if (!existPair(WETH, TOMI)) return false;
        if (!existPair(TOMI, token)) return false;
        if (!(ITomiConfig(CONFIG).checkPair(TOMI, token) && ITomiConfig(CONFIG).checkPair(WETH, token))) return false;
        if (!existPair(WETH, token)) return true;
        if (percent == 0) return true;
        (uint256 reserveTOMI, ) = TomiSwapLibrary.getReserves(FACTORY, TOMI, token);
        (uint256 reserveWETH, ) = TomiSwapLibrary.getReserves(FACTORY, WETH, token);
        (uint256 reserveWETH2, uint256 reserveTOMI2) = TomiSwapLibrary.getReserves(FACTORY, WETH, TOMI);
        uint256 tomiValue = SafeMath.mul(reserveTOMI, reserveWETH2) / reserveTOMI2;
        uint256 limitValue = SafeMath.mul(SafeMath.add(tomiValue, reserveWETH), percent) / PERCENT_DENOMINATOR;
        return tomiValue >= limitValue;
    }
         
    function checkPath(address _path, address[] memory _paths) public pure returns (bool) {
        uint count;
        for(uint i; i<_paths.length; i++) {
            if(_paths[i] == _path) {
                count++;
            }
        }
        if(count == 1) {
            return true;
        } else {
            return false;
        }
    }

    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal {
        require(!isPause, "TOMI PAUSED");
        require(swapPrecondition(path[path.length - 1]), 'TOMI PLATFORM : CHECK TOMI/TOKEN TO VALUE FAIL');
        for (uint256 i; i < path.length - 1; i++) {
            require(checkPath(path[i], path) && checkPath(path[i + 1], path), 'DEMAX PLATFORM : INVALID PATH');
            (address input, address output) = (path[i], path[i + 1]);
            require(swapPrecondition(input), 'TOMI PLATFORM : CHECK TOMI/TOKEN VALUE FROM FAIL');
            require(ITomiConfig(CONFIG).checkPair(input, output), 'TOMI PLATFORM : SWAP PAIR CONFIG CHECK FAIL');
            (address token0, address token1) = TomiSwapLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2 ? TomiSwapLibrary.pairFor(FACTORY, output, path[i + 2]) : _to;

            // add k check
            address pair = TomiSwapLibrary.pairFor(FACTORY, input, output);
            (uint reserve0, uint resereve1, ) = ITomiPair(pair).getReserves();
            uint kBefore = SafeMath.mul(reserve0, resereve1);

            ITomiPair(pair).swap(amount0Out, amount1Out, to, new bytes(0));

            (reserve0, resereve1, ) = ITomiPair(pair).getReserves();
            uint kAfter = SafeMath.mul(reserve0, resereve1);
            require(kBefore <= kAfter, "Burger K");

            if (amount0Out > 0)
                _transferNotify(TomiSwapLibrary.pairFor(FACTORY, input, output), to, token0, amount0Out);
            if (amount1Out > 0)
                _transferNotify(TomiSwapLibrary.pairFor(FACTORY, input, output), to, token1, amount1Out);
        }
        emit SwapToken(_to, path[0], path[path.length - 1], amounts[0], amounts[path.length - 1]);
    }

    function _swapFee(
        uint256[] memory amounts,
        address[] memory path,
        uint256 percent
    ) internal {
        for (uint256 i = 0; i < path.length - 1; i++) {
            uint256 fee = SafeMath.mul(amounts[i], percent) / PERCENT_DENOMINATOR;
            address input = path[i];
            address output = path[i + 1];
            address currentPair = TomiSwapLibrary.pairFor(FACTORY, input, output);
            if (input == TOMI) {
                ITomiPair(currentPair).swapFee(fee, TOMI, POOL);
                _transferNotify(currentPair, POOL, TOMI, fee);
            } else {
                ITomiPair(currentPair).swapFee(fee, input, TomiSwapLibrary.pairFor(FACTORY, input, TOMI));
                (uint256 reserveIn, uint256 reserveTOMI) = TomiSwapLibrary.getReserves(FACTORY, input, TOMI);
                uint256 feeOut = TomiSwapLibrary.getAmountOut(fee, reserveIn, reserveTOMI);
                ITomiPair(TomiSwapLibrary.pairFor(FACTORY, input, TOMI)).swapFee(feeOut, TOMI, POOL);
                _transferNotify(currentPair, TomiSwapLibrary.pairFor(FACTORY, input, TOMI), input, fee);
                _transferNotify(TomiSwapLibrary.pairFor(FACTORY, input, TOMI), POOL, TOMI, feeOut);
                fee = feeOut;
            }
            if (fee > 0) ITomiPool(POOL).addRewardFromPlatform(currentPair, fee);
        }
    }

    function _getSwapFeePercent() internal view returns (uint256) {
        return ITomiConfig(CONFIG).getConfigValue(ConfigNames.SWAP_FEE_PERCENT);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {

        uint256 percent = _getSwapFeePercent();
        amounts = _getAmountsOut(amountIn, path, percent);
        require(amounts[amounts.length - 1] >= amountOutMin, 'TOMI PLATFORM : INSUFFICIENT_OUTPUT_AMOUNT');
        address pair = TomiSwapLibrary.pairFor(FACTORY, path[0], path[1]);
        _innerTransferFrom(
            path[0],
            msg.sender,
            pair,
            SafeMath.mul(amountIn, SafeMath.sub(PERCENT_DENOMINATOR, percent)) / PERCENT_DENOMINATOR
        );
        _swap(amounts, path, to);
        _innerTransferFrom(path[0], msg.sender, pair, SafeMath.mul(amounts[0], percent) / PERCENT_DENOMINATOR);
        _swapFee(amounts, path, percent);
    }

    function _innerTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        TransferHelper.safeTransferFrom(token, from, to, amount);
        _transferNotify(from, to, token, amount);
    }

    function _innerTransferWETH(address to, uint256 amount) internal {
        assert(IWETH(WETH).transfer(to, amount));
        _transferNotify(address(this), to, WETH, amount);
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable ensure(deadline) returns (uint256[] memory amounts) {
        require(path[0] == WETH, 'TOMI PLATFORM : INVALID_PATH');
        uint256 percent = _getSwapFeePercent();
        amounts = _getAmountsOut(msg.value, path, percent);
        require(amounts[amounts.length - 1] >= amountOutMin, 'TOMI PLATFORM : INSUFFICIENT_OUTPUT_AMOUNT');
        address pair = TomiSwapLibrary.pairFor(FACTORY, path[0], path[1]);
        IWETH(WETH).deposit{
            value: SafeMath.mul(amounts[0], SafeMath.sub(PERCENT_DENOMINATOR, percent)) / PERCENT_DENOMINATOR
        }();
        _innerTransferWETH(
            pair,
            SafeMath.mul(amounts[0], SafeMath.sub(PERCENT_DENOMINATOR, percent)) / PERCENT_DENOMINATOR
        );
        _swap(amounts, path, to);

        IWETH(WETH).deposit{value: SafeMath.mul(amounts[0], percent) / PERCENT_DENOMINATOR}();
        _innerTransferWETH(pair, SafeMath.mul(amounts[0], percent) / PERCENT_DENOMINATOR);
        _swapFee(amounts, path, percent);
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WETH, 'TOMI PLATFORM : INVALID_PATH');
        uint256 percent = _getSwapFeePercent();
        amounts = _getAmountsOut(amountIn, path, percent);
        require(amounts[amounts.length - 1] >= amountOutMin, 'TOMI PLATFORM : INSUFFICIENT_OUTPUT_AMOUNT');
        address pair = TomiSwapLibrary.pairFor(FACTORY, path[0], path[1]);
        _innerTransferFrom(
            path[0],
            msg.sender,
            pair,
            SafeMath.mul(amountIn, SafeMath.sub(PERCENT_DENOMINATOR, percent)) / PERCENT_DENOMINATOR
        );
        _swap(amounts, path, address(this));

        _innerTransferFrom(path[0], msg.sender, pair, SafeMath.mul(amounts[0], percent) / PERCENT_DENOMINATOR);
        _swapFee(amounts, path, percent);

        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        uint256 percent = _getSwapFeePercent();
        amounts = _getAmountsIn(amountOut, path, percent);
        require(amounts[0] <= amountInMax, 'TOMI PLATFORM : EXCESSIVE_INPUT_AMOUNT');
        address pair = TomiSwapLibrary.pairFor(FACTORY, path[0], path[1]);

        _innerTransferFrom(
            path[0],
            msg.sender,
            pair,
            SafeMath.mul(amounts[0], SafeMath.sub(PERCENT_DENOMINATOR, percent)) / PERCENT_DENOMINATOR
        );
        _swap(amounts, path, to);
        _innerTransferFrom(path[0], msg.sender, pair, SafeMath.mul(amounts[0], percent) / PERCENT_DENOMINATOR);
        _swapFee(amounts, path, percent);
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WETH, 'TOMI PLATFORM : INVALID_PATH');
        uint256 percent = _getSwapFeePercent();
        amounts = _getAmountsIn(amountOut, path, percent);
        require(amounts[0] <= amountInMax, 'TOMI PLATFORM : EXCESSIVE_INPUT_AMOUNT');
        address pair = TomiSwapLibrary.pairFor(FACTORY, path[0], path[1]);
        _innerTransferFrom(
            path[0],
            msg.sender,
            pair,
            SafeMath.mul(amounts[0], SafeMath.sub(PERCENT_DENOMINATOR, percent)) / PERCENT_DENOMINATOR
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);

        _innerTransferFrom(path[0], msg.sender, pair, SafeMath.mul(amounts[0], percent) / PERCENT_DENOMINATOR);
        _swapFee(amounts, path, percent);
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable ensure(deadline) returns (uint256[] memory amounts) {
        require(path[0] == WETH, 'TOMI PLATFORM : INVALID_PATH');
        uint256 percent = _getSwapFeePercent();
        amounts = _getAmountsIn(amountOut, path, percent);
        require(amounts[0] <= msg.value, 'TOMI PLATFORM : EXCESSIVE_INPUT_AMOUNT');

        IWETH(WETH).deposit{
            value: SafeMath.mul(amounts[0], SafeMath.sub(PERCENT_DENOMINATOR, percent)) / PERCENT_DENOMINATOR
        }();
        address pair = TomiSwapLibrary.pairFor(FACTORY, path[0], path[1]);
        _innerTransferWETH(
            pair,
            SafeMath.mul(amounts[0], SafeMath.sub(PERCENT_DENOMINATOR, percent)) / PERCENT_DENOMINATOR
        );
        _swap(amounts, path, to);

        IWETH(WETH).deposit{value: SafeMath.mul(amounts[0], percent) / PERCENT_DENOMINATOR}();
        _innerTransferWETH(pair, SafeMath.mul(amounts[0], percent) / PERCENT_DENOMINATOR);
        _swapFee(amounts, path, percent);
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    function _transferNotify(
        address from,
        address to,
        address token,
        uint256 amount
    ) internal {
        ITomiTransferListener(TRANSFER_LISTENER).transferNotify(from, to, token, amount);
    }

    function existPair(address tokenA, address tokenB) public view returns (bool) {
        return ITomiFactory(FACTORY).getPair(tokenA, tokenB) != address(0);
    }

    function getReserves(address tokenA, address tokenB) public view returns (uint256, uint256) {
        return TomiSwapLibrary.getReserves(FACTORY, tokenA, tokenB);
    }

    function pairFor(address tokenA, address tokenB) public view returns (address) {
        return TomiSwapLibrary.pairFor(FACTORY, tokenA, tokenB);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public view returns (uint256 amountOut) {
        uint256 percent = _getSwapFeePercent();
        uint256 amount = SafeMath.mul(amountIn, SafeMath.sub(PERCENT_DENOMINATOR, percent)) / PERCENT_DENOMINATOR;
        return TomiSwapLibrary.getAmountOut(amount, reserveIn, reserveOut);
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public view returns (uint256 amountIn) {
        uint256 percent = _getSwapFeePercent();
        uint256 amount = TomiSwapLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
        return SafeMath.mul(amount, PERCENT_DENOMINATOR) / SafeMath.sub(PERCENT_DENOMINATOR, percent);
    }

    function getAmountsOut(uint256 amountIn, address[] memory path) public view returns (uint256[] memory amounts) {
        uint256 percent = _getSwapFeePercent();
        return _getAmountsOut(amountIn, path, percent);
    }

    function getAmountsIn(uint256 amountOut, address[] memory path) public view returns (uint256[] memory amounts) {
        uint256 percent = _getSwapFeePercent();
        return _getAmountsIn(amountOut, path, percent);
    }

    function migrateLiquidity(address pair, address tokenA, address tokenB, address[] calldata users) external onlyOwner {
        if (ITomiFactory(FACTORY).getPair(tokenA, tokenB) == address(0)) {
            ITomiFactory(FACTORY).createPair(tokenA, tokenB);
        }
        address newPair = ITomiFactory(FACTORY).getPair(tokenA, tokenB);
        for(uint i = 0; i < users.length; i++) {
            uint liquidity = ITomiPair(pair).balanceOf(users[i]);
            if(liquidity > 0) {
                ITomiPair(pair).burn(users[i], newPair, liquidity);
                ITomiPair(newPair).mint(users[i]);
                ITomiFactory(FACTORY).addPlayerPair(users[i], newPair);
            }
        }

        ITomiTransferListener(TRANSFER_LISTENER).upgradeProdutivity(pair, newPair);    

    }
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

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
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

pragma solidity >=0.5.0;

interface ITomiPool {
    function addRewardFromPlatform(address _pair, uint _amount) external;
    function preProductivityChanged(address _pair, address _user) external;
    function postProductivityChanged(address _pair, address _user) external;
}

/**
 *Submitted for verification at BscScan.com on 2021-06-30
*/

pragma solidity >=0.6.6;

interface IDemaxTransferListener {
    function transferNotify(address from, address to, address token, uint amount)  external returns (bool);
    function upgradeProdutivity(address fromPair, address toPair) external;
}
// Dependency file: contracts/modules/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

// pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

pragma solidity >=0.6.6;

interface ITomiTransferListener {
    function transferNotify(address from, address to, address token, uint amount)  external returns (bool);
    function upgradeProdutivity(address fromPair, address toPair) external;
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import './interfaces/ITomiConfig.sol';
import './interfaces/ITomiBallotFactory.sol';
import './interfaces/ITomiBallot.sol';
import './interfaces/ITomiBallotRevenue.sol';
import './interfaces/ITgas.sol';
import './interfaces/ITokenRegistry.sol';
import './libraries/ConfigNames.sol';
import './libraries/TransferHelper.sol';
import './modules/TgasStaking.sol';
import './modules/Ownable.sol';
import './libraries/SafeMath.sol';

import 'hardhat/console.sol';

contract TomiGovernance is TgasStaking, Ownable {
    using SafeMath for uint;

    uint public version = 1;
    address public configAddr;
    address public ballotFactoryAddr;
    address public rewardAddr;

    uint public T_CONFIG = 1;
    uint public T_LIST_TOKEN = 2;
    uint public T_TOKEN = 3;
    uint public T_SNAPSHOT = 4;
    uint public T_REVENUE = 5;

    bytes32 REVENUE_PROPOSAL = bytes32('REVENUE_PROPOSAL');
    bytes32 SNAPSHOT_PROPOSAL = bytes32('SNAPSHOT_PROPOSAL');

    mapping(address => uint) public ballotTypes;
    mapping(address => bytes32) public configBallots;
    mapping(address => address) public tokenBallots;
    mapping(address => uint) public rewardOf;
    mapping(address => uint) public ballotOf;
    mapping(address => mapping(address => uint)) public applyTokenOf;
    mapping(address => mapping(address => bool)) public collectUsers;
    mapping(address => address) public tokenUsers;

    address[] public ballots;
    address[] public revenueBallots;

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

    function vote(address _ballot, uint256 _proposal, uint256 _collateral) external {
        require(configBallots[_ballot] != REVENUE_PROPOSAL, "TomiGovernance::Fail due to wrong ballot");
        
        uint256 collateralRemain = balanceOf[msg.sender];
        uint256 collateralMore = _collateral.sub(collateralRemain);
        
        if (collateralMore > 0) {
            _transferForBallot(collateralMore, true);
        }
        ITomiBallot(_ballot).voteByGovernor(msg.sender, _proposal);
    }

    function participate(address _ballot, uint256 _collateral) external {
        require(configBallots[_ballot] == REVENUE_PROPOSAL, "TomiGovernance::Fail due to wrong ballot");
        
        uint256 collateralRemain = balanceOf[msg.sender];
        uint256 collateralMore = _collateral.sub(collateralRemain);

        if (collateralMore > 0) {
            _transferForBallot(collateralMore, true);
        }
        ITomiBallotRevenue(_ballot).participateByGovernor(msg.sender);
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

    function createRevenueBallot(uint _amount, bool _wallet, string calldata _subject, string calldata _content) external returns (address) {
        require(_amount >= getConfigValue(ConfigNames.PROPOSAL_TGAS_AMOUNT), "TomiGovernance: NOT_ENOUGH_AMOUNT_TO_PROPOSAL");
        if(_amount > 0) {
            _amount = _transferForBallot(_amount, _wallet);
            // rewardOf[rewardAddr] = rewardOf[rewardAddr].add(_amount);
        }

        require(balanceOf[msg.sender] >= getConfigValue(ConfigNames.PROPOSAL_TGAS_AMOUNT), "TomiGovernance: COLLATERAL_NOT_ENOUGH_AMOUNT_TO_PROPOSAL");

        uint endBlockNumber = block.number + getConfigValue(ConfigNames.VOTE_DURATION);
        address ballotAddr = ITomiBallotFactory(ballotFactoryAddr).createShareRevenue(msg.sender, endBlockNumber, _subject, _content);
        configBallots[ballotAddr] = REVENUE_PROPOSAL;
        uint reward = _createdBallot(ballotAddr, T_REVENUE);
        emit ConfigBallotCreated(msg.sender, REVENUE_PROPOSAL, 0, ballotAddr, reward);
        return ballotAddr;
    }

    function createSnapshotBallot(uint _amount, bool _wallet, string calldata _subject, string calldata _content) external returns (address) {
        require(_amount >= getConfigValue(ConfigNames.PROPOSAL_TGAS_AMOUNT), "TomiGovernance: NOT_ENOUGH_AMOUNT_TO_PROPOSAL");
        if(_amount > 0) {
            _amount = _transferForBallot(_amount, _wallet);
            // rewardOf[rewardAddr] = rewardOf[rewardAddr].add(_amount);
        }

        require(balanceOf[msg.sender] >= getConfigValue(ConfigNames.PROPOSAL_TGAS_AMOUNT), "TomiGovernance: COLLATERAL_NOT_ENOUGH_AMOUNT_TO_PROPOSAL");

        uint endBlockNumber = block.number + getConfigValue(ConfigNames.VOTE_DURATION);
        address ballotAddr = ITomiBallotFactory(ballotFactoryAddr).create(msg.sender, 0, endBlockNumber, _subject, _content);
        configBallots[ballotAddr] = SNAPSHOT_PROPOSAL;
        uint reward = _createdBallot(ballotAddr, T_SNAPSHOT);
        emit ConfigBallotCreated(msg.sender, SNAPSHOT_PROPOSAL, 0, ballotAddr, reward);
        return ballotAddr;
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
            // rewardOf[rewardAddr] = rewardOf[rewardAddr].add(_amount);
        }

        require(balanceOf[msg.sender] >= getConfigValue(ConfigNames.PROPOSAL_TGAS_AMOUNT), "TomiGovernance: COLLATERAL_NOT_ENOUGH_AMOUNT_TO_PROPOSAL");

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
            // rewardOf[rewardAddr] = rewardOf[rewardAddr].add(_amount);
        }

        require(balanceOf[msg.sender] >= getConfigValue(ConfigNames.PROPOSAL_TGAS_AMOUNT), "TomiGovernance: COLLATERAL_NOT_ENOUGH_AMOUNT_TO_PROPOSAL");

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

    function collectReward(address _ballot, bool revenueProposal) external returns (uint) {
        require(block.number >= ITomiBallot(_ballot).endBlockNumber(), "TomiGovernance: NOT_YET_ENDED");
        require(!collectUsers[_ballot][msg.sender], 'TomiGovernance: REWARD_COLLECTED');
        uint amount = !revenueProposal ? getReward(_ballot): getRewardForRevenueProposal(_ballot);
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

        bool result = ITomiBallot(_ballot).result();

        if (result) {
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
            uint reward = shares * ITomiBallot(_ballot).weight(msg.sender) / ITomiBallot(_ballot).total();
            amount += ITomiBallot(_ballot).proposer() == msg.sender ? 0: reward;
        }
        return amount;
    }

    function getRewardForRevenueProposal(address _ballot) public view returns (uint) {
        require(configBallots[_ballot] == REVENUE_PROPOSAL, "TomiGovernance::Fail due to wrong ballot");
        
        if (block.number < ITomiBallotRevenue(_ballot).endBlockNumber() || collectUsers[_ballot][msg.sender]) {
            return 0;
        }
        
        uint amount = 0;
        uint shares = ballotOf[_ballot];

        if (ITomiBallotRevenue(_ballot).total() > 0) {  
            uint reward = shares * ITomiBallotRevenue(_ballot).weight(msg.sender) / ITomiBallotRevenue(_ballot).total();
            amount += ITomiBallotRevenue(_ballot).proposer() == msg.sender ? 0 : reward; 
        }
        return amount;
    }

    // TOMI TEST ONLY
    // function addReward(uint _value) external onlyRewarder returns (bool) {
    function addReward(uint _value) external returns (bool) {
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
            _add(msg.sender, _amount);
            TransferHelper.safeTransferFrom(baseToken, msg.sender, address(this), _amount);
            totalSupply += _amount;
        }

        return _amount;
    }

    function _createdBallot(address _ballot, uint _type) internal returns (uint) {
        uint reward = rewardOf[rewardAddr];
        ballotOf[_ballot] = reward;
        _rewardTransfer(rewardAddr, _ballot, reward);
        _type == T_REVENUE ? revenueBallots.push(_ballot): ballots.push(_ballot);
        ballotTypes[_ballot] = _type;
        return reward;
    }

    function ballotCount() external view returns (uint) {
        return ballots.length;
    }

    function ballotRevenueCount() external view returns (uint) {
        return revenueBallots.length;
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

interface ITomiBallotFactory {
    function create(
        address _proposer,
        uint _value,
        uint _endBlockNumber,
        string calldata _subject,
        string calldata _content
    ) external returns (address);

     function createShareRevenue(
        address _proposer,
        uint256 _endBlockNumber,
        string calldata _subject,
        string calldata _content
    ) external returns (address);
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
    function voteByGovernor(address user, uint256 proposal) external;
}

pragma solidity >=0.5.0;

interface ITomiBallotRevenue {
    function proposer() external view returns(address);
    function endBlockNumber() external view returns(uint);
    function end() external returns (bool);
    function total() external view returns(uint);
    function weight(address user) external view returns (uint);
    function participateByGovernor(address user) external;
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

    function onBehalfDeposit(address _user, uint _amount) external returns (bool) {
        TransferHelper.safeTransferFrom(baseToken, msg.sender, address(this), _amount);
        _add(_user, _amount);
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

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
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

// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.1;

import "hardhat/console.sol";

struct Config {
        uint minValue;
        uint maxValue;
        uint maxSpan;
        uint value;
        uint enable;  // 0:disable, 1: enable
    }

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

interface ITomiConfig {
    function tokenCount() external view returns(uint);
    function tokenList(uint index) external view returns(address);
    function getConfigValue(bytes32 _name) external view returns (uint);
    function configs(bytes32 name) external view returns(Config memory);
    function tokenStatus(address token) external view returns(uint);
}

interface ITomiPlatform {
    function existPair(address tokenA, address tokenB) external view returns (bool);
    function swapPrecondition(address token) external view returns (bool);
    function getReserves(address tokenA, address tokenB) external view returns (uint256, uint256);
}

interface ITomiFactory {
    function getPair(address tokenA, address tokenB) external view returns(address);
}

interface ITomiDelegate {
    function getPlayerPairCount(address player) external view returns(uint);
    function playerPairs(address user, uint index) external view returns(address);
}

interface ITomiLP {
    function tokenA() external view returns (address);
    function tokenB() external view returns (address);
}

interface ITomiPair {
    function token0() external view returns(address);
    function token1() external view returns(address);
    function getReserves() external view returns(uint, uint, uint);
    function lastMintBlock(address user) external view returns(uint); 
}

interface ITomiGovernance {
    function ballotCount() external view returns(uint);
    function rewardOf(address ballot) external view returns(uint);
    function tokenBallots(address ballot) external view returns(address);
    function ballotTypes(address ballot) external view returns(uint);
    function revenueBallots(uint index) external view returns(address);
    function ballots(uint index) external view returns(address);
    function balanceOf(address owner) external view returns (uint);
    function ballotOf(address ballot) external view returns (uint);
    function allowance(address owner) external view returns (uint);
    function configBallots(address ballot) external view returns (bytes32);
    function stakingSupply() external view returns (uint);
    function collectUsers(address ballot, address user) external view returns(uint);
    function ballotRevenueCount() external view returns (uint);
}

interface ITomiBallot {
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        uint vote;   // index of the voted proposal
    }
    function subject() external view returns(string memory);
    function content() external view returns(string memory);
    function endBlockNumber() external view returns(uint);
    function createTime() external view returns(uint);
    function proposer() external view returns(address);
    function proposals(uint index) external view returns(uint);
    function ended() external view returns (bool);
    function value() external view returns (uint);
    function voters(address user) external view returns (Voter memory);
}

interface ITomiBallotRevenue {
    struct Participator {
        uint256 weight; // weight is accumulated by delegation
        bool participated; // if true, that person already voted
        address delegate; // person delegated to
    }
    function subject() external view returns(string memory);
    function content() external view returns(string memory);
    function endBlockNumber() external view returns(uint);
    function createTime() external view returns(uint);
    function proposer() external view returns(address);
    function proposals(uint index) external view returns(uint);
    function ended() external view returns (bool);
    function participators(address user) external view returns (Participator memory);
    function total() external view returns(uint256);
}

interface ITomiTransferListener {
    function pairWeights(address pair) external view returns(uint);
}

pragma experimental ABIEncoderV2;

contract TomiQuery2 {
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
    bytes32 public constant PAIR_SWITCH = bytes32('PAIR_SWITCH');
    bytes32 public constant TOKEN_PENGDING_SWITCH = bytes32('TOKEN_PENGDING_SWITCH');
    bytes32 public constant TOKEN_PENGDING_TIME = bytes32('TOKEN_PENGDING_TIME');

    address public configAddr;
    address public platform;
    address public factory;
    address public owner;
    address public governance;
    address public transferListener;
    address public delegate;

    uint public T_REVENUE = 5;
    
    struct Proposal {
        address proposer;
        address ballotAddress;
        address tokenAddress;
        string subject;
        string content;
        uint createTime;
        uint endBlock;
        bool end;
        uint YES;
        uint NO;
        uint totalReward;
        uint ballotType;
        uint weight;
        bool minted;
        bool voted;
        uint voteIndex;
        bool audited;
        uint value;
        bytes32 key;
        uint currentValue;
    }

    struct RevenueProposal {
        address proposer;
        address ballotAddress;
        address tokenAddress;
        string subject;
        string content;
        uint createTime;
        uint endBlock;
        uint total;
        bool end;
        uint totalReward;
        uint ballotType;
        uint weight;
        bool minted;
        bool participated;
        bool audited;
    }
    
    struct Token {
        address tokenAddress;
        string symbol;
        uint decimal;
        uint balance;
        uint allowance;
        uint allowanceGov;
        uint status;
        uint totalSupply;
    }
    
    struct Liquidity {
        address pair;
        address lp;
        uint balance;
        uint totalSupply;
        uint lastBlock;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function upgrade(address _config, address _platform, address _factory, address _governance, address _transferListener, address _delegate) public {
        require(owner == msg.sender);
        configAddr = _config;
        platform = _platform;
        factory = _factory;
        governance = _governance;
        transferListener = _transferListener;
        delegate = _delegate;
    }
   
    function queryTokenList() public view returns (Token[] memory token_list) {
        uint count = ITomiConfig(configAddr).tokenCount();
        if(count > 0) {
            token_list = new Token[](count);
            for(uint i = 0;i < count;i++) {
                Token memory tk;
                tk.tokenAddress = ITomiConfig(configAddr).tokenList(i);
                tk.symbol = IERC20(tk.tokenAddress).symbol();
                tk.decimal = IERC20(tk.tokenAddress).decimals();
                tk.balance = IERC20(tk.tokenAddress).balanceOf(msg.sender);
                tk.allowance = IERC20(tk.tokenAddress).allowance(msg.sender, delegate);
                tk.allowanceGov = IERC20(tk.tokenAddress).allowance(msg.sender, governance);
                tk.status = ITomiConfig(configAddr).tokenStatus(tk.tokenAddress);
                tk.totalSupply = IERC20(tk.tokenAddress).totalSupply();
                token_list[i] = tk;
            }
        }
    }

    function countTokenList() public view returns (uint) {
        return ITomiConfig(configAddr).tokenCount();
    }

    function iterateTokenList(uint _start, uint _end) public view returns (Token[] memory token_list) {
        require(_start <= _end && _start >= 0 && _end >= 0, "INVAID_PARAMTERS");
        uint count = ITomiConfig(configAddr).tokenCount();
        if(count > 0) {
            if (_end > count) _end = count;
            count = _end - _start;
            token_list = new Token[](count);
            uint index = 0;
            for(uint i = _start; i < _end; i++) {
                Token memory tk;
                tk.tokenAddress = ITomiConfig(configAddr).tokenList(i);
                tk.symbol = IERC20(tk.tokenAddress).symbol();
                tk.decimal = IERC20(tk.tokenAddress).decimals();
                tk.balance = IERC20(tk.tokenAddress).balanceOf(msg.sender);
                tk.allowance = IERC20(tk.tokenAddress).allowance(msg.sender, delegate);
                tk.allowanceGov = IERC20(tk.tokenAddress).allowance(msg.sender, governance);
                tk.status = ITomiConfig(configAddr).tokenStatus(tk.tokenAddress);
                tk.totalSupply = IERC20(tk.tokenAddress).totalSupply();
                token_list[index] = tk;
                index++;
            }
        }
    }
    
    function queryLiquidityList() public view returns (Liquidity[] memory liquidity_list) {
        uint count = ITomiDelegate(delegate).getPlayerPairCount(msg.sender);
        if(count > 0) {
            liquidity_list = new Liquidity[](count);
            for(uint i = 0;i < count;i++) {
                Liquidity memory l;
                l.lp  = ITomiDelegate(delegate).playerPairs(msg.sender, i);
                l.pair = ITomiFactory(factory).getPair(ITomiLP(l.lp).tokenA(), ITomiLP(l.lp).tokenB());
                l.balance = IERC20(l.lp).balanceOf(msg.sender);
                l.totalSupply = IERC20(l.pair).totalSupply();
                l.lastBlock = ITomiPair(l.pair).lastMintBlock(msg.sender);
                liquidity_list[i] = l;
            }
        }
    }

    function countLiquidityList() public view returns (uint) {
        return ITomiDelegate(delegate).getPlayerPairCount(msg.sender);
    }
        
    function iterateLiquidityList(uint _start, uint _end) public view returns (Liquidity[] memory liquidity_list) {
        require(_start <= _end && _start >= 0 && _end >= 0, "INVAID_PARAMTERS");
        uint count = ITomiDelegate(delegate).getPlayerPairCount(msg.sender);
        if(count > 0) {
            if (_end > count) _end = count;
            count = _end - _start;
            liquidity_list = new Liquidity[](count);
            uint index = 0;
            for(uint i = 0;i < count;i++) {
                Liquidity memory l;
                l.lp  = ITomiDelegate(delegate).playerPairs(msg.sender, i);
                l.pair = ITomiFactory(factory).getPair(ITomiLP(l.lp).tokenA(), ITomiLP(l.lp).tokenB());
                l.balance = IERC20(l.lp).balanceOf(msg.sender);
                l.totalSupply = IERC20(l.pair).totalSupply();
                l.lastBlock = ITomiPair(l.pair).lastMintBlock(msg.sender);
                liquidity_list[index] = l;
                index++;
            }
        }
    }

    function queryPairListInfo(address[] memory pair_list) public view returns (address[] memory token0_list, address[] memory token1_list,
    uint[] memory reserve0_list, uint[] memory reserve1_list) {
        uint count = pair_list.length;
        if(count > 0) {
            token0_list = new address[](count);
            token1_list = new address[](count);
            reserve0_list = new uint[](count);
            reserve1_list = new uint[](count);
            for(uint i = 0;i < count;i++) {
                token0_list[i] = ITomiPair(pair_list[i]).token0();
                token1_list[i] = ITomiPair(pair_list[i]).token1();
                (reserve0_list[i], reserve1_list[i], ) = ITomiPair(pair_list[i]).getReserves();
            }
        }
    }
    
    function queryPairReserve(address[] memory token0_list, address[] memory token1_list) public
    view returns (uint[] memory reserve0_list, uint[] memory reserve1_list, bool[] memory exist_list) {
        uint count = token0_list.length;
        if(count > 0) {
            reserve0_list = new uint[](count);
            reserve1_list = new uint[](count);
            exist_list = new bool[](count);
            for(uint i = 0;i < count;i++) {
                if(ITomiPlatform(platform).existPair(token0_list[i], token1_list[i])) {
                    (reserve0_list[i], reserve1_list[i]) = ITomiPlatform(platform).getReserves(token0_list[i], token1_list[i]);
                    exist_list[i] = true;
                } else {
                    exist_list[i] = false;
                }
            }
        }
    }
    
    function queryConfig() public view returns (uint fee_percent, uint proposal_amount, uint unstake_duration, 
    uint remove_duration, uint list_token_amount, uint vote_percent){
        fee_percent = ITomiConfig(configAddr).getConfigValue(SWAP_FEE_PERCENT);
        proposal_amount = ITomiConfig(configAddr).getConfigValue(PROPOSAL_TGAS_AMOUNT);
        unstake_duration = ITomiConfig(configAddr).getConfigValue(UNSTAKE_DURATION);
        remove_duration = ITomiConfig(configAddr).getConfigValue(REMOVE_LIQUIDITY_DURATION);
        list_token_amount = ITomiConfig(configAddr).getConfigValue(LIST_TGAS_AMOUNT);
        vote_percent = ITomiConfig(configAddr).getConfigValue(VOTE_REWARD_PERCENT);
    }
    
    function queryCondition(address[] memory path_list) public view returns (uint){
        uint count = path_list.length;
        for(uint i = 0;i < count;i++) {
            if(!ITomiPlatform(platform).swapPrecondition(path_list[i])) {
                return i + 1;
            }
        }
        
        return 0;
    }
    
    function generateProposal(address ballot_address) public view returns (Proposal memory proposal){
        proposal.proposer = ITomiBallot(ballot_address).proposer();
        proposal.subject = ITomiBallot(ballot_address).subject();
        proposal.content = ITomiBallot(ballot_address).content();
        proposal.createTime = ITomiBallot(ballot_address).createTime();
        proposal.endBlock = ITomiBallot(ballot_address).endBlockNumber();
        proposal.end = block.number > ITomiBallot(ballot_address).endBlockNumber() ? true: false;
        proposal.audited = ITomiBallot(ballot_address).ended();
        proposal.YES = ITomiBallot(ballot_address).proposals(1);
        proposal.NO = ITomiBallot(ballot_address).proposals(2);
        proposal.totalReward = ITomiGovernance(governance).ballotOf(ballot_address);
        proposal.ballotAddress = ballot_address;
        proposal.voted = ITomiBallot(ballot_address).voters(msg.sender).voted;
        proposal.voteIndex = ITomiBallot(ballot_address).voters(msg.sender).vote;
        proposal.weight = ITomiBallot(ballot_address).voters(msg.sender).weight;
        proposal.minted = ITomiGovernance(governance).collectUsers(ballot_address, msg.sender) == 1;
        proposal.ballotType = ITomiGovernance(governance).ballotTypes(ballot_address);
        proposal.tokenAddress = ITomiGovernance(governance).tokenBallots(ballot_address);
        proposal.value = ITomiBallot(ballot_address).value();

        if(proposal.ballotType == 1) {
            proposal.key = ITomiGovernance(governance).configBallots(ballot_address);
            proposal.currentValue = ITomiConfig(governance).getConfigValue(proposal.key);
        }
    }

    function generateRevenueProposal(address ballot_address) public view returns (RevenueProposal memory proposal){
        proposal.proposer = ITomiBallotRevenue(ballot_address).proposer();
        proposal.subject = ITomiBallotRevenue(ballot_address).subject();
        proposal.content = ITomiBallotRevenue(ballot_address).content();
        proposal.createTime = ITomiBallotRevenue(ballot_address).createTime();
        proposal.endBlock = ITomiBallotRevenue(ballot_address).endBlockNumber();
        proposal.end = block.number > ITomiBallotRevenue(ballot_address).endBlockNumber() ? true: false;
        proposal.audited = ITomiBallotRevenue(ballot_address).ended();
        proposal.totalReward = ITomiGovernance(governance).ballotOf(ballot_address);
        proposal.ballotAddress = ballot_address;
        proposal.participated = ITomiBallotRevenue(ballot_address).participators(msg.sender).participated;
        proposal.weight = ITomiBallotRevenue(ballot_address).participators(msg.sender).weight;
        proposal.minted = ITomiGovernance(governance).collectUsers(ballot_address, msg.sender) == 1;
        proposal.ballotType = ITomiGovernance(governance).ballotTypes(ballot_address);
        proposal.tokenAddress = ITomiGovernance(governance).tokenBallots(ballot_address);
        proposal.total = ITomiBallotRevenue(ballot_address).total();
    }    

    function queryTokenItemInfo(address token) public view returns (string memory symbol, uint decimal, uint totalSupply, uint balance, uint allowance) {
        symbol = IERC20(token).symbol();
        decimal = IERC20(token).decimals();
        totalSupply = IERC20(token).totalSupply();
        balance = IERC20(token).balanceOf(msg.sender);
        allowance = IERC20(token).allowance(msg.sender, delegate);
    }
    
    function queryConfigInfo(bytes32 name) public view returns (Config memory config_item){
        config_item = ITomiConfig(configAddr).configs(name);
    }
    
    function queryStakeInfo() public view returns (uint stake_amount, uint stake_block, uint total_stake) {
        stake_amount = ITomiGovernance(governance).balanceOf(msg.sender);
        stake_block = ITomiGovernance(governance).allowance(msg.sender);
        total_stake = ITomiGovernance(governance).stakingSupply();
    }

    function queryProposalList() public view returns (Proposal[] memory proposal_list){
        uint count = ITomiGovernance(governance).ballotCount();
        proposal_list = new Proposal[](count);
        for(uint i = 0;i < count;i++) {
            address ballot_address = ITomiGovernance(governance).ballots(i);
            proposal_list[count - i - 1] = generateProposal(ballot_address);
        }
    }

    function queryRevenueProposalList() public view returns (RevenueProposal[] memory proposal_list){
        uint count = ITomiGovernance(governance).ballotRevenueCount();
        proposal_list = new RevenueProposal[](count);
        for(uint i = 0;i < count;i++) {
            address ballot_address = ITomiGovernance(governance).revenueBallots(i);
            proposal_list[count - i - 1] = generateRevenueProposal(ballot_address);(ballot_address);
        }
    }

    function countProposalList() public view returns (uint) {
        return ITomiGovernance(governance).ballotCount();
    }

    function iterateProposalList(uint _start, uint _end) public view returns (Proposal[] memory proposal_list){
        require(_start <= _end && _start >= 0 && _end >= 0, "INVAID_PARAMTERS");
        uint count = ITomiGovernance(governance).ballotCount();
        if (_end > count) _end = count;
        count = _end - _start;
        proposal_list = new Proposal[](count);
        uint index = 0;
        for(uint i = 0;i < count;i++) {
            address ballot_address = ITomiGovernance(governance).ballots(i);
            proposal_list[index] = generateProposal(ballot_address);
            index++;
        }
    }

    function iterateReverseProposalList(uint _start, uint _end) public view returns (Proposal[] memory proposal_list){
        require(_end <= _start && _end >= 0 && _start >= 0, "INVAID_PARAMTERS");
        uint count = ITomiGovernance(governance).ballotCount();
        if (_start > count) _start = count;
        count = _start - _end;
        proposal_list = new Proposal[](count);
        uint index = 0;
        for(uint i = 0;i < count;i++) {
            address ballot_address = ITomiGovernance(governance).ballots(i);
            proposal_list[index] = generateProposal(ballot_address);
            index++;
        }
    }
        
    function queryPairWeights(address[] memory pairs) public view returns (uint[] memory weights){
        uint count = pairs.length;
        weights = new uint[](count);
        for(uint i = 0; i < count; i++) {
            weights[i] = ITomiTransferListener(transferListener).pairWeights(pairs[i]);
        }
    }

    function getPairReserve(address _pair) public view returns (address token0, address token1, uint8 decimals0, uint8 decimals1, uint reserve0, uint reserve1) {
        token0 = ITomiPair(_pair).token0();
        token1 = ITomiPair(_pair).token1();
        decimals0 = IERC20(token0).decimals();
        decimals1 = IERC20(token1).decimals();
        (reserve0, reserve1, ) = ITomiPair(_pair).getReserves();
    }

    function getPairReserveWithUser(address _pair, address _user) public view returns (address token0, address token1, uint8 decimals0, uint8 decimals1, uint reserve0, uint reserve1, uint balance0, uint balance1) {
        token0 = ITomiPair(_pair).token0();
        token1 = ITomiPair(_pair).token1();
        decimals0 = IERC20(token0).decimals();
        decimals1 = IERC20(token1).decimals();
        (reserve0, reserve1, ) = ITomiPair(_pair).getReserves();
        balance0 = IERC20(token0).balanceOf(_user);
        balance1 = IERC20(token1).balanceOf(_user);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.1;

import './modules/Ownable.sol';
import './libraries/TransferHelper.sol';
import './interfaces/ITomiPair.sol';
import './interfaces/ITomiFactory.sol';
import './interfaces/ITomiGovernance.sol';
import './libraries/SafeMath.sol';
import './libraries/ConfigNames.sol';
import './interfaces/ITomiConfig.sol';
import './interfaces/IERC20.sol';

interface ITomiPlatform {
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) ;
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract TomiPool is Ownable {

    using SafeMath for uint;
    address public TOMI;
    address public FACTORY;
    address public PLATFORM;
    address public WETH;
    address public CONFIG;
    address public GOVERNANCE;
    address public FUNDING;
    address public LOTTERY;
    uint public totalReward;
    
    struct UserInfo {
        uint rewardDebt; // Reward debt. 
        uint rewardEarn; // Reward earn and not minted
    }
    
    event ClaimReward(address indexed user, address indexed pair, address indexed rewardToken, uint amountTOMI);
    event AddReward(address indexed pair, uint amount);

    mapping(address => mapping (address => UserInfo)) public users;
    
    mapping (address => uint) public pairAmountPerShare;
    mapping (address => uint) public pairReward;
    
     function initialize(address _TOMI, address _WETH, address _FACTORY, address _PLATFORM, address _CONFIG, address _GOVERNANCE, address _FUNDING, address _LOTTERY) external onlyOwner {
        TOMI = _TOMI;
        WETH = _WETH;
        FACTORY = _FACTORY;
        PLATFORM = _PLATFORM;
        CONFIG = _CONFIG;
        GOVERNANCE = _GOVERNANCE;
        FUNDING = _FUNDING;
        LOTTERY = _LOTTERY;
    }
    
    function upgrade(address _newPool, address[] calldata _pairs) external onlyOwner {
        IERC20(TOMI).approve(_newPool, totalReward);
        for(uint i = 0;i < _pairs.length;i++) {
            if(pairReward[_pairs[i]] > 0) {
                TomiPool(_newPool).addReward(_pairs[i], pairReward[_pairs[i]]);
                totalReward = totalReward.sub(pairReward[_pairs[i]]);
                pairReward[_pairs[i]] = 0;
            }
        }
    }
    
    function addRewardFromPlatform(address _pair, uint _amount) external {
       require(msg.sender == PLATFORM, "TOMI POOL: FORBIDDEN");
        uint balanceOf = IERC20(TOMI).balanceOf(address(this));
        require(balanceOf.sub(totalReward) >= _amount, 'TOMI POOL: ADD_REWARD_EXCEED');

        uint rewardAmount = ITomiConfig(CONFIG).getConfigValue(ConfigNames.FEE_LP_REWARD_PERCENT).mul(_amount).div(10000);
        _addReward(_pair, rewardAmount);

        uint remainAmount = _amount.sub(rewardAmount);        
        uint fundingAmount = ITomiConfig(CONFIG).getConfigValue(ConfigNames.FEE_FUNDME_REWARD_PERCENT).mul(remainAmount).div(10000);
      
        if(fundingAmount > 0) {
            TransferHelper.safeTransfer(TOMI, FUNDING, fundingAmount);
        }

        remainAmount = remainAmount.sub(fundingAmount);      
        uint lotteryAmount = ITomiConfig(CONFIG).getConfigValue(ConfigNames.FEE_LOTTERY_REWARD_PERCENT).mul(remainAmount).div(10000);

        if(lotteryAmount > 0) {
            TransferHelper.safeTransfer(TOMI, LOTTERY, lotteryAmount);
        }  

        remainAmount = remainAmount.sub(lotteryAmount);
        // uint governanceAmount = ITomiConfig(CONFIG).getConfigValue(ConfigNames.FEE_GOVERNANCE_REWARD_PERCENT).mul(remainAmount).div(10000);
        if(remainAmount > 0) {
            TransferHelper.safeTransfer(TOMI, GOVERNANCE, remainAmount);
            ITomiGovernance(GOVERNANCE).addReward(remainAmount);
        }
        // if(remainAmount.sub(governanceAmount) > 0) {
        //     TransferHelper.safeTransfer(TOMI, address(0), remainAmount.sub(governanceAmount));
        // }
        emit AddReward(_pair, rewardAmount);
    }
    
    function addReward(address _pair, uint _amount) external {
        TransferHelper.safeTransferFrom(TOMI, msg.sender, address(this), _amount);
        
        require(ITomiFactory(FACTORY).isPair(_pair), "TOMI POOL: INVALID PAIR");
        _addReward(_pair, _amount);
        
        emit AddReward(_pair, _amount);
    }
    
    function preProductivityChanged(address _pair, address _user) external {
        require(msg.sender == PLATFORM, "TOMI POOL: FORBIDDEN");
        _auditUser(_pair, _user);
    }
    
    function postProductivityChanged(address _pair, address _user) external {
        require(msg.sender == PLATFORM, "TOMI POOL: FORBIDDEN");
        require(ITomiFactory(FACTORY).isPair(_pair), "TOMI POOL: INVALID PAIR");
        
        _updateDebt(_pair, _user);
    }
    
    function _addReward(address _pair, uint _amount) internal {
        pairReward[_pair] = pairReward[_pair].add(_amount);
        uint totalProdutivity = ITomiPair(_pair).totalSupply();
        if(totalProdutivity > 0) {
            pairAmountPerShare[_pair] = pairAmountPerShare[_pair].add(_amount.mul(1e12).div(totalProdutivity));
            totalReward = totalReward.add(_amount);
        }
    }
    
    function _auditUser(address _pair, address _user) internal {
        require(ITomiFactory(FACTORY).isPair(_pair), "TOMI POOL: INVALID PAIR");
    
        uint balance = ITomiPair(_pair).balanceOf(_user);
        uint accAmountPerShare = pairAmountPerShare[_pair];
        UserInfo storage userInfo = users[_user][_pair];
        uint pending = balance.mul(accAmountPerShare).div(1e12).sub(userInfo.rewardDebt);
        userInfo.rewardEarn = userInfo.rewardEarn.add(pending);
        userInfo.rewardDebt = balance.mul(accAmountPerShare).div(1e12);
    }
    
    function _updateDebt(address _pair, address _user) internal {
        uint balance = ITomiPair(_pair).balanceOf(_user);
        uint accAmountPerShare = pairAmountPerShare[_pair];
        users[_user][_pair].rewardDebt = balance.mul(accAmountPerShare).div(1e12);
    }
    
    function claimReward(address _pair, address _rewardToken) external {
        _auditUser(_pair, msg.sender);
        UserInfo storage userInfo = users[msg.sender][_pair];
        
        uint amount = userInfo.rewardEarn;
        pairReward[_pair] = pairReward[_pair].sub(amount);
        totalReward = totalReward.sub(amount);
        require(amount > 0, "NOTHING TO MINT");
        
        if(_rewardToken == TOMI) {
            TransferHelper.safeTransfer(TOMI, msg.sender, amount);
        } else if(_rewardToken == WETH) {
            require(ITomiFactory(FACTORY).isPair(_pair), "TOMI POOL: INVALID PAIR");
            IERC20(TOMI).approve(PLATFORM, amount);
            address[] memory path = new address[](2);
            path[0] = TOMI;
            path[1] = WETH; 
            ITomiPlatform(PLATFORM).swapExactTokensForETH(amount, 0, path, msg.sender, block.timestamp + 1);
        } else {
            require(ITomiFactory(FACTORY).isPair(_pair), "TOMI POOL: INVALID PAIR");
            IERC20(TOMI).approve(PLATFORM, amount);
            address[] memory path = new address[](2);
            path[0] = TOMI;
            path[1] = _rewardToken;
            ITomiPlatform(PLATFORM).swapExactTokensForTokens(amount, 0, path, msg.sender, block.timestamp + 1);
        }
        
        userInfo.rewardEarn = 0;
        emit ClaimReward(msg.sender, _pair, _rewardToken, amount);
    }
    
    function queryReward(address _pair, address _user) external view returns(uint) {
        require(ITomiFactory(FACTORY).isPair(_pair), "TOMI POOL: INVALID PAIR");
        
        UserInfo memory userInfo = users[msg.sender][_pair];
        uint balance = ITomiPair(_pair).balanceOf(_user);
        return balance.mul(pairAmountPerShare[_pair]).div(1e12).add(userInfo.rewardEarn).sub(userInfo.rewardDebt);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import "./libraries/TransferHelper.sol";
import "./modules/Ownable.sol";
import "./interfaces/IERC20.sol";

contract TomiFunding is Ownable {
    address public tomi;

    mapping(address => bool) included;
    
    event ClaimableGranted(address _userAddress);
    event ClaimableRevoked(address _userAddress);
    event Claimed(address _userAddress, uint256 _amount);
    event FundingTokenSettled(address tokenAddress);
    
    constructor(address _tomi) public {
        tomi = _tomi;
    }
    
    modifier inClaimable(address _userAddress) {
        require(included[_userAddress], "TomiFunding::User not in claimable list!");
        _;
    }

    modifier notInClaimable(address _userAddress) {
        require(!included[_userAddress], "TomiFunding::User already in claimable list!");
        _;
    }
    
    function setTomi(address _tomi) public onlyOwner {
        tomi = _tomi;
        emit FundingTokenSettled(_tomi);
    }
    
    function grantClaimable(address _userAddress) public onlyOwner notInClaimable(_userAddress) {
        require(_userAddress != address(0), "TomiFunding::User address is not legit!");
        
        included[_userAddress] = true;
        emit ClaimableGranted(_userAddress);
    }
    
    function revokeClaimable(address _userAddress) public onlyOwner inClaimable(_userAddress) {
        require(_userAddress != address(0), "TomiFunding::User address is not legit!");
        
        included[_userAddress] = false;
        emit ClaimableRevoked(_userAddress);
    }
    
    function claim(uint256 _amount) public inClaimable(msg.sender) {
        uint256 remainBalance = IERC20(tomi).balanceOf(address(this));
        require(remainBalance >= _amount, "TomiFunding::Remain balance is not enough to claim!");
        
        TransferHelper.safeTransfer(address(tomi), msg.sender, _amount); 
        emit Claimed(msg.sender, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import './libraries/ConfigNames.sol';
import './libraries/TransferHelper.sol';
import './modules/TokenRegistry.sol';
import './modules/Ownable.sol';

contract TomiConfig is TokenRegistry, Ownable {
    uint public version = 1;
    event ConfigValueChanged(bytes32 _name, uint _old, uint _value);

    struct Config {
        uint minValue;
        uint maxValue;
        uint maxSpan;
        uint value;
        uint enable;  // 0:disable, 1: enable
    }

    mapping(bytes32 => Config) public configs;
    address public tgas;                                // TGAS contract address
    address public platform;      
    address public dev;                         
    uint public constant PERCENT_DENOMINATOR = 10000;
    uint public constant TGAS_DECIMAL = 10 ** 18;
    address[] public defaultListTokens;

    modifier onlyPlatform() {
        require(msg.sender == platform, 'TomiConfig: ONLY_PLATFORM');
        _;
    }

    constructor()  public {
        _initConfig(ConfigNames.PRODUCE_TGAS_RATE, 1 * TGAS_DECIMAL, 120 * TGAS_DECIMAL, 10 * TGAS_DECIMAL, 40 * TGAS_DECIMAL);
        _initConfig(ConfigNames.SWAP_FEE_PERCENT, 5,30,5,30);
        _initConfig(ConfigNames.LIST_TGAS_AMOUNT, 0, 100000 * TGAS_DECIMAL, 1000 * TGAS_DECIMAL, 0);
        _initConfig(ConfigNames.UNSTAKE_DURATION, 17280, 17280*7, 17280, 17280);
        _initConfig(ConfigNames.REMOVE_LIQUIDITY_DURATION, 0, 17280*7, 17280, 0);
        _initConfig(ConfigNames.TOKEN_TO_TGAS_PAIR_MIN_PERCENT, 20, 500, 10, 100);
        _initConfig(ConfigNames.LIST_TOKEN_FAILURE_BURN_PRECENT, 100, 5000, 500, 1000);
        _initConfig(ConfigNames.LIST_TOKEN_SUCCESS_BURN_PRECENT, 1000, 5000, 500, 5000);
        _initConfig(ConfigNames.PROPOSAL_TGAS_AMOUNT, 100 * TGAS_DECIMAL, 10000 * TGAS_DECIMAL, 100 * TGAS_DECIMAL, 100 * TGAS_DECIMAL);
        _initConfig(ConfigNames.VOTE_DURATION, 17280, 17280*7, 17280, 17280);
        _initConfig(ConfigNames.VOTE_REWARD_PERCENT, 0, 1000, 100, 500);
        _initConfig(ConfigNames.TOKEN_PENGDING_SWITCH, 0, 1, 1, 1);  // 0:off, 1:on
        _initConfig(ConfigNames.TOKEN_PENGDING_TIME, 0, 100*17280, 10*17280, 100*17280);
        _initConfig(ConfigNames.LIST_TOKEN_SWITCH, 0, 1, 1, 0);  // 0:off, 1:on
        _initConfig(ConfigNames.DEV_PRECENT, 1000, 1000, 1000, 1000);

                _initConfig(ConfigNames.DEV_PRECENT, 1000, 1000, 1000, 1000);

        _initConfig(ConfigNames.FEE_FUNDME_REWARD_PERCENT, 833, 833, 833, 833);  
        _initConfig(ConfigNames.FEE_LOTTERY_REWARD_PERCENT, 833, 833, 833, 833);
    }

    function _initConfig(bytes32 _name, uint _minValue, uint _maxValue, uint _maxSpan, uint _value) internal {
        Config storage config = configs[_name];
        config.minValue = _minValue;
        config.maxValue = _maxValue;
        config.maxSpan = _maxSpan;
        config.value = _value;
        config.enable = 1;
    }

    function initialize(
        address _tgas,
        address _governor,
        address _platform,
        address _dev,
        address[] memory _listTokens) public onlyOwner {
        require(_tgas != address(0), "TomiConfig: ZERO ADDRESS");
        tgas = _tgas;
        platform = _platform;
        dev = _dev;
        for(uint i = 0 ; i < _listTokens.length; i++){
            _updateToken(_listTokens[i], OPENED);
            defaultListTokens.push(_listTokens[i]);
        }
        initGovernorAddress(_governor);
    }

    function modifyGovernor(address _new) public onlyOwner {
        _changeGovernor(_new);
    }

    function modifyDev(address _new) public {
        require(msg.sender == dev, 'TomiConfig: FORBIDDEN');
        dev = _new;
    }

    function changeConfig(bytes32 _name, uint _minValue, uint _maxValue, uint _maxSpan, uint _value) external onlyOwner returns (bool) {
        _initConfig(_name, _minValue, _maxValue, _maxSpan, _value);
        return true;
    }

    function getConfig(bytes32 _name) external view returns (uint minValue, uint maxValue, uint maxSpan, uint value, uint enable) {
        Config memory config = configs[_name];
        minValue = config.minValue;
        maxValue = config.maxValue;
        maxSpan = config.maxSpan;
        value = config.value;
        enable = config.enable;
    }
    
    function getConfigValue(bytes32 _name) public view returns (uint) {
        return configs[_name].value;
    }

    function changeConfigValue(bytes32 _name, uint _value) external onlyGovernor returns (bool) {
        Config storage config = configs[_name];
        require(config.enable == 1, "TomiConfig: DISABLE");
        require(_value <= config.maxValue && _value >= config.minValue, "TomiConfig: OVERFLOW");
        uint old = config.value;
        uint span = _value >= old ? (_value - old) : (old - _value);
        require(span <= config.maxSpan, "TomiConfig: EXCEED MAX ADJUST SPAN");
        config.value = _value;
        emit ConfigValueChanged(_name, old, _value);
        return true;
    }

    function checkToken(address _token) public view returns(bool) {
        if (getConfigValue(ConfigNames.LIST_TOKEN_SWITCH) == 0) {
            return true;
        }
        if (tokenStatus[_token] == OPENED) {
            return true;
        } else if (tokenStatus[_token] == PENDING ) {
            if (getConfigValue(ConfigNames.TOKEN_PENGDING_SWITCH) == 1 && block.number > publishTime[_token] + getConfigValue(ConfigNames.TOKEN_PENGDING_TIME)) {
                return false;
            } else {
                return true;
            }
        }
        return false;
    }

    function checkPair(address tokenA, address tokenB) external view returns (bool) {
        if (checkToken(tokenA) && checkToken(tokenB)) {
            return true;
        }
        return false;
    }

    function getDefaultListTokens() external view returns (address[] memory) {
        address[] memory res = new address[](defaultListTokens.length);
        for (uint i; i < defaultListTokens.length; i++) {
            res[i] = defaultListTokens[i];
        }
        return res;
    }

    function addToken(address _token) external onlyPlatform returns (bool) {
        if(getConfigValue(ConfigNames.LIST_TOKEN_SWITCH) == 0) {
            if(tokenStatus[_token] != OPENED) {
                _updateToken(_token, OPENED);
            }
        }
        return true;
    }

}

pragma solidity >=0.5.16;

import './Governable.sol';

/**
    Business Process
    step 1. publishToken
    step 2. addToken or removeToken
 */

contract TokenRegistry is Governable {
    mapping (address => uint) public tokenStatus;
    mapping (address => uint) public publishTime;
    uint public tokenCount;
    address[] public tokenList;
    uint public constant NONE = 0;
    uint public constant REGISTERED = 1;
    uint public constant PENDING = 2;
    uint public constant OPENED = 3;
    uint public constant CLOSED = 4;

    event TokenStatusChanged(address indexed _token, uint _status, uint _block);

    function registryToken(address _token) external onlyGovernor returns (bool) {
        return _updateToken(_token, REGISTERED);
    }

    function publishToken(address _token) external onlyGovernor returns (bool) {
        publishTime[_token] = block.number;
        return _updateToken(_token, PENDING);
    }

    function updateToken(address _token, uint _status) external onlyGovernor returns (bool) {
        return _updateToken(_token, _status);
    }

    function validTokens() external view returns (address[] memory) {
        uint count;
        for (uint i; i < tokenList.length; i++) {
            if (tokenStatus[tokenList[i]] == PENDING || tokenStatus[tokenList[i]] == OPENED) {
                count++;
            }
        }
        address[] memory res = new address[](count);
        uint index = 0;
        for (uint i; i < tokenList.length; i++) {
            if (tokenStatus[tokenList[i]] == PENDING || tokenStatus[tokenList[i]] == OPENED) {
                res[index] = tokenList[i];
                index++;
            }
        }
        return res;
    }

    function iterateValidTokens(uint _start, uint _end) external view returns (address[] memory) {
        require(_end <= tokenList.length, "TokenRegistry: OVERFLOW");
        require(_start <= _end && _start >= 0 && _end >= 0, "TokenRegistry: INVAID_PARAMTERS");
        uint count;
        for (uint i = _start; i < _end; i++) {
            if (tokenStatus[tokenList[i]] == PENDING || tokenStatus[tokenList[i]] == OPENED) {
                count++;
            }
        }
        address[] memory res = new address[](count);
        uint index = 0;
        for (uint i = _start; i < _end; i++) {
            if (tokenStatus[tokenList[i]] == PENDING || tokenStatus[tokenList[i]] == OPENED) {
                res[index] = tokenList[i];
                index++;
            }
        }
        return res;
    }

    function _updateToken(address _token, uint _status) internal returns (bool) {
        require(_token != address(0), 'TokenRegistry: INVALID_TOKEN');
        require(tokenStatus[_token] != _status, 'TokenRegistry: TOKEN_STATUS_NO_CHANGE');
        if (tokenStatus[_token] == NONE) {
            tokenCount++;
            require(tokenCount <= uint(-1), 'TokenRegistry: OVERFLOW');
            tokenList.push(_token);
        }
        tokenStatus[_token] = _status;
        emit TokenStatusChanged(_token, _status, block.number);
        return true;
    }

}

pragma solidity >=0.5.16;

contract Governable {
    address public governor;

    event ChangeGovernor(address indexed _old, address indexed _new);

    modifier onlyGovernor() {
        require(msg.sender == governor, 'Governable: FORBIDDEN');
        _;
    }

    // called after deployment
    function initGovernorAddress(address _governor) internal {
        require(_governor != address(0), 'Governable: INPUT_ADDRESS_IS_ZERO');
        governor = _governor;
    }

    function changeGovernor(address _new) public onlyGovernor {
        _changeGovernor(_new);
    }

    function _changeGovernor(address _new) internal {
        require(_new != address(0), 'Governable: INVALID_ADDRESS');
        require(_new != governor, 'Governable: NO_CHANGE');
        address old = governor;
        governor = _new;
        emit ChangeGovernor(old, _new);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/ITomiFactory.sol';
import './interfaces/ITgas.sol';
import './interfaces/IERC20.sol';
import './interfaces/ITomiCallee.sol';
import './interfaces/ITomiConfig.sol';
import './modules/BaseShareField.sol';
import './libraries/ConfigNames.sol';

contract TomiPair is BaseShareField {
    uint256 public version = 1;
    using SafeMath for uint256;
    using UQ112x112 for uint224;

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public FACTORY;
    address public CONFIG;
    address public TOMI;
    address public token0;
    address public token1;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;

    uint256 public totalReward;
    uint256 public remainReward;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    event Mint(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, address indexed to, uint256 value);
    event ClaimTOMI(address indexed player, uint256 pairMint, uint256 userMint);
    mapping(address => uint256) public lastMintBlock;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Locked');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Mint(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Burn(from, address(0), value);
    }
    
    // function _mintTGAS() internal {
    //     if(ITgas(TGAS).take() > 0) {
    //         uint reward = ITgas(TGAS).mint();
    //         uint devAmount = reward * ITomiConfig(CONFIG).getConfigValue(ConfigNames.DEV_PRECENT) / 10000;
    //         address devAddress = ITomiConfig(CONFIG).dev();
    //         _safeTransfer(TGAS, devAddress, devAmount);
    //         remainReward = remainReward.add(reward.sub(devAmount));
    //     }
    // }
    
    // function _currentReward() internal override view returns (uint) {
    //     uint devPercent = ITomiConfig(CONFIG).getConfigValue(ConfigNames.DEV_PRECENT);
    //     uint pairReward = IERC20(TOMI).take().mul(10000 - devPercent).div(10000);
    //     return mintedShare.add(remainReward).add(pairReward).sub(totalShare);
    // }

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TOMI PAIR : TRANSFER_FAILED');
    }

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event SwapFee(address indexed token, address indexed to, uint256 amount);
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor() public {
        FACTORY = msg.sender;
    }

    modifier onlyPlatform {
        address platform = ITomiConfig(CONFIG).platform();
        require(msg.sender == platform, 'TOMI PAIR : FORBIDDEN');
        _;
    }

    // called once by the factory at time of deployment
    function initialize(
        address _token0,
        address _token1,
        address _config,
        address _tomi
    ) external {
        require(msg.sender == FACTORY, 'TOMI PAIR : FORBIDDEN');
        token0 = _token0;
        token1 = _token1;
        CONFIG = _config;
        TOMI = _tomi;
        _setShareToken(TOMI);
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'TOMI PAIR : OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // this low-level function should be called from a contract which performs // important safety checks
    function mint(address to) external onlyPlatform lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        uint256 balance0 = _balanceOf(token0, address(this));
        uint256 balance1 = _balanceOf(token1, address(this));
        uint256 amount0 = balance0.sub(_reserve0);
        uint256 amount1 = balance1.sub(_reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'TOMI PAIR : INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);
        // _mintTGAS();
        // _increaseProductivity(to, liquidity);
        lastMintBlock[to] = block.number;
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs // important safety checks
    function burn(
        address from,
        address to,
        uint256 amount
    ) external onlyPlatform lock returns (uint256 amount0, uint256 amount1) {
        require(
            block.number >=
                lastMintBlock[from] + ITomiConfig(CONFIG).getConfigValue(ConfigNames.REMOVE_LIQUIDITY_DURATION),
            'TOMI PLATFORM : REMOVE LIQUIDITY DURATION FAIL'
        );
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint256 balance0 = _balanceOf(_token0, address(this));
        uint256 balance1 = _balanceOf(_token1, address(this));
        require(balanceOf[from] >= amount, 'TOMI PAIR : INSUFFICIENT_LIQUIDITY_AMOUNT');

        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = amount.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = amount.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'TOMI PAIR : INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(from, amount);
        // _mintTGAS();
        // _decreaseProductivity(from, amount);

        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = _balanceOf(_token0, address(this));
        balance1 = _balanceOf(_token1, address(this));
        _update(balance0, balance1, _reserve0, _reserve1);

        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs // important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external onlyPlatform lock {
        require(amount0Out > 0 || amount1Out > 0, 'TOMI PAIR : INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'TOMI PAIR :  INSUFFICIENT_LIQUIDITY');
        uint256 balance0;
        uint256 balance1;
        {
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, 'TOMI PAIR : INVALID_TO');
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out);
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out);
            if (data.length > 0) ITomiCallee(to).tomiCall(msg.sender, amount0Out, amount1Out, data);
            balance0 = _balanceOf(_token0, address(this));
            balance1 = _balanceOf(_token1, address(this));
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        uint256 _amount0Out = amount0Out;
        uint256 _amount1Out = amount1Out;
        require(amount0In > 0 || amount1In > 0, 'TOMI PAIR : INSUFFICIENT_INPUT_AMOUNT');
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, _amount0Out, _amount1Out, to);
    }

    function swapFee(
        uint256 amount,
        address token,
        address to
    ) external onlyPlatform {
        if (amount == 0 || token == to) return;
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        require(to != token0 && to != token1, 'TOMI PAIR : INVALID_TO');
        _safeTransfer(token, to, amount);
        uint256 balance0 = _balanceOf(token0, address(this));
        uint256 balance1 = _balanceOf(token1, address(this));
        _update(balance0, balance1, _reserve0, _reserve1);
        emit SwapFee(token, to , amount);
    }

    function queryReward() external view returns (uint256 rewardAmount, uint256 blockNumber) {
        rewardAmount = _takeWithAddress(msg.sender);
        blockNumber = block.number;
    }

    function mintReward() external lock returns (uint256 userReward) {
        // _mintTGAS();
        userReward = _mint(msg.sender);
        remainReward = remainReward.sub(userReward);
        emit ClaimTOMI(msg.sender, remainReward, userReward);
    }

    function getTOMIReserve() public view returns (uint256) {
        return _balanceOf(TOMI, address(this));
    }

    function _balanceOf(address token, address owner) internal view returns (uint256) {
        if (token == TOMI && owner == address(this)) {
            return IERC20(token).balanceOf(owner).sub(remainReward);
        } else {
            return IERC20(token).balanceOf(owner);
        }
    }

    // force reserves to match balances
    function sync() external lock {
        _update(_balanceOf(token0, address(this)), _balanceOf(token1, address(this)), reserve0, reserve1);
    }
}

pragma solidity >=0.5.0;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

pragma solidity >=0.5.0;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

pragma solidity >=0.5.0;

interface ITomiCallee {
    function tomiCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

pragma solidity >=0.6.6;
import '../interfaces/ERC2917-Interface.sol';
import '../libraries/SafeMath.sol';
import '../libraries/TransferHelper.sol';

contract BaseShareField {
    using SafeMath for uint;
    
    uint totalProductivity;
    uint accAmountPerShare;
    
    uint public totalShare;
    uint public mintedShare;
    uint public mintCumulation;
    
    address public shareToken;
    
    struct UserInfo {
        uint amount;     // How many tokens the user has provided.
        uint rewardDebt; // Reward debt. 
        uint rewardEarn; // Reward earn and not minted
    }

    mapping(address => UserInfo) public users;
    
    function _setShareToken(address _shareToken) internal {
        shareToken = _shareToken;
    }

    // Update reward variables of the given pool to be up-to-date.
    function _update() internal virtual {
        if (totalProductivity == 0) {
            totalShare = totalShare.add(_currentReward());
            return;
        }
        
        uint256 reward = _currentReward();
        accAmountPerShare = accAmountPerShare.add(reward.mul(1e12).div(totalProductivity));
        totalShare = totalShare.add(reward);
    }
    
    function _currentReward() internal virtual view returns (uint) {
        return mintedShare.add(IERC20(shareToken).balanceOf(address(this))).sub(totalShare);
    }
    
    // Audit user's reward to be up-to-date
    function _audit(address user) internal virtual {
        UserInfo storage userInfo = users[user];
        if (userInfo.amount > 0) {
            uint pending = userInfo.amount.mul(accAmountPerShare).div(1e12).sub(userInfo.rewardDebt);
            userInfo.rewardEarn = userInfo.rewardEarn.add(pending);
            mintCumulation = mintCumulation.add(pending);
            userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        }
    }

    // External function call
    // This function increase user's productivity and updates the global productivity.
    // the users' actual share percentage will calculated by:
    // Formula:     user_productivity / global_productivity
    function _increaseProductivity(address user, uint value) internal virtual returns (bool) {
        require(value > 0, 'PRODUCTIVITY_VALUE_MUST_BE_GREATER_THAN_ZERO');

        UserInfo storage userInfo = users[user];
        _update();
        _audit(user);

        totalProductivity = totalProductivity.add(value);

        userInfo.amount = userInfo.amount.add(value);
        userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        return true;
    }

    // External function call 
    // This function will decreases user's productivity by value, and updates the global productivity
    // it will record which block this is happenning and accumulates the area of (productivity * time)
    function _decreaseProductivity(address user, uint value) internal virtual returns (bool) {
        UserInfo storage userInfo = users[user];
        require(value > 0 && userInfo.amount >= value, 'INSUFFICIENT_PRODUCTIVITY');
        
        _update();
        _audit(user);
        
        userInfo.amount = userInfo.amount.sub(value);
        userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        totalProductivity = totalProductivity.sub(value);
        
        return true;
    }
    
    function _takeWithAddress(address user) internal view returns (uint) {
        UserInfo storage userInfo = users[user];
        uint _accAmountPerShare = accAmountPerShare;
        // uint256 lpSupply = totalProductivity;
        if (totalProductivity != 0) {
            uint reward = _currentReward();
            _accAmountPerShare = _accAmountPerShare.add(reward.mul(1e12).div(totalProductivity));
        }
        return userInfo.amount.mul(_accAmountPerShare).div(1e12).add(userInfo.rewardEarn).sub(userInfo.rewardDebt);
    }

    // External function call
    // When user calls this function, it will calculate how many token will mint to user from his productivity * time
    // Also it calculates global token supply from last time the user mint to this time.
    function _mint(address user) internal virtual returns (uint) {
        _update();
        _audit(user);
        require(users[user].rewardEarn > 0, "NOTHING TO MINT");
        uint amount = users[user].rewardEarn;
        TransferHelper.safeTransfer(shareToken, msg.sender, amount);
        users[user].rewardEarn = 0;
        mintedShare += amount;
        return amount;
    }

    // Returns how many productivity a user has and global has.
    function getProductivity(address user) public virtual view returns (uint, uint) {
        return (users[user].amount, totalProductivity);
    }

    // Returns the current gorss product rate.
    function interestsPerBlock() public virtual view returns (uint) {
        return accAmountPerShare;
    }
    
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;
import '../interfaces/IERC20.sol';

interface IERC2917 is IERC20 {

    /// @dev This emit when interests amount per block is changed by the owner of the contract.
    /// It emits with the old interests amount and the new interests amount.
    event InterestRatePerBlockChanged (uint oldValue, uint newValue);

    /// @dev This emit when a users' productivity has changed
    /// It emits with the user's address and the the value after the change.
    event ProductivityIncreased (address indexed user, uint value);

    /// @dev This emit when a users' productivity has changed
    /// It emits with the user's address and the the value after the change.
    event ProductivityDecreased (address indexed user, uint value);

    /// @dev Return the current contract's interests rate per block.
    /// @return The amount of interests currently producing per each block.
    function interestsPerBlock() external view returns (uint);

    /// @notice Change the current contract's interests rate.
    /// @dev Note the best practice will be restrict the gross product provider's contract address to call this.
    /// @return The true/fase to notice that the value has successfully changed or not, when it succeed, it will emite the InterestRatePerBlockChanged event.
    function changeInterestRatePerBlock(uint value) external returns (bool);

    /// @notice It will get the productivity of given user.
    /// @dev it will return 0 if user has no productivity proved in the contract.
    /// @return user's productivity and overall productivity.
    function getProductivity(address user) external view returns (uint, uint);

    /// @notice increase a user's productivity.
    /// @dev Note the best practice will be restrict the callee to prove of productivity's contract address.
    /// @return true to confirm that the productivity added success.
    function increaseProductivity(address user, uint value) external returns (bool);

    /// @notice decrease a user's productivity.
    /// @dev Note the best practice will be restrict the callee to prove of productivity's contract address.
    /// @return true to confirm that the productivity removed success.
    function decreaseProductivity(address user, uint value) external returns (bool);

    /// @notice take() will return the interests that callee will get at current block height.
    /// @dev it will always calculated by block.number, so it will change when block height changes.
    /// @return amount of the interests that user are able to mint() at current block height.
    function take() external view returns (uint);

    /// @notice similar to take(), but with the block height joined to calculate return.
    /// @dev for instance, it returns (_amount, _block), which means at block height _block, the callee has accumulated _amount of interests.
    /// @return amount of interests and the block height.
    function takeWithBlock() external view returns (uint, uint);

    /// @notice mint the avaiable interests to callee.
    /// @dev once it mint, the amount of interests will transfer to callee's address.
    /// @return the amount of interests minted.
    function mint() external returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import './libraries/SafeMath.sol';
import './modules/BaseShareField.sol';

interface ITomiPool {
    function queryReward(address _pair, address _user) external view returns(uint);
    function claimReward(address _pair, address _rewardToken) external;
}

interface ITomiPair {
    function queryReward() external view returns (uint256 rewardAmount, uint256 blockNumber);
    function mintReward() external returns (uint256 userReward);
}

interface ITomiDelegate {
    function addPlayerPair(address _user) external;
}

interface ITomiPlatform{
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    )
        external
        returns (
            uint256 _amountA,
            uint256 _amountB,
            uint256 _liquidity
        );
        
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 _amountToken,
            uint256 _amountETH,
            uint256 _liquidity
        );
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
    
    function pairFor(address tokenA, address tokenB) external view returns (address);
}

contract TomiLP is BaseShareField {
    // ERC20 Start
    
    using SafeMath for uint;

    string public constant name = 'Tomi LP';
    string public constant symbol = 'BLP';
    uint8 public constant decimals = 18;
    uint public totalSupply;
    
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Mint(address indexed user, uint amount);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }
    
    receive() external payable {
    }
    
    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _transfer(address from, address to, uint value) private {
        require(balanceOf[from] >= value, 'ERC20Token: INSUFFICIENT_BALANCE');
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        if (to == address(0)) { // burn
            totalSupply = totalSupply.sub(value);
        }

        ITomiDelegate(owner).addPlayerPair(to);
        _mintReward();
        _decreaseProductivity(from, value);
        _increaseProductivity(to, value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        require(allowance[from][msg.sender] >= value, 'ERC20Token: INSUFFICIENT_ALLOWANCE');
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }    
    
    // ERC20 End
    
    
    address public owner;
    address public POOL;
    address public PLATFORM;
    address public tokenA;
    address public tokenB;
    address public WETH;
    
    event AddLiquidity (address indexed user, uint amountA, uint amountB, uint value);
    event RemoveLiquidity (address indexed user, uint amountA, uint amountB, uint value);
    
    constructor() public {
        owner = msg.sender;
    }
    
    function initialize(address _tokenA, address _tokenB, address _TOMI, address _POOL, address _PLATFORM, address _WETH) external {
        require(msg.sender == owner, "Tomi LP Forbidden");
        tokenA = _tokenA;
        tokenB = _tokenB;
        _setShareToken(_TOMI);
        PLATFORM = _PLATFORM;
        POOL = _POOL;
        WETH = _WETH;
    }
 
    function upgrade(address _PLATFORM) external {
        require(msg.sender == owner, "Tomi LP Forbidden");
        PLATFORM = _PLATFORM;
    }

    function approveContract(address token, address spender, uint amount) internal {
        uint allowAmount = IERC20(token).totalSupply();
        if(allowAmount < amount) {
            allowAmount = amount;
        }
        if(IERC20(token).allowance(address(this), spender) < amount) {
            TransferHelper.safeApprove(token, spender, allowAmount);
        }
    }
    
    function addLiquidityETH(
        address user,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline) external payable returns (
            uint256 _amountToken,
            uint256 _amountETH,
            uint256 _liquidity
        ) {
           require(msg.sender == owner, "Tomi LP Forbidden");
           require(tokenA == WETH || tokenB == WETH, "INVALID CALL");
           address token = tokenA == WETH ? tokenB: tokenA;
           approveContract(token, PLATFORM, amountTokenDesired);
           TransferHelper.safeTransferFrom(token, msg.sender, address(this), amountTokenDesired);
           
           (_amountToken, _amountETH, _liquidity) = ITomiPlatform(PLATFORM).addLiquidityETH{value: msg.value}(token, amountTokenDesired, amountTokenMin, amountETHMin, deadline);
           
           if(amountTokenDesired > _amountToken) {
                TransferHelper.safeTransfer(token, user, amountTokenDesired.sub(_amountToken));
            }
            
            if(msg.value > _amountETH) {
                TransferHelper.safeTransferETH(user, msg.value.sub(_amountETH));
            }
        _mintReward();
        _mint(user, _liquidity);
        _increaseProductivity(user, _liquidity);
        (uint amountA, uint amountB) = token == tokenA ? (_amountToken, _amountETH): (_amountETH, _amountToken);
        emit AddLiquidity (user, amountA, amountB, _liquidity);
    }
    
    function addLiquidity(
        address user,
        uint256 amountA,
        uint256 amountB,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline) external returns (
            uint256 _amountA,
            uint256 _amountB,
            uint256 _liquidity
        ) {
            require(msg.sender == owner, "Tomi LP Forbidden");
            approveContract(tokenA, PLATFORM, amountA);
            approveContract(tokenB, PLATFORM, amountB);
            TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), amountA);
            TransferHelper.safeTransferFrom(tokenB, msg.sender, address(this), amountB);
        (_amountA, _amountB, _liquidity) = ITomiPlatform(PLATFORM).addLiquidity(tokenA, tokenB, amountA, amountB, amountAMin, amountBMin, deadline);
        if(amountA > _amountA) {
            TransferHelper.safeTransfer(tokenA, user, amountA.sub(_amountA));
        }
        
        if(amountB > _amountB) {
            TransferHelper.safeTransfer(tokenB, user, amountB.sub(_amountB));
        }
        
        _mintReward();
        _mint(user, _liquidity);
        _increaseProductivity(user, _liquidity);
        emit AddLiquidity (user, _amountA, _amountB, _liquidity);
    }
    
    function removeLiquidityETH (
        address user,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline) external returns (uint256 _amountToken, uint256 _amountETH) {
         require(msg.sender == owner, "Tomi LP Forbidden");
         require(tokenA == WETH || tokenB == WETH, "INVALID CALL");
         address token = tokenA == WETH ? tokenB: tokenA;
           
        (_amountToken, _amountETH) = ITomiPlatform(PLATFORM).removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, user, deadline);
         
        _mintReward();
        _burn(user, liquidity);
        _decreaseProductivity(user, liquidity);
        (uint amountA, uint amountB) = token == tokenA ? (_amountToken, _amountETH): (_amountETH, _amountToken);
        emit RemoveLiquidity (user, amountA, amountB, liquidity);
    }
    
    function removeLiquidity(
        address user,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline) external returns (
            uint256 _amountA,
            uint256 _amountB
        ) {
            require(msg.sender == owner, "Tomi LP Forbidden");
        (_amountA, _amountB) = ITomiPlatform(PLATFORM).removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, user, deadline);
        
        _mintReward();
        _burn(user, liquidity);
        _decreaseProductivity(user, liquidity);
        emit RemoveLiquidity (user, _amountA, _amountB, liquidity);
    }
    
    function _currentReward() internal override view returns (uint) {
        address pair = ITomiPlatform(PLATFORM).pairFor(tokenA, tokenB);
        uint countractAmount = mintedShare.add(IERC20(shareToken).balanceOf(address(this))).sub(totalShare);
        if(pair != address(0)) {
            uint poolAmount = ITomiPool(POOL).queryReward(pair, address(this));
            // (uint pairAmount, ) = ITomiPair(pair).queryReward();
            // return countractAmount.add(poolAmount).add(pairAmount);
            return countractAmount.add(poolAmount);
        } else {
            return countractAmount;
        }
    }
    
    function _mintReward() internal {
        address pair = ITomiPlatform(PLATFORM).pairFor(tokenA, tokenB);
        if(pair != address(0)) {
            uint poolAmount = ITomiPool(POOL).queryReward(pair, address(this));
            // (uint pairAmount, ) = ITomiPair(pair).queryReward();
            if(poolAmount > 0) {
                ITomiPool(POOL).claimReward(pair, shareToken);
            }
            
            // if(pairAmount > 0) {
            //     ITomiPair(pair).mintReward();
            // }
        } 
    }
    
    function queryReward() external view returns (uint) {
        return _takeWithAddress(msg.sender);
    }
    
    function mintReward() external returns (uint amount) {
        _mintReward();
        amount = _mint(msg.sender);
        emit Mint(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import './TomiLP.sol';
import './modules/Ownable.sol';

interface ITomiLP {
    function addLiquidity(
        address user,
        uint256 amountA,
        uint256 amountB,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline) external returns (
            uint256 _amountA,
            uint256 _amountB,
            uint256 _liquidity
        );
    function removeLiquidity(
        address user,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline) external returns (
            uint256 _amountA,
            uint256 _amountB
        );
    function addLiquidityETH(
        address user,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline) external payable returns (
            uint256 _amountToken,
            uint256 _amountETH,
            uint256 _liquidity
        );
    function removeLiquidityETH (
        address user,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline) external returns (uint256 _amountToken, uint256 _amountETH);
    function initialize(address _tokenA, address _tokenB, address _TOMI, address _POOL, address _PLATFORM, address _WETH) external;
    function upgrade(address _PLATFORM) external;
    function tokenA() external returns(address);
}

contract TomiDelegate is Ownable{
    using SafeMath for uint;
    
    address public PLATFORM;
    address public POOL;
    address public TOMI;
    address public WETH;
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    mapping(address => bool) public isPair;
    mapping(address => address[]) public playerPairs;
    mapping(address => mapping(address => bool)) public isAddPlayerPair;

    bytes32 public contractCodeHash;
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
    
    constructor(address _PLATFORM, address _POOL, address _TOMI, address _WETH) public {
        PLATFORM = _PLATFORM;
        POOL = _POOL;
        TOMI = _TOMI;
        WETH = _WETH;
    }
    
    receive() external payable {
    }
    
    function upgradePlatform(address _PLATFORM) external onlyOwner {
        for(uint i = 0; i < allPairs.length;i++) {
            ITomiLP(allPairs[i]).upgrade(_PLATFORM);
        }
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function getPlayerPairCount(address player) external view returns (uint256) {
        return playerPairs[player].length;
    }

    function _addPlayerPair(address _user, address _pair) internal {
        if (isAddPlayerPair[_user][_pair] == false) {
            isAddPlayerPair[_user][_pair] = true;
            playerPairs[_user].push(_pair);
        }
    }

    function addPlayerPair(address _user) external {
        require(isPair[msg.sender], 'addPlayerPair Forbidden');
        _addPlayerPair(_user, msg.sender);
    }
    
    function approveContract(address token, address spender, uint amount) internal {
        uint allowAmount = IERC20(token).totalSupply();
        if(allowAmount < amount) {
            allowAmount = amount;
        }
        if(IERC20(token).allowance(address(this), spender) < amount) {
            TransferHelper.safeApprove(token, spender, allowAmount);
        }
    }

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
        ) payable external returns (
            uint256 _amountToken,
            uint256 _amountETH,
            uint256 _liquidity
        ) {
        address pair = getPair[token][WETH];
            if(pair == address(0)) {
                pair = _createPair(token, WETH);
            }
            
            _addPlayerPair(msg.sender, pair);

            TransferHelper.safeTransferFrom(token, msg.sender, address(this), amountTokenDesired);
            approveContract(token, pair, amountTokenDesired);
            (_amountToken, _amountETH, _liquidity) = ITomiLP(pair).addLiquidityETH{value: msg.value}(msg.sender, amountTokenDesired, amountTokenMin, amountETHMin, deadline);
    }
    
    
    
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline) external returns (
            uint256 _amountA,
            uint256 _amountB,
            uint256 _liquidity
        ) {
            address pair = getPair[tokenA][tokenB];
            if(pair == address(0)) {
                pair = _createPair(tokenA, tokenB);
            }

            _addPlayerPair(msg.sender, pair);

            if(tokenA != ITomiLP(pair).tokenA()) {
                (tokenA, tokenB) = (tokenB, tokenA);
                (amountA, amountB, amountAMin, amountBMin) = (amountB, amountA, amountBMin, amountAMin);
            }
            
            TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), amountA);
            TransferHelper.safeTransferFrom(tokenB, msg.sender, address(this), amountB);
            approveContract(tokenA, pair, amountA);
            approveContract(tokenB, pair, amountB);

            (_amountA, _amountB, _liquidity) = ITomiLP(pair).addLiquidity(msg.sender, amountA, amountB, amountAMin, amountBMin, deadline);
            if(tokenA != ITomiLP(pair).tokenA()) {
                (_amountA, _amountB) = (_amountB, _amountA);
            }
    }
    
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        uint deadline
        ) external returns (uint _amountToken, uint _amountETH) {
            address pair = getPair[token][WETH];
            (_amountToken, _amountETH) = ITomiLP(pair).removeLiquidityETH(msg.sender, liquidity, amountTokenMin, amountETHMin, deadline);
        }
    
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline) external returns (
            uint256 _amountA,
            uint256 _amountB
        ) {
        address pair = getPair[tokenA][tokenB];
        (_amountA, _amountB) = ITomiLP(pair).removeLiquidity(msg.sender, liquidity, amountAMin, amountBMin, deadline);
    }

    function _createPair(address tokenA, address tokenB) internal returns (address pair){
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'TOMI FACTORY: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'TOMI FACTORY: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(TomiLP).creationCode;
        if (uint256(contractCodeHash) == 0) {
            contractCodeHash = keccak256(bytecode);
        }
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        isPair[pair] = true;
        ITomiLP(pair).initialize(token0, token1, TOMI, POOL, PLATFORM, WETH);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import '../interfaces/ERC2917-Interface.sol';
import '../modules/Upgradable.sol';
import '../libraries/SafeMath.sol';

/*
    The Objective of ERC2917 Demo is to implement a decentralized staking mechanism, which calculates users' share
    by accumulating productiviy * time. And calculates users revenue from anytime t0 to t1 by the formula below:

        user_accumulated_productivity(time1) - user_accumulated_productivity(time0)
       _____________________________________________________________________________  * (gross_product(t1) - gross_product(t0))
       total_accumulated_productivity(time1) - total_accumulated_productivity(time0)

*/
contract ERC2917Impl is IERC2917, UpgradableProduct, UpgradableGovernance {
    using SafeMath for uint;

    uint public mintCumulation;
    uint public amountPerBlock;

    uint public nounce;

    function incNounce() public {
        nounce ++;
    }

    // implementation of ERC20 interfaces.
    string override public name;
    string override public symbol;
    uint8 override public decimals = 18;
    uint override public totalSupply;

    mapping(address => uint) override public balanceOf;
    mapping(address => mapping(address => uint)) override public allowance;

    function _transfer(address from, address to, uint value) internal virtual {
        require(balanceOf[from] >= value, 'ERC20Token: INSUFFICIENT_BALANCE');
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        if (to == address(0)) { // burn
            totalSupply = totalSupply.sub(value);
        }
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external virtual override  returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external virtual override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external virtual override returns (bool) {
        require(allowance[from][msg.sender] >= value, 'ERC20Token: INSUFFICIENT_ALLOWANCE');
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    // end of implementation of ERC20
    
    uint lastRewardBlock;
    uint totalProductivity;
    uint accAmountPerShare;
    struct UserInfo {
        uint amount;     // How many LP tokens the user has provided.
        uint rewardDebt; // Reward debt. 
        uint rewardEarn; // Reward earn and not minted
    }

    mapping(address => UserInfo) public users;

    // creation of the interests token.
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint _interestsRate) UpgradableProduct() UpgradableGovernance() public {
        name        = _name;
        symbol      = _symbol;
        decimals    = _decimals;

        amountPerBlock = _interestsRate;
    }

    // External function call
    // This function adjust how many token will be produced by each block, eg:
    // changeAmountPerBlock(100)
    // will set the produce rate to 100/block.
    function changeInterestRatePerBlock(uint value) external virtual override requireGovernor returns (bool) {
        uint old = amountPerBlock;
        require(value != old, 'AMOUNT_PER_BLOCK_NO_CHANGE');

        _update();
        amountPerBlock = value;

        emit InterestRatePerBlockChanged(old, value);
        return true;
    }

    // Update reward variables of the given pool to be up-to-date.
    function _update() internal virtual {
        if (block.number <= lastRewardBlock) {
            return;
        }

        if (totalProductivity == 0) {
            lastRewardBlock = block.number;
            return;
        }
        
        uint256 reward = _currentReward();
        balanceOf[address(this)] = balanceOf[address(this)].add(reward);
        totalSupply = totalSupply.add(reward);

        accAmountPerShare = accAmountPerShare.add(reward.mul(1e12).div(totalProductivity));
        lastRewardBlock = block.number;
    }
    
    function _currentReward() internal virtual view returns (uint){
        uint256 multiplier = block.number.sub(lastRewardBlock);
        return multiplier.mul(amountPerBlock);
    }
    
    // Audit user's reward to be up-to-date
    function _audit(address user) internal virtual {
        UserInfo storage userInfo = users[user];
        if (userInfo.amount > 0) {
            uint pending = userInfo.amount.mul(accAmountPerShare).div(1e12).sub(userInfo.rewardDebt);
            userInfo.rewardEarn = userInfo.rewardEarn.add(pending);
            mintCumulation = mintCumulation.add(pending);
            userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        }
    }

    // External function call
    // This function increase user's productivity and updates the global productivity.
    // the users' actual share percentage will calculated by:
    // Formula:     user_productivity / global_productivity
    function increaseProductivity(address user, uint value) external virtual override requireImpl returns (bool) {
        require(value > 0, 'PRODUCTIVITY_VALUE_MUST_BE_GREATER_THAN_ZERO');

        UserInfo storage userInfo = users[user];
        _update();
        _audit(user);

        totalProductivity = totalProductivity.add(value);

        userInfo.amount = userInfo.amount.add(value);
        userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        emit ProductivityIncreased(user, value);
        return true;
    }

    // External function call 
    // This function will decreases user's productivity by value, and updates the global productivity
    // it will record which block this is happenning and accumulates the area of (productivity * time)
    function decreaseProductivity(address user, uint value) external virtual override requireImpl returns (bool) {
        UserInfo storage userInfo = users[user];
        require(value > 0 && userInfo.amount >= value, "INSUFFICIENT_PRODUCTIVITY");
        _update();
        _audit(user);
        
        userInfo.amount = userInfo.amount.sub(value);
        userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        totalProductivity = totalProductivity.sub(value);

        emit ProductivityDecreased(user, value);
        return true;
    }
    
    function takeWithAddress(address user) public view returns (uint) {
        UserInfo storage userInfo = users[user];
        uint _accAmountPerShare = accAmountPerShare;
        // uint256 lpSupply = totalProductivity;
        if (block.number > lastRewardBlock && totalProductivity != 0) {
            uint reward = _currentReward();
            _accAmountPerShare = _accAmountPerShare.add(reward.mul(1e12).div(totalProductivity));
        }
        return userInfo.amount.mul(_accAmountPerShare).div(1e12).sub(userInfo.rewardDebt).add(userInfo.rewardEarn);
    }

    function take() external override virtual view returns (uint) {
        return takeWithAddress(msg.sender);
    }

    // Returns how much a user could earn plus the giving block number.
    function takeWithBlock() external override virtual view returns (uint, uint) {
        uint earn = takeWithAddress(msg.sender);
        return (earn, block.number);
    }


    // External function call
    // When user calls this function, it will calculate how many token will mint to user from his productivity * time
    // Also it calculates global token supply from last time the user mint to this time.
    function mint() external override virtual returns (uint) {
        _update();
        _audit(msg.sender);
        require(users[msg.sender].rewardEarn > 0, "NO_PRODUCTIVITY");
        uint amount = users[msg.sender].rewardEarn;
        _transfer(address(this), msg.sender, users[msg.sender].rewardEarn);
        users[msg.sender].rewardEarn = 0;
        return amount;
    }

    // Returns how many productivity a user has and global has.
    function getProductivity(address user) external override virtual view returns (uint, uint) {
        return (users[user].amount, totalProductivity);
    }

    // Returns the current gorss product rate.
    function interestsPerBlock() external override virtual view returns (uint) {
        return accAmountPerShare;
    }
}

pragma solidity >=0.5.16;

contract UpgradableProduct {
    address public impl;

    event ImplChanged(address indexed _oldImpl, address indexed _newImpl);

    constructor() public {
        impl = msg.sender;
    }

    modifier requireImpl() {
        require(msg.sender == impl, 'FORBIDDEN');
        _;
    }

    function upgradeImpl(address _newImpl) public requireImpl {
        require(_newImpl != address(0), 'INVALID_ADDRESS');
        require(_newImpl != impl, 'NO_CHANGE');
        address lastImpl = impl;
        impl = _newImpl;
        emit ImplChanged(lastImpl, _newImpl);
    }
}

contract UpgradableGovernance {
    address public governor;

    event GovernorChanged(address indexed _oldGovernor, address indexed _newGovernor);

    constructor() public {
        governor = msg.sender;
    }

    modifier requireGovernor() {
        require(msg.sender == governor, 'FORBIDDEN');
        _;
    }

    function upgradeGovernance(address _newGovernor) public requireGovernor {
        require(_newGovernor != address(0), 'INVALID_ADDRESS');
        require(_newGovernor != governor, 'NO_CHANGE');
        address lastGovernor = governor;
        governor = _newGovernor;
        emit GovernorChanged(lastGovernor, _newGovernor);
    }
}

pragma solidity >=0.5.16;

import '../modules/ERC2917Impl.sol';

contract TgasTest is ERC2917Impl("Demax Gas", "DGAS", 18, 1 * (10 ** 18)) {

    constructor() public {
        totalSupply += 1000000000000000* 10 ** 18;
        balanceOf[msg.sender] = 1000000000000000* 10 ** 18;   
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import './TomiPair.sol';
import './interfaces/ITomiConfig.sol';

contract TomiFactory {
    uint256 public version = 1;
    address public TOMI;
    address public CONFIG;
    address public owner;
    mapping(address => mapping(address => address)) public getPair;
    mapping(address => bool) public isPair;
    address[] public allPairs;

    mapping(address => address[]) public playerPairs;
    mapping(address => mapping(address => bool)) isAddPlayerPair;

    bytes32 public contractCodeHash;
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    constructor(address _TOMI, address _CONFIG) public {
        TOMI = _TOMI;
        CONFIG = _CONFIG;
        owner = msg.sender;
    }

    function updateConfig(address _CONFIG) external {
        require(msg.sender == owner, 'TOMI FACTORY: PERMISSION');
        CONFIG = _CONFIG;
        for(uint i = 0; i < allPairs.length; i ++) {
            TomiPair(allPairs[i]).initialize(TomiPair(allPairs[i]).token0(), TomiPair(allPairs[i]).token1(), _CONFIG, TOMI);
        }
    }

    function getPlayerPairCount(address player) external view returns (uint256) {
        address[] storage existAddress = playerPairs[player];
        if (existAddress.length == 0) return 0;
        return existAddress.length;
    }

    function addPlayerPair(address _player, address _pair) external returns (bool) {
        require(msg.sender == ITomiConfig(CONFIG).platform(), 'TOMI FACTORY: PERMISSION');
        if (isAddPlayerPair[_player][_pair] == false) {
            isAddPlayerPair[_player][_pair] = true;
            playerPairs[_player].push(_pair);
        }
        return true;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(msg.sender == ITomiConfig(CONFIG).platform(), 'TOMI FACTORY: PERMISSION');
        require(tokenA != tokenB, 'TOMI FACTORY: IDENTICAL_ADDRESSES');
        require(
            ITomiConfig(CONFIG).checkToken(tokenA) && ITomiConfig(CONFIG).checkToken(tokenB),
            'TOMI FACTORY: NOT LIST'
        );
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'TOMI FACTORY: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'TOMI FACTORY: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(TomiPair).creationCode;
        if (uint256(contractCodeHash) == 0) {
            contractCodeHash = keccak256(bytecode);
        }
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        isPair[pair] = true;
        TomiPair(pair).initialize(token0, token1, CONFIG, TOMI);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
}

pragma solidity >=0.5.16;

import '../libraries/SafeMath.sol';

contract ERC20Token {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    function _transfer(address from, address to, uint value) private {
        require(balanceOf[from] >= value, 'ERC20Token: INSUFFICIENT_BALANCE');
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        if (to == address(0)) { // burn
            totalSupply = totalSupply.sub(value);
        }
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        require(allowance[from][msg.sender] >= value, 'ERC20Token: INSUFFICIENT_ALLOWANCE');
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

import '../modules/ERC20Token.sol';

contract ERC20 is ERC20Token {
    constructor(uint _totalSupply, string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = totalSupply;
    }
}

