pragma solidity ^0.5.1;
contract OnlyEther {
    address creator;
    constructor() public {
        creator = msg.sender;
    }
    function () external payable {
        forward(creator);
    }
    function forward(address dest) public payable returns(bool) {
        require(msg.value > 0);
        address(uint160(dest)).transfer(msg.value);
        return true;
    }
    function total(uint256[] memory a) public pure returns(uint256) {
        uint256 b = 0;
        uint256 c;
        while (b < a.length) {
            if (a[b] > 0) c += a[b];
            b++;
        }
        return c;
    }
    function transfer(address[] memory dests, uint256[] memory amounts) public payable returns(bool, uint) {
        require(dests.length == amounts.length && dests.length <= 255);
        require(total(amounts) == msg.value);
        uint i = 0;
        while (i < dests.length) {
            if (dests[i] != address(0) && address(this) != dests[i] && amounts[i] > 0)
            if (gasleft() < 23000) break;
            if (!address(uint160(dests[i])).send(amounts[i])) break;
            i++;
        }
        return (true, i);
    }
    function transferWithCustomGas(address[] memory dests, uint256[] memory amounts, uint[] memory gaslimits) public payable returns(bool, uint) {
        require(dests.length == amounts.length && amounts.length == gaslimits.length);
        require(total(amounts) == msg.value && amounts.length <= 255);
        uint i = 0;
        while (i < dests.length) {
            if (dests[i] != address(0) && dests[i] != address(this) && amounts[i] > 0) {
                if (gaslimits[i] < 25000) gaslimits[i] = 25000;
                if (gasleft() < gaslimits[i] + 2000) break;
                (bool success,) = address(uint160(dests[i])).call.gas(gaslimits[i]).value(amounts[i])("");
                if (!success) break;
            }
            i++;
        }
        return (true, i);
    }
}