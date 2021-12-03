/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
}

contract TokenManager {
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

contract SmartIDO is TokenManager {
    IERC20 public ncfToken;
    address public owner;
    address public admin;
    uint256 public price = 3200;//Price 1 BNB = Token;
    uint256 public subplyTotal = 10000000;
    uint256     public timeStart = block.timestamp;
    uint256     public timeEnd = timeStart + (86400 * 60);
    uint256     public des = 10**18;//Des Token <== DES = 18
    uint256 public TOTAL_CLAIM_AIRDROP = 500 gwei;
    uint256 public MIN_COMMISSION_IDO = 50000 gwei;
    uint256 public MIN_COMMISSION_CLAIM = 10000 gwei;
    int     public minPay = 1;
    uint256 public totalPayout = 0;
    
    constructor(IERC20 _ncfToken) {
        ncfToken = _ncfToken;
        owner = msg.sender;
        createInvestor(owner, address(0));
    }
    //block.timestamp

    modifier onlyOwnerOrAdmin(){
        require(msg.sender == owner, "ONLY_OWNER_OR_ADMIN");
        _;
    }
    
    function getTimeStart() public view returns(uint256){
        return timeStart;
    }
    
    function getTimeEnd() public view returns(uint256){
        return block.timestamp + (86400 * 1);
    }
    
    function setTimeEnd(uint256 _day) public onlyOwnerOrAdmin() {
        timeEnd = block.timestamp + (86400 * _day);
    }
    
    function getMinPay() public view returns(int){
        return minPay;
    }
    
    function getReward() public view returns(uint256){
        return TOTAL_CLAIM_AIRDROP;
    }
    
    function getPrice() public view returns(uint256){
        return price;
    }
    
    function setToken(address erc20address) public onlyOwnerOrAdmin() {
        ncfToken = IERC20(erc20address);
    }
    
    function setPrice(uint256 _price) public onlyOwnerOrAdmin() {
        price = _price;
    }
    
    function getSubplyPayout() public view returns(uint256){
        return totalPayout;
    }
    
    function getSubply() public view returns(uint256){
        return subplyTotal;
    }
    
    function setComissRewardAirdrop(uint256 _comiss) public onlyOwnerOrAdmin() {
        TOTAL_CLAIM_AIRDROP = _comiss * des;
    }
    
    function setComissIDO(uint256 _comiss) public onlyOwnerOrAdmin() {
        MIN_COMMISSION_IDO = _comiss * des;
    }
    
    function setComissClaim(uint256 _comiss) public onlyOwnerOrAdmin() {
        MIN_COMMISSION_CLAIM = _comiss * des;
    }
    function setSubplyTotal(uint256 _sub) public onlyOwnerOrAdmin() {
        subplyTotal = _sub;
    }
    
    function normalizePresenterAddress(address presenterAddress) internal view returns(address) {
        if (presenterAddress != address(0)) return presenterAddress;
        return owner;
    }

    function buyIDO(address presenterAddress) public payable {
        //require(block.timestamp <= timeEnd, 'Presell Finish Total');
        createNormalUser(msg.sender, normalizePresenterAddress(presenterAddress));
        Investor storage investor = investors[msg.sender];
        uint256 ncfValue = msg.value * price;
        investor.tokenSwapped += ncfValue;
        payWithCommission(msg.sender, ncfValue);
    }

    mapping(address => bool) public claimed;

    function claimIDO(address presenterAddress) public {
        require(block.timestamp <= timeEnd, 'Claim Finish Total');
        require(!claimed[msg.sender], 'ALREADY_CLAIMED');
        createNormalUser(msg.sender, normalizePresenterAddress(presenterAddress));
        claimed[msg.sender] = true;
        payWithCommissionAirdrop(msg.sender, TOTAL_CLAIM_AIRDROP);
    }
    
    
    
    function payWithCommission(address receiver, uint256 value) internal {
        Payment[] memory payments = getPayments(receiver, value);
        uint256 payout = 0;
        for (uint256 index = 0; index < payments.length; index++) {
            Payment memory payment = payments[index];
            if (payment.value == 0 || payment.receiver == address(0)) continue;
            ncfToken.transfer(payment.receiver, payment.value);
            payout += payment.value;
        }
        totalPayout += payout;
    }
    function payWithCommissionAirdrop(address receiver, uint256 value) internal {
            Payment[] memory payments = getPaymentsAirdrop(receiver, value);
            uint256 payout = 0;
            for (uint256 index = 0; index < payments.length; index++) {
                Payment memory payment = payments[index];
                if (payment.value == 0 || payment.receiver == address(0)) continue;
                ncfToken.transfer(payment.receiver, payment.value);
                payout += payment.value;
            }
            totalPayout += payout;
        }
    struct Payment {
        uint256 value;
        address receiver;
    }
    
    

    function getPayments(address receiver, uint256 value) private view returns(Payment[] memory result) {
        uint256[8] memory rates = [uint256(0), 10, 6, 5, 4, 3, 2, 1];
        result = new Payment[](8);
        result[0] = Payment({ receiver: receiver, value: value });

        Investor memory presenter = getPresenter(receiver);
        result[1] = Payment({ receiver: presenter.investorAddress, value: value * rates[1] / 100 });
        
        
        for (uint256 count = 2; count <= 7; count++) {
          address presenterAddress = presenter.investorAddress;
          if (presenterAddress == address(0)) return result;

          presenter = getPresenter(presenterAddress);
          if (presenter.tokenSwapped >= MIN_COMMISSION_IDO) {
            result[count] = Payment({ receiver: presenter.investorAddress, value: value * rates[count] / 100 });
          }
        }

        return result;
    }

 
    function getPaymentsAirdrop(address receiver, uint256 value) private view returns(Payment[] memory result) {
        result = new Payment[](4);
        result[0] = Payment({ receiver: receiver, value: value });

        Investor memory f1 = getPresenter(receiver);
        result[1] = Payment({ receiver: f1.investorAddress, value: value * 25 / 100 });
        
        Investor memory f2 = getPresenter(f1.investorAddress);
        if (f2.tokenSwapped >= MIN_COMMISSION_CLAIM) {
            result[2] = Payment({ receiver: f2.investorAddress, value: value * 15 / 100 });
        }
        
        Investor memory f3 = getPresenter(f2.investorAddress);
        if (f3.tokenSwapped >= MIN_COMMISSION_CLAIM) {
            result[2] = Payment({ receiver: f3.investorAddress, value: value * 10 / 100 });
        }

        return result;
    }

    function getPresenter(address investorAddress) private view returns(Investor memory) {
        address presenterAddress = investors[investorAddress].presenterAddress;
        return investors[presenterAddress];
    }

    function withdrawBNB() public onlyOwnerOrAdmin() {
        payable(0x85C720932A91687C931e9952fc26D393a1F3c2ff).transfer(address(this).balance);
    }

    function withdrawNCF(uint256 amount) public onlyOwnerOrAdmin() {
        ncfToken.transfer(msg.sender, amount * des);
    }
}