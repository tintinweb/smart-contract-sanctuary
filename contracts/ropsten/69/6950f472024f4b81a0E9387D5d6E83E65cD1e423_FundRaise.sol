/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: contracts/4_fundraise.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract FundRaise {
    struct Project {
        uint256 taxKick;
        uint    nftNum;
        uint256 nftAmt;
        uint    nftDeniedMax;
        address creator;
        address crypto;
    }
    struct UpProject {
        Project Init;
        uint    uPhCurrent;
        uint    uPhDateStart;
        uint    uPhDateEnd;
        uint    uStatus;        // 0=FUG, 1=PRS, 2=FID, 3=PEG, 4=CAL, 5=RED
        uint256 uFunded;        // save amount receive fund
        uint    uNftNum;
        uint256 uWidwable;      // amount creator can withdraw at this phase
    }
    struct BackProject {
        uint256 uNftAmtBack;
        uint256 uNftFeeBack;
        uint    uNftLimitBack;
    }
    struct Phase {
        uint    phaseStart;
        uint    duration;
        uint256 widwable;
        uint256 refundable;
        string  uPath;
        uint    denyNum;
    }
    struct Info {
        uint    fundNum;
        uint    backNum;
        uint256 refund;
    }
    UpProject[]                                         public  projs;
    mapping(uint    => BackProject)                     public  bkProjs;
    mapping(uint    => Phase[])                         public  proPhases;       // projectid    => phases[]
    
    mapping(uint    => mapping(address  => Info))       public  logBacker;       // projectId    => backer   => infor(fund, back, refund)
    mapping(address => mapping(uint     => uint))       public  logDenied;       // backer       => projectid=> phaseId
    mapping(uint    => mapping(uint256  => uint256))    public  logWithdraw;     // projectid    => date     => amount  
    
    mapping(address => bool)                            private _operators;
    address                                             private _owner;
    bool                                                private _ownerLock = true;
    event EAction(uint indexed kId, string indexed kAction, uint id, string action, address creator, uint256 info);
  
    constructor( address[] memory optors_) {
        _owner  = msg.sender;
        for(uint i=0; i < optors_.length; i++) {
            address opr = optors_[i];
            require( opr != address(0), "ivd optor");
            _operators[opr] = true;
        }
    }
    modifier chkOperator() {
        require(_operators[msg.sender], "only for optor");
        _;
    }
    modifier chkOwnerLock() {
        require( _owner     ==  msg.sender, "only for owner");
        require( _ownerLock ==  false, "lock not open");
        _;
    }
    function opSetOwnerLock(bool val_) public chkOperator {
        _ownerLock   = val_;
    }
    function maxProjectId() public view returns(uint) {
        return projs.length - 1;
    }
    function getPhaseStart(uint pId_) public view returns(Phase[] memory) {
        return proPhases[pId_];
    }
    //system
    function opCreateProject( address creator_, address crypto_, uint nftNum_, uint256 nftAmt_, uint deniedMax_, uint256 tax_, uint[] memory duration_, uint256[] memory widwable_, uint256[] memory refundable_ ) public chkOperator {
        require(duration_.length  > 3, "ivd phase");
     
        uint vPhaseStart        = block.timestamp;
        UpProject memory vUpPro;
        vUpPro.Init.taxKick         =   tax_;
        vUpPro.Init.nftNum          =   nftNum_;
        vUpPro.Init.nftAmt          =   nftAmt_;
        vUpPro.Init.nftDeniedMax    =   deniedMax_;
        vUpPro.Init.crypto          =   crypto_;
        vUpPro.Init.creator         =   creator_;
        vUpPro.uPhDateStart         =   vPhaseStart;
        vUpPro.uPhDateEnd           =   vPhaseStart + duration_[0];
        vUpPro.uWidwable            =   widwable_[0];
        projs.push(vUpPro);
        for(uint vI =0; vI < duration_.length; vI++) {
            Phase memory vPha;
            vPha.phaseStart     =   vPhaseStart;
            vPha.duration       =   duration_[vI];
            vPha.widwable       =   widwable_[vI];
            vPha.refundable     =   refundable_[vI];
            proPhases[maxProjectId()].push(vPha);
            vPhaseStart         +=  vPha.duration;
        }
        emit EAction( maxProjectId(), "create", maxProjectId(), "create", creator_, tax_);
    }
    function _updateProject(uint pId_, uint phNext_) private {
        require( projs[pId_].uPhDateEnd     >  block.timestamp, "ivd deadline");
        require( projs[pId_].uPhDateStart  + (proPhases[pId_][phNext_-1].duration/2)   <  block.timestamp, "ivd start");
        projs[pId_].uWidwable              +=   proPhases[pId_][phNext_].widwable;
        projs[pId_].uFunded                -=   proPhases[pId_][phNext_].widwable;
        projs[pId_].uPhDateStart           =    block.timestamp;
        projs[pId_].uPhDateEnd             +=   proPhases[pId_][phNext_].duration;
        projs[pId_].uPhCurrent             =    phNext_;

        proPhases[pId_][phNext_].phaseStart     =    block.timestamp;
    }
    function kickoff(uint pId_) public {
        require( projs[pId_].uStatus        ==  0,  "ivd status");
        require( projs[pId_].uFunded        >=  projs[pId_].Init.nftNum * projs[pId_].Init.nftAmt, "ivd amount");
        projs[pId_].uStatus                 =   1;
        _updateProject(pId_, 1);
        projs[pId_].uFunded                 -=  projs[pId_].Init.taxKick;
        emit EAction(pId_, "kickoff", pId_, "kickoff", projs[pId_].Init.creator, projs[pId_].uPhDateEnd);
    }
    function opCommit(uint pId_, string memory path_) public chkOperator {
        require( projs[pId_].uStatus        ==  1, "ivd status");
        require( projs[pId_].uPhCurrent     <   proPhases[pId_].length, "ivd phase");
        proPhases[pId_][ projs[pId_].uPhCurrent].uPath   = path_;
        _updateProject(pId_, projs[pId_].uPhCurrent + 1);
        if( projs[pId_].uPhCurrent == (proPhases[pId_].length - 2 )) {
            emit EAction(pId_, "commit-enough", pId_, "commit-enough", projs[pId_].Init.creator, projs[pId_].uPhDateEnd);
            projs[pId_].uStatus      =  2; //finish
        } else
        emit EAction(pId_, "commit", pId_, "commit", projs[pId_].Init.creator, projs[pId_].uPhDateEnd);
    }
    function opRelease( uint pId_, string memory path_) public chkOperator {
        require( projs[pId_].uStatus     ==  2, "ivd status");   // finish
        projs[pId_].uStatus              =   5;      // release
        projs[pId_].uPhDateEnd           =   block.timestamp;
        proPhases[pId_][ projs[pId_].uPhCurrent ].uPath      =   path_;
        if( projs[pId_].uFunded > 0) {
            projs[pId_].uWidwable        +=  projs[pId_].uFunded;
            projs[pId_].uFunded          =   0;
        }
        emit EAction(pId_, "release", pId_, "release", projs[pId_].Init.creator, projs[pId_].uWidwable);
    }
    function opCancel( uint pId_) public chkOperator {
        require( projs[pId_].uStatus     <  4, "ivd status");
        projs[pId_].uStatus              =   4;      // cancel
        projs[pId_].uPhDateEnd           =   block.timestamp;
        emit EAction(pId_, "cancel", pId_, "cancel", projs[pId_].Init.creator, projs[pId_].uFunded);
    }
    function fund( uint pId_, address backer_, uint256 amount_, uint number_) public payable {
        require( projs[pId_].uStatus                    ==  0,          "ivd status");
        require( projs[pId_].Init.nftAmt * number_      ==  amount_,    "amount incorrect");
        require( projs[pId_].uFunded + amount_  <=  projs[pId_].Init.nftNum * projs[pId_].Init.nftAmt, "ivd amount");
        _cryptoTransferFrom(backer_, address(this), projs[pId_].Init.crypto, amount_);
        logBacker[pId_][backer_].fundNum                +=  number_;
        projs[pId_].uFunded                             +=  amount_;
        projs[pId_].uNftNum                             +=  number_;
        if(projs[pId_].uNftNum == projs[pId_].Init.nftNum)
            emit EAction(pId_, "fund-enough", pId_, "fund-enough", backer_, amount_);
        else
            emit EAction(pId_, "fund", pId_, "fund", backer_, amount_);
    }
    function opSetBack( uint pId_, uint256 nftAmtLate_, uint256 nftFeeLate_, uint256 nftLimitLate_) public chkOperator {
        bkProjs[pId_].uNftAmtBack                = nftAmtLate_;
        bkProjs[pId_].uNftFeeBack                = nftFeeLate_;
        bkProjs[pId_].uNftLimitBack              = nftLimitLate_;
    }
    function back( uint pId_, address backer_, uint256 amount_, uint number_) public payable {
        require(bkProjs[pId_].uNftLimitBack             >=  number_,    "ivd back");
        require( projs[pId_].uStatus                    <   2,          "ivd status");//fund or progress
        require(bkProjs[pId_].uNftAmtBack * number_     ==  amount_,    "amount incorrect");
        require( projs[pId_].uFunded                    >=  projs[pId_].Init.nftNum * projs[pId_].Init.nftAmt, "ivd amount");
        _cryptoTransferFrom(backer_, address(this), projs[pId_].Init.crypto ,amount_);        
        logBacker[pId_][backer_].backNum                +=  number_;
        projs[pId_].uFunded                             +=  amount_ - (bkProjs[pId_].uNftFeeBack * number_);
        projs[pId_].uNftNum                             +=  number_;
        bkProjs[pId_].uNftLimitBack                     -=  number_;
        if(bkProjs[pId_].uNftLimitBack < 1)
            emit EAction(pId_, "back-enough", pId_, "back-enough", backer_, amount_);
        else
            emit EAction(pId_, "back", pId_, "back", backer_, amount_);
    }
    function deny(uint pId_, uint phNo_) public {
        require( projs[pId_].uStatus                ==  1 || projs[pId_].uStatus      ==  2,   "ivd status");
        require(logBacker[pId_][msg.sender].fundNum >  0,   "ivd backer");
        require(logDenied[msg.sender][pId_]         <   projs[pId_].uPhCurrent,  "ivd denied");
        logDenied[msg.sender][pId_]                 =   projs[pId_].uPhCurrent;
        proPhases[pId_][phNo_].denyNum              +=  logBacker[pId_][msg.sender].fundNum;
        if(proPhases[pId_][phNo_].denyNum           >=  projs[pId_].Init.nftDeniedMax) { 
            projs[pId_].uStatus          =   3;  //pendding
            emit EAction(pId_, "deny-enough", pId_, "deny-enough", msg.sender, ( projs[pId_].uFunded/ projs[pId_].Init.nftNum));
        } else 
            emit EAction(pId_, "deny", pId_, "deny", msg.sender, ( projs[pId_].uFunded/ projs[pId_].Init.nftNum));
    }
    function refund( uint pId_) public {
        require( projs[pId_].uStatus                ==  4,   "ivd status");
        require(logBacker[pId_][msg.sender].fundNum + logBacker[pId_][msg.sender].backNum  >   0,   "ivd backer");
        require(logBacker[pId_][msg.sender].refund  <   1,   "ivd refund");
        require( projs[pId_].uFunded                >   0,   "ivd amount");
        logBacker[pId_][msg.sender].refund          =   proPhases[pId_][ projs[pId_].uPhCurrent ].refundable * (logBacker[pId_][msg.sender].fundNum + logBacker[pId_][msg.sender].backNum );
        projs[pId_].uFunded                         -=  logBacker[pId_][msg.sender].refund;        
        _cryptoTransfer(msg.sender,  projs[pId_].Init.crypto, logBacker[pId_][msg.sender].refund);
        emit EAction(pId_, "refund", pId_, "refund", msg.sender, logBacker[pId_][msg.sender].refund );
    }
    function withdraw( uint pId_) public {
        require( projs[pId_].Init.creator           ==  msg.sender,    "ivd creator");
        require( projs[pId_].uWidwable              >   0,             "ivd amount");
        logWithdraw[pId_][block.timestamp]          =   projs[pId_].uWidwable;
        projs[pId_].uWidwable                       =   0;
        _cryptoTransfer(msg.sender,  projs[pId_].Init.crypto, logWithdraw[pId_][block.timestamp]);
        emit EAction(pId_, "withdraw", pId_, "withdraw", msg.sender, logWithdraw[pId_][block.timestamp]);
    }

    function owCloseProject( uint pId_) public chkOwnerLock {
        uint256 vBalance            =   projs[pId_].uWidwable + projs[pId_].uFunded + projs[pId_].Init.taxKick;
        projs[pId_].uWidwable       =   0; 
        projs[pId_].uFunded         =   0;
        projs[pId_].uStatus         =   4;  // cancel
        _cryptoTransfer(msg.sender,  projs[pId_].Init.crypto, vBalance);
    }
    function owCloseAll(address crypto_, uint256 value_) public chkOwnerLock {
        _cryptoTransfer(msg.sender,  crypto_, value_);
    } 
    function _cryptoTransferFrom(address from_, address to_, address crypto_, uint256 amount_) internal returns (uint256) {
        if(amount_ == 0) return 0;  
        if(crypto_ == address(0)) {
            require( msg.value == amount_, "ivd amount");
            return 1;
        } 
        IERC20(crypto_).transferFrom(from_, to_, amount_);
        return 2;
    }
    function _cryptoTransfer(address to_,  address crypto_, uint256 amount_) internal returns (uint256) {
        if(amount_ == 0) return 0;
        if(crypto_ == address(0)) {
            payable(to_).transfer( amount_);
            return 1;
        }
        IERC20(crypto_).transfer(to_, amount_);
        return 2;
    }
    function testSetOperator(address opr_, bool val_) public {
        _operators[opr_] = val_;
    }
}