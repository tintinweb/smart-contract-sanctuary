/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

interface IHub 
{
    event NFTCreatedEvent(
        address collection,
        address owner,
        uint256 tokenID,
        uint256 royaltyRate,
        string tokenCID);
    
    function emitNFTCreatedEvent(
        address _collection, 
        address _owner,
        uint256 _tokenID,
        uint256 _royaltyRate,
        string memory _tokenCID) external ;
    
}

contract Hub is IHub {
    address owner;
    
    constructor(address _owner) {
        owner = _owner;
    }
    
    function emitNFTCreatedEvent(
        address _collection, 
        address _owner,
        uint256 _tokenID,
        uint256 _royaltyRate,
        string memory _tokenCID
    ) external override{
        emit NFTCreatedEvent(_collection, _owner, _tokenID, _royaltyRate, _tokenCID);
    }
}