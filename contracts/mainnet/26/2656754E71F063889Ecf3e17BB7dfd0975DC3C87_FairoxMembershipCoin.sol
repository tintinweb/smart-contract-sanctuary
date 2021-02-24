// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "./ERC20Capped.sol";
import './SafeMath.sol';

contract FairoxMembershipCoin is ERC20Capped {

    using SafeMath for uint256;

    uint256 public last_extracted;
    uint256 extractions = 0;
    address proposedOwner = address(0);
    address private _owner;

    constructor ()
    ERC20("Fairox Membership Coin", "FOMC")
    ERC20Capped(25000000 * 1 ether)
    {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
        // Set last_extracted to current block and initialize extaction until next year.
        last_extracted = block.timestamp;
        // Mint 80% of total supply for manual distribution/burn
        _mint(msg.sender, (20000000 * 1 ether));
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Burned(address indexed burner, uint256 amount);
    event Minted(address indexed rewarded, uint256 amount);
    event Extracted(address indexed rewarded, uint256 amount);

    // Burn function is a wrapper around the internal _burn function to remove owned coins.
    function burn(uint256 _amount) public returns (bool) {
        require(_amount > 0, "FOMCERC20: Cannot burn 0 tokens");
        _burn(msg.sender, _amount);
        emit Burned(msg.sender, _amount);
        return true;
    } 

    // Extract function will mint 2% of the total supply for the contract owner.
    // This function can only be accesed every year since the first extract.
    function extract() public onlyOwner {
        require(extractions < 10, "FOMCERC20: There has been already 10 extractions for the supply");
        require(getNextExtractionAvailable() < block.timestamp, "FOMCERC20: Unable to extract on this period");
        uint256 amount = 500000 * 1 ether;
        _mint(msg.sender, amount);
        emit Minted(msg.sender, amount);
        last_extracted = last_extracted.add(365 days);
        extractions = extractions.add(1);
        emit Extracted(msg.sender, amount);
    }

    function getNextExtractionAvailable() public view returns (uint256) {
        return last_extracted.add(365 days);
    }

    function proposeOwner(address _proposedOwner) public onlyOwner {
        require(msg.sender != _proposedOwner, "ERROR_CALLER_ALREADY_OWNER");
        proposedOwner = _proposedOwner;
    }

    function claimOwnership() public {
    require(msg.sender == proposedOwner, "ERROR_NOT_PROPOSED_OWNER");
        emit OwnershipTransferred(_owner, proposedOwner);
        _owner = proposedOwner;
        proposedOwner = address(0);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

}