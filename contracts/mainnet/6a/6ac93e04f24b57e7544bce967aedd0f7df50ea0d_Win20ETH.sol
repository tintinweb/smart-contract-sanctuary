pragma solidity ^0.4.23;

contract Win20ETH {


    struct Comissions{
        uint total;
        uint referal;
        uint nextJackpot;
    }

    uint adminComission;

    Comissions comission;

    uint ticketPrice;
    uint blockOffset;
    uint jackpot;

    address owner;
    mapping(address => uint) referalProfits;
    address[] referals;

    mapping(uint => Game) games;

	event PurchaseError(address oldOwner, uint amount);

	struct Game{
	    uint blockId;
	    address[] gamers;
	    mapping(address=>bool) pays;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	/**
	 * @dev Sets owner and default lottery params
	 */
	constructor() public {
		owner = msg.sender;
		updateParams(0.005 ether, 1, 10, 5, 1);
		adminComission =0;

	}
	function withdrawAdmin() public onlyOwner{
	    require(adminComission>0);
	    uint t = adminComission;
	    adminComission = 0;
	    owner.transfer(t);


	}
	function updateParams(
		uint _ticketPrice,
		uint _blockOffset,
		uint _total,
		uint _refPercent,
		uint _nextJackpotPercent

	) public onlyOwner {
		ticketPrice = _ticketPrice;
		comission.total = _total;
		comission.referal = _refPercent;
		comission.nextJackpot =  _nextJackpotPercent;
		blockOffset = _blockOffset;

	}



    function buyTicketWithRef(address _ref) public payable{
       require(msg.value == ticketPrice);
       bool found = false;
       for(uint i=0; i< games[block.number+blockOffset].gamers.length;i++){
        	      if( msg.sender == games[block.number+blockOffset].gamers[i]){
        	        found = true;
        	        break;
        	      }
        	    }
        	    require(found == false);
	    jackpot+=msg.value;
	    games[block.number+blockOffset].gamers.push(msg.sender);
	    games[block.number+blockOffset].pays[msg.sender] = false;
	    if( _ref != address(0) && comission.referal>0){
	        referalProfits[_ref]+= msg.value*comission.referal/100;
	        bool _found = false;
	        for(i = 0;i<referals.length;i++){
	            if( referals[i] == _ref){
	                _found=true;
	                break;
	            }
	        }
	        if(!_found){
	            referals.push(_ref);
	        }
	    }
    }
	function buyTicket() public payable {

	    require(msg.value == ticketPrice);
	    bool found = false;
	    for(uint i=0; i< games[block.number+blockOffset].gamers.length;i++){
	      if( msg.sender == games[block.number+blockOffset].gamers[i]){
	        found = true;
	        break;
	      }
	    }
	    require(found == false);
	    jackpot+=msg.value;
	    games[block.number+blockOffset].gamers.push(msg.sender);
	    games[block.number+blockOffset].pays[msg.sender] = false;


	}


	function getLotteryAtIndex(uint _index) public view returns(
		address[] _gamers,
		uint _jackpot
	) {
        _gamers = games[_index].gamers;
        _jackpot = jackpot;
	}
    function _checkWin( uint _blockIndex, address candidate) internal view returns(uint) {
            uint32 blockHash = uint32(blockhash(_blockIndex));
            uint32 hit = blockHash ^ uint32(candidate);
            bool hit1 = (hit & 0xF == 0)?true:false;
            bool hit2 = (hit1 && ((hit & 0xF0)==0))?true:false;
            bool hit3 = (hit2 && ((hit & 0xF00)==0))?true:false;
            bool _found  = false;

            for(uint i=0;i<games[_blockIndex].gamers.length;i++){
                if(games[_blockIndex].gamers[i] == candidate) {
                    _found = true;
                }
            }
            if(!_found) return 0;
            uint amount = 0;
            if ( hit1 ) amount = 2*ticketPrice;
            if ( hit2 ) amount = 4*ticketPrice;
            if ( hit3 ) amount = jackpot;
            return amount;


    }
    function checkWin( uint _blockIndex, address candidate) public view returns(
        uint amount
        ){
            amount = _checkWin(_blockIndex, candidate);
        }




	function withdrawForWinner(uint _blockIndex) public {
	    require((block.number - 100) < _blockIndex );
		require(games[_blockIndex].gamers.length > 0);
		require(games[_blockIndex].pays[msg.sender]==false);

		uint amount =  _checkWin(_blockIndex, msg.sender) ;
		require(amount>0);

		address winner = msg.sender;
		if( amount > jackpot) amount=jackpot;
		if( amount == jackpot) amount = amount*99/100;
		
		games[_blockIndex].pays[msg.sender] = true;

		uint winnerSum = amount*(100-comission.total)/100;
		uint techSum = amount-winnerSum;

		winner.transfer( winnerSum );
		for(uint i=0;i<referals.length;i++){
		    if( referalProfits[referals[i]]>0 && referalProfits[referals[i]]<techSum){
		        referals[i].transfer( referalProfits[referals[i]]);
		        techSum -= referalProfits[referals[i]];
		        referalProfits[referals[i]] = 0;
		 }
		}
		if( techSum > 0){
		  owner.transfer(techSum);
		}
		jackpot = jackpot-amount;




	}
	function getJackpot() public view returns(uint){
	    return jackpot;
	}
	function getAdminComission() public view returns(uint){
	    return adminComission;
	}

    function balanceOf(address _user) public view returns(uint) {
		return referalProfits[_user];
    }

	/**
	 * @dev Disallow users to send ether directly to the contract
	 */
	function() public payable {
	    if( msg.sender != owner){
	        revert();
	    }
	    jackpot += msg.value;
	}


}