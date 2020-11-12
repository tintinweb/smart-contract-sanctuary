pragma solidity 0.6.6;

interface IRealityCards {

    function collectRentAllTokens() external;
    function numberOfTokens() external view returns(uint); 
    function ownerOf(uint) external view returns(address); 
    function currentOwnerRemainingDeposit(uint) external view returns(uint);

}

contract rentCollector {
    
    mapping (uint256 => address) public marketAddresses; 
    uint public numberOfMarkets;
    
    function addMarket(uint _position, address _marketAddress) public {
        require(msg.sender == 0xacD628D01dd8534Db6Ebe4894C1be3c8D34ebe14,"not owner");
        marketAddresses[_position] = _marketAddress;
    }
    
    function setNumberOfMarkets(uint _numberOfMarkets) public {
        require(msg.sender == 0xacD628D01dd8534Db6Ebe4894C1be3c8D34ebe14,"not owner");
        numberOfMarkets = _numberOfMarkets;
    }
    
    function hasCardExpired() external view returns (bool) {
        bool _expired = false;
        
        for (uint i = 0; i < numberOfMarkets; i++) {
            IRealityCards rc = IRealityCards(marketAddresses[i]);
            for (uint j = 0; j < rc.numberOfTokens(); j++) {
                if (rc.currentOwnerRemainingDeposit(j) == 0 && rc.ownerOf(j) != address(rc)) {
                    _expired = true;
                }
            }
        }
            
    return _expired;
        
    }
    
    function collectRentAllTokensAllMarkets() public 
    {
        bool _expired;
        
        for (uint i = 0; i < numberOfMarkets; i++) {
            IRealityCards rc = IRealityCards(marketAddresses[i]);
            _expired = false;
            for (uint j = 0; j < rc.numberOfTokens(); j++) {
                if (rc.currentOwnerRemainingDeposit(j) == 0 && rc.ownerOf(j) != address(rc)) {
                    _expired = true;
                }
            if (_expired) {
                rc.collectRentAllTokens(); 
                }
            }
        }
    }
        
}