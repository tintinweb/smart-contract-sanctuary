// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import "./libraries/TransferHelper.sol";
import "./modules/Ownable.sol";
import "./interfaces/IERC20.sol";

contract TomiFunding is Ownable {
    address public tomi;

    mapping(address => bool) included;
    
    event ClaimableGranted(address _userAddress);
    event ClaimableRevoked(address _userAddress);
    event Claimed(address _userAddress, uint256 _amount);
    event FundingTokenSettled(address tokenAddress);
    
    constructor(address _tomi) public {
        tomi = _tomi;
    }
    
    modifier inClaimable(address _userAddress) {
        require(included[_userAddress], "TomiFunding::User not in claimable list!");
        _;
    }

    modifier notInClaimable(address _userAddress) {
        require(!included[_userAddress], "TomiFunding::User already in claimable list!");
        _;
    }
    
    function setTomi(address _tomi) public onlyOwner {
        tomi = _tomi;
        emit FundingTokenSettled(_tomi);
    }
    
    function grantClaimable(address _userAddress) public onlyOwner notInClaimable(_userAddress) {
        require(_userAddress != address(0), "TomiFunding::User address is not legit!");
        
        included[_userAddress] = true;
        emit ClaimableGranted(_userAddress);
    }
    
    function revokeClaimable(address _userAddress) public onlyOwner inClaimable(_userAddress) {
        require(_userAddress != address(0), "TomiFunding::User address is not legit!");
        
        included[_userAddress] = false;
        emit ClaimableRevoked(_userAddress);
    }
    
    function claim(uint256 _amount) public inClaimable(msg.sender) {
        uint256 remainBalance = IERC20(tomi).balanceOf(address(this));
        require(remainBalance >= _amount, "TomiFunding::Remain balance is not enough to claim!");
        
        TransferHelper.safeTransfer(address(tomi), msg.sender, _amount); 
        emit Claimed(msg.sender, _amount);
    }
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

pragma solidity >=0.5.16;

contract Ownable {
    address public owner;

    event OwnerChanged(address indexed _oldOwner, address indexed _newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Ownable: FORBIDDEN');
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), 'Ownable: INVALID_ADDRESS');
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }

}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}