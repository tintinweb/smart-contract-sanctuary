/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

pragma solidity >=0.6.2 <0.7.0;



contract DDDD {
    
    modifier onlyOwner() {
        require(_owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }
    
    event Deposit(address addr, uint256 amount);
    
    address payable _owner;
    uint public x;
    mapping (address => uint256) public balance;
    
    constructor() public payable {
        x = 1;
        _owner = msg.sender;
    }
    
    fallback()  external {
     
    }
    
    receive() external payable {
        deposit();
    }
    
    
    function getX() public view returns (uint){
        return x;
    }
    
    function deposit() public payable {
        require(msg.value > 0, "zero deposit");
        balance[msg.sender] = msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    function balanceOf(address addr) public view returns (uint256) {
        return balance[addr];
    }
    
    function kill() public onlyOwner {
        selfdestruct(_owner);
    }
}