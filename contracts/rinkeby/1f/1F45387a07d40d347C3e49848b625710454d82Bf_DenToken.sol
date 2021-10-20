// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Capped.sol";
import "./IWolfPack.sol";
import "./Ownable.sol";

contract DenToken is Ownable, ERC20Capped {

    // total den tokens released (that were deposited to this contract)
    uint256 private _totalReleased;

    // wolf Id => last claim timestamp
    mapping(uint => uint64) private _lastClaimTimestamp; // seconds in 24 hours: 86400

    // wolf Id => amount minted per wolf
    mapping(uint => uint32) private mintedPerWolf;

    // wolf ID => released amount
    mapping(uint => uint) private _released;
    
    // implementing the Wolf Pack genesis tokens contract:
    IWolfPack wolfPackContract;

    constructor() ERC20("Den Token", "DEN") ERC20Capped(62050000) { }

    /**
     * @dev sets the Wolf Pack contract address (genesis wolfs)
     */
    function setWolfPackContractAddress(address _contractAddress) public onlyOwner {
        wolfPackContract = IWolfPack(_contractAddress);
    }

    /**
     * @dev getter function to get the last claim timestamp for a specific wolf ID
     */
    function getLastClaimTimestampForWolf(uint wolfId) external view returns(uint64) {
        return _lastClaimTimestamp[wolfId];
    }

    function claimDen(uint wolfId) external {
        address wolfOwner = wolfPackContract.ownerOf(wolfId);
        require(wolfOwner == msg.sender, "Only the owner of the wolf can call this function");

        (uint16 amountToClaim, uint denAvalibleToRelease) = availableDenForWolf(wolfId);

        if (mintedPerWolf[wolfId] < 36500) {
            if (denAvalibleToRelease >= amountToClaim) {
                _released[wolfId] += amountToClaim;
                _totalReleased += amountToClaim;
                bool success = transferFrom(address(this), wolfOwner, amountToClaim);
                require(success, "Payment didn't go through!");
            } else {
                if (denAvalibleToRelease >= 10) {
                    // (amount to release) = (amount of 10 den avalible to release)
                    uint denAmountToRelease = (denAvalibleToRelease - (denAvalibleToRelease % 10)) * 1000000000000000000;
                    // (amount to claim) - (amount of 10 den avalible to release) = (amount to mint)
                    uint16 amountToMint = uint16(amountToClaim - denAmountToRelease);

                    _mintDen(wolfOwner, amountToMint, wolfId);
                    _released[wolfId] += denAmountToRelease;
                    _totalReleased += denAmountToRelease;
                    bool success = transferFrom(address(this), wolfOwner, denAmountToRelease);
                    require(success, "Payment didn't go through!");
                } else {
                    _mintDen(wolfOwner, amountToClaim, wolfId);
                }
            }
        } else {
            require(denAvalibleToRelease != 0, "There is nothing to release");
            _released[wolfId] += denAvalibleToRelease;
            _totalReleased += denAvalibleToRelease;
            bool success = transferFrom(address(this), wolfOwner, denAvalibleToRelease);
            require(success, "Payment didn't go through!");
        }
    }

    function availableDenForWolf(uint _wolfId) public view returns(uint16 amountToClaim, uint denAvalibleToRelease) {
        uint totalReceived = balanceOf(address(this)) + _totalReleased;
        if (mintedPerWolf[_wolfId] < 36500) {
            uint numberOfDays = (block.timestamp - _lastClaimTimestamp[_wolfId]) / (1 days); // change to minutes for testing
            amountToClaim = uint16(numberOfDays * 10);
            
            uint _denAvalibleToRelease = ((totalReceived / 1700) - _released[_wolfId]);
            denAvalibleToRelease = (_denAvalibleToRelease - (_denAvalibleToRelease % 1000000000000000000)) / 1000000000000000000;
        } else {
            denAvalibleToRelease = (totalReceived / 1700) - _released[_wolfId];
        }
    }

    function _mintDen(address _address, uint16 _amount, uint _wolfId) private {
        _mint(_address, _amount);
        mintedPerWolf[_wolfId] += _amount;
        _lastClaimTimestamp[_wolfId] = uint64(block.timestamp);
    }

}