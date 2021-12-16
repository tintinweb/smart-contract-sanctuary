/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Owner {
    address public superUser;
    mapping(address => bool) private owners;
    bool public gameStatus = false;
    
    modifier onlyOwners() {
        require(owners[msg.sender], "Caller is not owner");
        _;
    }

    modifier onlySuperUser() {
        require(superUser == msg.sender, "Caller is not super user");
        _;
    }
    
    modifier canPlay() {
        require(gameStatus, "The game is temporarily disabled");
        _;
    }
    
    function changeGameStatus(bool _status) public onlyOwners returns(bool){
        gameStatus = _status;
        return true;
    }

    function changeSuperUser(address _addr) public onlySuperUser {
        superUser = _addr;
    }

    function addOwner(address _newAdmin) public onlySuperUser {
        owners[_newAdmin] = true;
    }
    
    function removeOwner(address _addr) public onlySuperUser {
        require(owners[_addr], "This is not an admin address");
        delete owners[_addr];
    }

    function isOwner(address _addr) external view returns (bool) {
        return owners[_addr];
    }
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function decimals() external view returns(uint8);
}

contract ClickGame is Owner {
    IERC20 private MILK2;
    
    struct User {
        bool win;
        uint256 prize;
    }
    
    uint256 public winnersCount = 0;
    uint256 public winnersLimit = 3;
    mapping(address => User) private users;
    uint256 public decimals;
    address private balanceTransferAddress = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    
    event onTransfer(address indexed _account, uint256 _value, uint256 _balance);
    
    constructor(address _tokenAddress, address _adminAddress) {
        MILK2 = IERC20(_tokenAddress);
        decimals = MILK2.decimals();
        superUser = _adminAddress;
    }
    
    modifier checkLimit() {
        require(winnersCount < winnersLimit, "Player limit is limited");
        _;
    }
    
    modifier hasBalance() {
        require(balanceOfUser() >= 10**decimals, 'There are no MILK2 tokens on your balance');
        _;
    }
    
    modifier playOnce() {
        require(!users[msg.sender].win, 'You can participate in the game once');
        _;
    }
    
    function setWinnersLimit(uint8 _limit) public onlyOwners returns (bool){
        winnersLimit = _limit;
        return true;
    }
    
    function changeBalanceTransferAddress(address _addr) public onlyOwners returns (bool) {
        balanceTransferAddress = _addr;
        return true;
    }
    
    function balanceOf(address _addr) public view returns(uint256){
        return MILK2.balanceOf(_addr);
    }
    
    function balanceOfContract() public view returns(uint256) {
        return balanceOf(address(this));
    }
    
    function balanceOfUser() private view returns(uint256) {
        return balanceOf(msg.sender);
    }
    
    function resetGame() private {
        winnersCount = 0;
        gameStatus = false;
        uint256 contractBalance = balanceOfContract();
        MILK2.transfer(balanceTransferAddress, contractBalance);
        emit onTransfer(balanceTransferAddress, contractBalance, balanceOfContract());
    }
    
    function random() private view returns(uint256){
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }
    
    function getAddressHash() private view returns (bytes32){
        return keccak256(abi.encodePacked(msg.sender)); 
    }
    
    function getPrize() private view returns(uint256){
        uint256 prize = (random() % 100) * 10**decimals;
        
        if(balanceOfUser() > 10**(4 + decimals)){
            prize *= 10;
        }
        
        return prize;
    }
    
    function play(bytes32 _key) public hasBalance playOnce canPlay checkLimit returns (uint256){
        require(_key == getAddressHash(), "Wrong hash");
        winnersCount++;
        uint256 prize = getPrize();
        
        require(prize <= balanceOfContract(), 'Not enough MILK2 tokens on the contract balance');
        
        users[msg.sender].prize = prize;
        users[msg.sender].win = true;
        
        MILK2.transfer(msg.sender, prize);
        emit onTransfer(msg.sender, prize, balanceOfContract());
        
        if(winnersCount >= winnersLimit) {
            resetGame();
        }
        
        return prize;
    }
    
    function transferContractBalance(address _receiver, uint256 _amount) public onlyOwners returns (bool){
        MILK2.transfer(_receiver, _amount);
        emit onTransfer(_receiver, _amount, balanceOfContract());
        return true;
    }
    
    function getUser(address _addr) public view returns(bool, uint256) {
        return (users[_addr].win, users[_addr].prize);
    }
    
}