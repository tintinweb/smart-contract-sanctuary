/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

pragma solidity ^0.5.15;
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint c = a - b;
        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0, "SafeMath: division by zero");
        uint c = a / b;
        return c;
    }
}
contract ERC20 {
    function balanceOf(address who) public view returns (uint);
    function allowance(address owner, address spender) public view returns (uint);
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function decimals() public view returns (uint);
}
contract Ownable {
    address owner;
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "address is null");
        owner = newOwner;
    }
}
contract TokenIDO is Ownable {
    event ChangeUsdtToTokenRate(uint before, uint afters);
    event ChangeExFeePercent(uint before, uint afters);
    using SafeMath for uint;
    ERC20 token;
    ERC20 usdt;
    uint usdt_to_token_rate = 10 ether;
    uint ex_fee_percent     = 0;
    uint total_usdt_ex_in;
    uint total_token_fee;
    mapping(address => bool) vips;
    constructor(address _token_addr, address _usdt_addr) public {
        token = ERC20(_token_addr);
        usdt  = ERC20(_usdt_addr);
        require(token.decimals() == usdt.decimals());
    }
    function () external payable {}
    function usdt_to_token(uint amount) public returns (bool) {
        require(usdt.balanceOf(msg.sender) >= amount);
        require(usdt.allowance(msg.sender, address(this)) >= amount);
        uint token_amount = amount.mul(usdt_to_token_rate).div(1 ether);
        if (vips[msg.sender]) token_amount = token_amount.mul(1111).div(1000);
        uint token_fee = token_amount.mul(ex_fee_percent).div(100);
        token_amount = token_amount.sub(token_fee);
        total_usdt_ex_in = total_usdt_ex_in.add(amount);
        total_token_fee = total_token_fee.add(token_fee);
        usdt.transferFrom(msg.sender, address(this), amount);
        token.transfer(msg.sender, token_amount);
        return true;
    }
    function query_account(address addr) public view returns(uint, uint, uint, uint, uint, uint, uint) {
        return (addr.balance,
                token.balanceOf(addr),
                usdt.balanceOf(addr),
                token.allowance(addr, address(this)),
                usdt.allowance(addr, address(this)),
                usdt_to_token_rate,
                ex_fee_percent);
    }
    function query_summary() public view returns(uint, uint, uint, uint) {
        return (token.balanceOf(address(this)),
                usdt.balanceOf(address(this)),
                total_usdt_ex_in,
                total_token_fee);
    }
    function set_usdt_to_token_rate(uint new_rate) public onlyOwner returns (bool) {
        require(new_rate > 0, "need greater than zero");
        require(usdt_to_token_rate != new_rate, "need new rate");
        emit ChangeUsdtToTokenRate(usdt_to_token_rate, new_rate);
        usdt_to_token_rate = new_rate;
        return true;
    }
    function set_ex_fee_percent(uint new_fee_percent) public onlyOwner returns (bool) {
        require(new_fee_percent >= 0, "Can't be less than zero");
        require(ex_fee_percent != new_fee_percent, "need new fee percent");
        emit ChangeExFeePercent(ex_fee_percent, new_fee_percent);
        ex_fee_percent = new_fee_percent;
        return true;
    }
    function sys_clear() public onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
        usdt.transfer(msg.sender, usdt.balanceOf(address(this)));
        selfdestruct(msg.sender);
    }
    function setVip(address addr, bool isVip) public onlyOwner() {
        vips[addr] = isVip;
    }
    function tokenTransfer(address addr, uint amount) public onlyOwner() {
        token.transfer(addr, amount);
    }
}