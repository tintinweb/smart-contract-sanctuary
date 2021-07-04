/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

pragma solidity 0.6.10;


interface ERC20Like {
    function transfer(address to, uint qty) external;
}

contract LUSDReserve {
    uint public ethToUsd;
    address public admin;
    ERC20Like public constant LUSD = ERC20Like(0x0b02b94638daa719290b5214825dA625af08A02F);
    
    constructor() public {
        admin = msg.sender;
    }
    
    function setEthToUsd(uint _ethToUsd) public {
        require(msg.sender == admin, "!admin");
        
        ethToUsd = _ethToUsd;
    }
    
    // kyber network reserve compatible function
    function trade(
        address /* srcToken */,
        uint256 /* srcAmount */,
        address /* destToken */,
        address payable destAddress,
        uint256 /* conversionRate */,
        bool /* validate */
    ) external payable returns (bool) {
        uint amount = msg.value * ethToUsd / 1e18;
        LUSD.transfer(destAddress, amount);
        
        return amount > 0;
    }

    function getConversionRate(
        address /* src */,
        address /* dest */,
        uint256 /* srcQty */,
        uint256 /* blockNumber */
    ) external view returns (uint256) {
        return ethToUsd;
    }

    receive() external payable {}    
}