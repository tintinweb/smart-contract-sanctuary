// SPDX-License-Identifier: MIT
pragma solidity ^0.5.17;

interface VaultLike {
    function available() external view returns (uint);
    function earn() external;
}

contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract VaultBatchEarn is Ownable {
    struct Vault {
        VaultLike vault;
        uint256 limit;
    }

    mapping (uint => Vault) public vaults;
    mapping (address => uint) public indexes;
    
    uint256 public numOfVaults;
    
    function addVault(VaultLike v, uint256 lim) public onlyOwner {
        require(lim > 0);
        v.available(); // Quick check if vault has available()
        
        uint index = indexes[address(v)];
        if (vaults[index].vault == v) {
            vaults[index].limit = lim;
        } else {
            vaults[numOfVaults] = Vault(v, lim);
            indexes[address(v)] = numOfVaults;
            numOfVaults++;
        }
    }
    
    function earn() public {
        for (uint256 i; i < numOfVaults; i++)  {
            Vault memory v = vaults[i];
            if (v.vault.available() > v.limit) {
                  v.vault.earn();
            }
        }
    }
    
    function shouldCallEarn() public view returns (bool) {
        for (uint256 i; i < numOfVaults; i++)  {
            Vault memory v = vaults[i];
            if (v.vault.available() > v.limit) {
                return true;
            }
        }
        return false;
    }
}