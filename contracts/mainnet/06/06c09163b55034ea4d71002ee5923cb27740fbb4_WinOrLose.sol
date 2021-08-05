/**
 *Submitted for verification at Etherscan.io on 2021-01-21
*/

pragma solidity 0.6.0;

contract WinOrLose {
    mapping(uint=> uint) public bets;
    Bet[] public activeBets;
    Bet[] private winners;
    string public contractWebsite  = "www.winorlose.live";
    address payable owner;
    uint public min = 50000000000000000;
    uint public betCount = 0;
    bool lock= false;
    uint8 public fees=2;
    struct Bet{
        uint id;
        uint price;
        uint8 coinSide;
        address payable b1;
    }

    event Win(
        uint8 win
    );
    
    event BetCanceled(
        uint id
    );
    
    event BetCreated(
        uint id,
        uint price,
        uint8 coinSide,
        address creator
    );
    
    event BetWinner(
        uint id,
        uint price,
        uint8 coinSide,
        address winner
    );
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this method");
        _;
    }
    
    constructor(address payable _owner) public{
        owner=_owner;
    }
    
    function createBet(uint _price,uint8 coinSide) external payable {
        require(min <= _price, "Minimum bet price is Eth 0.01");
        require(_price <= msg.value, "Price is greater than sending price");
        betCount++;
        activeBets.push(Bet(betCount, _price, coinSide,msg.sender));
        bets[betCount] = activeBets.length-1;
        emit BetCreated(betCount,_price,coinSide,msg.sender);
    }
    
    function getWinnerCount() external view returns(uint count) {
        return winners.length;
    }
    
    function getActiveCount() external view returns(uint count) {
        return activeBets.length;
    }
    
    function getWinner(uint index) external view returns(uint id, uint price, address winner,uint8 coin) {
        return (winners[index].id, winners[index].price, winners[index].b1, winners[index].coinSide);
    }
    
    function cancelBet(uint _id) external {
        require(!lock);
        lock=true;
        require(_id>0 &&  _id<= betCount ,'ID is not valid');
        Bet memory bet = activeBets[bets[_id]];
        require(bet.id==_id,'Bet ID is not matched');
        require(bet.b1==msg.sender,'Bet is not started by you');
        activeBets[bets[_id]] = activeBets[activeBets.length-1];
        activeBets.pop();
        delete bets[_id];
        bets[betCount]=bets[_id];
         emit BetCanceled(_id);
        bet.b1.transfer(bet.price);
        lock=false;
    }
    
    function joinBet(uint _id) external payable{
        require(!lock);
        lock=true;
        require(_id>0 &&  _id<= betCount ,'ID is not valid');
        Bet memory bet = activeBets[bets[_id]];
        require(bet.id==_id,'Bet ID is not matched');
        require(msg.value>=bet.price,'Sent Value is less than bet price');
        require(bet.b1!=msg.sender,'You can not join your own bet');
        require(tx.origin==msg.sender,"Don't try to hack");
        uint flip=(gasleft()%10) + (now%10);
        if(flip%2==1){
            bet.b1=msg.sender;
            bet.coinSide=bet.coinSide==1?2:1;
            emit Win(1);
        }else{
            emit Win(0);
        }
        activeBets[bets[_id]] = activeBets[activeBets.length-1];
        activeBets.pop();
        delete bets[_id];
        bets[betCount]=bets[_id];
        winners.push(bet);
        emit BetWinner(_id,bet.price,bet.coinSide,bet.b1);
        uint256 total=bet.price *2;
        uint256 commission = ((total)*fees)/100;
        owner.transfer(commission);
        bet.b1.transfer(total-commission);
        lock=false;
    }
    
    //this will be used for migration of latest version contract or to resolve any discrepancy
    function withdraw(uint val) onlyOwner external{
        owner.transfer(val);
    }

    // Contract may be destroyed only when there are no active bets
    function kill() external onlyOwner {
        require (activeBets.length == 0, "All bets should be processed (complete or canceled) before self-destruct.");
        selfdestruct(owner);
    }

    // Fees will be down in future if platform works well
    function feesDown(uint8 newFees) external onlyOwner {
        require (activeBets.length == 0, "All bets should be processed (complete or canceled) before Fees changes.");
        fees=newFees;
    }
    
    // Min bet will be down in future if platform works well
    function minDown(uint newMin) external onlyOwner {
        min=newMin;
    }

    
    fallback() external payable {  }
}