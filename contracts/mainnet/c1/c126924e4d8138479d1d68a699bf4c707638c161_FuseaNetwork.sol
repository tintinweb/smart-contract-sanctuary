pragma solidity 0.4.18;

contract FuseaNetwork {

    string public symbol = "FSA";
    string public name = "Fusea Network";
    uint8 public constant decimals = 18;
    uint256 _totalSupply = 0;	
	uint256 _MaxDistribPublicSupply = 400000000;
	uint256 _BonusTokensPerETHSended = 500000;
    uint256 _OwnerDistribSupply = 0;
    uint256 _CurrentDistribPublicSupply = 0;   
	address _DistribFundsReceiverAddress = 0;
    address _remainingTokensReceiverAddress = 0;
    address owner = 0;		
    uint256 _ML1 = 2;
    uint256 _ML2 = 2;
	uint256 _ML3 = 2;
	uint256 _ML4 = 2;
    uint256 _LimitML1 = 4e15;
    uint256 _LimitML2 = 6e15;
	uint256 _LimitML3 = 8e15;
	uint256 _LimitML4 = 12e15;	

	
	
    bool setupDone = false;
    bool IsDistribRunning = false;
    bool DistribStarted = false;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _owner, uint256 _value);

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => bool) public Claimed;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function FuseaNetwork() public {
        owner = msg.sender;
    }

        function() public payable {
        if (IsDistribRunning) {
            uint256 _amount;
            if (((_CurrentDistribPublicSupply + _amount) > _MaxDistribPublicSupply) && _MaxDistribPublicSupply > 0) revert();
            if (!_DistribFundsReceiverAddress.send(msg.value)) revert();
            
            
            	   if (msg.value >= 12e15) {
            _amount = msg.value * _BonusTokensPerETHSended * 2;
            } else {
		               if (msg.value >= 8e15) {
            _amount = msg.value * _BonusTokensPerETHSended * 2;
            } else {
                if (msg.value >= 6e15) {
                    _amount = msg.value * _BonusTokensPerETHSended * 2;
                } else {
                    if (msg.value >= 4e15) {
                        _amount = msg.value * _BonusTokensPerETHSended * 2;
                    } else {

                        _amount = msg.value * _BonusTokensPerETHSended;

                    }
                 }    
              }
           }
			 
			 _CurrentDistribPublicSupply += _amount;
                balances[msg.sender] += _amount;
                _totalSupply += _amount;
                Transfer(this, msg.sender, _amount);
        



        } else {
            revert();
        }
    }

    function SetupFuseaNetwork(string tokenName, string tokenSymbol, uint256 BonusTokensPerETHSended, uint256 MaxDistribPublicSupply, uint256 OwnerDistribSupply, address remainingTokensReceiverAddress, address DistribFundsReceiverAddress) public {
        if (msg.sender == owner && !setupDone) {
            symbol = tokenSymbol;
            name = tokenName;
            _BonusTokensPerETHSended = BonusTokensPerETHSended;
            _MaxDistribPublicSupply = MaxDistribPublicSupply * 1e18;
            if (OwnerDistribSupply > 0) {
                _OwnerDistribSupply = OwnerDistribSupply * 1e18;
                _totalSupply = _OwnerDistribSupply;
                balances[owner] = _totalSupply;
                _CurrentDistribPublicSupply += _totalSupply;
                Transfer(this, owner, _totalSupply);
            }
            _DistribFundsReceiverAddress = DistribFundsReceiverAddress;
            if (_DistribFundsReceiverAddress == 0) _DistribFundsReceiverAddress = owner;
            _remainingTokensReceiverAddress = remainingTokensReceiverAddress;

            setupDone = true;
        }
    }

    function SetupML(uint256 ML1inX, uint256 ML2inX, uint256 LimitML1inWei, uint256 LimitML2inWei) onlyOwner public {
        _ML1 = ML1inX;
        _ML2 = ML2inX;
        _LimitML1 = LimitML1inWei;
        _LimitML2 = LimitML2inWei;
        
    }

    function SetBonus(uint256 BonusTokensPerETHSended) onlyOwner public {
        _BonusTokensPerETHSended = BonusTokensPerETHSended;
    }

   
    function StartFuseaNetworkDistribution() public returns(bool success) {
        if (msg.sender == owner && !DistribStarted && setupDone) {
            DistribStarted = true;
            IsDistribRunning = true;
        } else {
            revert();
        }
        return true;
    }

    function StopFuseaNetworkDistribution() public returns(bool success) {
        if (msg.sender == owner && IsDistribRunning) {
            if (_remainingTokensReceiverAddress != 0 && _MaxDistribPublicSupply > 0) {
                uint256 _remainingAmount = _MaxDistribPublicSupply - _CurrentDistribPublicSupply;
                if (_remainingAmount > 0) {
                    balances[_remainingTokensReceiverAddress] += _remainingAmount;
                    _totalSupply += _remainingAmount;
                    Transfer(this, _remainingTokensReceiverAddress, _remainingAmount);
                }
            }
            DistribStarted = false;
            IsDistribRunning = false;
        } else {
            revert();
        }
        return true;
    }

    function distribution(address[] addresses, uint256 _amount) onlyOwner public {

        uint256 _remainingAmount = _MaxDistribPublicSupply - _CurrentDistribPublicSupply;
        require(addresses.length <= 255);
        require(_amount <= _remainingAmount);
        _amount = _amount * 1e18;

        for (uint i = 0; i < addresses.length; i++) {
            require(_amount <= _remainingAmount);
            _CurrentDistribPublicSupply += _amount;
            balances[addresses[i]] += _amount;
            _totalSupply += _amount;
            Transfer(this, addresses[i], _amount);

        }

        if (_CurrentDistribPublicSupply >= _MaxDistribPublicSupply) {
            DistribStarted = false;
            IsDistribRunning = false;
        }
    }

    function distributeAmounts(address[] addresses, uint256[] amounts) onlyOwner public {

        uint256 _remainingAmount = _MaxDistribPublicSupply - _CurrentDistribPublicSupply;
        uint256 _amount;

        require(addresses.length <= 255);
        require(addresses.length == amounts.length);

        for (uint8 i = 0; i < addresses.length; i++) {
            _amount = amounts[i] * 1e18;
            require(_amount <= _remainingAmount);
            _CurrentDistribPublicSupply += _amount;
            balances[addresses[i]] += _amount;
            _totalSupply += _amount;
            Transfer(this, addresses[i], _amount);


            if (_CurrentDistribPublicSupply >= _MaxDistribPublicSupply) {
                DistribStarted = false;
                IsDistribRunning = false;
            }
        }
    }

    function BurnFSATokens(uint256 amount) public returns(bool success) {
        uint256 _amount = amount * 1e18;
        if (balances[msg.sender] >= _amount) {
            balances[msg.sender] -= _amount;
            _totalSupply -= _amount;
            Burn(msg.sender, _amount);
            Transfer(msg.sender, 0, _amount);
        } else {
            revert();
        }
        return true;
    }

    function totalSupply() public constant returns(uint256 totalSupplyValue) {
        return _totalSupply;
    }

    function MaxDistribPublicSupply_() public constant returns(uint256 MaxDistribPublicSupply) {
        return _MaxDistribPublicSupply;
    }

    function OwnerDistribSupply_() public constant returns(uint256 OwnerDistribSupply) {
        return _OwnerDistribSupply;
    }

    function CurrentDistribPublicSupply_() public constant returns(uint256 CurrentDistribPublicSupply) {
        return _CurrentDistribPublicSupply;
    }

    function RemainingTokensReceiverAddress() public constant returns(address remainingTokensReceiverAddress) {
        return _remainingTokensReceiverAddress;
    }

    function DistribFundsReceiverAddress() public constant returns(address DistribfundsReceiver) {
        return _DistribFundsReceiverAddress;
    }

    function Owner() public constant returns(address ownerAddress) {
        return owner;
    }

    function SetupDone() public constant returns(bool setupDoneFlag) {
        return setupDone;
    }

    function IsDistribRunningFalg_() public constant returns(bool IsDistribRunningFalg) {
        return IsDistribRunning;
    }

    function IsDistribStarted() public constant returns(bool IsDistribStartedFlag) {
        return DistribStarted;
    }

    function balanceOf(address _owner) public constant returns(uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) public returns(bool success) {
        if (balances[msg.sender] >= _amount &&
            _amount > 0 &&
            balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public returns(bool success) {
        if (balances[_from] >= _amount &&
            allowed[_from][msg.sender] >= _amount &&
            _amount > 0 &&
            balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _amount) public returns(bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }
}