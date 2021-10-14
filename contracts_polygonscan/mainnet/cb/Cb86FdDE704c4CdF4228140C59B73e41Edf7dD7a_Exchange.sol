/**
 *Submitted for verification at polygonscan.com on 2021-10-14
*/

pragma solidity ^0.5.0;

contract Controlled {
    modifier onlyController { 
        require(msg.sender == controller); 
        _; 
    }

    address public controller;
    constructor () public {
        controller = msg.sender;
    }

    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


interface IERC721{
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}



contract Exchange is Controlled{

    event Aucting(address indexed from, uint256 indexed amount, uint256 indexed tokenId);
    event FreshPrice(address winner, uint256 lastPrice, uint256 price, uint256 tokenId);
    event StartAction(address from, address token, uint256 amount, uint256 step, uint256 tokenId, uint256 end);

    using SafeMath for uint256;
    using Address for address;
    
    address public feeToken;
    address public dToken;
    address public nftAddress;

    bool public status;

    uint public roundMembers;
    uint public transPrice;
    uint public pricePer;
    uint public layRoundSenconds;

    mapping(uint256 => address)   private tokenOwnner;
    mapping(uint256 => uint256)   private tokenStartPrice;
    mapping(uint256 => uint256)   private tokenAuctionPrice;
    mapping(uint256 => address)   private tokenAuctionWinner;
    mapping(uint256 => uint256)   private tokenAuctionEnd;
    mapping(uint256 => uint256)   private tokenAuctionPricePoint;
    mapping(uint256 => uint256)   private tokenAuctionBids;
    mapping(uint256 => address[])   private tokenAuctionBiders;
    mapping(uint256 => mapping(address => uint8))   private tokenAuctionBider;
    mapping(address => uint256)  private _userBidcount; //
    mapping(address => uint256)  private _userAmount; //
    mapping(address => uint256)  private _frozenAmount; //


    constructor (address _nft, address _feeToken, address _dToken) public {
        nftAddress = _nft;
        feeToken = _feeToken;
        dToken = _dToken;
        roundMembers =3;
        transPrice = 1000;
        pricePer = 10**6;
        layRoundSenconds = 43200;
        status = true;
    }

    function onoff() public onlyController{
        status = !status;
    }

    function setConfig(uint256 _members, uint _level, uint _seconds) public onlyController returns (bool){
        roundMembers = _members;
        transPrice = _level;
        layRoundSenconds = _seconds;
        return true;
    }

    function auctionToken(uint256 _tokenId, uint _baseAmount, uint _froAmount, uint _duration) public returns (bool) {
        require(status, "NFT: closed");
        IERC721 nftPool = IERC721(nftAddress);
        nftPool.transferFrom(msg.sender, address(this), _tokenId);
        require(tokenAuctionPrice[_tokenId]==0, "NFT: already start auction");
        require(_baseAmount>0, "NFT: price param illage");
        require(_duration<=86400*7, "too long time");
        require(_userFee[msg.sender]>=_userFro[msg.sender].add(_froAmount), "NFT: promise too less");
        uint256 end = now+_duration;
        tokenAuctionPrice[_tokenId] = _baseAmount;
        tokenStartPrice[_tokenId] = _baseAmount;
        tokenAuctionWinner[_tokenId] = msg.sender;
        tokenOwnner[_tokenId] = msg.sender;
        tokenAuctionEnd[_tokenId] = end;
        tokenAuctionPricePoint[_tokenId] = now;
        _tokenFro[_tokenId] = _froAmount;
        _userFro[msg.sender] = _userFro[msg.sender].add(_froAmount);

        emit StartAction(msg.sender, dToken, _baseAmount, 0, _tokenId, end);
        return true;
    }

    function joinAuction(uint256 _tokenId) public returns (bool) {
        require(tokenAuctionPrice[_tokenId]>0, "NFT: auction not start");
        require(now<tokenAuctionEnd[_tokenId], "NFT: already end");
        require(tokenAuctionBider[_tokenId][msg.sender] == 0, "NFT: repeat bid");
        require(_userBidcount[msg.sender] == 0, "NFT: busy!");
        uint256 lastPrice = tokenAuctionPrice[_tokenId];
        uint256 thisPrice = lastPrice.mul(106).div(100);
        require(_userAmount[msg.sender]>=thisPrice, "NFT: recharge amount");
        if(lastPrice>transPrice.mul(pricePer)){
            require(tokenAuctionBids[_tokenId]<30||now >= (tokenAuctionPricePoint[_tokenId]+layRoundSenconds));
        }
        _userBidcount[msg.sender] = _userBidcount[msg.sender].add(1);
        tokenAuctionBider[_tokenId][msg.sender] = 1;
        tokenAuctionBiders[_tokenId].push(msg.sender);
        tokenAuctionBids[_tokenId] = tokenAuctionBids[_tokenId].add(1);
        _userAmount[msg.sender] = _userAmount[msg.sender].sub(thisPrice);
        _frozenAmount[msg.sender] = _frozenAmount[msg.sender].add(thisPrice);

        if(lastPrice>transPrice.mul(pricePer)){
            if(now >= (tokenAuctionPricePoint[_tokenId]+layRoundSenconds)){
                refreshTokenPrice(_tokenId);
            }
        }else{
            if(tokenAuctionBids[_tokenId]>=roundMembers||now >= (tokenAuctionPricePoint[_tokenId]+600)){
                refreshTokenPrice(_tokenId);
            }
        }

        emit Aucting(msg.sender, thisPrice, _tokenId);
        return true;
    }

    function refreshTokenPrice(uint256 _tokenId) internal returns(bool){
        uint256 lastPrice = tokenAuctionPrice[_tokenId];
        uint256 thisPrice = lastPrice.mul(106).div(100);
        address winner = tokenAuctionWinner[_tokenId];
        uint maxPromise = 0;
        address maxUser = address(0);
        address[] memory currJoins = tokenAuctionBiders[_tokenId];
        for(uint i = 0; i<currJoins.length; i++){
            address bidUser = currJoins[i];
            tokenAuctionBider[_tokenId][bidUser] = 0;
            _userBidcount[bidUser] = _userBidcount[bidUser].sub(1);
            _userAmount[bidUser] = _userAmount[bidUser].add(thisPrice);
            _frozenAmount[bidUser] = _frozenAmount[bidUser].sub(thisPrice);
            uint256 myPromise = userActivePromise(bidUser);
            if(myPromise>maxPromise||maxUser==address(0)){
                maxUser = bidUser;
                maxPromise = myPromise;
            }
        }

        emit FreshPrice(maxUser, lastPrice, lastPrice.mul(106).div(100), _tokenId);

        bool succ = distribeIncrease(_tokenId, maxUser, winner, lastPrice);
        require(succ,"distribe fail");
        delete tokenAuctionBiders[_tokenId];
        tokenAuctionBids[_tokenId]=0;
        tokenAuctionPricePoint[_tokenId] = now;
        tokenAuctionWinner[_tokenId] = maxUser;
        tokenAuctionPrice[_tokenId] = lastPrice.mul(106).div(100);
        return true;
    }

    function distribeIncrease(uint256 _tokenId, address newWiner, address oldWiner, uint256 lastPrice) internal returns(bool){
        address owner = tokenOwnner[_tokenId];
        uint256 newPrice = lastPrice.mul(106).div(100);
        uint256 increase = newPrice - lastPrice;
        _userAmount[newWiner] = _userAmount[newWiner].sub(newPrice);
        _userAmount[owner] = _userAmount[owner].add(increase/6);
        _userAmount[oldWiner] = _userAmount[oldWiner].add(lastPrice).add(increase/3);
        _userAmount[controller] = _userAmount[controller].add(increase/2);
        return true;

    }

    function jumpRound(uint256 _tokenId) public returns (bool){
        uint256 lastPrice = tokenAuctionPrice[_tokenId];
        require(tokenAuctionPrice[_tokenId]>0, "NFT: auction not start");
        require(tokenAuctionBids[_tokenId]>0, "NFT: no player");
        if(lastPrice>transPrice.mul(pricePer)){
            require(now >= (tokenAuctionPricePoint[_tokenId]+layRoundSenconds), "NFT: too early");
        }else{
            require(now >= (tokenAuctionPricePoint[_tokenId]+600), "NFT: too early");
        }

        refreshTokenPrice(_tokenId);
        return true;
    }

    function closeAuction(uint256 _tokenId) public returns (bool){
        require(tokenOwnner[_tokenId]==msg.sender, "NFT: only owner can do this");
        require(tokenAuctionPrice[_tokenId]==tokenStartPrice[_tokenId]&&tokenAuctionBids[_tokenId]==0, "NFT: someone join,cannot do this");

        address winner = tokenAuctionWinner[_tokenId];
        IERC721 nftPool = IERC721(nftAddress);
        nftPool.transferFrom(address(this), winner, _tokenId);
        tokenAuctionPrice[_tokenId] = 0;
        tokenAuctionBids[_tokenId]=0;
        uint256 tokenFrothen = _tokenFro[_tokenId];
        _userFro[winner] = _userFro[winner].sub(tokenFrothen);
        return true;
    }

    function finishAuction(uint256 _tokenId) public returns (bool){
        require(tokenAuctionPrice[_tokenId]>0, "NFT: auction not start");
        require(now>tokenAuctionEnd[_tokenId], "NFT: too early");
        if(tokenAuctionBids[_tokenId]>0){
            refreshTokenPrice(_tokenId);
        }

        address winner = tokenAuctionWinner[_tokenId];
        address oldOwner = tokenOwnner[_tokenId];
        IERC721 nftPool = IERC721(nftAddress);
        nftPool.transferFrom(address(this), winner, _tokenId);
        tokenAuctionPrice[_tokenId] = 0;
        uint256 tokenFrothen = _tokenFro[_tokenId];
        _userFro[oldOwner] = _userFro[oldOwner].sub(tokenFrothen);
        return true;
    }


    function tokenAuctionStatus(uint256 _tokenId) public view returns (uint256 price, address winner, uint256 endPoint, uint256 pricePoint, uint bidCount, address[] memory bidUsers) {
        price = tokenAuctionPrice[_tokenId];
        winner = tokenAuctionWinner[_tokenId];
        endPoint = tokenAuctionEnd[_tokenId];
        pricePoint = tokenAuctionPricePoint[_tokenId];
        bidCount = tokenAuctionBids[_tokenId];
        bidUsers = tokenAuctionBiders[_tokenId];
    }


    mapping(address => uint256)  private _userFee; //
    mapping(address => uint256)  private _userFro; //
    mapping(uint256 => uint256)  private _tokenFro; //


    function userActivePromise(address _from) internal view returns(uint256){
        uint256 active = SafeMath.sub(_userFee[_from], _userFro[_from]);
        return active;
    }


    function withdraw(uint256 _number) public returns (bool){
        require(_number>0,"illage param");
        uint256 activeAmount = userActivePromise(msg.sender);
        require(_userFee[msg.sender] >= _number,"Insufficient Balance");
        require(activeAmount >= _number,"some frozen, out of balance");
        IERC20 fee = IERC20(feeToken);
        bool success = fee.transfer(msg.sender, _number);
        require(success);
        _userFee[msg.sender] = SafeMath.sub(_userFee[msg.sender], _number ); 
        return true;
    }

    function recharge(uint _number) public returns (bool){
        require(_number>0,"illage param");
        IERC20 fee = IERC20(feeToken);
        bool success =fee.transferFrom(msg.sender, address(this), _number);
        require(success);
        _userFee[msg.sender] = SafeMath.add(_userFee[msg.sender], _number); 
        return true;
    }

    function withdrawD(uint256 _number) public returns (bool){
        require(_number>0,"illage param");
        require(_userAmount[msg.sender] >= _number,"Insufficient Balance");
        IERC20 fee = IERC20(dToken);
        bool success = fee.transfer(msg.sender, _number);
        require(success);
        _userAmount[msg.sender] = SafeMath.sub(_userAmount[msg.sender], _number );
        return true;
    }

    function rechargeD(uint _number) public returns (bool){
        require(_number>0,"illage param");
        IERC20 fee = IERC20(dToken);
        bool success =fee.transferFrom(msg.sender, address(this), _number);
        require(success);
        _userAmount[msg.sender] = SafeMath.add(_userAmount[msg.sender], _number );
        
        return true;
    }

    function userFee(address from) public view returns (uint activeAmount, uint frozenAmount, uint bidCount, uint dAmount, uint frozenD) {
        uint totalAmount = _userFee[from];
        frozenAmount = _userFro[from];
        activeAmount = totalAmount.sub(frozenAmount);
        bidCount = _userBidcount[from];
        dAmount = _userAmount[from];
        frozenD = _frozenAmount[from];
    }
}




interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}