/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

pragma solidity ^0.7.0;

contract DonationToken {
    uint constant public totalSupply = 1_000_000;
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    uint internal totalWithdrawn = 0;
    mapping (address => uint) internal dividends;
    mapping (address => uint) internal dividendsAt;

    constructor () {
        balanceOf [msg.sender] = totalSupply;
    }

    receive () external payable {
        // Do nothing
    }

    function transfer (address to, uint256 value) public returns (bool success) {
        success = balanceOf [msg.sender] >= value;

        if (success) {
            updateDividends (msg.sender);
            updateDividends (to);

            balanceOf [msg.sender] -= value;
            balanceOf [to] += value;

            emit Transfer (msg.sender, to, value);
        }
    }

    function transferFrom (address from, address to, uint256 value) public returns (bool success) {
        success = allowance [from][msg.sender] >= value && balanceOf [from] >= value;

        if (success) {
            updateDividends (from);
            updateDividends (to);

            allowance [from][msg.sender] -= value;
            balanceOf [from] -= value;
            balanceOf [to] += value;

            emit Transfer (from, to, value);
        }
    }

    function approve (address spender, uint256 value) public returns (bool success) {
        success = true;

        allowance [msg.sender][spender] = value;

        emit Approval (msg.sender, spender, value);
    }

    function dividendsOf (address owner) public view returns (uint value) {
        return (dividends [owner] + (totalDonated () - dividendsAt [owner]) * balanceOf [owner]) / totalSupply;
    }

    function withdrawDividends (address payable to, uint value) public returns (bool success) {
        updateDividends (msg.sender);

        uint sv = value * totalSupply;

        success = dividends [msg.sender] >= sv;

        if (success) {
            dividends [msg.sender] -= sv;
            totalWithdrawn += value;
    
            require (to.send (value));
        }
    }

    function updateDividends (address owner) internal {
        uint td = totalDonated ();

        dividends [owner] += (td - dividendsAt [owner]) * balanceOf [owner];
        dividendsAt [owner] = td;
    }

    function totalDonated () internal view returns (uint value) {
        return totalWithdrawn + address (this).balance;
    }

    event Transfer (address indexed from, address indexed to, uint256  value);
    event Approval (address indexed owner, address indexed spender, uint256 value);
}