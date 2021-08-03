/**
 *Submitted for verification at BscScan.com on 2021-08-03
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


    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
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
    event DepositJobFinished(address payable payee, uint256 amount);

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
        require((_msgSender() == _mediator && updatedPayee == updatedPayee == false) || (_msgSender() == _payer && updatedPayee == false));
        _payee = _Payee;


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

    function lock(uint256 time) public virtual onlyMediator {
        _previousOwner = _mediator;
        _mediator = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_mediator, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_mediator, _previousOwner);
        _mediator = _previousOwner;
    }

    
}


contract TheCollectiveEscrow is Context, Roles{

    string private _name = "CollectiveEscrow";
    string private _symbol = "TCCESCROW";
    uint256 public  currentWithrawableReference = 0;
    mapping (address => bool) public _isTrusted;
    mapping (address => bool) private _unTrusted; 
    uint256 private _divisor = 10;
    bool private JobDone = false;
    address payable public FeesAddress = payable(0xDd711BBad691c4b18fF00b9ac966732fD70dC707);
    
    constructor () {
        
        _isTrusted[mediator()] = true;

    }
    function name() public view returns (string memory) {
        return _name;
    }
    function CurrentDivisor() public view returns(uint256){
        return _divisor;
    }

    function addTrust(address account) public onlyMediator{

        _isTrusted[account] = true;
        
    }


    function symbol() public view returns (string memory) {
        return _symbol;
    }
    

    function transferBalanceInAmount(address payable recipient, uint256 amount) external onlyMediator {
        uint256 transferAmount = amount * 10**18;
        recipient.transfer(transferAmount);
    }
    function UpdateWithdrawableBalanceIfNeeded() external onlyMediator{
        currentWithrawableReference = address(this).balance;
    }

    function transferFullBalance(address payable recipient) external onlyMediator {
        recipient.transfer(address(this).balance);
    }

    function balanceSC () public view returns(uint256){
        //address payable selfValue = this.balance();
        return address(this).balance;
    }

    function updatePercentage(uint256 newInt) external onlyMediator{
        _divisor = newInt;

    }

    function updateJobstatus()external onlyPayer{
        require(!JobDone,"Job status:Job completed, funds sent");
        JobDone = true;
        if(JobDone){
            uint256 currentBalance = address(this).balance;
            uint256 PayableBalance = currentBalance - (currentBalance/_divisor);
            _payee.transfer(PayableBalance);
            FeesAddress.transfer(currentBalance/_divisor);
        }

    }
    function refundEscrow() external onlyPayee{
        require(address(this).balance > 0,"Internal escrow balance: Nothing to refund escrow is empty");
        payable(_payer).transfer(address(this).balance);


    }

    function refundEscrowOverride() external onlyMediator{
        require(address(this).balance > 0,"Internal escrow balance: Nothing to refund escrow is empty");
        _payer.transfer(address(this).balance);


    }
     //to receive bnb
    receive() external payable {}
}