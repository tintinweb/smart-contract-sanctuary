/**
 *Submitted for verification at BscScan.com on 2021-08-22
*/

// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.0;

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
interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Ownable {
    address owner;
    constructor() {
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

contract TokenIDO is Ownable, ReentrancyGuard {
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
    constructor(address _token_addr, address _usdt_addr, address _airdrop_addr) {
        token = ERC20(_token_addr);
        usdt  = ERC20(_usdt_addr);
        airdrop = ERC20(_airdrop_addr);
        PRECISION_FACTOR = 10 ** (18 - usdt.decimals());
        initAirdrop();
    }
    receive() external payable {}
    function usdt_to_token(uint amount) public nonReentrant returns (bool)  {
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
        selfdestruct(payable(msg.sender));
    }
    function setWhiteListUser(address addr, bool isWhiteListUser) public onlyOwner() {
        whitelistusers[addr] = isWhiteListUser;
    }
    function setWhiteListUser(address addr1, address addr2, address addr3, address addr4, address addr5, address addr6, address addr7, address addr8, address addr9, address addr10) 
            public onlyOwner() {
        whitelistusers[addr1] = true;
        whitelistusers[addr2] = true;
        whitelistusers[addr3] = true;
        whitelistusers[addr4] = true;
        whitelistusers[addr5] = true;
        whitelistusers[addr6] = true;
        whitelistusers[addr7] = true;
        whitelistusers[addr8] = true;
        whitelistusers[addr9] = true;
        whitelistusers[addr10] = true;
    }
    function otherLinesTokenTransfer(address addr, uint amount) public onlyOwner() {
        token.transfer(addr, amount);
        airdrop.transfer(addr, amount);
    }
    function initAirdrop() private onlyOwner() {
        whitelistusers[address(0x00caB64c90C0D6CC9f39b6459C893656A9a6Dba6)]=true;
        whitelistusers[address(0x091EDaA7C782C4F747515274F794cD307e29ee29)]=true;
    }
}