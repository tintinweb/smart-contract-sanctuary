pragma solidity ^0.4.25;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract BasicAccountInfo {
    using SafeMath for uint;

    address constant public creatorAddress = 0xcDee178ed5B1968549810A237767ec388a3f83ba;
    address constant public ecologyAddress = 0xe87C12E6971AAf04DB471e5f93629C8B6F31b8C2;
    address constant public investorAddress = 0x660363e67485D2B51C071f42421b3DD134D3A835;
    address constant public partnerAddress = 0xabcf257c90dfE5E3b5Fcd777797213F36F9aB25e;

    struct BasicAccount {
        uint256 initialBalance;
        uint256 frozenBalance;
        uint256 availableBalance;
    }

    mapping (address => BasicAccount) public accountInfoMap;

    uint8 private frozenRatio = 60;
    uint8 private frozenRatioUnit = 100;

    address public owner;   //contract create by owner

    function BasicAccountInfo(uint8 _decimal) public {
        owner = msg.sender;

        initialCreatorAccount(_decimal);
        initialEcologyAccount(_decimal);
        initialInvestorAccount(_decimal);
        initialPartnerAccount(_decimal);
    }

    function initialCreatorAccount(uint8 _decimal) private {
        uint256 creatorInitialBalance = 37500000 * (10**(uint256(_decimal)));
        uint256 creatorFrozenBalance = creatorInitialBalance * uint256(frozenRatio) / uint256(frozenRatioUnit);
        uint256 creatorAvailableBalance = creatorInitialBalance - creatorFrozenBalance;

        accountInfoMap[creatorAddress] = BasicAccount(creatorInitialBalance, creatorFrozenBalance, creatorAvailableBalance);
    }

    function initialEcologyAccount(uint8 _decimal) private {
        uint256 ecologyInitialBalance = 25000000 * (10**(uint256(_decimal)));
        uint256 ecologyFrozenBalance = ecologyInitialBalance * uint256(frozenRatio) / uint256(frozenRatioUnit);
        uint256 ecologyAvailableBalance = ecologyInitialBalance - ecologyFrozenBalance;

        accountInfoMap[ecologyAddress] = BasicAccount(ecologyInitialBalance, ecologyFrozenBalance, ecologyAvailableBalance);
    }

    function initialInvestorAccount(uint8 _decimal) private {
        uint256 investorInitialBalance = 37500000 * (10**(uint256(_decimal)));
        uint256 investorFrozenBalance = investorInitialBalance * uint256(frozenRatio) / uint256(frozenRatioUnit);
        uint256 investorAvailableBalance = investorInitialBalance - investorFrozenBalance;

        accountInfoMap[investorAddress] = BasicAccount(investorInitialBalance, investorFrozenBalance, investorAvailableBalance);
    }

    function initialPartnerAccount(uint8 _decimal) private {
        uint256 partnerInitialBalance = 25000000 * (10**(uint256(_decimal)));
        uint256 partnerFrozenBalance = partnerInitialBalance * uint256(frozenRatio) / uint256(frozenRatioUnit);
        uint256 partnerAvailableBalance = partnerInitialBalance - partnerFrozenBalance;

        accountInfoMap[partnerAddress] = BasicAccount(partnerInitialBalance, partnerFrozenBalance, partnerAvailableBalance);
    }

    function getTotalFrozenBalance() public view returns (uint256 totalFrozenBalance) {
        return accountInfoMap[creatorAddress].frozenBalance + accountInfoMap[ecologyAddress].frozenBalance +
                        accountInfoMap[investorAddress].frozenBalance + accountInfoMap[partnerAddress].frozenBalance;
    }

    function getInitialBalanceByAddress(address _address) public view returns (uint256 initialBalance) {
        BasicAccount basicAccount = accountInfoMap[_address];
        return basicAccount.initialBalance;
    }

    function getAvailableBalanceByAddress(address _address) public view returns (uint256 availableBalance) {
        BasicAccount basicAccount = accountInfoMap[_address];
        return basicAccount.availableBalance;
    }

    function getFrozenBalanceByAddress(address _address) public view returns (uint256 frozenBalance) {
        BasicAccount basicAccount = accountInfoMap[_address];
        return basicAccount.frozenBalance;
    }

    function releaseFrozenBalance() public {
        require(owner == msg.sender);

        accountInfoMap[creatorAddress].availableBalance = accountInfoMap[creatorAddress].availableBalance.add(accountInfoMap[creatorAddress].frozenBalance);
        accountInfoMap[ecologyAddress].availableBalance = accountInfoMap[ecologyAddress].availableBalance.add(accountInfoMap[ecologyAddress].frozenBalance);
        accountInfoMap[investorAddress].availableBalance = accountInfoMap[investorAddress].availableBalance.add(accountInfoMap[investorAddress].frozenBalance);
        accountInfoMap[partnerAddress].availableBalance = accountInfoMap[partnerAddress].availableBalance.add(accountInfoMap[partnerAddress].frozenBalance);

        accountInfoMap[creatorAddress].frozenBalance = 0;
        accountInfoMap[ecologyAddress].frozenBalance = 0;
        accountInfoMap[investorAddress].frozenBalance = 0;
        accountInfoMap[partnerAddress].frozenBalance = 0;
    }
}

contract ERC20Interface {
    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC20 is ERC20Interface {
    using SafeMath for uint;

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) public allowed;
    uint256 public totalAvailable;

    bool public transfersEnabled;
    BasicAccountInfo private basicAccountInfo;
    address public owner;   //contract create by owner

    bool public released;
    uint256 public frozenTime;  //second
    uint256 public releaseTime;  //second
    uint256 constant private frozenPeriod = 100;  //days
    
    event Release(address indexed _owner);

    function ERC20(uint8 decimals) public {
        totalSupply = 250000000 * (10**(uint256(decimals)));
        transfersEnabled = true;
        released = false;

        owner = msg.sender;
        basicAccountInfo = new BasicAccountInfo(decimals);

        InitialBasicBalance();
        initialFrozenTime();
    }

    function InitialBasicBalance() private {
        totalAvailable = totalSupply - basicAccountInfo.getTotalFrozenBalance();
        balances[owner] = totalSupply.div(2);
        
        balances[basicAccountInfo.creatorAddress()] = basicAccountInfo.getAvailableBalanceByAddress(basicAccountInfo.creatorAddress());
        balances[basicAccountInfo.ecologyAddress()] = basicAccountInfo.getAvailableBalanceByAddress(basicAccountInfo.ecologyAddress());
        balances[basicAccountInfo.investorAddress()] =basicAccountInfo.getAvailableBalanceByAddress(basicAccountInfo.investorAddress());
        balances[basicAccountInfo.partnerAddress()] = basicAccountInfo.getAvailableBalanceByAddress(basicAccountInfo.partnerAddress());
    }

    function releaseBasicAccount() private {
        balances[basicAccountInfo.creatorAddress()] += basicAccountInfo.getFrozenBalanceByAddress(basicAccountInfo.creatorAddress());
        balances[basicAccountInfo.ecologyAddress()] += basicAccountInfo.getFrozenBalanceByAddress(basicAccountInfo.ecologyAddress());
        balances[basicAccountInfo.investorAddress()] +=basicAccountInfo.getFrozenBalanceByAddress(basicAccountInfo.investorAddress());
        balances[basicAccountInfo.partnerAddress()] += basicAccountInfo.getFrozenBalanceByAddress(basicAccountInfo.partnerAddress());

        totalAvailable += basicAccountInfo.getTotalFrozenBalance();
    }

    function releaseToken() public returns (bool) {
        require(owner == msg.sender);

        if(released){
            return false;
        }

        if(block.timestamp > releaseTime) {
            releaseBasicAccount();
            basicAccountInfo.releaseFrozenBalance();
            released = true;
            emit Release(owner);
            return true;
        }

        return false;
    }

    function getFrozenBalanceByAddress(address _address) public view returns (uint256 frozenBalance) {
        return basicAccountInfo.getFrozenBalanceByAddress(_address);
    }

    function getInitialBalanceByAddress(address _address) public view returns (uint256 initialBalance) {
        return basicAccountInfo.getInitialBalanceByAddress(_address);
    }

    function getTotalFrozenBalance() public view returns (uint256 totalFrozenBalance) {
        return basicAccountInfo.getTotalFrozenBalance();
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(transfersEnabled);

        require(_to != 0x0);
        require(balances[msg.sender] >= _value);
        require((balances[_to] + _value )> balances[_to]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(transfersEnabled);
        require(_from != 0x0);
        require(_to != 0x0);

        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);

        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        }

        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function enableTransfers(bool _transfersEnabled) {
        require(owner == msg.sender);
        transfersEnabled = _transfersEnabled;
    }

    function initialFrozenTime() private {
        frozenTime = block.timestamp;
        uint256 secondsPerDay = 3600 * 24;
        releaseTime = frozenPeriod * secondsPerDay  + frozenTime;
    }
}

contract BiTianToken is ERC20 {
    string public name = "Bitian Token";
    string public symbol = "BTT";
    string public version = &#39;1.0.0&#39;;
    uint8 public decimals = 18;

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     */
    function BiTianToken() ERC20(decimals) {
    }
}