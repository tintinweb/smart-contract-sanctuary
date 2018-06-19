pragma solidity 0.4.19;

contract Countout {

    address public owner;
    uint128 public ownerBank;
    uint8 public round;
    uint8 public round_after;
    uint8 public currentCount;
    uint8 public totalCount;
    uint128 public initialPrice = 0.005 ether;
    uint128 public bonusPrice = 0.1 ether;
    uint128 public nextPrice;
    uint128 public sumPrice;
    uint256 public lastTransactionTime;
    address public lastCountAddress;    
    uint8 private randomCount;
    
    address[] public sevenWinnerAddresses;      
    mapping (address => uint128) public addressToBalance;

    event Count(address from, uint8 count);
    event Hit(address from, uint8 count);

    /*** CONSTRUCTOR ***/
    function Countout() public {
        owner = msg.sender;
        _renew();
        _keepLastTransaction();
        //Set randomcount as 10 as pre-sale
        randomCount = 10;
    }

    /*** Owner Action ***/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    function ownerWithdraw() public onlyOwner {
        require (block.timestamp > lastTransactionTime + 7 days); 

        if (round_after < 77 && sevenWinnerAddresses.length > 0){
            uint128 sevensWinnerBack = (ownerBank + sumPrice) / uint8(sevenWinnerAddresses.length) - 0.0000007 ether;
            uint8 i;
            for (i = 0; i < sevenWinnerAddresses.length; i++){
                addressToBalance[sevenWinnerAddresses[i]]  = addressToBalance[sevenWinnerAddresses[i]] + sevensWinnerBack;
            }         
               
        } else {
            owner.transfer(this.balance);
        }
        sumPrice = 0;
        ownerBank = 0;
    }

    function sevenWinnerWithdraw() public {
        require(addressToBalance[msg.sender] > 0);
        msg.sender.transfer(addressToBalance[msg.sender]);
        addressToBalance[msg.sender] = 0;
    }    

    /*** Main Function ***/
    function _payFee(uint128 _price, address _referralAddress) internal returns (uint128 _processing){
        uint128 _cut = _price / 100;
        _processing = _price - _cut;
        if (_referralAddress != address(0)){
            _referralAddress.transfer(_cut);
        } else {    
            ownerBank = ownerBank + _cut;    
        }
        uint8 i;
        for (i = 0; i < sevenWinnerAddresses.length; i++){
            addressToBalance[sevenWinnerAddresses[i]]  = addressToBalance[sevenWinnerAddresses[i]] + _cut;
            _processing = _processing - _cut;
        }

        uint128 _remaining = (7 - uint8(sevenWinnerAddresses.length)) * _cut;
        ownerBank = ownerBank + _remaining;
        _processing = _processing - _remaining;
    }

    function _renew() internal{
        round++;
        if (sevenWinnerAddresses.length == 7){
            round_after++;
        }
        currentCount = 0;
        nextPrice = initialPrice;

        randomCount = uint8(block.blockhash(block.number-randomCount))%10 + 1;

        if(randomCount >= 7){
            randomCount = uint8(block.blockhash(block.number-randomCount-randomCount))%10 + 1;  
        }
        
        if (sevenWinnerAddresses.length < 7 && randomCount == 7){
            randomCount++;
        }         

    }

    function _keepLastTransaction() internal{
        lastTransactionTime = block.timestamp;
        lastCountAddress = msg.sender;
    }

    function countUp(address _referralAddress) public payable {
        require (block.timestamp < lastTransactionTime + 7 days);    
        require (msg.value == nextPrice); 

        uint128 _price = uint128(msg.value);
        uint128 _processing;
      
        totalCount++;
        currentCount++; 

        _processing = _payFee(_price, _referralAddress);     
        
        if (currentCount > 1) {
            lastCountAddress.transfer(_processing);
        } else {
            sumPrice = sumPrice + _processing;
        }

        if (currentCount == randomCount) {
            Hit(msg.sender, currentCount);
            _renew(); 

        } else {
            if (currentCount == 7) {
                if (sevenWinnerAddresses.length < 7){
                    sevenWinnerAddresses.push(msg.sender);
                } else {

                    if (sumPrice <= bonusPrice) {
                        msg.sender.transfer(sumPrice);
                        sumPrice = 0;
                    } else {
                        msg.sender.transfer(bonusPrice);
                        sumPrice = sumPrice - bonusPrice;
                   }
                }
                _renew();
            } else {
                nextPrice = nextPrice * 3/2;
            }   

            Count(msg.sender, currentCount);            
        }
        _keepLastTransaction(); 
    }

}