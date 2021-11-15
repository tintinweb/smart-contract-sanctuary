/**
 *Submitted for verification at BscScan.com on 2021-11-14
*/

interface IHub 
{
    event NFTCreatedEvent(address collection);
    
    function emitNFTCreatedEvent(address _collection) external ;
    
}

contract Hub is IHub {
    address owner;
    
    constructor(address _owner) {
        owner = _owner;
    }
    
    function emitNFTCreatedEvent(address _collection) external override{
        emit NFTCreatedEvent(_collection);
    }
}