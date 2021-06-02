/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <=0.8.4;

/* taking ideas from FirstBlood token */
contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
    }
}

abstract contract Token {
    uint256 public totalSupply;

    function balanceOf(address _owner) public virtual returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        public
        virtual
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public virtual returns (bool success);

    function approve(address _spender, uint256 _value)
        public
        virtual
        returns (bool success);

    function allowance(address _owner, address _spender)
        public
        virtual
        returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

/*  ERC 20 token */
contract StandardToken is Token {
    function transfer(address _to, uint256 _value)
        public
        override
        returns (bool success)
    {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool success) {
        if (
            balances[_from] >= _value &&
            allowed[_from][msg.sender] >= _value &&
            _value > 0
        ) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner)
        public
        view
        override
        returns (uint256 balance)
    {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value)
        public
        override
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        override
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
}

contract FUT is StandardToken, SafeMath {
    // metadata
    string public constant name = "FuttBucks";
    string public constant symbol = "FUT";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    // contracts
    address public owner; // contract owner to mint tokens

    // supply parameters
    uint256 public constant futFund = 500 * (10**6) * 10**decimals; // 500m FU T reserved for community growth
    uint256 public constant tokenCreationCap = 1500 * (10**6) * 10**decimals;

    // events
    event LogRefund(address indexed _to, uint256 _value);
    event CreateFUT(address indexed _to, uint256 _value);

    // constructor
    constructor() {
        owner = msg.sender;
        totalSupply = futFund;
        balances[owner] = futFund; // Deposit FUT share
        emit CreateFUT(owner, futFund); // logs FUT fund
    }

    /// @dev Creates new fut tokens.
    function mintTokens(uint tokens) external payable {
        if (msg.sender != owner) revert();
        uint256 checkedSupply = safeAdd(totalSupply, tokens);// check that we're not over totals
        // return money if something goes wrong
        if (tokenCreationCap < checkedSupply) revert(); // odd fractions won't be found
        totalSupply = checkedSupply;
        balances[msg.sender] += tokens; // safeAdd not needed; bad semantics to use here
        CreateFUT(msg.sender, tokens); // logs token creation
    }

}