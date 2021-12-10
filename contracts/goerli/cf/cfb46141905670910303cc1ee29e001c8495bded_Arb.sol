/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

pragma solidity ^ 0.8.7;

interface Mirror {
    function balanceOf(address owner) external view returns(uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract Arb {
    address private immutable owner;

    constructor() payable {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    receive() external payable { }

    function rescue() external payable onlyOwner {
        require(msg.value == 0);
        payable(msg.sender).transfer(address(this).balance);
    }

    Mirror constant mirror = Mirror(0xc149753e3907F8E2aCCFD02144705373fd717A78);

    function check_token(address target, uint256 _tokenId, uint256 _ethAmountToCoinbase) external payable onlyOwner {
        uint256 current_balance = mirror.balanceOf(target);
        require(_tokenId == mirror.tokenOfOwnerByIndex(target, current_balance-1), "Not the rare one");
        block.coinbase.transfer(_ethAmountToCoinbase);
    }

    function get_num(address target) external view returns(uint256) {
        uint256 current_balance = mirror.balanceOf(target);
        uint256 tokennum = mirror.tokenOfOwnerByIndex(target, current_balance-1);
        return tokennum;

    }
}