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
    
    
}

contract PreSell is InvestorManager{
    IERC20 public ncfToken;
    address public owner;
    address public admin;

    constructor(IERC20 _ncfToken, address _admin) {
        ncfToken = _ncfToken;
        owner = msg.sender;
        admin = _admin;
        createInvestor(owner, address(0));
    }

    modifier onlyOwnerOrAdmin(){
        require(msg.sender == owner || msg.sender == admin, "ONLY_OWNER_OR_ADMIN");
        _;
    }

    uint256 public price = 30000;
    uint256 public TotalPresell = 15000000;
    uint256 public Presell = 0;
    function setPrice(uint256 _price) public onlyOwnerOrAdmin() {
        price = _price;
    }
    
    function setPresellTotal(uint256 _TotalPresell) public onlyOwnerOrAdmin() {
        TotalPresell = _TotalPresell;
    }
    
    function PresellNumber() public virtual returns (uint256){
        return Presell;
    }

    function buyToken() public payable {
        //createNormalUser(msg.sender, normalizePresenterAddress(presenterAddress));
       // Investor storage investor = investors[msg.sender];
        uint256 ncfValue = msg.value * price;
        require(Presell+ncfValue >= TotalPresell, "Pre Sell Finish");
       // investor.tokenSwapped += ncfValue;
        //payWithCommission(msg.sender, ncfValue);
        ncfToken.transfer(msg.sender, ncfValue);
        Presell += ncfValue;
    }
    
    struct Payment {
        uint256 value;
        address receiver;
    }
    function withdrawBNB() public onlyOwnerOrAdmin() {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawNCF(uint256 amount) public onlyOwnerOrAdmin() {
        ncfToken.transfer(msg.sender, amount);
    }
}