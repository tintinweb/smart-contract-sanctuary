pragma solidity 0.5.16;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

// ----------------------------------------------------------------------------------
// Escrow contract to safely store and release the token allocated to Morpher at
// protocol inception
// ----------------------------------------------------------------------------------

contract MorpherEscrow is Ownable{
    using SafeMath for uint256;

    uint256 public lastEscrowTransferTime;
    address public recipient;
    address public morpherToken;

    uint256 public constant RELEASEAMOUNT = 10**25;
    uint256 public constant RELEASEPERIOD = 30 days;

    event EscrowReleased(uint256 _released, uint256 _leftInEscrow);

    constructor(address _recipientAddress, address _morpherToken, address _coldStorageOwnerAddress) public {
        setRecipientAddress(_recipientAddress);
        setMorpherTokenAddress(_morpherToken);
        lastEscrowTransferTime = now;
        transferOwnership(_coldStorageOwnerAddress);
    }

    // ----------------------------------------------------------------------------------
    // Owner can modify recipient address and update morpherToken adddress
    // ----------------------------------------------------------------------------------
    function setRecipientAddress(address _recipientAddress) public onlyOwner {
        recipient = _recipientAddress;
    }

    function setMorpherTokenAddress(address _address) public onlyOwner {
        morpherToken = _address;
    }

    // ----------------------------------------------------------------------------------
    // Anyone can release funds from escrow if enough time has elapsed
    // Every 30 days 1% of the total initial supply or 10m token are released to Morpher
    // ----------------------------------------------------------------------------------
    function releaseFromEscrow() public {
        require(IERC20(morpherToken).balanceOf(address(this)) > 0, "No funds left in escrow.");
        uint256 _releasedAmount;
        if (now > lastEscrowTransferTime.add(RELEASEPERIOD)) {
            if (IERC20(morpherToken).balanceOf(address(this)) > RELEASEAMOUNT) {
                _releasedAmount = RELEASEAMOUNT;
            } else {
                _releasedAmount = IERC20(morpherToken).balanceOf(address(this));
            }
            IERC20(morpherToken).transfer(recipient, _releasedAmount);
            lastEscrowTransferTime = lastEscrowTransferTime.add(RELEASEPERIOD);
            emit EscrowReleased(_releasedAmount, IERC20(morpherToken).balanceOf(address(this)));
        }
    }
}