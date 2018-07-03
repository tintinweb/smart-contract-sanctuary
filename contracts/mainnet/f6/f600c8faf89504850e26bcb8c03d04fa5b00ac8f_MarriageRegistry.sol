contract MarriageRegistry {
    address [] public registeredMarriages;
    event ContractCreated(address contractAddress);

    function createMarriage(string _leftName, string _leftVows, string _rightName, string _rightVows, uint _date) public {
        address newMarriage = new Marriage(msg.sender, _leftName, _leftVows, _rightName, _rightVows, _date);
        emit ContractCreated(newMarriage);
        registeredMarriages.push(newMarriage);
    }

    function getDeployedMarriages() public view returns (address[]) {
        return registeredMarriages;
    }
}

/**
 * @title Marriage
 * @dev The Marriage contract provides basic storage for names and vows, and has a simple function
 * that lets people ring a bell to celebrate the wedding
 */
contract Marriage {

    event weddingBells(address ringer, uint256 count);

    // Owner address
    address public owner;

    /// Marriage Vows
    string public leftName;
    string public leftVows;
    string public rightName;
    string public rightVows;
    // date public marriageDate;
    uint public marriageDate;
    
    // Bell counter
    uint256 public bellCounter;

    /**
    * @dev Throws if called by any account other than the owner
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Constructor sets the original `owner` of the contract to the sender account, and
    * commits the marriage details and vows to the blockchain
    */
    constructor(address _owner, string _leftName, string _leftVows, string _rightName, string _rightVows, uint _date) public {
        // TODO: Assert statements for year, month, day
        owner = _owner;
        leftName = _leftName;
        leftVows = _leftVows;
        rightName = _rightName;
        rightVows = _rightVows;
        marriageDate = _date; 
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) private pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    /**
    * @dev ringBell is a payable function that allows people to celebrate the couple&#39;s marriage, and
    * also send Ether to the marriage contract
    */
    function ringBell() public payable {
        bellCounter = add(1, bellCounter);
        emit weddingBells(msg.sender, bellCounter);
    }

    /**
    * @dev withdraw allows the owner of the contract to withdraw all ether collected by bell ringers
    */
    function collect() external onlyOwner {
        owner.transfer(address(this).balance);
    }

    /**
    * @dev withdraw allows the owner of the contract to withdraw all ether collected by bell ringers
    */
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    /**
    * @dev returns contract metadata in one function call, rather than separate .call()s
    * Not sure if this works yet
    */
    function getMarriageDetails() public view returns (
        address, string, string, string, string, uint, uint256) {
        return (
            owner,
            leftName,
            leftVows,
            rightName,
            rightVows,
            marriageDate,
            bellCounter
        );
    }
}