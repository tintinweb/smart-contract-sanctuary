/**
 *Submitted for verification at Etherscan.io on 2022-01-22
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

        for (uint i = 0; i < dim1; ++i) {
            for (uint j = 0; j < dim2; ++j) {
                for (uint k = 0; k < dim3; ++k) {
                    outputs[k + (dim3 * j) + (dim3 * dim2 * i)] = inputs[i][j][k];
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
 * by 255 and truncated to an integer). Input image should be a 1x8x8 array of
 * integers with values in the range [0, 255].
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
            outputs[i] = NeuralNetLib.max_pool_2d(inputs[i]);
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
            [int128(  0),   0,   0,   0,   0,   0,   0,   0],
            [int128(  0),   5,  18,   7,   4,   4,   1,   0],
            [int128(  0),  32, 114, 117, 117, 125,  30,   0],
            [int128(  0),   2,   7,  18,  44, 139,  23,   0],
            [int128(  0),   0,   0,   1,  81,  83,   1,   0],
            [int128(  0),   0,   0,  35, 128,  18,   0,   0],
            [int128(  0),   0,   8, 127,  65,   0,   0,   0],
            [int128(  0),   0,  23, 128,  20,   0,   0,   0]
        ]
    ];

    int128[][][][] default_conv1_weights = [
        [[
            [int128(-213),   79,  176,  -10,  -78],
            [int128(-419),  103,  282,  -50,  201],
            [int128(-673),  418,  541, -163, -107],
            [int128(-461), -425,  543,  525,  -35],
            [int128(  77), -293, -489,   82,   23]
        ]],
        [[
            [int128(-470), -537, -330, -472, -196],
            [int128( 471), 1058,  774,  264,  -45],
            [int128(-293), -678,  -45,  399,  -52],
            [int128( -32),  -24, -275,  -84, -163],
            [int128(  43),   -1,   -9, -113, -217]
        ]],
        [[
            [int128(-131), -225, -255,  260,  265],
            [int128(   8),  444,  358,  455,  244],
            [int128( 313), -221, -615, -582, -362],
            [int128(  84), -268,   11, -622,  -57],
            [int128( 143),  -44,  -55, -119,  523]
        ]],
        [[
            [int128(  92),  141,  316,  397,  685],
            [int128(  84),  108,   45, -235,  422],
            [int128(-249),   64, -528,    0,  141],
            [int128(-333), -476,  124,  262, -131],
            [int128( 580),  496,  391,  276,   66]
        ]]
    ];

    int128[] default_conv1_biases = [int128(118),  63, 206, -96];

    int128[][] default_fc1_weights = [
        [int128(-383),  193,  653, -350,  -85,  190, -201, -272,  150,  -84,  -63, -120, -277,   42, -101,  325],
        [int128(-429),    8, -141,  408,  172, -771, -116, -441,  322,  649,  478,  102,  237, -357,  369, -396],
        [int128(-317), -187, -122,   46,  568,  102,  118,  184,   36,  -96,  -10,  -59,  333,   94,  -52,   47],
        [int128(  98),  270, -432,  101,  378,  151,   37,  296, -110, -309, -153, -243,  367, -128, -282,  446],
        [int128( 284),   12,  -75,   15, -289, -337,  485, -232, -254, -507,  208,  -40, -187,  315,  201, -398],
        [int128( 281),  145, -185, -174,    6,   41,  -80,  174, -139,  487,  -84,  -13, -157,  174, -243,  380],
        [int128( -51),   29,  677,   29, -609, -487, -282,  263,   23,  262, -551, -145,  -35,  148, -479,  121],
        [int128(-425), -280, -293,   46,  223,  456,  220,   58,  196, -171,  248,  241, -376, -154,  659, -392],
        [int128( 507),   53,   17,    3,  -17,   91, -438,  -84, -354,  -95, -258,  267,  141,  -72, -219,  211],
        [int128( 320),  115, -159,  -22, -257,  465,  222,  -48,  -76, -412,  142,  -16, -313,   11,  238, -280]
    ];

    int128[] default_fc1_biases = [int128(-114), -104,  -49,   83,  209,  105,   22,  -96, -116,  -62];

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