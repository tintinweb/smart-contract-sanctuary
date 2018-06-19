pragma solidity ^0.4.15;

/*

    Crypto Market Prices via Ethereum Smart Contract

    A community driven smart contract that lets your contracts use fiat
    amounts in USD, EURO, and GBP. Need to charge $10.50 for a contract call?
    With this contract, you can convert ETH and other crypto&#39;s.

    Repo: https://github.com/hunterlong/marketprice
    Look at repo for more token examples

    Examples:

      MarketPrice price = MarketPrice(CONTRACT_ADDRESS);

      uint256 ethCent = price.USD(0);        // returns $0.01 worth of ETH in USD.
      uint256 weiAmount = ethCent * 2500     // returns $25.00 worth of ETH in USD
      require(msg.value == weiAmount);       // require $25.00 worth of ETH as a payment

    @author Hunter Long
*/

contract MarketPrice {

    mapping(uint => Token) public tokens;

    address public sender;
    address public creator;

    event NewPrice(uint id, string token);
    event DeletePrice(uint id);
    event UpdatedPrice(uint id);
    event RequestUpdate(uint id);

    struct Token {
        string name;
        uint256 eth;
        uint256 usd;
        uint256 eur;
        uint256 gbp;
        uint block;
    }

    // initialize function
    function MarketPrice() {
        creator = msg.sender;
        sender = msg.sender;
    }

    // returns the Token struct
    function getToken(uint _id) internal constant returns (Token) {
        return tokens[_id];
    }

    // returns rate price of coin related to ETH.
    function ETH(uint _id) constant returns (uint256) {
        return tokens[_id].eth;
    }

    // returns 0.01 value in United States Dollar
    function USD(uint _id) constant returns (uint256) {
        return tokens[_id].usd;
    }

    // returns 0.01 value in Euro
    function EUR(uint _id) constant returns (uint256) {
        return tokens[_id].eur;
    }

    // returns 0.01 value in British Pound
    function GBP(uint _id) constant returns (uint256) {
        return tokens[_id].gbp;
    }

    // returns block when price was updated last
    function updatedAt(uint _id) constant returns (uint) {
        return tokens[_id].block;
    }

    // update market rates in USD, EURO, and GBP for a specific coin
    function update(uint id, string _token, uint256 eth, uint256 usd, uint256 eur, uint256 gbp) external {
        require(msg.sender==sender);
        tokens[id] = Token(_token, eth, usd, eur, gbp, block.number);
        NewPrice(id, _token);
    }

    // delete a token from the contract
    function deleteToken(uint id) {
        require(msg.sender==sender);
        DeletePrice(id);
        delete tokens[id];
    }

    // change creator address
    function changeCreator(address _creator){
        require(msg.sender==creator);
        creator = _creator;
    }

    // change sender address
    function changeSender(address _sender){
        require(msg.sender==creator);
        sender = _sender;
    }

    // execute function for creator if ERC20&#39;s get stuck in this wallet
    function execute(address _to, uint _value, bytes _data) external returns (bytes32 _r) {
        require(msg.sender==creator);
        require(_to.call.value(_value)(_data));
        return 0;
    }

    // default function so this contract can accept ETH with low gas limits.
    function() payable {

    }

    // public function for requesting an updated price from server
    // using this function requires a payment of $0.35 USD
    function requestUpdate(uint id) external payable {
        uint256 weiAmount = tokens[0].usd * 35;
        require(msg.value >= weiAmount);
        sender.transfer(msg.value);
        RequestUpdate(id);
    }

    // donation function that get forwarded to the contract updater
    function donate() external payable {
        require(msg.value >= 0);
        sender.transfer(msg.value);
    }

}