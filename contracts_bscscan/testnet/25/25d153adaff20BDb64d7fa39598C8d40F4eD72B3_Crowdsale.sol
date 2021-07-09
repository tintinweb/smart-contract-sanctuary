/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

pragma solidity ^0.6.12;
interface token {
    
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT License
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

contract Crowdsale is Ownable{
    using SafeMath for uint256;
    
    uint256 public fundingGoal; 
    uint256 public amountRaised; 
    uint256 public deadline; 
    uint256 public price;

    uint256 public claimTime; 
    uint256 public startTime;
    uint256 public lowBuy;
    uint256 public maxBuy;
    bool public useWhitelist;

    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public whitelist;

    event FundTransfer(address backer, uint amount, bool isContribution); 
    
    /**
     * Constrctor function
     *
     * Setup the owner
     */
    function Init(
        uint256 fundingGoalInEthers,       // 众筹eth上限,单位eth个数 
        uint256 deadlineT,        // 众筹结束时间 , 单位时间戳
        uint256 etherCostOfEachToken,      // 一个eth能获得多少代币， 无单位, 公式: 1 eth * 10**18/ token 个数 
        address tokenRewardToken,    // token地址
        uint256 claimT,             // 用户领币时间， 单位时间戳
        uint256 startT,              // 募集开始时间， 单位时间戳
        uint256 lowB,             // 最少购买数量，单位finney
        uint256 maxB,            // 最大购买数量， 单位finney
        bool useWL          // 是否使用白名单   
    )public onlyOwner{
        setPrice(etherCostOfEachToken);
        setOwner(_msgSender());
        setFundingGoal(fundingGoalInEthers);
        setDeadline(deadlineT);
        setTokenReward(tokenRewardToken);
        setClaimTime(claimT);
        setStartTime(startT);
        setMaxBuy(maxB);
        setLowBuy(lowB);
        setUseWhitelist(useWL);
    }
    
    function setWhitelist(address[] calldata accounts, bool isWL)public onlyOwner{
         for(uint256 i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = isWL;
        }
    }
    
    function setUseWhitelist(bool useWL)public onlyOwner{
        useWhitelist = useWL;
    }
    
    function setMaxBuy(uint256 value)public onlyOwner{
        maxBuy = value * 1 finney;
    }
    
    function setLowBuy(uint256 value)public onlyOwner{
        lowBuy = value * 1 finney;
    }
    
    function setPrice(uint256 etherCostOfEachToken)public onlyOwner{
        price = etherCostOfEachToken;
    }
    
    function setOwner(address o)public onlyOwner{
        _owner = o;
    }
    
    function setFundingGoal(uint256 fundingGoalInEthers)public onlyOwner{
        fundingGoal = fundingGoalInEthers * 1 ether;
    }
    
    function setTokenReward(address addressOfTokenUsedAsReward) public onlyOwner{
        tokenReward = token(addressOfTokenUsedAsReward);
    }
    
    function setDeadline(uint256 deadlineT)public onlyOwner{
        deadline = deadlineT;
    }
    
    function setClaimTime(uint256 claimT) public onlyOwner{
        claimTime = claimT;
    }
    
    function setStartTime(uint256 startT) public onlyOwner{
        startTime = startT;
    }
    
    modifier onlyWhitelist(){
        if(useWhitelist){
            require(whitelist[msg.sender], "user not in whitelist!");
        }
        _;
    }

    function walk() payable external onlyWhitelist{
        require(now >= startTime, "Solicitation has not begun");
        require(now < deadline, "Fundraising closed");
        require(balanceOf[msg.sender] < maxBuy, "You have exceeded the maximum raised");

        uint amount = msg.value;
        require(amountRaised.add(amount) < fundingGoal, "More than the total amount raised");
        
        if (balanceOf[msg.sender] == 0){
            require(amount >= lowBuy, "Less than the minimum purchase value");
        }
        
        
        if (balanceOf[msg.sender].add(amount) > maxBuy){
            uint returnAmount = (balanceOf[msg.sender].add(amount)).sub(maxBuy);
            address(uint160(msg.sender)).transfer(returnAmount);
            amount = amount.sub(returnAmount);
        }
        
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        
        amountRaised = amountRaised.add(amount);
        FundTransfer(msg.sender, amount, true);
    }
    
    function getTokenTotal(address o)public view returns(uint256){
        // 获取用户可以领取的token余额
        return balanceOf[o].div(price) * 10 ** uint256(tokenReward.decimals());
    }
    
    function getEthTotal(address o)public view returns(uint256){
        return balanceOf[o];
    }
    
    function claim() public{
        require(balanceOf[msg.sender] > 0, "You did not participate in the subscription!");
        require(now >= claimTime, "It's not time to collect!");
        // 用户获取token
        uint256 total = getTokenTotal(msg.sender);
        tokenReward.transfer(msg.sender, total);
        balanceOf[msg.sender] = 0;
    }
    
    function OwnerSafeWithdrawalEth() public onlyOwner{
        // 取回所有eth
        address(uint160(owner())).transfer(address(this).balance);
    }

    function OwnerSafeWithdrawalToken(address token_address, uint256 amount) public onlyOwner{
        // 取回剩余代币
        token token_t = token(token_address);
        if (amount == 0){
            token_t.transfer(owner(), token_t.balanceOf(address(this)));
            return;
        }
        token_t.transfer(owner(), amount);
    }

    function getNow() public view returns(uint256){
        // 获取当前时间
        return now;
    }
    
    function getNeedContractToken() public view returns(uint256){
        return fundingGoal.div(price);
    }
    
    function setAmountRaised(uint256 raised)public onlyOwner{
        amountRaised = raised;
    }
    
    function setBalanceOf(address o, uint256 amount) public onlyOwner{
        balanceOf[o] = amount;
    }
    
    receive()payable external{}

}