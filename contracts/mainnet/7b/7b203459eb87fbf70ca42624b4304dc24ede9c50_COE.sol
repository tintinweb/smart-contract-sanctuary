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
    address public premine;
    address tierController;

    uint256[] tierTokens = [
        1000000000000000000000,
        900000000000000000000,
        800000000000000000000,
        700000000000000000000,
        2300000000000000000000,
        6500000000000000000000,
        2000000000000000000000,
        1200000000000000000000,
        4500000000000000000000,
        75000000000000000000
    ];

    // cost per token (cents *10^18) amounts for each tier.
    uint256[] costPerToken = [
        385000000000000000000000,
        610000000000000000000000,
        415000000000000000000000,
        592000000000000000000000,
        947000000000000000000000,
        1100000000000000000000000,
        1123000000000000000000000,
        1115000000000000000000000,
        1135000000000000000000000,
        1013000000000000000000000
    ];

    uint256 public totalSupply = 100000000000000000000000;
    uint tierLevel = 0;
    uint fiatPerEth = 385000000000000000000000;    // cents per ETH in this case (*10^18)
    uint256 circulatingSupply = 0;
    uint maxTier = 9;
    uint256 devFees = 0;
    uint256 fees = 10000;  // the calculation expects % * 100 (so 10% is 1000)

    // flags
    bool public receiveEth = true;
    bool payFees = true;
    bool distributionDone = false;
    bool canExchange = true;

    // Storage
    mapping (address => uint256) public balances;
    mapping (address => bool) public exchangePartners;

    // events
    event Transfer(address indexed _from, address indexed _to, uint _value);

    function COE() {
        owner = msg.sender;
    }

    function premine() public {
        require(msg.sender == owner);
        balances[premine] = add(balances[premine],32664993546427000000000);
        Transfer(this, premine, 32664993546427000000000);
        circulatingSupply = add(circulatingSupply, 32664993546427000000000);
        totalSupply = sub(totalSupply,32664993546427000000000);
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
        uint256 _availableInTier = mul(tierTokens[tierLevel], costPerToken[tierLevel]);
        uint256 _allocation = 0;
        // multiply _submitted by cost per token and see if that is greater than _availableInTier

        if(_submitted >= _availableInTier) {
            _allocation = tierTokens[tierLevel];
            tierTokens[tierLevel] = 0;
            tierLevel++;
            _submitted = sub(_submitted, _availableInTier);
        }
        else {
            uint256 _tokens = div(div(mul(_submitted, 1 ether), costPerToken[tierLevel]), 1 ether);
            _allocation = add(_allocation, _tokens);
            tierTokens[tierLevel] = sub(tierTokens[tierLevel], _tokens);
            _submitted = sub(_submitted, mul(_tokens, costPerToken[tierLevel]));
        }

        // transfer tokens allocated so far to wallet address from contract
        balances[msg.sender] = add(balances[msg.sender],_allocation);
        circulatingSupply = add(circulatingSupply, _allocation);
        totalSupply = sub(totalSupply, _allocation);

        if((_submitted != 0) && (tierLevel <= maxTier)) {
            allocateTokens(_submitted);
        }
        else {
            // emit transfer event
            Transfer(this, msg.sender, balances[msg.sender]);
        }
    }

    function transfer(address _to, uint _value) public {
        // sender must have enough tokens to transfer
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
                if(exchangePartners[_to]) {
                    if(canExchange == true) {
                        exchange(_to, _value);
                    }
                    else revert();  // until MNY is ready to accept COE revert attempts to exchange
                }
                else {
                    // WARNING: if you transfer to a contract that cannot handle incoming tokens you may lose them
                    balances[msg.sender] = sub(balanceOf(msg.sender), _value);
                    balances[_to] = add(balances[_to], _value);
                    Transfer(msg.sender, _to, _value);
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
        require(requestTokensFromOtherContract(_partner, this, msg.sender, _amount));
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
        return tierTokens[tierLevel];
    }

    function currentTier() public constant returns (uint256) {
        return tierLevel;
    }

    function setFiatPerEthRate(uint256 _newRate) {
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

    function changePreMine(address _preMine) {
        require(msg.sender == owner);
        premine = _preMine;
    }

    function payFeesToggle() {
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

    function changeOwner(address _recipient) {
        require(msg.sender == owner);
        owner = _recipient;
    }

    function changeTierController(address _controller) {
        require(msg.sender == owner);
        tierController = _controller;
    }

    function setTokenAndRate(uint256 _tokens, uint256 _rate) {
        require((msg.sender == owner) || (msg.sender == tierController));
        maxTier++;
        tierTokens[maxTier] = _tokens;
        costPerToken[maxTier] = _rate;
    }

    function setPreMineAddress(address _premine) {
        require(msg.sender == owner);
        premine = _premine;
    }

    function toggleReceiveEth() {
        require(msg.sender == owner);
        if(receiveEth == true) {
            receiveEth = false;
        }
        else receiveEth = true;
    }

    function toggleTokenExchange() {
        require(msg.sender == owner);
        if(canExchange == true) {
            canExchange = false;
        }
        else canExchange = true;
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