/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

// File: contracts\OwnableContract.sol

pragma solidity ^0.8.0;

contract OwnableContract {
    address public owner;
    address public pendingOwner;
    address public admin;
    address public dev;

    event NewAdmin(address oldAdmin, address newAdmin);
    event NewDev(address oldDev, address newDev);
    event NewOwner(address oldOwner, address newOwner);
    event NewPendingOwner(address oldPendingOwner, address newPendingOwner);

    constructor(){
        owner = msg.sender;
        admin = msg.sender;
        dev   = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"onlyOwner");
        _;
    }

    modifier onlyPendingOwner {
        require(msg.sender == pendingOwner,"onlyPendingOwner");
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == admin || msg.sender == owner,"onlyAdmin");
        _;
    } 

    modifier onlyDev {
        require(msg.sender == dev  || msg.sender == owner,"onlyDev");
        _;
    } 
    
    function transferOwnership(address _pendingOwner) public onlyOwner {
        emit NewPendingOwner(pendingOwner, _pendingOwner);
        pendingOwner = _pendingOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit NewOwner(owner, address(0));
        emit NewAdmin(admin, address(0));
        emit NewPendingOwner(pendingOwner, address(0));

        owner = address(0);
        pendingOwner = address(0);
        admin = address(0);
    }
    
    function acceptOwner() public onlyPendingOwner {
        emit NewOwner(owner, pendingOwner);
        owner = pendingOwner;

        address newPendingOwner = address(0);
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }    
    
    function setAdmin(address newAdmin) public onlyOwner {
        emit NewAdmin(admin, newAdmin);
        admin = newAdmin;
    }

    function setDev(address newDev) public onlyOwner {
        emit NewDev(dev, newDev);
        dev = newDev;
    }

}

// File: contracts\HeadPortraitGift.sol

pragma solidity ^0.8.0;


interface HeadPortrait721Interface{
    function mint(address user, uint256 tokenId, uint256[] memory attributes) external;
    function totalSupply() external returns(uint256);
}

contract HeadPortraitGift is OwnableContract{

    address public headPortrait721;

    address public signer1;
    address public signer2;

    uint256 public tokenId = 1001;
    
    uint256 public claimIndex = 0;

    uint256[] public hat = [101, 102, 103, 104, 105, 106, 107, 108, 109];
    uint256[] public skinColor = [201, 202, 203, 204, 205, 206, 207, 208, 209];
    uint256[] public eyes = [301, 302, 303, 304, 305, 306, 307, 308, 309];
    uint256[] public beak = [401, 402, 403, 404, 405, 406, 407, 408, 409];
    uint256[] public clothes = [501, 502, 503, 504, 505, 506, 507, 508, 509];
    uint256[] public background = [601, 602, 603, 604, 605, 606, 607, 608, 609];

    mapping(uint256 => bool) public claimedOrderId;

    event Claim(uint256 orderId, uint256 tokenId, address user, address signer, uint256 index);
    event AleadyClaim(uint256 orderId, uint256 tokenId, address user);

    constructor(address _headPortrait721){
        headPortrait721 = _headPortrait721;
    }

    function setSigner1(address _signer) public onlyOwner{
        signer1 = _signer;
    }

    function setSigner2(address _signer) public onlyOwner{
        signer2 = _signer;
    }

    function updateHeadPortrait721(address _headPortrait721) public onlyAdmin{
        headPortrait721 = _headPortrait721;
    }

    function getOrderIdIsClaim(uint256[] memory orderId) public view returns(bool flag){
        for(uint256 i=0; i<orderId.length; i++){
            if(!claimedOrderId[orderId[i]]){
                flag = false;
                break;
            }
        }
    }

    function batchClaim(uint256[] memory orderId, uint256[] memory amount, bytes[] memory signature) public{
        require(orderId.length == amount.length, "orderId length should eq floatAmount length");
        require(orderId.length == signature.length, "orderId length should eq signature length");
        for(uint256 i=0; i<orderId.length; i++){
            claim(orderId[i], amount[1], signature[i]);
        }
    }

    function claim(uint256 orderId, uint256 amount, bytes memory signature) public{
        if(claimedOrderId[orderId]){
            emit AleadyClaim(orderId, tokenId, msg.sender);
            return;
        }

        bytes32 hash1 = keccak256(abi.encode(address(this), msg.sender, orderId, amount));

        bytes32 hash2 = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash1));

        address _signer = recover(hash2, signature);
        require(_signer == signer1 || _signer == signer2, "invalid signer");

        uint256[] memory attributes = getAttributes(tokenId);
        HeadPortrait721Interface headPortrait721Interface = HeadPortrait721Interface(headPortrait721);
        headPortrait721Interface.mint(msg.sender, tokenId, attributes);

        tokenId++;
        claimIndex++;

        emit Claim(orderId, tokenId, msg.sender, _signer, claimIndex);
    }

    function getAttributes(uint256 _tokenId) internal view returns(uint256[] memory attributes){
        uint256 random = getRandom(_tokenId);
        attributes = new uint256[](6);
        uint256 _hat = random % 1000;
        if(_hat < 10){
            attributes[0] = hat[0];
        }else{
            uint256 index = _hat / 165;
            attributes[0] = hat[index + 1];
        }

        uint256 _skinColor = random % 100;
        if(_skinColor < 1){
            attributes[1] = skinColor[0];
        }else if(_skinColor < 20){
            attributes[1] = skinColor[1];
        }else if(_skinColor < 40){
            attributes[1] = skinColor[2];
        }else if(_skinColor < 65){
            attributes[1] = skinColor[3];
        }else if(_skinColor < 100){
            attributes[1] = skinColor[4];
        }

        uint256 _eyes = random % 10000;
        if(_eyes < 100){
            attributes[2] = eyes[0];
        }else{
            uint256 index = _eyes / 2475;
            attributes[2] = eyes[index + 1];
        }

        uint256 _beak = random % 10000;
        if(_beak < 100){
            attributes[3] = beak[0];
        }else{
            uint256 index = _beak / 3300;
            attributes[3] = beak[index + 1];
        }

        uint256 _clothes = random % 7;
        attributes[4] = clothes[_clothes];

        uint256 _background = random % 100;
        if(_background < 1){
            attributes[5] = background[0];
        }else if(_background < 6){
            attributes[5] = background[1];
        }else if(_background < 21){
            attributes[5] = background[2];
        }else if(_background < 41){
            attributes[5] = background[3];
        }else if(_background < 66){
            attributes[5] = background[4];
        }else if(_background < 100){
            attributes[5] = background[5];
        }
    }

    function getRandom(uint256 _tokenId) public view returns(uint256){
        uint256 random = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.coinbase))) + block.timestamp + _tokenId;
        return random;
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
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

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
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
}