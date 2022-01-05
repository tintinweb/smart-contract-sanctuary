/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

/*
The place to buy/sell patriot token.
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;


/// @title seller/buyer with fixed price
/// @author aqoleg
/// @dev
contract Seller {
    address public token = 0x62C5037b08B972E219a75dCd7F6f4E0796F5DC5c;

    /// @return token price in wei/token
    uint256 public price = 1e12;

    /// @return total number of tokens sold
    mapping(address => uint256) public sold;

    /// @return total number of tokens purchased
    mapping(address => uint256) public purchased;

    event Purchase(uint256 _tokens);

    event Sale(uint256 _tokens);

    /// @notice any unrecognized function are treated as a purchase
    fallback () external payable {
        buy();
    }

    /// @notice buys tokens with incoming eth
    receive () external payable {
        buy();
    }

    /// @notice sends tokens to the sender in exchange for all incoming eth
    /// @notice total number of tokens purchased must be less than 1 million for each address
    /// @return number of tokens purchased
    function buy() public payable returns (uint256) {
        uint256 tokens = msg.value * 1e18 / price;
        require(tokens <= Erc20(token).balanceOf(address(this)), "not enough tokens to sell");
        purchased[msg.sender] += tokens;
        require(purchased[msg.sender] <= 1e24, "purchase limit exceeded");
        Erc20(token).transfer(msg.sender, tokens);
        emit Purchase(tokens);
        return tokens;
    }

    /// @notice sends eth to the sender in exchange for tokens
    /// @notice total number of tokens sold must be less than 1 million for each address
    /// @dev approve tokens to transfer before this
    /// @param _tokens number of tokens to sell
    /// @return number of wei from sale
    function sell(uint256 _tokens) external returns (uint256) {
        uint256 payout = _tokens * price / 1e18;
        require(payout <= address(this).balance, "not enough eth to buy");
        sold[msg.sender] += _tokens;
        require(sold[msg.sender] <= 1e24, "sales limit exceeded");
        Erc20(token).transferFrom(msg.sender, address(this), _tokens);
        payable(msg.sender).transfer(payout);
        emit Sale(_tokens);
        return payout;
    }
}


interface Erc20 {
    function balanceOf(address _account) external view returns (uint256);

    function transfer(address _to, uint256 _value) external;

    function transferFrom(address _from, address _to, uint256 _value) external;
}