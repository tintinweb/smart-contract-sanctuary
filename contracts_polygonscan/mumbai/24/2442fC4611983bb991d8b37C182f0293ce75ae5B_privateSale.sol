/**
 *Submitted for verification at polygonscan.com on 2022-01-09
*/

pragma solidity 0.8.7;
// SPDX-License-Identifier: MIT

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract VerifySignature is Ownable {
    
    function getMessageHash(
        address _to
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    function verify(
        address _signer,
        bytes memory signature
    ) public view returns (bool) {
        require(_signer == owner(), "Signer should be owner only.");
        bytes32 messageHash = getMessageHash(msg.sender);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        private
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

    }
}

contract privateSale is VerifySignature{

    uint256 public releaseTime;
    uint256 public tokenPrice;
    address payable ownerAccount;
    uint256 public minLimit;
    uint256 public maxLimit;
    uint256 public remainingTokens;
    address[] public addresses;
    bool isSaleStart;
    //Re-Entrancy guard
    bool internal locked;
    
    struct userData{
        uint256 investAmount;
        uint256 tokenAmount;
        uint256 time;
    }
    mapping (address => userData) public users;
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
    constructor(){
        releaseTime = 0;  
        tokenPrice = 0;
        ownerAccount = payable(address(msg.sender));
        minLimit = 0;
        maxLimit = 0;
        isSaleStart = false;
    }

    // OWNER NEED TO CALL THIS FUNCTION BEFORE START ICO
    // OWNER ALSO NEED TO SET A GOAL OF TOKEN AMOUNT FOR FUND RAISING
    // THIS FUNCTION WILL TRANSFER THE TOKENS FROM OWNER TO CONTRACT
    function startBuying(uint256 tokenAmount, uint256 time, uint256 price) public onlyOwner{
        require(tokenAmount > 0 && price > 0, "Token Amount or price is wrong.");
        require(time >= block.timestamp, "Time is wrong.");
        require(isSaleStart == false, "Sale is already started.");
        minLimit = 25000;
        maxLimit = 250000;
        releaseTime = time;
        remainingTokens = tokenAmount;
        tokenPrice = price;
        isSaleStart = true;
    }

    
    //  THIS FUMCTION WILL BE USED BY INVESTOR FOR BUYING TOKENS
    //  IF THE OWNER WILL END ICO THEN NO ONE CAN INVEST ANYMORE 
    function buyToken(bytes memory _signature, uint256 amountOfToken) public noReentrant payable{
        require(verify(owner(), _signature), "You are not Whitelisted.");
        require(block.timestamp <= releaseTime, "TokenSale is ended.");
        require(msg.value == (amountOfToken * tokenPrice ),"You are passing wrong value.");
        require(amountOfToken >= minLimit,"You are exceeding min value.");
        require(amountOfToken <= maxLimit,"You are exceeding max value.");
        
        address sender =  msg.sender; 
        
        (bool success,) = owner().call{value: msg.value}("");
        if(!success) {
            revert("Payment Sending Failed");
        }
        users[sender] = userData(msg.value, amountOfToken, block.timestamp);
        addresses.push(sender);
        remainingTokens -= amountOfToken; 
    }

    // IT WILL RETURN ALL THE USERS
    function getAllUsers() public view onlyOwner returns(address[] memory) {
        return addresses;
    }

}