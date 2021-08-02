/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a - b;
        require(c <= a, "SafeMath: subtraction overflow");
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function div(uint16 a, uint16 b) internal pure returns (uint16) {
        require(b > 0, "SafeMath: division by zero");
        uint16 c = a / b;
        return c;
    }
}

contract Ownable  {
    address _owner;
    bool public paused;
    event OwnershipTransfer(address indexed oldOwner, address indexed newOwner);

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransfer(_owner, newOwner);
        _owner = newOwner;
    }

    function transfrtOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
        @dev 未暂停时可以调用的修饰符
        */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    /**
        @dev 暂停时可以调用的修饰符
        */
    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() external onlyOwner whenNotPaused {
        paused = true;
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
    }
}


contract IdoCenter is Ownable {
    using SafeMath for uint256;
    uint256 public rate =1000 ;
    uint256 public startTime; //开始时间
    uint256 public endTime; //结束时间
    uint256 public selledTokenTotal ;
    IERC20 idoToken; //idoToken 地址

    uint256 private constant maxLimit = 5*1e15;
    uint256 private constant minLimit = 1*1e15;
    uint256 private constant vipLimit = 2*1e15;
    uint256 private constant tokenTotalNum = 100*10000*1e18; 


    struct Order {
        uint32 createTime; //创建时间
        uint256 amountToken; //获得token数量
        uint256 amountBNB; //支付u数量
    }

    struct User {
        Order[] orders;
        uint256 totalInvestBnb;
        uint256 totalReceivedToken;
    }

    mapping(address => User) public users;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public vip;


    event NewSwap(
        address user,
        uint256 amountToken,
        uint256 amountBNB
    );
    event NewVip(
        address user
    );

     constructor(IERC20 token) public payable {
        paused = false;
        _owner = msg.sender;
        emit OwnershipTransfer(address(0), msg.sender);
        idoToken = token;
    }
    
    function whitelistInvesting() public payable{
        require(whitelist[msg.sender]==true,"you are not in whitelist");
        require(vip[msg.sender] == false,"you are already vip");
        require(msg.value == vipLimit,"Whitelist investment only allows 2 bnb of funds to be invested");
       
        vip[msg.sender]=true;
        emit NewVip(msg.sender);
    }
    
   function idoSwap() public payable{
        uint256 currentTime = getBlockTimestamp();
        require(currentTime >= startTime && currentTime <= endTime,"Not active ido at the current time");
        uint256 amount = msg.value;
        require(amount >= minLimit && amount <= maxLimit,"The investment amount exceeds the limit");
        require(users[msg.sender].totalInvestBnb +amount <= maxLimit,"Total investment is greater than 5 bnb");
        uint256 tokenNum = amount.mul(rate);
        uint256 _tokenBal = idoToken.balanceOf(address(this));
        require(_tokenBal >= tokenNum,"Insufficient contract balance");
        idoToken.transfer(msg.sender,tokenNum);
        selledTokenTotal += tokenNum;
        require(selledTokenTotal <= tokenTotalNum,"selledToken gt totalToken");
        User storage user = users[msg.sender];
        user.totalInvestBnb += amount;
        user.totalReceivedToken += tokenNum;
        user.orders.push(
            Order({
                createTime: uint32(block.timestamp),
                amountToken: tokenNum,
                amountBNB: amount
            })
        );

        emit NewSwap(msg.sender,amount,tokenNum);

}
    function isWhitelist()  external view  returns (bool){
        return whitelist[msg.sender];
    }

    function isViplist()  external view  returns (bool){
        return vip[msg.sender];
    }

    function burnIdoLeftToken() public onlyOwner {
        require(block.timestamp > endTime,"this function must do after endtime");
        uint256 balance = idoToken.balanceOf(address(this));
        idoToken.transfer(address(0),balance);
    }


//判断该用户是否还有资格参与ido
    function isAccessIdo() external view  returns (bool){
        //如果以投资金额大于5，则不再具有资格
        User memory user = users[msg.sender];
        return user.totalInvestBnb < maxLimit;
    }




    function addWhiteList(address[] memory arr) public  onlyOwner{
        for (uint256 i = 0; i < arr.length; i++) {
            whitelist[arr[i]]=true;
        }
    }



    function clearToken(IERC20 token, uint256 amount) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, "Contract asset shortage");
        IERC20(token).transfer(address(msg.sender), amount);
    }


    function clearETHByAmount(uint256 _amount) external onlyOwner {
        (bool result,) = msg.sender.call{value : _amount }("");
        require(result, "Tooth:transfer of ETH failed");
    }


    function showTokenBalance(address _TokenAddress ) external view returns (uint256){
        return IERC20(_TokenAddress).balanceOf(address(this));
    }


    receive() external payable {}


    function aggregateUser()
    public
    view
    returns (
        uint256,
        uint256,
        Order[] memory
    )
    {
        User memory user = users[msg.sender];
        return (user.totalInvestBnb, user.totalReceivedToken, user.orders);
    }
    function getBlockTimestamp() internal  returns (uint256) {
        return block.timestamp;
    }

    function setStartime(uint32 _time) public onlyOwner {
        startTime = _time;
        endTime = _time+ 3 days;
    }

    function updateEndTime(uint32 _time) public onlyOwner {
        endTime = _time;
    }

}