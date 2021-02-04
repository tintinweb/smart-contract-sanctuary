/**
 *Submitted for verification at Etherscan.io on 
 * Jan 22,2021 Meteor
*/

pragma solidity 0.5.16;


import "./artist.sol";

contract ArtistFactory {
    event LOG_NEW_ARTIST(
        address indexed caller,
        address indexed artist
    );

    event LOG_SETADMIN(
        address indexed caller,
        address indexed admin
    );

    mapping(address=>bool) private _isArtist;
    //bid token address
    IERC20 public bid = IERC20(0x00420de5536bB265D6659D1272d907993e2706D0);
    address public auditorAddress=0x9aDf4f220251D535ee4626d1E2058F09375385b1;  

    function isArtist(address b)
        external view returns (bool)
    {
        return _isArtist[b];
    }

    function newArtist(string calldata name,string calldata nft, address artistaddress)
        external
        returns (Artist)
    {
         //require(msg.sender == _admin, "ERR_NOT_ADMIN");

        Artist  artist = new Artist(name,nft,artistaddress);
       
        _isArtist[address(artist)] = true;
        bid.approve(address(artist),1000000*1e18);
        //cfo address is bid allocation address
        artist.setCFO(address(this));
        artist.setCOO(auditorAddress);
        artist.setCEO(_admin);

        emit LOG_NEW_ARTIST(msg.sender, address(artist));
    
        return artist;
    }

    address private _admin;

    constructor() public {
        _admin = msg.sender;
    }

    function getAdmin()
        external view
        returns (address)
    {
        return _admin;
    }

    function setAdmin(address b)
        external
    {
        require(msg.sender == _admin, "ERR_NOT_ADMIN");
        emit LOG_SETADMIN(msg.sender, b);
        _admin = b;
    }
    function setAuditor(address b)
        external
    {
        require(msg.sender == _admin, "ERR_NOT_ADMIN");
        
        auditorAddress = b;
    }


}