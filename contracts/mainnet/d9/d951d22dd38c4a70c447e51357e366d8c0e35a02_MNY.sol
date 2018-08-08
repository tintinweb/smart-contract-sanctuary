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

    uint256[] tierTokens = [
        5.33696E18,
        7.69493333E18,
        4.75684324E18,
        6.30846753E18,
        6.21620513E18,
        5.63157219E18,
        5.80023669E18,
        5.04458667E18,
        4.58042767E18,
        5E18
    ];

    uint256[] costPerToken = [
        9E16,
        9E16,
        8E16,
        7E16,
        8E16,
        5E16,
        6E16,
        5E16,
        5E16,
        6E16
    ];

    // used to store list of contracts MNY holds tokens in
    address[] contracts = [0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0];

    uint tierLevel = 0;
    uint maxTier = 9;
    uint256 totalSupply = 21000000000000000000000000;
    uint256 circulatingSupply = 0;
    uint contractCount = 1;

    // flags
    bool public receiveEth = true;
    bool swap = false;
    bool allSwapped = false;
    bool distributionCalculated = false;

    // Storage
    mapping (address => uint256) public balances;
    mapping (address => uint256) public tokenBalances;
    mapping (address => uint256) public tokenShare;
    mapping (address => uint256) public exchangeRates; // balance and rate in cents (where $1 = 1*10^18)

    // events
    event Transfer(address indexed _from, address indexed _to, uint _value);

    function MNY() {
        owner = msg.sender;
    }

    function transfer(address _to, uint _value, bytes _data) public {
        // sender must have enough tokens to transfer
        require(balances[msg.sender] >= _value);

        if(_to == address(this)) {
            if(swap == false) {
                // WARNING: if you transfer tokens back to the contract outside of the swap you will lose them
                // use the exchange function to exchange for tokens with approved partner contracts
                totalSupply = add(totalSupply, _value);
                circulatingSupply = sub(circulatingSupply, _value);
                if(circulatingSupply == 0) allSwapped = true;
                tierTokens[maxTier] = add(tierTokens[maxTier], _value);
                balances[msg.sender] = sub(balanceOf(msg.sender), _value);
                Transfer(msg.sender, _to, _value);
            }
            else {
                require(div(_value, 1 ether) > 0);   // whole tokens only in for swap
                if(distributionCalculated = false) {
                    calculateHeldTokenDistribution();
                }
                balances[msg.sender] = sub(balances[msg.sender], _value);
                shareStoredTokens(msg.sender, div(_value, 1 ether));
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

    function transfer(address _to, uint _value) public {
        // sender must have enough tokens to transfer
        require(balances[msg.sender] >= _value);

        if(_to == address(this)) {
            if(swap == false) {
                // WARNING: if you transfer tokens back to the contract outside of the swap you will lose them
                // use the exchange function to exchange for tokens with approved partner contracts
                totalSupply = add(totalSupply, _value);
                circulatingSupply = sub(circulatingSupply, _value);
                if(circulatingSupply == 0) allSwapped = true;
                tierTokens[maxTier] = add(tierTokens[maxTier], _value);
                balances[msg.sender] = sub(balanceOf(msg.sender), _value);
                Transfer(msg.sender, _to, _value);
            }
            else {
                if(distributionCalculated = false) {
                    calculateHeldTokenDistribution();
                }
                balances[msg.sender] = sub(balances[msg.sender], _value);
                shareStoredTokens(msg.sender, div(_value, 1 ether));
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

    function allocateTokens(uint256 _submitted, address _recipient) internal {
        uint256 _availableInTier = mul(tierTokens[tierLevel], costPerToken[tierLevel]);
        uint256 _allocation = 0;

        if(_submitted >= _availableInTier) {
            _allocation = tierTokens[tierLevel];
            tierTokens[tierLevel] = 0;
            tierLevel++;
            if(tierLevel > maxTier) {
                swap = true;
            }
            _submitted = sub(_submitted, _availableInTier);
        }
        else {
            uint256 stepOne = mul(_submitted, 1 ether);
            uint256 stepTwo = div(stepOne, costPerToken[tierLevel]);
            uint256 _tokens = stepTwo;
            _allocation = add(_allocation, _tokens);
            tierTokens[tierLevel] = sub(tierTokens[tierLevel], _tokens);
            _submitted = sub(_submitted, _availableInTier);
        }

        // transfer tokens allocated so far to wallet address from contract
        balances[_recipient] = add(balances[_recipient],_allocation);
        circulatingSupply = add(circulatingSupply, _allocation);
        totalSupply = sub(totalSupply, _allocation);

        if((_submitted != 0) && (tierLevel <= maxTier)) {
            allocateTokens(_submitted, _recipient);
        }
        else {
            // emit transfer event
            Transfer(this, _recipient, balances[_recipient]);
        }
    }

    function exchangeTokensFromOtherContract(address _source, address _recipient, uint256 _sentTokens) public {

        require(exchangeRates[msg.sender] > 0);
        uint256 _exchanged = mul(_sentTokens, exchangeRates[_source]);

        require(_exchanged <= mul(totalSupply, 1 ether));
        allocateTokens(_exchanged, _recipient);
    }

    function addExchangePartnerAddressAndRate(address _partner, uint256 _rate) {
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
            contracts[contractCount] = _partner;
        }
    }

    // public data retrieval funcs
    function getTotalSupply() public constant returns (uint256) {
        return totalSupply;
    }

    function getCirculatingSupply() public constant returns (uint256) {
        return circulatingSupply;
    }

    function balanceOf(address _receiver) public constant returns (uint256) {
        return balances[_receiver];
    }

    function balanceInTier() public constant returns (uint256) {
        return tierTokens[tierLevel];
    }

    function balanceInSpecificTier(uint tier) public constant returns (uint256) {
        return tierTokens[tier];
    }

    function currentTier() public constant returns (uint256) {
        return tierLevel;
    }

    // admin functions
    function convertTransferredTokensToMny(uint256 _value, address _recipient, address _source, uint256 _originalAmount) public {
        // allows tokens transferred in for exchange to be converted to MNY and distributed
        // COE is able to interact directly with contract - other exchange partners cannot
        require((msg.sender == owner) || (msg.sender == exchangeAdmin));
        require(exchangeRates[_source] > 0);
        maintainExternalContractTokenBalance(_source, _originalAmount);
        allocateTokens(_value, _recipient);
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
        require(swap = true);
        for(uint i=0; i<contractCount; i++) {
//            tokenShare[contracts[i]] = div(tokenBalances[contracts[i]], div(add(totalSupply, circulatingSupply), 1 ether));
            tokenShare[contracts[i]] = div(tokenBalances[contracts[i]], circulatingSupply);
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
            share = mul(mny, tokenShare[contracts[i]]);

            t = Target(contracts[i]);
            t.transfer(_recipient, share);
        }
    }

    function distributeMnyAfterSwap(address _recipient, uint256 _tokens) public {
        require(msg.sender == owner);
        require(totalSupply <= _tokens);
        balances[_recipient] = add(balances[_recipient], _tokens);
        Transfer(this, _recipient, _tokens);
        totalSupply = sub(totalSupply, _tokens);
        circulatingSupply = add(circulatingSupply, _tokens);
    }

    function existingContract(address _contract) internal returns (bool) {
        for(uint i=0; i<contractCount; i++) {
            if(contracts[i] == _contract) return true;
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
}