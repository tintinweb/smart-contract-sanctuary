contract META {

    string public name = "Dunaton Metacurrency";
    uint8 public decimals = 18;
    string public symbol = "META";

    address public _owner;
    address public dev = 0xC96CfB18C39DC02FBa229B6EA698b1AD5576DF4c;
    uint256 _tokePerEth = 156;
    uint256 weIn;

    uint public _totalSupply = 21000000;  // 21m, 18dp - one token is 1000000000000000000 therefore
    event Transfer(address indexed from, address indexed to, uint value, bytes data);

    // Storage
    mapping (address => uint256) balances;

    function META() {
        _owner = msg.sender;
        balances[_owner] = 5800000;    // premine 5.8m tokens to _owner
        _totalSupply = sub(_totalSupply,balances[_owner]);
    }

    function transfer(address _to, uint _value, bytes _data) public {
        // sender must have enough tokens to transfer
        require(balances[msg.sender] >= _value);

        uint codeLength;

        assembly {
        // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = sub(balanceOf(msg.sender), _value);
        balances[_to] = add(balances[_to], _value);
        
        Transfer(msg.sender, _to, _value, _data);
    }

    function transfer(address _to, uint _value) public {
        // sender must have enough tokens to transfer
        require(balances[msg.sender] >= _value);

        uint codeLength;
        bytes memory empty;

        assembly {
        // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = sub(balanceOf(msg.sender), _value);
        balances[_to] = add(balances[_to], _value);

        Transfer(msg.sender, _to, _value, empty);
    }

    // fallback to receive ETH into contract and send tokens back based on current exchange rate
    function () payable public {
        bytes memory empty;
        require(msg.value > 0);

        uint incomingValueAsEth = msg.value / 1 ether;

        weIn = incomingValueAsEth;

        uint256 _calcToken = (incomingValueAsEth * _tokePerEth); // value of payment in tokens

        require(_totalSupply >= _calcToken);
        _totalSupply = sub(_totalSupply, _calcToken);

        balances[msg.sender] = add(balances[msg.sender], _calcToken);

        Transfer(this, msg.sender, _calcToken, empty);
    }

    function changePayRate(uint256 _newRate) public {
        require((msg.sender == _owner) && (_newRate >= 0));
        _tokePerEth = _newRate;
    }

    function safeWithdrawal(address _receiver, uint256 _value) public {
        require((msg.sender == _owner));
        uint256 valueAsEth = _value * 1 ether;
        require((valueAsEth * 1 ether) < this.balance);
        _receiver.send(valueAsEth);
    }

    function balanceOf(address _receiver) public constant returns (uint balance) {
        return balances[_receiver];
    }

    function changeOwner(address _receiver) public {
        require(msg.sender == _owner);
        _owner = _receiver;
    }

    function tokens() public constant returns (uint) {
        return _totalSupply;
    }

    function updateTokenBalance(uint256 newBalance) public {
        require(msg.sender == _owner);
        _totalSupply = add(_totalSupply,newBalance);
    }

    function mul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }

    function assert(bool assertion) internal {
        if (!assertion) {
            revert();
        }
    }
}