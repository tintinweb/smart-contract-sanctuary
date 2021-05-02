/**
 *Submitted for verification at Etherscan.io on 2021-05-02
*/

contract test {
    mapping (uint => uint) public experiences; //tokenId => xp

    function grantExperience(uint256[] calldata _tokenIds, uint256[] calldata _xpValues) external  {
        require(_tokenIds.length == _xpValues.length, "DAOFacet: IDs must match XP array length");
        for (uint256 i; i < _tokenIds.length; i++) {
            experiences[_tokenIds[i]] = experiences[_tokenIds[i]] + _xpValues[i];
        }
    }
}