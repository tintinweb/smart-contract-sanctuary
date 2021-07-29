/**
 *Submitted for verification at BscScan.com on 2021-07-29
*/

// ___________      ___.   .__                                          
// \_   _____/ _____\_ |__ |  |   ____   _____                          
//  |    __)_ /     \| __ \|  | _/ __ \ /     \                         
//  |        \  Y Y  \ \_\ \  |_\  ___/|  Y Y  \                        
// /_______  /__|_|  /___  /____/\___  >__|_|  /                        
//         \/      \/    \/          \/      \/                         
//     ____   ____            .__   __                                  
//     \   \ /   /____   __ __|  |_/  |_                                
//      \   Y   /\__  \ |  |  \  |\   __\                               
//       \     /  / __ \|  |  /  |_|  |                                 
//       \___/  (____  /____/|____/__|                                 
//                   \/                                                
//   ___ ___                    .___.__                          _________
//  /   |   \_____    ____    __| _/|  |   ___________  ___  __ |  ____  /
// /    ~    \__  \  /    \  / __ | |  | _/ __ \_  __ \ \  \/   /    / /
// \    Y    // __ \|   |  \/ /_/ | |  |_\  ___/|  | \/  \    /    / /
//  \___|_  /(____  /___|  /\____ | |____/\___  >__|      \_/    /_/
//       \/      \/     \/      \/           \/                     

  
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
    function ownerOf(uint256 _tokenId) external returns (address _owner);
    function getApproved(uint256 _tokenId) external returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}

interface Ownable {
    function transferOwnership(address newOwner) external;
}

interface BasicERC20 {
    function burn(uint256 value) external;
    function mint(address account, uint256 amount) external;
    function decimals() external view returns (uint8);
}

contract Context {
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}


contract Bridged is Context {
    using SafeMath for uint256;
    using SafeMath for uint8;
    using SafeMath for uint;

    address public paymentAddress;
    
    mapping(uint => bool) public chainIds;
    mapping(uint => uint256) public chainBalances;
    
    constructor () public {
        chainIds[1] = true;
        chainBalances[1] = 200000000000000000;
        chainIds[137] = true;
        chainBalances[137] = 200000000000000000;
        chainIds[80001] = true;
        chainBalances[80001] = 200000000000000000;
        chainIds[100] = true;
        chainBalances[100] = 200000000000000000;
        chainIds[56] = true;
        chainBalances[56] = 200000000000000000;
        chainIds[250] = true;
        chainBalances[250] = 200000000000000000;
    }
    
    function transferToChain(uint chainId, uint256 amount) public returns (bool) {
        require(chainIds[chainId], 'Invalid Chain ID');
        IERC20Token paymentToken = IERC20Token(paymentAddress);
        require(paymentToken.allowance(_msgSender(), address(this)) >= amount, 'Handler unable to spend ');
        require(paymentToken.transferFrom(_msgSender(), address(this), amount), 'Transfer ERROR');
        BasicERC20(paymentAddress).burn(amount);
        chainBalances[chainId] = chainBalances[chainId].add(amount);
        emit BridgeDeposit(_msgSender(), amount, chainId);
        
        return true;
    }
    
    function _transferFromChain(address _to, uint chainId, uint256 amount) internal returns (bool) {
        require(chainBalances[chainId] >= amount, 'Can not transfer more than deposited');
        require(chainIds[chainId], 'Invalid Chain ID');
        BasicERC20 paymentToken = BasicERC20(paymentAddress);
        paymentToken.mint(_to, amount);
        chainBalances[chainId] = chainBalances[chainId].sub(amount);
        emit BridgeWithdrawal(_msgSender(), amount, chainId);
        
        return true;
    }
    
    event BridgeDeposit(address indexed sender, uint256 indexed amount, uint chainId);
    event BridgeWithdrawal(address indexed sender, uint256 indexed amount, uint chainId);
    
    function _addChainId(uint chainId) internal returns (bool) {
        chainIds[chainId] = true;
        return true;
    }
    
    function _removeChainId(uint chainId) internal returns (bool) {
        chainIds[chainId] = false;
        return true;
    }
    
}

contract VaultHandlerV7 is ReentrancyGuard, Bridged {
    
    using SafeMath for uint256;
    using SafeMath for uint8;
    address payable private owner;
    string public metadataBaseUri;
    bool public initialized;
    address public nftAddress;
    address public recipientAddress;
    // address public couponAddress;
    uint256 public price;
    // uint256 public offerPrice = 0;
    // bool public payToAcceptOffer = false;
    // bool public payToMakeOffer = false;
    bool public shouldBurn = false;
    
    struct PreMint {
        string payload;
        bytes32 preImage;
    }
    
    struct PreTransfer {
        string payload;
        bytes32 preImage;
        address _from;
    }
    
    struct Offer {
        uint tokenId;
        address _from;
    }

    
    // mapping(uint => PreMint) public tokenIdToPreMint;
    mapping(address => mapping(uint => PreMint)) preMints;
    mapping(address => mapping(uint => PreMint)) preMintsByIndex;
    mapping(address => uint) preMintCounts;
    
    mapping(uint => PreTransfer) preTransfers;
    mapping(uint => mapping(uint => PreTransfer)) preTransfersByIndex;
    mapping(uint => uint) preTransferCounts;
    
    mapping(uint => Offer[]) offers;
    mapping(uint => Offer[]) rejected;
    mapping(address => mapping(uint => Offer)) offered;
    
    mapping(address => bool) public witnesses;
    mapping(uint256 => bool) usedNonces;
    
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
        addWitness(owner);
        metadataBaseUri = "https://api.emblemvault.io/s:evmetadata/meta/";
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
        if (shouldBurn) {
            require(paymentToken.transferFrom(msg.sender, address(this), price), 'Transfer ERROR'); // Payment sent to recipient
            BasicERC20(paymentAddress).burn(price);
        } else {
            require(paymentToken.transferFrom(msg.sender, address(recipientAddress), price), 'Transfer ERROR'); // Payment sent to recipient
        }
        string memory _uri = concat(metadataBaseUri, uintToStr(_tokenId));
        nftToken.mint(_to, _tokenId, _uri, preMint.payload);
        delete preMintsByIndex[msg.sender][preMintCounts[msg.sender]];
        delete preMints[msg.sender][_tokenId];
        preMintCounts[msg.sender] = preMintCounts[msg.sender].sub(1);
    }
    
    function buyWithSignature(address _to, uint256 _tokenId, string calldata _payload, uint256 _nonce, bytes calldata _signature) public payable {
        IERC20Token paymentToken = IERC20Token(paymentAddress);
        IERC721 nftToken = IERC721(nftAddress);
        if (shouldBurn) {
            require(paymentToken.transferFrom(msg.sender, address(this), price), 'Transfer ERROR'); // Payment sent to recipient
            BasicERC20(paymentAddress).burn(price);
        } else {
            require(paymentToken.transferFrom(msg.sender, address(recipientAddress), price), 'Transfer ERROR'); // Payment sent to recipient
        }
        
        address signer = getAddressFromSignature(_tokenId, _nonce, _payload, _signature);
        require(witnesses[signer], 'Not Witnessed');
        usedNonces[_nonce] = true;
        string memory _uri = concat(metadataBaseUri, uintToStr(_tokenId));
        nftToken.mint(_to, _tokenId, _uri, _payload);
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
    
    function toggleShouldBurn() public {
        shouldBurn = !shouldBurn;
    }
    
    /* Transfer with code */
    function addWitness(address _witness) public isOwner {
        witnesses[_witness] = true;
    }

    function removeWitness(address _witness) public isOwner {
        witnesses[_witness] = false;
    }
    
    function getAddressFromSignature(uint256 _tokenId, uint256 _nonce, bytes memory signature) public view returns (address) {
        require(!usedNonces[_nonce]);
        bytes32 hash = keccak256(abi.encodePacked(concat(uintToStr(_tokenId), uintToStr(_nonce))));
        address addressFromSig = recoverSigner(hash, signature);
        return addressFromSig;
    }
    
    function getAddressFromSignature(uint256 _tokenId, uint256 _nonce, string calldata payload, bytes memory signature) public view returns (address) {
        require(!usedNonces[_nonce]);
        string memory combined = concat(uintToStr(_tokenId), payload);
        bytes32 hash = keccak256(abi.encodePacked(concat(combined, uintToStr(_nonce))));
        address addressFromSig = recoverSigner(hash, signature);
        return addressFromSig;
    }
    
    function getAddressFromSignature(bytes32 _hash, bytes calldata signature) public pure returns (address) {
        address addressFromSig = recoverSigner(_hash, signature);
        return addressFromSig;
    }
    
    function getHash(string calldata _payload) public pure returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(_payload));
        return hash;
    }
    
    function transferWithCode(uint256 _tokenId, string calldata code, address _to, uint256 _nonce,  bytes memory signature) public payable {
        require(witnesses[getAddressFromSignature(_tokenId, _nonce, signature)], 'Not Witnessed');
        IERC721 nftToken = IERC721(nftAddress);
        PreTransfer memory preTransfer = preTransfers[_tokenId];
        require(preTransfer.preImage == sha256(abi.encodePacked(code)), 'Code does not match'); // Payload should match
        nftToken.transferFrom(preTransfer._from, _to,  _tokenId);
        delete preTransfers[_tokenId];
        delete preTransfersByIndex[_tokenId][preTransferCounts[_tokenId]];
        preTransferCounts[_tokenId] = preTransferCounts[_tokenId].sub(1);
        usedNonces[_nonce] = true;
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
    
    function deletePreTransfer(uint256 _tokenId) public {
        require(preTransfers[_tokenId]._from == msg.sender, 'PreTransfer does not belong to sender');
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
    
    function changeMetadataBaseUri(string calldata _uri) public isOwner {
        metadataBaseUri = _uri;
    }
    
    function transferPaymentOwnership(address newOwner) external isOwner {
        Ownable paymentToken = Ownable(paymentAddress);
        paymentToken.transferOwnership(newOwner);
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
    
    // function changeCoupon(address coupon) public isOwner {
    //   couponAddress = coupon;
    // }
    
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
    
    // function changeOfferPrice(uint256 _price) public isOwner {
    //     uint decimals = BasicERC20(couponAddress).decimals();
    //     offerPrice = _price * 10 ** decimals;
    // }
    
    function addChainId(uint chainId) public isOwner returns (bool) {
        return (_addChainId(chainId));
    }
    
    function removeChainId(uint chainId) public isOwner returns (bool) {
        return (_removeChainId(chainId));
    }
    
    function transferFromChain(address _to, uint chainId, uint256 amount) public isOwner returns (bool) {
        return _transferFromChain(_to, chainId, amount);
    }
    
    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
    /**
    * @dev Recover signer address from a message by using their signature
    * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
    * @param sig bytes signature, the signature is generated using web3.eth.sign(). Inclusive "0x..."
    */
    function recoverSigner(bytes32 hash, bytes memory sig) internal pure returns (address) {
        require(sig.length == 65, "Require correct length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Signature version not match");

        return recoverSigner2(hash, v, r, s);
    }

    function recoverSigner2(bytes32 h, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, h));
        address addr = ecrecover(prefixedHash, v, r, s);

        return addr;
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
    
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
    }
    function bytes32ToStr(bytes32 _bytes32) internal pure returns (string memory) {

        // string memory str = string(_bytes32);
        // TypeError: Explicit type conversion not allowed from "bytes32" to "string storage pointer"
        // thus we should fist convert bytes32 to bytes (to dynamically-sized byte array)
    
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
            }
        return string(bytesArray);
    }
    function asciiToInteger(bytes32 x) public pure returns (uint256) {
        uint256 y;
        for (uint256 i = 0; i < 32; i++) {
            uint256 c = (uint256(x) >> (i * 8)) & 0xff;
            if (48 <= c && c <= 57)
                y += (c - 48) * 10 ** i;
            else
                break;
        }
        return y;
    }
    function toString(address account) public pure returns(string memory) {
        return toString(abi.encodePacked(account));
    }
    
    function toString(uint256 value) public pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }
    
    function toString(bytes32 value) public pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }
    
    function toString(bytes memory data) public pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";
    
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}