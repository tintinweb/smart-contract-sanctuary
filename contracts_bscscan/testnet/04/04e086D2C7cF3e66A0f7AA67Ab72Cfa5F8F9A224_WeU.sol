// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
import "./MLMcreatorV1.sol";
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
     //uint public teamReward; 
     address public PriceUpdaterAddress;
      /*....................constructor ...........................*/
     
    IBEP20 contractToken;
    MLMcreatorV1 MLMA;
    function initializeAddress (address ownerAddress, address collectorAddress, uint _APY, address _tokenAddress, address _MLMA, address _updaterAddress) external { // Owner Address is Owner of the Contract and Collectors is the Hot Wallet Address to aggregate collected funds. 
         owner = ownerAddress;
         collector = collectorAddress;
         APY = _APY;
         tokenAddress = _tokenAddress;
         contractToken = IBEP20(_tokenAddress);
         MLMA = MLMcreatorV1(_MLMA);
         PriceUpdaterAddress = _updaterAddress;
    }
    
    /* struct Token{
         uint APY;
         address tokenAddress;
     } */
    
    struct Deposit {
        uint usdvalue;
        uint time;
    }
    
    struct Withdraw{
        uint usdvalue;
        uint time;
    }
    
    mapping(uint => Deposit) public depositIDMap;
    mapping(string => uint[]) public userDepositID;
    mapping(string => uint) public totalUSDDeposit;
    mapping(string => uint) public usdWithdrawls;
    mapping(uint => Withdraw) public withdrawIDMap;
    mapping(string => uint[]) public userWithdrawID;
     
    function changePrice(uint price) external {
        require(PriceUpdaterAddress == msg.sender,"Not an Updater address");//price should in 8 decimals.
        currentPrice = price;
    } 
    
    function changeBNBPrice(uint price) external {
        require(PriceUpdaterAddress == msg.sender,"Not an Updater address");//price should be in 6 decimals.
        currentBNBPrice = price;
    } 
    
      
    function getWealthEarnings(string memory  username) public view returns(uint earnings) {
        for (uint i = 0 ; i< userDepositID[username].length ; i++) {
            uint _dID = userDepositID[username][i];
            earnings += depositIDMap[_dID].usdvalue*(block.timestamp - depositIDMap[_dID].time)*APY/3153600000;//365*24*60*60*100=3153600000
        }
    }
    
    function getTeamEarnings(string memory username) public view returns(uint earnings) {
        earnings = getTw1(username);

    }
    
    function getTotalEarnings(string memory username) public view returns(uint){ 
        return getWealthEarnings(username) + getTeamEarnings(username);
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
        _sendToUser(msg.sender, amount);
        usdWithdrawls[username] += amount;
        uint wID = block.timestamp + uint(keccak256(abi.encodePacked(username)));
        userWithdrawID[username].push(wID);
        Withdraw memory witData = Withdraw ({
            usdvalue : amount,
            time : block.timestamp
        });
        
        withdrawIDMap[wID] = witData;
    }
    
    function _sendToUser(address userAddress, uint amount) internal {
        uint amount1 = amount*(10**6);//80% only we have to send.//for calculation perpuose multply 10**6
        uint tokenAmount = ((8*amount1*10**7)/( currentPrice));   // = 10**8*100 / 10**6 //100 since amount is in cent.
        contractToken.transferFrom(collector,userAddress, tokenAmount); 
    }
    
    function deopsit() external payable {
        uint _usdvalue = (msg.value* currentBNBPrice)/10**22 ; //10**24 = 10**18 * 10**6 -100//the usd value in cent.
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
        userDepositID[username].push(dID);
        totalUSDDeposit[username] += _usdvalue;
    }
    function getSuperWitEntry(string memory username, uint _usdvalue, uint _withdrawTime) external {
    require(owner == msg.sender, "Owner Only Function for Migration");
         Withdraw memory witData = Withdraw ({
            usdvalue : _usdvalue,
            time : _withdrawTime
         });
        uint wID = _withdrawTime + uint(keccak256(abi.encodePacked(username)));
        withdrawIDMap[wID] = witData;
        userWithdrawID[username].push(wID);
        usdWithdrawls[username] += _usdvalue;
    }
        
    function getTw1(string memory username) public view returns(uint earnings){
            uint length1 = MLMA.getUserDownlineCount(username);
            if(length1 ==0) {return 0;}
            for (uint i = 0 ; i< length1 ; i++) {
                address _dAdd = MLMA.getUserDownline(username)[i];
                string memory child = MLMA.userAddressMap(_dAdd);
                earnings += getWealthEarnings(child)*2/10;
                }
    }

}