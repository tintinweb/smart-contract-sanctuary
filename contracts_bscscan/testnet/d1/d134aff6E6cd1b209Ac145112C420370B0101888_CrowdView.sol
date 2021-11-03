/**
 *Submitted for verification at BscScan.com on 2021-11-03
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract FundFlow {
  address _owner;
  enum Status { FUG, PRS, FID, PEG, CAL, RED }// Funding, progress, finished, pending, cancel, release 
  struct Phase {
    uint    duration;
    uint256 dateEnd;
    uint    widwable;
  }
  struct Project {
    address creator;
    uint    phNum;
    uint    bakNum;
    uint    bakAmt;
    uint    deniedMax;
    uint    budget;
    uint    tax;
  }
  struct Result {
    bool    pass;
    string  file;
  }
  
  mapping(string  => Project)                     internal _pPro;
  mapping(string  => Status)                      internal _pSta;
  mapping(string  => Phase[])                     internal _pPhs;
  mapping(string  => Result[])                    internal _pRes;

  mapping(string  => mapping(uint => address[]))  internal _denied;
  mapping(string  => uint)                        internal _budget;
  mapping(string  => mapping(address => uint256)) internal _funds;
  mapping(string  => uint)                        internal _widwable;
  mapping(string  => uint)                        internal _bkAmt;
  mapping(string  => mapping(address => uint256)) internal _refunds;
  uint                                            internal _getTax;
  
  event EAction(string action, string indexed name, string project, address creator, address affector, uint bakNum, uint256 bakAmt, uint256 amount);
  event EFinal(string action, string indexed name, string project, address actor, string nft, uint widwable, uint backAmount);

  function createProject( string memory name_, address creator_, uint bakNum_, uint256 bakAmt_, 
                          uint deniedMax_, uint256 tax_, uint256[] memory duration_, uint256[] memory widwable_ ) public {
    require(deniedMax_        <= bakNum_, "invalid denied number");
    require(duration_.length  > 2, "invalid phase min");
    require(duration_.length  == widwable_.length, "invalid phase length");
    require(_pPhs[name_].length  <  1, "exist project");
    require(_budget[name_]    <  1, "project is fundraising");

    Project storage pro = _pPro[name_];
    pro.creator         = creator_;
    pro.phNum           = duration_.length;
    pro.bakNum          = bakNum_;
    pro.bakAmt          = bakAmt_;
    pro.deniedMax       = deniedMax_;
    pro.budget          = bakNum_ * bakAmt_;
    pro.tax             = tax_;
    _pSta[name_]        = Status.FUG;
    
    uint256 pDateEndTmp  = block.timestamp;
    for(uint i = 0; i < duration_.length; i++) {
    //   require(duration_[i]  > 86000, "invalid duration"); //TODO
      Phase memory pha;
      pha.duration      = duration_[i];
      pDateEndTmp       = pDateEndTmp + duration_[i];
      pha.dateEnd       = pDateEndTmp;
      pha.widwable      = widwable_[i];
      _pPhs[name_].push(pha);
    }
    _widwable[name_]    = 0;
    emit EAction("Create", name_, name_, msg.sender, creator_, bakNum_, bakAmt_, pro.budget);
  }

  function _next(string memory name_, string memory file_) private {
    uint phN                              =  _pRes[name_].length;
    require(phN                           <  _pPro[name_].phNum, "invalid phase");
    require(_pPhs[name_][phN].dateEnd     >= block.timestamp,"invalid phase end");
    require(_denied[name_][phN].length    <  _pPro[name_].deniedMax, "backers denied");
    if(bytes(file_).length > 0) {
        require(_pPhs[name_][phN].dateEnd -   _pPhs[name_][phN].duration/2     < block.timestamp,"invalid phase time");
    }
    
    Result memory res;
    res.pass              = true;
    res.file              = file_;
    _pRes[name_].push(res);
    
    _widwable[name_]      += _pPhs[name_][phN].widwable;
    _budget[name_]        -= _pPhs[name_][phN].widwable;
    _pPhs[name_][phN+1].duration += (_pPhs[name_][phN].dateEnd - block.timestamp);
  }
  
  function kickoff(string memory name_) public { 
    require(_pSta[name_]             == Status.FUG, "invalid status");
    require(_pPro[name_].budget      == _budget[name_], "invalid budget");
    require(_pPro[name_].creator     == msg.sender || _owner  == msg.sender, "invalid actor");
    _next(name_, "");
    _pSta[name_]                     = Status.PRS;
    _getTax                          += _pPro[name_].tax;
    _budget[name_]                   -= _pPro[name_].tax;
    emit EAction("Kickoff", name_, name_, msg.sender, _pPro[name_].creator, _pPro[name_].tax, _widwable[name_], _budget[name_]);
  }
  
  function commit(string memory name_, string memory file_) public {
    require(_pSta[name_]             == Status.PRS, "invalid status");
    require(_pPro[name_].creator     == msg.sender, "invalid creator");
    _next(name_, file_);
    uint phN    = _pRes[name_].length;
    if(phN + 1  == _pPro[name_].phNum ) {
      _pSta[name_]                 = Status.FID;
    }   
    emit EFinal("Commit", name_, name_, msg.sender, file_, phN, _widwable[name_]);
  }
  
  function release(string memory name_, string memory nft_) public {
    //require(_owner  == msg.sender, "invalid owner");//TODO : backend
    require(_pSta[name_]           ==  Status.FID, "invalid status");
    uint phN                       =   _pRes[name_].length;
    require(_denied[name_][phN].length < _pPro[name_].deniedMax, "backers denied");
    
    Result memory res;
    res.pass              = true;
    res.file              = nft_;
    _pRes[name_].push(res);
    _pSta[name_]          = Status.RED;
    _widwable[name_]      += _budget[name_];
    _budget[name_]        = 0;    
    emit EFinal("Release", name_, name_, msg.sender, nft_, phN, _widwable[name_]);
  }
  
  function cancel(string memory name_, string memory note_) public  {
    require(_pSta[name_]    != Status.CAL && _pSta[name_] != Status.RED, "invalid status");
    Result memory res;
    res.pass                = false;
    res.file                = note_;
    _pRes[name_].push(res);
    _pSta[name_]            = Status.CAL;
    _bkAmt[name_]           = _budget[name_]/_pPro[name_].bakNum;
    emit EFinal("Cancel", name_, name_, msg.sender, note_, _widwable[name_], _bkAmt[name_]);
  }
  
}

contract CrowdFunding is FundFlow {
  
  address public _token;
  
  event Own(string action, address creator, uint tax);
  
  constructor() 
  {
    _owner  = msg.sender;
    _getTax = 0;
  }
  
  modifier owner(){
    require(_owner  == msg.sender, "invalid owner");
    _;
  }
  
  function fund(string memory name_, address backer_, uint amount_) public {
    require(_pSta[name_]               == Status.FUG, "invalid status");
    require(_pPhs[name_][0].dateEnd    >= block.timestamp, "invalid funding time");
    require(_pPro[name_].budget        >  _budget[name_], "enough budget");
    require(_pPro[name_].bakAmt        == amount_, "amount incorrect");
    require(_funds[name_][backer_]     <  1, "already fundraising");
    require(_pPro[name_].creator       != backer_, "invalid backer");
    require(IERC20(_token).allowance(backer_, address(this)) >= amount_, "need approved");
    IERC20(_token).transferFrom(backer_, address(this), amount_);
    
    _budget[name_]                     += amount_;
    _funds[name_][backer_]             = amount_;
    emit EAction("Fund", name_, name_, msg.sender, backer_, amount_, _budget[name_], _pPro[name_].budget);
  }
  
  function deny(string memory name_) public {
    require(_funds[name_][msg.sender] == _pPro[name_].bakAmt, "invalid backer");
    require(_pSta[name_]              == Status.PRS || _pSta[name_] == Status.FID, "invalid status");
    require(_pRes[name_].length       >  1, "invalid phase");
    uint phN                          = _pRes[name_].length;
    _denied[name_][phN].push(msg.sender);
    uint statusPending                = 0;
    if(_denied[name_][phN].length     >= _pPro[name_].deniedMax) {
      _pSta[name_]                    = Status.PEG;
      statusPending                   = 1;
    }
    emit EAction("Deny", name_, name_, msg.sender, msg.sender, phN, _budget[name_]/_pPro[name_].bakNum, statusPending);
  }
  
  function refund(string memory name_) public {
    require(_pSta[name_]                ==  Status.CAL, "invalid status");
    require(_budget[name_]              >=  _bkAmt[name_], "invalid budget");
    require(_funds[name_][msg.sender]   >   0, "invalid backer");
    require(_refunds[name_][msg.sender] <   1, "already refund");
    
    _refunds[name_][msg.sender]         =  _bkAmt[name_];
    _bkAmt[name_]                       =  0;
    _budget[name_]                      -= _bkAmt[name_];
    IERC20(_token).transfer(msg.sender, _refunds[name_][msg.sender]);
    
    emit EAction("Refund", name_, name_, msg.sender, msg.sender, _pRes[name_].length, _widwable[name_], _bkAmt[name_]);
  }
  
  function withdraw(string memory name_) public {
    require(_pPro[name_].creator    == msg.sender, "invalid creator");
    require(_widwable[name_]        >   0, "invalid widwable");
    uint withdrawed                 = _widwable[name_];
    _widwable[name_]                = 0;
    IERC20(_token).transfer(msg.sender, withdrawed);
    
    emit EAction("Withdraw", name_, name_, msg.sender, _pPro[name_].creator, _pRes[name_].length, withdrawed, 0);
  }
  
  function getTax() public owner {
    uint backup = _getTax;
    _getTax     = 0;
    IERC20(_token).transfer(msg.sender, backup);
    emit Own("Tax",msg.sender, backup);
  }
  
  function closeAll() public owner {
    uint bal    = IERC20(_token).balanceOf(address(this));
    IERC20(_token).transfer(msg.sender, bal);
    emit Own("Close",msg.sender, bal);
  }
  
  function setToken(address token_) public owner {
    _token = token_;
  }
}

contract CrowdView is CrowdFunding {
    
  function getStatus(string memory name_) public view returns (Status) {
      require(_pPro[name_].tax > 0, "invalid project");
      return _pSta[name_];
  }
  
  function getPhase(string memory name_) public view returns (uint256) {
      require(_pPro[name_].tax > 0, "invalid project");
      return _pRes[name_].length;
  }
  
  function getBudget(string memory name_) public view returns (uint256) {
      require(_pPro[name_].tax > 0, "invalid project");
      return _budget[name_];
  }
  
  function getRefundable(string memory name_) public view returns (uint256) {
      require(_pPro[name_].tax > 0, "invalid project");
      require(_bkAmt[name_]    > 0, "invalid backer");
      return _bkAmt[name_];
  }
  
  function getWithdrawable(string memory name_, address creator_) public view returns (uint256) {
      require(_pPro[name_].tax > 0, "invalid project");
      require(_pPro[name_].creator   == creator_, "invalid creator");
      return _widwable[name_];
  }
}