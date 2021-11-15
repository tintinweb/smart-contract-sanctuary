/**
 *Submitted for verification at BscScan.com on 2021-11-14
*/

interface IHub 
{
    event NFTCreatedEvent(address collection);
    
    function emitNFTCreatedEvent(address _collection) external ;
    
}

contract Collection 
{
    address Hub;
    
    constructor(address _hub) {
        Hub = _hub;    
    }
    
    event CollectionCreated(address collection);
    function NFTCreated(address _collection ) public {
        emit CollectionCreated(_collection);
        IHub(Hub).emitNFTCreatedEvent(_collection);
    }
}