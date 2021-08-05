/**
 *Submitted for verification at Etherscan.io on 2021-01-13
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

contract LeviathanCoreTaskV2 {
    address private constant _leviathan = 0xeE52c053e091e8382902E7788Ac27f19bBdFeeDc;
    address private constant _wlev = 0xA2482ccFF8432ee68b9A26a30fCDd2782Bd81BED;
    address private constant _claim = 0xb4345a489e4aF3a33F81df5FB26E88fFeCEd6489;

    mapping(uint => uint[3]) public stackMap;

    // task rotates through 11 'stacks', 3 leviathans each
    uint public stackID;

    constructor()
    public {
        stackMap[0] = [280, 281, 282];

        stackMap[1] = [283, 284, 285];

        stackMap[2] = [286, 287, 288];

        stackMap[3] = [289, 135, 276];

        stackMap[4] = [277, 278, 279];

        stackMap[5] = [290, 291, 292];

        stackMap[6] = [294, 295, 296];

        stackMap[7] = [273, 297, 274];

        stackMap[8] = [298, 275, 299];

        stackMap[9] = [300, 301, 311];

        stackMap[10] = [316, 331, 332];
    }

    function check(uint _requirement)
    external view returns (uint256) {
        uint[3] memory IDstack = stackMap[stackID];

        uint totalClaim;

        for(uint x = 0;x < 3; x++)
            totalClaim += IWLEV(_wlev).checkClaim(IDstack[x]);

        if(totalClaim >= _requirement)
            return 0;
        else
            return _requirement - totalClaim;
    }

    function execute()
    external {
        uint[3] memory IDstack = stackMap[stackID];

        for(uint x = 0;x < 3; x++)
            if(IWLEV(_wlev).checkClaim(IDstack[x]) > 0)
                IRelease(_claim).release(IDstack[x]);

        stackID++;

        if(stackID > 10)
            stackID = 0;
    }
}