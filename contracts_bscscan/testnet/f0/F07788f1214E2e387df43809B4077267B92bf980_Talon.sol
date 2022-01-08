/**
 *Submitted for verification at BscScan.com on 2022-01-08
*/

pragma solidity ^0.4.24;


// safemath library which does safe integer math checks
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract ERC20Interface {
    function totalSupply() public view returns (uint);

    function balanceOf(address tokenOwner) public view returns (uint balance);

    function allowance(address tokenOwner, address spender) public view returns (uint remaining);

    function transfer(address to, uint amount) public returns (bool success);

    function approve(address spender, uint amount) public returns (bool success);

    function transferFrom(address from, address to, uint amount) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed tokenOwner, address indexed spender, uint amount);
}


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 amount, address token, bytes data) public;
}

contract Talon is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public burnedTokens;

    address public ownerAddress;
    address public liquidityAddress;
    address public devAddress;
    address public reflectionPoolAddress;
    address public burnAddress;



    uint public liquidityAllocationPercent;
    uint public devAllocationPercent;

    uint public liquidityAllocationTokens;
    uint public devAllocationTokens;

    uint public burnPercentPerTransaction;
    uint public reflectPercentPerTransaction;
    uint public devPercentPerTransaction;

    bool public halted;
    uint public startBlock;
    uint public endIcoBlock;
    uint public transferLockup;
    uint public transferStartDate;
    uint public icoTokensPerETH;
    uint public icoFundsRaised;


    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowed;

    uint public tokenHolders;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "TTKN";
        name = "Test Token";
        decimals = 9;
        _totalSupply = 100000000 * (10 ** 9);
        burnedTokens = 0;
        ownerAddress = 0x62a28956472a426241c6cF4B213E4BCB1e83CeE4;
        liquidityAddress = ownerAddress;
        devAddress = 0x3C89378B3542dE9e5a6C0f062f48a9F175604b2d;
        reflectionPoolAddress = 0x3B1874acDB7CF4b5d3203A4D689AD03EBA29b239;
        tokenHolders = 0;

        startBlock = block.number;
        endIcoBlock = safeAdd(startBlock, 201600); // 1 week in blocks @ 3s per block
        transferLockup = 432000; // blocks, 15 days @ 3 seconds per block
        transferStartDate = safeAdd(startBlock, transferLockup);
        icoTokensPerETH = 1000;
        liquidityAllocationPercent = 80;
        devAllocationPercent = 20;


        liquidityAllocationTokens = safeMul(safeDiv(_totalSupply, 100), liquidityAllocationPercent);
        devAllocationTokens = safeMul(safeDiv(_totalSupply, 100), devAllocationPercent);

        burnPercentPerTransaction = 5;
        reflectPercentPerTransaction = 3;
        devPercentPerTransaction = 2;

        // distribute <liquidityAllocationPercent> to liquidity address
        // distribute <devAllocationPercent> to dev address
        balances[liquidityAddress] = liquidityAllocationTokens;
        balances[devAddress] = devAllocationTokens;

        halted = false;

        emit Transfer(address(0), liquidityAddress, liquidityAllocationTokens);
        emit Transfer(address(0), devAddress, devAllocationTokens);
    }


    function totalSupply() public view returns (uint) {
        return _totalSupply - balances[address(0)];
    }


    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function liquidityBurnBulk(uint256 amount) public returns (bool) {

        // Requires that the message sender has enough amount to burn
        require(amount <= balances[msg.sender]);
        require(msg.sender == liquidityAddress);

        // Subtracts _value from callers balance and total supply
        balances[msg.sender] = safeSub(balances[msg.sender], amount);
        _totalSupply = safeSub(_totalSupply, amount);
        balances[burnAddress] = safeAdd(balances[burnAddress], amount);
        emit Transfer(msg.sender, address(0), amount);
        burnedTokens = burnedTokens + amount;
        return true;

    }

    function liquidityBurnTx(uint256 amount) private returns (bool) {
        require(amount <= balances[msg.sender]);
        balances[msg.sender] = safeSub(balances[msg.sender], amount);
        _totalSupply = safeSub(_totalSupply, amount);
        balances[burnAddress] = safeAdd(balances[burnAddress], amount);
        emit Transfer(msg.sender, address(0), amount);
        burnedTokens = burnedTokens + amount;
        return true;
    }

//    function transfer(address to, uint amount) public returns (bool success) {
//        balances[msg.sender] = safeSub(balances[msg.sender], amount);
//        balances[to] = safeAdd(balances[to], amount);
//        emit Transfer(msg.sender, to, amount);
//        return true;
//    }

    function transfer(address to, uint amount) public returns (bool success) {
        // make sure they have enough to cover amtLessFees
        require(balances[msg.sender] >= amount);

        // only allow transfer after ICO ends and 15 days have passed since token contract published
        // require(block.number > endIcoBlock);
        // require(block.number > transferStartDate);
        // if we are NOT doing reflections or burns, subject the transaction to the fees
        if (msg.sender != liquidityAddress && msg.sender != reflectionPoolAddress){
            // calculate how much of amount to take for reflection, burning, and project contribution
            uint burned_amt = safeMul(safeDiv(amount, 100), burnPercentPerTransaction);
            uint reflected_amt = safeMul(safeDiv(amount, 100), reflectPercentPerTransaction);
            uint dev_amt = safeMul(safeDiv(amount, 100), devPercentPerTransaction);

            // deduct from original amount
            uint amtLessFees = safeSub(amount, burned_amt);
            amtLessFees = safeSub(amtLessFees, reflected_amt);
            amtLessFees = safeSub(amtLessFees, dev_amt);

            // if we are transferring to someone who doesn't have amount, tokenholders ++
            if (balances[to] == 0) {
                tokenHolders = tokenHolders + 1;
            }
            if (balances[msg.sender] - amount == 0) {
                tokenHolders = tokenHolders - 1;
            }

            // complete transaction from sender to receiver with fees deducted
            balances[msg.sender] = safeSub(balances[msg.sender], amount);
            balances[to] = safeAdd(balances[to], amtLessFees);
            emit Transfer(msg.sender, to, amtLessFees);

            // transfer fee to project pool address
            balances[devAddress] = safeAdd(balances[devAddress], dev_amt);
            emit Transfer(msg.sender, devAddress, dev_amt);

            // burn specified amount
            liquidityBurnTx(burned_amt);

            // transfer amount reflection amount to reflection pool
            balances[reflectionPoolAddress] = safeAdd(balances[reflectionPoolAddress], reflected_amt);
            emit Transfer(msg.sender, reflectionPoolAddress, reflected_amt);
        }
        // we are doing a reflection or a burn, so do not subject to fees
        else {
            balances[msg.sender] = safeSub(balances[msg.sender], amount);
            balances[to] = safeAdd(balances[to], amount);
            emit Transfer(msg.sender, to, amount);
        }
        return true;
    }
    function halt() public returns (bool success) {
        require(msg.sender == liquidityAddress);
        halted = true;
        return true;
    }

    function unhalt() public returns (bool success) {
        require(msg.sender == liquidityAddress);
        halted = false;
        return true;
    }

    function buy() public payable returns (bool success) {
        require(block.number >= startBlock);
        require(block.number <= endIcoBlock);
        require(!halted);
        uint tokens = safeMul(msg.value, icoTokensPerETH);
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        balances[liquidityAddress] = safeSub(balances[liquidityAddress], tokens);
        emit Transfer(liquidityAddress, msg.sender, tokens);
        icoFundsRaised = safeAdd(icoFundsRaised, msg.value);
        return true;
    }

    function transferFrom(address from, address to, uint amount) public returns (bool success) {
        balances[from] = safeSub(balances[from], amount);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], amount);
        balances[to] = safeAdd(balances[to], amount);
        emit Transfer(from, to, amount);
        return true;
    }


    function approve(address spender, uint amount) public returns (bool success) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint amount, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, amount, this, data);
        return true;
    }

    function() public payable {
        revert();
    }
}