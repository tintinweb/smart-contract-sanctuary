// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;
import "ERC20.sol";
import "Ownable.sol";
import "EnumerableSet.sol";
// import "./Mintable.sol";
contract AGT is ERC20, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _minters;

  constructor(
        uint256 initialSupply
  ) ERC20("Ankots Game Token", "AGT") {
    _mint(msg.sender, initialSupply);
  }
    //Imm X
    // function _mintFor(
    //     address _to,
    //     uint256 _amount,
    //     bytes memory
    // ) internal override {
    //     _mint(_to, _amount);
    // }
   function mint(address _to, uint256 _amount) public onlyMinter returns (bool) {
        _mint(_to, _amount);
        return true;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
    
    function addMinter(address _addMinter) public onlyOwner returns (bool) {
        require(_addMinter != address(0), "FragmentToken: _addMinter is the zero address");
        return EnumerableSet.add(_minters, _addMinter);
    }

    function delMinter(address _delMinter) public onlyOwner returns (bool) {
        require(_delMinter != address(0), "FragmentToken: _delMinter is the zero address");
        return EnumerableSet.remove(_minters, _delMinter);
    }

    function getMinterLength() public view returns (uint256) {
        return EnumerableSet.length(_minters);
    }

    function isMinter(address account) public view returns (bool) {
        return EnumerableSet.contains(_minters, account);
    }

    function getMinter(uint256 _index) public view onlyOwner returns (address) {
        require(_index <= getMinterLength() - 1, "FragmentToken: index out of bounds");
        return EnumerableSet.at(_minters, _index);
    }

    // modifier for mint function
    modifier onlyMinter() {
        require(isMinter(msg.sender), "FragmentToken: caller is not the minter");
        _;
    }
}