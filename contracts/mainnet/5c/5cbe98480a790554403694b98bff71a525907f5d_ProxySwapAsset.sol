/**
 *Submitted for verification at Etherscan.io on 2021-02-09
*/

pragma solidity >=0.5.0;

library Helper {
    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Helper::safeTransfer: failed');
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Helper::safeTransferFrom: failed');
    }
}

contract ProxySwapAsset {
    event LogChangeMPCOwner(address indexed oldOwner, address indexed newOwner, uint indexed effectiveTime);
    event LogChangeLpProvider(address indexed oldProvider, address indexed newProvider);
    event LogSwapin(bytes32 indexed txhash, address indexed account, uint amount);
    event LogSwapout(address indexed account, address indexed bindaddr, uint amount);

    address private _oldOwner;
    address private _newOwner;
    uint256 private _newOwnerEffectiveTime;
    uint256 constant public effectiveInterval = 2 * 24 * 3600;

    address public proxyToken;
    address public lpProvider;

    modifier onlyOwner() {
        require(msg.sender == owner(), "only owner");
        _;
    }

    modifier onlyProvider() {
        require(msg.sender == lpProvider, "only lp provider");
        _;
    }

    constructor(address _proxyToken, address _lpProvider) public {
        proxyToken = _proxyToken;
        lpProvider = _lpProvider;
        _newOwner = msg.sender;
        _newOwnerEffectiveTime = block.timestamp;
    }

    function owner() public view returns (address) {
        return block.timestamp >= _newOwnerEffectiveTime ? _newOwner : _oldOwner;
    }

    function changeMPCOwner(address newOwner) public onlyOwner returns (bool) {
        require(newOwner != address(0), "new owner is the zero address");
        _oldOwner = owner();
        _newOwner = newOwner;
        _newOwnerEffectiveTime = block.timestamp + effectiveInterval;
        emit LogChangeMPCOwner(_oldOwner, _newOwner, _newOwnerEffectiveTime);
        return true;
    }

    function changeLpProvider(address newProvider) public onlyProvider returns (bool) {
        require(newProvider != address(0), "new provider is the zero address");
        emit LogChangeLpProvider(lpProvider, newProvider);
        lpProvider = newProvider;
    }

    function withdraw(address to, uint256 amount) public onlyProvider {
        Helper.safeTransfer(proxyToken, to, amount);
    }

    function Swapin(bytes32 txhash, address account, uint256 amount) public onlyOwner returns (bool) {
        Helper.safeTransfer(proxyToken, account, amount);
        emit LogSwapin(txhash, account, amount);
        return true;
    }

    // keep same interface with 'amount' parameter though it's unnecessary here
    function Swapout(uint256 amount, address bindaddr) public returns (bool) {
        require(bindaddr != address(0), "bind address is the zero address");
        Helper.safeTransferFrom(proxyToken, msg.sender, address(this), amount);
        emit LogSwapout(msg.sender, bindaddr, amount);
        return true;
    }
}