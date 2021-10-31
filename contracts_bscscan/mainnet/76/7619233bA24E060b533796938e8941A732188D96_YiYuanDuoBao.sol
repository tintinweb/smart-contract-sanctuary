/**
 *Submitted for verification at BscScan.com on 2021-10-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract YiYuanDuoBao {
    
    uint constant divisor = 10000;
    uint constant max_tickets = 10000000;
    
    address[max_tickets] private tickets;
    // Owner address
    address owner;
    // Manager address
    address manager;
   
    uint[] public winning_numbers;
    address[] public winning_addrs;
    uint[] public claimed;
    uint public current_num_of_people;
    // Number of tickets
    uint public num_of_tickets;
    
    uint public current_round;
    uint public pay_out_ratio;
    address public tokenAddress;
    uint public ticket_price;
    uint public total_funds;
    uint private randNonce;
    
    
    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);
    event Prize(address indexed user, uint round);
    event Claim(address indexed user, uint round);
    
    constructor(address tokenAddress_){
        owner = msg.sender;
        manager = msg.sender;
        current_round = 0;
        pay_out_ratio = 10000;
        current_num_of_people=0;
        randNonce = 12345;
        total_funds = 0;
        tokenAddress=tokenAddress_;
        ticket_price = 1e18;
        num_of_tickets = 1000;
    }
    
    // Define onlyOwner modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not admin");
        _;
    }

    // Define onlyOwnerOrManager modifier
    modifier onlyOwnerOrManager() {
        require(msg.sender == owner || msg.sender == manager, "You are not admin or manager");
        _;
    }

    function transferManager(address newManger) public onlyOwner {
        require(newManger != address(0), "manager cannot be null");
        manager = newManger;
    }
    
    function setNumOfTickets(uint32 num) public onlyOwnerOrManager {
        require(num <= max_tickets, "Cannot have too many tickets!");
        require(num > 0, "Cannot have 0 tickets!");
        num_of_tickets=num;
    }
    
    function setPayOutRatio(uint32 num) public onlyOwnerOrManager {
        require(num <= divisor, "Cannot pay more than divisor!");
        pay_out_ratio=num;
    }
    
    function setTicketPrice(uint num) public onlyOwnerOrManager {
        require(num > 0, "Cannot set price to 0!");
        require(num < 1e37, "Cannot set price to a large number!");
        ticket_price=num;
    }
    
    function payOut(address winner) public onlyOwnerOrManager {
        IERC20 token = IERC20(tokenAddress);
        uint amount = total_funds * pay_out_ratio / divisor;
        total_funds -= amount;
        require(token.transfer(winner, amount), "Token transfer failed");
        emit Withdraw(winner, amount);
     }
     
     function enterLottery(uint num_of_t) public {
        require(num_of_t > 0, "You must buy at least 1 ticket!");
        require(num_of_t < 51, "You cannot buy more than 50 ticket at once!");
        require(num_of_t + current_num_of_people <= num_of_tickets, "Not enough tickets left!");
        uint total_price = ticket_price * num_of_t;
        
        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), total_price), "Token transfer failed");
        
        uint new_num_of_people = current_num_of_people + num_of_t;
        for (uint i=current_num_of_people; i<new_num_of_people; i++) {
            tickets[i] = msg.sender;
        }
        current_num_of_people=new_num_of_people;
        total_funds += total_price;
        emit Deposit(msg.sender, total_price);
     }
    
    function runLottery() public onlyOwnerOrManager {
        require(current_num_of_people == num_of_tickets, "Not enough people attending!");
        // Randomly generated lottery number          
        randNonce = uint(keccak256(abi.encode(block.timestamp, current_round, randNonce)));
        uint number = randNonce % current_num_of_people;
        winning_numbers.push(number);
        address winner = tickets[number];
        winning_addrs.push(winner);
        claimed.push(1);
        current_round = current_round +1;
        current_num_of_people = 0;
        emit Prize(winner, current_round-1);
    }
    
    function view_tickets(address addr) public view returns(uint){
        uint ts=0;
        for (uint i=0; i<current_num_of_people; i++) {
            if (tickets[i] == addr){
                ts +=1;
            }
        }
        return ts;
    }
    
    function check_winner(address addr) public view returns(bool){
        for (uint i=0; i<current_round; i++) {
            if (winning_addrs[i] == addr){
                if (claimed[i]==1) {
                    return true;
                }
            }
        }
        return false;
    }
    
    function claim(uint round) public {
        require(round < current_round, "Current round not ended!");
        require(round >=0, "Round must be non-negative!");
        uint c = claimed[round];
        require(c == 1, "Already Claimed!");
        address a = winning_addrs[round];
        require(msg.sender == a, "You did not win this round!");
        claimed[round] = 2;
    }
    
    /*
     * Get owner address
     */
    function getOwner() public view returns(address) {
        return owner;
    }
    
    /*
     * Get manager address
     */
    function getManager() public view returns(address) {
        return manager;
    }
    
 }