pragma solidity 0.7.1;

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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

abstract contract IERC20 {
    function balanceOf(address who) public virtual view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external virtual;
    function transfer(address recipient, uint amount) public virtual;
}

contract PFIContract{
    using SafeMath for uint256;
    
    modifier onlyOwner{
        require(msg.sender == _owner,"Forbidden");
        _;
    }
    
    address internal _owner;
    
    uint256 internal _ethToPfiPrice = 5000000;              //1ETH = 5 PFI
    uint256 internal _ethToPfiPriceDivided = 1000000;       //ETH to PFI = _ethToPfiPrice / _ethToPfiPriceDivided
    
    address private _pfiTokenContractAddress = 0x6096Ef5A1321e405EdC63D40e9a4C190a7ef1B98;      //PFI Contract
    
    uint256 internal _purchaseEndTime = 1612137600; //2021-02-01 00:00:00
    
    constructor () payable{
        _owner = _msgSender();
    }
    
    function updatePrice(uint256 price) external onlyOwner{
         _ethToPfiPrice = price;
        emit UpdatePfiPrice(price);
    }
    
    function getPrice() external view returns(uint256){
        return _ethToPfiPrice.div(_ethToPfiPriceDivided);
    }
    
    function updatePurchaseEndTime(uint256 endTime) external onlyOwner{
        _purchaseEndTime = endTime;
    }
    
    function getPurchaseEndTime() external view returns(uint256){
        return _purchaseEndTime;
    }
    
    receive () external payable{
         processPurchase();
    }
    
    function processPurchase() internal{
        require(_getNow() < _purchaseEndTime, "Purchase token time is end");
        address sender = _msgSender();
        
        uint256 ethAmount = msg.value;
        
        //Process to pay token for sender
        //Calculate ETH to token price
        uint256 tokenAmount = ethAmount.mul(_ethToPfiPrice).div(_ethToPfiPriceDivided);
        
        IERC20 token = IERC20(_pfiTokenContractAddress);
        require(token.balanceOf(address(this)) >= tokenAmount,"System balance is not enough");
         
        token.transfer(sender, tokenAmount);
        emit Purchase(sender, tokenAmount);
    }
    
    function withdrawEth() external onlyOwner{
        uint256 ethBalance = address(this).balance; 
        require(ethBalance > 0,'Balance is zero');
        msg.sender.transfer(ethBalance);
        
        emit WithdrawEth(ethBalance);
    }
    
    function withdrawToken(uint256 amount) external onlyOwner{
        require(amount > 0, "Withdraw amount should be greater than 0");
        
        IERC20 token = IERC20(_pfiTokenContractAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance >= amount, "Balance is not enough");
        
        token.transfer(_msgSender(),amount);
        emit WithdrawToken(amount);
    }
    
    function _getNow() private view returns(uint256){
        return block.timestamp;
    }
    
    function _msgSender() internal view returns(address){
        return msg.sender;
    }
    
    event UpdatePfiPrice(uint256 price);
    event Purchase(address sender, uint256 purchasedAmount);
    event WithdrawEth(uint256 eth);
    event WithdrawToken(uint256 amount);
}

//SPDX-License-Identifier: MIT