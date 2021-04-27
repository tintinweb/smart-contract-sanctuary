/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity ^0.6.0;


library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return _sub(a, b, "SafeMath: subtraction overflow");
    }

    function _sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return _div(a, b, "SafeMath: division by zero");
    }

    function _div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return _mod(a, b, "SafeMath: modulo by zero");
    }

    function _mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


 interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external  view returns (uint256);
    function transfer(address to, uint256 value) external  returns (bool ok);
    function transferFrom(address from, address to, uint256 value) external returns (bool ok);
    function approve(address spender, uint256 value)external returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}


contract BitmindCrowdsale {
    using SafeMath for uint256;

    uint256 public totalSold;
    IERC20 private tokenAddress;
    IERC20 private pairAddress;
    address payable private owner;
    
    uint256 public start_time;
    uint256 public end_time;

    /**
     * Event for token purchase logging
     * @param purchaser : who paid for the tokens and get the tokens
     * @param amount : total amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, uint256 amount);
    
    /**
     * Event for Start Crowdsale
     * @param owner : who owner this contract
     * @param openingtime : time when the Crowdsale started
     */
    event OpeningTime(address indexed owner, uint256 openingtime);
    
    /**
     * Event for Close Crowdsale
     * @param owner : who owner this contract
     * @param closingtime : time when the Crowdsale Ended
     */
    event ClosingTime(address indexed owner, uint256 closingtime);
  

    constructor(address _token, address _pair) public {
        owner = msg.sender;
        tokenAddress = IERC20(_token);
        pairAddress = IERC20(_pair); 

    }
    /**
     * Function for Purchase Token on Crowdsale
     * @param _amount : amount which user purchase
     * 
     * return event TokensPurchased
     */
    
    function Purchase(uint256 _amount) external returns(bool){
        
        //Validation Crowdsale
        require(start_time > 0 && end_time > 0 , 'BitmindMsg: Crowdsale is not started yet');
        require(now > start_time && now < end_time, 'BitmindMsg: Crowdsale is not started yet');
        
        //Validation Allowance
        uint256 tokenAmount = pairAddress.allowance(msg.sender, address(this));
        require(tokenAmount > 0 , 'BitmindMsg: Allowance not found');
        
        uint256 amount = _amount * 10 ** 12;
        
        
        require(remainingToken() > 0 && remainingToken() >= amount, "BitmindMsg: INSUFFICIENT BMD");
        require(pairAddress.balanceOf(msg.sender) >= _amount, "BitmindMsg: Amount higher than Your Balance");
        
        pairAddress.transferFrom(msg.sender, address(this), _amount);
        
        deliveryTokens(amount);
    }
    function deliveryTokens(uint256 _amount) internal returns(bool) {
        
        totalSold = totalSold.add(_amount);
        tokenAddress.transfer(msg.sender, _amount);
        
        emit TokensPurchased(msg.sender, _amount);
        return true;
    }
    
    //function to withdraw collected USDT
    //only owner can call this function
    function withdrawUSDT()public{
         require(msg.sender == owner && pairAddress.balanceOf(address(this))>0);
         pairAddress.transfer(msg.sender, pairAddress.balanceOf(address(this)));
    }
    
    //function to start the Sale
    //only owner can call this function
     
    function openingTime(uint256 _time) public {
        require(msg.sender == owner, "BitmindMsg: Owner Only");
        require(start_time == 0, "BitmindMsg: Opening Time already set");
        start_time = _time;
        
        emit OpeningTime(owner, _time);
    }
    function closingTime(uint256 _time) public {
        require(msg.sender == owner, "BitmindMsg: Owner Only");
        require(start_time > 0, "Crowdsale is not started yet");
        require(end_time == 0, "BitmindMsg: Closing Time already set");
        end_time = _time;
        
        emit ClosingTime(owner, _time);
    }
    
    //function to return the available BMD in the contract
    function remainingToken()public view returns(uint256){
        return tokenAddress.balanceOf(address(this));
    }
    
     //function to withdraw available BMD in this contract
     //only owner can call this function
     
    function withdrawToken()public{
         require(msg.sender==owner && tokenAddress.balanceOf(address(this))>0);
         tokenAddress.transfer(owner,tokenAddress.balanceOf(address(this)));
    }
    
    //function to change the owner
    //only owner can call this function
    
    function changeOwner(address payable _owner) public {
        require( msg.sender == owner, 'BitmindMsg: Only Owner' );
        owner=_owner;
    }
    

}