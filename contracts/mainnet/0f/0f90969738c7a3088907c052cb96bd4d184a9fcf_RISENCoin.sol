/**
* @title ERC20Basic
* @dev Simpler version of ERC20 interface
* @dev see https://github.com/ethereum/EIPs/issues/179
*/
contract ERC20Basic {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}
/**
* @title ERC20 interface
* @dev see https://github.com/ethereum/EIPs/issues/20
*/
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
* @title Basic token
* @dev Basic version of StandardToken, with no allowances.
*/
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    uint256 totalSupply_;
    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}
/**
* @title Standard ERC20 token
*
* @dev Implementation of the basic standard token.
* @dev https://github.com/ethereum/EIPs/issues/20
* @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
*/
contract StandardToken is ERC20, BasicToken {
    mapping(address => mapping(address => uint256)) internal allowed;
    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    *
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    *
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _addedValue The amount of tokens to increase the allowance by.
    */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    *
    * approve should be called when allowed[_spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        }
        else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control
* functions, this simplifies the implementation of "user permissions".
*/
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable() public {
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
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
* @title Pausable
* @dev Base contract which allows children to implement an emergency stop mechanism.
*/
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;
    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused);
        _;
    }
    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() onlyOwner whenNotPaused public
    {paused = true;
        Pause();
    }
    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

/**
* @title Pausable token
* @dev StandardToken modified with pausable transfers.
**/
contract PausableToken is StandardToken, Pausable {
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool){
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success)
    {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

/**
* @title Mintable token
* @dev Simple ERC20 Token example, with mintable token creation
* @dev Issue:
* https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
* Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
*/
contract MintableToken is StandardToken, Ownable {event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;
    modifier canMint() {require(!mintingFinished);
        _;
    }
    /**
    * @dev Function to mint tokens
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }
    /**
    * @dev Function to stop minting new tokens.
    * @return True if the operation was successful.
    */
    function finishMinting() onlyOwner canMint public returns (bool) {mintingFinished = true;
        MintFinished();
        return true;}
}



/**
* @title SafeERC20
* @dev Wrappers around ERC20 operations that throw on failure.
* To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
* which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
*/
library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}
/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256)
    {
        // assert(b > 0);
        // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b);
        // There is no case in which this doesn&#39;t hold
        return c;
    }
    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
/**
* @title SimpleToken
* @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
* Note they can later distribute these tokens as they wish using `transfer` and other
* `StandardToken` functions.
*/
contract SimpleToken is StandardToken {
    string public constant name = "SimpleToken";
    // solium-disable-line uppercase
    string public constant symbol = "SIM";
    // solium-disable-line uppercase
    uint8 public constant decimals = 18;
    // solium-disable-line uppercase
    uint256 public constant INITIAL_SUPPLY = 10000 * (10 ** uint256(decimals));
    /**
    * @dev Constructor that gives msg.sender all of existing tokens.
    */
    function SimpleToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
}

/**
* @title BiometricLock
* @dev BiometricLock in which only unlocked users can execute methods
*/
contract BiometricLockable is Ownable {
    event BiometricLocked(address beneficiary, bytes32 sha);
    event BiometricUnlocked(address beneficiary);

    address BOPS;
    mapping(address => bool) biometricLock;
    mapping(bytes32 => bool) biometricCompleted;
    mapping(bytes32 => uint256) biometricNow;
    /**
    * @dev Locks msg.sender address
    */
    function bioLock() external {
        uint rightNow = now;
        bytes32 sha = keccak256("bioLock", msg.sender, rightNow);
        biometricLock[msg.sender] = true;
        biometricNow[sha] = rightNow;
        BiometricLocked(msg.sender, sha);
    }
    /**
    * @dev Unlocks msg.sender single address.  v,r,s is the sign(sha) by BOPS
    */
    function bioUnlock(bytes32 sha, uint8 v, bytes32 r, bytes32 s) external {
        require(biometricLock[msg.sender]);
        require(!biometricCompleted[sha]);
        bytes32 bioLockSha = keccak256("bioLock", msg.sender, biometricNow[sha]);
        require(sha == bioLockSha);
        require(verify(sha, v, r, s) == true);
        biometricLock[msg.sender] = false;
        BiometricUnlocked(msg.sender);
        biometricCompleted[sha] = true;
    }

    function isSenderBiometricLocked() external view returns (bool) {
        return biometricLock[msg.sender];
    }

    function isBiometricLocked(address _beneficiary) internal view returns (bool){
        return biometricLock[_beneficiary];
    }

    function isBiometricLockedOnlyOwner(address _beneficiary) external onlyOwner view returns (bool){
        return biometricLock[_beneficiary];
    }
    /**
    * @dev BOPS Address setter.  BOPS signs biometric authentications to ensure user&#39;s identity
    *
    */
    function setBOPSAddress(address _BOPS) external onlyOwner {
        require(_BOPS != address(0));
        BOPS = _BOPS;
    }

    function verify(bytes32 sha, uint8 v, bytes32 r, bytes32 s) internal view returns (bool) {
        require(BOPS != address(0));
        return ecrecover(sha, v, r, s) == BOPS;
    }

    function isBiometricCompleted(bytes32 sha) external view returns (bool) {
        return biometricCompleted[sha];
    }
}

/**
* @title BiometricToken
* @dev BiometricToken is a token contract that can enable Biometric features for ERC20 functions
*/
contract BiometricToken is Ownable, MintableToken, BiometricLockable {
    event BiometricTransferRequest(address from, address to, uint256 amount, bytes32 sha);
    event BiometricApprovalRequest(address indexed owner, address indexed spender, uint256 value, bytes32 sha);
    // Transfer related methods variables
    mapping(bytes32 => address) biometricFrom;
    mapping(bytes32 => address) biometricAllowee;
    mapping(bytes32 => address) biometricTo;
    mapping(bytes32 => uint256) biometricAmount;

    function transfer(address _to, uint256 _value) public returns (bool) {
        if (isBiometricLocked(msg.sender)) {
            require(_value <= balances[msg.sender]);
            require(_to != address(0));
            require(_value > 0);
            uint rightNow = now;
            bytes32 sha = keccak256("transfer", msg.sender, _to, _value, rightNow);
            biometricFrom[sha] = msg.sender;
            biometricTo[sha] = _to;
            biometricAmount[sha] = _value;
            biometricNow[sha] = rightNow;
            BiometricTransferRequest(msg.sender, _to, _value, sha);
            return true;
        }
        else {
            return super.transfer(_to, _value);
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if (isBiometricLocked(_from)) {
            require(_value <= balances[_from]);
            require(_value <= allowed[_from][msg.sender]);
            require(_to != address(0));
            require(_from != address(0));
            require(_value > 0);
            uint rightNow = now;
            bytes32 sha = keccak256("transferFrom", _from, _to, _value, rightNow);
            biometricAllowee[sha] = msg.sender;
            biometricFrom[sha] = _from;
            biometricTo[sha] = _to;
            biometricAmount[sha] = _value;
            biometricNow[sha] = rightNow;
            BiometricTransferRequest(_from, _to, _value, sha);
            return true;
        }
        else {
            return super.transferFrom(_from, _to, _value);
        }
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        if (isBiometricLocked(msg.sender)) {
            uint rightNow = now;
            bytes32 sha = keccak256("approve", msg.sender, _spender, _value, rightNow);
            biometricFrom[sha] = msg.sender;
            biometricTo[sha] = _spender;
            biometricAmount[sha] = _value;
            biometricNow[sha] = rightNow;
            BiometricApprovalRequest(msg.sender, _spender, _value, sha);
            return true;
        }
        else {
            return super.approve(_spender, _value);
        }
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        if (isBiometricLocked(msg.sender)) {
            uint newValue = allowed[msg.sender][_spender].add(_addedValue);
            uint rightNow = now;
            bytes32 sha = keccak256("increaseApproval", msg.sender, _spender, newValue, rightNow);
            biometricFrom[sha] = msg.sender;
            biometricTo[sha] = _spender;
            biometricAmount[sha] = newValue;
            biometricNow[sha] = rightNow;
            BiometricApprovalRequest(msg.sender, _spender, newValue, sha);
            return true;
        }
        else {
            return super.increaseApproval(_spender, _addedValue);
        }
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        if (isBiometricLocked(msg.sender)) {
            uint oldValue = allowed[msg.sender][_spender];
            uint newValue;
            if (_subtractedValue > oldValue) {
                newValue = 0;
            }
            else {
                newValue = oldValue.sub(_subtractedValue);
            }
            uint rightNow = now;
            bytes32 sha = keccak256("decreaseApproval", msg.sender, _spender, newValue, rightNow);
            biometricFrom[sha] = msg.sender;
            biometricTo[sha] = _spender;
            biometricAmount[sha] = newValue;
            biometricNow[sha] = rightNow;
            BiometricApprovalRequest(msg.sender, _spender, newValue, sha);
            return true;
        }
        else {
            return super.decreaseApproval(_spender, _subtractedValue);
        }
    }
    /**
    * @notice Complete pending transfer, can only be called by msg.sender if it is the originator of Transfer
    */
    function releaseTransfer(bytes32 sha, uint8 v, bytes32 r, bytes32 s) public returns (bool){
        require(msg.sender == biometricFrom[sha]);
        require(!biometricCompleted[sha]);
        bytes32 transferFromSha = keccak256("transferFrom", biometricFrom[sha], biometricTo[sha], biometricAmount[sha], biometricNow[sha]);
        bytes32 transferSha = keccak256("transfer", biometricFrom[sha], biometricTo[sha], biometricAmount[sha], biometricNow[sha]);
        require(sha == transferSha || sha == transferFromSha);
        require(verify(sha, v, r, s) == true);
        if (transferFromSha == sha) {
            address _spender = biometricAllowee[sha];
            address _from = biometricFrom[sha];
            address _to = biometricTo[sha];
            uint256 _value = biometricAmount[sha];
            require(_to != address(0));
            require(_value <= balances[_from]);
            require(_value <= allowed[_from][_spender]);
            balances[_from] = balances[_from].sub(_value);
            balances[_to] = balances[_to].add(_value);
            allowed[msg.sender][_spender] = allowed[msg.sender][_spender].sub(_value);
            Transfer(_from, _to, _value);
        }
        if (transferSha == sha) {
            super.transfer(biometricTo[sha], biometricAmount[sha]);
        }
        biometricCompleted[sha] = true;
        return true;
    }
    /**
    * @notice Cancel pending transfer, can only be called by msg.sender == biometricFrom[sha]
    */
    function cancelTransfer(bytes32 sha) public returns (bool){
        require(msg.sender == biometricFrom[sha]);
        require(!biometricCompleted[sha]);
        biometricCompleted[sha] = true;
        return true;
    }
    /**
    * @notice Complete pending Approval, can only be called by msg.sender if it is the originator of Approval
    */
    function releaseApprove(bytes32 sha, uint8 v, bytes32 r, bytes32 s) public returns (bool){
        require(msg.sender == biometricFrom[sha]);
        require(!biometricCompleted[sha]);
        bytes32 approveSha = keccak256("approve", biometricFrom[sha], biometricTo[sha], biometricAmount[sha], biometricNow[sha]);
        bytes32 increaseApprovalSha = keccak256("increaseApproval", biometricFrom[sha], biometricTo[sha], biometricAmount[sha], biometricNow[sha]);
        bytes32 decreaseApprovalSha = keccak256("decreaseApproval", biometricFrom[sha], biometricTo[sha], biometricAmount[sha], biometricNow[sha]);
        require(approveSha == sha || increaseApprovalSha == sha || decreaseApprovalSha == sha);
        require(verify(sha, v, r, s) == true);
        super.approve(biometricTo[sha], biometricAmount[sha]);
        biometricCompleted[sha] = true;
        return true;
    }
    /**
    * @notice Cancel pending Approval, can only be called by msg.sender == biometricFrom[sha]
    */
    function cancelApprove(bytes32 sha) public returns (bool){
        require(msg.sender == biometricFrom[sha]);
        require(!biometricCompleted[sha]);
        biometricCompleted[sha] = true;
        return true;
    }
}

contract CompliantToken is BiometricToken {
    //list of praticipants that have purchased during the presale period
    mapping(address => bool) presaleHolder;
    //list of presale participants and date when their tokens are unlocked
    mapping(address => uint256) presaleHolderUnlockDate;
    //list of participants from the United States
    mapping(address => bool) utilityHolder;
    //list of Hoyos Integrity Corp addresses that accept RSN as payment for service
    mapping(address => bool) allowedHICAddress;
    //list of addresses that can add to presale address list (i.e. crowdsale contract)
    mapping(address => bool) privilegeAddress;

    function transfer(address _to, uint256 _value) public returns (bool) {
        if (presaleHolder[msg.sender]) {
            if (now >= presaleHolderUnlockDate[msg.sender]) {
                return super.transfer(_to, _value);
            }
            else {
                require(allowedHICAddress[_to]);
                return super.transfer(_to, _value);
            }
        }
        if (utilityHolder[msg.sender]) {
            require(allowedHICAddress[_to]);
            return super.transfer(_to, _value);
        }
        else {
            return super.transfer(_to, _value);
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if (presaleHolder[_from]) {
            if (now >= presaleHolderUnlockDate[_from]) {
                return super.transferFrom(_from, _to, _value);
            }
            else {
                require(allowedHICAddress[_to]);
                return super.transferFrom(_from, _to, _value);
            }
        }
        if (utilityHolder[_from]) {
            require(allowedHICAddress[_to]);
            return super.transferFrom(_from, _to, _value);
        }
        else {
            return super.transferFrom(_from, _to, _value);
        }
    }
    // Allowed HIC addresses to methods: set, remove, is
    function addAllowedHICAddress(address _beneficiary) onlyOwner public {
        allowedHICAddress[_beneficiary] = true;
    }

    function removeAllowedHICAddress(address _beneficiary) onlyOwner public {
        allowedHICAddress[_beneficiary] = false;
    }

    function isAllowedHICAddress(address _beneficiary) onlyOwner public view returns (bool){
        return allowedHICAddress[_beneficiary];
    }
    // Utility Holders methods: set, remove, is
    function addUtilityHolder(address _beneficiary) public {
        require(privilegeAddress[msg.sender]);
        utilityHolder[_beneficiary] = true;}

    function removeUtilityHolder(address _beneficiary) onlyOwner public {
        utilityHolder[_beneficiary] = false;
    }

    function isUtilityHolder(address _beneficiary) onlyOwner public view returns (bool){
        return utilityHolder[_beneficiary];
    }
    // Presale Holders methods: set, remove, is
    function addPresaleHolder(address _beneficiary) public {
        require(privilegeAddress[msg.sender]);
        presaleHolder[_beneficiary] = true;
        presaleHolderUnlockDate[_beneficiary] = now + 1 years;
    }

    function removePresaleHolder(address _beneficiary) onlyOwner public {
        presaleHolder[_beneficiary] = false;
        presaleHolderUnlockDate[_beneficiary] = now;
    }

    function isPresaleHolder(address _beneficiary) onlyOwner public view returns (bool){
        return presaleHolder[_beneficiary];
    }
    // Presale Priviledge Addresses methods: set, remove, is
    function addPrivilegeAddress(address _beneficiary) onlyOwner public {
        privilegeAddress[_beneficiary] = true;
    }

    function removePrivilegeAddress(address _beneficiary) onlyOwner public {
        privilegeAddress[_beneficiary] = false;
    }

    function isPrivilegeAddress(address _beneficiary) onlyOwner public view returns (bool){
        return privilegeAddress[_beneficiary];
    }
}

contract RISENCoin is CompliantToken, PausableToken {
    string public name = "RISEN";
    string public symbol = "RSN";
    uint8 public decimals = 18;
}