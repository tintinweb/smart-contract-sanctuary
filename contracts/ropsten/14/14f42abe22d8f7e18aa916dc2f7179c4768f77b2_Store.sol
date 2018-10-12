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
    constructor(address newOwner, bool pausableState) public {
        owner = newOwner;
        paused = pausableState;
    }
    modifier admin() {
        require(msg.sender == owner);
        _;
    }
    function getBalance(address token) internal view returns(uint) {
        if (token == address(0)) return address(this).balance;
        else return ERC20(token).balanceOf(address(this));
    }
    function rateOf(address token) public view returns(uint) {
        return tokenRates[token];
    }
    function dataOfBuy(address token) public pure returns(bytes) {
        return abi.encodePacked(bytes16(bytes4(keccak256("buy(address)"))), token);
    }
    function dataOfSell(address token, uint setRate) public pure returns(bytes) {
        return abi.encodePacked(bytes16(bytes4(keccak256("sell(address,uint256)"))), token, setRate);
    }
    function setOwner(address newOwner) public admin returns(bool) {
        require(newOwner != address(0) && address(this) != newOwner);
        owner = newOwner;
        return true;
    }
    function setPausable(bool pausableState) public admin returns(bool) {
        paused = pausableState;
        return true;
    }
    function sell(address token, uint setRate) public admin returns(bool) {
        require(setRate > 0);
        tokenRates[token] = setRate;
        return true;
    }
    function sendTo(address dest, uint amount, address token) public admin returns(bool) {
        require(dest != address(0) && address(this) != dest);
        require(amount > 0 && amount <= getBalance(token));
        if (token == address(0)) {
            if (!dest.call.gas(250000).value(amount)()) dest.transfer(amount);
        } else {
            if (!ERC20(token).transfer(dest, amount)) revert();
        }
        return true;
    }
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
    }
}