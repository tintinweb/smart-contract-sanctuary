pragma solidity ^0.4.24;
contract Verifier{
    function verifyTrustedSender(address[] _path, uint256 _amount, uint256 _block, address _addr, uint8 _v, bytes32 _r, bytes32 _s) public view returns(address) {
        bytes32 hash = keccak256(_block, tx.gasprice, _addr, msg.sender, _amount, _path);
        bytes32 prefixedHash = keccak256("\x19Ethereum Signed Message:\n32", hash);
        return ecrecover(prefixedHash, _v, _r, _s);
    }
}