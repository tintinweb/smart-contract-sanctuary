/**
 *Submitted for verification at polygonscan.com on 2021-06-30
*/

pragma solidity ^0.8.0;

contract Predictions {
    mapping (address => PredictionCollection) predictions;

    struct PredictionCollection {
        Prediction[] predictions;
        uint length;
    }

    struct Prediction {
        bytes32[8] text;
    }

    struct PredictionInfo {
        bytes32[8] text;
    }

    function open(PredictionInfo calldata prediction) public returns (uint) {
        uint id = predictions[msg.sender].length;
        predictions[msg.sender].predictions[id] = Prediction({
            text: prediction.text
        });
        return id;
    }

    function read(address creator, uint index) public view returns (Prediction memory) {
        return predictions[creator].predictions[index];
    }
}