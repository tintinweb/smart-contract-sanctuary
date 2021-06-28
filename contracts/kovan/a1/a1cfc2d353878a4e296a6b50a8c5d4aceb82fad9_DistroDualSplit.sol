/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

pragma solidity 0.6.7;

abstract contract DSTokenLike {
    function balanceOf(address) virtual view public returns (uint256);
    function transfer(address, uint256) virtual public;
}

contract DistroDualSplit {
    // --- Structs ---
    struct TokenReceiver {
        address who;
        uint256 allocation;
    }

    // --- Variables ---
    DSTokenLike   public token;
    TokenReceiver public firstReceiver;
    TokenReceiver public secondReceiver;

    constructor(
      address token_,
      address receiver1,
      address receiver2,
      uint256 allocation1
    ) public {
        require(token_ != address(0), "DistroDualSplit/null-token");
        require(receiver1 != address(0), "DistroDualSplit/null-receiver-1");
        require(receiver2 != address(0), "DistroDualSplit/null-receiver-2");
        require(both(allocation1 > 0, allocation1 < 100), "DistroDualSplit/invalid-allocation-1");

        token          = DSTokenLike(token_);

        firstReceiver  = TokenReceiver(receiver1, allocation1);
        secondReceiver = TokenReceiver(receiver2, 100 - allocation1);
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Math ---
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "DistroDualSplit/multiply-uint-uint-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "DistroDualSplit/sub-uint-uint-underflow");
    }

    // --- Core Logic ---
    /*
    * @notice Distribute tokens to the two receivers
    */
    function distribute() public {
        uint256 firstAllocation  = multiply(firstReceiver.allocation, token.balanceOf(address(this))) / 100;
        uint256 secondAllocation = subtract(token.balanceOf(address(this)), firstAllocation);

        token.transfer(firstReceiver.who, firstAllocation);
        token.transfer(secondReceiver.who, secondAllocation);
    }
}