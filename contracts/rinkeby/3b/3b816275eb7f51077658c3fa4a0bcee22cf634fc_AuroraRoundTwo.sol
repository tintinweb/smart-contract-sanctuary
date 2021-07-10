/**
 *Submitted for verification at Etherscan.io on 2021-07-10
*/

pragma solidity ^0.8.4; 
pragma experimental ABIEncoderV2;
 
library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	}
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}
	function sub(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
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
	function div(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;
		return c;
	}
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return mod(a, b, "SafeMath: modulo by zero");
	}
	function mod(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes memory) {
		this; 
		return msg.data;
	}
}

library Address {	
	function isContract(address account) internal view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}
	function sendValue(address payable recipient, uint256 amount) internal {
		require(
			address(this).balance >= amount,
			"Address: insufficient balance"
		);
		(bool success, ) = recipient.call{ value: amount }("");
		require(
			success,
			"Address: unable to send value, recipient may have reverted"
		);
	}
	function functionCall(address target, bytes memory data)
		internal
		returns (bytes memory)
	{
		return functionCall(target, data, "Address: low-level call failed");
	}

	function functionCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		return _functionCallWithValue(target, data, 0, errorMessage);
	}
	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value
	) internal returns (bytes memory) {
		return
			functionCallWithValue(
				target,
				data,
				value,
				"Address: low-level call with value failed"
			);
	}
	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(
			address(this).balance >= value,
			"Address: insufficient balance for call"
		);
		return _functionCallWithValue(target, data, value, errorMessage);
	}

	function _functionCallWithValue(
		address target,
		bytes memory data,
		uint256 weiValue,
		string memory errorMessage
	) private returns (bytes memory) {
		require(isContract(target), "Address: call to non-contract");
		(bool success, bytes memory returndata) =
			target.call{ value: weiValue }(data);
		if (success) {
			return returndata;
		} else {
			if (returndata.length > 0) {
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

contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);
	constructor() public{
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
		require(
			newOwner != address(0),
			"Ownable: new owner is the zero address"
		);
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount)
		external
		returns (bool);
	function allowance(address owner, address spender)
		external
		view
		returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);
	function mint(address account, uint256 amount) external returns (bool);
	function burn(address account, uint256 amount) external returns (bool);
	function addOperator(address minter) external returns (bool);
	function removeOperator(address minter) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract AuroraRoundTwo  is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
	IERC20 public tokenUsdt; 
	IERC20 public tokenAur;
	uint public usdtDecimal;
	uint public aurDecinal;
    uint public price = 40000;
	uint public thelowestquantitybuytogetbonus = 500000000;
	bool public offbuy;
	bool public openclaim;
	address addressreceive;
	address public addressburn = 0x0000000000000000000000000000000000000001;
	address addressmint = 0x0000000000000000000000000000000000000000;

	event HistoryBuyToken(
		uint timebuy,
		uint blockbuy,
		uint usdtbuy,
		uint aurbuy
	);
	
	event HistoryClaimToken(
		uint timebuy,
		uint blockbuy,
		uint aurbuy
	);	

	mapping(address => uint) public totalAur;
	mapping(address => uint) public totalUsdt;
	mapping(address => address) public mappingsponsor;
	mapping(address => bool) public boolsponsor;
    constructor( address _tokenUsdt ,address _tokenAur,  address _addressreceive, uint _usdtDecimal, uint _aurDecinal) public {
		tokenUsdt = IERC20(_tokenUsdt); // Token USDT
		usdtDecimal = _usdtDecimal;
		aurDecinal = _aurDecinal;
		tokenAur = IERC20(_tokenAur); // Token AUR
		addressreceive = _addressreceive;
	}

	function AddAddressReceive(address _address) public onlyOwner {
		addressreceive = _address;
	}

	function OnOrOffBuyToken() public onlyOwner {
		offbuy = !offbuy;
	}

	function OpenOrCloseClaimToken() public onlyOwner {
		openclaim = !openclaim;
	}

	function ClaimToken() public {
		require(openclaim, "Not open yet");
		uint balanceclaim = totalAur[msg.sender];
		tokenAur.mint(msg.sender, balanceclaim);
		totalAur[msg.sender] =0;
		emit HistoryClaimToken(
			block.timestamp,
			block.number,
			balanceclaim
		);
	}

	function BuyTokenAur(address _sponsor, uint _balance) public {
		require(!offbuy, "Ended");
		address sponsor;
		if(mappingsponsor[msg.sender] != addressmint){
			sponsor = mappingsponsor[msg.sender];
		}else if (_sponsor == msg.sender || mappingsponsor[_sponsor] == msg.sender) {
			sponsor = addressburn;
		} else {
			mappingsponsor[msg.sender] = sponsor = _sponsor;
		}
		tokenUsdt.safeTransferFrom(msg.sender, addressreceive , _balance);
		totalUsdt[msg.sender] += _balance;
		if (totalUsdt[sponsor] >= thelowestquantitybuytogetbonus) {
			uint bonus = _balance.mul(5).mul(uint(10**aurDecinal)).div(100).div(uint(price));
			tokenAur.mint(sponsor, bonus);
		}
		uint receiveAur = _balance.mul(uint(10**aurDecinal)).div(uint(price));
		totalAur[msg.sender] += receiveAur;
		emit HistoryBuyToken(
			block.timestamp,
			block.number,
			_balance,
			receiveAur
		);
	}
}