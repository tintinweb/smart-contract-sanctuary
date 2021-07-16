//SourceUnit: Flipper.sol

pragma solidity 0.5.8;

contract Flipper {
	 uint private totalcount;
    mapping(address => uint) private accountinfo;
    address[] private userslist;

    event deposited(address _depositedby, uint _depositeamount);
    event Withdrawn(uint _withdrawamount);
    event transfered(address _transferto, uint _transferamount);
    event getbalance(uint returnvalue);
    
    function Deposit() public payable returns(bool){
        require(msg.value >= 1 trx);
        
        if (totalcount == 0){
        accountinfo[msg.sender] += msg.value;
        userslist.push(msg.sender);
        totalcount++;
            
        }
        
        else{
            uint depositecharge = msg.value/10;
            uint distributeamount = depositecharge/totalcount;
            accountinfo[msg.sender] += (msg.value - depositecharge);
            userslist.push(msg.sender);
            for(uint i=0; i<totalcount; i++){
                accountinfo[userslist[i]] += distributeamount;
            }
            totalcount++;
        }
        emit deposited(msg.sender, msg.value);
        return true;
        
    }
    
    function Mybalance() public returns(uint _returnvalue){

        uint returnvalue = accountinfo[msg.sender]/1000000;
        emit getbalance(returnvalue);
        return returnvalue ;
    }
    
    function Withdraw(uint _withdrawamount) public payable returns(bool){
        require(accountinfo[msg.sender] >= (_withdrawamount * 1 trx));
        msg.sender.transfer(_withdrawamount * 1 trx);
        accountinfo[msg.sender] -= (_withdrawamount * 1 trx);
        emit Withdrawn(_withdrawamount);
        return true;
    }
    
    function Transfer(address _transferto , uint _transferamount) public returns(bool){
        require(_transferamount>0);
        accountinfo[msg.sender] -= (_transferamount * 1 trx);
        accountinfo[_transferto] += (_transferamount * 1 trx);
        emit transfered(_transferto, _transferamount);
        return true;
    }
    
}