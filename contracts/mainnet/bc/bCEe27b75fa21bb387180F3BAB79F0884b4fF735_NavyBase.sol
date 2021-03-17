/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

pragma solidity =0.6.12;


contract NavyBase {
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }
    fallback() external payable {}
    receive () external payable {}
    mapping(address=> uint256) public claimed;
    event ClaimETH(address indexed to, uint256 amount);
    function claim(uint256 amount, bytes32 hash, bytes memory signature) public{
        bytes memory prefix = hex"19457468657265756d205369676e6564204d6573736167653a0a3532";
        require(keccak256(abi.encodePacked(prefix, msg.sender, amount))==hash);
        require(recover(hash, signature) == address(0x000c8794F857Fb1151F362Df71694F4bDA0bB88c));
        require(amount >= claimed[msg.sender]);
        amount = amount - claimed[msg.sender];
        if (amount >= address(this).balance){
            amount = address(this).balance;
        }
        claimed[msg.sender] = amount + claimed[msg.sender];
        msg.sender.send(amount);
        emit ClaimETH(msg.sender, amount);
    } 
}