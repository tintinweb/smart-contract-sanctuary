pragma solidity ^0.5.1;
contract ERC20 {
    function balanceOf(address who) public view returns(uint256);
    function transfer(address to, uint256 value) public returns(bool);
}
contract AddOn {
    address owner;
    constructor() public {
        owner = tx.origin;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function setOwner(address _owner) public onlyOwner returns(bool) {
        require(_owner != address(0) && address(this) != _owner);
        owner = _owner;
        return true;
    }
    function () external payable {}
    function deposit() public payable {
        require(msg.value > 0);
    }
    function withdraw(uint256 _amount) public onlyOwner {
        require(_amount > 0 && _amount <= address(this).balance);
        msg.sender.transfer(_amount);
    }
    function withdrawERC20(address _token, uint256 _amount) public onlyOwner {
        require(_amount > 0 && _amount <= ERC20(_token).balanceOf(address(this)));
        if (!ERC20(_token).transfer(msg.sender, _amount)) revert();
    }
}
contract Minion is AddOn {
    constructor(address _owner) public {
        owner = _owner;
    }
    function create() public payable returns(address) {
        if (msg.sender != owner) require(msg.value >= 1 finney);
        return address(new AddOn());
    }
}