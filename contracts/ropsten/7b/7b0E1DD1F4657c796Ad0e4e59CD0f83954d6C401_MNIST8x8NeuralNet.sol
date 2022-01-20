/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

/**
 * @dev Neural network building blocks.
 */
library NeuralNetLib {
    /**
     * @dev 2D convolution layer (e.g. spatial convolution over images).
     *
     * Assumes stride value = 1.
     */
    function conv_2d(
        int128[][][] memory inputs,
        int128[][][] memory weights,
        int128 bias
    ) internal pure returns (int128[][] memory) { 
        uint dim_in = inputs[0].length;
        uint dim_out = 1 + ((dim_in - weights[0].length) / 1);

        int128[][] memory outputs = new int128[][](dim_out);

        for (uint h_start = 0; h_start < dim_out; ++h_start) {
            int128[] memory outputs_i = new int128[](dim_out);
            for (uint w_start = 0; w_start < dim_out; ++w_start) {
                uint h_end = h_start + weights[0].length;
                uint w_end = w_start + weights[0][0].length;
                for (uint i = 0; i < inputs.length; ++i) {
                    for (uint m = h_start; m < h_end; ++m) {
                        for (uint n = w_start; n < w_end; ++n) {
                            outputs_i[w_start] += (
                                inputs[i][m][n] * weights[i][m - h_start][n - w_start]
                            );
                        }
                    }
                }
                outputs_i[w_start] += bias;
            }
            outputs[h_start] = outputs_i;
        }

        return outputs;
    }

    /**
     * @dev Rectified Linear Unit activation function.
     */
    function relu(
        int128[] memory inputs
    ) internal pure returns (int128[] memory) {
        int128[] memory outputs = new int128[](inputs.length);

        for (uint i = 0; i < inputs.length; ++i) {
            if (inputs[i] > 0) {
                outputs[i] = inputs[i];
            } else {
                outputs[i] = 0;
            }
        }

        return outputs;
    }

    /**
     * @dev Max pooling operation for 2D spatial data.
     */
    function max_pool_2d(
        int128[][] memory inputs
    ) internal pure returns (int128[][] memory) {
        uint stride = 2;
        uint dim_in = inputs[0].length;
        uint dim_out = 1 + ((dim_in - stride) / stride);

        int128[][] memory outputs = new int128[][](dim_out);

        for (uint i = 0; i < dim_out; ++i) {
            int128[] memory outputs_i = new int128[](dim_out);
            for (uint j = 0; j < dim_out; ++j) {
                uint h_start = i * stride;
                uint w_start = j * stride;
                uint h_end = h_start + stride;
                uint w_end = w_start + stride;
                for (uint m = h_start; m < h_end; ++m) {
                    for (uint n = w_start; n < w_end; ++n) {
                        if (inputs[m][n] > outputs_i[j]) {
                            outputs_i[j] = inputs[m][n];
                        }
                    }
                }
            }
            outputs[i] = outputs_i;
        }

        return outputs;
    }

    /**
     * @dev Flattens the input.
     */
    function flatten(
        int128[][][] memory inputs
    ) internal pure returns (int128[] memory) {
        uint dim1 = inputs.length;
        uint dim2 = inputs[0].length;
        uint dim3 = inputs[0][0].length;

        int128[] memory outputs = new int128[](dim1 * dim2 * dim3);

        for (uint i = 0; i < dim3; ++i) {
            for (uint j = 0; j < dim2; ++j) {
                for (uint k = 0; k < dim1; ++k) {
                    outputs[i + (dim3 * j) + (dim3 * dim2 * k)] = inputs[k][j][i];
                }
            }
        }

        return outputs;
    }

    /**
     * @dev Just your regular densely-connected NN layer.
     */
    function dense(
        int128[] memory inputs,
        int128[][] memory weights,
        int128[] memory biases
    ) internal pure returns (int128[] memory) {
        int128[] memory outputs = new int128[](weights.length);

        for (uint i = 0; i < weights.length; ++i) {
            for (uint j = 0; j < weights[0].length; ++j) {
                outputs[i] += inputs[j] * weights[i][j];
            }
            outputs[i] += biases[i];
        }

        return outputs;
    }
}

/**
 * @title MNIST 8x8 Neural Network
 *
 * @notice Implements a simple neural network to predict 8x8 images of digits.
 * @dev Model architecture is hardcoded. Default model weights are hardcoded
 * as quantized integers (original floating-point values have been multiplied
 * by 256 and truncated to an integer). Input image should be a 1x8x8 integer
 * array with expected values in the range [0, 255].
 */
contract MNIST8x8NeuralNet {
    function conv2d(
        int128[][][] memory inputs,
        int128[][][][] memory weights,
        int128[] memory biases
    ) private pure returns (int128[][][] memory) {
        int128[][][] memory filters = new int128[][][](weights.length);
        for (uint i = 0; i < weights.length; ++i) {
            filters[i] = NeuralNetLib.conv_2d(inputs, weights[i], biases[i]);
        }
        return filters;
    }

    function relu(
        int128[][][] memory inputs
    ) private pure returns (int128[][][] memory) {
        for (uint i = 0; i < inputs.length; ++i) {
            for (uint j = 0; j < inputs[0].length; ++j) {
                inputs[i][j] = NeuralNetLib.relu(inputs[i][j]);
            }
        }
        return inputs;
    }

    function maxpool2d(
        int128[][][] memory inputs
    ) private pure returns (int128[][][] memory) {
        int128[][][] memory outputs = new int128[][][](inputs.length);
        for (uint i = 0; i < inputs.length; ++i) {
            int128[][] memory outputs_i;
            outputs_i = NeuralNetLib.max_pool_2d(inputs[i]);
            outputs[i] = outputs_i;
        }
        return outputs;
    }

    function flatten(
        int128[][][] memory inputs
    ) private pure returns (int128[] memory) {
        return NeuralNetLib.flatten(inputs);
    }

    function dense(
        int128[] memory inputs,
        int128[][] memory weights,
        int128[] memory biases
    ) private pure returns (int128[] memory) {
        return NeuralNetLib.dense(inputs, weights, biases);
    }

    function argmax(
        int128[] memory inputs
    ) internal pure returns (uint) {
        uint output = 0;
        int128 max_output = 0;
        for (uint i = 0; i < inputs.length; ++i) {
            if (inputs[i] > max_output) {
                max_output = inputs[i];
                output = i;
            }
        }
        return output;
    }

    function predict_proba(
        int128[][][] memory inputs,
        int128[][][][] memory conv1_weights,
        int128[] memory conv1_biases,
        int128[][] memory fc1_weights,
        int128[] memory fc1_biases
    ) public pure returns (int128[] memory) {
        int128[][][] memory x1 = conv2d(inputs, conv1_weights, conv1_biases);
        int128[][][] memory x2 = relu(x1);
        int128[][][] memory x3 = maxpool2d(x2);
        int128[] memory x4 = flatten(x3);
        int128[] memory x5 = dense(x4, fc1_weights, fc1_biases);
        return x5;
    }

    function predict(
        int128[][][] memory inputs,
        int128[][][][] memory conv1_weights,
        int128[] memory conv1_biases,
        int128[][] memory fc1_weights,
        int128[] memory fc1_biases
    ) public pure returns (uint) {
        int128[] memory proba = predict_proba(
            inputs,
            conv1_weights,
            conv1_biases,
            fc1_weights,
            fc1_biases
        );
        return argmax(proba);
    }

    int128[][][] ex_image = [
        [
            [int128(0), 0, 0, 0, 0, 0, 0, 0],
            [int128(0), 5, 18, 7, 4, 4, 1, 0],
            [int128(0), 32, 114, 117, 117, 125, 30, 0],
            [int128(0), 2, 7, 18, 44, 139, 23, 0],
            [int128(0), 0, 0, 1, 81, 83, 1, 0],
            [int128(0), 0, 0, 35, 128, 18, 0, 0],
            [int128(0), 0, 8, 127, 65, 0, 0, 0],
            [int128(0), 0, 23, 128, 20, 0, 0, 0]
        ]
    ];

    int128[][][][] default_conv1_weights = [
        [
            [
                [int128(-214), 79, 177, -10, -79],
                [int128(-421), 103, 283, -50, 201],
                [int128(-675), 420, 543, -164, -108],
                [int128(-462), -427, 545, 527, -35],
                [int128(78), -294, -491, 82, 23]
            ]
        ],
        [
           [
                [int128(-472), -540, -331, -474, -197],
                [int128(473), 1062, 777, 265, -45],
                [int128(-294), -681, -45, 400, -52],
                [int128(-32), -24, -276, -85, -164],
                [int128(43), -1, -9, -113, -218]
           ]
        ],
        [
           [
                [int128(-131), -226, -256, 261, 266],
                [int128(8), 446, 359, 457, 244],
                [int128(314), -221, -618, -584, -363],
                [int128(84), -269, 11, -625, -57],
                [int128(143), -44, -55, -119, 525]
           ]
        ],
        [
           [
                [int128(92), 141, 317, 399, 688],
                [int128(84), 108, 45, -236, 423],
                [int128(-250), 64, -530, 0, 141],
                [int128(-334), -478, 124, 263, -131],
                [int128(582), 498, 393, 277, 66]
           ]
        ]
    ];

    int128[] default_conv1_biases = [int128(119), 63, 207, -96];

    int128[][] default_fc1_weights = [
        [int128(-384), 194, 656, -351, -86, 191, -202, -273, 151, -85, -63, -120, -278, 42, -101, 327],
        [int128(-431), 8, -141, 409, 173, -774, -116, -443, 323, 651, 480, 103, 238, -359, 371, -398],
        [int128(-318), -188, -123, 46, 571, 103, 119, 185, 36, -96, -10, -59, 335, 95, -52, 47],
        [int128(99), 271, -434, 102, 379, 151, 38, 297, -110, -311, -154, -244, 369, -128, -283, 448],
        [int128(285), 12, -75, 15, -290, -339, 487, -233, -255, -509, 209, -40, -187, 316, 201, -400],
        [int128(282), 146, -186, -174, 6, 41, -81, 175, -139, 489, -84, -13, -158, 175, -244, 381],
        [int128(-51), 29, 680, 29, -612, -489, -283, 264, 23, 263, -554, -145, -35, 149, -480, 122],
        [int128(-426), -281, -294, 46, 224, 458, 221, 58, 197, -171, 249, 242, -378, -155, 662, -394],
        [int128(509), 53, 17, 3, -17, 91, -440, -84, -355, -95, -259, 268, 141, -72, -220, 212],
        [int128(321), 115, -159, -22, -258, 467, 223, -48, -77, -414, 143, -16, -314, 11, 239, -281]
    ];

    int128[] default_fc1_biases = [int128(-115), -104, -50, 84, 209, 105, 22, -97, -116, -63];

    function default_predict_proba(
        int128[][][] memory image
    ) public view returns (int128[] memory) {
        return predict_proba(
            image,
            default_conv1_weights,
            default_conv1_biases,
            default_fc1_weights,
            default_fc1_biases
        );
    }

    function default_predict(
        int128[][][] memory image
    ) public view returns (uint) {
        return predict(
            image,
            default_conv1_weights,
            default_conv1_biases,
            default_fc1_weights,
            default_fc1_biases
        );
    }

    function get_ex_predict_proba() external view returns (int128[] memory) {
        return default_predict_proba(ex_image);
    }

    function get_ex_predict() external view returns (uint) {
        return default_predict(ex_image);
    }
}