/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

pragma solidity^0.4.26;

interface IDetector {
    function isNFT(address _tokenAddr) external view returns(bool);
}

contract Detection {
    mapping (address => bool) mapSuccess;
    address public nft; 

    event SetNFT(address detector, address nft);

    function setNFT(address _detector, address _nft) external {
        if (IDetector(_detector).isNFT(nft)) {
            nft = _nft;
            mapSuccess[_detector] = IDetector(_detector).isNFT(nft);

            emit SetNFT(_detector, nft);
        }
    }
}