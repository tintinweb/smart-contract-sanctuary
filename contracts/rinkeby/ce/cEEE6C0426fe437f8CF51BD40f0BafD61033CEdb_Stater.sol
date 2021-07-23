/**
 *Submitted for verification at Etherscan.io on 2021-07-23
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

interface IAUR20 {
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

library SafeAUR20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IAUR20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IAUR20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IAUR20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeAUR20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IAUR20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IAUR20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeAUR20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function _callOptionalReturn(IAUR20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeAUR20: low-level call failed");
        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeAUR20: ERC20 operation did not succeed");
        }
    }
}

contract Stater is Ownable {
	using SafeMath for uint;
    using SafeAUR20 for IAUR20;

	struct ProjectInfo {
		uint256 id;
		address _tokenIdo;
		uint256 _startBlock;
		uint256 _endBlock;
		uint256 _offeringAmount;
		uint256 _hardcapIdo;
		address _method;
	}

	event historyBuyToken(
		address buyer,
		uint256 timeBuy,
		uint256 blockBuy,
		uint256 id,
		uint256 amount
	);
	
	event historyHarvest(
		address claimer,
		uint256 timeBuy,
		uint256 blockBuy,
		uint256 id,
		uint256 amount
	);	

	// Project Information
	mapping(uint256 => address) method; // Get method deposit
	mapping(uint256 => address) admin; // Get admin in project
	mapping(uint256 => ProjectInfo) public findProjectInfo;
	mapping(uint256 => uint256) public raisingAmount;
	ProjectInfo[] public projectInfo;
	mapping(uint256 => bool) public boolHarvest;

	//User Information
	mapping(address => mapping(uint256 => uint256)) public userBuyIdo;
	mapping(address => mapping(uint256 => bool)) public boolUserHarvest;

	function getProjectInfo() public view returns(ProjectInfo[] memory) {
		return projectInfo;
	}

	modifier onlyAdmin(uint256 _adminId) {
		require(msg.sender == admin[_adminId], "admin: wut?");
		_;
  	}

	function changeTokenAddress(uint256 _tokenId, address _tokenOldAddress, address _tokenAddress) public onlyOwner {
		require(findProjectInfo[_tokenId]._tokenIdo == _tokenOldAddress);
		findProjectInfo[_tokenId]._tokenIdo = _tokenAddress;
	}

	function setOfferingAmount(uint256 _tokenId, address _tokenAddress, uint256 _amount) public onlyOwner {
		require (_amount > 0, 'need _amount > 0');
		require(findProjectInfo[_tokenId]._tokenIdo == _tokenAddress);
		findProjectInfo[_tokenId]._offeringAmount = _amount;
	}

	function setStartIdo(uint256 _tokenId, address _tokenAddress, uint256 _startBlock) public onlyOwner {
		require(findProjectInfo[_tokenId]._endBlock > _startBlock, "time error");
		require(findProjectInfo[_tokenId]._tokenIdo == _tokenAddress);
		findProjectInfo[_tokenId]._startBlock = _startBlock;
	}

	function setEndIdo(uint256 _tokenId, address _tokenAddress, uint256 _endBlock) public onlyOwner {
		require(findProjectInfo[_tokenId]._startBlock < _endBlock, "time error");
		require(findProjectInfo[_tokenId]._tokenIdo == _tokenAddress);
		findProjectInfo[_tokenId]._endBlock = _endBlock;
	}

	function createIdo(
		address _tokenIdo,
		uint256 _startBlock,
		uint256 _endBlock,
		uint256 _offeringAmount,
		uint256 _hardcapIdo,
		address _admin,
		address _method
	) public onlyOwner {
		require(_startBlock > block.number && _endBlock > _startBlock, 'time error');
		uint256 lengthProject = projectInfo.length;
		projectInfo.push(ProjectInfo( lengthProject, _tokenIdo, _startBlock, _endBlock, _offeringAmount, _hardcapIdo, _method));
		findProjectInfo[lengthProject] = ProjectInfo(lengthProject, _tokenIdo, _startBlock, _endBlock, _offeringAmount, _hardcapIdo, _method);
		admin[lengthProject] = _admin;
		method[lengthProject] = _method;
	}

	function onOrOffHarvest(uint256 _tokenId, address _tokenAddress) public onlyOwner {
		require(findProjectInfo[_tokenId]._tokenIdo == _tokenAddress);
		boolHarvest[_tokenId] = !boolHarvest[_tokenId];
	}

	function buyToken(uint256 _tokenId, uint256 _amount) public {
		require(findProjectInfo[_tokenId]._startBlock > block.number && block.number < findProjectInfo[_tokenId]._endBlock, 'not ido time');
		require (_amount > 0, 'need _amount > 0');
		raisingAmount[_tokenId] = raisingAmount[_tokenId].add(_amount);
		userBuyIdo[msg.sender][_tokenId] = userBuyIdo[msg.sender][_tokenId].add(_amount);
		// boolUserHarvest[msg.sender][_tokenId] = false;
		IAUR20 methodBuyToken = IAUR20(method[_tokenId]);
		methodBuyToken.safeTransferFrom(msg.sender, admin[_tokenId] , _amount);

		emit historyBuyToken(
			msg.sender,
			block.timestamp,
			block.number,
			_tokenId,
			_amount
		);
	}

	function harvest(uint256 _tokenId) public {
		require (block.number > findProjectInfo[_tokenId]._endBlock, 'not harvest time');
		require (boolHarvest[_tokenId] == true, 'not harvest');
		require (userBuyIdo[msg.sender][_tokenId] > 0 && boolUserHarvest[msg.sender][_tokenId] == false, 'have you participated?');
		IAUR20 tokenTransfer = IAUR20(findProjectInfo[_tokenId]._tokenIdo);
		uint256 totalRaising = raisingAmount[_tokenId];
		uint256 amountBuy = userBuyIdo[msg.sender][_tokenId];
		uint256 offeringAmount = findProjectInfo[_tokenId]._offeringAmount;		
		uint256 amountTransfer = offeringAmount.mul(amountBuy).div(totalRaising);
		uint256 amount = amountTransfer > getBalanceToken(findProjectInfo[_tokenId]._tokenIdo) ? getBalanceToken(findProjectInfo[_tokenId]._tokenIdo) : amountTransfer;
		tokenTransfer.safeTransfer(msg.sender, amount);
		boolUserHarvest[msg.sender][_tokenId] = true;
		emit historyHarvest(
			msg.sender,
			block.timestamp,
			block.number,
			_tokenId,
			amount
		);

	}

	function getBalanceToken(address _address) public view returns( uint256 ) {
		IAUR20 token = IAUR20(_address);
		return token.balanceOf(address(this));
	}

}