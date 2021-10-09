/**
 *Submitted for verification at polygonscan.com on 2021-10-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity  >=0.7.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface PriceFeed {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (int256);
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract TokenSale is Owned {

    // Address validators
    IERC20 public tokenJAVA; 
    IERC20 public tokenUSDC;
    PriceFeed public priceFeed;
    
    // Min time for next transaction (Anti whale functions)
    uint256 public operationTime = 10 minutes;
    
    struct UserInfo {
        uint256 shares; // number of shares for a user
        uint256 lastUserActionTime; // keeps track of the last user action time
        uint256 firstUserActionTime; // Keeps the time for first transaction
    }
    
    mapping(address => UserInfo) public userInfo;

    constructor () {  
        //TOken contract JAVA Matic Network
        tokenJAVA = IERC20(0xAFC9AA5ebd7197662D869F75890F18AafEEFb1f5);
        //TOken Contract USDC Matic Network
        tokenUSDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
        //Price Feed Matic/Usd
        priceFeed = PriceFeed(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);
    }

    // Math funtions (sqrt and div)
    function sqrt (uint x) public pure returns (uint y) {
      uint z = (x + 1) / 2;
      y = x;
      while (z < y) {
          y = z;
          z = (x / z + z) / 2;
      }
    }
    
    //Modifiers for to do validations
    modifier validateOperationTime{
        UserInfo storage user = userInfo[msg.sender];
        require(block.timestamp > (user.lastUserActionTime + operationTime), "ERROR: User need wait 10 minutes for next action");
        _;
    }
    
    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        _;
    }

    
    function getMult(uint decimals) public pure returns (uint256){
        uint256 result = 1;
        
        for(uint i=0;i< decimals; i++){
            result = result * 10;
        }
        
        return result;
    }
    
    function calculateUsdcByJava(uint256 amountJava) public view returns (uint256){
        
        uint256 decimalsJava = getMult(tokenJAVA.decimals());
        uint256 decimalsLeft = getMult(tokenJAVA.decimals() - tokenUSDC.decimals());
        
        require (amountJava >= 200 * decimalsJava, "ERROR: The amount is below to 200 JAVAS");
        
        UserInfo storage user = userInfo[msg.sender];
        
        // Get history of shares bought 
        uint256 totalAssetsBought = user.shares;
        
        uint256 totalBuy = amountJava + totalAssetsBought;
        
        require (totalBuy <= 12650 * decimalsJava, "ERROR: The amount is above to 12650 JAVAS");
        
        
        // Do Calcules Count with the amoung bought
        uint256 Buy25 = totalBuy>(4000 * decimalsJava)?(4000 * decimalsJava):totalBuy;
        totalBuy = totalBuy<(4000 * decimalsJava)?0:(totalBuy-(4000 * decimalsJava));
        
        uint256 Buy33 = totalBuy>(2000 * decimalsJava)?(2000 * decimalsJava):totalBuy;
        totalBuy = totalBuy<(2000 * decimalsJava)?0:(totalBuy-(2000 * decimalsJava));
        
        uint256 Buy45 = totalBuy>(2000 * decimalsJava)?(2000 * decimalsJava):totalBuy;
        totalBuy = totalBuy<(2000 * decimalsJava)?0:(totalBuy-(2000 * decimalsJava));
        
        uint256 Buy60 = totalBuy>(2000 * decimalsJava)?(2000 * decimalsJava):totalBuy;
        totalBuy = totalBuy<(2000 * decimalsJava)?0:(totalBuy-(2000 * decimalsJava));
        
        uint256 Buy75 = totalBuy;
        
        
        uint256 amountUSDC = 0; 
        
        // x4 for the first 4000 Javas
        Buy25 = totalAssetsBought > Buy25?0:(Buy25 - totalAssetsBought);
        amountUSDC = Buy25 / (4 * decimalsLeft);
        
        // Refresh for the next validation
        totalAssetsBought = totalAssetsBought<(4000 * decimalsJava)?0:(totalAssetsBought-(4000 * decimalsJava));
        
        //x3.0303 for the second 2000 Javas
        Buy33 = totalAssetsBought > Buy33?0:(Buy33 - totalAssetsBought);
        amountUSDC = amountUSDC + Buy33 / (3030303030303);
        
        // Refresh for the next validation
        totalAssetsBought = totalAssetsBought<(2000 * decimalsJava)?0:(totalAssetsBought-(2000 * decimalsJava));
        
        //x2.2222 for the second 2000 Javas
        Buy45 = totalAssetsBought > Buy45?0:(Buy45 - totalAssetsBought);
        amountUSDC = amountUSDC + Buy45 / (2222222222222);
        
        // Refresh for the next validation
        totalAssetsBought = totalAssetsBought<(2000 * decimalsJava)?0:(totalAssetsBought-(2000 * decimalsJava));
        
        //x1.6666 for the second 2000 Javas
        Buy60 = totalAssetsBought > Buy60?0:(Buy60 - totalAssetsBought);
        amountUSDC = amountUSDC + Buy60 / (1666666666666);
        
        // Refresh for the next validation
        totalAssetsBought = totalAssetsBought<(2000 * decimalsJava)?0:(totalAssetsBought-(2000 * decimalsJava));
        
        //x1.6666 for the second 2000 Javas
        Buy75 = Buy75 - totalAssetsBought;
        amountUSDC = amountUSDC + Buy75 / (1333333333333);
        
        return amountUSDC;
    }
    
    function calculateMaticByJava(uint256 amountJava) public view returns (uint256){
          
        require (amountJava >= 200 ether, "ERROR: The amount is below to 200 JAVAS");
        
        //Get latest price for Matic
        uint256 latestPrice = uint256(priceFeed.latestAnswer());
        
        UserInfo storage user = userInfo[msg.sender];
        
        // Get history of shares bought 
        uint256 totalAssetsBought = user.shares;
        
        uint256 totalBuy = amountJava + totalAssetsBought;
        
        require (totalBuy <= 12650 ether, "ERROR: The amount is above to 12650 JAVAS");
        
        // Do Calcules Count with the amoung bought
        uint256 Buy25 = totalBuy>(4000 ether)?(4000 ether):totalBuy;
        totalBuy = totalBuy<(4000 ether)?0:(totalBuy-(4000 ether));
        
        uint256 Buy33 = totalBuy>(2000 ether)?(2000 ether):totalBuy;
        totalBuy = totalBuy<(2000 ether)?0:(totalBuy-(2000 ether));
        
        uint256 Buy45 = totalBuy>(2000 ether)?(2000 ether):totalBuy;
        totalBuy = totalBuy<(2000 ether)?0:(totalBuy-(2000 ether));
        
        uint256 Buy60 = totalBuy>(2000 ether)?(2000 ether):totalBuy;
        totalBuy = totalBuy<(2000 ether)?0:(totalBuy-(2000 ether));
        
        uint256 Buy75 = totalBuy;
        
        uint256 amountMATIC = 0;
        
        // x4 on MATIC Price for the first 4000 Javas
        Buy25 = totalAssetsBought > Buy25?0:(Buy25 - totalAssetsBought);
        amountMATIC = ( Buy25 / (4 * getMult(6) * latestPrice)) * getMult(14);
        
        // Refresh for the next validation
        totalAssetsBought = totalAssetsBought<(4000 ether)?0:(totalAssetsBought-(4000 ether));
        
        //x3.0303 for the second 2000 Javas
        Buy33 = totalAssetsBought > Buy33?0:(Buy33 - totalAssetsBought);
        amountMATIC = amountMATIC + ( Buy33 / (3030303 * latestPrice)) * getMult(14);
 
        // Refresh for the next validation
        totalAssetsBought = totalAssetsBought<(2000 ether)?0:(totalAssetsBought-(2000 ether));
        
        //x2.2222 for the second 2000 Javas
        Buy45 = totalAssetsBought > Buy45?0:(Buy45 - totalAssetsBought);
        amountMATIC = amountMATIC + ( Buy45 / (2222222 * latestPrice)) * getMult(14);
        
        // Refresh for the next validation
        totalAssetsBought = totalAssetsBought<(2000 ether)?0:(totalAssetsBought-(2000 ether));
        
        //x1.6666 for the second 2000 Javas
        Buy60 = totalAssetsBought > Buy60?0:(Buy60 - totalAssetsBought);
        amountMATIC = amountMATIC + ( Buy60 / (1666666 * latestPrice)) * getMult(14);
        
        // Refresh for the next validation
        totalAssetsBought = totalAssetsBought<(2000 ether)?0:(totalAssetsBought-(2000 ether));
        
        //x1.6666 for the second 2000 Javas
        Buy75 = Buy75 - totalAssetsBought;
        amountMATIC = amountMATIC + ( Buy75 / (1333333 * latestPrice)) * getMult(14);
        
        return amountMATIC;
    }
    
    function getJavaBalance() public view returns (uint){
        return tokenJAVA.balanceOf(address(this));
    }
    
    function acceptSwapUSDC(uint256 amountJAVA) public validateOperationTime notContract{

        uint256 amountUSDC = calculateUsdcByJava(amountJAVA);
        
        
        // Validation Section About Amount of Java on the contract, and the allowance for tokens
        require (tokenJAVA.balanceOf(address(this))>=amountJAVA, "Amount tokens JAVA below for this transaction");
        
        require(
            tokenUSDC.allowance(msg.sender, address(this)) >= amountUSDC,
            "Token allowance too low"
        );
        
        // Tranfers token of swap
        tokenUSDC.transferFrom(msg.sender, owner, amountUSDC);
        
        tokenJAVA.transfer(msg.sender, amountJAVA);
        
        // Update info user 
        UserInfo storage user = userInfo[msg.sender];
        
        user.shares = user.shares + amountJAVA;
        user.lastUserActionTime = block.timestamp; 
        
        if(user.firstUserActionTime == 0){
            user.firstUserActionTime = block.timestamp;
        }
        
    }
    
    function acceptSwapMATIC(uint256 amountJAVA) public payable validateOperationTime notContract{

        uint256 amountMATIC = calculateMaticByJava(amountJAVA);
        // Validation Section About Amount of Java on the contract, and the allowance for tokens
        require (tokenJAVA.balanceOf(address(this))>=amountJAVA, "Amount tokens JAVA below in this contrat for the transaction");
        
        // Validation Matic Amount
        require(amountMATIC <= msg.value + msg.value/100,"ERROR: Caller has not got enough ETH for Swap");
        
        // Tranfers token of swap
        payable(owner).transfer(msg.value);
        
        tokenJAVA.transfer(msg.sender, amountJAVA);
        
        // Update info user 
        UserInfo storage user = userInfo[msg.sender];
        
        user.shares = user.shares + amountJAVA;
        user.lastUserActionTime = block.timestamp; 
        
        if(user.firstUserActionTime == 0){
            user.firstUserActionTime = block.timestamp;
        }
    }

    receive() external payable {}
    
    // Validations for whales
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
    
     /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev Only callable by owner.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IERC20(_tokenAddress).transfer(owner, _tokenAmount);
    }
    
    function recoverEthereum(uint256 _amount) external onlyOwner {
        payable(owner).transfer(_amount);
    }
    
}