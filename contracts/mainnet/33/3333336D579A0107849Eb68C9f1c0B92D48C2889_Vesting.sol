/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

pragma solidity ^0.6.12;

/* SPDX-License-Identifier: UNLICENSED */

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


struct Schedule {
    uint32  start;
    uint32  length;
    uint256 initial;
    uint256 tokens;
}


contract Vesting is Owned, ERC20Interface {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;

    mapping(address => Schedule) public schedules;
    mapping(address => uint256) balances;
    address public lockedTokenAddress;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "VTLM";
        name = "Vesting Alien Worlds Trilium";
        decimals = 4;
    }

    /* ERC-20 functions, null most of them */

    function balanceOf(address tokenOwner) override virtual public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function totalSupply() override virtual public view returns (uint) {
        return 0;
    }

    function allowance(address tokenOwner, address spender) override virtual public view returns (uint remaining){
        return 0;
    }

    function transfer(address to, uint tokens) override virtual public returns (bool success) {
        require(false, "Use the claim function, not transfer");
    }

    function approve(address spender, uint tokens) override virtual public returns (bool success) {
        require(false, "Cannot approve spending");
    }

    function transferFrom(address from, address to, uint tokens) override virtual public returns (bool success) {
        require(false, "Use the claim function, not transferFrom");
    }


    /* My functions */

    function vestedTotal(address user) private view returns (uint256){
        uint256 time_now = block.timestamp;
        uint256 vesting_seconds = 0;
        Schedule memory s = schedules[user];

        uint256 vested_total = balances[user];

        if (s.start > 0) {
            if (time_now >= s.start) {
                vesting_seconds = time_now - s.start;

                uint256 vest_per_second_sats = s.tokens.sub(s.initial);
                vest_per_second_sats = vest_per_second_sats.div(s.length);
                
                vested_total = vesting_seconds.mul(vest_per_second_sats);
                vested_total = vested_total.add(s.initial); // amount they can withdraw
            }
            else {
                vested_total = 1;
            }
            
            if (vested_total > s.tokens) {
                vested_total = s.tokens;
            }
        }

        return vested_total;
    }

    function maxClaim(address user) public view returns (uint256) {
        uint256 vested_total = vestedTotal(user);
        Schedule memory s = schedules[user];
        uint256 max = 0;

        if (s.start > 0){
            uint256 claimed = s.tokens.sub(balances[user]);

            max = vested_total.sub(claimed);

            if (max > balances[user]){
                max = balances[user];
            }
        }

        return max;
    }

    function claim(uint256 amount) public {
        require(lockedTokenAddress != address(0x0), "Locked token contract has not been set");
        require(amount > 0, "Must claim more than 0");
        require(balances[msg.sender] > 0, "No vesting balance found");

        uint256 vested_total = vestedTotal(msg.sender);

        Schedule memory s = schedules[msg.sender];
        if (s.start > 0){
            uint256 remaining_balance = balances[msg.sender].sub(amount);

            if (vested_total < s.tokens) {
                uint min_balance = s.tokens.sub(vested_total);
                require(remaining_balance >= min_balance, "Cannot transfer this amount due to vesting locks");
            }
        }

        balances[msg.sender] = balances[msg.sender].sub(amount);
        ERC20Interface(lockedTokenAddress).transfer(msg.sender, amount);
    }

    function setSchedule(address user, uint32 start, uint32 length, uint256 initial, uint256 amount) public onlyOwner {
        schedules[user].start = start;
        schedules[user].length = length;
        schedules[user].initial = initial;
        schedules[user].tokens = amount;
    }

    function addTokens(address newOwner, uint256 amount) public onlyOwner {
        require(lockedTokenAddress != address(0x0), "Locked token contract has not been set");

        ERC20Interface tokenContract = ERC20Interface(lockedTokenAddress);

        uint256 userAllowance = tokenContract.allowance(msg.sender, address(this));
        uint256 fromBalance = tokenContract.balanceOf(msg.sender);
        require(fromBalance >= amount, "Sender has insufficient balance");
        require(userAllowance >= amount, "Please allow tokens to be spent by this contract");
        tokenContract.transferFrom(msg.sender, address(this), amount);

        balances[newOwner] = balances[newOwner].add(amount);
        
        emit Transfer(address(0x0), newOwner, amount);
    }

    function removeTokens(address owner, uint256 amount) public onlyOwner {
        ERC20Interface tokenContract = ERC20Interface(lockedTokenAddress);
        tokenContract.transfer(owner, amount);
        
        balances[owner] = balances[owner].sub(amount);
    }

    function setTokenContract(address _lockedTokenAddress) public onlyOwner {
        lockedTokenAddress = _lockedTokenAddress;
    }

    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    receive () external payable {
        revert();
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}