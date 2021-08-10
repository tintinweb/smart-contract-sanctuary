/**
 *Submitted for verification at BscScan.com on 2021-08-09
*/

// File: Kemfe Governance/SafeDecimalMath.sol

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.0 < 0.7.0;

// Libraries



// https://docs.synthetix.io/contracts/SafeDecimalMath
library SafeDecimalMath {
    using SafeMath for uint;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint public constant UNIT = 10**uint(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint public constant PRECISE_UNIT = 10**uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint x, uint y) internal pure returns (uint) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }
}


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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



pragma solidity >=0.4.0 <0.7.0;
/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


pragma solidity >=0.4.0 <0.7.0;

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
    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

pragma experimental ABIEncoderV2;
pragma solidity >=0.4.22 <0.9.0;



interface IERC20 {
    function totalSupply() external view  returns (uint256);
    function balanceOf(address account) external view  returns (uint256);
    function transfer(address recipient, uint256 amount) external  returns (bool);
    function allowance(address owner, address spender) external  view returns (uint256);
    function approve(address spender, uint256 amount) external  returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount)  external  returns (bool);
    function mint(address account, uint256 amount) external  returns (bool);
    function burnFrom(address account, uint256 amount) external;
}
contract KEMFEGOVERNANCE is Ownable{
    using SafeDecimalMath for uint;
    using SafeMath for uint;
    address private kem;
    mapping(address => uint) _balance;
    mapping(address => uint) _powerUps;
    mapping(uint => mapping(address => uint)) totalVotePwoer;
   
    mapping(bytes => uint) rewardPools;
    mapping(bytes => bool) isRewardPoolSuspended;
    mapping(bytes => bool) isAdded;
    struct Votters{
      address payable voter;
    }
    uint currentPeriod;
    Proposals[] proposals;
    mapping(uint => uint) proposalSystemTotalPower;
    mapping(uint => mapping(address => uint)) proposalUserTotalPower;
    mapping(bytes => mapping(uint=> bool)) stale;
    enum ProposalTypes {CREATE, DELETE, MINT, CHANGE, REGULATE}
    mapping(uint => mapping(address => bool)) voted;
    mapping(uint => mapping(address => bool)) period;
   
    mapping(uint => mapping(address => uint)) proposalPower;
    mapping(uint => Votters[]) listOfVoters;
    mapping(uint => Votters[]) listOfActiveVoters;
    mapping(ProposalTypes => bool) activeProposal;
    struct Proposals {
        ProposalTypes proposalType;
        string desc;
        uint value;
        uint votingPeriod;
        uint accepted;
        uint rejected;
        bool stale;
        string key;
        bool state;
    }
    
   struct RewardPool {
       string name;
       uint amount;
       bool suspended;
   }
   mapping(bytes => RewardPool) pools; 
   
event AddedMessenger(address prev, address curr);
event ProposalCreated(uint _proposalID, ProposalTypes _proposalType,string _desc, uint _value, string _key, bool _state);
event PoolSuspended(string _poolType);
event PoolIncreased(string _poolType);
event Deposited(address _user, uint _amount, uint _time);
event Powered(address _user, uint _amount, uint _time);
event Withdraw(address _user, uint _amount, uint _time);
event Refunded(uint _amount, address _voterAddress, uint _proposalID, uint _time);
event ProposalValidated(uint _proposalID, bool _state, address _validator);
event Rewarded(uint _share, address _voterAddress, string _key,uint _time, uint _period); 
event Voted(address _user, uint _proposalsID, uint _amount, uint _accepted, uint _rejected, bool _accept,  ProposalTypes typeOfProposal);
event Period(uint _period, string _key);
address messenger;
constructor(address _kem) public{
    kem = _kem;
    currentPeriod = currentPeriod.add(1);
}
function createProposal(ProposalTypes _proposalType, uint _value, string memory _desc, string memory _key, bool _state) external returns(bool){
     require(_proposalType == ProposalTypes.CREATE || _proposalType == ProposalTypes.DELETE || _proposalType == ProposalTypes.CHANGE
    ||  _proposalType == ProposalTypes.MINT,  "Invalid proposal type!");
    require(bytes(_desc).length > 0, "Add description.");
    require(!activeProposal[_proposalType], "Another proposal is still active");
    string memory convertedKey = _toLower(_key);
    
        
      Proposals memory _proposal = Proposals({
      proposalType: _proposalType,
      desc: _desc,
      value: _value,
      votingPeriod: block.timestamp.add(7 days),
      accepted: 0,
      rejected: 0,
      stale: false,
      key: convertedKey,
      state: _state
      
    });
    
    proposals.push(_proposal);
    uint256 newProposalID = proposals.length - 1;
     Proposals memory proposal = proposals[newProposalID];
     
     
    emit ProposalCreated(newProposalID ,proposal.proposalType, proposal.desc, proposal.value, proposal.key, proposal.state);
}

function governanceVote(ProposalTypes _proposalType, uint _proposalID, uint _votePower, bool _accept) external{
    Proposals storage proposal = proposals[_proposalID];
    require(proposal.votingPeriod >= block.timestamp, "Voting period has ended");
    require(_votePower > 0, "Power must be greater than zero!");
    require(_proposalType == ProposalTypes.CREATE || _proposalType == ProposalTypes.DELETE || _proposalType == ProposalTypes.CHANGE
    ||  _proposalType == ProposalTypes.MINT,  "Invalid proposal type!");
    IERC20 iERC20 = IERC20(kem);
    require(iERC20.allowance(msg.sender, address(this)) >= _votePower, "Insufficient KEM allowance for vote!");
    require(iERC20.transferFrom(msg.sender, address(this), _votePower), "Error");
    proposalPower[_proposalID][msg.sender] = proposalPower[_proposalID][msg.sender].add(_votePower);
    proposalUserTotalPower[currentPeriod][msg.sender] = proposalUserTotalPower[currentPeriod][msg.sender].add(_votePower);
    proposalSystemTotalPower[currentPeriod] = proposalSystemTotalPower[currentPeriod].add(_votePower);
    _accept ? proposal.accepted = proposal.accepted.add(_votePower) : proposal.rejected = proposal.rejected.add(_votePower);
        
        if(voted[_proposalID][msg.sender] == false){
            voted[_proposalID][msg.sender] = true;
            listOfVoters[_proposalID].push(Votters(msg.sender));
        }
        
         if(period[currentPeriod][msg.sender] == false){
            period[_proposalID][msg.sender] = true;
            listOfActiveVoters[currentPeriod].push(Votters(msg.sender));
        }
            
      emit Voted(msg.sender, _proposalID, _votePower, proposal.accepted, proposal.rejected, _accept, _proposalType);
           
    
}

     modifier onlyMessenger() {
        require(messenger == _msgSender(), " Caller is not a messenger");
        _;
    }
    
    
function createPool(string memory _name, uint _value) internal returns(bool){
     bytes memory key = bytes(_name);
     
      if (bytes(pools[key].name).length > 0) {
             // Don't overwrite previous mappings and return false
             return false;
         }
         
        RewardPool storage pool = pools[key];
        pool.name = _name;
        pool.amount = _value;
        
        
       
        return true;
        
        
     
}
function regulatePool(string memory _name, bool _state) internal returns(bool){
     bytes memory key = bytes(_name);
     require(bytes(pools[key].name).length > 0 && !pools[key].suspended, "Invalid pool/or pool already suspended.");
     RewardPool storage pool = pools[key];
     pool.suspended = _state;
     
     return true;
     
      
}

function deletePool(string memory _name) internal returns(bool){
     bytes memory key = bytes(_name);
     require(bytes(pools[key].name).length > 0, "Invalid pool/or pool already deleted.");
     delete pools[key];
     return true;
        
        
}

function increasePool(string memory _name, uint _value) internal returns(bool _increased){
     bytes memory key = bytes(_name);
     require(bytes(pools[key].name).length > 0 && !pools[key].suspended, "Invalid pool/or pool already suspended");
     RewardPool storage pool = pools[key];
     pool.amount = _value;
     return true;
}

function deposit(uint _amount) external{
    require(_amount > 0, "The amount must be greater than zero!");
    require(_powerUps[msg.sender] > 0, "You have not unlocked your wallet");
    IERC20 iERC20 = IERC20(kem);
    require(iERC20.allowance(msg.sender, address(this)) >= _amount, "Insufficient allowance!");
    require(iERC20.transferFrom(msg.sender, address(this), _amount), "Sending funds failed!");
    _balance[msg.sender] =  _balance[msg.sender].add(_amount);
    emit Deposited(msg.sender, _amount, now);
    
}

function powerUp(uint _amount) external{
    require(_amount > 0, "The amount must be greater than zero!");
    require(_powerUps[msg.sender] == 0, "You cannot unlock power twice");
    IERC20 iERC20 = IERC20(kem);
    require(iERC20.allowance(msg.sender, address(this)) >= _amount, "Insufficient allowance!");
    require(iERC20.transferFrom(msg.sender, address(this), _amount), "Sending funds failed!");
    _powerUps[msg.sender] = _powerUps[msg.sender].add(_amount);
    emit Powered(msg.sender, _amount, now);
    
}


function validateProposal(uint _proposalID) external{
    Proposals storage proposal = proposals[_proposalID];
    require(block.timestamp >= proposal.votingPeriod, "Voting period still active");
    require(!proposal.stale, "This proposal has already been validated");
    
    IERC20 _kem = IERC20(kem);
    if(proposal.proposalType == ProposalTypes.CREATE){
        if(proposal.accepted >= proposal.rejected){
            require(createPool(proposal.desc, proposal.value), "Could not proposal.");
            proposal.stale = true;
        }
        
    }else if(proposal.proposalType == ProposalTypes.MINT){
        if(proposal.accepted >= proposal.rejected){
            require(_kem.mint(address(this), proposal.value), "Could not mint token or address is not a minter");
            proposal.stale = true;
        }
        
    }else if(proposal.proposalType == ProposalTypes.DELETE){
        if(proposal.accepted >= proposal.rejected){
            require(deletePool(proposal.key), "Could not delete pool!");
            proposal.stale = true;
        }
        
    }else if(proposal.proposalType == ProposalTypes.CHANGE){
        if(proposal.accepted >= proposal.rejected){
            require(increasePool(proposal.key, proposal.value), "Could not change pool value!");
            proposal.stale = true;
        }
        
    }else if(proposal.proposalType == ProposalTypes.REGULATE){
        if(proposal.accepted >= proposal.rejected){
            require(regulatePool(proposal.key, proposal.state), "Could not regulate pool!");
            proposal.stale = true;
        }
        
    }
    
    for (uint256 i = 0; i < listOfVoters[_proposalID].length; i++) {
           address voterAddress = listOfVoters[_proposalID][i].voter;
           uint amount = proposalPower[_proposalID][voterAddress];
           require(_kem.transfer(voterAddress, amount), "Fail to refund voter");
           proposalPower[_proposalID][voterAddress] = 0;
           emit Refunded(amount, voterAddress, _proposalID, now);
    }
    
   
    emit ProposalValidated(_proposalID, proposal.accepted >= proposal.rejected, msg.sender);
}



function withdraw(uint _amount, address _recipient) external onlyMessenger{
    require(_amount > 0, "The amount must be greater than zero!");
    IERC20 iERC20 = IERC20(kem);
    require(iERC20.balanceOf(address(this)) >= _amount, "Insufficient funds for withdrawal!");
    require(iERC20.transfer(_recipient, _amount), "Withdrawing funds failed!");
    emit Withdraw(_recipient, _amount, now);
    
}

function userStats(address _user) external view returns(uint balance, uint powerUps){
    return(_balance[_user], _powerUps[_user]);
}

function setMessenger(address _messenger) onlyOwner external{
    address preMessenger = messenger;
    messenger = _messenger;
    
    emit AddedMessenger(preMessenger, _messenger);
}

function rewardVoters(uint _period, string memory _key) external{
    bytes memory key = bytes(_toLower(_key));
    RewardPool memory pool = pools[key];
    require(pool.amount > 0, "Invalid pool or pool deleted!");
  
    require(!stale[key][_period], "Rewarded.");
     
     
     IERC20 _kem = IERC20(kem);
       for (uint256 i = 0; i < listOfActiveVoters[_period].length; i++) {
            address voterAddress = listOfActiveVoters[_period][i].voter;


            // Start of reward calc
            uint totalUserVotePower = proposalUserTotalPower[_period][voterAddress].mul(1000);
            uint currentTotalPower = proposalSystemTotalPower[_period];
            uint percentage = totalUserVotePower.div(currentTotalPower);
            uint share = percentage.mul(pool.amount).div(1000);
            // End of reward calc
            
           
           require(_kem.transfer(voterAddress, share), "Fail to refund voter");
           emit Rewarded(share, voterAddress, _key, now, _period); 
       }
     
      currentPeriod = currentPeriod.add(1);
       emit Period(_period, _key);     
}

function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
    

 
}