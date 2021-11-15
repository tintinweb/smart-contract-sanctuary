// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./IERC20Mintable.sol";
import "./IERC20Burnable.sol";
import "./FullMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract Presale is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public aOTWO;
    address public wsOHM;
    address public USDT;
    address public addressToSendwsOHM;

    uint256 public endOfSale;
    uint256 public saleStartTimestamp;

    uint256 public purchasewsOHMAmount; // This is be 0.015 wsOHM
    uint256 public purchaseUSDTAmount; // This is 550 USDT
    uint256 public allocatedaOTWOPerUser; //  This is hardcoded to be 1 aOTWO

    mapping(address => bool) public boughtOTWO;
    mapping(address => bool) public whiteListed;

    function whiteListBuyers(address[] memory _buyers)
        external
        onlyOwner()
        returns (bool)
    {
        for (uint256 i; i < _buyers.length; i++) {
            whiteListed[_buyers[i]] = true;
        }

        return true;
    }

    function initialize(
        address _addressToSendwsOHM,
        address _wsOHM,
        address _aOTWO,
        address _USDT,
        uint256 _saleLength,
        uint256 _purchasewsOHMAmount,
        uint256 _purchaseUSDTAmount,
        uint256 _allocatedaOTWOPerUser,
        uint256 _saleStartTimestamp
    ) external onlyOwner() returns (bool) {
        require(saleStarted() == false, "Already initialized");

        aOTWO = _aOTWO;
        wsOHM = _wsOHM;
        USDT = _USDT;

        endOfSale = _saleLength.add(_saleStartTimestamp);

        saleStartTimestamp = _saleStartTimestamp;

        purchasewsOHMAmount = _purchasewsOHMAmount;
        purchaseUSDTAmount = _purchaseUSDTAmount;

        addressToSendwsOHM = _addressToSendwsOHM;

        allocatedaOTWOPerUser = _allocatedaOTWOPerUser;

        return true;
    }

    function saleStarted() public view returns (bool){
        if (saleStartTimestamp != 0){
            return block.timestamp > saleStartTimestamp;
        } else{
            return false;
        }
    }

    function purchaseaOTWOWithwsOHM() external returns (bool) {
        require(saleStarted() == true, "Not started");
        require(whiteListed[msg.sender] == true, "Not whitelisted");
        require(boughtOTWO[msg.sender] == false, "Already participated");
        require(block.timestamp < endOfSale, "Sale over");

        boughtOTWO[msg.sender] = true;

        IERC20(wsOHM).safeTransferFrom(msg.sender, addressToSendwsOHM, purchasewsOHMAmount);
        IERC20(aOTWO).safeTransfer(msg.sender, allocatedaOTWOPerUser);

        return true;
    }

    function purchaseaOTWOWithUSDT() external returns (bool) {
        require(saleStarted() == true, "Not started");
        require(whiteListed[msg.sender] == true, "Not whitelisted");
        require(boughtOTWO[msg.sender] == false, "Already participated");
        require(block.timestamp < endOfSale, "Sale over");

        boughtOTWO[msg.sender] = true;

        IERC20(USDT).safeTransferFrom(msg.sender, addressToSendwsOHM, purchaseUSDTAmount);
        IERC20(aOTWO).safeTransfer(msg.sender, allocatedaOTWOPerUser);

        return true;
    }

    /**
     *  @notice Burn the remaining aOTWO 
     *  @return true if it works
    */
    function burnRemainingaOTWO()
        external
        onlyOwner()
        returns (bool)
    {
        require(saleStarted() == true, "Not started");
        require(block.timestamp >= endOfSale, "Not ended");

        IERC20Burnable(aOTWO).burn(IERC20(aOTWO).balanceOf(address(this)));

        return true;
    }


}