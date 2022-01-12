/**
 *Submitted for verification at polygonscan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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
    function owner() public view returns (address) {
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
    function isOwner() public view returns (bool) {
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

interface ITRC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract NFTScan is Ownable {
    using SafeMath for uint256;
    address[] public businessAddresses;

    struct sendTrc721 {
        address trc721;
        uint256 tokenId;
        address maker;
        address taker;
        uint256 start;
        uint256 end;
        uint256 status; // 1 available, 2 canceled, 3 taken
    }
    mapping(uint256 => sendTrc721) private sendTrc721s;
    modifier onlyManager() {
        require(msg.sender == owner() || isBusiness());
        _;
    }

    constructor() {
        businessAddresses.push(msg.sender);
    }

    function isBusiness() public view returns (bool) {
        bool valid;
        for (uint256 i = 0; i < businessAddresses.length; i++) {
            if (businessAddresses[i] == msg.sender) valid = true;
        }
        return valid;
    }

    function setBusinessAdress(address[] memory _businessAddresses) public onlyOwner {
        businessAddresses = _businessAddresses;
    }

    event SendTRC721(uint256 _id);
    event RequestSendTRC721(uint256 _id, address taker, uint256 tokenId);

    function validateTime(uint256 _id) public view returns (bool validate) {
        validate = block.timestamp >= sendTrc721s[_id].start && block.timestamp <= sendTrc721s[_id].end;
    }

    function sendTRC721s(
        uint256[] memory _ids,
        address _trc721,
        uint256[] memory _tokenIds,
        uint256 _start,
        uint256 _end
    ) public {
        ITRC721 trc721 = ITRC721(_trc721);
        for (uint256 i = 0; i < _ids.length; i++) {
            trc721.transferFrom(msg.sender, address(this), _tokenIds[i]);
            _sendTRC721(_ids[i], _trc721, _tokenIds[i], _start, _end);
        }
    }

    function sendTRC721(
        uint256 _id,
        address _trc721,
        uint256 _tokenId,
        uint256 _start,
        uint256 _end
    ) public {
        ITRC721 trc721 = ITRC721(_trc721);
        trc721.transferFrom(msg.sender, address(this), _tokenId);
        _sendTRC721(_id, _trc721, _tokenId, _start, _end);
    }

    function _sendTRC721(
        uint256 _id,
        address _trc721,
        uint256 _tokenId,
        uint256 _start,
        uint256 _end
    ) public {
        require(sendTrc721s[_id].maker == address(0), "This id existed !");

        sendTrc721s[_id].trc721 = _trc721;
        sendTrc721s[_id].tokenId = _tokenId;
        sendTrc721s[_id].maker = msg.sender;
        sendTrc721s[_id].start = _start;
        sendTrc721s[_id].end = _end;
        sendTrc721s[_id].status = 1;
        emit SendTRC721(_id);
    }

    function getSendTRC721(uint256 _id)
        public
        view
        returns (
            address trc721,
            address maker,
            address taker,
            uint256 tokenId,
            uint256 start,
            uint256 end,
            uint256 status
        )
    {
        return (
            sendTrc721s[_id].trc721,
            sendTrc721s[_id].maker,
            sendTrc721s[_id].taker,
            sendTrc721s[_id].tokenId,
            sendTrc721s[_id].start,
            sendTrc721s[_id].end,
            sendTrc721s[_id].status
        );
    }

    function requestSendTRC721(uint256 _id) public {
        require(sendTrc721s[_id].status == 1, "this package not existed !");
        uint256 status = 3;
        if (msg.sender != sendTrc721s[_id].maker)
            require(validateTime(_id), "This time not available !");
        else {
            require(block.timestamp > sendTrc721s[_id].end, "This time not available !");
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
}