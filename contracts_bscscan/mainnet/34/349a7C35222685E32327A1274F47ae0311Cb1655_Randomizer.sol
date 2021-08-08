/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

// SPDX-License-Identifier: MIT
// defifusion.io
pragma solidity =0.6.12;

interface IRandomizer {
    function getCharge(address sender) external view returns (uint256);
    function requestRandom(bytes32 ref) external payable returns (uint256);
}

abstract contract RandomizerReceiver {
    address private _oracle;
    
    modifier onlyOracle {
        require(msg.sender == _oracle, 'restricted to oracle');
        _;
    }

    constructor (address addr) internal {
        _oracle = addr;
    }

    function requestRandom(bytes32 ref) internal returns (uint256) {
        uint256 charge = IRandomizer(_oracle).getCharge(address(this));

        return IRandomizer(_oracle).requestRandom{value: charge}(ref);
    }

    function randomCharge() public view returns (uint256) {
        return IRandomizer(_oracle).getCharge(address(this));
    }

    function receiveRandom(uint256 seed, bytes32 ref) external virtual onlyOracle {}
}

contract Randomizer {
    address payable public oracle;
    address public owner;
    RequestRandom[] private requests;
    
    mapping(address => Channel) public channels;

    struct RequestRandom {
        bytes32 ref;
        bool answered;
        uint256 seed;
        address channel;
    }

    struct Channel {
        address sender;
        uint256 charge;
        bool active;
    }

    modifier onlyOracle {
        require(msg.sender == oracle, 'restricted to oracle');
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner, 'restricted to owner');
        _;
    }

    modifier onlyChannel {
        require(channels[msg.sender].active, 'no payment channel');
        _;
    }

    event RequestedRandomness(uint256 indexed request);

    constructor () public {
        oracle = msg.sender;
        owner = msg.sender;
    }
    
    function transferOwnership(address account) public onlyOwner {
        owner = account;
    }

    function setOracle(address payable _oracle) public onlyOwner {
        oracle = _oracle;
    }

    function requestRandom(bytes32 ref) external payable onlyChannel returns (uint256) {
        uint256 charge = getCharge(msg.sender);
        require(msg.value >= charge, 'charge too low');
        uint256 request = requests.length;

        oracle.transfer(charge);

        requests.push(RequestRandom({
            ref: ref,
            answered: false,
            seed: 0,
            channel: msg.sender
        }));

        emit RequestedRandomness(request);
        
        return request;
    }

    function replyRandom(uint256 request, uint256 seed) external onlyOracle {
        require(!requests[request].answered, 'already replied');
        RandomizerReceiver(requests[request].channel)
            .receiveRandom(seed, requests[request].ref);

        requests[request].answered = true;
        requests[request].seed = seed;
    }

    function setChannel(address sender, uint256 charge) external onlyOwner {
        channels[sender] = Channel({
            sender: sender,
            charge: charge,
            active: true
        });
    }

    function killChannel(address sender) external onlyOwner {
        channels[sender].active = false;
    }

    function getCharge(address sender) public view returns (uint256) {
        return channels[sender].charge;
    }

    function changeOracle(address payable _oracle) external onlyOracle {
        oracle = _oracle;
    }
}