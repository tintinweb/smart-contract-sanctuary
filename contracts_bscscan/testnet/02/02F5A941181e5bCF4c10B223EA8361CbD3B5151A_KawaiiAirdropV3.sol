pragma solidity 0.6.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function abs(int256 x) private pure returns (int256) {
        return x >= 0 ? x : -x;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function initOwner() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() external view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() external onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

    function unpause() external onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}

interface IERC1155 {
    function mint(
        address to,
        uint256 tokenId,
        uint256 value
    ) external;
}

interface IKawaiiRandomness {
    function getRandomNumber(uint256 _totalWeight, uint256 randomNumber)
        external
        returns (uint256);
}

contract SignData {
    bytes32 public DOMAIN_SEPARATOR;
    string public NAME;
    bytes32 public CLAIM_HASH;
    bytes32 public CLAIM_RANDOM_HASH;
    mapping(address => uint256) public nonces;

    function initData() internal {
        NAME = "KawaiiAirdropV3";
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(NAME)),
                keccak256(bytes("1")),
                chainId,
                this
            )
        );

        CLAIM_HASH = keccak256(
            "Data(uint256 packId,address sender,uint256 nonce)"
        );
        CLAIM_RANDOM_HASH = keccak256("Data(address sender,uint256 nonce)");
    }

    function verify(
        bytes32 data,
        address sender,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, data)
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == sender,
            "Invalid nonce"
        );
    }
}

contract KawaiiAirdropV3 is Ownable, Pausable, SignData {
    using SafeMath for uint256;

    mapping(address => bool) public canClaimRandomPack;
    // packID => user => bool
    mapping(uint256 => mapping(address => bool)) public canClaimPack;

    uint256 public randomPackLength;
    mapping(uint256 => uint256[]) private randomPackNfts;
    uint256 public packLength;
    mapping(uint256 => uint256[]) private packNfts;
    bool public initialized;
    IKawaiiRandomness kawaiiRandomness;

    event ClaimAirdrop(address indexed sender);

    function init(IKawaiiRandomness _kawaiiRandomness) public {
        require(initialized == false);
        initData();
        initOwner();
        kawaiiRandomness = _kawaiiRandomness;
        initialized = true;
    }

    function getRandomPackNftsByIndex(uint256 index)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory nfts = randomPackNfts[index];
        return nfts;
    }

    function getPackNftsByIndex(uint256 index)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory nfts = packNfts[index];
        return nfts;
    }

    function addRamdomPack(uint256[] calldata _randomNfts) external onlyOwner {
        require(_randomNfts.length > 0, "Empty input");
        randomPackNfts[randomPackLength] = _randomNfts;
        randomPackLength = randomPackLength.add(1);
    }

    function updateRandomPack(uint256[] calldata _randomNfts, uint256 index)
        external
        onlyOwner
    {
        require(index < randomPackLength);
        require(_randomNfts.length > 0, "Empty input");
        randomPackNfts[index] = _randomNfts;
    }

    function setCanClaimRandomPack(address[] calldata users)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < users.length; i++) {
            canClaimRandomPack[users[i]] = true;
        }
    }

    function setCanClaimPack(address[] calldata users, uint256 packId)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < users.length; i++) {
            canClaimPack[packId][users[i]] = true;
        }
    }

    function addPackNfts(uint256[] calldata nfts) external onlyOwner {
        require(nfts.length > 0, "Empty input");
        packNfts[packLength] = nfts;
        packLength = packLength.add(1);
    }

    function updatePackNfts(uint256[] calldata nfts, uint256 index)
        external
        onlyOwner
    {
        require(index < packLength);
        require(nfts.length > 0, "Empty input");
        packNfts[index] = nfts;
    }

    function claimPackPermit(
        address sender,
        IERC1155 nftRegister,
        uint256 packId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        verify(
            keccak256(abi.encode(CLAIM_HASH, packId, sender, nonces[sender]++)),
            sender,
            v,
            r,
            s
        );
        _claimPack(sender, nftRegister, packId);
    }

    function claimPack(IERC1155 nftRegister, uint256 packId) external {
        _claimPack(msg.sender, nftRegister, packId);
    }

    function _claimPack(
        address sender,
        IERC1155 nftRegister,
        uint256 packId
    ) internal whenNotPaused {
        require(canClaimPack[packId][sender], "Forbidden");
        for (uint256 i = 0; i < packNfts[packId].length; i++) {
            nftRegister.mint(sender, packNfts[packId][i], 1);
        }
        canClaimPack[packId][sender] = false;
        emit ClaimAirdrop(sender);
    }

    function claimRandomPackPermit(
        address sender,
        IERC1155 nftRegister,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        verify(
            keccak256(abi.encode(CLAIM_RANDOM_HASH, sender, nonces[sender]++)),
            sender,
            v,
            r,
            s
        );
        _claimRandomPack(sender, nftRegister);
    }

    function claimRandomPack(IERC1155 nftRegister) external {
        _claimRandomPack(msg.sender, nftRegister);
    }

    function _claimRandomPack(address sender, IERC1155 nftRegister)
        internal
        whenNotPaused
    {
        require(canClaimRandomPack[sender], "Forbidden");
        uint256 index = _chooseItemWithoutRule(randomPackLength, gasleft());

        for (uint256 i = 0; i < randomPackNfts[index].length; i++) {
            nftRegister.mint(sender, randomPackNfts[index][i], 1);
        }

        canClaimRandomPack[sender] = false;
        emit ClaimAirdrop(sender);
    }

    function _chooseItemWithoutRule(uint256 range, uint256 randomNumber)
        private
        returns (uint256)
    {
        uint256 index = kawaiiRandomness.getRandomNumber(range, randomNumber);
        return index;
    }
}