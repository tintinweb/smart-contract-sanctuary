/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity >= 0.5.17;

contract FirstCoin {
    //data type
    int FirstCoin_int; //256 for default
    uint FirstCoin_uint; //cannot be negative (usually contain 10^18 data)
    string FirstCoin_string;
    bool FirstCoin_bool;
    mapping (uint256 => string) FirstCoin_dict; //create dictionary in solidity
    address FirstCoin_address; //wallet address only
    //extra
    mapping(uint256 => address) nft; //how nft works
    mapping(address => uint256) balance; //total balance
    
    //constructor
    constructor (uint256 init) public { //automatically call when deploy
        FirstCoin_uint = init;
    }
    
    //function
    function add(uint256 val) public {
        FirstCoin_uint += val;
    }
}