/**
 *Submitted for verification at BscScan.com on 2021-07-29
*/

pragma solidity ^0.6.9;
pragma experimental ABIEncoderV2;


interface IMintableToken {
    struct Fee {
        address recipient;
        uint256 value;
    }

    function mint(uint256 tokenId, uint8 v, bytes32 r, bytes32 s, Fee[] memory _fees, string memory tokenURI) external;

}

interface IAiright721 {
    function mint(address ownerNft, string memory name, string memory description, string memory tokenURI) external returns (uint256);
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract SignData {
    bytes32 public DOMAIN_SEPARATOR;
    string public NAME;

    bytes32 public UNLOCK_RARIBLE_TYPEHASH;
    bytes32 public UNLOCK_ORAI_TYPEHASH;

    mapping(address => uint) public nonces;


    constructor() public {
        NAME = "Orai swap nft";
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(NAME)),
                keccak256(bytes('1')),
                chainId,
                this
            )
        );
        UNLOCK_RARIBLE_TYPEHASH = keccak256("Data(string memory registerOrai, uint256 tokenOraiId, address to, uint256 nonceLock, bytes memory dataEth, uint8 v, bytes32 r, bytes32 s)");
        UNLOCK_ORAI_TYPEHASH = keccak256("Data(bytes memory data, uint8 v, bytes32 r, bytes32 s)");
    }

    function verify(bytes32 data, uint8 v, bytes32 r, bytes32 s) internal view returns (address sender){
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                data
            )
        );
        sender = ecrecover(digest, v, r, s);
    }
}

contract OraiSwapNft is SignData {
    struct OraiMappingData {
        string registerAddress;
        uint256 tokenId;
    }

    struct ETHMappingData {
        address registerAddress;
        uint256 tokenId;
    }

    struct LockingData {
        address registerEth;
        uint256 tokenEthId;
        address userEth;
        string registerOrai;
        uint256 tokenOraiId;
        string userOraiAddr;
        uint256 lockingCount;
    }

    mapping(bytes => uint256) public oraiToEths;

    mapping(bytes => uint256) public ethToOrais;

    mapping(address => bool) public isSigner;

    mapping(bytes => LockingData) public lockingData;

    mapping(bytes => uint256[]) public tokenMaps;

    mapping(uint256 => bool) public isAllowUnlocking;
    

    uint256 public lockingCount;

    address public owner;

    event LockNFT721(address registerEth, uint256 tokenEthId, address sender, string registerOrai, uint256 tokenOraiId, string userOrai, uint256 lockingCount);


    constructor() public {
        owner = msg.sender;
        isSigner[msg.sender] = true;

    }
    // FUNCTION MODIFITER -------------------------------------------------
    modifier onlyOwner(){
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    // FUNCTION PUBLIC ----------------------------------------------------
    
    function setSigner(address _signer, bool _isSigner) public onlyOwner {
        isSigner[_signer] = _isSigner;
    }

    function transferOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function setIsAllowUnlocking(uint256 key, bool result) public onlyOwner {
        isAllowUnlocking[key] = result;
    }

    function setLockingCount(uint256 _lockingCount) public onlyOwner {
        lockingCount = _lockingCount;
    }

    function unlockNftRarible(string memory _registerOrai, uint256 _tokenOraiId, address _to, uint256 nonceLock, bytes memory dataEth, uint8 v, bytes32 r, bytes32 s, IMintableToken.Fee[] memory _fee) external {
        address signer = verify(keccak256(abi.encode(UNLOCK_RARIBLE_TYPEHASH, address(this), _registerOrai, _tokenOraiId, _to, nonceLock)), v, r, s);
        require(isSigner[signer], "invalid signer");

        require(isAllowUnlocking[nonceLock] == false, "Unlocked");
        isAllowUnlocking[nonceLock] = true;

        string memory registerOrai = _registerOrai;
        uint256 tokenOraiId = _tokenOraiId;
        IMintableToken.Fee[] memory fee = _fee;
        address to = _to;

        (address regiterRarible, uint256 tokenRaribleId, uint8 vRarible, bytes32 rRarible, bytes32 sRarible, string memory tokenUrlRarible) = abi.decode(dataEth, (address, uint256, uint8, bytes32, bytes32, string));


        bytes memory key = abi.encode(registerOrai, regiterRarible, tokenOraiId);

        if (oraiToEths[key] == 0) {
            IMintableToken(regiterRarible).mint(tokenRaribleId, vRarible, rRarible, sRarible, fee, tokenUrlRarible);
            oraiToEths[key] = tokenRaribleId;

            ethToOrais[abi.encode(regiterRarible, registerOrai, tokenRaribleId)] = tokenOraiId;

            tokenMaps[abi.encode(registerOrai, regiterRarible)].push(tokenOraiId);
        }


        IERC721(regiterRarible).transferFrom(address(this), to, tokenRaribleId);
    }

    function unlockNftOrai(bytes memory data, uint8 v, bytes32 r, bytes32 s) external {
        string memory registerOrai;
        address registerEth;
        uint256 tokenOraiId;
        string memory name;
        string memory description;
        string memory tokenURI;
        address to;
        uint256 nonceLock;

        (registerOrai, registerEth, tokenOraiId, name, description, tokenURI, to, nonceLock) = abi.decode(data, (string, address, uint256, string, string, string, address, uint256));

        address signer = verify(keccak256(abi.encode(UNLOCK_ORAI_TYPEHASH, registerOrai, tokenOraiId, name, description, tokenURI, to, nonceLock)), v, r, s);
        require(isSigner[signer], "invalid signer");
        require(isAllowUnlocking[nonceLock] == false, "Unlocked");
        isAllowUnlocking[nonceLock] = true;

        bytes memory key = abi.encode(registerOrai, registerEth, tokenOraiId);

        uint256 tokenEthId;

        if (oraiToEths[key] == 0) {
            tokenEthId = IAiright721(registerEth).mint(to, name, description, tokenURI);
            oraiToEths[key] = tokenEthId;

            ethToOrais[abi.encode(registerEth, registerOrai, tokenEthId)] = tokenOraiId;

            tokenMaps[abi.encode(registerOrai, registerEth)].push(tokenOraiId);
        } else {
            tokenEthId = oraiToEths[key];
            IERC721(registerEth).transferFrom(address(this), to, tokenEthId);
        }


    }

    function lockNft(string memory registerOrai, string memory userOrai, address registerEth, uint256 tokenEthId) external {
        IERC721(registerEth).transferFrom(msg.sender, address(this), tokenEthId);
        bytes memory key = abi.encode(registerEth, registerOrai, tokenEthId);

        require(ethToOrais[key] != 0, "Not support this NFT");
        lockingData[key] = LockingData(address(registerEth), tokenEthId, msg.sender, registerOrai, ethToOrais[key], userOrai, lockingCount);
        lockingCount += 1;
        emit LockNFT721(address(registerEth), tokenEthId, msg.sender, registerOrai, ethToOrais[key], userOrai, lockingCount);
    }

    function lengthTokenMap(bytes memory key) public view returns (uint256){
        return tokenMaps[key].length;
    }

    function inCaseStuckToken(address register, address to, uint256 id) public onlyOwner {
        IERC721(register).transferFrom(address(this), to, id);
    }

    function onBEP721Received(
        address operator,
        address,
        uint256,
        bytes memory data
    ) public virtual returns (bytes4) {
        return this.onBEP721Received.selector;
    }

    function onERC721Received(
        address operator,
        address,
        uint256,
        bytes memory data
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }


    function test(bytes memory data) public view returns (address, uint256, uint8, bytes32, bytes32, string memory){
        return abi.decode(data, (address, uint256, uint8, bytes32, bytes32, string));
    }
    function test2(bytes memory data) public view returns (string memory, address, uint256, string memory, string memory, string memory, address, uint256){
        return abi.decode(data, (string, address, uint256, string, string, string, address, uint256));
    }

}