pragma solidity ^0.4.23;
import './owned.sol';
import './SafeMath.sol';


contract token{
    function transfer(address _to,uint256 amount) external;
    function transferFrom(address _from,address _to,uint256 _value) external;
}

contract ICO_USDT is owned{
    
    using SafeMath for uint;
    uint price;
    uint public fundAmount;
    token public tokenReward;
    token public usdtToken;

    address public beneficiary;
    mapping(address => uint) public balanceOf;
    event FundTransfer(address backer,uint amount);
    constructor (uint usdtDecimalCostofToken,address addressOfToken,address addressOfUSDT) {
        price = usdtDecimalCostofToken ;
        tokenReward = token(addressOfToken);
        usdtToken = token(addressOfUSDT);
        beneficiary = msg.sender;
    }
    function setPrice(uint usdtDecimalCostofToken) public onlyowner{
        price = usdtDecimalCostofToken ;
    }
    
    function getPrice() public view returns (uint){
        return price ;
    }
    
    function() public {
    }
    
    function withdrawal() public{
        
        require(beneficiary == msg.sender);
        usdtToken.transfer(beneficiary,fundAmount) ;
        fundAmount = 0;
        
    }
    
    function usdtSwap(uint _usdtDecimalAmount) public{
        
        usdtToken.transferFrom(msg.sender,address(this),_usdtDecimalAmount);
        balanceOf[msg.sender] += _usdtDecimalAmount;
        fundAmount += _usdtDecimalAmount;
        uint256 tokenAmount = _usdtDecimalAmount * (10 ** 18 )  / price  ;
        tokenReward.transfer(msg.sender,tokenAmount);
        emit FundTransfer(msg.sender,_usdtDecimalAmount);
        
    }
    
    
    
}