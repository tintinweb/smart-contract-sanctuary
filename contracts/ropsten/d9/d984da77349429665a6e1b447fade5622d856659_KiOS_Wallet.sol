pragma solidity ^0.4.25;
interface ERC20 {
    function totalSupply() external view returns(uint);
    function balanceOf(address _who) external view returns(uint);
    function approve(address _spender, uint _value) external returns(bool);
    function transfer(address _to, uint _value) external returns(bool);
}
interface KiOS {
    function sell(address _token, uint _amount, uint _rate) external returns(bool);
}
contract KiOS_Wallet {
    address public owner;
    address public store;
    constructor(address _owner, address _store) public {
        owner = _owner;
        store = _store;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function getBalance(address token) internal view returns(uint) {
        if (address(0) == token) return address(this).balance;
        else return ERC20(token).balanceOf(address(this));
    }
    function isToken(address what) internal view returns(bool) {
        if (address(0) == what) return false;
        else if (ERC20(what).totalSupply() > 0) return true;
        else return false;
    }
    function check(address who) internal view returns(bool) {
        if (who != address(0) && address(this) != who) return true;
        else return false;
    }
    function setOwner(address newOwner) public onlyOwner returns(bool) {
        require(check(newOwner));
        owner = newOwner;
        return true;
    }
    function setStore(address newStore) public onlyOwner returns(bool) {
        require(check(newStore) && newStore != owner);
        store = newStore;
        return true;
    }
    function sellToken(address token, uint amount, uint rate) public onlyOwner returns(bool) {
        require(isToken(token) && rate > 0);
        require(amount > 0 && amount <= ERC20(token).balanceOf(address(this)));
        if (!ERC20(token).approve(store, amount)) revert();
        return KiOS(store).sell(token, amount, rate);
    }
    function() public payable {}
    function withdraw(address token, uint amount) public onlyOwner returns(bool) {
        require(amount > 0 && amount <= getBalance(token));
        if (isToken(token)) {
            if (!ERC20(token).transfer(owner, amount))
            revert();
        } else {
            owner.transfer(amount);
        }
        return true;
    }
}