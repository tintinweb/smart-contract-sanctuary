pragma solidity ^0.4.25;
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
    function transfer(address to, uint value) public returns(bool);
    event Transfer(address indexed _from, address indexed _to, uint _value);
}
contract Store {
    address public owner;
    bool paused;
    mapping(address => uint) tokenRates;
    constructor() public {
        owner = msg.sender;
        paused = false;
    }
    modifier admin() {
        require(msg.sender == owner);
        _;
    }
    function () public payable {
        if (msg.sender != owner && msg.value > 0) owner.transfer(msg.value);
    } //fallback used for donation
    function getBalance(address token) internal view returns(uint) {
        if (token == address(0)) return address(this).balance;
        else return ERC20(token).balanceOf(address(this));
    }
    function rateOf(address token) public view returns(uint) {
        return tokenRates[token];
    } //check token rate
    function dataOfBuy(address token) public pure returns(bytes) {
        return abi.encodePacked(bytes16(bytes4(keccak256("buy(address)"))), token);
    } //parse data for buy token
    function dataOfSell(address token, uint setRate) public pure returns(bytes) {
        return abi.encodePacked(bytes16(bytes4(keccak256("sell(address,uint256)"))), token, setRate);
    } //parse data for sell token
    function setOwner(address newOwner) public admin returns(bool) {
        require(newOwner != address(0) && address(this) != newOwner);
        owner = newOwner;
        return true;
    } //change ownership
    function setPausable(bool pausableState) public admin returns(bool) {
        paused = pausableState;
        return true;
    } //paused=true => forward ether from buy function to owner address
    function sell(address token, uint setRate) public admin returns(bool) {
        require(setRate > 0);
        tokenRates[token] = setRate;
        return true;
    } //set token rate
    function sendTo(address dest, uint amount, address token) public admin returns(bool) {
        require(dest != address(0) && address(this) != dest);
        require(amount > 0 && amount <= getBalance(token));
        if (token == address(0)) {
            if (!dest.call.gas(250000).value(amount)()) dest.transfer(amount);
        } else {
            if (!ERC20(token).transfer(dest, amount)) revert();
        }
        return true;
    } //withdrawal
    function buy(address token) public payable returns(bool) {
        require(token != address(0));
        require(rateOf(token) > 0);
        uint amountEther = msg.value;
        uint amountERC20 = amountEther * rateOf(token);
        uint supplyERC20 = getBalance(token);
        uint returnEther = 0;
        if (amountERC20 > supplyERC20) {
            returnEther = amountEther - (supplyERC20 / rateOf(token));
            amountERC20 = supplyERC20;
        }
        require(ERC20(token).transfer(msg.sender, amountERC20));
        if (returnEther > 0) msg.sender.transfer(returnEther);
        if (!paused) owner.transfer((amountEther - returnEther));
        return true;
    } //buy token (if token rate higher than 0)
}