pragma solidity ^0.4.11;

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

// ERC20 Interface
contract ERC20 {
    function totalSupply() constant returns (uint totalSupply);
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
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract Wolk is ERC20Token {

    // TOKEN INFO
    string  public constant name = "Wolk Protocol Token";
    string  public constant symbol = "WOLK";
    uint256 public constant decimals = 18;

    // RESERVE
    uint256 public reserveBalance = 0; 
    uint16  public constant percentageETHReserve = 20;

    // CONTRACT OWNER
    address public owner = msg.sender;      
    address public multisigWallet;
    modifier onlyOwner { assert(msg.sender == owner); _; }

    // TOKEN GENERATION EVENT
    mapping (address => uint256) contribution;
    uint256 public constant tokenGenerationMin = 50 * 10**6 * 10**decimals;
    uint256 public constant tokenGenerationMax = 500 * 10**6 * 10**decimals;
    uint256 public start_block; 
    uint256 public end_block;
    bool    public saleCompleted = false;
    modifier isTransferable { assert(saleCompleted); _; }

    // WOLK SETTLERS
    mapping (address => bool) settlers;
    modifier onlySettler { assert(settlers[msg.sender] == true); _; }

    // TOKEN GENERATION EVENTLOG
    event WolkCreated(address indexed _to, uint256 _tokenCreated);
    event WolkDestroyed(address indexed _from, uint256 _tokenDestroyed);
    event LogRefund(address indexed _to, uint256 _value);

    // @param _startBlock
    // @param _endBlock
    // @param _wolkWallet
    // @return success
    // @dev Wolk Genesis Event [only accessible by Contract Owner]
    function wolkGenesis(uint256 _startBlock, uint256 _endBlock, address _wolkWallet) onlyOwner returns (bool success){
        require( (totalTokens < 1) && (!settlers[msg.sender]) && (_endBlock > _startBlock) );
        start_block = _startBlock;
        end_block = _endBlock;
        multisigWallet = _wolkWallet;
        settlers[msg.sender] = true;
        return true;
    }

    // @param _newOwner
    // @return success
    // @dev Transfering Contract Ownership. [only accessible by current Contract Owner]
    function changeOwner(address _newOwner) onlyOwner returns (bool success){
        owner = _newOwner;
        settlers[_newOwner] = true;
        return true;
    }

    // @dev Token Generation Event for Wolk Protocol Token. TGE Participant send Eth into this func in exchange of Wolk Protocol Token
    function tokenGenerationEvent() payable external {
        require(!saleCompleted);
        require( (block.number >= start_block) && (block.number <= end_block) );
        uint256 tokens = safeMul(msg.value, 5*10**9); //exchange rate
        uint256 checkedSupply = safeAdd(totalTokens, tokens);
        require(checkedSupply <= tokenGenerationMax);
        totalTokens = checkedSupply;
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);  
        contribution[msg.sender] = safeAdd(contribution[msg.sender], msg.value);  
        WolkCreated(msg.sender, tokens); // logs token creation
    }

    // @dev If Token Generation Minimum is Not Met, TGE Participants can call this func and request for refund
    function refund() external {
        require( (contribution[msg.sender] > 0) && (!saleCompleted) && (totalTokens < tokenGenerationMin) && (block.number > end_block) );
        uint256 tokenBalance = balances[msg.sender];
        uint256 refundBalance = contribution[msg.sender];
        balances[msg.sender] = 0;
        contribution[msg.sender] = 0;
        totalTokens = safeSub(totalTokens, tokenBalance);
        WolkDestroyed(msg.sender, tokenBalance);
        LogRefund(msg.sender, refundBalance);
        msg.sender.transfer(refundBalance); 
    }

    // @dev Finalizing the Token Generation Event. 20% of Eth will be kept in contract to provide liquidity
    function finalize() onlyOwner {
        require( (!saleCompleted) && (totalTokens >= tokenGenerationMin) );
        saleCompleted = true;
        end_block = block.number;
        reserveBalance = safeDiv(safeMul(this.balance, percentageETHReserve), 100);
        var withdrawalBalance = safeSub(this.balance, reserveBalance);
        msg.sender.transfer(withdrawalBalance);
    }
}

contract WolkProtocol is Wolk {

    // WOLK NETWORK PROTOCOL
    uint256 public burnBasisPoints = 500;  // Burn rate (in BP) when Service Provider withdraws from data buyers&#39; accounts
    mapping (address => mapping (address => bool)) authorized; // holds which accounts have approved which Service Providers
    mapping (address => uint256) feeBasisPoints;   // Fee (in BP) earned by Service Provider when depositing to data seller 

    // WOLK PROTOCOL Events:
    event AuthorizeServiceProvider(address indexed _owner, address _serviceProvider);
    event DeauthorizeServiceProvider(address indexed _owner, address _serviceProvider);
    event SetServiceProviderFee(address indexed _serviceProvider, uint256 _feeBasisPoints);
    event BurnTokens(address indexed _from, address indexed _serviceProvider, uint256 _value);

    // @param  _burnBasisPoints
    // @return success
    // @dev Set BurnRate on Wolk Protocol -- only Wolk Foundation can set this, affects Service Provider settleBuyer
    function setBurnRate(uint256 _burnBasisPoints) onlyOwner returns (bool success) {
        require( (_burnBasisPoints > 0) && (_burnBasisPoints <= 1000) );
        burnBasisPoints = _burnBasisPoints;
        return true;
    }

    // @param  _serviceProvider
    // @param  _feeBasisPoints
    // @return success
    // @dev Set Service Provider fee -- only Contract Owner can do this, affects Service Provider settleSeller
    function setServiceFee(address _serviceProvider, uint256 _feeBasisPoints) onlyOwner returns (bool success) {
        if ( _feeBasisPoints <= 0 || _feeBasisPoints > 4000){
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
    // @dev Check service ee (in BP) for a given provider
    function checkServiceFee(address _serviceProvider) constant returns (uint256 _feeBasisPoints) {
        return feeBasisPoints[_serviceProvider];
    }

    // @param  _buyer
    // @param  _value
    // @return success
    // @dev Service Provider Settlement with Buyer: a small percent is burnt (set in setBurnRate, stored in burnBasisPoints) when funds are transferred from buyer to Service Provider [only accessible by settlers]
    function settleBuyer(address _buyer, uint256 _value) onlySettler returns (bool success) {
        require( (burnBasisPoints > 0) && (burnBasisPoints <= 1000) && authorized[_buyer][msg.sender] ); // Buyer must authorize Service Provider 
        if ( balances[_buyer] >= _value && _value > 0) {
            var burnCap = safeDiv(safeMul(_value, burnBasisPoints), 10000);
            var transferredToServiceProvider = safeSub(_value, burnCap);
            balances[_buyer] = safeSub(balances[_buyer], _value);
            balances[msg.sender] = safeAdd(balances[msg.sender], transferredToServiceProvider);
            totalTokens = safeSub(totalTokens, burnCap);
            Transfer(_buyer, msg.sender, transferredToServiceProvider);
            BurnTokens(_buyer, msg.sender, burnCap);
            return true;
        } else {
            return false;
        }
    } 

    // @param  _seller
    // @param  _value
    // @return success
    // @dev Service Provider Settlement with Seller: a small percent is kept by Service Provider (set in setServiceFee, stored in feeBasisPoints) when funds are transferred from Service Provider to seller [only accessible by settlers]
    function settleSeller(address _seller, uint256 _value) onlySettler returns (bool success) {
        // Service Providers have a % fee for Sellers (e.g. 20%)
        var serviceProviderBP = feeBasisPoints[msg.sender];
        require( (serviceProviderBP > 0) && (serviceProviderBP <= 4000) );
        if (balances[msg.sender] >= _value && _value > 0) {
            var fee = safeDiv(safeMul(_value, serviceProviderBP), 10000);
            var transferredToSeller = safeSub(_value, fee);
            balances[_seller] = safeAdd(balances[_seller], transferredToSeller);
            Transfer(msg.sender, _seller, transferredToSeller);
            return true;
        } else {
            return false;
        }
    }

    // @param _providerToAdd
    // @return success
    // @dev Buyer authorizes the Service Provider (to call settleBuyer). For security reason, _providerToAdd needs to be whitelisted by Wolk Foundation first
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
        if (isPreauthorized && settlers[_providerToAdd] ) {
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

contract BancorFormula is SafeMath {

    // Taken from https://github.com/bancorprotocol/contracts/blob/master/solidity/contracts/BancorFormula.sol
    uint8 constant PRECISION   = 32;  // fractional bits
    uint256 constant FIXED_ONE = uint256(1) << PRECISION; // 0x100000000
    uint256 constant FIXED_TWO = uint256(2) << PRECISION; // 0x200000000
    uint256 constant MAX_VAL   = uint256(1) << (256 - PRECISION); // 0x0000000100000000000000000000000000000000000000000000000000000000

    /**
        @dev given a token supply, reserve, CRR and a deposit amount (in the reserve token), calculates the return for a given change (in the main token)

        Formula:
        Return = _supply * ((1 + _depositAmount / _reserveBalance) ^ (_reserveRatio / 100) - 1)

        @param _supply             token total supply
        @param _reserveBalance     total reserve
        @param _reserveRatio       constant reserve ratio, 1-100
        @param _depositAmount      deposit amount, in reserve token

        @return purchase return amount
    */
    function calculatePurchaseReturn(uint256 _supply, uint256 _reserveBalance, uint16 _reserveRatio, uint256 _depositAmount) public constant returns (uint256) {
        // validate input
        require(_supply != 0 && _reserveBalance != 0 && _reserveRatio > 0 && _reserveRatio <= 100);

        // special case for 0 deposit amount
        if (_depositAmount == 0)
            return 0;

        uint256 baseN = safeAdd(_depositAmount, _reserveBalance);
        uint256 temp;

        // special case if the CRR = 100
        if (_reserveRatio == 100) {
            temp = safeMul(_supply, baseN) / _reserveBalance;
            return safeSub(temp, _supply); 
        }

        uint256 resN = power(baseN, _reserveBalance, _reserveRatio, 100);

        temp = safeMul(_supply, resN) / FIXED_ONE;

        uint256 result =  safeSub(temp, _supply);
        // from the result, we deduct the minimal increment, which is a         
        // function of S and precision.       
        return safeSub(result, _supply / 0x100000000);
     }

    /**
        @dev given a token supply, reserve, CRR and a sell amount (in the main token), calculates the return for a given change (in the reserve token)

        Formula:
        Return = _reserveBalance * (1 - (1 - _sellAmount / _supply) ^ (1 / (_reserveRatio / 100)))

        @param _supply             token total supply
        @param _reserveBalance     total reserve
        @param _reserveRatio       constant reserve ratio, 1-100
        @param _sellAmount         sell amount, in the token itself

        @return sale return amount
    */
    function calculateSaleReturn(uint256 _supply, uint256 _reserveBalance, uint16 _reserveRatio, uint256 _sellAmount) public constant returns (uint256) {
        // validate input
        require(_supply != 0 && _reserveBalance != 0 && _reserveRatio > 0 && _reserveRatio <= 100 && _sellAmount <= _supply);

        // special case for 0 sell amount
        if (_sellAmount == 0)
            return 0;

        uint256 baseN = safeSub(_supply, _sellAmount);
        uint256 temp1;
        uint256 temp2;

        // special case if the CRR = 100
        if (_reserveRatio == 100) {
            temp1 = safeMul(_reserveBalance, _supply);
            temp2 = safeMul(_reserveBalance, baseN);
            return safeSub(temp1, temp2) / _supply;
        }

        // special case for selling the entire supply
        if (_sellAmount == _supply)
            return _reserveBalance;

        uint256 resN = power(_supply, baseN, 100, _reserveRatio);

        temp1 = safeMul(_reserveBalance, resN);
        temp2 = safeMul(_reserveBalance, FIXED_ONE);

        uint256 result = safeSub(temp1, temp2) / resN;

        // from the result, we deduct the minimal increment, which is a         
        // function of R and precision.       
        return safeSub(result, _reserveBalance / 0x100000000);
    }

    /**
        @dev Calculate (_baseN / _baseD) ^ (_expN / _expD)
        Returns result upshifted by PRECISION

        This method is overflow-safe
    */ 
    function power(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) internal returns (uint256 resN) {
        uint256 logbase = ln(_baseN, _baseD);
        // Not using safeDiv here, since safeDiv protects against
        // precision loss. It’s unavoidable, however
        // Both `ln` and `fixedExp` are overflow-safe. 
        resN = fixedExp(safeMul(logbase, _expN) / _expD);
        return resN;
    }
    
    /**
        input range: 
            - numerator: [1, uint256_max >> PRECISION]    
            - denominator: [1, uint256_max >> PRECISION]
        output range:
            [0, 0x9b43d4f8d6]

        This method asserts outside of bounds

    */
    function ln(uint256 _numerator, uint256 _denominator) internal returns (uint256) {
        // denominator > numerator: less than one yields negative values. Unsupported
        assert(_denominator <= _numerator);

        // log(1) is the lowest we can go
        assert(_denominator != 0 && _numerator != 0);

        // Upper 32 bits are scaled off by PRECISION
        assert(_numerator < MAX_VAL);
        assert(_denominator < MAX_VAL);

        return fixedLoge( (_numerator * FIXED_ONE) / _denominator);
    }

    /**
        input range: 
            [0x100000000,uint256_max]
        output range:
            [0, 0x9b43d4f8d6]

        This method asserts outside of bounds

    */
    function fixedLoge(uint256 _x) internal returns (uint256 logE) {
        /*
        Since `fixedLog2_min` output range is max `0xdfffffffff` 
        (40 bits, or 5 bytes), we can use a very large approximation
        for `ln(2)`. This one is used since it’s the max accuracy 
        of Python `ln(2)`

        0xb17217f7d1cf78 = ln(2) * (1 << 56)
        
        */
        //Cannot represent negative numbers (below 1)
        assert(_x >= FIXED_ONE);

        uint256 log2 = fixedLog2(_x);
        logE = (log2 * 0xb17217f7d1cf78) >> 56;
    }

    /**
        Returns log2(x >> 32) << 32 [1]
        So x is assumed to be already upshifted 32 bits, and 
        the result is also upshifted 32 bits. 
        
        [1] The function returns a number which is lower than the 
        actual value

        input-range : 
            [0x100000000,uint256_max]
        output-range: 
            [0,0xdfffffffff]

        This method asserts outside of bounds

    */
    function fixedLog2(uint256 _x) internal returns (uint256) {
        // Numbers below 1 are negative. 
        assert( _x >= FIXED_ONE);

        uint256 hi = 0;
        while (_x >= FIXED_TWO) {
            _x >>= 1;
            hi += FIXED_ONE;
        }

        for (uint8 i = 0; i < PRECISION; ++i) {
            _x = (_x * _x) / FIXED_ONE;
            if (_x >= FIXED_TWO) {
                _x >>= 1;
                hi += uint256(1) << (PRECISION - 1 - i);
            }
        }

        return hi;
    }

    /**
        fixedExp is a ‘protected’ version of `fixedExpUnsafe`, which 
        asserts instead of overflows
    */
    function fixedExp(uint256 _x) internal returns (uint256) {
        assert(_x <= 0x386bfdba29);
        return fixedExpUnsafe(_x);
    }

    /**
        fixedExp 
        Calculates e^x according to maclauren summation:

        e^x = 1+x+x^2/2!...+x^n/n!

        and returns e^(x>>32) << 32, that is, upshifted for accuracy

        Input range:
            - Function ok at    <= 242329958953 
            - Function fails at >= 242329958954

        This method is is visible for testcases, but not meant for direct use. 
 
        The values in this method been generated via the following python snippet: 

        def calculateFactorials():
            “”"Method to print out the factorials for fixedExp”“”

            ni = []
            ni.append( 295232799039604140847618609643520000000) # 34!
            ITERATIONS = 34
            for n in range( 1,  ITERATIONS,1 ) :
                ni.append(math.floor(ni[n - 1] / n))
            print( “\n        “.join([“xi = (xi * _x) >> PRECISION;\n        res += xi * %s;” % hex(int(x)) for x in ni]))

    */
    function fixedExpUnsafe(uint256 _x) internal returns (uint256) {
    
        uint256 xi = FIXED_ONE;
        uint256 res = 0xde1bc4d19efcac82445da75b00000000 * xi;

        xi = (xi * _x) >> PRECISION;
        res += xi * 0xde1bc4d19efcb0000000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x6f0de268cf7e58000000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x2504a0cd9a7f72000000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x9412833669fdc800000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x1d9d4d714865f500000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x4ef8ce836bba8c0000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xb481d807d1aa68000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x16903b00fa354d000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x281cdaac677b3400000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x402e2aad725eb80000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x5d5a6c9f31fe24000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x7c7890d442a83000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x9931ed540345280000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xaf147cf24ce150000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xbac08546b867d000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xbac08546b867d00000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xafc441338061b8000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x9c3cabbc0056e000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x839168328705c80000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x694120286c04a0000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x50319e98b3d2c400;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x3a52a1e36b82020;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x289286e0fce002;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x1b0c59eb53400;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x114f95b55400;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xaa7210d200;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x650139600;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x39b78e80;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x1fd8080;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x10fbc0;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x8c40;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x462;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x22;

        return res / 0xde1bc4d19efcac82445da75b00000000;
    }  
}

contract WolkExchange is WolkProtocol, BancorFormula {

    uint256 public maxPerExchangeBP = 50;

    // @param  _maxPerExchange
    // @return success
    // @dev Set max sell token amount per transaction -- only Wolk Foundation can set this
    function setMaxPerExchange(uint256 _maxPerExchange) onlyOwner returns (bool success) {
        require( (_maxPerExchange >= 10) && (_maxPerExchange <= 100) );
        maxPerExchangeBP = _maxPerExchange;
        return true;
    }

    // @return Estimated Liquidation Cap
    // @dev Liquidation Cap per transaction is used to ensure proper price discovery for Wolk Exchange 
    function EstLiquidationCap() public constant returns (uint256) {
        if (saleCompleted){
            var liquidationMax  = safeDiv(safeMul(totalTokens, maxPerExchangeBP), 10000);
            if (liquidationMax < 100 * 10**decimals){ 
                liquidationMax = 100 * 10**decimals;
            }
            return liquidationMax;   
        }else{
            return 0;
        }
    }

    // @param _wolkAmount
    // @return ethReceivable
    // @dev send Wolk into contract in exchange for eth, at an exchange rate based on the Bancor Protocol derivation and decrease totalSupply accordingly
    function sellWolk(uint256 _wolkAmount) isTransferable() external returns(uint256) {
        uint256 sellCap = EstLiquidationCap();
        uint256 ethReceivable = calculateSaleReturn(totalTokens, reserveBalance, percentageETHReserve, _wolkAmount);
        require( (sellCap >= _wolkAmount) && (balances[msg.sender] >= _wolkAmount) && (this.balance > ethReceivable) );
        balances[msg.sender] = safeSub(balances[msg.sender], _wolkAmount);
        totalTokens = safeSub(totalTokens, _wolkAmount);
        reserveBalance = safeSub(this.balance, ethReceivable);
        WolkDestroyed(msg.sender, _wolkAmount);
        msg.sender.transfer(ethReceivable);
        return ethReceivable;     
    }

    // @return wolkReceivable    
    // @dev send eth into contract in exchange for Wolk tokens, at an exchange rate based on the Bancor Protocol derivation and increase totalSupply accordingly
    function purchaseWolk() isTransferable() payable external returns(uint256){
        uint256 wolkReceivable = calculatePurchaseReturn(totalTokens, reserveBalance, percentageETHReserve, msg.value);
        totalTokens = safeAdd(totalTokens, wolkReceivable);
        balances[msg.sender] = safeAdd(balances[msg.sender], wolkReceivable);
        reserveBalance = safeAdd(reserveBalance, msg.value);
        WolkCreated(msg.sender, wolkReceivable);
        return wolkReceivable;
    }

    // @param _exactWolk
    // @return ethRefundable
    // @dev send eth into contract in exchange for exact amount of Wolk tokens with margin of error of no more than 1 Wolk. 
    // @note Purchase with the insufficient eth will be cancelled and returned; exceeding eth balanance from purchase, if any, will be returned.     
    function purchaseExactWolk(uint256 _exactWolk) isTransferable() payable external returns(uint256){
        uint256 wolkReceivable = calculatePurchaseReturn(totalTokens, reserveBalance, percentageETHReserve, msg.value);
        if (wolkReceivable < _exactWolk){
            // Cancel Insufficient Purchase
            revert();
            return msg.value;
        }else {
            var wolkDiff = safeSub(wolkReceivable, _exactWolk);
            uint256 ethRefundable = 0;
            // Refund if wolkDiff exceeds 1 Wolk
            if (wolkDiff < 10**decimals){
                // Credit Buyer Full amount if within margin of error
                totalTokens = safeAdd(totalTokens, wolkReceivable);
                balances[msg.sender] = safeAdd(balances[msg.sender], wolkReceivable);
                reserveBalance = safeAdd(reserveBalance, msg.value);
                WolkCreated(msg.sender, wolkReceivable);
                return 0;     
            }else{
                ethRefundable = calculateSaleReturn( safeAdd(totalTokens, wolkReceivable) , safeAdd(reserveBalance, msg.value), percentageETHReserve, wolkDiff);
                totalTokens = safeAdd(totalTokens, _exactWolk);
                balances[msg.sender] = safeAdd(balances[msg.sender], _exactWolk);
                reserveBalance = safeAdd(reserveBalance, safeSub(msg.value, ethRefundable));
                WolkCreated(msg.sender, _exactWolk);
                msg.sender.transfer(ethRefundable);
                return ethRefundable;
            }
        }
    }
}