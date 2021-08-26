/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

////// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract MoonChadRoyalties {
    uint256 private royalties = 0;
    address payable public communityWalletAddress;
    address[] private teamMembers;
    mapping(address => uint256) private royaltiesShare;

    modifier onlyMaintainer(address sender) {
        require(
            sender == teamMembers[0] || sender == teamMembers[1],
            "Caller must be a maintainer."
        );
        _;
    }

    modifier onlyProjectTeam(address sender) {
        require(
            sender == teamMembers[0] ||
                sender == teamMembers[1] ||
                sender == teamMembers[2],
            "Caller must be a project team member."
        );
        _;
    }

    constructor(address[] memory _teamMembers) payable {
        // Set project variables
        teamMembers = _teamMembers;
        for (uint256 i = 0; i < _teamMembers.length; i++) {
            address teamMember = _teamMembers[i];
            royaltiesShare[teamMember] = 0;
        }
    }

    fallback() external payable {}

    receive() external payable {}

    function splitRoyalties() public onlyMaintainer(msg.sender) {
        uint256 existingRoyalties = 0;
        for (uint256 i = 0; i < teamMembers.length; i++) {
            address member = teamMembers[i];
            existingRoyalties = existingRoyalties + royaltiesShare[member];
        }

        uint256 _unassignedRoyalties = address(this).balance -
            existingRoyalties;

        uint256 share = _unassignedRoyalties / 10;

        uint256 artistShare = share * 5;
        uint256 communityShare = share * 4;
        uint256 projectTeamShare = share / 2;

        royaltiesShare[teamMembers[0]] =
            royaltiesShare[teamMembers[0]] +
            projectTeamShare;
        royaltiesShare[teamMembers[1]] =
            royaltiesShare[teamMembers[1]] +
            projectTeamShare;
        royaltiesShare[teamMembers[2]] =
            royaltiesShare[teamMembers[2]] +
            artistShare;

        (bool success, ) = communityWalletAddress.call{value: communityShare}(
            ""
        );
        require(success, "Transfer failed.");
    }

    function withdrawRoyalties(address _to) public onlyProjectTeam(msg.sender) {
        require(
            royaltiesShare[_to] > 0,
            "The address has no project share to withdraw."
        );

        uint256 share = royaltiesShare[_to];

        royaltiesShare[_to] = 0;

        (bool success, ) = _to.call{value: share}("");
        require(success, "Transfer failed.");
    }

    function withdrawAll() public onlyMaintainer(msg.sender) {
        require(address(this).balance > 0, "Balance must be greater than 0");
        
        royaltiesShare[teamMembers[0]] = 0;
        royaltiesShare[teamMembers[1]] = 0;
        royaltiesShare[teamMembers[2]] = 0;
        
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function getShareBalance()
        public
        view
        onlyProjectTeam(msg.sender)
        returns (uint256)
    {
        return royaltiesShare[msg.sender];
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setCommunityWalletAddress(address payable _communityWalletAddress)
        public
        onlyMaintainer(msg.sender)
    {
        communityWalletAddress = _communityWalletAddress;
    }
}