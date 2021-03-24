// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract ERC20ForAssetGrouping is Ownable, ERC20 {

    //using Address for address; 

    bool private _minted = false;
    address public assetGouping;

    uint256 public chainId;
    
    constructor(uint256 _chainId, string memory name, string memory symbol) ERC20(name, symbol) {
        require(_chainId > 0, "Chain ID cannot be 0");
        chainId = _chainId;
    }

    /**
     * @dev Throws .
     */
    modifier canMint() {
        require(!_minted, "Cant mint more tokens");
        require(assetGouping != address(0), "Asset grouping address not yet set");
        _;
    }

    /**
     * @dev Asset grouping contract address from the private chain.
     */
    function setAssetGrouping(address _assetGrouping) public onlyOwner {
        require(_assetGrouping != address(0), "Asset grouping address already set");
        assetGouping = _assetGrouping;
    }

    function mint(address account, uint256 amount) public onlyOwner canMint {
        _minted = false;
        _mint(account, amount);
    }
}