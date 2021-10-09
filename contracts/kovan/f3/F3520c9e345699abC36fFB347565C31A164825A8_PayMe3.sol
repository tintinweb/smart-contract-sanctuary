/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;


interface Manager2 {
    function _bytesToAddress(bytes memory bys) external pure returns (address addr);
}

interface MyIERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface IGateway {
    function mint(bytes32 _pHash, uint256 _amount, bytes32 _nHash, bytes calldata _sig) external returns (uint256);
    function burn(bytes calldata _to, uint256 _amount) external returns (uint256);
}

interface IGatewayRegistry {
    function getGatewayBySymbol(string calldata _tokenSymbol) external view returns (IGateway);
    function getTokenBySymbol(string calldata _tokenSymbol) external view returns (MyIERC20);
}

contract PayMe3 {

    IGatewayRegistry registry;
    Manager2 manager; 
    MyIERC20 renBTC = MyIERC20(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D); 

    constructor(address _registry, address _manager) {
        registry = IGatewayRegistry(_registry);
        manager = Manager2(_manager);
    }

    function deposit(
        bytes calldata _user, 
        bytes calldata _userToken,
        uint _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) external {
        bytes32 pHash = keccak256(abi.encode(_user, _userToken));
        IGateway BTCGateway = registry.getGatewayBySymbol('BTC');
        BTCGateway.mint(pHash, _amount, _nHash, _sig);

        address user = manager._bytesToAddress(_user);
        address userToken = manager._bytesToAddress(_userToken);

        transferToManager(address(manager), user, userToken);
    }

    receive() external payable {} 

    function transferToManager(
        address _manager, 
        address _user, 
        address _userToken
    ) public {
        uint amount = renBTC.balanceOf(address(this));
        renBTC.transfer(_manager, amount);
        (bool success, ) = _manager.call(
            abi.encodeWithSignature(
                'exchangeToUserToken(uint256,address,address)',
                amount, _user, _userToken
            )
        );
        require(success, 'Transfer of renBTC to Manager failed');
    }
}