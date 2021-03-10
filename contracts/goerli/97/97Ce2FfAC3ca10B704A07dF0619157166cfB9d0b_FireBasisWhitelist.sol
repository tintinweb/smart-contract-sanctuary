pragma solidity ^0.6.0;

import "../Context.sol";
import "./Libraries.sol";

contract FireBasisWhitelist is Operator
{
    using SafeMath for uint256;

    uint256 public userIdSeq = 0;
    uint256 public userCount = 0;

    //address=>user
    mapping(address => uint256) public addressToIds;
    //userId=>user
    mapping(uint256 => address) public idToAddresses;

    //address=>bool
    mapping(address => bool) public addrAlreadyJoined;

    constructor() public {}

    function kickUser(address addr) external onlyOperator {
        addrAlreadyJoined[addr] = false;
        addressToIds[addr] = 0;
        userCount--;
    }

    function addUser(address addr) external onlyOperator {
        if (!addrAlreadyJoined[addr]) {
            userIdSeq++;

            //addr
            addressToIds[addr] = userIdSeq;
            addrAlreadyJoined[addr] = true;
            idToAddresses[userIdSeq] = addr;

            userCount++;
        }
    }

    /**
     *  enroll
     */
    function join() external onlyOperator {
        //addr must been not enrolled
        require(!userJoined(msg.sender), "address have been enrolled");

        //addr cannot be contract
        uint32 size;
        address senderAddress = msg.sender;
        assembly {
            size := extcodesize(senderAddress)
        }
        require(size == 0, "addr cannot be a contract");

        userIdSeq++;

        //addr
        addressToIds[msg.sender] = userIdSeq;
        addrAlreadyJoined[msg.sender] = true;
        idToAddresses[userIdSeq] = msg.sender;

        userCount++;
        // emit onUserRegistry(gameId,nowUser.userId,nowUser.addr,nowUser.userName,nowUser.directInviteUserId);
    }

    function queryUserAddr(uint256 _userId)
        external
        view
        returns (address userAddress)
    {
        userAddress = idToAddresses[_userId];
    }

    function queryUserId(address _addr) external view returns (uint256 userId) {
        userId = addressToIds[_addr];
    }

    //
    function userJoined(address user)
        public
        view
        returns (bool registerd)
    {
        registerd = addrAlreadyJoined[user];
    }

    function queryUsersCount() public view returns (uint256 totalCount) {
        totalCount = userCount;
    }

    function queryUsersIDMax() public view returns (uint256 maxId) {
        maxId = userIdSeq;
    }
}