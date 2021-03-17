/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

pragma solidity 0.8.0;

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

contract NEST36Dao{
    
    mapping(address=>uint256) maxValue;
    mapping(address=>uint256) price;
    mapping(address=>uint256) allValue;
    mapping(address=>uint256) totalETHReward;
    
    
    constructor () public {}
    
    // 回购
    function redeem(address ntokenAddress, uint amount) public payable {
        IERC20(ntokenAddress).transferFrom(address(msg.sender), address(this), amount);
        allValue[ntokenAddress] = allValue[ntokenAddress] + amount;
        uint256 eth = amount * 1 ether / price[ntokenAddress];
        totalETHReward[ntokenAddress] = totalETHReward[ntokenAddress] - eth;
        payable(address(uint160(msg.sender))).transfer(eth);
        
    }
    // 当前可回购
    function quotaOf(address ntokenAddress) public view returns (uint) {
        return 300000 ether;
    }
    // 最大可回购 
    function getMaxValue(address nToken) public view returns(uint256){
        return maxValue[nToken];
    }
    // 锁定总量
    function getAllValue(address nToken) public view returns(uint256){
        return allValue[nToken];
    }
    // 设置最大可回购 
    function setMaxValue(address nToken, uint256 num) public {
        maxValue[nToken] = num;
    }
    // 设置价格
    function setPrice(address nToken, uint256 num) public {
        price[nToken] = num;
    }
    // 
    function totalETHRewards(address nToken) public view returns (uint) {
        return totalETHReward[nToken];
    }
    
    function addETH(address nToken) public payable {
        totalETHReward[nToken] = totalETHReward[nToken] + msg.value;
    }
    
}