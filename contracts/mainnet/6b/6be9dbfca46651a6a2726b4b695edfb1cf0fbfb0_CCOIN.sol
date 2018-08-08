pragma solidity ^0.4.23;




contract Escrow {
    using SafeMath for uint256;
    using ContentUtils for ContentUtils.ContentMapping;

    ContentUtils.ContentMapping public content;
    address escrowAddr = address(this);

    uint256 public claimable = 0; 
    uint256 public currentBalance = 0; 
    mapping(bytes32 => uint256) public claimableRewards;

    /// @notice valid reward and user has enough funds
    modifier validReward(uint256 _reward) {
        require(_reward > 0 && _depositEscrow(_reward));
        _;
    }

    /// @notice complete deliverable by making reward amount claimable
    function completeDeliverable(bytes32 _id, address _creator, address _brand) internal returns(bool) {
        require(content.isFulfilled(_id, _creator, _brand));
        content.completeDeliverable(_id);
        return _approveEscrow(_id, content.rewardOf(_id));       
    }

    /// @notice update current balance, if proper token amount approved
    function _depositEscrow(uint256 _amount) internal returns(bool) {
        currentBalance = currentBalance.add(_amount);
        return true;
    }

    /// @notice approve reward amount for transfer from escrow contract to creator
    function _approveEscrow(bytes32 _id, uint256 _amount) internal returns(bool) {
        claimable = claimable.add(_amount);
        claimableRewards[_id] = _amount;
        return true;
    }

    function getClaimableRewards(bytes32 _id) public returns(uint256) {
        return claimableRewards[_id];
    }

    function getContentByName(string _name) public view returns(
        string name,
        string description,
        uint reward,
        uint addedOn) 
    {
        var (_content, exist) = content.getContentByName(_name);
        if (exist) {
            return (_content.name, _content.description, _content.deliverable.reward, _content.addedOn);
        } else {
            return ("", "", 0, 0);
        }
    }

    function currentFulfillment(string _name) public view returns(bool fulfillment) {
        var (_content, exist) = content.getContentByName(_name);
        if (exist) {
            return _content.deliverable.fulfillment[msg.sender];
        } else {
            false;
        }
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








library DeliverableUtils {

    struct Deliverable {
        uint256 reward;
        mapping(address=>bool) fulfillment;
        bool fulfilled;
    }

    /// @notice msg.sender can be creator or brand and mark their delivery or approval, returns check if completely Fulfilled
    function fulfill(Deliverable storage self, address _creator, address _brand) internal returns(bool) {
        require(msg.sender == _creator || msg.sender == _brand);
        self.fulfillment[msg.sender] = true;
        return self.fulfillment[_creator] && self.fulfillment[_brand];
    }

    /// @notice check if deliverable fulfilled completely
    function isFulfilled(Deliverable storage self, address _creator, address _brand) internal view returns(bool) {
        return self.fulfillment[_creator] && self.fulfillment[_brand];
    }

    /// @notice return new deliverable struct if reward greater than 0
    function newDeliverable(uint256 _reward) internal pure returns(Deliverable _deliverable) {
        require(_reward > 0);
        return Deliverable(_reward, false);
    }
}

library ContentUtils {
    using SafeMath for uint256;
    using DeliverableUtils for DeliverableUtils.Deliverable;

    struct Content {
        bytes32 id;
        string name;
        string description;
        uint addedOn;
        DeliverableUtils.Deliverable deliverable;
    }

    /// @notice utility for mapping bytes32=>Content. Keys must be unique. It can be updated until it is locked.
    struct ContentMapping {
        mapping(bytes32=>Content) data;
        bytes32[] keys;
        bool locked;
    }

    string constant UNIQUE_KEY_ERR = "Content with ID already exists ";
    string constant KEY_NOT_FOUND_ERR = "Key not found";

    /// @notice put item into mapping
    function put(ContentMapping storage self, 
        string _name, 
        string _description, 
        uint _reward) public returns (bool) 
    {
            require(!self.locked);

            bytes32 _id = generateContentID(_name);
            require(self.data[_id].id == bytes32(0));

            self.data[_id] = Content(_id, _name, _description, block.timestamp, DeliverableUtils.newDeliverable(_reward));
            self.keys.push(_id);
            return true;
    }
    
    /// @notice get amount of items in mapping
    function size(ContentMapping storage self) public view returns (uint) {
        return self.keys.length;
    }

    /// @notice return reward of content delivarable
    function rewardOf(ContentMapping storage self, bytes32 _id) public view returns (uint256) {
        return self.data[_id].deliverable.reward;
    }

    function getKey(ContentMapping storage self, uint _index) public view returns (bytes32) {
        isValidIndex(_index, self.keys.length);
        return self.keys[_index];
    }

    /// @notice get content by plain string name
    function getContentByName(ContentMapping storage self, string _name) public view returns (Content storage _content, bool exists) {
        bytes32 _hash = generateContentID(_name);
        return (self.data[_hash], self.data[_hash].addedOn != 0);
    }

    /// @notice get content by sha3 ID hash
    function getContentByID(ContentMapping storage self, bytes32 _id) public view returns (Content storage _content, bool exists) {
        return (self.data[_id], self.data[_id].id == bytes32(0));
    }

    /// @notice get content by _index into key array 
    function getContentByKeyIndex(ContentMapping storage self, uint _index) public view returns (Content storage _content) {
        isValidIndex(_index, self.keys.length);
        return (self.data[self.keys[_index]]);
    }

    /// @notice wrapper around internal deliverable method
    function fulfill(ContentMapping storage self, bytes32 _id, address _creator, address _brand) public returns(bool) {
        return self.data[_id].deliverable.fulfill(_creator, _brand);
    }

    /// @notice wrapper around internal deliverable method
    function isFulfilled(ContentMapping storage self, bytes32 _id, address _creator, address _brand) public view returns(bool) {
        return self.data[_id].deliverable.isFulfilled(_creator, _brand);
    }

    /// @notice marks deliverable as fulfilled
    function completeDeliverable(ContentMapping storage self, bytes32 _id) internal returns(bool) {
        self.data[_id].deliverable.fulfilled = true;
        return true;
    }

    /// @notice get sha256 hash of name for content ID
    function generateContentID(string _name) public pure returns (bytes32) {
        return keccak256(_name);
    }

    /// @notice index not out of bounds
    function isValidIndex(uint _index, uint _size) public pure {
        require(_index < _size, KEY_NOT_FOUND_ERR);
    }
}



contract Agreement is Escrow {
    
    bool public locked;
    uint  public createdOn;
    uint public expiration;
    uint public startTime;
    address public brand;
    address public creator;
    
    constructor(address _creator, uint _expiration, address _token) public {
        brand = msg.sender;
        creator = _creator;
        expiration = _expiration;
    }

    /// @notice only brand is authorized
    modifier onlyBrand() {
        require(msg.sender == brand);
        _;
    }

    /// @notice only creator is authorized
    modifier onlyCreator() {
        require(msg.sender == creator);
        _;
    }

    /// @notice deliverable fulfilled
    modifier fulfilled(bytes32 _id) {
        require(content.isFulfilled(_id, creator, brand));
        _;
    }

    /// @notice agreement expired, refunds remaining balance in escrow
    modifier expired() {
        require(block.timestamp > expiration);
        _;
    }

    /// @notice agreement not expired, refunds remaining balance in escrow
    modifier notExpired() {
        require(block.timestamp < expiration);
        _;
    }

    /// @notice agreement not locked
    modifier notLocked() {
        require(!locked);
        _;
    }

    /// @notice add content to the agreement
    function addContent(string _name, 
        string _description, 
        uint _reward) notLocked onlyBrand validReward(_reward) 
        public returns(bool _success) {
            return content.put(_name, _description, _reward);
    }

    function _fulfill(bytes32 _id) private returns (bool) {
        bool _fulfilled = content.fulfill(_id, creator, brand);
        if(_fulfilled) {
            return completeDeliverable(_id, creator, brand);
        }

        return false;
    }

    function fulfillDeliverable(bytes32 _id) notExpired onlyCreator public returns (bool) {
        return _fulfill(_id);
    }

    function approveDeliverable(bytes32 _id) onlyBrand public returns (bool) {
        return _fulfill(_id);
    }
    
    function claim(bytes32 _id) external onlyCreator {
        claimableRewards[_id] = 0;
    }


    function lock() onlyBrand public {
        content.locked == true;
        locked = true;
        startTime = block.timestamp;
    }

    function extendExpiration(uint _expiration) onlyBrand public returns (bool) {
        require(_expiration > expiration && _expiration >= block.timestamp);
        expiration = _expiration;
        return true;
    }

    function destroy() onlyBrand expired public {
        selfdestruct(msg.sender);
    }

    function deposit() payable {}
}

/**
 * @title ERC20 interface
 */
contract ERC20 {
    uint public totalSupply;

    function balanceOf(address who) constant returns (uint);

    function allowance(address owner, address spender) constant returns (uint);

    function transfer(address to, uint value) returns (bool ok);

    function transferFrom(address from, address to, uint value) returns (bool ok);

    function approve(address spender, uint value) returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0))
            owner = newOwner;
    }

    function kill() {
        if (msg.sender == owner)
            selfdestruct(owner);
    }

    modifier onlyOwner() {
        if (msg.sender == owner)
            _;
    }
}

// Token Contract
contract CCOIN is ERC20, Ownable {

    struct Escrow {
        address creator;
        address brand;
        address agreementContract;
        uint256 reward;
    }

    // Public variables of the token
    string public constant name = "CCOIN";
    string public constant symbol = "CCOIN";
    uint public constant decimals = 18;
    uint public totalSupply = 1000000000 * 10 ** 18;
    bool public locked;

    address public multisigETH; // SafeMath.multisig contract that will receive the ETH
    address public crowdSaleaddress; // Crowdsale address
    uint public ethReceived; // Number of ETH received
    uint public totalTokensSent; // Number of tokens sent to ETH contributors
    uint public startBlock; // Crowdsale start block
    uint public endBlock; // Crowdsale end block
    uint public maxCap; // Maximum number of token to sell
    uint public minCap; // Minimum number of ETH to raise
    uint public minContributionETH; // Minimum amount to invest
    uint public tokenPriceWei;

    uint firstPeriod;
    uint secondPeriod;
    uint thirdPeriod;
    uint fourthPeriod;
    uint fifthPeriod;
    uint firstBonus;
    uint secondBonus;
    uint thirdBonus;
    uint fourthBonus;
    uint fifthBonus;
    uint public multiplier;

    bool public stopInEmergency = false;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => Escrow) escrowAgreements;
    // Whitelist
    mapping(address => bool) public whitelisted;

    event Whitelist(address indexed participant);
    event Locked();
    event Unlocked();
    event StoppedCrowdsale();
    event RestartedCrowdsale();
    event Burned(uint256 value);

    // Lock transfer during the ICO
    modifier onlyUnlocked() {
        if (msg.sender != crowdSaleaddress && locked && msg.sender != owner)
            revert();
        _;
    }

    // @notice to protect short address attack
    modifier onlyPayloadSize(uint numWords){
        assert(msg.data.length >= numWords * 32 + 4);
        _;
    }

    modifier onlyAuthorized() {
        if (msg.sender != crowdSaleaddress && msg.sender != owner)
            revert();
        _;
    }

    // The Token constructor
    constructor() public {
        locked = true;
        multiplier = 10 ** 18;

        multisigETH = msg.sender;
        minContributionETH = 1;
        startBlock = 0;
        endBlock = 0;
        maxCap = 1000 * multiplier;
        tokenPriceWei = SafeMath.div(1, 1400);
        minCap = 100 * multiplier;
        totalTokensSent = 0;
        firstPeriod = 100;
        secondPeriod = 200;
        thirdPeriod = 300;
        fourthPeriod = 400;
        fifthPeriod = 500;

        firstBonus = 120;
        secondBonus = 115;
        thirdBonus = 110;
        fourthBonus = SafeMath.div(1075, 10);
        fifthBonus = 105;
        balances[multisigETH] = totalSupply;
    }

    function resetCrowdSaleaddress(address _newCrowdSaleaddress) public onlyAuthorized() {
        crowdSaleaddress = _newCrowdSaleaddress;
    }

    function unlock() public onlyAuthorized {
        locked = false;
        emit Unlocked();
    }

    function lock() public onlyAuthorized {
        locked = true;
        emit Locked();
    }

    function burn(address _member, uint256 _value) public onlyAuthorized returns (bool) {
        balances[_member] = SafeMath.sub(balances[_member], _value);
        totalSupply = SafeMath.sub(totalSupply, _value);
        emit Transfer(_member, 0x0, _value);
        emit Burned(_value);
        return true;
    }

    function Airdrop(address _to, uint256 _tokens) external onlyAuthorized returns(bool) {
        require(transfer(_to, _tokens));
    } 

    function transfer(address _to, uint _value) public onlyUnlocked returns (bool) {
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public onlyUnlocked returns (bool success) {
        if (balances[_from] < _value)
            revert();
        // Check if the sender has enough
        if (_value > allowed[_from][msg.sender])
            revert();
        // Check allowance
        balances[_from] = SafeMath.sub(balances[_from], _value);
        // SafeMath.subtract from the sender
        balances[_to] = SafeMath.add(balances[_to], _value);
        // SafeMath.add the same to the recipient
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    function withdrawFromEscrow(address _agreementAddr, bytes32 _id) {
        require(balances[_agreementAddr] > 0);
        Agreement agreement = Agreement(_agreementAddr);
        require(agreement.creator() == msg.sender);
        uint256 reward = agreement.getClaimableRewards(_id);
        require(reward > 0);
        balances[_agreementAddr] = SafeMath.sub(balances[_agreementAddr], reward);
        balances[msg.sender] = SafeMath.add(balances[msg.sender], reward);
    }

    function WhitelistParticipant(address participant) external onlyAuthorized {
        whitelisted[participant] = true;
        emit Whitelist(participant);
    }

    function BlacklistParticipant(address participant) external onlyAuthorized {
        whitelisted[participant] = false;
        emit Whitelist(participant);
    }

    // {fallback function}
    // @notice It will call internal function which handles allocation of Ether and calculates tokens.
    function() public payable onlyPayloadSize(2) {
        contribute(msg.sender);
    }

    // @notice It will be called by fallback function whenever ether is sent to it
    // @param  _backer {address} address of beneficiary
    // @return res {bool} true if transaction was successful
    function contribute(address _backer) internal returns (bool res) {
        // stop when required minimum is not sent
        if (msg.value < minContributionETH)
            revert();

        // calculate number of tokens
        uint tokensToSend = calculateNoOfTokensToSend();

        // Ensure that max cap hasn&#39;t been reached
        if (SafeMath.add(totalTokensSent, tokensToSend) > maxCap)
            revert();

        // Transfer tokens to contributor
        if (!transfer(_backer, tokensToSend))
            revert();

        ethReceived = SafeMath.add(ethReceived, msg.value);
        totalTokensSent = SafeMath.add(totalTokensSent, tokensToSend);

        return true;
    }

    // @notice This function will return number of tokens based on time intervals in the campaign
    function calculateNoOfTokensToSend() constant internal returns (uint) {
        uint tokenAmount = SafeMath.div(SafeMath.mul(msg.value, multiplier), tokenPriceWei);
        if (block.number <= startBlock + firstPeriod)
            return tokenAmount + SafeMath.div(SafeMath.mul(tokenAmount, firstBonus), 100);
        else if (block.number <= startBlock + secondPeriod)
            return tokenAmount + SafeMath.div(SafeMath.mul(tokenAmount, secondBonus), 100);
        else if (block.number <= startBlock + thirdPeriod)
            return tokenAmount + SafeMath.div(SafeMath.mul(tokenAmount, thirdBonus), 100);
        else if (block.number <= startBlock + fourthPeriod)
            return tokenAmount + SafeMath.div(SafeMath.mul(tokenAmount, fourthBonus), 100);
        else if (block.number <= startBlock + fifthPeriod)
            return tokenAmount + SafeMath.div(SafeMath.mul(tokenAmount, fifthBonus), 100);
        else
            return tokenAmount;
    }

    function stopCrowdsale() external onlyOwner{
        stopInEmergency = true;
        emit StoppedCrowdsale();
    }

    function restartCrowdsale() external onlyOwner{
        stopInEmergency = false;
        emit RestartedCrowdsale();
    }

}