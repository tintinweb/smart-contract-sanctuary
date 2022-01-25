/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

pragma solidity 0.5.8;
 
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

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        // 空字符串hash值
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;  
        //内联编译（inline assembly）语言，是用一种非常底层的方式来访问EVM
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
 
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;
 
    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
 
    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
 
    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),"SafeERC20: approve from non-zero to non-zero allowance");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
 
    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
 
    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
 
    function callOptionalReturn(ERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
 
interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract Pledge {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
 
    address private owner;
 
    mapping(address => PledgeOrder) _orders;

	uint256 childrenDaysAmount = 200000000000000000000;
 
    ERC20 public _ParentToken;
    ERC20 public _ChildrenToken;
    ERC20 public _LPToken;
    KeyFlag[] keys;
 
    uint256 _totalPledegAmount;

    struct PledgeOrder {
        bool isExist;
        uint256 token;
        uint256 parentProfitToken;
        uint256 childrenProfitToken;
        uint256 index;
    }
 
    struct KeyFlag {
        address key;
        bool isExist;
    }
 
	//lp合约地址
	//母币合约地址
	//子币合约地址
    constructor (
        address lpAddress,
		address pAddress,
        address cpAddress
    ) 
        public 
    {
        _LPToken = ERC20(lpAddress);
        _ParentToken = ERC20(pAddress);
        _ChildrenToken = ERC20(cpAddress);
        owner = msg.sender;
    }
	
	//质押lp
    function pledgeToken(uint256 _amount) public{
        require(address(msg.sender) == address(tx.origin), "no contract");
		_LPToken.transferFrom(msg.sender, address(this), _amount);
        if(_orders[msg.sender].isExist==false){
            keys.push(KeyFlag(msg.sender, true));
            createOrder(_amount,keys.length.sub(1));
        }else{
            PledgeOrder storage order=_orders[msg.sender];
            order.token=order.token.add(_amount);
            keys[order.index].isExist=true;
        }
        _totalPledegAmount=_totalPledegAmount.add(_amount);
    }
 
    function createOrder(uint256 trcAmount,uint256 index) private {
        _orders[msg.sender]=PledgeOrder(
            true,
            trcAmount,
            0,
            0,
            index
        );
    }
 
	//分配收益
    function profit() public onlyOwner{
        require(_totalPledegAmount>0, "no pledge");
		uint parentBalance = _ParentToken.balanceOf(address(this));
		uint childrenBalance = _ChildrenToken.balanceOf(address(this));
        for(uint i = 0; i < keys.length; i++) {
            if(keys[i].isExist == true){
                PledgeOrder storage order=_orders[keys[i].key];
                order.parentProfitToken=order.parentProfitToken.add(order.token.mul(parentBalance).div(_totalPledegAmount));
				if(childrenBalance >= childrenDaysAmount){
					order.childrenProfitToken=order.childrenProfitToken.add(order.token.mul(childrenDaysAmount).div(_totalPledegAmount));
				}
            }
        }
    }
 
	//提取收益
    function takeProfit() public {
        require(address(msg.sender) == address(tx.origin), "no contract");
        PledgeOrder storage order=_orders[msg.sender];
        uint256 ppt = order.parentProfitToken;
        order.parentProfitToken = order.parentProfitToken.sub(ppt);
        _ParentToken.safeTransfer(address(msg.sender), ppt);
        uint256 cpt = order.childrenProfitToken;
        order.childrenProfitToken = order.childrenProfitToken.sub(cpt);
        _ChildrenToken.safeTransfer(address(msg.sender), cpt);
    }
 
	//提取本金
    function takeAllToken() public {
        require(address(msg.sender) == address(tx.origin), "no contract");
        PledgeOrder storage order = _orders[msg.sender];
        require(order.token > 0,"no order");
        keys[order.index].isExist = false;
        uint256 takeAmount = order.token;
        order.token= 0 ;
        _totalPledegAmount = _totalPledegAmount.sub(takeAmount);
        _LPToken.safeTransfer(address(msg.sender), takeAmount);
    }
 
 	//查询质押数量
    function getPledgeToken(address tokenAddress) public view returns(uint256) {
        require(address(msg.sender) == address(tx.origin), "no contract");
        PledgeOrder memory order=_orders[tokenAddress];
        return order.token;
    }
 
	//查询母币收益
    function getParentProfitToken(address tokenAddress) public view returns(uint256) {
        require(address(msg.sender) == address(tx.origin), "no contract");
        PledgeOrder memory order=_orders[tokenAddress];
        return order.parentProfitToken;
    }

	//查询子币收益
	function getChildrenProfitToken(address tokenAddress) public view returns(uint256) {
        require(address(msg.sender) == address(tx.origin), "no contract");
        PledgeOrder memory order=_orders[tokenAddress];
        return order.childrenProfitToken;
    }
 

	//查询所有人质押总量
    function getTotalPledge() public view returns(uint256) {
        require(address(msg.sender) == address(tx.origin), "no contract");
        return _totalPledegAmount;
    }

    function changeOwner(address paramOwner) public onlyOwner {
        require(paramOwner != address(0));
		owner= paramOwner;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
 
    function getOwner() public view returns (address) {
        return owner;
    }
 
    function nowTime() public view returns (uint256) {
        return block.timestamp;
    }

	//提现母币
	function withdrawParentToken(address receiver, uint amount) public onlyOwner payable {
        uint balance = _ParentToken.balanceOf(address(this));
        if (amount == 0) {
            amount = balance;
        }
        require(amount > 0 && balance >= amount, "bad amount");
        _ParentToken.transfer(receiver, amount);
    }

	//提现子币
	function withdrawChildrenToken(address receiver, uint amount) public onlyOwner payable {
        uint balance = _ChildrenToken.balanceOf(address(this));
        if (amount == 0) {
            amount = balance;
        }
        require(amount > 0 && balance >= amount, "bad amount");
        _ChildrenToken.transfer(receiver, amount);
    }
}