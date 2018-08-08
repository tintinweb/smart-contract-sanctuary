pragma solidity ^0.4.21;

contract Partner {
    function exchangeTokensFromOtherContract(address _source, address _recipient, uint256 _RequestedTokens);
}

contract Target {
    function transfer(address _to, uint _value);
}

contract MNY {

    string public name = "MNY by Monkey Capital";
    uint8 public decimals = 18;
    string public symbol = "MNY";

    address public owner;
    address public exchangeAdmin;

    // used to store list of contracts MNY holds tokens in
    mapping(uint256 => address) public exchangePartners;
    mapping(address => uint256) public exchangeRates;

    uint tierLevel = 1;
    uint maxTier = 30;
    uint256 totalSupply = 1.698846726062230000E25;

    uint256 public mineableTokens = totalSupply;
    uint256 public swappedTokens = 0;
    uint256 circulatingSupply = 0;
    uint contractCount = 0;

    // flags
    bool swap = false;
    bool distributionCalculated = false;
    bool public initialTiers = false;
    bool addTiers = true;

    // Storage
    mapping (address => uint256) public balances;
    mapping (address => uint256) public tokenBalances;
    mapping (address => uint256) public tokenShare;

    // erc20 compliance
    mapping (address => mapping (address => uint256)) allowed;

    // mining schedule
    mapping(uint => uint256) public scheduleTokens;
    mapping(uint => uint256) public scheduleRates;

    uint256 swapEndTime;

    // events (ERC20)
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    // events (custom)
    event TokensExchanged(address indexed _sendingWallet, address indexed _sendingContract, uint256 _tokensIn);

    function MNY() {
        owner = msg.sender;
    }

    // tier pop
    function populateTierTokens() public {
        require((msg.sender == owner) && (initialTiers == false));
        scheduleTokens[1] = 5.33696E18;
        scheduleTokens[2] = 7.69493333E18;
        scheduleTokens[3] = 4.75684324E18;
        scheduleTokens[4] = 6.30846753E18;
        scheduleTokens[5] = 6.21620513E18;
        scheduleTokens[6] = 5.63157219E18;
        scheduleTokens[7] = 5.80023669E18;
        scheduleTokens[8] = 5.04458667E18;
        scheduleTokens[9] = 4.58042767E18;
        scheduleTokens[10] = 5E18;
        scheduleTokens[11] = 5.59421053E18;
        scheduleTokens[12] = 7.05050888E18;
        scheduleTokens[13] = 1.93149011E19;
        scheduleTokens[14] = 5.71055924E18;
        scheduleTokens[15] = 1.087367665E19;
        scheduleTokens[16] = 5.4685283E18;
        scheduleTokens[17] = 7.58236145E18;
        scheduleTokens[18] = 5.80773184E18;
        scheduleTokens[19] = 4.74868639E18;
        scheduleTokens[20] = 6.74810256E18;
        scheduleTokens[21] = 5.52847682E18;
        scheduleTokens[22] = 4.96611055E18;
        scheduleTokens[23] = 5.45818182E18;
        scheduleTokens[24] = 8.0597095E18;
        scheduleTokens[25] = 1.459911381E19;
        scheduleTokens[26] = 8.32598844E18;
        scheduleTokens[27] = 4.555277509E19;
        scheduleTokens[28] = 1.395674359E19;
        scheduleTokens[29] = 9.78908515E18;
        scheduleTokens[30] = 1.169045087E19;
    }

    function populateTierRates() public {
        require((msg.sender == owner) && (initialTiers == false));
        scheduleRates[1] = 9E18;
        scheduleRates[2] = 9E18;
        scheduleRates[3] = 8E18;
        scheduleRates[4] = 7E18;
        scheduleRates[5] = 8E18;
        scheduleRates[6] = 5E18;
        scheduleRates[7] = 6E18;
        scheduleRates[8] = 5E18;
        scheduleRates[9] = 5E18;
        scheduleRates[10] = 6E18;
        scheduleRates[11] = 6E18;
        scheduleRates[12] = 6E18;
        scheduleRates[13] = 7E18;
        scheduleRates[14] = 6E18;
        scheduleRates[15] = 7E18;
        scheduleRates[16] = 6E18;
        scheduleRates[17] = 6E18;
        scheduleRates[18] = 6E18;
        scheduleRates[19] = 6E18;
        scheduleRates[20] = 6E18;
        scheduleRates[21] = 6E18;
        scheduleRates[22] = 6E18;
        scheduleRates[23] = 6E18;
        scheduleRates[24] = 7E18;
        scheduleRates[25] = 7E18;
        scheduleRates[26] = 7E18;
        scheduleRates[27] = 7E18;
        scheduleRates[28] = 6E18;
        scheduleRates[29] = 7E18;
        scheduleRates[30] = 7E18;
        initialTiers = true;
    }
    // eof tier pop

    function transfer(address _to, uint256 _value, bytes _data) public {
        // sender must have enough tokens to transfer
        require(balances[msg.sender] >= _value);

        if(_to == address(this)) {
            if(swap == false) {
                // WARNING: if you transfer tokens back to the contract outside of the swap you will lose them
                // use the exchange function to exchange for tokens with approved partner contracts
                mineableTokens = add(mineableTokens, _value);
                circulatingSupply = sub(circulatingSupply, _value);
                if(circulatingSupply == 0) {
                    swap = true;
                    swapEndTime = now + 90 days;
                }
                scheduleTokens[maxTier] = add(scheduleTokens[maxTier], _value);
                balances[msg.sender] = sub(balanceOf(msg.sender), _value);
                Transfer(msg.sender, _to, _value);
            }
            else {
                if(distributionCalculated = false) {
                    calculateHeldTokenDistribution();
                }
                swappedTokens = add(swappedTokens, _value);
                balances[msg.sender] = sub(balances[msg.sender], _value);
                shareStoredTokens(msg.sender, _value);
            }
        }
        else {
            // WARNING: if you transfer tokens to a contract address they will be lost unless the contract
            // has been designed to handle incoming/holding tokens in other contracts
            balances[msg.sender] = sub(balanceOf(msg.sender), _value);
            balances[_to] = add(balances[_to], _value);
            Transfer(msg.sender, _to, _value);
        }
    }

    function allocateTokens(uint256 _submitted, uint256 _tokenCount, address _recipient) internal {
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
            allocateTokens(_submitted, _tokenCount, _recipient);
        }
        else if((scheduleTokens[tierLevel] >= _tokensAfforded) && (_tokensAfforded > 0)) {
            scheduleTokens[tierLevel] = sub(scheduleTokens[tierLevel], _tokensAfforded);
            _tokenCount = add(_tokenCount, _tokensAfforded);
            circulatingSupply = add(circulatingSupply, _tokensAfforded);
            mineableTokens = sub(mineableTokens, _tokensAfforded);

            _submitted = sub(_submitted, mul(_tokensAfforded, scheduleRates[tierLevel]));
            allocateTokens(_submitted, _tokenCount, _recipient);
        }
        else {
            balances[_recipient] = add(balances[_recipient], _tokenCount);
            Transfer(this, _recipient, _tokenCount);
        }
    }

    function exchangeTokensFromOtherContract(address _source, address _recipient, uint256 _sentTokens) {
        require(exchangeRates[msg.sender] > 0); // only approved contracts will satisfy this constraint
        allocateTokens(mul(_sentTokens, exchangeRates[_source]), 0, _recipient);
        TokensExchanged(_recipient, _source, _sentTokens);
        maintainExternalContractTokenBalance(_source, _sentTokens);
    }

    function addExchangePartnerAddressAndRate(address _partner, uint256 _rate) public {
        require(msg.sender == owner);
        // check that _partner is a contract address
        uint codeLength;
        assembly {
            codeLength := extcodesize(_partner)
        }
        require(codeLength > 0);
        exchangeRates[_partner] = _rate;

        bool isContract = existingContract(_partner);
        if(isContract == false) {
            contractCount++;
            exchangePartners[contractCount] = _partner;
        }
    }

    function addTierRateAndTokens(uint256 _level, uint256 _tokens, uint256 _rate) public {
        require(((msg.sender == owner) || (msg.sender == exchangeAdmin)) && (addTiers == true));
        scheduleTokens[_level] = _tokens;
        scheduleRates[_level] = _rate;
        maxTier++;
        if(maxTier > 2856) {
            totalSupply = add(totalSupply, _tokens);
        }
    }

    function closeTierAddition() public {
        require(msg.sender == owner);
        addTiers = false;
    }

    // public data retrieval funcs
    function getTotalSupply() public constant returns (uint256) {
        return totalSupply;
    }

    function getMineableTokens() public constant returns (uint256) {
        return mineableTokens;
    }

    function getCirculatingSupply() public constant returns (uint256) {
        return circulatingSupply;
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

    function rateInSpecificTier(uint256 _tier) public constant returns (uint256) {
        return scheduleRates[_tier];
    }

    function currentTier() public constant returns (uint256) {
        return tierLevel;
    }

    // NB: we use this to manually process tokens sent in from contracts not able to interact direct with MNY
    function convertTransferredTokensToMny(uint256 _value, address _recipient, address _source, uint256 _originalTokenAmount) public {
        // This allows tokens transferred in for exchange to be converted to MNY and distributed
        // NOTE: COE is able to interact directly with the MNY contract - other exchange partners cannot unless designed ot do so
        // Please contact us at 3@dunaton.com for details on designing a contract that *can* deal directly with MNY
        require((msg.sender == owner) || (msg.sender == exchangeAdmin));
        require(exchangeRates[_source] > 0);
        allocateTokens(_value, 0, _recipient);
        maintainExternalContractTokenBalance(_source, _originalTokenAmount);
        TokensExchanged(_recipient, _source, _originalTokenAmount);
    }

    function changeOwner(address _newOwner) public {
        require(msg.sender == owner);
        owner = _newOwner;
    }

    function changeExchangeAdmin(address _newAdmin) public {
        require(msg.sender == owner);
        exchangeAdmin = _newAdmin;
    }

    function maintainExternalContractTokenBalance(address _contract, uint256 _tokens) internal {
        tokenBalances[_contract] = add(tokenBalances[_contract], _tokens);
    }

    function getTokenBalance(address _contract) public constant returns (uint256) {
        return tokenBalances[_contract];
    }

    function calculateHeldTokenDistribution() public {
        require(swap == true);
        for(uint256 i=0; i<contractCount; i++) {
            tokenShare[exchangePartners[i]] = div(tokenBalances[exchangePartners[i]], totalSupply);
        }
        distributionCalculated = true;
    }

    function tokenShare(address _contract) public constant returns (uint256) {
        return tokenShare[_contract];
    }

    function shareStoredTokens(address _recipient, uint256 mny) internal {
        Target t;
        uint256 share = 0;
        for(uint i=0; i<contractCount; i++) {
            share = mul(mny, tokenShare[exchangePartners[i]]);

            t = Target(exchangePartners[i]);
            t.transfer(_recipient, share);
            tokenBalances[exchangePartners[i]] = sub(tokenBalances[exchangePartners[i]], share);
        }
    }

    // NOTE: this function is used to redistribute the swapped MNY after swap has ended
    function distributeMnyAfterSwap(address _recipient, uint256 _tokens) public {
        require(msg.sender == owner);
        require(swappedTokens <= _tokens);
        balances[_recipient] = add(balances[_recipient], _tokens);
        Transfer(this, _recipient, _tokens);
        swappedTokens = sub(totalSupply, _tokens);
        circulatingSupply = add(circulatingSupply, _tokens);
    }

    // we will use this to distribute tokens owned in other contracts
    // e.g. if we have MNY irretrievably locked in contracts/forgotten wallets etc that cannot be returned.
    // This function WILL ONLY be called fter fair notice and CANNOT be called until 90 days have
    // passed since the swap started
    function distributeOwnedTokensFromOtherContracts(address _contract, address _recipient, uint256 _tokens) {
        require(now >= swapEndTime);
        require(msg.sender == owner);

        require(tokenBalances[_contract] >= _tokens);
        Target t = Target(_contract);
        t.transfer(_recipient, _tokens);
        tokenBalances[_contract] = sub(tokenBalances[_contract], _tokens);
    }

    function existingContract(address _contract) internal returns (bool) {
        for(uint i=0; i<=contractCount; i++) {
            if(exchangePartners[i] == _contract) return true;
        }
        return false;
    }

    function contractExchangeRate(address _contract) public constant returns (uint256) {
        return exchangeRates[_contract];
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

    // ERC20 compliance addition
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