/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


// _receiver: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
// _multihash: QmXeDksYDm7Z1HGXQ27LVDsRtzKoC8P3b6skviBJ21FSgb
// _daly: 200
// _minCap: 3

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
    // bytes32 ipfsHash;
 
    event Contribution(address _contributor, uint _amount);
    
    address public newCagnotte;
    mapping(bytes32 => address) public hashIPFSToCagnotte;
    // hashIPFSToCagnotte[multihash] = newCagnotte;
    
     /**
     * @dev Start CryptoLeetchi
     * @param _delay The delay of the CryptoLeetchi.
     * @param _minCap The minimum cap to reach.
     */
    function start(address payable _receiver, uint _delay, uint _minCap) external {
        require(!isStarted);
        // hashIPFSToCagnotte[multihash] = newCagnotte;
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
            receiver.transfer(address(this).balance);
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
        
        contributor.transfer(amount);
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