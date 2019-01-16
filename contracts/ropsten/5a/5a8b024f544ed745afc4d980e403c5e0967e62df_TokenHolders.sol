pragma solidity >0.4.99 <0.6.0;
pragma experimental ABIEncoderV2;

contract SantaClausToken {
  function balanceOf(address who) public view returns (uint256);
}

contract TokenHolders {
    
    string[] names;
    mapping(address => bool) registeredAddresses;

    SantaClausToken token;
    
    constructor(address _token) public {
        token = SantaClausToken(_token);
    }
    
    function registerName(string memory name) public {
        require(!registeredAddresses[msg.sender]);
        require(token.balanceOf(msg.sender) > 0);
        
        names.push(name);
        registeredAddresses[msg.sender] = true;
    }
    
    function getNames() public view returns(string[] memory) {
        // may fail to return if array is too large
        return names;
    }
}