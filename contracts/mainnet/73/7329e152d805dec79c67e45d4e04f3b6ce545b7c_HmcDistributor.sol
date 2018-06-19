pragma solidity ^0.4.16;

contract ERC20Interface {
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

contract HmcDistributor {

    //add limit to 1 year
    uint64  public constant lockDuration   = 1 minutes;
    //Bonus amount
    uint256 public constant bonus          = 2*10*18;
    //add limit to 7000000 block height
    uint    public constant minBlockNumber = 5000000;

    address public owner;
    address public hmcAddress;

    uint256 public joinCount        = 0;
    uint256 public withdrawCount    = 0;
    uint256 public distributorCount = 0;

    struct member {
        uint unlockTime;
        bool withdraw;
    }

    mapping(address => member)   public whitelist;
    mapping(address => bool)     public distributors;

    modifier onlyDistributor {
        require(distributors[msg.sender] == true);
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function HmcDistributor() public {
        owner = msg.sender;
        distributors[msg.sender] = true;
        hmcAddress = 0xAa0bb10CEc1fa372eb3Abc17C933FC6ba863DD9E;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function setDistributor(address []_addr)
        external
        onlyOwner
    {
        uint256 index;
        for(index = 0;index< _addr.length;index ++) {
            distributors[_addr[index]] = true;
        }
        distributorCount += _addr.length;
    }

    function setHmcAddress(address _addr)
        external
        onlyOwner
    {
        require(_addr != 0x0);
        hmcAddress = _addr;
    }

    function distribute(address _addr)
        external
        onlyDistributor
    {
        require(hmcAddress != address(0));
        require(whitelist[_addr].unlockTime == 0);
        whitelist[_addr].unlockTime = now + lockDuration;
        joinCount++;
    }

    function done(address _owner) external view returns (bool) {
        if(whitelist[_owner].unlockTime == 0   ||
           whitelist[_owner].withdraw   == true) {
            return false;
        }
        if(now >= whitelist[_owner].unlockTime && block.number > minBlockNumber) {
            return true;
        }else{
            return false;
        }
    }

    function withdraw() external {
        require(withdrawCount<joinCount);
        require(whitelist[msg.sender].withdraw == false);
        require(whitelist[msg.sender].unlockTime > 1500000000);
        require(now >= whitelist[msg.sender].unlockTime && block.number > minBlockNumber);
        whitelist[msg.sender].withdraw = true;
        withdrawCount++;
        require(ERC20Interface(hmcAddress).transfer(msg.sender, bonus));
    }
}