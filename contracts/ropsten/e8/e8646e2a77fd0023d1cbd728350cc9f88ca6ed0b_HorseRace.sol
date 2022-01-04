/**
 *Submitted for verification at Etherscan.io on 2022-01-03
*/

// We will be using Solidity version 0.8.10
pragma solidity 0.8.10;

contract HorseRace {
    event Joined(address indexed _from, uint256 _value);
    event Withdraw(address indexed _from, uint256 _value);
    event GameOver(address indexed _from, uint256 _position);
    event GameTimeout();
    event GameStarted(uint256 _amount_player);
    event GameError(string error);
    event GameDebug(address indexed _from);

    uint256 private price = 0.1 ether;
    uint256 private totalAmount = 0;
    address[] private players = new address[](6);
    address private owner;
    address private external_wallet;
    bool private gamePlaying = false;
    uint256 private timeGameStarted = 0;

    constructor() public {
        owner = msg.sender;
        external_wallet = msg.sender;
    }

    function setOwner(address new_wallet) public {
        require(msg.sender == owner, "You are not the owner");
        external_wallet = new_wallet;
    }

    function setPrice(uint256 new_price) public {
        require(msg.sender == owner, "You are not the owner");
        price = new_price;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getStatusGame() public view returns (bool) {
        return gamePlaying;
    }

    function getTotalPlayers() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < 6; i++) {
            if (players[i] != address(0)) total += 1;
        }
        return total;
    }

    function checkPosition(uint256 position) private view returns (bool) {
        if (players[position] != address(0)) return true;
        else return false;
    }

    function setWinner(uint256 position) public {
        require(msg.sender == owner, "You are not the owner");
        require(gamePlaying, "Game is not playing");
        require(
            address(this).balance >= totalAmount,
            "Not enough money in the contract"
        );

        if (!checkPosition(position)) {
            revert("No player at that position");
        }

        gamePlaying = false;

        if (position >= 0 && position <= 6) {
            uint256 amount_owner = uint256(totalAmount / 100) * 10;
            uint256 amount_player = totalAmount - amount_owner;
            if (address(this).balance >= amount_player) {
                emit GameOver(players[position], position);
                address payable receiver = payable(players[position]);
                receiver.transfer(amount_player);
                totalAmount = 0;
                receiver = payable(external_wallet);
                if (address(this).balance >= amount_owner) {
                    receiver.transfer(amount_owner);
                } else {
                    if (address(this).balance > 0) {
                        receiver.transfer(address(this).balance);
                    } else {
                        //probably use revert to dont give money away ?! :/
                        emit GameError(
                            "Not money in the contract for the owner"
                        );
                    }
                }
            } else {
                totalAmount = 0;
                revert("Not enough money to send to winner");
            }
        }
        totalAmount = 0;
        emptyPlayers();
    }

    function refundPlayers() private {
        address payable receiver;

        for (uint256 i = 0; i < 6; i++) {
            if (players[i] != address(0)) {
                receiver = payable(players[i]);
                if (address(this).balance >= price) {
                    receiver.transfer(price);
                }
            }
        }
    }

    function timeout() public {
        require(msg.sender == owner, "You are not the owner");
        require(gamePlaying, "There is no game playing");
        emit GameTimeout();
        //check if it is playing first! maybe check the timing as well!
        gamePlaying = false;
        refundPlayers();
        emptyPlayers();
        totalAmount = 0;
    }

    function gameStarted() public {
        require(msg.sender == owner, "You are not the owner");
        gamePlaying = true;
        timeGameStarted = block.timestamp;
        emit GameStarted(getTotalPlayers());
    }

    function emptyPlayers() private {
        for (uint256 i = 0; i < 6; i++) {
            players[i] = address(0);
        }
    }

    function random() private view returns (uint256) {
        // sha3 and now have been deprecated
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, players)
                )
            );
        // convert hash to integer
        // players is an array of entrants
    }

    function pickPosition() private view returns (uint256) {
        uint256 length = 0;
        uint256[] memory freeSlots = new uint256[](6);
        for (uint256 i = 0; i < 6; i++) {
            if (players[i] == address(0)) {
                freeSlots[length] = i;
                length += 1;
            }
        }
        uint256 number = random() % length;
        if (number >= 0 && number <= 6) return freeSlots[number];
        else revert("Error random place user");
    }

    function checkExist(address joiner) private view returns (bool) {
        bool joined = false;
        for (uint256 i = 0; i < 6; i++) {
            if (players[i] == joiner) {
                joined = true;
            }
        }
        return joined;
    }

    function checkJoin(address useraddr) public  view returns(bool) {
       // emit GameDebug(useraddr);
        for (uint256 i = 0; i < 6; i++) {
            if (players[i] == useraddr) {
                    return true;
            }
        }
        return false;
    }


    function withdraw() public  returns (bool) {
        require(!gamePlaying, "You cant withdraw during in game");
        for (uint256 i = 0; i < 6; i++) {
            if (players[i] == msg.sender) {
                emit Withdraw(msg.sender, i);
                address payable receiver =  payable(players[i]);
                if (address(this).balance >= price) {
                    receiver.transfer(price);
                    players[i] = address(0);
                    return true;
                } else {
                    players[i] = address(0);
                }

            }
        }
        return false;
    }

    function joinRoom() public payable {

        require(msg.value >= price, "Not enough Ether provided.");
        if (checkExist(msg.sender)) {
            revert("You have already joined");
        }
        if (!gamePlaying) {
            if (getTotalPlayers() < 6) {
                //check if every spot is taken
                uint256 position = pickPosition();
                players[position] = msg.sender;
                totalAmount += msg.value;
                emit Joined(msg.sender, position);
            } else {
                revert("Room is full");
            }
        } else {
            emit GameError("Game is  playing");
            revert("Game is not playing");
        }
    }
}