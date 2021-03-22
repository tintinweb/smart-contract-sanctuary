/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function decimals() external view returns(uint256);
    // function totalSupply() external view returns(uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Auction {
/****VARIABLES****/

    struct Result{
        string userName;
        uint256 bid;
    }
    
    address public contractOwner;
    
    string[] public depositors;
    string public maxBidUser;
   
    mapping(string => uint256) public deposits;
    mapping(string => mapping(address => uint256[3])) public depositPerAccount;
    mapping(string => uint256[3]) public depositsPerCoin;
    mapping(string => bool) public claimStatus;
    mapping(string => address) public primaryAddress;
    mapping(string => address[]) public depositAccounts;
    
    uint256 public totalBidAmounts;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public totalWinners;
    uint256 public minimumBid;
    uint256 constant public PRECISION = 10**18;
    
    IERC20[3] public coins;
/****EVENTS****/
event Deposits(string userName, address account, address coin, uint amount);

/****Modifiers*****/
    modifier onlyOnwer(){
        require(contractOwner == msg.sender, "Only admin can call!!");
        _;
    }
    
/****Constructor****/
    constructor(IERC20[3] memory _coins, uint256 _startTime, uint256 _endTime, uint256 _totalWinners, uint256 _minimumBid){
        require(_startTime > block.timestamp, "Invalid start time");
        require(_endTime > startTime, "End time can not be before start time");
        
        contractOwner = msg.sender;
        startTime = _startTime;
        endTime = _endTime;
        coins = _coins;
        totalWinners = _totalWinners;
        minimumBid = _minimumBid;
    }
    
/****ADMIN FUNCTIONS****/

    function transferCoins(address account) public onlyOnwer() returns(bool){
        for(uint256 i= 0 ; i < coins.length; i++){
            uint256 totalBalance = coins[i].balanceOf(address(this));
            if(totalBalance > 0 ){
                coins[i].transfer(account, totalBalance);
            }
        }
        return true;
    }
    
    function transferOwnership(address newOwner) public onlyOnwer() returns(bool){
        contractOwner = newOwner;
        return true;
    }
    
/****Users Functions****/
    function setPrimaryAddress(string memory userName) public returns(bool){
        require(primaryAddress[userName] == address(0), "Already registered, call changeAddress to update address");
        require(block.timestamp < endTime, "Auction Over");
        
        primaryAddress[userName] = msg.sender;
        return true;
    }
    
    function changeAddress(string memory userName, address newPrimaryAddress) public returns(bool){
        require(primaryAddress[userName] != address(0), "Register First");
        require(primaryAddress[userName] == msg.sender, "You can change only your primary address");
        
        primaryAddress[userName] = newPrimaryAddress;
        return true;
    }
    
    function placeBid(uint256 amount, uint256 coinIndex, string memory userName) public returns(bool){
        require(block.timestamp > startTime, "Auction not yet started");
        require(block.timestamp < endTime , "Auction over");
        require(primaryAddress[userName] != address(0), "Register your primary address first");
        require(amount > 0 , "Invalid amount");
        
        uint256 updatedAmount =  amount * PRECISION / (10**coins[coinIndex].decimals());
        deposits[userName] = deposits[userName] + updatedAmount;
        require(deposits[userName] > minimumBid , "Deposit amount can not be less than minimum bid amount");
        totalBidAmounts = totalBidAmounts + updatedAmount;
        
        if(deposits[userName] > deposits[maxBidUser]){
            maxBidUser = userName;
        }
        if(newAccount(userName)){
            depositAccounts[userName].push(msg.sender);
        }
        
        depositPerAccount[userName][msg.sender][coinIndex] = depositPerAccount[userName][msg.sender][coinIndex] + amount;
        depositsPerCoin[userName][coinIndex] = depositsPerCoin[userName][coinIndex] + amount;
        coins[coinIndex].transferFrom(msg.sender, address(this), amount);
        emit Deposits(userName, msg.sender, address(coins[coinIndex]), amount);
        return true;
    }
    
    function claimBidAmount(string memory userName) public returns(bool){
        require(primaryAddress[userName] == msg.sender, 'Claim can be done only using primary account');
        require(canClaim(userName), 'Not eligible');
        require(!claimStatus[userName], 'Already claimed');
        
        claimStatus[userName] = true;
        
        for(uint i = 0 ; i < coins.length ; i++){
            uint256 claimableAmount = depositsPerCoin[userName][i];
            if(claimableAmount > 0){
                coins[i].transfer(primaryAddress[userName], claimableAmount);
            }
        }
        
        return true;
    }
    
    function getAllDepositAccounts(string memory userName) public view returns(address[] memory){
        return depositAccounts[userName];
    }
     
    function canClaim(string memory userName) public view returns (bool){
        if(block.timestamp < endTime){
            return false;
        }
        Result[] memory topUsers = getTopBidders();
        for(uint i = 0 ; i < topUsers.length; i++){
            if(keccak256(bytes(topUsers[i].userName)) == keccak256(bytes(userName))){
                return false;
            }
        }
        return true;
    }
    
/****Other Functions****/
    
    function getAllBidders() public view returns(string[] memory){
        return depositors;
    }

    function getTopBidders() public view returns (Result[] memory) {
        uint256 totalDepositors = depositors.length;
        string[] memory sortedResult = depositors;
        for(uint i = 0; i < totalDepositors; i++) {
            for(uint j = i+1; j < totalDepositors ;j++) {
                if(deposits[sortedResult[i]] < deposits[sortedResult[j]]) {
                    string memory temp =sortedResult[i] ;
                    sortedResult[i] = sortedResult[j];
                    sortedResult[j] = temp;
                }
            }
        }
        Result[] memory topUsers = new Result[](totalWinners); 
        for(uint m = 0 ; m < totalWinners && m < totalDepositors ; m++){
            topUsers[m] = Result(sortedResult[m],deposits[sortedResult[m]]) ;
        }
        return topUsers;
    }
    
    function totalBids() public view returns(uint256){
        return depositors.length;
    }
    
    function newAccount(string memory userName) internal view returns(bool){
        for(uint256 i = 0; i < coins.length; i++){
            if(depositPerAccount[userName][msg.sender][i] > 0){
                return false;
            }
        }
        return true;
    }
    
/**** TEST FUNCTION****/
    function changeTimes_TestFunction(uint256 _startTime, uint256 _endTime) public {
        startTime = _startTime;
        endTime = _endTime;
    }
    
    
}