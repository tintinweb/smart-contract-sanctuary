pragma solidity ^0.4.24;

contract ERC20Interface {
    function name() public constant returns (string);
    function symbol() public constant returns (string);
    function decimals() public constant returns (uint8);
    function totalSupply() public constant returns (uint);
    function balanceOf(address _owner) public constant returns (uint);
    function transfer(address _to, uint _value) public returns (bool);
    function transferFrom(address _from, address _to, uint _value) public returns (bool);
    function approve(address _spender, uint _value) public returns (bool);
    function allowance(address _owner, address _spender) public constant returns (uint);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract WeduToken is ERC20Interface {
    /**
     * @dev Constant parameters
     */
    string private TOKEN_NAME;
    string private TOKEN_SYMBOL;
    uint8 private DECIMAL;
    uint private WEDU_UNIT;

    /**
     * @dev Management parameters
     */
    address owner;
    mapping(address => bool) internal blackList;

    /**
     * @dev Balance parameters
     */
    uint private totalSupplyValue;
    struct BalanceType {
        uint locked;
        uint unlocked;
    }

    mapping(address => mapping (address => uint)) internal allowed;
    mapping(address => BalanceType) internal balanceValue;


    /**
     * @dev Modifier, Only owner can execute the function
     */
    modifier onlyOwner() { require(owner == msg.sender, "Not a owner"); _;}

    /**
     * @dev Event, called when the number of token changed
     */
    event ChangeNumberofToken(uint oldValue, uint newValue);

    /**
     * @dev Constructor, Initialize the name, symbol, etc.
     */
    constructor() public {
        TOKEN_NAME = "Educo-op";
        TOKEN_SYMBOL = "WEDU";

        DECIMAL = 18;
        WEDU_UNIT = 1000000000000000000;
        totalSupplyValue = 10000000000 * WEDU_UNIT;

        owner = msg.sender;
        balanceValue[owner].unlocked = totalSupplyValue;
    }

    /**
     * @dev Main info for WEDU token
     */
    function name() public constant returns (string){ return TOKEN_NAME; }
    function symbol() public constant returns (string){ return TOKEN_SYMBOL; }
    function decimals() public constant returns (uint8){ return DECIMAL; }
    function totalSupply() public constant returns (uint){ return totalSupplyValue; }

    /**
     * @dev Balance info of WEDU token for each user
     */
    function balanceOf(address _user) public constant returns (uint){ return balanceValue[_user].unlocked+balanceValue[_user].locked; }
    function balanceOfLocked(address _user) public constant returns (uint){ return balanceValue[_user].locked; }
    function balanceOfUnlocked(address _user) public constant returns (uint){ return balanceValue[_user].unlocked; }

    /**
     * @dev Lock the WEDU token in users
     * @param _who The user for locking WEDU token
     * @param _value The amount of locking WEDU token
     */
    function lockBalance(address _who, uint _value) public onlyOwner {
        // Check the unlocked balance of a user
        require(_value <= balanceValue[_who].unlocked, "Unsufficient balance");

        uint totalBalanceValue = balanceValue[_who].locked + balanceValue[_who].unlocked;

        balanceValue[_who].unlocked -= _value;
        balanceValue[_who].locked += _value;

        assert(totalBalanceValue == balanceValue[_who].locked + balanceValue[_who].unlocked);
    }

    /**
     * @dev Unlock the WEDU token in users
     * @param _who The user for unlocking WEDU token
     * @param _value The amount of unlocking WEDU token
     */
    function unlockBalance(address _who, uint _value) public onlyOwner {
        // Check the locked balance of a user
        require(_value <= balanceValue[_who].locked, "Unsufficient balance");

        uint totalBalanceValue = balanceValue[_who].locked + balanceValue[_who].unlocked;

        balanceValue[_who].locked -= _value;
        balanceValue[_who].unlocked += _value;

        assert(totalBalanceValue == balanceValue[_who].locked + balanceValue[_who].unlocked);
    }

    /**
     * @dev Transfer the WEDU token
     * @param _from The user who will transmit WEDU token
     * @param _to The user who will receive WEDU token
     * @param _value The amount of WEDU token transmits to user
     * @return True when the WEDU token transfer success
     */
    function _transfer(address _from, address _to, uint _value) internal returns (bool){
        // Check the address
        require(_from != address(0), "Address is wrong");
        require(_from != owner, "Owner uses the privateTransfer");
        require(_to != address(0), "Address is wrong");

        // Check a user included in blacklist
        require(!blackList[_from], "Sender in blacklist");
        require(!blackList[_to], "Receiver in blacklist");

        // Check the unlocked balance of a user
        require(_value <= balanceValue[_from].unlocked, "Unsufficient balance");
        require(balanceValue[_to].unlocked <= balanceValue[_to].unlocked + _value, "Overflow");

        uint previousBalances = balanceValue[_from].unlocked + balanceValue[_to].unlocked;

        balanceValue[_from].unlocked -= _value;
        balanceValue[_to].unlocked += _value;

        emit Transfer(_from, _to, _value);

        assert(balanceValue[_from].unlocked + balanceValue[_to].unlocked == previousBalances);
        return true;
    }

    function transfer(address _to, uint _value) public returns (bool){
        return _transfer(msg.sender, _to, _value);
    }

    /**
     * @dev Educo-op transfers the WEDU token to a user
     * @param _to The user who will receive WEDU token
     * @param _value The amount of WEDU token transmits to a user
     * @return True when the WEDU token transfer success
     */
    function privateTransfer(address _to, uint _value) public onlyOwner returns (bool) {
        // Check the address
        require(_to != address(0), "Address is wrong");

        // Account balance validation
        require(_value <= balanceValue[owner].unlocked, "Unsufficient balance");
        require(balanceValue[_to].unlocked <= balanceValue[_to].unlocked + _value, "Overflow");

        uint previousBalances = balanceValue[owner].unlocked + balanceValue[_to].locked;

        balanceValue[owner].unlocked -= _value;
        balanceValue[_to].locked += _value;

        emit Transfer(msg.sender, _to, _value);

        assert(balanceValue[owner].unlocked + balanceValue[_to].locked == previousBalances);
        return true;
    }

    /**
     * @dev Educo-op transfers the WEDU token to multiple users simultaneously
     * @param _tos The users who will receive WEDU token
     * @param _nums The number of users that will receive WEDU token
     * @param _submitBalance The amount of WEDU token transmits to users
     * @return True when the WEDU token transfer success to all users
     */
    function multipleTransfer(address[] _tos, uint _nums, uint _submitBalance) public onlyOwner returns (bool){
        // Check the input parameters
        require(_tos.length == _nums, "Number of users who receives the token is not match");
        require(_submitBalance < 100000000 * WEDU_UNIT, "Too high submit balance");
        require(_nums < 256, "Two high number of users");
        require(_nums*_submitBalance <= balanceValue[owner].unlocked, "Unsufficient balance");

        balanceValue[owner].unlocked -= (_nums*_submitBalance);
        uint8 numIndex;
        for(numIndex=0; numIndex < _nums; numIndex++){
            require(balanceValue[_tos[numIndex]].unlocked == 0, "Already user has token");
            require(_tos[numIndex] != address(0));
            balanceValue[_tos[numIndex]].unlocked = _submitBalance;

            emit Transfer(owner, _tos[numIndex], _submitBalance);
        }
        return true;
    }

    /**
     * @dev Receive the WEDU token from other user
     * @param _from The users who will transmit WEDU token
     * @param _to The users who will receive WEDU token
     * @param _value The amount of WEDU token transmits to user
     * @return True when the WEDU token transfer success
     */
    function transferFrom(address _from, address _to, uint _value) public returns (bool){
        // Check the unlocked balance and allowed balance of a user
        require(allowed[_from][msg.sender] <= balanceValue[_from].unlocked, "Unsufficient allowed balance");
        require(_value <= allowed[_from][msg.sender], "Unsufficient balance");

        allowed[_from][msg.sender] -= _value;
        return _transfer(_from, _to, _value);
    }

    /**
     * @dev Approve the WEDU token transfer to other user
     * @param _spender A user allowed to receive WEDU token
     * @param _value The amount of WEDU token allowed to receive at a user
     * @return True when the WEDU token successfully allowed
     */
    function approve(address _spender, uint _value) public returns (bool){
        // Check the address
        require(msg.sender != owner, "Owner uses the privateTransfer");
        require(_spender != address(0), "Address is wrong");
        require(_value <= balanceValue[msg.sender].unlocked, "Unsufficient balance");

        // Check a user included in blacklist
        require(!blackList[msg.sender], "Sender in blacklist");
        require(!blackList[_spender], "Receiver in blacklist");

        // Is really first Approve??
        require(allowed[msg.sender][_spender] == 0, "Already allowed token exists");

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Get the amount of WEDU token that allowed to the user
     * @param _owner A user who allowed WEDU token transmission
     * @param _spender A user who allowed WEDU token reception
     * @return The amount of WEDU token that allowed to the user
     */
    function allowance(address _owner, address _spender) public constant returns (uint){
        // Only the user who related with the token allowance can see the allowance value
        require(msg.sender == _owner || msg.sender == _spender);
        return allowed[_owner][_spender];
    }

    /**
     * @dev Increase the amount of WEDU token that allowed to the user
     * @param _spender A user who allowed WEDU token reception
     * @param _addedValue The amount of WEDU token for increasing
     * @return True when the amount of allowed WEDU token successfully increases
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool){
        // Check the address
        require(_spender != address(0), "Address is wrong");
        require(allowed[msg.sender][_spender] > 0, "Not approved until yet");

        // Check a user included in blacklist
        require(!blackList[msg.sender], "Sender in blacklist");
        require(!blackList[_spender], "Receiver in blacklist");

        uint oldValue = allowed[msg.sender][_spender];
        require(_addedValue + oldValue <= balanceValue[msg.sender].unlocked, "Unsufficient balance");

        allowed[msg.sender][_spender] = _addedValue + oldValue;
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of WEDU token that allowed to the user
     * @param _spender A user who allowed WEDU token reception
     * @param _substractedValue The amount of WEDU token for decreasing
     * @return True when the amount of allowed WEDU token successfully decreases
     */
    function decreaseApproval(address _spender, uint _substractedValue) public returns (bool){
        // Check the address
        require(_spender != address(0), "Address is wrong");
        require(allowed[msg.sender][_spender] > 0, "Not approved until yet");

        // Check a user included in blacklist
        require(!blackList[msg.sender], "Sender in blacklist");
        require(!blackList[_spender], "Receiver in blacklist");

        uint oldValue = allowed[msg.sender][_spender];
        if (_substractedValue > oldValue){
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue - _substractedValue;
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Add the blacklist member
     * @param _who A user who will be blocked
     */
    function addBlackList(address _who) public onlyOwner {
        require(!blackList[_who], "Already, sender in blacklist");
        blackList[_who] = true;
    }

    /**
     * @dev Remove the blacklist member
     * @param _who A user who will be unblocked
     */
    function removalBlackList(address _who) public onlyOwner {
        require(blackList[_who], "Sender does not included in blacklist");
        blackList[_who] = false;
    }

    /**
     * @dev Increase the total amount of WEDU token
     * @param _value The amount of WEDU token for increasing
     * @return True when the amount of total WEDU token successfully increases
     */
    function tokenIssue(uint _value) public onlyOwner returns (bool) {
        require(totalSupplyValue <= totalSupplyValue + _value, "Overflow");
        uint oldTokenNum = totalSupplyValue;

        totalSupplyValue += _value;
        balanceValue[owner].unlocked += _value;

        emit ChangeNumberofToken(oldTokenNum, totalSupplyValue);
        return true;
    }

    /**
     * @dev Decrease the total amount of WEDU token
     * @param _value The amount of WEDU token for decreasing
     * @return True when the amount of total WEDU token successfully decreases
     */
    function tokenBurn(uint _value) public onlyOwner returns (bool) {
        require(_value <= balanceValue[owner].unlocked, "Unsufficient balance");
        uint oldTokenNum = totalSupplyValue;

        totalSupplyValue -= _value;
        balanceValue[owner].unlocked -= _value;

        emit ChangeNumberofToken(oldTokenNum, totalSupplyValue);
        return true;
    }

    /**
     * @dev Migrate the owner of this contract
     * @param _owner The user who will receive the manager authority
     * @return The user who receivee the manager authority
     */
    function ownerMigration (address _owner) public onlyOwner returns (address) {
        owner = _owner;
        return owner;
    }


    /**
     * @dev Kill contract
     */
    function kill() public onlyOwner {
        selfdestruct(owner);
    }
}