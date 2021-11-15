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
    function mint(address to, uint256 tokenId, uint256 value) external;
}

interface IKawaiiRandomness {
    function getRandomNumber(uint256 _totalWeight, uint256 randomNumber) external returns (uint256);
}


library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
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

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IBEP20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

contract Signed {
    mapping(bytes32 => bool) permitDoubleSpending;

    function getSigner(bytes32 data, uint8 v, bytes32 r, bytes32 s) internal returns (address){
        require(permitDoubleSpending[data] == false, "Forbidden double spending");
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
    bytes32 public CRAFTING_HASH;
    mapping(address => uint256) public nonces;


    constructor() internal {
        NAME = "KawaiiCrafting";
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

        CRAFTING_HASH = keccak256("Data(bytes adminSignedData,uint256 nonce)");
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


contract KawaiiCrafting is Signed, Ownable, SignData {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    IBEP20 public kawaiiToken;
    IKawaiiRandomness public kawaiiRandomness;
    mapping(address => bool) public isSigner;
    constructor(IBEP20 _kawaiiToken, IKawaiiRandomness _kawaiiRandomness) public {
        kawaiiToken = _kawaiiToken;
        kawaiiRandomness = _kawaiiRandomness;
        isSigner[msg.sender] = true;
    }
    function setKawaiiToken(IBEP20 _kawaiiToken) public onlyOwner {
        kawaiiToken = _kawaiiToken;
    }

    function setKawaiiRandomness(IKawaiiRandomness _kawaiiRandomness) public onlyOwner {
        kawaiiRandomness = _kawaiiRandomness;
    }


    function setSigner(address user, bool _result) public onlyOwner {
        isSigner[user] = _result;
    }

    function craftingItem(address _nft1155Address, uint256[] memory _tokenIds, uint256[] memory _weights, uint256 _craftingPrice, uint256 timestamp, address sender, bytes memory adminSignedData, uint8 v, bytes32 r, bytes32 s) public {
        verify(keccak256(abi.encode(CRAFTING_HASH, keccak256(adminSignedData), nonces[sender]++)), sender, v, r, s);
        (v, r, s) = abi.decode(adminSignedData, (uint8, bytes32, bytes32));
        address signer = getSigner(
            keccak256(
                abi.encode(address(this), this.craftingItem.selector, _nft1155Address, _tokenIds, _weights, _craftingPrice, timestamp)
            ), v, r, s);
        require(isSigner[signer] == true, "Forbidden");
        require(_tokenIds.length == _weights.length, "Invalid input length");
        uint256 totalWeight;
        for (uint256 i = 0; i < _weights.length; i++) {
            totalWeight = totalWeight.add(_weights[i]);
        }
        uint256 rand = kawaiiRandomness.getRandomNumber(totalWeight, gasleft());
        uint256 indexId = selectItem(_weights, rand);
        kawaiiToken.safeTransferFrom(sender, address(this), _craftingPrice);
        IERC1155(_nft1155Address).mint(sender, _tokenIds[indexId], 1);
    }

    function selectItem(uint256[] memory _weights, uint256 rand) internal pure returns (uint256) {
        uint256 indexId;
        for (uint256 i = 0; i < _weights.length - 1; i++) {
            if (rand > _weights[i]) {
                indexId = i + 1;
                rand = rand.sub(_weights[i]);
            }
        }
        return indexId;
    }
}

