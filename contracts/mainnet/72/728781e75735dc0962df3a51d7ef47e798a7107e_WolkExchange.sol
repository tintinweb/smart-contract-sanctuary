pragma solidity ^0.4.16;

// SafeMath Taken From FirstBlood
contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}

// Ownership
contract Owned {

    address public owner;
    address public newOwner;
    modifier onlyOwner { assert(msg.sender == owner); _; }

    event OwnerUpdate(address _prevOwner, address _newOwner);

    function Owned() {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

// ERC20 Interface
contract ERC20 {
    function totalSupply() constant returns (uint _totalSupply);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
    function approve(address _spender, uint _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

// ERC20Token
contract ERC20Token is ERC20, SafeMath {

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalTokens; 

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = safeSub(balances[msg.sender], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        var _allowance = allowed[_from][msg.sender];
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = safeAdd(balances[_to], _value);
            balances[_from] = safeSub(balances[_from], _value);
            allowed[_from][msg.sender] = safeSub(_allowance, _value);
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function totalSupply() constant returns (uint256) {
        return totalTokens;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract Wolk is ERC20Token, Owned {

    // TOKEN INFO
    string  public constant name = "Wolk Protocol Token";
    string  public constant symbol = "WOLK";
    uint256 public constant decimals = 18;

    // RESERVE
    uint256 public reserveBalance = 0; 
    uint8  public constant percentageETHReserve = 15;

    // CONTRACT OWNER
    address public multisigWallet;


    // WOLK SETTLERS
    mapping (address => bool) settlers;
    modifier onlySettler { assert(settlers[msg.sender] == true); _; }

    // TOKEN GENERATION CONTROL
    address public wolkSale;
    bool    public allSaleCompleted = false;
    bool    public openSaleCompleted = false;
    modifier isTransferable { require(allSaleCompleted); _; }
    modifier onlyWolk { assert(msg.sender == wolkSale); _; }

    // TOKEN GENERATION EVENTLOG
    event WolkCreated(address indexed _to, uint256 _tokenCreated);
    event WolkDestroyed(address indexed _from, uint256 _tokenDestroyed);
    event LogRefund(address indexed _to, uint256 _value);
}

contract WolkTGE is Wolk {

    // TOKEN GENERATION EVENT
    mapping (address => uint256) contribution;
    mapping (address => uint256) presaleLimit;
    mapping (address => bool) presaleContributor;
    uint256 public constant tokenGenerationMin = 50 * 10**6 * 10**decimals;
    uint256 public constant tokenGenerationMax = 150 * 10**6 * 10**decimals;
    uint256 public presale_start_block; 
    uint256 public start_block;
    uint256 public end_block;

    // @param _presaleStartBlock
    // @param _startBlock
    // @param _endBlock
    // @param _wolkWallet
    // @param _wolkSale
    // @return success
    // @dev Wolk Genesis Event [only accessible by Contract Owner]
    function wolkGenesis(uint256 _presaleStartBlock, uint256 _startBlock, uint256 _endBlock, address _wolkWallet, address _wolkSale) onlyOwner returns (bool success){
        require((totalTokens < 1) && (block.number <= _startBlock) && (_endBlock > _startBlock) && (_startBlock > _presaleStartBlock));
        presale_start_block = _presaleStartBlock;
        start_block = _startBlock;
        end_block = _endBlock;
        multisigWallet = _wolkWallet;
        wolkSale = _wolkSale;
        settlers[msg.sender] = true;
        return true;
    }

    // @param _presaleParticipants
    // @return success
    // @dev Adds addresses that are allowed to take part in presale [only accessible by current Contract Owner]
    function addParticipant(address[] _presaleParticipants, uint256[] _contributionLimits) onlyOwner returns (bool success) {
        require(_presaleParticipants.length == _contributionLimits.length);         
        for (uint cnt = 0; cnt < _presaleParticipants.length; cnt++){           
            presaleContributor[_presaleParticipants[cnt]] = true;
            presaleLimit[_presaleParticipants[cnt]] =  safeMul(_contributionLimits[cnt], 10**decimals);       
        }
        return true;
    } 

    // @param _presaleParticipants
    // @return success
    // @dev Revoke designated presale contributors [only accessible by current Contract Owner]
    function removeParticipant(address[] _presaleParticipants) onlyOwner returns (bool success){         
        for (uint cnt = 0; cnt < _presaleParticipants.length; cnt++){           
            presaleContributor[_presaleParticipants[cnt]] = false;
            presaleLimit[_presaleParticipants[cnt]] = 0;      
        }
        return true;
    }

    // @param _participant
    // @return remainingAllocation
    // @dev return PresaleLimit allocated to given address
    function participantBalance(address _participant) constant returns (uint256 remainingAllocation) {
        return presaleLimit[_participant];
    }
    

    // @param _participant
    // @dev use tokenGenerationEvent to handle Pre-sale and Open-sale
    function tokenGenerationEvent(address _participant) payable external {
        require( presaleContributor[_participant] && !openSaleCompleted && !allSaleCompleted && (block.number <= end_block) && msg.value > 0);

        /* Early Participation Discount (rounded to the nearest integer)
        ---------------------------------
        | Token Issued | Rate | Discount|
        ---------------------------------
        |   0  -  50MM | 1177 |  15.0%  |
        | 50MM -  60MM | 1143 |  12.5%  |
        | 60MM -  70MM | 1111 |  10.0%  |
        | 70MM -  80MM | 1081 |   7.5%  |
        | 80MM -  90MM | 1053 |   5.0%  |         
        | 90MM - 100MM | 1026 |   2.5%  |
        |    100MM+    | 1000 |   0.0%  |
        ---------------------------------
        */

        uint256 rate = 1000;  // Default Rate

        if ( totalTokens < (50 * 10**6 * 10**decimals) ) {  
            rate = 1177;
        } else if ( totalTokens < (60 * 10**6 * 10**decimals) ) {  
            rate = 1143;
        } else if ( totalTokens < (70 * 10**6 * 10**decimals) ) {  
            rate = 1111;
        } else if ( totalTokens < (80 * 10**6 * 10**decimals) ) {  
            rate = 1081;
        } else if ( totalTokens < (90 * 10**6 * 10**decimals) ) {  
            rate = 1053;
        } else if ( totalTokens < (100 * 10**6 * 10**decimals) ) {  
            rate = 1026;
        }else{
            rate = 1000;
        }

        if ((block.number < start_block) && (block.number >= presale_start_block))  { 
            require(presaleLimit[_participant] >= msg.value);
            presaleLimit[_participant] = safeSub(presaleLimit[_participant], msg.value);
        } else {
            require(block.number >= start_block) ;
        }

        uint256 tokens = safeMul(msg.value, rate);
        uint256 checkedSupply = safeAdd(totalTokens, tokens);
        require(checkedSupply <= tokenGenerationMax);

        totalTokens = checkedSupply;
        Transfer(address(this), _participant, tokens);
        balances[_participant] = safeAdd(balances[_participant], tokens);
        contribution[_participant] = safeAdd(contribution[_participant], msg.value);
        WolkCreated(_participant, tokens); // logs token creation
    }


    // @dev If Token Generation Minimum is Not Met, TGE Participants can call this func and request for refund
    function refund() external {
        require((contribution[msg.sender] > 0) && (!allSaleCompleted) && (totalTokens < tokenGenerationMin) && (block.number > end_block));
        uint256 tokenBalance = balances[msg.sender];
        uint256 refundBalance = contribution[msg.sender];
        balances[msg.sender] = 0;
        contribution[msg.sender] = 0;
        totalTokens = safeSub(totalTokens, tokenBalance);
        WolkDestroyed(msg.sender, tokenBalance);
        LogRefund(msg.sender, refundBalance);
        msg.sender.transfer(refundBalance); 
    }

    // @dev Finalizing the Open-Sale for Token Generation Event. 15% of Eth will be kept in contract to provide liquidity
    function finalizeOpenSale() onlyOwner {
        require((!openSaleCompleted) && (totalTokens >= tokenGenerationMin));
        openSaleCompleted = true;
        end_block = block.number;
        reserveBalance = safeDiv(safeMul(totalTokens, percentageETHReserve), 100000);
        var withdrawalBalance = safeSub(this.balance, reserveBalance);
        msg.sender.transfer(withdrawalBalance);
    }

    // @dev Finalizing the Private-Sale. Entire Eth will be kept in contract to provide liquidity. This func will conclude the entire sale.
    function finalize() onlyWolk payable external {
        require((openSaleCompleted) && (!allSaleCompleted));                                                                                                    
        uint256 privateSaleTokens =  safeDiv(safeMul(msg.value, 100000), percentageETHReserve);
        uint256 checkedSupply = safeAdd(totalTokens, privateSaleTokens);                                                                                                
        totalTokens = checkedSupply;                                                                                                                         
        reserveBalance = safeAdd(reserveBalance, msg.value);                                                                                                 
        Transfer(address(this), wolkSale, privateSaleTokens);                                                                                                              
        balances[wolkSale] = safeAdd(balances[wolkSale], privateSaleTokens);                                                                                                  
        WolkCreated(wolkSale, privateSaleTokens); // logs token creation for Presale events                                                                                                 
        allSaleCompleted = true;                                                                                                                                
    }
}

contract IBurnFormula {
    function calculateWolkToBurn(uint256 _value) public constant returns (uint256);
}

contract IFeeFormula {
    function calculateProviderFee(uint256 _value) public constant returns (uint256);
}

contract WolkProtocol is Wolk {

    // WOLK NETWORK PROTOCOL
    address public burnFormula;
    bool    public settlementIsRunning = true;
    uint256 public burnBasisPoints = 500;  // Burn rate (in BP) when Service Provider withdraws from data buyers&#39; accounts
    mapping (address => mapping (address => bool)) authorized; // holds which accounts have approved which Service Providers
    mapping (address => uint256) feeBasisPoints;   // Fee (in BP) earned by Service Provider when depositing to data seller
    mapping (address => address) feeFormulas;      // Provider&#39;s customizable Fee mormula
    modifier isSettleable { require(settlementIsRunning); _; }


    // WOLK PROTOCOL Events:
    event AuthorizeServiceProvider(address indexed _owner, address _serviceProvider);
    event DeauthorizeServiceProvider(address indexed _owner, address _serviceProvider);
    event SetServiceProviderFee(address indexed _serviceProvider, uint256 _feeBasisPoints);
    event BurnTokens(address indexed _from, address indexed _serviceProvider, uint256 _value);

    // @param  _burnBasisPoints
    // @return success
    // @dev Set BurnRate on Wolk Protocol -- only Wolk can set this, affects Service Provider settleBuyer
    function setBurnRate(uint256 _burnBasisPoints) onlyOwner returns (bool success) {
        require((_burnBasisPoints > 0) && (_burnBasisPoints <= 1000));
        burnBasisPoints = _burnBasisPoints;
        return true;
    }
    
    // @param  _newBurnFormula
    // @return success
    // @dev Set the formula to use for burning -- only Wolk  can set this
    function setBurnFormula(address _newBurnFormula) onlyOwner returns (bool success){
        uint256 testBurning = estWolkToBurn(_newBurnFormula, 10 ** 18);
        require(testBurning > (5 * 10 ** 13));
        burnFormula = _newBurnFormula;
        return true;
    }
    
    // @param  _newFeeFormula
    // @return success
    // @dev Set the formula to use for settlement -- settler can customize its fee  
    function setFeeFormula(address _newFeeFormula) onlySettler returns (bool success){
        uint256 testSettling = estProviderFee(_newFeeFormula, 10 ** 18);
        require(testSettling > (5 * 10 ** 13));
        feeFormulas[msg.sender] = _newFeeFormula;
        return true;
    }
    
    // @param  _isRunning
    // @return success
    // @dev upating settlement status -- only Wolk can set this
    function updateSettlementStatus(bool _isRunning) onlyOwner returns (bool success){
        settlementIsRunning = _isRunning;
        return true;
    }
    
    // @param  _serviceProvider
    // @param  _feeBasisPoints
    // @return success
    // @dev Set Service Provider fee -- only Contract Owner can do this, affects Service Provider settleSeller
    function setServiceFee(address _serviceProvider, uint256 _feeBasisPoints) onlyOwner returns (bool success) {
        if (_feeBasisPoints <= 0 || _feeBasisPoints > 4000){
            // revoke Settler privilege
            settlers[_serviceProvider] = false;
            feeBasisPoints[_serviceProvider] = 0;
            return false;
        }else{
            feeBasisPoints[_serviceProvider] = _feeBasisPoints;
            settlers[_serviceProvider] = true;
            SetServiceProviderFee(_serviceProvider, _feeBasisPoints);
            return true;
        }
    }

    // @param  _serviceProvider
    // @return _feeBasisPoints
    // @dev Check service Fee (in BP) for a given provider
    function checkServiceFee(address _serviceProvider) constant returns (uint256 _feeBasisPoints) {
        return feeBasisPoints[_serviceProvider];
    }

    // @param _serviceProvider
    // @return _formulaAddress
    // @dev Returns the contract address of the Service Provider&#39;s fee formula
    function checkFeeSchedule(address _serviceProvider) constant returns (address _formulaAddress) {
        return feeFormulas[_serviceProvider];
    }
    
    // @param _value
    // @return wolkBurnt
    // @dev Returns estimate of Wolk to burn 
    function estWolkToBurn(address _burnFormula, uint256 _value) constant internal returns (uint256){
        if(_burnFormula != 0x0){
            uint256 wolkBurnt = IBurnFormula(_burnFormula).calculateWolkToBurn(_value);
            return wolkBurnt;    
        }else{
            return 0; 
        }
    }
    
    // @param _value
    // @param _serviceProvider
    // @return estFee
    // @dev Returns estimate of Service Provider&#39;s fee 
    function estProviderFee(address _serviceProvider, uint256 _value) constant internal returns (uint256){
        address ProviderFeeFormula = feeFormulas[_serviceProvider];
        if (ProviderFeeFormula != 0x0){
            uint256 estFee = IFeeFormula(ProviderFeeFormula).calculateProviderFee(_value);
            return estFee;      
        }else{
            return 0;  
        }
    }
    
    // @param  _buyer
    // @param  _value
    // @return success
    // @dev Service Provider Settlement with Buyer: a small percent is burnt (set in setBurnRate, stored in burnBasisPoints) when funds are transferred from buyer to Service Provider [only accessible by settlers]
    function settleBuyer(address _buyer, uint256 _value) onlySettler isSettleable returns (bool success) {
        require((burnBasisPoints > 0) && (burnBasisPoints <= 1000) && authorized[_buyer][msg.sender]); // Buyer must authorize Service Provider 
        require(balances[_buyer] >= _value && _value > 0);
        var WolkToBurn = estWolkToBurn(burnFormula, _value);
        var burnCap = safeDiv(safeMul(_value, burnBasisPoints), 10000); //can not burn more than this

        // If burn formula not found, use default burn rate. If Est to burn exceeds BurnCap, cut back to the cap
        if (WolkToBurn < 1) WolkToBurn = burnCap;
        if (WolkToBurn > burnCap) WolkToBurn = burnCap;
            
        var transferredToServiceProvider = safeSub(_value, WolkToBurn);
        balances[_buyer] = safeSub(balances[_buyer], _value);
        balances[msg.sender] = safeAdd(balances[msg.sender], transferredToServiceProvider);
        totalTokens = safeSub(totalTokens, WolkToBurn);
        Transfer(_buyer, msg.sender, transferredToServiceProvider);
        Transfer(_buyer, 0x00000000000000000000, WolkToBurn);
        BurnTokens(_buyer, msg.sender, WolkToBurn);
        return true;
    } 

    // @param  _seller
    // @param  _value
    // @return success
    // @dev Service Provider Settlement with Seller: a small percent is kept by Service Provider (set in setServiceFee, stored in feeBasisPoints) when funds are transferred from Service Provider to seller [only accessible by settlers]
    function settleSeller(address _seller, uint256 _value) onlySettler isSettleable returns (bool success) {
        // Service Providers have a % max fee (e.g. 20%)
        var serviceProviderBP = feeBasisPoints[msg.sender];
        require((serviceProviderBP > 0) && (serviceProviderBP <= 4000) && (_value > 0));
        var seviceFee = estProviderFee(msg.sender, _value);
        var Maximumfee = safeDiv(safeMul(_value, serviceProviderBP), 10000);
        
        // If provider&#39;s fee formula not set, use default burn rate. If Est fee exceeds Maximumfee, cut back to the fee
        if (seviceFee < 1) seviceFee = Maximumfee;  
        if (seviceFee > Maximumfee) seviceFee = Maximumfee;
        var transferredToSeller = safeSub(_value, seviceFee);
        require(balances[msg.sender] >= transferredToSeller );
        balances[_seller] = safeAdd(balances[_seller], transferredToSeller);
        Transfer(msg.sender, _seller, transferredToSeller);
        return true;
    }

    // @param _providerToAdd
    // @return success
    // @dev Buyer authorizes the Service Provider (to call settleBuyer). For security reason, _providerToAdd needs to be whitelisted by Wolk Inc first
    function authorizeProvider(address _providerToAdd) returns (bool success) {
        require(settlers[_providerToAdd]);
        authorized[msg.sender][_providerToAdd] = true;
        AuthorizeServiceProvider(msg.sender, _providerToAdd);
        return true;
    }

    // @param _providerToRemove
    // @return success
    // @dev Buyer deauthorizes the Service Provider (from calling settleBuyer)
    function deauthorizeProvider(address _providerToRemove) returns (bool success) {
        authorized[msg.sender][_providerToRemove] = false;
        DeauthorizeServiceProvider(msg.sender, _providerToRemove);
        return true;
    }

    // @param _owner
    // @param _serviceProvider
    // @return authorizationStatus
    // @dev Check authorization between account and Service Provider
    function checkAuthorization(address _owner, address _serviceProvider) constant returns (bool authorizationStatus) {
        return authorized[_owner][_serviceProvider];
    }

    // @param _owner
    // @param _providerToAdd
    // @return authorizationStatus
    // @dev Grant authorization between account and Service Provider on buyers&#39; behalf [only accessible by Contract Owner]
    // @note Explicit permission from balance owner MUST be obtained beforehand
    function grantService(address _owner, address _providerToAdd) onlyOwner returns (bool authorizationStatus) {
        var isPreauthorized = authorized[_owner][msg.sender];
        if (isPreauthorized && settlers[_providerToAdd]) {
            authorized[_owner][_providerToAdd] = true;
            AuthorizeServiceProvider(msg.sender, _providerToAdd);
            return true;
        }else{
            return false;
        }
    }

    // @param _owner
    // @param _providerToRemove
    // @return authorization_status
    // @dev Revoke authorization between account and Service Provider on buyers&#39; behalf [only accessible by Contract Owner]
    // @note Explicit permission from balance owner are NOT required for disabling ill-intent Service Provider
    function removeService(address _owner, address _providerToRemove) onlyOwner returns (bool authorizationStatus) {
        authorized[_owner][_providerToRemove] = false;
        DeauthorizeServiceProvider(_owner, _providerToRemove);
        return true;
    }
}

// Taken from https://github.com/bancorprotocol/contracts/blob/master/solidity/contracts/BancorFormula.sol
contract IBancorFormula {
    function calculatePurchaseReturn(uint256 _supply, uint256 _reserveBalance, uint8 _reserveRatio, uint256 _depositAmount) public constant returns (uint256);
    function calculateSaleReturn(uint256 _supply, uint256 _reserveBalance, uint8 _reserveRatio, uint256 _sellAmount) public constant returns (uint256);
}

contract WolkExchange is WolkProtocol, WolkTGE {

    uint256 public maxPerExchangeBP = 50;
    address public exchangeFormula;
    bool    public exchangeIsRunning = false;
    modifier isExchangable { require(exchangeIsRunning && allSaleCompleted); _; }
    
    // @param  _newExchangeformula
    // @return success
    // @dev Set the bancor formula to use -- only Wolk Inc can set this
    function setExchangeFormula(address _newExchangeformula) onlyOwner returns (bool success){
        require(sellWolkEstimate(10**decimals, _newExchangeformula) > 0);
        require(purchaseWolkEstimate(10**decimals, _newExchangeformula) > 0);
        exchangeIsRunning = false;
        exchangeFormula = _newExchangeformula;
        return true;
    }
    
    // @param  _isRunning
    // @return success
    // @dev upating exchange status -- only Wolk Inc can set this
    function updateExchangeStatus(bool _isRunning) onlyOwner returns (bool success){
        if (_isRunning){
            require(sellWolkEstimate(10**decimals, exchangeFormula) > 0);
            require(purchaseWolkEstimate(10**decimals, exchangeFormula) > 0);   
        }
        exchangeIsRunning = _isRunning;
        return true;
    }
    
    // @param  _maxPerExchange
    // @return success
    // @dev Set max sell token amount per transaction -- only Wolk Inc can set this
    function setMaxPerExchange(uint256 _maxPerExchange) onlyOwner returns (bool success) {
        require((_maxPerExchange >= 10) && (_maxPerExchange <= 100));
        maxPerExchangeBP = _maxPerExchange;
        return true;
    }

    // @return Estimated Liquidation Cap
    // @dev Liquidation Cap per transaction is used to ensure proper price discovery for Wolk Exchange 
    function estLiquidationCap() public constant returns (uint256) {
        if (openSaleCompleted){
            var liquidationMax  = safeDiv(safeMul(totalTokens, maxPerExchangeBP), 10000);
            if (liquidationMax < 100 * 10**decimals){ 
                liquidationMax = 100 * 10**decimals;
            }
            return liquidationMax;   
        }else{
            return 0;
        }
    }

    function sellWolkEstimate(uint256 _wolkAmountest, address _formula) internal returns(uint256) {
        uint256 ethReceivable =  IBancorFormula(_formula).calculateSaleReturn(totalTokens, reserveBalance, percentageETHReserve, _wolkAmountest);
        return ethReceivable;
    }
    
    function purchaseWolkEstimate(uint256 _ethAmountest, address _formula) internal returns(uint256) {
        uint256 wolkReceivable = IBancorFormula(_formula).calculatePurchaseReturn(totalTokens, reserveBalance, percentageETHReserve, _ethAmountest);
        return wolkReceivable;
    }
    
    // @param _wolkAmount
    // @return ethReceivable
    // @dev send Wolk into contract in exchange for eth, at an exchange rate based on the Bancor Protocol derivation and decrease totalSupply accordingly
    function sellWolk(uint256 _wolkAmount) isExchangable() returns(uint256) {
        uint256 sellCap = estLiquidationCap();
        require((balances[msg.sender] >= _wolkAmount));
        require(sellCap >= _wolkAmount);
        uint256 ethReceivable = sellWolkEstimate(_wolkAmount,exchangeFormula);
        require(this.balance > ethReceivable);
        balances[msg.sender] = safeSub(balances[msg.sender], _wolkAmount);
        totalTokens = safeSub(totalTokens, _wolkAmount);
        reserveBalance = safeSub(this.balance, ethReceivable);
        WolkDestroyed(msg.sender, _wolkAmount);
        Transfer(msg.sender, 0x00000000000000000000, _wolkAmount);
        msg.sender.transfer(ethReceivable);
        return ethReceivable;     
    }

    // @return wolkReceivable    
    // @dev send eth into contract in exchange for Wolk tokens, at an exchange rate based on the Bancor Protocol derivation and increase totalSupply accordingly
    function purchaseWolk(address _buyer) isExchangable() payable returns(uint256){
        require(msg.value > 0);
        uint256 wolkReceivable = purchaseWolkEstimate(msg.value, exchangeFormula);
        require(wolkReceivable > 0);
        totalTokens = safeAdd(totalTokens, wolkReceivable);
        balances[_buyer] = safeAdd(balances[_buyer], wolkReceivable);
        reserveBalance = safeAdd(reserveBalance, msg.value);
        WolkCreated(_buyer, wolkReceivable);
        Transfer(address(this),_buyer,wolkReceivable);
        return wolkReceivable;
    }

    // @dev  fallback function for purchase
    // @note Automatically fallback to tokenGenerationEvent before sale is completed. After the token generation event, fallback to purchaseWolk. Liquidity exchange will be enabled through updateExchangeStatus  
    function () payable {
        require(msg.value > 0);
        if(!openSaleCompleted){
            this.tokenGenerationEvent.value(msg.value)(msg.sender);
        }else if (block.number >= end_block){
            this.purchaseWolk.value(msg.value)(msg.sender);
        }else{
            revert();
        }
    }
}