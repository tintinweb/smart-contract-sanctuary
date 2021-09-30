/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.5.12;

contract Ownable {

    address payable internal _owner;

    constructor() internal {
        require(msg.sender != address(0));
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Not owner");
        _;
    }

    function isOwner() internal view returns (bool) {
        return msg.sender == _owner;
    }
    
}

 interface IERC20 {
     function transfer(address to, uint256 value) external returns (bool);
     function balanceOf(address who) external view returns (uint256);
     function decimals() external view returns(uint8);
 }

contract ClickGame is Ownable {
    IERC20 private MILK2;
    
    struct User {
        bool win;
        uint256 prize;
        bool approve;
    }
    
    mapping(address => User) private users;
    uint256 public decimals;
    
    event OnWithdraw(address indexed _account, uint256 _value);
    
    constructor(address mftAddress) public {
        MILK2 = IERC20(mftAddress);
        decimals = MILK2.decimals();
    }
    
    modifier hasBalance() {
        require(balanceOfUser() >= 10**decimals, 'There are no MILK2 tokens on your balance');
        _;
    }
    
    modifier approved() {
        require(users[msg.sender].approve, 'First you need to approve');
        _;
    }
    
    modifier playOnce() {
        require(!users[msg.sender].win, 'You can participate in the game once');
        _;
    }
    
    function balanceOf(address _addr) public view returns(uint256){
        return MILK2.balanceOf(_addr);
    }
    
    function balanceOfContract() public view returns(uint256) {
        return balanceOf(address(this));
    }
    
    function balanceOfUser() public view returns (uint256) {
        return balanceOf(msg.sender);
    }
    
    function approve() public hasBalance returns (bool) {
        users[msg.sender].approve = true;
        return true;
    }
    
    function random() private view returns(uint256){
        return uint256(keccak256(abi.encodePacked(block.difficulty, now)));
    }
    
    function getPrize() private view returns(uint256){
        uint256 prize = (random() % 100) * 10**decimals;
        
        if(balanceOfUser() > 10**(4 + decimals)){
            prize *= 10;
        }
        
        return prize;
    }
    
    function play() public hasBalance approved playOnce returns (uint256){
        uint256 prize = getPrize();
        
        require(prize <= balanceOfContract(), 'Not enough MILK2 tokens on the contract balance');
        
        users[msg.sender].prize = prize;
        users[msg.sender].win = true;
        
        MILK2.transfer(msg.sender, prize);
        emit OnWithdraw(msg.sender, prize);
        
        return prize;
    }
    
    function transferContractBalance(address _receiver, uint256 _amount) public onlyOwner returns (bool){
        MILK2.transfer(_receiver, _amount);
        return true;
    }
    
    function getUser(address _addr) public view returns(bool, bool, uint256) {
        return (users[_addr].win, users[_addr].approve, users[_addr].prize);
    }
    
    function allowance(address _addr) public view returns(bool) {
        return users[_addr].approve;
    }

}