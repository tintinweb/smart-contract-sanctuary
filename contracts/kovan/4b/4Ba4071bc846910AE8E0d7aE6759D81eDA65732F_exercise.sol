/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

pragma solidity 0.4.26;


contract exercise {
    mapping (address => bool) owner;
    mapping (address => uint256)balanceOf;
    uint256 public countOwner = 0;
    uint256  public balanceGroup = address(this).balance;
    event Deposit(address indexed  owner, uint256 value);
    event Withdraw(address indexed owner, uint256 value);
    
    constructor() public{
         owner[msg.sender] = true;
         countOwner +=1;
    }
    
    struct VoteDeposit{
        address adrFrom;
        uint256 money;
        uint vote;
        bool success;
    }
    struct VoteWithdraw{
        address adrFrom;
        address adrTo;
        uint256 money;
        uint vote;
        bool success;
    }
    struct VoteAdd{
        address adrFrom;
        address adrNew;
        uint vote;
        bool success;
    }
    struct VoteRemove{
        address adrFrom;
        address adrOld;
        uint vote;
        bool success;
    }
    mapping(uint256 => VoteDeposit) public listVoteDep;
    mapping(uint256 => VoteWithdraw) public listVoteWith;
    mapping(uint256 => VoteAdd) public listVoteAdd;
    mapping (uint256 => VoteRemove) public listVoteRemo;
    mapping (address => mapping ( uint256 => bool )) public isVoteDep; 
    mapping (address => mapping ( uint256 => bool )) public isVoteWith;
    mapping (address => mapping ( uint256 => bool )) public isVotedAdd;
    mapping (address => mapping ( uint256 => bool )) public isVotedRemo;
    uint256 sizeAdd = 0;
    uint256 sizeDep= 0;
    uint256 sizeRemo = 0;
    uint256 sizeWith = 0;
    modifier onlyOwner() {
        require(owner[msg.sender] == true,"only Owner can do");
        _;
    }
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function SeebalanceOf(address adr) public view returns (uint256){
        return adr.balance;
    }
    function addOwner(address newOwner) public onlyOwner {
        require(msg.sender != newOwner, "don't add yourself");
        require(owner[newOwner] != true, "this is already a member");
        if(countOwner == 1){
            owner[newOwner] = true;
            countOwner++;
        }
        else{
            VoteAdd memory voteAdd = VoteAdd({
            adrFrom: msg.sender,
            adrNew: newOwner,
            vote: 0,
            success: false
        });
        sizeAdd++;
        listVoteAdd[sizeAdd] = voteAdd;
     }
    }
    function voteAddMem(uint256 idVotedAdd) public onlyOwner{
        require(isVotedAdd[msg.sender][idVotedAdd] == false ,"This adr voted " );
        listVoteAdd[idVotedAdd].vote += 1;
        isVotedAdd[msg.sender][idVotedAdd] = true;
        if (listVoteAdd[idVotedAdd].vote > countOwner  * 49 / 100){
            listVoteAdd[idVotedAdd].success = true;
            execAddOwner(listVoteAdd[idVotedAdd].adrNew);

        }
        else{
            listVoteAdd[idVotedAdd].success = false;
            
        }
    }
    function execAddOwner(address newOwner) onlyOwner public {
        owner[newOwner] = true;
        countOwner+= 1;
    }
    function GroupDeposit(uint256 amount) payable onlyOwner public { 
          
        VoteDeposit memory voteDeposit = VoteDeposit({
            adrFrom: msg.sender,
            money: amount,
            vote: 0,
            success: false
        });
        sizeDep++;
        listVoteDep[sizeDep] = voteDeposit;
    }
    function VoteforDeposit(uint256 idVoteDep) onlyOwner public{
        require(isVoteDep[msg.sender][idVoteDep] == false ,"This address voted" );
        listVoteDep[idVoteDep].vote += 1;
        isVoteDep[msg.sender][idVoteDep]  = true;
        if (listVoteDep[idVoteDep].vote == countOwner){
            listVoteDep[idVoteDep].success = true;
            execDeposit(listVoteDep[idVoteDep].money);
        }
        else{
            listVoteDep[idVoteDep].success = false;
        }   
    }
    function deposit0(uint256 amount) onlyOwner  payable  public{
        require (msg.value == amount);
        emit Deposit(msg.sender, msg.value);

    } 
    function deposit(uint256 amount) onlyOwner payable public{
         require (msg.value == amount);
         require(amount <= address(this).balance* 30 / 100, " amount greater than 30% ETH smart contract hold ");
         emit Deposit(msg.sender, msg.value);
    }
    function execDeposit(uint256 amount) onlyOwner{
        emit Deposit(msg.sender, amount);
        balanceGroup += amount;
    }
    function withdrawTo(uint256 amount, address _to) onlyOwner payable public{
        require(this.balance >= amount, "The amount is too big, not enough money");
        emit Withdraw(msg.sender, amount);
        _to.transfer(amount);
    }
    function removeOwner(address oldOwmer) public onlyOwner{
        require(msg.sender != oldOwmer, "don't remove yourself");
        require(owner[oldOwmer] == true, "this address is not a owner yet");
        VoteRemove memory voteRemove = VoteRemove({
            adrFrom: msg.sender,
            adrOld: oldOwmer,
            vote: 0,
            success: false
        });
        sizeRemo++;
        listVoteRemo[sizeRemo] = voteRemove;
    }
    function VoteforRemove(uint256 idVoteRemo) onlyOwner public{
        require(isVotedRemo[msg.sender][idVoteRemo] == false ,"This address voted" );
        listVoteRemo[idVoteRemo].vote += 1;
        isVotedRemo[msg.sender][idVoteRemo]  = true;
        if  (listVoteRemo[idVoteRemo].vote > countOwner  * 49 / 100){
            listVoteRemo[idVoteRemo].success = true;
            execRemove(listVoteRemo[idVoteRemo].adrOld);
        }
        else{
            listVoteRemo[idVoteRemo].success = false;
        }   
    }
    function execRemove(address oldOwner) onlyOwner public {
        owner[oldOwner] = false;
        countOwner -= 1;
    }
    function GroupWithdrawTo(uint256 amount, address _to) payable onlyOwner public { 
        VoteWithdraw memory voteWithdraw = VoteWithdraw({
            adrFrom: msg.sender,
            adrTo: _to,
            money: amount,
            vote: 0,
            success: false
        });
        sizeWith++;
        listVoteWith[sizeWith] = voteWithdraw;
    }
    function VoteforWithdraw(uint256 idVoteWith) onlyOwner public{
        require(isVoteWith[msg.sender][idVoteWith] == false ,"This address voted" );
        listVoteWith[idVoteWith].vote += 1;
        isVoteWith[msg.sender][idVoteWith]  = true;
        if (listVoteWith[idVoteWith].vote == countOwner){
            listVoteWith[idVoteWith].success = true;
            withdrawTo(listVoteWith[idVoteWith].money,listVoteWith[idVoteWith].adrTo );
        }
        else{
            listVoteWith[idVoteWith].success = false;
        }   
    }
   
}