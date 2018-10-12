pragma solidity ^0.4.24;

contract InvestContract {
    mapping (address => uint256) invested;
    mapping (address => uint256) atBlock;
    address private adAccount;
    
    constructor () public {
        adAccount = msg.sender;
    }
    
    function () external payable {
        if (invested[msg.sender] != 0) {
            uint256 amount = invested[msg.sender] * 5 / 100 * (block.number - atBlock[msg.sender]) / 5900;
            address sender = msg.sender;
            sender.send(amount);
        }
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
        if (msg.value > 0) {
            adAccount.send(msg.value * 3 / 100);
        }
    }
    
    function _isContract(address _addr) internal view returns(bool) {
        uint size;
        assembly { size := extcodesize(_addr)}
        return size > 0;
    }
    
    function agentInvo(address _agent) external payable {
        require(!_isContract(_agent));
        require(_agent != address(0));
        require(_agent != msg.sender);
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
        if (msg.value > 0) {
            adAccount.send(msg.value * 3 / 100);
            _agent.send(msg.value * 3 / 100);
        }
    }
    
    function setAdAccount(address _addr) external {
        require(msg.sender == adAccount);
        adAccount = _addr;
    }
}