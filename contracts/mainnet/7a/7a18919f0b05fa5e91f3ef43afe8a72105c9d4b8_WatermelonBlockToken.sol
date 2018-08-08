/*
 *  The WatermelonBlock Token contract complies with the ERC20 standard (see https://github.com/ethereum/EIPs/issues/20).
 *  Author: Justas Kregzde
 */
 
pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}

contract WatermelonBlockToken {
    using SafeMath for uint;

    // Public variables of the token
    string constant public standard = "ERC20";
    string constant public name = "WatermelonBlock tokens";
    string constant public symbol = "WMB";
    uint8 constant public decimals = 6;

    uint _totalSupply = 400000000e6; // Total supply of 400 million WatermelonBlock tokens
    uint constant public tokensICO = 240000000e6; // 60% token sale
    uint constant public teamReserve = 80000000e6; // 20% team
    uint constant public seedInvestorsReserve = 40000000e6; // 10% seed investors
    uint constant public emergencyReserve = 40000000e6; // 10% emergency

    address public icoAddr;
    address public teamAddr;
    address public emergencyAddr;

    uint constant public lockStartTime = 1527811200; // 2018 June 1, Friday, 00:00:00
    bool icoEnded;

    struct Lockup
    {
        uint lockupTime;
        uint lockupAmount;
    }
    Lockup lockup;
    mapping(address=>Lockup) lockupParticipants;

    uint[] lockupTeamSum = [80000000e6,70000000e6,60000000e6,50000000e6,40000000e6,30000000e6,20000000e6,10000000e6];
    uint[] lockupTeamDate = [1535760000,1543622400,1551398400,1559347200,1567296000,1575158400,1583020800,1590969600];

    // Array with all balances
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

    // Public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed _owner, address indexed spender, uint value);
    event Burned(uint amount);

    // What is the balance of a particular account?
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    // Get the total token supply
    function totalSupply() constant returns (uint totalSupply) {
        totalSupply = _totalSupply;
    }

    // Initializes contract
    function WatermelonBlockToken(address _icoAddr, address _teamAddr, address _emergencyAddr) {
        icoAddr = _icoAddr;
        teamAddr = _teamAddr;
        emergencyAddr = _emergencyAddr;

        balances[icoAddr] = tokensICO;
        balances[teamAddr] = teamReserve;

        // seed investors
        address investor_1 = 0xF735e4a0A446ed52332AB891C46661cA4d9FD7b9;
        balances[investor_1] = 20000000e6;
        var lockupTime = lockStartTime.add(1 years);
        lockup = Lockup({lockupTime:lockupTime,lockupAmount:balances[investor_1]});
        lockupParticipants[investor_1] = lockup;

        address investor_2 = 0x425207D7833737b62E76785A3Ab3f9dEce3953F5;
        balances[investor_2] = 8000000e6;
        lockup = Lockup({lockupTime:lockupTime,lockupAmount:balances[investor_2]});
        lockupParticipants[investor_2] = lockup;

        var leftover = seedInvestorsReserve.sub(balances[investor_1]).sub(balances[investor_2]);
        balances[emergencyAddr] = emergencyReserve.add(leftover);
    }

    // Send some of your tokens to a given address
    function transfer(address _to, uint _value) returns(bool) {
        if (lockupParticipants[msg.sender].lockupAmount > 0) {
            if (now < lockupParticipants[msg.sender].lockupTime) {
                require(balances[msg.sender].sub(_value) >= lockupParticipants[msg.sender].lockupAmount);
            }
        }
        if (msg.sender == teamAddr) {
            for (uint i = 0; i < lockupTeamDate.length; i++) {
                if (now < lockupTeamDate[i])
                    require(balances[msg.sender].sub(_value) >= lockupTeamSum[i]);
            }
        }
        balances[msg.sender] = balances[msg.sender].sub(_value); // Subtract from the sender
        balances[_to] = balances[_to].add(_value); // Add the same to the recipient
        Transfer(msg.sender, _to, _value); // Notify anyone listening that this transfer took place
        return true;
    }
	
    // A contract or person attempts to get the tokens of somebody else.
    // This is only allowed if the token holder approved.
    function transferFrom(address _from, address _to, uint _value) returns(bool) {
        if (lockupParticipants[_from].lockupAmount > 0) {
            if (now < lockupParticipants[_from].lockupTime) {
                require(balances[_from].sub(_value) >= lockupParticipants[_from].lockupAmount);
            }
        }
        if (_from == teamAddr) {
            for (uint i = 0; i < lockupTeamDate.length; i++) {
                if (now < lockupTeamDate[i])
                    require(balances[_from].sub(_value) >= lockupTeamSum[i]);
            }
        }
        var _allowed = allowed[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value); // Subtract from the sender
        balances[_to] = balances[_to].add(_value); // Add the same to the recipient
        allowed[_from][msg.sender] = _allowed.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
	
    // Approve the passed address to spend the specified amount of tokens
    // on behalf of msg.sender.
    function approve(address _spender, uint _value) returns (bool) {
        //https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}