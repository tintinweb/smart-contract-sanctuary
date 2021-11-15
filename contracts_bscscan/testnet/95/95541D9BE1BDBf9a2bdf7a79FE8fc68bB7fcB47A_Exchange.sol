// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;
import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC1155/IERC1155.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/GSN/Context.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

//Import custom interfaces
import "./interfaces/INFTStorage.sol";
import "./interfaces/ITransferProxy.sol";
import "./interfaces/IERC20TransferProxy.sol";
import "./interfaces/IRouter.sol";

//Import custom libraries
import "./libraries/StringLibrary.sol";
import "./libraries/BytesLibrary.sol";


contract Exchange is Ownable{
    using SafeMath for uint256;
    using StringLibrary for string;
    using BytesLibrary for bytes32;
    
    
    struct ExchangeData {
        bool is721;
        address token;
        uint256 tokenId;
        uint256 prevTotal;
        uint256 value;
        address currency;
        uint256 price;
        address payable owner;
        string salt;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct BidData {
        bool is721;
        address token;
        uint256 tokenId;
        address currency;
        uint256 price;
        address payable winner;
        string salt;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    //Fees
    mapping(address=>uint256) public fees;
    mapping(address=>IRouter) public routers; 

    //Beneficiaries
    address payable public bbWallet;
    address payable public companyWallet;

    //External contracts
    INFTStorage public nftStorage;
    ITransferProxy public transferProxy;
    IERC20TransferProxy public transferProxyERC20;

    //Rewards
    IERC20 public rewardToken = IERC20(address(0));
    uint256 public reward = 0;
    bool public rewardsOn = false;

    //Events
    event Exchanged(address seller, address buyer, address collection, uint256 id, uint256 value, address currency, uint256 price);
    event AuctionEnded(address owner, address winner, address tokenAddress, uint256 tokenId, address currency, uint256 price);
    event RewardPaid(address _to, uint256 _amount);
    event FeesPaid(address to, uint256 fee);

    receive() external payable{}

//////////////Verification Functions/////////////////////////////////////////////////////////////////////////////

    function _generateKey(address token, uint256 tokenId, uint256 value, address currency, uint256 price,string memory salt )internal pure returns(bytes32 key){
        key = keccak256(abi.encode(token,tokenId,value,currency,price,salt));
    }

    function generateKey(address token, uint256 tokenId, uint256 value, address currency, uint256 price,string memory salt )external pure returns(bytes32 key){
        key = _generateKey(token,tokenId,value,currency,price,salt);
    }

    function generateMessage(address token, uint256 tokenId, uint256 value, address currency, uint256 price,string memory salt) external pure returns(string memory _message){
        _message = _generateKey(token,tokenId,value,currency,price,salt).toString();
    }

    function verifyOrder(ExchangeData memory data)public pure returns(bool verified){
        bytes32 _message = _generateKey(data.token,data.tokenId,data.prevTotal,data.currency,data.price,data.salt);
        address confirmed = _message.toString().recover(data.v,data.r,data.s);
        return (confirmed==data.owner);
    }

    function verifyBid(BidData memory data)public pure returns(bool verified){
        bytes32 _message = _generateKey(data.token,data.tokenId,1,data.currency,data.price,data.salt);
        address confirmed = _message.toString().recover(data.v,data.r,data.s);
        return (confirmed==data.winner);
    }

/////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////Exchange Functions/////////////////////////////////////////////////////////////////////////////

    function exchange(ExchangeData memory data) 
    external payable
    {
        executeOrder(data);
        _transferCost(data);
        if(data.is721){
            _transfer721(data); 
        }
        else{
            _transfer1155(data);
        }
          _sendReward(_msgSender());
    }

    function _transfer721(ExchangeData memory data) internal{
        transferProxy.erc721safeTransferFrom(IERC721(data.token),data.owner,msg.sender,data.tokenId);
       emit Exchanged(data.owner,msg.sender,data.token,data.tokenId,1,data.currency, data.price);
    }

    function _transfer1155(ExchangeData memory data) internal{
        transferProxy.erc1155safeTransferFrom(IERC1155(data.token),data.owner,msg.sender,data.tokenId,data.value,"");
        emit Exchanged(data.owner,msg.sender,data.token,data.tokenId,data.value,data.currency, data.price.mul(data.value));
    }

    function _generateFees(ExchangeData memory data)internal  view returns(address payable creator,uint256[2] memory _fees){
        uint256 price = data.price.mul(data.value);
        uint256 buyerFee = requiredFee(data.currency);
        (address payable _creator,uint256 creatorFeePercentage) = nftStorage.getNFT(data.token,data.tokenId);
        uint256 creatorFee = (price.mul(creatorFeePercentage)).div(100);
        creator = _creator;
        _fees=[buyerFee,creatorFee];
    }

   function _transferCost(ExchangeData memory data) internal {
        uint256 price = data.price.mul(data.value);
        (address payable creator,uint256[2] memory _fees) = _generateFees(data);
        if(creator == address(0)){
            creator = companyWallet;
        }
        
        uint256 toSeller = price.sub(_fees[1]);
        uint256 toBenefeciary = _fees[0];
        uint256 toCreator = _fees[1];

        

        if(IERC20(data.currency)==IERC20(address(0))){
            require(msg.value>=price.add(_fees[0]),"Order is underpriced");
            if(data.owner==creator){
                data.owner.transfer(toSeller.add(toCreator));
            }
            else{
                data.owner.transfer(toSeller);
                creator.transfer(toCreator);
                emit FeesPaid(creator,toCreator);
            }
            
            companyWallet.transfer(toBenefeciary.div(2));
            bbWallet.transfer(toBenefeciary.div(2));
            msg.sender.transfer(msg.value.sub(price.add(_fees[0]))); 
            emit FeesPaid(companyWallet,toBenefeciary.div(2));
            
        }
        else{
            if(data.owner==creator){
                transferProxyERC20.erc20safeTransferFrom(IERC20(data.currency),msg.sender,data.owner,toSeller.add(toCreator));
            }
            else{
                transferProxyERC20.erc20safeTransferFrom(IERC20(data.currency),msg.sender,data.owner,toSeller);
                transferProxyERC20.erc20safeTransferFrom(IERC20(data.currency),msg.sender,creator,toCreator);
                emit FeesPaid(creator,toCreator);
            }
            transferProxyERC20.erc20safeTransferFrom(IERC20(data.currency),msg.sender,companyWallet,toBenefeciary.div(2));
            transferProxyERC20.erc20safeTransferFrom(IERC20(data.currency),msg.sender,bbWallet,toBenefeciary.div(2));

            emit FeesPaid(companyWallet,toBenefeciary.div(2));
            
        }
        
    } 

    function _sendReward(address _to) internal{
        if(rewardsOn){
            rewardToken.transfer(_to, reward);
        emit RewardPaid(_to,reward);
        }
    }
 

    function executeOrder(ExchangeData memory data) internal {
        require(verifyOrder(data),"Order is not verified!");
        nftStorage.setComplete(
            _generateKey(data.token, data.tokenId, data.prevTotal, data.currency, data.price,data.salt),
            data.prevTotal,
            data.value
        );
    }

////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function endAuction(BidData memory data) 
    external payable
    {
        executeAuction(data);
        _transferCostAu(data);
        if(data.is721){
            _transfer721Au(data); 
        }
        else{
            _transfer1155Au(data);
        }
          
    }

    function _transfer721Au(BidData memory data) internal{
        transferProxy.erc721safeTransferFrom(IERC721(data.token),msg.sender,data.winner,data.tokenId);
        emit AuctionEnded(msg.sender, data.winner, data.token, data.tokenId, data.currency, data.price);
    }

    function _transfer1155Au(BidData memory data) internal{
        transferProxy.erc1155safeTransferFrom(IERC1155(data.token),msg.sender,data.winner,data.tokenId,1,"");
        emit AuctionEnded(msg.sender, data.winner, data.token, data.tokenId, data.currency, data.price);
    }

    function _generateFeesAu(BidData memory data)internal  view returns(address payable creator,uint256 fee){
        uint256 price = data.price;
        (address payable _creator,uint256 creatorFeePercentage) = nftStorage.getNFT(data.token,data.tokenId);
        uint256 creatorFee = (price.mul(creatorFeePercentage)).div(100);
        creator = _creator;
        fee=creatorFee;
    }

    function _transferCostAu(BidData memory data) internal {
        uint256 price = data.price;
        (address payable creator,uint256 fee) = _generateFeesAu(data);

        if(creator == address(0)){
            creator = companyWallet;
        }
        
        uint256 toSeller = price.sub(fee);
        uint256 toCreator = fee;

        if(creator == msg.sender){
            transferProxyERC20.erc20safeTransferFrom(IERC20(data.currency),data.winner,msg.sender,toSeller.add(toCreator));
        }
        else{
            transferProxyERC20.erc20safeTransferFrom(IERC20(data.currency),data.winner,msg.sender,toSeller);
            transferProxyERC20.erc20safeTransferFrom(IERC20(data.currency),data.winner,creator,toCreator);
            emit FeesPaid(creator,toCreator);
        }
        
    } 

    function executeAuction(BidData memory data) internal {
        require(verifyBid(data),"Order is not verified!");
        nftStorage.setComplete(
            _generateKey(data.token, data.tokenId, 1, data.currency, data.price,data.salt),
            1,
            1
        );
    }



//////////////Auction Functions/////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function changeFees(address _currency, uint256 _fee, IRouter _router)external onlyOwner{
        fees[_currency]=_fee;
        routers[_currency]=_router;
    }

    function setBeneficiaries(address payable _bb,address payable _com)external onlyOwner{
        bbWallet=_bb;
        companyWallet=_com;
    }

    function setExtContracts(INFTStorage _nftStorage,ITransferProxy _transferProxy,IERC20TransferProxy _transferProxyERC20)external onlyOwner{
        nftStorage = _nftStorage;
        transferProxy=_transferProxy;
        transferProxyERC20=_transferProxyERC20;
    }

    function setRewards(IERC20 _rewardToken, uint256 _reward)external onlyOwner{
        rewardToken = _rewardToken;
        reward = _reward;
    }

    function switchRewards(bool _switch) external onlyOwner{
        rewardsOn = _switch;
    }

    /////////////////////Router Actions/////////////////////////////
    function requiredFee(address _currency)public view returns(uint256 fee){
        address[] memory bep20Path;
        address[] memory bnbPath;
        bep20Path = new address[](3);
        bnbPath = new address[](2);
        bep20Path[0]=0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        bep20Path[1]=0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        bep20Path[2]=_currency;
        bnbPath[0]=0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        bnbPath[1]=0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        if(_currency==address(0)){
            fee=routers[_currency].getAmountsOut(fees[_currency],bnbPath)[1];
        }else{
            fee=routers[_currency].getAmountsOut(fees[_currency],bep20Path)[2];
        }
    }
    ////////////////////////////////////////////////////////////////
    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

interface IERC20TransferProxy{
    function erc20safeTransferFrom(IERC20 token, address from, address to, uint256 value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface INFTStorage{
    event NFTAdded(address moderator, address _collection, uint256 _id, address payable _creator, uint256 _fee);
    event OrderExecuted(bytes32 orderId, uint256 total, uint256 sold);
    event ModeratorAdded(address _moderator);
    event ModeratorRemoved(address _moderator);


    function addModerator(address _moderator) external;
    function removeModerator(address _moderator) external;

    function addNFT(address _collection, uint256 _id, address payable _creator, uint256 _fee) external;

    function setComplete(bytes32 orderId, uint256 total, uint256 value) external;

    function getNFT(address _collection, uint256 _id) external view returns(address payable creator, uint256 feePrecentage);

    function getOrder(bytes32 _orderId) external view returns(uint256 total, uint256 sold);

    function isModerator(address _moderator) external view returns(bool _isModerator);
    

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC1155/IERC1155.sol";
interface ITransferProxy {
    function erc721safeTransferFrom(
        IERC721 token,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function erc1155safeTransferFrom(
        IERC1155 token,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
library BytesLibrary {
    function toString(bytes32 value) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            str[i*2] = alphabet[uint8(value[i] >> 4)];
            str[1+i*2] = alphabet[uint8(value[i] & 0x0f)];
        }
        return string(str);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
import "./UintLibrary.sol";

library StringLibrary {
    using UintLibrary for uint256;

    function append(string memory a, string memory b) internal pure returns (string memory) {
        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);
        bytes memory bab = new bytes(ba.length + bb.length);
        uint k = 0;
        for (uint i = 0; i < ba.length; i++) bab[k++] = ba[i];
        for (uint i = 0; i < bb.length; i++) bab[k++] = bb[i];
        return string(bab);
    }

    function append(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);
        bytes memory bc = bytes(c);
        bytes memory bbb = new bytes(ba.length + bb.length + bc.length);
        uint k = 0;
        for (uint i = 0; i < ba.length; i++) bbb[k++] = ba[i];
        for (uint i = 0; i < bb.length; i++) bbb[k++] = bb[i];
        for (uint i = 0; i < bc.length; i++) bbb[k++] = bc[i];
        return string(bbb);
    }

    function recover(string memory message, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes memory msgBytes = bytes(message);
        bytes memory fullMessage = concat(
            bytes("\x19Ethereum Signed Message:\n"),
            bytes(msgBytes.length.toString()),
            msgBytes,
            new bytes(0), new bytes(0), new bytes(0), new bytes(0)
        );
        return ecrecover(keccak256(fullMessage), v, r, s);
    }

    function concat(bytes memory ba, bytes memory bb, bytes memory bc, bytes memory bd, bytes memory be, bytes memory bf, bytes memory bg) internal pure returns (bytes memory) {
        bytes memory resultBytes = new bytes(ba.length + bb.length + bc.length + bd.length + be.length + bf.length + bg.length);
        uint k = 0;
        for (uint i = 0; i < ba.length; i++) resultBytes[k++] = ba[i];
        for (uint i = 0; i < bb.length; i++) resultBytes[k++] = bb[i];
        for (uint i = 0; i < bc.length; i++) resultBytes[k++] = bc[i];
        for (uint i = 0; i < bd.length; i++) resultBytes[k++] = bd[i];
        for (uint i = 0; i < be.length; i++) resultBytes[k++] = be[i];
        for (uint i = 0; i < bf.length; i++) resultBytes[k++] = bf[i];
        for (uint i = 0; i < bg.length; i++) resultBytes[k++] = bg[i];
        return resultBytes;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

library UintLibrary {
    using SafeMath for uint;

    function toString(uint256 i) internal pure returns (string memory) {
        if (i == 0) {
            return "0";
        }
        uint j = i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0) {
            bstr[k--] = byte(uint8(48 + i % 10));
            i /= 10;
        }
        return string(bstr);
    }

    function bp(uint value, uint bpValue) internal pure returns (uint) {
        return value.mul(bpValue).div(10000);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

