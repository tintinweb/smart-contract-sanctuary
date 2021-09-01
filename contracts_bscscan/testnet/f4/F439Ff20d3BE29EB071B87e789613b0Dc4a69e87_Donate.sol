/**
 *Submitted for verification at BscScan.com on 2021-09-01
*/

pragma solidity ^0.4.24;

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

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
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract EIP20Interface {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

library SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns(uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    function safeSub(uint256 a, uint256 b) internal pure returns(uint256)
    {
        assert(b <= a);
        return a - b;
    }
    function safeMul(uint256 a, uint256 b) internal pure returns(uint256)
    {
        if (a == 0) {
        return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function safeDiv(uint256 a, uint256 b) internal pure returns(uint256)
    {
        uint256 c = a / b;
        return c;
    }
}

contract LockInterface {
     function put(address _addr, uint256 _value) public returns (bool success);
     function withdraw() public returns (bool success);
}

contract Donate is EIP20Interface, Ownable, Pausable {
    using SafeMath for uint256;
    uint constant public PERCENTS_DIVIDER = 100000;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    address public receiver; // USD Treceiver
    address public platform; // platform
    EIP20Interface public inCoin;
    LockInterface public lockInt;
    uint256 public minDonate = 100000000;
    uint8 public index = 0; // index
    uint8 public maxIndex = 0; // maxIndex
    bool public donateEnd = false;
    
    /* This creates an array with all balances */
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public freezeOf;
    mapping(address => mapping (address => uint256)) public allowance;
    
    mapping(address => User) public users;
    mapping(uint8 => Rule) public rules;
    
    //mapping (uint8 => mapping(uint8 => uint256)) public indexRemain; // 1: airdrop remain 2: 
    //mapping (address => mapping(uint8 => uint256)) public donateOf; // 1: donate, 2: own 3: inviter 4: node
    
    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
 
    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
 
    /* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);
 
    /* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);
    
    /* This notifies clients about the amount Donate */
    event NewDonate(address indexed from, uint256 indexed ownReward, uint256 indexed inviterReward, uint256 nodeReward);
    
    struct User {
        address inviter;
        bool isNode;
        bool isUsed;
        address upNode;
        mapping(uint8 => uint256)  donateOf; // 1: donate, 2: own 3: inviter 4: node
    }
    
    struct Rule {
        uint8 index; // index
        uint256 airdrop; // airdrop amount
        uint32 upProp; // Inviter reward ratio
        uint32 nodeProp; //   Inviter reward ratio
        uint32 priceProP;  // price = priceProP/PERCENTS_DIVIDER
        mapping(uint8 => uint256) indexRemain; // 1: airdrop remain 2: reward remain
    }
 
    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint8 initDecimals,
        address _holder, 
        address _rece, 
        address _platform,
        address _inCoin
    ) public {
        decimals = initDecimals;
        totalSupply = initialSupply;                           //  total supply
        balanceOf[_holder] = totalSupply;                       // Give the creator all initial tokens
        name = tokenName;                                      // Set the name for display purposes
        symbol = tokenSymbol;                                  // Set the symbol for display purposes
        owner = _holder;
        receiver = _rece;
        inCoin = EIP20Interface(_inCoin);
        platform =_platform;
    }
    
    /* stopDonate */
    function stopDonate() public onlyOwner returns (bool success){
        require(maxIndex > 0 && index == maxIndex, 'has the next issue!!');
        donateEnd = true ;
        return true;
    }
    
    /* start next index */
    function stratNextIndex() public onlyOwner returns (bool success){
        require(maxIndex > 0, 'no next issue ');
        require(index < maxIndex, 'no next issue ');
        index += 1 ;
        return true;
    }
    
    /* set Lock contract */
    function setLockAddr(address _addr) public onlyOwner returns (bool success){
        require(_addr != address(0), 'address 0 ');
        lockInt = LockInterface(_addr);
        return true;
    }
    
    /* setnode */
    function setNode(address _addr, bool _set) public onlyOwner returns (bool success){
        require(users[_addr].isUsed, "this account is not activated");
        if(_set)
            users[_addr].isNode = true;
        else
            users[_addr].isNode = false;
        
        return true;
    }
    
    /* setRule */
    function setRule(uint256 _airdrop, uint256 _reward, uint32 _inviterProp, uint32 _nodeProp, uint32 _priceProp, uint8 _isAdd, uint8 _index) public onlyOwner returns (bool success){
        require((_isAdd == 0 && _index <= maxIndex) || _isAdd == 1, 'index error !');
        uint8 nowIndex = _isAdd == 1 ? maxIndex + 1: _index;
        Rule storage rule = rules[nowIndex];
        rule.airdrop= _airdrop;
        rule.index = nowIndex;
        rule.upProp =_inviterProp;
        rule.nodeProp =_nodeProp;
        rule.priceProP =_priceProp;
        rule.indexRemain[1] = _airdrop;
        rule.indexRemain[2] = _reward;
        
        if(_isAdd == 1)
            maxIndex += 1; 
        
        return true;
    }

    /* setMinDonate */
    function setMinDonate(uint256 _value) public onlyOwner returns(bool success) {
        minDonate = _value;
        return true;
    }
    
    // Do not filter whether these modified addresses are 0, equal to 0. Specific operations will be filtered
    /* setAddress */
    function setInCoin(address _inCoin) public onlyOwner returns(bool success) {
        inCoin = EIP20Interface(_inCoin);
        return true;
    }

    /* setReceiver */
    function setReceiver(address _receiver) public onlyOwner returns(bool success){
        receiver =_receiver;
        return true;
    }
    
    /* setPlatform */
    function setPlatform(address _platform) public onlyOwner returns(bool success){
        platform =_platform;
        return true;
    }
    
    /* donate */
    function doDonate(uint256 _value, address _inviterAddr) public whenNotPaused returns (bool success){
        require(inCoin != address(0) && receiver != address(0) && lockInt != address(0) && index > 0, 'not open!');
        require(_value > 0, 'minimum donate amount > 0 ');
        require(!donateEnd && rules[index].indexRemain[1] > 0, 'activity has stopped!');
        require((_inviterAddr != address(0) && users[_inviterAddr].isUsed) || (_inviterAddr == address(0)), 'inviter does not exist !' );
        
        User storage user = users[msg.sender];
        inCoin.transferFrom(msg.sender, receiver, _value);
        if(!user.isUsed)
            user.inviter = _inviterAddr;
        
        user.isUsed = true;
        user.upNode = users[_inviterAddr].isNode ? _inviterAddr : users[_inviterAddr].upNode;
        user.donateOf[1] = user.donateOf[1].safeAdd(_value);
        uint256 ownReward = _value.safeMul(PERCENTS_DIVIDER).safeDiv(rules[index].priceProP);
        uint256 transferToPlatform;
        uint256 transferToLock = ownReward;
        
        uint256 airdropRemain = rules[index].indexRemain[1];
        uint256 remainReward = rules[index].indexRemain[2];
        user.donateOf[2] = user.donateOf[2].safeAdd(ownReward);
        if(airdropRemain < ownReward) {
            ownReward = airdropRemain;
        }
        
        uint256 inviterReward;
        uint256 nodeReward;
        
        if(_value >= minDonate && ownReward > 0) {
            inviterReward = ownReward.safeMul(rules[index].upProp).safeDiv(PERCENTS_DIVIDER);
            if(remainReward >= inviterReward) {
                remainReward -= inviterReward;
            } else {
                inviterReward = remainReward;
                remainReward = 0;
            }
            if(inviterReward > 0) {
                if(user.inviter != address(0)) {
                    lockInt.put(user.inviter, inviterReward);
                    users[user.inviter].donateOf[3] = users[user.inviter].donateOf[3].safeAdd(inviterReward);
                    transferToLock = transferToLock.safeAdd(inviterReward);
                } else {
                    transferToPlatform = transferToPlatform.safeAdd(inviterReward);
                    users[platform].donateOf[3] = users[platform].donateOf[3].safeAdd(inviterReward);
                }
            }
            nodeReward = ownReward.safeMul(rules[index].nodeProp).safeDiv(PERCENTS_DIVIDER);
            if(remainReward >= nodeReward) {
                remainReward -= nodeReward;
            } else {
                nodeReward = remainReward;
                remainReward = 0;
            }
            if(nodeReward > 0) {
                if(user.upNode != address(0)) {
                    lockInt.put(user.upNode, nodeReward);
                    transferToLock = transferToLock.safeAdd(nodeReward);
                    users[user.upNode].donateOf[4] = users[user.upNode].donateOf[4].safeAdd(nodeReward);
                } else {
                    transferToPlatform = transferToPlatform.safeAdd(nodeReward);
                    users[platform].donateOf[4] = SafeMath.safeAdd(users[platform].donateOf[4], nodeReward);
                }
            }
        } else {
            ownReward = 0;
            transferToLock = 0;
        }
        if(ownReward > 0) {
            lockInt.put(msg.sender, ownReward);
            rules[index].indexRemain[1] -= ownReward;
            rules[index].indexRemain[2] = remainReward;
        }
        if(transferToLock > 0)
            this.transfer(lockInt, transferToLock);
        if(transferToPlatform > 0)
            this.transfer(platform, transferToPlatform);
            
        emit NewDonate(msg.sender, ownReward, inviterReward, nodeReward);
        
        return true;
    }
    
    /* getUserNum  1: donate 2: own reward 3: inviter 4: node */
    function getUserNum(address _addr, uint8 _num) public view returns (uint value){
        return users[_addr].donateOf[_num];
    }
    
    /* getRuleNum  1: airdrop remain 2: reward remain */
    function getRuleNum(uint8 _index, uint8 _num) public view returns (uint value){
        return rules[_index].indexRemain[_num];
    }
    
    /* getIndexInfo */
    function getIndexInfo() public view returns(uint8 indexOf, bool running) {
        return (index, rules[index].indexRemain[1] > 0);
    }
    
    /* balanceOf */
    function balanceOf(address _account) public view returns (uint) {
        return balanceOf[_account];
    }
 
    /* Send coins */
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success){
        require(_to != address(0));  // Prevent transfer to 0x0 address. Use burn() instead
        require(_value > 0); 
        require(balanceOf[msg.sender] >= _value, 'Insufficient assets ');           // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to], 'num overflow'); // Check for overflows
        balanceOf[msg.sender] = balanceOf[msg.sender].safeSub(_value);                     // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].safeAdd(_value);                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        return true;
    }
 
    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        require(_value > 0); 
        allowance[msg.sender][_spender] = _value;
        return true;
    }
 
    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool success){
        require(_to != address(0) && _from != address(0));                                // Prevent transfer to 0x0 address. Use burn() instead
        require(_value > 0); 
        require(balanceOf[_from] >= _value);                 // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]);  // Check for overflows
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        balanceOf[_from] = balanceOf[_from].safeSub(_value);                           // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].safeAdd(_value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = allowance[_from][msg.sender].safeSub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    /* burn */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);            // Check if the sender has enough
        require(_value > 0); 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        totalSupply = totalSupply.safeSub(_value);                                // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
    
    /* freeze */
    function freeze(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);            // Check if the sender has enough
        require(_value > 0); 
        balanceOf[msg.sender] = balanceOf[msg.sender].safeSub( _value);                      // Subtract from the sender
        freezeOf[msg.sender] = freezeOf[msg.sender].safeAdd(_value);                                // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }
    
    /* unfreeze */
    function unfreeze(uint256 _value) public returns (bool success) {
        require(freezeOf[msg.sender] >= _value);            // Check if the sender has enough
        require(_value > 0); 
        freezeOf[msg.sender] = freezeOf[msg.sender].safeSub(_value);                      // Subtract from the sender
        balanceOf[msg.sender] = balanceOf[msg.sender].safeAdd(_value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
    
    /* allowance */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }
}