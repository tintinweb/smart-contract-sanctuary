pragma solidity ^0.4.0;
contract Chance {
    address owner;
    uint public pot;
    uint SEKU_PRICE;
    uint private _random;
    address[] public participants;
    mapping (address => uint) public sekus;
    mapping (uint => address) public invitation;
    uint public reflink;
    
    event Payout(address target, uint amount, uint nrOfParticipants, uint sekus);
	
    modifier onlyBy(address _account)
    {
        require(msg.sender == _account);
        _;
    }
    
    constructor () public {
        owner = msg.sender;
        pot= address(this).balance;
        SEKU_PRICE=0.001 ether;
    }
	 function setSEKU(uint price) public onlyBy(owner){
        SEKU_PRICE = price* 1 ether;
    }
    function withdrawal()payable public onlyBy(owner){
        terminate();
    }
	
    function getref() constant returns (uint) { 
        return uint32(keccak256(abi.encodePacked(msg.sender)));
    }
    
     function buySEKU(uint amount,uint ref) payable public {
        require(msg.value == amount*SEKU_PRICE && amount>0 && amount<201 );
        bool _ref=false;
        if(ref != 0 && invitation[ref] != msg.sender && sekus[invitation[ref]]>amount){
            _ref=true;
        }
        for (uint i=0; i<amount; i++) {
            participants.push(msg.sender);
            if( _ref==true && (i%4==0)){
                participants.push(invitation[ref]);
        }
    }
        sekus[msg.sender]+=amount;
        reflink=uint32(keccak256(abi.encodePacked(msg.sender)));
        invitation[reflink]= msg.sender;
        pot+=msg.value;
    }
   
    function terminate() private {
        uint totalPayout = pot;
        _random= random();
        uint ownerFee = totalPayout / 10;
        uint payoutToFirstWinner = (totalPayout) / 2;
        uint payoutToSecondWinner = (totalPayout) / 4;
        uint payoutToThirdWinner = (totalPayout)  / 20;
        
        owner.transfer(ownerFee);
        
        uint firstWinnerIndex =  uint(blockhash(block.number-1-_random))  % participants.length;
        address firstWinner = participants[firstWinnerIndex];
        firstWinner.transfer(payoutToFirstWinner);
        emit Payout(firstWinner, payoutToFirstWinner, participants.length,sekus[firstWinner]);
        uint secondWinnerIndex =  uint(blockhash(block.number-2-_random)) % participants.length;
        address secondWinner = participants[secondWinnerIndex];
        while (secondWinner==firstWinner || secondWinner==owner){
            _random+=1;
            secondWinnerIndex =  uint(blockhash(block.number-2-_random)) % participants.length;
            secondWinner = participants[secondWinnerIndex];
        }
        
        secondWinner.transfer(payoutToSecondWinner);
        emit Payout(secondWinner, payoutToSecondWinner, participants.length,sekus[secondWinner]);
        uint thirdWinnerIndex =  uint(blockhash(block.number-3-_random)) % participants.length;
        address thirdWinner = participants[thirdWinnerIndex];
        while (thirdWinner==firstWinner || thirdWinner==secondWinner || secondWinner==owner){
            _random+=1;
            thirdWinnerIndex =  uint(blockhash(block.number-3-_random)) % participants.length;
            thirdWinner = participants[thirdWinnerIndex];
        }
        
        thirdWinner.transfer(payoutToThirdWinner);
        emit Payout(thirdWinner, payoutToThirdWinner, participants.length,sekus[thirdWinner]);
        pot-=(ownerFee+payoutToThirdWinner+payoutToSecondWinner+payoutToFirstWinner);
        delete participants;
    }
      function random() private view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(now, block.difficulty)))%251);
    }
}