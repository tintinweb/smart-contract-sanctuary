/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

pragma solidity ^0.5.12;


library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20Basic {
    uint public _totalSupply;

    function totalSupply() public view returns (uint);

    function balanceOf(address who) public view returns (uint);

    function transfer(address to, uint value) public;

    function transferFrom(address from, address to, uint value) public;

    event Transfer(address indexed from, address indexed to, uint value);
}

contract MixerTest {
    using SafeMath for uint;
    mapping(string => uint) token_balance;
    mapping(string => address) public token_address;
    address public owner;

    struct OfferInfo {
        uint sell_amt;
        string sell_token;
        uint buy_amt;
        string buy_token;
        address owner;
        uint64 timestamp;
        bytes32 secret_hash;
    }

    uint last_offer_id = 0;
    mapping(uint => OfferInfo) public offers;

    event MakeOrder(uint number_offer, uint pay_amt, string pay_token, uint buy_amt, string buy_token);
    event CloseOrder(uint number_offer, address buyer);
    event OrderCancel(uint number_offer);


    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    modifier can_buy(uint id) {
        _;
    }

    modifier can_cancel(uint id) {
        require(getOwner(id) == msg.sender);
        _;
    }

    modifier can_offer {
        _;
    }


    constructor() public {
        owner = msg.sender;
    }
    function getOwner(uint id) public view returns (address _owner) {
        return offers[id].owner;
    }

    function _next_id() internal returns (uint){
        last_offer_id++;
        return last_offer_id;
    }

    function setAddressToken(address _addr, string calldata _symbol) onlyOwner external returns (bool){
        token_address[_symbol] = _addr;
        token_balance[_symbol] = 0;
        return true;
    }

    function getBalanceToken(string memory _symbol) public view returns (uint _balance){
        ERC20Basic b = ERC20Basic(token_address[_symbol]);
        return b.balanceOf(address(this));
    }

    function sendTokens(string memory _symbol, uint amount, address _to) internal returns (bool _is_ok){
        require(getBalanceToken(_symbol) >= amount, "contract dont have tokens");
        ERC20Basic b = ERC20Basic(token_address[_symbol]);
        b.transfer(_to, amount);
        token_balance[_symbol] -= amount;
        return true;
    }

    function checkBalanceToken(string memory _symbol, uint amount) internal returns (bool _is_check){
        uint bal = getBalanceToken(_symbol);
        if (bal > 0 && token_balance[_symbol] + amount <= bal) {
            token_balance[_symbol] += amount;
            return true;
        } else {
            return false;
        }
    }

    function balanceOfOwner() external view returns (uint){
        return owner.balance;
    }

    function balanceOf() public view returns (uint){
        return address(this).balance;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function getOffer(uint id) public view returns (uint, string memory, uint, string memory) {
        OfferInfo memory offer = offers[id];
        return (offer.sell_amt, offer.sell_token, offer.buy_amt, offer.buy_token);
    }

    function offer(uint sell_amt, string memory sell_token, uint buy_amt, string memory buy_token, bytes32 secret_hash) public can_offer returns (uint id){
        require(uint128(sell_amt) == sell_amt);
        require(uint128(buy_amt) == buy_amt);
        require(token_address[sell_token] != address(0x0));
        require(token_address[buy_token] != address(0x0));

        require(sell_amt > 0);
        require(buy_amt > 0);
        require(token_address[sell_token] != token_address[buy_token]);

        ERC20Basic b = ERC20Basic(token_address[sell_token]);
        uint bal_before = getBalanceToken(sell_token);
        b.transferFrom(msg.sender, address(this), sell_amt);
        uint bal_after = getBalanceToken(sell_token);
        assert(bal_before + sell_amt <= bal_after);

        require(checkBalanceToken(sell_token, sell_amt) == true, "you dont give tokens");

        OfferInfo memory info;
        info.sell_amt = sell_amt;
        info.sell_token = sell_token;
        info.buy_amt = buy_amt;
        info.buy_token = buy_token;
        info.owner = msg.sender;
        info.secret_hash = secret_hash;
        id = _next_id();
        offers[id] = info;
        emit MakeOrder(id, sell_amt, sell_token, buy_amt, buy_token);
        return id;
    }

    function buy_offer(uint _id, string memory secret_word) public can_offer returns (uint id){

        require(offers[_id].secret_hash == sha256(abi.encodePacked(secret_word)));
        OfferInfo memory info = offers[_id];

        ERC20Basic b = ERC20Basic(token_address[info.buy_token]);
        uint bal_before = getBalanceToken(info.buy_token);
        b.transferFrom(msg.sender, address(this), info.buy_amt);
        uint bal_after = getBalanceToken(info.buy_token);
        assert(bal_before + info.buy_amt <= bal_after);
        require(checkBalanceToken(info.buy_token, info.buy_amt) == true, "you dont give tokens");

        sendTokens(info.buy_token,
            info.buy_amt,
            info.owner);
        sendTokens(info.sell_token,
            info.sell_amt,
            msg.sender);


        delete offers[_id];
        emit CloseOrder(_id, msg.sender);
        return _id;
    }

    function cancel(uint id) public can_cancel(id) returns (bool){
        OfferInfo memory info = offers[id];
        sendTokens(info.sell_token,
            info.sell_amt,
            msg.sender);
        delete offers[id];
        emit OrderCancel(id);
        return true;
    }
}