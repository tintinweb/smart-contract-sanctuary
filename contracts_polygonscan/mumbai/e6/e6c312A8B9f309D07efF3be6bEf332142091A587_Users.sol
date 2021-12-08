/**
 *Submitted for verification at polygonscan.com on 2021-12-07
*/

pragma solidity >0.6.1 <0.6.8;
pragma experimental ABIEncoderV2;
contract Users
{
    // Creating a database of all Players Betting.
    address payable [] Winner;
   address payable owner = msg.sender;
    uint EthAmount;
    uint EthtoSend;
    uint EthtoKeep;
    uint Counts;
    uint Counts2;
    uint Counts3;
    uint PlayerCount;
    uint [] queen;
    uint _f = 200*1000;
    uint _id;
    struct User
    {
        uint id;
        address payable Payable;
        address ofUsers;
        string Game;
        string Player1;
        string Player2;
        string Player3;
        string Player4;
        string Player5;
        uint Points;
        uint Points1;
        uint Points2;
        uint Points3;
        uint Points4;
        uint Points5;
        uint Rank;
        uint EthValue;
       
    }
    mapping(uint => User) ofPlayers;
    uint [] public PlayersAcct; 
    
     // All Payment Functions Start from here. Main Computing has been completed in the Coding mentioned above itself.
       
    modifier onlyOwner()
    {
        require(msg.sender == owner, "Not Authorized");
         _;
    }
        
     // Investing Ethereum in order to Place Betting
        
    function Invest() external payable 
    {
        
        if(msg.value < 0.1 ether || msg.value > 0.5 ether)
        {
            revert("Acceptable Ethereum Amount is 0.5");
        }
    }
        
    // Checking Total Ethereum Staked for Betting
        
    function TotalBalanceof() external onlyOwner view returns(uint)
    {
        return address(this).balance;
    }
        
    // Transferring Ethereum to Winners of Each Pool
       
    function transfer(uint _idd) public
    { 
     if((ofPlayers[_idd].Rank==1) || (ofPlayers[_idd].Rank==2) || (ofPlayers[_idd].Rank==3))
        {
        uint amount = ofPlayers[_idd].EthValue;
        address payable temp = ofPlayers[_idd].Payable;
        temp.transfer(amount);
        ofPlayers[_idd].EthValue = 0; ofPlayers[_idd].Payable= (address(uint(0)));
        }      
    }
        
    // Withdrawing the Remaining Amount of Ethereum to Owners Wallet
    event Withdraw(uint amount, uint balance);
    function withdraw() public onlyOwner
    {
        owner.transfer(EthtoKeep);
        emit Withdraw(EthtoKeep, address(this).balance);  
        EthtoKeep=0;
    }

    // Entering All User Data.
   
    function setUser(string memory _ofusers, string memory _Game, string memory _Player1, string memory _Player2, string memory _Player3, string memory _Player4, string memory _Player5) public 
    {
        address _ofUsers;
        bytes memory tmp = bytes(_ofusers);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) 
        {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) 
            {
                b1 -= 87;
            } 
            else if ((b1 >= 65) && (b1 <= 70)) 
            {
                b1 -= 55;
            } 
            else if ((b1 >= 48) && (b1 <= 57)) 
            {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) 
            {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) 
            {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) 
            {
                b2 -= 48;
            }
             iaddr += (b1 * 16 + b2);
        }
        _ofUsers = address(uint160(iaddr));
        _id+=1;
        User storage user = ofPlayers[_id];
        user.id = _id;
        user.ofUsers = _ofUsers;
        user.Game = _Game;
        user.Player1 = _Player1;
        user.Player2 = _Player2;
        user.Player3 = _Player3;
        user.Player4 = _Player4;
        user.Player5 = _Player5; 
        PlayersAcct.push(_id);
    }

    // An Array of all Users Wallet Address Playing Separate Games
       
    function Sort_Games(string memory _game) public onlyOwner
    {
        for(uint c=0; c<PlayersAcct.length;c++){
        if((keccak256(abi.encodePacked(ofPlayers[PlayersAcct[c]].Game)))==(keccak256(abi.encodePacked(_game)))){
            queen.push(ofPlayers[PlayersAcct[c]].id); 
        }}
        uint len = queen.length;
        if(len<9){
             for(uint i=len;i<10;i++){
                queen.push(200*1000);
            }
        }
        else{
            uint d=len/9;uint r=len%9;
            if(r>=d){
                    for(uint i=len;i<((d+1)*10);i++){
                        queen.push(200*1000);
            }}
            else{
                for(uint i=len;i<(d*10);i++){
                    queen.push(200*1000);
                }}
            }                                      
    }     
       // Meant for User Interface showing Every User their Details including their Rank
       
        function showUser(uint _idd) view public returns (uint, string memory, string memory, string memory, string memory, string memory, uint)
        {
        return (_idd, ofPlayers[_idd].Player1, ofPlayers[_idd].Player2, ofPlayers[_idd].Player3, ofPlayers[_idd].Player4, ofPlayers[_idd].Player5, ofPlayers[_idd].Rank);
        }

        function Showme(uint _idd) view public returns(uint,string memory,uint,uint,uint,uint,uint)
        {
           return(ofPlayers[_idd].Points,ofPlayers[_idd].Game,ofPlayers[_idd].Points1,ofPlayers[_idd].Points2,ofPlayers[_idd].Points3,ofPlayers[_idd].Points4, ofPlayers[_idd].Points5);
        }


        function ShowGame() external view returns(uint [] memory )
        {
           return(queen);
        }
      // Giving Points for Betting !!!!
      
        function givePoints(string memory player, uint points) public onlyOwner
        {
            for(uint i=0; i<queen.length; i++)
            {
                if ((keccak256(abi.encodePacked(ofPlayers[queen[i]].Player1))) == (keccak256(abi.encodePacked(player))))
                {
                    ofPlayers[queen[i]].Points += points;
                    ofPlayers[queen[i]].Points1 += points;
                }
                if ((keccak256(abi.encodePacked(ofPlayers[queen[i]].Player2))) == (keccak256(abi.encodePacked(player))))
                {
                    ofPlayers[queen[i]].Points += points;
                    ofPlayers[queen[i]].Points2 += points;
                }
                if ((keccak256(abi.encodePacked(ofPlayers[queen[i]].Player3))) == (keccak256(abi.encodePacked(player))))
                {
                    ofPlayers[queen[i]].Points += points;
                    ofPlayers[queen[i]].Points3 += points;
                }
                if ((keccak256(abi.encodePacked(ofPlayers[queen[i]].Player4))) == (keccak256(abi.encodePacked(player))))
                {
                    ofPlayers[queen[i]].Points += points;
                    ofPlayers[queen[i]].Points4 += points;
                }
                if ((keccak256(abi.encodePacked(ofPlayers[queen[i]].Player5))) == (keccak256(abi.encodePacked(player))))
                {
                    ofPlayers[queen[i]].Points += points;
                    ofPlayers[queen[i]].Points5 += points;
                }
            }
        }
        
        // Giving Ranks to all Players !!!!!!!
        
        function GivingRank(uint Pool, string memory _game) public onlyOwner
        {
            // Sorting Betters Addresses 
            for(uint i=(Pool-1); i<(Pool+9); i++) 
            {
                for(uint j = i+1; j<(Pool+9); j++)
                {
                    if(queen[i] != _f){
                   if((ofPlayers[queen[i]].Points) < (ofPlayers[queen[j]].Points))
                   {
                    uint temp = queen[i];
                    queen[i] = queen[j];
                    queen[j] = temp;
                   }
                }
            }   }      
            //Giving Ranks to all Betters
            uint k=1;
            for(uint i=(Pool-1); i<(Pool+9); i++)
            {
                if(queen[i] != _f){
                if(ofPlayers[queen[i]].Points == ofPlayers[queen[i+1]].Points)
                    {
                    ofPlayers[queen[i+1]].Rank = ofPlayers[queen[i]].Rank;
                    }
                ofPlayers[queen[i]].Rank = k;
            }
              k++;
            }
        }

    function calc(uint Pool, string memory _game) public onlyOwner {
            Counts=1;
            Counts2=1;
            Counts3=1;
            PlayerCount = 0;
            for(uint i=Pool-1;i<Pool+9;i++)
            {
                if(ofPlayers[queen[i]].Rank ==1)
                {
                    Counts+=1;
                }
                if(ofPlayers[queen[i]].Rank ==2)
                {
                    Counts2+=1;
                }
                if(ofPlayers[queen[i]].Rank ==3)
                {
                    Counts3+=1;
                }
            }
             //Calculating the Amount of Ethereum won by Winners(and if there are more than one Winner, by them collectively)
            
            for(uint i=(Pool-1); i<(Pool+9); i++)
            {
            if(queen[i] != _f) {
            EthAmount += ofPlayers[queen[i]].EthValue;
            PlayerCount += 1;
            }}
            uint y=0; uint r=0;
            for(uint i=(Pool-1); i<Pool+9; i++)
            {
                if(PlayerCount>5){
                if((ofPlayers[queen[i]].Rank) == 1)
                {
                EthtoSend = ((2*10**17)/Counts);
                ofPlayers[queen[i]].EthValue = EthtoSend; 
                y+=EthtoSend;    
                }
                 if((ofPlayers[queen[i]].Rank) == 2)
                {
                EthtoSend = ((15*10**16)/Counts2);
                ofPlayers[queen[i]].EthValue = EthtoSend;  
                y+=EthtoSend;   
                }
                 if((ofPlayers[queen[i]].Rank) == 3)
                {
                EthtoSend = ((125*10**15)/Counts3);
                ofPlayers[queen[i]].EthValue = EthtoSend; 
                y+=EthtoSend;    
                }
                }
                else{
                    r = EthAmount/PlayerCount;
                    EthtoSend = EthAmount-r;
                    if (EthtoSend > 0){
                                 if((ofPlayers[queen[i]].Rank) == 1)
                                {
                                    EthtoSend = ((1*10**17)/Counts);
                                    ofPlayers[queen[i]].EthValue = EthtoSend; 
                                    y+=EthtoSend;    
                                }
                    }
                    else{
                        y=r;
                    }
                }

            }
            if(y!=EthAmount){
            EthtoKeep = EthAmount - y;
            }
            else{
                EthtoKeep=y;
            }
            }
            function setWinner() public onlyOwner{
            for(uint i=0;i<queen.length;i++){
               if((queen[i] != _f) && ((ofPlayers[PlayersAcct[i]].Rank==1)|| (ofPlayers[PlayersAcct[i]].Rank==2) ||(ofPlayers[PlayersAcct[i]].Rank==3))){
                   address temp = ofPlayers[queen[i]].ofUsers;
                   ofPlayers[queen[i]].Payable =address(uint(temp));
               }
            }
            }
            function del() public onlyOwner{
            delete PlayersAcct;
            delete queen;
            }
}