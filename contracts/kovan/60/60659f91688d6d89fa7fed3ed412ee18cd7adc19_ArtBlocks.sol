/**
 *Submitted for verification at Etherscan.io on 2021-08-28
*/

pragma solidity 0.6.12;

interface IERC721 {
    function mint(address _to, uint256 _projectId, address _by) external;
}


contract ArtBlocks{
    struct Project {
        string name;
        uint256 invocations;
        uint256 maxInvocations;
        bool paused;
        uint256 pricePerTokenInWei;
    }

    mapping(uint256 => Project) projects;
    function mint(address _to, uint256 _projectId, address _by) external{
        projects[_projectId].invocations = projects[_projectId].invocations + 1;
    }

    function projectTokenInfo(uint256 _projectId) view public returns (address artistAddress, uint256 pricePerTokenInWei, uint256 invocations, uint256 maxInvocations, bool active, address additionalPayee, uint256 additionalPayeePercentage ,string memory currency, address currencyAddress) {
        artistAddress = address( 0x00);
        pricePerTokenInWei = projects[_projectId].pricePerTokenInWei;
        invocations = projects[_projectId].invocations;
        maxInvocations = projects[_projectId].maxInvocations;
        active = true;
        additionalPayee = address( 0x00);
        additionalPayeePercentage = 0;
        currency = '';
        currencyAddress = address( 0x00);
    }

    function setProject(uint256 _projectId,  uint256 _invocations,
        uint256 _maxInvocations) external{
        projects[_projectId].invocations = _invocations;
        projects[_projectId].maxInvocations = _maxInvocations;
    }
}