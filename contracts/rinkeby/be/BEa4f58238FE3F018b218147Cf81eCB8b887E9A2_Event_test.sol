pragma solidity ^0.8.0;


contract Event_test {

    function hashRechargeTransaction(uint256 _ethAmount, uint256 _ticketNumber, address sender, string memory nonce) public pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(_ethAmount, _ticketNumber, sender, nonce, "ichiban_recharge"))
            )
        );
        return hash;
    }

    function hashWithdrawTransaction(uint256 _amount, uint256 _tokenId, address _contractAddress, address _fromAddress,address _toAddress, string memory nonce) public pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(_amount, _tokenId, _contractAddress, _fromAddress,_toAddress,nonce,"ichiban_withdraw"))
            )
        );
        return hash;
    }

    function hasBatchWithdrawTransaction(uint256[] memory _amountArray,address[] memory _contractAddressArray, uint256[] memory _tokenIdArray,  address[] memory _fromAddressArray,address _toAddress, string memory nonce) public pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(_amountArray,_tokenIdArray,_contractAddressArray, _fromAddressArray,_toAddress,nonce,"ichiban_withdraw"))
            )
        );
        return hash;
    }

}