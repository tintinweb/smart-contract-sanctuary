/**
 *Submitted for verification at Etherscan.io on 2021-01-19
*/

pragma solidity <=0.6.2;

interface ILeviathan {
  function tokensOfOwner(address owner) external view returns (uint256[] memory);  
  function setApprovalForAll(address operator, bool _approved) external;
}

interface IRelease {
    function release(uint ID) external;
}

interface IWLEV {
    function checkClaim(uint ID) external view returns (uint256);
    function wrap(uint256[] calldata _leviathansToWrap) external;
    function unwrap(uint256 _amount) external;
}

interface IERC20 {
	function balanceOf(address) external view returns (uint256);
}
contract WLEVClaimTask {
    address private constant _leviathan = 0xeE52c053e091e8382902E7788Ac27f19bBdFeeDc;
    address private constant _wlev = 0xA2482ccFF8432ee68b9A26a30fCDd2782Bd81BED;
    address private constant _claim = 0xb4345a489e4aF3a33F81df5FB26E88fFeCEd6489;

    // index of the next index, if equal or greater than the length of the total number of NFTs held by the WLEV contract, reset back to 0
    uint public NFTIndex;

    function check(uint _requirement)
    external view returns (uint256) {
        uint index = NFTIndex;

        // array of NFT IDs owned by the WLEV contract
        uint[] memory tokensOwned = ILeviathan(_leviathan).tokensOfOwner(_wlev);
    
        // if the index is greater than or equal the length of the array of NFT IDs returned, reset the index back to 0
        if(index >= tokensOwned.length)
            index = 0;
        
        // the ID of the NFT we want to check
        uint NFTID = tokensOwned[index];

        uint totalClaim = IWLEV(_wlev).checkClaim(NFTID);

        if(totalClaim >= _requirement)
            return 0;
        else
            return _requirement - totalClaim;
    }

    function execute()
    external {
        // array of NFT IDs owned by the WLEV contract
        uint[] memory tokensOwned = ILeviathan(_leviathan).tokensOfOwner(_wlev);

        // if the index is greater than or equal the length of the array of NFT IDs returned, reset the index back to 0
        if(NFTIndex >= tokensOwned.length)
            NFTIndex = 0;

        // the ID of the NFT we want to check
        uint NFTID = tokensOwned[NFTIndex];

        IRelease(_claim).release(NFTID);

        NFTIndex++;
    }
}

contract WLEVForwarderTask {
    address private constant _surf = 0xEa319e87Cf06203DAe107Dd8E5672175e3Ee976c;
    address private constant _leviathan = 0xeE52c053e091e8382902E7788Ac27f19bBdFeeDc;
    address private constant _wlev = 0xA2482ccFF8432ee68b9A26a30fCDd2782Bd81BED;
    address private constant _claim = 0xb4345a489e4aF3a33F81df5FB26E88fFeCEd6489;

    constructor()
    public {
        ILeviathan(_leviathan).setApprovalForAll(_wlev, true);
    }

    function check(uint _requirement)
    external view returns (uint256) {
        uint balance = IERC20(_surf).balanceOf(_wlev);

        if(balance >= _requirement)
            return 0;
        else
            return _requirement - balance;
    }

    function execute()
    external {
        // wrap the sole NFT held by this task contract, triggering the 'SURF forwarding' functionality in the WLEV contract
        IWLEV(_wlev).wrap(ILeviathan(_leviathan).tokensOfOwner(address(this)));

        // unwrap the NFT back
        IWLEV(_wlev).unwrap(1);
    }
}