// 不是吧？ 难道你连私募合约也要抄？ 不至于吧哥们，这么菜发什么币？？？？
// 不会吧不会吧 不会有人连写代码都不会还来发币吧？？？？ 这个人不会就是你把？？？
// 如果你觉得你能做出我们那么牛X的生态 你就抄吧  哦对了忘了告诉你 我们网站加密了 你抄不了
// 安心做你的土狗去吧
// https://t.me/dicebounty
// https://dicebounty.com/

import { SafeMath } from 'SafeMath.sol';
import 'Ownable.sol';
import { ReentrancyGuard } from 'ReentrancyGuard.sol';
import { IERC20 } from 'ERC20.sol';


contract DBPrivatePresale is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    // Maps user to the number of tokens owned
    mapping (address => uint256) public tokensOwned;
    mapping (address => uint256) public lastTokensClaimed;
    mapping (address => uint256) public numClaims;
    mapping (address => uint256) public tokensToclaimed;
    mapping (address => bool) public hasKeyToBuyPrivatePresale;
    mapping (address => uint256) public tryAmount;
    mapping (address => uint256) public buyTime;
    IERC20 DiceBounty;
    
    
    bool isSaleActive;
    bool isLotteryActive;
    
    uint256 startingTimeStamp;
    uint256 totalTokensSold = 0;
    uint256 MaticLotteryed = 0;
    uint256 price;
    uint256 MaticReceived = 0;

    address[] PrivatePresaleeBuyer;
        
    event TokenBuy(address user, uint256 tokens);
    event TokenClaim(address user, uint256 tokens);

    constructor () public {
        isSaleActive = false;
        price = 400;
    }

    receive() external payable {
        buy (msg.sender);
    }

    function buy (address beneficiary) public payable nonReentrant {
        require(isLotteryActive,"Lottery not start");
        address _buyer = beneficiary;
        uint256 _Matic = msg.value;
        uint256 tokens  = _Matic  * price;
        
        if(hasKeyToBuyPrivatePresale[_buyer] == false){
            require(_Matic >= 5,"Wrong Matic Value,SHOULD send more than 5 Matic");
            if(BuyerAddresIsExist(_buyer) == false){
                PrivatePresaleeBuyer.push(_buyer);
            }
            MaticLotteryed += _Matic;
            if(randUint256(9) == 8 || tryAmount[_buyer] >19){
                hasKeyToBuyPrivatePresale[_buyer] = true;
            }
            else{
                tryAmount[_buyer] += 1;
            }
        }
        else{
          require(isSaleActive, "DB Private PreSale not active");
          require (_Matic >= 200 ether, "Matic is lesser than min value");
          require (_Matic <= 2000 ether, "Matic is greater than max value");
          require (MaticReceived <= 20000 ether, "Private Presale sold out");
          require (block.timestamp >= startingTimeStamp, "Presale has not started");
          tokensOwned[_buyer] = tokensOwned[_buyer].add(tokens);
          require(tokensOwned[_buyer] <= price * 2000 ether, "Private presale at most buy 2000 Matic");
          tokensToclaimed[_buyer] = tokensToclaimed[_buyer].add(tokens);
          totalTokensSold = totalTokensSold.add(tokens);
          buyTime[_buyer] = block.timestamp;
          MaticReceived = MaticReceived.add(msg.value);
          emit TokenBuy(beneficiary, tokens);
          //别抄了 吐了
        }
    }

    function setSaleActive(bool _isSaleActive) external onlyOwner {
        isSaleActive = _isSaleActive;
    }
    
    function setLotteryActive(bool _isActive) public onlyOwner{
        isLotteryActive = _isActive;
    }
    
    
    function SetPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function GetTokensOwned(address _address) external view returns (uint256) {
        return tokensOwned[_address];
    }

    function getTotalTokensSold() public view returns(uint256){
        return totalTokensSold;
    }

    function getTokensToClaimed(address _address) external view returns(uint256) {
        return tokensToclaimed[_address];
    }
    
    function getHasKEyToBuyPrivatePresale(address _address) external view returns(bool){
        return hasKeyToBuyPrivatePresale[_address];
    }

    function getLastTokensClaimed () external view returns (uint256) {
        return lastTokensClaimed[msg.sender];
    }

    function getDBLeft() external view returns (uint256) {
        return DiceBounty.balanceOf(address(this));
    }

    function getNumClaims () external view returns (uint256) {
        return numClaims[msg.sender];
    }

    function claimTokens() external nonReentrant {
        require (tokensOwned[msg.sender] > 0, "NO TOKENS TO CLAIM");
        require (tokensToclaimed[msg.sender] > 0, "NO TOKENS TO CLAIM");
        require (DiceBounty.balanceOf(address(this)) >= tokensOwned[msg.sender], "ERROR DB TOKEN NOT ENOUGH");
        require (numClaims[msg.sender] < 1, "DO NOT CLAIM REPEATLY");

        tokensToclaimed[msg.sender] = tokensToclaimed[msg.sender].sub(tokensOwned[msg.sender]);
        lastTokensClaimed[msg.sender] = block.timestamp;
        numClaims[msg.sender] = numClaims[msg.sender].add(1);

        DiceBounty.transfer(msg.sender, tokensOwned[msg.sender]);
        emit TokenClaim(msg.sender, tokensOwned[msg.sender]);
    }

    function resetToken(IERC20 _DBNewToken) public onlyOwner {
        DiceBounty = _DBNewToken;
    }

    function withdrawFunds () external onlyOwner {
        (msg.sender).transfer(address(this).balance);
    }
    
   function randUint256(uint256 _length) public view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return random%_length;
    }
    
    function BuyerAddresIsExist(address _address) internal view returns(bool){
        for(uint256 i = 0; i < PrivatePresaleeBuyer.length ; i++){
            if(_address == PrivatePresaleeBuyer[i]){
                return true;
            }
        }
        return false;
    }
    
    function getBuyTime(address _address) public view returns(uint256){
        return buyTime[_address];
    }
    
    function getClaimTokenTime(address _address) public view returns(uint256){
        return lastTokensClaimed[_address];
    }
    
    function getPrivatePresaleJoinMemberAmount() public view returns(uint256){
        return PrivatePresaleeBuyer.length;
    }
    
    function getprivatePresaleMemberAddressByIndex(uint256 _index) public view returns(address){
        return PrivatePresaleeBuyer[_index];
    }
    
    function getTryAmountByAddress(address _address) public view returns(uint256){
        return tryAmount[_address];
    }

    function withdrawUnsoldTokens() external onlyOwner {
        DiceBounty.transfer(msg.sender, DiceBounty.balanceOf(address(this)));
    }
}