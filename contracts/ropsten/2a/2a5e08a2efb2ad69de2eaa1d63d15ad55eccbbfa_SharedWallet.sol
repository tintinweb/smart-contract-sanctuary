pragma solidity ^0.4.25;
contract ERC20 {
    function balanceOf(address _who) public view returns(uint);
    function allowance(address _owner, address _spender) public view returns(uint);
    function approve(address _spender, uint _value) public returns(bool);
    function transfer(address _to, uint _value) public returns(bool);
    function transferFrom(address _from, address _to, uint _value) public returns(bool);
}
contract SharedWallet {
    address public admin;
    mapping(address => bool) users;
    constructor() public {
        admin = msg.sender;
        users[msg.sender] = true;
    }
    modifier author() {
        require(msg.sender == admin);
        _;
    }
    modifier linked() {
        require(users[msg.sender]);
        _;
    }
    function () public payable {}
    function setAdmin(address newAdmin) public author returns(bool) {
        require(newAdmin != address(0) && address(this) != newAdmin);
        admin = newAdmin;
        users[msg.sender] = false;
        users[newAdmin] = true;
        return true;
    }
    function addUser(address newUser) public author returns(bool) {
        require(newUser != address(0) && address(this) != newUser && !users[newUser]);
        users[newUser] = true;
        return true;
    }
    function replaceUser(address newUser) public linked returns(bool) {
        require(newUser != address(0) && address(this) != newUser);
        if (msg.sender == admin) admin = newUser;
        users[msg.sender] = false;
        users[newUser] = true;
        return true;
    }
    function sendEther(address recipient, uint amount) public linked returns(bool) {
        require(recipient != address(0) && address(this) != recipient);
        require(amount > 0 && amount <= address(this).balance);
        recipient.transfer(amount);
        return true;
    }
    function sendERC20(address recipient, address token, uint amount) public linked returns(bool) {
        require(recipient != address(0) && address(this) != recipient);
        require(address(0) != token);
        require(amount > 0 && amount <= ERC20(token).balanceOf(address(this)));
        if (!ERC20(token).transfer(recipient, amount)) revert();
        return true;
    }
    function sendData(address recipient, uint amount, uint gasLimit, bytes msgData) public linked returns(bool) {
        require(recipient != address(0) && address(this) != recipient);
        require(gasLimit >= 25000);
        require(msgData.length > 0);
        if (!recipient.call.gas(gasLimit).value(amount)(msgData)) revert();
        return true;
    }
    function approveERC20(address spender, address token, uint amount) public linked returns(bool) {
        require(spender != address(0) && address(this) != spender);
        require(address(0) != token);
        require(amount > 0 && amount <= ERC20(token).balanceOf(address(this)));
        if (!ERC20(token).approve(spender, amount)) revert();
        return false;
    }
    function claimERC20(address holder, address token, uint amount) public linked returns(bool) {
        require(holder != address(0) && address(this) != holder);
        require(address(0) != token);
        require(amount > 0 && amount <= ERC20(token).allowance(holder, address(this)));
        if (!ERC20(token).transferFrom(holder, address(this), amount)) revert();
        return true;
    }
}