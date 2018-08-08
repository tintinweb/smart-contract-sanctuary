pragma solidity ^0.4.19;

// Turn the usage of callcode
contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
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

contract CreatorEnabled {
    address public creator = 0x0;

    modifier onlyCreator() { require(msg.sender==creator); _; }

    function changeCreator(address _to) public onlyCreator {
        creator = _to;
    }
}

// ERC20 standard
contract StdToken is SafeMath {

    mapping(address => uint256) public balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    uint public totalSupply = 0;


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns(bool) {
      require(0x0!=_to);

      balances[msg.sender] = safeSub(balances[msg.sender],_value);
      balances[_to] = safeAdd(balances[_to],_value);

      Transfer(msg.sender, _to, _value);
      return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns(bool) {
      require(0x0!=_to);

      balances[_to] = safeAdd(balances[_to],_value);
      balances[_from] = safeSub(balances[_from],_value);
      allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_value);

      Transfer(_from, _to, _value);
      return true;
    }

    function balanceOf(address _owner) constant returns (uint256) {
      return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool) {
      // To change the approve amount you first have to reduce the addresses`
      //  allowance to zero by calling `approve(_spender, 0)` if it is not
      //  already 0 to mitigate the race condition described here:
      //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
      require((_value == 0) || (allowed[msg.sender][_spender] == 0));

      allowed[msg.sender][_spender] = _value;
      Approval(msg.sender, _spender, _value);
      return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256) {
      return allowed[_owner][_spender];
    }

    modifier onlyPayloadSize(uint _size) {
      require(msg.data.length >= _size + 4);
      _;
    }
}

contract IGoldFee {
    function calculateFee(address _sender, bool _isMigrationStarted, bool _isMigrationFinished, uint _mntpBalance, uint _value) public constant returns(uint);
}

contract GoldFee is CreatorEnabled {

    mapping(address => bool) exceptAddresses;

    function GoldFee() {
        creator = msg.sender;
    }

    function getMin(uint out)returns (uint) {
        // 0.002 GOLD is min fee
        uint minFee = (2 * 1 ether) / 1000;
        if (out < minFee) {
             return minFee;
        }
        return out;
    }

    function getMax(uint out)returns (uint) {
        // 0.02 GOLD is max fee
        uint maxFee = (2 * 1 ether) / 100;
        if (out >= maxFee) {
             return maxFee;
        }
        return out;
    }

    function calculateFee(address _sender, bool _isMigrationStarted, bool _isMigrationFinished, uint _mntpBalance, uint _value) public constant returns(uint)
    {
        return 0;

       //if this is an excaptional address
       if (exceptAddresses[_sender]) {
            return 0;
       }

        // When migration process is finished (1 year from Goldmint blockchain launch), then transaction fee is 1% GOLD.
        if (_isMigrationFinished) {
             return (_value / 100);
        }

        // If the sender holds 0 MNTP, then the transaction fee is 1% GOLD.

        // If the sender holds at least 10 MNTP, then the transaction fee is 0.333333% GOLD,
        // but not less than 0.002 MNTP

        // If the sender holds at least 1000 MNTP, then the transaction fee is 0.033333% GOLD,
        // but not less than 0.002 MNTP

        // If the sender holds at least 10000 MNTP, then the transaction fee is 0.0333333% GOLD,
        // but not more than 0.02 MNTP
        if (_mntpBalance >= (10000 * 1 ether)) {
             return getMax((_value / 100) / 30);
        }
        if (_mntpBalance >= (1000 * 1 ether)) {
             return getMin((_value / 100) / 30);
        }
        if (_mntpBalance >= (10 * 1 ether)) {
             return getMin((_value / 100) / 3);
        }

        // 1%
        return getMin(_value / 100);
    }

    function addExceptAddress(address _address) public onlyCreator {
        exceptAddresses[_address] = true;
    }

    function removeExceptAddress(address _address) public onlyCreator {
        exceptAddresses[_address] = false;
    }

    function isAddressExcept(address _address) public constant returns(bool) {
        return exceptAddresses[_address];
    }
}

contract Gold is StdToken, CreatorEnabled {

    string public constant name = "GoldMint GOLD cryptoasset";
    string public constant symbol = "GOLD";
    uint8 public constant decimals = 18;

    // this is used to send fees (that is then distributed as rewards)
    address public migrationAddress = 0x0;
    address public storageControllerAddress = 0x0;

    address public goldmintTeamAddress = 0x0;
    IMNTP public mntpToken;
    IGoldFee public goldFee;


    bool public transfersLocked = false;
    bool public contractLocked = false;
    bool public migrationStarted = false;
    bool public migrationFinished = false;

    uint public totalIssued = 0;
    uint public totalBurnt = 0;

    // Modifiers:
    modifier onlyMigration() { require(msg.sender == migrationAddress); _; }
    modifier onlyMigrationOrStorageController() { require(msg.sender == migrationAddress || msg.sender == storageControllerAddress); _; }
    modifier onlyCreatorOrStorageController() { require(msg.sender == creator || msg.sender == storageControllerAddress); _; }
    modifier onlyIfUnlocked() { require(!transfersLocked); _; }

    // Functions:
    function Gold(address _mntpContractAddress, address _goldmintTeamAddress, address _goldFeeAddress) public {
        creator = msg.sender;

        mntpToken = IMNTP(_mntpContractAddress);
        goldmintTeamAddress = _goldmintTeamAddress;
        goldFee = IGoldFee(_goldFeeAddress);
    }

    function setCreator(address _address) public onlyCreator {
       creator = _address;
    }

    function lockContract(bool _contractLocked) public onlyCreator {
       contractLocked = _contractLocked;
    }

    function setStorageControllerContractAddress(address _address) public onlyCreator {
        storageControllerAddress = _address;
    }

    function setMigrationContractAddress(address _migrationAddress) public onlyCreator {
        migrationAddress = _migrationAddress;
    }

    function setGoldmintTeamAddress(address _teamAddress) public onlyCreator {
        goldmintTeamAddress = _teamAddress;
    }

    function setGoldFeeAddress(address _goldFeeAddress) public onlyCreator {
        goldFee = IGoldFee(_goldFeeAddress);
    }

    function issueTokens(address _who, uint _tokens) public onlyCreatorOrStorageController {
        require(!contractLocked);

        balances[_who] = safeAdd(balances[_who],_tokens);
        totalSupply = safeAdd(totalSupply,_tokens);
        totalIssued = safeAdd(totalIssued,_tokens);

        Transfer(0x0, _who, _tokens);
    }

    function burnTokens(address _who, uint _tokens) public onlyMigrationOrStorageController {
        require(!contractLocked);
        balances[_who] = safeSub(balances[_who],_tokens);
        totalSupply = safeSub(totalSupply,_tokens);
        totalBurnt = safeAdd(totalBurnt,_tokens);
    }

    // there is no way to revert that
    function startMigration() public onlyMigration {
        require(false == migrationStarted);
        migrationStarted = true;
    }

    // there is no way to revert that
    function finishMigration() public onlyMigration {
        require(true == migrationStarted);

        migrationFinished = true;
    }

    function lockTransfer(bool _lock) public onlyMigration {
        transfersLocked = _lock;
    }

    function transfer(address _to, uint256 _value) public onlyIfUnlocked onlyPayloadSize(2 * 32) returns(bool) {

        uint yourCurrentMntpBalance = mntpToken.balanceOf(msg.sender);

        // you can transfer if fee is ZERO
        uint fee = goldFee.calculateFee(msg.sender, migrationStarted, migrationFinished, yourCurrentMntpBalance, _value);
        
        uint sendThis = _value;
        if (0 != fee) {
             sendThis = safeSub(_value,fee);

             // 1.Transfer fee
             // A -> rewards account
             //
             // Each GOLD token transfer should send transaction fee to
             // GoldmintMigration contract if Migration process is not started.
             // Goldmint team if Migration process is started.
             if (migrationStarted) {
                  super.transfer(goldmintTeamAddress, fee);
             } else {
                  super.transfer(migrationAddress, fee);
             }
        }
        
        // 2.Transfer
        // A -> B
        return super.transfer(_to, sendThis);
    }

    function transferFrom(address _from, address _to, uint256 _value) public onlyIfUnlocked returns(bool) {

        uint yourCurrentMntpBalance = mntpToken.balanceOf(_from);

        uint fee = goldFee.calculateFee(msg.sender, migrationStarted, migrationFinished, yourCurrentMntpBalance, _value);
        if (0 != fee) {
             // 1.Transfer fee
             // A -> rewards account
             //
             // Each GOLD token transfer should send transaction fee to
             // GoldmintMigration contract if Migration process is not started.
             // Goldmint team if Migration process is started.
             if (migrationStarted) {
                  super.transferFrom(_from, goldmintTeamAddress, fee);
             } else {
                  super.transferFrom(_from, migrationAddress, fee);
             }
        }

        // 2.Transfer
        // A -> B
        uint sendThis = safeSub(_value,fee);
        return super.transferFrom(_from, _to, sendThis);
    }

    // Used to send rewards)
    function transferRewardWithoutFee(address _to, uint _value) public onlyMigration onlyPayloadSize(2*32) {
        require(0x0!=_to);

        balances[migrationAddress] = safeSub(balances[migrationAddress],_value);
        balances[_to] = safeAdd(balances[_to],_value);

        Transfer(migrationAddress, _to, _value);
    }

    // This is an emergency function that can be called by Creator only
    function rescueAllRewards(address _to) public onlyCreator {
        require(0x0!=_to);

        uint totalReward = balances[migrationAddress];

        balances[_to] = safeAdd(balances[_to],totalReward);
        balances[migrationAddress] = 0;

        Transfer(migrationAddress, _to, totalReward);
    }


    function getTotalIssued() public constant returns (uint) {
        return totalIssued;
    }

    function getTotalBurnt() public constant returns (uint) {
        return totalBurnt;
    }
}

contract IMNTP is StdToken {
    // Additional methods that MNTP contract provides
    function lockTransfer(bool _lock);
    function issueTokens(address _who, uint _tokens);
    function burnTokens(address _who, uint _tokens);
}

contract GoldmintMigration is CreatorEnabled {
    
    IMNTP public mntpToken;
    Gold public goldToken;

    address public managerAddress = 0x0;

    event MntpHold(address _ethAddress, string _gmAddress, uint256 _amount);
    event MntpUnhold(address _ethAddress, uint256 _amount);
    event GoldHold(address _ethAddress, string _gmAddress, uint256 _amount);
    event GoldUnhold(address _ethAddress, uint256 _amount);

    modifier onlyManagerOrCreator() { require(msg.sender == managerAddress || msg.sender == creator); _; }


    function GoldmintMigration(address _mntpContractAddress, address _goldContractAddress) public {
        creator = msg.sender;

        require(_mntpContractAddress != 0);
        require(_goldContractAddress != 0);

        mntpToken = IMNTP(_mntpContractAddress);
        goldToken = Gold(_goldContractAddress);
    }

    function setManagerAddress(address _address) public onlyCreator {
       managerAddress = _address;
    }

    function lockMntpTransfers(bool _lock) public onlyCreator {
        mntpToken.lockTransfer(_lock);
    }

    function lockGoldTransfers(bool _lock) public onlyCreator {
        goldToken.lockTransfer(_lock);
    }

    function unholdMntp(address _ethAddress, uint _amount) public onlyManagerOrCreator {
        uint balance = mntpToken.balanceOf(address(this));
        require(balance >= _amount);

        mntpToken.transfer(_ethAddress, _amount);

        MntpUnhold(_ethAddress, _amount);
    }

    function unholdGold(address _ethAddress, uint _amount) public onlyManagerOrCreator {
        uint balance = goldToken.balanceOf(address(this));
        require(balance >= _amount);

        goldToken.transfer(_ethAddress, _amount);

        GoldUnhold(_ethAddress, _amount);
    }

    // do not allow to send money to this contract...
    function() external payable {
        revert();
    }
}