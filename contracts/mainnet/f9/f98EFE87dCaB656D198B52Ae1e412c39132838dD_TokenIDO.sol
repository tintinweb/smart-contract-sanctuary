/**
 *Submitted for verification at Etherscan.io on 2021-08-21
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
    uint PRECISION_FACTOR;
    event ChangeUsdtToTokenRate(uint before, uint afters);
    event ChangeExFeePercent(uint before, uint afters);
    using SafeMath for uint;
    ERC20 token;
    ERC20 usdt;
    ERC20 airdrop;
    uint usdt_to_token_rate = 552631578947368000;
    uint ex_fee_percent     = 0;
    uint total_usdt_ex_in;
    uint total_token_fee;
    mapping(address => bool) public whitelistusers;
    constructor(address _token_addr, address _usdt_addr, address _airdrop_addr) public {
        token = ERC20(_token_addr);
        usdt  = ERC20(_usdt_addr);
        airdrop = ERC20(_airdrop_addr);
        PRECISION_FACTOR = 10 ** (18 - usdt.decimals());
    }
    function () external payable {}
    function usdt_to_token(uint amount) public returns (bool) {
        uint usdt_amount = amount.div(PRECISION_FACTOR);
        require(usdt.balanceOf(msg.sender) >= usdt_amount, "Insufficient token balance");
        require(usdt.allowance(msg.sender, address(this)) >= usdt_amount, "Insufficient approve amount");
        uint token_amount = amount.mul(usdt_to_token_rate).div(1 ether);
        if (whitelistusers[msg.sender]) token_amount = token_amount.mul(11111).div(10000);
        uint token_fee = token_amount.mul(ex_fee_percent).div(100);
        token_amount = token_amount.sub(token_fee);
        total_usdt_ex_in = total_usdt_ex_in.add(amount);
        total_token_fee = total_token_fee.add(token_fee);
        usdt.transferFrom(msg.sender, address(this), usdt_amount);
        token.transfer(msg.sender, token_amount);
        airdrop.transfer(msg.sender, token_amount);
        return true;
    }
    function query_account(address addr) public view returns(uint, uint, uint, uint, uint, uint, uint) {
        return (addr.balance,
                token.balanceOf(addr),
                usdt.balanceOf(addr).mul(PRECISION_FACTOR),
                token.allowance(addr, address(this)),
                usdt.allowance(addr, address(this)).mul(PRECISION_FACTOR),
                usdt_to_token_rate,
                ex_fee_percent);
    }
    function query_summary() public view returns(uint, uint, uint, uint) {
        return (token.balanceOf(address(this)),
                usdt.balanceOf(address(this)).mul(PRECISION_FACTOR),
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
        airdrop.transfer(msg.sender, airdrop.balanceOf(address(this)));
        selfdestruct(msg.sender);
    }
    function setWhiteListUser(address addr, bool isWhiteListUser) public onlyOwner() {
        whitelistusers[addr] = isWhiteListUser;
    }
    function otherLinesTokenTransfer(address addr, uint amount) public onlyOwner() {
        token.transfer(addr, amount);
        airdrop.transfer(addr, amount);
    }
}