/**
 *Submitted for verification at polygonscan.com on 2021-09-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/IERC20.sol";

contract HelloDeposit {
    event NewPendingSwap(address indexed to, uint256 amount, uint256 id);

    struct PendingSwap
    {
        // Address on Cardano chain
        // TODO the address type is for Ethereum, needs changing to Cardano
        address to;
        // Amount of Matic tokens to swap
        uint amount;
        // Created time
        uint createdAt;
    }
    
    // Holds all swaps that have not yet been processed
    mapping(uint => PendingSwap) public pendingSwaps;
    uint[] public pendingSwapKeys;
    uint public pendingSwapHeight;
    
    function __addPendingSwap(address _to, uint _amount) private {
        pendingSwapKeys.push(pendingSwapHeight);
        pendingSwaps[pendingSwapHeight] = PendingSwap(_to, _amount, block.timestamp);
        emit NewPendingSwap(_to, _amount, pendingSwapHeight);
        pendingSwapHeight++;
    }
    
    function __popPendingSwap() private returns (address, uint) {
        uint id = pendingSwapKeys[0];
        pendingSwapKeys.pop();
        PendingSwap memory ps = pendingSwaps[id];
        delete pendingSwaps[id];
        return (ps.to, ps.amount);
    }

    address payable owner;
    
    constructor() {
        owner = payable(msg.sender);
    }

    // A function anyone can call to request a swap of MATIC -> mMATIC to the given address on Cardano
    function swap(address _to, uint _amount) public {
        //address MATIC_CONTRACT = 0x0000000000000000000000000000000000001010;
        //IERC20(MATIC_CONTRACT).transferFrom(msg.sender, address(this), _amount);
        //payable(address(this)).transfer(_amount);
        __addPendingSwap(_to, _amount);
    }

    function popSwap() public returns (address, uint) {
        require(msg.sender == owner, "Only the contract owner can call this function");
        return __popPendingSwap();
    }

}