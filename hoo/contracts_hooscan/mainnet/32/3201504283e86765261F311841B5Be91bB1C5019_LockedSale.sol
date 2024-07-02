pragma solidity >=0.8.10;

import "./Ownable.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./IPancakeRouter01.sol";
import "./ReentrancyGuard.sol";
// contract
contract LockedSale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    struct Claim {
        uint256 amount;
        uint256 claimBlock;
        bool claimed;
    }

    uint256 public saleBP = 1000; // sale base point 100 -> 1%
    uint256 public minAmount = 0.01 ether;
    bool public saleActive = true;
    uint256 public claimTime = 50; // 200 blocks
    uint256 public soldAmount = 0;

    IBEP20 public token; // token for sale
    IPancakeRouter01 public router;
    address public receiver; // sale funds go to.
    // wbnb , busd
    mapping(address => bool) public whiteListedTokens;
    mapping(address => Claim[]) claimList;

    constructor(IBEP20 _token, IPancakeRouter01 _router, address _recv) {
        token = _token;
        router = _router;
        receiver = _recv;
    }

    function buyToken(uint256 _amount, IBEP20 _spendingToken) public onlySaleActive nonReentrant {
        // _amount RBS to buy
        require(msg.sender != address(0),"Spender address zero.");
        require(whiteListedTokens[address(_spendingToken)] == true, "This token is not whitelisted.");
        require(_amount >= minAmount, "amount too low.");
        uint256 contractBalance = getContractBalance();
        require(_amount <= contractBalance,"amount too high.");
        uint256 currentPrice = getAmountOut(_spendingToken, _amount); // currenPrice means total busd or wbnb have to paid to buy that amount from lp
        uint256 saleDiscount = currentPrice.mul(saleBP).div(10000);
        uint256 discountedPrice = currentPrice.sub(saleDiscount);
        _spendingToken.safeTransferFrom(msg.sender, receiver, discountedPrice);
        Claim[] storage claims = claimList[msg.sender];
        claims.push(Claim({
            amount : _amount,
            claimBlock : block.number.add(claimTime),
            claimed : false
        }));
        soldAmount = soldAmount.add(_amount);

        emit TokenBought(_spendingToken,_amount, discountedPrice);
    }


    // _cid => claim id, claim index in array
    function claimTokens(uint64 _cid) public nonReentrant {
        require(msg.sender != address(0), "Sender address zero.");
        Claim memory claim = claimList[msg.sender][_cid];
        require(claim.claimed == false, "Already claimed"); // unnecessary can be removed
        require(claim.amount > 0, "Claim amount zero");
        uint256 currBlock = block.number;
        require(currBlock >= claim.claimBlock, "You have to wait.");
        uint256 amount = claim.amount;
        delete claimList[msg.sender][_cid];
        // eğer yukarıdaki çalışmazsa
        // claimList[msg.sender][_cid].claimed = true;
        token.safeTransfer(msg.sender, amount);
        soldAmount = soldAmount.sub(amount);
        emit TokensClaimed(amount);
    }

    // internal functions

    function pathMaker(IBEP20 _spendingToken) internal view returns(address[] memory) {
        address[] memory path;
        path = new address[](2);
        path[0] = address(token);
        path[1] = address(_spendingToken);
        return path;
    }

    // view functions

    function getUsersClaims(address _user) public view returns(Claim[] memory) {
        require(_user != address(0), "Address zero.");

        Claim[] memory claims = claimList[_user];
        return claims;
    }

    function getClaim(address _user, uint256 _cid) public view returns(Claim memory) {
        require(_user != address(0),"Address zero.");

        return claimList[_user][_cid];
    }

    function getContractBalance() public view returns(uint256) {
        uint256 balance = token.balanceOf(address(this));
        require(balance >= soldAmount, "Sold amount higher");
        uint256 available = balance.sub(soldAmount);
        return available;
    }

    function getAmountOut(IBEP20 _spendingToken, uint256 _amount) public view returns(uint256) {
        address[] memory path = pathMaker(_spendingToken);
        uint256[] memory amounts = router.getAmountsOut(_amount, path);
        return amounts[1];
    }

    function getTokensOut(IBEP20 _spendingToken, uint256 _amount) public view returns(uint256) {
        // kullanıcı rbs miktarını yazacak ve ne kadar ödeyeceğini döndürecek
        address[] memory path = pathMaker(_spendingToken);
        uint256[] memory amounts = router.getAmountsOut(_amount, path);
        uint256 payAmount = amounts[1];
        uint256 saleDiscount = payAmount.mul(saleBP).div(10000);
        uint256 discountedPrice = payAmount.sub(saleDiscount);
        return discountedPrice;
    }


    // owner functions

    function setSaleDiscount(uint256 _sale) public onlyOwner {
        require(_sale < 10000, "Sale is too much");
        saleBP = _sale;

        emit SaleDiscountChanged(_sale);
    }

    function setSpendingTokenWhiteListed(IBEP20 _token) public onlyOwner {
        if(whiteListedTokens[address(_token)]) {
            return;
        }

        whiteListedTokens[address(_token)] = true;
    }

    function discardSpendingToken(IBEP20 _token) public onlyOwner {
        whiteListedTokens[address(_token)] = false;
    }

    function toggleSaleStatus() public onlyOwner {
        saleActive = !saleActive;
    }

    function setClaimTime(uint256 _time) public onlyOwner {
        claimTime = _time;

        emit ClaimTimeChanged(_time);
    }

    function setMinAmount(uint256 _amount) public onlyOwner {
        minAmount = _amount;

        emit MinAmountChanged(_amount);
    }

    function setReceiverAddress(address _recv) public onlyOwner {
        receiver = _recv;

        emit ReceiverAddressChanged(_recv);
    }

    function withdrawTokens(uint256 _amount) public onlyOwner {
        token.safeTransfer(msg.sender, _amount);
    }

    function changeSoldAmount(uint256 _newAmount) public onlyOwner {
        soldAmount = _newAmount;
    }

    // modifiers

    modifier onlySaleActive {
        require(saleActive, "Sale is not active.");
        _;
    }

    event SaleDiscountChanged(uint256 discount);
    event ClaimTimeChanged(uint256 time);
    event MinAmountChanged(uint256 amount);
    event ReceiverAddressChanged(address receiver);
    event TokenBought(IBEP20 _spendingToken, uint256 paidAmount, uint256 boughtAmount);
    event TokensClaimed(uint256 amount);
}