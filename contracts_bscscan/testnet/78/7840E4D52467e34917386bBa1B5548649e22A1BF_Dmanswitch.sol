//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "./TransferHelper.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IDexV2Router02.sol";
import "./IDexV2Pair.sol";
import "./WETH.sol";
import "./SafeMath.sol";
import "./IDexV2Factory.sol";

contract Dmanswitch is Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    address payable private devaddr;
    address private immutable _BURN_ADDRESS =
        address(0x0000000000000000000000000000000000000000);
    address private immutable _WBNB_ADDRESS =
        address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address private immutable _TESTNET_WBNB_ADDRESS =
        address(0x094616F0BdFB0b526bD735Bf66Eca0Ad254ca81F);

    WETH private WETH_CONTRACT;

    uint64 private lastUpdate;

    // struct ActivatedSwitchInfo {
    //     //date the switch was created
    //     uint64 creationDate;
    //     //message included with tx
    //     bytes32 message;
    //     //receiver of the dmanswitch
    //     address payable receiver;
    //     //token amount (if any)
    //     uint256 tokenAmount;
    //     //token address
    //     address tokenAddress;
    //     //creation address
    //     address emitter;
    // }

    struct SwitchInfo {
        //date the switch was created
        uint64 creationDate;
        //message included with tx
        bytes32 message;
        //receiver of the dmanswitch
        address payable receiver;
        //token amount (if any)
        uint256 tokenAmount;
    }

    struct UserInfo {
        bool initialized;
        //last ping from user
        uint64 lastUpdate; //utimestamp
        //time before activation
        uint64 deltaBeforeActivation; //utimestamp
        //switch info
        uint32 switches;
    }

    //total users
    uint256 private totalUsers;
    //addresses of users
    EnumerableSet.AddressSet private userAddresses;
    //user info mapped to address
    mapping(address => UserInfo) private users;
    //user address mapped to switches
    mapping(address => SwitchInfo[]) private switches;
    //whitelisted addresses for testing purposes
    EnumerableSet.AddressSet private whitelist;
    

    uint256 public ETHfee;

    event SwitchActivated(address receiver, bytes32 message);

    constructor() {
        totalUsers = 0;

        devaddr = payable(_msgSender());
        //dev works hard, deserves not to pay fees when creating switches, prease andastand
        whitelist.add(devaddr);

        WETH_CONTRACT = WETH(0x094616F0BdFB0b526bD735Bf66Eca0Ad254ca81F); //TESTNET, change to MAINNET

        ETHfee = 0.1 ether;
    }

    function setOwner(address payable _newOwner) external onlyOwner {
        transferOwnership(_newOwner);
        devaddr = _newOwner;
    }

    function addDManSwitch(
        uint256 amount,
        uint32 activationTime,
        bytes32 usrMsg,
        address payable receiver
    ) public payable {
        address userAddress = _msgSender();
        require(
            msg.value >= ETHfee || whitelist.contains(userAddress),
            "Invalid fee."
        );

        uint64 _time = uint64(block.timestamp);
        lastUpdate = _time;

        //transfer funds to contract and keep track of change in balance
        uint256 _prevBalance = WETH_CONTRACT.balanceOf(address(this));
        WETH_CONTRACT.transferFrom(userAddress, address(this), amount);
        uint256 _newBalance = WETH_CONTRACT.balanceOf(address(this));

        //save delta as amount to add to switch
        uint256 newAmount = _newBalance.sub(_prevBalance);
        SwitchInfo memory _info = SwitchInfo(_time, usrMsg, receiver, newAmount);

        //increase number of total users and save reference to address in an iterable way
        if (!userAddresses.contains(userAddress)) {
            userAddresses.add(userAddress);
            totalUsers++;
        }

        //save switch info linked to address
        UserInfo storage user = users[userAddress];
        user.lastUpdate = _time;
        user.deltaBeforeActivation = user.deltaBeforeActivation != 0 ? user.deltaBeforeActivation : activationTime;
        
        switches[userAddress][user.switches] = _info;
        
        user.switches++;
    }

    function updateDeltaBeforeActivation(uint32 delta) external {
        require(userAddresses.contains(_msgSender()), "Must be a user of the service.");
        UserInfo storage u = users[_msgSender()];
        u.deltaBeforeActivation = delta;
    }

    //expensive and non-scalable
    function checkExpiredDManSwitches() public view returns (address[] memory) {
        uint256 userSize = userAddresses.length();
        address[] memory pastActivationDate;
        uint256 activations = 0;
        for (uint256 i = 0; i < userSize; i++) {
            address user = userAddresses.at(i);
            uint64 lastUserUpdate = users[user].lastUpdate;
            uint64 deltaBeforeActivation = users[user].deltaBeforeActivation;
            if (lastUserUpdate + deltaBeforeActivation < block.timestamp) {
                pastActivationDate[activations] = user;
                activations++;
            }
        }

        return pastActivationDate;
    }

    function isUserElegibleForActivation(address user) external view returns (bool) {
        require(users[user].initialized, "Address not in storage.");
        return users[user].lastUpdate + users[user].deltaBeforeActivation < block.timestamp;
    }

    function commitDManSwitch(address user) public payable nonReentrant {
        UserInfo memory userInfo = users[user];
        //make sure address is past switch time
        require(userInfo.initialized && userInfo.lastUpdate + userInfo.deltaBeforeActivation < block.timestamp, "Can't launch switch.");
        
        //activate all switches for given address
        for (uint i = 0; i < userInfo.switches; i++) {
            SwitchInfo memory info = switches[user][i];
            WETH_CONTRACT.transfer(info.receiver, info.tokenAmount);
            emit SwitchActivated(info.receiver, info.message);
            delete switches[user][i];
        }

        users[user].switches = 0;
    }

    function getDManSwitchData(
        address user,
        uint256 idx
    ) public view returns (uint64, address, uint256) {
        //TODO
        uint64 creationDate = switches[user][idx].creationDate;
        address payable receiver = switches[user][idx].receiver;
        uint256 tokenAmount = switches[user][idx].tokenAmount;
        return (creationDate, receiver, tokenAmount);
    }

    //send fees to dev wallet (ETH/BNB funds are stored as wrapped tokens, so those are not retrievable by the dev)
    function retrieveFees() external onlyOwner {
        payable(devaddr).transfer(address(this).balance);
    }

    /*
     * TODO
     *  - remove switch
     *  - interaction with token
     *  - keep track of past switches? and add functionality to access their data
     *  - !!!properly figure out delta and times so funds don't get locked
     *  - change eth fee
     *  - add/remove whitelists
     */
}