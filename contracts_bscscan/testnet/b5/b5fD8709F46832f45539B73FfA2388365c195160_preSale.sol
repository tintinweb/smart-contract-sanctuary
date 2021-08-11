/**
 *Submitted for verification at BscScan.com on 2021-08-11
*/

pragma solidity ^0.8.4;

//SPDX-License-Identifier: MIT Licensed

interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}


contract preSale{
    
    using SafeMath for uint256;
    using Address for address;
    
    IBEP20 public token;
    AggregatorV3Interface public priceFeedBnb;
    
    address payable public owner;
    
    uint256 public tokenPerUsd;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public preSaleTime;
    uint256 public soldToken;
    uint256 public amountRaised;
    uint256 public refPercent;

    bool public refType;
    
    mapping(address => uint256) public balances;
    mapping(address => uint256) public refBalance;


    modifier onlyOwner() {
        require(msg.sender == owner,"BEP20: Not an owner");
        _;
    }
    
    event BuyToken(address _user, uint256 _amount);

    
    constructor(address _owner, IBEP20 _token) {
        owner = payable(_owner); 
        token = _token;
        priceFeedBnb = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
        tokenPerUsd = 20;
        minAmount = 0.01 ether;
        maxAmount = 5 ether;
        preSaleTime = block.timestamp + 30 days;
        refPercent = 10;
    }
    
    receive() external payable{}
    
    function getLatestPriceBnb() public view returns (uint256) {
        (,int price,,,) = priceFeedBnb.latestRoundData();
        return uint256(price).div(1e8);
    }


    // to buy token during preSale time => for web3 use
    function buyToken(address payable _referrer) payable public {
        require(!address(msg.sender).isContract(),"BEP20: contract can not buy");
        require(_referrer != address(0) && _referrer != msg.sender,"BEP20: invalid referrer");
        
        uint256 numberOfTokens = usdToToken(msg.value);
        uint256 maxToken = usdToToken(maxAmount);      
        
        require(msg.value >= minAmount && msg.value <= maxAmount,"BEP20: Amount not correct");
        require(numberOfTokens.add(token.balanceOf(msg.sender)) <= maxToken,"BEP20: Amount exceeded max limit");
        require(block.timestamp < preSaleTime,"BEP20: PreSale over");
        require(token.balanceOf(_referrer) > 0,"referrer is not LC holder");
        
        token.transferFrom(owner, msg.sender, numberOfTokens);
        if(refType){
            _referrer.transfer(msg.value.mul(refPercent).div(100));
            refBalance[msg.sender] = refBalance[msg.sender].add(msg.value.mul(refPercent).div(100));
        }else{
            token.transferFrom(owner, _referrer, numberOfTokens.mul(refPercent).div(100));
        }
        soldToken = soldToken.add(numberOfTokens);
        amountRaised = amountRaised.add(msg.value);
        
        emit BuyToken(msg.sender, balances[msg.sender]);
    }
    
    // to check number of token for given BNB
    function usdToToken(uint256 _amount) public view returns(uint256){
        uint256 bnbToUsd = _amount.mul(getLatestPriceBnb());
        uint256 numberOfTokens = bnbToUsd.mul(tokenPerUsd);
        return numberOfTokens;
    }
    
    // to change Price of the token
    function changePrice(uint256 _tokenPerUsd) external onlyOwner{
        tokenPerUsd = _tokenPerUsd;
    }
    
    function setAmountLimits(uint256 _minAmount, uint256 _maxAmount) external onlyOwner{
        minAmount = _minAmount;
        maxAmount = _maxAmount;
    }
    
    function setpreSaleTime(uint256 _time) external onlyOwner{
        preSaleTime = _time;
    }
    
    function setRefPercent(uint256 _percent, bool _type) external onlyOwner{
        refPercent = _percent;
        refType = _type;
    }
    
    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner{
        owner = _newOwner;
    }
    
    // to draw funds for liquidity
    function transferFunds(uint256 _value) external onlyOwner returns(bool){
        owner.transfer(_value);
        return true;
    }
    
    function getCurrentTime() public view returns(uint256){
        return block.timestamp;
    }
    
    function contractBalanceBnb() external view returns(uint256){
        return address(this).balance;
    }
    
    function getContractTokenBalance() external view returns(uint256){
        return token.allowance(owner, address(this));
    }
    
}

 
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