// File: contracts\SafeMath.sol

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

// File: contracts\EgorasMicrofinanceInterface.sol

pragma solidity >=0.4.0 <0.7.0;
// SPDX-License-Identifier: MIT
interface EgorasMicrofinanceInterface {
    struct Loan{
        uint amount;
        string title;
        uint length;
        uint min_weekly_returns;
        uint total_returns;
        string image_url;
        string companyName;
        uint totalWeeks;
        uint numWeekspaid;
        uint totalPayment;
        bool isApproved;
        uint loanFee;
        address creator;
    }
event LoanCreated(uint newLoanID, uint _amount, string _title, uint _length, uint _min_weekly_returns, uint _total_returns,  
string _image_url, string _companyName, uint getTotalWeeks, uint _loanFee, uint countDown, address _creator);
 
    struct Company{
        bool isApproved;
        uint positiveVote;
        uint negativeVote;
        uint votingPeriod;
        bool stale;
        string companyName;
        uint registeredDate;
    }

    event Rewarded(
        address voter, 
        uint share, 
        uint currentVotingPeriod, 
        uint time
        );
        
      
    event CompanyCreated(
        address owner,
        string companyName,
        uint votingPeriod
    );
    event VotedForRequest(
        address _voter,
        uint _requestID,
        uint _positiveVote,
        uint _negativeVote,
        bool _accept
    );
    event RequestCreated(
      address _creator,
      uint _requestType,
      uint _changeTo,
      string _reason,
      uint _positiveVote,
      uint _negativeVote,
      uint _powerUsed,
      bool _stale,
      uint _votingPeriod,
      uint _requestID
      );
    event CompanyApproved(
    address companyAddress,
    uint now,
    bool state,
    address _initiator
    );
    event VoteInCompany(
    address _company,
    address voter,
    bool _accept,
    uint _negativeVote,
    uint _positiveVote);
  
    event ApproveLoan(uint _loanID, bool state, address initiator, uint time);
    event ApproveRequest(uint _requestID, bool _state, address _initiator);    
    event LoanRepayment(
        uint loanID,
        uint amount,
        address remitter,
        uint time
    );
    
    event Refunded(uint amount, address voterAddress, uint _loanID, uint time);

    event Voted(address voter,  uint loanID, uint _positiveVote, uint _negativeVote, bool _accept);
    event Repay(uint _amount, uint _time, uint _week, uint _loanID);

    function applyForLoan(
        uint _amount,
        string calldata _title,
        uint _length,
        string calldata _image_url
        ) external;

    function approveLoanCompany(address companyAddress) external;
    function registerLoanCompany(string calldata companyName) external;
    function getLoanByID(uint _loanID) external view returns(uint _amount, uint _min_weekly_returns, uint _totalWeeks, 
    uint _length, string memory _title, uint _total_returns, string memory _image_url, string memory _companyName,  uint _numWeekspaid, uint _totalPayment, bool _isApproved, address _creator);
    function claimable() external view returns (bool);
    function isDue(uint _loanID) external view returns (bool);
    function getVotesByLoanID(uint _loanID) external view returns(uint _accepted, uint _declined);
    function repayLoan(uint _loanID) external;
    function approveLoan(uint _loanID) external;
    function rewardHoldersByVotePower() external;
    function distributeFee() external;
    function vote(uint _loanID, uint _votePower, bool _accept) external;
    function voteinCompany(address _company, uint _votePower, bool _accept) external;
    function createRequest(uint _requestType, uint _changeTo, string calldata _reason, bool _withdrawEGR) external;
    function governanceVote(uint _requestType, uint _requestID, uint _votePower, bool _accept) external;
    function validateRequest(uint _requestID) external;
    
}

// File: contracts\EgorasLending.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.7.0;




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

contract EgorasMicrofinance is EgorasMicrofinanceInterface {
    mapping(uint => bool) activeRequest;
    mapping(uint => mapping(address => uint)) requestPower;
    mapping(address => mapping(address => uint)) VoteInCompanyPower;
    uint private totalLoans;
    uint private loanInterestRate;
    mapping(address => Company) company;
    mapping (address => bool) companyExist;
    struct Votters{
      address payable voter;
    }
    
     struct Requests{
      address creator;
      uint requestType;
      uint changeTo;
      string reason;
      uint positiveVote;
      uint negativeVote;
      uint powerUsed;
      bool  withdrawEGR;
      bool stale;
      uint votingPeriod;
    }
    
    Requests[] requests;
    mapping(uint => Requests[]) listOfrequests;
    mapping(uint => Votters[]) listOfvoters;
    mapping(uint => Votters[]) etherActiveVotters;
    mapping(uint => Votters[]) activeVoters;
    mapping(uint => Votters[]) activeRequestVoters;
    mapping(address => Votters[]) activeLoanCompanyVoters;
    mapping(uint => mapping(address => bool)) hasVoted;
    mapping(uint => mapping(address => bool)) manageRequestVoters;
    mapping(address => mapping(address => bool)) manageLoanCompanyVoters;
    mapping(address => mapping(uint => bool)) isCurrentVotter;
    mapping(address => mapping(uint => bool)) isCurrentEtherVotter;
    mapping(uint => bool) stale;
    mapping(uint => mapping(address => uint)) votePower;
    mapping(address => uint) totalVotePower;
    mapping(uint => uint) positiveVote;
    mapping(uint => uint) voteCountDown;
    mapping(uint => uint) negativeVote;
    mapping (uint => bool) isLoanApproved;
    mapping(uint => uint) currentTotalVotePower;
    mapping(uint => uint) currentTotalVotePower2;
    uint public nextClaimDate;
    mapping(address => mapping(uint => uint)) userCurrentVotePower;
    mapping(address => mapping(uint => uint)) userCurrentVotePower2;
    Loan[] loans;
    Votters[] voters;
    using SafeMath for uint256;
    address private NGNC;
    address private egorasEGR;
    uint private loanFee;
    uint private systemFeeBalance;
     
    uint private currentVotingPeriod;
    uint private requestCreationPower;
    uint private currentEtherVotingPeriod;
    uint public totalIncentive;
    uint public weeklyIncentive;
    uint public treasuryCut;
    constructor(address _NGNC, address _egorasEgr, uint _initialLoanFee, uint _totalIncentive, uint _weeklyIncentive, uint _initialRequestPower
    , uint _treasuryCut)  public {
        egorasEGR = _egorasEgr;
        NGNC = _NGNC;
        loanFee = _initialLoanFee;
        currentVotingPeriod = currentVotingPeriod.add(1);
        currentEtherVotingPeriod = currentEtherVotingPeriod.add(1);
        totalIncentive = _totalIncentive;
        weeklyIncentive = _weeklyIncentive;
        nextClaimDate = block.timestamp.add(8 days);
        requestCreationPower = _initialRequestPower;
        treasuryCut = _treasuryCut;
    }

/// Request
function createRequest(uint _requestType, uint _changeTo, string memory _reason, bool _withdrawEGR) public override{
    require(_requestType == 0 || _requestType == 1 || _requestType == 2,  "Invalid request type!");
    require(!activeRequest[_requestType], "Another request is still active");
    IERC20 iERC20 = IERC20(egorasEGR);
    require(iERC20.allowance(msg.sender, address(this)) >= requestCreationPower, "Insufficient EGR allowance for vote!");
    iERC20.transferFrom(msg.sender, address(this), requestCreationPower);
    Requests memory _request = Requests({
      creator: msg.sender,
      requestType: _requestType,
      changeTo: _changeTo,
      reason: _reason,
      positiveVote: 0,
      negativeVote: 0,
      powerUsed: requestCreationPower,
      withdrawEGR: _withdrawEGR,
      stale: false,
      votingPeriod: block.timestamp.add(3 days)
    });
    
    requests.push(_request);
    uint256 newRequestID = requests.length - 1;
     Requests memory request = requests[newRequestID];
    emit RequestCreated(
      request.creator,
      request.requestType,
      request.changeTo,
      request.reason,
      request.positiveVote,
      request.negativeVote,
      request.powerUsed,
      request.stale,
      request.votingPeriod,
      newRequestID
      );
}

function governanceVote(uint _requestType, uint _requestID, uint _votePower, bool _accept) public override{
    Requests storage request = requests[_requestID];
    require(request.votingPeriod >= block.timestamp, "Voting period ended");
    require(_votePower > 0, "Power must be greater than zero!");
    require(_requestType == 0 || _requestType == 1 || _requestType == 2,  "Invalid request type!");
    IERC20 iERC20 = IERC20(egorasEGR);
    require(iERC20.allowance(msg.sender, address(this)) >= _votePower, "Insufficient EGR allowance for vote!");
    iERC20.transferFrom(msg.sender, address(this), _votePower);
    requestPower[_requestType][msg.sender] = requestPower[_requestType][msg.sender].add(_votePower);
     
     
       if(_accept){
            request.positiveVote = request.positiveVote.add(_votePower);
        }else{
            request.negativeVote = request.negativeVote.add(_votePower);  
        }
      
           
            if(manageRequestVoters[_requestID][msg.sender] == false){
                manageRequestVoters[_requestID][msg.sender] = true;
                activeRequestVoters[_requestID].push(Votters(msg.sender));
            }
       
           updateVotingStats(_votePower, msg.sender);
    
    emit VotedForRequest(msg.sender, _requestID, request.positiveVote, request.negativeVote, _accept);
    
}

function validateRequest(uint _requestID) public override{
    Requests storage request = requests[_requestID];
    require(block.timestamp >= request.votingPeriod, "Voting period still active");
    require(!request.stale, "This has already been validated");
    IERC20 ngnc = IERC20(NGNC);
    IERC20 egr = IERC20(egorasEGR);
    if(request.requestType == 0){
        if(request.positiveVote >= request.negativeVote){
            loanFee = request.changeTo;
            request.stale = true;
            
        }
        
    }else if(request.requestType == 1){
        if(request.positiveVote >= request.negativeVote){
            requestCreationPower = request.changeTo;
            request.stale = true;
            
            
        }
        
    }else if(request.requestType == 2){
        if(request.positiveVote >= request.negativeVote){
            if(request.withdrawEGR){
               require(egr.transfer(request.creator, request.changeTo), "Fail to transfer fund");
               }else{
                require(ngnc.transfer(request.creator, request.changeTo), "Fail to transfer fund");
               }
            
            request.stale = true;
            
        }
    }
    
   
    
   
    
    for (uint256 i = 0; i < activeRequestVoters[_requestID].length; i++) {
           address voterAddress = activeRequestVoters[_requestID][i].voter;
           uint amount = requestPower[request.requestType][voterAddress];
           require(egr.transfer(voterAddress, amount), "Fail to refund voter");
           requestPower[request.requestType][voterAddress] = 0;
           emit Refunded(amount, voterAddress, _requestID, now);
    }
    
     require(egr.transfer(request.creator, request.powerUsed), "Fail to transfer fund");
    emit ApproveRequest(_requestID, request.positiveVote >= request.negativeVote, msg.sender);
}
  // Loan

    function applyForLoan(
        uint _amount,
        string memory _title,
        uint _length,
        string memory _image_url
        ) public override {
            require(_amount > 0, "Loan amount should be greater than zero");
            require(_length > 0, "Loan duration should be greater than zero");
            require(bytes(_title).length > 3, "Loan title should more than three characters long");
            require(companyExist[msg.sender], "Company does not exist");
            Company memory comp = company[msg.sender];
            require(comp.isApproved, "This company is not eligible to create loan!");
            string memory name_of_loan_company = company[msg.sender].companyName;
            uint getTotalWeeks = _length.div(6);
            uint amount = _amount.div(getTotalWeeks);
            uint fee = uint(int256(amount) / int256(10000) * int256(loanFee));
            uint  weekly_payment = fee.add(amount);
         Loan memory _loan = Loan({
         amount: _amount,
         title: _title,
         length: _length,
         min_weekly_returns: weekly_payment,
         total_returns: weekly_payment.mul(getTotalWeeks),
         image_url: _image_url,
         companyName: name_of_loan_company,
         totalWeeks: getTotalWeeks,
         numWeekspaid: 0,
         totalPayment: 0,
         isApproved: false,
         loanFee: loanFee,
         creator: msg.sender
        });
             loans.push(_loan);
             uint256 newLoanID = loans.length - 1;
             voteCountDown[newLoanID] = block.timestamp.add(3 days);
             emit LoanCreated(newLoanID, _amount, _title, _length, weekly_payment, weekly_payment.mul(getTotalWeeks),_image_url,  name_of_loan_company, getTotalWeeks, loanFee, block.timestamp.add(3 days), msg.sender);
        }

    function getLoanByID(uint _loanID) external override view returns(uint _amount, uint _min_weekly_returns, uint _totalWeeks, 
    uint _length, string memory _title, uint _total_returns, string memory _image_url, string memory _companyName, uint _numWeekspaid, uint _totalPayment, bool _isApproved, address _creator){
         Loan memory loan = loans[_loanID];
         return (loan.amount, loan.min_weekly_returns,loan.totalWeeks, loan.length, 
         loan.title, loan.total_returns, loan.image_url, loan.companyName, loan.numWeekspaid, loan.totalPayment, loan.isApproved,
          loan.creator);
     }
     
     function getVotesByLoanID(uint _loanID) external override view returns(uint _accepted, uint _declined){
            return (positiveVote[_loanID], negativeVote[_loanID]);
        }

function vote(uint _loanID, uint _votePower, bool _accept) external override{
            require(_votePower > 0, "Power must be greater than zero!");
            IERC20 iERC20 = IERC20(egorasEGR);
            require(iERC20.allowance(msg.sender, address(this)) >= _votePower, "Insufficient EGR allowance for vote!");
            iERC20.transferFrom(msg.sender, address(this), _votePower);
            if(_accept){
                positiveVote[_loanID] = positiveVote[_loanID].add(_votePower);
            }else{
              negativeVote[_loanID] = negativeVote[_loanID].add(_votePower);  
            }
            
             
             votePower[_loanID][msg.sender] = votePower[_loanID][msg.sender].add(_votePower);
           
           
            if(hasVoted[_loanID][msg.sender] == false){
                hasVoted[_loanID][msg.sender] = true;
                listOfvoters[_loanID].push(Votters(msg.sender));
            }
          updateVotingStats(_votePower, msg.sender);
     
            
            emit Voted(msg.sender, _loanID,  positiveVote[_loanID],negativeVote[_loanID], _accept);
    } 
       
function repayLoan(uint _loanID) external override{
   Loan storage loan = loans[_loanID];
   require(loan.isApproved, "This loan is not approved yet.");
   require(loan.creator == msg.sender, "Unauthorized.");
   IERC20 iERC20 = IERC20(NGNC);
   require(loan.totalWeeks > loan.numWeekspaid, "The loan fully paid!");
   uint fee = uint(int256(loan.min_weekly_returns) / int256(10000) * int256(loan.loanFee));
   require(iERC20.allowance(msg.sender, address(this)) >= loan.min_weekly_returns, "Insufficient EUSD allowance for repayment!");
   require(iERC20.transferFrom(msg.sender, address(this), fee), "Fail to transfer");
   iERC20.burnFrom(msg.sender, loan.min_weekly_returns.sub(fee));
   loan.totalPayment = loan.totalPayment.add(loan.min_weekly_returns);
  
   systemFeeBalance = systemFeeBalance.add(fee);
   loan.numWeekspaid = loan.numWeekspaid.add(1);
   emit Repay(loan.min_weekly_returns, now, loan.numWeekspaid, _loanID);
}

function approveLoan(uint _loanID) external override{
     require(isDue(_loanID), "Voting is not over yet!");
     require(!stale[_loanID], "The loan is either approve/declined");
     bool state = false;
     Loan storage loan = loans[_loanID];
     IERC20 ngnc = IERC20(NGNC);
     IERC20 egr = IERC20(egorasEGR);
     if(positiveVote[_loanID] > negativeVote[_loanID]){
     require(ngnc.mint(loan.creator, loan.amount), "Fail to transfer fund");
     loan.isApproved = true;
     state = true;
     }
    
    for (uint256 i = 0; i < listOfvoters[_loanID].length; i++) {
           address voterAddress = listOfvoters[_loanID][i].voter;
           uint amount = votePower[_loanID][voterAddress];
           require(egr.transfer(voterAddress, amount), "Fail to refund voter");
           emit Refunded(amount, voterAddress, _loanID, now);
    }
    
    stale[_loanID] = true;
    ApproveLoan(_loanID, state, msg.sender, now);
}


// Company

        function registerLoanCompany(string calldata _companyName) external override{
            require(!companyExist[msg.sender], "Company already exist!");
            Company storage comp = company[msg.sender];
            uint countDown = block.timestamp.add(3 days);
            comp.isApproved = false;
            comp.companyName = _companyName;
            comp.registeredDate = now;
            comp.votingPeriod = countDown;
            companyExist[msg.sender] = true;
            emit CompanyCreated(msg.sender, _companyName, countDown);
        }

        function approveLoanCompany(address companyAddress) external override{
            require(companyExist[companyAddress], "Company does not exist!");
            bool state = false;
            Company storage comp = company[companyAddress];
            IERC20 egr = IERC20(egorasEGR);
           require( block.timestamp >= comp.votingPeriod, "Voting period still active");
            require(!comp.stale, "This has already been validated");
            if(comp.positiveVote >= comp.negativeVote){
                comp.isApproved = true;
                state = true;
            }
            
            for (uint256 i = 0; i < activeLoanCompanyVoters[companyAddress].length; i++) {
                address voterAddress = activeLoanCompanyVoters[companyAddress][i].voter;
                uint amount = VoteInCompanyPower[companyAddress][voterAddress];
                require(egr.transfer(voterAddress, amount), "Fail to refund voter");
            }
            comp.stale = true;
            emit CompanyApproved(companyAddress, now, state, msg.sender);
              

        }




        
   
        
        
    function voteinCompany(address _company, uint _votePower, bool _accept) external override{
           require(_votePower > 0, "Power must be greater than zero!");   
            IERC20 iERC20 = IERC20(egorasEGR);
            require(iERC20.allowance(msg.sender, address(this)) >= _votePower, "Insufficient EGR allowance for vote!");
             iERC20.transferFrom(msg.sender, address(this), _votePower);
             Company storage comp = company[_company];
              if(_accept){
                comp.positiveVote = comp.positiveVote.add(_votePower);
            }else{
              comp.negativeVote = comp.negativeVote.add(_votePower);  
            }
            
               VoteInCompanyPower[_company][msg.sender] = VoteInCompanyPower[_company][msg.sender].add(_votePower);
               if(manageLoanCompanyVoters[_company][msg.sender] == false){
                manageLoanCompanyVoters[_company][msg.sender] = true;
                activeLoanCompanyVoters[_company].push(Votters(msg.sender));
            }
            
           updateVotingStats(_votePower, msg.sender);
           
           emit VoteInCompany(_company,msg.sender, _accept, comp.negativeVote, comp.positiveVote);
            
    }
    
     



 function updateVotingStats(uint _power, address payable _voter) private {
      currentTotalVotePower[currentVotingPeriod] = currentTotalVotePower[currentVotingPeriod].add(_power);
      userCurrentVotePower[_voter][currentVotingPeriod] = userCurrentVotePower[_voter][currentVotingPeriod].add(_power);
      currentTotalVotePower2[currentEtherVotingPeriod] = currentTotalVotePower2[currentEtherVotingPeriod].add(_power);
      userCurrentVotePower2[_voter][currentEtherVotingPeriod] = userCurrentVotePower2[_voter][currentEtherVotingPeriod].add(_power);
             if(isCurrentEtherVotter[_voter][currentEtherVotingPeriod] == false){
                etherActiveVotters[currentEtherVotingPeriod].push(Votters(_voter));
            }
       
        if(isCurrentVotter[_voter][currentVotingPeriod] == false){
                activeVoters[currentVotingPeriod].push(Votters(_voter));
            }
            
         totalVotePower[_voter] = totalVotePower[_voter].add(_power);
          
 }     


function claimable() public override view returns (bool) {
        if (block.timestamp >= nextClaimDate)
            return true;
        else
            return false;
    }

function isDue(uint _loanID) public override view returns (bool) {
        if (block.timestamp >= voteCountDown[_loanID])
            return true;
        else
            return false;
    }

function rewardHoldersByVotePower() external override{
      IERC20 iERC20 = IERC20(egorasEGR);
       require(claimable(), "Not yet time for reward");
       uint treasuryShare = uint(int256(weeklyIncentive) / int256(10000) * int256(treasuryCut));
       uint votersShare = weeklyIncentive.sub(treasuryShare);
       require(totalIncentive >= treasuryShare, "No incentive left for distribution");
       
      for (uint256 i = 0; i < activeVoters[currentVotingPeriod].length; i++) {
            address _voter = activeVoters[currentVotingPeriod][i].voter;
            uint totalUserVotePower = userCurrentVotePower[_voter][currentVotingPeriod].mul(1000);
            uint currentTotalPower = currentTotalVotePower[currentVotingPeriod];
            uint percentage = totalUserVotePower.div(currentTotalPower);
            uint share = percentage.mul(votersShare).div(1000);
            require(totalIncentive >= share, "No incentive left for distribution");
            require(iERC20.mint(_voter, share), "Unable to mint token");
            totalIncentive = totalIncentive.sub(share);
            emit Rewarded(_voter, share, currentVotingPeriod, now);
            
        }
        require(iERC20.mint(address(this), treasuryShare), "Unable to mint token");
        
         currentVotingPeriod = currentVotingPeriod.add(1);
         nextClaimDate = block.timestamp.add(8 days);
}

function distributeFee() external override{ 
    uint minEther =  1 ether;
    uint balance = address(this).balance;
    require(balance >= minEther, "Not enough balance");

        for (uint256 i = 0; i < etherActiveVotters[currentEtherVotingPeriod].length; i++) {
            address payable _voter = etherActiveVotters[currentVotingPeriod][i].voter;
            uint totalUserVotePower = userCurrentVotePower2[_voter][currentEtherVotingPeriod].mul(1000);
            uint currentTotalPower = currentTotalVotePower[currentEtherVotingPeriod];
            uint percentage = totalUserVotePower.div(currentTotalPower);
            uint share = percentage.mul(balance).div(1000);
            require(balance >= share, "Non-sufficient funds");
           _voter.transfer(share);
            
            emit Rewarded(_voter, share, currentVotingPeriod, now);
            
        }
        
         currentEtherVotingPeriod = currentEtherVotingPeriod.add(1);
         
}
function depositEther() public payable {
}

function systemInfo() public view  returns(uint _requestpower, uint _loanFee, uint _totalIncentive, uint _weeklyIncentive ,  uint _treasuryCut, uint _nextClaimDate){
    return(requestCreationPower, loanFee, totalIncentive, weeklyIncentive, treasuryCut, nextClaimDate);
}

}