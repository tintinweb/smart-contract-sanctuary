pragma solidity 0.4.24;

contract JobChain
{
    // Maximum jobs in market
    uint constant MAXJOBS = 99;

    enum JobStatus
    {
        EmptySlot,
        JobAdvertised,
        WorkCompleted
    }

    struct Job  
    {
        string jobDetails;
        JobStatus jobStatus;
        address jobOwner;
        uint jobValue;
        string subEvidence;
        address subOwner;
    }
    
    // State variables
    // Contract owner
    address public contractOwner;

    // All our jobs
    Job[MAXJOBS] private jobs;
    
    // Panic mode (emergency stop)
    bool private panicMode;

    // Use pull model for withdrawals
    // From http://solidity.readthedocs.io/en/v0.4.24/common-patterns.html#withdrawal-from-contracts
    mapping (address => uint) private pendingWithdrawals;
    
    // Events
    event LogSubmissionAccepted(address jobOwner, address subOwner);
    event LogSubmissionRejected(address jobOwner, address subOwner);
    event LogWithdrawalPaidOut(address subOwner, uint weiAmount);

    
    /// @notice Create test data
    /// @dev Create test data just for internal testing, all with Ether value 0
    /// This will only create data once (also prevents bad usage to fill all jobs)
    function createTestData() private
    {
        // Only if not already created
       if (jobs[0].jobOwner == address(0))
       {
         // Job with a submission (from same address), but not approved yet
         jobs[0].jobDetails = "Create an ICO website.";
         jobs[0].jobStatus = JobStatus.WorkCompleted;
         jobs[0].jobOwner = msg.sender;
         jobs[0].jobValue = 0;
         jobs[0].subEvidence = "I have done it, please accept work.";
         jobs[0].subOwner = msg.sender;
       }

       if (jobs[1].jobOwner == address(0))
       {
         // Job without any submissions yet
         jobs[1].jobDetails = "Explanation Video for my Dapp Game.";
         jobs[1].jobStatus = JobStatus.JobAdvertised;
         jobs[1].jobOwner = msg.sender;
         jobs[1].jobValue = 0;      
         jobs[1].subEvidence = "";
         jobs[1].subOwner = address(0); 
      }
    }

    constructor () public payable
    {
        contractOwner = msg.sender;

        // Test data to save time during unit testing. When made productive this could be removed, but doesn&#39;t have to be.
        createTestData();        
     
    }

    /// @notice Create a new job, pass Ether to pay the worker.
    /// @param details is the description of the job that needs done.
    /// @return a job id.
    function createJob(string details) public payable
    returns(uint jobId)
    {
        // Find empty slot
        for (uint i=0; i<jobs.length; i++)
        {
          if ((jobs[i].jobStatus == JobStatus.EmptySlot))
          {
             jobs[i].jobDetails = details;
             jobs[i].jobStatus =  JobStatus.JobAdvertised;
             jobs[i].jobOwner = msg.sender;
             jobs[i].jobValue = msg.value;
             return i;
          }
        }
        revert("No vacant job slots left in job array.");
    }
    
    /// @notice List all jobs with status
    /// @dev See enum JobStatus to translate job status values
    /// @return jobStatuses is a list of job statuses
    function getAllJobs() public view
    returns(JobStatus[MAXJOBS] jobStatuses)
    {        
        for (uint i=0; i<jobs.length; i++)
        {
            jobStatuses[i] = jobs[i].jobStatus;
        }
    }
        
    /// @notice Returns a single job detail from jobId (zero based).    
    /// @dev See enum JobStatus to translate job status values
    /// @return job details as individual fields.
    function getJobDetail(uint jobId) public view
    returns(string jDetails, JobStatus jStatus, address jOwner, uint jValue, string sEvidence, address sOwner)
    {
        // Check safety
        require(jobId < MAXJOBS, "Job array is not that large");
        
       jDetails = jobs[jobId].jobDetails;
       jStatus = jobs[jobId].jobStatus;
       jOwner = jobs[jobId].jobOwner;
       jValue = jobs[jobId].jobValue;
       sEvidence = jobs[jobId].subEvidence;
       sOwner = jobs[jobId].subOwner;        
    }
    
    /// @notice Make a work submission for a job.
    /// @dev Checks jobId is valid.
    /// @param jobId job id
    /// @param subEvidence some descriptive evidence of work done
    /// @return true if submission was stored ok.
    function createSubmission(uint jobId, string subEvidence) public
    returns(bool isSubmissionOk)
    {
        // Check safety
        require(jobId < MAXJOBS, "Job array is not that large");
        
        // Check job
        if (jobs[jobId].jobStatus != JobStatus.JobAdvertised)
        {
           revert("This job is not accepting work any more. Please contact job owner.");
        }

        // Store the work submission
        jobs[jobId].jobStatus = JobStatus.WorkCompleted;
        jobs[jobId].subOwner = msg.sender;
        jobs[jobId].subEvidence = subEvidence;
        isSubmissionOk = true;    
    } 
        
    /// @notice Process is that a job owner accepts or rejects a submission, then payees can withdraw Ether later.
    /// @dev As later step, Payee calls makeWithdrawal().
    /// @param jobId job id    
    function acceptSubmission(uint jobId) public
    {
        // Check safety
        require(jobId < MAXJOBS, "Job array is not that large");
                
        // Check job owner
        require(msg.sender == jobs[jobId].jobOwner, "Must be job owner to accept work submission.");
        
        // Check job status
        require(jobs[jobId].jobStatus == JobStatus.WorkCompleted, "Job must have work to be accepted.");
        
        // Using payment pull model
        uint jobValue = jobs[jobId].jobValue;
        address subOwner = jobs[jobId].subOwner;               
        pendingWithdrawals[subOwner] += jobValue;
        
        // Job slot is wholly free again
        jobs[jobId].jobDetails = "";
        jobs[jobId].jobStatus = JobStatus.EmptySlot;
        jobs[jobId].jobOwner = address(0);
        jobs[jobId].jobValue = 0;      
        jobs[jobId].subEvidence = "";
        jobs[jobId].subOwner = address(0); 
        
        // Event
         emit LogSubmissionAccepted(msg.sender, subOwner);
    }

    /// @notice Job owners can reject a work submission
    /// @dev This frees up space for another work submission for this job
    /// @param jobId job id    
    function rejectSubmission(uint jobId) public
    {
        // Check safety
        require(jobId < MAXJOBS, "Job array is not that large");
                
        // Check job owner
        require(msg.sender == jobs[jobId].jobOwner, "Must be job owner to reject work submission.");
        
        // Check job status
        require(jobs[jobId].jobStatus == JobStatus.WorkCompleted, "Job must have work to be rejected.");
                
        // Job slot is free to let someone else submit work
        address subOwner = jobs[jobId].subOwner;               
        jobs[jobId].jobStatus = JobStatus.JobAdvertised;
        jobs[jobId].subEvidence = "";
        jobs[jobId].subOwner = address(0);         

        // Events
         emit LogSubmissionRejected(msg.sender, subOwner);
    }

    /// @notice Withdraw any Ether due. Only works if emergency stop not active.
    /// @dev Uses pull payment model, with an emergency stop check.
    function jobHunterWithdrawal() public
    {
        // Check emergency stop panic button
        require(panicMode == false, "No withdrawals allowed. Panic mode (emergency stop) is on.");

        uint amountDue = 0;

        if (pendingWithdrawals[msg.sender] > 0)
        {
            // How much do we owe?
            amountDue = pendingWithdrawals[msg.sender];

            // Nothing due anymore to this sender
            pendingWithdrawals[msg.sender] = 0;
        
            // Log
            emit LogWithdrawalPaidOut(msg.sender, amountDue);

            // Notice how the send is the last thing we do (guard against re-entrancy)
            msg.sender.transfer(amountDue);
        }
    }

    /// @notice Returns amount of Ether due in Wei to the caller.
    /// @dev Doesn&#39;t care about emergency stop, this is just returning a value
    function getJobHunterWithdrawalAmount() public view
    returns (uint amountWeiDue)
    {
        return pendingWithdrawals[msg.sender];
    }
        
    /// @dev fallback
    function() public payable { }

    /// @notice Delete contract and return funds to the owner of the contract.
    /// @dev Only works if called by the contract owner
    function kill() public 
    {
        require(contractOwner == msg.sender, "Only contract owner can kill contract.");
        selfdestruct(contractOwner);
    }

    /// @notice Switch on panic mode (emergency stop)
    /// @dev Only works if called by the contract owner
    function panicOn() public 
    {
        require(contractOwner == msg.sender, "Only contract owner can switch on panic mode.");
        panicMode = true;
    }

    /// @notice Switch off panic mode (emergency stop)
    /// @dev Only works if called by the contract owner
    function panicOff() public 
    {
        require(contractOwner == msg.sender, "Only contract owner can switch off panic mode.");
        panicMode = false;
    }    
}