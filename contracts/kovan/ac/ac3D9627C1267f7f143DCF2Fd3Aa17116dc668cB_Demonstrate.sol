// SPDX-License-Identifier: CC-BY-1.0
pragma solidity =0.8.6;

import "./IMintable.sol";

struct Demonstration {
    uint256 startTime;
    bytes32[] whatThreeWords;
    uint256 funds;
    address owner;
}

contract Demonstrate {

    address public immutable owner;
    address public token;
    uint256 private _funds;

    Demonstration[] public demonstrations;

    function count() public view returns (uint256) {
        return demonstrations.length;
    }

    function totalFunds() public view returns (uint256) {
        return _funds;
    }

    constructor() {
        owner = msg.sender;
    }

    function setToken(address _token) public onlyOwner {
        token = _token;
    }

    function add(uint256 _startTime, bytes32[] memory _whatThreeWords) public {
        require(_whatThreeWords.length == 2, "Not enough words");

        demonstrations.push(Demonstration(_startTime, _whatThreeWords, 0, msg.sender));
        IMintable(token).mint(msg.sender);
        emit NewDemonstration(demonstrations.length - 1, msg.sender);
    }

    function fund(uint256 _index) public payable {
        require(demonstrations[_index].owner != address(0), "Invalid demonstration");
        demonstrations[_index].funds += msg.value;
        _funds += msg.value;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can execute this");
        _;
    }

    modifier onlyCampaignOwner(uint256 _index) {
        require(demonstrations[_index].owner == msg.sender, "Only owner");
        _;
    }

    event NewDemonstration(uint256 index, address indexed who);
}

// SPDX-License-Identifier: CC-BY-1.0
pragma solidity =0.8.6;

interface IMintable {
    function mint(address account) external;
}

