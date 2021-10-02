/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
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
    constructor () {
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

interface NFT {
function ownerOf(uint256 tokenId) external view returns (address);
function mint(address to, uint tokenID) external returns(bool);
function burn(uint tokenID) external returns(bool);
  
}
contract EgorasV2 is Ownable{
   using SafeDecimalMath for uint;
    mapping(uint => bool) activeRequest;
    mapping(uint => mapping(address => uint)) requestPower;
     struct Loan{
        string title;
        uint amount;
        uint length;
        string image_url;
        address creator;
        bool isloan;
        string loanMetaData;
        uint inventoryFee;
        bool isConfirmed;
    }

   Loan[] loans;
   Votters[] voters;
   struct Votters{
      address voter;
    }
    struct Requests{
      address creator;
      uint requestType;
      uint backers;
      uint company;
      uint branch;
      uint incentive;
      uint threshold;
      string reason;
      bool stale;
      
    }
    event RequestCreated(
      address _creator,
      uint _requestType,
      uint _backers,
      uint _company,
      uint _branch,
      uint _incentive,
      string _reason,
      uint _threshold,
      bool _stale,
      uint _requestID
      );
  event ApproveRequest(uint _requestID, bool _state, address _initiator);    
  Requests[] requests;
  mapping(uint => Votters[]) listOfvoters;
  mapping(uint => mapping(address => bool)) hasVoted;
  mapping(uint => bool) stale;
  mapping(uint => mapping(address => uint)) userVoteAmount;
  mapping(uint => uint) requestVoteAmount;
  mapping(uint => uint) loanVoteAmount;
  mapping(uint => uint) buyVoteAmount;
  mapping(uint => bool) isApproved;
  using SafeMath for uint256;
  address private egorasEUSD;
  address private egorasEGC;
  address private eNFTAddress;
  address private egorasEGR;
  uint private votingThreshold;
  uint private systemFeeBalance;
  uint private requestCreationPower;
  uint public backers;
  uint public company;
  uint public branch;
  uint public dailyIncentive;
  mapping(uint => uint) backersReward;
  mapping(uint => uint) companyReward;
  mapping(uint => uint) branchReward;
  mapping(address => bool)  branchAddress;
  mapping(address => address) branchRewardAddress;
  mapping(uint => mapping(address => bool)) manageRequestVoters;
  mapping(uint => mapping(address => bool)) currentVoters;
  mapping(uint => Votters[]) curVoters;
  mapping(uint => Votters[]) requestVoters;
  mapping(uint => mapping(address => uint)) votePower;
  uint private currentPeriod;
  uint public nextRewardDate;
  mapping(uint => uint) currentTotalVotePower;
  mapping(uint => bool) canReward;
  mapping(uint => mapping(address => uint)) currentUserTotalVotePower;
  event Repay(uint _amount, uint _time, uint _loanID);
    event ApproveLoan(uint _loanID, bool state, address initiator, uint time);
      event RequestVote(
        address _voter,
        uint _requestID,
        uint _power,
        uint _totalPower
        
    );
    event Bought(uint _id, string _metadata, uint _time);
    event Refunded(uint amount, address voterAddress, uint _id, uint time);
    event Rewarded(uint amount, address voterAddress, uint _id, uint time);
    
    event LoanCreated(
        uint newLoanID, string _title,  uint _amount,  uint _length, 
       string _image_url, uint _inventoryFee, address _creator, bool _isLoan, bool _isConfirmed
);
event Voted(address voter,  uint loanID, uint _totalBackedAmount, uint _userPower);

  constructor(
address _egorasEusd, address _egorasEgr, address _egorasEGC, uint _votingThreshold
    , uint _backers, uint _company, uint _branch){
        require(address(0) != _egorasEusd, "Invalid address");
        require(address(0) != _egorasEgr, "Invalid address");
         require(address(0) != _egorasEGC, "Invalid address");
        egorasEGR = _egorasEgr;
        egorasEUSD = _egorasEusd;
        egorasEGC  = _egorasEGC;
        votingThreshold = _votingThreshold;
        backers = _backers;
        company = _company;
        branch = _branch;
        nextRewardDate = block.timestamp.add(1 days);
        currentPeriod = block.timestamp;
  }

   function addBranch(address _branch, address _branchRewardAddress) external onlyOwner returns(bool){
        branchAddress[_branch] = true;
        branchRewardAddress[_branch] = _branchRewardAddress;
        return true;
    }
     function addNFTAddress(address _eNFTAddress) external onlyOwner returns(bool){
        eNFTAddress = _eNFTAddress;
        return true;
    }
   function suspendBranch(address _branch) external onlyOwner returns(bool) {
       branchAddress[_branch] = false;
       return true;
   }

    /*** Restrict access to Branch role*/    
      modifier onlyBranch() {        
        require(branchAddress[msg.sender] == true, "Address is not allowed to upload a loan!");       
        _;}
 
    /// Request
function createRequest(uint _requestType,uint _threshold, uint _incentive, uint _backers, uint _company, uint _branch, string memory _reason) public onlyOwner{
    require(_requestType >= 0 && _requestType <  2,  "Invalid request type!");
    require(!activeRequest[_requestType], "Another request is still active");
    Requests memory _request = Requests({
      creator: msg.sender,
      requestType: _requestType,
      backers: _backers,
      company: _company,
      branch: _branch,
      incentive: _incentive,
      reason: _reason,
      stale: false,
      threshold: _threshold
     
    });
    
    requests.push(_request);
    uint256 newRequestID = requests.length - 1;
     Requests memory request = requests[newRequestID];
    emit RequestCreated(
      request.creator,
      request.requestType,
      request.backers,
      request.company,
      request.branch,
      request.incentive,
      request.reason,
      request.threshold,
      request.stale,
      newRequestID
      );
     
}

function governanceVote(uint _requestID, uint _votePower) public{
    require(_votePower > 0, "Power must be greater than zero!");
    IERC20 iERC20 = IERC20(egorasEGR);
    require(iERC20.allowance(msg.sender, address(this)) >= _votePower, "Insufficient EGR allowance for vote!");
    require(iERC20.transferFrom(msg.sender, address(this), _votePower), "Error");
    requestPower[_requestID][msg.sender] = requestPower[_requestID][msg.sender].add(_votePower);

      requestVoteAmount[_requestID] = requestVoteAmount[_requestID].add(_votePower);
        currentTotalVotePower[currentPeriod] = currentTotalVotePower[currentPeriod].add(_votePower);
        currentUserTotalVotePower[currentPeriod][msg.sender] = currentUserTotalVotePower[currentPeriod][msg.sender].add(_votePower);
         
         if(currentVoters[currentPeriod][msg.sender] == false){
             currentVoters[currentPeriod][msg.sender] == true;
             curVoters[currentPeriod].push(Votters(msg.sender));
         }
        if(manageRequestVoters[_requestID][msg.sender] == false){
            manageRequestVoters[_requestID][msg.sender] = true;  
            
            requestVoters[_requestID].push(Votters(msg.sender));
        }   
        canReward[currentPeriod] = true;
        emit RequestVote(msg.sender, _requestID, _votePower, requestVoteAmount[_requestID]);   
}

function validateRequest(uint _requestID) public{
    Requests storage request = requests[_requestID];
    require(requestVoteAmount[_requestID] >= votingThreshold, "It has not reach the voting threshold!");
    require(!request.stale, "This has already been validated");
    IERC20 egr = IERC20(egorasEGR);
    if(request.requestType == 0){
        votingThreshold = request.threshold;
    }else if(request.requestType == 1){
        dailyIncentive = request.incentive;
    }else if(request.requestType == 2){
        backers = request.backers;
        company = request.company;       
        branch  = request.branch;
    }
    
    for (uint256 i = 0; i < requestVoters[_requestID].length; i++) {
           address voterAddress = requestVoters[_requestID][i].voter;
           uint amount = requestPower[_requestID][voterAddress];
           require(egr.transfer(voterAddress, amount), "Fail to refund voter");
           requestPower[request.requestType][voterAddress] = 0;
           emit Refunded(amount, voterAddress, _requestID, block.timestamp);
    }
    
   request.stale = true;
    emit ApproveRequest(_requestID, requestVoteAmount[_requestID] >= votingThreshold, msg.sender);
}
  
 function applyForLoan(
        string memory _title,
        uint _amount,
        uint _length,
        uint _inventoryFee,
        string memory _image_url,
        bool _isloan,
        string memory _loanMetaData
        ) external onlyBranch {
        require(_amount > 0, "Loan amount should be greater than zero");
        require(_length > 0, "Loan duration should be greater than zero");
        require(bytes(_title).length > 3, "Loan title should more than three characters long");
        require(branch.add(backers.add(company)) == 10000, "Invalid percent");
         Loan memory _loan = Loan({
         title: _title,
         amount: _amount,
         length: _length,
         image_url: _image_url,
         inventoryFee: _inventoryFee,
         loanMetaData: _loanMetaData,
         creator: msg.sender,
         isloan: _isloan,
         isConfirmed: false
        });

             loans.push(_loan);
             uint256 newLoanID = loans.length - 1;
             
             backersReward[newLoanID] = backersReward[newLoanID].add(uint(uint(_inventoryFee).divideDecimalRound(uint(10000)).multiplyDecimalRound(uint(backers))));
             companyReward[newLoanID] = companyReward[newLoanID].add(uint(uint(_inventoryFee).divideDecimalRound(uint(10000)).multiplyDecimalRound(uint(company))));
             branchReward[newLoanID] = branchReward[newLoanID].add(uint(uint(_inventoryFee).divideDecimalRound(uint(10000)).multiplyDecimalRound(uint(branch))));
             
             emit LoanCreated(newLoanID, _title, _amount, _length,_image_url, _inventoryFee, msg.sender, _isloan, false);
        }


        function vote(uint _loanID, uint _votePower) external{
            require(!stale[_loanID], "The loan is either approve/declined");
            require(!hasVoted[_loanID][msg.sender], "You cannot vote twice");
            Loan memory loan = loans[_loanID];
            require(loan.isConfirmed, "Can't vote at the moment!");
            require(_votePower > 0, "Power must be greater than zero!");
            IERC20 iERC20 = IERC20(egorasEGR);
            require(iERC20.allowance(msg.sender, address(this)) >= _votePower, "Insufficient EGR allowance for vote!");
            require(iERC20.transferFrom(msg.sender, address(this), _votePower), "Error!");
            loanVoteAmount[_loanID] = loanVoteAmount[_loanID].add(_votePower);
             votePower[_loanID][msg.sender] = votePower[_loanID][msg.sender].add(_votePower);
            currentTotalVotePower[currentPeriod] = currentTotalVotePower[currentPeriod].add(_votePower);
            currentUserTotalVotePower[currentPeriod][msg.sender] = currentUserTotalVotePower[currentPeriod][msg.sender].add(_votePower);
             if(currentVoters[currentPeriod][msg.sender] == false){
             currentVoters[currentPeriod][msg.sender] == true;
             curVoters[currentPeriod].push(Votters(msg.sender));
         }
            if(!hasVoted[_loanID][msg.sender]){
                 hasVoted[_loanID][msg.sender] = true;
                listOfvoters[_loanID].push(Votters(msg.sender));
            }
             canReward[currentPeriod] = true;
            emit Voted(msg.sender, _loanID,  loanVoteAmount[_loanID], _votePower);
    } 

    function isDue(uint _loanID) public view returns (bool) {
        if (loanVoteAmount[_loanID] >= votingThreshold)
            return true;
        else
            return false;
    }

    function approveLoan(uint _loanID) external{
    Loan storage loan = loans[_loanID];
    require(loan.isConfirmed, "This loan is yet to be confirmed!");
     require(isDue(_loanID), "Voting is not over yet!");
     require(!stale[_loanID], "The loan is either approve/declined");
     NFT ENFT = NFT(eNFTAddress);
     IERC20 EUSD = IERC20(egorasEUSD);
     IERC20 egr = IERC20(egorasEGR);
     if(loanVoteAmount[_loanID] >= votingThreshold){
     require(ENFT.mint(loan.creator, _loanID), "Unable to mint token");
     require(EUSD.mint(loan.creator, loan.amount), "Fail to transfer fund");
     require(EUSD.mint(owner(), backersReward[_loanID]), "Fail to transfer fund");
     require(EUSD.mint(branchRewardAddress[loan.creator], branchReward[_loanID]), "Fail to transfer fund");
    for (uint256 i = 0; i < listOfvoters[_loanID].length; i++) {
           address voterAddress = listOfvoters[_loanID][i].voter;


            // Start of reward calc
            uint totalUserVotePower = votePower[_loanID][voterAddress].mul(1000);
            uint currentTotalPower = loanVoteAmount[_loanID];
            uint percentage = totalUserVotePower.div(currentTotalPower);
            uint share = percentage.mul(backersReward[_loanID]).div(1000);
            // End of reward calc
            
           uint amount = votePower[_loanID][voterAddress];
           require(egr.transfer(voterAddress, amount), "Fail to refund voter");
           votePower[_loanID][voterAddress] = votePower[_loanID][voterAddress].sub(amount);
           require(EUSD.mint(voterAddress, share), "Fail to refund voter");
           emit Refunded(amount, voterAddress, _loanID, block.timestamp);
    }
     isApproved[_loanID] = true;
     stale[_loanID] = true;
     
     emit ApproveLoan(_loanID, true, msg.sender, block.timestamp);
     }else{
        for (uint256 i = 0; i < listOfvoters[_loanID].length; i++) {
           address voterAddress = listOfvoters[_loanID][i].voter;
           uint amount = votePower[_loanID][voterAddress];
           require(egr.transfer(voterAddress, amount), "Fail to refund voter");
           emit Refunded(amount, voterAddress, _loanID, block.timestamp);
    } 
     stale[_loanID] = true;
     emit ApproveLoan(_loanID, false, msg.sender, block.timestamp);
     }
}

function repayLoan(uint _loanID) external{
   Loan storage loan = loans[_loanID];
   require(loan.isloan, "Invalid loan.");
   require(loan.length >= block.timestamp, "Repayment period is over!");
   require(isApproved[_loanID], "This loan is not eligible for repayment!");
   require(loan.creator == msg.sender, "Unauthorized.");
   IERC20 iERC20 = IERC20(egorasEUSD);
   NFT eNFT = NFT(eNFTAddress);
   require(iERC20.allowance(msg.sender, address(this)) >= loan.amount, "Insufficient EUSD allowance for repayment!");
   iERC20.burnFrom(msg.sender, loan.amount);
   eNFT.burn(_loanID);
   emit Repay(loan.amount, block.timestamp, _loanID);  
}


function buy(uint _id, string memory _buyerMetadata) external{
    Loan storage buyorder = loans[_id];
    require(!buyorder.isloan, "Invalid buy order.");
    require(isApproved[_id], "You can't buy this asset at the moment!");
    IERC20 iERC20 = IERC20(egorasEUSD);
    NFT eNFT = NFT(eNFTAddress);
    require(iERC20.allowance(msg.sender, address(this)) >= buyorder.amount, "Insufficient EUSD allowance for repayment!");
    iERC20.burnFrom(msg.sender, buyorder.amount);
    eNFT.burn(_id);
    emit Bought(_id,_buyerMetadata, block.timestamp); 
}

 function auction(uint _loanID, string memory _buyerMetadata) external{
   Loan storage loan = loans[_loanID];
   require(loan.isloan, "Invalid loan.");
   require(block.timestamp >= loan.length, "You can't auction it now!");
   require(isApproved[_loanID], "This loan is not eligible for repayment!");
   require(loan.creator != msg.sender, "Unauthorized.");
    IERC20 iERC20 = IERC20(egorasEUSD);
    NFT eNFT = NFT(eNFTAddress);
    require(iERC20.allowance(msg.sender, address(this)) >= loan.amount, "Insufficient EUSD allowance for repayment!");
    iERC20.burnFrom(msg.sender, loan.amount);
    eNFT.burn(_loanID);
    emit Bought(_loanID,_buyerMetadata, block.timestamp); 
 }

function rewardVoters() external{
//require(nextRewardDate >= block.timestamp, "Not yet time. Try again later");
require(canReward[currentPeriod], "No votes yet");
 IERC20 iERC20 = IERC20(egorasEGC);
 for (uint256 i = 0; i < curVoters[currentPeriod].length; i++) {
           address voterAddress = curVoters[currentPeriod][i].voter;
           uint amount = currentUserTotalVotePower[currentPeriod][voterAddress];
           uint total = currentTotalVotePower[currentPeriod];
           uint per = amount.divideDecimalRound(total);
           uint reward = dailyIncentive.multiplyDecimalRound(per);
           require(iERC20.mint(voterAddress, reward ), "Fail to mint EGC");
           emit Rewarded(reward, voterAddress, currentPeriod, block.timestamp);
    } 
   currentPeriod = block.timestamp;
   nextRewardDate = block.timestamp.add(1 days);
   canReward[currentPeriod] = false;

}


}