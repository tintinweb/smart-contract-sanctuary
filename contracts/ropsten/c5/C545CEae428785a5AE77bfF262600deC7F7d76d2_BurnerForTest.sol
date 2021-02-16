/**
 *Submitted for verification at Etherscan.io on 2021-02-16
*/

pragma solidity >=0.5.0 <0.9.0;


contract BurnerForTest {
	mapping (uint32 => uint32) burners_mapping;
	event MyselfTransfer(address indexed msg_sender_address, uint256 _value);

	constructor() public {
		updateBurnerMap(0, 100);
	}

	function updateBurnerMap(uint32 from_index, uint32 to_index) public {
		require(to_index > from_index);
		for (uint32 i=from_index; i < to_index; i++){
			burners_mapping[i] = 2**32 - 1;
		}
	}

	function useBurner(uint32 key_id, uint32 remove_amount, uint32 min_burner_amount) public payable {
        require(burners_mapping[key_id] >= remove_amount, "Not enough value for delete from this key_id");
		emit MyselfTransfer(msg.sender, msg.value);
        address(msg.sender).transfer(msg.value);
		require((burners_mapping[key_id] - remove_amount) >= min_burner_amount, "Min amount should be more then min_burner_amount");
		burners_mapping[key_id] -= remove_amount;
    }

	function getBurner(uint32 key_id) public view returns(uint) {
		return burners_mapping[key_id];
	}

//	function getBurnerLen() public view returns(uint) {
//		uint32 asd = 0;
//		while (burners_mapping[asd] > 0) {
//			asd += 1;
//		}
//		return asd;
//	}

}