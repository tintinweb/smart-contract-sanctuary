//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "./TransferHelper.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IDexV2Router02.sol";
import "./IDexV2Pair.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IDexV2Factory.sol";

contract Dmanswitch is Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    address payable private devaddr;
    address private immutable _BURN_ADDRESS =
        address(0x0000000000000000000000000000000000000000);
    address private immutable _WBNB =
        address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address private immutable _TESTNET_WBNB =
        address(0x094616F0BdFB0b526bD735Bf66Eca0Ad254ca81F);

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
        //token address
        address tokenAddress;
    }

    struct UserInfo {
        bool initialized;
        //last ping from user
        uint64 lastUpdate; //utimestamp
        //time before activation
        uint64 deltaBeforeActivation; //utimestamp
        //iterable array of addresses
        EnumerableSet.AddressSet tokenAddresses;
        //fuck
        mapping(address => uint16) numberOfSwitchesForToken;
        //switch info
        mapping(address => SwitchInfo[]) tokenSwitches;
    }

    //TODO: way to iterate through mapping
    mapping(address => UserInfo) private users;
    EnumerableSet.AddressSet private whitelist;
    uint256 private totalUsers;
    EnumerableSet.AddressSet private userAddresses;

    uint256 public ETHfee;
    uint256 public tokenFee;

    event switchActivated(address receiver, bytes32 message);

    constructor() {
        totalUsers = 0;
        devaddr = payable(_msgSender());
        ETHfee = 0.1 ether;
    }

    function setOwner(address payable _newOwner) external onlyOwner {
        transferOwnership(_newOwner);
        devaddr = _newOwner;
    }

    // function addFactory(address _factAdd) external onlyOwner {
    //     factories.push(IDexV2Factory(_factAdd));
    // }

    // bruh
    // function pairExists(address _token) internal view returns (IDexV2Factory, bool) {
    //     bool pairDoesExist = false;
    //     bool token0 = false;
    //     uint256 i = 0;
    //     for (; i < factories.length; i++) {
    //         address _pair = factories[i].getPair(_token, _WBNB);
    //         if (_pair != _BURN_ADDRESS) {
    //             pairDoesExist = true;
    //             token0 = true;
    //             break;
    //         }
    //         address _pair2 = factories[i].getPair(_WBNB, _token);
    //         if (_pair2 != _BURN_ADDRESS) {
    //             pairDoesExist = true;
    //             break;
    //         }
    //     }

    //     require(pairDoesExist, "Pair does not exist for token");
    //     return (factories[i], token0);
    // }

    function addDManSwitch(
        address tokenAddress,
        uint256 amount,
        uint32 activationTime,
        bytes32 usrMsg,
        address payable receiver
    ) public payable {
        require(
            msg.value >= ETHfee || whitelist.contains(_msgSender()),
            "Invalid fee."
        );
        uint64 _time = uint64(block.timestamp);
        //update lastUpdate
        //TODO: check if needed to commit switches
        lastUpdate = _time;
        IERC20 _token = IERC20(tokenAddress);

        //transfer funds to contract and keep track of change in balance
        uint256 _prevBalance = _token.balanceOf(address(this));
        _token.transferFrom(_msgSender(), address(this), amount);
        uint256 _newBalance = _token.balanceOf(address(this));

        //save delta as amount to add to switch
        uint256 newAmount = _newBalance.sub(_prevBalance);
        SwitchInfo memory _info = SwitchInfo({
            creationDate: _time,
            message: usrMsg,
            receiver: receiver,
            tokenAmount: newAmount,
            tokenAddress: tokenAddress
        });

        //increase number of total users and save reference to address in an iterable way
        if (!userAddresses.contains(_msgSender())) {
            userAddresses.add(_msgSender());
            totalUsers++;
        }

        //save switch info linked to address
        UserInfo storage user = users[_msgSender()];
        user.tokenAddresses.add(tokenAddress);
        user.lastUpdate = _time;
        user.deltaBeforeActivation = activationTime;
        user.numberOfSwitchesForToken[tokenAddress]++;

        //TODO: check if it works on new users (length of array)
        user.tokenSwitches[tokenAddress][
            user.tokenSwitches[tokenAddress].length
        ] = _info;
    }

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

    function commitDManSwitch(address user) public payable {
        //transfer allocated funds to receiver
        UserInfo storage userInfo = users[user];
        require(
            userInfo.lastUpdate + userInfo.deltaBeforeActivation <
                block.timestamp,
            "User pinged too recently."
        );
        //iterate through user tokens
        for (uint256 i = 0; i < userInfo.tokenAddresses.length(); i++) {
            address addy = userInfo.tokenAddresses.at(i);
            SwitchInfo[] storage si = userInfo.tokenSwitches[addy];
            //iterate through switches for a given token
            IERC20 _token = IERC20(addy);
            for (uint256 j; j < userInfo.numberOfSwitchesForToken[addy]; j++) {
                _token.transfer(si[j].receiver, si[j].tokenAmount);
                emit switchActivated(si[j].receiver, si[j].message);
                //TODO: save references to activated switches
            }
            userInfo.tokenAddresses.remove(userInfo.tokenAddresses.at(i));
        }
    }

    function getDManSwitchData(
        address user,
        address token,
        uint256 idx
    ) public view returns (uint64, address, uint256, address) {
        //TODO
        uint64 creationDate = users[user].tokenSwitches[token][idx].creationDate;
        address payable receiver = users[user].tokenSwitches[token][idx].receiver;
        uint256 tokenAmount = users[user].tokenSwitches[token][idx].tokenAmount;
        address tokenAddress = users[user].tokenSwitches[token][idx].tokenAddress;
        return (creationDate, receiver, tokenAmount, tokenAddress);
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
     */
}