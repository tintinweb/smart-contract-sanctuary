/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

/*
The next escrow contract uses a role based contract to provide permissions and automate interaction through a freelancer platform.

Most of the transaction costs are considerably low even transfers, version 1.0.

This will probably be mass produced through a implementation proxy TBA

*/



pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

contract Roles is Context {
    address private _mediator;
    address private _previousOwner;
    uint256 private _lockTime;
    address payable  public _payer;
    address payable public _payee;
    bool private updatedPayee = false;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    

    constructor () {
        address msgSender = _msgSender();
        _mediator = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function mediator() public view returns (address) {
        return _mediator;
    }     
    modifier onlyMediator() { //modifier to make functions only accessible to management
        require(_mediator == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    modifier onlyPayee(){
        require(_payee == _msgSender(),"Escrow role: Function caller is not the service provider");
        _;
    }
    modifier onlyPayer(){
        require(_payer == _msgSender(),"Escrow role: Function caller is not the client");
        _;
    }

    function renounceOwnership() public virtual onlyMediator {
        emit OwnershipTransferred(_mediator, address(0));
        _mediator = address(0);
    }
    function setPayee(address payable _Payee) external {
        require((_msgSender() == _mediator ) || (_msgSender() == _payer && updatedPayee == false));
        _payee = _Payee;
        updatedPayee == true;


    }

    function setPayer(address payable _Payer) external onlyMediator{
        _payer = _Payer;
    }
  

    function transferOwnership(address newOwner) public virtual onlyMediator {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_mediator, newOwner);
        _mediator = newOwner;
    }
    
    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }
    
}


contract TheCollectiveEscrow is Context, Roles{

    string private _name = "CollectiveEscrow";
    string private _symbol = "TCCESCROW";
    uint256 private feePercentage = 10;
    bool private JobDone = false;
    address payable public feesAddress = payable(0xDd711BBad691c4b18fF00b9ac966732fD70dC707);
    event freelancerPayment(address payable payee, uint256 amount);
    event refundedEscrow(uint256 amount);
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) public balances;
    IERC20 paymentTokenAddress;
    
    constructor () {

    }
    function name() public view returns (string memory) {
        return _name;
    }
    function CurrentDivisor() public view returns(uint256){
        return feePercentage;
    }


    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function balanceSC () public view returns(uint256){
        return address(this).balance;
    }

    function updatePercentage(uint256 newInt) external onlyMediator{
        feePercentage = newInt;

    }

    function deposit(uint256 amountDeposited) public payable{
            

    }

    function setPaymentToken(address tokenAddress) public onlyMediator{
        paymentTokenAddress = IERC20(tokenAddress);
        balances[address(this)] = paymentTokenAddress.balanceOf(address(this));

    }

    function checkBal() public view returns(uint256) {
        
        return balances[address(this)];
        
    }
    



    function updateJobstatus()external onlyPayer{
        require(JobDone == false,"Job status:Job completed, funds sent");
        JobDone = true;
        if(JobDone){
            uint256 currentBalance = address(this).balance;
            uint256 PayableBalance = currentBalance - (currentBalance/feePercentage);
            _payee.transfer(PayableBalance);
            feesAddress.transfer(currentBalance/feePercentage);
            emit freelancerPayment(_payee, PayableBalance);
        }                             

    }

    function updateJobStatusOverride() external onlyMediator{ //Updates the job status to completed in order to send the funds to Freelancer and destroy the contact instance

        require(JobDone == false,"Job status:Job completed, funds sent");
        JobDone = true;
        if(JobDone){
            uint256 currentBalance = address(this).balance;
            uint256 PayableBalance = currentBalance - (currentBalance/feePercentage);
            _payee.transfer(PayableBalance);
            feesAddress.transfer(currentBalance/feePercentage);
        }
    }
    function refundEscrow() external onlyPayee{ //Allows Freelancer to refund customer in full at low gas cost. 
        require(address(this).balance > 0,"Internal escrow balance: Nothing to refund escrow is empty");
        payable(_payer).transfer(address(this).balance);
        emit refundedEscrow(address(this).balance);


    }

    function refundEscrowOverride() external onlyMediator{ //Will refund escrow in case theres an unsolvable dispute only callable by mediators
        require(address(this).balance > 0,"Internal escrow balance: Nothing to refund escrow is empty");
        _payer.transfer(address(this).balance);
        emit refundedEscrow(address(this).balance);


    }

    function finalize() external onlyMediator {
        require(JobDone == true,"Contract cant be destroyed, job not completed");
        selfdestruct(feesAddress);
        
    }   

    function updateFeeAddress(address payable newAddress) external onlyMediator{
            feesAddress = newAddress;
    }

    
     //to receive bnb
    receive() external payable {}
}