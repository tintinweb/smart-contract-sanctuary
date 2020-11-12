// ___________      ___.   .__                                              
// \_   _____/ _____\_ |__ |  |   ____   _____                              
//  |    __)_ /     \| __ \|  | _/ __ \ /     \                             
//  |        \  Y Y  \ \_\ \  |_\  ___/|  Y Y  \                            
// /_______  /__|_|  /___  /____/\___  >__|_|  /                            
//         \/      \/    \/          \/      \/                             
// ____   ____            .__   __                                          
// \   \ /   /____   __ __|  |_/  |_                                        
//  \   Y   /\__  \ |  |  \  |\   __\                                       
//   \     /  / __ \|  |  /  |_|  |                                         
//   \___/  (____  /____/|____/__|                                         
//               \/                                                        
//   ___ ___                    .___.__                         _____  
//  /   |   \_____    ____    __| _/|  |   ___________  ___  __/  |  | 
// /    ~    \__  \  /    \  / __ | |  | _/ __ \_  __ \ \  \/ /   |  |_
// \    Y    // __ \|   |  \/ /_/ | |  |_\  ___/|  | \/  \   /    ^   /
//  \___|_  /(____  /___|  /\____ | |____/\___  >__|      \_/\____   | 
//       \/      \/     \/      \/           \/                  |__| 

// File: browser/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
// File: browser/IERC20Token.sol

pragma solidity ^0.6.11;
interface IERC20Token {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: browser/SafeMath.sol

pragma solidity ^0.6.11;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
// File: browser/VaultHandler_v4.sol

pragma experimental ABIEncoderV2;
pragma solidity ^0.6.11;


interface IERC721 {
    function burn(uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function mint( address _to, uint256 _tokenId, string calldata _uri, string calldata _payload) external;
    function changeName(string calldata name, string calldata symbol) external;
    function updateTokenUri(uint256 _tokenId,string memory _uri) external;
    function tokenPayload(uint256 _tokenId) external view returns (string memory);
}

interface Ownable {
    function transferOwnership(address newOwner) external;
}

interface BasicERC20 {
    function decimals() external view returns (uint8);
}

contract VaultHandlerV4 is ReentrancyGuard {
    
    using SafeMath for uint256;
    using SafeMath for uint8;
    address payable private owner;
    string public metadataBaseUri;
    bool public initialized;
    address public nftAddress;
    address public paymentAddress;
    address public recipientAddress;
    address public couponAddress;
    uint256 public price;
    
    struct PreMint {
        string payload;
        bytes32 preImage;
    }
    
    struct PreTransfer {
        string payload;
        bytes32 preImage;
        address _from;
    }

    
    // mapping(uint => PreMint) public tokenIdToPreMint;
    mapping(address => mapping(uint => PreMint)) preMints;
    mapping(address => mapping(uint => PreMint)) preMintsByIndex;
    mapping(address => uint) preMintCounts;
    
    mapping(uint => PreTransfer) preTransfers;
    mapping(uint => mapping(uint => PreTransfer)) preTransfersByIndex;
    mapping(uint => uint) preTransferCounts;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function transferOwnership(address payable newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }
    
    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
    
    constructor(address _nftAddress, address _paymentAddress, address _recipientAddress, uint256 _price) public {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
        metadataBaseUri = "http://104.154.252.216/meta/";
        nftAddress = _nftAddress;
        paymentAddress = _paymentAddress;
        recipientAddress = _recipientAddress;
        initialized = true;
        uint decimals = BasicERC20(paymentAddress).decimals();
        price = _price * 10 ** decimals;
    }
    
    function claim(uint256 tokenId) public isOwner {
        IERC721 token = IERC721(nftAddress);
        token.burn(tokenId);
    }
    
    function buyWithPaymentOnly(address _to, uint256 _tokenId, string calldata image) public payable {
        IERC20Token paymentToken = IERC20Token(paymentAddress);
        IERC721 nftToken = IERC721(nftAddress);
        PreMint memory preMint = preMints[msg.sender][_tokenId];
        require(preMint.preImage == sha256(abi.encodePacked(image)), 'Payload does not match'); // Payload should match
        require(paymentToken.transferFrom(msg.sender, address(recipientAddress), price), 'Transfer ERROR'); // Payment sent to recipient
        string memory _uri = concat(metadataBaseUri, uintToStr(_tokenId));
        nftToken.mint(_to, _tokenId, _uri, preMint.payload);
        delete preMintsByIndex[msg.sender][preMintCounts[msg.sender]];
        delete preMints[msg.sender][_tokenId];
        preMintCounts[msg.sender] = preMintCounts[msg.sender].sub(1);
    }
    
    function addPreMint(address _for, string calldata _payload, uint256 _tokenId, bytes32 preImage) public isOwner {
        try IERC721(nftAddress).tokenPayload(_tokenId) returns (string memory) {
            revert('NFT Exists with this ID');
        } catch {
            require(!_duplicatePremint(_for, _tokenId), 'Duplicate PreMint');
            preMintCounts[_for] = preMintCounts[_for].add(1);
            preMints[_for][_tokenId] = PreMint(_payload, preImage);
            preMintsByIndex[_for][preMintCounts[_for]] = preMints[_for][_tokenId];
        }
    }
    
    function _duplicatePremint(address _for, uint256 _tokenId) internal view returns (bool) {
        string memory data = preMints[_for][_tokenId].payload;
        bytes32 NULL = keccak256(bytes(''));
        return keccak256(bytes(data)) != NULL;
    }
    
    function deletePreMint(address _for, uint256 _tokenId) public isOwner {
        delete preMintsByIndex[_for][preMintCounts[_for]];
        preMintCounts[_for] = preMintCounts[_for].sub(1);
        delete preMints[_for][_tokenId];
    }
    
    function getPreMint(address _for, uint256 _tokenId) public view returns (PreMint memory) {
        return preMints[_for][_tokenId];
    }
    
    function checkPreMintImage(string memory image, bytes32 preImage) public pure returns (bytes32, bytes32, bool) {
        bytes32 calculated = sha256(abi.encodePacked(image));
        bytes32 preBytes = preImage;
        return (calculated, preBytes, calculated == preBytes);
    }
    
    function getPreMintCount(address _for) public view returns (uint length) {
        return preMintCounts[_for];
    }
    
    function getPreMintByIndex(address _for, uint index) public view returns (PreMint memory) {
        return preMintsByIndex[_for][index];
    }
    
    function transferWithCode(uint256 _tokenId, string calldata code) public payable {
        IERC721 nftToken = IERC721(nftAddress);
        PreTransfer memory preTransfer = preTransfers[_tokenId];
        require(preTransfer.preImage == sha256(abi.encodePacked(code)), 'Code does not match'); // Payload should match
        nftToken.transferFrom(preTransfer._from, msg.sender,  _tokenId);
        delete preTransfers[_tokenId];
        delete preTransfersByIndex[_tokenId][preTransferCounts[_tokenId]];
        preTransferCounts[_tokenId] = preTransferCounts[_tokenId].sub(1);
    }
    
    function addPreTransfer(uint256 _tokenId, bytes32 preImage) public {
        require(!_duplicatePretransfer(_tokenId), 'Duplicate PreTransfer');
        preTransferCounts[_tokenId] = preTransferCounts[_tokenId].add(1);
        preTransfers[_tokenId] = PreTransfer("payload", preImage, msg.sender);
        preTransfersByIndex[_tokenId][preTransferCounts[_tokenId]] = preTransfers[_tokenId];
    }
    
    function _duplicatePretransfer(uint256 _tokenId) internal view returns (bool) {
        string memory data = preTransfers[_tokenId].payload;
        bytes32 NULL = keccak256(bytes(''));
        return keccak256(bytes(data)) != NULL;
    }
    
    /*  */
    function deletePreTransfer(uint256 _tokenId) public isOwner {
        delete preTransfersByIndex[_tokenId][preTransferCounts[_tokenId]];
        preTransferCounts[_tokenId] = preTransferCounts[_tokenId].sub(1);
        delete preTransfers[_tokenId];
    }
    
    function getPreTransfer(uint256 _tokenId) public view returns (PreTransfer memory) {
        return preTransfers[_tokenId];
    }
    
    function checkPreTransferImage(string memory image, bytes32 preImage) public pure returns (bytes32, bytes32, bool) {
        bytes32 calculated = sha256(abi.encodePacked(image));
        bytes32 preBytes = preImage;
        return (calculated, preBytes, calculated == preBytes);
    }
    
    function getPreTransferCount(uint256 _tokenId) public view returns (uint length) {
        return preTransferCounts[_tokenId];
    }
    
    function getPreTransferByIndex(uint256 _tokenId, uint index) public view returns (PreTransfer memory) {
        return preTransfersByIndex[_tokenId][index];
    }
    /*  */
    
    function changeMetadataBaseUri(string calldata _uri) public isOwner {
        metadataBaseUri = _uri;
    }
    
    function transferNftOwnership(address newOwner) external isOwner {
        Ownable nftToken = Ownable(nftAddress);
        nftToken.transferOwnership(newOwner);
    }
    
    function mint( address _to, uint256 _tokenId, string calldata _uri, string calldata _payload) external isOwner {
        IERC721 nftToken = IERC721(nftAddress);
        nftToken.mint(_to, _tokenId, _uri, _payload);
    }
    
    function changeName(string calldata name, string calldata symbol) external isOwner {
        IERC721 nftToken = IERC721(nftAddress);
        nftToken.changeName(name, symbol);
    }
    
    function updateTokenUri(uint256 _tokenId,string memory _uri) external isOwner {
        IERC721 nftToken = IERC721(nftAddress);
        nftToken.updateTokenUri(_tokenId, _uri);
    }
    
    function getPaymentDecimals() public view returns (uint8){
        BasicERC20 token = BasicERC20(paymentAddress);
        return token.decimals();
    }
    
    function changePayment(address payment) public isOwner {
       paymentAddress = payment;
    }
    
    function changeCoupon(address coupon) public isOwner {
       couponAddress = coupon;
    }
    
    function changeRecipient(address _recipient) public isOwner {
       recipientAddress = _recipient;
    }
    
    function changeNft(address token) public isOwner {
        nftAddress = token;
    }
    
    function changePrice(uint256 _price) public isOwner {
        uint decimals = BasicERC20(paymentAddress).decimals();
        price = _price * 10 ** decimals;
    }
    
    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
    
    /// @notice converts number to string
    /// @dev source: https://github.com/provable-things/ethereum-api/blob/master/oraclizeAPI_0.5.sol#L1045
    /// @param _i integer to convert
    /// @return _uintAsString
    function uintToStr(uint _i) internal pure returns (string memory _uintAsString) {
        uint number = _i;
        if (number == 0) {
            return "0";
        }
        uint j = number;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (number != 0) {
            bstr[k--] = byte(uint8(48 + number % 10));
            number /= 10;
        }
        return string(bstr);
    }
    
    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
    }
    function bytes32ToStr(bytes32 _bytes32) public pure returns (string memory) {

        // string memory str = string(_bytes32);
        // TypeError: Explicit type conversion not allowed from "bytes32" to "string storage pointer"
        // thus we should fist convert bytes32 to bytes (to dynamically-sized byte array)
    
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
            }
        return string(bytesArray);
    }
}