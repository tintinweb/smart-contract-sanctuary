// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.9;

import "./interface/IDC2CDonate.sol";
import "./abstract/Ownable.sol";
contract DC2CDonate is IDC2CDonate, Ownable{

    mapping(address =>  uint256) public totalDonateBalance;
    mapping(address => mapping(address => uint256)) public accountDonateBalance;
    uint public endHeight;

    function donateBalanceOf(address token, address account) external override view returns (uint256) {
        return accountDonateBalance[token][account];
    }

    function donate(address token, uint256 amount) external override returns (bool) {
        require(_balanceOf(token, msg.sender) >= amount, "DC2CDonate: BALANCE_NO_ENOUGH");
        _safeTransferFrom(token, msg.sender, address(this), amount);
        if((endHeight == 0) || (block.number < endHeight)){
            accountDonateBalance[token][msg.sender] += amount;
            totalDonateBalance[token] += amount;
        }

        emit Donate(token, amount);
        return true;
    }

    function updateHeight(uint256 height) external override onlyGovernor returns (bool) {
        endHeight = height;
        return true;
    }

    function withdraw(address token) external override onlyOwner returns (bool) {
        uint256 balance = _balanceOf(token, address(this));
        require(balance > 0, "DC2CDonate: BALANCE_NO_ENOUGH");
        _safeTransfer(token, owner, balance);
        return true;
    }

    function _safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), ' DC2CPool: TRANSFER_FAILED');
    }

    function _safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), ' DC2CPool: TRANSFER_FROM_FAILED');
    }


    function _balanceOf(address token, address account) internal view returns (uint256) {
        // bytes4(keccak256(bytes('balanceOf(address)')));
        (bool success, bytes memory data) =
        token.staticcall(abi.encodeWithSelector(0x70a08231,account));
        require(success && data.length >= 32, " DToken: BALANCE_INVALID");
        return abi.decode(data, (uint256));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.9;

interface IDC2CDonate {
    event Donate(address token, uint256 amount);

    function donateBalanceOf(address token, address account) external view returns (uint256);
    function donate(address token, uint256 amount) external returns (bool);
    function withdraw(address token) external returns (bool);
    function updateHeight(uint256 height) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

abstract contract Ownable {
    address public owner;
    address public governor;//reserve authority management for contract governance

    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event GovernorChanged(address indexed oldOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;     // default sender
        governor = owner; //default owner
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    modifier onlyGovernor{
        require(governor == msg.sender, "Ownable: caller is not the governor");
        _;
    }

    //update owner
    function setOwner(address _owner) external virtual onlyOwner{
        require(_owner != address(0), "Ownable: new owner is the zero address");
        address oldOwner = _owner;
        owner = _owner;
        emit OwnerChanged(oldOwner, _owner);
    }

    //update governor
    function setGovernor(address _governor) external virtual onlyOwner{
        require(_governor != address(0), "Ownable: new governor is the zero address");
        address oldGovernor = _governor;
        governor = _governor;
        emit OwnerChanged(oldGovernor, _governor);
    }
}