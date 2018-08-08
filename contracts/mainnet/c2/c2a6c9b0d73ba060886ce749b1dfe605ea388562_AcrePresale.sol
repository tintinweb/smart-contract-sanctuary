pragma solidity 0.4.20;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        assert(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        assert(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        assert(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        assert(b > 0);
        c = a / b;
        assert(a == b * c + a % b);
    }
}

contract AcreConfig {
    using SafeMath for uint;
    
    uint internal constant TIME_FACTOR = 1 minutes;

    // Ownable
    uint internal constant OWNERSHIP_DURATION_TIME = 7; // 7 days
    
    // MultiOwnable
    uint8 internal constant MULTI_OWNER_COUNT = 5; // 5 accounts, exclude master
    
    // Lockable
    uint internal constant LOCKUP_DURATION_TIME = 365; // 365 days
    
    // AcreToken
    string internal constant TOKEN_NAME            = "TAA";
    string internal constant TOKEN_SYMBOL          = "TAA";
    uint8  internal constant TOKEN_DECIMALS        = 18;
    
    uint   internal constant INITIAL_SUPPLY        =   1*1e8 * 10 ** uint(TOKEN_DECIMALS); // supply
    uint   internal constant CAPITAL_SUPPLY        =  31*1e6 * 10 ** uint(TOKEN_DECIMALS); // supply
    uint   internal constant PRE_PAYMENT_SUPPLY    =  19*1e6 * 10 ** uint(TOKEN_DECIMALS); // supply
    uint   internal constant MAX_MINING_SUPPLY     =   4*1e8 * 10 ** uint(TOKEN_DECIMALS); // supply
    
    // Sale
    uint internal constant MIN_ETHER               = 1*1e17; // 0.1 ether
    uint internal constant EXCHANGE_RATE           = 1000;   // 1 eth = 1000 acre
    uint internal constant PRESALE_DURATION_TIME   = 15;     // 15 days 
    uint internal constant CROWDSALE_DURATION_TIME = 21;     // 21 days
    
    // helper
    function getDays(uint _time) internal pure returns(uint) {
        return SafeMath.div(_time, 1 days);
    }
    
    function getHours(uint _time) internal pure returns(uint) {
        return SafeMath.div(_time, 1 hours);
    }
    
    function getMinutes(uint _time) internal pure returns(uint) {
        return SafeMath.div(_time, 1 minutes);
    }
}

contract Ownable is AcreConfig {
    address public owner;
    address public reservedOwner;
    uint public ownershipDeadline;
    
    event ReserveOwnership(address indexed oldOwner, address indexed newOwner);
    event ConfirmOwnership(address indexed oldOwner, address indexed newOwner);
    event CancelOwnership(address indexed oldOwner, address indexed newOwner);
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    function reserveOwnership(address newOwner) onlyOwner public returns (bool success) {
        require(newOwner != address(0));
        ReserveOwnership(owner, newOwner);
        reservedOwner = newOwner;
		ownershipDeadline = SafeMath.add(now, SafeMath.mul(OWNERSHIP_DURATION_TIME, TIME_FACTOR));
        return true;
    }
    
    function confirmOwnership() onlyOwner public returns (bool success) {
        require(reservedOwner != address(0));
        require(now > ownershipDeadline);
        ConfirmOwnership(owner, reservedOwner);
        owner = reservedOwner;
        reservedOwner = address(0);
        return true;
    }
    
    function cancelOwnership() onlyOwner public returns (bool success) {
        require(reservedOwner != address(0));
        CancelOwnership(owner, reservedOwner);
        reservedOwner = address(0);
        return true;
    }
}

contract MultiOwnable is Ownable {
    address[] public owners;
    
    event GrantOwners(address indexed owner);
    event RevokeOwners(address indexed owner);
    
    modifier onlyMutiOwners {
        require(isExistedOwner(msg.sender));
        _;
    }
    
    modifier onlyManagers {
        require(isManageable(msg.sender));
        _;
    }
    
    function MultiOwnable() public {
        owners.length = MULTI_OWNER_COUNT;
    }
    
    function grantOwners(address _owner) onlyOwner public returns (bool success) {
        require(!isExistedOwner(_owner));
        require(isEmptyOwner());
        owners[getEmptyIndex()] = _owner;
        GrantOwners(_owner);
        return true;
    }

    function revokeOwners(address _owner) onlyOwner public returns (bool success) {
        require(isExistedOwner(_owner));
        owners[getOwnerIndex(_owner)] = address(0);
        RevokeOwners(_owner);
        return true;
    }
    
    // helper
    function isManageable(address _owner) internal constant returns (bool) {
        return isExistedOwner(_owner) || owner == _owner;
    }
    
    function isExistedOwner(address _owner) internal constant returns (bool) {
        for(uint8 i = 0; i < MULTI_OWNER_COUNT; ++i) {
            if(owners[i] == _owner) {
                return true;
            }
        }
    }
    
    function getOwnerIndex(address _owner) internal constant returns (uint) {
        for(uint8 i = 0; i < MULTI_OWNER_COUNT; ++i) {
            if(owners[i] == _owner) {
                return i;
            }
        }
    }
    
    function isEmptyOwner() internal constant returns (bool) {
        for(uint8 i = 0; i < MULTI_OWNER_COUNT; ++i) {
            if(owners[i] == address(0)) {
                return true;
            }
        }
    }
    
    function getEmptyIndex() internal constant returns (uint) {
        for(uint8 i = 0; i < MULTI_OWNER_COUNT; ++i) {
            if(owners[i] == address(0)) {
                return i;
            }
        }
    }
}

contract Pausable is MultiOwnable {
    bool public paused = false;
    
    event Pause();
    event Unpause();
    
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    modifier whenPaused() {
        require(paused);
        _;
    }
    
    modifier whenConditionalPassing() {
        if(!isManageable(msg.sender)) {
            require(!paused);
        }
        _;
    }
    
    function pause() onlyManagers whenNotPaused public returns (bool success) {
        paused = true;
        Pause();
        return true;
    }
  
    function unpause() onlyManagers whenPaused public returns (bool success) {
        paused = false;
        Unpause();
        return true;
    }
}

contract Lockable is Pausable {
    mapping (address => uint) public locked;
    
    event Lockup(address indexed target, uint startTime, uint deadline);
    
    function lockup(address _target) onlyOwner public returns (bool success) {
	    require(!isManageable(_target));
        locked[_target] = SafeMath.add(now, SafeMath.mul(LOCKUP_DURATION_TIME, TIME_FACTOR));
        Lockup(_target, now, locked[_target]);
        return true;
    }
    
    // helper
    function isLockup(address _target) internal constant returns (bool) {
        if(now <= locked[_target])
            return true;
    }
}

interface tokenRecipient { 
    function receiveApproval(address _from, uint _value, address _token, bytes _extraData) external; 
}

contract TokenERC20 {
    using SafeMath for uint;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    
    uint public totalSupply;
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    event ERC20Token(address indexed owner, string name, string symbol, uint8 decimals, uint supply);
    event Transfer(address indexed from, address indexed to, uint value);
    event TransferFrom(address indexed from, address indexed to, address indexed spender, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    function TokenERC20(
        string _tokenName,
        string _tokenSymbol,
        uint8 _tokenDecimals,
        uint _initialSupply
    ) public {
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _tokenDecimals;
        
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = totalSupply;
        
        ERC20Token(msg.sender, name, symbol, decimals, totalSupply);
    }

    function _transfer(address _from, address _to, uint _value) internal returns (bool success) {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        require(SafeMath.add(balanceOf[_to], _value) > balanceOf[_to]);
        uint previousBalances = SafeMath.add(balanceOf[_from], balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(_from, _to, _value);
        assert(SafeMath.add(balanceOf[_from], balanceOf[_to]) == previousBalances);
        return true;
    }
    
    function transfer(address _to, uint _value) public returns (bool success) {
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        TransferFrom(_from, _to, msg.sender, _value);
        return true;
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}

contract AcreToken is Lockable, TokenERC20 {
    string public version = &#39;1.0&#39;;
    
    address public companyCapital;
    address public prePayment;
    
    uint public totalMineSupply;
    mapping (address => bool) public frozenAccount;

    event FrozenAccount(address indexed target, bool frozen);
    event Burn(address indexed owner, uint value);
    event Mining(address indexed recipient, uint value);
    event WithdrawContractToken(address indexed owner, uint value);
    
    function AcreToken(address _companyCapital, address _prePayment) TokenERC20(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS, INITIAL_SUPPLY) public {
        require(_companyCapital != address(0));
        require(_prePayment != address(0));
        companyCapital = _companyCapital;
        prePayment = _prePayment;
        transfer(companyCapital, CAPITAL_SUPPLY);
        transfer(prePayment, PRE_PAYMENT_SUPPLY);
        lockup(prePayment);
        pause(); 
    }

    function _transfer(address _from, address _to, uint _value) whenConditionalPassing internal returns (bool success) {
        require(!frozenAccount[_from]); // freeze                     
        require(!frozenAccount[_to]);
        require(!isLockup(_from));      // lockup
        require(!isLockup(_to));
        return super._transfer(_from, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(!frozenAccount[msg.sender]); // freeze
        require(!isLockup(msg.sender));      // lockup
        return super.transferFrom(_from, _to, _value);
    }
    
    function freezeAccount(address _target) onlyManagers public returns (bool success) {
        require(!isManageable(_target));
        require(!frozenAccount[_target]);
        frozenAccount[_target] = true;
        FrozenAccount(_target, true);
        return true;
    }
    
    function unfreezeAccount(address _target) onlyManagers public returns (bool success) {
        require(frozenAccount[_target]);
        frozenAccount[_target] = false;
        FrozenAccount(_target, false);
        return true;
    }
    
    function burn(uint _value) onlyManagers public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);            
        totalSupply = totalSupply.sub(_value);                      
        Burn(msg.sender, _value);
        return true;
    }
    
    function mining(address _recipient, uint _value) onlyManagers public returns (bool success) {
        require(_recipient != address(0));
        require(!frozenAccount[_recipient]); // freeze
        require(!isLockup(_recipient));      // lockup
        require(SafeMath.add(totalMineSupply, _value) <= MAX_MINING_SUPPLY);
        balanceOf[_recipient] = balanceOf[_recipient].add(_value);
        totalSupply = totalSupply.add(_value);
        totalMineSupply = totalMineSupply.add(_value);
        Mining(_recipient, _value);
        return true;
    }
    
    function withdrawContractToken(uint _value) onlyManagers public returns (bool success) {
        _transfer(this, msg.sender, _value);
        WithdrawContractToken(msg.sender, _value);
        return true;
    }
    
    function getContractBalanceOf() public constant returns(uint blance) {
        blance = balanceOf[this];
    }
    
    function getRemainingMineSupply() public constant returns(uint supply) {
        supply = MAX_MINING_SUPPLY - totalMineSupply;
    }
    
    function () public { revert(); }
}

contract AcreSale is MultiOwnable {
    uint public saleDeadline;
    uint public startSaleTime;
    uint public softCapToken;
    uint public hardCapToken;
    uint public soldToken;
    uint public receivedEther;
    address public sendEther;
    AcreToken public tokenReward;
    bool public fundingGoalReached = false;
    bool public saleOpened = false;
    
    Payment public kyc;
    Payment public refund;
    Payment public withdrawal;

    mapping(uint=>address) public indexedFunders;
    mapping(address => Order) public orders;
    uint public funderCount;
    
    event StartSale(uint softCapToken, uint hardCapToken, uint minEther, uint exchangeRate, uint startTime, uint deadline);
    event ReservedToken(address indexed funder, uint amount, uint token, uint bonusRate);
    event WithdrawFunder(address indexed funder, uint value);
    event WithdrawContractToken(address indexed owner, uint value);
    event CheckGoalReached(uint raisedAmount, uint raisedToken, bool reached);
    event CheckOrderstate(address indexed funder, eOrderstate oldState, eOrderstate newState);
    
    enum eOrderstate { NONE, KYC, REFUND }
    
    struct Order {
        eOrderstate state;
        uint paymentEther;
        uint reservedToken;
        bool withdrawn;
    }
    
    struct Payment {
        uint token;
        uint eth;
        uint count;
    }

    modifier afterSaleDeadline { 
        require(now > saleDeadline); 
        _; 
    }
    
    function AcreSale(
        address _sendEther,
        uint _softCapToken,
        uint _hardCapToken,
        AcreToken _addressOfTokenUsedAsReward
    ) public {
        require(_sendEther != address(0));
        require(_addressOfTokenUsedAsReward != address(0));
        require(_softCapToken > 0 && _softCapToken <= _hardCapToken);
        sendEther = _sendEther;
        softCapToken = _softCapToken * 10 ** uint(TOKEN_DECIMALS);
        hardCapToken = _hardCapToken * 10 ** uint(TOKEN_DECIMALS);
        tokenReward = AcreToken(_addressOfTokenUsedAsReward);
    }
    
    function startSale(uint _durationTime) onlyManagers internal {
        require(softCapToken > 0 && softCapToken <= hardCapToken);
        require(hardCapToken > 0 && hardCapToken <= tokenReward.balanceOf(this));
        require(_durationTime > 0);
        require(startSaleTime == 0);

        startSaleTime = now;
        saleDeadline = SafeMath.add(startSaleTime, SafeMath.mul(_durationTime, TIME_FACTOR));
        saleOpened = true;
        
        StartSale(softCapToken, hardCapToken, MIN_ETHER, EXCHANGE_RATE, startSaleTime, saleDeadline);
    }
    
    // get
    function getRemainingSellingTime() public constant returns(uint remainingTime) {
        if(now <= saleDeadline) {
            remainingTime = getMinutes(SafeMath.sub(saleDeadline, now));
        }
    }
    
    function getRemainingSellingToken() public constant returns(uint remainingToken) {
        remainingToken = SafeMath.sub(hardCapToken, soldToken);
    }
    
    function getSoftcapReached() public constant returns(bool reachedSoftcap) {
        reachedSoftcap = soldToken >= softCapToken;
    }
    
    function getContractBalanceOf() public constant returns(uint blance) {
        blance = tokenReward.balanceOf(this);
    }
    
    function getCurrentBonusRate() public constant returns(uint8 bonusRate);
    
    // check
    function checkGoalReached() onlyManagers afterSaleDeadline public {
        if(saleOpened) {
            if(getSoftcapReached()) {
                fundingGoalReached = true;
            }
            saleOpened = false;
            CheckGoalReached(receivedEther, soldToken, fundingGoalReached);
        }
    }
    
    function checkKYC(address _funder) onlyManagers afterSaleDeadline public {
        require(!saleOpened);
        require(orders[_funder].reservedToken > 0);
        require(orders[_funder].state != eOrderstate.KYC);
        require(!orders[_funder].withdrawn);
        
        eOrderstate oldState = orders[_funder].state;
        
        // old, decrease
        if(oldState == eOrderstate.REFUND) {
            refund.token = refund.token.sub(orders[_funder].reservedToken);
            refund.eth   = refund.eth.sub(orders[_funder].paymentEther);
            refund.count = refund.count.sub(1);
        }
        
        // state
        orders[_funder].state = eOrderstate.KYC;
        kyc.token = kyc.token.add(orders[_funder].reservedToken);
        kyc.eth   = kyc.eth.add(orders[_funder].paymentEther);
        kyc.count = kyc.count.add(1);
        CheckOrderstate(_funder, oldState, eOrderstate.KYC);
    }
    
    function checkRefund(address _funder) onlyManagers afterSaleDeadline public {
        require(!saleOpened);
        require(orders[_funder].reservedToken > 0);
        require(orders[_funder].state != eOrderstate.REFUND);
        require(!orders[_funder].withdrawn);
        
        eOrderstate oldState = orders[_funder].state;
        
        // old, decrease
        if(oldState == eOrderstate.KYC) {
            kyc.token = kyc.token.sub(orders[_funder].reservedToken);
            kyc.eth   = kyc.eth.sub(orders[_funder].paymentEther);
            kyc.count = kyc.count.sub(1);
        }
        
        // state
        orders[_funder].state = eOrderstate.REFUND;
        refund.token = refund.token.add(orders[_funder].reservedToken);
        refund.eth   = refund.eth.add(orders[_funder].paymentEther);
        refund.count = refund.count.add(1);
        CheckOrderstate(_funder, oldState, eOrderstate.REFUND);
    }
    
    // withdraw
    function withdrawFunder(address _funder) onlyManagers afterSaleDeadline public {
        require(!saleOpened);
        require(fundingGoalReached);
        require(orders[_funder].reservedToken > 0);
        require(orders[_funder].state == eOrderstate.KYC);
        require(!orders[_funder].withdrawn);
        
        // token
        tokenReward.transfer(_funder, orders[_funder].reservedToken);
        withdrawal.token = withdrawal.token.add(orders[_funder].reservedToken);
        withdrawal.eth   = withdrawal.eth.add(orders[_funder].paymentEther);
        withdrawal.count = withdrawal.count.add(1);
        orders[_funder].withdrawn = true;
        WithdrawFunder(_funder, orders[_funder].reservedToken);
    }
    
    function withdrawContractToken(uint _value) onlyManagers public {
        tokenReward.transfer(msg.sender, _value);
        WithdrawContractToken(msg.sender, _value);
    }
    
    // payable
    function () payable public {
        require(saleOpened);
        require(now <= saleDeadline);
        require(MIN_ETHER <= msg.value);
        
        uint amount = msg.value;
        uint curBonusRate = getCurrentBonusRate();
        uint token = (amount.mul(curBonusRate.add(100)).div(100)).mul(EXCHANGE_RATE);
        
        require(token > 0);
        require(SafeMath.add(soldToken, token) <= hardCapToken);
        
        sendEther.transfer(amount);
        
        // funder info
        if(orders[msg.sender].paymentEther == 0) {
            indexedFunders[funderCount] = msg.sender;
            funderCount = funderCount.add(1);
            orders[msg.sender].state = eOrderstate.NONE;
        }
        
        orders[msg.sender].paymentEther = orders[msg.sender].paymentEther.add(amount);
        orders[msg.sender].reservedToken = orders[msg.sender].reservedToken.add(token);
        receivedEther = receivedEther.add(amount);
        soldToken = soldToken.add(token);
        
        ReservedToken(msg.sender, amount, token, curBonusRate);
    }
}

contract AcrePresale is AcreSale {
    function AcrePresale(
        address _sendEther,
        uint _softCapToken,
        uint _hardCapToken,
        AcreToken _addressOfTokenUsedAsReward
    ) AcreSale(
        _sendEther,
        _softCapToken, 
        _hardCapToken, 
        _addressOfTokenUsedAsReward) public {
    }
    
    function startPresale() onlyManagers public {
        startSale(PRESALE_DURATION_TIME);
    }
    
    function getCurrentBonusRate() public constant returns(uint8 bonusRate) {
        if      (now <= SafeMath.add(startSaleTime, SafeMath.mul( 7, TIME_FACTOR))) { bonusRate = 30; } // 7days  
        else if (now <= SafeMath.add(startSaleTime, SafeMath.mul(15, TIME_FACTOR))) { bonusRate = 25; } // 8days
        else                                                                        { bonusRate = 0; }  // 
    } 
}

contract AcreCrowdsale is AcreSale {
    function AcreCrowdsale(
        address _sendEther,
        uint _softCapToken,
        uint _hardCapToken,
        AcreToken _addressOfTokenUsedAsReward
    ) AcreSale(
        _sendEther,
        _softCapToken, 
        _hardCapToken, 
        _addressOfTokenUsedAsReward) public {
    }
    
    function startCrowdsale() onlyManagers public {
        startSale(CROWDSALE_DURATION_TIME);
    }
    
    function getCurrentBonusRate() public constant returns(uint8 bonusRate) {
        if      (now <= SafeMath.add(startSaleTime, SafeMath.mul( 7, TIME_FACTOR))) { bonusRate = 20; } // 7days
        else if (now <= SafeMath.add(startSaleTime, SafeMath.mul(14, TIME_FACTOR))) { bonusRate = 15; } // 7days
        else if (now <= SafeMath.add(startSaleTime, SafeMath.mul(21, TIME_FACTOR))) { bonusRate = 10; } // 7days
        else                                                                        { bonusRate = 0; }  // 
    }
}