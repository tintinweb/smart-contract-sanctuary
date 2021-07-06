/**
 *Submitted for verification at polygonscan.com on 2021-06-30
*/

pragma solidity ^0.8.0;

contract Predictions {
	struct PredictionInfo {
		bytes32[8] text;
	}
	
	struct Prediction {
		// a newline character should separate title and description;
		bytes32[8] text;
	}

	struct PredictionCollection {
		Prediction[] predictions;
		uint length;
	}
	
	mapping (address => PredictionCollection) predictions;

	function open(PredictionInfo calldata prediction) public returns (uint) {
		uint id = predictions[msg.sender].length;
		predictions[msg.sender].predictions[id] = Prediction({
			text: prediction.text
		});
		predictions[msg.sender].length++;
		return id;
	}

	function read(address creator, uint index) public view returns (Prediction memory) {
		return predictions[creator].predictions[index];
	}
}