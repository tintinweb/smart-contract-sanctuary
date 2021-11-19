/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;


//ierc20 interface
interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Swap {

//transaction data;
struct SwapData {
    uint256 id;
    uint256 _to_network;
    uint256 _from_network;
    address user;
    uint256 time;
    uint256 status;
    uint256 amount;
    uint256 price;
    string other_address;
    string trx_hash;
}


// Global variables
    
    address public governence;
    
    // only admin or only governance access modifier
    
    modifier onlyOwner() {
      require(msg.sender == governence, "only governance can call this");      
      _;
    }
    
//transaction id;
 uint256 public trans;

//pending swaps;
 uint256[] public pending;
 
// last complete
 uint256 public last_pending;

mapping(uint256 =>SwapData) public trans_id;

    IERC20 public token;

//constructor
 constructor(IERC20 _token){
     token = _token;
    governence = msg.sender;
}

// get token value

function balance() external view returns (uint256 amount){
    amount = token.balanceOf(msg.sender );
}
//add token transaction
function swap_token(uint256 _network, uint256 _from, uint256 _amount, uint256 _price, string memory o_address)external payable{
    require(token.balanceOf(msg.sender ) > 0, "not enough token");
    require(_amount > 0, "Amount need to be greater than 0");
    
    //approve transfer
    // require(token.approve(msg.sender,_amount));
    //transfer the token from user address to this address
    require(token.transferFrom(msg.sender,address(this),_amount),"Error getting fund from you");
    uint256 new_id = trans+ 1;
    trans_id[new_id]._from_network = _from;
    trans_id[new_id].id = new_id; trans_id[new_id]._to_network = _network;trans_id[new_id].user = msg.sender;trans_id[new_id].time = block.timestamp;
    trans_id[new_id].status = 0;
    trans_id[new_id].other_address = o_address;
    trans_id[new_id].amount = _amount;
    trans_id[new_id].price = _price;
    trans++;
    pending.push(new_id);
}

function swap_core(uint256 _network, uint256 _from, uint256 _price)external payable{
    require(msg.value > 0, "Value must be greater than zero");
    require(_price > 0, "Price must have a positive value");
    uint256 new_id = trans+ 1;
    trans_id[new_id]._from_network = _from;
    trans_id[new_id].id = new_id;
    trans_id[new_id]._to_network = _network;
    trans_id[new_id].user = msg.sender;
    trans_id[new_id].time = block.timestamp;
    trans_id[new_id].status = 0;
    // trans_id[new_id].other_address = o_address;
    trans_id[new_id].amount = msg.value;
    trans_id[new_id].price = _price;
    trans++;
    pending.push(new_id);
    
}

//add transaction
function swap(uint256 _network, uint256 _from, uint256 _amount, uint256 _price, string memory o_address)public{
    // require(token.balanceOf(msg.sender ) > 0, "not enough token");
    require(_amount > 0, "Amount need to be greater than 0");
    //transfer the token from user address to this address
    
    uint256 new_id = trans+ 1;
    trans_id[new_id]._from_network = _from;
    trans_id[new_id].id = new_id; trans_id[new_id]._to_network = _network;trans_id[new_id].user = msg.sender;trans_id[new_id].time = block.timestamp;
    trans_id[new_id].status = 0;
    trans_id[new_id].other_address = o_address;
    trans_id[new_id].amount = _amount;
    trans_id[new_id].price = _price;
    trans++;
    pending.push(new_id);
}
//get view
function get_swap(uint256 _id)external view returns (uint256 amount, uint256 _network, address _user, uint256 _time, uint256 _stat, string memory _o_address){
    amount = trans_id[_id].amount;
    _network = trans_id[_id]._to_network;
    _user = trans_id[_id].user;
    _time = trans_id[_id].time;
    _stat = trans_id[_id].status;
    _o_address = trans_id[_id].other_address;
    
}

//update swap
function update_swap(uint256 _id, string memory transaction_hash) external onlyOwner(){
    trans_id[_id].trx_hash = transaction_hash;
    trans_id[_id].status = 1;
    last_pending++;
    
}

//transfer token balance to address
    function transfer_token(address _user, uint256 _amount) external onlyOwner(){
        require(token.balanceOf(address(this)) > 0,"Contract dose not have balance");
        require(token.transferFrom(address(this),_user,_amount),"Error getting fund from you");
    }

}