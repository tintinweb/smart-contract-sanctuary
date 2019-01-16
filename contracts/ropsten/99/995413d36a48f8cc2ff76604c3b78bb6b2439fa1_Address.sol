pragma solidity ^0.5.2;
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
    function transfer(address to, uint value) public returns(bool);
}
contract Checked {
    function isContract(address addr) internal view returns(bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}
contract Address is Checked {
    Info public ContractDetails;
    struct Info {
        address Contract;
        address Owner;
        address Creator;
        uint Block;
        uint Timestamp;
        bytes32 Hash;
    }
    constructor(address _owner) public {
        ContractDetails.Contract = address(this);
        ContractDetails.Owner = _owner;
        ContractDetails.Creator = msg.sender;
        ContractDetails.Block = block.number;
        ContractDetails.Timestamp = now;
        ContractDetails.Hash = keccak256(abi.encodePacked(address(this), _owner, msg.sender, block.number, now));
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
    function receive() public payable {
        if (msg.value < 1) revert();
    }
    function transfer(address token, address payable to, uint amount) public onlyOwner {
        require(to != token && to != address(0) && address(this) != to);
        require(amount > 0);
        if (address(0) == token) {
            require(amount <= address(this).balance);
            to.transfer(amount);
        } else {
            require(isContract(token) && ERC20(token).balanceOf(address(this)) >= amount);
            if (!ERC20(token).transfer(to, amount)) revert();
        }
    }
    function call(address contractAddr, uint amount, uint gaslimit, bytes memory data) public onlyOwner {
        require(isContract(contractAddr) && amount <= address(this).balance);
        if (gaslimit < 35000) gaslimit = 35000;
        bool success;
        if (amount > 0) {
            (success,) = address(uint160(contractAddr)).call.gas(gaslimit).value(amount)(data);
        } else {
            (success,) = contractAddr.call.gas(gaslimit).value(amount)(data);
        }
        if (!success) revert();
    }
}