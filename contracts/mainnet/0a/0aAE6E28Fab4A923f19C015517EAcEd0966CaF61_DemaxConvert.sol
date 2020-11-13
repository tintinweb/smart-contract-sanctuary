// Dependency file: contracts/libraries/TransferHelper.sol

// SPDX-License-Identifier: GPL-3.0-or-later

// pragma solidity >=0.6.0;

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


// Root file: contracts/DemaxConvert.sol

pragma solidity >=0.5.16;

// import 'contracts/libraries/TransferHelper.sol';

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
}

contract DemaxConvert {
    event ConvertETHForBNB(address indexed user, uint amount);
    event ConvertTokenForBNB(address indexed user, address token, uint amount);
    event CollectETH(uint amount);
    event CollectToken(address token, uint amount);
    
    address public owner;
    address public wallet;
    
    address[] public allTokens;
    
    mapping (address => bool) public users;
    
    mapping (address => uint) public tokenLimits;
    
    constructor (address _wallet) public {
        owner = msg.sender;
        wallet = _wallet;
    }
    
    function changeWallet(address _wallet) external {
        require(msg.sender == owner, "FORBIDDEN");
        wallet = _wallet;
    }
    
    function enableToken(address _token, uint _limit) external{
        require(msg.sender == owner, "FORBIDDEN");    
        tokenLimits[_token] = _limit;
        
        bool isAdd = false;
        for(uint i = 0;i < allTokens.length;i++) {
            if(allTokens[i] == _token) {
                isAdd = true;
                break;
            }
        }
        
        if(!isAdd) {
            allTokens.push(_token);
        }
    }
    
    function validTokens() external view returns (address[] memory) {
        uint count;
        for (uint i; i < allTokens.length; i++) {
            if (tokenLimits[allTokens[i]] > 0) {
                count++;
            }
        }
        address[] memory res = new address[](count);
        uint index = 0;
        for (uint i; i < allTokens.length; i++) {
            if (tokenLimits[allTokens[i]] > 0) {
                res[index] = allTokens[i];
                index++;
            }
        }
        return res;
    }
    
    function convertETHForBNB() payable external {
        require(msg.value > 0 && msg.value <= tokenLimits[address(0)], "INVALID_AMOUNT");
        require(users[msg.sender] == false, "ALREADY_CONVERT");
        users[msg.sender] = true;
        emit ConvertETHForBNB(msg.sender, msg.value);
    }
    
    function convertTokenForBNB(address _token, uint _amount) external {
        require(_amount > 0 && _amount <= tokenLimits[_token], "INVALID_AMOUNT");
        require(users[msg.sender] == false, "ALREADY_CONVERT");
        users[msg.sender] = true;
        TransferHelper.safeTransferFrom(_token, msg.sender, address(this), _amount);
        emit ConvertTokenForBNB(msg.sender, _token, _amount);
    }
    
    function collect() external {
        require(msg.sender == owner, "FORBIDDEN");
        for(uint i = 0;i < allTokens.length;i++) {
            uint balance = IERC20(allTokens[i]).balanceOf(address(this));
            if(balance > 0) {
                TransferHelper.safeTransfer(allTokens[i], wallet, balance);
                emit CollectToken(allTokens[i], balance);
            }
        }
        
        if(address(this).balance > 0) {
            emit CollectETH(address(this).balance);
            TransferHelper.safeTransferETH(wallet, address(this).balance);
        }
    }
}