pragma solidity ^0.4.23;


contract Random {

    uint public ticketsNum = 0;
    
    mapping(uint => address) internal tickets;
    mapping(uint => bool) internal payed_back;
    
    uint32 public random_num = 0;
 
    uint public liveBlocksNumber = 5760;
    uint public startBlockNumber = 0;
    uint public endBlockNumber = 0;
    
    string public constant name = "Random Daily Lottery";
    string public constant symbol = "RND";
    uint   public constant decimals = 0;

    uint public constant onePotWei = 10000000000000000; // 1 ticket cost is 0.01 ETH

    address public inv_contract = 0x1d9Ed8e4c1591384A4b2fbd005ccCBDc58501cc0; // investing contract
    address public rtm_contract = 0x67e5e779bfc7a93374f273dcaefce0db8b3559c2; // team contract
    
    address manager; 
    
    uint public winners_count = 0; 
    uint public last_winner = 0; 
    uint public others_prize = 0;
    
    uint public fee_balance = 0; 
    bool public autopayfee = true;

    // Events
    // This generates a publics event on the blockchain that will notify clients
    
    event Buy(address indexed sender, uint eth); 
    event Withdraw(address indexed sender, address to, uint eth); 
    event Transfer(address indexed from, address indexed to, uint value); 
    event TransferError(address indexed to, uint value); // event (error): sending ETH from the contract was failed
    event PayFee(address _to, uint value);
    
    
    

    // methods with following modifier can only be called by the manager
    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }
    

    // constructor
    constructor() public {
        manager = msg.sender;
        startBlockNumber = block.number - 1;
        endBlockNumber = startBlockNumber + liveBlocksNumber;
    }


    /// function for straight tickets purchase (sending ETH to the contract address)

    function() public payable {
        emit Transfer(msg.sender, 0, 0);
        require(block.number < endBlockNumber || msg.value < 1000000000000000000);  
        if (msg.value > 0 && last_winner == 0) { 
            uint val =  msg.value / onePotWei;  
            uint i = 0;
            for(i; i < val; i++) { tickets[ticketsNum+i] = msg.sender; }  
            ticketsNum += val;                                    
            emit Buy(msg.sender, msg.value);                      
        }
        if (block.number >= endBlockNumber) { 
            EndLottery(); 
        }
    }
    
    /// function for ticket sending from owner&#39;s address to designated address
    function transfer(address _to, uint _ticketNum) public {    
        require(msg.sender == tickets[_ticketNum] && _to != address(0));
        tickets[_ticketNum] = _to;
        emit Transfer(msg.sender, _to, _ticketNum);
    }


    /// manager&#39;s opportunity to write off ETH from the contract, in a case of unforseen contract blocking (possible in only case of more than 24 hours from the moment of lottery ending had passed and a new one has not started)
    function manager_withdraw() onlyManager public {
        require(block.number >= endBlockNumber + liveBlocksNumber);
        msg.sender.transfer(address(this).balance);
    }
    
    /// lottery ending  
    function EndLottery() public payable returns (bool success) {
        require(block.number >= endBlockNumber); 
        uint tn = ticketsNum;
        if(tn < 3) { 
            tn = 0;
            if(msg.value > 0) { msg.sender.transfer(msg.value); }  
            startNewDraw(0);
            return false;
        }
        uint pf = prizeFund(); 
        uint jp1 = percent(pf, 10);
        uint jp2 = percent(pf, 4);
        uint jp3 = percent(pf, 1);
        uint lastbet_prize = onePotWei*10;  

        if(tn < 100) { lastbet_prize = onePotWei; }
        
        if(last_winner == 0) { 
            
            winners_count = percent(tn, 4) + 3; 

            uint prizes = jp1 + jp2 + jp3 + lastbet_prize*2; 
            
            uint full_prizes = jp1 + jp2 + jp3 + ( lastbet_prize * (winners_count+1)/10 );
            
            if(winners_count < 10) {
                if(prizes > pf) {
                    others_prize = 0;
                } else {
                    others_prize = pf - prizes;    
                }
            } else {
                if(full_prizes > pf) {
                    others_prize = 0;
                } else {
                    others_prize = pf - full_prizes;    
                }
            }
            sendEth(tickets[getWinningNumber(1)], jp1);
            sendEth(tickets[getWinningNumber(2)], jp2);
            sendEth(tickets[getWinningNumber(3)], jp3);
            last_winner += 3;
            
            sendEth(msg.sender, lastbet_prize + msg.value);
            return true;
        } 
        
        if(last_winner < winners_count && others_prize > 0) {
            
            uint val = others_prize / winners_count;
            uint i;
            uint8 cnt = 0;
            for(i = last_winner; i < winners_count; i++) {
                sendEth(tickets[getWinningNumber(i+3)], val);
                cnt++;
                if(cnt >= 9) {
                    last_winner = i;
                    return true;
                }
            }
            last_winner = i;
            if(cnt < 9) { 
                startNewDraw(lastbet_prize + msg.value); 
            } else {
                sendEth(msg.sender, lastbet_prize + msg.value);
            }
            return true;
            
        } else {

            startNewDraw(lastbet_prize + msg.value);
        }
        
        return true;
    }
    
    /// new draw start
    function startNewDraw(uint _msg_value) internal { 
        ticketsNum = 0;
        startBlockNumber = block.number - 1;
        endBlockNumber = startBlockNumber + liveBlocksNumber;
        random_num += 1;
        winners_count = 0;
        last_winner = 0;
        
        fee_balance = subZero(address(this).balance, _msg_value); 
        if(msg.value > 0) { sendEth(msg.sender, _msg_value); }
        // fee_balance = address(this).balance;
        
        if(autopayfee) { _payfee(); }
    }
    
    /// sending rewards to the investing, team and marketing contracts 
    function payfee() public {   
        require(fee_balance > 0);
        uint val = fee_balance;
        
        RNDInvestor rinv = RNDInvestor(inv_contract);
        rinv.takeEther.value( percent(val, 25) )();
        rtm_contract.transfer( percent(val, 74) );
        fee_balance = 0;
        
        emit PayFee(inv_contract, percent(val, 25) );
        emit PayFee(rtm_contract, percent(val, 74) );
    }
    
    function _payfee() internal {
        if(fee_balance <= 0) { return; }
        uint val = fee_balance;
        
        RNDInvestor rinv = RNDInvestor(inv_contract);
        rinv.takeEther.value( percent(val, 25) )();
        rtm_contract.transfer( percent(val, 74) );
        fee_balance = 0;
        
        emit PayFee(inv_contract, percent(val, 25) );
        emit PayFee(rtm_contract, percent(val, 74) );
    }
    
    /// function for sending ETH with balance check (does not interrupt the program if balance is not sufficient)
    function sendEth(address _to, uint _val) internal returns(bool) {
        if(address(this).balance < _val) {
            emit TransferError(_to, _val);
            return false;
        }
        _to.transfer(_val);
        emit Withdraw(address(this), _to, _val);
        return true;
    }
    
    
    /// get winning ticket number basing on block hasg (block number is being calculated basing on specified displacement)
    function getWinningNumber(uint _blockshift) internal constant returns (uint) {
        return uint(blockhash(endBlockNumber - _blockshift)) % ticketsNum + 1;  
    }
    

    /// current amount of jack pot 1
    function jackPotA() public view returns (uint) {  
        return percent(prizeFund(), 10);
    }
    
    /// current amount of jack pot 2
    function jackPotB() public view returns (uint) {
        return percent(prizeFund(), 4);
    }
    

    /// current amount of jack pot 3
    function jackPotC() public view returns (uint) {
        return percent(prizeFund(), 1);
    }

    /// current amount of prize fund
    function prizeFund() public view returns (uint) {
        return ( (ticketsNum * onePotWei) / 100 ) * 90;
    }

    /// function for calculating definite percent of a number
    function percent(uint _val, uint _percent) public pure returns (uint) {
        return ( _val * _percent ) / 100;
    }


    /// returns owner address using ticket number
    function getTicketOwner(uint _num) public view returns (address) { 
        if(ticketsNum == 0) {
            return 0;
        }
        return tickets[_num];
    }

    /// returns amount of tickets for the current draw in the possession of specified address
    function getTicketsCount(address _addr) public view returns (uint) {
        if(ticketsNum == 0) {
            return 0;
        }
        uint num = 0;
        for(uint i = 0; i < ticketsNum; i++) {
            if(tickets[i] == _addr) {
                num++;
            }
        }
        return num;
    }
    
    /// returns amount of tickets for the current draw in the possession of specified address
    function balanceOf(address _addr) public view returns (uint) {
        if(ticketsNum == 0) {
            return 0;
        }
        uint num = 0;
        for(uint i = 0; i < ticketsNum; i++) {
            if(tickets[i] == _addr) {
                num++;
            }
        }
        return num;
    }
    
    /// returns tickets numbers for the current draw in the possession of specified address
    function getTicketsAtAdress(address _address) public view returns(uint[]) {
        uint[] memory result = new uint[](getTicketsCount(_address)); 
        uint num = 0;
        for(uint i = 0; i < ticketsNum; i++) {
            if(tickets[i] == _address) {
                result[num] = i;
                num++;
            }
        }
        return result;
    }


    /// returns amount of paid rewards for the current draw
    function getLastWinner() public view returns(uint) {
        return last_winner+1;
    }


    // /// investing contract address change
    // function setInvContract(address _addr) onlyManager public {
    //     inv_contract = _addr;
    // }

    /// team contract address change
    function setRtmContract(address _addr) onlyManager public {
        rtm_contract = _addr;
    }
    
    function setAutoPayFee(bool _auto) onlyManager public {
        autopayfee = _auto;
    }

   
    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function blockLeft() public view returns (uint256) {
        if(endBlockNumber > block.number) {
            return endBlockNumber - block.number;    
        }
        return 0;
    }

    /// method for direct contract replenishment with ETH
    function deposit() public payable {
        require(msg.value > 0);
    }



    ///Math functions

    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }
    
    function subZero(uint a, uint b) internal pure returns (uint) {
        if(a < b) {
            return 0;
        }
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c>=a && c>=b);
        return c;
    }
    
    
    function destroy() public onlyManager {
        selfdestruct(manager);
    }
    

}


/**
* @title Random Investor Contract
* @dev The Investor token contract
*/

contract RNDInvestor {
   
    address public owner; // Token owner address
    mapping (address => uint256) public balances; // balanceOf
    address[] public addresses;

    mapping (address => uint256) public debited;

    mapping (address => mapping (address => uint256)) allowed;

    string public standard = &#39;Random 1.1&#39;;
    string public constant name = "Random Investor Token";
    string public constant symbol = "RINVEST";
    uint   public constant decimals = 0;
    uint   public constant totalSupply = 2500;
    uint   public raised = 0;

    uint public ownerPrice = 1 ether;
    uint public soldAmount = 0; // current sold amount (for current state)
    bool public buyAllowed = true;
    bool public transferAllowed = false;
    
    State public current_state; // current token state
    
    // States
    enum State {
        Presale,
        ICO,
        Public
    }

    //
    // Events
    // This generates a publics event on the blockchain that will notify clients
    
    event Sent(address from, address to, uint amount);
    event Buy(address indexed sender, uint eth, uint fbt);
    event Withdraw(address indexed sender, address to, uint eth);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Raised(uint _value);
    event StateSwitch(State newState);
    
    //
    // Modifiers

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyIfAllowed() {
        if(!transferAllowed) { require(msg.sender == owner); }
        _;
    }

    //
    // Functions
    // 

    // Constructor
    function RNDInvestor() public {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }

    // fallback function
    function() payable public {
        if(current_state == State.Public) {
            takeEther();
            return;
        }
        
        require(buyAllowed);
        require(msg.value >= ownerPrice);
        require(msg.sender != owner);
        
        uint wei_value = msg.value;

        // uint tokens = safeMul(wei_value, ownerPrice);
        uint tokens = wei_value / ownerPrice;
        uint cost = tokens * ownerPrice;
        
        if(current_state == State.Presale) {
            tokens = tokens * 2;
        }
        
        uint currentSoldAmount = safeAdd(tokens, soldAmount);

        if (current_state == State.Presale) {
            require(currentSoldAmount <= 1000);
        }
        
        require(balances[owner] >= tokens);
        
        balances[owner] = safeSub(balances[owner], tokens);
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        soldAmount = safeAdd(soldAmount, tokens);
        
        uint extra_ether = safeSub(msg.value, cost); 
        if(extra_ether > 0) {
            msg.sender.transfer(extra_ether);
        }
    }
    
    
    function takeEther() payable public {
        if(msg.value > 0) {
            raised += msg.value;
            emit Raised(msg.value);
        } else {
            withdraw();
        }
    }
    
    function setOwnerPrice(uint _newPrice) public
        onlyOwner
        returns (bool success)
    {
        ownerPrice = _newPrice;
        return true;
    }
    
    function setTokenState(State _nextState) public
        onlyOwner
        returns (bool success)
    {
        bool canSwitchState
            =  (current_state == State.Presale && _nextState == State.ICO)
            || (current_state == State.Presale && _nextState == State.Public)
            || (current_state == State.ICO && _nextState == State.Public) ;

        require(canSwitchState);
        
        current_state = _nextState;

        emit StateSwitch(_nextState);

        return true;
    }
    
    function setBuyAllowed(bool _allowed) public
        onlyOwner
        returns (bool success)
    {
        buyAllowed = _allowed;
        return true;
    }
    
    function allowTransfer() public
        onlyOwner
        returns (bool success)
    {
        transferAllowed = true;
        return true;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
      if (newOwner != address(0)) {
        owner = newOwner;
      }
    }

    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }
    
    function safeSub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c>=a && c>=b);
        return c;
    }

    function withdraw() public returns (bool success) {
        uint val = ethBalanceOf(msg.sender);
        if(val > 0) {
            msg.sender.transfer(val);
            debited[msg.sender] += val;
            return true;
        }
        return false;
    }



    function ethBalanceOf(address _investor) public view returns (uint256 balance) {
        uint val = (raised / totalSupply) * balances[_investor];
        if(val >= debited[_investor]) {
            return val - debited[_investor];
        }
        return 0;
    }


    function manager_withdraw() onlyOwner public {
        uint summ = 0;
        for(uint i = 0; i < addresses.length; i++) {
            summ += ethBalanceOf(addresses[i]);
        }
        require(summ < address(this).balance);
        msg.sender.transfer(address(this).balance - summ);
    }

    
    function manual_withdraw() public {
        for(uint i = 0; i < addresses.length; i++) {
            addresses[i].transfer( ethBalanceOf(addresses[i]) );
        }
    }


    function checkAddress(address _addr) public
        returns (bool have_addr)
    {
        for(uint i=0; i<addresses.length; i++) {
            if(addresses[i] == _addr) {
                return true;
            }
        }
        addresses.push(_addr);
        return true;
    }
    

    function destroy() public onlyOwner {
        selfdestruct(owner);
    }


    /**
     * ERC 20 token functions
     *
     * https://github.com/ethereum/EIPs/issues/20
     */
    
    function transfer(address _to, uint256 _value) public
        onlyIfAllowed
        returns (bool success) 
    {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            checkAddress(_to);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public
        onlyIfAllowed
        returns (bool success)
    {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            checkAddress(_to);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }


    function approve(address _spender, uint256 _value) public
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public
        constant returns (uint256 remaining)
    {
      return allowed[_owner][_spender];
    }
    
    
    
}