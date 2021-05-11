/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Cyberdeck {
    using SafeMath for uint256;

    address payable public owner;

    event LogETHDeposit(address indexed sender, uint amount);
    event LogETHWithdrawal(address indexed owner, uint amount);
    event LogETHTransfer(address indexed recipient, uint amount);
    event LogTokenTransfer(address indexed token, address indexed recipient, uint amount);

    constructor(address _owner) payable {
        owner = payable(_owner);
    }

    receive() external payable {}

    modifier onlyOwner() {
        require(owner == msg.sender, "Cyberdeck: caller is not the owner.");
        _;
    }

    function depositETH() public payable {
        require(msg.value > 0, "Cyberdeck: ETH deposit has no ETH.");
        emit LogETHDeposit(msg.sender, msg.value);
    }

    function getETHBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdrawETH(uint amount) public onlyOwner {
        require(address(this).balance >= amount, "Cyberdeck: not enough ETH for withdraw.");
        owner.transfer(amount);
        emit LogETHWithdrawal(msg.sender, amount);
    }

    function transferETH(address payable recipient, uint amount) public onlyOwner {
        require(recipient != address(0), "Cyberdeck: cannot transfer to 0x0.");
        require(address(this).balance >= amount, "Cyberdeck: not enough ETH for transfer.");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Cyberdeck: unable to send ETH, recipient may have reverted");
        emit LogETHTransfer(recipient, amount);
    }

    function transferERC20(address token, address to, uint amount) public onlyOwner {
        require(IERC20(token).balanceOf(address(this)) >= amount, "Cyberdeck: token balance insufficient");
        IERC20(token).transfer(to, amount);
        emit LogTokenTransfer(token, to, amount);
    }
}

contract CyberdeckSweatshop {
    address payable public nightcorp;
    bool public sweatshopStatus = true;

    uint256 public numberOfCyberdecks;
    Cyberdeck[] public cyberdecks;
    mapping (address => address[]) private deckowners;

    event NewCyberdeck(address indexed owner, address indexed cyberdeck);

    constructor(address _nightcorp) payable {
        nightcorp = payable(_nightcorp);
    }

    function _createCyberdeck(address caller) internal returns (address) {
        Cyberdeck deck = new Cyberdeck(caller);
        cyberdecks.push(deck);
        deckowners[caller].push(address(deck));
        numberOfCyberdecks++;

        emit NewCyberdeck(caller, address(deck));
        return address(deck);
    }

    function _createCyberdeckAndSendEther(address caller) internal returns (address) {
        Cyberdeck deck = (new Cyberdeck){value: msg.value}(caller);
        cyberdecks.push(deck);
        deckowners[caller].push(address(deck));
        numberOfCyberdecks++;

        emit NewCyberdeck(caller, address(deck));
        return address(deck);
    }

    function create(address caller) external payable returns (address) {
        require(sweatshopStatus == true, "Cyberdeck Sweatshop: this sweatshop has been retired.");
        if (msg.value > 0) {
            return _createCyberdeckAndSendEther(caller);
        } else {
            return _createCyberdeck(caller);
        }
    }

    function retire() external {
        require(msg.sender == nightcorp, "Cyberdeck Sweatshop: retire can only be called through NightCorp.");
        sweatshopStatus = false;
    }
}