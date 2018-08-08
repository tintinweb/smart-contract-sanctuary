pragma solidity ^0.4.18;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  address public agent; // sale agent

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
  
  modifier onlyAgentOrOwner() {
      require(msg.sender == owner || msg.sender == agent);
      _;
  }

  function setSaleAgent(address addr) public onlyOwner {
      agent = addr;
  }
  
}

contract HeartBoutToken is Ownable {
    function transferTokents(address addr, uint256 tokens) public;
}

contract HeartBoutSale is Ownable {
    
    uint32 rate = 10 ** 5;
    
    uint64 public startDate;
    uint64 public endDate;
    uint256 public soldOnCurrentSale = 0;
    
    mapping(string => address) addressByAccountMapping;

    HeartBoutToken tokenContract;
    
    function HeartBoutSale(HeartBoutToken _tokenContract) public {
        tokenContract = _tokenContract;
    }
    
    function startSale(uint32 _rate, uint64 _startDate, uint64 _endDate) public onlyOwner {
        require(rate != 0);
        require(_rate <= rate);
        require(100 < _rate && _rate < 15000);
        require(_endDate > now);
        require(_startDate < _endDate);
        
        soldOnCurrentSale = 0;
        
        rate = _rate;
        startDate = _startDate;
        endDate = _endDate;
    }
    
    function completeSale() public onlyOwner {
        endDate = 0;
        soldOnCurrentSale = 0;
    }
    
    function () public payable {
        revert();
    }
    
    function buyTokens(string _account) public payable {
        
        require(msg.value > 0);
        require(rate > 0);
        require(endDate > now);
        
        require(msg.value >= (10 ** 16));
        
        uint256 tokens = msg.value * rate;
        
        address _to = msg.sender;
        
        if(addressByAccountMapping[_account] != 0x0) {
            require(addressByAccountMapping[_account] == _to);      
        }
        addressByAccountMapping[_account] = _to;
        
        soldOnCurrentSale += tokens;

        tokenContract.transferTokents(msg.sender, tokens);
        owner.transfer(msg.value);
    }
    
    function getAddressForAccount(string _account) public view returns (address) {
      return addressByAccountMapping[_account];
    }
    
    function stringEqual(string a, string b) internal pure returns (bool) {
      return keccak256(a) == keccak256(b);
    }
}