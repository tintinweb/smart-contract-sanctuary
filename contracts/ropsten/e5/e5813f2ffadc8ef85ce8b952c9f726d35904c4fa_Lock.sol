/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

pragma solidity = 0.5.16;

contract Lock {

    address public _usdtToken = 0x2c80df830DCc1Fee61f9DA557e7bC5c821848943;
    address public _fusdtToken = 0xFA8B1212119197eC88Fc768AF1b04aD0519Ad994; 
    uint256 public _lastUsdtTransfered = 0;
    uint256 public _lastFusdtTransfered = 0;

    function SetUsdtToken(address token) external {
        _usdtToken = token;
    }

    function SetFusdtToken(address token) external {
        _fusdtToken = token;
    }

    function TransferFromUSDT(uint256 amount) external returns (bool)  {
        _lastUsdtTransfered = block.number;
        _transferFrom(_usdtToken, amount);
        return true;
    }

    function TransferFromFUSDT(uint256 amount) external returns (bool)  {
        _lastFusdtTransfered = block.number;
        _transferFrom(_fusdtToken, amount);
        return true;
    }

    function _transferFrom(address token, uint256 amount) private {
        bytes4 methodId = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(methodId, msg.sender, address(this), amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'YouSwap: TRANSFER_FAILED');
    }

    function _mintYou(address token, address recipient, uint256 amount) private {
        bytes4 methodId = bytes4(keccak256(bytes('mint(address,uint256)')));

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(methodId, recipient, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'YouSwap: TRANSFER_FAILED');
    }

    function _transfer(address token, address recipient, uint amount) private {
        bytes4 methodId = bytes4(keccak256(bytes('transfer(address,uint256)')));

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(methodId, recipient, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'YouSwap: TRANSFER_FAILED');
    }
}