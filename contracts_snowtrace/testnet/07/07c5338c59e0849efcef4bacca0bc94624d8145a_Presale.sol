// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;

import "./IERC20Mintable.sol";
import "./IERC20Burnable.sol";
import "./FullMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract Presale is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public aSBR;
    address public MIM;
    address public addressToSendMIM;

    uint256 public endOfSale;
    uint256 public saleStartTimestamp;

    uint256 public purchaseMIMAmount; // This is 30 MIM
    uint256 public allocatedaSBRPerUser; //  This is hardcoded to be 100 aSBR

    mapping(address => bool) public boughtSBR;
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
        address _addressToSendMIM,
        address _aSBR,
        address _MIM,
        uint256 _saleLength,
        uint256 _purchaseMIMAmount,
        uint256 _allocatedaSBRPerUser,
        uint256 _saleStartTimestamp
    ) external onlyOwner() returns (bool) {
        require(saleStarted() == false, "Already initialized");

        aSBR = _aSBR;
        MIM = _MIM;

        endOfSale = _saleLength.add(_saleStartTimestamp);

        saleStartTimestamp = _saleStartTimestamp;

        purchaseMIMAmount = _purchaseMIMAmount;

        addressToSendMIM = _addressToSendMIM;

        allocatedaSBRPerUser = _allocatedaSBRPerUser;

        return true;
    }

    function saleStarted() public view returns (bool){
        if (saleStartTimestamp != 0){
            return block.timestamp > saleStartTimestamp;
        } else{
            return false;
        }
    }

    function purchaseaSBRWithMIM() external returns (bool) {
        require(saleStarted() == true, "Not started");
        require(whiteListed[msg.sender] == true, "Not whitelisted");
        require(boughtSBR[msg.sender] == false, "Already participated");
        require(block.timestamp < endOfSale, "Sale over");

        boughtSBR[msg.sender] = true;

        IERC20(MIM).safeTransferFrom(msg.sender, addressToSendMIM, purchaseMIMAmount);
        IERC20(aSBR).safeTransfer(msg.sender, allocatedaSBRPerUser);

        return true;
    }

    /**
     *  @notice Burn the remaining aSBR 
     *  @return true if it works
    */
    function burnRemainingaSBR()
        external
        onlyOwner()
        returns (bool)
    {
        require(saleStarted() == true, "Not started");
        require(block.timestamp >= endOfSale, "Not ended");

        IERC20Burnable(aSBR).burn(IERC20(aSBR).balanceOf(address(this)));

        return true;
    }


}