/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

pragma solidity 0.5.6;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
contract ERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Claimable{

    ERC20 private _token;
    address private owner;
    uint private oneMinute = 1 minutes;
    uint private oneDay = 1 days;

    struct usersDetails {
        address User;
        uint orginalBalanceAfterCliff;
        uint balance;
        uint vestingStartTime;
        uint percentageShareTGE;
        uint cliffTimePeriod;
        uint interval;
        uint vestingEndTime;
        uint claimableBalance;
        uint vestingPercentage;
    }
    // ERC20 e;
    
    ERC20[] public tokenAddressArray;
    constructor(ERC20 token) public{
        owner = msg.sender;
         _token = token;
         tokenAddressArray.push(_token);
        // e.totalSupply();
    }
    function checkBalance(address addr) public view returns(uint){
       ERC20 e = ERC20(addr);
       return e.totalSupply();
    }
    mapping(address => mapping(address => usersDetails)) public userMapping;
    address[] public userArray;
    address[] public tokenArray;
    
    function _getClaimableBalance(address _tokenAddress, address _userAddress, uint _interval ) public view returns(uint){
        
        if(now >= userMapping[_tokenAddress][_userAddress].cliffTimePeriod){
            
            //calculate the days after cliff using interval : Dividing the result with interval Value; 3
            uint daysAfterCliff = (now-userMapping[_tokenAddress][_userAddress].cliffTimePeriod)/_interval;
            
            // used to calculate tokens according to the vesting % allowed to this user; 80 Tokens
            uint calcDailyToken= userMapping[_tokenAddress][_userAddress].orginalBalanceAfterCliff/100;
            calcDailyToken= calcDailyToken* userMapping[_tokenAddress][_userAddress].vestingPercentage;
            
            // known issues : check if balance is too low
            // known issues : multiple every amount with 100
            // known issues : Counting Days from day 1 even users withdrawals his/her day 1 tokens
            // known issues : If user didn't withdrawal his/her TGE claimable balance than handle other equality operator
            
            uint tokensAvailableToWithdraw = daysAfterCliff * calcDailyToken + userMapping[_tokenAddress][_userAddress].claimableBalance; //store the value for 3 days : 240 Tokens
            
            if(userMapping[_tokenAddress][_userAddress].balance != userMapping[_tokenAddress][_userAddress].orginalBalanceAfterCliff){ // Balance is 560 Tokens
                // uint remainingDaysToWithdrawal = userMapping[_tokenAddress][_userAddress].balance/calcDailyToken; // store the value of remaining days vesting : 9 days
                
                //calculate the value of tokens if balance is lowwer than orginalBalanceAfterCliff and return balance according to the current day and withdrawal Tokens
                uint daysDifference = (userMapping[_tokenAddress][_userAddress].orginalBalanceAfterCliff - userMapping[_tokenAddress][_userAddress].balance)/ calcDailyToken; // store the days differnece in total : 1
                uint exectDaysLeft = daysAfterCliff - daysDifference;
                return exectDaysLeft * calcDailyToken;
            }
            
            
            // Checks if user balance is exceeded from orginalBalanceAfterCliff than shows 
            if(tokensAvailableToWithdraw >= userMapping[_tokenAddress][_userAddress].orginalBalanceAfterCliff + userMapping[_tokenAddress][_userAddress].claimableBalance){
                // checks if balance is 0 
                if(userMapping[_tokenAddress][_userAddress].balance == 0){
                    return userMapping[_tokenAddress][_userAddress].balance;    
                }
                return userMapping[_tokenAddress][_userAddress].orginalBalanceAfterCliff + userMapping[_tokenAddress][_userAddress].claimableBalance;
            }
            
            return tokensAvailableToWithdraw;
        }else{
            
            //returns the claimable balance before cliff 
            return userMapping[_tokenAddress][_userAddress].claimableBalance;
        }
    }
    function getTime()public view returns(uint){
        return now;
    }
    // ["0x609A4ebD8e09a5d2D87A3966A0F6f232E6bDc729","0x8e4Ac077A63c5BFc0BBD6CfECc54f2D07BA3cfE3"]
    function _addUserAndBalances(address[] memory _userArray, uint _percentageShareTGE, uint _cliffTimePeriod, uint _interval, uint _vestingEndTime, uint _claimableBalance, ERC20 token, address _tokenAddress,uint _vestingPercentage, uint[] memory _balc) public {
        _token = token;
        tokenAddressArray.push(_token);
        for(uint i= 0;i < _userArray.length; i++) {
            if( userMapping[_tokenAddress][_userArray[i]].User == _userArray[i]){
            userMapping[_tokenAddress][_userArray[i]].balance +=  _balc[i];
            userMapping[_tokenAddress][_userArray[i]].orginalBalanceAfterCliff +=  _balc[i];
            tokenArray.push(_tokenAddress);
            }
            else{
                userMapping[_tokenAddress][_userArray[i]] = (usersDetails(_userArray[i], _balc[i], _balc[i],now,_percentageShareTGE,now +_cliffTimePeriod * oneMinute, _interval * oneMinute, now+ _cliffTimePeriod* oneDay + _vestingEndTime * oneDay, _claimableBalance, _vestingPercentage));
                if(now >= userMapping[_tokenAddress][_userArray[i]].vestingStartTime){
                    uint calcTokenValue = userMapping[_tokenAddress][_userArray[i]].balance * userMapping[_tokenAddress][_userArray[i]].percentageShareTGE;
                    calcTokenValue = calcTokenValue/100;
                    userMapping[_tokenAddress][_userArray[i]].orginalBalanceAfterCliff = userMapping[_tokenAddress][_userArray[i]].balance- calcTokenValue;
                    userMapping[_tokenAddress][_userArray[i]].balance = userMapping[_tokenAddress][_userArray[i]].balance- calcTokenValue;
                    userMapping[_tokenAddress][_userArray[i]].claimableBalance = calcTokenValue;
                }
                // _getClaimableBalance(userMapping[_tokenAddress][_userArray[i]].balance, userMapping[_tokenAddress][_userArray[i]].claimableBalance);
                tokenArray.push(_tokenAddress);
            }
        }
    }
    
    function transferTokens(address sender, address _tokenAddress, address token,  address recvr, uint amnt, uint _interval) public returns(bool){
        
        //Uncomment Later Starts
        
        // require(_token.allowance(owner, address(this)) >= amnt, "Insufficient Tokens in Smart contract");
        // require(userMapping[_tokenAddress][recvr].balance >= amnt, "User Balance is not Sufficient!");
        // require(amnt >= _getClaimableBalance(_tokenAddress, recvr, _interval), "User Withdrawalable Balance is not Sufficient!");
        
        //Uncomment Later Ends
        
        
        // _token = token;
        // uint transferToken= _getClaimableBalance(_tokenAddress, recvr );
        // if(userMapping[_tokenAddress][recvr].claimableBalance >= 0){
        //     userMapping[_tokenAddress][recvr].claimableBalance = userMapping[_tokenAddress][recvr].claimableBalance-transferToken;
        // }
        
        for(uint o = 1; o < tokenAddressArray.length; o++){
            if(tokenAddressArray[o] == ERC20(token)){
                
        //Uncomment Later Starts
        
                // _token.transferFrom(sender, recvr, amnt);
        
        //Uncomment Later Ends
        
                userMapping[_tokenAddress][recvr].balance = userMapping[_tokenAddress][recvr].balance - (amnt- userMapping[_tokenAddress][recvr].claimableBalance);
                userMapping[_tokenAddress][recvr].claimableBalance= 0;
                return true;        
            }
        }
        
    }
}