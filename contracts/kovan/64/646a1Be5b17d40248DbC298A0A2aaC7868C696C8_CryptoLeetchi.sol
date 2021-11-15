// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title CryptoLeetchi
 */
contract CryptoLeetchi {
    address payable public receiver;
    uint public timeout;
    uint public minCap;
    mapping(address => uint) public contributors;
    uint public total;
    bool public isStarted;
    bool public isFinalized;
    
    event Contribution(address _contributor, uint _amount);
    
    /**
     * @dev Start CryptoLeetchi
     * @param _delay The delay of the CryptoLeetchi.
     * @param _minCap The minimum cap to reach.
     */
    function start(address payable _receiver, uint _delay, uint _minCap) external {
        require(!isStarted);
        
        receiver = _receiver;
        timeout = block.timestamp + _delay;
        minCap = _minCap;
        
        isStarted = true;
    }

    /**
     * @dev Contribute
     */
    function contribute() external payable {
        require(msg.value > 0 && block.timestamp < timeout);
        
        contributors[msg.sender] += msg.value;
        total += msg.value;
    }
    
    /**
     * @dev Finalize
     */
    function finalize() external {
        require(!isFinalized && block.timestamp > timeout);
        
        if (total >= minCap) {
            receiver.send(address(this).balance);
        }
        
        isFinalized = true;
    }
    
    /**
     * @dev Withdraw
     */
    function withdraw() external {
        require(isFinalized && contributors[msg.sender] > 0);
        
        address payable contributor = payable(msg.sender);
        uint amount = contributors[msg.sender];
        
        contributors[msg.sender] = 0;
        
        contributor.send(amount);
    }
    
    /**
     * @dev Return timeleft
     */
    function getTimeLeft() external view returns (uint) {
        if (timeout <= block.timestamp) {
            return 0;
        }
        return timeout - block.timestamp;
    }
}

