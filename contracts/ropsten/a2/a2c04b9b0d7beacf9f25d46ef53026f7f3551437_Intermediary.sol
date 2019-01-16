pragma solidity ^0.5.1;
contract ERC20 {
    function allowance(address owner, address spender) public view returns(uint256);
    function transferFrom(address from, address to, uint256 value) public returns(bool);
}
contract Intermediary {
    constructor() public {}
    function total(uint256[] memory a) internal pure returns(uint256) {
        uint256 b = 0;
        uint256 c;
        while (b < a.length) {
            if (a[b] > 0) c += a[b];
            b++;
        }
        return c;
    }
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    function send(address to, uint256 amount) internal returns(bool) {
        if (to != address(0) && address(this) != to && to != msg.sender) {
            (bool success,) = address(uint160(to)).call.gas(100000).value(amount)("");
            if (!success) address(uint160(to)).transfer(amount);
            return true;
        } else {
            return false;
        }
    }
    function batchSend(address[] memory dests, uint256[] memory amounts) public payable returns(bool, uint) {
        require(dests.length == amounts.length && dests.length <= 255);
        uint256 totalAmount = total(amounts);
        uint256 restAmount = msg.value;
        uint i;
        require(totalAmount > 0 && totalAmount <= msg.value);
        while (i < dests.length) {
            if (amounts[i] > 0) {
                if (!send(dests[i], amounts[i])) break;
                restAmount -= amounts[i];
            }
            i++;
        }
        if (restAmount > 0) msg.sender.transfer(restAmount);
        return (true, i);
    }
    function batchTransfer(address token, address[] memory dests, uint256[] memory amounts) public returns(bool, uint) {
        require(isContract(token));
        require(dests.length == amounts.length && dests.length <= 255);
        uint256 remaining = ERC20(token).allowance(msg.sender, address(this));
        uint256 totalAmount = total(amounts);
        uint i = 0;
        require(remaining > 0 && totalAmount <= remaining);
        while (i < dests.length) {
            if (dests[i] != address(0) && dests[i] != address(this) && amounts[i] > 0 && dests[i] != msg.sender)
            if (!ERC20(token).transferFrom(msg.sender, dests[i], amounts[i])) break;
            i++;
        }
        return (true, i);
    }
}