pragma solidity ^0.8.0;

contract EtherStore {

    uint256 public withdrawalLimit = 1 ether;
    mapping(address => uint256) public lastWithdrawTime;
    mapping(address => uint256) public balances;
    event Deposit (
        address indexed from,
        uint256 amount
    );
    constructor() {}

    fallback () external payable{
        emit Deposit(msg.sender, msg.value);
    }

    function depositFunds() public payable {
        emit Deposit(msg.sender, msg.value);
        balances[msg.sender] += msg.value;
    }

    function collectEther() public {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawFunds (uint256 _weiToWithdraw) public {
        require(balances[msg.sender] >= _weiToWithdraw, 'withdraw is greater than balance');
        require(_weiToWithdraw <= withdrawalLimit, 'withdraw is greater than 1 ether');
//        require(now >= lastWithdrawTime[msg.sender] + 1 weeks);
        (bool _success,  ) = msg.sender.call{value: _weiToWithdraw}("");
         require(_success,"call should be success");
        balances[msg.sender] -= _weiToWithdraw;
        lastWithdrawTime[msg.sender] = block.timestamp;
    }
}

