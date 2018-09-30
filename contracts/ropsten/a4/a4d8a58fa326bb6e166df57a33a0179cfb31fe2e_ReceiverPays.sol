pragma solidity 0.4.24;

contract ReceiverPays {
    mapping(uint256 => bool) public usedNonces;
    address public owner = msg.sender;
    
    // The purpose of the constructor is to give funds to this contract
    constructor() public payable {}
    
    /// @notice A function that executes the transfer of a specific amount of ether to a user based on a off-chain signed message by the owner with a specific nonce and amounts
    /// @param amount The amount of ETH that you will receive after executing the function successfully. It must be in WEI and the exact same as the initial signed message
    /// @param nonce A unique number like 1 or 2 that is used to identify that specific message to avoid replay attacks
    /// @param signature A hexadecimal bytes signature that contains the signed message with the parameters set up by the signer
    function receivePayment(uint256 amount, uint256 nonce, bytes signature) public {
        require(!usedNonces[nonce]);
        require(signature.length == 65);
        usedNonces[nonce] = true;
        
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(msg.sender, amount, nonce, address(this)))));
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        
        address originalSigner = ecrecover(message, v, r, s);
        require(originalSigner == owner);
        
        msg.sender.transfer(amount);
    }
}