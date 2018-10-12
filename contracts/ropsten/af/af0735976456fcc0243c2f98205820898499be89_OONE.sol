pragma solidity ^0.4.23;

contract OONE {
    string public name = "Olympus One";
    uint8 public decimals = 18;
    string public symbol = "OONE";

    address public owner;
    address public feesAddr;//todo
    address trancheAdmin;//todo

    uint256 public totalSupply = 50000000000000000000000000; // 50m e18
    uint256 public mineableTokens = totalSupply;
    uint public trancheLevel = 1;
    uint256 public circulatingSupply = 0;
    uint maxTranche = 4;
    uint loopCount = 0;
    uint256 public devFees = 0;
    uint256 feePercent = 1500;  // the calculation expects % * 100 (so 10% is 1000)
    uint256 trancheOneSaleTime;
    uint fiatPerEth = 17089000000000000000000;   // cents per ETH in this case (*10^18)
    bool public receiveEth = true;
    bool payFees = true;
    bool addTranches = true;
    bool public initialTranches = false;
    bool trancheOne = true;

    // Storage
    mapping (address => uint256) public balances;
    mapping (address => uint256) public trancheOneBalances;
    mapping(address => mapping (address => uint256)) allowed;

    // mining schedule
    mapping(uint => uint256) public trancheTokens;
    mapping(uint => uint256) public trancheRate;

    // events (ERC20)
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    function OONE() {
        owner = msg.sender;
        feesAddr = msg.sender;
        trancheAdmin = msg.sender;
        trancheOneSaleTime = now + 182 days;    // 6 months
        populateTrancheTokens();
        populateTrancheRates();
    }

    function populateTrancheTokens() public {
        // require((msg.sender == owner) && (initialTranches == false));
        trancheTokens[1] = 1E25;
        trancheTokens[2] = 2E25;
        trancheTokens[3] = 1E25;
        trancheTokens[4] = 1E25;
    }

    function populateTrancheRates() public {
        //require((msg.sender == owner) && (initialTranches == false));
        //require(msg.sender == owner);
        trancheRate[1] = 5E24;
        trancheRate[2] = 8.643E19;
        trancheRate[3] = 4.321E19;
        trancheRate[4] = 2.161E19;
        initialTranches = true;
    }

    function () payable public {
        require((msg.value > 0) && (receiveEth));
        allocateTokens(msg.value,0);
    }

    function convertEthToCents(uint256 _incoming) internal returns (uint256) {
        return mul(_incoming, fiatPerEth);
    }

    function allocateTokens(uint256 _submitted, uint256 _tokenCount) internal {
        uint256 _tokensAfforded = 0;
        loopCount++;

        if((trancheLevel <= maxTranche) && (loopCount <= maxTranche)) {
            _tokensAfforded = div(mul(_submitted, trancheRate[trancheLevel]), 1 ether);
        }

        if((_tokensAfforded >= trancheTokens[trancheLevel]) && (loopCount <= maxTranche)) {
            _submitted = sub(_submitted, div(mul(trancheTokens[trancheLevel], 1 ether), trancheRate[trancheLevel]));
            _tokenCount = add(_tokenCount, trancheTokens[trancheLevel]);

            if(trancheLevel == 1) {
                // we need to record tranche1 purchases so we can stop sale/transfer of them during the first 6 mths
                trancheOneBalances[msg.sender] = add(trancheOneBalances[msg.sender], trancheTokens[trancheLevel]);
            }

            circulatingSupply = add(circulatingSupply, _tokensAfforded);
            trancheTokens[trancheLevel] = 0;

            trancheLevel++;

            if(trancheLevel == 2) {
                trancheOne = false;
            }

            allocateTokens(_submitted, _tokenCount);
        }
        else if((trancheTokens[trancheLevel] >= _tokensAfforded) && (_tokensAfforded > 0) && (loopCount <= maxTranche)) {
            trancheTokens[trancheLevel] = sub(trancheTokens[trancheLevel], _tokensAfforded);
            _tokenCount = add(_tokenCount, _tokensAfforded);
            circulatingSupply = add(circulatingSupply, _tokensAfforded);

            if(trancheLevel == 1) {
                // we need to record tranche1 purchases
                trancheOneBalances[msg.sender] = add(trancheOneBalances[msg.sender], _tokenCount);
            }

            // we&#39;ve spent up - go around again and issue tokens to recipient
            allocateTokens(0, _tokenCount);
        }
        else {
            // take 15% of the purchased tokens as fees and transfer the rest to the purchaser
            uint256 fees = 0;
            if(payFees) {
                fees = add(fees, ((_tokenCount * feePercent) / 10000));
            }

            balances[msg.sender] = add(balances[msg.sender], _tokenCount);
            balances[feesAddr] = add(balances[feesAddr], fees);

            if(trancheOne) {
                trancheOneBalances[feesAddr] = add(trancheOneBalances[feesAddr], fees);
            }

            Transfer(this, msg.sender, _tokenCount);
            Transfer(this, feesAddr, fees);
            loopCount = 0;
        }
    }

    function transfer(address _to, uint256 _value) public {
        require(balances[msg.sender] >= _value);

        if(_to == address(this)) {
            // WARNING: if you transfer tokens back to the contract you will lose them
            balances[msg.sender] = sub(balances[msg.sender], _value);
            circulatingSupply = sub(circulatingSupply, _value);
            Transfer(msg.sender, _to, _value);
        }
        else {
            if(now >= trancheOneSaleTime) {
                balances[msg.sender] = sub(balances[msg.sender], _value);
                balances[_to] = add(balances[_to], _value);
                Transfer(msg.sender, _to, _value);
            }
            else {
                if(_value <= sub(balances[msg.sender],trancheOneBalances[msg.sender])) {
                    balances[msg.sender] = sub(balances[msg.sender], _value);
                    balances[_to] = add(balances[_to], _value);
                    Transfer(msg.sender, _to, _value);
                }
                else revert();  // you can&#39;t transfer tranche1 tokens during the first 6 months
            }
        }
    }

    function balanceOf(address _receiver) public constant returns (uint256) {
        return balances[_receiver];
    }

    function trancheOneBalanceOf(address _receiver) public constant returns (uint256) {
        return trancheOneBalances[_receiver];
    }

    function balanceInTranche() public constant returns (uint256) {
        return trancheTokens[trancheLevel];
    }

    function balanceInSpecificTranche(uint256 _tranche) public constant returns (uint256) {
        return trancheTokens[_tranche];
    }

    function rateOfSpecificTranche(uint256 _tranche) public constant returns (uint256) {
        return trancheRate[_tranche];
    }

    function changeFeesAddress(address _devFees) public {
        require(msg.sender == owner);
        feesAddr = _devFees;
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

    // enables fee update - must be between 0 and 100 (%)
    function updateFeeAmount(uint _newFee) public {
        require(msg.sender == owner);
        require((_newFee >= 0) && (_newFee <= 100));
        feePercent = _newFee * 100;
    }

    function changeOwner(address _recipient) public {
        require(msg.sender == owner);
        owner = _recipient;
    }

    function changeTrancheAdmin(address _trancheAdmin) public {
        require((msg.sender == owner) || (msg.sender == trancheAdmin));
        trancheAdmin = _trancheAdmin;
    }

    function toggleReceiveEth() public {
        require(msg.sender == owner);
        if(receiveEth == true) {
            receiveEth = false;
        }
        else receiveEth = true;
    }

    function otcPurchase(uint256 _tokens, address _recipient) public {
        require(msg.sender == owner);
        balances[_recipient] = add(balances[_recipient], _tokens);
        Transfer(this, _recipient, _tokens);
    }

    function otcPurchaseAndEscrow(uint256 _tokens, address _recipient) public {
        require(msg.sender == owner);
        balances[_recipient] = add(balances[_recipient], _tokens);
        trancheOneBalances[msg.sender] = add(trancheOneBalances[msg.sender], _tokens);
        Transfer(this, _recipient, _tokens);
    }

    function safeWithdrawal(address _receiver, uint256 _value) public {
        require(msg.sender == owner);
        require(_value <= this.balance);
        _receiver.transfer(_value);
    }

    function addTrancheRateAndTokens(uint256 _level, uint256 _tokens, uint256 _rate) public {
        require(((msg.sender == owner) || (msg.sender == trancheAdmin)) && (addTranches == true));
        require(add(_tokens, circulatingSupply) <= totalSupply);
        trancheTokens[_level] = _tokens;
        trancheRate[_level] = _rate;
    }

    function updateTranchRate(uint256 _level, uint256 _rate) {
        require((msg.sender == owner) || (msg.sender == trancheAdmin));
        trancheRate[_level] = _rate;
    }

    // when all tranches have been added to the contract (not possible to deploy with all of them)
    function closeTrancheAddition() public {
        require(msg.sender == owner);
        addTranches = false;
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

    // ERC20 compliance
    function transferFrom(address _from, address _to, uint256 _tokens) public returns (bool success) {
        require(balances[_from] >= _tokens);
        balances[_from] = sub(balances[_from],_tokens);
        allowed[_from][msg.sender] = sub(allowed[_from][msg.sender],_tokens);
        balances[_to] = add(balances[_to],_tokens);
        Transfer(_from, _to, _tokens);
        return true;
    }

    function approve(address _spender, uint256 _tokens) public returns (bool success) {
        allowed[msg.sender][_spender] = _tokens;
        Approval(msg.sender, _spender, _tokens);
        return true;
    }

    function allowance(address _tokenOwner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_tokenOwner][_spender];
    }
}