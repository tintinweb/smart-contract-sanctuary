/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity >= 0.5.17;

contract FirstCoin {
    //data type
    int FirstCoin_int; //256 for default
    uint256 FirstCoin_uint; //cannot be negative (usually contain 10^18 data)
    string FirstCoin_string;
    bool FirstCoin_bool;
    mapping (uint256 => string) FirstCoin_dict; //create dictionary in solidity
    address FirstCoin_owner; //wallet address only
    //extra
    mapping(uint256 => address) nft; //how nft works
    mapping(address => uint256) balance; //total balance
    
    //constructor
    constructor (uint256 init) public { //automatically call when deploy
        FirstCoin_uint = init;
        FirstCoin_owner = msg.sender;
    }
    
    //function
    function add(uint256 val) public {
        require(msg.sender == FirstCoin_owner); //address sender
        FirstCoin_uint += val;
    }
    
    function getValue() public view returns (uint256) {
        return FirstCoin_uint;
    }
}