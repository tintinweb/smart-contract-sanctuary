/**
 *Submitted for verification at BscScan.com on 2021-08-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
}
contract InvestorManager {
    struct Investor {
        address investorAddress;
        address presenterAddress;
        uint256 tokenSwapped;
        uint256 level;
    }

    mapping(address => Investor) public investors;
    
    event CreateInvestor(address investorAddress, address presenterAddress);
      
    function createInvestor(address investorAddress, address presenterAddress) internal {
        investors[investorAddress] = Investor({
            investorAddress: investorAddress,
            presenterAddress: presenterAddress,
            tokenSwapped: 0,
            level: investors[presenterAddress].level + 1
        });
        emit CreateInvestor(investorAddress, presenterAddress);
    }
    
    function createNormalUser(address investorAddress, address presenterAddress) internal {
        if (isInvestor(investorAddress)) return;
        require(isInvestor(presenterAddress), 'PRESENTER_NOT_FOUND');
        createInvestor(investorAddress, presenterAddress);
    }

    function isInvestor(address presenterAddress) public view returns(bool) {
        return investors[presenterAddress].level != 0;
    }
}

contract PreSell is InvestorManager {
    IERC20 public ncfToken;
    address public owner;
    address public admin;

    

    modifier onlyOwnerOrAdmin(){
        require(msg.sender == owner || msg.sender == admin, "ONLY_OWNER_OR_ADMIN");
        _;
    }

    uint256 public price = 77778;

    function setPrice(uint256 _price) public onlyOwnerOrAdmin() {
        price = _price;
    }

    function buyToken() public payable {
        //createNormalUser(msg.sender, normalizePresenterAddress(presenterAddress));
       // Investor storage investor = investors[msg.sender];
        uint256 ncfValue = msg.value / price;
       // investor.tokenSwapped += ncfValue;
        //payWithCommission(msg.sender, ncfValue);
        ncfToken.transfer(msg.sender, ncfValue);
    }

    struct Payment {
        uint256 value;
        address receiver;
    }
}