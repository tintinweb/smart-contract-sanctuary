pragma solidity ^0.5.2;
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
    function transfer(address to, uint value) public returns(bool);
    function transferFrom(address from, address to, uint value) public returns(bool);
}
contract Vault {
    Info public ContractDetails;
    struct Info {
        address Contract;
        address Creator;
        address Owner;
        bytes32 UniqueID;
        string Username;
    }
    constructor(address _owner, string memory _username) public {
        ContractDetails.Contract = address(this);
        ContractDetails.Owner = _owner;
        ContractDetails.Creator = msg.sender;
        ContractDetails.UniqueID = keccak256(abi.encodePacked(now, address(this), _owner, msg.sender, _username));
        ContractDetails.Username = _username;
    }
    modifier onlyOwner() {
        require(msg.sender == ContractDetails.Owner);
        _;
    }
    function changeOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0) && address(this) != newOwner);
        ContractDetails.Owner = newOwner;
    }
    function () external payable {}
    function deposit() public payable {
        if (msg.value < 1) revert();
    }
    function depositToken(address token, uint amount) public {
        uint length;
        assembly { length := extcodesize(token) }
        require(length > 0 && amount > 0);
        if (!ERC20(token).transferFrom(msg.sender, address(this), amount))
        revert();
    }
    function withdraw(uint amount) public onlyOwner {
        require(amount > 0 && amount <= address(this).balance);
        msg.sender.transfer(amount);
    }
    function withdrawToken(address token, uint amount) public onlyOwner {
        uint length;
        assembly { length := extcodesize(token) }
        require(amount > 0 && length > 0);
        if (!ERC20(token).transfer(msg.sender, amount))
        revert();
    }
}