/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

pragma solidity >=0.5.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}


interface IGateway {
    function mint(bytes32 _pHash, uint256 _amount, bytes32 _nHash, bytes calldata _sig) external returns (uint256);
    function burn(bytes calldata _to, uint256 _amount) external returns (uint256);
}

interface IGatewayRegistry {
    function getGatewayBySymbol(string calldata _tokenSymbol) external view returns (IGateway);
    function getTokenBySymbol(string calldata _tokenSymbol) external view returns (IERC20);
}

contract Basic {
    IGatewayRegistry public registry;

    event Deposit(uint256 _amount, address _address, uint256 _amountIn, uint256 _amountOut, address[] _path);
    event Withdrawal(bytes _to, uint256 _amount, bytes _msg);

    constructor(IGatewayRegistry _registry) public {
        registry = _registry;
    }

    function deposit(
        // Parameters from users
        address _address,
        uint256          _amountOfDeposit,
        uint256          _amountIn,
        uint256          _amountOut,
        address[] calldata _path,
        // Parameters from RenVM
        uint256        _amount,
        bytes32        _nHash,
        bytes calldata _sig
    ) external {
        bytes32 pHash = keccak256(abi.encode(_address, _amountOfDeposit));
        uint256 mintedAmount = registry.getGatewayBySymbol("BTC").mint(pHash, _amount, _nHash, _sig);
        emit Deposit(mintedAmount, _address, _amountIn, _amountOut, _path);
    }

    function withdraw(bytes calldata _msg, bytes calldata _to, uint256 _amount) external {
        uint256 burnedAmount = registry.getGatewayBySymbol("BTC").burn(_to, _amount);
        emit Withdrawal(_to, burnedAmount, _msg);
    }

    function balance() public view returns (uint256) {
        return registry.getTokenBySymbol("BTC").balanceOf(address(this));
    }
}