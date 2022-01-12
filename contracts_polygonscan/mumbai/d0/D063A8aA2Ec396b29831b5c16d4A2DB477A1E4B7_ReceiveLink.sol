/**
 *Submitted for verification at polygonscan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

library SafeMath {

    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns(address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface ITRC21 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
}

interface ITRC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}
contract ReceiveLink is Ownable {
    using SafeMath for uint256;
    address[] public businessAddresses;
    struct sendTrc21 {
        address trc21;
        address maker;
        address taker;
        uint256 amount;
        uint256 start;
        uint256 end;
        uint256 status; // 1 available, 2 canceled, 3 taken
    }
    mapping(uint256 => sendTrc21) private sendTrc21s;
    struct tomo {
        uint256 amount;
        address maker;
        address taker;
        uint256 start;
        uint256 end;
        uint256 status;  // 1 available, 2 canceled, 3 taken
    }
    mapping(uint256 => tomo) private tomos;

    struct sendTrc721 {
        address trc721;
        uint256 tokenId;
        address maker;
        address taker;
        uint256 start;
        uint256 end;
        uint256 status;  // 1 available, 2 canceled, 3 taken
    }
    mapping(uint256 => sendTrc721) private sendTrc721s;
    modifier onlyManager() {
        require(msg.sender == owner() || isBusiness());
        _;
    }
    function isBusiness() public view returns (bool) {
        bool valid;
        for(uint256 i = 0; i < businessAddresses.length; i++) {
            if(businessAddresses[i] == msg.sender) valid = true;

        }
        return valid;
    }
    function setBusinessAdress(address[] memory _businessAddresses) public onlyOwner {
        businessAddresses = _businessAddresses;
    }
    event Tomo(uint256 _id);
    event SendTRC21(uint256 _id);
    event SendTRC721(uint256 _id);
    event RequestSendTRC21(uint256 _id, address taker);
    event RequestSendTRC721(uint256 _id, address taker, uint256 tokenId);
    event RequestTomo(uint256 _id, address taker);
    constructor () {}
    function sendTRC21s(uint256 _num, uint256[] memory _ids, address _trc21, uint256 _amount, uint256 _start, uint256 _end) public {
        ITRC21 trc21 = ITRC21(_trc21);
        require(trc21.transferFrom(msg.sender, address(this), _amount.mul(_num)));
        for(uint256 i = 0; i< _num; i++) {
            _sendTRC21(_ids[i], _trc21, _amount, _start, _end);
        }
    }
    function sendTRC21(uint256 _id, address _trc21, uint256 _amount, uint256 _start, uint256 _end) public {
        ITRC21 trc21 = ITRC21(_trc21);
        require(trc21.transferFrom(msg.sender, address(this), _amount));
        _sendTRC21(_id, _trc21, _amount, _start, _end);
    }
    function _sendTRC21(uint256 _id, address _trc21, uint256 _amount, uint256 _start, uint256 _end) internal {
        require(sendTrc21s[_id].maker == address(0), 'This id existed !');

        sendTrc21s[_id].trc21 = _trc21;
        sendTrc21s[_id].amount = _amount;
        sendTrc21s[_id].maker = msg.sender;
        sendTrc21s[_id].start = _start;
        sendTrc21s[_id].end = _end;
        sendTrc21s[_id].status = 1;
        emit SendTRC21(_id);
    }
    function getSendTRC21(uint256 _id) public view returns(address trc21,
        address maker,
        address taker,
        uint256 amount,
        uint256 start,
        uint256 end,
        uint256 status) {

        return (sendTrc21s[_id].trc21, sendTrc21s[_id].maker, sendTrc21s[_id].taker, sendTrc21s[_id].amount, sendTrc21s[_id].start, sendTrc21s[_id].end,
        sendTrc21s[_id].status);
    }
    function validateTime(uint256 _type, uint256 _id) public view returns(bool) {
        bool validate;
        if(_type == 1) {
            validate = block.timestamp >= sendTrc21s[_id].start && block.timestamp <= sendTrc21s[_id].end;

        }
        else if(_type == 2) {
            validate = block.timestamp >= tomos[_id].start && block.timestamp <= tomos[_id].end;

        }
        else {
            validate = block.timestamp >= sendTrc721s[_id].start && block.timestamp <= sendTrc721s[_id].end;

        }
        return validate;
    }

    function requestSendTRC21(uint256 _id) public {
        require(sendTrc21s[_id].status == 1, 'this package not existed !');
        uint256 status = 3;
        if(msg.sender != sendTrc21s[_id].maker) {
            require(validateTime(1, _id), 'This time not available !');
//            require(sendTrc21s[_id].taker == msg.sender);
        }
        else {
            require(block.timestamp > sendTrc21s[_id].end, 'This time not available !');
            status = 2;
        }

        ITRC21 trc21 = ITRC21(sendTrc21s[_id].trc21);
        trc21.transfer(msg.sender, sendTrc21s[_id].amount);
        sendTrc21s[_id].amount = 0;
        sendTrc21s[_id].status = status;
        sendTrc21s[_id].taker = msg.sender;
        emit RequestSendTRC21(_id, msg.sender);
    }
    function getSendTomo(uint256 _id) public view returns(
        address maker,
        address taker,
        uint256 amount,
        uint256 start,
        uint256 end,
        uint256 status) {

        return (tomos[_id].maker, tomos[_id].taker, tomos[_id].amount, tomos[_id].start, tomos[_id].end, tomos[_id].status);
    }
    function sendTomos(uint256 _num, uint256[] memory _ids, uint256 _amount, uint256 _start, uint256 _end) public payable{
        require(msg.value >= _amount.mul(_num));
        for(uint256 i = 0; i< _num; i++) {
            _sendTomo(_ids[i], _amount, _start, _end);
        }
    }
    function sendTomo(uint256 _id, uint256 _amount, uint256 _start, uint256 _end) public payable{
        require(msg.value == _amount);
        _sendTomo(_id, _amount, _start, _end);
    }
    function _sendTomo(uint256 _id, uint256 _amount, uint256 _start, uint256 _end) internal{
        require(tomos[_id].maker == address(0), 'This id existed !');
        tomos[_id].amount = _amount;
        tomos[_id].maker = msg.sender;
        tomos[_id].start = _start;
        tomos[_id].end = _end;
        tomos[_id].status = 1;
        emit Tomo(_id);
    }

    function requestSendTomo(uint256 _id) public {
        require(tomos[_id].status == 1, 'this package not existed !');
        uint256 status = 3;
        if(msg.sender != tomos[_id].maker) {
            require(validateTime(2, _id), 'This time not available !');
//            require(tomos[_id].taker == msg.sender);
        }
        else {
            require(block.timestamp > tomos[_id].end, 'This time not available !');
            status = 2;
        }
        payable(msg.sender).transfer(tomos[_id].amount);
        tomos[_id].amount = 0;
        tomos[_id].status = status;
        tomos[_id].taker = msg.sender;
        emit RequestTomo(_id, msg.sender);
    }
    function sendTRC721s(uint256[] memory _ids, address _trc721, uint256[] memory _tokenIds, uint256 _start, uint256 _end) public {
        ITRC721 trc721 = ITRC721(_trc721);
        for(uint256 i = 0; i< _ids.length; i++) {
            trc721.transferFrom(msg.sender, address(this), _tokenIds[i]);
            _sendTRC721(_ids[i], _trc721, _tokenIds[i], _start, _end);
        }
    }
    function sendTRC721(uint256 _id, address _trc721, uint256 _tokenId, uint256 _start, uint256 _end) public {
        ITRC721 trc721 = ITRC721(_trc721);
        trc721.transferFrom(msg.sender, address(this), _tokenId);
        _sendTRC721(_id, _trc721, _tokenId, _start, _end);
    }
    function _sendTRC721(uint256 _id, address _trc721, uint256 _tokenId, uint256 _start, uint256 _end) public {
        require(sendTrc721s[_id].maker == address(0), 'This id existed !');

        sendTrc721s[_id].trc721 = _trc721;
        sendTrc721s[_id].tokenId = _tokenId;
        sendTrc721s[_id].maker = msg.sender;
        sendTrc721s[_id].start = _start;
        sendTrc721s[_id].end = _end;
        sendTrc721s[_id].status = 1;
        emit SendTRC721(_id);
    }
    function getSendTRC721(uint256 _id) public view returns(address trc721,
        address maker,
        address taker,
        uint256 tokenId,
        uint256 start,
        uint256 end,
        uint256 status) {

        return (sendTrc721s[_id].trc721, sendTrc721s[_id].maker, sendTrc721s[_id].taker, sendTrc721s[_id].tokenId, sendTrc721s[_id].start, sendTrc721s[_id].end,
        sendTrc721s[_id].status);
    }
//    function setTakerTomo(uint256 _id, address _taker) public onlyManager {
//        tomos[_id].taker = _taker;
//    }
//    function setTakerTrc21(uint256 _id, address _taker) public onlyManager {
//        sendTrc21s[_id].taker = _taker;
//    }
//    function setTakerTrc721(uint256 _id, address _taker) public onlyManager {
//        sendTrc721s[_id].taker = _taker;
//    }
    function requestSendTRC721(uint256 _id) public {
        require(sendTrc721s[_id].status == 1, 'this package not existed !');
        uint256 status = 3;
        if(msg.sender != sendTrc721s[_id].maker) {
            require(validateTime(3, _id), 'This time not available !');
//            require(sendTrc721s[_id].taker == msg.sender);
        }
        else {
            require(block.timestamp > sendTrc721s[_id].end, 'This time not available !');
            status = 2;
        }
        ITRC721 trc721 = ITRC721(sendTrc721s[_id].trc721);
        uint256 tokenId = sendTrc721s[_id].tokenId;
        trc721.transferFrom(address(this), msg.sender, tokenId);
        sendTrc721s[_id].tokenId = 0;
        sendTrc721s[_id].status = status;
        sendTrc721s[_id].taker = msg.sender;
        emit RequestSendTRC721(_id, msg.sender, tokenId);
    }
    function resetLink(uint256 _id, uint256 _type) public onlyManager {
        // _type == 1 => Tomo
        // _type == 2 => sendTrc21s
        // _type == 3 => sendTrc721s
        if(_type == 1) {
            payable(tomos[_id].maker).transfer(tomos[_id].amount);
            tomos[_id].amount = 0;
            tomos[_id].status = 2;
        } else if(_type == 2) {
            ITRC21 trc21 = ITRC21(sendTrc21s[_id].trc21);
            trc21.transfer(sendTrc21s[_id].maker, sendTrc21s[_id].amount);
            sendTrc21s[_id].amount = 0;
            sendTrc21s[_id].status = 2;
        } else {
            ITRC721 trc721 = ITRC721(sendTrc721s[_id].trc721);
            uint256 tokenId = sendTrc721s[_id].tokenId;
            trc721.transferFrom(address(this), sendTrc721s[_id].maker, tokenId);
            sendTrc721s[_id].tokenId = 0;
            sendTrc721s[_id].status = 2;
        }
    }
}