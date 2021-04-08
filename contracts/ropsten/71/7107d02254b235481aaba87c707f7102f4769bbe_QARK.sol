/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity ^0.5.0;

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event LockBalance(address indexed from, address indexed to, uint tokens);
    event FreezeBalance(address indexed from, uint tokens, uint until);
    event LogUint(string key, uint value);
    event LogString(string key, string value);
    event LogAddress(string key, address value);
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract QARK is ERC20Interface, Owned {

    /*
     * Use SafeMath Library
     * for uint operations.
     */
    using SafeMath for uint;

    /*
     * Token symbol listed
     * on exchanges.
     */
    string public symbol;

    /*
     * Token name displayed
     * on block explorers
     */
    string public  name;

    /*
     * Atomic unit of the token.
     */
    uint8 public decimals;

    /*
     * Total supply available
     * of the token.
     */
    uint _totalSupply;

    /*
     * Stores token holder
     * balances.
     */
    mapping(address => uint) balances;

    /*
     * Stores allowances
     * of tokens holders to
     * each other.
     */
    mapping(address => mapping(address => uint)) allowed;

    /*
     * Method to claim unsold
     * private sale tokens into
     * the reserve.
     */
    function claimReserve() public {

        //ONLY RESERVE ADDRESS CAN CLAIM
        require(msg.sender == roles[4], 'Only reserve address can claim!');

        //RESERVE CAN ONLY BE CLAIMED AFTER END OF PUBLIC SALE
        if(block.timestamp < pubSaleEnd + 7 * 24 * 60 * 60){
            revert('Reserve can not be claimed before end of public sale!');
        }

        //CLAIM FUNDS
        balances[roles[4]] = balances[roles[4]].add(balances[roles[0]]);

        //EMIT TRANSFER EVENTS
        emit Transfer(roles[0], roles[4], balances[roles[0]]);

        //DEDUCT BALANCES OF EXCHANGE AND PRIV SELLER
        balances[roles[0]] = 0;
    }

    /*
     * Mapping for roles
     * to addresses:
     * 0 => Private seller
     * 1 => Exchange
     * 2 => Management
     * 3 => Centrum Circle
     * 4 => Reserve
     * 5 => Rate updater
     */
    mapping(uint => address) roles;

    /*
     * Get the current address
     * for a given role.
     */
    function getRoleAddress(uint _roleId) public view returns (address) {
        return roles[_roleId];
    }

    /*
     * Sets an address
     * for a given role.
     */
    function setRoleAddress(uint _roleId, address _newAddress) public onlyOwner {

        //ENSURE THAT ONLY ADDRESSES WITHOUT BALANCE CAN BE ASSIGNED
        require(balances[_newAddress] == 0, 'Only zero balance addresses can be assigned!');

        //GET OLD ADDRESS OF THE ROLE
        address _oldAddress = roles[_roleId];

        //IF TRYING TO UPDATE EXCHANGE ADDRESS, REVERT
        if(_roleId == 1 && _oldAddress != address(0)){
            revert('Exchange address MUST not be updated!');
        }

        //IF THIS IS THE INITIALIZATION OF THE ADDRESS
        if(_oldAddress == address(0)){

            //INITIALIZATION BALANCE
            uint initBalance = 0;

            //PRIVATE SELLER
            if(_roleId == 0){
                initBalance = 133333200;
            }

            //EXCHANGE
            if(_roleId == 1){
                initBalance = 88888800;
            }

            //MANAGEMENT
            if(_roleId == 2){
                initBalance = 44444400;
            }

            //CENTRUM
            if(_roleId == 3){
                initBalance = 44444400;
            }

            //RESERVE
            if(_roleId == 4){
                initBalance = 22222200;
            }

            //5 = RATE UPDATER

            //IF THERE IS BALANCE TO BE INITIALIZED, DO IT
            if(initBalance > 0){
                initBalance = initBalance * 10**uint(decimals);
                balances[_newAddress] = initBalance;
                emit Transfer(address(0), _newAddress, initBalance);

                //FOR MANAGEMENT AND RESERVE, APPLY FREEZE TO THE INIT BALANCE
                if(_roleId == 2 || _roleId == 4){
                    frozenBalances[_newAddress] = initBalance;
                    frozenTiming[_newAddress] = block.timestamp + 180 * 24 * 60 * 60;
                    emit FreezeBalance(_newAddress, initBalance, frozenTiming[_newAddress]);
                }
            }
        }

        //IF CURRENT ACCOUNT HAS BALANCE
        if(balances[_oldAddress] > 0){

            //MOVE FUNDS OF OLD ACCOUNT TO NEW ACCOUNT
            balances[_newAddress] = balances[_oldAddress];

            //EMIT TRANSFER EVENT
            emit Transfer(_oldAddress, _newAddress, balances[_oldAddress]);

            //REMOVE OLD BALANCE
            balances[_oldAddress] = 0;

            //TRANSFER FROZEN BALANCES AS WELL
            if(frozenBalances[_oldAddress] > 0){

                frozenBalances[_newAddress] = frozenBalances[_oldAddress];
                frozenTiming[_newAddress] = frozenTiming[_oldAddress];

                emit FreezeBalance(_newAddress, frozenBalances[_newAddress], frozenTiming[_newAddress]);

                frozenBalances[_oldAddress] = 0;
                frozenTiming[_oldAddress] = 0;
            }
        }

        //ASSIGN NEW ADDRESS
        roles[_roleId] = _newAddress;
    }

    /*
     * The current conversion rate of
     * 1 QARK => USD cents.
     */
    uint public conversionRate;

    function setRate(uint _newConversionRate) public {
        require(msg.sender == roles[5], 'Only rate updater is allowed to perform this!');
        conversionRate = _newConversionRate;
    }

    /*
     * Stores the locked balances
     * of those who bought during
     * private sale and are restricted
     * from selling after public sale.
     */
    mapping(address => uint256) lockedBalances;

    /*
     * UNIX timestamp of the start
     * time of the public sale.
     */
    uint public pubSaleStart;

    /*
     * UNIX timestamp of the end
     * time of the public sale.
     */
    uint public pubSaleEnd;

    /*
     * UNIX timestamp of the end
     * time of the private buyers'
     * restrictions.
     */
    uint public restrictionEnd;

    /*
     * Sets the public sale and
     * restrictions related timings.
     */
    function setTiming(uint _pubSaleStart, uint _pubSaleEnd, uint _restrictionEnd) public onlyOwner {
        require(pubSaleStart == 0 && pubSaleEnd == 0 && restrictionEnd == 0, 'Timing only can be set once');
        pubSaleStart = _pubSaleStart;
        pubSaleEnd = _pubSaleEnd;
        restrictionEnd = _restrictionEnd;
    }

    /*
     * Constructs the contract
     * with 333,333,300 QARK tokens
     * with 18 decimals.
     */
    constructor() public {
        symbol = "QARK";
        name = "QARK Token of QAN Platform";
        decimals = 18;
        _totalSupply = 333333000 * 10**uint(decimals);
    }

    /*
     * Returns the total supply
     * minus the amounts of burned tokens.
     */
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

    /*
     * Returns the balance
     * of a given token holder.
     */
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    /*
     * Returns the locked balance
     * of a given token holder.
     */
    function lockedBalanceOf(address tokenOwner) public view returns (uint lockedBalance) {
        return lockedBalances[tokenOwner];
    }

    /*
     * Stores the frozen balances
     * of those who bought have
     * frozen their own balances
     * until a certain UNIX timestamp.
     */
    mapping(address => uint) frozenBalances;

    /*
     * Stores the UNIX timestamps
     * until when a certain token
     * holders' tokens have frozen
     * their own tokens.
     */
    mapping(address => uint) frozenTiming;

    /*
     * Method to freeze own
     * tokens until a certain time.
     */
    function freezeOwnTokens(uint amount, uint until) public {

        //FIRST AUTO UNFREEZE ANY PREVIOUSLY LOCKED TOKENS
        _autoUnfreeze();

        //AVAIL BALANCE MUST BE GREATER THAN TOKENS TO BE LOCKED
        require(balances[msg.sender] - lockedBalances[msg.sender] > amount);

        //ALSO CURRENTLY LOCKED AMOUNT MUST BE LESS THAN TOKENS TO BE LOCKED
        require(frozenBalances[msg.sender] < amount);

        //LOCK PERIOD MUST BE FUTURE, AND GREATER THAN CURRENT LOCK
        require(until > block.timestamp && until > frozenTiming[msg.sender]);

        //MAKE FREEZE
        frozenBalances[msg.sender] = amount;
        frozenTiming[msg.sender] = until;
    }

    /*
     * Returns the frozen balance
     * of a given token holder.
     */
    function frozenBalanceOf(address tokenOwner) public view returns (uint frozenBalance) {
        return frozenBalances[tokenOwner];
    }

    /*
     * Returns the UNIX timestamp
     * until when some tokens
     * of a given token holder
     * are frozen.
     */
    function frozenTimingOf(address tokenOwner) public view returns (uint until) {
        return frozenTiming[tokenOwner];
    }

    /*
     * Automatically unfreezes
     * all tokens of msg.sender
     * if freeze time has passed.
     */
    function _autoUnfreeze() private {

        if(frozenBalances[msg.sender] > 0 && block.timestamp > frozenTiming[msg.sender]){
            frozenBalances[msg.sender] = 0;
        }
    }

    /*
     * Private method to handle private
     * sale transfers.
     */
    function _privTransfer(address to, uint tokens) private returns (bool success) {

        //ONLY PRIVATE SELLER CAN EXECUTE PRIVATE SALE TRANSACTION
        require(msg.sender == roles[0], 'Only private seller can make private sale TX!');

        //NO PRIVATE SALE TRANSACTION CAN BE MADE AFTER PUBLIC SALE CLOSED
        require(block.timestamp < pubSaleEnd, 'No transfer from private seller after public sale!');

        //LOCK THE TOKEN AMOUNT OF THE BUYER
        lockedBalances[to] = lockedBalances[to].add(tokens);
        emit LockBalance(msg.sender, to, tokens);
        emit LogAddress('PrivateSaleFrom', msg.sender);
        //MAKE A REGULAR TRANSFER
        return _regularTransfer(to, tokens);
    }

    /*
     * Private method to handle public
     * sale (IEO) transfers.
     */
    function _pubTransfer(address to, uint tokens) private returns (bool success) {

        //MAKE SURE PRIVATE AND RESTRICTED TRANSACTIONS ARE NOT HANDLED HERE
        require(msg.sender != roles[0], 'Public transfer not allowed from private seller');

        //MAKE SURE THAT ONLY REGULAR TRANSACTIONS CAN BE EXECUTED NOT INVOLVING LOCKED TOKENS
        require(balances[msg.sender].sub(lockedBalances[msg.sender]) >= tokens, 'Not enough unlocked tokens!');
        emit LogAddress('PublicSaleFrom', msg.sender);
        //MAKE A REGULAR TRANSFER
        return _regularTransfer(to, tokens);
    }

    /*
     * Private method to handle secondary
     * market transfers (after IEO).
     */
    function _postPubTransfer(address to, uint tokens) private returns (bool success) {

        //IF PUBLIC SALE ENDED AND EXCHANGE OR PRIVATE SELLER TRIES TO MAKE A TRANSFER
        if(block.timestamp > pubSaleEnd + 7 * 24 * 60 * 60 && (msg.sender == roles[1] || msg.sender == roles[0])){
            revert('No transfer from exchange / private seller after public sale!');
        }

        //IF PRIVATE SALE RESTRICTIONS DID NOT END YET AND SENDER IS A PRIVATE SALE BUYER
        if(block.timestamp < restrictionEnd && lockedBalances[msg.sender] > 0){
            emit LogAddress('RestrictedSaleFrom', msg.sender);
            return _restrictedTransfer(to, tokens);
        }
        emit LogAddress('PostPublicSaleFrom', msg.sender);
        //ELSE MAKE A REGULAR TRANSFER
        return _regularTransfer(to, tokens);
    }

    /*
     * Makes sure that private sale buyers
     * can withdraw unsold tokens on exchanges
     * even if restrictions are active.
     */
    mapping(address => address) withdrawMap;

    /*
     * Private method to handle transactions
     * of private sale buyers to whom certain
     * restrictions apply to protect market prices.
     */
    function _restrictedTransfer(address to, uint tokens) private returns (bool success) {

        //DECLARE CURRENT BALANCES
        uint totalBalance = balances[msg.sender];
        uint lockedBalance = lockedBalances[msg.sender];
        uint unlockedBalance = totalBalance.sub(lockedBalance);

        //IF PRICE IS LOW, THIS ADDRESS IS RESTRICTED, AND IS NOT TRYING TO WITHDRAW TO HIS PREVIOUS ACCOUNT
        if(conversionRate < 39 && unlockedBalance < tokens && to != withdrawMap[msg.sender]){
            revert('Private token trading halted because of low market prices!');
        }

        //IF THERE IS NOT ENOUGH UNLOCKED BALANCE TO SEND TOKENS
        if(unlockedBalance < tokens){

            //CALCULATE TOKENS TO BE LOCKED ON RECIPIENT'S ACCOUNT
            uint lockables = tokens.sub(unlockedBalance);

            //LOCK THEM
            lockedBalances[to] = lockedBalances[to].add(lockables);
            emit LockBalance(msg.sender, to, lockables);

            //RELEASE LOCK ON SENDER
            lockedBalances[msg.sender] = lockedBalances[msg.sender].sub(lockables);

            //UPDATE WITHDRAW MAP TO ENABLE SENDER TO SEND FUNDS BACK TO HIMSELF LATER
            withdrawMap[to] = msg.sender;
        }

        //PERFORM A REGULAR TRANSFER
        return _regularTransfer(to, tokens);
    }

    /*
     * Performs a regular
     * ERC20 transfer.
     */
    function _regularTransfer(address to, uint tokens) private returns (bool success) {

        //DEDUCT FROM SENDER, CREDIT BENEFICIARY
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    /*
     * Transfer logic to handle
     * all possible scenarios:
     * - Private sale
     * - Public sale (IEO)
     * - Secondary market trading
     */
    function transfer(address to, uint tokens) public returns (bool success) {

        //AUTOMATICALLY UNFREEZE ANY UNFREEZABLE TOKENS
        _autoUnfreeze();

        //IF THE SENDER STILL HAS FROZEN BALANCE, CHECK FOR LIQUIDITY
        if(frozenBalances[msg.sender] > 0 && balances[msg.sender] - frozenBalances[msg.sender] < tokens){
            revert('Frozen balance can not be spent yet, insufficient tokens!');
        }

        //REQUIRE THAT SENDER HAS THE BALANCE TO MAKE THE TRANSFER
        require(balances[msg.sender] >= tokens, 'Not enough liquid tokens!');

        //IF RESERVE IS TRYING TO MAKE A TRANSFER AND 1 YEAR FREEZE NOT PASSED YET, REVERT
        if(msg.sender == roles[4] && block.timestamp < pubSaleEnd + 60 * 60 * 24 * 30 * 12){
            revert('Reserve can not be accessed before the 1 year freeze period');
        }

        //HANDLE PRIVATE SALE TRANSACTIONS
        if(msg.sender == roles[0]){
            return _privTransfer(to, tokens);
        }

        //HANDLE PUBLIC SALE TRANSACTIONS
        if(block.timestamp > pubSaleStart && block.timestamp < pubSaleEnd){
            return _pubTransfer(to, tokens);
        }

        //HANDLE TRANSACTIONS AFTER PUBLIC SALE ENDED
        if(block.timestamp > pubSaleEnd){
            return _postPubTransfer(to, tokens);
        }

        //NO CASES MATCHED
        return false;
    }

    /*
     * Grant spend ability
     * of tokens to a third party.
     */
    function approve(address spender, uint tokens) public returns (bool success) {

        //DURING RESTRICTION PERIOD, NO APPROVAL TRANSFERS FOR PRIV BUYERS
        if(block.timestamp < restrictionEnd){
            require(lockedBalances[msg.sender] == 0, 'This address MUST not start approval related transactions!');
            require(lockedBalances[spender] == 0, 'This address MUST not start approval related transactions!');
        }

        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    /*
     * Transfer tokens from another
     * address given they granted approval
     * to msg.sender of the current call.
     */
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {

        //DURING RESTRICTION PERIOD, NO APPROVAL TRANSFERS FOR PRIV BUYERS
        if(block.timestamp < restrictionEnd){
            require(lockedBalances[msg.sender] == 0, 'This address MUST not start approval related transactions!');
            require(lockedBalances[from] == 0, 'This address MUST not start approval related transactions!');
            require(lockedBalances[to] == 0, 'This address MUST not start approval related transactions!');
        }

        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    /*
     * Returns the amount of tokens a
     * spender is allowed to spend
     * from tokenOwner's balance.
     */
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function () external payable {

        //DON'T ACCEPT ETH
        revert();
    }

    /*
     * Enables the contract owner
     * to retrieve other ERC20 tokens
     * sent to the contract.
     */
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}