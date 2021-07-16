//SourceUnit: DigiLotto_V2.sol

pragma solidity 0.5.9;

contract DigiLotto {
    address private ownerWallet;

    bool private SignupPause = true;
	bool private TJPPause = true;
	bool private FreeBetPromotion = true;
	uint private currUserID = 0;
    uint private currBet2DID = 0;	
	uint private currBet3DID = 0;	
	uint private currBet4DID = 0;	
    uint private currDraw2DID = 0;
	uint private currDraw3DID = 0;
	uint private currDraw4DID = 0;
	uint private currDrawNumber =0;
    uint private currDrawDate =0;
	uint private currBetDrawDate = 0;
	uint private currBetCloseDate = 0;
	uint private currBetDrawNumber = 0;
	uint private currBetNumber =0;
	uint private currBetNumber1 =0;
	uint private currBetNumber2 =0;
	uint private currBetNumber3 =0;
	uint private currBetNumber4 =0;
	uint private currBetQuantity=0;
	uint private currBetUserID=0;
	string private currBetType="";	
	uint private currFreeBet2DID;
	uint private currFreeBet3DID;
	uint private currFreeBet4DID;
		
	struct DrawStruct{
		bool isExist;
        uint drawno;
        uint drawbetdue;
		string bettype;
	}
	
	struct FreeBetStruct{
		bool isExist;	
	}
	
	struct UserStruct {
        bool isExist;
        uint userid;
        uint referrerID;
    }

    struct BetStruct{
	    bool isExist;
		bool isDirect;
		bool isPermutation;
		bool isRollFront;
		bool isRollBack;
		uint drawnumber;
		uint betid;
		uint betuserid;
        string bettype;
		uint betnumber;
		uint betqty;
	}
	
	mapping(address => UserStruct) public users;
    mapping(uint => address) public userList;
	mapping(address => BetStruct) public bets2D;
	mapping(uint => address) public betList2D;
	mapping(uint => BetStruct) public betDetail2D;	
	mapping(address => BetStruct) public bets3D;
	mapping(uint => address) public betList3D;
	mapping(uint => BetStruct) public betDetail3D;	
	mapping(address => BetStruct) public bets4D;
	mapping(uint => address) public betList4D;
	mapping(uint => BetStruct) public betDetail4D;	
    mapping(uint => DrawStruct) public draws2D;
	mapping(uint => DrawStruct) public draws3D;
	mapping(uint => DrawStruct) public draws4D;
	mapping(address => FreeBetStruct) public freebet2D;
	mapping(address => FreeBetStruct) public freebet3D;
	mapping(address => FreeBetStruct) public freebet4D;
	
	uint singlebet_price = 50 trx;
    
    event adduser(address indexed _user, uint _userid, uint _referrerid, uint _time);
	event addbet(address indexed _user, uint _userid, uint _drawnumber, uint _betid, string _bettype, uint _betnumber, uint _betqty, uint _betamount, bool isDirect, bool isPermutation, bool isRollFront, bool isRollBack, uint _time);
	event adddraw(uint  indexed _drawnumber, uint _drawdate, string _bettype, uint _time);
    event addtokenreceive(uint indexed _userid, uint ContractBalance, uint _time);
	
    UserStruct[] private requests;
    
    constructor() public {
        ownerWallet = msg.sender;    

		UserStruct memory userStruct;
        currUserID++;
        userStruct = UserStruct({
            isExist: true,
            userid: currUserID,
            referrerID: 0
        });
        users[ownerWallet] = userStruct;
        userList[currUserID] = ownerWallet;
        emit adduser(msg.sender, currUserID, 0, now);
    
    }
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//SIGN UP
//	
    
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
function SignUp(uint _referrerID) public {
		require(!(SignupPause),"Sign Up Been Paused");
        require(!users[msg.sender].isExist, "Address Already Exists");
		
        UserStruct memory userStruct;
        currUserID++;
        userStruct = UserStruct({
            isExist: true,
            userid: currUserID,
            referrerID: _referrerID
        });
        users[msg.sender] = userStruct;
        userList[currUserID] = msg.sender;   
      
        emit adduser(msg.sender, currUserID, _referrerID, now);
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//DIRECT BET 
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
function FreeBet2D(uint _drawnumber, uint _betnumber1, uint _betnumber2) public {
		require(FreeBetPromotion,"Free Bet Promotion Ended");
		require(bets2D[msg.sender].isExist  , "You Need To Have Minimum 1 Paid Bet Before Can Redeem Free Bet");
		require(!freebet2D[msg.sender].isExist  , "Free Bet Already Redeemed");
		require(((!(SignupPause) && users[msg.sender].isExist) || !(TJPPause)), "Please Sign Up First");
		require(draws2D[_drawnumber].isExist, 'Invalid Draw');
		currBetCloseDate = draws2D[_drawnumber].drawbetdue ;
		require(currBetCloseDate > now, 'Draw Closed');
		require(_betnumber1 >= 0 && _betnumber1 <= 9 && _betnumber2 >= 0 && _betnumber2 <= 9 , 'Incorrect Bet Number');
		
		currBetNumber1 = _betnumber1;
		currBetNumber2 = _betnumber2;
		currBetNumber = currBetNumber1*10 + currBetNumber2*1;
		
		currBetQuantity = 1;
		currBetUserID = users[msg.sender].userid;
		currBetDrawNumber= _drawnumber;
		
		BetStruct memory betStruct;
        currBet2DID++;
        betStruct = BetStruct({
			isExist: true,
			isDirect: true,
            isPermutation: false,
			isRollFront: false,
			isRollBack: false,
			drawnumber: currBetDrawNumber,
            betid: currBet2DID,
			betuserid: currBetUserID,
			bettype: "2D",
			betnumber: currBetNumber,
			betqty: 1
        });
        bets2D[msg.sender] = betStruct;
        betList2D[currBet2DID] = msg.sender;
		betDetail2D[currBet2DID] = betStruct;	
		emit addbet(msg.sender, currBetUserID, currBetDrawNumber, currBet2DID, "2D", currBetNumber, 1, 0 , true, false, false, false, now);
		
		FreeBetStruct memory freebetStruct;
        currFreeBet2DID++;
        freebetStruct = FreeBetStruct({
			isExist: true
        });
        freebet2D[msg.sender] = freebetStruct;
}

function FreeBet3D(uint _drawnumber, uint _betnumber1, uint _betnumber2, uint _betnumber3) public {
		require(FreeBetPromotion,"Free Bet Promotion Ended");
		require(bets3D[msg.sender].isExist  , "You Need To Have Minimum 1 Paid Bet Before Can Redeem Free Bet");
		require(!freebet3D[msg.sender].isExist  , "Free Bet Already Redeemed");
		require(((!(SignupPause) && users[msg.sender].isExist) || !(TJPPause)), "Please Sign Up First");
		require(draws3D[_drawnumber].isExist, 'Invalid Draw');
		currBetCloseDate = draws3D[_drawnumber].drawbetdue ;
		require(currBetCloseDate > now, 'Draw Closed');
		require(_betnumber1 >= 0 && _betnumber1 <= 9 && _betnumber2 >= 0 && _betnumber2 <= 9 && _betnumber3 >= 0 && _betnumber3 <= 9 , 'Incorrect Bet Number');
		
		currBetNumber1 = _betnumber1;
		currBetNumber2 = _betnumber2;
		currBetNumber3 = _betnumber3;
		currBetNumber = currBetNumber1*100 + currBetNumber2*10 + currBetNumber3*1;
		
		currBetQuantity = 1;
		currBetUserID = users[msg.sender].userid;
		currBetDrawNumber= _drawnumber;
		
		BetStruct memory betStruct;
        currBet3DID++;
        betStruct = BetStruct({
			isExist: true,
            isDirect: true,
			isPermutation: false,
			isRollFront: false,
			isRollBack: false,
			drawnumber: currBetDrawNumber,
            betid: currBet3DID,
			betuserid: currBetUserID,
			bettype: "3D",
			betnumber: currBetNumber,
			betqty: 1
        });
        bets3D[msg.sender] = betStruct;
        betList3D[currBet3DID] = msg.sender;
		betDetail3D[currBet3DID] = betStruct;				
		emit addbet(msg.sender, currBetUserID, currBetDrawNumber, currBet3DID, "3D", currBetNumber, 1, 0 , true, false, false, false, now);
		
		FreeBetStruct memory freebetStruct;
        currFreeBet3DID++;
        freebetStruct = FreeBetStruct({
			isExist: true
        });
        freebet3D[msg.sender] = freebetStruct;
}

function FreeBet4D(uint _drawnumber, uint _betnumber1, uint _betnumber2, uint _betnumber3, uint _betnumber4) public {
		require(FreeBetPromotion,"Free Bet Promotion Ended");
		require(bets4D[msg.sender].isExist  , "You Need To Have Minimum 1 Paid Bet Before Can Redeem Free Bet");
		require(!freebet4D[msg.sender].isExist  , "Free Bet Already Redeemed");
		require(((!(SignupPause) && users[msg.sender].isExist) || !(TJPPause)), "Please Sign Up First");
		require(draws4D[_drawnumber].isExist, 'Invalid Draw');
		currBetCloseDate = draws4D[_drawnumber].drawbetdue ;
		require(currBetCloseDate > now, 'Draw Closed');
		require(_betnumber1 >= 0 && _betnumber1 <= 9 && _betnumber2 >= 0 && _betnumber2 <= 9 && _betnumber3 >= 0 && _betnumber3 <= 9 && _betnumber4 >= 0 && _betnumber4 <= 9 , 'Incorrect Bet Number');
		
		
		currBetNumber1 = _betnumber1;
		currBetNumber2 = _betnumber2;
		currBetNumber3 = _betnumber3;
		currBetNumber4 = _betnumber4;
		currBetNumber = currBetNumber1*1000 + currBetNumber2*100 + currBetNumber3*10 + currBetNumber4*1 ;
		
		currBetQuantity = 1;
		currBetUserID = users[msg.sender].userid;
		currBetDrawNumber= _drawnumber;
		
		BetStruct memory betStruct;
        currBet4DID++;
        betStruct = BetStruct({
			isExist: true,
            isDirect: true,
			isPermutation: false,
			isRollFront: false,
			isRollBack: false,
			drawnumber: currBetDrawNumber,
            betid: currBet4DID,
			betuserid: currBetUserID,
			bettype: "4D",
			betnumber: currBetNumber,
			betqty: 1
        });
        bets4D[msg.sender] = betStruct;
        betList4D[currBet4DID] = msg.sender;
		betDetail4D[currBet4DID] = betStruct;				
		emit addbet(msg.sender, currBetUserID, currBetDrawNumber, currBet4DID, "4D", currBetNumber, 1, 0 , true, false, false, false, now);
		
		FreeBetStruct memory freebetStruct;
        currFreeBet4DID++;
        freebetStruct = FreeBetStruct({
			isExist: true
        });
        freebet4D[msg.sender] = freebetStruct;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//DIRECT BET 
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
function DirectBet2D(uint _drawnumber, uint _betnumber1, uint _betnumber2, uint _betqty) public payable {
		require(((!(SignupPause) && users[msg.sender].isExist) || !(TJPPause)), "Please Sign Up First");
		require(draws2D[_drawnumber].isExist, 'Invalid Draw');
		currBetCloseDate = draws2D[_drawnumber].drawbetdue ;
		require(currBetCloseDate > now, 'Draw Closed');
		require(_betnumber1 >= 0 && _betnumber1 <= 9 && _betnumber2 >= 0 && _betnumber2 <= 9 , 'Incorrect Bet Number');
		require(msg.value == singlebet_price * _betqty, 'Incorrect Amount');  
		
		currBetNumber1 = _betnumber1;
		currBetNumber2 = _betnumber2;
		currBetNumber = currBetNumber1*10 + currBetNumber2*1;
		
		currBetQuantity = _betqty;
		currBetUserID = users[msg.sender].userid;
		currBetDrawNumber= _drawnumber;
		
		BetStruct memory betStruct;
        currBet2DID++;
        betStruct = BetStruct({
			isExist: true,
			isDirect: true,
            isPermutation: false,
			isRollFront: false,
			isRollBack: false,
			drawnumber: currBetDrawNumber,
            betid: currBet2DID,
			betuserid: currBetUserID,
			bettype: "2D",
			betnumber: currBetNumber,
			betqty: currBetQuantity
        });
        bets2D[msg.sender] = betStruct;
        betList2D[currBet2DID] = msg.sender;
		betDetail2D[currBet2DID] = betStruct;			
		emit addbet(msg.sender, currBetUserID, currBetDrawNumber, currBet2DID, "2D", currBetNumber, currBetQuantity, currBetQuantity * 50 , true, false, false, false, now);
		
		sendBalance(currBetUserID);
}

function DirectBet3D(uint _drawnumber, uint _betnumber1, uint _betnumber2, uint _betnumber3, uint _betqty) public payable {
		require(((!(SignupPause) && users[msg.sender].isExist) || !(TJPPause)), "Please Sign Up First");
		require(draws3D[_drawnumber].isExist, 'Invalid Draw');
		currBetCloseDate = draws3D[_drawnumber].drawbetdue ;
		require(currBetCloseDate > now, 'Draw Closed');
		require(_betnumber1 >= 0 && _betnumber1 <= 9 && _betnumber2 >= 0 && _betnumber2 <= 9 && _betnumber3 >= 0 && _betnumber3 <= 9 , 'Incorrect Bet Number');
		require(msg.value == singlebet_price * _betqty, 'Incorrect Amount');  
		
		currBetNumber1 = _betnumber1;
		currBetNumber2 = _betnumber2;
		currBetNumber3 = _betnumber3;
		currBetNumber = currBetNumber1*100 + currBetNumber2*10 + currBetNumber3*1;
		
		currBetQuantity = _betqty;
		currBetUserID = users[msg.sender].userid;
		currBetDrawNumber= _drawnumber;
		
		BetStruct memory betStruct;
        currBet3DID++;
        betStruct = BetStruct({
			isExist: true,
            isDirect: true,
			isPermutation: false,
			isRollFront: false,
			isRollBack: false,
			drawnumber: currBetDrawNumber,
            betid: currBet3DID,
			betuserid: currBetUserID,
			bettype: "3D",
			betnumber: currBetNumber,
			betqty: currBetQuantity
        });
        bets3D[msg.sender] = betStruct;
        betList3D[currBet3DID] = msg.sender;
		betDetail3D[currBet3DID] = betStruct;				
		emit addbet(msg.sender, currBetUserID, currBetDrawNumber, currBet3DID, "3D", currBetNumber, currBetQuantity, currBetQuantity * 50 , true, false, false, false, now);
		
		sendBalance(currBetUserID);
}

function DirectBet4D(uint _drawnumber, uint _betnumber1, uint _betnumber2, uint _betnumber3, uint _betnumber4, uint _betqty) public payable {
		require(((!(SignupPause) && users[msg.sender].isExist) || !(TJPPause)), "Please Sign Up First");
		require(draws4D[_drawnumber].isExist, 'Invalid Draw');
		currBetCloseDate = draws4D[_drawnumber].drawbetdue ;
		require(currBetCloseDate > now, 'Draw Closed');
		require(_betnumber1 >= 0 && _betnumber1 <= 9 && _betnumber2 >= 0 && _betnumber2 <= 9 && _betnumber3 >= 0 && _betnumber3 <= 9 && _betnumber4 >= 0 && _betnumber4 <= 9 , 'Incorrect Bet Number');
		require(msg.value == singlebet_price * _betqty, 'Incorrect Amount');  
		
		currBetNumber1 = _betnumber1;
		currBetNumber2 = _betnumber2;
		currBetNumber3 = _betnumber3;
		currBetNumber4 = _betnumber4;
		currBetNumber = currBetNumber1*1000 + currBetNumber2*100 + currBetNumber3*10 + currBetNumber4*1 ;
		
		currBetQuantity = _betqty;
		currBetUserID = users[msg.sender].userid;
		currBetDrawNumber= _drawnumber;
		
		BetStruct memory betStruct;
        currBet4DID++;
        betStruct = BetStruct({
			isExist: true,
            isDirect: true,
			isPermutation: false,
			isRollFront: false,
			isRollBack: false,
			drawnumber: currBetDrawNumber,
            betid: currBet4DID,
			betuserid: currBetUserID,
			bettype: "4D",
			betnumber: currBetNumber,
			betqty: currBetQuantity
        });
        bets4D[msg.sender] = betStruct;
        betList4D[currBet4DID] = msg.sender;
		betDetail4D[currBet4DID] = betStruct;				
		emit addbet(msg.sender, currBetUserID, currBetDrawNumber, currBet4DID, "4D", currBetNumber, currBetQuantity, currBetQuantity * 50 , true, false, false, false, now);
		
		sendBalance(currBetUserID);
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//ROLL FRONT BET 
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
function RollFrontBet2D(uint _drawnumber, uint _betnumber1, uint _betqty) public payable {
		require(((!(SignupPause) && users[msg.sender].isExist) || !(TJPPause)), "Please Sign Up First");
		require(draws2D[_drawnumber].isExist, 'Invalid Draw');
		currBetCloseDate = draws2D[_drawnumber].drawbetdue ;
		require(currBetCloseDate > now, 'Draw Closed');
		require(_betnumber1 >= 0 && _betnumber1 <= 9, 'Incorrect Bet Number');
		require(msg.value == singlebet_price * _betqty * 10, 'Incorrect Amount');  
		
		currBetNumber = _betnumber1;
		currBetQuantity = _betqty;
		currBetUserID = users[msg.sender].userid;
		currBetDrawNumber= _drawnumber;
		
		BetStruct memory betStruct;
        currBet2DID++;
        betStruct = BetStruct({
			isExist: true,
			isDirect: false,
            isPermutation: false,
			isRollFront: true,
			isRollBack: false,
			drawnumber: currBetDrawNumber,
            betid: currBet2DID,
			betuserid: currBetUserID,
			bettype: "2D",
			betnumber: currBetNumber,
			betqty: currBetQuantity
        });
        bets2D[msg.sender] = betStruct;
        betList2D[currBet2DID] = msg.sender;
		betDetail2D[currBet2DID] = betStruct;				
		emit addbet(msg.sender, currBetUserID, currBetDrawNumber, currBet2DID, "2D", currBetNumber, currBetQuantity, currBetQuantity * 10 * 50 , false, false, true, false, now);
		
		sendBalance(currBetUserID);
}

function RollFrontBet3D(uint _drawnumber, uint _betnumber1, uint _betnumber2, uint _betqty) public payable {
		require(((!(SignupPause) && users[msg.sender].isExist) || !(TJPPause)), "Please Sign Up First");
		require(draws3D[_drawnumber].isExist, 'Invalid Draw');
		currBetCloseDate = draws3D[_drawnumber].drawbetdue ;
		require(currBetCloseDate > now, 'Draw Closed');
		require(_betnumber1 >= 0 && _betnumber1 <= 9 && _betnumber2 >= 0 && _betnumber2 <= 9, 'Incorrect Bet Number');
		require(msg.value == singlebet_price * _betqty * 10, 'Incorrect Amount');  
		
		currBetNumber = _betnumber1 * 10 + _betnumber2 * 1;
		currBetQuantity = _betqty;
		currBetUserID = users[msg.sender].userid;
		currBetDrawNumber= _drawnumber;
		
		BetStruct memory betStruct;
        currBet3DID++;
        betStruct = BetStruct({
			isExist: true,
			isDirect: false,
            isPermutation: false,
			isRollFront: true,
			isRollBack: false,
			drawnumber: currBetDrawNumber,
            betid: currBet3DID,
			betuserid: currBetUserID,
			bettype: "3D",
			betnumber: currBetNumber,
			betqty: currBetQuantity
        });
        bets3D[msg.sender] = betStruct;
        betList3D[currBet3DID] = msg.sender;
		betDetail3D[currBet3DID] = betStruct;				
		emit addbet(msg.sender, currBetUserID, currBetDrawNumber, currBet3DID, "3D", currBetNumber, currBetQuantity, currBetQuantity * 10 * 50 , false, false, true, false, now);
		
		sendBalance(currBetUserID);
}

function RollFrontBet4D(uint _drawnumber, uint _betnumber1, uint _betnumber2, uint _betnumber3, uint _betqty) public payable {
		require(((!(SignupPause) && users[msg.sender].isExist) || !(TJPPause)), "Please Sign Up First");
		require(draws4D[_drawnumber].isExist, 'Invalid Draw');
		currBetCloseDate = draws4D[_drawnumber].drawbetdue ;
		require(currBetCloseDate > now, 'Draw Closed');
		require(_betnumber1 >= 0 && _betnumber1 <= 9 && _betnumber2 >= 0 && _betnumber2 <= 9 && _betnumber3 >= 0 && _betnumber3 <= 9, 'Incorrect Bet Number');
		require(msg.value == singlebet_price * _betqty * 10, 'Incorrect Amount');  
		
		currBetNumber = _betnumber1 * 100 + _betnumber2 * 10 + _betnumber3 * 1 ;
		currBetQuantity = _betqty;
		currBetUserID = users[msg.sender].userid;
		currBetDrawNumber= _drawnumber;
		
		BetStruct memory betStruct;
        currBet4DID++;
        betStruct = BetStruct({
			isExist: true,
			isDirect: false,
            isPermutation: false,
			isRollFront: true,
			isRollBack: false,
			drawnumber: currBetDrawNumber,
            betid: currBet4DID,
			betuserid: currBetUserID,
			bettype: "4D",
			betnumber: currBetNumber,
			betqty: currBetQuantity
        });
        bets4D[msg.sender] = betStruct;
        betList4D[currBet4DID] = msg.sender;
		betDetail4D[currBet4DID] = betStruct;				
		emit addbet(msg.sender, currBetUserID, currBetDrawNumber, currBet4DID, "4D", currBetNumber, currBetQuantity, currBetQuantity * 10 * 50 , false, false, true, false, now);
		
		sendBalance(currBetUserID);
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//ROLL BACK BET 
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
function RollBackBet2D(uint _drawnumber, uint _betnumber1, uint _betqty) public payable {
		require(((!(SignupPause) && users[msg.sender].isExist) || !(TJPPause)), "Please Sign Up First");
		require(draws2D[_drawnumber].isExist, 'Invalid Draw');
		currBetCloseDate = draws2D[_drawnumber].drawbetdue ;
		require(currBetCloseDate > now, 'Draw Closed');
		require(_betnumber1 >= 0 && _betnumber1 <= 9, 'Incorrect Bet Number');
		require(msg.value == singlebet_price * _betqty * 10, 'Incorrect Amount');  
		
		currBetNumber = _betnumber1;
		currBetQuantity = _betqty;
		currBetUserID = users[msg.sender].userid;
		currBetDrawNumber= _drawnumber;
		
		BetStruct memory betStruct;
        currBet2DID++;
        betStruct = BetStruct({
			isExist: true,
			isDirect: false,
            isPermutation: false,
			isRollFront: false,
			isRollBack: true,
			drawnumber: currBetDrawNumber,
            betid: currBet2DID,
			betuserid: currBetUserID,
			bettype: "2D",
			betnumber: currBetNumber,
			betqty: currBetQuantity
        });
        bets2D[msg.sender] = betStruct;
        betList2D[currBet2DID] = msg.sender;
		betDetail2D[currBet2DID] = betStruct;				
		emit addbet(msg.sender, currBetUserID, currBetDrawNumber, currBet2DID, "2D", currBetNumber, currBetQuantity, currBetQuantity * 10 * 50 , false, false, false, true, now);
		
		sendBalance(currBetUserID);
}

function RollBackBet3D(uint _drawnumber, uint _betnumber1, uint _betnumber2, uint _betqty) public payable {
		require(((!(SignupPause) && users[msg.sender].isExist) || !(TJPPause)), "Please Sign Up First");
		require(draws3D[_drawnumber].isExist, 'Invalid Draw');
		currBetCloseDate = draws3D[_drawnumber].drawbetdue ;
		require(currBetCloseDate > now, 'Draw Closed');
		require(_betnumber1 >= 0 && _betnumber1 <= 9 && _betnumber2 >= 0 && _betnumber2 <= 9, 'Incorrect Bet Number');
		require(msg.value == singlebet_price * _betqty * 10, 'Incorrect Amount');  
		
		currBetNumber = _betnumber1 * 10 + _betnumber2 * 1;
		currBetQuantity = _betqty;
		currBetUserID = users[msg.sender].userid;
		currBetDrawNumber= _drawnumber;
		
		BetStruct memory betStruct;
        currBet3DID++;
        betStruct = BetStruct({
			isExist: true,
			isDirect: false,
            isPermutation: false,
			isRollFront: false,
			isRollBack: true,
			drawnumber: currBetDrawNumber,
            betid: currBet3DID,
			betuserid: currBetUserID,
			bettype: "3D",
			betnumber: currBetNumber,
			betqty: currBetQuantity
        });
        bets3D[msg.sender] = betStruct;
        betList3D[currBet3DID] = msg.sender;
		betDetail3D[currBet3DID] = betStruct;				
		emit addbet(msg.sender, currBetUserID, currBetDrawNumber, currBet3DID, "3D", currBetNumber, currBetQuantity, currBetQuantity * 10 * 50 , false, false, false, true, now);
		
		sendBalance(currBetUserID);
}

function RollBackBet4D(uint _drawnumber, uint _betnumber1, uint _betnumber2, uint _betnumber3, uint _betqty) public payable {
		require(((!(SignupPause) && users[msg.sender].isExist) || !(TJPPause)), "Please Sign Up First");
		require(draws4D[_drawnumber].isExist, 'Invalid Draw');
		currBetCloseDate = draws4D[_drawnumber].drawbetdue ;
		require(currBetCloseDate > now, 'Draw Closed');
		require(_betnumber1 >= 0 && _betnumber1 <= 9 && _betnumber2 >= 0 && _betnumber2 <= 9 && _betnumber3 >= 0 && _betnumber3 <= 9, 'Incorrect Bet Number');
		require(msg.value == singlebet_price * _betqty * 10, 'Incorrect Amount');  
		
		currBetNumber = _betnumber1 * 100 + _betnumber2 * 10 + _betnumber3 * 1 ;
		currBetQuantity = _betqty;
		currBetUserID = users[msg.sender].userid;
		currBetDrawNumber= _drawnumber;
		
		BetStruct memory betStruct;
        currBet4DID++;
        betStruct = BetStruct({
			isExist: true,
			isDirect: false,
            isPermutation: false,
			isRollFront: false,
			isRollBack: true,
			drawnumber: currBetDrawNumber,
            betid: currBet4DID,
			betuserid: currBetUserID,
			bettype: "4D",
			betnumber: currBetNumber,
			betqty: currBetQuantity
        });
        bets4D[msg.sender] = betStruct;
        betList4D[currBet4DID] = msg.sender;
		betDetail4D[currBet4DID] = betStruct;				
		emit addbet(msg.sender, currBetUserID, currBetDrawNumber, currBet4DID, "4D", currBetNumber, currBetQuantity, currBetQuantity * 10 * 50 , false, false, false, true, now);
		
		sendBalance(currBetUserID);
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//PERMUTATION BET 
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
function PermutationBet3D_3(uint _drawnumber, uint _betnumber1, uint _betnumber2, uint _betnumber3, uint _betqty) public payable {
		require(((!(SignupPause) && users[msg.sender].isExist) || !(TJPPause)), "Please Sign Up First");
		require(draws3D[_drawnumber].isExist, 'Invalid Draw');
		currBetCloseDate = draws3D[_drawnumber].drawbetdue ;
		require(currBetCloseDate > now, 'Draw Closed');
		require(_betnumber1 >= 0 && _betnumber1 <= 9 && _betnumber2 >= 0 && _betnumber2 <= 9 && _betnumber3 >= 0 && _betnumber3 <= 9, 'Incorrect Bet Number');
		require((_betnumber1 != _betnumber2 && _betnumber2 == _betnumber3) || (_betnumber1 != _betnumber2 && _betnumber1 == _betnumber3) || (_betnumber1 != _betnumber3 && _betnumber1 == _betnumber2) , 'Incorrect Bet Number');
		require(msg.value == singlebet_price * _betqty * 3, 'Incorrect Amount');  
		
		currBetNumber = _betnumber1 * 100 + _betnumber2 * 10 + _betnumber3 * 1 ;
		currBetQuantity = _betqty;
		currBetUserID = users[msg.sender].userid;
		currBetDrawNumber= _drawnumber;
		
		BetStruct memory betStruct;
        currBet3DID++;
        betStruct = BetStruct({
			isExist: true,
            isDirect: false,
            isPermutation: true,
			isRollFront: false,
			isRollBack: false,
			drawnumber: currBetDrawNumber,
            betid: currBet3DID,
			betuserid: currBetUserID,
			bettype: "3D",
			betnumber: currBetNumber,
			betqty: currBetQuantity
        });
        bets3D[msg.sender] = betStruct;
        betList3D[currBet3DID] = msg.sender;
		betDetail3D[currBet3DID] = betStruct;		
		
		emit addbet(msg.sender, currBetUserID, currBetDrawNumber, currBet3DID, "3D", currBetNumber, currBetQuantity, currBetQuantity * 3 * 50 , false, true, false, false, now);
		sendBalance(currBetUserID);
}

function PermutationBet3D_6(uint _drawnumber, uint _betnumber1, uint _betnumber2, uint _betnumber3, uint _betqty) public payable {
		require(((!(SignupPause) && users[msg.sender].isExist) || !(TJPPause)), "Please Sign Up First");
		require(draws3D[_drawnumber].isExist, 'Invalid Draw');
		currBetCloseDate = draws3D[_drawnumber].drawbetdue ;
		require(currBetCloseDate > now, 'Draw Closed');
		require(_betnumber1 >= 0 && _betnumber1 <= 9 && _betnumber2 >= 0 && _betnumber2 <= 9 && _betnumber3 >= 0 && _betnumber3 <= 9, 'Incorrect Bet Number');
		require((_betnumber1 != _betnumber2 && _betnumber1 != _betnumber3 && _betnumber2 != _betnumber3) , 'Incorrect Bet Number');
		require(msg.value == singlebet_price * _betqty * 6, 'Incorrect Amount');  
		
		currBetNumber = _betnumber1 * 100 + _betnumber2 * 10 + _betnumber3 * 1 ;
		currBetQuantity = _betqty;
		currBetUserID = users[msg.sender].userid;
		currBetDrawNumber= _drawnumber;
		
		BetStruct memory betStruct;
        currBet3DID++;
        betStruct = BetStruct({
			isExist: true,
            isDirect: false,
            isPermutation: true,
			isRollFront: false,
			isRollBack: false,
			drawnumber: currBetDrawNumber,
            betid: currBet3DID,
			betuserid: currBetUserID,
			bettype: "3D",
			betnumber: currBetNumber,
			betqty: currBetQuantity
        });
        bets3D[msg.sender] = betStruct;
        betList3D[currBet3DID] = msg.sender;
		betDetail3D[currBet3DID] = betStruct;		
		
		emit addbet(msg.sender, currBetUserID, currBetDrawNumber, currBet3DID, "3D", currBetNumber, currBetQuantity, currBetQuantity * 6 * 50 , false, true, false, false, now);
		sendBalance(currBetUserID);
}

function PermutationBet4D_4(uint _drawnumber, uint _betnumber1, uint _betnumber2, uint _betnumber3, uint _betnumber4, uint _betqty) public payable {
		require(((!(SignupPause) && users[msg.sender].isExist) || !(TJPPause)), "Please Sign Up First");
		require(draws4D[_drawnumber].isExist, 'Invalid Draw');
		currBetCloseDate = draws4D[_drawnumber].drawbetdue ;
		require(currBetCloseDate > now, 'Draw Closed');
		require(_betnumber1 >= 0 && _betnumber1 <= 9 && _betnumber2 >= 0 && _betnumber2 <= 9 && _betnumber3 >= 0 && _betnumber3 <= 9 && _betnumber4 >= 0 && _betnumber4 <= 9 , 'Incorrect Bet Number');
		require((_betnumber1 != _betnumber2 && _betnumber2 == _betnumber3 && _betnumber2 == _betnumber4) || (_betnumber2 != _betnumber1 && _betnumber1 == _betnumber3 && _betnumber1 == _betnumber4) || (_betnumber3 != _betnumber1 && _betnumber1 == _betnumber2 && _betnumber1 == _betnumber4) || (_betnumber4 != _betnumber1 && _betnumber1 == _betnumber2 && _betnumber1 == _betnumber3) , 'Incorrect Bet Number');
		
		require(msg.value == singlebet_price * _betqty * 4, 'Incorrect Amount');  
		
		currBetNumber = _betnumber1 * 1000 + _betnumber2 * 100 + _betnumber3 * 10 + _betnumber4 * 1;
		currBetQuantity = _betqty;
		currBetUserID = users[msg.sender].userid;
		currBetDrawNumber= _drawnumber;
		
		BetStruct memory betStruct;
        currBet4DID++;
        betStruct = BetStruct({
			isExist: true,
            isDirect: false,
            isPermutation: true,
			isRollFront: false,
			isRollBack: false,
			drawnumber: currBetDrawNumber,
            betid: currBet4DID,
			betuserid: currBetUserID,
			bettype: "4D",
			betnumber: currBetNumber,
			betqty: currBetQuantity
        });
        bets4D[msg.sender] = betStruct;
        betList4D[currBet4DID] = msg.sender;
		betDetail4D[currBet4DID] = betStruct;		
		
		emit addbet(msg.sender, currBetUserID, currBetDrawNumber, currBet4DID, "4D", currBetNumber, currBetQuantity, currBetQuantity * 4 * 50 , false, true, false, false, now);
		sendBalance(currBetUserID);
}

function PermutationBet4D_6(uint _drawnumber, uint _betnumber1, uint _betnumber2, uint _betnumber3, uint _betnumber4, uint _betqty) public payable {
		require(((!(SignupPause) && users[msg.sender].isExist) || !(TJPPause)), "Please Sign Up First");
		require(draws4D[_drawnumber].isExist, 'Invalid Draw');
		currBetCloseDate = draws4D[_drawnumber].drawbetdue ;
		require(currBetCloseDate > now, 'Draw Closed');
		require(_betnumber1 >= 0 && _betnumber1 <= 9 && _betnumber2 >= 0 && _betnumber2 <= 9 && _betnumber3 >= 0 && _betnumber3 <= 9 && _betnumber4 >= 0 && _betnumber4 <= 9 , 'Incorrect Bet Number');
		require((_betnumber1 == _betnumber2 && _betnumber1 != _betnumber3 && _betnumber3 == _betnumber4) || (_betnumber1 == _betnumber3 && _betnumber1 != _betnumber2 && _betnumber2 == _betnumber4) || (_betnumber1 == _betnumber4 && _betnumber1 != _betnumber2 && _betnumber2 == _betnumber3), 'Incorrect Bet Number');
		require(msg.value == singlebet_price * _betqty * 6, 'Incorrect Amount');  
		
		currBetNumber = _betnumber1 * 1000 + _betnumber2 * 100 + _betnumber3 * 10 + _betnumber4 * 1;
		currBetQuantity = _betqty;
		currBetUserID = users[msg.sender].userid;
		currBetDrawNumber= _drawnumber;
		
		BetStruct memory betStruct;
        currBet4DID++;
        betStruct = BetStruct({
			isExist: true,
            isDirect: false,
            isPermutation: true,
			isRollFront: false,
			isRollBack: false,
			drawnumber: currBetDrawNumber,
            betid: currBet4DID,
			betuserid: currBetUserID,
			bettype: "4D",
			betnumber: currBetNumber,
			betqty: currBetQuantity
        });
        bets4D[msg.sender] = betStruct;
        betList4D[currBet4DID] = msg.sender;
		betDetail4D[currBet4DID] = betStruct;		
		
		emit addbet(msg.sender, currBetUserID, currBetDrawNumber, currBet4DID, "4D", currBetNumber, currBetQuantity, currBetQuantity * 6 * 50 , false, true, false, false, now);
		sendBalance(currBetUserID);
}

function PermutationBet4D_12(uint _drawnumber, uint _betnumber1, uint _betnumber2, uint _betnumber3, uint _betnumber4, uint _betqty) public payable {
		require(((!(SignupPause) && users[msg.sender].isExist) || !(TJPPause)), "Please Sign Up First");
		require(draws4D[_drawnumber].isExist, 'Invalid Draw');
		currBetCloseDate = draws4D[_drawnumber].drawbetdue ;
		require(currBetCloseDate > now, 'Draw Closed');
		require(_betnumber1 >= 0 && _betnumber1 <= 9 && _betnumber2 >= 0 && _betnumber2 <= 9 && _betnumber3 >= 0 && _betnumber3 <= 9 && _betnumber4 >= 0 && _betnumber4 <= 9 , 'Incorrect Bet Number');
		require((_betnumber1 == _betnumber2 && _betnumber1 != _betnumber3 && _betnumber1 != _betnumber4 && _betnumber3 != _betnumber4) || (_betnumber1 == _betnumber3 && _betnumber1 != _betnumber2 && _betnumber1 != _betnumber4 && _betnumber2 != _betnumber4) || (_betnumber1 == _betnumber4 && _betnumber1 != _betnumber2 && _betnumber1 != _betnumber3 && _betnumber2 != _betnumber3) || (_betnumber2 == _betnumber3 && _betnumber2 != _betnumber1 && _betnumber2 != _betnumber4 && _betnumber1 != _betnumber4) || (_betnumber2 == _betnumber4 && _betnumber2 != _betnumber1 && _betnumber2 != _betnumber3 && _betnumber1 != _betnumber3) || (_betnumber3 == _betnumber4 && _betnumber3 != _betnumber1 && _betnumber3 != _betnumber2 && _betnumber1 != _betnumber2), 'Incorrect Bet Number');
		require(msg.value == singlebet_price * _betqty * 12, 'Incorrect Amount');  
		
		currBetNumber = _betnumber1 * 1000 + _betnumber2 * 100 + _betnumber3 * 10 + _betnumber4 * 1;
		currBetQuantity = _betqty;
		currBetUserID = users[msg.sender].userid;
		currBetDrawNumber= _drawnumber;
		
		BetStruct memory betStruct;
        currBet4DID++;
        betStruct = BetStruct({
			isExist: true,
            isDirect: false,
            isPermutation: true,
			isRollFront: false,
			isRollBack: false,
			drawnumber: currBetDrawNumber,
            betid: currBet4DID,
			betuserid: currBetUserID,
			bettype: "4D",
			betnumber: currBetNumber,
			betqty: currBetQuantity
        });
        bets4D[msg.sender] = betStruct;
        betList4D[currBet4DID] = msg.sender;
		betDetail4D[currBet4DID] = betStruct;		
		
		emit addbet(msg.sender, currBetUserID, currBetDrawNumber, currBet4DID, "4D", currBetNumber, currBetQuantity, currBetQuantity * 12 * 50 , false, true, false, false, now);
		sendBalance(currBetUserID);
}

function PermutationBet4D_24(uint _drawnumber, uint _betnumber1, uint _betnumber2, uint _betnumber3, uint _betnumber4, uint _betqty) public payable {
		require(((!(SignupPause) && users[msg.sender].isExist) || !(TJPPause)), "Please Sign Up First");
		require(draws4D[_drawnumber].isExist, 'Invalid Draw');
		currBetCloseDate = draws4D[_drawnumber].drawbetdue ;
		require(currBetCloseDate > now, 'Draw Closed');
		require(_betnumber1 >= 0 && _betnumber1 <= 9 && _betnumber2 >= 0 && _betnumber2 <= 9 && _betnumber3 >= 0 && _betnumber3 <= 9 && _betnumber4 >= 0 && _betnumber4 <= 9 , 'Incorrect Bet Number');
		require((_betnumber1 != _betnumber2 && _betnumber1 != _betnumber3 && _betnumber1 != _betnumber4 && _betnumber2 != _betnumber3 && _betnumber2 != _betnumber4 && _betnumber3 != _betnumber4) , 'Incorrect Bet Number');
		require(msg.value == singlebet_price * _betqty * 24, 'Incorrect Amount');  
		
		currBetNumber = _betnumber1 * 1000 + _betnumber2 * 100 + _betnumber3 * 10 + _betnumber4 * 1;
		currBetQuantity = _betqty;
		currBetUserID = users[msg.sender].userid;
		currBetDrawNumber= _drawnumber;
		
		BetStruct memory betStruct;
        currBet4DID++;
        betStruct = BetStruct({
			isExist: true,
            isDirect: false,
            isPermutation: true,
			isRollFront: false,
			isRollBack: false,
			drawnumber: currBetDrawNumber,
            betid: currBet4DID,
			betuserid: currBetUserID,
			bettype: "4D",
			betnumber: currBetNumber,
			betqty: currBetQuantity
        });
        bets4D[msg.sender] = betStruct;
        betList4D[currBet4DID] = msg.sender;
		betDetail4D[currBet4DID] = betStruct;		
		
		emit addbet(msg.sender, currBetUserID, currBetDrawNumber, currBet4DID, "4D", currBetNumber, currBetQuantity, currBetQuantity * 24 * 50 , false, true, false, false, now);
		sendBalance(currBetUserID);
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////    
    function getTrxBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function sendBalance(uint _userid) private{
        uint ContractBalance = getTrxBalance();
        if (ContractBalance>0){
            if (!address(uint160(ownerWallet)).send(ContractBalance)) {
            }
        }
    }
    
    function withdrawSafe(uint _amount) external {
        require(msg.sender == ownerWallet, 'Permission denied');
        if (_amount > 0) {
            uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint amtToTransfer = _amount > contractBalance ? contractBalance : _amount;
                msg.sender.transfer(amtToTransfer);
            }
       }
   }
   
	function SignUpPaused(bool _issignup_paused) public {
		require(msg.sender == ownerWallet, 'Permission denied');		
		SignupPause = _issignup_paused;
    }
	
	function TronJackpotPaused(bool _istronjackpots_paused) public {
		require(msg.sender == ownerWallet, 'Permission denied');		
		TJPPause = _istronjackpots_paused;
    }
	
	function BetPromotion(bool _isfreebetpromotion) public {
		require(msg.sender == ownerWallet, 'Permission denied');		
		FreeBetPromotion = _isfreebetpromotion;
    }

	function RegisterDraw_2D(uint _drawnumber, uint _drawduetime) public {
		require(msg.sender == ownerWallet, 'Permission denied');
		
		currDrawNumber = _drawnumber;
		currDrawDate = _drawduetime;
		
		DrawStruct memory drawStruct;
        currDraw2DID++;
        drawStruct = DrawStruct({
            isExist: true,
            drawno: currDrawNumber,
            drawbetdue: currDrawDate,
			bettype: "2D"
        }); 
        draws2D[currDrawNumber] = drawStruct;
           
		emit adddraw(currDrawNumber, currDrawDate , "2D", now);
	}	
	
	function RegisterDraw_3D(uint _drawnumber, uint _drawduetime) public {
		require(msg.sender == ownerWallet, 'Permission denied');
		
		currDrawNumber = _drawnumber;
		currDrawDate = _drawduetime;
		
		DrawStruct memory drawStruct;
        currDraw3DID++;
        drawStruct = DrawStruct({
            isExist: true,
            drawno: currDrawNumber,
            drawbetdue: currDrawDate,
			bettype: "3D"
        }); 
        draws3D[currDrawNumber] = drawStruct;
           
		emit adddraw(currDrawNumber, currDrawDate , "3D", now);
	}	
		
	function RegisterDraw_4D(uint _drawnumber, uint _drawduetime) public {
		require(msg.sender == ownerWallet, 'Permission denied');
		
		currDrawNumber = _drawnumber;
		currDrawDate = _drawduetime;
		
		DrawStruct memory drawStruct;
        currDraw4DID++;
        drawStruct = DrawStruct({
            isExist: true,
            drawno: currDrawNumber,
            drawbetdue: currDrawDate,
			bettype: "4D"
        }); 
        draws4D[currDrawNumber] = drawStruct;
           
		emit adddraw(currDrawNumber, currDrawDate , "4D", now);
	}	
			
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        
 }