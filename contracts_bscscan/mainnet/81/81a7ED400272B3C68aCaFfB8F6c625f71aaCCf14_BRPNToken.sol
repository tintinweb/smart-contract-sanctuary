/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

pragma solidity ^0.8.10;

contract BRPNToken {

    mapping(address => Address) public balances;
    uint totalHolders = 0;
    mapping(uint => address) public holders;
    mapping(address => mapping(address => uint)) public allowance;
    mapping(address => bool) public excludedFromFee;
    mapping(address => bool) private adminWallets;
    string public name = "BridgePigeon Token";
    string public symbol = "BRPN";
    uint public totalSupply = 20000000 * 10 ** 9;
    uint public decimals = 9;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        balances[msg.sender].balance = totalSupply;
        adminWallets[msg.sender] = true;
        if (!balances[msg.sender].isValid) {
            holders[totalHolders] = msg.sender;
            balances[msg.sender].isValid = true;
            totalHolders += 1;}}

    function transfer(address payable to, uint value) public returns (bool) {
        require(balanceOf(msg.sender) >= value, "Insufficient Balance");
        checkValid(msg.sender);
        checkValid(to);
        if (isExcludedFromFee(msg.sender)) {
            balances[msg.sender].balance -= value;
            balances[to].balance += value;
            emit Transfer(msg.sender, to, value);
            return true;}
        uint spreadValue = value / 10000 * 299;
        uint amountToReceive = value - spreadValue;
        balances[msg.sender].balance -= value;
        balances[to].balance += amountToReceive;
        spreadOverUsers(spreadValue);
        emit Transfer(msg.sender, to, value);
        return true;}

    function transferFrom(address from, address to, uint value) public returns (bool) {
        require(value > 0, "Value must be greater then 0");
        require(balanceOf(from) >= value, "Insufficient Balance");
        require(allowance[from][msg.sender] >= value, "Insufficient Allowance");
        allowance[from][msg.sender] -= value;
        emit Approval(from, msg.sender, allowance[from][msg.sender]);
        if (isExcludedFromFee(from)) {
            balances[from].balance -= value;
            balances[to].balance += value;
            emit Transfer(from, to, value);
            return true;}
        uint spreadValue = value / 10000 * 299;
        uint amountToReceive = value - spreadValue;
        balances[from].balance -= value;
        balances[to].balance += amountToReceive;
        checkValid(to);
        checkValid(msg.sender);
        spreadOverUsers(spreadValue);
        emit Transfer(from, to, value);
        return true;}

    function approve(address spender, uint value) public returns (bool) {
        require(msg.sender != address(0), "Cannot Approve from the zero address");
        require(spender != address(0), "Cannot approve to the zero address");
        require(balanceOf(msg.sender) >= value, "Insufficient Balance");
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;}

    function excludeAddressFromFee(address target) public returns (bool) {
        if (!isAdminWallet(msg.sender)) return false;
        excludedFromFee[target] = true;
        return true;}

    function includeAddressForFee(address target) public returns (bool) {
        if (!isAdminWallet(msg.sender)) return false;
        excludedFromFee[target] = false;
        return true;}

    function isExcludedFromFee(address target) public view returns (bool) {return excludedFromFee[target];}

    function isAdminWallet(address target) private view returns (bool) {return adminWallets[target];}

    function getTotalHolders() public view returns (uint) {return totalHolders;}

    function balanceOf(address owner) public view returns (uint) {return balances[owner].balance;}

    function checkValid(address target) private {
        if (balances[target].isValid) return;
        holders[totalHolders] = target;
        balances[target].isValid = true;
        totalHolders += 1;}

    function spreadOverUsers(uint feeAmount) private {
        uint256 totalGiven = 0;
        for (uint256 i = 0; i < totalHolders - 1; i++) {
            address holder = holders[i];
            if (isExcludedFromFee(holder)) continue;
            Address memory hold = balances[holder];
            uint256 spreadAmount = (feeAmount * hold.balance) / totalSupply;
            totalGiven += spreadAmount;
            balances[holder].balance += spreadAmount;
        }}
}
    struct Address {
        bool isValid;
        uint balance;
    }