pragma solidity ^0.4.24;

contract blockbytesRegistry {
    address [] public registeredMarriages;
    event ContractCreated(address contractAddress);

    function createMarriage(string _leftName, string _leftVows, string _rightName, string _rightVows, uint _date) public {
        address newMarriage = new blockbytesMarriage(msg.sender, _leftName, _leftVows, _rightName, _rightVows, _date);
        emit ContractCreated(newMarriage);
        registeredMarriages.push(newMarriage);
    }

    function getDeployedblockbytesMarriages() public view returns (address[]) {
        return registeredMarriages;
    }
}

contract blockbytesMarriage {

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
    constructor(address _owner, string _leftName, string _leftVows, string _rightName, string _rightVows, uint _date) public {
        // TODO: Assert statements for year, month, day
        owner = _owner;
        leftName = _leftName;
        leftVows = _leftVows;
        rightName = _rightName;
        rightVows = _rightVows;
        marriageDate = _date; 
    }
    function add(uint256 a, uint256 b) private pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

function collect() external onlyOwner {
        owner.transfer(address(this).balance);
    }
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
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