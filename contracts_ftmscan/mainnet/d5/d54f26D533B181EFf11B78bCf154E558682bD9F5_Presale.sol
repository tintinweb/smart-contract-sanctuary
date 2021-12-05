// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import './SafeMath.sol';
import './SafeERC20.sol';
import './Ownable.sol';
import './IERC20.sol';



contract Presale is Ownable{

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public rewardToken;
    address public paymentToken;
    uint256 public totalRaised;
    
    bool public presaleOpen = false;
    uint256 maxPayout = 1500e18;

    mapping( address => bool ) isWhitelisted;
    mapping( address => bool ) whitelistHasBought;
    mapping( address => uint256 ) remainingPayment;
    uint public sellPrice; // sellPrice in usd (256 for instance is 2.56)

    uint256 epochNumber = 0;

    constructor (
        address _rewardToken,
        address _paymentToken,
        uint256 _sellPrice
    ) {
        require( _rewardToken != address(0));
        require( _paymentToken != address(0));
        rewardToken = _rewardToken;
        paymentToken = _paymentToken;
        sellPrice = _sellPrice;
    }


    function addToWhitelist(address[] memory _addresses) public onlyOwner {
        for (uint256 i=0; i<_addresses.length; i++) {
            isWhitelisted[_addresses[i]] = true;
            remainingPayment[_addresses[i]] = maxPayout;
        }
    }
    
    modifier sellEnabled() {
        require( presaleOpen, "Presale is not open");
        _;
    }

    function buySomeToken( uint256 _paymentAmount ) external sellEnabled {
        uint256 amountNewToken = _paymentAmount.mul(100).div(sellPrice);
        require( _paymentAmount <= remainingPayment[msg.sender], "Presale Allocation exceeded");
        require( IERC20(rewardToken).balanceOf(address(this)) >= amountNewToken, "Contract is not full enough, contact support");
        remainingPayment[msg.sender] = remainingPayment[msg.sender].sub(_paymentAmount);
        IERC20(paymentToken).transferFrom(msg.sender, address(this), _paymentAmount);
        IERC20(rewardToken).transfer(msg.sender, amountNewToken);
        totalRaised = totalRaised.add(_paymentAmount);
        emit SoldSomeToken(msg.sender, amountNewToken);
    }

    event SoldSomeToken(address recipient, uint256 amount);

    function enableSale() external onlyOwner {
        require( !presaleOpen, "presale is already enabled");
        presaleOpen = true;
    }

    function disableSale() external onlyOwner {
        require( presaleOpen, "presale is already disabled");
        presaleOpen = false;
    }

    function checkOwnAllocation() public view returns(uint256) {
        return remainingPayment[msg.sender];
    }
    function checkUserAllocation(address _user) external onlyOwner returns(uint256){
        return remainingPayment[_user];
    }
    function checkOwnWhitelisted() public view returns (bool) {
        return isWhitelisted[msg.sender];
    }
    function checkUserWhitelisted(address _user) external onlyOwner returns (bool) {
        return isWhitelisted[_user];
    }

    function retrievePayments() external onlyOwner {
        IERC20(paymentToken).transfer(msg.sender, IERC20(paymentToken).balanceOf(address(this)));
    }
}