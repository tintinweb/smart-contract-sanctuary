//"SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.8.0;

import "./safeMath.sol";
import "./ownable.sol";
import "./safeERC20.sol";

interface ICrowdSale {
    function setReferrals(address referee, address referral) external;

    function direct_referee(address _user) external view returns (address);

    function referrals(address _user, uint256 _index)
        external
        view
        returns (address);

    function getReferralLength(address referral)
        external
        view
        returns (uint256);
}


contract CrowdSaleV2 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 constant public PRICE_CAP = 1.9 ether;  // 1.9 usdt
    uint256 constant public INITIAL_PRICE = 1.3 ether;   // 1.3 usdt
    uint256 constant public TOTAL_ROB_TO_BE_SOLD = 6700000 ether;
    uint256 constant public PRICE_INCREASE = 89552239000;
    
    IERC20 public USDT;
    IERC20 public ROB;

    ICrowdSale public CROWDSALEV1;

   mapping(address=>uint256) public tokensBought;

    uint256 public price = INITIAL_PRICE; // 1.3 usdt
    
    uint256 public total_rob_sold = 0;
    uint256 public total_usdt_received = 0;

    uint[] public level_bonuses = [5, 7, 4, 2, 2];

    event PurchasedUsingUSDT(address indexed user, uint256 amount_token, uint256 amount_usdt);

    constructor(address _usdt, address _rob,ICrowdSale _crowdSaleV1){
        USDT = IERC20(_usdt);
        ROB = IERC20(_rob);
        CROWDSALEV1 = ICrowdSale(_crowdSaleV1);
    }


    function getReferralLength(address referral) public view returns(uint256){
        return CROWDSALEV1.getReferralLength(referral);
    }

    function direct_referee(address _user) public view returns(address){
        return CROWDSALEV1.direct_referee(_user);
    }
    
    function validateAndManageReferrals(uint256 _usdt_amount, address referee) internal {
        require(_usdt_amount > 0, "CrowdSaleV2: Cannot buy for 0");
        require(referee != address(0), "CrowdSaleV2: referee can not be a 0 address");
        require(referee != msg.sender, "CrowdSaleV2: self reference.");
        if(referee!=CROWDSALEV1.direct_referee(msg.sender)){
            CROWDSALEV1.setReferrals(referee,msg.sender);
        }
    }

    function transferTokensWithReferrals(uint256 _amount, IERC20 token) internal {
        uint256 counter = 0;
        uint256 pending_amount = _amount;
        address referee = msg.sender;
        while(counter < 5){
            if(CROWDSALEV1.direct_referee(msg.sender) == address(0)){
                break;
            }else{
                referee = CROWDSALEV1.direct_referee(msg.sender);
                uint256 transferAmount =  _amount.mul(level_bonuses[counter]).div(100);
                token.safeTransferFrom(msg.sender, referee, transferAmount);
                pending_amount = pending_amount.sub(transferAmount);
                counter = counter.add(1);
            }
        }
        token.safeTransferFrom(msg.sender, address(this), pending_amount);
    }
    
    function newPrice(uint256 _tokenReceive) internal view returns(uint256){
        uint256 priceIncrease = price.add((_tokenReceive.add(total_rob_sold)).mul(PRICE_INCREASE).div(1e18));
        
        // price cap 1.9 usdt
        if(priceIncrease >= PRICE_CAP){
            priceIncrease = PRICE_CAP;
        }
        return priceIncrease;
    }

 // A(referee) => B(referral), A refers B
    function setReferrals(address referee, address referral) public onlyOwner {
        if(referee!=CROWDSALEV1.direct_referee(referral)){
            CROWDSALEV1.setReferrals(referee,referral);
        }
    }
    
    function buyUsingUSDT(uint256 _usdt_amount, address referee) external {
        validateAndManageReferrals(_usdt_amount, referee);
        setReferrals(referee, msg.sender);
        uint256 tokensToReceive = calculateRobTokens(_usdt_amount);
        total_usdt_received = total_usdt_received.add(_usdt_amount);
        transferTokensWithReferrals(_usdt_amount, USDT);
        price = newPrice(tokensToReceive);
        total_rob_sold = total_rob_sold.add(tokensToReceive);
        ROB.safeTransfer(msg.sender, tokensToReceive);
        tokensBought[msg.sender]=tokensBought[msg.sender].add(tokensToReceive);
        emit PurchasedUsingUSDT(msg.sender, tokensToReceive, _usdt_amount);
    }
    
    function sqrt(uint x) public pure returns (uint y) {
        uint z = (x.add(1)).div(2);
        y = x;
        while (z < y) {
            y = z;
            z = ((x.div(z)).add(z)).div(2);
        }
    }
    
    function calculateUsdtTokens(uint256 _rob_amount) public view returns(uint256){
        uint256 totalTokens = (_rob_amount.add(total_rob_sold)).mul(INITIAL_PRICE.mul(2).add((_rob_amount.add(total_rob_sold)).mul(PRICE_INCREASE).div(1e18))).div(2);
        return totalTokens.div(1e18).sub(total_usdt_received);
    }
    
    
    function calculateRobTokens(uint256 _usdt_amount) public view returns(uint256){
        uint256 newRobSum = total_usdt_received.add(_usdt_amount);
        uint256 priceSqr = INITIAL_PRICE.mul(INITIAL_PRICE);
        uint256 a =PRICE_INCREASE.mul(newRobSum).mul(2);
        uint256 b = sqrt(priceSqr.add(a));
        uint256 c = b.sub(INITIAL_PRICE);
        uint256 totalSum = (c.mul(1e18)).div(PRICE_INCREASE);
        uint256 tokensToReceive = totalSum.sub(total_rob_sold);
        return tokensToReceive;
    }
    
    function withdrawAny(address _token_address, uint256 _amount) external onlyOwner{
        IERC20 token = IERC20(_token_address);
        require(token.balanceOf(address(this)) > _amount, "Cannot withdraw more than balance");
        token.safeTransfer(msg.sender, _amount);
    }
    
    function referrals(address _user,uint256 _index) public view returns(address){
        return CROWDSALEV1.referrals(_user,_index);
    }
    
    function getPrice() public view returns(uint256){
        return price;
    }
    
    function getRemainingRobToBeSold() public view returns(uint256){
        return TOTAL_ROB_TO_BE_SOLD.sub(total_rob_sold);
    }
}