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

contract Collection 
{
    address Hub;
    
    constructor(address _hub) {
        Hub = _hub;    
    }
    
    event CollectionCreated(
        address collection,
        address owner,
        uint256 tokenID,
        uint256 royaltyRate,
        string tokenCID);
    
    function NFTCreated(
    address _collection, 
        address _owner,
        uint256 _tokenID,
        uint256 _royaltyRate,
        string memory _tokenCID) public {
        emit CollectionCreated(_collection, _owner, _tokenID, _royaltyRate, _tokenCID);
        IHub(Hub).emitNFTCreatedEvent(_collection, _owner, _tokenID, _royaltyRate, _tokenCID);
    }
}