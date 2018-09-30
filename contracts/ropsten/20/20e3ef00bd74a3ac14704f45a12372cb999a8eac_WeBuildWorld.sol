pragma solidity ^0.4.23;

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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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

contract Extendable is Ownable {
    struct ProviderItem {
        uint start;
        uint end;
        address providerAddress;
    }

    uint public currentId = 10000;
    uint16 public currentVersion = 0;
    mapping (uint => ProviderItem) internal providers;

    function upgradeProvider(address _address) 
        public onlyOwner returns (bool) 
    {
        require(_address != 0x0);
        require(providers[currentVersion].providerAddress != _address);

        // first time
        if (providers[currentVersion].providerAddress == 0x0) {
            providers[currentVersion].start = currentId;
            providers[currentVersion].end = 10 ** 18;
            providers[currentVersion].providerAddress = _address;
            return true;            
        }

        providers[currentVersion].end = currentId - 1;

        ProviderItem memory newProvider = ProviderItem({
            start: currentId,
            end: 10**18,
            providerAddress: _address
        });

        providers[++currentVersion] = newProvider;

        return true;
    }

    function getProviderDetails(uint _version) public view returns (uint _start, uint _end, address _address) 
    {
        ProviderItem memory provider = providers[_version];
        return (provider.start, provider.end, provider.providerAddress);
    }

    function getProviderById(uint _id) public view returns (address) {
        for (uint i = currentVersion; i >= 0; i--) {
            ProviderItem memory item = providers[i];
            if (item.start <= _id && item.end >= _id) {
                return item.providerAddress;
            }
        }

        return getCurrentProvider();
    }

    function getCurrentProvider() public view returns(address) {
        return providers[currentVersion].providerAddress;
    }   

    function getAllProviders() public view returns (address[] memory addresses) {
        addresses = new address[](currentVersion + 1);
        for (uint i=0; i <= currentVersion; i++) {
            addresses[i] = providers[i].providerAddress;
        }

        return addresses;
    }

    function resetCurrentIdTo(uint _newId) public onlyOwner returns (bool success) {
        currentId = _newId;
        return true;
    }
}

interface Provider {
    function isBrickOwner(uint _brickId, address _address) external view returns (bool success);
    function addBrick(uint _brickId, string _title, string _url, uint _expired, string _description, bytes32[] _tags, uint _value)
        external returns (bool success);
    function changeBrick(
        uint _brickId,
        string _title,
        string _url,
        string _description,
        bytes32[] _tags,
        uint _value) external returns (bool success);
    function accept(uint _brickId, address[] _builderAddresses, uint[] percentages, uint _additionalValue) external returns (uint total);
    function cancel(uint _brickId) external returns (uint value);
    function startWork(uint _brickId, bytes32 _builderId, bytes32 _nickName, address _builderAddress) external returns(bool success);
    function getBrickIds() external view returns(uint[]);
    function getBrickSize() external view returns(uint);
    function getBrick(uint _brickId) external view returns(
        string title,
        string url, 
        address owner,
        uint value,
        uint32 dateCreated,
        uint32 dateCompleted, 
        uint32 expired,
        uint status
    );

    function getBrickDetail(uint _brickId) external view returns(
        bytes32[] tags, 
        string description, 
        uint32 builders, 
        address[] winners
    );

    function getBrickBuilders(uint _brickId) external view returns (
        address[] addresses,
        uint[] dates,
        bytes32[] keys,
        bytes32[] names
    );

    function filterBrick(
        uint _brickId, 
        bytes32[] _tags, 
        uint _status, 
        uint _started,
        uint _expired
        ) external view returns (
      bool
    );


    function participated( 
        uint _brickId,
        address _builder
        ) external view returns (
        bool
    ); 
}

// solhint-disable-next-line compiler-fixed, compiler-gt-0_4







contract WeBuildWorld is Extendable {
    using SafeMath for uint256;

    string public constant VERSION = "0.1";
    uint public constant DENOMINATOR = 10000;
    enum AddressRole { Owner, Builder }


    modifier onlyBrickOwner(uint _brickId) {
        require(getProvider(_brickId).isBrickOwner(_brickId, msg.sender));
        _;
    }

    event BrickAdded (uint _brickId);
    event BrickUpdated (uint _brickId);
    event BrickCancelled (uint _brickId);
    event WorkStarted (uint _brickId, address _builderAddress);
    event WorkAccepted (uint _brickId, address[] _winners);
 
    function () public payable {
        revert();
    }

    function getBrickIdsByOwner(address _owner) public view returns(uint[] brickIds) {
        return _getBrickIdsByAddress(_owner, AddressRole.Owner);
    }

    function getBrickIdsByBuilder(address _builder) public view returns(uint[] brickIds) {
        return _getBrickIdsByAddress(_builder, AddressRole.Builder);
    }
 
    function _getBrickIdsByAddress(
        address _address,
        AddressRole role
      ) 
        private view returns(uint[] brickIds) { 
        address[] memory providers = getAllProviders();
        uint[] memory temp; 
        uint total = 0;
        uint index = 0; 

        for (uint i = providers.length; i > 0; i--) {
            Provider provider = Provider(providers[i-1]);
            total = total + provider.getBrickSize();  
        }

        brickIds = new uint[](total);  
    
        for(i = 0; i < providers.length; i++){
            temp = provider.getBrickIds();
            for (uint j = 0; j < temp.length; j++) {
                bool cond = true;
                if(role == AddressRole.Owner){
                    cond = provider.isBrickOwner(temp[j], _address);
                }else{
                    cond = provider.participated(temp[j], _address);
                } 
                if(cond){
                    brickIds[index] = temp[j]; 
                    index++;
                }
            }
        }

        return brickIds;
    }

    function getBrickIds(
        uint _skip,
        uint _take,
        bytes32[] _tags, 
        uint _status, 
        uint _started, 
        uint _expired
        ) 
        public view returns(uint[] brickIds) {

        address[] memory providers = getAllProviders();
        uint[] memory temp;

        brickIds = new uint[](_take);
        uint counter = 0; 
        uint taken = 0;

        for (uint i = providers.length; i > 0; i--) {
            if (taken >= _take) {
                break;
            }

            Provider provider = Provider(providers[i-1]);
            temp = provider.getBrickIds();
            
            for (uint j = 0; j < temp.length; j++) { 
                if (taken >= _take) {
                    break;
                }
                
                bool exist = provider.filterBrick(temp[j], _tags, _status, _started, _expired);
                if(exist){
                    if (counter >= _skip) { 
                        brickIds[taken] = temp[j];                     
                        taken++;
                    }
                    counter++;
                }
            }
        }

        return brickIds;
    }

    function addBrick(string _title, string _url, uint _expired, string _description, bytes32[] _tags) 
        public payable
        returns (uint id)
    {
        id = getId();
        require(getProvider(id).addBrick(id, _title, _url, _expired, _description, _tags, msg.value));
        emit BrickAdded(id);
    }

    function changeBrick(uint _brickId, string _title, string _url, string _description, bytes32[] _tags) 
        public onlyBrickOwner(_brickId) payable
        returns (bool success) 
    {
        success = getProvider(_brickId).changeBrick(_brickId, _title, _url, _description, _tags, msg.value);
        emit BrickUpdated(_brickId);

        return success;
    }

    // msg.value is tip.
    function accept(uint _brickId, address[] _winners, uint[] _weights) 
        public onlyBrickOwner(_brickId) 
        payable
        returns (bool success) 
    {
        uint total = getProvider(_brickId).accept(_brickId, _winners, _weights, msg.value);
        require(total > 0);
        for (uint i=0; i < _winners.length; i++) {
            _winners[i].transfer(total.mul(_weights[i]).div(DENOMINATOR));    
        }     

        emit WorkAccepted(_brickId, _winners);
        return true;   
    }

    function cancel(uint _brickId) 
        public onlyBrickOwner(_brickId) 
        returns (bool success) 
    {
        uint value = getProvider(_brickId).cancel(_brickId);
        require(value > 0);

        msg.sender.transfer(value);  
        emit BrickCancelled(_brickId);
        return true;      
    }    

    function startWork(uint _brickId, bytes32 _builderId, bytes32 _nickName) 
        public returns(bool success)
    {
        success = getProvider(_brickId).startWork(_brickId, _builderId, _nickName, msg.sender);    
        emit WorkStarted(_brickId, msg.sender);
    }

    function getBrick(uint _brickId) public view returns (
        string title,
        string url,
        address owner,
        uint value,
        uint dateCreated,
        uint dateCompleted,
        uint expired,
        uint status
    ) {
        return getProvider(_brickId).getBrick(_brickId);
    }

    function getBrickDetail(uint _brickId) public view returns (
        bytes32[] tags,
        string description,
        uint32 builders,
        address[] winners        
    ) {
        return getProvider(_brickId).getBrickDetail(_brickId);
    }

    function getBrickBuilders(uint _brickId) public view returns (
        address[] addresses,
        uint[] dates,
        bytes32[] keys,
        bytes32[] names
    )
    {
        return getProvider(_brickId).getBrickBuilders(_brickId);
    }

    function getProvider(uint _brickId) private view returns (Provider) {
        return Provider(getProviderById(_brickId));
    }

    function getId() private returns (uint) {
        return currentId++;
    }      
}