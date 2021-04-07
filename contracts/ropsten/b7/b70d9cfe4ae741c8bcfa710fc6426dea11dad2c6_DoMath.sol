/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

pragma solidity ^0.8.0;

library DoMath {
    function add(uint a, uint b) public pure returns (uint){
        uint c = a+b;
        require(c >= a, 'Over flow: add');
        return c;
    }
    
    function sub(uint a, uint b) public pure returns (uint){
        require(a > b , 'Over flow: sub');
        return a-b;
    }
    
}


contract TechnixoCoin {
    using DoMath for uint;
    mapping(address => uint) public balances;
    string public symbol = 'XOCOIN';
    address public owner;
    address public technixoVoteContract;
    uint public constant sell_rate = 100;
    uint public decimal = 6;
    
    event MoneySent(address _sender, address _receiver, uint _amount);
    event TokenSold(address _receiver, uint _amount);
    event WithdrawFund(address _receiver, uint _timestamp, uint _amount);
    
    modifier onlyOwner(){
         require(owner == msg.sender, 'Only onwer can call');
         _;
    }
    
    modifier onlyTechnixoVoteContract(){
        require(technixoVoteContract == msg.sender, 'Only Technixo Vote contract');
        _;
    }
    
    constructor(){
        //set owner của contract
        owner = msg.sender;
    }
    
    function setTechnixoVoteContractAddress(address _address) public onlyOwner {
        technixoVoteContract = _address;
    }
    
    //mint coin cho _receiver với số tiền là _amount
    function mint(address _receiver, uint _amount) public onlyOwner {
        balances[_receiver] = balances[_receiver].add(_amount*10**decimal);
    }
    
    function balanceOf(address _address) public view returns (uint) {
         return balances[_address];
    } 
    
    //query số dư của ví có địa chỉ là _address
    function getBalanceOf(address _address) public view returns (uint) {
        return balances[_address];
    }
    
    function transferFromTechnixoVote(address _spender, uint _amount) public onlyTechnixoVoteContract {
        _transfer(_spender, technixoVoteContract, _amount);
    }
    
    function transferBackToVoter(address _receiver, uint _amount) public onlyTechnixoVoteContract {
        _transfer(technixoVoteContract, _receiver, _amount);
    }
    
    //gửi tiền cho người nhận là _receiver
    function send(address _receiver, uint _amount) public {
        _transfer(msg.sender, _receiver, _amount);
    }
    
    function _transfer(address _sender, address _receiver, uint _amount) private {
        require(getBalanceOf(_sender) >= _amount*10**decimal, 'Khong co tien');
        balances[_sender] -= _amount*10**decimal;
        balances[_receiver] += _amount*10**decimal;
        emit MoneySent(_sender, _receiver, _amount);
    }
    
    function buyToken() public payable {
        //msg.value ether = wei = 1e18
        //1e6
        require(msg.value > 0, 'Send some eth');
        uint receive_token = msg.value*sell_rate/10**12;
        balances[msg.sender] = receive_token;
        emit TokenSold(msg.sender, receive_token);
    }
    
    function withdrawFund(uint _amount) public onlyOwner {
        payable(msg.sender).transfer(_amount);
        emit WithdrawFund(msg.sender, block.timestamp, _amount);
    }
    
}