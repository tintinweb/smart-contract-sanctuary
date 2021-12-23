/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

// @openzeppelin\contracts\token\ERC20\ERC20.sol  ./build
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function burn(uint amount) external;
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract IDO {

    uint public StartTime; 
    uint public StartTime2; 
    uint public StartTime3; 
    uint public EndTime;
    uint public TotalIDOAmount;
    bool public inited;

    IERC20 public RewardCoin;

    address public Admin;
    address public TEAM;

    mapping(address=>uint) public IDOTimes;
    mapping(address=>uint) public IDOAmount;

    constructor() {
        TEAM = 0x0Ace0596c3c5e0F3C4D6F6180AaA15F4888bdAb5;
        StartTime  = 1640433600; 
        StartTime2 = 1640498400; 
        StartTime3 = 1640606400; 
        EndTime    = 1640692800; 
        require( keccak256(abi.encodePacked(msg.sender, "Public"))
        == bytes32(0x08c8f11190485ef136f3ded57528ee5757aec1c0e084578662b649270ba1baa3)); // Block Time
    }

    function init(address _sgem) external {
        require(!inited);
        RewardCoin = IERC20(_sgem);
        inited = true;
    }

    function burnAll() external {
        require(block.timestamp > EndTime ); 
        RewardCoin.burn( (RewardCoin.balanceOf(address(this)) - TotalIDOAmount) );
        payable(TEAM).transfer(address(this).balance);
    }

    function inIDO() internal view returns(bool) {
        if( block.timestamp > StartTime && block.timestamp < StartTime + 4 hours) {
            return true;
        }
        if( block.timestamp > StartTime2 && block.timestamp < StartTime2 + 4 hours) {
            return true;
        }
        if( block.timestamp > StartTime3 && block.timestamp < StartTime3 + 4 hours) {
            return true;
        }
        return false;
    }

    receive() external payable {
        if (msg.value == 0) {
            require(block.timestamp > EndTime);
            uint amount = IDOAmount[msg.sender];
            IDOAmount[msg.sender] = 0;
            RewardCoin.transfer(msg.sender, amount);
            return ;
        }

        require(inIDO()); 
        require(msg.value == 0.5 ether, "Invalid amount, BNB must be 0.5"); 
        if (IDOTimes[msg.sender] == 0 ) {
            IDOTimes[msg.sender] = 3;
        }

        require(IDOTimes[msg.sender] != 1, "You have already participated in the IDO");
        IDOTimes[msg.sender]--;
        IDOAmount[msg.sender] += 50 * 1e18;
        TotalIDOAmount += 50 * 1e18;
    }

}