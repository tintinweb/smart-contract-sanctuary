/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/5_FundRaise.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


contract FundRaise {
    
    struct Project {
        address creator;
        string  name;
        uint256 tax;
        
        uint    nftNum;
        uint256 nftAmt;
        uint    nftDeniedMax;
        
        uint    uPhCurrent;
        uint256 uPhDateEnd;
        uint    uStatus;        // 0=FUG, 1=PRS, 2=FID, 3=PEG, 4=CAL, 5=RED
        uint256 uFunded;        // save amount receive fund
        uint256 uWidwable;      // amount creator can withdraw at this phase
    }
    
    struct Phase {
        uint    duration;
        uint256 widwable;
        uint256 refundable;
        string  uPath;
    }
    
    Project[]                                           public  projects;
    mapping(address => uint[])                          public  creProjects;     // creator      => projectid[]
    mapping(uint    => Phase[])                         public  proPhases;       // projectid    => phases[]
    
    mapping(uint    => mapping(address  => uint256))    public  logFund;         // projectid    => backer   => number NFT
    mapping(address => mapping(uint     => uint))       public  logDenied;       // backer       => projectid=> phaseId
    mapping(uint    => mapping(uint     => uint))       public  logDeniedNo;     // projectid    => phaseId  => number denied
    mapping(uint    => mapping(address  => uint))       public  logRefund;       // projectId    => backer   => amount
    mapping(uint    => mapping(uint256  => uint256))    public  logWithdraw;     // projectid    => date     => amount  
    
    uint256                                             public  tax;             // tax of all project
    address                                             private _token;
    mapping(address => bool)                            private _operators;
    address                                             private _owner;
    
    event EAction(string name, string action, address creator, uint256 info);
  
    constructor(address token_, address[] memory operators_) {
        _owner  = msg.sender;
        _token  = token_;
        for(uint i=0; i < operators_.length; i++) {
            address opr = operators_[i];
            require( opr != address(0), "invalid operator");
            _operators[opr] = true;
        }
    }
    
    modifier chkProject(string memory name_, uint pId_) {
        require( keccak256(abi.encodePacked((projects[pId_].name))) == keccak256(abi.encodePacked((name_))), "invalid project");
        _;
    }
    
    modifier chkOperator() {
        require(_operators[msg.sender], "only for operator");
        _;
    }
    
    //system
    function createProject( string memory name_, address creator_, uint nftNum_, uint256 nftAmt_, uint deniedMax_, uint256 tax_, uint256[] memory duration_, uint256[] memory widwable_, uint256[] memory refundable_ ) public chkOperator {
        require(duration_.length  > 2, "invalid phase");
        Project memory vPro;
        vPro.creator            =   creator_;
        vPro.name               =   name_;
        vPro.tax                =   tax_;
        
        vPro.nftNum             =   nftNum_;
        vPro.nftAmt             =   nftAmt_;
        vPro.nftDeniedMax       =   deniedMax_;
        
        vPro.uPhDateEnd         =   block.timestamp + duration_[0];
        vPro.uWidwable          =   widwable_[0];
        
        projects.push(vPro);
        
        uint vProId             =   projects.length -1;
        
        for(uint vI =0; vI < duration_.length; vI++) {
            Phase memory vPha;
            vPha.duration       =   duration_[vI];
            
            vPha.widwable       =   widwable_[vI];
            vPha.refundable     =   refundable_[vI];
            
            proPhases[vProId].push(vPha);
        }
        creProjects[creator_].push(vProId);
        emit EAction(name_, "create", creator_, tax_);
    }
    
    function _updateProject(uint pId_, uint phNext_) private {
        require(projects[pId_].uPhDateEnd   >  block.timestamp, "invalid deadline");
        require(projects[pId_].uPhDateEnd   <  block.timestamp + (proPhases[pId_][phNext_-1].duration/2), "invalid start");//TODO check half duration not OK
        
        uint    vEarly                      =    projects[pId_].uPhDateEnd - block.timestamp;     
        projects[pId_].uWidwable            +=   proPhases[pId_][phNext_].widwable;
        projects[pId_].uFunded              -=   proPhases[pId_][phNext_].widwable;
        projects[pId_].uPhDateEnd           +=   proPhases[pId_][phNext_].duration; 
        projects[pId_].uPhCurrent           =    phNext_;

        proPhases[pId_][phNext_].duration   +=   vEarly;   //add more duration
    }
    
    function kickoff(string memory name_, uint pId_) public chkOperator chkProject(name_, pId_) { 
        require(projects[pId_].uStatus      ==  0,  "invalid status");
        require(projects[pId_].uFunded      ==  projects[pId_].nftNum * projects[pId_].nftAmt, "invalid amount");
        
        projects[pId_].uStatus              =   1;      // progress
        _updateProject(pId_, 1);
        tax                                 +=  projects[pId_].tax;
        projects[pId_].uFunded              -=  projects[pId_].tax;
        emit EAction(name_, "kickoff", projects[pId_].creator, projects[pId_].uPhDateEnd);
    }
    
    function commit(string memory name_, uint pId_, string memory path_) public chkOperator chkProject(name_, pId_) {
        require(projects[pId_].uStatus      ==  1, "invalid status");
        require(projects[pId_].uPhCurrent   <   proPhases[pId_].length, "invalid phase");
        
        proPhases[pId_][projects[pId_].uPhCurrent].uPath   = path_;
        if(projects[pId_].uPhCurrent == (proPhases[pId_].length - 2 )) projects[pId_].uStatus      =  2; //finish
        _updateProject(pId_, projects[pId_].uPhCurrent + 1);
        emit EAction(name_, "commit", projects[pId_].creator, projects[pId_].uPhDateEnd);
    }
    
    function release(string memory name_, uint pId_, string memory path_) public chkOperator chkProject(name_, pId_) {
        require(projects[pId_].uStatus      ==  2, "invalid status");   // finish
        
        projects[pId_].uStatus              =   5;      // release
        projects[pId_].uPhDateEnd           =   block.timestamp;
        proPhases[pId_][ projects[pId_].uPhCurrent ].uPath      =   path_;
        if(projects[pId_].uFunded > 0) {
            projects[pId_].uWidwable        +=  projects[pId_].uFunded;
            projects[pId_].uFunded          =   0;
        }
        emit EAction(name_, "release", projects[pId_].creator, projects[pId_].uWidwable);
    }
    
    function cancel(string memory name_, uint pId_) public chkOperator chkProject(name_, pId_) {
        require(projects[pId_].uStatus      <  4, "invalid status");
        
        projects[pId_].uStatus              =   4;      // cancel
        projects[pId_].uPhDateEnd           =   block.timestamp;
        emit EAction(name_, "cancel", projects[pId_].creator, projects[pId_].uFunded);
    }
    
    function fund(string memory name_, uint pId_, address backer_, uint256 amount_, uint number_) public chkProject(name_, pId_) {
        require(projects[pId_].uStatus          ==  0,          "invalid status");
        require(projects[pId_].uFunded          <   projects[pId_].nftNum * projects[pId_].nftAmt, "invalid amount");
        require(projects[pId_].nftAmt * number_ ==  amount_,    "amount incorrect");
        
        IERC20(_token).transferFrom(backer_, address(this), amount_);
        logFund[pId_][backer_]              +=  number_;
        projects[pId_].uFunded              +=  amount_;
        emit EAction(name_, "fund", projects[pId_].creator, amount_);
    }
    /// backer
    function deny(string memory name_,uint pId_, uint phNo_) public chkProject(name_, pId_) {
        require(projects[pId_].uStatus      ==  1 || projects[pId_].uStatus      ==  2,   "invalid status");
        require(logFund[pId_][msg.sender]   >  0,   "invalid backer");
        require(logDenied[msg.sender][pId_] <   projects[pId_].uPhCurrent,  "invalid denied");
        
        logDenied[msg.sender][pId_]         =   projects[pId_].uPhCurrent;
        logDeniedNo[pId_][phNo_]            +=  logFund[pId_][msg.sender];
        if(logDeniedNo[pId_][phNo_]         >=  projects[pId_].nftDeniedMax)    projects[pId_].uStatus          =   3;  //pendding
        emit EAction(name_, "deny", projects[pId_].creator, (projects[pId_].uFunded/projects[pId_].nftNum));
    }
    
    function refund(string memory name_, uint pId_) public chkProject(name_, pId_) {
        require(projects[pId_].uStatus      ==  4,   "invalid status");
        require(logFund[pId_][msg.sender]   >   0,   "invalid backer");
        require(logRefund[pId_][msg.sender] <   1,   "invalid refund");
        require(projects[pId_].uFunded      >   0,   "invalid amount");
        
        logRefund[pId_][msg.sender]         =   proPhases[pId_][ projects[pId_].uPhCurrent ].refundable * logFund[pId_][msg.sender];
        projects[pId_].uFunded              -=  proPhases[pId_][ projects[pId_].uPhCurrent ].refundable * logFund[pId_][msg.sender];
        IERC20(_token).transfer(msg.sender, logRefund[pId_][msg.sender]);
        emit EAction(name_, "deny", projects[pId_].creator, (projects[pId_].uFunded/projects[pId_].nftNum)*logFund[pId_][msg.sender]);
    }
    // creator
    function withdraw(string memory name_, uint pId_) public chkProject(name_, pId_) {
        require(projects[pId_].creator      ==  msg.sender,    "invalid creator");
        require(projects[pId_].uWidwable    >   0,             "invalid amount");
        
        logWithdraw[pId_][block.timestamp]  =   projects[pId_].uWidwable;
        projects[pId_].uWidwable            =   0;
        IERC20(_token).transfer(msg.sender, logWithdraw[pId_][block.timestamp] );
        emit EAction(name_, "withdraw", projects[pId_].creator, logWithdraw[pId_][block.timestamp]);
    }
    
    // owner
    function owGetTax() public {
        require( _owner     ==  msg.sender, "only for owner");
        uint256 vTax        =   tax;
        tax                 =   0;
        IERC20(_token).transfer(msg.sender, vTax);
    }
    
    function owCloseProject(string memory name_, uint pId_) public chkProject(name_, pId_) {
        require( _owner     ==  msg.sender, "only for owner");
        uint256 vBalance    =   projects[pId_].uWidwable + projects[pId_].uFunded + projects[pId_].tax;
        projects[pId_].uWidwable    =   0; 
        projects[pId_].uFunded      =   0;
        projects[pId_].tax          =   0;
        projects[pId_].uStatus      =   4;  // cancel
        IERC20(_token).transfer(msg.sender, vBalance);
    }

    function owCloseAll() public {
        require( _owner     ==  msg.sender, "only for owner");
        uint256 vBalance    =   IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, vBalance);
    }
}