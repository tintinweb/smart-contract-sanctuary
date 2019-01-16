pragma solidity ^0.4.19;

contract TicTacToe
{

    
    struct Game {
        string name;
        address[9]     board;
        address[2]     player;
        uint blocked_until;
        uint movs;
        uint turn;
        uint amount;
        bool waiting;
        bool finish;
    }
    Game public room;
    
    function TicTacToe() public
    {
        room.finish = true;
    }
    
    
    modifier waiting()
    {
        require(room.waiting == true);
        _;
    }

    modifier notWaiting()
    {
        require(room.waiting == false);
        _;
    }
    
    modifier otherPlayer()
    {
        require(room.player[0] != msg.sender);
        _;
    }
    
    modifier checkBid()
    {
        require(room.amount <= msg.value);
        _;
    }
    
    modifier myTurn()
    {
        require(room.player[room.turn] == msg.sender);
        _;
    }
    
    modifier playable(uint c)
    {
        require(room.board[c] == 0);
        _;
    }
    
    modifier notOpen()
    {
        require(room.finish == true);
        _;
    }
    
    modifier open()
    {
        require(room.finish == false);
        _;
    }
    
    modifier canReclaim()
    {
        require(room.blocked_until >= block.number);
        _;
    }

    event TurnChange(address _t);
    event PlayerJoin(address _t);
    event NewGame(string _name, uint256 _amount);
    event EndGame(address _winner, uint256 _amount);


    function nextTurn() internal
    {
        if (room.turn == 0) 
            room.turn = 1;
        else 
            room.turn = 0;
        
        TurnChange(room.player[room.turn]);
    }
    
    function getPlayers() 
        constant 
        public 
        returns(address[2])
    {
        return room.player;
    }

    function roomFree() 
        constant 
        public 
        returns(bool)
    {
        return room.finish;
    }

    function getRoomName() 
        constant 
        public 
        returns(string)
    {
        return room.name;
    }

    function checkBoard(uint c) 
        constant 
        internal 
        returns (bool)
    {
        address[9] memory board = room.board;
        if (c == 0) 
        {
            if ((board[0] == board[4]  && board[0] == board[8]) ||
                (board[0] == board[1]  && board[0] == board[2]) ||
                (board[0] == board[3]  && board[0] == board[6])) 
            { 
                return true; 
            }
            else
            {
                return false;
            }
        } 
        else if (c== 1)
        {
            if ((board[1] == board[0] && board[1] == board[2])||
                (board[1] == board[4] && board[1] == board[7]))
            {
                return true;
            }
            else
            {
                return false;
            }
        }
        else if (c == 2)
        {
            if ((board[2] == board[0] && board[2] == board[1])||
                (board[2] == board[4] && board[2] == board[6])||
                (board[2] == board[5] && board[2] == board[8]))
            {
                return true;
            }
            else 
            {
                return false;
            }
        }
        else if (c == 3) 
        {
            if ((board[3] == board[0] && board[3] == board[6])||
                (board[3] == board[4] && board[3] == board[5]))
            {
                return true;
            }
            else
            {
                return false;
            }
        }
        else if (c == 4)
        {
            if ((board[3] == board[4] && board[4] == board[5])||
                (board[2] == board[4] && board[4] == board[6])||
                (board[1] == board[4] && board[4] == board[7])||
                (board[0] == board[4] && board[4] == board[8]))
            {
                return true;
            }
            else
            {
                return false;
            }
        }
        else if (c == 5)
        {
            if ((board[3] == board[5] && board[4] == board[5])||
                (board[2] == board[5] && board[8] == board[5]))
            {
                return true;
            }
            else 
            {
                return false;
            }
        }
        else if (c == 6)
        {
            if ((board[6] == board[0] && board[6] == board[3]) ||
                (board[6] == board[7] && board[6] == board[8]) ||
                (board[6] == board[4] && board[6] == board[2]))
            {
                return true;
            }
            else
            {
                return false;
            }
        }
        else if (c == 7)
        {
            if ((board[7] == board[6] && board[7] == board[8]) ||
                (board[7] == board[4] && board[7] == board[1]))
            {
                return true;
            }
            else
            {
                return false;
            }
        }
        else if (c == 8)
        {
            if ((board[8] == board[6] && board[8] == board[7]) ||
                (board[8] == board[2] && board[8] == board[5]) ||
                (board[8] == board[0] && board[8] == board[4]))
            {
                return true;
            }
            else 
            {
                return false;
            }
        }
    }
    function getBid() 
        constant 
        public 
        returns(uint)
    {
        return room.amount;
    }

    function getBoard() 
        constant 
        public 
        returns(address[9])
    {
        address[9] memory board;
        if (room.waiting == true || room.finish == true)
        {
            return board;
        }
        return room.board;
    }

    function getTurn()
        constant 
        public 
        returns(address)
    {
        if (room.waiting == true || room.finish == true)
        {
            return address(0);
        }
        return room.player[room.turn];
    }

    function newGame(string room_name) 
        notOpen() 
        public 
        payable
    {
        room.board        = [address(0),address(0),address(0),address(0),address(0),address(0),address(0),address(0),address(0)];
        room.name         = room_name;
        room.player[0]    = msg.sender;
        room.turn         = 0;
        room.amount       = msg.value;
        room.waiting      = true;
        room.finish       = false;
        room.blocked_until = block.number + 100;
        room.movs         = 9;
        NewGame(room.name,msg.value);
    }
    
    function isWaiting() 
        constant
        public
        returns(bool)
    {
        return room.waiting;
    }

    function joinGame() 
        public 
        payable 
        waiting() 
        otherPlayer() 
        checkBid() 
    {
        if (msg.value > room.amount)
            msg.sender.transfer(msg.value-room.amount);
        room.amount    = this.balance;
        room.player[1] = msg.sender;
        room.waiting   = false;
        room.blocked_until = block.number + 100;
        PlayerJoin(msg.sender);
    }
    

    function reclaim()
        public
        canReclaim()
        open()
    {
        if (room.waiting) {
            if (msg.sender == room.player[0]) {
                room.player[0] = address(0);
                room.waiting   = false;
                room.finish     = true;
                msg.sender.transfer(room.amount);
            }
        }
        else {
            if (room.turn == 0)
                if (room.player[1] == msg.sender) {
                    room.finish     = true;
                    room.player[1].transfer(room.amount);
                }
            else 
                if (room.player[0] == msg.sender) {
                    room.finish     = true;
                    room.player[0].transfer(room.amount);
                }
        }
    }


    function play(uint c) 
        public 
        open() 
        playable(c) 
        myTurn() 
    {
        room.board[c]     = msg.sender;
        room.movs         = room.movs -1;
        room.blocked_until = block.number + 100;

        if (checkBoard(c)) {
            room.finish = true;
            msg.sender.transfer(room.amount);
            EndGame(msg.sender,room.amount);
        }
        else {
            if (room.movs == 0) {
                room.finish = true;
                room.player[0].transfer(room.amount/2);
                room.player[1].transfer(room.amount/2);
                EndGame(address(0),0);
            }
            else {
                room.blocked_until = block.number + 100;
                nextTurn();
            }
        }
    }
}