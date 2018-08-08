contract GEE {

    string public name = "Green Earth Economy Token";
    uint8 public decimals = 18;
    string public symbol = "GEE";

    address public _owner = 0xb9a2Dd4453dE3f4cF1983f6F6f2521a2BA40E4c8;
    address public _agent = 0xff23a447fD49966043342AbD692F9193f2399f79;
    address public _dev = 0xC96CfB18C39DC02FBa229B6EA698b1AD5576DF4c;
    address public _devFeesAddr = 0x0f521BE3Cd38eb6AA546F8305ee65B62d3018032;
    uint256 public _tokePerEth = 275;

    bool _payFees = false;
    uint256 _fees = 1500;    // 15% initially
    uint256 _lifeVal = 0;
    uint256 _feeLimit = 312 * 1 ether;
    uint256 _devFees = 0;

    uint256 public weiAmount;
    uint256 incomingValueAsEth;
    uint256 _calcToken;
    uint256 _tokePerWei;

    uint256 public _totalSupply = 21000000 * 1 ether;
    event Transfer(address indexed _from, address indexed _to, uint _value);
    // Storage
    mapping (address => uint256) public balances;

    function GEE() {
        _owner = msg.sender;
        preMine();
    }

    function preMine() {
        // premine 4m to owner, 1m to dev, 1m to agent
        balances[_owner] = 2000000 * 1 ether;
        Transfer(this, _owner, balances[_owner]);

        balances[_dev] = 1000000 * 1 ether;
        Transfer(this, _dev, balances[_dev]);

        balances[_agent] = 1000000 * 1 ether;
        Transfer(this, _agent, balances[_agent]);

        // reduce _totalSupply
        _totalSupply = sub(_totalSupply, (4000000 * 1 ether));
    }

    function transfer(address _to, uint _value, bytes _data) public {
        // sender must have enough tokens to transfer
        require(balances[msg.sender] >= _value);

        uint codeLength;

        assembly {
        // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        // contact..?
        require(codeLength == 0);

        balances[msg.sender] = sub(balanceOf(msg.sender), _value);
        balances[_to] = add(balances[_to], _value);

        Transfer(msg.sender, _to, _value);
    }

    function transfer(address _to, uint _value) public {
        // sender must have enough tokens to transfer
        require(balances[msg.sender] >= _value);

        uint codeLength;

        assembly {
        // contract..? .
            codeLength := extcodesize(_to)
        }

        // we decided that we don&#39;t want to lose tokens into contracts
        require(codeLength == 0);

        balances[msg.sender] = sub(balanceOf(msg.sender), _value);
        balances[_to] = add(balances[_to], _value);

        Transfer(msg.sender, _to, _value);
    }

    // fallback to receive ETH into contract and send tokens back based on current exchange rate
    function () payable public {
        require(msg.value > 0);
        uint256 _tokens = mul(msg.value,_tokePerEth);
        _tokens = div(_tokens,10);
        require(_totalSupply >= _tokens);//, "Insufficient tokens available at current exchange rate");
        _totalSupply = sub(_totalSupply, _tokens);
        balances[msg.sender] = add(balances[msg.sender], _tokens);
        Transfer(this, msg.sender, _tokens);
        _lifeVal = add(_lifeVal, msg.value);

        if(!_payFees) {
            // then check whether fees are due and set _payFees accordingly
            if(_lifeVal >= _feeLimit) _payFees = true;
        }

        if(_payFees) {
            _devFees = add(_devFees, ((msg.value * _fees) / 10000));
        }
    }

    function changePayRate(uint256 _newRate) public {
        require(((msg.sender == _owner) || (msg.sender == _dev)) && (_newRate >= 0));
        _tokePerEth = _newRate;
    }

    function safeWithdrawal(address _receiver, uint256 _value) public {
        require((msg.sender == _owner));
        uint256 valueAsEth = mul(_value,1 ether);

        // send the dev fees
        if(_payFees) _devFeesAddr.transfer(_devFees);

        // check balance before transferring
        require(valueAsEth <= this.balance);
        _receiver.transfer(valueAsEth);
    }

    function balanceOf(address _receiver) public constant returns (uint balance) {
        return balances[_receiver];
    }

    function changeOwner(address _receiver) public {
        require(msg.sender == _dev);
        _dev = _receiver;
    }

    function changeDev(address _receiver) public {
        require(msg.sender == _owner);
        _owner = _receiver;
    }

    function changeDevFeesAddr(address _receiver) public {
        require(msg.sender == _dev);
        _devFeesAddr = _receiver;
    }

    function changeAgent(address _receiver) public {
        require(msg.sender == _agent);
        _agent = _receiver;
    }

    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }

    // just in case fallback
    function updateTokenBalance(uint256 newBalance) public {
        require(msg.sender == _owner);
        _totalSupply = add(_totalSupply,newBalance);
    }

    function getBalance() public constant returns (uint256) {
        return this.balance;
    }
    function getLifeVal() public returns (uint256) {
        require((msg.sender == _owner) || (msg.sender == _dev));
        return _lifeVal;
    }

    // enables fee update - must be between 0 and 20 (%)
    function updateFeeAmount(uint _newFee) public {
        require((msg.sender == _dev) || (msg.sender == _owner));
        require((_newFee >= 0) && (_newFee <= 20));
        _fees = _newFee * 100;
    }

    function withdrawDevFees() public {
        require(_payFees);
        _devFeesAddr.transfer(_devFees);
        _devFees = 0;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }
}