/**
 *Submitted for verification at BscScan.com on 2021-11-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;


interface BNBYields{
	function getUserDownlineCount(address userAddress) external view returns(uint256[5] memory referrals);
	function getUserAmountOfDeposits(address userAddress) external view returns(uint256);
	function getUserDepositInfo(address userAddress, uint256 index) external view returns(uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish);
}

interface BNBY{
	function balanceOf(address owner) external view returns(uint);
	function transfer(address to, uint value) external returns(bool);
    function transferFrom(address from, address to, uint value) external returns(bool);
    function approve(address spender, uint value) external returns (bool);
}


contract BNBYieldsBonus {
	using SafeMath for uint256;

	BNBYields public bnbYields;
	BNBY public bnbY;

	mapping (address => uint256) internal userClaimed;
	mapping (address => mapping(uint256 => bool)) internal paidDeposits;
	mapping (address => uint256) internal paidReferral;

	uint256 public startDate = 1636900125;

	

	event Claim(address user, uint256 amount);

	constructor(address bnbYieldsAddress, address bnbYAddress) {
		require(bnbYieldsAddress != address(0),"unvalid address");
		require(bnbYAddress != address(0),"unvalid address");

		bnbYields = BNBYields(bnbYieldsAddress);
		bnbY = BNBY(bnbYAddress);
	}

	function getUserBonus(address userAddress) public view returns(uint256,uint256){
		uint256 userDepositCnt = bnbYields.getUserAmountOfDeposits(userAddress);
		uint256 totalBonus=0;

		//deposits
		for(uint256 i=0; i < userDepositCnt; i++){
			if(paidDeposits[userAddress][i] == false){
				(, , uint256 amount, uint256 start,) = bnbYields.getUserDepositInfo(userAddress, i);
				if(start >= startDate){
					if(amount >= 5 ether){
						totalBonus += 10000 ether;
					}else if(amount < 5 ether && amount >= 1 ether){
						totalBonus += 5000 ether;
					}else if(amount < 1 ether && amount >= 0.5 ether){
						totalBonus += 1000 ether;
					}else if(amount < 0.5 ether && amount >= 0.05 ether){
						totalBonus += 100 ether;
					}
				}
			}
		}

		//referrals
		uint256[5] memory referrals = bnbYields.getUserDownlineCount(userAddress);
		if(referrals[0].div(50) > paidReferral[userAddress]){
			totalBonus += ((referrals[0].div(50)).sub(paidReferral[userAddress])).mul(5000 ether);
		}

		return (totalBonus,userClaimed[userAddress]);
	}

	function claim() public{
		uint256 userDepositCnt = bnbYields.getUserAmountOfDeposits(msg.sender);
		uint256 totalBonus=0;

		//deposits
		for(uint256 i=0; i < userDepositCnt; i++){
			if(paidDeposits[msg.sender][i] == false){
				(, , uint256 amount, uint256 start,) = bnbYields.getUserDepositInfo(msg.sender, i);
				if(start >= startDate){
					if(amount >= 5 ether){
						totalBonus += 10000 ether;
					}else if(amount < 5 ether && amount >= 1 ether){
						totalBonus += 5000 ether;
					}else if(amount < 1 ether && amount >= 0.5 ether){
						totalBonus += 1000 ether;
					}else if(amount < 0.5 ether && amount >= 0.05 ether){
						totalBonus += 100 ether;
					}
				}
				paidDeposits[msg.sender][i] = true;
			}
		}

		//referrals
		uint256[5] memory referrals = bnbYields.getUserDownlineCount(msg.sender);
		if(referrals[0].div(50) > paidReferral[msg.sender]){
			totalBonus += ((referrals[0].div(50)).sub(paidReferral[msg.sender])).mul(5000 ether);
			paidReferral[msg.sender] = referrals[0].div(50);
		}

		require(totalBonus > 0 , "zero bonus" );
		require(bnbY.balanceOf(address(this)) >= totalBonus, "contract balance is not enough" );
		bnbY.transfer(msg.sender, totalBonus);
		userClaimed[msg.sender] = userClaimed[msg.sender].add(totalBonus);
		emit Claim(msg.sender, totalBonus);
	}

}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}