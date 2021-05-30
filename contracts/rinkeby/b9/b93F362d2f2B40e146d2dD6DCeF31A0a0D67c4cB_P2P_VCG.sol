/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

pragma solidity >=0.7.0 <0.8.3;
contract P2P_VCG{
    uint public Price;
    uint public Demond;
    address public chairperson;
    struct Bidder {
        bool Authorized;
        bool Paid;
        bytes32 Hash;
        uint Amount;
        uint Bidprice;
        uint final_price;
        uint final_amount;
        uint Index;
        uint _final_amount;
    }
    mapping (address => Bidder) public bidders;
    mapping (address => address) _nextBidder;
    uint public listSize;
    address constant GUARD = address(1);
    constructor (uint demand, uint price) {
        chairperson = msg.sender;
        Demond = demand;
        Price = price*1000000000;
        
        _nextBidder[GUARD] = GUARD;
    }
    function authorize(uint amount) public payable{
        if(msg.value == amount*Price){
            bidders[msg.sender].Authorized = true;
            bidders[msg.sender].Amount = amount;
        }
        else
            payable(msg.sender).transfer(msg.value);
    }
    
    function _verifyIndex(address preBidder, uint newPrice, address nexBidder) internal view returns(bool) {
        return (preBidder == GUARD || bidders[preBidder].Bidprice >= newPrice) && 
               (nexBidder == GUARD || newPrice > bidders[nexBidder].Bidprice);
    }
    function _findIndex(uint newPrice) internal view returns(address candidate) {
        address candidateAddress = GUARD;
        while(true) {
            if(_verifyIndex(candidateAddress, newPrice, _nextBidder[candidateAddress]))
                return candidateAddress;
            candidateAddress = _nextBidder[candidateAddress];
        }
    }
    function addBidHash(bytes32 hash) public{
        require(bidders[msg.sender].Authorized == true);
        bidders[msg.sender].Hash = hash;
    }
    function addBid(uint price, uint extr) public {
        address bidder = msg.sender;
        require(bidders[msg.sender].Hash == keccak256(abi.encode(price, extr)));
        require(_nextBidder[bidder] == address(0) && bidders[bidder].Authorized == true);
        bidders[bidder].Bidprice = price;
        address prebidder = _findIndex(price);
        _nextBidder[bidder] = _nextBidder[prebidder];
        _nextBidder[prebidder] = bidder;
        listSize++;
    }
    function isBidded(address bidder) public view returns(bool) {
        return _nextBidder[bidder] != address(0);
    }
    function getNumber(uint amountofpower) public view returns(uint number) {
        address currentAddress =  _nextBidder[GUARD];
        uint num = 0;
        uint amo = 0;
        while(amo <= amountofpower){
            num += 1;
            amo = amo + bidders[currentAddress].Amount;
            currentAddress = _nextBidder[currentAddress];
        }
        num -= 1;
        return num;
    }
    function getTop(uint k, uint amountofpower) public returns(uint price_all) {
        //address[] memory top = new address[](k+1);
        uint amou = 0;
        uint priceall = 0;
        address currentAddress = _nextBidder[GUARD];
        for(uint a = 0; a < k; a += 1) {
            //top[a] = currentAddress;
            amou += bidders[currentAddress].Amount;
            bidders[currentAddress].final_amount = bidders[currentAddress].Amount;
            bidders[currentAddress].Index = a;
            priceall = priceall + bidders[currentAddress].final_amount * bidders[currentAddress].Bidprice;
            currentAddress = _nextBidder[currentAddress];
        }
        if(amou < amountofpower){
            //top[k] = currentAddress;
            bidders[currentAddress].final_amount = amountofpower-amou;
            bidders[currentAddress].Index = k;
            priceall = priceall + bidders[currentAddress].final_amount * bidders[currentAddress].Bidprice;
        }
        return priceall;
    }
    function _getTop(uint k, uint amountofpower) internal returns(uint price_all) {
        //address[] memory top = new address[](k+1);
        uint amou = 0;
        uint priceall = 0;
        address currentAddress = _nextBidder[GUARD];
        for(uint a = 0; a < k; a += 1) {
            //top[a] = currentAddress;
            amou += bidders[currentAddress].Amount;
            bidders[currentAddress]._final_amount = bidders[currentAddress].Amount;
            bidders[currentAddress].Index = a;
            priceall = priceall + bidders[currentAddress]._final_amount * bidders[currentAddress].Bidprice;
            currentAddress = _nextBidder[currentAddress];
        }
        if(amou < amountofpower){
            //top[k] = currentAddress;
            bidders[currentAddress]._final_amount = amountofpower-amou;
            bidders[currentAddress].Index = k;
            priceall = priceall + bidders[currentAddress]._final_amount * bidders[currentAddress].Bidprice;
        }
        return priceall;
    }
    function VCG(address bidder) public returns(uint finalprice) {
        uint Number1 = getNumber(Demond);
        uint PriceAll_1 = getTop(Number1, Demond);
        uint Number2 = getNumber(Demond + bidders[bidder].Amount);
        uint PriceAll_2 = _getTop(Number2, Demond + bidders[bidder].Amount);
        if(bidders[bidder].final_amount < bidders[bidder].Amount){
            finalprice = PriceAll_2 - PriceAll_1 - 
            (bidders[bidder].Amount-bidders[bidder].final_amount)*bidders[bidder].Bidprice;
        }
        else{
            finalprice = PriceAll_2 - PriceAll_1;
        }
        if(bidders[bidder].final_amount == 0){
            finalprice = 0;
        }
        bidders[bidder].final_price = finalprice;
        return finalprice;
    }
    function pay() public payable {
        if(msg.value == bidders[msg.sender].final_price*1000000000){
            bidders[msg.sender].Paid = true;
        }
        else
            payable(msg.sender).transfer(msg.value);
    }
    fallback ()  payable external {}
    receive () payable external {}
}