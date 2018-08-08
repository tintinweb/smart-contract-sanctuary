contract Partner {
    function exchangeTokensFromOtherContract(address _source, address _recipient, uint256 _RequestedTokens);
}

contract Target {
    function transfer(address _to, uint _value);
}

contract PRECOE {

    string public name = "Premined Coeval";
    uint8 public decimals = 18;
    string public symbol = "PRECOE";

    address public owner;
    address public devFeesAddr = 0x36Bdc3B60dC5491fbc7d74a05709E94d5b554321;
    address tierAdmin;

    uint256 public totalSupply = 71433000000000000000000;
    uint256 public mineableTokens = totalSupply;
    uint public tierLevel = 1;
    uint256 public fiatPerEth = 3.85E25;
    uint256 public circulatingSupply = 0;
    uint maxTier = 132;
    uint256 public devFees = 0;
    uint256 fees = 10000;  // the calculation expects % * 100 (so 10% is 1000)

    bool public receiveEth = false;
    bool payFees = true;
    bool public canExchange = true;
    bool addTiers = true;
    bool public initialTiers = false;

    // Storage
    mapping (address => uint256) public balances;
    mapping (address => bool) public exchangePartners;

    // mining schedule
    mapping(uint => uint256) public scheduleTokens;
    mapping(uint => uint256) public scheduleRates;

    // events (ERC20)
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    // events (custom)
    event TokensExchanged(address indexed _owningWallet, address indexed _with, uint256 _value);

    function PRECOE() {
        owner = msg.sender;
        // premine
        balances[owner] = add(balances[owner],4500000000000000000000);
        Transfer(this, owner, 4500000000000000000000);
        circulatingSupply = add(circulatingSupply, 4500000000000000000000);
        mineableTokens = sub(mineableTokens,4500000000000000000000);
    }

    function populateTierTokens() public {
        require((msg.sender == owner) && (initialTiers == false));
        scheduleTokens[1] = 1E20;
        scheduleTokens[2] = 1E20;
        scheduleTokens[3] = 1E20;
        scheduleTokens[4] = 1E20;
        scheduleTokens[5] = 1E20;
        scheduleTokens[6] = 1E20;
        scheduleTokens[7] = 1E20;
        scheduleTokens[8] = 1E20;
        scheduleTokens[9] = 1E20;
        scheduleTokens[10] = 1E20;
        scheduleTokens[11] = 1E20;
        scheduleTokens[12] = 1E20;
        scheduleTokens[13] = 1E20;
        scheduleTokens[14] = 1E20;
        scheduleTokens[15] = 1E20;
        scheduleTokens[16] = 1E20;
        scheduleTokens[17] = 1E20;
        scheduleTokens[18] = 1E20;
        scheduleTokens[19] = 1E20;
        scheduleTokens[20] = 1E20;
        scheduleTokens[21] = 1E20;
        scheduleTokens[22] = 1E20;
        scheduleTokens[23] = 1E20;
        scheduleTokens[24] = 1E20;
        scheduleTokens[25] = 1E20;
        scheduleTokens[26] = 1E20;
        scheduleTokens[27] = 1E20;
        scheduleTokens[28] = 1E20;
        scheduleTokens[29] = 1E20;
        scheduleTokens[30] = 3E20;
        scheduleTokens[31] = 3E20;
        scheduleTokens[32] = 3E20;
        scheduleTokens[33] = 3E20;
        scheduleTokens[34] = 3E20;
        scheduleTokens[35] = 3E20;
        scheduleTokens[36] = 3E20;
        scheduleTokens[37] = 3E20;
        scheduleTokens[38] = 3E20;
        scheduleTokens[39] = 3E20;
        scheduleTokens[40] = 3E20;
    }

    function populateTierRates() public {
        //require((msg.sender == owner) && (initialTiers == false));
        //require(msg.sender == owner);
        scheduleRates[1] = 3.85E23;
        scheduleRates[2] = 6.1E23;
        scheduleRates[3] = 4.15E23;
        scheduleRates[4] = 5.92E23;
        scheduleRates[5] = 9.47E23;
        scheduleRates[6] = 1.1E24;
        scheduleRates[7] = 1.123E24;
        scheduleRates[8] = 1.15E24;
        scheduleRates[9] = 1.135E24;
        scheduleRates[10] = 1.013E24;
        scheduleRates[11] = 8.48E23;
        scheduleRates[12] = 8.17E23;
        scheduleRates[13] = 7.3E23;
        scheduleRates[14] = 9.8E23;
        scheduleRates[15] = 1.07E23;
        scheduleRates[16] = 1.45E24;
        scheduleRates[17] = 1.242E24;
        scheduleRates[18] = 1.383E24;
        scheduleRates[19] = 1.442E24;
        scheduleRates[20] = 4.8E22;
        scheduleRates[21] = 1.358E24;
        scheduleRates[22] = 1.25E23;
        scheduleRates[23] = 9.94E24;
        scheduleRates[24] = 1.14E24;
        scheduleRates[25] = 1.253E24;
        scheduleRates[26] = 1.29E24;
        scheduleRates[27] = 1.126E24;
        scheduleRates[28] = 1.173E24;
        scheduleRates[29] = 1.074E24;
        scheduleRates[30] = 1.127E24;
        scheduleRates[31] = 1.223E24;
        scheduleRates[32] = 1.145E24;
        scheduleRates[33] = 1.199E24;
        scheduleRates[34] = 1.319E24;
        scheduleRates[35] = 1.312E24;
        scheduleRates[36] = 1.287E24;
        scheduleRates[37] = 1.175E24;
        scheduleRates[38] = 1.15E23;
        scheduleRates[39] = 1.146E24;
        scheduleRates[40] = 1.098E24;
        initialTiers = true;
    }

    function () payable public {
        require((msg.value > 0) && (receiveEth));

        if(payFees) {
            devFees = add(devFees, ((msg.value * fees) / 10000));
        }
        allocateTokens(convertEthToCents(msg.value),0);
    }

    function convertEthToCents(uint256 _incoming) internal returns (uint256) {
        return mul(_incoming, fiatPerEth);
    }

    function allocateTokens(uint256 _submitted, uint256 _tokenCount) internal {
        uint256 _tokensAfforded = 0;

        if(tierLevel <= maxTier) {
            _tokensAfforded = div(_submitted, scheduleRates[tierLevel]);
        }

        if(_tokensAfforded >= scheduleTokens[tierLevel]) {
            _submitted = sub(_submitted, mul(scheduleTokens[tierLevel], scheduleRates[tierLevel]));
            _tokenCount = add(_tokenCount, scheduleTokens[tierLevel]);
            circulatingSupply = add(circulatingSupply, _tokensAfforded);
            mineableTokens = sub(mineableTokens, _tokensAfforded);
            scheduleTokens[tierLevel] = 0;
            tierLevel++;
            allocateTokens(_submitted, _tokenCount);
        }
        else if((scheduleTokens[tierLevel] >= _tokensAfforded) && (_tokensAfforded > 0)) {
            scheduleTokens[tierLevel] = sub(scheduleTokens[tierLevel], _tokensAfforded);
            _tokenCount = add(_tokenCount, _tokensAfforded);
            circulatingSupply = add(circulatingSupply, _tokensAfforded);
            mineableTokens = sub(mineableTokens, _tokensAfforded);
            _submitted = sub(_submitted, mul(_tokensAfforded, scheduleRates[tierLevel]));
            allocateTokens(_submitted, _tokenCount);
        }
        else {
            balances[msg.sender] = add(balances[msg.sender], _tokenCount);
            Transfer(this, msg.sender, _tokenCount);
        }
    }

    function transfer(address _to, uint _value) public {
        require(balances[msg.sender] >= _value);

        if(_to == address(this)) {
            // WARNING: if you transfer tokens back to the contract you will lose them
            // use the exchange function to exchange for tokens with approved partner contracts
            balances[msg.sender] = sub(balances[msg.sender], _value);
            Transfer(msg.sender, _to, _value);
        }
        else {
            uint codeLength;

            assembly {
                codeLength := extcodesize(_to)
            }

            if(codeLength != 0) {
                if(canExchange == true) {
                    if(exchangePartners[_to]) {
                        // WARNING: exchanging COE into MNY costs more Gas than a normal transfer as we interact directly
                        // with the MNY contract - suggest doubling the recommended gas limit
                        exchange(_to, _value);
                    }
                    else {
                        // WARNING: if you transfer to a contract that cannot handle incoming tokens you may lose them
                        balances[msg.sender] = sub(balances[msg.sender], _value);
                        balances[_to] = add(balances[_to], _value);
                        Transfer(msg.sender, _to, _value);
                    }
                }
            }
            else {
                balances[msg.sender] = sub(balances[msg.sender], _value);
                balances[_to] = add(balances[_to], _value);
                Transfer(msg.sender, _to, _value);
            }
        }
    }

    function exchange(address _partner, uint256 _amount) internal {
        require(exchangePartners[_partner]);
        requestTokensFromOtherContract(_partner, this, msg.sender, _amount);
        balances[msg.sender] = sub(balanceOf(msg.sender), _amount);
        circulatingSupply = sub(circulatingSupply, _amount);
        Transfer(msg.sender, this, _amount);
        TokensExchanged(msg.sender, _partner, _amount);
    }

    function requestTokensFromOtherContract(address _targetContract, address _sourceContract, address _recipient, uint256 _value) internal returns (bool){
        Partner p = Partner(_targetContract);
        p.exchangeTokensFromOtherContract(_sourceContract, _recipient, _value);
        return true;
    }

    function balanceOf(address _receiver) public constant returns (uint256) {
        return balances[_receiver];
    }

    function balanceInTier() public constant returns (uint256) {
        return scheduleTokens[tierLevel];
    }

    function balanceInSpecificTier(uint256 _tier) public constant returns (uint256) {
        return scheduleTokens[_tier];
    }

    function rateOfSpecificTier(uint256 _tier) public constant returns (uint256) {
        return scheduleRates[_tier];
    }

    function setFiatPerEthRate(uint256 _newRate) public {
        require(msg.sender == owner);
        fiatPerEth = _newRate;
    }

    function addExchangePartnerTargetAddress(address _partner) public {
        require(msg.sender == owner);
        exchangePartners[_partner] = true;
    }

    function canContractExchange(address _contract) public constant returns (bool) {
        return exchangePartners[_contract];
    }

    function removeExchangePartnerTargetAddress(address _partner) public {
        require(msg.sender == owner);
        exchangePartners[_partner] = false;
    }

    function withdrawDevFees() public {
        require(payFees);
        devFeesAddr.transfer(devFees);
        devFees = 0;
    }

    function changeDevFees(address _devFees) public {
        require(msg.sender == owner);
        devFeesAddr = _devFees;
    }

    function payFeesToggle() public {
        require(msg.sender == owner);
        if(payFees) {
            payFees = false;
        }
        else {
            payFees = true;
        }
    }

    function safeWithdrawal(address _receiver, uint256 _value) public {
        require(msg.sender == owner);
        withdrawDevFees();
        require(_value <= this.balance);
        _receiver.transfer(_value);
    }

    // enables fee update - must be between 0 and 100 (%)
    function updateFeeAmount(uint _newFee) public {
        require(msg.sender == owner);
        require((_newFee >= 0) && (_newFee <= 100));
        fees = _newFee * 100;
    }

    function handleTokensFromOtherContracts(address _contract, address _recipient, uint256 _tokens) public {
        require(msg.sender == owner);
        Target t;
        t = Target(_contract);
        t.transfer(_recipient, _tokens);
    }

    function changeOwner(address _recipient) public {
        require(msg.sender == owner);
        owner = _recipient;
    }

    function changeTierAdmin(address _tierAdmin) public {
        require((msg.sender == owner) || (msg.sender == tierAdmin));
        tierAdmin = _tierAdmin;
    }

    function toggleReceiveEth() public {
        require(msg.sender == owner);
        if(receiveEth == true) {
            receiveEth = false;
        }
        else receiveEth = true;
    }

    function toggleTokenExchange() public {
        require(msg.sender == owner);
        if(canExchange == true) {
            canExchange = false;
        }
        else canExchange = true;
    }

    function addTierRateAndTokens(uint256 _level, uint256 _tokens, uint256 _rate) public {
        require(((msg.sender == owner) || (msg.sender == tierAdmin)) && (addTiers == true));
        scheduleTokens[_level] = _tokens;
        scheduleRates[_level] = _rate;
    }

    // not really needed as we fix the max tiers on contract creation but just for completeness&#39; sake we&#39;ll call this
    // when all tiers have been added to the contract (not possible to deploy with all of them)
    function closeTierAddition() public {
        require(msg.sender == owner);
        addTiers = false;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }
}