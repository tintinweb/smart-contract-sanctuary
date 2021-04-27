// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.22 <0.9.0;

import "./FundShare.sol";


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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


contract FundContract{

    string public name = "Fund";
    address private owner; 

    
    IERC20 private daiToken;

    struct Request{
        address user;
        uint256 amount;
        bool isPending; // false: deposit has been accepted or rejected, true: deposit pending
    }

    struct Fund{
        address fundManager;
        mapping(address => Request) depositRequests;
        mapping(address => Request) withdrawRequests;
        uint depositRequestCount;
        uint withdrawRequestCount;
        address[] users;
        mapping(address => bool) userExists;
        uint NAV;
        mapping(address => uint) depositedBalance;
        uint totalDeposit;
        FundShare sharesToken;
    }

    mapping(address => Fund) public fundMapping;

    mapping(address => address) public referral;

    constructor(address _daiToken, address _owner){
        owner = _owner;

        daiToken = IERC20(_daiToken);
    }
    
    //get DAI balance of _addr
    function getDAIBalance() 
    public view 
    returns(uint){

        return (daiToken.balanceOf(msg.sender));
    }
    

    // get shares balance of _addr
    function getSharesBalance(address fund_address) 
    public view 
    returns(uint){
        Fund storage fund = fundMapping[fund_address];
        require(fund.fundManager==fund_address, "Fund not found");

        return (fund.sharesToken.balanceOf(fund_address));
    }


    event newUser(address _addr);
    event referralSend(address _from, address _to, uint _amount);

    // create a new fund
    // fund-manager would be the msg.sender
    // sharesTokens would be a IERC20 contract
    function createFund(FundShare _sharesToken)
    public{

        Fund storage fund = fundMapping[msg.sender];
        fund.fundManager = msg.sender;
        fund.sharesToken = _sharesToken;
        fund.NAV = 1;
    }

    // get user's deposited balance
    function getDepositedBalance(address fundManagerAddress) 
    public view returns(uint){
        Fund storage fund = fundMapping[fundManagerAddress];
        require(fund.fundManager==fundManagerAddress, "Fund not found");

        return(fund.depositedBalance[msg.sender]);
    }

    // get user's pending deposit request
    function getMyDepositRequest(address fundManagerAddress) 
    public view returns(Request memory){
        Fund storage fund = fundMapping[fundManagerAddress];
        require(fund.fundManager==fundManagerAddress, "Fund not found");

        require(fund.depositRequests[msg.sender].isPending, "Pending request not found.");

        return(fund.depositRequests[msg.sender]);
    }

    // get user's pending withdrawal request
    function getMyWithdrawalRequest(address fundManagerAddress) 
    public view returns(Request memory){
        Fund storage fund = fundMapping[fundManagerAddress];
        require(fund.fundManager==fundManagerAddress, "Fund not found");

        require(fund.withdrawRequests[msg.sender].isPending, "Pending request not found.");

        return(fund.withdrawRequests[msg.sender]);
    }

    // Deposit request function
    // fundManagerAddress = fund manager's address
    // user creates a new deposit request with _amount
    // refAddr: address of the referral, 0x00 if no referral
    function sendDepositRequest(uint _amount, address fundManagerAddress, address _refAddr) 
    public{
        // Require amount greater than 0
        require(_amount > 0, "Deposit amount cannot be 0");

        Fund storage fund = fundMapping[fundManagerAddress];
        require(fund.fundManager==fundManagerAddress, "Fund not found");
        
        daiToken.transferFrom(msg.sender, address(this), _amount);
        // Add user to deposit request 

        // check if deposit request already exist
        if(fund.depositRequests[msg.sender].user == msg.sender) {
            fund.depositRequests[msg.sender].amount += _amount;
        }
        // for new user
        else{
            Request memory req = Request(msg.sender, _amount, true);
            fund.depositRequests[msg.sender] = req;
            fund.depositRequestCount+=1;
            if(!fund.userExists[msg.sender]){
                fund.users.push(msg.sender);
                fund.userExists[msg.sender] = true;
                emit newUser(msg.sender);
                referral[msg.sender] = _refAddr;
            }
        }
    }

    // get users array from fund
    function getAllUsers() public view returns(address[] memory){
        Fund storage fund = fundMapping[msg.sender];
        require(fund.fundManager==msg.sender, "Fund not found");
        return(fund.users);
    }

    function getPendingDepositRequests() 
    public view 
    returns(Request[] memory) {
        Fund storage fund = fundMapping[msg.sender];
        require(fund.fundManager==msg.sender, "Fund not found");

        Request[] memory pendingRequests = new Request[](fund.depositRequestCount);
        uint count = 0;
        for(uint i=0; i<fund.users.length; i++){
            if(fund.depositRequests[fund.users[i]].isPending){
                pendingRequests[count] = fund.depositRequests[fund.users[i]];
                count++;
            }
        }
        return pendingRequests;
    }
    

    // param
    // _addr -> address of the user
    // _nav -> net asset value (shares/dai)
    // 3% entrance fee
    // 3% referral fee
    function acceptDeposit(address _addr, uint256 _nav) public{

        Fund storage fund = fundMapping[msg.sender];
        require(fund.fundManager==msg.sender, "Fund not found");
        require(fund.depositRequests[_addr].isPending, "No pending deposit request found.");

        uint entrance_fee = fund.depositRequests[_addr].amount*3/100;
        //  deposit the amount to fund owner
        daiToken.transfer(owner, entrance_fee);

        uint deposit_amount = fund.depositRequests[_addr].amount*94/100;

        //3%
        uint referral_amount = fund.depositRequests[_addr].amount*3/100;

        // if no referrals
        if(referral[_addr]==address(0x0000000000000000000000000000000000000000)){
            deposit_amount += referral_amount;
        }
        else{
            address ref = referral[_addr];
            while(ref!=address(0x0000000000000000000000000000000000000000)){
                // 90%
                referral_amount = referral_amount*90/100;
                daiToken.transfer(referral[_addr], referral_amount);
                emit referralSend(_addr, referral[_addr], referral_amount);
                // 10%
                referral_amount = referral_amount*10/100;
                ref = referral[ref];
            }

            daiToken.transfer(referral[_addr], referral_amount);
        }

        // add to deposit
        fund.depositedBalance[_addr] += deposit_amount;

        //  deposit the amount to fund owner
        daiToken.transfer(fund.fundManager, deposit_amount);

        fund.totalDeposit += deposit_amount;

        //empty the deposit request
        delete fund.depositRequests[_addr];
        fund.depositRequestCount-=1;

        // transfer shares to user
        fund.sharesToken.transfer(_addr, deposit_amount/_nav);
    }


    // accept all pending requests
    // numShares = amountDeposited
    function acceptAllDeposits(uint256 _nav) public{

        Request[] memory pending = getPendingDepositRequests();
        for(uint i=0; i<pending.length; i++){
            if(pending[i].isPending){
                acceptDeposit(pending[i].user, _nav);
            }
        }
    }
    

    // invalidate the deposit request and return the DAI tokens back
    function rejectDeposit(address _addr) public{

        Fund storage fund = fundMapping[msg.sender];
        require(fund.fundManager==msg.sender, "Fund not found");

        require(fund.depositRequests[_addr].isPending, "No pending deposit request found");
        
        // return the dai tokens to user
        daiToken.transfer(_addr, fund.depositRequests[_addr].amount);
        
        //empty the deposit request
        delete fund.depositRequests[_addr];
        fund.depositRequestCount-=1;
    }

    function rejectAllDeposit() public{

        Request[] memory pending = getPendingDepositRequests();
        for(uint i=0; i<pending.length; i++){
            if(pending[i].isPending){
                rejectDeposit(pending[i].user);
            }
        }
    }
    

    // create a withraw request
    // param: number of shares to withdraw
    function requestWithdraw(address fund_manager, uint256 _numShares) public{
        require(_numShares>0, "Amount should be >0");

        Fund storage fund = fundMapping[fund_manager];
        require(fund.fundManager==fund_manager, "Fund not found");

        fund.sharesToken.transferFrom(msg.sender, address(this), _numShares);

        // check if withdraw request already exist
        if(fund.withdrawRequests[msg.sender].user == msg.sender) {
            fund.withdrawRequests[msg.sender].amount += _numShares;
        }
        // for new user
        else{
            Request memory req = Request(msg.sender, _numShares, true);
            fund.withdrawRequests[msg.sender] = req;
            fund.withdrawRequestCount+=1;
        }
       
    }

    function getPendingWithdrawRequests() 
    public view
    returns(Request[] memory){
        Fund storage fund = fundMapping[msg.sender];
        require(fund.fundManager==msg.sender, "Fund not found");

        Request[] memory pendingRequests = new Request[](fund.withdrawRequestCount);
        uint count = 0;
        for(uint i=0; i<fund.users.length; i++){
            if(fund.withdrawRequests[fund.users[i]].isPending){
                pendingRequests[count] = fund.withdrawRequests[fund.users[i]];
                count++;
            }
        }
        return pendingRequests;
    }


    // 3% withdrawal fee
    function acceptWithdraw(address _addr, uint256 _nav) public{

        Fund storage fund = fundMapping[msg.sender];
        require(fund.fundManager==msg.sender, "Fund not found");

        require(fund.withdrawRequests[_addr].isPending, "No pending withdraw request found.");

        daiToken.transferFrom(fund.fundManager, address(this), fund.withdrawRequests[_addr].amount*_nav);

        fund.sharesToken.transfer(fund.fundManager, fund.withdrawRequests[_addr].amount);

        daiToken.transfer(_addr, fund.withdrawRequests[_addr].amount*_nav*97/100);

        //3% withdraw fee
        daiToken.transfer(owner, fund.withdrawRequests[_addr].amount*_nav*3/100);

        delete fund.withdrawRequests[_addr];
        fund.withdrawRequestCount-=1;
    }


    function acceptAllWithdraws(uint256 _nav) public{

        Request[] memory pending = getPendingWithdrawRequests();
        for(uint i=0; i<pending.length; i++){
            if(pending[i].isPending){
                acceptWithdraw(pending[i].user, _nav);
            }
        }
    }

    event transferFromFund(uint _amount, uint _balance);

    function rejectWithdraw(address _addr) public{
        Fund storage fund = fundMapping[msg.sender];
        require(fund.fundManager==msg.sender, "Fund not found");

        require(fund.withdrawRequests[_addr].isPending, "No pending deposit request found");
        
        emit transferFromFund(fund.withdrawRequests[_addr].amount, fund.sharesToken.balanceOf(address(this)));
        // return the fund shares to user
        
        fund.sharesToken.transfer(_addr, fund.withdrawRequests[_addr].amount);

        //empty the deposit request
        delete fund.withdrawRequests[_addr];
        fund.withdrawRequestCount-=1;

    }

    function rejectAllWithdraws() public{

        Request[] memory pending = getPendingWithdrawRequests();
        for(uint i=0; i<pending.length; i++){
            if(pending[i].isPending){
                rejectWithdraw(pending[i].user);
            }
        }
    }
}