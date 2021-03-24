// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

import "./Ownable.sol";
import "./ERC20ForAssetGrouping.sol";


contract ERC20FactoryV1_0 is Ownable {

    event NewERC20(address indexed tokenAddress, address indexed owner);

    address[] public tokens;

    //upgradability
    bool internal _initialized;

    function initialize(address _owner) public {
        require(!_initialized, "contract already initialized");
        require(_owner != address(0), "Owner address cannot be 0");
        setOwner(_owner);
        _initialized = true;
    }

    function deploy(uint256 _chainId, string memory _name, string memory _symbol) virtual public onlyOwner {
        ERC20ForAssetGrouping uToken = new ERC20ForAssetGrouping(_chainId, _name, _symbol);
        uToken.transferOwnership(msg.sender);
        tokens.push(address(uToken));
        emit NewERC20(address(uToken), msg.sender);
    }

    function getTokens() virtual public view returns(address[] memory) {
        return tokens;
    }
}