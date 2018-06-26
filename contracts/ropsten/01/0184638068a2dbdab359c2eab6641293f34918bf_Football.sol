pragma solidity ^0.4.24;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Football {
    using SafeMath for uint256;
    
    address public initialHolder;
    uint256 public percent_of_commission;
    
    mapping (address => uint256) bets_team_1;
    mapping (address => uint256) bets_team_2;
    
    uint256 public coefficient_team_1;
    uint256 public coefficient_team_2;
    
    bool public is_started;
    bool public is_payment_to_users;
    uint8 public winner;
    uint256 public min_bet;
    
    uint256 public amount_bets_on_team_1;
    uint256 public amount_bets_on_team_2;
    
    address[] public users_on_team_1;
    address[] public users_on_team_2;
    
    uint256 private oneHandred = 100;
    
    uint dot;
    
    function Football(){
        dot = 1000;
        percent_of_commission = 10;
        initialHolder = msg.sender;
        coefficient_team_1 = 0;
        coefficient_team_2 = 0;
        amount_bets_on_team_1 = 0;
        amount_bets_on_team_2 = 0;
        is_started = false;
        min_bet = 10000000000000000;
        // 0 - game not started, 1 - team 1 is winner, 2 - team 2 is winner
        winner = 0;
        is_payment_to_users = false;
    }
    
    modifier onlyOwner() {
        require(msg.sender == initialHolder);
        _;
    }
    
    modifier isGameStarted() {
        require(is_started == false);
        _;
    }
    
    modifier isGameEnded() {
        require(winner == 1 || winner == 2);
        _;
    }
    
    modifier isPaymentToUsers() {
        require(is_payment_to_users == true);
        _;
    }
    
    modifier isRegisteredCMD1(address _address) {
        require(bets_team_1[_address] == 0);
        _;
    }
    
    modifier isRegisteredCMD2(address _address) {
        require(bets_team_2[_address] == 0);
        _;
    }
    
    modifier moreThenMinBet() {
        require(msg.value >= min_bet);
        _;
    }
  
    function bet_on_team_1() payable public
    moreThenMinBet()
    isRegisteredCMD1(msg.sender) 
    isRegisteredCMD2(msg.sender)
    isGameStarted()
    {
        bets_team_1[msg.sender] = msg.value.mul(oneHandred.sub(percent_of_commission)).div(oneHandred);
        amount_bets_on_team_1 += msg.value.mul(oneHandred.sub(percent_of_commission)).div(oneHandred);
        users_on_team_1.push(msg.sender);
        update_coeff();
    }
    
    function bet_on_team_2() payable public
    moreThenMinBet()
    isRegisteredCMD1(msg.sender) 
    isRegisteredCMD2(msg.sender)
    isGameStarted()
    {
        bets_team_2[msg.sender] = msg.value.mul(oneHandred.sub(percent_of_commission)).div(oneHandred);
        amount_bets_on_team_2 += msg.value.mul(oneHandred.sub(percent_of_commission)).div(oneHandred);
        users_on_team_2.push(msg.sender);
        update_coeff();
    }
    
    function get_bet(address _address) public constant returns (uint balance) {
        if (bets_team_1[_address] > 0) {
            return bets_team_1[_address];
        } else if (bets_team_2[_address] > 0) {
            return bets_team_2[_address];
        }
    }
    
    function update_coeff() public {

        if (amount_bets_on_team_1 != 0){
            coefficient_team_1 = (amount_bets_on_team_1.add(amount_bets_on_team_2).mul(dot)).div(amount_bets_on_team_1);
        }
        if (amount_bets_on_team_2 != 0){
            coefficient_team_2 = (amount_bets_on_team_1.add(amount_bets_on_team_2).mul(dot)).div(amount_bets_on_team_2);
        }
        
    }

    function request_payout_holder()
    onlyOwner()
    isGameEnded()
    isPaymentToUsers()
    public
    {
        initialHolder.transfer(address(this).balance);
    }
    
    function request_payout_users()
    isGameEnded()
    public
    {
        uint128 i;
        uint256 amount;
        if (winner == 1) {
            for(i = 0; i < users_on_team_1.length; i++){
                amount = bets_team_1[users_on_team_1[i]].mul(coefficient_team_1).div(dot);
                users_on_team_1[i].transfer(amount);
            }
            is_payment_to_users = true;
        }
    
        if (winner == 2) {
            for(i = 0; i < users_on_team_2.length; i++){
                amount = bets_team_2[users_on_team_2[i]].mul(coefficient_team_2).div(dot);
                users_on_team_2[i].transfer(amount);
            }
            is_payment_to_users = true;
        }
    }
    
    function start_game()
    onlyOwner()
    public
    {
        is_started = true;
    }
    
    function get_contract_money() 
    onlyOwner()
    public constant 
    returns (uint256)
    {
        return address(this).balance;
    }
    
    function set_result_of_game(uint8 _winner)
    onlyOwner()
    public
    {
        if (_winner == 1 || _winner == 2) {
            winner = _winner;
        }
    }
}