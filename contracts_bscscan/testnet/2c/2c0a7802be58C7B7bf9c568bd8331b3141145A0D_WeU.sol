// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
import "MLMcreator.sol";
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/IERC20.sol
interface IBEP20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract WeU{
     address public owner;
     address public collector;
     uint public APY;
     address public tokenAddress;
     uint public currentPrice;
     uint public currentBNBPrice;
     uint [20] teamReward; 
     uint [3] familyReward; 
      /*....................constructor ...........................*/
     
    IBEP20 contractToken;
    MLMAutomator MLMA;
    constructor (address ownerAddress, address collectorAddress, uint _APY, address _tokenAddress, address _MLMA) { // Owner Address is Owner of the Contract and Collectors is the Hot Wallet Address to aggregate collected funds. 
         owner = ownerAddress;
         collector = collectorAddress;
         APY = _APY;
         tokenAddress = _tokenAddress;
         contractToken = IBEP20(_tokenAddress);
         MLMA = MLMAutomator(_MLMA);
    }
    
    /* struct Token{
         uint APY;
         address tokenAddress;
     } */
    
    struct Deposit {
        uint usdvalue;
        uint time;
    }
    
    mapping(uint => Deposit) public depositIDMap;
    mapping(string => uint[]) public userDepositID;
    mapping(string => uint) public totalUSDDeposit;
    mapping(string => uint) public usdWithdrawls;
     
    function changePrice(uint price) external {
        currentPrice = price;
    } 
    
    function changeBNBPrice(uint price) external {
        currentBNBPrice = price;
    } 
    
    function changeTeam(uint [20]memory  _teamReward) external {
        for(uint i=0; i<20; i++) {
            teamReward[i] = _teamReward[i];
        }
    }
    
    function changeFamily(uint [3] memory _teamReward) external {
        for(uint i=0; i<3 ; i++) {
            teamReward[i] = _teamReward[i];
        }
    }
     
    function getWealthEarnings(string memory  username) public view returns(uint earnings) {
        for (uint i = 0 ; i< userDepositID[username].length ; i++) {
            uint _dID = userDepositID[username][i];
            earnings += depositIDMap[_dID].usdvalue*(block.timestamp - depositIDMap[_dID].time)*APY/8640000;
        }
    }
    
    function getTeamEarnings(string memory username) public view returns(uint earnings) {
        uint length1 = MLMA.getUserDownlineCount(username);
        if(length1 ==0) {return 0;}
        uint length = MLMA.getPeerCount(username);
        if(length == 0) { return 0; }
        for(uint j = 0; j< (length > 20 ? 20 : length); j++) {
            for (uint i = 0 ; i< length ; i++) {
                address _dAdd = MLMA.getUserDownline(username)[i];
                earnings += getWealthEarnings(MLMA.userAddressMap(_dAdd))*teamReward[j]/100;
            }
        }
    }
    
    function getFamilyEarnings(string memory username) public view returns(uint earnings) {
        string memory father = MLMA.getSponsorName(username);
        string memory grandfather = MLMA.getSponsorName(father);
        string memory greatGF = MLMA.getSponsorName(grandfather);
        uint peerCount = MLMA.getPeerCount(father);
        earnings += getWealthEarnings(father)*familyReward[0]/(peerCount* 100);
        earnings += getWealthEarnings(grandfather)*familyReward[1]/(peerCount* 100);
        earnings += getWealthEarnings(greatGF)*familyReward[2]/(peerCount* 100);
    }
    
    function getTotalEarnings(string memory username) public view returns(uint){ 
        return getWealthEarnings(username) + getTeamEarnings(username) + getFamilyEarnings(username);
    }
    
    function getBalance(string memory username) public view returns(uint balance) {
        uint myEarnings = getTotalEarnings(username);
        balance = myEarnings > totalUSDDeposit[username]*4 ? totalUSDDeposit[username]*4 : myEarnings;
        balance = balance - usdWithdrawls[username];
    }
    
    function withdraw(uint amount) external {
        string memory username = MLMA.userAddressMap(msg.sender);
        require(MLMA.doesUserExist(username), "User Doesnt Exist");
        require(amount <= getBalance(username), "Insufficient Balance");
        _sendToUser(msg.sender, (8*amount/10));
        usdWithdrawls[username] += amount;
    }
    
    function _sendToUser(address userAddress, uint amount) internal {
        uint tokenAmount = (amount * currentPrice * 100);   // 100 = 10**8 / 10**6
        contractToken.transferFrom(collector,userAddress, tokenAmount); 
    }
    
    function deopsit() external payable {
        uint _usdvalue = (msg.value* currentBNBPrice)/10**24 ; //10**24 = 10**18 * 10**6 
        payable(collector).transfer(msg.value);
        string memory username = MLMA.getUserfromAddress(msg.sender);
        uint dID = block.timestamp + uint(keccak256(abi.encodePacked(username)));
        userDepositID[username].push(dID);
        Deposit memory depData = Deposit ({
            usdvalue : _usdvalue,
            time : block.timestamp
        });
        depositIDMap[dID] = depData;
        totalUSDDeposit[username] += _usdvalue;
    }

    function getStakingBalance(string memory username) public view returns(uint stake) {
	    return (2*usdWithdrawls[username]/10);
    }
    
    function getSuperDepEntry(string memory username, uint _usdvalue, uint depositTime) external {
        require(owner == msg.sender, "Owner Only Function for Migration");
        Deposit memory depData = Deposit ({
            usdvalue : _usdvalue,
            time : depositTime
        });
        uint dID = depositTime + uint(keccak256(abi.encodePacked(username)));
        depositIDMap[dID] = depData;
        totalUSDDeposit[username] += _usdvalue;
    }
    
}