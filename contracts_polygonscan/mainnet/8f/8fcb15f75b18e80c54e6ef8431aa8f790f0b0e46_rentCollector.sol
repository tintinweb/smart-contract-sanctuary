/**
 *Submitted for verification at polygonscan.com on 2021-08-01
*/

pragma solidity 0.6.6;

interface IRealityCards {

    function collectRentAllCards() external;
    function state() external view returns(uint);

}

contract rentCollector {
    
    mapping (uint256 => address) public marketAddresses; 
    uint public numberOfMarkets = 0;
    
    function addMarket(address _marketAddress) public {
        require(msg.sender == 0x34A971cA2fd6DA2Ce2969D716dF922F17aAA1dB0 || msg.sender == 0x613588b1694FD22825945a9Dc3e91F32EBf04C64 || msg.sender == 0x10C0D6840659F085581ab91Ed1eB5cc174C89e9a ,"not owner");
        marketAddresses[numberOfMarkets] = _marketAddress;
        numberOfMarkets = numberOfMarkets + 1;
    }
    
    function hasCardExpired() external pure returns (bool) {
        return true;
    }

    function collectRentIfExpired() public 
    {
        collectRentAlways();
    }
    
    function collectRentAlways() public 
    {
    for (uint i = 0; i < numberOfMarkets; i++) {
        IRealityCards rc = IRealityCards(marketAddresses[i]);
            if (rc.state() == 1) {
                rc.collectRentAllCards(); 
            }
        }
    }
}