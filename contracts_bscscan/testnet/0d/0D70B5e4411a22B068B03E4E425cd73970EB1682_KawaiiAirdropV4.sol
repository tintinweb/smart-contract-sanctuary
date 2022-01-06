/**
 *Submitted for verification at BscScan.com on 2022-01-06
*/

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
        return x >= 0 ? x : - x;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor () internal {
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
        (bool success,) = recipient.call{value : amount}("");
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
        (bool success, bytes memory returndata) = target.call{value : value}(
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

    constructor () internal {
        NAME = "KawaiiAirdropV4";
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

contract KawaiiAirdropV4 is Ownable, Pausable, SignData {
    using SafeMath for uint256;

    mapping(address => bool) public canClaimPack;

    IKawaiiRandomness public kawaiiRandomness;

    uint256 public fieldId;

    uint256[] public animalIds;

    uint256[] public treeIds;

    event Claim(address _user, uint256 treeId, uint256 animal, uint256 field);

    constructor(IKawaiiRandomness _kawaiiRandomness) public {
        kawaiiRandomness = _kawaiiRandomness;
    }

    function setTreeId(uint256[] memory _ids) public onlyOwner {
        treeIds = _ids;
    }


    function setAnimalId(uint256[] memory _ids) public onlyOwner {
        animalIds = _ids;
    }

    function setField(uint256 _id) public onlyOwner {
        fieldId = _id;
    }

    function claim(address _user, IERC1155 _kawaiiCore) public {
        require(canClaimPack[_user], "user can't claim");

        // tree
        uint256 indexTree = chooseIndex(treeIds.length, gasleft());
        _kawaiiCore.mint(_user, treeIds[indexTree], 1);

        // animal
        uint256 indexAnimal = chooseIndex(animalIds.length, gasleft());
        _kawaiiCore.mint(_user, animalIds[indexAnimal], 1);

        // field
        _kawaiiCore.mint(_user, fieldId, 1);

        canClaimPack[_user] = false;

        emit Claim(_user, treeIds[indexTree], animalIds[indexAnimal], fieldId);

    }

    function setCanClaim(address[] memory users, bool _is) public onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            canClaimPack[users[i]] = _is;
        }
    }


    function chooseIndex(uint256 range, uint256 randomNumber) private returns (uint256) {
        uint256 index = kawaiiRandomness.getRandomNumber(range, randomNumber);
        return index;

    }
}