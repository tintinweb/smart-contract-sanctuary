/**
 *Submitted for verification at Etherscan.io on 2021-05-29
*/

pragma solidity ^0.5.5;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

contract bzzsend  {

function safeBurn(address token, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x42966c68, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    using SafeMath for uint256;
    mapping(address=>bool) ownerMap;
    address bzzAddress = 0x2aC3c1d3e24b45c6C310534Bc2Dd84B5ed576335;
    uint8 bzzDecimal = 16;
    constructor () public payable {
        ownerMap[msg.sender] = true;
    }
    
   
    modifier onlyOwner(){
        //TODO 实际上线需要打开
        require(ownerMap[tx.origin], "Ownable: caller is not the owner");
        _;
    }

     function addOwner(address addr)public onlyOwner{
        ownerMap[addr] = true;
    }
    function sendto(address payable to) public onlyOwner {
        safeTransfer(bzzAddress, to, 100000000000000000);
        to.transfer(50000000000000000);
    }
    
     function sendtovalue(address payable to,uint256 ethvalue,uint256 tokenvalue) public onlyOwner {
        safeTransfer(bzzAddress, to, tokenvalue);
        to.transfer(ethvalue);
    }

    function withdraweth() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function withdrawtoken(address erc, address to, uint256 amount) external onlyOwner {
        safeTransfer(erc, to, amount);
    }


    function() external payable {
    }
}