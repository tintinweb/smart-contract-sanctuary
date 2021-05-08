/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

/**
 *Submitted for verification at Etherscan.io on 2018-02-07
*/

pragma solidity ^0.5.0;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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



contract holdYourEther {
    using SafeMath for uint256;
    struct deposit_st{
        uint256 amount;
        uint256 term;
    }
    
    struct deposit_list{
        uint256[] list_key;
        // mapping time => deposit struct
        mapping(uint256=>deposit_st) deposits;
    }
    
    address payable public service_founder;
    // mapping account address => deposit_list
    mapping (address =>deposit_list) depositors;
    
    event Deposit(address account,uint256 amount,uint256 term);
    event Withdrawal(address account,uint index);
    event Transfer(address account,address to,uint256 amount,uint256 term);
    
    constructor() public {
        service_founder = msg.sender;
    }
    function () external payable {
        require(msg.sender != address(0x0));
        deposit(now);
    }
    function deposit_period (uint256 number_of_days) public payable {
        uint256 term =now+number_of_days*86400;
        deposit(term);
    }
    function deposit(uint256 term) public payable {
        uint256 amount=msg.value;
        require(msg.sender != address(0x0));
        require(amount>0);
        uint256 fee=amount.div(200);
        uint256 amount_of_deposit=amount.sub(fee);
        service_founder.transfer(fee); //some one sends eth to this contract
        deposit_to_address(msg.sender,amount_of_deposit,term);
        emit Deposit (msg.sender,amount_of_deposit,term);
    }
    function withdrawal(uint index) public {
        //validate deposit available
        require(index<depositors[msg.sender].list_key.length);
        uint256 createtime=depositors[msg.sender].list_key[index];
        require(depositors[msg.sender].deposits[createtime].amount>0);
        require(depositors[msg.sender].deposits[createtime].term<now);
        //return ethereum to depositors
        msg.sender.transfer(depositors[msg.sender].deposits[createtime].amount); // send ETH from smart contract to the function caller
        //remove deposit
        remove_deposit(msg.sender,index);
        //event
        emit Withdrawal(msg.sender,index);
    }
    function transfer(address to,uint index) public{
        //validate deposit available
        require(index<depositors[msg.sender].list_key.length);
        uint256 createtime=depositors[msg.sender].list_key[index];
        require(depositors[msg.sender].deposits[createtime].amount>0);
        require(depositors[msg.sender].deposits[createtime].term<now);
        //
        uint256 _amount=depositors[msg.sender].deposits[createtime].amount;
        uint256 _term=depositors[msg.sender].deposits[createtime].term;
        //remove the deposit from the old account
        remove_deposit(msg.sender,index);
        //deposit to the new account
        deposit_to_address(to,_amount,_term);
        //event
        emit Transfer(msg.sender,to,_amount,_term);
    }
     function deposit_to_address(address account,uint256 _amount,uint256 _term) private{
        uint256 currenttime=now;
        while(depositors[account].deposits[currenttime].amount>0){
            currenttime++;
        }
        depositors[account].deposits[currenttime]=deposit_st({amount:_amount,term:_term});
        depositors[account].list_key.push(currenttime);
    }
    function remove_deposit(address account,uint index) private{
        uint256 createtime=depositors[account].list_key[index];
        //remove deposit 
        delete depositors[account].deposits[createtime];
        //remove from list key
        uint count=depositors[account].list_key.length;
        depositors[account].list_key[index]=depositors[account].list_key[count-1];
        delete depositors[account].list_key[count-1];
        depositors[account].list_key.length--;
    }
    function get_list_deposit_key(address account) public view returns (uint256[] memory){
        return depositors[account].list_key;
    }
    function get_deposit_balance(address account,uint256 key) public view returns (uint256){
        return depositors[account].deposits[key].amount;
    }
    function get_deposit_term(address account,uint256 key) public view returns (uint256){
        return depositors[account].deposits[key].term;
    }
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}