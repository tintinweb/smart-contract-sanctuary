// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './IERC20.sol';
import './SafeMath.sol';

contract Airdrop{

    using SafeMath for uint256;

    IERC20 token;
    address owner;
    address coinbase;
    struct Investor{
        address wallet;
        string email;
        uint256 amount;
        uint256 time;
    }
    uint256 rate;
    uint256 min_amount;

    bool public airdrop_live = true;

    // List Holders
    Investor[] public initial_investors;

    // map investor;
    mapping(address => bool) investors;

    // Define Events
    event AirdropReceived(address indexed from, address indexed to, uint256 value);

    // Define Modifiers
    modifier onlyAdmin(){
        require(msg.sender == owner,"Airdrop: Action not Allowed!");
        _;
    }

    constructor(uint256 _rate,uint256 _min_amount,address _coinbase,address _token,address _owner){
        owner = _owner;
        token = IERC20(_token);
        rate = _rate;
        min_amount = _min_amount;
        coinbase = _coinbase;
    }

    function airdrop(string memory mail) public payable virtual{
        require(msg.value >= min_amount,"Airdrop: Amount must be more than min amount!");
        require(airdrop_live,"Airdrop: Airdrop Ended!");
        require(!investors[msg.sender], "Airdrop: Already Claimed!");

        // Total Token
        uint256 total = rate.mul(msg.value);

        // Transfer Tokens
        token.transferFrom(coinbase, msg.sender, total);

        // Add to investor List
        Investor memory _investor;
        _investor.wallet = msg.sender;
        _investor.email = mail;
        _investor.amount = msg.value;
        _investor.time = block.timestamp;
        initial_investors.push(_investor);
        investors[msg.sender] = true;

        // Emit Event
        emit AirdropReceived(coinbase, msg.sender, total);
    }

    function transferInvestment(uint256 amount) public virtual onlyAdmin{
        address payable _owner = payable(owner);
        _owner.transfer(amount);
    }

    function startIco() public virtual onlyAdmin{
        airdrop_live = true;
    }
    function stopIco() public virtual onlyAdmin{
        airdrop_live = false;
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
    function getHolders() public virtual view returns(Investor[] memory){
        return initial_investors;
    }

    function getMinAmount() public virtual view returns(uint256){
        return min_amount;
    }

    function getRate() public virtual view returns(uint256){
        return rate;
    }
    function investorStatus(address _investor) public virtual view returns(bool){
        return investors[_investor];
    }
}