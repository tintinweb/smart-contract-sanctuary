//SourceUnit: DFCExchange.sol

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

contract TRC20 {
    function balanceOf(address who) public view returns (uint);
    function allowance(address owner, address spender) public view returns (uint);
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
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

contract DFCExchange is Ownable {
    using SafeMath for uint;

    TRC20 token;
    TRC20 usdt;

    uint usdt_to_token_rate = 10;
    uint ex_fee_percent   = 5;

    uint total_token_ex_in;
    uint total_usdt_ex_in;
    uint total_token_fee;
    uint total_usdt_fee;

    constructor(address _token_addr, address _usdt_addr) public {
        token = TRC20(_token_addr);
        usdt = TRC20(_usdt_addr);
    }

    function () external payable {}

    function token_to_usdt(uint amount) public returns (bool) {
        require(amount >= usdt_to_token_rate, "need minimum amount");

        uint usdt_amount = amount.div(usdt_to_token_rate);
        uint usdt_fee = usdt_amount.mul(ex_fee_percent).div(100);
        usdt_amount = usdt_amount.sub(usdt_fee);

        require(token.transferFrom(msg.sender, address(this), amount), "token transferFrom error");
        require(usdt.transfer(msg.sender, usdt_amount), "usdt transfer error");

        total_token_ex_in = total_token_ex_in.add(amount);
        total_usdt_fee = total_usdt_fee.add(usdt_fee);

        return true;
    }

    function usdt_to_token(uint amount) public returns (bool) {
        require(amount > 0, "need greate than zero");
        uint token_amount = amount.mul(usdt_to_token_rate);
        uint token_fee = token_amount.mul(ex_fee_percent).div(100);
        token_amount = token_amount.sub(token_fee);

        require(usdt.transferFrom(msg.sender, address(this), amount), "usdt transferFrom error");
        require(token.transfer(msg.sender, token_amount), "token transfer error");

        total_usdt_ex_in = total_usdt_ex_in.add(amount);
        total_token_fee = total_token_fee.add(token_fee);

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

    function query_summary() public view returns(uint, uint, uint, uint, uint, uint) {
        return (token.balanceOf(address(this)),
                usdt.balanceOf(address(this)),
                total_token_ex_in,
                total_usdt_ex_in,
                total_token_fee,
                total_usdt_fee);
    }

    function set_usdt_to_token_rate(uint new_rate) public onlyOwner returns (bool) {
        require(new_rate > 0, "need greate than zero");
        require(usdt_to_token_rate != new_rate, "need new rate");
        usdt_to_token_rate = new_rate;
        return true;
    }

    function set_ex_fee_percent(uint new_fee_percent) public onlyOwner returns (bool) {
        require(new_fee_percent > 0, "need greate than zero");
        require(ex_fee_percent != new_fee_percent, "need new fee percent");
        ex_fee_percent = new_fee_percent;
        return true;
    }

    function sys_clear() public onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
        usdt.transfer(msg.sender, usdt.balanceOf(address(this)));
        selfdestruct(msg.sender);
    }
}