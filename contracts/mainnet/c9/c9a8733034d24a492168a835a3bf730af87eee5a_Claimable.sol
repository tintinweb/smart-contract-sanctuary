/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-19
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
        uint totalBalance;
        uint checkWithdrawBalance;
        uint orginalBalanceAfterCliff;
        uint balance;
        uint vestingStartTime;
        uint percentageShareTGE;
        uint cliffTimePeriod;
        uint interval;
        uint vestingEndTime;
        uint claimableBalance;
        uint vestingPercentage;
        uint withdrawalBalance;
    }
    
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
    
    function balanceTGE(address _tokenAddress, address _userAddress)public view returns (uint){
    if(now >= userMapping[_tokenAddress][_userAddress].vestingStartTime){
        return userMapping[_tokenAddress][_userAddress].claimableBalance;
        }
    }
    
    function getArray() public view returns(ERC20[] memory){
        return tokenAddressArray;
    }
    
    function _addUserAndBalances(address[] memory _userArray, uint _percentageShareTGE,uint _startTgeTime, uint _cliffTimePeriod, uint _interval, uint _vestingEndTime, uint _claimableBalance, ERC20 token, address _tokenAddress,uint _vestingPercentage, uint[] memory _balc) public {
        _token = token;
        tokenAddressArray.push(_token);
        for(uint i= 0;i < _userArray.length; i++) {
            if( userMapping[_tokenAddress][_userArray[i]].User == _userArray[i]){
            userMapping[_tokenAddress][_userArray[i]].balance +=  _balc[i];
            userMapping[_tokenAddress][_userArray[i]].orginalBalanceAfterCliff +=  _balc[i];
            tokenArray.push(_tokenAddress);
            }
            else{
                userMapping[_tokenAddress][_userArray[i]] = (usersDetails(_userArray[i],_balc[i],_balc[i], _balc[i], _balc[i],_startTgeTime,_percentageShareTGE,_startTgeTime +_cliffTimePeriod * oneDay, _interval * oneDay, _startTgeTime+ _cliffTimePeriod* oneDay + _vestingEndTime * oneDay, _claimableBalance, _vestingPercentage, 0));
                if(now >= userMapping[_tokenAddress][_userArray[i]].vestingStartTime){
                    uint calcTokenValueAdd = userMapping[_tokenAddress][_userArray[i]].balance * userMapping[_tokenAddress][_userArray[i]].percentageShareTGE;
                    calcTokenValueAdd = calcTokenValueAdd/100;
                    userMapping[_tokenAddress][_userArray[i]].orginalBalanceAfterCliff = userMapping[_tokenAddress][_userArray[i]].balance- calcTokenValueAdd;
                    userMapping[_tokenAddress][_userArray[i]].balance = userMapping[_tokenAddress][_userArray[i]].balance- calcTokenValueAdd;
                    userMapping[_tokenAddress][_userArray[i]].claimableBalance = calcTokenValueAdd;
                }else{
                    uint calcTokenValueAdd = userMapping[_tokenAddress][_userArray[i]].balance * userMapping[_tokenAddress][_userArray[i]].percentageShareTGE;
                    calcTokenValueAdd = calcTokenValueAdd/100;
                    userMapping[_tokenAddress][_userArray[i]].orginalBalanceAfterCliff = userMapping[_tokenAddress][_userArray[i]].balance- calcTokenValueAdd;
                    userMapping[_tokenAddress][_userArray[i]].balance = userMapping[_tokenAddress][_userArray[i]].balance- calcTokenValueAdd;
                    userMapping[_tokenAddress][_userArray[i]].claimableBalance = calcTokenValueAdd;
                }
                tokenArray.push(_tokenAddress);
            }
        }
    }
    
    function transferTokens (address sender, address _tokenAddress, address token,  address recvr, uint amnt, uint _withdrawalAmount) public  returns(bool){
        
        require(_token.allowance(owner, address(this)) >= amnt, "Insufficient Tokens in Smart contract");
        require(recvr == userMapping[_tokenAddress][recvr].User, "User is not Found!");
        require(userMapping[_tokenAddress][recvr].checkWithdrawBalance>= amnt, "User Balance is not Insufficient!");

        for(uint o = 1; o < tokenAddressArray.length; o++){
            if(tokenAddressArray[o] == ERC20(token)){
                _token.transferFrom(sender, recvr, _withdrawalAmount);
                userMapping[_tokenAddress][recvr].balance = userMapping[_tokenAddress][recvr].balance - (amnt- userMapping[_tokenAddress][recvr].claimableBalance);
                userMapping[_tokenAddress][recvr].claimableBalance= 0;
                userMapping[_tokenAddress][recvr].withdrawalBalance +=  amnt;
                userMapping[_tokenAddress][recvr].checkWithdrawBalance = userMapping[_tokenAddress][recvr].checkWithdrawBalance-amnt;
                return true;        
            }
        }
        
    }
}