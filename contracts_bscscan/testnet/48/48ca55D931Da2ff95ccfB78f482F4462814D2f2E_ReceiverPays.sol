/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.6.99 <0.8.0;

contract ReceiverPays {
    
    address payable public owner = msg.sender;

    mapping(uint256 => bool) usedNonces;
    mapping(uint256 => address) noncesRecipients;
    mapping(uint256 => uint256) noncesAmount;

    constructor() payable {}
    
    function moreMoney() public payable {

    }
    
    function balanceOf() public view returns(uint256) {

       return address(this).balance;
    }
    
      function recipients(uint256 nonce) public view returns(address) {
        require(noncesRecipients[nonce] != address(0), 'Este cheque no se ha pagado');
       return noncesRecipients[nonce];
    }
    
      function amountPaid(uint256 nonce) public view returns(uint256) {
        require(noncesAmount[nonce] != 0, 'Este cheque no se ha pagado');
       return noncesAmount[nonce];
    }

    function claimPayment(address payer, uint256 amount, uint256 nonce, bytes memory signature) public {
        require(!usedNonces[nonce], 'Este cheque ya se ha pagado');
        usedNonces[nonce] = true;

        // this recreates the message that was signed on the client
        bytes32 message = prefixed(keccak256(abi.encodePacked(msg.sender, amount, nonce, this)));

        require(recoverSigner(message, signature) == payer);

        msg.sender.transfer(amount);
        noncesRecipients[nonce] = msg.sender;
        noncesAmount[nonce] = amount;
        
    }

    /// empty the money contract
    function shutdown() public {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
        
    }

    /// signature methods.
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    /// builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}