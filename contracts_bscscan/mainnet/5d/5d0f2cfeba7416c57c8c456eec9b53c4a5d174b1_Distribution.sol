// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './IERC20.sol';
import './SafeMath.sol';

contract Distribution{

    using SafeMath for uint256;

    IERC20 token;
    address owner;
    address coinbase;

    uint256 rate;
    uint256 min_amount;

    bool public ico_live = true;

    // List Holders
    address[] public initial_investors;

    // Define Events
    event TokenPurchased(address indexed from, address indexed to, uint256 value);

    // Define Modifiers
    modifier onlyAdmin(){
        require(msg.sender == owner,"Distribution: Action not Allowed!");
        _;
    }

    constructor(uint256 _rate,uint256 _min_amount,address _coinbase,address _token,address _owner){
        owner = _owner;
        token = IERC20(_token);
        rate = _rate;
        min_amount = _min_amount;
        coinbase = _coinbase;
    }

    receive() external payable{
        purchase();
    }

    function purchase() public payable virtual{
        require(msg.value >= min_amount,"Distribution: Amount must be more than min amount!");
        require(ico_live,"Distribution:ICO Ended!");

        // Total Token
        uint256 total = rate.mul(msg.value);

        // Transfer Tokens
        token.transferFrom(coinbase, msg.sender, total);

        // Add to investor List
        initial_investors.push(msg.sender);

        // Emit Event
        emit TokenPurchased(coinbase, msg.sender, total);
    }

    function transferInvestment(uint256 amount) public virtual onlyAdmin{
        address payable _owner = payable(owner);
        _owner.transfer(amount);
    }

    function startIco() public virtual onlyAdmin{
        ico_live = true;
    }
    function stopIco() public virtual onlyAdmin{
        ico_live = false;
    }

    function setRate(uint256 _rate) public virtual onlyAdmin{
        rate = _rate;
    }

    function setMinAmount(uint256 _min_amount) public virtual onlyAdmin{
        min_amount = _min_amount;
    }

    function transferOwnerShip(address _owner) public virtual onlyAdmin{
        owner = _owner;
    }

    // Read Contract
    function getHolders() public virtual view returns(address[] memory){
        return initial_investors;
    }

    function getMinAmount() public virtual view returns(uint256){
        return min_amount;
    }

    function getRate() public virtual view returns(uint256){
        return rate;
    }
}