/**
 *Submitted for verification at BscScan.com on 2021-12-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}




contract Crowdsale {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    address payable private _wallet = payable(0x31E155Fe1C52A6419782c33cb4577DdC9E1b1A0f); // our wallet address
    address payable private ceo = payable(0x31E155Fe1C52A6419782c33cb4577DdC9E1b1A0f); // ceo address
    address payable private fas = payable(0x85604fc2F8818928524E88A59A9023F938c448c4); // fas address
    address payable private dev = payable(0x1b71038959BF7Eed4710E4F96D9c3fee27043B0B); // dev address

    uint256 public totalBNBCollected;
    mapping(address => uint256) public investments;
    mapping(address => bool) public exist;
    address payable [] public investors;
    uint256 public target = 1000000000000000000;

    IERC20 private _token;

    uint256 private _rate;

    uint256 private _weiRaised;
    
    address public owner;
    
    address public owner2;
    

    event TokensPurchased(address indexed purchaser, uint256 value);

    constructor () {
        _rate = 4000;
        _wallet = payable(msg.sender);
        _token = IERC20(0xfd9e9220ECe1Ce92687A8f5FeE446B9f310Aa0d2);
        owner = msg.sender;
        owner2 = 0x85604fc2F8818928524E88A59A9023F938c448c4;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner || msg.sender == owner2, 'only Owner can run this function');
        _;
    }
    
    receive() external payable {
        buyTokens();
    }

    function token() public view returns (IERC20) {
        return _token;
    }

    function wallet() public view returns (address) {
        return _wallet;
    }

    function rate() public view returns (uint256) {
        return _rate;
    }
    function remainingTokens() public view returns (uint256) {
        return _token.balanceOf(address(this));
    }

    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }
    
    function changeRate(uint256 price) public onlyOwner() returns(bool success) {
        _rate = price;
        return success;
    }
    

    function buyTokens() public payable {
       // require(msg.value >= 0.5 ether && msg.value <= 10 ether);
        address payable sender = payable(msg.sender);
        uint256 weiAmount = (msg.value);
        if(!exist[sender]){
            investors.push(sender);
            exist[sender] = true;
        }
        totalBNBCollected = totalBNBCollected.add(msg.value);
        investments[sender] = investments[sender].add(msg.value);

        // calculate token amount to be created
        // update state
        _weiRaised = _weiRaised.add(weiAmount);

        emit TokensPurchased(msg.sender, weiAmount);

    }

    function _deliverTokens(address sender, uint256 tokenAmount) internal {
        _token.safeTransfer(sender, tokenAmount);
    }

    
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate);
    }
    
    function getInvestment() external view returns(uint256) {
        return _getTokenAmount(investments[msg.sender]);
    }
    
    function endIco() public onlyOwner {
        for(uint256 i = 0; i < investors.length; i++){
            address investor = investors[i];
            uint256 investment = investments[investor];
            uint256 numberOfTokens = _getTokenAmount(investment);
            investors[i] = investors[investors.length - 1];
            investors.pop();
            delete investments[investor];
            delete exist[investor];
            delete totalBNBCollected;
            _token.transfer(investor, numberOfTokens);
        }
        uint256 balance = address(this).balance;
        ceo.transfer((balance.div(100)).mul(40));
        fas.transfer((balance.div(100)).mul(40));
        dev.transfer((balance.div(100)).mul(20));
       
        delete _weiRaised;
        return;
    
    }
    
    function withdrawBNB() external onlyOwner{
        uint256 balance = address(this).balance;
        if(balance > 0){
            ceo.transfer((balance.div(100)).mul(40));
            fas.transfer((balance.div(100)).mul(40));
            dev.transfer((balance.div(100)).mul(20));
            
        }
    }
    
    function changeTarget(uint256 _target) external onlyOwner{
        target = _target;
    } 
    
    function getTokens() external onlyOwner returns(bool){
        _token.transfer(_wallet, remainingTokens());
        return true;
    }
}