/**
 *Submitted for verification at BscScan.com on 2021-09-27
*/

// SPDX-License-Identifier: GNU GENERAL PUBLIC LICENSE V3

pragma solidity ^0.8.2;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract KanSale is Ownable {
    
    IERC20 public tokenContract;
    
    uint256 public saleEnds;
    uint256 public saleStarts;
    
    uint256 public price;
    
    bool public finalized = false;
    
    bool public cancelled = false;
    
    bool public allowWithdrawBeforeSaleEnds = true;
    
    mapping(address => uint256) public balances;
    
    uint256 public maxTokenPerInvestor;
    
    mapping(address => uint256) public maxTokenPerInvestorOverwrites;
    
    mapping(address => bool) public tokenClaimed;
    
    uint256 totalInvested = 0;
    uint256 totalInvestors = 0;
    uint256 totalTokensClaimed = 0;
    
    event Withdrawal(address investor, uint256 balance);
    event Deposited(address investor, uint256 balance);
    event TokensClaimed(address investor, uint256 tokens);
    event Finalized();
    event Cancelled();
    event SaleTimesChanged(uint256 starts, uint256 ends);
    event TokenContractChanged(address newAddress);
    event AllowWithdrawBeforeSaleEndsChanged(bool isAllowed);
    event MaxTokenPerInvestorChanged();
    
    
    constructor(address __tokenAddress, uint256 __saleStarts, uint256 __saleEnds, uint256 __price, uint256 __maxTokenPerInvestor, bool __allowWithdrawBeforeSaleEnds){
        require(__saleStarts < __saleEnds, 'Invalid params');
        tokenContract = IERC20(__tokenAddress);
        saleStarts = __saleStarts;
        saleEnds = __saleEnds;
        price = __price;
        maxTokenPerInvestor = __maxTokenPerInvestor;
        allowWithdrawBeforeSaleEnds = __allowWithdrawBeforeSaleEnds;
    }
    
    modifier notCancelledOrFinalized(){
        require(!cancelled, 'Sale cancelled!');
        require(!finalized, 'Sale finalized');
        _;
    }
    
    function setTokenAddress(address __address) public onlyOwner notCancelledOrFinalized{
        IERC20 newTokenContract = IERC20(__address);
        uint256 balance = newTokenContract.balanceOf(address(this));
        require(balance >= (totalInvested / price), 'Sale contract do not have enought tokens to sale in this token contract!');
        tokenContract = newTokenContract;
        emit TokenContractChanged(__address);
    }
    
    function setSaleTimes(uint256 __starts, uint256 __ends) public onlyOwner notCancelledOrFinalized{
        require(__starts < __starts, 'Invalid params');
        saleStarts = __starts;
        saleEnds = __ends;
        emit SaleTimesChanged(__starts, __ends);
    }

    
    function finalize() public onlyOwner notCancelledOrFinalized{
        require(block.timestamp >= saleEnds, 'Sale is not ended yet!');
        finalized = true;
        emit Finalized();
    }
    
    function setAllowWithdrawBeforeSaleEnds(bool __isAllowed) public onlyOwner notCancelledOrFinalized{
        allowWithdrawBeforeSaleEnds = __isAllowed;
        emit AllowWithdrawBeforeSaleEndsChanged(__isAllowed);
    }
    
    function cancelSale() public onlyOwner notCancelledOrFinalized{
        cancelled = true;
        emit Cancelled();
    }
    
    function setMaxTokenPerInvestor(uint256 __amount) public onlyOwner notCancelledOrFinalized{
        maxTokenPerInvestor = __amount;
        emit MaxTokenPerInvestorChanged();
    }
    
    function setMaxTokenPerInvestorOverwrite(address __address, uint256 __amount) public onlyOwner notCancelledOrFinalized{
        maxTokenPerInvestorOverwrites[__address] = __amount;
        emit MaxTokenPerInvestorChanged();
    }
    
    function maxTokenPerInvestorOf(address __address) public view returns(uint256){
        uint256 overwrite = maxTokenPerInvestorOverwrites[__address];
        if(overwrite > 0){
            return overwrite;
        }
        else{
            return maxTokenPerInvestor;
        }
    }
    
    function myMaxTokenPerInvestor() public view returns(uint256){
        return maxTokenPerInvestorOf(_msgSender());
    }
    
    function balanceOf(address __address) public view returns(uint256){
        return balances[__address];
    }
    
    function myBalance() public view returns(uint256){
        return balances[_msgSender()];
    }
    
    function totalTokens() public view returns(uint256){
        uint256 total = tokenContract.balanceOf(address(this));
        return total;
    }
    
    function remainingTokens() public view returns(uint256){
        return totalTokens() - (totalInvested / price);
    }
    
    //Tra ve so token cho claim
    function pendingTokensOf(address __address) public view returns(uint256){
        uint256 balance = balanceOf(__address);
        return balance / price;
    }
    
    function myPendingTokens() public view returns(uint256){
        return pendingTokensOf(_msgSender());
    }
    
    function remaingTokensToBuyOf(address __address) public view returns(uint256){
        return maxTokenPerInvestorOf(__address) - pendingTokensOf(__address);
    }
    
    function myRemaingTokensToBuy() public view returns(uint256){
        return remaingTokensToBuyOf(_msgSender());
    }
    
    //Investor deposit bnb de mua token
    function deposit() public payable notCancelledOrFinalized{
        require(block.timestamp > saleStarts && block.timestamp < saleEnds, 'Sale ended!');
        uint256 balance = balances[_msgSender()];
        uint256 tokens = balance / price;
        uint256 maxCanBuy = maxTokenPerInvestorOf(_msgSender());
        uint256 tokenAmount = msg.value / price;
        require(tokens + tokenAmount <= maxCanBuy, 'Exceeded the maximum tokens you can buy.');
        uint256 canSale = remainingTokens() * price;
        require(canSale >=  msg.value, 'Not enought tokens to sale');
        totalInvested = totalInvested + msg.value;
        balances[_msgSender()] = balance + msg.value;
        if(balance == 0){
            totalInvestors = totalInvestors + 1;
        }
        
        emit Deposited(_msgSender(), msg.value);
    }
    
    //Investor rut bnb
    function withdraw() public{
        require(balances[_msgSender()] > 0,  'No balance to withdraw!');
        require(!finalized, 'Sale is finalized!');
        if(!cancelled){
            bool saleEnded = block.timestamp >= saleEnds;
            if(!saleEnded){
                require(allowWithdrawBeforeSaleEnds, 'Not allow to withdraw before sale ended!');
            }
        }
        uint256 balance = balances[_msgSender()];
        totalInvested = totalInvested - balance;
        balances[_msgSender()] = 0;
        totalInvestors = totalInvestors - 1;
        
        payable(_msgSender()).transfer(balance);
        
        emit Withdrawal(_msgSender(), balance);
    }
    
    //Investor claim token khi sale finalized
    function claimTokens() public {
        require(finalized, 'Sale is not finalized yet!');
        require(balances[_msgSender()] > 0,  'Nothing to claim!');
        require(!tokenClaimed[_msgSender()], 'Tokens claimed!');
        uint256 balance = balances[_msgSender()];
        uint256 tokens = balance / price;
        totalTokensClaimed = totalTokensClaimed + tokens;
        tokenClaimed[_msgSender()] = true;
        
        tokenContract.transfer(_msgSender(), tokens);
        
        emit TokensClaimed(_msgSender(), tokens);
    }
    
    //Owner withdraw bnb khi sale finalized
    function saleResultWithdraw(address __to) public onlyOwner{
        require(finalized, 'Only can withdraw once sale finalized');
        require(address(this).balance > 0, 'Nothing to withdraw!');
        uint256 amount = address(this).balance;
        payable(__to).transfer(amount);
    }
    
    //Owner transfer token den vi khac
    function saleTokensTransfer(address __to, uint256 __amount) public onlyOwner{
        require(remainingTokens() >= __amount, 'Not enought tokens to transfer!');
        tokenContract.transfer(__to, __amount);
    }
    
}