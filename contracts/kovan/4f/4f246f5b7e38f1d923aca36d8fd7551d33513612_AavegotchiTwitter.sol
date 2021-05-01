/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IAavegotchi {
    function grantExperience(uint256[] calldata _tokenIds, uint256[] calldata _xpValues) external;
    function ownerOf(uint256 _tokenId) external view returns (address owner_);
}

contract AavegotchiTwitter {
    uint256[] public followers;
    uint256[] public experiences;

    address public owner;
    address public manager;

    IAavegotchi public aavegotchi;

    //mapping (uint => uint) public canUpdate; //tokenId => timestamp
    mapping (uint => uint) public unclaimedXp; //tokenId => unclimed xp
    mapping (uint => uint) public nextClaim; //tokenId => timestamp when claim available

    uint public claimPeriod = 2 minutes;

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner.");
        _;
    }

    modifier onlyManager() {
        require(manager == msg.sender, "Caller is not the manager.");
        _;
    }

    constructor(address _aavegotchi) {
        owner = msg.sender;
        manager = msg.sender;
        addCondition(1000, 1);
        addCondition(10000, 2);
        addCondition(100000, 5);
        addCondition(10000000000, 10);
        aavegotchi = IAavegotchi(_aavegotchi);
    }


    function claim(uint _tokenId) external {
        require(nextClaim[_tokenId] < block.timestamp);
        //require(aavegotchi.ownerOf(_tokenId) == msg.sender);
        uint256[] memory ids = new uint[](1);
        uint256[] memory xps = new uint[](1); 
        ids[0] = _tokenId;
        xps[0] = unclaimedXp[_tokenId];
        aavegotchi.grantExperience(ids, xps);
        unclaimedXp[_tokenId] = 0;
        nextClaim[_tokenId] = block.timestamp + claimPeriod;
    }


    function addExperience(uint256[] calldata _tokenIds, uint256[] calldata _followers) external  {
        require(_tokenIds.length == _followers.length, "IDs must match _followers array length");
        for (uint256 i; i < _tokenIds.length; i++) {
            _addXp(_tokenIds[i], _followers[i]);
        }
    }

    function _addXp(uint _tokenId, uint _followers) internal {
        //require(canUpdate[_tokenId] < block.timestamp);
        uint xp = getExp(_followers);
        uint unclaimed = unclaimedXp[_tokenId] + xp;
        require(unclaimed <= 1000, "Cannot grant more than 1000 XP at a time");
        require(unclaimed >= xp);
        unclaimedXp[_tokenId] = unclaimed;
        //canUpdate[_tokenId] = block.timestamp + 23 hours;
    }

    function addCondition(uint _followers, uint _experiences) public onlyOwner {
        followers.push(_followers);
        experiences.push(_experiences);
    }

    function editCondition(uint _index, uint _followers, uint _experiences) external onlyOwner {
        require(_index < followers.length);
        require(_index < experiences.length);
        followers[_index] = _followers;
        experiences[_index] = _experiences;
    }

    function delLastCondition() external onlyOwner {
        require(followers.length > 0);
        require(experiences.length > 0);
        followers.pop();
        experiences.pop();
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
    }

    function setManager(address _newManager) external onlyOwner{
        require(_newManager != address(0));
        manager = _newManager;
    }

    function getExp(uint _followers) public view returns (uint xp) {
        for(uint i = 0; i < followers.length; i++) {
            if (_followers < followers[i]) {
                return experiences[i];
            }
        }
    }


}