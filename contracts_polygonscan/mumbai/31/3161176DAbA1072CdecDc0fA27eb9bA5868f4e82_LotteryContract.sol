/**
 *Submitted for verification at polygonscan.com on 2022-01-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

contract LotteryContract {
    
    string private contractName = "Lottery Contract";

    // Start: Configration for game
    uint256 private totalTickets = 10; // total tickets in one round
    uint256 private oneTicketPrice = 4*10**17; // 1 Matic / Ether / BNB
    // End: Configration for game

    // Start:
    uint256 private CurrentGameCount; // which game round is currently going on
    mapping(uint256 => uint256) private totalTicketOfGame; // gamecount => how many tickets  sold (only) (like 1,2,3,4...)

    bool private canPlayerBuyTicket;

    mapping(uint256 => address[]) private playersOfGame; // gamecount => players in the game

    mapping(address => mapping(uint256 =>uint256[]))
        private ticketsOfUserInGame; // owner=>(gamecount=>tickets)

    mapping(uint256 => mapping(uint256 => address)) private inGameOwnerOfTicket; // gamecount=>(ticket=>owner)

    // can't see anyone
    mapping(uint256 => uint256) private private_random_variable_forgame; // gamecount=>random variable for this game and this will private

    struct WinnerPlayers {
        address Player1;
        address Player2;
        address Player3;
        uint256 TotalTickets;
        uint256 Time;
    }
    mapping(uint256 => WinnerPlayers) private winnerJakpotPlayerOfGame;
    mapping(uint256 => address[]) private consulationWinnersOfGame;

    mapping(uint256 => mapping(address=>uint256)) public playerRefferalCountOfGame; // gamecount => (user=>totalReferral) 
    mapping(uint256 => address[]) private playersThatRefferInGame; // gamecount => totalplayers who refer more than 0 players

    struct RefferalWinner {
        uint256 TotalRefferals;
        address  User;
    }
    mapping(uint256 => RefferalWinner[]) private RefferalWinnersShorted; // gamecount => shortedWinners high to low


    // config for admin
    address private admin;

    address private adminWallet1;
    address private adminWallet2;
    address private adminWallet3;
    address private adminWallet4;
    address private adminWallet5;
    address private adminWallet6;
    

    constructor()
    {
        admin = msg.sender;
        CurrentGameCount = 1;
        canPlayerBuyTicket = true;
    }
    
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "This function only owner can call");
        _;
    }

    modifier onlyWhenGameIsGoingOn() {
        require(
            canPlayerBuyTicket == true,
            "Game will start soon... Please try again."
        );
        _;
    }


    function buyTicket() public payable onlyWhenGameIsGoingOn  {
        require(msg.value >= oneTicketPrice, "Please Pay full entry Fee");
        require(
            totalTicketOfGame[CurrentGameCount] < totalTickets,
            "All tickets of this game are sold. Please try in next game"
        );
        _buyTicket_withWithout_refferal();
    }

    function buyTicketUsingReferral(address _referral)
        public
        payable
        onlyWhenGameIsGoingOn
    {
        require(msg.value >= oneTicketPrice, "Please Pay full entry Fee");
        require(
            totalTicketOfGame[CurrentGameCount] < totalTickets,
            "All tickets of this game are sold. Please try in next game"
        );
        // send ticket to who refer this guy
        if(_referral != msg.sender){
            if (isPlayerAddressAdded(_referral)) { // referral must buy alest one ticket
                playerRefferalCountOfGame[CurrentGameCount][_referral] += 1;
                if(!isReferPlayerAdded(_referral)){
                    playersThatRefferInGame[CurrentGameCount].push(_referral);
                }
            }
        }

        _buyTicket_withWithout_refferal();
    }

    function _buyTicket_withWithout_refferal() private {
        if (!isPlayerAddressAdded(msg.sender)) {
            playersOfGame[CurrentGameCount].push(msg.sender);
        }

        if (totalTicketOfGame[CurrentGameCount] == 1) {
            getRandomNumberChainlink();
        }

        totalTicketOfGame[CurrentGameCount] += 1;

        ticketsOfUserInGame[msg.sender][CurrentGameCount].push(totalTicketOfGame[CurrentGameCount]);

        inGameOwnerOfTicket[CurrentGameCount][
            totalTicketOfGame[CurrentGameCount]
        ] = msg.sender;


        if (totalTicketOfGame[CurrentGameCount] == totalTickets) {
            // stop game, find winner, transfer money and start game again
            canPlayerBuyTicket = false;
            _findRandomVariablesAndWinners();
        }
    }


    function getRandomNumberChainlink() private {
        private_random_variable_forgame[CurrentGameCount] = block.timestamp;
    }


    function _findRandomVariablesAndWinners() private {
        uint256 _firstRandomVariable = private_random_variable_forgame[
            CurrentGameCount
        ];

        uint256 _firstWinnerTicket = (_firstRandomVariable %
            totalTicketOfGame[CurrentGameCount]) + 1;
        address _firstWinner = inGameOwnerOfTicket[CurrentGameCount][
            _firstWinnerTicket
        ];

        //selecting secound winner
        bool runLoop = true;
        uint256 _secoundRandomVariable;
        uint256 _secoundWinnerTicket;
        address _secoundWinner;

        if(playersOfGame[CurrentGameCount].length > 1 ){
            for (uint256 i = 1; runLoop; i++) {
                _secoundRandomVariable = _firstRandomVariable / 2 + i;
                _secoundWinnerTicket =
                    (_secoundRandomVariable % totalTicketOfGame[CurrentGameCount]) +
                    1;
                _secoundWinner = inGameOwnerOfTicket[CurrentGameCount][
                    _secoundWinnerTicket
                ];
                if (_firstWinner != _secoundWinner) {
                    runLoop = false;
                }
            }
        } else{
            _secoundWinner = address(0);
        }

            //selecting third winner
            bool runLoop3 = true;
            uint256 _thirdRandomVariable;
            uint256 _thirdWinnerTicket;
            address _thirdWinner;

        if(playersOfGame[CurrentGameCount].length > 2 ){
            for (uint256 i = 1; runLoop3; i++) {
                _thirdRandomVariable = _secoundRandomVariable / 2 + i;
                _thirdWinnerTicket =
                    (_thirdRandomVariable % totalTicketOfGame[CurrentGameCount]) +
                    1;
                _thirdWinner = inGameOwnerOfTicket[CurrentGameCount][
                    _thirdWinnerTicket
                ];
                if (_firstWinner != _thirdWinner &&  _secoundWinner != _thirdWinner) {
                    runLoop3 = false;
                }
            }

        } else {
            _thirdWinner = address(0);
        }


        winnerJakpotPlayerOfGame[CurrentGameCount] = WinnerPlayers(
            _firstWinner,
            _secoundWinner,
            _thirdWinner,
            totalTicketOfGame[CurrentGameCount],
            block.timestamp
        );


        sendMoneyTo(_firstWinner,10); //$6000 for 
        sendMoneyTo(_secoundWinner,6); //$4000 for 
        sendMoneyTo(_thirdWinner,5); //$2000 for 

        // consulation price
        if(playersOfGame[CurrentGameCount].length > 3 ){
            uint256 _randomVarForConPrice = _firstRandomVariable % playersOfGame[CurrentGameCount].length;

            uint256 _totalPayerForCol = 4;
            if(playersOfGame[CurrentGameCount].length - 3 < _totalPayerForCol){
                _totalPayerForCol = playersOfGame[CurrentGameCount].length - 3;
            }

            for(uint256 i = 0; consulationWinnersOfGame[CurrentGameCount].length <= _totalPayerForCol; i++) {
                if(playersOfGame[CurrentGameCount][_randomVarForConPrice + i] != _firstWinner
                 && playersOfGame[CurrentGameCount][_randomVarForConPrice + i] != _secoundWinner && 
                 playersOfGame[CurrentGameCount][_randomVarForConPrice + i] != _thirdWinner ){
                    consulationWinnersOfGame[CurrentGameCount].push(playersOfGame[CurrentGameCount][_randomVarForConPrice + i]);
                }
                if(_randomVarForConPrice + i + 1 >= consulationWinnersOfGame[CurrentGameCount].length){
                    i = 1;
                    _randomVarForConPrice = 0;
                }
            }

            // send money to col players
            for(uint256 i=0; i < consulationWinnersOfGame[CurrentGameCount].length; i++){
                address _playerAddress = consulationWinnersOfGame[CurrentGameCount][i];
                    if(i < 2){
                        sendMoneyTo(_playerAddress,3); //$200 for 
                            
                    }else if (i < _totalPayerForCol){
                        sendMoneyTo(_playerAddress,2); //$100 for        
                }
            }

        }


        // Send money to refferal users

        RefferalWinner[] memory _referalWinnersTemp = new RefferalWinner[](playersThatRefferInGame[CurrentGameCount].length);

        for(uint256 i = 0; i < playersThatRefferInGame[CurrentGameCount].length;i++){
            address _user = playersThatRefferInGame[CurrentGameCount][i];
            uint256 _totalRef = playerRefferalCountOfGame[CurrentGameCount][_user];
            
            _referalWinnersTemp[i] = RefferalWinner(_totalRef,_user);
        }
        
        
        RefferalWinner[] memory _referalWinnersShorted = getShoetedWinnersArray(_referalWinnersTemp);
        for(uint256 i = 0; i < _referalWinnersShorted.length;i++){
            RefferalWinnersShorted[CurrentGameCount].push(_referalWinnersShorted[i]);
        }

        //sending money to refferals 
        for(uint256 i = 0; i < RefferalWinnersShorted[CurrentGameCount].length;i++){
            address _user = RefferalWinnersShorted[CurrentGameCount][i].User;
            // uint256 _totalRef = RefferalWinnersShorted[CurrentGameCount][i].TotalRefferals;

            if( i < 1){
                sendMoneyTo(_user,4); //$300 for 
            } else if( i < 2){
                sendMoneyTo(_user,2); 
            } else if( i < 3){
                sendMoneyTo(_user,1);                
            }

        }


        // send money to team

            // // send money to wallet one
            // sendMoneyTo(adminWallet1,2000);
            // // send money to wallet two
            // sendMoneyTo(adminWallet2,800);
            // // send money to wallet 3
            // sendMoneyTo(adminWallet3,400);
            // // send money to wallet 4
            // sendMoneyTo(adminWallet4,400);
            // // send money to wallet 5
            // sendMoneyTo(adminWallet5,200);
            // // send money to wallet 6
            // sendMoneyTo(adminWallet6,200);
            
        // start new game
        canPlayerBuyTicket = true;
        CurrentGameCount += 1;
    }


    function sendMoneyTo(address _to, uint256 _amount) private returns(bool) {
        if(address(0) != _to){
        (bool os, ) = payable(_to).call{value: _amount*10**17}("");
        }

        return true;
    }

    function getShoetedWinnersArray(RefferalWinner[] memory arr_) private pure returns (RefferalWinner[] memory )
    {
        uint256 l = arr_.length;
        RefferalWinner[] memory arr = new RefferalWinner[] (l);

        for(uint256 i=0;i<l;i++)
        {
            arr[i] = arr_[i];
        }

        for(uint256 i=0;i<l;i++)
        {
            for(uint256 j=i+1;j<l;j++)
            {
                if(arr[i].TotalRefferals<arr[j].TotalRefferals)
                {
                    RefferalWinner memory temp= arr[j];
                    arr[j]=arr[i];
                    arr[i] = temp;

                }

            }
        }
        return arr;
    }

    // Start: Helping functions
    function isPlayerAddressAdded(address _player) private view returns (bool) {
        for (uint256 i = 0; i < playersOfGame[CurrentGameCount].length; i++) {
            if (playersOfGame[CurrentGameCount][i] == _player) {
                return true;
            }
        }
        return false;
    }

    function isReferPlayerAdded(address _player) private view returns (bool) {
        for (uint256 i = 0; i < playersThatRefferInGame[CurrentGameCount].length; i++) {
            if (playersThatRefferInGame[CurrentGameCount][i] == _player) {
                return true;
            }
        }
        return false;
    }

    

    function all_players_are_not_same() private view returns (bool) {
        if (1 < playersOfGame[CurrentGameCount].length) {
            address _oneAddress = playersOfGame[CurrentGameCount][0];
            for (
                uint256 i = 1;
                i < playersOfGame[CurrentGameCount].length;
                i++
            ) {
                if (playersOfGame[CurrentGameCount][i] != _oneAddress) {
                    return true;
                }
            }
        }
        return false;
    }

    // End: Helping functions

    // *********Start: Admin Functions

    function isAdmin() public view returns (bool) {
        if (msg.sender == admin) {
            return true;
        } else {
            return false;
        }
    }

    function knowAdminBalance() public view onlyAdmin returns (uint256) {
        return address(this).balance;
    }

    function withdrawAdminBalance(address payable _owner, uint256 _amount)
        public
        onlyAdmin
        returns (bool)
    {
        (bool sent, ) = _owner.call{value: _amount}("");

        return sent;
    }

    function changeAdmin(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
    }

    // function knowAdminBalanceOfToken(IERC20 _tokenAddress)
    //     public
    //     view
    //     onlyAdmin
    //     returns (uint256)
    // {
    //     return _tokenAddress.balanceOf(address(this));
    // }

    // function withdrawAdminBalanceOfToken(
    //     IERC20 _tokenAddress,
    //     address payable _owner,
    //     uint256 _amount
    // ) public onlyAdmin {
    //     _tokenAddress.transfer(_owner, _amount);
    // }

    // *********End: Admin Functions

    // Functions for get data

    // --start: Configration for game


    function getTotalTickets() public view returns (uint256) {
        return totalTickets;
    }

    function getOneTicketPrice() public view returns (uint256) {
        return oneTicketPrice;
    }

    // --End: Configration for game

    //

    function getCurrentGameCount() public view returns (uint256) {
        return CurrentGameCount;
    }

    function getCanPlayerBuyTicket() public view returns (bool) {
        return canPlayerBuyTicket;
    }

    function gettotalTicketOfGame(uint256 _gamecount)
        public
        view
        returns (uint256)
    {
        return totalTicketOfGame[_gamecount];
    }


    function getAllTicketsOfUserInGame(address _user, uint256 _gamecount)
        public
        view
        returns (uint256[] memory)
    {
        return ticketsOfUserInGame[_user][_gamecount];
    }

    function getInGameOwnerOfTicket(uint256 _gamecount, uint256 _ticket)
        public
        view
        returns (address)
    {
        return inGameOwnerOfTicket[_gamecount][_ticket];
    }

    function getWinnerJakpotPlayerOfGame(uint256 _gamecount)
        public
        view
        returns (WinnerPlayers memory)
    {
        return winnerJakpotPlayerOfGame[_gamecount];
    }

    function getRefferalWinnersShorted(uint256 _gamecount)
        public
        view
        returns (RefferalWinner[] memory)
    {
        return RefferalWinnersShorted[_gamecount];
    }

    function getConsulationWinnersOfGame(uint256 _gamecount)
        public
        view
        returns (address[] memory)
    {
        return consulationWinnersOfGame[_gamecount];
    }          
}