/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

// SPDX-License-Identifier: MIT
// Version: 1
// Author: Satoshi Nakamoto <[email protected]>
pragma solidity >=0.4.22 <0.7.0;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function approve(address, uint) external returns (bool);
    function deposit() external payable;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function withdraw(uint) external;
}

library SafeMath {
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }
}

contract AnyTokenEscrowV1 {
    using SafeMath for uint;

    // the state of the transaction
    enum State { Inactive, Created, Locked }
    // the structure of a transaction
    struct Transaction {
        address token; // token contract address
        uint amount; // token amount to be transacted (stake = 2 * amount)
        address seller;
        address buyer;
        State state; // the state has a default value `State.Inactive`
    }
    // transactions that initiated by a token buyer
    // A buyer can have only one active transaction at once
    mapping(address=>Transaction) public transactions;
    
    // fully decentralized. no owner. non-stoppable.
    constructor() public {
    }

    event Created();
    event Aborted();
    event Accepted();
    event Confirmed();

    // Buyer (anyone) can initiate a transaction
    function create(address _seller, address _token, uint _amount) public
    {
        require(State.Inactive == transactions[msg.sender].state, "State not Inactive");

        IERC20(_token).transferFrom(msg.sender, address(this), _amount.mul(2));

        Transaction memory txn = Transaction({
            token: _token,
            amount: _amount,
            seller: _seller,
            buyer: msg.sender,
            state: State.Created
        });

        transactions[msg.sender] = txn;

        emit Created();
    }

    // Buyer can abort the transaction and reclaim the token
    // before the txn is locked
    function abort() public
    {
        require(State.Created == transactions[msg.sender].state, "State not Created");
        require(msg.sender == transactions[msg.sender].buyer, "Not buyer");

        //refund the buyer
        address token = transactions[msg.sender].token;
        uint amount = transactions[msg.sender].amount;
        IERC20(token).transfer(msg.sender, amount.mul(2));

        emit Aborted();
        transactions[msg.sender].state = State.Inactive;
    }

    // Seller accepts the sale
    // 2 * amount of tokens will be locked up
    // until confirmed
    function accept(address _buyer) public
    {
        require(State.Created == transactions[_buyer].state, "State not Created");
        require(msg.sender == transactions[_buyer].seller, "Seller required.");

        address token = transactions[_buyer].token;
        uint amount = transactions[_buyer].amount;
        IERC20(token).transferFrom(msg.sender, address(this), amount.mul(2));

        emit Accepted();
        transactions[_buyer].state = State.Locked;
    }

    // Seller confirms to close the deal
    // 1 * amount of tokens will be refunded to Seller
    // 3 * amount of tokens will be refunded to Buyer
    function confirm(address _buyer) public 
    {
        require(State.Locked == transactions[_buyer].state, "State not Locked");
        require(msg.sender == transactions[_buyer].seller, "Seller required.");

        address token = transactions[_buyer].token;
        uint amount = transactions[_buyer].amount;
        IERC20(token).transfer(msg.sender, amount);
        IERC20(token).transfer(_buyer, amount.mul(3));

        emit Confirmed();
        transactions[_buyer].state = State.Inactive;
    }

}