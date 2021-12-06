pragma solidity >=0.5.16;

// import "./Ownable.sol";

contract HelloWorld {
    mapping (address => uint) favourite_number;
    function save_favourite_number(uint number) external {
        favourite_number[msg.sender] = number;
    }
    
    function get_favourite_number() view external returns (uint) {
        return favourite_number[msg.sender];
    }
}