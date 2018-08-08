pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

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
    require(msg.sender == owner, "Only the owner may call this method.");
    _;
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
    require(_newOwner != address(0), "Invalid owner address");
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract ReviewThisPlease is Ownable 
{
    /*******************************************
     * Data
     *******************************************/
    event Accept(string topic, uint256 value);
    event Decline(string topic, uint256 value);
    event NewTopic(string topic, address from, uint256 value);
    event ContributeToTopic(string topic, address from, uint256 value);
    
    struct Supporter 
    {
        address addr;
        uint256 value;
    }
    struct SupporterList
    {
        mapping(uint256 => Supporter) idToSupporter;
        uint256 length;
    }
    struct TopicList
    {
        mapping(uint256 => string) idToTopic;
        uint256 length;
    }
    
    uint256 public minForNewTopic;
    uint256 public minForExistingTopic;
   
    mapping(string => SupporterList) private topicToSupporterList;
    mapping(address => TopicList) private supporterToTopicList;
    TopicList private allTopics;
    
    /*******************************************
     * Admin
     *******************************************/
    constructor() public 
    {
        minForNewTopic = 0.05 ether;
        minForExistingTopic = 0.001 ether;
    }
    
    function setMins(uint256 _minForNewTopic, uint256 _minForExistingTopic)
        onlyOwner public 
    {
        require(_minForNewTopic > 0, 
            "The _minForNewTopic should be > 0.");
        require(_minForExistingTopic > 0, 
            "The _minForExistingTopic should be > 0.");
        
        minForNewTopic = _minForNewTopic;
        minForExistingTopic = _minForExistingTopic;
    }
    
    /*******************************************
     * Read only
     *******************************************/
    function getTopicCount() public view returns (uint256)
    {
        return allTopics.length;
    }
    
    function getTopic(uint256 id) public view returns (string)
    {
        return allTopics.idToTopic[id];
    }
    
    function getSupportersForTopic(string topic) public view 
        returns (address[], uint256[])
    {
        SupporterList storage supporterList = topicToSupporterList[topic];
        
        address[] memory addressList = new address[](supporterList.length);
        uint256[] memory valueList = new uint256[](supporterList.length);
        
        for(uint i = 0; i < supporterList.length; i++)
        {
            Supporter memory supporter = supporterList.idToSupporter[i];
            addressList[i] = supporter.addr;
            valueList[i] = supporter.value;
        }
        
        return (addressList, valueList);
    }
    
    /*******************************************
     * Public write
     *******************************************/
    function requestTopic(string topic) public payable
    {
        require(bytes(topic).length > 0, 
            "Please specify a topic.");
        require(bytes(topic).length <= 500, 
            "The topic is too long (max 500 characters).");
            
        SupporterList storage supporterList = topicToSupporterList[topic];
        
        if(supporterList.length == 0)
        { // New topic
            require(msg.value >= minForNewTopic, 
                "Please send at least &#39;minForNewTopic&#39; to request a new topic.");
          
            allTopics.idToTopic[allTopics.length++] = topic;
            emit NewTopic(topic, msg.sender, msg.value);
        }
        else
        { // Existing topic
            require(msg.value >= minForExistingTopic, 
                "Please send at least &#39;minForExistingTopic&#39; to add support to an existing topic.");
        
            emit ContributeToTopic(topic, msg.sender, msg.value);
        }
        
        supporterList.idToSupporter[supporterList.length++] = 
            Supporter(msg.sender, msg.value);
    }

    function refund(string topic) public returns (bool)
    {
        SupporterList storage supporterList = topicToSupporterList[topic];
        uint256 amountToRefund = 0;
        for(uint i = 0; i < supporterList.length; i++)
        {
            Supporter memory supporter = supporterList.idToSupporter[i];
            if(supporter.addr == msg.sender)
            {
                amountToRefund += supporter.value;
                supporterList.idToSupporter[i] = supporterList.idToSupporter[--supporterList.length];
                i--;
            }
        }
        
        bool topicWasRemoved = false;
        if(supporterList.length == 0)
        {
            _removeTopic(topic);
            topicWasRemoved = true;
        }
        
        msg.sender.transfer(amountToRefund);
        
        return (topicWasRemoved);
    }
    
    function refundAll() public
    {
        for(uint i = 0; i < allTopics.length; i++)
        {
            if(refund(allTopics.idToTopic[i]))
            {
                i--;
            }
        }
    }
    
    /*******************************************
     * Owner only write
     *******************************************/
    function accept(string topic) public onlyOwner
    {
        SupporterList storage supporterList = topicToSupporterList[topic];
        uint256 totalValue = 0;
        for(uint i = 0; i < supporterList.length; i++)
        {
            totalValue += supporterList.idToSupporter[i].value;
        }
       
        _removeTopic(topic);
        emit Accept(topic, totalValue);
        
        owner.transfer(totalValue);
    }
    
    function decline(string topic) public onlyOwner
    {
        SupporterList storage supporterList = topicToSupporterList[topic];
        uint256 totalValue = 0;
        for(uint i = 0; i < supporterList.length; i++)
        {
            totalValue += supporterList.idToSupporter[i].value;
            supporterList.idToSupporter[i].addr.transfer(
                supporterList.idToSupporter[i].value);
        }
        
        _removeTopic(topic);
        emit Decline(topic, totalValue);
    }
    
    function declineAll() public onlyOwner
    {
        for(uint i = 0; i < allTopics.length; i++)
        {
            decline(allTopics.idToTopic[i]);
        }
    }
    
    /*******************************************
     * Private helpers
     *******************************************/
    function _removeTopic(string topic) private
    {
        delete topicToSupporterList[topic];
        bytes32 topicHash = keccak256(abi.encodePacked(topic));
        for(uint i = 0; i < allTopics.length; i++)
        {
            string memory _topic = allTopics.idToTopic[i];
            if(keccak256(abi.encodePacked(_topic)) == topicHash)
            {
                allTopics.idToTopic[i] = allTopics.idToTopic[--allTopics.length];
                return;
            }
        }
    }
}