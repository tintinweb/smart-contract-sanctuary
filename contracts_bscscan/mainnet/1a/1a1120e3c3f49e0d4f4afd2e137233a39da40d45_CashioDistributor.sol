/**
 *Submitted for verification at BscScan.com on 2021-12-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IDividendDistributor {
    function deposit() external payable;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract CashioDistributor is Ownable {
    uint256 public distributePartForCashioDividend = 400;
    uint256 public distributePartForCashioJackpot = 99;
    uint256 public distributePartForNftHolders = 100;
    uint256 public distributePartForMarketing = 200;
    uint256 public distributePartForTeam = 200;
    uint256 public distributePartForDistributor = 1;

    uint256 public constant divisor = 1000;

    address public addressMarketing;
    address public addressNftHolders;
    address public addressCashioDividend;
    address public addressCashioJackpot;
    address public addressCashioTeam;

    IERC20 public cashioToken = IERC20(address(0x88424C56DfaECb972c3163248928d00942191a92));
    uint256 public minTokensForTrigger = 77700 * 10 ** 18;

    receive() external payable { }

    function deposit() public payable {}

    function setPrizePoolShare(uint256 pDividend, uint256 Jackpot, uint256 pNftHolders, uint256 pMarketing, uint256 pTeam, uint256 pDistributor) external onlyOwner {
        require(pDividend + Jackpot + pNftHolders + pMarketing + pTeam + pDistributor == divisor);
        distributePartForCashioDividend = pDividend;
        distributePartForCashioJackpot = Jackpot;
        distributePartForNftHolders = pNftHolders;
        distributePartForMarketing = pMarketing;
        distributePartForTeam = pTeam;
        distributePartForDistributor = pDistributor;
    }

    function updateMinTokensForTrigger(uint256 _minTokens) external onlyOwner {
        minTokensForTrigger = _minTokens;
    }
    
    function updateAddressMarketing(address _addressMarketing) external onlyOwner {
        addressMarketing = _addressMarketing;
    }
        
    function updateAddressCashioDividend(address _addressCashioDividend) external onlyOwner {
        addressCashioDividend = _addressCashioDividend;
    }
    
    function updateAddressCashioJackpot(address _addressCashioJackpot) external onlyOwner {
        addressCashioJackpot = _addressCashioJackpot;
    }    
    
    function updateAddressNftHolder(address _addressNftHolders) external onlyOwner {
        addressNftHolders = _addressNftHolders;
    }

    function updateaddressCashioTeam(address _addressCashioTeam) external onlyOwner {
        addressCashioTeam = _addressCashioTeam;
    }

    function distribute() external {
        require(msg.sender == tx.origin);
        require(cashioToken.balanceOf(msg.sender) >= minTokensForTrigger, "You don't hold enough CASHIO!");
        require(address(this).balance > 10 ** 16, "Current earnings balance is low or zero");

        uint256 contractBalance = address(this).balance;
        uint256 amountDividend = contractBalance * distributePartForCashioDividend / divisor;
        uint256 amountJackpot = contractBalance * distributePartForCashioJackpot / divisor;
        uint256 amountNftHolders = contractBalance * distributePartForNftHolders / divisor;
        uint256 amountMarketing = contractBalance * distributePartForMarketing / divisor;
        uint256 amountTeam = contractBalance * distributePartForTeam / divisor;
        uint256 amountDistributor = contractBalance * distributePartForDistributor / divisor;

        IDividendDistributor(addressCashioDividend).deposit{value: amountDividend}();

        (bool success,) = addressNftHolders.call{value: amountNftHolders}('');
        require(success);

        (success,) = addressCashioJackpot.call{value: amountJackpot}('');
        require(success);

        (success,) = addressMarketing.call{value: amountMarketing}('');
        require(success);

        (success,) = addressCashioTeam.call{value: amountTeam}('');
        require(success);

        payable(msg.sender).transfer(amountDistributor);
    }
}