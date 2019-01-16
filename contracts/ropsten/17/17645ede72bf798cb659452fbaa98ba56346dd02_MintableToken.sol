library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to relinquish control of the contract.
    * @notice Renouncing to ownership will leave the contract without an owner.
    * It will not be possible to call the functions with the `onlyOwner`
    * modifier anymore.
    */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
    * @dev Transfers control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}
contract ERC20Interface {

    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function allowance(address owner, address spender)public view returns (uint256);
    function transferFrom(address from, address to, uint256 value)public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner,address indexed spender,uint256 value);

}
contract TimeLock {
    //FINERC20 var definition
    MintableToken ERC20Contract;
    // custom data structure to hold locked funds and time
    struct accountData {
        uint256 balance;
        uint256 releaseTime;
    }

    event Lock(address indexed _tokenLockAccount, uint256 _lockBalance, uint256 _releaseTime);
    event UnLock(address indexed _tokenUnLockAccount, uint256 _unLockBalance, uint256 _unLockTime);

    // only one locked account per address
    mapping (address => accountData) accounts;

    /**
    * @dev Constructor in which we pass the ERC20Contract address for reference and method calls
    */

    constructor(MintableToken _ERC20Contract) public {
        ERC20Contract = _ERC20Contract;
    }

    function timeLockTokens(uint256 _lockTimeS) public {

        uint256 lockAmount = ERC20Contract.allowance(msg.sender, this); // get this time lock contract&#39;s approved amount of tokens


        require(lockAmount != 0); // check that this time lock contract has been approved to lock an amount of tokens on the msg.sender&#39;s behalf

        if (accounts[msg.sender].balance > 0) { // if locked balance already exists, add new amount to the old balance and retain the same release time
            accounts[msg.sender].balance = SafeMath.add(accounts[msg.sender].balance, lockAmount);
      } else { // else populate the balance and set the release time for the newly locked balance
            accounts[msg.sender].balance = lockAmount;
            accounts[msg.sender].releaseTime = SafeMath.add(now, _lockTimeS);
        }

        emit Lock(msg.sender, lockAmount, accounts[msg.sender].releaseTime);

        ERC20Contract.transferFrom(msg.sender, this, lockAmount);

    }

    function tokenRelease() public {
        // check if user has funds due for pay out because lock time is over
        require (accounts[msg.sender].balance != 0 && accounts[msg.sender].releaseTime <= now);
        accounts[msg.sender].balance = 0;
        accounts[msg.sender].releaseTime = 0;
        emit UnLock(msg.sender, accounts[msg.sender].balance, now);
        ERC20Contract.transfer(msg.sender, accounts[msg.sender].balance);

    }

    // some helper functions for demo purposes (not required)
    function getLockedFunds(address _account) view public returns (uint _lockedBalance) {
        return accounts[_account].balance;
    }

    function getReleaseTime(address _account) view public returns (uint _releaseTime) {
        return accounts[_account].releaseTime;
    }

    /**
    * @dev Used to retrieve the ERC20 contract address that this deployment is attatched to
    * @return address - the ERC20 contract address that this deployment is attatched to
    */
    function getERC20() public view returns (address) {
        return ERC20Contract;
    }
}
contract FINPointRecord is Ownable {
    using SafeMath for uint256;

    // claimRate is the multiplier to calculate the number of FIN ERC20 claimable per FIN points reorded
    // e.g., 100 = 1:1 claim ratio
    // this claim rate can be seen as a kind of airdrop for exsisting FIN point holders at the time of claiming
    uint256 claimRate;

    // an address map used to store the per account claimable FIN ERC20 record
    // as a result of swapped FIN points
    mapping (address => uint256) public claimableFIN;

    event FINRecordCreate(
        address indexed _recordAddress,
        uint256 _finPointAmount,
        uint256 _finERC20Amount
    );

    event FINRecordUpdate(
        address indexed _recordAddress,
        uint256 _finPointAmount,
        uint256 _finERC20Amount
    );

    event FINRecordMove(
        address indexed _oldAddress,
        address indexed _newAddress,
        uint256 _finERC20Amount
    );

    /**
     * Throws if claim rate is not set
    */
    modifier canRecord() {
        require(claimRate > 0);
        _;
    }
    /**
     * @dev sets the claim rate for FIN ERC20
     * @param _claimRate is the claim rate applied during record creation
    */
    function setClaimRate(uint256 _claimRate) public onlyOwner{
        require(_claimRate <= 1000); // maximum 10x migration rate
        require(_claimRate >= 100); // minimum 1x migration rate
        claimRate = _claimRate;
    }

    /**
    * @dev Used to calculate and store the amount of claimable FIN ERC20 from existing FIN point balances
    * @param _recordAddress - the registered address assigned to FIN ERC20 claiming
    * @param _finPointAmount - the original amount of FIN points to be moved, this param should always be entered as base units
    * i.e., 1 FIN = 10**18 base units
    * @param _applyClaimRate - flag to apply the claim rate or not, any Finterra Technologies company FIN point allocations
    * are strictly moved at one to one and do not recive the claim (airdrop) bonus applied to FIN point user balances
    */
    function recordCreate(address _recordAddress, uint256 _finPointAmount, bool _applyClaimRate) public onlyOwner canRecord {
        require(_finPointAmount >= 100000); // minimum allowed FIN 0.000000000001 (in base units) to avoid large rounding errors

        uint256 finERC20Amount;

        if(_applyClaimRate == true) {
            finERC20Amount = _finPointAmount.mul(claimRate).div(100);
        } else {
            finERC20Amount = _finPointAmount;
        }

        claimableFIN[_recordAddress] = claimableFIN[_recordAddress].add(finERC20Amount);

        emit FINRecordCreate(_recordAddress, _finPointAmount, claimableFIN[_recordAddress]);
    }

    /**
    * @dev Used to calculate and update the amount of claimable FIN ERC20 from existing FIN point balances
    * @param _recordAddress - the registered address assigned to FIN ERC20 claiming
    * @param _finPointAmount - the original amount of FIN points to be migrated, this param should always be entered as base units
    * i.e., 1 FIN = 10**18 base units
    * @param _applyClaimRate - flag to apply claim rate or not, any Finterra Technologies company FIN point allocations
    * are strictly migrated at one to one and do not recive the claim (airdrop) bonus applied to FIN point user balances
    */
    function recordUpdate(address _recordAddress, uint256 _finPointAmount, bool _applyClaimRate) public onlyOwner canRecord {
        require(_finPointAmount >= 100000); // minimum allowed FIN 0.000000000001 (in base units) to avoid large rounding errors

        uint256 finERC20Amount;

        if(_applyClaimRate == true) {
            finERC20Amount = _finPointAmount.mul(claimRate).div(100);
        } else {
            finERC20Amount = _finPointAmount;
        }

        claimableFIN[_recordAddress] = finERC20Amount;

        emit FINRecordUpdate(_recordAddress, _finPointAmount, claimableFIN[_recordAddress]);
    }

    /**
    * @dev Used to move FIN ERC20 records from one address to another, primarily in case a user has lost access to their originally registered account
    * @param _oldAddress - the original registered address
    * @param _newAddress - the new registerd address
    */
    function recordMove(address _oldAddress, address _newAddress) public onlyOwner canRecord {
        require(claimableFIN[_oldAddress] != 0);
        require(claimableFIN[_newAddress] == 0);

        claimableFIN[_newAddress] = claimableFIN[_oldAddress];
        claimableFIN[_oldAddress] = 0;

        emit FINRecordMove(_oldAddress, _newAddress, claimableFIN[_newAddress]);
    }

    /**
    * @dev Used to retrieve the FIN ERC20 migration records for an address, for FIN ERC20 claiming
    * @param _recordAddress - the registered address where FIN ERC20 tokens can be claimed
    * @return uint256 - the amount of recorded FIN ERC20 after FIN point migration
    */
    function recordGet(address _recordAddress) view public returns (uint256) {
        return claimableFIN[_recordAddress];
    }
}
contract Claimable is Ownable {
    // FINPointRecord var definition
    FINPointRecord finPointRecordContract;

    // an address map used to store the cliamed flag, so accounts cannot claim more than once
    mapping (address => bool) public claimed;

    event MigrationSourceTransferred(
        address indexed previousMigrationContract,
        address indexed newMigrationContract
    );


    /**
    * @dev The Claimable constructor sets the original `claim contract` to the provided _claimContract
    * account.
    */
    constructor(FINPointRecord _finPointRecordContract) public {
        finPointRecordContract = _finPointRecordContract;
    }

    /**
    * @dev Throws if called by any account other than the claimContract.
    */
    modifier canClaim() {
        require(finPointRecordContract.recordGet(msg.sender) != 0);
        require(claimed[msg.sender] == false);
        _;
    }

    /**
    * @dev Allows to change the migration information source contract.
    * @param _newMigrationContract The address of the new migration contract
    */
    function transferMigrationSource(FINPointRecord _newMigrationContract) public onlyOwner {
        _transferMigrationSource(_newMigrationContract);
    }

    /**
    * @dev Transfers the reference of the recorded migrations contract to a newMigrationContract.
    * @param _newMigrationContract The address of the new migration contract
    */
    function _transferMigrationSource(FINPointRecord _newMigrationContract) internal {
        require(_newMigrationContract != address(0));
        emit MigrationSourceTransferred(finPointRecordContract, _newMigrationContract);
        finPointRecordContract = _newMigrationContract;
    }
}
contract StandardToken is ERC20Interface {

    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 totalSupply_;

    // the following variables need to be here for scoping to properly freeze normal transfers after migration has started
    // migrationStart flag
    bool migrationStart;
    // var for storing the the TimeLock contract deployment address (for vesting FIN allocations)
    TimeLock timeLockContract;

    /**
     * @dev Modifier for allowing only TimeLock transactions to occur after the migration period has started
    */
    modifier migrateStarted {
        if(migrationStart == true){
            require(msg.sender == address(timeLockContract));
        }
        _;
    }

    constructor(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev Transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public migrateStarted returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
        )
        public
        migrateStarted
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _addedValue The amount of tokens to increase the allowance by.
    */
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed[_spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}
contract FINERC20Migrate is Ownable {
    using SafeMath for uint256;

    // Address map used to store the per account migratable FIN balances
    // as per the account&#39;s FIN ERC20 tokens on the Ethereum Network

    mapping (address => uint256) public migratableFIN;
    
    MintableToken finErc20;

    constructor(MintableToken _finErc20) public {
        finErc20 = _finErc20;
    }   

    // Note: _totalMigratableFIN is a running total of FIN claimed as migratable in this contract, 
    // but does not represent the actual amount of FIN migrated to the Gallactic network
    event FINMigrateRecordUpdate(
        address indexed _account,
        uint256 _totalMigratableFIN
    ); 

    /**
    * @dev Used to calculate and store the amount of FIN ERC20 token balances to be migrated to the Gallactic network
    * 
    * @param _balanceToMigrate - the requested balance to reserve for migration (in most cases this should be the account&#39;s total balance)
    *    - primarily included as a parameter for simple validation on the Gallactic side of the migration
    */
    function initiateMigration(uint256 _balanceToMigrate) public {
        uint256 migratable = finErc20.migrateTransfer(msg.sender, _balanceToMigrate);
        migratableFIN[msg.sender] = migratableFIN[msg.sender].add(migratable);
        emit FINMigrateRecordUpdate(msg.sender, migratableFIN[msg.sender]);
    }

    /**
    * @dev Used to retrieve the FIN ERC20 total migration records for an Etheruem account
    * @param _account - the account to be checked for a migratable balance
    * @return uint256 - the running total amount of migratable FIN ERC20 tokens
    */
    function getFINMigrationRecord(address _account) public view returns (uint256) {
        return migratableFIN[_account];
    }

    /**
    * @dev Used to retrieve FIN ERC20 contract address that this deployment is attatched to
    * @return address - the FIN ERC20 contract address that this deployment is attatched to
    */
    function getERC20() public view returns (address) {
        return finErc20;
    }
}
contract MintableToken is StandardToken, Claimable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event SetMigrationAddress(address _finERC20MigrateAddress);
    event SetTimeLockAddress(address _timeLockAddress);
    event MigrationStarted();
    event Migrated(address indexed account, uint256 amount);

    bool public mintingFinished = false;

    // var for storing the the FINERC20Migrate contract deployment address (for migration to the GALLACTIC network)
    FINERC20Migrate finERC20MigrationContract;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
     * @dev Modifier allowing only the set FINERC20Migrate.sol deployment to call a function
    */
    modifier onlyMigrate {
        require(msg.sender == address(finERC20MigrationContract));
        _;
    }

    /**
    * @dev Constructor to pass the finPointMigrationContract address to the Claimable constructor
    */
    constructor(FINPointRecord _finPointRecordContract, string _name, string _symbol, uint8 _decimals)

    Claimable(_finPointRecordContract)
    StandardToken(_name, _symbol, _decimals) public {

    }

    /**
    * @dev Allows addresses with FIN migration records to claim thier ERC20 FIN tokens. This is the only way minting can occur.
    * @param _msgHash is the hash of the message
    */
    function claim(bytes32 _msgHash, uint8 v, bytes32 r, bytes32 s) public canClaim {
        address signingAddress = ecrecover(_msgHash, v, r, s);
        require(signingAddress == owner);
        bytes memory prefix = "\x19Ethereum Signed Message:\n";
        require(keccak256(abi.encodePacked(prefix, "21", msg.sender, true)) == _msgHash);
        claimed[msg.sender] = true;
        mint(msg.sender, finPointRecordContract.recordGet(msg.sender));
    }

    /**
    * @dev Function to mint tokens
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(
        address _to,
        uint256 _amount
    )
        canMint
        private
        returns (bool)
    {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
    * @dev Function to stop all minting of new tokens.
    * @return True if the operation was successful.
    */
    function finishMinting() public onlyOwner canMint returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

   /**
    * @dev Function to set the migration contract address
    * @return True if the operation was successful.
    */
    function setMigrationAddress(FINERC20Migrate _finERC20MigrationContract) public onlyOwner returns (bool) {
        // check that this FIN ERC20 deployment is the migration contract&#39;s attached ERC20 token
        require(_finERC20MigrationContract.getERC20() == address(this));

        finERC20MigrationContract = _finERC20MigrationContract;
        emit SetMigrationAddress(_finERC20MigrationContract);
        return true;
    }

   /**
    * @dev Function to set the TimeLock contract address
    * @return True if the operation was successful.
    */
    function setTimeLockAddress(TimeLock _timeLockContract) public onlyOwner returns (bool) {
        // check that this FIN ERC20 deployment is the timelock contract&#39;s attached ERC20 token
        require(_timeLockContract.getERC20() == address(this));

        timeLockContract = _timeLockContract;
        emit SetTimeLockAddress(_timeLockContract);
        return true;
    }

   /**
    * @dev Function to start the migration period
    * @return True if the operation was successful.
    */
    function startMigration() onlyOwner public returns (bool) {
        require(migrationStart == false);
        // check that the FIN migration contract address is set
        require(finERC20MigrationContract != address(0));
        // // check that the TimeLock contract address is set
        require(timeLockContract != address(0));

        migrationStart = true;
        emit MigrationStarted();

        return true;
    }

    /**
     * @dev Function to modify the FIN ERC-20 balance in compliance with migration to FIN ERC-777 on the GALLACTIC Network
     *      - called by the FIN-ERC20-MIGRATE FINERC20Migrate.sol Migration Contract to record the amount of tokens to be migrated
     * @dev modifier onlyMigrate - Permissioned only to the deployed FINERC20Migrate.sol Migration Contract
     * @param _account The Ethereum account which holds some FIN ERC20 balance to be migrated to Gallactic
     * @param _amount The amount of FIN ERC20 to be migrated
    */
    function migrateTransfer(address _account, uint256 _amount) onlyMigrate public returns (uint256) {

        require(migrationStart == true);

        uint256 userBalance = balanceOf(_account);
        require(userBalance >= _amount);

        emit Migrated(_account, _amount);

        balances[_account] = balances[_account].sub(_amount);

        return _amount;
    }

}