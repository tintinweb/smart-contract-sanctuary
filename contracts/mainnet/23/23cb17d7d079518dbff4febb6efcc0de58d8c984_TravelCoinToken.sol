//ERC20 Token customised for travelcoins
pragma solidity ^0.4.2;
contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract token {
    /* Public variables of the token */
    string public standard = &#39;TRV 0.1&#39;;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Allocate(address from,address to, uint value,uint price,bool equals);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function token(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /* A contract attempts _ to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;   // Check allowance
        balanceOf[_from] -= _value;                          // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    /* This unnamed function is called whenever someone tries to send ether to it */
    function () {
        throw;     // Prevents accidental sending of ether
    }
}

contract TravelCoinToken is owned, token {

    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping(address=>bool) public frozenAccount;
    mapping(address=>uint) public rewardPoints;
    mapping(address=>bool) public oneTimeTickets;
    mapping (address => bool) public oneTimeSold;
    address[] public ONETIMESOLD;


    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    uint256 public constant initialSupply = 200000 * 10**16;
    uint8 public constant decimalUnits = 16;
    string public tokenName = "TravelCoin";
    string public tokenSymbol = "TRV";
    function TravelCoinToken() token (initialSupply, tokenName, decimalUnits, tokenSymbol) {}

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        if (frozenAccount[msg.sender]) throw;                // Check if frozen
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        if(ticket_address_added[_to]){
            if(_value>=tickets[_to].price){
                if(oneTimeSold[_to]) throw;
                if(oneTimeTickets[_to]){
                    oneTimeSold[_to] = true;
                    ONETIMESOLD.push(_to);
                }
                allocateTicket(msg.sender,_to);
                rewardPoints[msg.sender]+=tickets[_to].reward_pts;
                Allocate(msg.sender,_to,_value,tickets[_to].price,_value>=tickets[_to].price);
                //this Allocate event is a customised test
            }
        }
    }


    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (frozenAccount[_from]) throw;                        // Check if frozen
        if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;   // Check allowance
        balanceOf[_from] -= _value;                          // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() payable {
        uint amount = msg.value / buyPrice;                // calculates the amount
        if (balanceOf[this] < amount) throw;               // checks if it has enough to sell
        balanceOf[msg.sender] += amount;                   // adds the amount to buyer&#39;s balance
        balanceOf[this] -= amount;                         // subtracts amount from seller&#39;s balance
        Transfer(this, msg.sender, amount);                // execute an event reflecting the change
    }

    function sell(uint256 amount) {
        if (balanceOf[msg.sender] < amount ) throw;        // checks if the sender has enough to sell
        balanceOf[this] += amount;                         // adds the amount to owner&#39;s balance
        balanceOf[msg.sender] -= amount;                   // subtracts the amount from seller&#39;s balance
        if (!msg.sender.send(amount * sellPrice)) {        // sends ether to the seller. It&#39;s important
            throw;                                         // to do this last to avoid recursion attacks
        } else {
            Transfer(msg.sender, this, amount);            // executes an event reflecting on the change
        }
    }

    //Lavi&#39;s additional dApp code start
    struct ticket{
        uint price;
        // bytes32 destination;
        // bytes32 starting_point;
        address _company_addr;
        // uint ticket_no;
        // bytes32 ticket_name;
        // bytes32 times;
        // uint land_time;
        // uint topup;
        uint reward_pts;
        // uint expriration_time;
        // bytes32 promo_no;
        // bytes32 insurance_no;
        // bytes32 category;
    }

    mapping(address=>ticket) public tickets;
    mapping(address=>bool) public ticket_address_added;
    mapping(address=>address[]) public customer_tickets;
    address[] public ticket_addresses;

    function addNewTicket(
        // bytes32 category,
        address ticket_address,
        uint price,
        // bytes32 to,
        // bytes32 from,
        // uint ticket_no,
        // bytes32 ticket_name,
        // bytes32 times,
        // uint land_time,
        // uint topup,
        uint reward_pts,
        bool oneTime
        // uint expriration_time,
        // bytes32 promo_no,
        // bytes32 insurance_no
        )
    {
        if(ticket_address_added[ticket_address]) throw;
        ticket memory newTicket;
        // newTicket.category = category;
        newTicket.price = price;
        // newTicket.destination = to;
        // newTicket.starting_point = from;
        newTicket._company_addr = ticket_address;
        // newTicket.ticket_no = ticket_no;
        // newTicket.ticket_name = ticket_name;
        // newTicket.times = times;
        // newTicket.land_time = land_time;
        // newTicket.topup = topup;
        newTicket.reward_pts = reward_pts;
        if(oneTime)
            oneTimeTickets[ticket_address] = true;
        // newTicket.expriration_time = expriration_time;
        // newTicket.promo_no = promo_no;
        // newTicket.insurance_no = insurance_no;
        tickets[ticket_address] = newTicket;
        ticket_address_added[ticket_address] = true;
        ticket_addresses.push(ticket_address);
    }

    function allocateTicket(address customer_addr,address ticket_addr) internal {
        customer_tickets[customer_addr].push(ticket_addr);
    }

    function getAllTickets() constant returns (address[],uint[],uint[],bool[])
    {
        address[] memory tcks = ticket_addresses;
        uint length = tcks.length;

        address[] memory addrs = new address[](length);
        uint[] memory prices = new uint[](length);
        uint[] memory points = new uint[](length);
        bool[] memory OT = new bool[](length);
        for(uint i = 0;i<length;i++){
            addrs[i] = tcks[i];
            prices[i] = tickets[tcks[i]].price;
            points[i] = tickets[tcks[i]].reward_pts;
            OT[i] = oneTimeTickets[tcks[i]];
        }
        return (addrs,prices,points,OT);
    }

    function getONETIMESOLD() constant returns (address[]){
        return ONETIMESOLD;
    }

    function getMyTicketAddresses(address c) constant returns (address[]){
        return (customer_tickets[c]);
    }

    function transferTicket(address _to,address _t){
        address[] memory myTickets = new address[](customer_tickets[msg.sender].length);
        bool done_once = false;
        for(uint i = 0; i < customer_tickets[msg.sender].length;i++){
            if(customer_tickets[msg.sender][i]==_t&&!done_once){
                done_once = true;
                allocateTicket(_to,_t);
                continue;
            }
            myTickets[i] = (customer_tickets[msg.sender][i]);
        }
        customer_tickets[msg.sender] = myTickets;
    }
}