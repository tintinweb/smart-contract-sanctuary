pragma solidity ^0.5.0;

interface TeamInterface {

    function isOwner() external view returns (bool);

    function isAdmin(address _sender) external view returns (bool);

    function isDev(address _sender) external view returns (bool);

}

/**
 * @title Artist Contract
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="dcaaafb5aea5a4b19cedeaeff2bfb3b1">[email&#160;protected]</a>>
 */
contract Artist {

    TeamInterface private team; 
    mapping(bytes32 => address payable) private artists; 

    constructor(address _teamAddress) public {
        require(_teamAddress != address(0));
        team = TeamInterface(_teamAddress);
    }

    function() external payable {
        revert();
    }

    event OnUpgrade(address indexed _teamAddress);
    event OnAdd(bytes32 _artistID, address indexed _address);
    event OnUpdateAddress(bytes32 _artistID, address indexed _address);

    modifier onlyAdmin() {
        require(team.isAdmin(msg.sender));
        _;
    }

    function upgrade(address _teamAddress) external onlyAdmin() {
        require(_teamAddress != address(0));
        team = TeamInterface(_teamAddress);
        emit OnUpgrade(_teamAddress);
    }

    function getAddress(bytes32 _artistID) external view returns (address payable) {
        return artists[_artistID];
    }
   
    function add(bytes32 _artistID, address payable _address) external onlyAdmin() {
        require(this.hasArtist(_artistID) == false);
        artists[_artistID] = _address;
        emit OnAdd(_artistID, _address);
    }

    function hasArtist(bytes32 _artistID) external view returns (bool) {
        return artists[_artistID] != address(0);
    }

    function updateAddress(bytes32 _artistID, address payable _address) external onlyAdmin() {
        require(artists[_artistID] != address(0) && _address != address(0));
        artists[_artistID] = _address;
        emit OnUpdateAddress(_artistID, _address);
    }

}