contract Partner {
    function exchangeTokensFromOtherContract(address _source, address _recipient, uint256 _RequestedTokens);
}

contract Target {
    function transfer(address _to, uint _value);
}

contract COE {

    string public name = "Coeval by Monkey Capital";
    uint8 public decimals = 18;
    string public symbol = "COE";

    address public owner;
    address public devFeesAddr = 0xF772464393Ac87a1b7C628bF79090e014d931A23;
    address tierAdmin;

    uint256 public totalSupply = 100000000000000000000000;
    uint tierLevel = 1;
    uint fiatPerEth = 385000000000000000000000;
    uint256 circulatingSupply = 0;
    uint maxTier = 132;
    uint256 public devFees = 0;
    uint256 fees = 10000;  // the calculation expects % * 100 (so 10% is 1000)

    // flags
    bool public receiveEth = false;
    bool payFees = true;
    bool distributionDone = false;
    bool canExchange = false;
    bool addTiers = true;
    bool public initialTiers = false;

    // Storage
    mapping (address => uint256) public balances;
    mapping (address => bool) public exchangePartners;

    // mining schedule
    mapping(uint => uint256) public scheduleTokens;
    mapping(uint => uint256) public scheduleRates;

    // events
    event Transfer(address indexed _from, address indexed _to, uint _value);

    function COE() {
        owner = msg.sender;
        doPremine();
    }

    function doPremine() public {
        require(msg.sender == owner);
        require(distributionDone == false);
        balances[owner] = add(balances[owner],32664993546427000000000);
        Transfer(this, owner, 32664993546427000000000);
        circulatingSupply = add(circulatingSupply, 32664993546427000000000);
        totalSupply = sub(totalSupply,32664993546427000000000);
        distributionDone = true;
    }

    function populateTierTokens() public {
        require((msg.sender == owner) && (initialTiers == false));
        scheduleTokens[1] = 1E21;
        scheduleTokens[2] = 9E20;
        scheduleTokens[3] = 8E20;
        scheduleTokens[4] = 7E20;
        scheduleTokens[5] = 2.3E21;
        scheduleTokens[6] = 6.5E21;
        scheduleTokens[7] = 2E21;
        scheduleTokens[8] = 1.2E21;
        scheduleTokens[9] = 4.5E21;
        scheduleTokens[10] = 7.5E19;
        scheduleTokens[11] = 7.5E19;
        scheduleTokens[12] = 7.5E19;
        scheduleTokens[13] = 7.5E19;
        scheduleTokens[14] = 7.5E19;
        scheduleTokens[15] = 7.5E19;
        scheduleTokens[16] = 7.5E19;
        scheduleTokens[17] = 7.5E19;
        scheduleTokens[18] = 5.6E21;
        scheduleTokens[19] = 7.5E19;
        scheduleTokens[20] = 7.5E19;
        scheduleTokens[21] = 7.5E19;
        scheduleTokens[22] = 7.5E19;
        scheduleTokens[23] = 7.5E19;
        scheduleTokens[24] = 8.2E21;
        scheduleTokens[25] = 2.5E21;
        scheduleTokens[26] = 1.45E22;
        scheduleTokens[27] = 7.5E19;
        scheduleTokens[28] = 7.5E19;
        scheduleTokens[29] = 7.5E19;
        scheduleTokens[30] = 7.5E19;
        scheduleTokens[31] = 7.5E19;
        scheduleTokens[32] = 7.5E19;
        scheduleTokens[33] = 7.5E19;
        scheduleTokens[34] = 7.5E19;
        scheduleTokens[35] = 7.5E19;
        scheduleTokens[36] = 7.5E19;
        scheduleTokens[37] = 7.5E19;
        scheduleTokens[38] = 7.5E19;
        scheduleTokens[39] = 7.5E19;
        scheduleTokens[40] = 7.5E19;
        scheduleTokens[41] = 7.5E19;
        scheduleTokens[42] = 7.5E19;
        scheduleTokens[43] = 7.5E19;
        scheduleTokens[44] = 7.5E19;
        scheduleTokens[45] = 7.5E19;
        scheduleTokens[46] = 7.5E19;
        scheduleTokens[47] = 7.5E19;
        scheduleTokens[48] = 7.5E19;
        scheduleTokens[49] = 7.5E19;
        scheduleTokens[50] = 7.5E19;
    }

    function populateTierRates() public {
        require((msg.sender == owner) && (initialTiers == false));
        require(msg.sender == owner);
        scheduleRates[1] = 3.85E23;
        scheduleRates[2] = 6.1E23;
        scheduleRates[3] = 4.15E23;
        scheduleRates[4] = 5.92E23;
        scheduleRates[5] = 9.47E23;
        scheduleRates[6] = 1.1E24;
        scheduleRates[7] = 1.123E24;
        scheduleRates[8] = 1.115E24;
        scheduleRates[9] = 1.135E24;
        scheduleRates[10] = 1.013E24;
        scheduleRates[11] = 8.48E23;
        scheduleRates[12] = 8.17E23;
        scheduleRates[13] = 7.3E23;
        scheduleRates[14] = 9.8E23;
        scheduleRates[15] = 1.007E24;
        scheduleRates[16] = 1.45E24;
        scheduleRates[17] = 1.242E24;
        scheduleRates[18] = 1.383E24;
        scheduleRates[19] = 1.442E24;
        scheduleRates[20] = 2.048E24;
        scheduleRates[21] = 1.358E24;
        scheduleRates[22] = 1.245E24;
        scheduleRates[23] = 9.94E23;
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
        scheduleRates[38] = 1.175E24;
        scheduleRates[39] = 1.146E24;
        scheduleRates[40] = 1.098E24;
        scheduleRates[41] = 1.058E24;
        scheduleRates[42] = 9.97E23;
        scheduleRates[43] = 9.32E23;
        scheduleRates[44] = 8.44E23;
        scheduleRates[45] = 8.33E23;
        scheduleRates[46] = 7.8E23;
        scheduleRates[47] = 7.67E23;
        scheduleRates[48] = 8.37E23;
        scheduleRates[49] = 1.011E24;
        scheduleRates[50] = 9.79E23;
        initialTiers = true;
    }

    function () payable public {
        require((msg.value > 0) && (receiveEth));

        if(payFees) {
            devFees = add(devFees, ((msg.value * fees) / 10000));
        }
        allocateTokens(convertEthToCents(msg.value));
    }

    function convertEthToCents(uint256 _incoming) internal returns (uint256) {
        return mul(_incoming, fiatPerEth);
    }

    function allocateTokens(uint256 _submitted) internal {
        uint256 _availableInTier = mul(scheduleTokens[tierLevel], scheduleRates[tierLevel]);
        uint256 _allocation = 0;

        if(_submitted >= _availableInTier) {
            _allocation = scheduleTokens[tierLevel];
            scheduleTokens[tierLevel] = 0;
            tierLevel++;
            _submitted = sub(_submitted, _availableInTier);
        }
        else {
            uint256 _tokens = div(div(mul(_submitted, 1 ether), scheduleRates[tierLevel]), 1 ether);
            _allocation = add(_allocation, _tokens);
            scheduleTokens[tierLevel] = sub(scheduleTokens[tierLevel], _tokens);
            _submitted = sub(_submitted, mul(_tokens, scheduleRates[tierLevel]));
        }

        balances[msg.sender] = add(balances[msg.sender],_allocation);
        circulatingSupply = add(circulatingSupply, _allocation);
        totalSupply = sub(totalSupply, _allocation);

        if((_submitted != 0) && (tierLevel <= maxTier)) {
            allocateTokens(_submitted);
        }
        else {
            Transfer(this, msg.sender, balances[msg.sender]);
        }
    }

    function transfer(address _to, uint _value) public {
        require(balances[msg.sender] >= _value);
        totalSupply = add(totalSupply, _value);
        circulatingSupply = sub(circulatingSupply, _value);

        if(_to == address(this)) {
            // WARNING: if you transfer tokens back to the contract you will lose them
            // use the exchange function to exchange for tokens with approved partner contracts
            balances[msg.sender] = sub(balanceOf(msg.sender), _value);
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
                        balances[msg.sender] = sub(balanceOf(msg.sender), _value);
                        balances[_to] = add(balances[_to], _value);
                        Transfer(msg.sender, _to, _value);
                    }
                }
            }
            else {
                balances[msg.sender] = sub(balanceOf(msg.sender), _value);
                balances[_to] = add(balances[_to], _value);
                Transfer(msg.sender, _to, _value);
            }
        }
    }

    function exchange(address _partner, uint _amount) internal {
        require(exchangePartners[_partner]);
        requestTokensFromOtherContract(_partner, this, msg.sender, _amount);
        balances[msg.sender] = sub(balanceOf(msg.sender), _amount);
        circulatingSupply = sub(circulatingSupply, _amount);
        totalSupply = add(totalSupply, _amount);
        Transfer(msg.sender, this, _amount);
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

    function currentTier() public constant returns (uint256) {
        return tierLevel;
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
        // check balance before transferring
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

    function handleTokensFromOtherContracts(address _contract, address _recipient, uint256 _tokens) {
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

    function addTierRateAndTokens(uint256 _rate, uint256 _tokens, uint256 _level) public {
        require(((msg.sender == owner) || (msg.sender == tierAdmin)) && (addTiers == true));
        scheduleTokens[_level] = _tokens;
        scheduleRates[_level] = _rate;
    }

    // not really needed as we fix the max tiers on contract creation but just for completeness&#39; sake
    function closeTierAddition() public {
        require(msg.sender == owner);
        addTiers = false;
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