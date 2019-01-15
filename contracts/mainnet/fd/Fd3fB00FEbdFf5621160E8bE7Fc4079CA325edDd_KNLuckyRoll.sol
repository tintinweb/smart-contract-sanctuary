pragma solidity ^0.4.25;

contract ERC20Interface {
  function transfer(address to, uint tokens) public;
  function transferFrom(address from, address to, uint tokens) public returns (bool);
  function balanceOf(address tokenOwner) public view returns (uint256);
  function allowance(address tokenOwner, address spender) public view returns (uint);
}

contract KNLuckyRoll{
    address public admin;
    uint256 exceed;
    uint256 _seed = now;
    event PlayResult(
    address player,
    string xtype,
    uint256 betvalue,
    bool win,
    uint256 wonamount
    );
    
    event Shake(
    address from,
    bytes32 make_chaos
    );
    
    constructor() public{
        admin = 0x7D5c8C59837357e541BC7d87DeE53FCbba55bA65;
    }
    
    function random() private view returns (uint8) {
        return uint8(uint256(keccak256(block.timestamp, block.difficulty, _seed))%100); // random 0-99
    }
    
    function PlayX2() public payable {
        require(msg.value >= 1);
        require(ERC20Interface(0xbfd18F20423694a69e35d65cB9c9D74396CC2c2d).balanceOf(address(msg.sender)) >= 50000000000000000000);
        ERC20Interface(0xbfd18F20423694a69e35d65cB9c9D74396CC2c2d).transferFrom(msg.sender, address(this), 50000000000000000000);
        uint8 _random = random();

        if (_random + 50 >= 100) {
            if(msg.value*97/50 < address(this).balance) {
                msg.sender.transfer(msg.value*97/50);
                uint256 winx2 = msg.value*97/50;
                emit PlayResult(msg.sender, "x2", msg.value, true, winx2);
            } else {
                msg.sender.transfer(address(this).balance);
                emit PlayResult(msg.sender, "x2", msg.value, true, address(this).balance);
            }
        } else {
            emit PlayResult(msg.sender, "x2", msg.value, false, 0x0);
        }
    }
    
    function PlayX3() public payable {
        require(msg.value >= 1);
        require(ERC20Interface(0xbfd18F20423694a69e35d65cB9c9D74396CC2c2d).balanceOf(address(msg.sender)) >= 50000000000000000000);
        ERC20Interface(0xbfd18F20423694a69e35d65cB9c9D74396CC2c2d).transferFrom(msg.sender, address(this), 50000000000000000000);
        uint8 _random = random();

        if (_random + 33 >= 100) {
            if(msg.value*97/33 < address(this).balance) {
                msg.sender.transfer(msg.value*95/33);
                uint256 winx3 = msg.value*97/33;
                emit PlayResult(msg.sender, "x3", msg.value, true, winx3);
            } else {
                msg.sender.transfer(address(this).balance);
                emit PlayResult(msg.sender, "x3", msg.value, true, address(this).balance);
            }
        } else {
            emit PlayResult(msg.sender, "x3", msg.value, false, 0x0);
        }
    }
    
    function PlayX5() public payable {
        require(msg.value >= 1);
        require(ERC20Interface(0xbfd18F20423694a69e35d65cB9c9D74396CC2c2d).balanceOf(address(msg.sender)) >= 50000000000000000000);
        ERC20Interface(0xbfd18F20423694a69e35d65cB9c9D74396CC2c2d).transferFrom(msg.sender, address(this), 50000000000000000000);
        uint8 _random = random();

        if (_random + 20 >= 100) {
            if(msg.value*97/20 < address(this).balance) {
                msg.sender.transfer(msg.value*97/20);
                uint256 winx5 = msg.value*97/20;
                emit PlayResult(msg.sender, "x5", msg.value, true, winx5);
            } else {
                msg.sender.transfer(address(this).balance);
                emit PlayResult(msg.sender, "x5", msg.value, true, address(this).balance);
            }
        } else {
            emit PlayResult(msg.sender, "x5", msg.value, false, 0x0);
        }
    }
    
    function PlayX10() public payable {
        require(msg.value >= 1);
        require(ERC20Interface(0xbfd18F20423694a69e35d65cB9c9D74396CC2c2d).balanceOf(address(msg.sender)) >= 50000000000000000000);
        ERC20Interface(0xbfd18F20423694a69e35d65cB9c9D74396CC2c2d).transferFrom(msg.sender, address(this), 50000000000000000000);
        uint8 _random = random();

        if (_random + 10 >= 100) {
            if(msg.value*97/10 < address(this).balance) {
                msg.sender.transfer(msg.value*97/10);
                uint256 winx10 = msg.value*97/10;
                emit PlayResult(msg.sender, "x10", msg.value, true, winx10);
            } else {
                msg.sender.transfer(address(this).balance);
                emit PlayResult(msg.sender, "x10", msg.value, true, address(this).balance);
            }
        } else {
            emit PlayResult(msg.sender, "x10", msg.value, false, 0x0);
        }
    }
    
    function PlayX20() public payable {
        require(msg.value >= 1);
        require(ERC20Interface(0xbfd18F20423694a69e35d65cB9c9D74396CC2c2d).balanceOf(address(msg.sender)) >= 50000000000000000000);
        ERC20Interface(0xbfd18F20423694a69e35d65cB9c9D74396CC2c2d).transferFrom(msg.sender, address(this), 50000000000000000000);
        uint8 _random = random();

        if (_random + 5 >= 100) {
            if(msg.value*97/5 < address(this).balance) {
                msg.sender.transfer(msg.value*97/5);
                uint256 winx20 = msg.value*97/5;
                emit PlayResult(msg.sender, "x20", msg.value, true, winx20);
            } else {
                msg.sender.transfer(address(this).balance);
                emit PlayResult(msg.sender, "x20", msg.value, true, address(this).balance);
            }
        } else {
            emit PlayResult(msg.sender, "x20", msg.value, false, 0x0);
        }
    }
    
    function PlayX30() public payable {
        require(msg.value >= 1);
        require(ERC20Interface(0xbfd18F20423694a69e35d65cB9c9D74396CC2c2d).balanceOf(address(msg.sender)) >= 50000000000000000000);
        ERC20Interface(0xbfd18F20423694a69e35d65cB9c9D74396CC2c2d).transferFrom(msg.sender, address(this), 50000000000000000000);
        uint8 _random = random();

        if (_random + 3 >= 100) {
            if(msg.value*97/3 < address(this).balance) {
                msg.sender.transfer(msg.value*97/3);
                uint256 winx30 = msg.value*97/3;
                emit PlayResult(msg.sender, "x30", msg.value, true, winx30);
            } else {
                msg.sender.transfer(address(this).balance);
                emit PlayResult(msg.sender, "x30", msg.value, true, address(this).balance);
            }
        } else {
            emit PlayResult(msg.sender, "x30", msg.value, false, 0x0);
        }
    }
    
    function PlayX50() public payable {
        require(msg.value >= 1);
        require(ERC20Interface(0xbfd18F20423694a69e35d65cB9c9D74396CC2c2d).balanceOf(address(msg.sender)) >= 50000000000000000000);
        ERC20Interface(0xbfd18F20423694a69e35d65cB9c9D74396CC2c2d).transferFrom(msg.sender, address(this), 50000000000000000000);
        uint8 _random = random();

        if (_random + 2 >= 100) {
            if(msg.value*97/2 < address(this).balance) {
                msg.sender.transfer(msg.value*97/2);
                uint256 winx50 = msg.value*97/2;
                emit PlayResult(msg.sender, "x50", msg.value, true, winx50);
            } else {
                msg.sender.transfer(address(this).balance);
                emit PlayResult(msg.sender, "x50", msg.value, true, address(this).balance);
            }
        } else {
            emit PlayResult(msg.sender, "x50", msg.value, false, 0x0);
        }
    }
    
    function PlayX100() public payable {
        require(msg.value >= 1);
        require(ERC20Interface(0xbfd18F20423694a69e35d65cB9c9D74396CC2c2d).balanceOf(address(msg.sender)) >= 50000000000000000000);
        ERC20Interface(0xbfd18F20423694a69e35d65cB9c9D74396CC2c2d).transferFrom(msg.sender, address(this), 50000000000000000000);
        uint8 _random = random();

        if (_random + 1 >= 100) {
            if(msg.value*97 < address(this).balance) {
                msg.sender.transfer(msg.value*97);
                uint256 winx100 = msg.value*95;
                emit PlayResult(msg.sender, "x100", msg.value, true, winx100);
            } else {
                msg.sender.transfer(address(this).balance);
                emit PlayResult(msg.sender, "x100", msg.value, true, address(this).balance);
            }
        } else {
            emit PlayResult(msg.sender, "x100", msg.value, false, 0x0);
        }
    }
    
    function Playforfreetoken() public payable {
        require(msg.value >= 0.01 ether);
        exceed = msg.value - 0.01 ether;
        require(ERC20Interface(0xbfd18F20423694a69e35d65cB9c9D74396CC2c2d).balanceOf(address(this)) >= 200000000000000000000);
        ERC20Interface(0xbfd18F20423694a69e35d65cB9c9D74396CC2c2d).transfer(msg.sender, 200000000000000000000);
        uint8 _random = random();

        if (_random + 50 >= 100) {
            if(msg.value < address(this).balance) {
                msg.sender.transfer(msg.value);
                uint256 winfreetoken = msg.value;
                emit PlayResult(msg.sender, "freetoken", msg.value, true, winfreetoken);
            } else {
                msg.sender.transfer(address(this).balance);
                emit PlayResult(msg.sender, "freetoken", msg.value, true, address(this).balance);
            }
        } else {
            msg.sender.transfer(exceed);
            emit PlayResult(msg.sender, "freetoken", msg.value, false, 0);
        }
    }
    
    function Playforbulktoken() public payable {
        require(msg.value >= 1 ether);
        exceed = msg.value - 1 ether;
        require(ERC20Interface(0xbfd18F20423694a69e35d65cB9c9D74396CC2c2d).balanceOf(address(this)) >= 20000000000000000000000);
        ERC20Interface(0xbfd18F20423694a69e35d65cB9c9D74396CC2c2d).transfer(msg.sender, 20000000000000000000000);
        uint8 _random = random();

        if (_random + 50 >= 100) {
            if(msg.value < address(this).balance) {
                msg.sender.transfer(msg.value);
                emit PlayResult(msg.sender, "bulktoken", msg.value, true, msg.value);
            } else {
                msg.sender.transfer(address(this).balance);
                emit PlayResult(msg.sender, "bulktoken", msg.value, true, address(this).balance);
            }
        } else {
            msg.sender.transfer(exceed);
            emit PlayResult(msg.sender, "bulktoken", msg.value, false, 0);
        }
    }

    modifier onlyAdmin() {
        // Ensure the participant awarding the ether is the admin
        require(msg.sender == admin);
        _;
    }
    
    function withdrawEth(address to, uint256 balance) external onlyAdmin {
        if (balance == uint256(0x0)) {
            to.transfer(address(this).balance);
        } else {
        to.transfer(balance);
        }
    }
    
    function withdrawToken(address contractAddress, address to, uint256 balance) external onlyAdmin {
        ERC20Interface erc20 = ERC20Interface(contractAddress);
        if (balance == uint256(0x0)){
            erc20.transfer(to, erc20.balanceOf(address(this)));
        } else {
            erc20.transfer(to, balance);
        }
    }
    
    function shake(uint256 choose_a_number_to_chaos_the_algo) public {
        _seed = uint256(keccak256(choose_a_number_to_chaos_the_algo));
        emit Shake(msg.sender, "You changed the algo");
    }
    
    function () public payable {
        require(msg.value > 0 ether);
    }
}