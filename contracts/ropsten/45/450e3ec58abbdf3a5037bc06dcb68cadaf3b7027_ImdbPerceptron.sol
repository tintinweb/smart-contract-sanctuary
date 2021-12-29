/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT
/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 private constant INT256_MIN = -2**255;

    /**
     * @dev Multiplies two signed integers, reverts on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(
            !(a == -1 && b == INT256_MIN),
            "SignedSafeMath: multiplication overflow"
        );

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(
            !(b == -1 && a == INT256_MIN),
            "SignedSafeMath: division overflow"
        );

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two signed integers, reverts on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require(
            (b >= 0 && c <= a) || (b < 0 && c > a),
            "SignedSafeMath: subtraction overflow"
        );

        return c;
    }

    /**
     * @dev Adds two signed integers, reverts on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require(
            (b >= 0 && c >= a) || (b < 0 && c < a),
            "SignedSafeMath: addition overflow"
        );

        return c;
    }
}

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not the owner.");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be 0x0.");
        owner = newOwner;
    }
}

/**
 * A Perceptron where the data given for updating and predicting is sparse.
 * `update` and `predict` methods take `data` that holds the indices of the features that are present.
 */
contract ImdbPerceptron is Ownable {
    using SignedSafeMath for int256;

    /**
     * The weights for the model.
     * Multiplied by `toFloat`.
     */
    mapping(uint64 => int80) public weights;

    /**
     * The bias to add to the multiplication of the weights and the data.
     * Multiplied by `toFloat`.
     */
    int80 public intercept;

    /**
     * The amount of impact that new training data has to the weights.
     * Multiplied by `toFloat`.
     */
    uint32 public learningRate;

    /**
     * @param _weights The weights for the model. Each multiplied by `toFloat`.
     * @param _intercept The bias to add to the multiplication of the weights and the data. Multiplied by `toFloat`.
     * @param _learningRate (Optional, defaults to 1). The amount of impact that new training data has to the weights.
     Multiplied by `toFloat`.
     */
    constructor(
        int80[] memory _weights,
        int80 _intercept,
        uint32 _learningRate
    ) public {
        intercept = _intercept;
        learningRate = _learningRate;

        require(_weights.length < 2**64 - 1, "Too many weights given.");
        for (uint64 i = 0; i < _weights.length; ++i) {
            weights[i] = _weights[i];
        }
    }

    /**
     * Initialize weights for the model.
     * Made to be called just after the contract is created and never again.
     * @param startIndex The index to start placing `_weights` into the model's weights.
     * @param _weights The weights to set for the model.
     */
    function initializeWeights(uint64 startIndex, int80[] memory _weights)
        public
        onlyOwner
    {
        for (uint64 i = 0; i < _weights.length; ++i) {
            weights[startIndex + i] = _weights[i];
        }
    }

    /**
     * Initialize sparse weights for the model.
     * Made to be called just after the contract is created and never again.
     * @param _weights A sparse representation of the weights.
     * Each innermost array is a tuple of the feature index and the weight for that feature.
     */
    function initializeSparseWeights(int80[][] memory _weights)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _weights.length; ++i) {
            int80 featureIndex = _weights[i][0];
            require(featureIndex < 2**64, "A feature index is too large.");
            weights[uint64(featureIndex)] = _weights[i][1];
        }
    }

    function norm(
        int64[] memory /* data */
    ) public pure returns (uint256) {
        revert("Normalization is not required.");
    }

    function predict(int64[] memory data) public view returns (uint64) {
        int256 m = intercept;
        for (uint256 i = 0; i < data.length; ++i) {
            // `update` assumes this check is done.
            require(data[i] >= 0, "Not all indices are >= 0.");
            m = m.add(weights[uint64(data[i])]);
        }
        if (m <= 0) {
            return 0;
        } else {
            return 1;
        }
    }

    function update(int64[] memory data, uint64 classification)
        public
        onlyOwner
    {
        // `data` holds the indices of the features that are present.
        uint64 prediction = predict(data);
        if (prediction != classification) {
            // Update model.
            // predict checks each data[i] >= 0.
            uint256 i;
            uint256 len = data.length;
            if (classification > 0) {
                // sign = 1
                for (i = 0; i < len; ++i) {
                    weights[uint64(data[i])] += learningRate;
                }
            } else {
                // sign = -1
                for (i = 0; i < len; ++i) {
                    weights[uint64(data[i])] -= learningRate;
                }
            }
        }
    }

    /**
     * Evaluate a batch.
     *
     * Force samples to have a size of 60 because about 78% of the IMDB test data has less than 60 tokens. If the sample has less than 60 unique tokens, then use a value > weights.length.
     *
     * @return numCorrect The number correct in the batch.
     */
    function evaluateBatch(
        uint24[60][] calldata dataBatch,
        uint64[] calldata _classifications
    ) external view returns (uint256 numCorrect) {
        numCorrect = 0;
        uint256 len = dataBatch.length;
        uint256 i;
        uint256 dataLen;
        uint24[60] memory data;
        int80 prediction;
        for (uint256 dataIndex = 0; dataIndex < len; ++dataIndex) {
            data = dataBatch[dataIndex];
            // Re-implement prediction for speed and to handle the type of data not matching.
            prediction = intercept;
            dataLen = data.length;
            for (i = 0; i < dataLen; ++i) {
                prediction += weights[data[i]];
            }
            if (prediction <= 0) {
                prediction = 0;
            } else {
                prediction = 1;
            }

            if (prediction == _classifications[dataIndex]) {
                numCorrect += 1;
            }
        }
    }
}