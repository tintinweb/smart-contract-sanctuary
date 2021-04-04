/**
 *Submitted for verification at Etherscan.io on 2021-04-04
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title The Button
 * @dev Pay a fee to the pot to press the button. After a press, the timer is reset. When the timer times out, the last person to press the button wins the pot.
 */
contract Button {

    uint256 public immutable button_press_cost; // recommended: 10000000000000000 (0.01 ETH)
    uint256 public immutable timer_duration; // recommended: 7200 to 172800 (2 hours to 2 days)

    uint256 start_date;
    uint64 iteration;
    bool public game_in_progress;
    uint256 last_press_date;
    address payable last_press_addr;


    modifier correctPayment {
        require(msg.value == button_press_cost);
        _;
    }
    modifier activeGame {
        require(game_in_progress);
        _;
    }

    event Button_press(address presser, uint64 _iteration);
    event Win(address winner, uint256 amount, uint64 _iteration);
    event New_game(uint256 _button_press_cost, uint256 _timer_duration, uint64 _iteration);


    constructor(uint256 _button_press_cost, uint256 _timer_duration) {
        button_press_cost = _button_press_cost;
        timer_duration = _timer_duration;
        start_date = block.timestamp;
        iteration = 0;
        game_in_progress = false;
        last_press_date = block.timestamp;
        last_press_addr = payable(msg.sender);
    }


    /**
     * @dev Press the button with the right amount of ETH to start a new game
     */
    function first_press() payable public correctPayment {
        require(! game_in_progress);
        start_date = block.timestamp;
        iteration = iteration + 1;
        game_in_progress = true;
        emit New_game(button_press_cost, timer_duration, iteration);
        emit Button_press(msg.sender, iteration);
        last_press_date = block.timestamp;
        last_press_addr = payable(msg.sender);
    }

    /**
     * @dev Press the button on behalf of someone else with the right amount of ETH to start a new game
     */
    function first_press(address on_behalf_of) payable public correctPayment {
        require(! game_in_progress);
        start_date = block.timestamp;
        iteration = iteration + 1;
        game_in_progress = true;
        emit New_game(button_press_cost, timer_duration, iteration);
        emit Button_press(on_behalf_of, iteration);
        last_press_date = block.timestamp;
        last_press_addr = payable(on_behalf_of);
    }

    /**
     * @dev Press the button with the right amount of ETH
     */
    function press() payable public correctPayment activeGame {
        require(block.timestamp - last_press_date < timer_duration);
        emit Button_press(msg.sender, iteration);
        last_press_date = block.timestamp;
        last_press_addr = payable(msg.sender);
    }

    /**
     * @dev Press the button with the right amount of ETH as part of a specific game iteration
     */
    function press(uint64 _iteration) payable public correctPayment activeGame {
        require(_iteration == iteration && block.timestamp - last_press_date < timer_duration);
        emit Button_press(msg.sender, iteration);
        last_press_date = block.timestamp;
        last_press_addr = payable(msg.sender);
    }

    /**
     * @dev Press the button on behalf of someone else with the right amount of ETH as part of a specific game iteration
     */
    function press(address on_behalf_of, uint64 _iteration) payable public correctPayment activeGame {
        require(_iteration == iteration && block.timestamp - last_press_date < timer_duration);
        emit Button_press(on_behalf_of, iteration);
        last_press_date = block.timestamp;
        last_press_addr = payable(on_behalf_of);
    }

    /**
     * @dev Reward the current game winner if the game has ended
     */
    function claim() public activeGame {
        require(block.timestamp - last_press_date >= timer_duration);
        emit Win(last_press_addr, address(this).balance, iteration);
        last_press_addr.transfer(address(this).balance);
        game_in_progress = false;
    }


    /**
     * @dev Return the current value of the pot
     * @return value of the pot
     */
    function view_jackpot() public view activeGame returns (uint256, uint64){
        return (address(this).balance, iteration);
    }

    /**
     * @dev Return how long has the current game been running for
     * @return age of the current game
     */
    function current_game_age() public view activeGame returns (uint256, uint64){
        return (block.timestamp - start_date, iteration);
    }

    /**
     * @dev Return the current value of the timer. When it reaches 0, the game ends.
     * @return timer value
     */
    function time_left() public view activeGame returns (uint256, uint64){
        if(last_press_date + timer_duration > block.timestamp){
            return (last_press_date + timer_duration - block.timestamp, iteration);
        }
        return (0, iteration);
    }

    /**
     * @dev Return the current iteration of the game
     * @return game iteration
     */
    function view_iteration() public view activeGame returns (uint64){
        return iteration;
    }

    /**
     * @dev Return the current candidate for winning the jackpot. Better press that button quickly if you wanna take their place...
     * @return current winning candidate
     */
    function view_candidate() public view activeGame returns (address, uint64){
        return (last_press_addr, iteration);
    }
}