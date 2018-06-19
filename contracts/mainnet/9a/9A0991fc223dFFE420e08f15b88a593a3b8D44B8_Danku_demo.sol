pragma solidity ^0.4.19;
// Danku contract version 0.0.1
// Data points are x, y, and z

contract Danku_demo {
  function Danku_demo() public {
    // Neural Network Structure:
    //
    // (assertd) input layer x number of neurons
    // (optional) hidden layers x number of neurons
    // (assertd) output layer x number of neurons
  }
  struct Submission {
      address payment_address;
      // Define the number of neurons each layer has.
      uint num_neurons_input_layer;
      uint num_neurons_output_layer;
      // There can be multiple hidden layers.
      uint[] num_neurons_hidden_layer;
      // Weights indexes are the following:
      // weights[l_i x l_n_i x pl_n_i]
      // Also number of layers in weights is layers.length-1
      int256[] weights;
      int256[] biases;
  }
  struct NeuralLayer {
    int256[] neurons;
    int256[] errors;
    string layer_type;
  }

  address public organizer;
  // Keep track of the best model
  uint public best_submission_index;
  // Keep track of best model accuracy
  int256 public best_submission_accuracy = 0;
  // The model accuracy criteria
  int256 public model_accuracy_criteria;
  // Use test data if provided
  bool public use_test_data = false;
  // Each partition is 5% of the total dataset size
  uint constant partition_size = 25;
  // Data points are made up of x and y coordinates and the prediction
  uint constant datapoint_size = 3;
  uint constant prediction_size = 1;
  // Max number of data groups
  // Change this to your data group size
  uint16 constant max_num_data_groups = 500;
  // Training partition size
  uint16 constant training_data_group_size = 400;
  // Testing partition size
  uint16 constant testing_data_group_size = max_num_data_groups - training_data_group_size;
  // Dataset is divided into data groups.
  // Every data group includes a nonce.
  // Look at sha_data_group() for more detail about hashing a data group
  bytes32[max_num_data_groups/partition_size] hashed_data_groups;
  // Nonces are revelead together with data groups
  uint[max_num_data_groups/partition_size] data_group_nonces;
  // + 1 for prediction
  // A data group has 3 data points in total
  int256[datapoint_size][] public train_data;
  int256[datapoint_size][] public test_data;
  bytes32 partition_seed;
  // Deadline for submitting solutions in terms of block size
  uint public submission_stage_block_size = 241920; // 6 weeks timeframe
  // Deadline for revealing the testing dataset
  uint public reveal_test_data_groups_block_size = 17280; // 3 days timeframe
  // Deadline for evaluating the submissions
  uint public evaluation_stage_block_size = 40320; // 7 days timeframe
  uint public init1_block_height;
  uint public init3_block_height;
  uint public init_level = 0;
  // Training partition size is 14 (70%)
  // Testing partition size is 6 (30%)
  uint[training_data_group_size/partition_size] public training_partition;
  uint[testing_data_group_size/partition_size] public testing_partition;
  uint256 train_dg_revealed = 0;
  uint256 test_dg_revealed = 0;
  Submission[] submission_queue;
  bool public contract_terminated = false;
  // Integer precision for calculating float values for weights and biases
  int constant int_precision = 10000;

  // Takes in array of hashed data points of the entire dataset,
  // submission and evaluation times
  function init1(bytes32[max_num_data_groups/partition_size] _hashed_data_groups, int accuracy_criteria, address organizer_refund_address) external {
    // Make sure contract is not terminated
    assert(contract_terminated == false);
    // Make sure it&#39;s called in order
    assert(init_level == 0);
    organizer = organizer_refund_address;
    init_level = 1;
    init1_block_height = block.number;

    // Make sure there are in total 20 hashed data groups
    assert(_hashed_data_groups.length == max_num_data_groups/partition_size);
    hashed_data_groups = _hashed_data_groups;
    // Accuracy criteria example: 85.9% => 8,590
    // 100 % => 10,000
    assert(accuracy_criteria > 0);
    model_accuracy_criteria = accuracy_criteria;
  }

  function init2() external {
    // Make sure contract is not terminated
    assert(contract_terminated == false);
    // Only allow calling it once, in order
    assert(init_level == 1);
    // Make sure it&#39;s being called within 20 blocks on init1()
    // to minimize organizer influence on random index selection
    if (block.number <= init1_block_height+20 && block.number > init1_block_height) {
      // TODO: Also make sure it&#39;s being called 1 block after init1()
      // Randomly select indexes
      uint[] memory index_array = new uint[](max_num_data_groups/partition_size);
      for (uint i = 0; i < max_num_data_groups/partition_size; i++) {
        index_array[i] = i;
      }
      randomly_select_index(index_array);
      init_level = 2;
    } else {
      // Cancel the contract if init2() hasn&#39;t been called within 5
      // blocks of init1()
      cancel_contract();
    }
  }

  function init3(int256[] _train_data_groups, int256 _train_data_group_nonces) external {
    // Pass a single data group at a time
    // Make sure contract is not terminated
    assert(contract_terminated == false);
    // Only allow calling once, in order
    assert(init_level == 2);
    // Verify data group and nonce lengths
    assert((_train_data_groups.length/partition_size)/datapoint_size == 1);
    // Verify data group hashes
    // Order of revealed training data group must be the same with training partitions
    // Otherwise hash verification will fail
    assert(sha_data_group(_train_data_groups, _train_data_group_nonces) ==
      hashed_data_groups[training_partition[train_dg_revealed]]);
    train_dg_revealed += 1;
    // Assign training data after verifying the corresponding hash
    unpack_data_groups(_train_data_groups, true);
    if (train_dg_revealed == (training_data_group_size/partition_size)) {
      init_level = 3;
      init3_block_height = block.number;
    }
  }

  function get_training_index() public view returns(uint[training_data_group_size/partition_size]) {
    return training_partition;
  }

  function get_testing_index() public view returns(uint[testing_data_group_size/partition_size]) {
    return testing_partition;
  }

  function get_submission_queue_length() public view returns(uint) {
    return submission_queue.length;
  }

  function submit_model(
    // Public function for users to submit a solution
    address payment_address,
    uint num_neurons_input_layer,
    uint num_neurons_output_layer,
    uint[] num_neurons_hidden_layer,
    int[] weights,
    int256[] biases) public {
      // Make sure contract is not terminated
      assert(contract_terminated == false);
      // Make sure it&#39;s not the initialization stage anymore
      assert(init_level == 3);
      // Make sure it&#39;s still within the submission stage
      assert(block.number < init3_block_height + submission_stage_block_size);
      // Make sure that num of neurons in the input & output layer matches
      // the problem description
      assert(num_neurons_input_layer == datapoint_size - prediction_size);
      // Because we can encode binary output in two different ways, we check
      // for both of them
      assert(num_neurons_output_layer == prediction_size || num_neurons_output_layer == (prediction_size+1));
      // Make sure that the number of weights match network structure
      assert(valid_weights(weights, num_neurons_input_layer, num_neurons_output_layer, num_neurons_hidden_layer));
      // Add solution to submission queue
      submission_queue.push(Submission(
        payment_address,
        num_neurons_input_layer,
        num_neurons_output_layer,
        num_neurons_hidden_layer,
        weights,
        biases));
  }

  function get_submission_id(
    // Public function that returns the submission index ID
    address paymentAddress,
    uint num_neurons_input_layer,
    uint num_neurons_output_layer,
    uint[] num_neurons_hidden_layer,
    int[] weights,
    int256[] biases) public view returns (uint) {
      // Iterate over submission queue to get submission index ID
      for (uint i = 0; i < submission_queue.length; i++) {
        if (submission_queue[i].payment_address != paymentAddress) {
          continue;
        }
        if (submission_queue[i].num_neurons_input_layer != num_neurons_input_layer) {
          continue;
        }
        if (submission_queue[i].num_neurons_output_layer != num_neurons_output_layer) {
          continue;
        }
        for (uint j = 0; j < num_neurons_hidden_layer.length; j++) {
            if (submission_queue[i].num_neurons_hidden_layer[j] != num_neurons_hidden_layer[j]) {
              continue;
            }
        }
        for (uint k = 0; k < weights.length; k++) {
            if (submission_queue[i].weights[k] != weights[k]) {
              continue;
            }
        }
        for (uint l = 0; l < biases.length; l++) {
          if (submission_queue[i].biases[l] != biases[l]) {
            continue;
          }
        }
        // If everything matches, return the submission index
        return i;
      }
      // If submission is not in the queue, just throw an exception
      require(false);
  }

    function reveal_test_data(int256[] _test_data_groups, int256 _test_data_group_nonces) external {
    // Make sure contract is not terminated
    assert(contract_terminated == false);
    // Make sure it&#39;s not the initialization stage anymore
    assert(init_level == 3);
    // Make sure it&#39;s revealed after the submission stage
    assert(block.number >= init3_block_height + submission_stage_block_size);
    // Make sure it&#39;s revealed within the reveal stage
    assert(block.number < init3_block_height + submission_stage_block_size + reveal_test_data_groups_block_size);
    // Verify data group and nonce lengths
    assert((_test_data_groups.length/partition_size)/datapoint_size == 1);
    // Verify data group hashes
    assert(sha_data_group(_test_data_groups, _test_data_group_nonces) ==
      hashed_data_groups[testing_partition[test_dg_revealed]]);
    test_dg_revealed += 1;
    // Assign testing data after verifying the corresponding hash
    unpack_data_groups(_test_data_groups, false);
    // Use test data for evaluation
    use_test_data = true;
  }

  function evaluate_model(uint submission_index) public {
    // TODO: Make sure that if there&#39;s two same submission w/ same weights
    // and biases, the first one submitted should get the reward.
    // Make sure contract is not terminated
    assert(contract_terminated == false);
    // Make sure it&#39;s not the initialization stage anymore
    assert(init_level == 3);
    // Make sure it&#39;s evaluated after the reveal stage
    assert(block.number >= init3_block_height + submission_stage_block_size + reveal_test_data_groups_block_size);
    // Make sure it&#39;s evaluated within the evaluation stage
    assert(block.number < init3_block_height + submission_stage_block_size + reveal_test_data_groups_block_size + evaluation_stage_block_size);
    // Evaluates a submitted model & keeps track of the best model
    int256 submission_accuracy = 0;
    if (use_test_data == true) {
      submission_accuracy = model_accuracy(submission_index, test_data);
    } else {
      submission_accuracy = model_accuracy(submission_index, train_data);
    }

    // Keep track of the most accurate model
    if (submission_accuracy > best_submission_accuracy) {
      best_submission_index = submission_index;
      best_submission_accuracy = submission_accuracy;
    }
  }

  function cancel_contract() public {
    // Make sure contract is not already terminated
    assert(contract_terminated == false);
    // Contract can only be cancelled if initialization has failed.
    assert(init_level < 3);
    // Refund remaining balance to organizer
    organizer.transfer(this.balance);
    // Terminate contract
    contract_terminated = true;
  }

  function finalize_contract() public {
    // Make sure contract is not terminated
    assert(contract_terminated == false);
    // Make sure it&#39;s not the initialization stage anymore
    assert(init_level == 3);
    // Make sure the contract is finalized after the evaluation stage
    assert(block.number >= init3_block_height + submission_stage_block_size + reveal_test_data_groups_block_size + evaluation_stage_block_size);
    // Get the best submission to compare it against the criteria
    Submission memory best_submission = submission_queue[best_submission_index];
    // If best submission passes criteria, payout to the submitter
    if (best_submission_accuracy >= model_accuracy_criteria) {
      best_submission.payment_address.transfer(this.balance);
    // If the best submission fails the criteria, refund the balance back to the organizer
    } else {
      organizer.transfer(this.balance);
    }
    contract_terminated = true;
  }

  function model_accuracy(uint submission_index, int256[datapoint_size][] data) public constant returns (int256){
    // Make sure contract is not terminated
    assert(contract_terminated == false);
    // Make sure it&#39;s not the initialization stage anymore
    assert(init_level == 3);
    // Leave function public for offline error calculation
    // Get&#39;s the sum error for the model
    Submission memory sub = submission_queue[submission_index];
    int256 true_prediction = 0;
    int256 false_prediction = 0;
    bool one_hot; // one-hot encoding if prediction size is 1 but model output size is 2
    int[] memory prediction;
    int[] memory ground_truth;
    if ((prediction_size + 1) == sub.num_neurons_output_layer) {
      one_hot = true;
      prediction = new int[](sub.num_neurons_output_layer);
      ground_truth = new int[](sub.num_neurons_output_layer);
    } else {
      one_hot = false;
      prediction = new int[](prediction_size);
      ground_truth = new int[](prediction_size);
    }
    for (uint i = 0; i < data.length; i++) {
      // Get ground truth
      for (uint j = datapoint_size-prediction_size; j < data[i].length; j++) {
        uint d_index = j - datapoint_size + prediction_size;
        // Only get prediction values
        if (one_hot == true) {
          if (data[i][j] == 0) {
            ground_truth[d_index] = 1;
            ground_truth[d_index + 1] = 0;
          } else if (data[i][j] == 1) {
            ground_truth[d_index] = 0;
            ground_truth[d_index + 1] = 1;
          } else {
            // One-hot encoding for more than 2 classes is not supported
            require(false);
          }
        } else {
          ground_truth[d_index] = data[i][j];
        }
      }
      // Get prediction
      prediction = get_prediction(sub, data[i]);
      // Get error for the output layer
      for (uint k = 0; k < ground_truth.length; k++) {
        if (ground_truth[k] == prediction[k]) {
          true_prediction += 1;
        } else {
          false_prediction += 1;
        }
      }
    }
    // We multipl by int_precision to get up to x decimal point precision while
    // calculating the accuracy
    return (true_prediction * int_precision) / (true_prediction + false_prediction);
  }

  function get_train_data_length() public view returns(uint256) {
    return train_data.length;
  }

  function get_test_data_length() public view returns(uint256) {
    return test_data.length;
  }

  function round_up_division(int256 dividend, int256 divisor) private pure returns(int256) {
    // A special trick since solidity normall rounds it down
    return (dividend + divisor -1) / divisor;
  }

  function not_in_train_partition(uint[training_data_group_size/partition_size] partition, uint number) private pure returns (bool) {
    for (uint i = 0; i < partition.length; i++) {
      if (number == partition[i]) {
        return false;
      }
    }
    return true;
  }

  function randomly_select_index(uint[] array) private {
    uint t_index = 0;
    uint array_length = array.length;
    uint block_i = 0;
    // Randomly select training indexes
    while(t_index < training_partition.length) {
      uint random_index = uint(sha256(block.blockhash(block.number-block_i))) % array_length;
      training_partition[t_index] = array[random_index];
      array[random_index] = array[array_length-1];
      array_length--;
      block_i++;
      t_index++;
    }
    t_index = 0;
    while(t_index < testing_partition.length) {
      testing_partition[t_index] = array[array_length-1];
      array_length--;
      t_index++;
    }
  }

  function valid_weights(int[] weights, uint num_neurons_input_layer, uint num_neurons_output_layer, uint[] num_neurons_hidden_layer) private pure returns (bool) {
    // make sure the number of weights match the network structure
    // get number of weights based on network structure
    uint ns_total = 0;
    uint wa_total = 0;
    uint number_of_layers = 2 + num_neurons_hidden_layer.length;

    if (number_of_layers == 2) {
      ns_total = num_neurons_input_layer * num_neurons_output_layer;
    } else {
      for(uint i = 0; i < num_neurons_hidden_layer.length; i++) {
        // Get weights between first hidden layer and input layer
        if (i==0){
          ns_total += num_neurons_input_layer * num_neurons_hidden_layer[i];
        // Get weights between hidden layers
        } else {
          ns_total += num_neurons_hidden_layer[i-1] * num_neurons_hidden_layer[i];
        }
      }
      // Get weights between last hidden layer and output layer
      ns_total += num_neurons_hidden_layer[num_neurons_hidden_layer.length-1] * num_neurons_output_layer;
    }
    // get number of weights in the weights array
    wa_total = weights.length;

    return ns_total == wa_total;
  }

    function unpack_data_groups(int256[] _data_groups, bool is_train_data) private {
    int256[datapoint_size][] memory merged_data_group = new int256[datapoint_size][](_data_groups.length/datapoint_size);

    for (uint i = 0; i < _data_groups.length/datapoint_size; i++) {
      for (uint j = 0; j < datapoint_size; j++) {
        merged_data_group[i][j] = _data_groups[i*datapoint_size + j];
      }
    }
    if (is_train_data == true) {
      // Assign training data
      for (uint k = 0; k < merged_data_group.length; k++) {
        train_data.push(merged_data_group[k]);
      }
    } else {
      // Assign testing data
      for (uint l = 0; l < merged_data_group.length; l++) {
        test_data.push(merged_data_group[l]);
      }
    }
  }

    function sha_data_group(int256[] data_group, int256 data_group_nonce) private pure returns (bytes32) {
      // Extract the relevant data points for the given data group index
      // We concat all data groups and add the nounce to the end of the array
      // and get the sha256 for the array
      uint index_tracker = 0;
      uint256 total_size = datapoint_size * partition_size;
      /* uint256 start_index = data_group_index * total_size;
      uint256 iter_limit = start_index + total_size; */
      int256[] memory all_data_points = new int256[](total_size+1);

      for (uint256 i = 0; i < total_size; i++) {
        all_data_points[index_tracker] = data_group[i];
        index_tracker += 1;
      }
      // Add nonce to the whole array
      all_data_points[index_tracker] = data_group_nonce;
      // Return sha256 on all data points + nonce
      return sha256(all_data_points);
    }

  function relu_activation(int256 x) private pure returns (int256) {
    if (x < 0) {
      return 0;
    } else {
      return x;
    }
  }

  function get_layer(uint nn) private pure returns (int256[]) {
    int256[] memory input_layer = new int256[](nn);
    return input_layer;
  }

  function get_hidden_layers(uint[] l_nn) private pure returns (int256[]) {
    uint total_nn = 0;
    // Skip first and last layer since they&#39;re not hidden layers
    for (uint i = 1; i < l_nn.length-1; i++) {
      total_nn += l_nn[i];
    }
    int256[] memory hidden_layers = new int256[](total_nn);
    return hidden_layers;
  }

  function access_hidden_layer(int256[] hls, uint[] l_nn, uint index) private pure returns (int256[]) {
    // TODO: Bug is here, doesn&#39;t work for between last hidden and output layer
    // Returns the hidden layer from the hidden layers array
    int256[] memory hidden_layer = new int256[](l_nn[index+1]);
    uint hidden_layer_index = 0;
    uint start = 0;
    uint end = 0;
    for (uint i = 0; i < index; i++) {
      start += l_nn[i+1];
    }
    for (uint j = 0; j < (index + 1); j++) {
      end += l_nn[j+1];
    }
    for (uint h_i = start; h_i < end; h_i++) {
      hidden_layer[hidden_layer_index] = hls[h_i];
      hidden_layer_index += 1;
    }
    return hidden_layer;
  }

  function get_prediction(Submission sub, int[datapoint_size] data_point) private pure returns(int256[]) {
    uint[] memory l_nn = new uint[](sub.num_neurons_hidden_layer.length + 2);
    l_nn[0] = sub.num_neurons_input_layer;
    for (uint i = 0; i < sub.num_neurons_hidden_layer.length; i++) {
      l_nn[i+1] = sub.num_neurons_hidden_layer[i];
    }
    l_nn[sub.num_neurons_hidden_layer.length+1] = sub.num_neurons_output_layer;
    return forward_pass(data_point, sub.weights, sub.biases, l_nn);
  }

  function forward_pass(int[datapoint_size] data_point, int256[] weights, int256[] biases, uint[] l_nn) private pure returns (int256[]) {
    // Initialize neuron arrays
    int256[] memory input_layer = get_layer(l_nn[0]);
    int256[] memory hidden_layers = get_hidden_layers(l_nn);
    int256[] memory output_layer = get_layer(l_nn[l_nn.length-1]);

    // load inputs from input layer
    for (uint input_i = 0; input_i < l_nn[0]; input_i++) {
      input_layer[input_i] = data_point[input_i];
    }
    return forward_pass2(l_nn, input_layer, hidden_layers, output_layer, weights, biases);
  }

  function forward_pass2(uint[] l_nn, int256[] input_layer, int256[] hidden_layers, int256[] output_layer, int256[] weights, int256[] biases) public pure returns (int256[]) {
    // index_counter[0] is weight index
    // index_counter[1] is hidden_layer_index
    uint[] memory index_counter = new uint[](2);
    for (uint layer_i = 0; layer_i < (l_nn.length-1); layer_i++) {
      int256[] memory current_layer;
      int256[] memory prev_layer;
      // If between input and first hidden layer
      if (hidden_layers.length != 0) {
        if (layer_i == 0) {
          current_layer = access_hidden_layer(hidden_layers, l_nn, layer_i);
          prev_layer = input_layer;
        // If between output and last hidden layer
        } else if (layer_i == (l_nn.length-2)) {
          current_layer = output_layer;
          prev_layer = access_hidden_layer(hidden_layers, l_nn, (layer_i-1));
        // If between hidden layers
        } else {
          current_layer = access_hidden_layer(hidden_layers, l_nn, layer_i);
          prev_layer = access_hidden_layer(hidden_layers, l_nn, layer_i-1);
        }
      } else {
        current_layer = output_layer;
        prev_layer = input_layer;
      }
      for (uint layer_neuron_i = 0; layer_neuron_i < current_layer.length; layer_neuron_i++) {
        int total = 0;
        for (uint prev_layer_neuron_i = 0; prev_layer_neuron_i < prev_layer.length; prev_layer_neuron_i++) {
          total += prev_layer[prev_layer_neuron_i] * weights[index_counter[0]];
          index_counter[0]++;
        }
        total += biases[layer_i];
        total = total / int_precision; // Divide by int_precision to scale down
        // If between output and last hidden layer
        if (layer_i == (l_nn.length-2)) {
            output_layer[layer_neuron_i] = relu_activation(total);
        } else {
            hidden_layers[index_counter[1]] = relu_activation(total);
        }
        index_counter[1]++;
      }
    }
    return output_layer;
  }

  // Fallback function for sending ether to this contract
  function () public payable {}
}