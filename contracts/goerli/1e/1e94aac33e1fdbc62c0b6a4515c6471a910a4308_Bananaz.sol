// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

interface ICoolApeClub {
    function ownerOf(uint256 tokenId) external  returns(address);
}

contract Bananaz is ERC20, Ownable {
    using SafeMath for uint256;
    
    ICoolApeClub public CoolApeClub;
    address public capeverseAddress;

    uint256 public startTime;
    uint256 public earningRate = 10 ether;

    bool public claimingLive = false;
    mapping(uint256 => uint256) public lastClaim;

    mapping(address => bool) public allowedAddresses;
    
    constructor() ERC20("Bananaz", "BNZ") {}

    /*////////////////////////////////////////////////////////////////////
    //                        ERC20 Logic                             //
    ////////////////////////////////////////////////////////////////////*/

    function burn(address user, uint256 amount) external {
        require(msg.sender == capeverseAddress || allowedAddresses[msg.sender], "Address not authorized to burn Bananaz");
        require(msg.sender == user, "You can't burn someone else's Bananaz");
        _burn(user, amount);
    }

    function mint(address to, uint256 value) external {
        require(msg.sender == capeverseAddress || allowedAddresses[msg.sender], "Address not authorized to mint Bananaz");
        _mint(to, value);
    }

    function setAllowedAddresses(address _address, bool _access) public onlyOwner {
        allowedAddresses[_address] = _access;
    }

    function setCapeverseAddress(address _capeverseAddress) external onlyOwner {
        capeverseAddress = _capeverseAddress;
    }

    function setCoolApeClubAddr(address _coolApeClubAddress) external onlyOwner {
        CoolApeClub = ICoolApeClub(_coolApeClubAddress);
    }

    /*////////////////////////////////////////////////////////////////////
    //                        Staking Logic                             //
    ////////////////////////////////////////////////////////////////////*/
    
    //Function to set staking start time for $Bananaz
    function setStakingStartTime() external onlyOwner {
        startTime = block.timestamp;
    }

    //Internal Claim function for $Bananaz
    function _claim(uint id) internal {
        require(claimingLive, "Claiming $Bananaz is currently paused");
        require(CoolApeClub.ownerOf(id) == msg.sender, "You do not own this Cool Ape");
        _mint(msg.sender, getEarnings(id));
        lastClaim[id] = block.timestamp;
    }

    //External Claim function for $Bananaz
    function claimMany(uint256[] calldata ids) external {
        for(uint256 i = 0; i < ids.length; i++){
            _claim(ids[i]);
        }
    }

    function getTotalClaimable(uint256[] calldata ids) external view returns(uint256){
        uint256 claimableBananaz = 0;
        for(uint256 i = 0; i < ids.length; i++){
            claimableBananaz += getEarnings(ids[i]);
        }
        return claimableBananaz;
    }

    function getEarnings(uint256 id) internal view returns(uint256) {
        return earningRate * (block.timestamp - (lastClaim[id] >= startTime ? lastClaim[id] : startTime))/ 1 days;
    }

    //Toggle status of claiming $Bananaz
    function toggleClaiming() public onlyOwner {
        claimingLive = !claimingLive;
    }
}