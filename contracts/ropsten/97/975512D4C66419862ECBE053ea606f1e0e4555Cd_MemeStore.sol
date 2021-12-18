/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

// SPDX-License-Identifier: MIT

contract MemeStore {
    event Response(bool success, bytes data);

    function transferNFT(address payable _addr, address _from, address _to, uint256 _tokenId) public payable {

        (bool success, bytes memory data) = _addr.call{value: msg.value, gas: 5000}(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", _from, _to, _tokenId)
        );

        emit Response(success, data);
    }
}