pragma solidity 0.4.23;


library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/// @title Escrow contract
/// @author Farah Brunache
/// @notice It&#39;s an escrow contract for creating, claiming and rewarding jobs.

contract Escrow{

    using SafeMath for uint;
    enum JobStatus { Open, inProgress, Completed, Cancelled }

    struct Job{
        string description;               // description of job
        // uint JobID;                       // Id of the job
        address manager;                  // address of manager
        uint salaryDeposited;             // salary deposited by manager
        address worker;                   // address of worker
        JobStatus status;                 // current status of the job
        uint noOfTotalPayments;           // total number of Payments set by the manager
        uint noOfPaymentsMade;            // number of payments that have already been made
        uint paymentAvailableForWorker;   // amount of DAI tokens available for the worker as claimable
        uint totalPaidToWorker;           // total amount of DAI tokens paid to worker so far for this job
        address evaluator;                // address of evaluator for this job
        bool proofOfLastWorkVerified;     // status of the proof of work for the last milestone
        uint sponsoredTokens;             // amount of DAI tokens sponsored to the job
        mapping(address => uint) sponsors; // mapping of all the sponsors with their contributions for a job
        address[] sponsorList;             // List of addresses for all sponsors for iterations
        uint sponsorsCount;                // total number of contributors for this job
    }

    Job[] public Jobs;                    // List of all the jobs


    mapping(address => uint[]) public JobsByManager;        // all the jobs held by a manager
    mapping(address => uint[]) public JobsByWorker;         // all the jobs held by a worker


    ERC20 public DAI;

    uint public jobCount = 0;     // current count of the total Jobs

    address public arbitrator;     // address of arbitrator

    constructor(address _DAI, address _arbitrator) public{
        DAI = ERC20(_DAI);
        arbitrator = _arbitrator;
    }


    modifier onlyArbitrator{
        require(msg.sender == arbitrator);
        _;
    }

    event JobCreated(address manager, uint salary, uint noOfTotalPayments, uint JobID, string description, address _evaluator);

    /// @notice this function creates a job
    /// @dev Uses transferFrom on the DAI token contract
    /// @param _salary is the amount of salary deposited by the manager
    /// @param _noOfTotalPayments is the number of total payments iterations set by the manager
    function createJob(string _description, uint _salary, uint _noOfTotalPayments, address _evaluator) public {
        require(_salary > 0);
        require(_noOfTotalPayments > 0);

        address[] memory empty;
        uint finalSalary = _salary.sub(_salary.mul(1).div(10));

        Job memory newJob = Job(_description, msg.sender, finalSalary, 0x0, JobStatus.Open, _noOfTotalPayments, 0, 0, 0, _evaluator, false, 0, empty, 0);
        Jobs.push(newJob);
        JobsByManager[msg.sender].push(jobCount);

        require(DAI.allowance(msg.sender, address(this)) >= _salary);

        emit JobCreated(msg.sender, finalSalary, _noOfTotalPayments, jobCount, _description, _evaluator);
        jobCount++;

        DAI.transferFrom(msg.sender, address(this), _salary);

    }


    event JobClaimed(address worker, uint JobID);

    /// @notice this function lets the worker claim the job
    /// @dev Uses transferFrom on the DAI token contract
    /// @param _JobID is the ID of the job to be claimed by the worker
    function claimJob(uint _JobID) public {
        require(_JobID >= 0);

        Job storage job = Jobs[_JobID];

        require(msg.sender != job.manager);
        require(msg.sender != job.evaluator);

        require(job.status == JobStatus.Open);

        job.worker = msg.sender;
        job.status = JobStatus.inProgress;

        JobsByWorker[msg.sender].push(_JobID);
        emit JobClaimed(msg.sender, _JobID);


    }


    event EvaluatorSet(uint JobID, address evaluator);

    /// @notice this function lets a registered address become an evaluator for a job
    /// @param _JobID is the ID of the job for which the sender wants to become an evaluator
    function setEvaluator(uint _JobID) public {
        require(_JobID >= 0);

        Job storage job = Jobs[_JobID];

        require(msg.sender != job.manager);
        require(msg.sender != job.worker);

        job.evaluator = msg.sender;
        emit EvaluatorSet(_JobID, msg.sender);

    }


    event JobCancelled(uint JobID);

    /// @notice this function lets the manager or arbitrator cancel the job
    /// @dev Uses transfer on the DAI token contract to return DAI from escrow to manager
    /// @param _JobID is the ID of the job to be cancelled
    function cancelJob(uint _JobID) public {
        require(_JobID >= 0);

        Job storage job = Jobs[_JobID];

        if(msg.sender != arbitrator){
            require(job.manager == msg.sender);
            require(job.worker == 0x0);
            require(job.status == JobStatus.Open);
        }

        job.status = JobStatus.Cancelled;
        uint returnAmount = job.salaryDeposited;

        emit JobCancelled(_JobID);
        DAI.transfer(job.manager, returnAmount);
    }


    event PaymentClaimed(address worker, uint amount, uint JobID);

    /// @notice this function lets the worker claim the approved payment
    /// @dev Uses transfer on the DAI token contract to send DAI from escrow to worker
    /// @param _JobID is the ID of the job from which the worker intends to claim the DAI tokens
    function claimPayment(uint _JobID) public {
        require(_JobID >= 0);
        Job storage job = Jobs[_JobID];

        require(job.worker == msg.sender);
        require(job.noOfPaymentsMade > 0);

        uint payment = job.paymentAvailableForWorker;
        require(payment > 0);

        job.paymentAvailableForWorker = 0;
        job.totalPaidToWorker = job.totalPaidToWorker + payment;
        emit PaymentClaimed(msg.sender, payment, _JobID);
        DAI.transfer(msg.sender, payment);

    }


    event PaymentApproved(address manager, uint JobID, uint amount);

    /// @notice this function lets the manager to approve payment
    /// @param _JobID is the ID of the job for which the payment is approved
    function approvePayment(uint _JobID) public {
        require(_JobID >= 0);

        Job storage job = Jobs[_JobID];

        if(msg.sender != arbitrator){
            require(job.manager == msg.sender);
            require(job.proofOfLastWorkVerified == true);
        }
        require(job.noOfTotalPayments > job.noOfPaymentsMade);

        uint currentPayment = job.salaryDeposited.div(job.noOfTotalPayments);

        job.paymentAvailableForWorker = job.paymentAvailableForWorker + currentPayment;

        job.noOfPaymentsMade++;

        if(job.noOfTotalPayments == job.noOfPaymentsMade){
            job.status = JobStatus.Completed;
        }

        emit PaymentApproved(msg.sender, _JobID, currentPayment);

    }


    event EvaluatorPaid(address manager, address evaluator, uint JobID, uint payment);

    /// @notice this function lets the manager pay DAI to arbitrator
    /// @dev Uses transferFrom on the DAI token contract to send DAI from manager to evaluator
    /// @param _JobID is the ID of the job for which the evaluator is to be paid
    /// @param _payment is the amount of DAI tokens to be paid to evaluator
    function payToEvaluator(uint _JobID, uint _payment) public {
        require(_JobID >= 0);
        require(_payment > 0);

        Job storage job = Jobs[_JobID];
        require(msg.sender == job.manager);

        address evaluator = job.evaluator;

        require(DAI.allowance(job.manager, address(this)) >= _payment);

        emit EvaluatorPaid(msg.sender, evaluator, _JobID, _payment);
        DAI.transferFrom(job.manager, evaluator, _payment);


    }


    event ProofOfWorkConfirmed(uint JobID, address evaluator, bool proofVerified);

    /// @notice this function lets the evaluator confirm the proof of work provided by worker
    /// @param _JobID is the ID of the job for which the evaluator confirms proof of work
    function confirmProofOfWork(uint _JobID) public {
        require(_JobID >= 0);

        Job storage job = Jobs[_JobID];
        require(msg.sender == job.evaluator);

        job.proofOfLastWorkVerified = true;

        emit ProofOfWorkConfirmed(_JobID, job.evaluator, true);

    }

    event ProofOfWorkProvided(uint JobID, address worker, bool proofProvided);

    /// @notice this function lets the worker provide proof of work
    /// @param _JobID is the ID of the job for which worker provides proof
    function provideProofOfWork(uint _JobID) public {
        require(_JobID >= 0);

        Job storage job = Jobs[_JobID];
        require(msg.sender == job.worker);

        job.proofOfLastWorkVerified = false;
        emit ProofOfWorkProvided(_JobID, msg.sender, true);

    }


    event TipMade(address from, address to, uint amount);

    /// @notice this function lets any registered address send DAI tokens to any other address
    /// @dev Uses transferFrom on the DAI token contract to send DAI from sender&#39;s address to receiver&#39;s address
    /// @param _to is the address of the receiver receiving the DAI tokens
    /// @param _amount is the amount of DAI tokens to be paid to receiving address
    function tip(address _to, uint _amount) public {
        require(_to != 0x0);
        require(_amount > 0);
        require(DAI.allowance(msg.sender, address(this)) >= _amount);

        emit TipMade(msg.sender, _to, _amount);
        DAI.transferFrom(msg.sender, _to, _amount);
    }


    event DAISponsored(uint JobID, uint amount, address sponsor);

    /// @notice this function lets any registered address send DAI tokens to any Job as sponsored tokens
    /// @dev Uses transferFrom on the DAI token contract to send DAI from sender&#39;s address to Escrow
    /// @param _JobID is the ID of the job for which the sponsor contributes DAI
    /// @param _amount is the amount of DAI tokens to be sponsored to the Job
    function sponsorDAI(uint _JobID, uint _amount) public {
        require(_JobID >= 0);
        require(_amount > 0);

        Job storage job = Jobs[_JobID];
        require(job.status == JobStatus.inProgress);

        if(job.sponsors[msg.sender] == 0){
            job.sponsorList.push(msg.sender);
        }

        job.sponsors[msg.sender] = job.sponsors[msg.sender] + _amount;
        job.sponsoredTokens = job.sponsoredTokens + _amount;

        job.paymentAvailableForWorker = job.paymentAvailableForWorker + _amount;


        job.sponsorsCount = job.sponsorsCount + 1;
        emit DAISponsored(_JobID, _amount, msg.sender);

        require(DAI.allowance(msg.sender, address(this)) >= _amount);
        DAI.transferFrom(msg.sender, address(this), _amount);
    }

    event DAIWithdrawn(address receiver,uint amount);

    /// @notice this function lets arbitrator withdraw DAI to the provided address
    /// @dev Uses transfer on the DAI token contract to send DAI from Escrow to the provided address
    /// @param _receiver is the receiving the withdrawn DAI tokens
    /// @param _amount is the amount of DAI tokens to be withdrawn
    function withdrawDAI(address _receiver, uint _amount) public onlyArbitrator {
        require(_receiver != 0x0);
        require(_amount > 0);

        require(DAI.balanceOf(address(this)) >= _amount);

        DAI.transfer(_receiver, _amount);
        emit DAIWithdrawn(_receiver, _amount);
    }


    /// @notice this function lets get an amount of sponsored DAI by an address in a given job
    /// @param _JobID is the Job for the job
    /// @param _sponsor is the address of sponsor for which we are retreiving the sponsored tokens amount
    function get_Sponsored_Amount_in_Job_By_Address(uint _JobID, address _sponsor) public view returns (uint) {
        require(_JobID >= 0);
        require(_sponsor != 0x0);

        Job storage job = Jobs[_JobID];

        return job.sponsors[_sponsor];
    }


    /// @notice this function lets retrieve the list of all sponsors in a given job
    /// @param _JobID is the Job for the job for which we are retrieving the list of sponsors
    function get_Sponsors_list_by_Job(uint _JobID) public view returns (address[] list) {
        require(_JobID >= 0);

        Job storage job = Jobs[_JobID];

        list = new address[](job.sponsorsCount);

        list = job.sponsorList;
    }


    function getJob(uint _JobID) public view returns ( string _description, address _manager, uint _salaryDeposited, address _worker, uint _status, uint _noOfTotalPayments, uint _noOfPaymentsMade, uint _paymentAvailableForWorker, uint _totalPaidToWorker, address _evaluator, bool _proofOfLastWorkVerified, uint _sponsoredTokens, uint _sponsorsCount) {
        require(_JobID >= 0);

        Job storage job = Jobs[_JobID];
        _description = job.description;
        _manager = job.manager;
        _salaryDeposited = job.salaryDeposited;
        _worker = job.worker;
        _status = uint(job.status);
        _noOfTotalPayments = job.noOfTotalPayments;
        _noOfPaymentsMade = job.noOfPaymentsMade;
        _paymentAvailableForWorker = job.paymentAvailableForWorker;
        _totalPaidToWorker = job.totalPaidToWorker;
        _evaluator = job.evaluator;
        _proofOfLastWorkVerified = job.proofOfLastWorkVerified;
        _sponsoredTokens = job.sponsoredTokens;
        _sponsorsCount = job.sponsorsCount;
    }

}