/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

pragma solidity 0.6.6;

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

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

contract ShellyToken is ERC20Interface, SafeMath {
        string public symbol;
        string public name;
        uint8 public decimal;
        uint public _totalSupply;

        mapping(address => uint) balances;
        mapping(address => mapping(address => uint)) allowed;

        constructor () public {
            symbol = "SLT";
            name = "ShellyToken";
            decimal = 10;
            _totalSupply = 100;
            balances[0xE4258F24dB0A75E1944564b4d0D3A412B4bdDB05] = _totalSupply;
            emit Transfer(address(0), 0xE4258F24dB0A75E1944564b4d0D3A412B4bdDB05, _totalSupply);
        }

        function totalSupply () virtual public view override returns (uint) {
            return _totalSupply;
        }

        function balanceOf(address tokenOwner) virtual public view override returns (uint balance) {
            return balances[tokenOwner];
        }

        function allowance(address tokenOwner, address spender) virtual public view override returns (uint remaining) {
            return allowed[tokenOwner][spender];
        }

        function transfer(address to, uint tokens) virtual public override returns (bool success) {
            balances[msg.sender] = safeSub (balances[msg.sender], tokens);
            balances[to] = safeAdd (balances[to], tokens);
            emit Transfer(msg.sender, to, tokens);
            return true;
        }

       function approve(address spender, uint tokens) virtual public override returns (bool success) {
           if (_totalSupply < tokens) {
               return false;
           } else {
               allowed[msg.sender][spender] = tokens;
               emit Approval(msg.sender, spender, tokens);
               return true;
           }
       }

       function transferFrom(address from, address to, uint tokens) virtual public override returns (bool success) {
           balances[from] = safeSub(balances[from], tokens);
           balances[to] = safeAdd(balances[to], tokens);
           allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
           emit Transfer(from, to, tokens);
           return true;
       }


}