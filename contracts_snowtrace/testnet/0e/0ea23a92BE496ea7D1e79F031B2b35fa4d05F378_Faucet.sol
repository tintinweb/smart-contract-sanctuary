// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

interface IMintableERC {
    function mint(address, uint256) external;
}

contract Faucet {
    struct DrinkerState {
        uint wAVAXDrinkTime;
    }

    uint256 birthTimestamp;
    uint public maxAllowedDrinkTimes;

    mapping(address => DrinkerState) public wAvaxDrinkerMapping;
    mapping(address => DrinkerState) public signAvaxLpDrinkerMapping;

    address public wAVAXAddress;
    address _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not Owner");
        _;
    }

    constructor() {
        birthTimestamp = block.timestamp;
        maxAllowedDrinkTimes = 1;
        _owner = msg.sender;
    }

    function getwAVAX() external payable returns (bool)
    {
        updateMaxAllowedDrinkTimesByTimestamp();
        require(wAvaxDrinkerMapping[msg.sender].wAVAXDrinkTime 
                < maxAllowedDrinkTimes, "SignDAOFaucet: Sorry already claimed today");

        require(wAVAXAddress != address(0), "SignDAOFaucet: No token selected");
        IMintableERC wAvax = IMintableERC(wAVAXAddress);

        wAvax.mint(msg.sender, 100000000000000000000);
        wAvaxDrinkerMapping[msg.sender].wAVAXDrinkTime += 1;

        return true;
    }

    function setWAvaxAddress(address newWAVAXAddress) external onlyOwner 
    {
        wAVAXAddress = newWAVAXAddress;
    }

    /**
     *
     */
    function canDrinkToday() public view returns (bool)
    {
        return wAvaxDrinkerMapping[msg.sender].wAVAXDrinkTime
               < maxAllowedDrinkTimes;
    }

    /**
     *
     */
    function updateMaxAllowedDrinkTimesByTimestamp() public
    {
        uint currentTimestamp = block.timestamp;
        uint newAllowedDrinkTimes = ( currentTimestamp - birthTimestamp ) / 60 / 60 / 24 + 1;

        if (newAllowedDrinkTimes <= maxAllowedDrinkTimes) {
            return;
        }

        maxAllowedDrinkTimes = newAllowedDrinkTimes;
    }
}