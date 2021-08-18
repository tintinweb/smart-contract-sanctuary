/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

pragma solidity 0.8.6;
// SPDX-License-Identifier: UNLICENSED

contract SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }


    // mitigate short address attack
    // thanks to https://github.com/numerai/contract/blob/c182465f82e50ced8dacb3977ec374a892f5fa8c/contracts/Safe.sol#L30-L34.
    // TODO: doublecheck implication of >= compared to ==
    modifier onlyPayloadSize(uint numWords) {
        assert(msg.data.length >= numWords * 32 + 4);
        _;
    }
}

contract Poll is SafeMath {
    address public owner;
    // address payable public operator;
    // address payable public operator_2;

    // inputs from constructor
    string title;
    string public questions_in_json_string; // {"question1": ["", "option1", "option2"], "question2": [] ...}
    mapping (uint256 => mapping (uint256 => bytes32)) public options; // option_desc_for_certain_question = options[question_index][option_index]
    uint256 opening_time;
    uint256 closing_time;
    uint256 num_of_questions;
    uint256 num_of_batch_allowed;
    uint256 max_options;
    uint256 max_votes;
    uint256 amount_of_rewards; // in wei
    bool show_result_after_close;
	bool allowing_update_after_voted;

    // control vars
    uint256 public current_votes;
    mapping (uint256 => bool) public voted;

    // vote results
    mapping (uint256 => mapping (uint256 => uint256)) votes; // vote_for_certain_question = votes[voter_id][question_index]
    mapping (uint256 => mapping (uint256 => uint256)) count_of_options; // vote_count_for_certain_option = options[question_index][option_index]

    // rewards
    bool public rewards_sent;
    mapping (uint256 => address) voter_addresses;

    // events
    event Voted(uint256 voter, uint256 option_id);
    event AddLiquidity(uint256 eth_amount);
    event RemoveLiquidity(uint256 eth_amount);
    event Received(address, uint256);

    modifier onlyBeforeOpen {
        // solium-disable-next-line security/no-block-members
        require(block.timestamp < opening_time);
        require(msg.sender == owner);
        _;
    }

    modifier onlyWhileOpen {
        // solium-disable-next-line security/no-block-members
        require(block.timestamp >= opening_time && block.timestamp <= closing_time && address(this).balance >= amount_of_rewards);
        require(msg.sender == owner);
        _;
    }

    modifier onlyAfterClose {
        // solium-disable-next-line security/no-block-members
        require(msg.sender == owner);
        if (isClosed()) {
            _;
        }
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // receive() external payable {
    //     emit Received(msg.sender, msg.value);
    // }

    function isClosed() private view returns (bool) {
        return (block.timestamp > closing_time || (max_votes == current_votes && max_votes > 0));
    }

    // function addLiquidity() external payable {
    //     require(msg.value > 0);
    //     emit AddLiquidity(msg.value);
    // }

    // function removeLiquidity(uint256 _amount) external onlyOwner {
    //     require(_amount <= address(this).balance);
    //     owner.transfer(_amount);
    //     emit RemoveLiquidity(_amount);
    // }


    constructor(
        string memory _title,
        string memory _questions_in_json_string,
        bytes32[] memory _options,
        uint256 _opening_time,
        uint256 _closing_time,
        uint256 _num_of_questions,
        uint256 _max_options,
        uint256 _max_votes,
        uint256 _amount_of_rewards,
        bool _show_result_after_close) {

        // solium-disable-next-line security/no-block-members
        require(_closing_time >= block.timestamp);
        require(_closing_time >= _opening_time);
        require(_max_votes >= 0);
        require(_num_of_questions == _options.length / _max_options);

        owner = msg.sender;
        // operator = _operator;
        // operator_2 = _operator_2;

        title = _title;
        questions_in_json_string = _questions_in_json_string;
        opening_time = _opening_time;
        closing_time = _closing_time;
        num_of_questions = _num_of_questions;
        max_options = _max_options; // start from 0, but options index start from 1, reserve 0 for empty answer
        max_votes = _max_votes;
        amount_of_rewards = _amount_of_rewards;
        show_result_after_close = _show_result_after_close;
        current_votes = 0;
        num_of_batch_allowed = 100;

        loadOptions(_options);
    }

    function loadOptions(bytes32[] memory _options) private {
        uint256 i = 0;
        uint256 j = 0;
        while (i < num_of_questions) {
            while (j < max_options) {
                options[i][j] = _options[i * max_options + j];
                j = add(j, 1);
            }
            j = 0;
            i = add(i, 1);
        }
    }

    // _voter_batch = [ voter_1, voter_2 ... voter_10 ]
    // _option_id_batch = [ op_id_1_of_voter_1, op_id_2_of_voter_1, ... op_id_10_of_voter_1, ... op_id_1_of_voter_2, op_id_2_of_voter_2, ... op_id_10_of_voter_100 ]
    // _voter_address_batch = [ addr_of_voter_1, addr_of_voter_2 ... addr_of_voter_10 ]

    function batch_vote(uint256[] memory _voter_batch, uint256[] memory _option_id_batch, address[] memory _voter_address_batch) onlyWhileOpen public {
        // check we can do vote
        if (max_votes > 0) {
            require(current_votes < max_votes);
        }

        uint256 index_of_votes = 0; // vote results
        uint256 index_of_questions = 0; // option id in result

        while (index_of_votes < _voter_batch.length) {
            if (voted[ _voter_batch[ index_of_votes ] ] && allowing_update_after_voted == false) {
                index_of_votes = add(index_of_votes, 1);
                continue;
            }

            if (max_votes > 0) {
                if (current_votes >= max_votes) {
                    // stop here
                    index_of_votes = add(index_of_votes, 1);
                    continue;
                }
            }

            voted[ _voter_batch[ index_of_votes ] ] = true;
            voter_addresses[ current_votes ] = _voter_address_batch[ index_of_votes ];

            while (index_of_questions < num_of_questions) {
                votes[_voter_batch[ index_of_votes ]][ index_of_questions ] = _option_id_batch[ index_of_votes * num_of_questions + index_of_questions ];

                if (_option_id_batch[ index_of_votes * num_of_questions + index_of_questions ] != 0) {
                    count_of_options[index_of_questions][_option_id_batch[ index_of_votes * num_of_questions + index_of_questions ]] = add(count_of_options[index_of_questions][_option_id_batch[ index_of_votes * num_of_questions + index_of_questions ]], 1);
                }

                emit Voted(_voter_batch[ index_of_votes ], votes[_voter_batch[ index_of_votes ]][ index_of_questions ]);

                index_of_questions = add(index_of_questions, 1);
            }
            index_of_questions = 0;

            current_votes = add(current_votes, 1);
            index_of_votes = add(index_of_votes, 1);

        }
    }

    function vote(uint256 _voter, uint256[] memory _option_id, address _voter_address) onlyWhileOpen public {
        require(!voted[_voter]);
        if (max_votes > 0) {
            require(current_votes < max_votes);
        }
        voted[_voter] = true;
        voter_addresses[current_votes] = _voter_address;
        // mapping (uint256 => mapping (uint256 => uint256)) votes; // vote_for_certain_question = votes[voter_id][question_index]
        // mapping (uint256 => mapping (uint256 => uint256)) count_of_options; // vote_count_for_certain_option = options[question_index][option_index]
        uint256 i = 0;
        while (i < _option_id.length) {
            votes[_voter][i] = _option_id[i];
            count_of_options[i][_option_id[i]] = add(count_of_options[i][_option_id[i]], 1);

            emit Voted(_voter, votes[_voter][i] = _option_id[i]);
            i = add(i, 1);
        }

        current_votes = add(current_votes, 1);
    }

    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
    }

    function changeCloseTime(uint256 _closing_time) external onlyOwner {
        require(_closing_time >= block.timestamp);
        require(_closing_time >= opening_time);
        closing_time = _closing_time;
    }

    function changeMaxVotes(uint256 _max_votes) external onlyOwner {
        require(_max_votes >= 0);
        if (_max_votes > 0) {
            require(_max_votes >= current_votes);
        }
        max_votes = _max_votes;
    }

    function retrieveResults(uint256 _question_index) public view returns (uint256[] memory) {
        uint256[] memory _results = new uint256[](max_options);
        uint256 i = 0;
        if (show_result_after_close && !isClosed()) {
            _results[0] = 0;
        } else {
            while (i < max_options) {
                _results[i] = count_of_options[_question_index][i];
                i = add(i, 1);
            }
        }
        return _results;
    }

    function retrieveVotes(uint256 _voter) public view returns (uint256[] memory) {
        uint256[] memory _votes = new uint256[](num_of_questions);
        uint256 i = 0;
        while (i < num_of_questions) {
            _votes[i] = votes[_voter][i];
            i = add(i, 1);
        }
        return _votes;
    }

    function hasOpened() public view returns (bool) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp >= opening_time;
    }

    // function amountOfRewardsStored() public view returns (uint256) {
    //     // solium-disable-next-line security/no-block-members
    //     return address(this).balance;
    // }

    // function rewardsFilled() public view returns (bool) {
    //     return address(this).balance >= amount_of_rewards;
    // }

    function hasClosed() public view returns (bool) {
        // solium-disable-next-line security/no-block-members
        return isClosed();
    }

    // function checkRewards() onlyAfterClose external returns (uint256 rewardAmount) {
    //     require(!rewards_sent);

    //     uint256 i = 0;
    //     uint256 rewards = div(address(this).balance, current_votes);
    //     while (i < current_votes) {
    //         voter_addresses[i].transfer(rewards);
    //         i = add(i, 1);
    //     }
    //     rewards_sent = true;
    //     return rewards;
    // }
}