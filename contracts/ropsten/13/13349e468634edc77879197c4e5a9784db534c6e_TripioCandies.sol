pragma solidity ^0.4.24;

contract TripioToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    function transfer(address _to, uint256 _value) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
}

contract TripioCandies {
    address trio;
    address owner;
    /**
     * Constructor
     */
    constructor(address _trio) public {
        // Init the data source
        trio = _trio;
        owner = msg.sender;
    }

    function withdraw() public {
        require(msg.sender == owner);
        TripioToken tripio = TripioToken(trio);
        uint256 tokens = tripio.balanceOf(address(this));
        tripio.transfer(owner, tokens);
    }

    function getTRIOs() public {
        TripioToken tripio = TripioToken(trio);
        require(tripio.balanceOf(msg.sender) < 10000000000000000000);
        tripio.transfer(msg.sender, 10000000000000000000);
    }
}