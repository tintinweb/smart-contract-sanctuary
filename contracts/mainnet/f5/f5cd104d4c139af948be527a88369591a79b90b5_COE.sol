contract Partner {
    function exchangeTokensFromOtherContract(address _source, address _recipient, uint256 _RequestedTokens);
}

contract COE {

    string public name = "CoEval";
    uint8 public decimals = 18;
    string public symbol = "COE";


    address public _owner;
    address public _dev = 0xC96CfB18C39DC02FBa229B6EA698b1AD5576DF4c;
    address _pMine = 0x76D05E325973D7693Bb854ED258431aC7DBBeDc3;
    address public _devFeesAddr;
    uint256 public _tokePerEth = 177000000000000000;
    bool public _coldStorage = true;
    bool public _receiveEth = true;

    // fees vars - added for future extensibility purposes only
    bool _feesEnabled = false;
    bool _payFees = false;
    uint256 _fees;  // the calculation expects % * 100 (so 10% is 1000)
    uint256 _lifeVal = 0;
    uint256 _feeLimit = 0;
    uint256 _devFees = 0;

    uint256 public _totalSupply = 100000 * 1 ether;
    uint256 public _frozenTokens = 0;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Exchanged(address indexed _from, address indexed _to, uint _value);
    // Storage
    mapping (address => uint256) public balances;

    // list of contract addresses that can request tokens
    // use add/remove functions to update
    mapping (address => bool) public exchangePartners;

    // permitted exch partners and associated token rates
    // rate is X target tokens per Y incoming so newTokens = Tokens/Rate
    mapping (address => uint256) public exchangeRates;

    function MNY() {
        _owner = msg.sender;
        preMine();
    }

    function preMine() internal {
        balances[_dev] = 32664750000000000000000;
        Transfer(this, _pMine, 32664750000000000000000);
        _totalSupply = sub(_totalSupply, 32664750000000000000000);
    }

    function transfer(address _to, uint _value, bytes _data) public {
        // sender must have enough tokens to transfer
        require(balances[msg.sender] >= _value);

        if(_to == address(this)) {
            // WARNING: if you transfer tokens back to the contract you will lose them
            // use the exchange function to exchange with approved partner contracts
            _totalSupply = add(_totalSupply, _value);
            balances[msg.sender] = sub(balanceOf(msg.sender), _value);
            Transfer(msg.sender, _to, _value);
        }
        else {
            uint codeLength;

            assembly {
                codeLength := extcodesize(_to)
            }

            // we decided that we don&#39;t want to lose tokens into OTHER contracts that aren&#39;t exchange partners
            require(codeLength == 0);

            balances[msg.sender] = sub(balanceOf(msg.sender), _value);
            balances[_to] = add(balances[_to], _value);

            Transfer(msg.sender, _to, _value);
        }
    }

    function transfer(address _to, uint _value) public {
        /// sender must have enough tokens to transfer
        require(balances[msg.sender] >= _value);

        if(_to == address(this)) {
            // WARNING: if you transfer tokens back to the contract you will lose them
            // use the exchange function to exchange for tokens with approved partner contracts
            _totalSupply = add(_totalSupply, _value);
            balances[msg.sender] = sub(balanceOf(msg.sender), _value);
            Transfer(msg.sender, _to, _value);
        }
        else {
            uint codeLength;

            assembly {
                codeLength := extcodesize(_to)
            }

            // we decided that we don&#39;t want to lose tokens into OTHER contracts that aren&#39;t exchange partners
            require(codeLength == 0);

            balances[msg.sender] = sub(balanceOf(msg.sender), _value);
            balances[_to] = add(balances[_to], _value);

            Transfer(msg.sender, _to, _value);
        }
    }

    function exchange(address _partner, uint _amount) public {
        require(balances[msg.sender] >= _amount);

        // intended partner addy must be a contract
        uint codeLength;
        assembly {
        // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_partner)
        }
        require(codeLength > 0);

        require(exchangePartners[_partner]);
        require(requestTokensFromOtherContract(_partner, this, msg.sender, _amount));

        if(_coldStorage) {
            // put the tokens from this contract into cold storage if we need to
            // (NB: if these are in reality to be burnt, we just never defrost them)
            _frozenTokens = add(_frozenTokens, _amount);
        }
        else {
            // or return them to the available supply if not
            _totalSupply = add(_totalSupply, _amount);
        }

        balances[msg.sender] = sub(balanceOf(msg.sender), _amount);
        Exchanged(msg.sender, _partner, _amount);
        Transfer(msg.sender, this, _amount);
    }

    // fallback to receive ETH into contract and send tokens back based on current exchange rate
    function () payable public {
        require((msg.value > 0) && (_receiveEth));
        uint256 _tokens = mul(div(msg.value, 1 ether),_tokePerEth);
        require(_totalSupply >= _tokens);//, "Insufficient tokens available at current exchange rate");
        _totalSupply = sub(_totalSupply, _tokens);
        balances[msg.sender] = add(balances[msg.sender], _tokens);
        Transfer(this, msg.sender, _tokens);
        _lifeVal = add(_lifeVal, msg.value);

        if(_feesEnabled) {
            if(!_payFees) {
                // then check whether fees are due and set _payFees accordingly
                if(_lifeVal >= _feeLimit) _payFees = true;
            }

            if(_payFees) {
                _devFees = add(_devFees, ((msg.value * _fees) / 10000));
            }
        }
    }

    function requestTokensFromOtherContract(address _targetContract, address _sourceContract, address _recipient, uint256 _value) internal returns (bool){
        Partner p = Partner(_targetContract);
        p.exchangeTokensFromOtherContract(_sourceContract, _recipient, _value);
        return true;
    }

    function exchangeTokensFromOtherContract(address _source, address _recipient, uint256 _RequestedTokens) {
        require(exchangeRates[msg.sender] > 0);

        uint256 _exchanged = mul(_RequestedTokens, exchangeRates[_source]);

        require(_exchanged <= _totalSupply);

        balances[_recipient] = add(balances[_recipient],_exchanged);
        _totalSupply = sub(_totalSupply, _exchanged);
        Exchanged(_source, _recipient, _exchanged);
        Transfer(this, _recipient, _exchanged);
    }

    function changePayRate(uint256 _newRate) public {
        require(((msg.sender == _owner) || (msg.sender == _dev)) && (_newRate >= 0));
        _tokePerEth = _newRate;
    }

    function safeWithdrawal(address _receiver, uint256 _value) public {
        require((msg.sender == _owner));
        uint256 valueAsEth = mul(_value,1 ether);

        // if fees are enabled send the dev fees
        if(_feesEnabled) {
            if(_payFees) _devFeesAddr.transfer(_devFees);
            _devFees = 0;
        }

        // check balance before transferring
        require(valueAsEth <= this.balance);
        _receiver.transfer(valueAsEth);
    }

    function balanceOf(address _receiver) public constant returns (uint balance) {
        return balances[_receiver];
    }

    function changeOwner(address _receiver) public {
        require(msg.sender == _owner);
        _dev = _receiver;
    }

    function changeDev(address _receiver) public {
        require(msg.sender == _dev);
        _owner = _receiver;
    }

    function changeDevFeesAddr(address _receiver) public {
        require(msg.sender == _dev);
        _devFeesAddr = _receiver;
    }

    function toggleReceiveEth() public {
        require((msg.sender == _dev) || (msg.sender == _owner));
        if(!_receiveEth) {
            _receiveEth = true;
        }
        else {
            _receiveEth = false;
        }
    }

    function toggleFreezeTokensFlag() public {
        require((msg.sender == _dev) || (msg.sender == _owner));
        if(!_coldStorage) {
            _coldStorage = true;
        }
        else {
            _coldStorage = false;
        }
    }

    function defrostFrozenTokens() public {
        require((msg.sender == _dev) || (msg.sender == _owner));
        _totalSupply = add(_totalSupply, _frozenTokens);
        _frozenTokens = 0;
    }

    function addExchangePartnerAddressAndRate(address _partner, uint256 _rate) {
        require((msg.sender == _dev) || (msg.sender == _owner));
        uint codeLength;
        assembly {
            codeLength := extcodesize(_partner)
        }
        require(codeLength > 0);
        exchangeRates[_partner] = _rate;
    }

    function addExchangePartnerTargetAddress(address _partner) public {
        require((msg.sender == _dev) || (msg.sender == _owner));
        exchangePartners[_partner] = true;
    }

    function removeExchangePartnerTargetAddress(address _partner) public {
        require((msg.sender == _dev) || (msg.sender == _owner));
        exchangePartners[_partner] = false;
    }

    function canExchange(address _targetContract) public constant returns (bool) {
        return exchangePartners[_targetContract];
    }

    function contractExchangeRate(address _exchangingContract) public constant returns (uint256) {
        return exchangeRates[_exchangingContract];
    }

    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }

    // just in case fallback
    function updateTokenBalance(uint256 newBalance) public {
        require((msg.sender == _dev) || (msg.sender == _owner));
        _totalSupply = newBalance;
    }

    function getBalance() public constant returns (uint256) {
        return this.balance;
    }

    function getLifeVal() public returns (uint256) {
        require((msg.sender == _owner) || (msg.sender == _dev));
        return _lifeVal;
    }

    function payFeesToggle() {
        require((msg.sender == _dev) || (msg.sender == _owner));
        if(_payFees) {
            _payFees = false;
        }
        else {
            _payFees = true;
        }
    }

    // enables fee update - must be between 0 and 100 (%)
    function updateFeeAmount(uint _newFee) public {
        require((msg.sender == _dev) || (msg.sender == _owner));
        require((_newFee >= 0) && (_newFee <= 100));
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