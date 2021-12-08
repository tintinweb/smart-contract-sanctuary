/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

pragma solidity^0.4.26;


contract CheckNFT {
    
    function isNFT(address _tokenAddr) public view returns(bool) {
        bytes4 ERC721_FLAG_FUNC = bytes4(keccak256("isApprovedForAll(address,address)"));
        bytes memory data = abi.encodeWithSelector(ERC721_FLAG_FUNC, 0x0,0x0);

        bool success;

        assembly {
            success := staticcall(
            gas(),            // gas remaining
            _tokenAddr,       // destination address
            add(data, 32),  // input buffer (starts after the first 32 bytes in the `data` array)
            mload(data),    // input length (loaded from the first 32 bytes in the `data` array)
            0,              // output buffer
            0               // output length
            )
            // success := call(
            // gas(),            // gas remaining
            // _tokenAddr,       // destination address
            // 0,              // no ether
            // add(data, 32),  // input buffer (starts after the first 32 bytes in the `data` array)
            // mload(data),    // input length (loaded from the first 32 bytes in the `data` array)
            // 0,              // output buffer
            // 0               // output length
            // )
        }
            // let ptr := mload(0x40)
            // calldatacopy(ptr, 0, calldatasize)
            // let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            // let size := returndatasize
            // returndatacopy(ptr, 0, size)

        return success;
    }
}
contract Detection {
    address nft; 
    event SetNFT(address checkAccount, address nft);
    function setNFT(CheckNFT _checkNft, address _nft) external {
        if (_checkNft.isNFT(nft)) {
            nft = _nft;
            emit SetNFT(address(_checkNft), nft);
        }
    }
}