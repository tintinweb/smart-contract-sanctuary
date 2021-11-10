/**
 *Submitted for verification at BscScan.com on 2021-11-10
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EspanaMetod {

    uint256 public constant MIN_AMOUNT = 1000;

    Swap[] public swaps;
    uint256 public swapCount = 0;

    enum State {
        NOTOPEN, 
        INITIALIZED, 
        REFUNDED, 
        ACTIVE, 
        CLOSED
    }

    struct Swap {
        State state;
        uint256 tradeAmount;
        address cryptoBuyer; 
        address cryptoSeller;
        uint256 createdAt;
        string cryptoBuyerMemo;
        string cryptoSellerMemo;
    }

    event SwapOpened(uint256 id, address cryptoBuyer, uint256 tradeAmount);
    event SwapCanceled(uint256 id, address cryptoBuyer, uint256 totalAmount);
    event SwapCalled(uint256 id, address cryptoSeller, uint256 tradeAmount);
    event SwapClosed(uint256 id, address cryptoBuyer, address cryptoSeller, uint256 tradeAmount);

    function viewSwap(uint256 id) public view returns (
        State state, 
        uint256 tradeAmount,
        address cryptoBuyer, 
        address cryptoSeller, 
        uint256 createdAt, 
        string memory cryptoBuyerMemo, 
        string memory cryptoSellerMemo
    ) {
        Swap memory swap = swaps[id];
        return (swap.state, swap.tradeAmount, swap.cryptoBuyer, swap.cryptoSeller, swap.createdAt, swap.cryptoBuyerMemo, swap.cryptoSellerMemo);
    }

    function openSwap(string memory memo) payable external returns(uint256 id) {
        require(msg.value >= MIN_AMOUNT, "EspanaMetod: Opening a swap with value less than minimum. "); 

        uint256 tradeAmount = div(msg.value, 3);
        Swap memory swap = Swap({
            state: State.INITIALIZED,
            tradeAmount: tradeAmount,
            cryptoBuyer: msg.sender,
            cryptoSeller: address(0),
            createdAt: block.timestamp, 
            cryptoBuyerMemo: memo, 
            cryptoSellerMemo: ""
        });
        swaps.push(swap);
        
        emit SwapOpened(swapCount++, msg.sender, tradeAmount);
        return swapCount - 1;
    }

    function refundSwap(uint256 id) external {
        Swap storage swap = swaps[id];
        require(swaps[id].state == State.INITIALIZED, "EspanaMetod: Swap not in INITIALIZED state. ");
        require(msg.sender == swap.cryptoBuyer, "EspanaMetod: Refunder isn't cryptoBuyer. "); 

        uint256 totalAmount = mul(swap.tradeAmount, 3);
        payable(msg.sender).transfer(totalAmount);

        swap.state = State.REFUNDED;
        emit SwapCanceled(id, msg.sender, totalAmount);
    }

    function callSwap(uint256 id, string memory memo) payable external {
        Swap storage swap = swaps[id];
        require(msg.sender != swap.cryptoBuyer, "EspanaMetod: msg.sender can not be cryptoBuyer. ");
        require(swaps[id].state == State.INITIALIZED, "EspanaMetod: Swap not in INITIALIZED state. ");
        uint256 tradeAmount = div(msg.value, 3);
        require(swap.tradeAmount == tradeAmount, "EspanaMetod: Invalid trade amount. ");

        swap.state = State.ACTIVE;
        swap.cryptoSeller = msg.sender;
        swap.cryptoSellerMemo = memo;

        emit SwapCalled(id, msg.sender, tradeAmount);
    }

    function approveSwap(uint256 id) external {
        Swap storage swap = swaps[id];
        require(swap.state == State.ACTIVE, "EspanaMetod: Swap not in ACTIVE state. ");
        require(swap.cryptoSeller == msg.sender, "EspanaMetod: cryptoSeller must close the swap. ");

        payable(swap.cryptoBuyer).transfer(mul(swap.tradeAmount, 4));
        payable(swap.cryptoSeller).transfer(mul(swap.tradeAmount, 2));
        swap.state = State.CLOSED;

        emit SwapClosed(id, swap.cryptoBuyer, swap.cryptoSeller, swap.tradeAmount);
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
}