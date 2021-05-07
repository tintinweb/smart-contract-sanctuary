pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Roles.sol";

contract MToken is ERC20, ERC20Detailed, Ownable {
    using Roles for Roles.Role;

    Roles.Role private _minters;
    using SafeMath for uint256;

    address[] minters_;
    uint256 maxSupply_;

    constructor(
     	address[] memory minters,
        uint256 maxSupply
    )
       ERC20Detailed("Metis Token", "Metis", 18)
       public
    {
        for (uint256 i = 0; i < minters.length; ++i) {
	    _minters.add(minters[i]);
        }
        minters_ = minters;
        maxSupply_ = maxSupply;
    }

    function mint(address target, uint256 amount) external {
        require(_minters.has(msg.sender), "ONLY_MINTER_ALLOWED_TO_DO_THIS");
        require(SafeMath.add(totalSupply(), amount) <= maxSupply_, "EXCEEDING_MAX_SUPPLY");
        _mint(target, amount);
    }

    function burn(address target, uint256 amount) external {
        require(_minters.has(msg.sender), "ONLY_MINTER_ALLOWED_TO_DO_THIS");
        _burn(target, amount);
    }
    function addMinter(address minter) external onlyOwner {
        require(!_minters.has(minter), "HAVE_MINTER_ROLE_ALREADY");
        _minters.add(minter);
        minters_.push(minter);
    }


    function removeMinter(address minter) external onlyOwner {
        require(_minters.has(msg.sender), "HAVE_MINTER_ROLE_ALREADY");
        _minters.remove(minter);
        uint256 i;
        for (i = 0; i < minters_.length; ++i) {
            if (minters_[i] == minter) {
                minters_[i] = address(0);
                break;
            }
        }
    }
}