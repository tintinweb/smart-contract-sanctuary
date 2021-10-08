/**
 *Submitted for verification at BscScan.com on 2021-10-07
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: Unlicensed

contract BrewBank {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    mapping (address => uint) private balances;
    address public bankManager;
    address payable public migrationWallet = payable(0x0a10Bb17AA8087e5b0cB1c76Ca75A5A953CFef72);

    event LogDepositMade(address indexed accountAddress, uint amount);

    constructor() {
        bankManager = msg.sender;
        _status = _NOT_ENTERED;}
    
    modifier nonReentrant() {
        require(_status != _ENTERED, "No.");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;}
    
    modifier onlyManager() {
        require(bankManager == msg.sender, "Only The Bank Manager Can Call This Function.");
        _;}

    function depositBNB() internal returns (uint) {
        balances[msg.sender] += msg.value;
        emit LogDepositMade(msg.sender, msg.value);
        return balances[msg.sender];}

    function withdraw(uint withdrawAmount) public nonReentrant returns (uint remainingBal) {
        if (withdrawAmount <= balances[msg.sender]) {
            balances[msg.sender] -= withdrawAmount;
            payable(msg.sender).transfer(withdrawAmount);}
        return balances[msg.sender];}

    function viewBalance() public view returns (uint) {
        return balances[msg.sender];}
    
    function closeBranch() external onlyManager {
        selfdestruct(migrationWallet);}
    
    receive() external payable {
        depositBNB();}
        
    fallback() external payable {
        depositBNB();}}