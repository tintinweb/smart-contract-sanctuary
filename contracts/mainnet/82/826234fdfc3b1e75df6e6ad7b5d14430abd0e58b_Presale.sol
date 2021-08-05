// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Ownable.sol";
import "./IERC20.sol";
import "./TransferHelper.sol";
import "./SafeMath.sol";

contract Presale is Ownable {
    using SafeMath for uint256;
    
    IERC20 public saleToken;

    bool public presaleHasEnded = false;
    bool public presaleHasStarted = false;
    
    uint256 ETH_RATE;
    uint256 TOKEN_RATE;
    uint256 HARDCAP;
    uint256 TOTAL_ETH_RAISED = 0;

    address payable devAddress;
    
    mapping(address => uint256) public participants;

    constructor (IERC20 _saleToken, uint256 _ethRate, uint256 _tokenRate, uint256 _hardcap, address payable _devAddress) public {
        saleToken = _saleToken;
        ETH_RATE = _ethRate;
        TOKEN_RATE = _tokenRate;
        HARDCAP = _hardcap;
        devAddress = _devAddress;
    }
    
    function endPresale () public onlyOwner {
        presaleHasEnded = true;
    }

    function startPresale () public onlyOwner {
        presaleHasStarted = true;
    }
    
    function purchase () public payable {
        require(!presaleHasEnded, 'PRESALE OVER');
        require(presaleHasStarted, 'PRESALE HAS NOT STARTED');
        require(msg.value > 0, 'NO ETH');
        uint256 ETH_IN = msg.value;
        if (TOTAL_ETH_RAISED.add(msg.value) > HARDCAP) {
            require(TOTAL_ETH_RAISED != HARDCAP, 'HARDCAP REACHED');
            ETH_IN = HARDCAP.sub(TOTAL_ETH_RAISED);
            msg.sender.transfer(msg.value.sub(ETH_IN)); //refund the difference
        }
        uint256 amountPurchased = ETH_IN.mul(TOKEN_RATE).div(ETH_RATE);
        uint256 participantBalance = participants[msg.sender];
        participants[msg.sender] = participantBalance.add(amountPurchased);
        TOTAL_ETH_RAISED = TOTAL_ETH_RAISED.add(ETH_IN);

        devAddress.transfer(ETH_IN);
    }
    
    function withdraw () public {
        require(presaleHasEnded, 'PRESALE NOT COMPLETED');
        uint256 participantBalance = participants[msg.sender];
        require(participantBalance > 0, 'ZERO BALANCE');
        participants[msg.sender] = 0;
        TransferHelper.safeTransfer(address(saleToken), msg.sender, participantBalance);
    }
    
    function getPresaleInfo () public view returns (uint256, uint256, uint256, uint256) {
        return (ETH_RATE, TOKEN_RATE, HARDCAP, TOTAL_ETH_RAISED);
    }
}