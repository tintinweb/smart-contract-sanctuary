/**
 *Submitted for verification at BscScan.com on 2022-01-20
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function mint(address account, uint amount) external;
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


library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}("");
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
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
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

contract Box{
    using SafeMath for uint256;

    

	IERC20 public usdt = IERC20(0x1630e1F838D33f3f57F319c5AE10700Bd45c87fA);
    IERC20 public pizza = IERC20(0x629AEfbA09b3691e1cd2fE3AeD2C65afcE18727e);
   
    address public wallet = 0x4127685C2946EF891Def795da039D127907A5907;
	uint256 public minBrokerage = 300 * 10 **18;

    struct SaleInfo{
        bool status;
        uint256 pizzaTotalAmount;
        uint256 maxUsdtAmount;
        uint256 usdtRate;       
        uint256 pizzaRate; 
		uint256 endSaletTime;
		uint256 sellPizzaAmount;
		uint256 invitationreward;
		uint256 maxPurchases;
		uint256 twoPeriodTime;
		uint256 threePeriodTime;
    }
    SaleInfo public saleMap;
	
	struct UserInfo{
		uint256 brokerage;
		uint256 purchases;
		uint256 usdtAmount;
		address leader;
		uint256 installmentTwo;
		uint256 installmentThree;
		uint256 invitations;
		//address[] underling;
	}
	mapping(address => UserInfo) public userMap;


    mapping(address => bool) public manager;
    
    mapping(address => bool) public whitelist;

    event Plan(address user, uint256 usdtAmount);
	event Withdrawal(address user, uint256 pizzaAmount);

    constructor() public {
        manager[msg.sender] = true;
       _setSaleMap(true, 30000000 * 10 ** 18, 1000 *10 ** 18, 1, 100,1643126400 ,50 * 10 ** 18, 3 ,1645804800,1648224000);
	}
    
    receive() external payable {

	}
    
    function plan(uint256 _usdtAmount, address _leader) public{
        require(saleMap.status,"This order is not opened");
        require(saleMap.maxPurchases > userMap[msg.sender].purchases,"run out");
		require(saleMap.maxUsdtAmount >= userMap[msg.sender].usdtAmount.add(_usdtAmount),"Insufficient quota");
		require(saleMap.endSaletTime >= block.timestamp,"time expires");
		require(saleMap.pizzaTotalAmount > saleMap.sellPizzaAmount,"Not enough");
				
        usdt.transferFrom(msg.sender, wallet, _usdtAmount);
        uint256 pizzaAmount = _usdtAmount.div(saleMap.usdtRate).mul(saleMap.pizzaRate);
		
		uint256 installmentFirst = pizzaAmount.mul(50).div(100);
		userMap[msg.sender].installmentTwo = userMap[msg.sender].installmentTwo.add(pizzaAmount.mul(25).div(100));
		userMap[msg.sender].installmentThree = userMap[msg.sender].installmentThree.add(pizzaAmount.mul(25).div(100));	
		
		
		handling(msg.sender,_leader);
		userMap[msg.sender].purchases = userMap[msg.sender].purchases.add(1);
		userMap[msg.sender].usdtAmount = userMap[msg.sender].usdtAmount.add(_usdtAmount);
		saleMap.sellPizzaAmount = saleMap.sellPizzaAmount.add(pizzaAmount);
		
		pizza.transfer(msg.sender,installmentFirst);   
		emit Withdrawal(msg.sender,installmentFirst);
        emit Plan(msg.sender, _usdtAmount);

       
    }

	function handling(address _from, address _leader) internal {
       
        if(userMap[_from].leader == address(0) && _leader != address(0) && _leader != _from){
            userMap[_from].leader = _leader;
        }
        if(userMap[_from].leader != address(0)){
			userMap[userMap[_from].leader].brokerage = userMap[userMap[_from].leader].brokerage.add(saleMap.invitationreward);
			userMap[userMap[_from].leader].invitations = userMap[userMap[_from].leader].invitations.add(1);
        }        
       
    }
	
	function installmentForTwo() public{
		require(block.timestamp >= saleMap.twoPeriodTime,"time has not come");
		uint256 bal = userMap[msg.sender].installmentTwo;
		userMap[msg.sender].installmentTwo = 0;
		pizza.transfer(msg.sender,bal);
		emit Withdrawal(msg.sender, bal);
	}
	
	function installmentForThree() public{
		require(block.timestamp >= saleMap.threePeriodTime,"time has not come");
		uint256 bal = userMap[msg.sender].installmentThree;
		userMap[msg.sender].installmentThree = 0;
		pizza.transfer(msg.sender,bal);
		emit Withdrawal(msg.sender, bal);
	}
	

	function withdrawal() public{
		require( userMap[msg.sender].brokerage >= minBrokerage,"too low");
		uint256 bal = userMap[msg.sender].brokerage;
		userMap[msg.sender].brokerage = 0;
		pizza.transfer(msg.sender,bal);
		emit Withdrawal(msg.sender, bal);
	
	}
	
    function setSaleMap( bool _status, 
						uint256 _pizzaTotalAmount, 
						uint256 _maxUsdtAmount, 
						uint256 _usdtRate, 
						uint256 _pizzaRate,
						uint256 _endSaletTime,
						uint256 _invitationreward,
						uint256 _maxPurchases,
						uint256 _TwoPeriodTime,
						uint256 _threePeriodTime								
						)external onlyOwner{
			
		_setSaleMap(_status,_pizzaTotalAmount,_maxUsdtAmount,_usdtRate,_pizzaRate,_endSaletTime,_invitationreward,_maxPurchases,_TwoPeriodTime,_threePeriodTime);
	}


    function _setSaleMap( bool _status, 
						uint256 _pizzaTotalAmount, 
						uint256 _maxUsdtAmount, 
						uint256 _usdtRate, 
						uint256 _pizzaRate,
						uint256 _endSaletTime,
						uint256 _invitationreward,
						uint256 _maxPurchases,
						uint256 _twoPeriodTime,
						uint256 _threePeriodTime								
						)internal{
        saleMap.status = _status;
		saleMap.pizzaTotalAmount = _pizzaTotalAmount;
		saleMap.maxUsdtAmount = _maxUsdtAmount;
		saleMap.usdtRate = _usdtRate;
		saleMap.pizzaRate = _pizzaRate;
		saleMap.endSaletTime = _endSaletTime;
		saleMap.invitationreward = _invitationreward;
		saleMap.maxPurchases = _maxPurchases;
		saleMap.twoPeriodTime = _twoPeriodTime;
		saleMap.threePeriodTime = _threePeriodTime;
    } 

    function setWallet(address _wallet)external onlyOwner{
        wallet = _wallet;
    }

    function setMinBrokerage(uint256 _minBrokerage) external onlyOwner{
        minBrokerage = _minBrokerage;
    }
    
    function withdrawStuckTokens(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }
    
    function withdrawalETH() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

  
        
    modifier onlyOwner {
        require(manager[msg.sender] == true);
        _;
    }
}