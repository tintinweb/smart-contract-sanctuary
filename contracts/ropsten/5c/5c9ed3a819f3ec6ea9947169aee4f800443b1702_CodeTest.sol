// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

contract CodeTest is Ownable{
    
    address payable public beneficiary;

    struct UserStruct {
        uint id;
        address payable referrerID;
        address[] referral;
        uint investment;
		uint investment_time;
		uint ROI_percent;
		uint ROI_before_investment;
		uint ROI_taken_time;
    }

    uint public totalInvest = 0;
    uint public withdrawal = 0;
	uint public withdrawal_fee_in_lock = 5;
	uint public withdrawal_fee_after_lock = 1;
	uint public lock_period = 30 days;

    uint[] public reward_precent = [100,100,10,10,10,10,10,10,10,10,10];
	uint[] public min_balance = [1 ether,5 ether,10 ether];
	uint[] public ROI_percent = [25,30,35];

    mapping (address => UserStruct) public users;

    uint public currUserID = 0;

    event regEvent(address indexed _user, address indexed _referrer, uint _time);
    event investEvent(address indexed _user, uint _amount, uint _time);
    event getMoneyEvent(uint indexed _user, uint indexed _referral, uint _amount, uint _level, uint _time);
	event WithdrawalEvent(address indexed _user, uint _amount, uint _time);
	event ROI_WithdrawalEvent(address indexed _user, uint _amount, uint _time);
   
    constructor() {
        beneficiary = payable(msg.sender);

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            id: currUserID,
            referrerID: beneficiary,
            referral: new address[](0),
            investment: 99999999 ether,
			investment_time: block.timestamp,
			ROI_percent: 35,
			ROI_before_investment: 0,
			ROI_taken_time: block.timestamp
        });
        users[beneficiary] = userStruct;
    }

    function regUser(address payable _referrerID) public payable {
        require(users[msg.sender].id == 0, "User exist");
        require(msg.value >= min_balance[0], 'register with minimum 1 ETH');

        totalInvest += msg.value;
        currUserID++;

		UserStruct memory userStruct;
        userStruct = UserStruct({
            id: currUserID,
            referrerID: _referrerID,
            referral: new address[](0),
            investment: msg.value,
			investment_time: block.timestamp,
			ROI_percent: 0,
			ROI_before_investment: 0,
			ROI_taken_time: block.timestamp
        });
        users[msg.sender] = userStruct;
        users[_referrerID].referral.push(msg.sender);
		for (uint i = 0; i < min_balance.length; i++) {
			if(users[msg.sender].investment >= min_balance[i]){
				users[msg.sender].ROI_percent = ROI_percent[i];
			}
		}

        emit regEvent(msg.sender, _referrerID, block.timestamp);
    }

    function invest() public payable {
        require(users[msg.sender].id > 0, 'User not exist');
        require(msg.value > 0, 'invest with ETH');

        totalInvest += msg.value;

        users[msg.sender].investment += msg.value;
        emit investEvent(msg.sender, msg.value, block.timestamp);
    }

    function viewUserROI(address _user, uint _gen) public view returns(uint) {
        uint ROI = 0;
		ROI = users[_user].investment * reward_precent[_gen] * users[_user].ROI_percent / 10000 * (users[_user].ROI_taken_time / 1 days);
		if(_gen <= 10){
			for (uint i = 0; i < users[_user].referral.length; i++) {
				uint temp = viewUserROI(users[_user].referral[i], (_gen + uint(1)));
				ROI += temp;
			}
		}
        return ROI;
    }

	function viewUserGen(address _user, uint _gen) public view returns(uint) {
        uint gen = _gen;
        for (uint i = 0; i < users[_user].referral.length; i++) {
            uint temp = viewUserGen(users[_user].referral[i], (_gen + uint(1)));
            if(temp > gen){
                gen = temp;
            }
        }
        return gen;
    }

    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user].referral;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function ROI_Withdrawal() public returns (bool) {
		require(users[msg.sender].id > 0, 'User not exist');
        uint amount = viewUserROI(msg.sender, 0);
		users[msg.sender].ROI_taken_time = block.timestamp;
		payable(msg.sender).transfer(amount);
		emit ROI_WithdrawalEvent(msg.sender, amount, block.timestamp);
        return true;
    }

	function userWithdrawal() public returns (bool) {
		require(users[msg.sender].id > 0, 'User not exist');
        uint amount = 0;
		if(users[msg.sender].investment_time + lock_period < block.timestamp){
			amount = users[msg.sender].investment * (100 - withdrawal_fee_after_lock) / 100;
		}else{
			amount = users[msg.sender].investment * (100 - withdrawal_fee_in_lock) / 100;
		}
		users[msg.sender].investment = 0;
		payable(msg.sender).transfer(amount);
		emit WithdrawalEvent(msg.sender, amount, block.timestamp);
        return true;
    }

	function beneficiaryWithdrawal() public onlyOwner returns (bool) {
        withdrawal += address(this).balance;
        beneficiary.transfer(address(this).balance);
        return true;
    }

    function updateRewardPercent(uint[] memory _precent_of_reward) onlyOwner public returns (bool) {
        reward_precent = _precent_of_reward;
        return true;
    }
}