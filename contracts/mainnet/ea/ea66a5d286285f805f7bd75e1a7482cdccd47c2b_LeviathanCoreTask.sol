/**
 *Submitted for verification at Etherscan.io on 2021-01-09
*/

pragma solidity <=0.6.2;

interface ILeviathan {
  function tokensOfOwner(address owner) external view returns (uint256[] memory);  
}

interface IRelease {
    function release(uint ID) external;
}

interface IWLEV {
    function checkClaim(uint ID) external view returns (uint256); 
}

contract LeviathanCoreTask {
    address private constant _leviathan = 0xeE52c053e091e8382902E7788Ac27f19bBdFeeDc;
    address private constant _wlev = 0xA2482ccFF8432ee68b9A26a30fCDd2782Bd81BED;
    address private constant _claim = 0xb4345a489e4aF3a33F81df5FB26E88fFeCEd6489;
    address private constant _core = 0xceC62ebf1cd98b91556D84eebd5F8542E301b8b1;

    uint256[] private _IDs;

    function check(uint _requirement)
    external view returns (uint256) {
        uint totalClaim;

        for(uint x = 0;x < _IDs.length; x++)
            totalClaim += IWLEV(_wlev).checkClaim(_IDs[x]);

        if(totalClaim >= _requirement)
            return 0;
        else
            return _requirement - totalClaim;
    }

    function execute()
    external {
        for(uint x = 0;x < _IDs.length; x++)
            IRelease(_claim).release(_IDs[x]);
    }

    function update()
    external {
        _IDs = ILeviathan(_leviathan).tokensOfOwner(_core);
    }
}