/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

pragma solidity 0.4.26;

contract exercise {
    mapping (address => bool) owner;
    mapping (address => uint256) balanceOf;
    uint256 public countOwner = 0;
    
    event Deposit(address indexed  owner, uint256 value);
    
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
    
    struct VoteAdd{
        address adrFrom;
        address adrNew;
        uint vote;
        bool success;
    }
    mapping(uint256 => VoteDeposit) public listVoteDep;
    mapping(uint256 => VoteAdd) public listVoteAdd;
    mapping (address => mapping ( uint256 => bool )) public isVoteDep; 
    mapping (address => mapping ( uint256 => bool )) public isVotedAdd;
    uint256 sizeAdd = 0;
    uint256 sizeDep= 0;

    modifier onlyOwner() {
        require(owner[msg.sender] == true,"only Owner can do");
        _;
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    function seeBalance() public view returns (uint256) {
        return msg.sender.balance;
    }
    function seeBalanceDep(address depositedAdr) public view returns (uint256) {
        return balanceOf[depositedAdr];
    }

    function addOwner(address newOwner) public onlyOwner {
        require(msg.sender != newOwner, "don't add yourself");
        require(owner[newOwner] != true, "this is already a member");
        VoteAdd memory voteAdd = VoteAdd({
            adrFrom: msg.sender,
            adrNew: newOwner,
            vote: 0,
            success: false
        });
        sizeAdd++;
        listVoteAdd[sizeAdd] = voteAdd;
    }
    
    function voteAddMem(uint256 idVotedAdd) public onlyOwner{
        require(isVotedAdd[msg.sender][idVotedAdd] == false ,"This adr voted " );
        listVoteAdd[idVotedAdd].vote += 1;
        
        if (listVoteAdd[idVotedAdd].vote > countOwner  * 49 / 100){
            listVoteAdd[idVotedAdd].success = true;
            isVotedAdd[msg.sender][idVotedAdd] = true;
            execAddMem(listVoteAdd[idVotedAdd].adrNew);
        }
        else{
            listVoteAdd[idVotedAdd].success = false;
        }
    }
    function execAddMem(address newOwner) onlyOwner public {
        owner[newOwner] = true;
        countOwner+= 1;
    }
    
    function GroupDeposit(uint256 amount) payable onlyOwner public { 
        require(msg.value == amount);
          
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
            deposit(listVoteDep[idVoteDep].money);
            balanceOf[listVoteDep[idVoteDep].adrFrom] += listVoteDep[idVoteDep].money;
        }
        else{
            listVoteDep[idVoteDep].success = false;
        }   
    }
        function deposit(uint256 amount) onlyOwner  payable  public{
        emit Deposit(msg.sender, msg.value);
    }
}