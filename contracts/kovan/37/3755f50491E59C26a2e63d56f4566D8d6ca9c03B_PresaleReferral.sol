/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-31
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

contract Context {
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma experimental ABIEncoderV2;

interface IStdReference {
    struct ReferenceData {
        uint256 rate;
        uint256 lastUpdatedBase;
        uint256 lastUpdatedQuote;
    }

    function getReferenceData(string memory _base, string memory _quote)
        external
        view
        returns (ReferenceData memory);

    function getReferenceDataBulk(string[] memory _bases, string[] memory _quotes)
        external
        view
        returns (ReferenceData[] memory);
}

interface TRUSTMOON {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

contract PresaleReferral is Ownable {
    using SafeMath for uint256;
    
    TRUSTMOON public token;
    
    address payable public mainWallet;
    
    uint public    referralFeePercent = 5;
    uint public    holdFeePercent = 2;
    
    uint256 public totalDepositedBNBBalance;
    uint256 public tokenPricePerBNB;
    bool public presaleStatus;

    string public baseUrl = "https://virgo.fund/r?ref=";
    
    struct userInfo {
      string userNickName;
      string inviterNickName;
      address walletAddress;
    }
    userInfo[] userInfoArrays;
    
    mapping(address => uint256) public deposits;

    constructor(TRUSTMOON _token) public {
        token = _token;
        
        mainWallet = 0xf430B4Fe0b47577018DF4DEA86f89aC7da55eca3;
        
        tokenPricePerBNB = 10000 * 1e9;

        presaleStatus = true;
    }

    receive() payable external {
        // buyPresale(this.owner());
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return token.balanceOf(account);
    }
    
    function saveUser(string calldata _userNickName, string calldata _inviterNickName) external returns (bool) {
        require(keccak256(abi.encodePacked(_userNickName)) != keccak256(abi.encodePacked("")), "USER NICKNAME CAN'T BE EMPTY");
        require(keccak256(abi.encodePacked(_userNickName)) != keccak256(abi.encodePacked(_inviterNickName)), "INVITER CAN'T BE YOURSELF");
        require(existUser(_userNickName) != true, "INVITER NICKNAME CAN'T BE EMPTY");
        require(existWallet(msg.sender) != true, "INVITER NICKNAME CAN'T BE EMPTY");

        userInfo memory user;
        user.userNickName = _userNickName;
        if (keccak256(abi.encodePacked(_inviterNickName)) != keccak256(abi.encodePacked(""))) {
            user.inviterNickName = _inviterNickName;
        } else {
            user.inviterNickName = "";
        }
        user.walletAddress = msg.sender;
        userInfoArrays.push(user);
        
        return true;
    }
    
    function existUser(string calldata _userNickName) public view returns (bool) {
        require(keccak256(abi.encodePacked(_userNickName)) != keccak256(abi.encodePacked("")), "USER NICKNAME CAN'T BE EMPTY");
        
        for (uint i = 0; i < userInfoArrays.length; i++) {
            if (keccak256(abi.encodePacked(userInfoArrays[i].userNickName)) == keccak256(abi.encodePacked(_userNickName))) {
                return true;
            }
        }
        return false;
    }
    
    function existWallet(address walletAddress) public view returns (bool) {
        //require(keccak256(abi.encodePacked(_userNickName)) != keccak256(abi.encodePacked("")), "USER NICKNAME CAN'T BE EMPTY");
        
        for (uint i = 0; i < userInfoArrays.length; i++) {
            if (walletAddress == userInfoArrays[i].walletAddress) {
                return true;
            }
        }
        return false;
    }
    
    function getWallet(string calldata _userNickName) public view returns (address ) {
        require(keccak256(abi.encodePacked(_userNickName)) != keccak256(abi.encodePacked("")), "USER NICKNAME CAN'T BE EMPTY");
        
        address wallet;
        
        for (uint i = 0; i < userInfoArrays.length; i++) {
            if (keccak256(abi.encodePacked(userInfoArrays[i].userNickName)) == keccak256(abi.encodePacked(_userNickName))) {
                wallet = userInfoArrays[i].walletAddress;
                return wallet;
            }
        }
        return wallet;
    }
    
    function getInviter(string calldata _userNickName) public view returns (string memory) {
        require(keccak256(abi.encodePacked(_userNickName)) != keccak256(abi.encodePacked("")), "USER NICKNAME CAN'T BE EMPTY");
        
        for (uint i = 0; i < userInfoArrays.length; i++) {
            if (keccak256(abi.encodePacked(userInfoArrays[i].userNickName)) == keccak256(abi.encodePacked(_userNickName))) {
                return userInfoArrays[i].inviterNickName;
            }
        }
        return "";
    }
    
    function getInviteeList(string calldata _userNickName) public view returns (string memory) {
        require(keccak256(abi.encodePacked(_userNickName)) != keccak256(abi.encodePacked("")), "USER NICKNAME CAN'T BE EMPTY");
        
        bytes memory b;
        for (uint i = 0; i < userInfoArrays.length; i++) {
            if (keccak256(abi.encodePacked(userInfoArrays[i].inviterNickName)) == keccak256(abi.encodePacked(_userNickName))) {
                b = abi.encodePacked(b, userInfoArrays[i].userNickName);
                b = abi.encodePacked(b, ",");
            }
        }
        string memory inviteeList = string(b);
        return inviteeList;
    }
    
    function buyPresale(string calldata _userNickName) public payable {
        require(presaleStatus == true, "Presale : Presale is finished");
        require(keccak256(abi.encodePacked(_userNickName)) != keccak256(abi.encodePacked("")), "USER NICKNAME CAN'T BE EMPTY");
        require(msg.value >= 1 * 1e17, "Presale : Unsuitable Amount");
        require(msg.value <= 2 * 1e18, "Presale : Unsuitable Amount");

        uint256 tokenAmount = msg.value.mul(tokenPricePerBNB).div(1e18);
        require(tokenAmount > 0, "Presale : Token aomunt for Buyer must be greate than 0");
        
        string memory inviter = getInviter(_userNickName);
        if (keccak256(abi.encodePacked(inviter)) != keccak256(abi.encodePacked(""))) {
            address inviteWallet;
            for (uint i = 0; i < userInfoArrays.length; i++) {
                if (keccak256(abi.encodePacked(userInfoArrays[i].userNickName)) == keccak256(abi.encodePacked(inviter))) {
                    inviteWallet = userInfoArrays[i].walletAddress;
                    break;
                }
            }
            uint256 tokenForInviter = tokenAmount.mul(referralFeePercent).div(100);
            token.transfer(inviteWallet, tokenForInviter);
            
            uint256 tokenForBuyer = tokenAmount - tokenForInviter;
            token.transfer(msg.sender, tokenForBuyer);
        } else {
            token.transfer(msg.sender, tokenAmount);
        }
        
        totalDepositedBNBBalance = totalDepositedBNBBalance.add(msg.value);
        deposits[msg.sender] = deposits[msg.sender].add(msg.value);
        emit Deposited(msg.sender, msg.value);
    }

    
    function releaseFunds() external onlyOwner {
        require(presaleStatus == false, "Presale : Presale is in progress");
        mainWallet.transfer(address(this).balance);
        totalDepositedBNBBalance = totalDepositedBNBBalance.sub(address(this).balance);
    }

    function recoverBEP20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IBEP20(tokenAddress).transfer(this.owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }
    
    function setReferralRewardFee(uint256 newReward) public onlyOwner returns (bool) {
        referralFeePercent = newReward;
        return true;
    }
    
    function setHoldRewardFee(uint256 newReward) public onlyOwner returns (bool) {
        holdFeePercent = newReward;
        return true;
    }

    function setWithdrawAddress(address payable _address) external onlyOwner {
        mainWallet = _address;
    }
    
    function setTokenPricePerBNB(uint256 _newTokenPrice) external onlyOwner {
        tokenPricePerBNB = _newTokenPrice;
    }

    function stopPresale() external onlyOwner {
        presaleStatus = false;
    }

    function resumePresale() external onlyOwner {
        presaleStatus = true;
    }
    
    function setTokenAddress(TRUSTMOON tokenAddr) external onlyOwner {
        token = tokenAddr;
    }
    
    function setBaseUrl(string calldata _baseUrl) external onlyOwner {
        baseUrl = _baseUrl;
    }

    event Deposited(address indexed user, uint256 amount);
    event Recovered(address token, uint256 amount);
}