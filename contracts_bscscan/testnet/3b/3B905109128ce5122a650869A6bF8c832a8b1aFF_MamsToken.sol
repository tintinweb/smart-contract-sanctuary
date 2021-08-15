// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";
import "Ownable.sol";

contract MamsToken is ERC20, Ownable {

	//list of distributed balance of each address to calculate restricted amount, In Wei
	mapping(address => uint256[3]) private distBalances;

	// total distributed token amount, In Wei
	uint256 public distributed;

	uint256 public PublicofferingTime1 = 1629820800;  //第一轮启动时间
	uint256 public PublicofferingTime2 = 1630425600;  //第二轮启动时间
	uint256 public PublicofferingTime3 = 1630857600;  //第三轮启动时间
	uint256 public PublicofferingTimeend = 1631375999;  //公募结束时间

	/**
	 *	1 mamo token (10**18) crowdsale price, in wei
	 *  if 1mamo = 0.5busd then usdCostPerTokenInWei = 10 ** 18 * 0.5
	 */
	uint256 public usdCostPerTokenInWei;

	// max distribute amount per account, In Wei
	uint256 public maxDistAmount;
	// max distribute amount for all, In Wei, 5% of totalSupply
	uint256 public totalMaxDistAmount = 200000000000 * 10 ** 16 * 5;

	// busd contract address on bsc
	address public busdAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
	// usdt contract address on bsc
	address public usdtAddress = 0x55d398326f99059fF775485246999027B3197955;

	//constructor
	constructor() ERC20("Mams Token", "Mams") Ownable() {
		//mint to contract owner
		_mint(msg.sender, 200000000000 * 10 ** 18 - totalMaxDistAmount);
		//todo, if more EOA address need to mint token, add them here
	}

	/**
	 *	set mamo token (10**18) crowdsale price, in wei
	 *  if 1mamo = 0.5busd then usdCostPerTokenInWei = 0.5 * 10 ** 18
	 */
	function setCrowdSalePrice(uint256 price) public onlyOwner {
		require(price > 0);
		usdCostPerTokenInWei = price;
	}

	/**
	 *  _amountInWei token distributed amount
	 */
	function distribute(uint256 _amountInWei, address _to) private {

		if(block.timestamp < PublicofferingTime2){
			require(distBalances[_to][0] <= 11764706);
			require(distributed + _amountInWei <= totalMaxDistAmount);
			distributed = distributed + _amountInWei;
			_mint(_to, _amountInWei);
			distBalances[_to][0] = distBalances[_to][0] + _amountInWei;
		}else if(block.timestamp < PublicofferingTime3){
			require(distBalances[_to][1] <= 11764706);//修改二期最高限额
			require(distributed + _amountInWei <= totalMaxDistAmount);
			distributed = distributed + _amountInWei;
			_mint(_to, _amountInWei);
			distBalances[_to][1] = distBalances[_to][1] + _amountInWei;
		}else if(block.timestamp < PublicofferingTimeend){
			require(distBalances[_to][2] <= 11764706);//修改一期最高限额
			require(distributed + _amountInWei <= totalMaxDistAmount);
			distributed = distributed + _amountInWei;
			_mint(_to, _amountInWei);
			distBalances[_to][2] = distBalances[_to][2] + _amountInWei;
		}
	}

	/**
	 *  _amountInWei busd amount
	 */
	function crowdSaleWithBusd(uint256 _amountInWei) public {
		require(block.timestamp <= PublicofferingTimeend);
		IERC20(busdAddress).transferFrom(msg.sender, owner(), _amountInWei);
		
		uint tokenAmountInWei = _amountInWei / usdCostPerTokenInWei * 10**18;
		distribute(tokenAmountInWei, msg.sender);
	}

	/**
	 *  _amountInWei usdt amount
	 */
	function crowdSaleWithUsdt(uint256 _amountInWei) public {
		require(block.timestamp <= PublicofferingTimeend);
		IERC20(usdtAddress).transferFrom(msg.sender, owner(), _amountInWei);

		uint tokenAmountInWei = _amountInWei / usdCostPerTokenInWei * 10**18;
		distribute(tokenAmountInWei, msg.sender);
	}

	/**
	 *  ERC 20 Standard Token interface transfer function
	 *
	 *  Prevent transfers until freeze period is over.
	 */
	function transfer(address _to, uint256 _value) public override returns (bool) {

		//calculate free amount
		if (block.timestamp < 1644335999) {
			uint _freeAmount = freeAmount(msg.sender);
			if (_freeAmount < _value) {
				return false;
			}
		}
		_transfer(msg.sender, _to, _value);
		return true;
	}

	function freeAmount(address user) private view returns (uint256) {
		if (block.timestamp >= PublicofferingTimeend + 150 days) {
			//距离最后轮公募时间超过150天后函数内容不再执行
			return balanceOf(user);
		}
		uint[] memory monthDiff = new uint[](3);
		uint[] memory unrestricted = new uint[](3);
		uint256 amount;
		if (block.timestamp < PublicofferingTime1 + 30 days) {    //距离第一次公募时间少于30天就不进行计算
			monthDiff[0] = 0;
			monthDiff[1] = 0;
			monthDiff[2] = 0;
			unrestricted[0] = distBalances[user][0] / 2 ;
			unrestricted[1] = distBalances[user][1] / 2 ;
			unrestricted[2] = distBalances[user][2] / 2 ;
		} else {
			monthDiff[0] = (block.timestamp - PublicofferingTime1) / 30 days;   //计算第一轮公募分发次数
			monthDiff[1] = (block.timestamp - PublicofferingTime2) / 30 days;   //计算第二轮公募分发次数
			monthDiff[2] = (block.timestamp - PublicofferingTime3) / 30 days;   //计算第三轮公募分发次数
			
			unrestricted[0] = distBalances[user][0] / 2 + distBalances[user][0] * monthDiff[0] / 10;
			unrestricted[1] = distBalances[user][1] / 2 + distBalances[user][1] * monthDiff[1] / 10;
			unrestricted[2] = distBalances[user][2] / 2 + distBalances[user][2] * monthDiff[2] / 10;
		}
		if (unrestricted[0] > distBalances[user][0]) {
			unrestricted[0] = distBalances[user][0];
		}
		if (unrestricted[1] > distBalances[user][1]) {
			unrestricted[1] = distBalances[user][1];
		}
		if (unrestricted[2] > distBalances[user][2]) {
			unrestricted[2] = distBalances[user][2];
		}
		//5) calculate total free amount including those not from distribution
		// wtf? confuse about the algorithm here
		if (unrestricted[0] + (balanceOf(user) - distBalances[user][1] - distBalances[user][2]) < distBalances[user][0] && unrestricted[1] + (balanceOf(user)- distBalances[user][0] - distBalances[user][2])< distBalances[user][1] && unrestricted[2] + (balanceOf(user)- distBalances[user][0] - distBalances[user][1])< distBalances[user][2]) {
			amount = 0;
		} else {
			amount = unrestricted[0] + unrestricted[1] + unrestricted[2] + balanceOf(user) - distBalances[user][0] - distBalances[user][1] - distBalances[user][2];
		}

		return amount;
	}

	function getFreeAmount(address user) private view returns (uint256) {
		uint256 amount = freeAmount(user);
		return amount;
	}

	function getRestrictedAmount(address user) private view returns (uint256) {
		uint256 amount = balanceOf(user) - freeAmount(user);
		return amount;
	}

	/**
	 * ERC 20 Standard Token interface transfer function
	 *
	 * Prevent transfers until freeze period is over.
	 */
	function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
		//same as above. Replace this line with the following if you want to protect against wrapping uints.
		
		if (block.timestamp < 1644335999) {
			uint _freeAmount = freeAmount(_from);
			if (_freeAmount < _value) {
				return false;
			}
		}

		_transfer(_from, _to, _value);
		uint256 currentAllowance = allowance(_from, msg.sender);

		require(currentAllowance >= _value, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(_from, msg.sender, currentAllowance - _value);
        }
        return true;
	}
}