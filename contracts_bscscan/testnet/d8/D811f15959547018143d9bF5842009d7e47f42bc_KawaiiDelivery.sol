pragma solidity ^0.6.0;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function abs(int x) private pure returns (int) {
        return x >= 0 ? x : - x;
    }
}


interface IERC1155 {
    function mint(address _account, uint256 _id, uint256 _amount, bytes memory _data) external;

    function burn(address _account, uint256 _id, uint256 _amount) external;
}

interface IERC20 {
    function mint(address account, uint amount) external;
}

contract Signed {
    mapping(bytes32 => bool) public permitDoubleSpending;

    function getSigner(bytes32 data, uint8 v, bytes32 r, bytes32 s) internal returns (address){
        require(permitDoubleSpending[data] == false, "Forbidden double spending in admin");
        permitDoubleSpending[data] = true;
        return ecrecover(getEthSignedMessageHash(data), v, r, s);
    }
    //    FUNCTION internal
    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract SignData {
    bytes32 public DOMAIN_SEPARATOR;
    string public NAME;
    bytes32 public DELIVERY_HASH;
    mapping(address => uint256) public nonces;


    constructor() internal {
        NAME = "KawaiiDelivery";
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

        DELIVERY_HASH = keccak256("Data(bytes adminSignedData,uint256 nonce)");
    }

    function verify(bytes32 data, address sender, uint8 v, bytes32 r, bytes32 s) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                data
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == sender, "Invalid nonce");
    }
}


contract KawaiiDelivery is Ownable, Signed, SignData {
    using SafeMath for uint256;
    IERC20 public kawaiiToken;
    mapping(address => bool) public isSigner;

    event Delivery(address indexed sender, uint256 reward);

    constructor(IERC20 _kawaiiToken) public {
        kawaiiToken = _kawaiiToken;
    }
    function setKawaiiToken(IERC20 _kawaiiToken) public onlyOwner {
        kawaiiToken = _kawaiiToken;
    }

    function setSigner(address user, bool _result) public onlyOwner {
        isSigner[user] = _result;
    }


    function delivery(address _nft1155Address, uint256[] memory _tokenIds, uint256[] memory _rateItems, uint256[] memory _amounts, uint256 timestamp, address sender, bytes memory adminSignedData, uint8 v, bytes32 r, bytes32 s) public {
        verify(keccak256(abi.encode(DELIVERY_HASH, keccak256(adminSignedData), nonces[sender])), sender, v, r, s);
        (v, r, s) = abi.decode(adminSignedData, (uint8, bytes32, bytes32));
        address signer = getSigner(
            keccak256(
                abi.encode(address(this), this.delivery.selector, _nft1155Address, _tokenIds, _rateItems, _amounts, timestamp, nonces[sender]++)
            ), v, r, s);
        require(isSigner[signer] == true, "Forbidden");
        require(_tokenIds.length == _amounts.length && _tokenIds.length == _rateItems.length, "KawaiiDelivery: must same length");
        uint256 length = _tokenIds.length;
        uint256 totalReward;
        for (uint256 i = 0; i < length; i++) {
            totalReward = totalReward.add(_amounts[i].mul(_rateItems[i]));
            IERC1155(_nft1155Address).burn(sender, _tokenIds[i], _amounts[i]);
        }
        IERC20(kawaiiToken).mint(sender, totalReward);
        emit Delivery(sender, totalReward);
    }
}

