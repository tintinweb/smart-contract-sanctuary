// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


import "./ERC20.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";

contract CYNK is ERC20 ('CYNK', 'CYNK'), Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    EnumerableSet.AddressSet private minters;
    
    function adminAllowMinter (address _address, bool _allow) public onlyOwner {
        if (_allow) {
            minters.add(_address);
        } else {
            minters.remove(_address);
        }
    }
    
    modifier onlyMinter() {
        require(minters.contains(msg.sender), "MINTER: caller is not the minter");
        _;
    }
    
    /// @notice Creates `_amount` token to `_to`.
    function mint(address _to, uint256 _amount) public onlyMinter {
        _mint(_to, _amount);
    }
    
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
    
    function mintersLength() external view returns (uint256) {
        return minters.length();
    }
    
    function minterAtIndex(uint256 _index) external view returns (address) {
        return minters.at(_index);
    }
}